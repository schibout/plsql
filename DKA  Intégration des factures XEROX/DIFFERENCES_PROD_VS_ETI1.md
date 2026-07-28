# Comparaison des versions : PROD vs ETI1 (Dev)
## Package `dka_iapfacxgs_pkg`

Ce document résume les principales différences techniques et fonctionnelles identifiées entre la version de production (`DKA_IAPFACXGS_PKG_PROD.sql`) et la version de développement ETI1 (`DKA_IAPFACXGS_PKG_ETI1.sql`).

---

### 1. Détermination Dynamique de la Source et du Folio
**C'est le changement majeur de la version ETI1.**

- **En PROD :** La logique est principalement codée en dur pour distinguer les flux `XGS` et `DSP` (Ivalua). La source AP est systématiquement forcée à `'SCAN_XGS'`.
- **En ETI1 :** Introduction de trois nouvelles fonctions pour automatiser l'identification via le nom du fichier :
    - `get_prefix_from_filename` : Extrait le préfixe (ex: VE1, OCR, DSP).
    - `get_source_from_filename` : Détermine la source AP (`SCAN_XGS` ou `DEMAT`).
    - `get_folio_from_filename` : Détermine le folio (`XGS`, `DSP`, `OCR`, `DMT`).

**Préfixes supportés en ETI1 :**
| Préfixe | Source AP | Folio (Attribute9) |
|---------|-----------|--------------------|
| **VE1** | SCAN_XGS  | XGS                |
| **DSP** | SCAN_XGS  | DSP                |
| **ZCI** | SCAN_XGS  | XGS                |
| **OCR** | **DEMAT** | **OCR**            |
| **DMT** | **DEMAT** | **DMT**            |

---

### 2. Refactorisation de `insert_header`
- **En PROD :** La fonction `insert_header` insère systématiquement la valeur `'SCAN_XGS'` dans la colonne `SOURCE`.
- **En ETI1 :** 
    - Ajout d'un paramètre `pv_source` à la signature de la fonction.
    - L'insertion utilise désormais ce paramètre, permettant de gérer des sources variées (ex: `DEMAT`).

---

### 3. Gestion Multi-Source dans `child_import`
- **En PROD :** Le traitement est conçu pour un seul type de source par exécution.
- **En ETI1 :** 
    - Le tableau associatif `va_group_id` utilise désormais une clé composée : `source | group_id`.
    - Cela permet au package de lancer plusieurs programmes d'import standard (`APXIIMPT`) avec des origines différentes (ex: un import pour `SCAN_XGS` et un pour `DEMAT`) au cours d'une même session.

---

### 4. Élargissement des Filtres de Recherche
- Plusieurs curseurs ont été mis à jour pour inclure les nouveaux flux :
    - `cur_error` : Recherche désormais les rejets pour les sources `'SCAN_XGS'` et `'DEMAT'`.
    - `cur_ap_interface` : Filtre les factures en attente pour les deux sources.

---

### 5. Évolutions de Maintenance
- Ajout de commentaires de suivi signés `--shoussai` ou `--sho` identifiant les zones modifiées pour le support de la dématérialisation.
- Structure globale conservée mais volume de code augmenté (environ +135 lignes) pour intégrer ces nouvelles fonctions de parsing.

---

