CREATE OR REPLACE PROCEDURE APPS.DKA_GENERATE_URL_IMAGE_FACTURE (
    DATE_EXTR_DEB   IN DATE, 
    DATE_EXTR_FIN   IN DATE)
AS
    VD_DATE_EXTR_FAC   
    DATE := TO_DATE (DATE_EXTR_DEB, 'DD/MM/YYYY HH24:MI:SS');
	--EDB362	
	vv_param1 VARCHAR2(150);
	
BEGIN
	
    DELETE FROM DKA_JMETER_ST.EXTRACTION_FACTURE;

    COMMIT;
	
	--EDB362
	BEGIN
	
	SELECT TRIM(VARCHAR2_VALUE)
        INTO vv_param1
        FROM
            DKA_PARAMETERS
        WHERE
            PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
			AND PARAMETER_NAME = 'PARAM1';
	END;


    INSERT INTO DKA_JMETER_ST.EXTRACTION_FACTURE (INVOICE_ID, URL, ACCESS_ID)
        SELECT INVOICE_ID, URL, ACCESS_ID
          FROM (SELECT AIA.INVOICE_ID,
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
                               PARTITION BY AIA.INVOICE_ID
                               ORDER BY FD.MEDIA_ID DESC, FLA.TIMESTAMP DESC)    ORDRE
                  FROM APPS.FND_ATTACHED_DOCUMENTS  FAD
                       JOIN APPS.AP_INVOICES_ALL AIA
                           ON FAD.PK1_VALUE = AIA.INVOICE_ID
                       JOIN APPS.FND_DOCUMENTS FD
                           ON FAD.DOCUMENT_ID = FD.DOCUMENT_ID
                       JOIN FND_DOCUMENT_CATEGORIES_TL FDCT
                           ON (    FDCT.CATEGORY_ID = FD.CATEGORY_ID
                               AND FDCT.LANGUAGE = 'F'
                               AND FDCT.NAME = 'MISC')
                       JOIN APPS.FND_LOB_ACCESS FLA
                           ON FLA.FILE_ID = FD.MEDIA_ID
                       JOIN APPS.FND_DOCUMENTS_TL FDT
                           ON (    FDT.DOCUMENT_ID = FD.DOCUMENT_ID
                               AND FDT.LANGUAGE = 'F'
                               AND FDT.DESCRIPTION = 'IMAGE FACTURE')
                       JOIN FND_DOCUMENT_DATATYPES FDAT
                           ON (    FD.DATATYPE_ID = FDAT.DATATYPE_ID
                               AND FDAT.LANGUAGE = 'F'
                               AND FDAT.NAME = 'FILE')
                 WHERE     1 = 1
                       AND FAD.ENTITY_NAME = 'AP_INVOICES'
                       AND FAD.LAST_UPDATE_DATE >= DATE_EXTR_DEB
                       AND AIA.LAST_UPDATE_DATE >= DATE_EXTR_DEB
                       AND FAD.LAST_UPDATE_DATE < DATE_EXTR_FIN 
                       AND AIA.LAST_UPDATE_DATE < DATE_EXTR_FIN)
         WHERE ORDRE = 1;

    COMMIT;


    UPDATE FND_LOB_ACCESS
       SET TIMESTAMP = TO_DATE ('01/01/2050', 'DD/MM/YYYY')
     WHERE     ACCESS_ID IN
                   (SELECT ACCESS_ID FROM DKA_JMETER_ST.EXTRACTION_FACTURE)
           AND TIMESTAMP <> TO_DATE ('01/01/2050', 'DD/MM/YYYY');


    COMMIT;
END DKA_GENERATE_URL_IMAGE_FACTURE;

/
SHOW ERRORS;
EXIT