"""Plan de production : la bible Control-M (docs/Plan de Production.xlsx) enrichie par les photos ODAT.

On raisonne toujours autour de la clôture : J = dernier jour ouvré du mois, J-7 … J+16 en jours ouvrés
(week-ends et fériés français exclus), calendrier Control-M en rappel (J-n = L{n+1}, J+n = D{n}).
Les chaînes quotidiennes s'expriment en jours de semaine (« lun mar mer jeu ven »), les autres en J±n.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta
import io
import re
import sqlite3
import zipfile

import pandas as pd

from calendar_import import _excel_date, _rows, _shared_strings, _sheets
from db import BASE_DIR

BIBLE = BASE_DIR / "docs" / "Plan de Production.xlsx"
AVANT, APRES = 7, 16                      # fenêtre J-7 … J+16
JOURS = ["lun", "mar", "mer", "jeu", "ven", "sam", "dim"]
NON_LANCE = "Non lancé"                   # cf. forecast.consolider : ordonnancé, jamais parti pour cet odate
ORDRE = {"Ended Not OK": 0, "Executing": 1, "Wait for Event": 2, "Ended OK": 3, NON_LANCE: 4}
ICONES = {"Ended Not OK": "✖", "Executing": "▶", "Wait for Event": "⏸", "Ended OK": "✔", NON_LANCE: "⊘"}
NON_OBSERVE, PREVU, SANS_PHOTO = "○", "·", "?"      # absent d'une photo du jour / à venir / jour sans photo
# ponytail: seuils fixes de l'heuristique de planification observée ; à exposer si les propositions déçoivent
SEUIL_QUOTIDIEN = 0.6                     # part des jours avec photo où la chaîne tourne
SEUIL_RECURRENT = 0.5                     # part des mois (ou des semaines) où un J±n / un jour revient
OUBLI_JOURS = 40                          # absente depuis plus d'un cycle mensuel : « Plus vue »
CODE = re.compile(r"^FIN[A-Z]{3}_\w+$")


# ---------------------------------------------------------------- calendrier
def jours_feries(annee: int) -> set[date]:
    """Fériés nationaux français (Pâques : algorithme de Meeus)."""
    a, b, c = annee % 19, annee // 100, annee % 100
    d, e = b // 4, b % 4
    g = (8 * b + 13) // 25
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    mois = (h + l - 7 * m + 114) // 31
    paques = date(annee, mois, (h + l - 7 * m + 114) % 31 + 1)
    fixes = [(1, 1), (5, 1), (5, 8), (7, 14), (8, 15), (11, 1), (11, 11), (12, 25)]
    return {date(annee, mm, jj) for mm, jj in fixes} | {paques + timedelta(days=n) for n in (1, 39, 50)}


def ouvre(d: date) -> bool:
    return d.weekday() < 5 and d not in jours_feries(d.year)


def jour_j(annee: int, mois: int) -> date:
    """J : dernier jour ouvré du mois."""
    d = (date(annee + mois // 12, mois % 12 + 1, 1)) - timedelta(days=1)
    while not ouvre(d):
        d -= timedelta(days=1)
    return d


def _decaler(d: date, n: int) -> date:
    """n-ième jour ouvré après (n > 0) ou avant (n < 0) d."""
    pas = 1 if n > 0 else -1
    for _ in range(abs(n)):
        d += timedelta(days=pas)
        while not ouvre(d):
            d += timedelta(days=pas)
    return d


def label_ctm(label: str) -> str:
    """J-2 -> L3, J -> L1, J+4 -> D4."""
    n = 0 if label == "J" else int(label[1:])
    return f"L{1 - n}" if n <= 0 else f"D{n}"


def calendrier(annee: int, mois: int) -> pd.DataFrame:
    """Jours de J-7 à J+16 (non ouvrés inclus, sans label) : date, label_j, label_ctm, ouvre."""
    j = jour_j(annee, mois)
    labels = {_decaler(j, n) if n else j: ("J" if n == 0 else f"J{n:+d}") for n in range(-AVANT, APRES + 1)}
    debut, fin = min(labels), max(labels)
    lignes = []
    for k in range((fin - debut).days + 1):
        d = debut + timedelta(days=k)
        lj = labels.get(d, "")
        lignes.append(dict(date=d, label_j=lj, label_ctm=label_ctm(lj) if lj else "", ouvre=ouvre(d)))
    return pd.DataFrame(lignes)


def libelle(label_j: str, label_ctm: str) -> str:
    return f"{label_j} ({label_ctm})" if label_j else ""


def label_jour(d: date) -> str:
    """Label J±n d'un jour ouvré quelconque : J-n du mois si n ≤ 7, sinon J+n du mois précédent ("" au-delà)."""
    if not ouvre(d):
        return ""
    j = jour_j(d.year, d.month)
    n = 0
    x = d
    while x < j:
        x = _decaler(x, 1)
        n += 1
    if n <= AVANT:
        return "J" if n == 0 else f"J-{n}"
    prec = jour_j(d.year - (d.month == 1), 12 if d.month == 1 else d.month - 1)
    m, x = 0, prec
    while x < d:
        x = _decaler(x, 1)
        m += 1
    return f"J+{m}" if m <= APRES else ""


