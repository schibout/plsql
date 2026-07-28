-- =====================================================================
-- CODE SOURCE : DKA_GENERATE_URL_IMAGE_FACTURE
-- =====================================================================
-- Téléchargé depuis : Oracle EBS 19.28.0.0.0 Production
-- Schéma : APPS
-- Date téléchargement : 09/03/2026
-- Dernière modification DDL : 10/10/2025
-- Statut : VALID
-- =====================================================================

PROCEDURE DKA_GENERATE_URL_IMAGE_FACTURE (
    DATE_EXTR_DEB   IN DATE,
    DATE_EXTR_FIN   IN DATE
)
AS
/*
04/09/2025 : CGI oracle : on construit l'URL via l'API
*/
    VD_DATE_EXTR_FAC DATE := TO_DATE(DATE_EXTR_DEB, 'DD/MM/YYYY HH24:MI:SS');
	--EDB362
	vv_param1 VARCHAR2(150);

BEGIN

    DELETE FROM DKA_JMETER_ST.EXTRACTION_FACTURE;

    COMMIT;

	--EDB362
	BEGIN

	SELECT TRIM(VARCHAR2_VALUE)
        INTO vv_param1
        FROM DKA_PARAMETERS
        WHERE PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC'
			AND PARAMETER_NAME = 'PARAM1';

	END;



    INSERT INTO DKA_JMETER_ST.EXTRACTION_FACTURE (INVOICE_ID, URL, ACCESS_ID)
        SELECT INVOICE_ID, URL, ACCESS_ID
          FROM (SELECT AIA.INVOICE_ID,
/*                          vv_param1
                       || CHR (38)
                       || 'fid='
                       || FD.MEDIA_ID
                       || CHR (38)
                       || 'accessid='
                       || TO_CHAR (FLA.ACCESS_ID)                                URL,*/ -- 04/09/2025 : CGI oracle
                       DKA_construct_download_url(FD.MEDIA_ID)                                   URL,
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

-- =====================================================================
-- FONCTION UTILITAIRE : DKA_construct_download_url
-- =====================================================================

FUNCTION DKA_construct_download_url(file_id NUMBER)
RETURN VARCHAR2
IS
  /*
  04/09/2025 CGI Oracle : Création de cette fonction pour générer les URL à la volée
  */
      PRAGMA AUTONOMOUS_TRANSACTION;
      file_ext   VARCHAR2(10);
      l_url VARCHAR2(2000);
BEGIN

    l_url  := fnd_gfm.construct_download_url(
                  gfm_agent     => fnd_web_config.gfm_agent,
                  file_id       => file_id,
                  --purge_on_view boolean default FALSE,
                  --modplsql      boolean default FALSE,
                  authenticate  => FALSE --,
                  --user_name     => 'DKAEXPLOIT'
                  --lifespan      number  default NULL
              );

    COMMIT;
    RETURN l_url;
    
EXCEPTION
    WHEN OTHERS THEN
        fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
        fnd_message.set_token('ROUTINE', 'DKA_construct_download_url');
        fnd_message.set_token('ERRNO', SQLCODE);
        fnd_message.set_token('REASON', SQLERRM);
        RAISE;
END;
/

-- =====================================================================
-- PARAMÈTRE DE CONFIGURATION
-- =====================================================================

-- SELECT * FROM DKA_PARAMETERS WHERE PROGRAM_CODE = 'DKA_GEN_URL_IMG_BDC';
-- 
-- PROGRAM_CODE         : DKA_GEN_URL_IMG_BDC
-- PARAMETER_NAME       : PARAM1
-- VARCHAR2_VALUE       : http://finance.dalkia.net:8001/OA_HTML/fndgfm.jsp?mode=download_blob
-- DESCRIPTION          : Url du serveur PRODUCTION
--
-- NOTE : Ce paramètre n'est plus utilisé depuis la migration du 04/09/2025

-- =====================================================================
-- EXEMPLE D'APPEL
-- =====================================================================

-- Année complète 2026 (ATTENTION : corriger la date de fin!)
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/01/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'), 
    TO_DATE('31/12/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')  -- Corrigé : 23:59:59 au lieu de 00:00:00
);

-- Mois spécifique
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TO_DATE('01/11/2025 00:00:00', 'DD/MM/YYYY HH24:MI:SS'), 
    TO_DATE('30/11/2025 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
);

-- Jour spécifique (hier)
exec DKA_GENERATE_URL_IMAGE_FACTURE ( 
    TRUNC(SYSDATE - 1), 
    TRUNC(SYSDATE) - 1/86400  -- 23:59:59 d'hier
);

-- =====================================================================
-- VOIR : Analyse_Detaillee_Package_DKA_GENERATE_URL_IMAGE_FACTURE.md
-- =====================================================================
