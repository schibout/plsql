/* Formatted on 31/10/2019 17:53:54 (QP5 v5.326) */
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
    CURSOR CUR_CLOSE_PO
    IS
SELECT PH.PO_HEADER_ID               VN_HEADER_ID,
       PH.SEGMENT1                   VV_SEGMENT1,
       NVL (PH.CANCEL_FLAG, 'N')     VV_CANCEL_FLAG,
       PH.CLOSED_CODE                VV_CLOSED_CODE,
       PH.ATTRIBUTE9                 VV_ATTRIBUTE9,
       PH.WF_ITEM_TYPE               VV_ITEM_TYPE,
       PH.WF_ITEM_KEY                VV_ITEM_KEY,
       PH.ORG_ID                     VN_ORG_ID,
       HAOU.NAME                     VV_UO,
       PH.CLOSED_DATE                VD_CLOSED_DATE,
       PH.AUTHORIZATION_STATUS       VV_AUTHORIZATION_STATUS
  FROM APPS.PO_HEADERS_ALL  PH
       JOIN APPS.PO_VENDOR_SITES_ALL PVSA
           ON (    PH.VENDOR_ID = PVSA.VENDOR_ID
               AND PH.VENDOR_SITE_ID = PVSA.VENDOR_SITE_ID)
       JOIN APPS.HR_ALL_ORGANIZATION_UNITS HAOU
           ON HAOU.ORGANIZATION_ID = PH.ORG_ID
      WHERE     PH.SEGMENT1 IN ('BC1607464', 'BC1633105', 'BC1607467', 'BC1634681', 'BC1727084',
                                    'BC1727085', 'BC1727083', 'BC1727081', 'BC1941171', 'BC1941157',
                                    'BC1527081', 'BC1527090', 'BC1527108', 'BC1529520', 'BC1529524',
                                    'BC1529547', 'BC1529567', 'BC1530087', 'BC1530267', 'BC1530278',
                                    'BC1930345', 'BC1533245', 'BC1538841', 'BC1540445', 'BC1540908',
                                    'BC1540909', 'BC1551384', 'BC1551386', 'BC1579114', 'BC1812833',
                                    'BC1586116', 'BC1587053', 'BC1633634', 'BC1633635', 'BC1633637',
                                    'BC1711066', 'BC1705254', 'BC1638597', 'BC1638720', 'BC1701756',
                                    'BC1700249', 'BC1662158', 'BC1662179', 'BC1693623', 'BC1680659'
                                );
    VV_ACTION              VARCHAR2 (100) := 'FERMER';
    VV_ATTRIBUTE9          APPS.PO_HEADERS_ALL.ATTRIBUTE9%TYPE := NULL;
    VV_MESSAGE             APPS.FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE := NULL;
    VV_COMMENTAIRE         APPS.FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE := NULL;
    VN_LAST_UPDATED_BY     APPS.PO_HEADERS_ALL.LAST_UPDATED_BY%TYPE := 32472;
    VN_LAST_UPDATE_DATE    APPS.PO_HEADERS_ALL.LAST_UPDATE_DATE%TYPE := NULL;
    VN_LAST_UPDATE_LOGIN   APPS.PO_HEADERS_ALL.LAST_UPDATE_LOGIN%TYPE := 0;
    --'H00035381F'  DKCOde Samir
    VD_END_DATE            DATE;
    DOCOMMIT               BOOLEAN := FALSE;
    FORCE                  BOOLEAN := TRUE;



    VN_COUNT               INTEGER := 0;

    TYPE NUMLIST IS TABLE OF APPS.PO_HEADERS_ALL.SEGMENT1%TYPE
        INDEX BY BINARY_INTEGER;

    INIT                   NUMLIST;
    ENUMS                  NUMLIST;
