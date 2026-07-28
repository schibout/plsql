# Oracle EBS Finance - PL/SQL Analysis Repository

## System Context

**Environment**: Oracle E-Business Suite 12.2.13 Production (Database 19.25.0.0.0)  
**Primary Focus**: Financial operations analysis for Dalkia organization  
**Language**: French documentation, SQL/PL/SQL code  
**Connection**: Database accessed via `oracleProd` connection (SQLcl MCP server)

This workspace contains SQL queries and analysis documents for Oracle EBS financial modules (AP, GL, PO, XLA, FA). Files document production incidents, performance issues, and corrective solutions.

## Architecture & Data Flows

### Core EBS Modules Interaction

**Sub-Ledger to General Ledger Flow**:
```
AP/PO Transactions → RCV_TRANSACTIONS → XLA_DISTRIBUTION_LINKS → XLA_AE_LINES → GL_JE_LINES
```

**Critical Architectural Change (NOV-25)**: Oracle XLA stopped populating `APPLIED_TO_DIST_ID_NUM_1` field. Receipt accruals now ONLY link through `RCV_RECEIVING_SUB_LEDGER` → `RCV_TRANSACTIONS.TRANSACTION_ID` path. See `README_Changement_APPLIED_TO_NOV25.md` for migration pattern.

### Key External Integrations

- **iValua**: Supplier and invoice data exchange (3 flows: Import, Export, Control)
- **Hercule**: Decision support system data extraction
- **Custom DKA packages**: Supplier site duplication/synchronization (`DKA_SAPFRSDUPLI_*`)

## Critical Patterns & Conventions

### Query Structure for Provisions (Receipt Accruals)

**CORRECT Pattern (post-NOV-25)**:
```sql
-- Join via RCV_TRANSACTIONS, not APPLIED_TO_DIST_ID_NUM_1
LEFT OUTER JOIN PO.RCV_TRANSACTIONS RT
    ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
    AND XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'

LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
    ON PDA.PO_DISTRIBUTION_ID = COALESCE(
        XDL.APPLIED_TO_DIST_ID_NUM_1,  -- OCT-25 compatibility
        RT.PO_DISTRIBUTION_ID           -- NOV-25 required
    )

WHERE RT.TRANSACTION_ID IS NOT NULL  -- Filter on RCV, not PDA
```

See `Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql` for complete implementation.

### Period Naming Convention

- Format: `MMM-YY` (e.g., `NOV-25`, `OCT-25`)
- Batch naming: `PROVISION_<ENTITY>_<PERIOD>_<SEQ>_` (e.g., `PROVISION_ECOLIANE_NOV-25_1_`)
- Retroactive provisions: OCT-25 provisions may appear in NOV-25 GL period during month-end close

### Concurrent Program Analysis Pattern

Common queries analyze Oracle concurrent programs via:
- `FND_CONCURRENT_PROGRAMS_VL`: Program metadata
- `FND_CONCURRENT_REQUESTS`: Execution history with `REQUEST_ID`
- Duration calculation: `(ACTUAL_COMPLETION_DATE - ACTUAL_START_DATE) * 24 * 60` (minutes)
- See `Definition_programme_maj_sites_fournisseurs.sql`

## Known Issues & Workarounds

### Supplier Site Duplication Performance

**Problem**: `DKA_SAPFRSDUPLI_MAJ` program normally runs in 18 seconds but degraded to 10+ hours when processing >27,000 sites (incident NOV-27/28).

**Root Cause**:
- No intermediate COMMITs (processes all sites in single transaction)
- Sequential processing without BULK COLLECT
- 7-table cursor join for each site
- See `Rapport_detaille_incident_maj_sites_fournisseurs.md`

**When Analyzing Concurrent Program Issues**:
1. Check execution history: look for abnormal durations via `FND_CONCURRENT_REQUESTS`
2. Identify data volume spikes: count records modified between executions
3. Trace to user: check `LAST_UPDATED_BY` and `LAST_UPDATE_DATE` patterns
4. Review PL/SQL package for transaction boundaries

