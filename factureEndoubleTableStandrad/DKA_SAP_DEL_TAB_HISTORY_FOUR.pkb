CREATE OR REPLACE PACKAGE BODY DKA_ICE_BANKBRANCHES_DTR_PKG AS
  ----------------------------------------------------------------------------------------------
  -- $Id$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_ICE_BANKBRANCHES_DTR_PKG.pkb
  -- DESCRIPTION       : DKA_ICE_BANKBRANCHES_DTR_PKG package body :
  ---
  --- AUTEUR           : Oussama BENHAYOUN
  --- DATE DE CREATION : 19/09/2017
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : 
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------------------------
  --- 26/09/2017 OBE artf2227837 : INT082 - Nom des fichiers à corriger + Vue DKA
  --- 12/01/2023 IBA EDB353
  --- 23/10/2023 BNZ EDB371 : Suppression des caractères parasites lors du traitement DKA : Extraction des évènements AR
  ----------------------------------------------------------------------------------------------

  --EXCEPTIONS
  E_FATAL_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_FATAL_ERROR, -20012);
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;

  --CONSTANTE
  cv_package_name CONSTANT VARCHAR2(30) := 'DKA_ICE_BANKBRANCHES_DTR_PKG';
  K_SEPARATOR     CONSTANT VARCHAR2(2) := ';';
  K_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
  
  gv_message_ledger VARCHAR2(32000) ;

  ------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal  
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS
  
  BEGIN
  
    dka_tools_pkg.put_debug_message(p_message);
  
  END p_put_debug_message;

  ------------------------------------------------------------------------------------
  --  Nom           : p_validate
  --  Description   : 
  --
  --  PARAMETRES    : p_condition: Si FALSE => Affiche un message dans le journal et
  --                                           genere une erreur fatale   
  --                               Si TRUE  => Fait aucune action
  --                  p_message:   Message a afficher dans le journal
  ------------------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN, p_message IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
  
    IF NOT p_condition THEN
      IF p_message IS NOT NULL THEN
        p_put_debug_message(p_message);
      END IF;
    
      RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM, nvl(p_message, 'Erreur fatale : '));
    
    END IF;
  
  END p_validate;


  ------------------------------------------------------------------------------------
  --  Nom           : p_check_directory
  --  Description   : Verifie que le directory existe
  --
  --  PARAMETRES    :
  --  p_directory_name          nom du directory    
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type) IS
  
    CURSOR cur_directory(p_directory_name IN ALL_DIRECTORIES.directory_name%type) IS
      SELECT owner, directory_name, directory_path FROM all_directories WHERE directory_name = p_directory_name;
    l_dir cur_directory%ROWTYPE;
  
  BEGIN
  
    OPEN cur_directory(p_directory_name);
    FETCH cur_directory
      INTO l_dir;
  
    IF cur_directory%NOTFOUND THEN
      CLOSE cur_directory;
      p_validate(FALSE, 'Le directory ' || p_directory_name || ' n''existe pas.');
    END IF;
  
    CLOSE cur_directory;
  
    p_put_debug_message('p_check_directory :  ' || p_directory_name || ' -> ' || l_dir.directory_path);
  
  END p_check_directory;

  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data
  --  Description   : Extrait les ecritures comptables vers Hyperion
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --  p_nb_lignes_maj         Nombre de lignes flaguees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data(p_directory_name IN ALL_DIRECTORIES.directory_name%type, 
                           p_file_name      IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS
    
    vv_ligne         VARCHAR2(4000);
    vn_nb_lignes     NUMBER := 0;
    l_file           UTL_FILE.file_type;
            
            --          replace(replace( replace(  ,'''',' '), ',', ' '),'"',' ') 

    CURSOR cur_bank IS
	--<DEBUT IBA EDB353 
      SELECT
      '"ROW_ID"#$#"BANK_HOME_COUNTRY"#$#"BANK_PARTY_ID"#$#"BANK_NAME"#$#"BANK_NAME_ALT"#$#"SHORT_BANK_NAME"#$#"BANK_NUMBER"#$#"BRANCH_PARTY_ID"#$#"BANK_BRANCH_NAME"#$#"BANK_BRANCH_NAME_ALT"#$#"BRANCH_NUMBER"#$#"START_DATE"#$#"END_DATE"#$#"ADDRESS_LINE1"#$#"ADDRESS_LINE2"#$#"ADDRESS_LINE3"#$#"ADDRESS_LINE4"#$#"CITY"#$#"STATE"#$#"PROVINCE"#$#"ZIP"#$#"COUNTRY"#$#"BANK_INSTITUTION_TYPE"#$#"BANK_BRANCH_TYPE"#$#"DESCRIPTION"#$#"EFT_SWIFT_CODE"#$#"EFT_USER_NUMBER"#$#"EDI_ID_NUMBER"#$#"PK_ID"'
      AS LIGNE
      FROM DUAL
      UNION ALL
	  --< DEBUT BNZ EDB371
      SELECT       
      '"'||ROW_ID||'"#$#'||
      '"'||replace(replace( replace(BANK_HOME_COUNTRY,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||BANK_PARTY_ID||'"#$#'||
      '"'||replace(replace( replace( BANK_NAME ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(BANK_NAME_ALT,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( SHORT_BANK_NAME ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(BANK_NUMBER ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||BRANCH_PARTY_ID||'"#$#'||
      '"'||replace(replace( replace( BANK_BRANCH_NAME ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( BANK_BRANCH_NAME_ALT ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( BRANCH_NUMBER,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||to_char(START_DATE,'YYYY/MM/DD HH24:MI:SS')||'"#$#'||
      '"'||to_char(END_DATE,'YYYY/MM/DD HH24:MI:SS')||'"#$#'||
      '"'||replace(replace( replace( ADDRESS_LINE1 ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( ADDRESS_LINE2 ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( ADDRESS_LINE3 ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( ADDRESS_LINE4 ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(CITY,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(STATE,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(PROVINCE,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(ZIP,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(COUNTRY,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( BANK_INSTITUTION_TYPE ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( BANK_BRANCH_TYPE ,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(DESCRIPTION,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(EFT_SWIFT_CODE,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace( EFT_USER_NUMBER,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||replace(replace( replace(EDI_ID_NUMBER,'''',' '), ',', ' '),'"',' ')||'"#$#'||
      '"'||PK_ID||'"'
	  -- FIN BNZ EDB371
	  --FIN IBA EDB353>
      FROM DKA_BANK_BRANCHES_V    -- OBE artf2227837
    ;
    
   
   TYPE t_bank IS TABLE OF cur_bank%ROWTYPE index by binary_integer;
   rec_bank t_bank;
   
  BEGIN
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '-- EXTRACTION DES DONNEES                                ');
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    p_put_debug_message('Dans la procedure p_extract_data (' || p_directory_name || ';' || p_file_name || ';' || p_nb_lignes || ')');  
                           
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);
    
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W');
    
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' || p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
      Fnd_File.put_line(Fnd_File.output,'Erreur : Le fichier ne peut pas être ouvert en écriture.');
    END IF;
      
      
    OPEN cur_bank;
    FETCH cur_bank BULK COLLECT INTO rec_bank;
    CLOSE cur_bank;   
    -- Extraction des donnees
     
    IF rec_bank.COUNT > 0 THEN
       FOR i in rec_bank.FIRST..rec_bank.LAST LOOP
   
          vv_ligne := rec_bank(i).LIGNE;     
          -- Ecrit dans le fichier
          utl_file.put_line(l_file, vv_ligne);
          -- Maj des compteurs
          vn_nb_lignes := vn_nb_lignes + 1;
    
       END LOOP;  
       Fnd_File.put_line(Fnd_File.output,'Les données ont été correctement extraits.');
     ELSE
        p_validate(FALSE, 'Requête des banques ne retourne aucune ligne.');
        Fnd_File.put_line(Fnd_File.output,'Aucune ligne n''a été extraite.');
     END IF;
     
     COMMIT; 
    
    
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
    
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    p_nb_lignes      := vn_nb_lignes;
   
    
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE, 'Probleme dans la procedure p_extract_data (' || SQLERRM || ')'); 
      Fnd_File.put_line(Fnd_File.output,'Erreur dans la phase d''extraction des données : '|| SQLERRM);
   
  END p_extract_data;

  
  ------------------------------------------------------------------------------------
  --  Nom           : Output_Header
  --  Description   : Procédure pour insérer une en-tête dans le fichier de sortie
  --
  --  PARAMETRES    :
  --              
  --
  ------------------------------------------------------------------------------------  

  PROCEDURE output_header IS
    cv_line                  VARCHAR2(100);
    v_conc_program_name      fnd_concurrent_programs.concurrent_program_name%TYPE;
    v_user_conc_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN
  
    cv_line := '+-------------------------------------------------------------------------+';
  
    ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
    BEGIN
      SELECT fcp.concurrent_program_name, fcpt.user_concurrent_program_name
        INTO v_conc_program_name, v_user_conc_program_name
        FROM fnd_concurrent_programs fcp, fnd_concurrent_programs_tl fcpt
       WHERE fcp.application_id = Fnd_Global.prog_appl_id
         AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.application_id = Fnd_Global.prog_appl_id
         AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.LANGUAGE = Fnd_Global.current_language;
    EXCEPTION
      WHEN OTHERS THEN
        v_user_conc_program_name := '???????????????????????';
        v_conc_program_name      := '???????';
    END;
  
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Nom du traitement  : ' || v_user_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Code du traitement : ' || v_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Programme lancé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;   
  
  
  ------------------------------------------------------------------------------------
  --  Nom           : p_bilan
  --  Description   : Affichage des stats
  --
  --  PARAMETRES    :
  --  p_nb_lignes      nombre de lignes extraites dans le fichier                  
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_bilan(p_nb_lignes IN NUMBER, p_date_der_exc IN DATE, p_odate IN DATE) IS
  
  BEGIN
  
    Fnd_File.put_line(Fnd_File.output, chr(10));
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '-- PARAMETRE DU TRAITEMENT, lancé le ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '1) Date de dernière exécution : ' || p_date_der_exc);
    Fnd_File.put_line(Fnd_File.output, '2) Date du plan de production : ' || p_odate);    
    Fnd_File.put_line(Fnd_File.output, chr(10));

    --Fnd_File.put_line(Fnd_File.output, chr(10));
    --Fnd_File.put_line(Fnd_File.output, chr(10));
    
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '-- BILAN                                                 ');
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
  
    IF p_nb_lignes > 0 THEN
      Fnd_File.put_line(Fnd_File.output, 'Volume des lignes extraites : ' || p_nb_lignes || ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucune ligne trouvée.');
    END IF;
  
  END p_bilan;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_livre              Jeu de livres
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT NOCOPY VARCHAR2, pn_retcode OUT NOCOPY NUMBER, p_date_der_exc IN VARCHAR2, p_odate IN VARCHAR2) IS
  
    lv_current_program_unit VARCHAR2(30) := 'main';
    lv_nom_fichier          VARCHAR2(200);
    ln_nb_lignes            NUMBER := 0;
    vd_odate        DATE;
    vd_date_der_exc DATE;
    
  BEGIN
  
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
    Output_Header;
    
    vd_odate := TRUNC(fnd_date.canonical_to_date(p_odate));     
    vd_date_der_exc := TRUNC(fnd_date.canonical_to_date(p_date_der_exc));      
  
    -- Construction du nom du fichier
    lv_nom_fichier := 'FIN01_' || to_char(sysdate, 'YYYYMMDDHH24miss') || '_CE-BANK-BRANCHES-V_001_'||
                       to_char(vd_date_der_exc, 'YYYYMMDD') || '_' ||to_char(vd_odate, 'YYYYMMDD') ||'.csv'; -- OBE artf2227837

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''EXTRACTION DES DONNEES');                       
    -- Extrait les lignes d'écritures dans le fichier
    p_extract_data(K_DIRECTORY, lv_nom_fichier, ln_nb_lignes);

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'AFFICHAGE DU BILAN');    
    -- Edite un rapport de traitment
    p_bilan(ln_nb_lignes,vd_date_der_exc,vd_odate);
    
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || cv_package_name || '.' || lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
  END main;

END DKA_ICE_BANKBRANCHES_DTR_PKG;
/
SHOW ERROR PACKAGE BODY DKA_ICE_BANKBRANCHES_DTR_PKG;
EXIT
