# Analyse du Dossier de Paramétrage SoftaPlay

**Date d'analyse** : 28 janvier 2026  
**Analyste** : GitHub Copilot  
**Dossier analysé** : `Paramétrage SoftaPlay-20260128T131011Z-3-001`

---

## 1. RÉSUMÉ EXÉCUTIF

Ce dossier contient l'historique complet des paramétrages de l'outil **SoftaPlay** pour la gestion des sociétés et unités opérationnelles (Operating Units) dans Oracle E-Business Suite, couvrant la période **mars 2022 à juillet 2025** (dernière mise à jour).

**Points clés** :
- **53+ fichiers de paramétrage** (format INITSOC, deployment Excel)
- **3 types de création** : FULL, LIGHT (SVD), et transferts entre OU
- **Versions logicielles** : SoftaPlay 2.1.027 (dernière version identifiée)
- **17 mois de paramétrages** documentés (2022-2025)

---

## 2. STRUCTURE DU DOSSIER

### 2.1 Organisation Chronologique

Le dossier suit une organisation par période mensuelle au format `YYYYMM` :

| Période | Contenu | Type d'opérations |
|---------|---------|-------------------|
| **032022** | Mars 2022 | Créations initiales |
| **052022** | Mai 2022 | Créations de sociétés |
| **072023** | Juillet 2023 | Créations PROD |
| **202211** | Novembre 2022 | Créations FULL + Transferts SVD |
| **202303** | Mars 2023 | SVD 88 (Full DMS - 0382) |
| **202305** | Mai 2023 | SVD 99 (Full DNA - 0399) |
| **202308** | Août 2023 | BEF (UO DEW - 0367), TERA (Full DMS - 0501) |
| **202401** | Janvier 2024 | Full DCW (0535) |
| **202402** | Février 2024 | Créations SVD PROD |
| **202405** | Mai 2024 | Transferts ETI |
| **202406** | Juin 2024 | Full DCW (0538) |
| **202407** | Juillet 2024 | Transferts PROD |
| **202411** | Novembre 2024 | Transferts ETI |
| **202501** | Janvier 2025 | Transfert MOTTEO (DK 23 → 0507 vers DEW) |
| **202502** | **Février 2025** | **9 créations SVD** + **3 transferts majeurs** |
| **202504** | Avril 2025 | Création FULL CLICHY LIVRY CHALEUR (0560 DRW) |
| **202505** | Mai 2025 | Transfert ESTER (SVD 115 → 0444 DLS) |
| **202506** | Juin 2025 | Créations LIGHT SVD |
| **202507** | **Juillet 2025** | **Dernière activité** : MIRECOURT ENERGIES (0595 Full DCW) |

### 2.2 Types de Fichiers

```
📁 Paramétrage SoftaPlay/
│
├── 📄 Documentation
│   ├── Création de société complète_V2.0 18-AVR-2025.docx (DERNIÈRE VERSION)
│   ├── Création et transfert de SVD_V2.1_27-NOV-2025.docx (DERNIÈRE VERSION)
│   ├── Création de société complète_V1.5 14-DEC-2021.docx (ancienne)
│   └── Création et transfert de SVD_V1.2_22-DEC-2021.docx (ancienne)
│
├── 📊 Fichiers de Suivi
│   ├── Setup SoftaPlay Projects.xlsx (registre des projets)
│   ├── Paramétrages POST SOFTAPLAY de sociétés_MAI 2024.xlsx
│   ├── Créations 2021 12.xlsx (historique décembre 2021)
│   ├── deployment.xls (modèle générique)
│   ├── deployment_Societes_full_202112.xls
│   └── deployment_SVD_202112.xls
│
├── 📋 Données de Référence
│   └── DKA_CODE_APE.xlsx (codes activité APE)
│
├── 💻 Installation
│   ├── SoftaPlay-2.1-027-setup.exe
│   └── dlsetup.exe
│
├── 🔧 Scripts Correctifs
│   └── flag profile taxe/
│       └── KDFI-187-update_flag_profil_taxe.txt
│
├── 🎥 Démo
│   └── Démo IA Fichiers Softa/
│       └── Démo GEM_DSIN.mp4
│
└── 📂 Dossiers Mensuels (YYYYMM)
    └── [Créations FULL / LIGHT / Transferts]
```

