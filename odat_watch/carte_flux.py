"""Carte des flux : l'état de chaque flux du référentiel, lu dans ce qu'ODAT Watch sait déjà (fichiers
transmis de Ctrl Flux, contrôles des virements, des prélèvements et des relevés), et les nœuds et liens
du diagramme applications → Oracle → applications. Module pur, sans Streamlit ni Oracle."""
from __future__ import annotations
import sqlite3
from datetime import datetime

import pandas as pd

import flux_ref as fx

TOL = 0.01
ORACLE = "FIN01 · ORACLE"
ETATS = ("ok", "ecart", "inconnu", "inactif")
LIBELLES_ETAT = {"ok": "conforme", "ecart": "en écart", "inconnu": "sans donnée", "inactif": "inactif"}
COULEURS_ETAT = {"ok": "#2FB170", "ecart": "#F0A020", "inconnu": "#C4CBD4", "inactif": "#E6E9EE"}
# Palette des nœuds, façon Neo4j Browser : pastels francs, un par domaine du schéma, Oracle en bleu nuit
COULEURS_DOMAINE = {"FINANCES": "#FFC454", "REFERENTIEL": "#4C8EDA", "OPERATION": "#F79767",
                    "RESSOURCES HUMAINES": "#C990C0", "PARTENAIRES EXTERNES": "#848484",
                    "JURIDIQUE, RISQUE, COMMUNICATION & PILOTAGE": "#57C7E3",
                    "MARKETING, COMMERCE & RELATION CLIENTS": "#8DCC93",
                    "APPLICATION SYSTEME D'INFORMATION": "#D9C8AE", "DECOMMISSIONNEE": "#A5ABB6", "INCONNU": "#ECB5C9"}
COULEUR_ORACLE = "#1F3B73"
TIRETS_NATURE = {"Flux Asynchrone (Batch)": [8, 4], "Flux Asynchrone (Fil de l'eau)": [2, 4],
                 "Flux Synchrone": False, "Nature de flux inconnue": [10, 4, 2, 4]}


def _date_fr(txt) -> datetime | None:
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(str(txt)[:10], fmt)
        except (TypeError, ValueError):
            continue
    return None


def _jjmm(d: datetime | None) -> str:
    return d.strftime("%d/%m/%Y") if d else "—"


# ------------------------------------------------------------------ état d'un flux

VIDE = {"nb_fichiers": 0, "nb_lignes": 0, "nb_folios": 0, "folios": "", "nb_pieces": None, "montant": None,
        "ecart": None, "nb_ecart": 0, "types": "", "dernier_fichier": "", "rapprochees": 0}


def _etat_ctrl_flux(con, motif: str) -> dict:
    """État et volumétrie d'un flux d'après les lignes Ctrl Flux dont le fichier transmis suit le motif :
    fichiers, folios, types (FOURNISSEURS / CLIENTS / GL), pièces et montant amont, écart restant."""
    lignes = pd.read_sql_query(
        "SELECT fichier, folio, type, date, amont_nb, amont_debit, ecart_debit, ecart_nb, rapproche FROM ("
        "  SELECT l.fichier, l.folio, l.type, l.date, l.amont_nb, l.amont_debit, l.ecart_debit, l.ecart_nb, "
        "         EXISTS (SELECT 1 FROM fr_rapprochement_lignes rl JOIN fr_rapprochements r ON r.id = rl.rapprochement_id "
        "                 WHERE rl.empreinte = l.empreinte AND r.annule_le IS NULL) AS rapproche "
        "  FROM fr_lignes l WHERE l.present = 1 AND l.fichier IS NOT NULL)", con)
    if not lignes.empty:
        lignes = lignes[[fx.reconnait(motif, f) for f in lignes["fichier"]]]
    if lignes.empty:
        return {"etat": "inconnu", "detail": "aucun fichier transmis connu pour ce motif", "vu_le": None, **VIDE}
    dates = [d for d in (_date_fr(x) for x in lignes["date"]) if d]
    vu_le = max(dates) if dates else None
    ouvertes = lignes[~lignes["rapproche"].astype(bool)]
    ecart = round(float(ouvertes["ecart_debit"].fillna(0).sum()), 2)
    nb_ecart = int((ouvertes["ecart_debit"].fillna(0).abs() >= TOL).sum())
    folios = sorted(f for f in lignes["folio"].dropna().unique() if str(f).strip())
    types = sorted(t for t in lignes["type"].dropna().unique() if str(t).strip())
    # dernier fichier transmis vu, à la dernière date connue
    recents = lignes[[_date_fr(x) == vu_le for x in lignes["date"]]] if vu_le else lignes
    dernier = sorted(recents["fichier"].dropna().unique())[-1] if len(recents) else ""
    if nb_ecart:
        etat = "ecart"
        detail = f"{nb_ecart} ligne(s) en écart, {ecart:,.2f} € manquant(s) au SI Finance".replace(",", " ")
    else:
        etat, detail = "ok", "amont et SI Finance à l'équilibre sur toutes les lignes"
    return {"etat": etat, "detail": detail, "vu_le": vu_le,
            "nb_fichiers": int(lignes["fichier"].nunique()), "nb_lignes": len(lignes),
            "nb_folios": len(folios), "folios": ", ".join(folios[:12]) + ("…" if len(folios) > 12 else ""),
            "nb_pieces": float(lignes["amont_nb"].fillna(0).sum()),
            "montant": round(float(lignes["amont_debit"].fillna(0).sum()), 2),
            "ecart": ecart, "nb_ecart": nb_ecart, "types": ", ".join(types), "dernier_fichier": dernier,
            "rapprochees": int(lignes["rapproche"].astype(bool).sum())}


