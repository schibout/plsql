# Onglet Prélèvements dans ODAT Watch — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** ajouter un onglet « 💳 Prélèvements » à ODAT Watch qui lance le rapprochement Oracle ↔ EDF par clé métier (outil `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapprochement_cle_metier.py`) et affiche son résultat, exactement sur le modèle de l'onglet Virements (patron « pont »).

**Architecture :** le contrôle reste dans son dossier et garde sa ligne de commande ; on lui ajoute une fonction `executer()` importable qui écrit, à côté du classeur et des deux CSV, un petit `_resume.json` (contexte, compteurs par statut, avertissements, code retour). Dans `odat_watch`, un module pur `prelevements.py` (config `[prelevements]`, lancement, relecture du dernier rapport, chiffres des tuiles) et un module `ui_prelevements.py` (Streamlit), branchés dans `app.py`. Aucune table SQLite : tout est relu depuis `rapport/`, comme pour les virements.

**Tech stack :** Python 3.13, stdlib + openpyxl (outil), pandas + Streamlit + `streamlit.testing.v1.AppTest` (ODAT Watch), pytest.

---

## Décisions de conception (validées par l'exploration du 21/09/2026)

| Sujet | Décision | Pourquoi |
|---|---|---|
| Quel outil brancher | **Uniquement `rapprochement_cle_metier.py`** (clé IBAN créancier × échéance, 10 statuts). Pas le rapprochement journalier `prelevements_rapprochement.py`. | C'est l'outil de référence ; l'autre repose sur la règle J+2/J+4 reconnue comme fausse et donne des verdicts contradictoires (README écart 589). |
| Mode de lancement | Import en process (`sys.path.insert` + `import rapprochement_cle_metier`), comme `virements.py` fait avec `controle_virements`. | Même patron, pas de sous-processus, exceptions remontées dans l'UI. |
| Paramètres exposés dans l'onglet | Date de référence (défaut aujourd'hui) et profondeur en jours (défaut `config.ini`, 10). | Ce sont les deux seuls paramètres métier de l'outil ; le reste (dossiers, motifs) va dans `config.ini`. |
| Notion de « journée » | Il n'y a pas de dossier par jour comme pour les virements : un rapport est une **photo à une date de référence**. L'onglet liste les dates de référence déjà contrôlées (fichiers `Rapprochement_Cle_Metier_<AAAAMMJJ>_*`) et affiche le **plus récent** rapport de la date choisie. | Reflète le nommage existant des sorties. |
| Résumé structuré | `executer()` écrit `<base>_resume.json`. | Les CSV ne portent ni les avertissements, ni les lignes Oracle non conformes, ni le contexte : sans ce fichier, l'UI ne peut pas afficher le statut global sans relancer. |
| Statut global (tuile) | `ERREUR` si lignes Oracle non conformes (code 2) · `DÉGRADÉ` si avertissements (code 3) · `ANOMALIES` si statuts NON_RECU / ECART_PARTIEL / EDF_SANS_ORACLE (code 1) · `OK` sinon. | Reprend exactement les codes retour de `main()`. |
| Hors périmètre de ce plan | Historisation SQLite / tendance, planification automatique, fusion des deux outils, retrait du PowerShell, sortie des données de prod de git. | YAGNI pour l'onglet ; listés en « suites possibles » en fin de plan, à décider séparément. |

**Fichiers**

| Action | Fichier | Rôle |
|---|---|---|
| Modifier | `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapprochement_cle_metier.py` | `executer()` importable + `_resume.json` ; `main()` s'appuie dessus. |
| Modifier | `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/tests/test_rapprochement_cle_metier.py` | Tests d'`executer()`. |
| Créer | `odat_watch/prelevements.py` | Pont : config, dates disponibles, lancer, lire_rapport, resume. |
| Créer | `odat_watch/tests/test_prelevements.py` | Tests unitaires du pont (jeu de données minimal en `tmp_path`). |
| Créer | `odat_watch/ui_prelevements.py` | Onglet Streamlit. |
| Créer | `odat_watch/tests/test_ui_prelevements.py` | AppTest de l'onglet. |
| Modifier | `odat_watch/app.py:309-344` | Nouvel onglet après Virements. |
| Modifier | `odat_watch/config.ini.exemple` | Section `[prelevements]`. |
| Modifier | `odat_watch/README.md:32` | Ligne du tableau « Contenu ». |
| Modifier | `.gitignore` | Ignorer `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapport/`, réparer la ligne corrompue. |

Convention de commit : messages en français, préfixe `ODAT Watch : Prélèvements — …` ou `Contrôle prélèvements : …`, dernière ligne `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

Toutes les commandes ci-dessous se lancent depuis `C:\Users\samir.chibout\Documents\Project\plsql` (PowerShell).

---

### Task 1 : `executer()` importable dans l'outil clé métier

**Files:**
- Modify: `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapprochement_cle_metier.py:979-1049` (`main`)
- Test: `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/tests/test_rapprochement_cle_metier.py`

- [ ] **Step 1 : écrire le test qui échoue**

Ajouter en fin de `tests/test_rapprochement_cle_metier.py` (le fichier fait déjà `sys.path.insert(0, parent.parent)` et importe le module sous le nom `rcm` ; vérifier l'alias en tête de fichier et l'adapter si besoin) :

```python
def _jeu_minimal(tmp_path):
    """Un fichier Oracle PCL (1 prélèvement, échéance 30/09/2026) et un état EDF qui le confirme."""
    oracle = tmp_path / "ORACLE" / "20260910"
    oracle.mkdir(parents=True)
    entetes = ["TRANSACTIONDATE", "AMOUNT", "ENTITYBANKACCOUNTNUMBER", "CUSTOMERNAME",
               "MANDATEREFERENCE", "CUSTOMERBANKACCOUNTNUMBER"]
    entetes += [f"C{i}" for i in range(len(entetes), 55)]
    ligne = ["09/30/2026", "100.00", "FR7630003000000000000000001", "CLIENT A",
             "RUM1", "FR7630003000000000000000002"] + [""] * 49
    (oracle / "DKA-20260911-1_PCLFRST.txt").write_text(
        "HEADER,x\n" + ",".join(entetes) + "\n" + ",".join(ligne) + "\n", encoding="utf-8")
    edf = tmp_path / "EDF"
    (edf / "REJETS").mkdir(parents=True)
    (edf / "IMPORT_AVP_DK.20260913.070000.csv").write_text(
        "NOM DU SI DALKIA;IBAN CREANCIER;DATE D'ECHEANCE;NOMBRE;MONTANT;\n"
        "ORACLE;FR7630003000000000000000001;30/09/2026;1;100,00;\n", encoding="utf-8")
    return tmp_path


