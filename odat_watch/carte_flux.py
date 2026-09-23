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
COULEURS_ETAT = {"ok": "#1F9D55", "ecart": "#D9A400", "inconnu": "#B8C0CC", "inactif": "#E5E7EB"}
COULEURS_DOMAINE = {"REFERENTIEL": "#0F57C7", "OPERATION": "#FF5717", "MARKETING, COMMERCE & RELATION CLIENTS": "#4F9E30",
                    "RESSOURCES HUMAINES": "#70A8DB", "FINANCES": "#FFB20F",
                    "JURIDIQUE, RISQUE, COMMUNICATION & PILOTAGE": "#0F8AFF", "PARTENAIRES EXTERNES": "#141414",
                    "APPLICATION SYSTEME D'INFORMATION": "#B8B8B8", "DECOMMISSIONNEE": "#666666", "INCONNU": "#DDDDDD"}


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

def _etat_ctrl_flux(con, motif: str) -> dict:
    lignes = pd.read_sql_query(
        "SELECT fichier, folio, date, ecart_debit, ecart_nb, rapproche FROM ("
        "  SELECT l.fichier, l.folio, l.date, l.ecart_debit, l.ecart_nb, "
        "         EXISTS (SELECT 1 FROM fr_rapprochement_lignes rl JOIN fr_rapprochements r ON r.id = rl.rapprochement_id "
        "                 WHERE rl.empreinte = l.empreinte AND r.annule_le IS NULL) AS rapproche "
        "  FROM fr_lignes l WHERE l.present = 1 AND l.fichier IS NOT NULL)", con)
    if not lignes.empty:
        lignes = lignes[[fx.reconnait(motif, f) for f in lignes["fichier"]]]
    if lignes.empty:
        return {"etat": "inconnu", "detail": "aucun fichier transmis connu pour ce motif", "vu_le": None,
                "nb_fichiers": 0, "ecart": None, "nb_lignes": 0}
    dates = [d for d in (_date_fr(x) for x in lignes["date"]) if d]
    ouvertes = lignes[~lignes["rapproche"].astype(bool)]
    ecart = round(float(ouvertes["ecart_debit"].fillna(0).sum()), 2)
    nb_ecart = int((ouvertes["ecart_debit"].fillna(0).abs() >= TOL).sum())
    if nb_ecart:
        etat, detail = "ecart", f"{nb_ecart} ligne(s) en écart, {ecart:,.2f} € manquant(s) au SI Finance".replace(",", " ")
    else:
        etat, detail = "ok", "amont et SI Finance à l'équilibre sur toutes les lignes"
    return {"etat": etat, "detail": detail, "vu_le": max(dates) if dates else None,
            "nb_fichiers": int(lignes["fichier"].nunique()), "ecart": ecart, "nb_lignes": len(lignes)}


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


def carte(con: sqlite3.Connection) -> pd.DataFrame:
    """Tous les flux du référentiel avec leur état, leur libellé et leur nombre d'interlocuteurs."""
    f = fx.flux(con)
    if f.empty:
        return pd.DataFrame(columns=fx.COLS_FLUX + ["libelle", "etat", "etat_libelle", "detail", "vu_le",
                                                     "nb_interlocuteurs"])
    inter = fx.interlocuteurs(con).groupby("code").size() if not f.empty else pd.Series(dtype=int)
    lignes = []
    for fiche in f.to_dict("records"):
        e = etat_flux(con, fiche)
        lignes.append({**fiche, "libelle": fx.libelle(fiche), "etat": e["etat"],
                       "etat_libelle": LIBELLES_ETAT[e["etat"]], "detail": e["detail"],
                       "vu_le": _jjmm(e.get("vu_le")), "nb_interlocuteurs": int(inter.get(fiche["code"], 0))})
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