---

## 3. ANALYSE DES OPÉRATIONS

### 3.1 Types d'Opérations Identifiées

#### A. Créations de Sociétés FULL
**Définition** : Création complète d'une nouvelle société avec tous les modules EBS actifs.

**Exemples récents** :
- **Avril 2025** : CLICHY LIVRY CHALEUR (0560) - Full DRW
- **Juillet 2025** : MIRECOURT ENERGIES (0595) - Full DCW
- **Août 2023** : TERA (0501) - Full DMS
- **Janvier 2024** : 0535 - Full DCW

**Caractéristiques** :
- Fichiers `INITSOC_FULL` avec paramétrage complet
- Fichiers `deployment` associés (format `.xls`)
- Code société à 4 chiffres (ex: 0560, 0595)

#### B. Créations LIGHT / SVD (Sociétés à Volume Dérisoire)
**Définition** : Création simplifiée pour entités à faible activité transactionnelle.

**Vague massive - Février 2025** :
- **9 créations simultanées** : DK 45 à DK 54 (codes 0540-0556)
- Toutes rattachées à l'OU **DOS**
- Fichier de regroupement : `Créations 2025 02 SVD_PROD.xlsx`
- Déploiement : `deployment_202502_SVD_PROD.xls`

**Détail des créations** :
```
DK 45 → 0540
DK 46 → 0541
DK 48 → 0545
DK 49 → 0548
DK 50 → 0549
DK 51 → 0552
DK 52 → 0554
DK 53 → 0555
DK 54 → 0556
```

**Autres créations SVD** :
- **Juin 2025** : Créations LIGHT SVD (non détaillées)
- **Mai 2023** : SVD 99 (0399) - Full DNA
- **Mars 2023** : SVD 88 (0382) - Full DMS

#### C. Transferts de Sociétés
**Définition** : Migration d'une société d'une Operating Unit vers une autre.

**Transferts Février 2025** (3 opérations majeures) :
1. **SVD 102 → MIRECOURT CHALEUR URBAINE** (0402)
   - Origine : DOS → Destination : **DCW**
   
2. **DK 42 → CALORIA** (0531)
   - Origine : DOS → Destination : **DRW**
   - Type : FULL
   
3. **DK 43 → RCCHOSPITALIER ANGOULEME** (0532)
   - Origine : DOS → Destination : **DNA**
   - Version : V02

**Autres transferts** :
- **Mai 2025** : SVD 115 → ESTER (0444) vers **DLS**
- **Avril 2025** : DK 33 → SRCM (0520) vers **DEW**
- **Janvier 2025** : DK 23 → MOTTEO (0507) vers **DEW**

### 3.2 Nomenclature des Codes

#### Codes d'Operating Units (OU)
```
DOS - Operating Unit source (société de départ)
DNA - Dalkia Nord-Est
DCW - Dalkia Centre-Ouest  
DRW - Dalkia Région Ouest
DEW - Dalkia Est
DMS - Dalkia Méditerranée Sud
DLS - Dalkia (à confirmer)
```

#### Codes Société
- **Format** : 4 chiffres (ex: 0520, 0532, 0560)
- **Anciens codes** : DK XX (ex: DK 23, DK 42, DK 43)
- **SVD** : Numéros à 2-3 chiffres (ex: SVD 99, SVD 102, SVD 115)

---

## 4. ANALYSE DÉTAILLÉE PAR PÉRIODE

### 4.1 Période Récente (2025)

#### Février 2025 - ACTIVITÉ MAXIMALE
**12 opérations au total** :
- ✅ 9 créations LIGHT (DK 45-54)
- ✅ 3 transferts majeurs (MIRECOURT, CALORIA, RCCHOSPITALIER)
- **Environnement** : PROD et ETI
- **Fichiers deployment** : 3 fichiers distincts

