# DKA_SCTLFLUX_EAI — Analyse du traitement simultané (Oracle EBS)

## Contexte
- Environnement: Oracle EBS 12.2.13 (DB 19.25)
- Module: Contrôle des flux comptables (GL)
- Objet: Programme concurrent `DKA_SCTLFLUX_EAI` / Exécutable `DKA_SCTLFLUX_EAI_PKG.main`
- Package PL/SQL: `APPS.DKA_SCTLFLUX_EAI_PKG` (spec + body VALIDE)
- Répertoire externe: `SCTLFLUX_OUT_DIR`

## Métadonnées Programme
- Nom technique: `DKA_SCTLFLUX_EAI`
- Nom utilisateur: `DKA : Extraction du contrôle de flux`
- `CONCURRENT_PROGRAM_ID`: 62533 — `ENABLED_FLAG`: Y
- Méthode d’exécution: `I` (PL/SQL)
- Exécutable: `FND_EXECUTABLES.EXECUTION_FILE_NAME = 'DKA_SCTLFLUX_EAI_PKG.main'`
- Description: « Extraction du contrôle de flux »

## Spécification (params)
Procédure `main(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER, pv_folio IN VARCHAR2, pn_traitement_reprise IN NUMBER, pd_date_reprise_de IN VARCHAR2, pd_date_reprise_a IN VARCHAR2)`
- `pv_folio`: code folio GL (contrôle par jeu de valeurs `DKA_PARAM_FOLIO_GL`)
- `pn_traitement_reprise`: identifiant de reprise (rejouer un traitement)
- `pd_date_reprise_de` / `pd_date_reprise_a`: fenêtre temporelle à reprendre (format chaîne, converti plus loin)

## Logique Principale (résumé code)
- Variables profil FND:
  - `cn_num_traitement := fnd_profile.value('CONC_REQUEST_ID')` (tag pour marquer les enregistrements)
  - `gn_user_id := TO_NUMBER(FND_PROFILE.VALUE('USER_ID'))`
- Fonctions utilitaires de log: `out_msg` (outfile) et `log_msg` (log)

### Étape GL_INTERFACE
1) Flag des lignes `GL_INTERFACE` avec `attribute5 = cn_num_traitement` filtrées par:
   - `ATTRIBUTE9 = pv_folio` (si fourni) et présence dans le jeu de valeurs `DKA_PARAM_FOLIO_GL`
   - `DATE_CREATED BETWEEN pd_date_debut AND pd_date_fin`
   - Ledgers primaires uniquement (`GL_LEDGERS.ledger_category_code = 'PRIMARY'`)
   - Reprise: `(attribute5 is null OR gv_reprise = 'Y')`
2) Insertion agrégée dans `DKA_SCTLFLUX_EAI`:
   - Champs: `CODE_FOLIO, DATE_EXEC, NB_PIECE, DEBIT, CREDIT, FICHIER, TRAITE, N_TRAITEMENT, DATE_DEBUT, DATE_FIN, CREATED_BY, CREATION_DATE`
   - Sources: `GL_INTERFACE`
   - Spécificités:
     - `DATE_EXEC = MIN(TRUNC(GI.DATE_CREATED))` (correction historique du 18/05/2015)
     - `NB_PIECE = COUNT(DISTINCT (ATTRIBUTE9 || '|' || REFERENCE4))` (22/05/2015)
     - `DEBIT = SUM(Entered_Dr)`, `CREDIT = SUM(Entered_Cr)`
     - `FICHIER = ATTRIBUTE10`
     - Filtre de reprise via `attribute5 = to_char(cn_num_traitement)`
3) `COMMIT` explicite.

### Étape GL_JE_LINES / GL_JE_HEADERS
- Flag des `GL_JE_LINES.ATTRIBUTE5 = cn_num_traitement` sous conditions:
  - `CREATION_DATE` dans la fenêtre
  - `ATTRIBUTE9` = `pv_folio` et présent dans `DKA_PARAM_FOLIO_GL`
  - Non contrepassé (`GL_JE_HEADERS.REVERSED_JE_HEADER_ID IS NULL`)
  - Reprise: `(attribute5 is null OR gv_reprise = 'Y')`