BEGIN
    DBMS_OUTPUT.PUT_LINE (
        'DKA : SCRIPT - Ouverture/Fermeture/Deblocage de commande');
    ENUMS := INIT;

    DBMS_OUTPUT.PUT_LINE (CHR (10));
    DBMS_OUTPUT.PUT_LINE ('Informations sur les commandes');
    DBMS_OUTPUT.PUT_LINE ('---------------------------------------');
    DBMS_OUTPUT.PUT_LINE (CHR (10));
    DBMS_OUTPUT.PUT_LINE (
           RPAD ('PO_HEADER_ID |', 15, ' ')
        || RPAD ('PO_NUM |', 15, ' ')
        || RPAD ('UO_NAME |', 15, ' ')
        || RPAD ('AUTHORIZATION_STATUS |', 25, ' ')
        --        || RPAD ('CLOSED_DATE |', 15, ' ')
        || RPAD ('CLOSED_CODE |', 15, ' ')
        || RPAD ('CANCEL_FLAG |', 15, ' ')
        || RPAD ('COMMENTAIRE', 50, ' '));

    FOR PCUR_CLOSE_PO IN CUR_CLOSE_PO
    LOOP
     
        IF VV_ACTION = 'OUVRIR'
        THEN
            IF     NVL (PCUR_CLOSE_PO.VV_CANCEL_FLAG, 'N') <> 'Y'
               AND PCUR_CLOSE_PO.VV_CLOSED_CODE IN  ('FINALLY CLOSED')
            THEN
                VV_COMMENTAIRE := 'Cde a été ouverte';
            END IF;
        ELSIF VV_ACTION = 'FERMER'
        THEN
            IF                
               PCUR_CLOSE_PO.VV_CLOSED_CODE NOT IN  ('FINALLY CLOSED') --= 'OPEN'
            THEN
                
                VV_MESSAGE := 'Fermeture par Script en masse';

                            UPDATE APPS.PO_LINE_LOCATIONS_ALL
                               SET CLOSED_CODE = 'FINALLY CLOSED',
                                   CLOSED_DATE = SYSDATE,
                                   SHIPMENT_CLOSED_DATE = SYSDATE --SNK artf07230322 27/03/2019
                                                                 ,
                                   CLOSED_BY = VN_LAST_UPDATED_BY,
                                   CLOSED_REASON = SUBSTR (VV_MESSAGE, 1, 240),
                                   LAST_UPDATE_DATE = SYSDATE,
                                   LAST_UPDATED_BY = VN_LAST_UPDATED_BY,
                                   LAST_UPDATE_LOGIN = VN_LAST_UPDATE_LOGIN
                             WHERE PO_HEADER_ID = PCUR_CLOSE_PO.VN_HEADER_ID;

                -- MAJ des lignes de commande
                            UPDATE APPS.PO_LINES_ALL
                               SET CLOSED_CODE = 'FINALLY CLOSED',
                                   CLOSED_DATE = SYSDATE,
                                   CLOSED_BY = VN_LAST_UPDATED_BY,
                                   CLOSED_REASON = SUBSTR (VV_MESSAGE, 1, 240),
                                   LAST_UPDATE_DATE = SYSDATE,
                                   LAST_UPDATED_BY = VN_LAST_UPDATED_BY,
                                   LAST_UPDATE_LOGIN = VN_LAST_UPDATE_LOGIN
                             WHERE PO_HEADER_ID = PCUR_CLOSE_PO.VN_HEADER_ID;

                
                -- MAJ entete de commande
                               UPDATE APPS.PO_HEADERS_ALL
                                  SET CLOSED_DATE = SYSDATE,
                                      CLOSED_CODE = 'FINALLY CLOSED',
                                      ATTRIBUTE9 = NULL,
                                      LAST_UPDATE_DATE = SYSDATE,
                                      LAST_UPDATED_BY = VN_LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN = VN_LAST_UPDATE_LOGIN
                                WHERE PO_HEADER_ID = PCUR_CLOSE_PO.VN_HEADER_ID;
                VV_COMMENTAIRE := 'Cde fermée le :' || TO_CHAR (SYSDATE);
            ELSE
                
                VV_COMMENTAIRE :=
                    'Cde déjà fermée avant le lancement du script';
            END IF;
        
        END IF;

        DBMS_OUTPUT.PUT_LINE (
               RPAD (PCUR_CLOSE_PO.VN_HEADER_ID, 15, ' ')
            || ' | '
            || RPAD (PCUR_CLOSE_PO.VV_SEGMENT1, 15, ' ')
            || ' | '
            || RPAD (PCUR_CLOSE_PO.VV_UO, 15, ' ')
            || ' | '
            || RPAD (PCUR_CLOSE_PO.VV_AUTHORIZATION_STATUS, 25, ' ')
            || ' | '
            || RPAD (PCUR_CLOSE_PO.VV_CLOSED_CODE, 15, ' ')
            || ' | '
            || RPAD (PCUR_CLOSE_PO.VV_CANCEL_FLAG, 15, ' ')
            || ' | '
            || RPAD (VV_COMMENTAIRE, 50, ' '));
    END LOOP;

    
    DBMS_OUTPUT.PUT_LINE ('*** FIN DU TRAITEMENT');
-- COMMIT;

EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE ('ERREUR : ' || SQLCODE || ' est survenue.');
        DBMS_OUTPUT.PUT_LINE (SQLERRM);
        DBMS_OUTPUT.PUT_LINE ('FAILURE');
END;
/