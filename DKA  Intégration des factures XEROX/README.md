# Documentation du Package `dka_iapfacxgs_pkg`

## Présentation Générale
Le package `dka_iapfacxgs_pkg` est le composant central de l'interface d'intégration des factures fournisseurs numérisées. Initialement conçu pour **Xerox (XGS)**, il a évolué pour supporter d'autres sources comme **ZCI** et **DSP (Ivalua)**.

Son rôle est de transformer les données brutes issues de la numérisation en factures exploitables dans le module **Oracle Payables (AP)** en passant par l'Open Interface standard.

## Fonctionnalités Clés
- **Multi-Source** : Support de XeroX (XGS), ZCI et DSP/Ivalua.
- **Rapprochement Automatique** : Réconciliation avec les Commandes d'Achat (PO) ou les Bons de Réception (BL).
- **Gestion des Règles Métier (CAS 1 à 9)** : Application de logiques complexes selon le type de taxe (IC, TVA Immo), les écarts de montants et les types de prestations (SSTRT).
- **Contrôle de Doublons** : Détection des doublons réels et des "faux doublons" (même numéro mais montants/dates différents).
- **Validation Comptable** : Vérification des périodes ouvertes et cohérence des régions (UO vs Commande).
- **Reporting Intégré** : Suivi détaillé de l'état d'intégration dans des tables de reporting dédiées.

## Architecture Technique

### 1. Flux d'Intégration
Le processus se déroule généralement en trois étapes :
1. **Peuplement (`populate_xxx_tables`)** : Les données sont déplacées des tables temporaires (`DKA_IAPFACXGS_TMP`) vers la table d'interface principale (`DKA_IAPFACXGS_INTERFACE`) et les tables d'historique.
2. **Traitement (`import` / `child_import`)** : 
   - Analyse de chaque facture.
   - Calcul des taxes et des imputations.
   - Application des règles de rapprochement.
   - Insertion dans les tables standards Oracle : `AP_INVOICES_INTERFACE` et `AP_INVOICE_LINES_INTERFACE`.
3. **Import Standard** : Lancement du programme concurrent standard Oracle `APXIIMPT` (Open Interface Import) pour valider et créer les factures définitives.

### 2. Procédures Principales
- `import` : Point d'entrée principal. Identifie les organisations (OU) concernées et lance le traitement par bloc.
- `child_import` : Cœur de la logique métier pour une organisation donnée.
- `control_double` : Procédure de nettoyage et de marquage des doublons avant l'import.
- `populate_xgs_tables` / `populate_zci_tables` / `populate_dsp_tables` : Procédures de chargement initial selon la source.

### 3. Tables Utilisées
| Table | Description |
|-------|-------------|
| `DKA_IAPFACXGS_INTERFACE` | Table de staging principale pour les données numérisées. |
| `DKA_IAPFACXGS_REPORTING_ALL` | Suivi en temps réel du statut de chaque facture (OK, KO, Erreur). |
| `DKA_IAPFACXGS_INT_HIST_HEADS/LINES` | Archive historique des intégrations passées. |
| `AP_INVOICES_INTERFACE` | Table d'entête standard pour l'import Oracle AP. |
| `AP_INVOICE_LINES_INTERFACE` | Table de lignes standard pour l'import Oracle AP. |

## Règles de Rapprochement (Résumé)
Le package applique différentes stratégies selon la qualité des données reçues :
- **ALLCDE** : Rapprochement global sur toute la commande si les montants correspondent.
- **BL** : Rapprochement spécifique basé sur le numéro de bon de livraison/réception.
- **SSTRT** : Logique dédiée aux factures de sous-traitance (Ivalua).
- **GENERAL** : Rapprochement ligne à ligne pour les commandes simples.
- **Imputation en attente** : Si le rapprochement automatique échoue, la facture est intégrée avec un blocage pour revue manuelle.

## Maintenance et Diagnostics
En cas d'erreur lors de l'intégration :
1. Consulter la table `DKA_IAPFACXGS_REPORTING_ALL` pour identifier la facture en erreur via le champ `DESCRIPTION_ANO_INTERFACE`.
2. Vérifier les logs du programme concurrent `IAPFACXGS` (ou équivalent selon la source).
3. Les erreurs fréquentes incluent : Fournisseur non trouvé, Période comptable fermée, ou écart de région entre la facture et la commande.

---
*Dernière mise à jour basée sur l'analyse du code source (Mars 2026).*