def _mois_de_label(d: date, label: str) -> tuple[int, int]:
    """Mois comptable auquel se rapporte le label (J+n du mois précédent)."""
    if label.startswith("J+"):
        return (d.year - (d.month == 1), 12 if d.month == 1 else d.month - 1)
    return (d.year, d.month)


# ---------------------------------------------------------------- planification (texte)
def lire_planification(texte: str | None) -> tuple[set[int], set[str]]:
    """« lun mar ven » -> jours de semaine ; « J-2, J, D4, L3 » -> labels J (D4 = J+4, L3 = J-2)."""
    jours, labels = set(), set()
    for tok in re.split(r"[\s,;]+", (texte or "").strip().lower()):
        if m := re.fullmatch(r"j([+-]\d+)?", tok):
            n = int(m.group(1) or 0)
            labels.add("J" if n == 0 else f"J{n:+d}")
        elif m := re.fullmatch(r"([ld])(\d+)", tok):
            n = int(m.group(2))
            n = 1 - n if m.group(1) == "l" else n
            labels.add("J" if n == 0 else f"J{n:+d}")
        elif tok[:3] in JOURS:
            jours.add(JOURS.index(tok[:3]))
    return jours, labels


def labels_du_texte(texte: str) -> set[str]:
    """Labels L/D écrits par l'auteur de la bible (« Clôture - L6, L5 », « Périodique D4 ») ; rien si la règle
    est quotidienne ou à exceptions (« Quotidien - Sauf L7 », « En journée - L3 … »)."""
    if not texte or re.search(r"sauf|quotidien|jour", texte, re.I):
        return set()
    return lire_planification(" ".join(re.findall(r"\b[LD]\d+\b", texte)))[1]


NOMS_JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]


def jours_du_texte(texte: str) -> set[int]:
    """Jours nommés d'une règle hebdo (« tous les samedis 13h00 », « Lundi sauf L1 »), intervalles compris
    (« Du dimanche au vendredi ») ; rien pour « 1er Samedi », « 2ème Vendredi » (mensuel) ni « entre L3 et D2 »."""
    t = (texte or "").lower()
    if re.search(r"\d+\s*(er|e|ème|éme|eme)\b|entre", t):
        return set()
    noms = "|".join(NOMS_JOURS)
    if m := re.search(rf"\b({noms})s?\s+au\s+({noms})", t):
        a, b = NOMS_JOURS.index(m.group(1)), NOMS_JOURS.index(m.group(2))
        return {(a + k) % 7 for k in range((b - a) % 7 + 1)}
    return {i for i, nom in enumerate(NOMS_JOURS) if re.search(rf"\b{nom}", t)}


def _tri_labels(labels) -> list[str]:
    return sorted(labels, key=lambda l: 0 if l == "J" else int(l[1:]))


def ecrire_labels(labels) -> str:
    return ", ".join(_tri_labels(labels))


def ecrire_jours(jours) -> str:
    return " ".join(JOURS[i] for i in sorted(jours))


