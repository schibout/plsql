# ODAT Watch — onglet « 🏦 Relevés bancaires »

Date : 20/09/2026. Statut : validé avec l'utilisateur (accès PFE par copie manuelle ; logs `.req/.out` en
source première, Oracle en complément).

## Objectif

Suivre de bout en bout la chaîne quotidienne d'intégration des relevés bancaires et détecter tôt ce qui a
causé l'incident du 14-18/09/2026 (`ControleReleveBancaire/README.md`) :

```
PFE (Talend)            Control-M FINEXT_J14INT_05_Q / 06_Q                     Oracle EBS (XXRB)
SOURCE → TARGET  ──►  MOV01 ─► ZIP01 ─► CON01 ─► WRK01 ─► IMP01 ─► MEL01/WRK02  ──►  RBAFBIMP  ─►  DKA_SRBCTRLRB
 + compteur_*.zip       (Compteur.zip NAS → dézip → AFB120.txt → filtre → import RB)     import         contrôle
```

Deux flux par matinée : **A** (multi-banques, PFE 07:16/07:46 → import 07:50) et **B** (Société Générale
30003 seule, PFE 08:16 → import 08:20, chaîne cyclique 06).

## Sources de données (toutes locales, dossiers configurables)

`config.ini [releves]` :

```ini
[releves]
dossier_pfe    = ..\ControleReleveBancaire\fluxPFE      ; un sous-dossier <uuid> par exécution Talend
dossier_ebs    = ..\ControleReleveBancaire\fichierBanque ; AFB120.txt_<AAAAMMJJHHMMSS> reçus par EBS (data/traite)
dossiers_logs  = ..\ControleReleveBancaire\import;..\ControleReleveBancaire\controle  ; l<id>.req / o<id>.out
banque_flux_b  = 30003                                    ; flux B = fichiers ne contenant que cette banque
comptes_connus = 30003/03620/00020137269;16807/00166/31990892212   ; anomalies préexistantes (aussi éditable dans l'onglet)
```

Les dossiers sont alimentés à la main (copie des `<uuid>` PFE, `copy_ebs_logs.sh` pour les logs). Un bouton
« Scanner » relit tout ; ce qui est déjà en base est reconnu (uuid, nom de fichier, request_id).

## Lecture des fichiers

### AFB120 (`SOURCE`, `TARGET`, `AFB120.txt_*`)

Enregistrements à position fixe (CFONB 120) : code enregistrement colonnes 1-2 (`01` ancien solde / ouverture
de relevé, `04` mouvement, `05` complément, `07` nouveau solde / clôture), code banque 3-7, guichet 12-16,
devise 17-19, n° de compte 22-32, date 35-40 (`JJMMAA`). Un **relevé** = un enregistrement `01`.
`lire_afb120()` renvoie : `nb_releves` (01), `nb_mouvements` (04), `nb_lignes`, `banques` (codes distincts avec
nb de relevés), `comptes` (liste `banque.guichet.compte` avec date début = date du `01` et date fin = date du `07`),
`date_min`, `date_max`, `md5`, `flux` = `B` si l'unique banque est `banque_flux_b`, sinon `A`.
Vérification sur `2b6da61b…/TARGET` : 213 × `01`, 2 014 × `04`, 6 333 × `05`, 213 × `07`, flux B.

### Exécution PFE (`<uuid>/`)

`SOURCE/*.txt` (fichier banque brut), `TARGET/compt_AFB120_RELEVESDECOMPTE_<AAMMJJ-HHMMSS>.txt` (livré à EBS),
`TARGET/compteur_<AAAAMMJJ>_<HHMM>.zip` (doit contenir le TARGET), `TALEND/LS_IN.OK`. Horodatage = celui du nom
du TARGET. `complete` = les quatre présents et le zip contient bien le TARGET.

### Fichier reçu par EBS (`AFB120.txt_<AAAAMMJJHHMMSS>[suffixe]`)

Horodatage = les 14 chiffres après `AFB120.txt_`. Un fichier PFE est **reçu** si un fichier EBS a le même md5
que son TARGET ; **non reçu** sinon (le rapprochement du README §6 doit être reproduit exactement : 11 reçus,
`2b6da61b…` et `f067afff…` absents).

### Log d'import `RBAFBIMP` (`l<id>.req` + `o<id>.out`)

