
# Intégration des Notes de Frais - Notilus

## Contexte

Ce dossier contient les scripts de correction pour l'intégration des notes de frais provenant de **Notilus** dans Oracle EBS.

Les notes de frais qui n'ont pas pu être chargées lors de la clôture mensuelle nécessitent une mise à jour de leurs dates comptables. Un traitement de nuit passe ensuite pour les intégrer dans les modules AP (Accounts Payable) et GL (General Ledger).

---

## Tables Oracle Concernées

| Table | Description |
|-------|-------------|
| `AP_INVOICES_INTERFACE` | En-têtes des factures en interface (table de staging) |
| `AP_INVOICE_LINES_INTERFACE` | Lignes des factures en interface |

### Identification des Enregistrements Notilus

- **ATTRIBUTE9** = `'NOT'` → Identifiant source Notilus
- **ATTRIBUTE10** → Contient le nom du fichier batch (ex: `NOT01_SRC_FACTURESFOURNISSEURS_20260131231758`)

---

## Mode d’emploi (SQL Developer)

Le script principal à utiliser est : **Correction_Dates_Notilus.sql**.

### Prérequis
- Statut ciblé : **REJECTED** (le script filtre `Status = 'REJECTED'`).
- Identifier la période cible (1er jour du mois ouvert, ex: `01/02/26`).
- Optionnel : filtrer un fichier Notilus spécifique via `ATTRIBUTE10`.

### Étapes d’utilisation

1. **Ouvrir** le fichier **Correction_Dates_Notilus.sql** dans SQL Developer.
2. **Exécuter le bloc de paramètres** (Section 1) pour définir :
   - `v_nouvelle_date`
   - `v_source_notilus`
   - `nom_fichier` (NULL = tous les fichiers)
   - `v_statut_filtre` (REJECTED)
   - `mode_execution` (`SIMULATION` ou `MISE_A_JOUR`)

3. **Section 2** : Analyse des volumes + liste des fichiers (ATTRIBUTE10).

4. **Section 3** :
   - **SIMULATION** → affiche les volumes sans modifier la base.
   - **MISE_A_JOUR** → exécute les 3 mises à jour (lignes standard, lignes TAX, en‑têtes).

5. **Section 5** : Vérifications post‑correction (comptes par type de ligne, total, en‑têtes).

6. **Section 4** : `COMMIT` pour valider ou `ROLLBACK` pour annuler.

---

## Requêtes de Vérification (intégrées au script)

Le script exécute déjà :
- **Nombre d’en‑têtes modifiés**
- **Nombre de lignes par type** (TAX, ITEM, etc.)
- **Nombre total de lignes modifiées**

---

## Notes Importantes

1. **Statut REJECTED** : On ne modifie pas le statut, seule la date est changée. Le retraitement nocturne tentera à nouveau l'import.

2. **Période cible** : Toujours utiliser le 1er jour du mois ouvert (ex: `01/02/26` pour février 2026).

3. **Traitement nocturne** : Après la mise à jour des dates, le batch nocturne Oracle (`Payables Open Interface Import`) retraitera automatiquement les factures.

4. **Mode SIMULATION** : Aucun changement en base, uniquement des comptages.

---

## Fichiers du Dossier

| Fichier | Description |
|---------|-------------|
| `Correction_Dates_Notilus.sql` | Script principal (SQL Developer) avec mode SIMULATION / MISE_A_JOUR |
| `MOA - modif période dans O.I. pour Notilus_V2.sql` | Script historique / ancien format |

---

## Historique des Interventions

| Date | Période Cible | Volume | Commentaire |
|------|---------------|--------|-------------|
| 03/02/2026 | FEB-26 | ~261 en-têtes, ~1475 lignes | Correction période pour clôture JAN-26 |