def en_ctm(planification: str | None) -> str:
    """Rappel Control-M d'une planification J±n : « J-2, J, J+4 » -> « L3, L1, D4 » (vide pour des jours de semaine)."""
    return ", ".join(label_ctm(l) for l in _tri_labels(lire_planification(planification)[1]))


def attendus(planification: str | None, cal: pd.DataFrame) -> set[date]:
    jours, labels = lire_planification(planification)
    return {d for d, lj in zip(cal["date"], cal["label_j"])
            if d.weekday() in jours or (lj and lj in labels)}


# ---------------------------------------------------------------- bible Excel
def lire_bible(content: bytes) -> pd.DataFrame:
    """Une ligne par chaîne de la bible : code, description, categorie, planification_ref, jours_reference,
    planification (proposée : jours de semaine si quotidienne, J±n sinon), feuille. Lecture zipfile, sans macro."""
    if not content:
        raise ValueError("Fichier vide.")
    try:
        zf = zipfile.ZipFile(io.BytesIO(content))
    except zipfile.BadZipFile as exc:
        raise ValueError("Le fichier n'est pas un classeur Excel .xlsx lisible.") from exc
    feuilles = []
    with zf:
        shared = _shared_strings(zf)
        for nom, root in _sheets(zf):
            rows = {int(r["__row__"]): r for r in _rows(root, shared)}
            entete_j, entete_d = rows.get(1, {}), rows.get(4, {})
            dates = {c: _excel_date(v) for c, v in entete_d.items() if c not in ("A", "B", "C", "__row__")}
            dates = {c: date.fromisoformat(v) for c, v in dates.items() if v}
            if not dates:
                continue
            chaines: dict[str, dict] = {}
            for num in sorted(r for r in rows if r >= 5):
                r = rows[num]
                cellules = {c: v for c, v in r.items() if c in dates and CODE.match(v or "")}
                code = r.get("A", "") if CODE.match(r.get("A", "")) else next(iter(cellules.values()), "")
                if not code:
                    continue
                cat, planif = (re.split(r"\s+-(?:\s+|$)", r.get("C", "") or "", maxsplit=1) + [""])[:2]
                cat = "Périodique" if cat.strip() == "Periodique" else cat
                ch = chaines.setdefault(code, dict(code=code, descriptions=[], categorie=cat.strip(),
                                                   planifs=[], jours=set()))
                for desc in (r.get("B") or "").splitlines():
                    if desc.strip() and desc.strip() not in ch["descriptions"]:
                        ch["descriptions"].append(desc.strip())
                if planif.strip() and planif.strip() not in ch["planifs"]:
                    ch["planifs"].append(planif.strip())
                ch["jours"] |= {(dates[c], entete_j.get(c, "")) for c, v in cellules.items() if v == code}
            feuilles.append((max(dates.values()), nom, chaines))
    if not feuilles:
        raise ValueError("Aucune feuille au format de la bible (dates en ligne 4) n'a été reconnue.")
    retenu: dict[str, dict] = {}
    for _, nom, chaines in sorted(feuilles, key=lambda f: f[0]):   # la feuille la plus récente l'emporte
        for code, ch in chaines.items():
            retenu[code] = {**ch, "feuille": nom}
    lignes = []
    for ch in retenu.values():
        jours = sorted(ch["jours"])
        ref = [lj or (JOURS[d.weekday()] if d.weekday() >= 5 else "férié") for d, lj in jours]
        labels = {lj for _, lj in jours if lj}
        texte = " ".join(ch["planifs"])
        ecrits, nommes = labels_du_texte(texte), jours_du_texte(f"{ch['categorie']} {texte}")
        quotidienne = (re.search(r"quotidien|tous les jours", texte, re.I)
                       or ch["categorie"] in ("Quotidienne", "Référentiel") or len(labels) >= 10)
        if ecrits:                                   # la règle écrite (L/D) prime sur les cases cochées
            planif = ecrire_labels(ecrits)
        elif nommes:                                 # « tous les samedis », « Lundi sauf L1 »
            planif = ecrire_jours(nommes)
        elif quotidienne or (jours and not labels):  # quotidienne, ou uniquement le week-end
            semaine = {d.weekday() for d, _ in jours}
            planif = ecrire_jours(semaine - {5, 6} if re.search(r"sauf le w", texte, re.I) else semaine)
        else:
            planif = ecrire_labels(labels)
        lignes.append(dict(code=ch["code"], description=" ; ".join(ch["descriptions"]), categorie=ch["categorie"],
                           planification_ref=" ; ".join(ch["planifs"]), jours_reference=",".join(ref),
                           planification=planif, feuille=ch["feuille"]))
    return pd.DataFrame(lignes).sort_values("code").reset_index(drop=True)


