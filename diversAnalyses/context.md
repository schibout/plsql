# Oracle EBS R12 Environment Context

## System Information
- **EBS Version**: 12.2.13
- **Database**: Oracle Database 19c EE Extreme Perf (19.0.0.0.0)
- **Environment Type**: Production (PDB: ebs_PDBFINP1)
- **Host**: prdscanc1pdb03.dalkia.net
- **Oracle User**: `aroux`

## Key Schemas & Objects Count
- **GL** (General Ledger): ~109,555 tables/objects
- **DKA** (Custom Dalkia): 2,173 tables/objects
- **AR** (Accounts Receivable): 762 tables
- **PO** (Purchasing): 348 tables
- **AP** (Accounts Payable): 327 tables
- **FA** (Fixed Assets): 222 tables
- **XLA** (Subledger Accounting): 177 tables

## Core Technical Concepts (Oracle EBS R12)
- **Multi-Org**: Utilisation de `ORG_ID` pour séparer les entités opérationnelles (Operating Units).
- **Flexfields**:
  - **Accounting Flexfield (KFF)**: Structure de la COA (Chart of Accounts) dans GL.
  - **Descriptive Flexfields (DFF)**: Attributs personnalisés (`ATTRIBUTE1..15`).
- **Concurrent Processing**: Gestion des jobs via `FND_CONCURRENT_REQUESTS`.
- **SLA (Subledger Accounting)**: Moteur `XLA` qui fait le lien entre les modules (AP, AR, PO) et la comptabilité générale (GL).

## Specific Dalkia Customizations
- **Prefix**: `DKA`
- **Interfaces**:
  - **APIMPORT**: Importation des factures fournisseurs.
  - **IARPAFAC**: Probablement lié à l'interface AR/AP.
  - **SoftaPlay**: Intégration mentionnée dans les fichiers locaux.
- **Workflow**: Utilisation intensive de l'AME (Approval Management Engine).

## Organizational Structure (Operating Units)
### Top 10 Operating Units by Volume
| OU Name | OU ID | Total Invoices | Invoices (30d) | Total PO | PO (30d) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DSW0001** | 91 | 1,904,735 | 20,952 | 679,478 | 5,348 |
| **DMS0001** | 88 | 1,446,489 | 16,306 | 541,869 | 5,166 |
| **DRW0001** | 90 | 1,247,737 | 11,605 | 652,724 | 4,908 |
| **DEW0001** | 86 | 856,155 | 9,678 | 400,916 | 3,483 |
| **DNA0001** | 89 | 811,466 | 7,893 | 340,951 | 3,480 |
| **DCW0001** | 85 | 690,298 | 7,497 | 278,542 | 2,540 |
| **DLS0001** | 87 | 673,009 | 6,560 | 281,440 | 2,242 |
| **DOS0001** | 82 | 236,895 | 1,272 | 45,636 | 335 |
| **DMS0441** | 107 | 228,262 | 2,737 | 172,811 | 1,713 |
| **DOS0119** | 249 | 157,332 | 2,486 | 93,894 | 1,520 |

*Note: Le volume total d'invoices dépasse les 8 millions de lignes sur l'ensemble des OUs.*

## Concurrent Processing Statistics (Last 30 Days)
### Top Custom Programs (DKA)
1. **DKA : Création du fichier avis de virement** (`DKA_RAPVIR_PDF`) : ~20,121 exécutions.
2. **DKA : Création blocages comptabilisation factures AP** (`DKA_SAPCREATE_BLOCAGES`) : ~12,614 exécutions.
3. **DKA : Créer une comptabilisation - Immobilisations** (`DKA_SFAACCPB`) : ~6,672 exécutions.
4. **DKA : Lanceur (SHELL)** (`DKA_SLAUNCHER`) : ~4,618 exécutions (Moyenne 9.5 min).
5. **DKA : Import des donnees depuis l'open Interface AP** (`DKA_OPEN_INTERFACE_AP_EAI`) : ~1,664 exécutions.

### Top Standard Programs
1. **Créer une comptabilisation** (`XLAACCPB`) : ~15,059 exécutions.
2. **Créer une comptabilisation - Immobilisations** (`FAACCPB`) : ~13,318 exécutions.
3. **EasyLink** (`GLLEZL`) : ~12,073 exécutions.
4. **Validation de factures** (`APPRVL` + `WORKERAPPRVL`) : ~16,700 exécutions cumulées.
5. **Programme d'importation de l'interface coopérative Payables** (`APXIIMPT`) : ~7,421 exécutions.

## Essential Tables Reference
### Foundation (FND)
- `FND_USER`: Utilisateurs de l'application.
- `FND_RESPONSIBILITY_VL`: Responsabilités.
- `FND_CONCURRENT_PROGRAMS_VL`: Définitions des programmes.
- `FND_CONCURRENT_REQUESTS`: Historique et état des jobs.

### General Ledger (GL)
- `GL_JE_BATCHES`: Lots d'écritures.
- `GL_JE_HEADERS`: En-têtes d'écritures.
- `GL_JE_LINES`: Lignes d'écritures.
- `GL_CODE_COMBINATIONS`: Combinaisons comptables (CCID).
- `GL_INTERFACE`: Table pivot pour l'import d'écritures.

### Accounts Payable (AP)
- `AP_INVOICES_ALL`: Factures.
- `AP_INVOICE_LINES_ALL`: Lignes de factures.
- `AP_INVOICE_DISTRIBUTIONS_ALL`: Ventilations comptables.
- `AP_SUPPLIERS`: Fournisseurs (ex `PO_VENDORS`).
- `AP_SUPPLIER_SITES_ALL`: Sites fournisseurs.

### Purchasing (PO)
- `PO_HEADERS_ALL`: Commandes d'achat.
- `PO_LINES_ALL`: Lignes de commandes.
- `PO_REQUISITION_HEADERS_ALL`: Demandes d'achat.

## Common Diagnostic Queries
- **Vérifier un job**: `SELECT status_code, phase_code FROM fnd_concurrent_requests WHERE request_id = :id;`
- **Trouver les responsabilités d'un user**: `SELECT frt.responsibility_name FROM fnd_user fu, fnd_user_resp_groups_direct furg, fnd_responsibility_tl frt WHERE fu.user_id = furg.user_id AND furg.responsibility_id = frt.responsibility_id AND fu.user_name = :username;`
