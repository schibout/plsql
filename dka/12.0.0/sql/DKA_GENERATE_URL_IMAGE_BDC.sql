CREATE OR REPLACE PROCEDURE APPS.DKA_GENERATE_URL_IMAGE_BDC (
DATE_EXTR IN DATE,
DATE_EXTR_FIN   IN DATE --EDB362
)
AS
    VD_DATE_EXTR_CDE   DATE := TO_DATE (DATE_EXTR, 'DD/MM/YYYY HH24:MI:SS');
  --EDB362
  VD_DATE_EXTR_FIN_CDE   DATE := TO_DATE (DATE_EXTR_FIN, 'DD/MM/YYYY HH24:MI:SS');
  
  vv_param1 VARCHAR2(150);
  vv_param2 VARCHAR2(150);
  vv_param3 VARCHAR2(150);
  vv_param4 VARCHAR2(150);
  
BEGIN
  
  --EDB362
  BEGIN
  
  SELECT TRIM(VARCHAR2_VALUE)
        INTO vv_param1
        FROM
            DKA_PARAMETERS
        WHERE
            PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
      AND PARAMETER_NAME = 'PARAM1'
      ;
  
  SELECT TRIM(VARCHAR2_VALUE)
        INTO vv_param2
        FROM
            DKA_PARAMETERS
        WHERE
            PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
      AND PARAMETER_NAME = 'PARAM2'
      ;
  
  SELECT TRIM(VARCHAR2_VALUE)
        INTO vv_param3
        FROM
            DKA_PARAMETERS
        WHERE
            PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
      AND PARAMETER_NAME = 'PARAM3'
      ;
      
  SELECT TRIM(VARCHAR2_VALUE)
        INTO vv_param4
        FROM
            DKA_PARAMETERS
        WHERE
            PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
      AND PARAMETER_NAME = 'PARAM4'
      ;
    
  END;
  
  
    DELETE FROM DKA_JMETER_ST.EXTRACTION_BDC;

    COMMIT;


    INSERT INTO DKA_JMETER_ST.EXTRACTION_BDC (PO_HEADER_ID, URL, ACCESS_ID)
        SELECT PHA.PO_HEADER_ID, FD.URL URL, '0' ACCESS_ID
          FROM APPS.FND_ATTACHED_DOCUMENTS  FAD
               JOIN APPS.PO_HEADERS_ALL PHA
                   ON FAD.PK1_VALUE = PHA.PO_HEADER_ID
               JOIN APPS.FND_DOCUMENTS FD ON FAD.DOCUMENT_ID = FD.DOCUMENT_ID
         WHERE     1 = 1
               AND FD.CATEGORY_ID = 39
               AND FAD.ENTITY_NAME = 'PO_HEADERS'
               AND FAD.LAST_UPDATE_DATE >= VD_DATE_EXTR_CDE
         AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN --EDB362
               AND PHA.LAST_UPDATE_DATE >= VD_DATE_EXTR_CDE
         AND PHA.LAST_UPDATE_DATE < DATE_EXTR_FIN --EDB362
               AND PHA.SEGMENT1 LIKE 'BC%'
        UNION
        SELECT PO_HEADER_ID, URL, ACCESS_ID
          FROM (SELECT PHA.PO_HEADER_ID,
                          vv_param1
                       || CHR (38)
                       || 'fid='
                       || FD.MEDIA_ID
                       || CHR (38)
                       || 'accessid='
                       || TO_CHAR (FLA.ACCESS_ID)                                URL,
                       TO_CHAR (FLA.ACCESS_ID)                                   ACCESS_ID,
                       FLA.TIMESTAMP,
                       FD.MEDIA_ID,
                       ROW_NUMBER ()
                           OVER (
                               PARTITION BY PHA.PO_HEADER_ID
                               ORDER BY FD.MEDIA_ID DESC, FLA.TIMESTAMP DESC)    ORDRE
                  FROM APPS.FND_ATTACHED_DOCUMENTS  FAD
                       JOIN APPS.PO_HEADERS_ALL PHA
                           ON FAD.PK1_VALUE = PHA.PO_HEADER_ID
                       JOIN APPS.FND_DOCUMENTS FD
                           ON FAD.DOCUMENT_ID = FD.DOCUMENT_ID
                       JOIN FND_LOB_ACCESS FLA ON FLA.FILE_ID = FD.MEDIA_ID
                 WHERE     1 = 1
                       AND FD.CATEGORY_ID = 39
                       AND FAD.ENTITY_NAME = 'PO_HEADERS'
                       AND FAD.LAST_UPDATE_DATE >= VD_DATE_EXTR_CDE
             AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN --EDB362
                       AND PHA.LAST_UPDATE_DATE >= VD_DATE_EXTR_CDE
             AND PHA.LAST_UPDATE_DATE < DATE_EXTR_FIN --EDB362
                       AND PHA.SEGMENT1 NOT LIKE 'BC%')
         WHERE ORDRE = 1;

    COMMIT;


    UPDATE FND_LOB_ACCESS
       SET TIMESTAMP = TO_DATE ('01/01/2050', 'dd/mm/yyyy')
     WHERE     TO_CHAR (ACCESS_ID) IN
                   (SELECT TO_CHAR (ACCESS_ID)
                      FROM DKA_JMETER_ST.EXTRACTION_BDC)
           AND TIMESTAMP <> TO_DATE ('01/01/2050', 'dd/mm/yyyy');

    COMMIT;


    UPDATE DKA_JMETER_ST.EXTRACTION_BDC
       SET URL =
               REPLACE (
                   URL,
                   vv_param2,
                   vv_param4)
     WHERE URL LIKE '%/sheet/pdf%';

    COMMIT;


    UPDATE DKA_JMETER_ST.EXTRACTION_BDC
       SET URL =
               REPLACE (
                   URL,
                   vv_param3,
                   vv_param4)
     WHERE URL LIKE '%/sheet/pdf%';

    COMMIT;

    UPDATE DKA_JMETER_ST.EXTRACTION_BDC
       SET URL = REPLACE (URL, '/sheet/pdf/cancel', '')
     WHERE URL LIKE '%/sheet/pdf/cancel';

    COMMIT;

    UPDATE DKA_JMETER_ST.EXTRACTION_BDC
       SET URL = REPLACE (URL, '/sheet/pdf', '')
     WHERE URL LIKE '%/sheet/pdf';

    COMMIT;
END DKA_GENERATE_URL_IMAGE_BDC;

/
SHOW ERRORS;
EXIT