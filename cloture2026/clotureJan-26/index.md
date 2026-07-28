Cette partie est dedié aux cloture mensuelle ainsi que tous les contrôles qu'on dois faire.
SELECT 
    AC.CHECK_ID,
    AC.CHECK_NUMBER,
    AC.CHECK_DATE,
    AC.AMOUNT,
    AC.STATUS_LOOKUP_CODE,
    AC.VOID_DATE,
    ABA.BANK_ACCOUNT_NAME,
    PV.VENDOR_NAME
FROM AP.AP_CHECKS_ALL AC
JOIN AP.AP_BANK_ACCOUNTS_ALL ABA 
    ON AC.BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
LEFT JOIN AP.AP_SUPPLIERS PV 
    ON AC.VENDOR_ID = PV.VENDOR_ID
WHERE AC.CHECK_NUMBER = '400011351'
    AND AC.ORG_ID = 82; -- Ajuster selon l'organisation


    DECLARE
    v_request_id NUMBER;
BEGIN
    v_request_id := FND_REQUEST.SUBMIT_REQUEST(
        application => 'SQLAP',
        program     => 'APXPBVPC',
        description => 'Annulation paiement 400011351',
        start_time  => SYSDATE,
        sub_request => FALSE,
        argument1   => '82',            -- ORG_ID
        argument2   => '400011351',     -- CHECK_NUMBER
        argument3   => SYSDATE,         -- VOID_DATE
        argument4   => 'VOID'           -- VOID_REASON_CODE
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Request ID: ' || v_request_id);
END;
/