def test_executer_ecrit_les_quatre_fichiers_et_le_resume(tmp_path):
    racine = _jeu_minimal(tmp_path)
    res = rcm.executer(reference="2026-09-14", racine=racine, jours=10)
    assert res["code"] == 0 and res["statut_global"] == "OK"
    assert res["par_statut"]["RAPPROCHE"]["cles"] == 1
    dossier = racine / "rapport"
    for suffixe in (".xlsx", ".csv", "_justifications.csv", "_resume.json"):
        assert (dossier / (res["base"] + suffixe)).is_file(), suffixe
    resume = json.loads((dossier / (res["base"] + "_resume.json")).read_text(encoding="utf-8"))
    assert resume["reference"] == "2026-09-14" and resume["statut_global"] == "OK"
    assert resume["contexte"]["Lignes Oracle"] == 1 and resume["avertissements"] == []


def test_executer_statut_degrade_sans_fichier_edf(tmp_path):
    racine = _jeu_minimal(tmp_path)
    (racine / "EDF" / "IMPORT_AVP_DK.20260913.070000.csv").unlink()
    res = rcm.executer(reference="2026-09-14", racine=racine, jours=10)
    assert res["code"] == 3 and res["statut_global"] == "DEGRADE"
    assert any("Aucun fichier EDF" in a for a in res["avertissements"])


def test_executer_leve_sur_racine_absente(tmp_path):
    with pytest.raises(rcm.ErreurTraitement):
        rcm.executer(reference="2026-09-14", racine=tmp_path / "nulle_part", jours=10)
```

Ajouter `import json` et `import pytest` en tête du fichier de test s'ils manquent. Si les noms de colonnes requis diffèrent de ceux ci-dessus, prendre exactement `COLONNES_REQUISES` (`rapprochement_cle_metier.py:52-54`) et le format du fichier attendu par `charger_oracle` (`:255-341`) ; s'inspirer du jeu de données des tests existants du même fichier plutôt que d'en inventer un.

- [ ] **Step 2 : vérifier que le test échoue**

```powershell
cd CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS; python -m pytest tests/test_rapprochement_cle_metier.py -k executer -v; cd ..
```
Attendu : 3 FAILED avec `AttributeError: module ... has no attribute 'executer'`.

- [ ] **Step 3 : implémenter `executer()` et faire reposer `main()` dessus**

Remplacer le corps de `main()` (`rapprochement_cle_metier.py:979-1049`) par :

```python
STATUT_GLOBAL_PAR_CODE = {0: "OK", 1: "ANOMALIES", 2: "ERREUR", 3: "DEGRADE"}


def executer(reference=None, racine=None, sortie=None, jours=10, nom_si="ORACLE",
             dossier_oracle="ORACLE", dossier_edf="EDF",
             motifs_oracle=("*PCX*", "*PCL*"), motif_edf="IMPORT_AVP_DK.*.*.csv",
             motif_rejets="REJETS_INTERNES_DK.*.csv"):
    """Lance le rapprochement et ecrit rapport/<base>.xlsx, .csv, _justifications.csv, _resume.json.

    Retourne un dict : code (0 OK, 1 anomalies, 2 lignes Oracle non conformes, 3 degrade),
    statut_global, base (nom des fichiers sans extension), dossier (Path), reference (date),
    par_statut {statut: {cles, nb, montant}}, nb_anomalies, nb_signales, nb_a_investiguer,
    nb_lignes_ko, avertissements (list[str]), contexte (dict).
    Leve ErreurTraitement (racine absente, date invalide) et OSError."""
    args = argparse.Namespace(
        racine=Path(racine) if racine else Path(__file__).resolve().parent,
        sortie=Path(sortie) if sortie else None, date=reference, jours=int(jours),
        dossier_oracle=dossier_oracle, dossier_edf=dossier_edf,
        motifs_oracle=list(motifs_oracle), motif_edf=motif_edf,
        motif_rejets=motif_rejets, nom_si=nom_si)
    diag = Diagnostic()
    rapprochement, rejets, lignes_ko, contexte, reference = analyser(args, diag)

    # Les rapports sont toujours regroupes dans un sous-dossier dedie : ils
    # ne se melangent jamais aux fichiers sources analyses.
    dossier = (args.sortie or args.racine).resolve() / DOSSIER_RAPPORT
    dossier.mkdir(parents=True, exist_ok=True)
    base = f"Rapprochement_Cle_Metier_{reference.strftime('%Y%m%d')}_" \
           f"{datetime.now().strftime('%H%M%S')}"

    resume = {}
    for r in rapprochement:
        e = resume.setdefault(r["statut"], {"cles": 0, "nb": 0, "montant": Decimal(0)})
        e["cles"] += 1
        e["nb"] += r["nb_oracle"] or r["nb_edf"]
        e["montant"] += r["montant_oracle"] or r["montant_edf"]
    justifications = construire_justifications(rapprochement)

    print("Génération du rapport...")
    generer_classeur(dossier / f"{base}.xlsx", rapprochement, rejets,
                     lignes_ko, resume, contexte, justifications)
    generer_csv(dossier / f"{base}.csv", rapprochement)
    generer_csv_justifications(dossier / f"{base}_justifications.csv", justifications)

    anomalies = sum(1 for r in rapprochement if r["statut"] in STATUTS_ANOMALIE)
    signales = sum(1 for r in rapprochement if r["statut"] in STATUTS_SIGNALES)
    a_investiguer = sum(1 for j in justifications if j["cause"] in CAUSES_A_INVESTIGUER)
    code = 2 if lignes_ko else 3 if diag.avertissements else 1 if anomalies else 0

    res = {
        "code": code, "statut_global": STATUT_GLOBAL_PAR_CODE[code],
        "base": base, "dossier": dossier, "reference": reference,
        "par_statut": {s: {"cles": e["cles"], "nb": e["nb"], "montant": e["montant"]}
                       for s, e in resume.items()},
        "nb_anomalies": anomalies, "nb_signales": signales, "nb_a_investiguer": a_investiguer,
        "nb_lignes_ko": len(lignes_ko), "avertissements": list(diag.avertissements),
        "contexte": {k: v for k, v in contexte},
    }
    serialisable = dict(res, dossier=str(dossier), reference=reference.isoformat(),
                        par_statut={s: dict(e, montant=str(e["montant"])) for s, e in res["par_statut"].items()},
                        genere_le=datetime.now().isoformat(timespec="seconds"))
    temporaire = dossier / f"{base}_resume.tmp.json"
    temporaire.write_text(json.dumps(serialisable, ensure_ascii=False, indent=2), encoding="utf-8")
    os.replace(temporaire, dossier / f"{base}_resume.json")
    return res


