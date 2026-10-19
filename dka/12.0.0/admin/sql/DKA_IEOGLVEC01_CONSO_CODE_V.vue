----------------------------------------------------------------------------------------------
-- $$ 
-- CAPGEMINI
-- PROJECT           : DALKIA Oracle Applications
-- NAME              : DKA_IEOGLVEC01_CONSO_CODE_V.vue
-- DESCRIPTION       : Creation of view DKA_IEOGLVEC01_VEOLIA_CODE_V
--
-- AUTHOR            : CDE (CG)
-- CREATION DATE     : 30/10/2006
-- COMMENTS          : To execute on SQLPLUS with user APPS
--------------------------------------------------------------------------------------------
-- MODIFICATIONS HISTORY
-- Date       Who Description
-- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION OF VIEW DKA_IEOGLVEC01_CONSO_CODE_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA.DKA_IEOGLVEC01_CONSO_CODE_V (
  balancing_seg_value,
  operating_unit,
  conso_code
)
AS
	SELECT DSL.PARAM1_VALUE, DSL.PARAM2_VALUE, DSL.RETURN_VALUE
	FROM DKA_STRANSCO_HEADERS DSH, DKA_STRANSCO_LINES DSL
	WHERE DSH.SET_ID = DSL.SET_ID
	AND   DSH.SET_NAME = 'DKA_CONSO_VECTOR'
	UNION ALL
	SELECT 'ALL', NULL, 'ALL'
    FROM dual	
	;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP OF SYNONYM DKA_IEOGLVEC01_CONSO_CODE_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
DROP SYNONYM DKA_IEOGLVEC01_CONSO_CODE_V; 
  
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION OF SYNONYM DKA_IEOGLVEC01_CONSO_CODE_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
create synonym DKA_IEOGLVEC01_CONSO_CODE_V FOR DKA.DKA_IEOGLVEC01_CONSO_CODE_V;

SHOW ERROR

EXIT