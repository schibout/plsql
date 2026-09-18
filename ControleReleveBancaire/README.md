# Contrôle relevés bancaires – Incident « pas d'import depuis le 14/09/2026 »

Analyse réalisée le 18/09/2026 à partir des logs EBS (`import/`, `controle/`), des fichiers
banque reçus par EBS (`fichierBanque/`) et des exécutions Talend PFE (`fluxPFE/`).

## 1. Résumé

- **Constat MOA** : plus d'import de relevés depuis le 14/09.
- **Réalité** : un seul des deux flux quotidiens est cassé, le **flux Société Générale (banque 30003, 213 relevés, fichier de ~08:16/08:20)**. Le flux multi-banques de 07:50 (BNP, etc.) est importé normalement tous les jours.
- **Cause racine** : les fichiers SG des relevés du **14/09** et du **15/09** (produits par PFE les 15 et 16/09 à 08:16) **ne sont jamais arrivés dans EBS**. Depuis, l'import `RBAFBIMP` rejette la totalité des fichiers SG suivants avec `Erreur 025 : Journée manquante` (contrôle de continuité des relevés).
- **Ce n'est pas un bug applicatif** et il n'y a **rien à demander à la banque** : les deux fichiers manquants sont disponibles dans `fluxPFE/`.
- **Job en erreur (Control-M, FIN-FINANCE)** : `FINEXT_J14INT_06_ZIP01_Q` – Ended Not OK après 10 reruns, **le 15/09 (07:50) et le 16/09 (07:52)**. Les deux jours, le move de la chaîne cyclique `FINEXT_J14INT_06_Q` s'est déclenché à 07:49 en concurrence avec `FINEXT_J14INT_05_Q` sur le même `Compteur.zip` ; la chaîne 06 s'est bloquée et n'a jamais traité le zip de 08:16. Le 17/09 (flux A arrivé à 07:16) la concurrence n'a pas eu lieu et la chaîne 06 a fonctionné (voir §7).
- **Reprise** : rejouer 4 fichiers dans l'ordre (voir §8).

## 2. Contenu du dossier

| Dossier / fichier | Contenu |
|---|---|
| `fichierBanque/` | Fichiers `AFB120.txt_<horodatage>` reçus par EBS (archivés depuis `/data/flf/files/PDBFINP1/data/traite`) |
| `import/` | Logs `l*.req` et sorties `o*.out` des requests EBS **RBAFBIMP – XXRB Import fichier des banques** |
| `controle/` | Logs et sorties des requests **DKA_SRBCTRLRB – Contrôle des relevés bancaires** (`DKA_SRBCTRLRB_PKG.sql`) |
| `fluxPFE/<uuid>/` | Exécutions Talend PFE : `SOURCE/` (fichier banque brut `CDPG.NC4.EXPORT…AFB.txt`), `TARGET/` (fichier livré à EBS `compt_AFB120_RELEVESDECOMPTE_<AAMMJJ-HHMMSS>.txt` + zip `compteur_*`), `TALEND/LS_IN.OK` |
| `FichierODAT/` | Exports Control-M (`Report_ctm_<odate>_*.csv`) des odates 14 à 17 (matinées du 15, 16 et 17/09) |
| `copy_ebs_logs.sh`, `list.txt` | Script de récupération des `.req` / `.out` depuis le serveur EBS |

## 3. Les deux flux quotidiens

| Flux | Heure PFE → EBS | Contenu | Relevés | Erreurs « normales » à chaque import |
|---|---|---|---|---|
| **A** | 07:16 / 07:46 → 07:50 | Multi-banques : 142 BNP (30004), 14 SG (30003), 13825, 99375, CH260, CH530 | 160 | 19 × `Erreur 001 : Compte bancaire erroné` |
| **B** | 08:16 → 08:20 | Société Générale (30003) uniquement | 213 | 5 × `Erreur 001` + 1 × `Erreur 025` (compte 03620/00020137269, en écart depuis avant le 08/09) |

Le rapport de contrôle `DKA_SRBCTRLRB` exécuté après le flux A liste toujours les ~207 comptes SG du flux B
(pas encore reçus à cette heure) ; exécuté après le flux B il est vide. C'est le comportement normal.

## 4. Chronologie des imports EBS (`import/`)