### Night Batch Processing

**Schedule**: Critical processing window 00h00-06h59  
**Peak Period**: 03h13-05h18 (main GL/AP/FA batch)  
**Monitoring**: See `Rapport_Traitements_Nuit_Oracle_EBS.md` for baseline execution patterns  
**Top Programs**: Payment file generation (14,499/month), supplier schedules (1,438/month)

**Evening Controls (19h00-23h59)**: Post-business processing chain  
**Peak Period**: 19h00-19h45 (XLA/FA accounting, 73K executions)  
**Monitoring**: See `controleNuit.md` for detailed analysis (142K executions/night)  
**Top Programs**: Create Accounting (12.5K/night), AP Invoice Validation (6.3K/night), FA accounting (12.5K/night)

## File Organization

### Analysis Reports (`.md`)
- `Rapport_*.md`: Comprehensive system analysis reports
- `Analyse_*.md`: Specific incident or problem investigations  
- `CONCLUSION_*.md`: Summary findings and recommendations

### SQL Queries (`.sql`)
- `Requete_*.sql`: Data extraction queries (often with corrections)
- `Definition_*.sql`: Metadata queries for Oracle objects
- `Detail_*.sql`: Detailed algorithm documentation
- `Verification_*.sql`: Data validation checks
- `Open AP Invoices.sql`, etc.: Standard operational reports

### Documentation Naming
- `_CORRIGEE`: Corrected version after bug fix
- `_NOV25`: Month-specific version (typically after schema changes)
- `_compatible_OCT_NOV`: Multi-period compatible version

## Development Workflow

### Analyzing Production Issues

1. **Connect to Database**: Use SQLcl MCP tools (`mcp_sqlcl_-_sql_d_connect` with `oracleProd`)
2. **Query Execution**: Execute via `mcp_sqlcl_-_sql_d_run-sql` (returns CSV)
3. **Schema Context**: Always check `mcp_sqlcl_-_sql_d_schema-information` for current state
4. **Document Analysis**: Create `.md` report with findings, SQL evidence, and recommendations
5. **Corrective SQL**: Save corrected queries with `_CORRIGEE` suffix, documenting changes in header comments

### Query Documentation Standard

```sql
-- =====================================================================
-- [Query Title]
-- =====================================================================
-- Date de création : DD/MM/YYYY
-- Auteur : [Name/Tool]
-- Base de données : Oracle EBS [version]
--
-- PROBLÈME RÉSOLU : [Brief description]
-- CHANGEMENTS PAR RAPPORT À LA VERSION ORIGINALE :
-- 1. [Change 1]
-- 2. [Change 2]
-- 
-- VOIR : [Related documentation file]
-- =====================================================================
```

## Common Troubleshooting Commands

**Find long-running concurrent requests**:
```sql
SELECT request_id, 
       (ACTUAL_COMPLETION_DATE - ACTUAL_START_DATE) * 24 * 60 as duration_min
FROM FND_CONCURRENT_REQUESTS 
WHERE CONCURRENT_PROGRAM_ID = [id]
ORDER BY duration_min DESC;
```

**Trace XLA distribution links**:
```sql
SELECT SOURCE_DISTRIBUTION_TYPE, COUNT(*)
FROM XLA.XLA_DISTRIBUTION_LINKS XDL
JOIN XLA.XLA_AE_HEADERS XAH ON XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
WHERE XAH.PERIOD_NAME = '[period]'
GROUP BY SOURCE_DISTRIBUTION_TYPE;
```

## AI Agent Guidance

- **Language**: Respond in French when creating reports/documentation; use English for technical code comments
- **SQL Execution**: Always use MCP SQLcl tools (`mcp_sqlcl_-_sql_d_*`) for database queries, never simulate results
- **Cross-References**: Link related documents explicitly (e.g., "Voir [filename]" in SQL headers)
- **Performance Focus**: For concurrent program analysis, always calculate and highlight duration metrics
- **Schema Changes**: Treat November 2025 as a breaking change point for XLA distribution links