def main(argv=None):
    args = construire_parser().parse_args(argv)
    try:
        res = executer(reference=args.date, racine=args.racine, sortie=args.sortie, jours=args.jours,
                       nom_si=args.nom_si, dossier_oracle=args.dossier_oracle, dossier_edf=args.dossier_edf,
                       motifs_oracle=args.motifs_oracle, motif_edf=args.motif_edf,
                       motif_rejets=args.motif_rejets)
    except ErreurTraitement as exc:
        print(f"Erreur critique : {exc}", file=sys.stderr)
        return 2
    except OSError as exc:
        print(f"Erreur d'acces fichier : {exc}", file=sys.stderr)
        return 2

    print("\n=======================================================")
    print(f" Rapport : {res['dossier'] / (res['base'] + '.xlsx')}")
    for statut in ORDRE_STATUTS:
        if statut in res["par_statut"]:
            print(f"   {res['par_statut'][statut]['cles']:5}  {statut}")
    print("-------------------------------------------------------")
    if res["nb_a_investiguer"] or res["nb_anomalies"] or res["nb_signales"]:
        print(f" {res['nb_a_investiguer']} écart(s) à investiguer — détail : onglet « Justification des écarts ».")
    if res["nb_lignes_ko"]:
        print(f" {res['nb_lignes_ko']} ligne(s) Oracle non conforme(s) — résultat non fiable.")
    if res["nb_signales"]:
        print(f" {res['nb_signales']} clé(s) à signaler au métier.")
    if res["nb_anomalies"]:
        print(f" {res['nb_anomalies']} ANOMALIE(S) à traiter.")
    else:
        print(" Aucune anomalie : tout est rapproché ou expliqué.")
    if res["avertissements"]:
        print(f" {len(res['avertissements'])} avertissement(s) — exécution dégradée.")
    print("=======================================================")
    return res["code"]
```

Ajouter `import json` et `import os` en tête du module s'ils manquent (`os` est déjà utilisé par `os.replace`). Le bloc `if __name__ == "__main__": sys.exit(main())` reste inchangé.

- [ ] **Step 4 : lancer toute la suite de l'outil**

```powershell
cd CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS; python -m pytest tests -q; cd ..
```
Attendu : 27 + 18 + 3 = 48 passed.

- [ ] **Step 5 : vérifier que la ligne de commande fonctionne toujours sur les vraies données**

```powershell
cd CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS; python rapprochement_cle_metier.py --date 2026-09-15 --jours 10; echo "code=$LASTEXITCODE"; cd ..
Get-ChildItem CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS\rapport\Rapprochement_Cle_Metier_20260915_* | Select-Object Name
```
Attendu : code 0, 1 ou 3 (selon les données), et quatre fichiers avec le même horodatage dont `_resume.json`.

- [ ] **Step 6 : commit**

```powershell
git add CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapprochement_cle_metier.py CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/tests/test_rapprochement_cle_metier.py
git commit -m "Contrôle prélèvements : executer() importable, résumé JSON à côté du classeur (contexte, statuts, avertissements, code retour)" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2 : module pont `odat_watch/prelevements.py`

**Files:**
- Create: `odat_watch/prelevements.py`
- Create: `odat_watch/tests/test_prelevements.py`

- [ ] **Step 1 : écrire les tests qui échouent**

`odat_watch/tests/test_prelevements.py` :