def _maintenant() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def importer_bible(con: sqlite3.Connection, nom: str, content: bytes) -> str:
    """Remplace les chaînes issues de la bible ; les chaînes ajoutées depuis les ODAT (statut « nouvelle ») restent."""
    bible = lire_bible(content)
    now = _maintenant()
    with con:
        codes = list(bible["code"])
        con.execute(f"DELETE FROM pdp_chaines WHERE statut<>'nouvelle' AND code NOT IN ({','.join('?' * len(codes))})",
                    codes)
        con.executemany("""
            INSERT INTO pdp_chaines(code, description, categorie, planification, planification_ref, jours_reference,
                                    statut, source, importe_le)
            VALUES (?,?,?,?,?,?,?,?,?)
            ON CONFLICT(code) DO UPDATE SET description=excluded.description, categorie=excluded.categorie,
                planification=excluded.planification, planification_ref=excluded.planification_ref,
                jours_reference=excluded.jours_reference, statut=excluded.statut, source=excluded.source,
                importe_le=excluded.importe_le""",
            [(r.code, r.description, r.categorie, r.planification, r.planification_ref, r.jours_reference,
              "supprimee" if r.categorie.lower().startswith("suppr") else "bible", f"{nom} ({r.feuille})", now)
             for r in bible.itertuples()])
    return f"{len(bible)} chaîne(s) chargée(s) depuis {nom}."


def referentiel(con: sqlite3.Connection) -> pd.DataFrame:
    return pd.read_sql_query("SELECT * FROM pdp_chaines ORDER BY code", con)


EDITABLES = ("description", "categorie", "planification", "statut", "commentaire")


def enregistrer(con: sqlite3.Connection, df: pd.DataFrame) -> int:
    """Enregistre les colonnes éditables des lignes modifiées. Renvoie le nombre de lignes changées."""
    avant = referentiel(con).set_index("code")
    now, n = _maintenant(), 0
    with con:
        for r in df.itertuples():
            if r.code not in avant.index:
                continue
            valeurs = [None if pd.isna(getattr(r, c)) else getattr(r, c) for c in EDITABLES]
            if valeurs != [None if pd.isna(avant.at[r.code, c]) else avant.at[r.code, c] for c in EDITABLES]:
                manuelle = int(avant.at[r.code, "planif_manuelle"] or 0)
                if valeurs[EDITABLES.index("planification")] != avant.at[r.code, "planification"]:
                    manuelle = 1 if valeurs[EDITABLES.index("planification")] else 0   # vider rend la main aux ODAT
                con.execute(f"UPDATE pdp_chaines SET {', '.join(f'{c}=?' for c in EDITABLES)}, planif_manuelle=?, "
                            "maj_le=? WHERE code=?", (*valeurs, manuelle, now, r.code))
                n += 1
    return n


def ajouter(con: sqlite3.Connection, lignes: pd.DataFrame) -> int:
    """Ajoute au référentiel des chaînes vues dans les ODAT (colonnes chaine, description, planification_observee)."""
    now = _maintenant()
    with con:
        cur = con.executemany("""INSERT OR IGNORE INTO pdp_chaines(code, description, categorie, planification,
                                   statut, source, importe_le) VALUES (?,?,?,?, 'nouvelle', 'ODAT', ?)""",
                              [(r.chaine, r.description, "À qualifier", r.planification_observee, now)
                               for r in lignes.itertuples()])
    return cur.rowcount


def adopter_planification(con: sqlite3.Connection, planifs: dict[str, str]) -> int:
    now = _maintenant()
    with con:
        con.executemany("UPDATE pdp_chaines SET planification=?, planif_manuelle=0, maj_le=? WHERE code=?",
                        [(p, now, c) for c, p in planifs.items()])
    return len(planifs)