| Date / heure | Request | Fichier EBS | Flux | Lus | Écrits | Chargés | Résultat |
|---|---|---|---|---|---|---|---|
| 08/09 08:19 | 48977998 | – | B | 7574 | 1415 | 207 | OK |
| 09/09 07:49 | 48991443 | `AFB120.txt_20260909074950` | A | 2848 | 462 | 141 | OK |
| 09/09 08:19 | 48991493 | `AFB120.txt_20260909081953` | B | 5953 | 1181 | 207 | OK |
| 10/09 07:49 | 49004013 | `AFB120.txt_20260910074953` | A | 3936 | 675 | 141 | OK |
| 10/09 08:20 | 49004076 | `AFB120.txt_20260910082023` | B | 6939 | 1352 | 207 | OK |
| 11/09 07:49 | 49014038 | `AFB120.txt_20260911074952` | A | 4109 | 725 | 141 | OK |
| 11/09 08:20 | 49014213 | `AFB120.txt_20260911082047` | B (09→10/09) | 7284 | 1360 | 207 | OK |
| 12/09 07:49 | 49025145 | `AFB120.txt_20260912074952` | A | 4376 | 744 | 141 | OK |
| 12/09 08:20 | – | **aucun fichier** | B | | | | Fichier SG non produit par la banque ce jour (arrivé le 14/09) |
| 14/09 07:20 | 49029055 | `AFB120.txt_20260914071959` | (1 relevé 13825) | 2 | 0 | 0 | 1 × Err 001 (compte inconnu, sans impact) |
| 14/09 07:49 | 49029106 | `AFB120.txt_20260914074951` | B (10→**11/09**) | 8342 | 1663 | 207 | **OK – dernier import SG réussi** |
| 15/09 07:49 | 49041437 | `AFB120.txt_20260915074956` | A | 5388 | 924 | 141 | OK |
| 15/09 08:20 | – | **aucun fichier** | B (11→14/09) | | | | **Fichier produit par PFE mais jamais reçu** |
| 16/09 07:49 | 49051565 | `AFB120.txt_20260916074954` | A | 5725 | 931 | 141 | OK |
| 16/09 08:20 | – | **aucun fichier** | B (14→15/09) | | | | **Fichier produit par PFE mais jamais reçu** |
| 17/09 07:19 | 49061457 | `AFB120.txt_20260917071950` | A | 3756 | 670 | 141 | OK |
| 17/09 08:19 | 49061539 | `AFB120.txt_20260917081953` | B (15→16/09) | 8285 | **0** | **0** | **208 × Erreur 025** |
| 18/09 07:49 | 49069848 | `AFB120.txt_20260918074956` | A | 6251 | 1118 | 141 | OK |
| 18/09 08:20 | 49069912 | `AFB120.txt_20260918082009` | B (16→17/09) | 11060 | **0** | **0** | **208 × Erreur 025** |

Extrait de `import/o49061539.out` (idem le 18/09) :

```
00001 >  0130003    01100EUR2 00020398294  150926   ...
 Erreur 025 : Journée manquante (date supérieure à celle du dernier relevé chargé)
```

Le dernier relevé SG chargé se termine au **11/09** ; le fichier du 17/09 commence au **15/09** → trou de continuité → rejet
de la totalité du fichier. Tant que le trou n'est pas comblé, **tous les fichiers SG suivants seront rejetés**.

## 5. Confirmation par le rapport de contrôle (`controle/`)

| Exécution | Date de référence | Lignes en anomalie |
|---|---|---|
| 09/09 08:26, 10/09 08:28, 11/09 08:29, 14/09 07:56 | veille | 1 (compte BPARA 16807 isolé, préexistant) |
| 15/09 07:52 | 14/09 | 208 dont **207 SG** |
| 16/09 07:51 | 15/09 | 208 dont **207 SG** |
| 17/09 07:21 et **08:26** | 16/09 | 208 dont **207 SG** – non résorbé après le flux B |
| 18/09 07:58 et **08:27** | 17/09 | 208 dont **207 SG** – non résorbé après le flux B |

Les 207 comptes SG apparaissent avec `DATE_DERNIER_IMPORT=14-SEP-26`, `DATE_DEBUT_RELEVE=10-SEP-26`,
`DATE_FIN_RELEVE=11-SEP-26` depuis le 15/09.

(Le run 49069846 du 18/09 07:49 liste aussi 128 comptes BNP : il a été lancé pendant l'import du flux A, ce n'est pas une anomalie.)

## 6. Rapprochement PFE ↔ EBS (`fluxPFE/`)

Chaque fichier `TARGET/compt_AFB120_RELEVESDECOMPTE_*.txt` de PFE a été comparé par md5 aux fichiers reçus par EBS :