```python
"""Pont Prélèvements : config, dates disponibles, relecture du dernier rapport, chiffres des tuiles."""
import json
from datetime import date
from pathlib import Path

import pandas as pd
import pytest

import prelevements as pv


def _rapport(dossier: Path, base: str, statut_global="OK", par_statut=None, avertissements=(), lignes_ko=0):
    dossier.mkdir(parents=True, exist_ok=True)
    (dossier / f"{base}.csv").write_text(
        "iban_creancier;echeance;nb_oracle;montant_oracle;nb_edf;montant_edf;ecart_nb;ecart_montant;"
        "nb_rejets;montant_rejets;codes_rejets;statut;emissions;tranches_edf\n"
        "FR76A;30/09/2026;589;2780219.23;0;0;589;2780219.23;0;0;;EN_ATTENTE;10/09/2026;\n"
        "FR76B;15/09/2026;3;300.00;3;300.00;0;0;0;0;;RAPPROCHE;01/09/2026;03/09:3\n",
        encoding="utf-8-sig")
    (dossier / f"{base}_justifications.csv").write_text(
        "echeance;iban_creancier;cause;nb;montant;beneficiaire;rum;iban_debiteur;code;motif;emission;"
        "fichier_oracle;fichier_rejet;fichier_edf;statut_cle;ecart_nb_cle;ecart_montant_cle\n"
        "30/09/2026;FR76A;INEXPLIQUE;589;2780219.23;;;;;;10/09/2026;DKA-20260910-1_PCLFRST.txt;;;EN_ATTENTE;589;2780219.23\n",
        encoding="utf-8-sig")
    (dossier / f"{base}.xlsx").write_bytes(b"PK")
    (dossier / f"{base}_resume.json").write_text(json.dumps({
        "code": {"OK": 0, "ANOMALIES": 1, "ERREUR": 2, "DEGRADE": 3}[statut_global],
        "statut_global": statut_global, "base": base, "dossier": str(dossier),
        "reference": "2026-09-14", "genere_le": "2026-09-14T08:14:00",
        "par_statut": par_statut or {"RAPPROCHE": {"cles": 1, "nb": 3, "montant": "300.00"},
                                     "EN_ATTENTE": {"cles": 1, "nb": 589, "montant": "2780219.23"}},
        "nb_anomalies": 0, "nb_signales": 0, "nb_a_investiguer": 1, "nb_lignes_ko": lignes_ko,
        "avertissements": list(avertissements),
        "contexte": {"Lignes Oracle": 592, "Lignes EDF": 3, "Rejets retenus": 0, "Clés rapprochées": 2},
    }), encoding="utf-8")


def test_config_par_defaut_sans_section(monkeypatch, tmp_path):
    monkeypatch.setattr(pv, "CONFIG", tmp_path / "absent.ini")
    cfg = pv.config_prelevements()
    assert cfg["racine"].name == "CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS"
    assert cfg["jours"] == 10 and cfg["nom_si"] == "ORACLE"


def test_config_lue_depuis_config_ini(monkeypatch, tmp_path):
    ini = tmp_path / "config.ini"
    ini.write_text("[prelevements]\nracine = C:\\outil\njours = 15\nnom_si = CIF\n", encoding="utf-8")
    monkeypatch.setattr(pv, "CONFIG", ini)
    cfg = pv.config_prelevements()
    assert cfg["racine"] == Path(r"C:\outil") and cfg["jours"] == 15 and cfg["nom_si"] == "CIF"


def test_dates_disponibles_les_plus_recentes_d_abord(tmp_path):
    r = tmp_path / "rapport"
    _rapport(r, "Rapprochement_Cle_Metier_20260806_120000")
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400")
    _rapport(r, "Rapprochement_Cle_Metier_20260914_093000")
    assert pv.dates_disponibles(tmp_path) == [date(2026, 9, 14), date(2026, 8, 6)]


def test_dates_disponibles_sans_dossier(tmp_path):
    assert pv.dates_disponibles(tmp_path) == []


def test_lire_rapport_prend_le_plus_recent_de_la_date(tmp_path):
    r = tmp_path / "rapport"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400", statut_global="ANOMALIES")
    _rapport(r, "Rapprochement_Cle_Metier_20260914_093000")
    rapport = pv.lire_rapport(tmp_path, date(2026, 9, 14))
    assert rapport["base"].endswith("_093000") and rapport["resume"]["statut_global"] == "OK"
    assert list(rapport["rapprochement"]["statut"]) == ["EN_ATTENTE", "RAPPROCHE"]
    assert len(rapport["justifications"]) == 1 and rapport["xlsx"].is_file()


def test_lire_rapport_absent(tmp_path):
    assert pv.lire_rapport(tmp_path, date(2026, 9, 14)) is None


def test_lire_rapport_sans_resume_json_reste_lisible(tmp_path):
    """Rapports produits avant executer() : pas de _resume.json → statut global INCONNU, tables lues quand même."""
    r = tmp_path / "rapport"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400")
    (r / "Rapprochement_Cle_Metier_20260914_081400_resume.json").unlink()
    rapport = pv.lire_rapport(tmp_path, date(2026, 9, 14))
    assert rapport["resume"]["statut_global"] == "INCONNU" and len(rapport["rapprochement"]) == 2


def test_resume_chiffres_des_tuiles(tmp_path):
    r = tmp_path / "rapport"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400", avertissements=["Aucun fichier EDF depuis 2026-09-11 (3 jours)"])
    res = pv.resume(pv.lire_rapport(tmp_path, date(2026, 9, 14)))
    assert res["statut_global"] == "OK" and res["nb_cles"] == 2
    assert res["nb_emis"] == 592 and round(res["montant_emis"], 2) == 2780519.23
    assert res["en_attente"] == 1 and res["anomalies"] == 0 and res["signales"] == 0
    assert res["a_investiguer"] == 1 and res["avertissements"] == 1


def test_par_statut_respecte_l_ordre_metier(tmp_path):
    r = tmp_path / "rapport"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400")
    groupes = pv.par_statut(pv.lire_rapport(tmp_path, date(2026, 9, 14))["rapprochement"])
    assert [s for s, _ in groupes] == ["RAPPROCHE", "EN_ATTENTE"]
    assert len(groupes[1][1]) == 1
```

- [ ] **Step 2 : vérifier que les tests échouent**

```powershell
cd odat_watch; python -m pytest tests/test_prelevements.py -q; cd ..
```
Attendu : erreur de collecte `ModuleNotFoundError: No module named 'prelevements'`.

- [ ] **Step 3 : écrire `odat_watch/prelevements.py`**