def synchroniser(con: sqlite3.Connection, df_runs: pd.DataFrame) -> pd.DataFrame:
    """Ajuste le plan de production sur les photos ODAT (la bible n'a servi qu'au premier chargement) :
    ajoute les chaînes nouvelles, passe « supprimée » une chaîne absente des photos depuis OUBLI_JOURS jours,
    réactive une chaîne supprimée qui revient, aligne la planification sur celle observée sauf saisie manuelle.
    Renvoie le journal des changements : code, changement, avant, après."""
    cols = ["code", "changement", "avant", "après"]
    if df_runs.empty:
        return pd.DataFrame(columns=cols)
    ref = referentiel(con).set_index("code")
    histo = historique_chaines(df_runs).set_index("group_name")["derniere_odate"]
    obs = planification_observee(df_runs)
    descs = descriptions_chaines(df_runs)
    limite = max(df_runs["odate"]) - timedelta(days=OUBLI_JOURS)
    now, journal = _maintenant(), []
    with con:
        for code in sorted(set(histo.index) - set(ref.index)):
            if histo[code] < limite:
                continue                                   # disparue avant d'avoir été référencée
            con.execute("""INSERT INTO pdp_chaines(code, description, categorie, planification, statut, source,
                           importe_le, maj_le) VALUES (?,?,'À qualifier',?,'nouvelle','ODAT',?,?)""",
                        (code, descs.get(code, ""), obs.get(code, ""), now, now))
            journal.append((code, "ajoutée", "", obs.get(code, "")))
        for code, r in ref.iterrows():
            vue = code in histo.index and histo[code] >= limite
            statut = r["statut"]
            if not vue and statut != "supprimee":
                statut = "supprimee"
                depuis = f"plus vue depuis le {histo[code]:%d/%m/%Y}" if code in histo.index else "jamais vue"
                journal.append((code, "supprimée", r["statut"], depuis))
            elif vue and statut == "supprimee":
                statut = "nouvelle" if r["source"] == "ODAT" else "bible"
                journal.append((code, "réactivée", "supprimee", f"vue le {histo[code]:%d/%m/%Y}"))
            planif = r["planification"] or ""
            proposee = obs.get(code, "")
            if (vue and not r["planif_manuelle"] and proposee not in ("", "variable") and proposee != planif):
                journal.append((code, "planification", planif, proposee))
                planif = proposee
            if statut != r["statut"] or planif != (r["planification"] or ""):
                con.execute("UPDATE pdp_chaines SET statut=?, planification=?, maj_le=? WHERE code=?",
                            (statut, planif, now, code))
        con.execute("INSERT INTO parametres(cle, valeur) VALUES ('pdp.synchro', ?) "
                    "ON CONFLICT(cle) DO UPDATE SET valeur=excluded.valeur", (now,))
    return pd.DataFrame(journal, columns=cols)


def derniere_synchro(con: sqlite3.Connection) -> str | None:
    row = con.execute("SELECT valeur FROM parametres WHERE cle='pdp.synchro'").fetchone()
    return row[0] if row else None


# ---------------------------------------------------------------- observations ODAT
def _dernier_etat(df_runs: pd.DataFrame) -> pd.DataFrame:
    """Un état par (job, odate) : celui de la photo la plus récente."""
    if df_runs.empty:
        return df_runs
    return df_runs.sort_values("snap_time").drop_duplicates(["job_name", "odate"], keep="last")


def grille(df_runs: pd.DataFrame, cal: pd.DataFrame, cle: str = "group_name") -> pd.DataFrame:
    """cle (chaîne ou job) × jour de la fenêtre : nb_jobs, statut (pire état des jobs)."""
    cols = [cle, "odate", "nb_jobs", "statut"]
    if df_runs.empty:
        return pd.DataFrame(columns=cols)
    d = _dernier_etat(df_runs)
    d = d[d["odate"].isin(set(cal["date"]))]
    if d.empty:
        return pd.DataFrame(columns=cols)
    d = d.assign(_o=d["status"].map(ORDRE).fillna(9))
    g = d.sort_values("_o").groupby([cle, "odate"]).agg(nb_jobs=("job_name", "nunique"), statut=("status", "first"))
    return g.reset_index()[cols]