def _etat_virements(con) -> dict:
    r = con.execute("SELECT date_ctrl, ok, ko, ecarts, nb_envoyes, montant_envoye FROM vir_histo "
                    "ORDER BY date_ctrl DESC, executed_at DESC LIMIT 1").fetchone()
    if not r:
        return {"etat": "inconnu", "detail": "aucun contrôle des virements en base", "vu_le": None}
    conforme = bool(r["ok"]) and not (r["ko"] or 0) and not (r["ecarts"] or 0)
    return {"etat": "ok" if conforme else "ecart", "vu_le": _date_fr(r["date_ctrl"]),
            "detail": (f"{r['nb_envoyes'] or 0} envoi(s), {float(r['montant_envoye'] or 0):,.2f} € "
                       + ("conformes" if conforme else f"— {r['ko'] or 0} KO, {r['ecarts'] or 0} écart(s)")).replace(",", " ")}


def _etat_prelevements(con) -> dict:
    r = con.execute("SELECT reference, statut_global, nb_emis, montant_emis FROM pv_histo "
                    "ORDER BY reference DESC, executed_at DESC LIMIT 1").fetchone()
    if not r:
        return {"etat": "inconnu", "detail": "aucun rapprochement des prélèvements en base", "vu_le": None}
    return {"etat": "ok" if r["statut_global"] == "OK" else "ecart", "vu_le": _date_fr(r["reference"]),
            "detail": f"{r['nb_emis'] or 0} prélèvement(s) émis, statut {r['statut_global']}"}


def _etat_releves(con) -> dict:
    r = con.execute("SELECT date_max, nb_releves, nb_lignes FROM rb_ebs ORDER BY date_max DESC LIMIT 1").fetchone()
    if not r:
        return {"etat": "inconnu", "detail": "aucun relevé reçu par EBS en base", "vu_le": None}
    return {"etat": "ok", "vu_le": _date_fr(r["date_max"]),
            "detail": f"{r['nb_releves'] or 0} relevé(s), {r['nb_lignes'] or 0} ligne(s) au dernier fichier reçu"}


def etat_flux(con: sqlite3.Connection, fiche: dict) -> dict:
    """État d'un flux d'après sa source d'état : Ctrl Flux (motif), virements, prélèvements ou relevés."""
    if str(fiche.get("statut") or "Actif") == "Inactif":
        return {"etat": "inactif", "detail": "flux déclaré inactif", "vu_le": None}
    source = str(fiche.get("source_etat") or "").strip()
    motif = str(fiche.get("motif") or "").strip()
    if source == "virements":
        return _etat_virements(con)
    if source == "prelevements":
        return _etat_prelevements(con)
    if source == "releves":
        return _etat_releves(con)
    if motif:
        return _etat_ctrl_flux(con, motif)
    return {"etat": "inconnu", "detail": "aucun motif ni source d'état : rien à suivre pour l'instant", "vu_le": None}