| Exécution PFE | UUID | Contenu | Reçu par EBS ? |
|---|---|---|---|
| 11/09 07:46 | e11f956c… | flux A | ✅ identique |
| 11/09 08:16 | 785a9d6c… | flux B (09→10/09) | ✅ identique |
| 12/09 07:46 | 77bb3bfe… | flux A | ✅ identique (pas de 08:16 produit ce jour) |
| 14/09 07:16 | 2495cdaa… | 1 relevé 13825 | ✅ identique |
| 14/09 07:46 | 88767fca… | flux B (10→11/09) | ✅ identique |
| 15/09 07:46 | 9098a5f9… | flux A | ✅ identique |
| **15/09 08:16** | **2b6da61b…** | **flux B (11→14/09), 213 relevés, 8773 lignes** | ❌ **absent d'EBS** |
| 16/09 07:46 | 3d2a2a63… | flux A | ✅ identique |
| **16/09 08:16** | **f067afff…** | **flux B (14→15/09), 213 relevés, 8716 lignes** | ❌ **absent d'EBS** |
| 17/09 07:16 | 7bf52490… | flux A | ✅ identique |
| 17/09 08:16 | d114a1fb… | flux B (15→16/09) | ✅ identique (rejeté Err 025) |
| 18/09 07:46 | 62ac1b44… | flux A | ✅ identique |
| 18/09 08:16 | ddd884a6… | flux B (16→17/09) | ✅ identique (rejeté Err 025) |

Les deux exécutions manquantes sont complètes côté PFE (`SOURCE` présent, `TARGET` bien formé, `compteur_*.zip`, `TALEND/LS_IN.OK`).
**La perte se situe entre PFE et le répertoire EBS `/data/flf/files/PDBFINP1/data/in/`** : c'est la chaîne Control-M de
move / dézip qui n'a pas tourné (voir §7).

Chaîne des relevés SG une fois les fichiers rejoués :
`10→11/09 (chargé)` → `11→14/09 (PFE 15/09)` → `14→15/09 (PFE 16/09)` → `15→16/09 (EBS 17/09)` → `16→17/09 (EBS 18/09)`.

## 7. Analyse Control-M (`FichierODAT/`) – le job en erreur

Exports Control-M (`Report_ctm_<odate>_<heure>.csv`), application **FIN-FINANCE**. Attention : le nom des fichiers ne
reflète pas l'heure de capture ; la date de modification du fichier fait foi (ex. `Report_ctm_260914_14_16h45.csv`
a été capturé le 15/09 à 07:06, avant l'exécution de la chaîne).

L'import RB est piloté par deux groupes :

| Groupe | Rôle | Étapes |
|---|---|---|
| `FINEXT_J14INT_05_Q` | Chaîne du matin (one-shot) | `MOV01` move `Compteur.zip` depuis le NAS → `ZIP01` dézip → `CON01` concat en `AFB120.txt` → `WRK01` filtre → `IMP01` import RB → `MEL01` mail relevés manquants / `WRK02` édition CSP |
| `FINEXT_J14INT_06_Q` | Même chaîne en **cyclique**, « démarrant à 8h après `FINEXT_J14INT_05_Q` », pour les zips suivants (08:16) | idem |

### 7.1 Comparaison des trois matinées (snapshots pris à 08:06 / 07:36)

| Job | 15/09 (odate 14) | 16/09 (odate 15) | 17/09 (odate 16) |
|---|---|---|---|
| `FINEXT_J14INT_05_MOV01_Q` | 07:49:37 → 07:49:39 OK | 07:49:41 → 07:49:42 OK | 07:19:37 → 07:19:38 OK |
| `FINEXT_J14INT_05_ZIP01_Q` | 07:49:39 → 07:49:46 OK | 07:49:43 → 07:49:44 OK | 07:19:39 → 07:19:40 OK |
| `FINEXT_J14INT_05_IMP01_Q` | 07:49:50 → 07:52:19 OK (req 49041437) | 07:49:48 → 07:50:58 OK (req 49051565) | 07:19:43 → 07:20:56 OK (req 49061457) |
| **`FINEXT_J14INT_06_MOV01_Q`** | **07:49:37 → 07:49:46** (même seconde que la chaîne 05) | **07:49:41 → 07:49:42** (même seconde que la chaîne 05) | **pas déclenché** avec la chaîne 05 |
| **`FINEXT_J14INT_06_ZIP01_Q`** | **Ended Not OK, rerun 10** (07:50:02 → 07:51:05), oid `40ccp` | **Ended Not OK, rerun 10** (07:52:27 → 07:52:28), oid `40et5` | Wait for Event (normal) |
| `FINEXT_J14INT_06_CON01/WRK01/IMP01_Q` | jamais exécutés | jamais exécutés | exécutés à 08:16 (req 49061539 à 08:19) |
| Fichier de 08:16 importé dans EBS ? | ❌ | ❌ | ✅ |

### 7.2 Lecture

1. Les 15 et 16/09, le move de la chaîne cyclique **06 s'est déclenché à la même seconde que celui de la chaîne 05**
   (07:49), sur le même `Compteur.zip` de 07:46 (flux A). La chaîne 05 a récupéré le fichier et l'a importé normalement.
