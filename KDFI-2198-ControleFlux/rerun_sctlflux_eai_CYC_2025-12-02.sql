-- =====================================================================
-- Rerun DKA_SCTLFLUX_EAI for folio CYC on 02/12/2025
-- =====================================================================
-- Usage: Run in SQL Developer connected as APPS
-- This script:
-- 1) Initializes EBS context (FND_GLOBAL.APPS_INITIALIZE)
-- 2) Sets a fresh CONC_REQUEST_ID to tag rows
-- 3) Calls APPS.DKA_SCTLFLUX_EAI_PKG.main in reprise mode for 2025-12-02
-- 4) Shows the control rows inserted in DKA_SCTLFLUX_EAI for this run
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Replace these IDs with valid values for your instance
DECLARE
  v_user_id      NUMBER := 12345;      -- FND_USERS.USER_ID
  v_resp_id      NUMBER := 98765;      -- FND_RESPONSIBILITY.RESPONSIBILITY_ID
  v_resp_appl_id NUMBER := 200;        -- FND_APPLICATION.APPLICATION_ID of the responsibility
  v_req_id       VARCHAR2(30);
BEGIN
  FND_GLOBAL.APPS_INITIALIZE(v_user_id, v_resp_id, v_resp_appl_id);

  -- Generate a new synthetic request id to tag data for this session
  v_req_id := TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')));
  FND_PROFILE.PUT('CONC_REQUEST_ID', v_req_id);
  FND_PROFILE.PUT('USER_ID', TO_CHAR(v_user_id));
  DBMS_OUTPUT.PUT_LINE('Initialized APPS context; CONC_REQUEST_ID='||v_req_id);
END;
/

-- Call the package in reprise mode for the exact date window 02/12/2025
DECLARE
  v_errbuf   VARCHAR2(4000);
  v_retcode  NUMBER;
BEGIN
  APPS.DKA_SCTLFLUX_EAI_PKG.main(
    pv_errbuf             => v_errbuf,
    pn_retcode            => v_retcode,
    pv_folio              => 'CYC',                      -- same folio as the run
    pn_traitement_reprise => NULL,                       -- normal path; gv_reprise driven by dates
    pd_date_reprise_de    => '2025/12/02 00:00:00',      -- start of window
    pd_date_reprise_a     => '2025/12/02 23:59:59'       -- end of window
  );
  DBMS_OUTPUT.PUT_LINE('RET: '||NVL(v_retcode,0));
  DBMS_OUTPUT.PUT_LINE('ERR: '||NVL(v_errbuf,'<null>'));
END;
/

-- Inspect the control rows for this rerun
COLUMN CODE_FOLIO FORMAT A6
COLUMN DATE_EXEC FORMAT A12
COLUMN FICHIER FORMAT A40
SELECT CODE_FOLIO, DATE_EXEC, NB_PIECE, ROUND(NVL(DEBIT,0),2) DEBIT,
       ROUND(NVL(CREDIT,0),2) CREDIT, FICHIER, TRAITE, N_TRAITEMENT
  FROM DKA_SCTLFLUX_EAI
 WHERE N_TRAITEMENT = FND_PROFILE.VALUE('CONC_REQUEST_ID')
 ORDER BY CODE_FOLIO, DATE_EXEC, FICHIER;

-- Optional: count per source block
SELECT TRAITE, COUNT(*) cnt
  FROM DKA_SCTLFLUX_EAI
 WHERE N_TRAITEMENT = FND_PROFILE.VALUE('CONC_REQUEST_ID')
 GROUP BY TRAITE
 ORDER BY TRAITE;

-- Note: The CSV file is written server-side in directory SCTLFLUX_OUT_DIR
-- Filename pattern: NOM_FICHIER || '_' || YYMMDD-HH24MISS || '.csv'
-- Retrieve via server access or DBA assistance if needed.