COLS_VOLUME = list(VIDE)


def carte(con: sqlite3.Connection) -> pd.DataFrame:
    """Tous les flux du référentiel avec leur état, leur volumétrie Ctrl Flux et leurs interlocuteurs."""
    f = fx.flux(con)
    if f.empty:
        return pd.DataFrame(columns=fx.COLS_FLUX + ["libelle", "etat", "etat_libelle", "detail", "vu_le",
                                                     "nb_interlocuteurs"] + COLS_VOLUME)
    inter = fx.interlocuteurs(con).groupby("code").size() if not f.empty else pd.Series(dtype=int)
    lignes = []
    for fiche in f.to_dict("records"):
        e = etat_flux(con, fiche)
        lignes.append({**fiche, "libelle": fx.libelle(fiche), "etat": e["etat"],
                       "etat_libelle": LIBELLES_ETAT[e["etat"]], "detail": e["detail"],
                       "vu_le": _jjmm(e.get("vu_le")), "nb_interlocuteurs": int(inter.get(fiche["code"], 0)),
                       **{c: e.get(c, VIDE[c]) for c in COLS_VOLUME}})
    return pd.DataFrame(lignes)


# ------------------------------------------------------------------ diagramme

def sankey(df: pd.DataFrame) -> dict:
    """Nœuds et liens du diagramme : applications entrantes → Oracle → applications sortantes.
    Une même application peut être des deux côtés (CELERIS envoie et reçoit) : deux nœuds distincts."""
    noeuds, index = [], {}

    def noeud(cle, label, couleur):
        if cle not in index:
            index[cle] = len(noeuds)
            noeuds.append({"cle": cle, "label": label, "couleur": couleur})
        return index[cle]

    entrants = df[df["sens"] == "entrant"].sort_values(["domaine", "application"])
    sortants = df[df["sens"] == "sortant"].sort_values(["domaine", "application"])
    for _, r in entrants.iterrows():
        noeud(f"in:{r['application']}", f"{r['application']} · {r['nom_application'] or ''}".strip(" ·"),
              COULEURS_DOMAINE.get(r["domaine"], COULEURS_DOMAINE["INCONNU"]))
    centre = noeud("oracle", ORACLE, "#FFB20F")
    for _, r in sortants.iterrows():
        noeud(f"out:{r['application']}", f"{r['application']} · {r['nom_application'] or ''}".strip(" ·"),
              COULEURS_DOMAINE.get(r["domaine"], COULEURS_DOMAINE["INCONNU"]))
    liens = []
    for _, r in df.iterrows():
        src, dst = ((index[f"in:{r['application']}"], centre) if r["sens"] == "entrant"
                    else (centre, index[f"out:{r['application']}"]))
        liens.append({"source": src, "cible": dst, "valeur": 1, "code": r["code"], "label": r["objet"],
                      "etat": r["etat"], "couleur": COULEURS_ETAT[r["etat"]],
                      "info": f"{r['objet']} · {r['nature']} · {r['etat_libelle']} · vu le {r['vu_le']}"})
    return {"noeuds": noeuds, "liens": liens}


ORACLE_ID = "ORACLE"


def _eur(v) -> str:
    if v is None or (isinstance(v, float) and pd.isna(v)) or not float(v):
        return ""
    return f"{float(v):,.2f}".replace(",", " ").replace(".", ",") + " €"


def _nb(v) -> str:
    if v is None or (isinstance(v, float) and pd.isna(v)):
        return "—"
    return f"{float(v):,.0f}".replace(",", " ")


def volumetrie(g: pd.DataFrame) -> dict:
    """Cumul Ctrl Flux d'un ensemble de flux : fichiers, folios, pièces, montant amont, écart restant."""
    suivis = g[g["nb_fichiers"].fillna(0) > 0]
    folios = sorted({f.strip() for ligne in suivis["folios"].fillna("") for f in str(ligne).split(",") if f.strip()})
    return {"nb_fichiers": int(suivis["nb_fichiers"].fillna(0).sum()),
            "nb_lignes": int(suivis["nb_lignes"].fillna(0).sum()),
            "nb_pieces": float(suivis["nb_pieces"].fillna(0).sum()),
            "montant": round(float(suivis["montant"].fillna(0).sum()), 2),
            "ecart": round(float(suivis["ecart"].fillna(0).sum()), 2),
            "nb_ecart": int(suivis["nb_ecart"].fillna(0).sum()),
            "folios": folios, "suivis": len(suivis)}