2. La chaîne 06 s'est retrouvée sans fichier : son dézip **`FINEXT_J14INT_06_ZIP01_Q`** a échoué 10 fois de suite et
   s'est terminé **Ended Not OK**. C'est le job en erreur de l'incident, deux jours de suite.
3. La chaîne cyclique étant bloquée sur ce Not OK, les zips `compteur_20260915_0816.zip` et `compteur_20260916_0816.zip`
   déposés par PFE à 08:16 n'ont jamais été movés ni importés.
4. Le 17/09 le flux A est arrivé plus tôt (07:16) ; le move de la chaîne 06 ne s'est pas déclenché en concurrence,
   la chaîne 06 est restée saine et a bien traité le zip de 08:16 (importé à 08:19, rejeté ensuite par EBS pour
   rupture de continuité – voir §4). Idem le 18/09 d'après les logs EBS (pas de snapshot Control-M).

### 7.3 Questions ouvertes pour l'exploitation / Control-M

- Quelle est la condition de démarrage de `FINEXT_J14INT_06_MOV01_Q` (time-from, événement fichier partagé avec la
  chaîne 05) ? Pourquoi se déclenche-t-il à 07:49 alors que la chaîne est censée démarrer à 8h ?
- Un snapshot 08:06 d'une journée normale (ex. odate 10 ou 11) permettrait de dire si cette concurrence existait déjà
  avant l'incident (et était sans effet) ou si elle est apparue le 15/09.
- Que fait `DEZIP_Generique_DKA.ksh` quand le zip est absent ? Après 10 reruns Not OK, la chaîne cyclique 06 doit se
  remettre en attente et non rester bloquée jusqu'au lendemain.
- Où sont passés `compteur_20260915_0816.zip` et `compteur_20260916_0816.zip` (toujours sur le NAS ?).

## 8. Plan de reprise

Prérequis : aucun import `RBAFBIMP` en cours ; le fichier `/data/flf/files/PDBFINP1/data/in/AFB120.txt` doit être absent
avant chaque dépôt. Traiter **un fichier à la fois, dans l'ordre**, et attendre la fin du request avant le suivant
(le contrôle de continuité impose l'ordre chronologique). Note : `/data/log/AFB120.txt.err` est écrasé à chaque exécution.

| Étape | Fichier source | Relevé SG | Résultat attendu (`Synthèse des relevés`) |
|---|---|---|---|
| 1 | `fluxPFE/2b6da61b5e384790970e4ab0b536102e/TARGET/compt_AFB120_RELEVESDECOMPTE_260915-081614.txt` | 11→14/09 | 207 chargés / 6 erreurs (5 × Err 001 + 1 × Err 025 habituels) |
| 2 | `fluxPFE/f067afff37d54178852c7c46a7048ab0/TARGET/compt_AFB120_RELEVESDECOMPTE_260916-081613.txt` | 14→15/09 | 207 chargés / 6 erreurs |
| 3 | `fichierBanque/AFB120.txt_20260917081953` | 15→16/09 | 207 chargés / 6 erreurs |
| 4 | `fichierBanque/AFB120.txt_20260918082009` | 16→17/09 | 207 chargés / 6 erreurs |

Pour chaque étape :

1. Copier le fichier sous le nom `AFB120.txt` dans `/data/flf/files/PDBFINP1/data/in/`.
2. Lancer le request **XXRB - Import fichier des banques (RBAFBIMP)**.
3. Vérifier dans le log : `Nombre de lignes écrites` > 0 et, dans la sortie, `Relevés chargés 207 / erreurs 6`.
   Si `Erreur 025` sur tous les comptes → l'ordre n'a pas été respecté, ne pas continuer.

Après l'étape 4 :

5. Lancer **DKA : Contrôle des relevés bancaires (DKA_SRBCTRLRB)** avec la date de référence 17/09/2026 :
   les 207 comptes SG doivent avoir disparu du rapport (il ne doit rester que la ligne BPARA 16807 préexistante).
6. Vérifier le 19/09 que le flux B de 08:16 arrive bien dans EBS et s'importe (207 chargés).

## 9. Points annexes (préexistants, hors incident)

- 19 comptes du flux A et 5 comptes du flux B en `Erreur 001 : Compte bancaire erroné` chaque jour (comptes non paramétrés dans EBS) – jamais chargés.
- Compte SG `03620 / 00020137269` en `Erreur 025` depuis avant le 08/09 – à traiter séparément.
- Compte BPARA `16807 / 00166 / 31990892212` toujours en anomalie dans le rapport de contrôle (dernier relevé 31/08).
- Le fichier SG du vendredi 12/09 n'a été produit que le lundi 14/09 à 07:46 (retard banque, sans conséquence : chargé).