```python
"""Onglet Prélèvements : pont vers l'outil CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS (rapprochement par clé métier).

Le contrôle lui-même vit dans ../CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS (rapprochement_cle_metier.executer) ;
ici on choisit la date de référence, on le lance en local et on relit le dernier rapport de cette date
(rapport/Rapprochement_Cle_Metier_<AAAAMMJJ>_<HHMMSS>.csv, _justifications.csv, _resume.json, .xlsx).
"""
from __future__ import annotations
import configparser
import json
import re
import sys
from datetime import date, datetime
from pathlib import Path

import pandas as pd

from oracle_refresh import BASE_DIR, CONFIG

DEFAUTS = {"racine": r"..\CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS", "jours": "10", "nom_si": "ORACLE"}
DOSSIER_RAPPORT = "rapport"
PREFIXE = "Rapprochement_Cle_Metier_"
RE_BASE = re.compile(rf"{PREFIXE}(\d{{8}})_(\d{{6}})")

# Statuts de l'outil, dans son ordre d'affichage (ORDRE_STATUTS de rapprochement_cle_metier.py)
ORDRE_STATUTS = ["RAPPROCHE", "RAPPROCHE_AVEC_REJET_POSTERIEUR", "EXPLIQUE_PAR_REJET", "REJETE_INTEGRALEMENT",
                 "REJET_PARTIEL_NON_CONFIRME", "EN_ATTENTE", "NON_RECU", "ECART_PARTIEL", "EDF_SANS_ORACLE",
                 "HORS_PERIMETRE_HISTORIQUE"]
STATUTS_ANOMALIE = {"NON_RECU", "ECART_PARTIEL", "EDF_SANS_ORACLE"}
STATUTS_SIGNALES = {"RAPPROCHE_AVEC_REJET_POSTERIEUR", "REJET_PARTIEL_NON_CONFIRME"}
CAUSES_A_INVESTIGUER = {"INEXPLIQUE", "SANS_ORACLE"}
LIBELLES_STATUT = {
    "RAPPROCHE": "Rapproché", "RAPPROCHE_AVEC_REJET_POSTERIEUR": "Rapproché, rejet postérieur",
    "EXPLIQUE_PAR_REJET": "Écart expliqué par rejet", "REJETE_INTEGRALEMENT": "Rejeté intégralement",
    "REJET_PARTIEL_NON_CONFIRME": "Rejet partiel non confirmé", "EN_ATTENTE": "En attente EDF",
    "NON_RECU": "Non reçu par EDF", "ECART_PARTIEL": "Écart partiel", "EDF_SANS_ORACLE": "EDF sans Oracle",
    "HORS_PERIMETRE_HISTORIQUE": "Hors historique Oracle",
}
EXPLICATIONS = {
    "RAPPROCHE": "Nombre et montant identiques de part et d'autre.",
    "RAPPROCHE_AVEC_REJET_POSTERIEUR": "Totaux conformes, mais un rejet est arrivé après la remontée EDF : le prélèvement échouera.",
    "EXPLIQUE_PAR_REJET": "L'écart correspond exactement aux rejets internes.",
    "REJETE_INTEGRALEMENT": "Tous les prélèvements ont été rejetés : EDF ne remonte donc aucune ligne.",
    "REJET_PARTIEL_NON_CONFIRME": "Des rejets existent mais EDF n'a encore rien remonté pour cette clé.",
    "EN_ATTENTE": "Émis, pas encore confirmé par EDF, dans le délai normal.",
    "NON_RECU": "Émis, non confirmé par EDF au-delà du délai normal.",
    "ECART_PARTIEL": "Écart non expliqué par les rejets.",
    "EDF_SANS_ORACLE": "EDF a remonté des prélèvements sans contrepartie Oracle.",
    "HORS_PERIMETRE_HISTORIQUE": "Échéance antérieure à l'historique Oracle disponible : non concluant.",
}
LIBELLES_GLOBAL = {"OK": "✅ OK", "ANOMALIES": "❌ Anomalies", "DEGRADE": "⚠ Dégradé", "ERREUR": "❌ Erreur",
                   "INCONNU": "❔ Inconnu"}
TON_GLOBAL = {"OK": "ok", "ANOMALIES": "err", "DEGRADE": "warn", "ERREUR": "err", "INCONNU": "neutral"}


def _chemin(v: str) -> Path:
    p = Path(v.strip())
    return p if p.is_absolute() else (BASE_DIR / p).resolve()


def config_prelevements() -> dict:
    """Section [prelevements] de config.ini, complétée par les valeurs par défaut."""
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(";", "#"))
    if CONFIG.exists():
        cfg.read(CONFIG, encoding="utf-8")
    val = {k: cfg.get("prelevements", k, fallback=v) for k, v in DEFAUTS.items()}
    return {"racine": _chemin(val["racine"]), "jours": int(val["jours"] or 10), "nom_si": val["nom_si"].strip() or "ORACLE"}


def _bases(racine: Path) -> list[tuple[date, str, str]]:
    """(date de référence, horodatage, base) de chaque rapport présent, du plus récent au plus ancien."""
    out = []
    for f in (Path(racine) / DOSSIER_RAPPORT).glob(f"{PREFIXE}*.csv"):
        m = RE_BASE.fullmatch(f.stem)
        if m:
            out.append((datetime.strptime(m.group(1), "%Y%m%d").date(), m.group(2), f.stem))
    return sorted(out, reverse=True)


def dates_disponibles(racine: Path) -> list[date]:
    """Dates de référence déjà contrôlées, la plus récente en premier."""
    return sorted({d for d, _, _ in _bases(racine)}, reverse=True)


def _outil(racine: Path) -> None:
    """Rend importable rapprochement_cle_metier depuis la racine de l'outil."""
    r = str(Path(racine))
    if r not in sys.path:
        sys.path.insert(0, r)


def lancer(reference: date, cfg: dict) -> dict:
    """Exécute le rapprochement et écrit rapport/<base>.*. Renvoie le dict de rapprochement_cle_metier.executer."""
    _outil(cfg["racine"])
    import rapprochement_cle_metier
    return rapprochement_cle_metier.executer(reference=reference.isoformat(), racine=cfg["racine"],
                                             jours=cfg["jours"], nom_si=cfg["nom_si"])


def _csv(f: Path) -> pd.DataFrame:
    if not f.is_file() or not f.stat().st_size:
        return pd.DataFrame()
    return pd.read_csv(f, sep=";", dtype=str, keep_default_na=False, encoding="utf-8-sig")


def lire_rapport(racine: Path, reference: date) -> dict | None:
    """Relit le rapport le plus récent de la date de référence : rapprochement, justifications, résumé, classeur."""
    candidats = [b for d, _, b in _bases(racine) if d == reference]
    if not candidats:
        return None
    base = candidats[0]
    dossier = Path(racine) / DOSSIER_RAPPORT
    resume_f = dossier / f"{base}_resume.json"
    if resume_f.is_file():
        resume = json.loads(resume_f.read_text(encoding="utf-8"))
    else:   # rapport produit avant executer() : pas de résumé structuré
        resume = {"statut_global": "INCONNU", "par_statut": {}, "avertissements": [], "contexte": {},
                  "nb_lignes_ko": 0, "nb_anomalies": None, "nb_signales": None, "nb_a_investiguer": None}
    rapprochement = _csv(dossier / f"{base}.csv")
    for c in ("nb_oracle", "nb_edf", "ecart_nb", "nb_rejets"):
        if c in rapprochement.columns:
            rapprochement[c] = pd.to_numeric(rapprochement[c], errors="coerce").fillna(0).astype(int)
    for c in ("montant_oracle", "montant_edf", "ecart_montant", "montant_rejets"):
        if c in rapprochement.columns:
            rapprochement[c] = pd.to_numeric(rapprochement[c], errors="coerce").fillna(0.0)
    xlsx = dossier / f"{base}.xlsx"
    return {"base": base, "dossier": dossier, "resume": resume, "rapprochement": rapprochement,
            "justifications": _csv(dossier / f"{base}_justifications.csv"),
            "xlsx": xlsx if xlsx.is_file() else None,
            "genere_le": datetime.fromtimestamp((dossier / f"{base}.csv").stat().st_mtime)}


def resume(rapport: dict) -> dict:
    """Chiffres clés pour les tuiles, calculés depuis les tables (le JSON ne sert qu'au statut global et aux avertissements)."""
    df = rapport["rapprochement"]
    r = rapport["resume"]
    statut = df["statut"] if not df.empty else pd.Series(dtype=str)
    nb_emis = int(df["nb_oracle"].sum()) if not df.empty else 0
    montant = float(df["montant_oracle"].sum()) if not df.empty else 0.0
    just = rapport["justifications"]
    a_investiguer = int(just["cause"].isin(CAUSES_A_INVESTIGUER).sum()) if not just.empty else 0
    return {"statut_global": r.get("statut_global", "INCONNU"), "nb_cles": int(len(df)),
            "nb_emis": nb_emis, "montant_emis": montant,
            "en_attente": int((statut == "EN_ATTENTE").sum()),
            "anomalies": int(statut.isin(STATUTS_ANOMALIE).sum()),
            "signales": int(statut.isin(STATUTS_SIGNALES).sum()),
            "a_investiguer": a_investiguer,
            "avertissements": len(r.get("avertissements", [])),
            "lignes_ko": int(r.get("nb_lignes_ko") or 0)}


def par_statut(df: pd.DataFrame) -> list[tuple[str, pd.DataFrame]]:
    """Groupes non vides du rapprochement, dans l'ordre métier."""
    if df.empty:
        return []
    return [(s, df[df["statut"] == s]) for s in ORDRE_STATUTS if (df["statut"] == s).any()]
```