def _lances(df_runs: pd.DataFrame) -> pd.DataFrame:
    """Exécutions réellement parties (sans les « Non lancé »)."""
    return df_runs[df_runs["status"].ne(NON_LANCE)] if "status" in df_runs else df_runs


def historique_chaines(df_runs: pd.DataFrame) -> pd.DataFrame:
    df_runs = _lances(df_runs)
    if df_runs.empty:
        return pd.DataFrame(columns=["group_name", "premiere_odate", "derniere_odate", "nb_odates"])
    return (df_runs.groupby("group_name")["odate"].agg(premiere_odate="min", derniere_odate="max", nb_odates="nunique")
            .reset_index())


def planification_observee(df_runs: pd.DataFrame) -> dict[str, str]:
    """Planification déduite de tout l'historique : jours de semaine pour une quotidienne ou une hebdo,
    J±n qui reviennent au moins un mois sur deux sinon, « variable » quand rien ne revient."""
    if df_runs.empty:
        return {}
    jours_photo = sorted(set(df_runs["odate"]))
    labels = {d: label_jour(d) for d in jours_photo}
    out = {}
    for chaine, g in _lances(df_runs).groupby("group_name"):
        vus = set(g["odate"])
        periode = [d for d in jours_photo if min(vus) <= d <= max(vus)]
        if len(vus) >= SEUIL_QUOTIDIEN * len(periode) and len(periode) >= 5:
            par_jour = {w: [d for d in periode if d.weekday() == w] for w in range(7)}
            out[chaine] = ecrire_jours(w for w, ds in par_jour.items()
                                       if ds and sum(d in vus for d in ds) >= SEUIL_RECURRENT * len(ds))
            continue
        # hebdo avant J±n : un J+5 qui revient peut n'être qu'un vendredi
        photos_jour = {w: sum(d.weekday() == w for d in periode) for w in range(7)}
        hebdo = {w for w, n in photos_jour.items()
                 if n >= 3 and sum(d.weekday() == w for d in vus) >= SEUIL_RECURRENT * n}
        if hebdo:
            out[chaine] = ecrire_jours(hebdo)
            continue
        mois = {_mois_de_label(d, labels[d]) for d in periode if labels[d]}
        compte: dict[str, set] = {}
        for d in vus:
            if labels.get(d):
                compte.setdefault(labels[d], set()).add(_mois_de_label(d, labels[d]))
        retenus = {l for l, ms in compte.items() if len(mois) >= 2 and len(ms) >= SEUIL_RECURRENT * len(mois)}
        if retenus:
            out[chaine] = ecrire_labels(retenus)
            continue
        out[chaine] = "variable"
    return out


def descriptions_chaines(df_runs: pd.DataFrame) -> dict[str, str]:
    """Description d'une chaîne vue dans les ODAT : celle de son job homonyme, sinon la plus fréquente."""
    if df_runs.empty:
        return {}
    out = {}
    for chaine, g in df_runs.groupby("group_name"):
        homonyme = g.loc[g["job_name"] == chaine, "description"].dropna()
        desc = homonyme if len(homonyme) else g["description"].dropna()
        out[chaine] = desc.mode().iloc[0] if len(desc) else ""
    return out


# ---------------------------------------------------------------- synthèse du mois
def entete(d: date, label_j: str) -> str:
    return f"{label_j or JOURS[d.weekday()]} {d:%d/%m}"