`.req` : `Fichier des relevés`, `Nombre d'enregistrements lus`, `Nombre de lignes écrites`, dates début / fin
(`Date et heure système`). `.out` : pages « Enregistrements erronés lors du chargement » (une ligne
`NNNNN >  01…` suivie de ` Erreur 0xx : libellé` ; banque / guichet / compte / date lus sur l'enregistrement),
puis « Synthèse des relevés, chargement N° <batch> » : une ligne par relevé
(`Err.` = `1` si erreur, n°, `Compte` = `banque.guichet.compte`, devise, date début, ancien solde, date fin,
nouveau solde, nb mouvements, lignes début-fin) et le pied `Relevés chargés X / erreurs Y / total Z`,
`Lignes chargées X / erreurs Y / total Z`. Encodage cp1252/latin-1 (`logs.lire` gère déjà).
Attendus : `49061539` → lus 8 285, écrits 0, relevés chargés 0, erreurs 213, 213 × `Erreur 025` ;
`49029106` → 207 chargés (6 erreurs : 5 × 001 + 1 × 025) ; `49041437` → flux A, 141 chargés.

### Log de contrôle `DKA_SRBCTRLRB` (`o<id>.out`)

`DATE DE REFERENCE:JJ/MM/AAAA` puis un CSV `;` : `ID;NOM_BANQUE;BANQUE;GUICHET;COMPTE;NOM_COMPTE;RAPPRO;
COMPTE_LOCAL;DATE_DERNIER_IMPORT;DATE_DEBUT_RELEVE;DATE_FIN_RELEVE;SOLDE_INITIAL_RELVE;SOLDE_FINAL_RELEVE`.
Une ligne par compte en anomalie. Attendu : `49069921` → date de référence 17/09/2026, 208 lignes dont 207 SG.
Un contrôle lancé **avant** le flux B liste normalement les ~207 comptes SG (README §3) : l'anomalie « réelle »
est le contrôle exécuté **après** le flux B qui reste non vide (hors comptes connus).

### Control-M (photos ODAT déjà en base `ctm_jobs`)

Pour une matinée (odate = veille), jobs des groupes `FINEXT_J14INT_05_Q` et `FINEXT_J14INT_06_Q` : statut,
début, fin, reruns, pris dans la **dernière photo** couvrant la matinée. Règles :
- **conflit 05/06** : `FINEXT_J14INT_06_MOV01_Q` démarre à moins de 60 s de `FINEXT_J14INT_05_MOV01_Q` ;
- **chaîne 06 bloquée** : `FINEXT_J14INT_06_ZIP01_Q` en `Ended Not OK` (reruns ≥ 1) ;
- conséquence attendue : aucun `06_IMP01_Q` ce jour → fichier PFE de 08:16 non reçu.
Attendu (photos 08:06 des 15 et 16/09) : conflit + ZIP01 Not OK rerun 10 ; 17/09 : pas de conflit.

## Modèle (SQLite, préfixe `rb_`)

```
rb_pfe(uuid PK, horodatage, fichier_source, fichier_target, zip, ls_in_ok, complete, flux, nb_releves,
       nb_lignes, banques, date_min, date_max, md5, ebs_md5_recu, vu_le)
rb_ebs(nom PK, horodatage, flux, nb_releves, nb_lignes, banques, date_min, date_max, md5, vu_le)
rb_imports(request_id PK, debut, fin, fichier, lus, ecrits, batch, releves_charges, releves_erreurs,
           lignes_chargees, lignes_erreurs, err001, err025, autres_erreurs, flux, md5_ebs, source_req, source_out)
rb_import_releves(request_id, num, compte, banque, guichet, numero, devise, date_debut, date_fin, mouvements,
                  en_erreur, code_erreur, PRIMARY KEY(request_id, num))
rb_controles(request_id PK, executed_at, date_reference, nb_anomalies, nb_sg, nb_hors_connus)
rb_controle_lignes(request_id, compte_id, banque, guichet, numero, nom_compte, date_dernier_import,
                   date_debut_releve, date_fin_releve, PRIMARY KEY(request_id, compte_id))
rb_comptes_connus(cle PK 'banque/guichet/compte', motif, ajoute_le)
```

`flux` d'un import : déduit du fichier (md5 avec `rb_ebs` → banques) sinon de l'heure (< 08:05 → A, sinon B)
et des comptes de la synthèse (100 % `30003` → B).

## Moteur `releves.py`

- `lire_afb120(source, nom=None) -> Afb120` ; `scanner_pfe(dossier, con)` ; `scanner_ebs(dossier, con)` ;
  `scanner_logs(dossiers, con)` (réutilise `logs.lire`, `logs.parse_req` pour compteurs/dates ; parseurs dédiés
  `parse_import_out`, `parse_controle_out`) ; `rapprocher_pfe_ebs(con)` (md5) ; `scanner_tout(cfg, con) -> str`.
- `chaine_controlm(con, jour) -> DataFrame` (jobs 05/06 de la matinée) + `diagnostic_controlm(df) -> dict`
  (`conflit_mov`, `zip06_not_ok`, `import06_execute`).
- `journee(con, jour) -> Journee` : pour A et B : exécution PFE (la plus proche de l'heure attendue), fichier EBS,
  import (request dont l'heure ∈ fenêtre du flux), contrôle(s) du jour, chaîne Control-M ; **verdict** par flux :
  `OK` (PFE complet, reçu, import avec relevés chargés > 0 et pas d'Err 025 massif), `WARN` (Err 025 sur un
  seul compte connu, contrôle avant flux B, PFE absent un jour où la banque n'a rien produit), `KO` (PFE non
  reçu, import 0 chargé / Err 025 massif, ZIP01 Not OK, contrôle post-B non vide hors connus) ; **causes** en
  français, issues des règles ci-dessus.
- `chronologie(con, jours) -> DataFrame` : le tableau du README §4 (date, request, fichier, flux, lus, écrits,
  chargés, résultat).
- `continuite(con) -> DataFrame` : par compte SG, dernier relevé chargé (`date_fin` du dernier import où
  `en_erreur = 0`) et date de fin attendue (date max des TARGET PFE flux B) → `retard_j`, `trou` si un import
  postérieur a rejeté ce compte en Err 025.
- `plan_reprise(con) -> list[Etape]` : fichiers à rejouer dans l'ordre chronologique : TARGET PFE non reçus,
  puis fichiers EBS dont l'import a été rejeté en Err 025 massif ; pour chaque étape le chemin, le relevé couvert
  (date_min → date_max), le résultat attendu (`207 chargés / 6 erreurs` = nb relevés − comptes connus en erreur).
  Attendu au 18/09 : les 4 étapes du README §8 dans cet ordre.
- `liste_logs_manquants(con) -> Path` : requests `RBAFBIMP` / `DKA_SRBCTRLRB` connues d'`ora_requests` sans
  `.req/.out` local → `list.txt` pour `copy_ebs_logs.sh` (même format que `logs.ecrire_liste`).
- Oracle (optionnel, si `[database]` présent) : `synthese_xxrb(jours)` = requête 7 et `anomalies_xxrb(date)` =
  requêtes 3-4 du SQL d'analyse, affichées en complément (« vue Oracle ») ; jamais bloquant.

## Onglet `ui_releves.py` (« 🏦 Relevés bancaires », après « ☀️ Matin »)

1. Barre : date (défaut aujourd'hui), bouton **🔄 Scanner les dossiers** (PFE, EBS, logs) avec journal,
   bouton **📋 list.txt des logs manquants**, bouton **📄 Rapport HTML**.
2. **Frise de la matinée** : deux lignes (flux A, flux B), cinq pastilles chacune — PFE · Control-M · Reçu EBS ·
   Import · Contrôle — vert / orange / rouge, heure sous chaque pastille, verdict et causes à droite.
3. **Chronologie** des imports sur N jours (tableau §4) + mini-tendance relevés chargés / erreurs.
4. **Continuité SG** : comptes en retard, trou détecté → encadré rouge « Plan de reprise » (étapes ordonnées,
   chemins, résultats attendus).
5. **Rapprochement PFE ↔ EBS** (§6) : exécutions PFE avec reçu / non reçu / rejeté (Err 025).
6. **Chaîne Control-M** de la matinée : tableau des jobs 05/06 (statut, heures, reruns) + diagnostic conflit.
7. **Contrôles `DKA_SRBCTRLRB`** : liste, date de référence, anomalies (hors connus), détail.
8. **Comptes connus** (`st.data_editor`) : anomalies préexistantes à ignorer, avec motif.
Les étapes sans donnée locale affichent « pas de log / fichier : lancer copy_ebs_logs.sh avec list.txt ».

## Rapport `rapport_releves.py`

Charte des autres rapports : bandeau verdict du jour, frise A/B, chronologie, continuité + plan de reprise,
rapprochement PFE ↔ EBS, contrôles. `rapports/Releves_<AAAAMMJJ>_<HHMM>.html`.

## Tests (pytest, sans Oracle, sur les fichiers réels de `ControleReleveBancaire/`)

- `lire_afb120` sur le TARGET `2b6da61b…` (213/2014/6333/213, flux B, md5 = celui de `fichierBanque/…` ? non :
  absent) et sur `AFB120.txt_20260915074956` (flux A, banques 30004 majoritaire).
- `scanner_pfe` : 13 exécutions, toutes complètes ; `rapprocher_pfe_ebs` : 11 reçues, 2 non reçues (uuids du §6).
- `parse_import_out` : `49061539` (0 chargés, 213 erreurs, 213 × 025), `49029106` (207 / 6), compteurs `.req`.
- `parse_controle_out` : `49069921` (17/09/2026, 208 lignes, 207 × 30003).
- `chaine_controlm` / `diagnostic_controlm` sur `odat.db` de test alimenté par les photos de
  `ControleReleveBancaire/FichierODAT/` (ingest) : 15/09 conflit + ZIP01 Not OK ; 17/09 sain.
- `journee(18/09)` : flux A OK, flux B KO cause « Err 025 massif — trou depuis le 11/09 » ; `plan_reprise` = 4
  étapes du §8 dans l'ordre.
- Rapport HTML : sections, échappement. AppTest : scan + frise + plan de reprise affichés.

## Hors périmètre V1

Exécution automatique de la reprise (dépôt dans `data/in`, lancement de requests), envoi mail, lecture
directe du NAS / de PFE, lecture des sorties Oracle via `FND_WEBFILE`.