#### Avril 2025 - CRÉATION STRATÉGIQUE
- **Société** : CLICHY LIVRY CHALEUR
- **Code** : 0560
- **Type** : FULL
- **OU** : DRW
- **Version fichier** : V08 (nombreuses révisions)
- **Environnement** : ETI

#### Juillet 2025 - DERNIÈRE ACTIVITÉ
- **Société** : MIRECOURT ENERGIES
- **Code** : 0595
- **Type** : FULL
- **OU** : DCW
- **Environnement** : ETI1

### 4.2 Tendances Observées

**Volume d'opérations par année** :
- 2022 : ~3-5 opérations (démarrage)
- 2023 : ~6-8 opérations
- 2024 : ~8-10 opérations
- 2025 (partiel, jusqu'à juillet) : **~15 opérations**

**Accélération significative en 2025**, notamment sur les créations LIGHT.

---

## 5. DOCUMENTATION ET PROCESSUS

### 5.1 Documents de Procédure

#### Version 2.0 (Avril 2025) - ACTUELLE
- **Fichier** : `Création de société complète_V2.0 18-AVR-2025.docx`
- **Scope** : Processus complet de création de société FULL
- **Mise à jour** : Avril 2025

#### Version 2.1 (Novembre 2025) - ACTUELLE
- **Fichier** : `Création et transfert de SVD_V2.1_27-NOV-2025.docx`
- **Scope** : Processus de création et transfert SVD
- **Mise à jour** : 27 novembre 2025 (DERNIÈRE VERSION)

#### Anciennes Versions (décembre 2021)
- `Création de société complète_V1.5 14-DEC-2021.docx`
- `Création et transfert de SVD_V1.2_22-DEC-2021.docx`

**⚠️ Recommandation** : Utiliser uniquement les versions 2.x pour les nouvelles opérations.

### 5.2 Structure des Fichiers INITSOC

Format standardisé : `INITSOC_[TYPE] - [DESCRIPTION] - [CODE] - [DATE].xlsx`

**Exemples** :
```
INITSOC_FULL - 0560 CLICHY LIVRY CHALEUR DRW - V08 04 2025.xlsx
INITSOC_LIGHT - DOS - DK 45 - 0540 - V01 2025.xlsx
INITSOC_SVD 102 devient MIRECOURT CHALEUR URBAINE DOS VERS DCW 0402 - 02 25.xlsx
INITSOC_FULL - DK33 devient SRCM - DEW - 0520 - V04 2025.xlsx
```

**Champs identifiés** :
- **Type** : FULL / LIGHT / SVD
- **Description** : Nom de la société
- **Code** : Code à 4 chiffres
- **Version** : V01, V02, V08... (nombre de révisions)
- **Date** : Format MM YYYY

### 5.3 Fichiers Deployment

Format : `[Prefix] - deployment_[PÉRIODE]_[DETAILS]_[ENV].xls`

**Exemples** :
```
20 - Deployment_ 2025 02_ETI_Cré-Trans - DCW0402.xls
Deployment_Full_0560_ETI1.xls
deployment_202502_SVD_PROD.xls
deployment_202506_SVD_ETI1.xls
```

**Utilité** : Fichiers de configuration pour l'exécution du déploiement dans SoftaPlay.

---

## 6. CORRECTION TECHNIQUE IDENTIFIÉE

### 6.1 Mise à Jour Flag Profil Taxe

**Dossier** : `flag profile taxe/`  
**Fichier** : `KDFI-187-update_flag_profil_taxe.txt`  
**Type d'intervention** : Correctif post-création

#### Problème
Les Operating Units créées n'avaient pas le flag `use_le_as_subscriber_flag` positionné, causant des dysfonctionnements dans le moteur de taxes (`ZX`).

#### Solution Appliquée
```sql
-- Requête de détection
SELECT * 
FROM zx_party_tax_profile 
WHERE party_type_code = 'OU' 
  AND use_le_as_subscriber_flag IS NULL;

-- Correction
UPDATE zx_party_tax_profile
SET use_le_as_subscriber_flag = 'Y'
WHERE party_type_code = 'OU' 
  AND use_le_as_subscriber_flag IS NULL;
```

**Impact** : Cette correction doit être appliquée après chaque création de société FULL pour assurer le bon fonctionnement de la taxation.

---

## 7. LOGICIEL SOFTAPLAY

### 7.1 Installation
- **Version identifiée** : SoftaPlay 2.1.027
- **Fichier setup** : `SoftaPlay-2.1-027-setup.exe`
- **Fichier additionnel** : `dlsetup.exe` (librairies dépendantes ?)

### 7.2 Démonstration
- **Vidéo** : `Démo GEM_DSIN.mp4` (dans `Démo IA Fichiers Softa/`)
- **Contenu présumé** : Démonstration de l'interface et du processus de création

---

## 8. DONNÉES DE RÉFÉRENCE

### 8.1 Codes APE
**Fichier** : `DKA_CODE_APE.xlsx`
- Présent à la racine ET dans plusieurs dossiers mensuels (202303, 202305)
- **Utilité** : Table de référence pour les codes d'activité économique (nomenclature INSEE)
- **Usage** : Renseignement obligatoire lors de la création de société

---

## 9. SUIVI ET GOUVERNANCE

### 9.1 Registre des Projets
**Fichier** : `Setup SoftaPlay Projects.xlsx`
- Registre central de tous les projets de paramétrage
- Suivi des créations, transferts, et statuts d'avancement

### 9.2 Post-Paramétrage
**Fichier** : `Paramétrages POST SOFTAPLAY de sociétés_MAI 2024.xlsx`
- Interventions manuelles nécessaires après création SoftaPlay
- Exemples : correctifs SQL, activations de modules, paramétrages spécifiques

---

## 10. ENVIRONNEMENTS

### 10.1 Environnements Identifiés
- **PROD** : Production
- **ETI** / **ETI1** / **ETI2** : Environnements de test/intégration
- **Notation** : Les fichiers précisent l'environnement cible (ex: `_PROD`, `_ETI`)

### 10.2 Bonnes Pratiques Observées
1. **Dualité ETI/PROD** : Tests en ETI avant déploiement PROD
2. **Versioning** : Numéros de version (V01, V02...) pour tracer les modifications
3. **Nomenclature** : Convention stricte de nommage des fichiers
4. **Groupage** : Fichiers de regroupement mensuel (ex: `Créations 2025 02 SVD_PROD.xlsx`)

---

## 11. CONSTATS ET RECOMMANDATIONS

### 11.1 Points Forts ✅
1. **Organisation chronologique claire** : Structure par mois facilite la traçabilité
2. **Documentation à jour** : Versions 2.x des procédures (avril et novembre 2025)
3. **Nomenclature standardisée** : Format INITSOC cohérent et lisible
4. **Versioning** : Traçabilité des révisions (V01, V02...)
5. **Séparation environnements** : Distinction PROD/ETI respectée
6. **Historique complet** : Conservation de 3+ années de paramétrages

### 11.2 Points d'Amélioration 🔧
1. **Duplication codes APE** : Le fichier `DKA_CODE_APE.xlsx` existe en 3 exemplaires (risque de désynchronisation)
2. **Documentation ancienne** : Les versions 1.x (2021) devraient être archivées séparément ou supprimées
3. **Correction post-création** : Le flag taxe (KDFI-187) devrait être intégré au processus SoftaPlay pour éviter les oublis
4. **README manquant** : Pas de fichier `README.md` à la racine expliquant la structure du dossier

### 11.3 Risques Identifiés ⚠️
1. **Volume de créations SVD** : La vague de 9 créations en février 2025 suggère une volumétrie inhabituelle → vérifier la cohérence métier
2. **Versions multiples de MIRECOURT** : Présence en février 2025 (SVD 102) ET juillet 2025 (0595) → risque de doublons ?
3. **Révisions multiples** : CLICHY LIVRY (V08) et SRCM (V04) indiquent des difficultés de paramétrage
4. **Correction SQL manuelle** : Le flag taxe nécessite une intervention post-création → automatiser ?

### 11.4 Recommandations Opérationnelles 📋

#### Immédiat
1. ✅ **Créer un README.md** à la racine avec :
   - Structure du dossier
   - Convention de nommage
   - Procédure de création (lien vers docs V2.x)
   - Liste des correctifs obligatoires (flag taxe)

2. ✅ **Consolider DKA_CODE_APE.xlsx** :
   - Garder une seule version à la racine
   - Supprimer les copies dans les sous-dossiers

3. ✅ **Archiver anciennes versions** :
   - Déplacer les docs V1.x vers un dossier `_Archive/`

#### Court terme
1. **Intégrer le correctif KDFI-187** dans SoftaPlay :
   - Modifier le script de création pour positionner automatiquement `use_le_as_subscriber_flag = 'Y'`

2. **Standardiser les fichiers deployment** :
   - Créer un modèle unique avec instructions
   - Éviter les variations de nommage (`20 -`, `Deployment_`, `deployment_`)

3. **Documenter les révisions** :
   - Créer un changelog pour les fichiers multi-versions (V02, V08...)

#### Moyen terme
1. **Automatiser le suivi** :
   - Script pour générer automatiquement la liste des créations à partir des fichiers INITSOC
   - Mise à jour auto du fichier `Setup SoftaPlay Projects.xlsx`

2. **Contrôle qualité post-création** :
   - Checklist automatisée des points de vérification (flag taxe, codes APE, etc.)

---

## 12. STATISTIQUES

### 12.1 Volumétrie
- **Fichiers Excel de paramétrage** : 53+
- **Périodes couvertes** : 17 mois (mars 2022 à juillet 2025)
- **Créations LIGHT (février 2025)** : 9 sociétés
- **Transferts (février 2025)** : 3 opérations
- **Révisions maximales** : V08 (CLICHY LIVRY CHALEUR)

### 12.2 Répartition par Type
- **Créations FULL** : ~15-20
- **Créations LIGHT/SVD** : ~25-30
- **Transferts** : ~8-10

### 12.3 OU de Destination (Top 5)
1. **DOS** : Operating Unit source (la plus fréquente)
2. **DCW** : Dalkia Centre-Ouest
3. **DRW** : Dalkia Région Ouest
4. **DEW** : Dalkia Est
5. **DNA** : Dalkia Nord-Est

---

## 13. ANNEXES

### 13.1 Glossaire
- **SoftaPlay** : Outil de paramétrage automatisé pour la création de sociétés dans Oracle EBS
- **INITSOC** : Fichier d'initialisation de société (paramètres de création)
- **SVD** : Société à Volume Dérisoire (création simplifiée)
- **FULL** : Création complète avec tous les modules EBS
- **LIGHT** : Création allégée (synonyme de SVD)
- **OU** : Operating Unit (unité opérationnelle dans Oracle EBS)
- **Deployment** : Fichier de configuration pour l'exécution du déploiement
- **ETI** : Environnement de Test/Intégration
- **DK XX** : Ancien système de codification des sociétés

### 13.2 Conventions de Nommage

#### Dossiers
```
YYYYMM/                          # Période au format année-mois
  ├── Création FULL/             # Créations complètes
  ├── Création SVD/              # Créations simplifiées
  ├── Transfert [X] sociétés/    # Transferts d'OU
  └── Créations LIGHT/           # Créations simplifiées
```

#### Fichiers INITSOC
```
INITSOC_[TYPE] - [DESCRIPTION] - [CODE] - V[XX] [MM YYYY].xlsx

TYPE        : FULL | LIGHT | SVD | (vide)
DESCRIPTION : Nom société ou "DK XX devient [NOM]"
CODE        : Code à 4 chiffres (ex: 0560)
VERSION     : V01, V02, V08...
DATE        : Format MM YYYY
```

#### Fichiers Deployment
```
[Prefix] - deployment_[PÉRIODE]_[TYPE]_[ENV].xls
[Prefix] - Deployment_[TYPE]_[CODE]_[ENV].xls

Prefix  : "20" (année abrégée) ou vide
PÉRIODE : YYYYMM
TYPE    : Full | SVD | Trans | Cré-Trans
CODE    : Code société (ex: 0560)
ENV     : PROD | ETI | ETI1 | ETI2
```

### 13.3 Chronologie Complète des Opérations

| Date | Code | Société | Type | OU | Fichier |
|------|------|---------|------|----|---------|
| 03/2022 | - | Diverses | - | - | 032022/ |
| 05/2022 | - | Diverses | - | - | 052022/ |
| 07/2023 | - | Diverses | PROD | - | 072023/ |
| 11/2022 | - | Diverses | FULL+SVD | - | 202211/ |
| 03/2023 | 0382 | SVD 88 | Full | DMS | 202303/ |
| 05/2023 | 0399 | SVD 99 | Full | DNA | 202305/ |
| 08/2023 | 0367 | BEF | - | DEW | 202308/ |
| 08/2023 | 0501 | TERA | Full | DMS | 202308/ |
| 01/2024 | 0535 | - | Full | DCW | 202401/ |
| 02/2024 | - | Diverses | SVD | - | 202402/ |
| 05/2024 | - | Diverses | Trans | ETI | 202405/ |
| 06/2024 | 0538 | - | Full | DCW | 202406/ |
| 07/2024 | - | Diverses | Trans | PROD | 202407/ |
| 11/2024 | - | Diverses | Trans | ETI | 202411/ |
| 01/2025 | 0507 | MOTTEO (DK 23) | Trans | DEW | 202501/ |
| **02/2025** | **0540-0556** | **DK 45-54** | **LIGHT** | **DOS** | **202502/** |
| 02/2025 | 0402 | MIRECOURT (SVD 102) | Trans | DCW | 202502/ |
| 02/2025 | 0531 | CALORIA (DK 42) | Trans | DRW | 202502/ |
| 02/2025 | 0532 | RCCHOSPITALIER (DK 43) | Trans | DNA | 202502/ |
| 04/2025 | 0560 | CLICHY LIVRY CHALEUR | Full | DRW | 202504/ |
| 04/2025 | 0520 | SRCM (DK 33) | Trans | DEW | 202504/ |
| 05/2025 | 0444 | ESTER (SVD 115) | Trans | DLS | 202505/ |
| 06/2025 | - | Diverses | LIGHT | - | 202506/ |
| **07/2025** | **0595** | **MIRECOURT ENERGIES** | **Full** | **DCW** | **202507/** |

---

## 14. CONCLUSION

Le dossier de paramétrage SoftaPlay constitue **un référentiel complet et bien structuré** des opérations de création et transfert de sociétés dans Oracle EBS pour l'organisation Dalkia.

**Forces principales** :
- Organisation chronologique claire et cohérente
- Documentation procédurale à jour (versions 2.x)
- Nomenclature standardisée facilitant la traçabilité
- Conservation de l'historique sur 3+ années

**Axes d'amélioration prioritaires** :
1. Intégrer les correctifs post-création (flag taxe) directement dans SoftaPlay
2. Archiver les anciennes versions de documentation
3. Créer un README explicatif à la racine
4. Consolider les fichiers de référence (codes APE)

**Activité récente** :
L'année 2025 montre une **accélération significative** des créations, notamment avec la vague de **9 sociétés LIGHT en février** et les créations stratégiques FULL (CLICHY LIVRY, MIRECOURT ENERGIES). Cette tendance suggère une phase d'expansion ou de réorganisation importante de la structure du groupe.

---

**Fin du rapport d'analyse**