- [ ] **Step 4 : lancer les tests**

```powershell
cd odat_watch; python -m pytest tests/test_prelevements.py -v; cd ..
```
Attendu : 9 passed.

- [ ] **Step 5 : commit**

```powershell
git add odat_watch/prelevements.py odat_watch/tests/test_prelevements.py
git commit -m "ODAT Watch : Prélèvements — module pont (config [prelevements], dates contrôlées, lancement, relecture du dernier rapport, chiffres des tuiles)" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3 : onglet Streamlit `ui_prelevements.py`

**Files:**
- Create: `odat_watch/ui_prelevements.py`
- Create: `odat_watch/tests/test_ui_prelevements.py`

- [ ] **Step 1 : écrire le test AppTest qui échoue**

`odat_watch/tests/test_ui_prelevements.py` :

```python
"""Onglet Prélèvements via AppTest : lecture d'un rapport fabriqué, tuiles, groupes par statut, message sans rapport."""
from datetime import date
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import prelevements as pv
from tests.test_prelevements import _rapport


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_prelevements

    def faux_kpi(col, valeur, libelle, ton=""):
        assert ton in {"ok", "warn", "err", "run", "neutral", ""}, ton
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_prelevements.render(faux_kpi)


def test_onglet_affiche_le_rapport(monkeypatch, tmp_path):
    _rapport(tmp_path / "rapport", "Rapprochement_Cle_Metier_20260914_081400")
    monkeypatch.setattr(pv, "config_prelevements", lambda: {"racine": tmp_path, "jours": 10, "nom_si": "ORACLE"})
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    texte = "\n".join(m.value for m in at.markdown) + "\n".join(c.value for c in at.caption)
    assert "✅ OK résultat global [ok]" in texte
    assert "592 prélèvements émis" in texte and "1 en attente EDF" in texte
    assert "Rapport généré le" in texte
    labels = [e.label for e in at.expander]
    assert any("Rapproché" in l and "1 clé" in l for l in labels)
    assert any("En attente EDF" in l for l in labels)
    assert any("Justification des écarts" in l for l in labels)


def test_onglet_sans_aucun_rapport(monkeypatch, tmp_path):
    monkeypatch.setattr(pv, "config_prelevements", lambda: {"racine": tmp_path, "jours": 10, "nom_si": "ORACLE"})
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    assert any("Lancer le rapprochement" in c.value for c in at.caption)


def test_onglet_racine_absente(monkeypatch, tmp_path):
    monkeypatch.setattr(pv, "config_prelevements", lambda: {"racine": tmp_path / "nulle_part", "jours": 10, "nom_si": "ORACLE"})
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    assert any("config.ini [prelevements] racine" in c.value for c in at.caption)
```

Note : `from tests.test_prelevements import _rapport` fonctionne parce que `conftest.py` met `odat_watch/` dans `sys.path` ; si pytest refuse l'import (pas de `tests/__init__.py`), créer `odat_watch/tests/__init__.py` vide.

- [ ] **Step 2 : vérifier que le test échoue**

```powershell
cd odat_watch; python -m pytest tests/test_ui_prelevements.py -q; cd ..
```
Attendu : `ModuleNotFoundError: No module named 'ui_prelevements'` (levé dans `at.exception`, donc 3 FAILED).

- [ ] **Step 3 : écrire `odat_watch/ui_prelevements.py`**

```python
"""Onglet Prélèvements : date de référence, lancement du rapprochement clé métier (outil
CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS), tuiles, justification des écarts, clés par statut, téléchargements."""
from __future__ import annotations
from datetime import date

import streamlit as st

import prelevements as pv


def _fmt_nb(n) -> str:
    return f"{int(n):,}".replace(",", " ")


def _fmt_montant(m) -> str:
    return f"{float(m):,.2f} €".replace(",", " ").replace(".", ",")


def _tuiles(kpi, r: dict) -> None:
    c1, c2, c3, c4, c5, c6, c7 = st.columns(7)
    g = r["statut_global"]
    kpi(c1, pv.LIBELLES_GLOBAL.get(g, g), "résultat global", pv.TON_GLOBAL.get(g, "neutral"))
    kpi(c2, _fmt_nb(r["nb_emis"]), "prélèvements émis", "neutral")
    kpi(c3, _fmt_montant(r["montant_emis"]), "montant émis", "neutral")
    kpi(c4, _fmt_nb(r["nb_cles"]), "clés IBAN × échéance", "neutral")
    kpi(c5, _fmt_nb(r["en_attente"]), "en attente EDF", "warn" if r["en_attente"] else "ok")
    kpi(c6, _fmt_nb(r["anomalies"]), "anomalies", "err" if r["anomalies"] else "ok")
    kpi(c7, _fmt_nb(r["a_investiguer"]), "écarts à investiguer", "err" if r["a_investiguer"] else "ok")


def _table(df, hauteur: int = 320) -> None:
    st.dataframe(df, hide_index=True, use_container_width=True, height=min(hauteur, 38 * len(df) + 40))


