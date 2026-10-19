----------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJECT           : DALKIA Oracle Applications
-- NAME              : DKA_IEOGLVEC01_FILE_GENERATION.sql
-- DESCRIPTION       : Script to generate file to VECTOR
--
-- AUTHOR           : CDE (CG)
-- CREATION DATE    : 31/10/2006
-- COMMENTS         : Execute it on SQLPLUS with user APPS
-- PARAMETERS       : 1 : veolia code
--                  : 2 : amount limit interco
------------------------------------------------------------------------------
-- MODIFICATION HISTORY
-- Date       Who Description
-- ---------- --- -----------------------------------------------------------
-- 2006/12/14 CD  XDKA_ARGOS_CPTE_HORS_GROUPE => XDKA_ARGOS_THIRD_PARTIES 
-- 2007/01/15 CD  Delete of ";" after column D_PS 
-- 2007/03/06 CD  Apply threshold only on PL and 40PL accounts
-- 2007/03/21 CD  delete HAVING   ROUND (SUM (dka_ieoglvec01_int.amount)) != 0 
--                for Global lines
-- 2008/01/04 EMA Adding request_id parameter
-- 2016/11/22 PBR Migration R12.
------------------------------------------------------------------------------

SET VERIFY OFF
SET HEAD OFF
--SET PAGESIZE 100
SET LINESIZE 500
SET FEEDBACK OFF

COLUMN LINE_TYPE NOPRINT

-- Head line
SELECT   'D_CA;D_DP;D_PE;D_RU;D_AC;D_FL;D_CU;P_AMOUNT;D_AU;D_PS' line_text,
         1 line_type
FROM     DUAL
UNION ALL
-- Global lines
SELECT      'ACTUAL'
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dka_ieoglvec01_int.period_name),'RRRR.MM')
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dka_ieoglvec01_int.period_name),'RRRR.MM')
         || ';'
         || dka_ieoglvec01_int.entity
         || ';'
         || dka_ieoglvec01_int.accnt
         || ';'
         || dka_ieoglvec01_int.flow
         || ';'
         || dka_ieoglvec01_int.currency_code
         || ';'
         || ROUND (SUM (dka_ieoglvec01_int.amount)) 
         || ';'
         || dka_ieoglvec01_int.nature
         || ';'
         || '' line_text,
         2 line_type
FROM     dka_ieoglvec01_int
WHERE    dka_ieoglvec01_int.request_id = &&3
AND      dka_ieoglvec01_int.entity     = '&&1'
GROUP BY dka_ieoglvec01_int.period_name,
         dka_ieoglvec01_int.entity,
         dka_ieoglvec01_int.accnt,
         dka_ieoglvec01_int.flow,
         dka_ieoglvec01_int.currency_code,
         dka_ieoglvec01_int.nature
--HAVING   ROUND (SUM (dka_ieoglvec01_int.amount)) != 0
UNION ALL
-- Partner details for PL and 40PL accounts
SELECT      'ACTUAL'
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dka_ieoglvec01_int.period_name),'RRRR.MM')
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dka_ieoglvec01_int.period_name),'RRRR.MM')
         || ';'
         || dka_ieoglvec01_int.entity
         || ';'
         || dka_ieoglvec01_int.accnt
         || ';'
         || dka_ieoglvec01_int.flow
         || ';'
         || dka_ieoglvec01_int.currency_code
         || ';'
         || ROUND (SUM (dka_ieoglvec01_int.amount)) 
         || ';'
         || dka_ieoglvec01_int.nature
         || ';'
         || dka_ieoglvec01_int.partner line_text,
         2 line_type
FROM     dka_ieoglvec01_int
WHERE    dka_ieoglvec01_int.request_id = &&3
AND      dka_ieoglvec01_int.entity     = '&&1'
AND      dka_ieoglvec01_int.partner IS NOT NULL
AND      (substr(accnt,1,4) = '40PL' OR substr(accnt,1,2) = 'PL')
GROUP BY dka_ieoglvec01_int.period_name,
         dka_ieoglvec01_int.entity,
         dka_ieoglvec01_int.accnt,
         dka_ieoglvec01_int.flow,
         dka_ieoglvec01_int.currency_code,
         dka_ieoglvec01_int.nature,
         dka_ieoglvec01_int.partner