def synthese(df_runs: pd.DataFrame, cal: pd.DataFrame, ref: pd.DataFrame,
             planif_obs: dict[str, str] | None = None) -> pd.DataFrame:
    """Une ligne par chaîne (référentiel ∪ chaînes vues dans la fenêtre) : colonnes fixes puis une colonne par jour."""
    planif_obs = planif_obs if planif_obs is not None else planification_observee(df_runs)
    g = grille(df_runs, cal)
    histo = historique_chaines(df_runs).set_index("group_name")
    descs = descriptions_chaines(df_runs)
    jours_photo = set(df_runs["odate"]) if not df_runs.empty else set()
    derniere_photo = max(jours_photo) if jours_photo else None
    debut = cal["date"].min()
    ref = ref.set_index("code") if not ref.empty else pd.DataFrame(
        columns=["description", "categorie", "planification", "statut"])
    obs = {c: dict(zip(sg["odate"], zip(sg["statut"], sg["nb_jobs"]))) for c, sg in g.groupby("group_name")}
    heads = {d: entete(d, lj) for d, lj in zip(cal["date"], cal["label_j"])}
    nom = {d: (lj or f"{JOURS[d.weekday()]} {d:%d/%m}") for d, lj in zip(cal["date"], cal["label_j"])}
    lignes = []
    for chaine in sorted(set(ref.index) | set(obs)):
        connu = chaine in ref.index
        r = ref.loc[chaine] if connu else None
        planif = (r["planification"] if connu else "") or ""
        vus = obs.get(chaine, {})
        lances = {d for d, (statut, _) in vus.items() if statut != NON_LANCE}   # ⊘ : ordonnancée, jamais partie
        prevus = attendus(planif, cal)
        if not connu:
            origine = "Nouvelle"
        elif r["statut"] == "supprimee":
            origine = "Supprimée"
        elif chaine not in histo.index:
            origine = "Jamais vue"
        elif (not vus and derniere_photo is not None
              and histo.at[chaine, "derniere_odate"] < min(debut, derniere_photo - timedelta(days=OUBLI_JOURS))):
            origine = f"Plus vue depuis {histo.at[chaine, 'derniere_odate']:%d/%m/%Y}"
        else:
            origine = "Ajoutée" if r["statut"] == "nouvelle" else "Référentiel"
        ecarts = ""
        if planif and origine not in ("Supprimée",):
            plus = [nom[d] for d in sorted(lances) if d not in prevus]
            moins = [nom[d] for d in sorted(prevus) if d in jours_photo and d not in lances]
            ecarts = " ".join([f"+{x}" for x in plus] + [f"−{x}" for x in moins])
        ligne = dict(chaine=chaine,
                     description=(r["description"] if connu and r["description"] else descs.get(chaine, "")),
                     categorie=(r["categorie"] if connu else "À qualifier") or "",
                     planification=planif, planification_observee=planif_obs.get(chaine, ""),
                     origine=origine, ecarts=ecarts)
        for d in cal["date"]:
            if d in vus:
                statut, nb = vus[d]
                ligne[heads[d]] = f"{ICONES.get(statut, '•')} {nb}" + (
                    "" if d in prevus or not planif or statut == NON_LANCE else "+")
            elif d in prevus and origine != "Supprimée":
                ligne[heads[d]] = (NON_OBSERVE if d in jours_photo
                                   else PREVU if derniere_photo is None or d > derniere_photo else SANS_PHOTO)
            else:
                ligne[heads[d]] = ""
        lignes.append(ligne)
    colonnes = ["chaine", "description", "categorie", "planification", "planification_observee", "origine", "ecarts",
                *heads.values()]
    return pd.DataFrame(lignes, columns=colonnes)


def mois_disponibles(df_runs: pd.DataFrame) -> list[tuple[int, int]]:
    """Mois comptables dont la fenêtre J-7 … J+16 recoupe l'historique, plus le mois suivant (à préparer)."""
    if df_runs.empty:
        today = date.today()
        return [(today.year, today.month)]
    debut, fin = min(df_runs["odate"]), max(df_runs["odate"])
    a, m = (debut.year, debut.month - 1) if debut.month > 1 else (debut.year - 1, 12)
    out = []
    while True:
        cal = calendrier(a, m)
        if cal["date"].min() > fin:
            out.append((a, m))                    # premier mois entièrement à venir
            break
        if cal["date"].max() >= debut:
            out.append((a, m))
        a, m = (a, m + 1) if m < 12 else (a + 1, 1)
    return out


if __name__ == "__main__":                     # contrôle rapide sur la bible du dépôt
    b = lire_bible(BIBLE.read_bytes())
    print(len(b), "chaînes")
    print(b.head(20).to_string())