def render(kpi):
    cfg = pv.config_prelevements()
    racine = cfg["racine"]
    st.markdown("#### Prélèvements · Oracle (OUT_SEPA) → EDF CashCollection (état de réception, rejets internes)")
    if not racine.is_dir():
        st.caption(f"Racine introuvable : `{racine}` — `config.ini [prelevements] racine` "
                   "(dossiers ORACLE\\<AAAAMMJJ>, EDF, EDF\\REJETS alimentés à la main).")
        return

    dates = pv.dates_disponibles(racine)
    b1, b2, b3, b4 = st.columns([1.3, 0.8, 1.4, 3])
    reference = b1.date_input("Date de référence", value=dates[0] if dates else date.today(),
                              format="DD/MM/YYYY", key="pv_date")
    jours = b2.number_input("Profondeur (j)", min_value=1, max_value=90, value=cfg["jours"], key="pv_jours")
    if b3.button("▶ Lancer le rapprochement", type="primary", use_container_width=True, key="pv_lancer",
                 help=f"Racine : {racine}\nSI : {cfg['nom_si']}"):
        with st.spinner("Rapprochement Oracle ↔ EDF…"):
            try:
                res = pv.lancer(reference, dict(cfg, jours=int(jours)))
                st.session_state["pv_msg"] = (f"Rapprochement au {reference:%d/%m/%Y} terminé : "
                                              f"{res['statut_global']} · {sum(e['cles'] for e in res['par_statut'].values())} clé(s)"
                                              f" · {res['nb_anomalies']} anomalie(s)")
            except Exception as e:  # noqa: BLE001 — l'outil externe peut échouer sur un fichier mal formé
                st.session_state["pv_msg"] = f"⚠ {type(e).__name__}: {e}"
    b4.caption("Dates déjà contrôlées : " + (", ".join(d.strftime("%d/%m") for d in dates[:8]) if dates else "aucune")
               + f" · SI = {cfg['nom_si']}")
    if st.session_state.get("pv_msg"):
        msg = st.session_state.pop("pv_msg")
        (st.error if msg.startswith("⚠") else st.success)(msg)

    rapport = pv.lire_rapport(racine, reference)
    if rapport is None:
        st.caption("Aucun rapport pour cette date de référence : cliquez sur **Lancer le rapprochement**.")
        return
    r = pv.resume(rapport)
    _tuiles(kpi, r)
    st.caption(f"Rapport généré le {rapport['genere_le']:%d/%m/%Y %H:%M} dans `{rapport['dossier']}` · `{rapport['base']}`")

    res = rapport["resume"]
    if r["lignes_ko"]:
        st.error(f"{r['lignes_ko']} ligne(s) Oracle non conforme(s) : résultat non fiable (voir l'onglet « Lignes rejetées » du classeur).")
    for a in res.get("avertissements", []):
        st.warning(a)
    if res.get("contexte"):
        st.caption(" · ".join(f"{k} : {v}" for k, v in res["contexte"].items()))

    just = rapport["justifications"]
    n_inv = r["a_investiguer"]
    with st.expander(f"{'🔴' if n_inv else '🟢'} Justification des écarts — {len(just)} cause(s), {n_inv} à investiguer",
                     expanded=bool(n_inv)):
        if just.empty:
            st.caption("Aucun écart : toutes les clés sont rapprochées.")
        else:
            st.caption("Une ligne par cause : REJET (rejet interne apparié), NON_CONFIRME, INEXPLIQUE, SANS_ORACLE. "
                       "Les causes INEXPLIQUE et SANS_ORACLE sont à investiguer.")
            _table(just, 400)
            st.download_button("⬇ Justifications (CSV)", just.to_csv(index=False, sep=";").encode("utf-8-sig"),
                               f"{rapport['base']}_justifications.csv", "text/csv", key="pv_csv_just")

    st.markdown("##### Clés par statut")
    for statut, df in pv.par_statut(rapport["rapprochement"]):
        icone = "🔴" if statut in pv.STATUTS_ANOMALIE else "🟠" if statut in pv.STATUTS_SIGNALES or statut == "EN_ATTENTE" else "🟢"
        with st.expander(f"{icone} {pv.LIBELLES_STATUT[statut]} — {len(df)} clé(s), "
                         f"{_fmt_nb(df['nb_oracle'].sum() or df['nb_edf'].sum())} prélèvement(s) · `{statut}`",
                         expanded=statut in pv.STATUTS_ANOMALIE):
            st.caption(pv.EXPLICATIONS[statut])
            _table(df.drop(columns=["statut"]))

    c1, c2 = st.columns(2)
    c1.download_button("⬇ Rapprochement complet (CSV)",
                       rapport["rapprochement"].to_csv(index=False, sep=";").encode("utf-8-sig"),
                       f"{rapport['base']}.csv", "text/csv", key="pv_csv")
    if rapport["xlsx"]:
        c2.download_button("⬇ Classeur Excel", rapport["xlsx"].read_bytes(), rapport["xlsx"].name,
                           "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", key="pv_xlsx")
```

- [ ] **Step 4 : lancer les tests**

```powershell
cd odat_watch; python -m pytest tests/test_ui_prelevements.py tests/test_prelevements.py -v; cd ..
```
Attendu : 12 passed. Si l'assertion `"1 en attente EDF"` échoue à cause du formatage, vérifier que `faux_kpi` écrit bien `valeur libelle [ton]` et que `_fmt_nb(1)` donne `1`.

- [ ] **Step 5 : commit**

```powershell
git add odat_watch/ui_prelevements.py odat_watch/tests/test_ui_prelevements.py
git commit -m "ODAT Watch : Prélèvements — onglet (date de référence, lancement, tuiles, justification des écarts, clés par statut, téléchargements)" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4 : branchement dans l'application, configuration, documentation

**Files:**
- Modify: `odat_watch/app.py:309-310` (liste des onglets) et `:334-336` (bloc Virements)
- Modify: `odat_watch/config.ini.exemple` (après la section `[virements]`)
- Modify: `odat_watch/README.md:32` et `:36`

- [ ] **Step 1 : ajouter l'onglet dans `app.py`**

Remplacer la déclaration des onglets (`app.py:309-310`) par :

```python
tab_plan, tab_calendriers, tab_soir, tab_demain, tab_now, tab_matin, tab_releves, tab_folio, tab_vir, tab_prel, tab_ora, tab_histo, tab_profils, tab_data, tab_sql = st.tabs(
    ["🧭 Préparer ma nuit", "📥 Clôtures", "🌙 Ce soir", "📅 Demain", "🔴 Maintenant", "☀️ Matin", "🏦 Relevés bancaires", "🌹 Folio Rose", "💸 Virements", "💳 Prélèvements", "🅾 Oracle", "🔎 Historique", "📈 Profils", "🗂 Données", "⌨ SQL"])
```

Et juste après le bloc `with tab_vir:` (`app.py:334-336`) ajouter :

```python
with tab_prel:
    import ui_prelevements
    ui_prelevements.render(kpi)
```

- [ ] **Step 2 : ajouter la section dans `config.ini.exemple`**

Après la section `[virements]` :

```ini
[prelevements]
; Onglet Prelevements. Racine de l'outil CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS : dossiers ORACLE\<AAAAMMJJ>
; (fichiers *PCX* / *PCL* archives depuis DATA/Traite/OUT_SEPA), EDF (IMPORT_AVP_DK.*.csv, pieces jointes du mail
; "Synthese quotidienne des prelevements Dalkia recus par CashCollection") et EDF\REJETS (REJETS_INTERNES_DK.*.csv).
; Rapports ecrits dans rapport\Rapprochement_Cle_Metier_<AAAAMMJJ>_<HHMMSS>.*
racine = ..\CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS
; Profondeur du perimetre en jours calendaires (echeances de reference - jours a reference + 25 j)
jours = 10
; Nom du SI dans les etats EDF (l'autre SI est CIF)
nom_si = ORACLE
```

- [ ] **Step 3 : mettre à jour le README**

Après la ligne `virements.py / ui_virements.py` du tableau (`README.md:32`) ajouter :