### Sorties / Répertoire
- Écritures log/out via `FND_FILE` (répertoires concurrents définis)
- Référence externe `SCTLFLUX_OUT_DIR` (pour génération de fichier de contrôle, renommage historique)

## Points d’attention (Performance & Robustesse)
- Marquage par lot via `attribute5 = CONC_REQUEST_ID` sur `GL_INTERFACE` et `GL_JE_LINES` pour tracer la session.
- Joins sur `FND_FLEX_VALUES_VL` et `FND_FLEX_VALUE_SETS` pour restreindre aux folios valides (`DKA_PARAM_FOLIO_GL`).
- `COMMIT` présent après insertions dans la table de contrôle — réduit la fenêtre de verrouillage.
- Filtre ledgers primaires pour éviter volumes sur secondaires.
- Comptage distinct par combinaison `ATTRIBUTE9|REFERENCE4` (attention à cardinalité).

## Historique notable (extraits du code)
- 18/05/2015: correction date minimale de création des pièces
- 22/05/2015: correction du décompte NB_PIECE
- 04/05/2016: migration R12 (SPE186)
- 24/01/2018: colonne crédit vide — correction
- 25/11/2019: MAJ folio et nom de fichier pour lignes de taxe
- 01/06/2023: EDB295 Remboursement Avoir Client (lot 2)
- 06/10/2025: dernière compilation body validée

## Recommandations d’exploitation
- Paramétrage: toujours fournir `pv_folio` appartenant à `DKA_PARAM_FOLIO_GL`.
- Fenêtre: contrôler `pd_date_debut` / `pd_date_fin` pour limiter volume.
- Reprise: utiliser `pn_traitement_reprise` + `gv_reprise = 'Y'` si besoin (vérifier les autres blocs du package pour la logique complète de reprise).
- Surveillance: filtrer les exécutions longues via `FND_CONCURRENT_REQUESTS` et suivre `attribute5 = CONC_REQUEST_ID` sur `GL_INTERFACE`/`GL_JE_LINES`.

## SQL d’analyse (à exécuter)

```sql
-- Métadonnées programme
SELECT fcp.concurrent_program_name,
       fcp.user_concurrent_program_name,
       fcp.concurrent_program_id,
       fcp.enabled_flag,
       fcp.execution_method_code,
       fcp.executable_id,
       fcp.description
FROM fnd_concurrent_programs_vl fcp
WHERE fcp.concurrent_program_name = 'DKA_SCTLFLUX_EAI';

-- Exécutable
SELECT fe.executable_id, fe.executable_name, fe.execution_method_code,
       fe.execution_file_name, fe.subroutine_name
FROM fnd_executables fe
WHERE fe.executable_name = 'DKA_SCTLFLUX_EAI';

-- Dernières exécutions (30 jours)
SELECT fcr.request_id,
       fcp.user_concurrent_program_name,
       TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') AS date_debut,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') AS date_fin,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) AS duree_minutes,
       fcr.phase_code, fcr.status_code, fcr.argument_text
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.concurrent_program_name = 'DKA_SCTLFLUX_EAI'
  AND fcr.actual_start_date >= TRUNC(SYSDATE) - 30
ORDER BY fcr.actual_start_date DESC
FETCH FIRST 50 ROWS ONLY;

-- Traçage par CONC_REQUEST_ID
SELECT COUNT(*) nb_glint
FROM gl_interface
WHERE attribute5 = TO_CHAR(:request_id);

SELECT COUNT(*) nb_gjlines
FROM gl_je_lines
WHERE attribute5 = TO_CHAR(:request_id);
```

## Conclusion
Le programme `DKA_SCTLFLUX_EAI` extrait et consolide les informations de contrôle de flux depuis `GL_INTERFACE` en les historisant dans `DKA_SCTLFLUX_EAI`, tout en marquant les interfaces et écritures GL par le `CONC_REQUEST_ID`. Les paramètres de folio et de période sont essentiels pour limiter la volumétrie et garantir la pertinence des agrégations. Le dispositif de reprise et les commits intermédiaires contribuent à la robustesse opérationnelle.