def _detail_types(g: pd.DataFrame) -> list[str]:
    """Une ligne par type de flux (FOURNISSEURS / CLIENTS / GL / AUTRE) : flux, fichiers, pièces, montant."""
    out = []
    for typ, sous in g.groupby("type_flux"):
        v = volumetrie(sous)
        morceaux = [f"{len(sous)} flux"]
        if v["suivis"]:
            morceaux.append(f"{v['nb_fichiers']} fichier(s)")
            if v["folios"]:
                morceaux.append(f"{len(v['folios'])} folio(s)")
            if v["nb_pieces"]:
                morceaux.append(f"{_nb(v['nb_pieces'])} pièces")
            if v["montant"]:
                morceaux.append(_eur(v["montant"]))
            if v["nb_ecart"]:
                morceaux.append(f"⚠ {_eur(v['ecart'])} d'écart")
        out.append(f"  {typ or 'AUTRE'} : " + " · ".join(morceaux))
    return out


def _titre_noeud(app: str, nom: str, domaine: str, g: pd.DataFrame) -> str:
    """Infobulle d'un nœud : domaine, états, détail par type de flux, folios et motifs des fichiers."""
    etats = " · ".join(f"{LIBELLES_ETAT[e]} {n}" for e, n in g["etat"].value_counts().items())
    v = volumetrie(g)
    lignes = [f"{app} · {nom}".strip(" ·"), domaine, f"{len(g)} flux : {etats}"]
    lignes += _detail_types(g)
    if v["folios"]:
        lignes.append("Folios : " + ", ".join(v["folios"][:14]) + ("…" if len(v["folios"]) > 14 else ""))
    motifs = sorted({m for m in g["motif"].fillna("") if str(m).strip()})
    if motifs:
        lignes.append("Motifs : " + " | ".join(motifs[:6]) + ("…" if len(motifs) > 6 else ""))
    derniers = sorted({d for d in g.get("dernier_fichier", pd.Series(dtype=str)).fillna("") if str(d).strip()})
    if derniers:
        lignes.append("Dernier fichier : " + derniers[-1])
    return "\n".join(lignes)


def _titre_lien(r) -> str:
    """Infobulle d'un lien : le flux, son état, son motif et sa volumétrie Ctrl Flux."""
    lignes = [fx.libelle(r), f"{r['nature']} · {r['etat_libelle']} · vu le {r['vu_le']}"]
    if str(r.get("type_flux") or "").strip():
        lignes[0] += f"  [{r['type_flux']}]"
    if str(r.get("motif") or "").strip():
        lignes.append(f"Motif : {r['motif']}")
    if float(r.get("nb_fichiers") or 0):
        morceaux = [f"{_nb(r['nb_fichiers'])} fichier(s)", f"{_nb(r['nb_lignes'])} ligne(s)"]
        if r.get("nb_folios"):
            morceaux.append(f"{_nb(r['nb_folios'])} folio(s)")
        if r.get("nb_pieces"):
            morceaux.append(f"{_nb(r['nb_pieces'])} pièces")
        if r.get("montant"):
            morceaux.append(_eur(r["montant"]))
        lignes.append(" · ".join(morceaux))
        if str(r.get("folios") or "").strip():
            lignes.append(f"Folios : {r['folios']}")
        if str(r.get("dernier_fichier") or "").strip():
            lignes.append(f"Dernier : {r['dernier_fichier']}")
    lignes.append(r["detail"])
    return "\n".join(lignes)