```markdown
| `prelevements.py` / `ui_prelevements.py` | **Prélèvements** : onglet pont vers `../CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS` (rapprochement Oracle ↔ EDF par clé IBAN créancier × échéance, `rapprochement_cle_metier.executer`) : date de référence et profondeur, tuiles (statut global, émis, en attente, anomalies, écarts à investiguer), justification des écarts, clés par statut, téléchargement CSV / classeur. Config `[prelevements]`. |
```

Dans la ligne `app.py` (`README.md:36`), insérer « Prélèvements » après « Virements ».

- [ ] **Step 4 : vérifier que l'application démarre et que toute la suite passe**

```powershell
cd odat_watch; python -m pytest tests -q; cd ..
```
Attendu : tous les tests passent (les tests virements se désactivent d'eux-mêmes si les données sont absentes).

```powershell
cd odat_watch; python -c "import ast,sys; ast.parse(open('app.py',encoding='utf-8').read()); print('app.py OK')"; cd ..
```
Puis lancer l'interface (`odat_watch\run.bat` ou `streamlit run odat_watch/app.py`), ouvrir l'onglet 💳 Prélèvements, choisir la date de référence 15/09/2026 (rapport produit à la Task 1, étape 5) et vérifier : tuiles, expander « Justification des écarts », groupes par statut, les deux boutons de téléchargement. Cliquer « Lancer le rapprochement » avec la date du jour et vérifier que le message de fin s'affiche et que le rapport se recharge.

- [ ] **Step 5 : commit**

```powershell
git add odat_watch/app.py odat_watch/config.ini.exemple odat_watch/README.md
git commit -m "ODAT Watch : onglet Prélèvements branché, section [prelevements] du config.ini.exemple, README" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5 : assainissement minimal du dossier de l'outil

Points relevés lors de l'exploration qui gênent directement l'intégration. Le reste (voir « Suites possibles ») est laissé à une décision séparée.

**Files:**
- Modify: `.gitignore:28` et `:41`
- Modify: `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/Lancer_Rapprochement.bat`
- Modify: `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/prelevements_rapprochement.py:690` (`--motif-rejets`)
- Modify: `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/docs/GUIDE_rapprochement_cle_metier.md` (§ lancement, compteur de tests)

- [ ] **Step 1 : `.gitignore` — ignorer les rapports générés et réparer la ligne corrompue**

La ligne 41 contient deux motifs collés (`*.outextractionCap/*.xlsx`) : la scinder en `*.out` puis `extractionCap/*.xlsx`. Ajouter à la fin du fichier :

```gitignore
# Rapports generes par le rapprochement des prelevements (ODAT Watch, onglet Prelevements)
CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapport/
```

Vérifier ce que git suit déjà dans ce dossier et le retirer de l'index sans supprimer les fichiers :

```powershell
git ls-files CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapport | Measure-Object -Line
git rm -r --cached -q CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/rapport
```

Exception : `rapport/README_ecart_589_20260914.md` est une analyse rédigée, pas un fichier généré. Le déplacer dans `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/docs/` avec `git mv` **avant** le `git rm --cached`.

- [ ] **Step 2 : un seul lanceur, sans Excel COM**

Remplacer le contenu de `Lancer_Rapprochement.bat` par un appel à l'outil de référence, avec le même choix `py`/`python` que `rapprochement_cle_metier.bat` :

```bat
@echo off
rem Lanceur historique conserve pour les habitudes : il appelle desormais le rapprochement par cle metier
rem (plus de PowerShell ni d'Excel COM). Options : voir rapprochement_cle_metier.bat.
call "%~dp0rapprochement_cle_metier.bat" %*
```

Ne pas supprimer `Prelevements_Rapprochement_Oracle_EDF.ps1` dans ce plan (décision utilisateur, voir suites).

- [ ] **Step 3 : aligner le motif des rejets entre les deux scripts**

Dans `prelevements_rapprochement.py:690`, remplacer la valeur par défaut `REJETS_INTERNES_DK.*` par `REJETS_INTERNES_DK.*.csv` pour qu'un fichier `.tmp` ou `.bak` déposé dans `EDF\REJETS` ne soit jamais lu par un outil et ignoré par l'autre. Lancer :

```powershell
cd CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS; python -m pytest tests -q; cd ..
```
Attendu : 48 passed.

- [ ] **Step 4 : documentation de l'outil**

Dans `docs/GUIDE_rapprochement_cle_metier.md`, section lancement : ajouter un paragraphe « Depuis ODAT Watch » (onglet 💳 Prélèvements, mêmes fichiers de sortie, plus `_resume.json`) et corriger le compteur « 26 tests » en « 30 tests ». Dans `docs/GUIDE_prelevements_rapprochement.md:374`, corriger « 10 tests » en « 18 tests ».

- [ ] **Step 5 : commit**

```powershell
git add .gitignore CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS
git commit -m "Contrôle prélèvements : rapports générés hors git, lanceur unique vers la clé métier, motif rejets aligné, guides à jour" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## Suites possibles (hors plan, à décider)

1. **Données de production dans git** : 6 626 fichiers Oracle/EDF suivis (IBAN, RUM, noms, montants). Proposition : ignorer `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/ORACLE/` et `EDF/`, les retirer de l'index (`git rm --cached`), et purger l'historique si le dépôt est partagé. Décision et calendrier à valider.
2. **Dossier `traitementSortie/`** : logs iValua (`DKA_IPOFRS_IVALUA_LOADER`) sans lien avec les prélèvements et référencés nulle part. À déplacer ou supprimer.
3. **Retrait de `Prelevements_Rapprochement_Oracle_EDF.ps1`** et du `.docx` v2 qui le documente, une fois le lanceur unique adopté par les utilisateurs.
4. **Historisation SQLite + tendance** (table `pv_histo` sur le modèle de `controle_matin_histo`) pour suivre l'évolution des clés EN_ATTENTE / NON_RECU jour après jour.
5. **Planification** : tâche Windows sur le modèle de `planif_matin.py` lançant `rapprochement_cle_metier.py` après réception de l'état EDF (~07:05), avec dépôt automatique des pièces jointes des mails EDF.
6. **Fusion des deux outils** : sortir les helpers partagés (`_titre`, `_entetes`, `_ajuster_largeurs`, `Diagnostic`, `ErreurTraitement`, `trouver_dossier_rejets`) dans un module commun, puis décider du sort du rapprochement journalier.
7. **Jours fériés** dans la règle J+2/J+4 du rapprochement journalier, si celui-ci est conservé (`prelevements_rapprochement.py:289`).