HAVING   ABS (SUM (dka_ieoglvec01_int.amount)) > &&2
UNION ALL
-- Partner details for other accounts
SELECT      'ACTUAL'
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dka_ieoglvec01_int.period_name),'RRRR.MM')
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dka_ieoglvec01_int.period_name),'RRRR.MM')
         || ';'
         || dka_ieoglvec01_int.entity
         || ';'
         || dka_ieoglvec01_int.accnt
         || ';'
         || dka_ieoglvec01_int.flow
         || ';'
         || dka_ieoglvec01_int.currency_code
         || ';'
         || ROUND (SUM (dka_ieoglvec01_int.amount)) 
         || ';'
         || dka_ieoglvec01_int.nature
         || ';'
         || dka_ieoglvec01_int.partner line_text,
         2 line_type
FROM     dka_ieoglvec01_int
WHERE    dka_ieoglvec01_int.request_id = &&3
AND      dka_ieoglvec01_int.entity     = '&&1'
AND      dka_ieoglvec01_int.partner IS NOT NULL
AND      (substr(accnt,1,4) != '40PL' AND substr(accnt,1,2) != 'PL')
GROUP BY dka_ieoglvec01_int.period_name,
         dka_ieoglvec01_int.entity,
         dka_ieoglvec01_int.accnt,
         dka_ieoglvec01_int.flow,
         dka_ieoglvec01_int.currency_code,
         dka_ieoglvec01_int.nature,
         dka_ieoglvec01_int.partner
-- S9999 details
UNION ALL
SELECT      'ACTUAL'
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dii.period_name),'RRRR.MM')
         || ';'
         || to_char(dka_ieoglvec01_pkg.get_gl_period_end_date(dii.period_name),'RRRR.MM')
         || ';'
         || dii.entity
         || ';'
         || dii.accnt
         || ';'
         || dii.flow
         || ';'
         || dii.currency_code
         || ';'
         || ROUND(sum(dii.amount_global)-sum(dii.amount_part))
         || ';'
         || dii.nature
         || ';'
         || 'S9999' line_text,
         2 line_type
FROM    (SELECT period_name,
                 entity,
                 accnt,
                 flow,
                 currency_code,
                 SUM (amount) amount_global,
                 0 amount_part,
                 nature
         FROM   dka_ieoglvec01_int
         WHERE  request_id = &&3
         GROUP BY  period_name,
                   entity,
                   accnt,
                   flow,
                   currency_code,
                   nature
         UNION ALL
         SELECT period_name,
                 entity,
                 accnt,
                 flow,
                 currency_code,
                 0 amount_global,
                 SUM (amount) amount_part,
                 nature
         FROM   dka_ieoglvec01_int
         WHERE  request_id = &&3
         AND    partner IS NOT NULL
         AND    (substr(accnt,1,4) = '40PL' OR substr(accnt,1,2) = 'PL')
         GROUP BY  period_name,
                   entity,
                   accnt,
                   flow,
                   currency_code,
                   nature,
                   partner
         HAVING   ABS (SUM (amount)) > &&2
         UNION ALL
         SELECT period_name,
                 entity,
                 accnt,
                 flow,
                 currency_code,
                 0 amount_global,
                 SUM (amount) amount_part,
                 nature
         FROM   dka_ieoglvec01_int
         WHERE  request_id = &&3
         AND    partner IS NOT NULL
         AND    (substr(accnt,1,4) != '40PL' AND substr(accnt,1,2) != 'PL')
         GROUP BY  period_name,
                   entity,
                   accnt,
                   flow,
                   currency_code,
                   nature,
                   partner
          ) dii
WHERE    dii.entity = '&&1'
AND      dii.accnt IN (SELECT flex_value
                         FROM   fnd_flex_values ffv,
                                fnd_flex_value_sets ffvs
                        WHERE     ffv.flex_value_set_id = ffvs.flex_value_set_id
                              AND ffv.enabled_flag = 'Y'
                              AND ffvs.flex_value_set_name = 'XDKA_ARGOS_THIRD_PARTIES')                             
GROUP BY dii.period_name,
         dii.entity,
         dii.accnt,
         dii.flow,
         dii.currency_code,
         dii.nature
HAVING   ROUND(sum(dii.amount_global)-sum(dii.amount_part)) != 0
ORDER BY 2,
         1;

