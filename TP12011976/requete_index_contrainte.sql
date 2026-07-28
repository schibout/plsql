-- =====================================================================
-- Requête : Structure de l'index unique DKA_RA_INTERFACE_LINES_U1
-- =====================================================================
-- Date de création : 12/01/2026
-- Contexte : Analyse incident DKA_IARPAFAC REQUEST_ID 46750251
-- Erreur : ORA-00001 violation de contrainte unique
-- =====================================================================

-- 1. Colonnes de l'index unique violé
SELECT ic.column_position,
       ic.column_name,
       ic.descend
FROM all_ind_columns ic
WHERE ic.index_name = 'DKA_RA_INTERFACE_LINES_U1'
ORDER BY ic.column_position;

/*
Résultat attendu :
COLUMN_POSITION | COLUMN_NAME                  | DESCEND
----------------|------------------------------|--------
1               | INTERFACE_LINE_CONTEXT       | ASC
2               | INTERFACE_LINE_ATTRIBUTE1    | ASC
3               | INTERFACE_LINE_ATTRIBUTE2    | ASC
4               | INTERFACE_LINE_ATTRIBUTE3    | ASC
5               | INTERFACE_LINE_ATTRIBUTE4    | ASC
6               | INTERFACE_LINE_ATTRIBUTE5    | ASC
7               | REQUEST_ID                   | ASC

Mapping avec DKA_IARPAFAC_INTERFACE :
- INTERFACE_LINE_ATTRIBUTE1 = ORIGIN (ex: GCA)
- INTERFACE_LINE_ATTRIBUTE2 = COMPANY_CODE (ex: 0001)
- INTERFACE_LINE_ATTRIBUTE3 = INVOICE_NUMBER (ex: 0001S2601P211)
- INTERFACE_LINE_ATTRIBUTE4 = LINE_NUMBER (ex: 1) <-- PROBLEME ICI
- INTERFACE_LINE_ATTRIBUTE5 = Période YYYYMM (ex: 202601)
*/

-- 2. Factures avec plusieurs lignes LINE_NUMBER = 1 (cause des doublons)
SELECT INVOICE_NUMBER, 
       COUNT(*) as nb_lignes_avec_line1,
       COUNT(DISTINCT FMT_AMOUNT) as nb_montants_differents,
       LISTAGG(ROUND(FMT_AMOUNT/100,2), ' | ') WITHIN GROUP (ORDER BY FMT_AMOUNT) as montants
FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS IN ('P','R')
  AND LINE_NUMBER = 1
GROUP BY INVOICE_NUMBER
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 3. Détail d'une facture en doublon (exemple)
SELECT IARPAFAC_ID, INVOICE_NUMBER, LINE_NUMBER, LINE_TYPE,
       FMT_AMOUNT/100 as MONTANT_EUR, DESCRIPTION, TASK_CODE
FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE INVOICE_NUMBER = '0001S2601P211'
ORDER BY LINE_NUMBER, IARPAFAC_ID;
