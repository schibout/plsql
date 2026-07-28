# Documentation FLOW_LOGS - Jobs Talend Oracle EBS

**Date de création** : 30/12/2024  
**Base de données** : Oracle EBS 19.25.0.0.0 (Production)  
**Schéma** : DKA (Custom Dalkia)

## Vue d'ensemble

Les tables de logs des flux Talend sont stockées dans le schéma **DKA** et servent à tracer les exécutions des jobs d'intégration ETL entre Oracle EBS et les systèmes externes (iValua, Hercule, Xerox, EAI).

## Architecture des tables de logs

### 1. DKA_SCTLFLUX_EAI - Logs des flux comptables vers EAI/Hercule

**Usage** : Traçabilité des exports comptables (journaux GL) vers le système décisionnel Hercule.

**Structure** :
| Colonne | Type | Description |
|---------|------|-------------|
| CODE_FOLIO | VARCHAR2(150) | Code du folio/batch comptable |
| DATE_EXEC | VARCHAR2(10) | Date d'exécution (format texte) |
| NB_PIECE | NUMBER | Nombre de pièces comptables traitées |
| DEBIT | NUMBER | Montant total débit |
| CREDIT | NUMBER | Montant total crédit |
| FICHIER | VARCHAR2(150) | Nom du fichier généré |
| TRAITE | NUMBER | Flag de traitement (0=non traité, 1=traité) |
| N_TRAITEMENT | NUMBER | Numéro de traitement |
| DATE_DEBUT | DATE | Date/heure début traitement |
| DATE_FIN | DATE | Date/heure fin traitement |
| CREATED_BY | NUMBER | User ID créateur |
| CREATION_DATE | DATE | Date création enregistrement |

**Volumétrie estimée** : Quotidienne (exports de nuit)

**Jobs Talend associés** : Export journaux comptables (voir KDFI-2198-ControleFlux/)

---

### 2. DKA_IAPCTRFLUX_IVALUA - Logs des flux factures iValua

**Usage** : Contrôle des flux d'import de factures depuis iValua (3 flux : Import, Export, Contrôle).

**Structure** :
| Colonne | Type | Description |
|---------|------|-------------|
| NOM_FICHIER | VARCHAR2(50) | Nom du fichier traité |
| DATE_ENVOI | DATE | Date d'envoi du fichier |
| COMPANY_VALUE | VARCHAR2(3) | Code société (Operating Unit) |
| NB_INVOICES_PROCESSED | VARCHAR2(20) | Nombre de factures traitées |
| NB_INVOICES_REJECTED | VARCHAR2(20) | Nombre de factures rejetées |
| NB_TRA_FILE | VARCHAR2(20) | Nombre de lignes TRA |
| NB_PNC_FILE | VARCHAR2(20) | Nombre de lignes PNC |
| STATUS | VARCHAR2(3) | Statut traitement (OK/KO/...) |
| CREATED_BY | NUMBER | User ID créateur |
| CREATION_DATE | DATE | Date création |
| LAST_UPDATE_DATE | DATE | Dernière modification |
| LAST_UPDATED_BY | NUMBER | Dernier modificateur |
| LAST_UPDATE_LOGIN | NUMBER | Session de modification |

**Volumétrie estimée** : Multiple par jour (selon fréquence imports iValua)

**Intégration** : Voir dossier Ivalua/ pour les vérifications de chargement

---

### 3. DKA_IAPCTRFLUX_XEROX - Logs des flux Xerox

**Usage** : Contrôle des flux d'import de factures depuis Xerox (legacy).

**Structure** : Identique à DKA_IAPCTRFLUX_IVALUA (même colonnes)

**Note** : Flux probablement obsolète ou en cours de migration vers iValua.

---

### 4. DKA_SCTLFLUX_ARFLAG_EAI - Logs des flags AR vers EAI

**Usage** : Traçabilité des exports de factures clients (AR) vers systèmes externes.

**Structure** :
| Colonne | Type | Description |
|---------|------|-------------|
| ORIGIN | VARCHAR2(15) | Origine de la facture |
| COMPANY_CODE | VARCHAR2(4) | Code société |
| INVOICE_NUMBER | VARCHAR2(8) | Numéro de facture AR |
| FIC_IDENT | VARCHAR2(150) | Identifiant fichier |
| REQUEST_ID | NUMBER | ID du concurrent program Oracle |
| CREATED_BY | NUMBER | User ID créateur |
| CREATION_DATE | DATE | Date création |

**Lien Oracle EBS** : REQUEST_ID permet de tracer le job dans FND_CONCURRENT_REQUESTS

---

### 5. Tables temporaires

- **DKA_IAPCTRFLUX_IVALUA_TMP** : Staging iValua
- **DKA_IAPCTRFLUX_XEROX_TMP** : Staging Xerox
- **DKA_EMPLOYEE_JOBS_TMP** : Temporaire RH (non Talend)
- **DKA_SGLCTRLFLUXIFRS_TMP** : Contrôle flux IFRS (temporaire)

---

## Monitoring et Diagnostics

### Indicateurs clés (KPIs)

1. **Fréquence des exécutions** : Nombre de jobs par jour/heure
2. **Durée de traitement** : DATE_FIN - DATE_DEBUT (DKA_SCTLFLUX_EAI)
3. **Volumétrie** : Nombre de pièces/factures traitées
4. **Taux d'erreur** : Factures rejetées / factures traitées (iValua)
5. **Intégrité comptable** : Vérification DEBIT = CREDIT (DKA_SCTLFLUX_EAI)

### Cas d'usage typiques

1. **Incident iValua** : Vérifier DKA_IAPCTRFLUX_IVALUA.STATUS et NB_INVOICES_REJECTED
2. **Export Hercule manquant** : Requête sur DKA_SCTLFLUX_EAI.TRAITE = 0
3. **Performance dégradée** : Analyser durée jobs via DATE_DEBUT/DATE_FIN
4. **Audit trail** : Cross-check REQUEST_ID avec FND_CONCURRENT_REQUESTS

---

## Relations avec autres systèmes

### Liens Oracle EBS

- **DKA_SCTLFLUX_ARFLAG_EAI.REQUEST_ID** → FND_CONCURRENT_REQUESTS.REQUEST_ID
- **USER_ID fields** → FND_USER.USER_ID
- **COMPANY_CODE** → HR_OPERATING_UNITS.ORGANIZATION_ID

### Liens externes

- **iValua** : Import factures AP (3 flux documentés dans Ivalua/)
- **Hercule** : Export GL/AP/PO pour décisionnel (voir Rapport_Traitements_Flux_DKA_SCTLFLUX_EAI.md)
- **Xerox** : Import factures AP (legacy)

---

## Références

- **Analyse flux EAI** : KDFI-2198-ControleFlux/Analyse_DKA_SCTLFLUX_EAI_Avoirs.md
- **Package contrôle** : KDFI-2198-ControleFlux/APPS.DKA_SCTLFLUX_EAI_PKG.pkb
- **Vérifications iValua** : Ivalua/Vérification chargmt depuis iValua.sql

---

## Notes techniques

- **Schéma propriétaire** : DKA (Custom Dalkia)
- **Audit standard Oracle** : Colonnes CREATED_BY, CREATION_DATE, LAST_UPDATE_DATE, LAST_UPDATED_BY
- **Pas de contraintes PK documentées** : Vérifier avant insertion bulk
- **Format dates** : DATE_EXEC en VARCHAR2 (attention conversions)
