# Synthèse du Script de Recherche de Facture

**Date de création** : 21/05/2024  
**Fichier SQL associé** : `Recherche_Facture_11633263.sql`  
**Base de données** : Oracle E-Business Suite

---

## 1. Objectif du script

Ce script SQL a pour but de fournir une **vue complète à 360°** d'une facture fournisseur spécifique dans Oracle EBS. Il a été conçu pour regrouper en une seule exécution toutes les informations pertinentes, de la fiche fournisseur jusqu'au paiement final.

Il est particulièrement utile pour :
- Analyser une facture en détail.
- Investiguer des anomalies de paiement ou de comptabilisation.
- Répondre rapidement à des demandes métier concernant une transaction.

---

## 2. Paramètres de Recherche

Le script est structuré pour être facilement adaptable. Les principaux paramètres à modifier pour une nouvelle recherche se trouvent dans les clauses `WHERE` de chaque partie :

- **Numéro Fournisseur** : `APS.SEGMENT1 = '27254'`
- **Code Site Fournisseur** : `APSA.VENDOR_SITE_CODE = 'FRA35510'`
- **Numéro de Facture** : `AIA.INVOICE_NUM = '11633263'`

---

## 3. Structure Détaillée du Script

Le script est divisé en 5 parties logiques, chacune interrogeant un aspect différent du processus de facturation.

### Partie 1 : Informations générales du fournisseur
*   **Table principale** : `AP.AP_SUPPLIERS`
*   **Informations extraites** :
    *   ID et nom du fournisseur.
    *   Numéro (`segment1`), type et statut (`ACTIF`).
    *   Dates de validité.

### Partie 2 : Détails du site fournisseur
*   **Tables principales** : `AP.AP_SUPPLIER_SITES_ALL`, `HR.HR_OPERATING_UNITS`
*   **Informations extraites** :
    *   Adresse complète du site.
    *   Unité Opérationnelle (`Operating Unit`).
    *   Flags indiquant si c'est un site de paiement (`PAY_SITE_FLAG`) ou d'achats (`PURCHASING_SITE_FLAG`).
    *   Méthode de paiement par défaut.

### Partie 3 : Informations sur la facture (En-tête)
*   **Table principale** : `AP.AP_INVOICES_ALL`
*   **Informations extraites** :
    *   Montant, date, devise et description de la facture.
    *   Statut de paiement (`Y`=Payée, `N`=Non Payée, `P`=Partiellement Payée).
    *   Montant déjà payé.
    *   Utilisateur ayant créé la facture.

### Partie 4 : Lignes de distribution (Imputations comptables)
*   **Tables principales** : `AP.AP_INVOICE_DISTRIBUTIONS_ALL`, `GL.GL_CODE_COMBINATIONS_KFV`
*   **Informations extraites** :
    *   Les différentes lignes d'imputation de la facture.
    *   Le code comptable complet (`CONCATENATED_SEGMENTS`).
    *   Le montant associé à chaque imputation.

### Partie 5 : Paiements liés à la facture
*   **Tables principales** : `AP.AP_INVOICE_PAYMENTS_ALL`, `AP.AP_CHECKS_ALL`
*   **Informations extraites** :
    *   Le montant du paiement.
    *   La date et le statut du paiement (ex: `NEGOTIABLE`, `VOIDED`).

---

## 4. Utilisation

Pour utiliser ce script, il suffit de copier l'intégralité de son contenu et de le coller dans un client SQL connecté à la base de données Oracle (comme SQL Developer, DBeaver, etc.). Les résultats de chaque partie s'afficheront les uns après les autres.

---

## 5. Signification des Attributs (Exemples)

Les tables Oracle EBS contiennent des colonnes génériques `ATTRIBUTE1`, `ATTRIBUTE2`, etc., dont la signification dépend du contexte et du paramétrage. Voici quelques exemples d'utilisation identifiés dans vos scripts :

| Table / Contexte | Colonne | Valeur / Paramétrage | Signification |
| :--- | :--- | :--- | :--- |
| `AP_INVOICES_INTERFACE` | `ATTRIBUTE9` | `'NOT'` | Identifie une facture provenant de l'interface **Notilus** (notes de frais). |
| `AP_INVOICES_INTERFACE` | `ATTRIBUTE10` | Nom du fichier batch | Stocke le nom du fichier d'origine de l'interface Notilus. |
| `AP_INVOICES_INTERFACE` | `GLOBAL_ATTRIBUTE1` | `'CRE/M'` ou `'DEB/M'` | Régime fiscal (Crédit/Débit). Déterminé par `XXEAI_INTERFACE_TOOLS_PKG`. |
| `AP_INVOICE_LINES_INTERFACE` | `ATTRIBUTE1` | ID du projet de refacturation | Utilisé dans les cas de refacturation inter-sociétés. |
| `AP_INVOICE_LINES_INTERFACE` | `ATTRIBUTE7` | ID de la tâche de refacturation | Utilisé dans les cas de refacturation inter-sociétés. |
| `GL_INTERFACE` (CUF) | `CONTEXT3` | `'Y.E.X'`, `'MAT'`, `'FRAIS'`... | Contexte de la clé comptable pour déterminer les segments à utiliser. |
| `GL_INTERFACE` (CUF) | `ATTRIBUTE11` | ID du projet ou Matricule | Stocke l'ID du projet ou le matricule de l'employé (contexte `MAT`). |
| `GL_INTERFACE` (CUF) | `ATTRIBUTE12` | Type d'événement PA | Pour les comptes de produits (classe 7), stocke le type d'événement Oracle Projects. |
| `GL_INTERFACE` (CUF) | `ATTRIBUTE13` | Type de dépense PA | Pour les comptes de charges (classe 6), stocke le type de dépense Oracle Projects. |
| `GL_INTERFACE` (CUF) | `ATTRIBUTE14` | Quantité | Quantité associée à la ligne de dépense/événement. |
| `GL_INTERFACE` (CUF) | `ATTRIBUTE15` | ID du projet à refacturer | Dans un flux de refacturation, stocke le projet initial. |
| `GL_INTERFACE` (CUF) | `ATTRIBUTE17` | ID de la tâche | ID de la tâche du projet. |
| `GL_INTERFACE` (CUF) | `ATTRIBUTE18` | ID de la tâche à refacturer | Dans un flux de refacturation, stocke la tâche initiale. |

---

Pour utiliser ce script, il suffit de copier l'intégralité de son contenu et de le coller dans un client SQL connecté à la base de données Oracle (comme SQL Developer, DBeaver, etc.). Les résultats de chaque partie s'afficheront les uns après les autres.