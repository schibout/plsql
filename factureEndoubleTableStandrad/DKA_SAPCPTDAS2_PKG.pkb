CREATE OR REPLACE PACKAGE BODY DKA_IPOEXTRACTCDE_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IPOEXTRACTCDE_PKG.pkb 190 2008-03-17 16:10:08Z NORDEST\jdequidt $
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_IPOEXTRACTCDE_PKG.pkb
-- DESCRIPTION       : DKA_IPOEXTRACTCDE_PKG package body
---
--- AUTEUR           : Jonathan Dequidt (Capgemini)
--- DATE DE CREATION : 25/01/2008
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 07/03/2008 JDE Modification du nom du fichier,du nom du fichier de sortie, utilisation de fnd_messages
--- 09/05/2016 BDE Modification du nom du fichier de sortie, prise en compte des modifications
--- sur les noms des tables etc.., ajout de nouvelles restrictions sur la deuxième requête...
--- 20/12/2016 YWA Boucle for + modif TYPE Seconde requête
--- 16/03/2017 EFL artf2123058: Modification de l'insertion des donnees dans DKA_IPOEXTRACTCDE_INTERFACE
------------------------------------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

e_file          EXCEPTION;
e_main          EXCEPTION;

cv_directory    CONSTANT VARCHAR2(50)         := 'DKA_IPOEXTRACTCDE_DIR';
cv_message_name CONSTANT VARCHAR2(50)         := 'DKA_IPOEXTRACTCDE_001';


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  PROCEDURE write_file
  IS

    TYPE t_date_extract IS TABLE OF DKA_IPOEXTRACTCDE_INTERFACE .c_date_extract%TYPE;
    TYPE t_societe IS TABLE OF DKA_IPOEXTRACTCDE_INTERFACE .c_csociete%TYPE;
    TYPE t_division IS TABLE OF DKA_IPOEXTRACTCDE_INTERFACE .c_cdivision%TYPE;
    TYPE t_region IS TABLE OF DKA_IPOEXTRACTCDE_INTERFACE .c_cregion%TYPE;
    TYPE t_no_commande IS TABLE OF DKA_IPOEXTRACTCDE_INTERFACE .c_no_commande%TYPE;
    TYPE t_tiers IS TABLE OF DKA_IPOEXTRACTCDE_INTERFACE .c_ctiers%TYPE;
    TYPE t_dcreation IS TABLE OF DKA_IPOEXTRACTCDE_INTERFACE .c_dcreation%TYPE;

    l_date_extract      t_date_extract;
    l_societe           t_societe;
    l_division          t_division;
    l_region            t_region;
    l_no_commande       t_no_commande;
    l_tiers             t_tiers;
    l_dcreation         t_dcreation;

    lv_file_id          utl_file.file_type;

    lv_buffer           VARCHAR2(10000);

    ln_line_count       PLS_INTEGER;

    vv_filename         VARCHAR2(50);
    vv_directory_name   dba_directories.directory_path%TYPE;

  BEGIN

    SELECT             dkai.c_date_extract,
                       dkai.c_csociete,
                       dkai.c_cdivision,
                       dkai.c_cregion,
                       dkai.c_no_commande,
                       dkai.c_ctiers,
                       dkai.c_dcreation
    BULK COLLECT INTO  l_date_extract,
                       l_societe,
                       l_division,
                       l_region,
                       l_no_commande,
                       l_tiers,
                       l_dcreation
    FROM               DKA_IPOEXTRACTCDE_INTERFACE  dkai;

    fnd_message.set_name('DKA', cv_message_name);

    vv_filename := fnd_message.get() || to_char(SYSDATE, 'YYYYMMDDHHmiss') || '.dat';

    lv_file_id := utl_file.fopen(cv_directory, vv_filename, 'w');

    SELECT dd.directory_path
    INTO   vv_directory_name
    FROM   dba_directories dd
    WHERE  dd.directory_name = 'DKA_IPOEXTRACTCDE_DIR';

    BEGIN
      IF utl_file.is_open(lv_file_id) THEN
        dka_tools_pkg.put_log_message('Création du fichier ' || vv_directory_name || '/' || vv_filename || ' réussie');

      ELSE
        RAISE e_file;
      END IF;

      ln_line_count := 0;

      --FOR j IN l_societe.FIRST..l_societe.LAST
      FOR j IN 1..l_societe.COUNT  --YWA
        LOOP
          lv_buffer := l_societe(j) || ';'
                       || l_division(j) || ';'
                       || l_region(j) || ';'
                       || l_no_commande(j) || ';'
                       || l_tiers(j) || ';'
                       || to_char(l_dcreation(j), 'YYYYMMDD');


          utl_file.put_line(lv_file_id, lv_buffer);
          ln_line_count := ln_line_count + 1;
        END LOOP;
        utl_file.fclose(lv_file_id);
        dka_tools_pkg.put_log_message('Fichier fermé');
        COMMIT;
        dka_tools_pkg.put_log_message('Commit effectué');
        dka_tools_pkg.put_log_message(   to_char(ln_line_count) || ' lignes écrites dans le fichier '
                                      || vv_directory_name || '/' || vv_filename);

        EXCEPTION
          WHEN utl_file.INVALID_PATH THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : File location is invalid');
            RAISE e_file;
          WHEN utl_file.INVALID_MODE THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : The open_mode parameter in FOPEN is invalid');
            RAISE e_file;
          WHEN utl_file.INVALID_FILEHANDLE THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : File handle is invalid');
            RAISE e_file;
          WHEN utl_file.INVALID_OPERATION THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : File could not be opened or operated on as requested');
            RAISE e_file;
          WHEN utl_file.READ_ERROR THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : Operating system error occurred during the read operation');
            RAISE e_file;
          WHEN utl_file.WRITE_ERROR THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : Operating system error occurred during the write operation');
            RAISE e_file;
          WHEN utl_file.INTERNAL_ERROR THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : Unspecified PL/SQL error');
            RAISE e_file;
          WHEN utl_file.CHARSETMISMATCH THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : A file is opened using FOPEN_NCHAR, but later I/O operations use nonchar functions such as PUTF or GET_LINE');
            RAISE e_file;
          WHEN utl_file.FILE_OPEN THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : The requested operation failed because the file is open');
            RAISE e_file;
          WHEN utl_file.INVALID_MAXLINESIZE THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : The MAX_LINESIZE value for FOPEN() is invalid; it should be within the range 1 to 32767');
            RAISE e_file;
          WHEN utl_file.INVALID_FILENAME THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : The filename parameter is invalid');
            RAISE e_file;
          WHEN utl_file.ACCESS_DENIED THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message(   'Erreur lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename
                                          || ' : Permission to access to the file location is denied');
            RAISE e_file;
          WHEN OTHERS THEN
            IF utl_file.is_open(lv_file_id) THEN
              utl_file.fclose(lv_file_id);
            END IF;
            dka_tools_pkg.put_log_message('Erreur ' || SQLCODE || ' : ' || SQLERRM);
            dka_tools_pkg.put_log_message(   'Erreur inconnue lors d''une opération sur le fichier '
                                          || vv_directory_name || '/' || vv_filename);
            RAISE e_file;
    END;
  END write_file;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : point d'entrée du traitement
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--      px_param1       type
--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         1: avertissement
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main (
    pv_errbuf     OUT      VARCHAR2,
    pn_retcode    OUT      NUMBER
  )
  IS

    vn_line_added           NUMBER;
    vn_line_total           NUMBER;

  BEGIN
    -- initialisation des paramètres de sorties
    pv_errbuf := NULL;
    pn_retcode := 0;

    dka_tools_pkg.put_log_message('Démarrage du traitement');

    dka_tools_pkg.put_log_message('Effacement du contenu de la table spécifique DKA_IPOEXTRACTCDE_INTERFACE ');

    EXECUTE IMMEDIATE 'truncate TABLE dka.DKA_IPOEXTRACTCDE_INTERFACE ';

    dka_tools_pkg.put_log_message('Remplissage de la table spécifique DKA_IPOEXTRACTCDE_INTERFACE ');

    BEGIN

          INSERT INTO DKA_IPOEXTRACTCDE_INTERFACE
          ( c_date_extract,
            c_csociete,
            c_cdivision,
            c_cregion,
            c_no_commande,
            c_ctiers,
            c_dcreation )
          SELECT
             SYSDATE
           , gcc.segment1 c_csociete
           , 'ENERGIE' c_cdivision
           , gcc.segment2 c_cregion
           , ph.segment1 c_no_commande
           , pv.segment1 c_ctiers
           , ph.creation_date c_dcreation
          FROM
		     po_headers_all ph
           , po_line_locations_all pll
           , po_distributions_all pd
           , gl_code_combinations gcc
           , ap_suppliers pv
          WHERE
             pll.line_location_id IN ( SELECT MIN (pll.line_location_id)
                                       FROM
									     po_line_locations_all pll
                                       , po_headers_all ph
                                       WHERE NVL(pll.closed_code, 'OPEN') IN ('OPEN', 'CLOSED FOR RECEIVING')
                                       AND NVL(pll.cancel_flag, 'N') <> 'Y'
                                       AND pll.po_header_id = ph.po_header_id
                                       AND ph.type_lookup_code = 'STANDARD'
                                       AND NVL(ph.closed_code, 'OPEN') = 'OPEN'
                                       AND ph.approved_flag = 'Y'
                                       GROUP BY ph.po_header_id )
          AND  pll.po_header_id = ph.po_header_id
          AND  pd.line_location_id = pll.line_location_id
          AND  pd.po_distribution_id =  ( SELECT MIN(pd2.po_distribution_id)
                                      FROM po_distributions_all pd2
                                      WHERE pd2.line_location_id = pll.line_location_id )
          AND gcc.code_combination_id = pd.code_combination_id
          AND pv.vendor_id = ph.vendor_id;

          vn_line_added := SQL%ROWCOUNT;

		  -- Nbre de commandes
          SELECT COUNT (1)
          INTO vn_line_total
          FROM po_headers_all ph
          WHERE ph.type_lookup_code = 'STANDARD'
          AND NVL(ph.closed_code, 'OPEN') = 'OPEN'
          AND ph.approved_flag = 'Y';

    EXCEPTION

        WHEN OTHERS THEN
          ROLLBACK;
          dka_tools_pkg.put_log_message('Erreur pendant la récupération des détails : ' || SQLERRM);
          RAISE e_main; -- erreur fatale
    END;


    COMMIT;

    write_file();

    dka_tools_pkg.put_log_message(vn_line_added || ' lignes ajoutées et ' || to_char(vn_line_total - vn_line_added) || ' lignes ignorées');

    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        pn_retcode := 2;
        pv_errbuf  := SQLERRM;
  END main;

END DKA_IPOEXTRACTCDE_PKG;

/
show errors package body DKA_IPOEXTRACTCDE_PKG;
EXIT;