def graphe(df: pd.DataFrame, par_type: bool = False) -> dict:
    """Nœuds et liens du graphe façon Neo4j : Oracle Finance au centre, un nœud par application — ou par
    application et type de flux (fournisseurs, clients, GL) quand `par_type` — et un lien orienté par flux.
    Les nœuds portent la volumétrie Ctrl Flux, les liens d'un même couple s'écartent pour rester visibles."""
    noeuds = [{"id": ORACLE_ID, "label": "Oracle\nFinance", "titre": "FIN01 · ORACLE E-Business Suite",
               "couleur": COULEUR_ORACLE, "bordure": "#122246", "police": "#FFFFFF", "taille": 46,
               "domaine": "FINANCES", "sens": "centre", "x": 0, "y": 0}]
    if df.empty:
        return {"noeuds": noeuds, "liens": []}
    df = df.copy()
    df["_cle"] = (df["application"] + " · " + df["type_flux"].fillna("AUTRE")) if par_type else df["application"]
    groupes = df.groupby("_cle")
    entrants = sorted(a for a, g in groupes if (g["sens"] == "entrant").any() and not (g["sens"] == "sortant").any())
    sortants = sorted(a for a, g in groupes if (g["sens"] == "sortant").any() and not (g["sens"] == "entrant").any())
    mixtes = sorted(a for a, g in groupes if (g["sens"] == "entrant").any() and (g["sens"] == "sortant").any())

    def position(liste, x, ecart=110):
        return {a: (x, (i - (len(liste) - 1) / 2) * ecart) for i, a in enumerate(liste)}

    positions = {**position(entrants, -520), **position(sortants, 520),
                 **{a: ((i - (len(mixtes) - 1) / 2) * 180, -420 if i % 2 == 0 else 420) for i, a in enumerate(mixtes)}}
    for cle, g in groupes:
        app = str(g["application"].iloc[0])
        # une application déclarée par le schéma et par un fichier inconnu garde le domaine du schéma
        connus = [d for d in g["domaine"].tolist() if d and d != "INCONNU"]
        domaine = max(set(connus), key=connus.count) if connus else "INCONNU"
        noms = [n for n in g["nom_application"].tolist() if n]
        nom = str(noms[0] if noms else "")
        v = volumetrie(g)
        typ = str(g["type_flux"].iloc[0] or "AUTRE") if par_type else ""
        etiquette = f"{app} · {typ}" if par_type else (f"{app}\n{nom}" if nom else app)
        if v["suivis"]:
            etiquette += f"\n{_nb(v['nb_pieces'])} pièces" if v["nb_pieces"] else f"\n{v['nb_fichiers']} fichier(s)"
        sens = "mixte" if cle in mixtes else ("entrant" if cle in entrants else "sortant")
        x, y = positions[cle]
        noeuds.append({"id": cle, "label": etiquette, "titre": _titre_noeud(app, nom, domaine, g),
                       "couleur": COULEURS_DOMAINE.get(domaine, COULEURS_DOMAINE["INCONNU"]),
                       "bordure": "#FFFFFF", "police": "#1F2937", "taille": 18 + 3 * len(g),
                       "domaine": domaine, "sens": sens, "x": x, "y": y,
                       "application": app, "type_flux": typ, "nb_fichiers": v["nb_fichiers"],
                       "nb_pieces": v["nb_pieces"], "montant": v["montant"], "ecart": v["ecart"],
                       "folios": v["folios"]})
    liens, compteur = [], {}
    for _, r in df.iterrows():
        de, vers = (r["_cle"], ORACLE_ID) if r["sens"] == "entrant" else (ORACLE_ID, r["_cle"])
        k = compteur[(de, vers)] = compteur.get((de, vers), -1) + 1
        liens.append({"de": de, "vers": vers, "code": r["code"], "objet": r["objet"], "etat": r["etat"],
                      "nature": r["nature"], "type_flux": r["type_flux"], "motif": r["motif"],
                      "couleur": COULEURS_ETAT[r["etat"]],
                      "largeur": 3 if r["etat"] == "ecart" else 2 if r["etat"] == "ok" else 1.4,
                      "tirets": TIRETS_NATURE.get(r["nature"], [10, 4, 2, 4]), "roundness": 0.08 + 0.13 * k,
                      "titre": _titre_lien(r)})
    return {"noeuds": noeuds, "liens": liens}


def resume(df: pd.DataFrame) -> dict:
    """Compteurs pour les tuiles."""
    if df.empty:
        return {"flux": 0, "entrants": 0, "sortants": 0, "ok": 0, "ecart": 0, "inconnu": 0, "inactif": 0,
                "applications": 0, "suivis": 0}
    return {"flux": len(df), "entrants": int((df["sens"] == "entrant").sum()),
            "sortants": int((df["sens"] == "sortant").sum()),
            **{e: int((df["etat"] == e).sum()) for e in ETATS},
            "applications": int(df["application"].nunique()),
            "suivis": int((df["etat"].isin(["ok", "ecart"])).sum())}
