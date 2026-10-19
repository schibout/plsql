---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_AUTO_SARREFAC_ETAT.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_AUTO_SARREFAC_ETAT
--
-- AUTEUR           : Capgemini
-- DATE DE CREATION : 30/05/2006
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
-- Version          : 2.0
-- Date             : 27/09/2016
-- Auteur           : J.Jardez
-- Nature           : Portage HELIOS R12 
---------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 19/08/2019 SFA 	artf07289015 : 	INC0332370 - SPE022 - Problème archivage état de refacturation

----------------------------------------------------------------------------------------------------


SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR Ret_Code      VARCHAR2(10);
VAR Code_Bande    VARCHAR2(6);
VAR Utl_File_Name VARCHAR2(512);

DECLARE

    Vv_Code_Bande       VARCHAR2(6)   := '&&1';
    Vn_Nb_Jours         NUMBER        := 20;
    Vv_Prog_Name        VARCHAR2(250) := 'DKA_SARREFAC_GPE';
    Vv_Type_Fichier     VARCHAR2(250) := 'REFAC_';
    Vv_Original         VARCHAR2(250) := 'ORIGINAL';
    Vv_Duplicata        VARCHAR2(250) := 'DUPLICATA';
    Vv_Repertoire       VARCHAR2(250) := '$REP_DATA/editions_legales/DKA_SARREFAC/';
    Vn_Nb_Fic_A_Copier  NUMBER        := 0;
    Vn_Nb_Fic_Copies    NUMBER        := 0;

    Vv_Utl_File_Dir     V$parameter.VALUE%TYPE;
    Vv_Utl_File_Name    VARCHAR2(250);
    Vv_Extension        VARCHAR2(25);
    Vn_Request_Id       Fnd_Concurrent_Programs.Concurrent_Program_Name%TYPE;
    Vn_Prev_request_Id  Fnd_Concurrent_Programs.Concurrent_Program_Name%TYPE;
    Vv_Nom_Fichier      VARCHAR2(250);
    Vv_Line             VARCHAR2(250);
    Vf_Myfile           Utl_File.File_Type;
    
    vr_data      dka_parameters%ROWTYPE;
    vn_nb_etat   dka_parameters.number_value%TYPE;
    vn_retcode   NUMBER;
    vv_err_msg   VARCHAR2(100);
    Vn_orig_Request_Id fnd_concurrent_requests.request_id%TYPE;
    Vn_dup_Request_Id  fnd_concurrent_requests.request_id%TYPE;
    
    -----------------------------------------------
    -- Curseur de lecture des centres de gestion --
    -----------------------------------------------
    CURSOR Cur_Cdg IS
        SELECT Ffv.Flex_Value Centredegestion
        FROM   Fnd_Flex_Value_Sets Ffvs,
               Fnd_Flex_Values     Ffv
        WHERE  Ffvs.Flex_Value_Set_Name = 'DKA_CENTRES_DE_GESTION' 
        AND    Ffvs.Flex_Value_Set_Id   = Ffv.Flex_Value_Set_Id
        ORDER  BY Ffv.Flex_Value;

    Rec_Cdg Cur_Cdg%ROWTYPE;
    
    CURSOR Cur_output(p_req_id IN NUMBER) IS
     SELECT substr(file_name, 1, instr(file_name, '/', -1) - 1) path,
       substr(file_name, instr(file_name, '/', -1) + 1) file_name,
       lower(fcro.file_type) file_type
       FROM fnd_conc_req_outputs fcro
       WHERE concurrent_request_id = p_req_id;
       
    Rec_output Cur_output%ROWTYPE;

    -----------------------------------------
    -- Fonction de recherche du Request_Id --
    -----------------------------------------
    FUNCTION Recherche_Request_Id(Pv_Cdg             VARCHAR2,
                                  Pv_Type            VARCHAR2,
                                  Pn_Prev_Request_Id NUMBER) RETURN NUMBER IS

        Vn_Request_Id Fnd_Concurrent_Requests.Request_Id%TYPE;
    
        CURSOR Cur_Request IS
            SELECT Fcr.Request_Id
            FROM   Fnd_Concurrent_Requests Fcr,
                   Fnd_Concurrent_Programs Fcp,
                   Fnd_User                Fu
            WHERE  Fcr.Concurrent_Program_Id   = Fcp.Concurrent_Program_Id 
            AND    Fcp.Concurrent_Program_Name = Vv_Prog_Name 
            AND    Fcr.Requested_By            = Fu.User_Id 
            AND    Fcr.Request_Id              <  Nvl(Pn_Prev_Request_Id, Fcr.Request_Id+1) --JJA 21/09/2015
            AND    Fcr.Phase_Code              = 'C' 
            AND    Fcr.Status_Code             = 'C' 
            AND    Fcr.Argument1               = 'TRX_NUMBER' 
            AND    Fcr.Argument2  IS NULL 
            AND    Fcr.Argument3  IS NULL 
            AND    Fcr.Argument4  IS NULL 
            AND    Fcr.Argument5  IS NULL 
            AND    Fcr.Argument6  IS NULL 
            AND    Fcr.Argument7  IS NULL 
            AND    Fcr.Argument8  IS NULL 
            AND    Fcr.Argument9  IS NULL 
            AND    Fcr.Argument10 IS NULL 
            AND    Decode(Pv_Type, 'DUPLICATA', Fcr.Argument11, Nvl(Fcr.Argument11, '#')) = Decode(Pv_Type, 'DUPLICATA', Pv_Cdg, '#') 
            AND    Decode(Pv_Type,  'ORIGINAL', Fcr.Argument12, Nvl(Fcr.Argument12, '#')) = Decode(Pv_Type,  'ORIGINAL', Pv_Cdg, '#') 
            AND    Fcr.Argument13 = Decode(Pv_Type, 'ORIGINAL', 0, 1) 
            AND    Fu.User_Name   = Pv_Cdg 
            AND    Fcr.Actual_Completion_Date BETWEEN SYSDATE - Vn_Nb_Jours 
                                              AND     SYSDATE
            ORDER  BY Fcr.Actual_Completion_Date DESC;
    
    BEGIN
    
        OPEN Cur_Request;
        FETCH Cur_Request INTO Vn_Request_Id;
        CLOSE Cur_Request;
    
        RETURN(Vn_Request_Id);

    END Recherche_Request_Id;

    ---------------------------------------------------------------------------------
    -- Fonction de recherche de l'extension des fichiers en fonction de la période --
    ---------------------------------------------------------------------------------
    FUNCTION Recherche_Extension (pn_req_id NUMBER, Pv_Indice VARCHAR2,Pn_nb_etat NUMBER) RETURN VARCHAR2 IS
    
        Vc_Extension VARCHAR2(25);
        VV_extension VARCHAR2(30) := NULL;

    BEGIN
	   --<! SFA  : artf07289015
        /*SELECT To_Char(To_Date(Period_Name, 'MON-YY'), '_YYYY_MM') || 
               Decode(Pv_Indice, NULL, '.out', '_' || Pv_Indice || decode(Pn_nb_etat-1,0,'',Pn_nb_etat-1) ||'.out')
        INTO   Vc_Extension
        FROM   Gl_Period_Statuses
        WHERE  Application_Id                     = 222 
        AND    Set_Of_Books_Id                    = Fnd_Profile.VALUE('GL_SET_OF_BKS_ID') 
        AND    Last_Day(Trunc(SYSDATE, 'MM') - 1) = End_Date;
        */
    FOR Rec_output IN Cur_output(pn_req_id) LOOP
       VV_extension := Rec_output.file_type;
    END LOOP;
           
    IF VV_extension IS NULL THEN
      VV_extension := 'out';
    END IF;
           
		SELECT
			TO_CHAR(TO_DATE(PERIOD_NAME,'MON-YY'),'_YYYY_MM')
			|| DECODE(PV_INDICE,NULL,'.'||VV_extension,'_'
											  || PV_INDICE
											  || DECODE(PN_NB_ETAT - 1,0,'',PN_NB_ETAT - 1)
											  || '.'||VV_extension)
		INTO   Vc_Extension									  
		FROM
			GL_PERIODS
		WHERE
			PERIOD_SET_NAME = 'GROUPE'
			AND END_DATE = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1));
        RETURN(Vc_Extension);
        --fin modification SFA  : artf07289015 -->--
    END Recherche_Extension;


    -------------------------------------------------------
    -- Procédure d'écriture dans le fichier de commandes --
    -------------------------------------------------------
    PROCEDURE Ecriture_Fichier (Pn_Request_Id       NUMBER,
                                Pv_Type             VARCHAR2,
                                Pv_Repertoire       VARCHAR2,
                                Pv_Nom_Fichier      VARCHAR2,
                                Pv_CentreDeGestion  VARCHAR2,
                                Pf_Myfile           Utl_File.File_Type) IS

        Vv_Line  VARCHAR2(250);
        VV_fichier VARCHAR2(100);

    BEGIN  
                                
        Dbms_Output.Put_Line('====> Traitement du fichier : ' || Pv_Nom_Fichier);
        VV_fichier := NULL;
        

        IF Pn_Request_Id IS NOT NULL THEN
          
           FOR Rec_output IN Cur_output(Pn_Request_Id) LOOP
             VV_fichier := Rec_output.file_name;
           END LOOP;
           
           IF VV_fichier IS NULL THEN
             VV_fichier := 'o'|| Pn_Request_Id || '.out';
           END IF;

          Vv_Line := 'echo Traitement du fichier '|| VV_fichier;
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Vv_Line := 'cp $APPLCSF/$APPLOUT/' || VV_fichier || ' ' || Pv_Repertoire || Pv_Nom_Fichier;
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Vv_Line := 'if [ $? -eq 0 ]';
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Vv_Line := 'then';
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Vv_Line := '   echo La copie du fichier ' || VV_fichier || ' en ' || Pv_Nom_Fichier || ' est terminée';
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Vv_Line := 'else';
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Vv_Line := '   echo Erreur lors de la copie du fichier ' || VV_fichier;
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Vv_Line := 'fi';
           Utl_File.Put_Line(Pf_Myfile, Vv_Line);
           Utl_File.Fflush(Pf_Myfile);

           Vn_Nb_Fic_Copies := Vn_Nb_Fic_Copies + 1;
        ELSE
           Dbms_Output.Put_Line('==> ERREUR :');
           Dbms_Output.Put_Line('==> Le traitement ' || Pv_Type || ' pour le centre de gestion ' || Pv_CentreDeGestion || ' n''a pas été trouvé !!!');
           :Ret_Code := 'FAILURE';
        END IF;

    END Ecriture_Fichier;

BEGIN

    :Ret_Code   := 'SUCCESS';
    :Code_Bande := Vv_Code_Bande;


    -----------------------------------------------------------------------------
    -- Recherche du parametre : SARREFAC/NB_ETAT_ARCHIVAGE                     --
    -----------------------------------------------------------------------------
    BEGIN
        
      dka_tools_pkg.get_parameter('SARREFAC','NB_ETAT_ARCHIVAGE',vr_data,vn_retcode,vv_err_msg);
      vn_nb_etat := vr_data.number_value;
      
      IF vn_retcode != 0 THEN
         Dbms_Output.Put_Line('Erreur lors de  le parametre : SARREFAC/NB_ETAT_ARCHIVAGE : la valeur par défaut est 3');
         vn_nb_etat := 3;
      END IF;            
  
    EXCEPTION
        WHEN OTHERS THEN
            Dbms_Output.Put_Line('Impossible de récupérer le parametre : SARREFAC/NB_ETAT_ARCHIVAGE : la valeur par défaut est 3');
            vn_nb_etat := 3;   
    END;
    
    -----------------------------------------------------------------------------
    -- Recherche du répertoire dans lequel sera généré le fichier de commandes --
    -----------------------------------------------------------------------------
    BEGIN
        /*
		SELECT Value
        INTO   Vv_Utl_File_Dir
        FROM   V$parameter
        WHERE  Name = 'utl_file_dir';
		*/  
		-- SELO tracker50786 - INC0404259
		select directory_path
		  into Vv_Utl_File_Dir
		  from all_directories
		 where directory_name like 'DKA_OUT_DIR' ;    
    
        /*
		IF Instr(Vv_Utl_File_Dir, ',') != 0 THEN
           Vv_Utl_File_Dir := Substr(Vv_Utl_File_Dir, 1, Instr(Vv_Utl_File_Dir, ',') - 1);
        END IF;
        */
    EXCEPTION
        WHEN OTHERS THEN
            Dbms_Output.Put_Line('Impossible de récupérer le répertoire de création des fichiers :');
            :Ret_Code := 'FAILURE';
            RETURN;
    END;

    Vv_Utl_File_Name := 'DKA_SARREFAC.sh';
    :Utl_File_Name   := Vv_Utl_File_Dir || '/' || Vv_Utl_File_Name;

    --------------------------------------
    -- Ouverture du fichier de commande --
    --------------------------------------
    -- Vf_Myfile := Utl_File.Fopen(Vv_Utl_File_Dir, Vv_Utl_File_Name, 'w');  -- SELO tracker50786 - INC0404259
	Vf_Myfile := Utl_File.Fopen('DKA_OUT_DIR', Vv_Utl_File_Name, 'w');		 -- SELO tracker50786 - INC0404259
	
	

    ---------------------------------------------------------------------------------------------
    -- Dans le fichier de commandes, on commence par supprimer tous les fichiers du répertoire --
    ---------------------------------------------------------------------------------------------
    Utl_File.Put_Line(Vf_Myfile, 'echo Vidage des fichiers');
    Utl_File.Put_Line(Vf_Myfile, 'rm ' || Vv_Repertoire || Vv_Type_Fichier || Vv_Original || '*.out');
    Utl_File.Put_Line(Vf_Myfile, 'rm ' || Vv_Repertoire || Vv_Type_Fichier || Vv_Duplicata || '*.out');
    Utl_File.Put_Line(Vf_Myfile, 'echo Transfert des fichiers');
    Utl_File.Fflush(Vf_Myfile);

    ----------------------------------------------
    -- Boucle de lecture des centres de gestion --
    ----------------------------------------------
    OPEN Cur_Cdg;
    LOOP
        FETCH Cur_Cdg INTO Rec_Cdg;
        EXIT WHEN Cur_Cdg%NOTFOUND;
        
        Vn_orig_Request_Id := NULL;
        Vn_dup_Request_Id  := NULL;
        
        Utl_File.Put_Line(Vf_Myfile, Rec_Cdg.Centredegestion);
    
        FOR i in 1..vn_nb_etat LOOP
          --------------------------------------------------------------------------------------
          -- Recherche du Request_Id du dernier traitement original pour le centre de gestion --
          --------------------------------------------------------------------------------------
          --Utl_File.Put_Line(Vf_Myfile, Rec_Cdg.Centredegestion||'/'|| Vv_Duplicata ||'/'|| Vn_orig_Request_Id);
          Vn_Request_Id      := Recherche_Request_Id(Rec_Cdg.Centredegestion, Vv_Original, Vn_orig_Request_Id);
          --Utl_File.Put_Line(Vf_Myfile, 'rid : ' || Vn_Request_Id);
          IF  Vn_Request_Id !=  nvl(Vn_orig_Request_Id,-1) THEN
            Vn_orig_Request_Id := Vn_Request_Id;
            Vn_Nb_Fic_A_Copier := Vn_Nb_Fic_A_Copier + 1;
            Vv_Extension       := Recherche_Extension(Vn_Request_Id, 'J',i);
            Vv_Nom_Fichier     := Vv_Type_Fichier || Vv_Original || '_' || Rec_Cdg.Centredegestion || Vv_Extension;
            Ecriture_Fichier (Vn_Request_Id, Vv_Original, Vv_Repertoire, Vv_Nom_Fichier, Rec_Cdg.CentreDeGestion, Vf_Myfile);
          END IF;
          
          ---------------------------------------------------------------------------------------
          -- Recherche du request_Id du dernier traitement duplicata pour le centre de gestion --
          ---------------------------------------------------------------------------------------
          --Utl_File.Put_Line(Vf_Myfile, Rec_Cdg.Centredegestion||'/'|| Vv_Duplicata ||'/'|| Vn_orig_Request_Id);
          Vn_Request_Id      := Recherche_Request_Id(Rec_Cdg.Centredegestion, Vv_Duplicata, Vn_dup_Request_Id);
          --Utl_File.Put_Line(Vf_Myfile, 'rid : ' || Vn_Request_Id);
          IF  Vn_Request_Id !=  nvl(Vn_dup_Request_Id,-1) THEN
            Vn_dup_Request_Id  := Vn_Request_Id;
            Vn_Nb_Fic_A_Copier := Vn_Nb_Fic_A_Copier + 1;
            Vv_Extension       := Recherche_Extension(Vn_Request_Id, 'J',i);
            Vv_Nom_Fichier     := Vv_Type_Fichier || Vv_Duplicata || '_' || Rec_Cdg.Centredegestion || Vv_Extension;
            Ecriture_Fichier (Vn_Request_Id, Vv_Duplicata, Vv_Repertoire, Vv_Nom_Fichier, Rec_Cdg.CentreDeGestion, Vf_Myfile);
          END IF;
          
        END LOOP;
    END LOOP;
    CLOSE Cur_Cdg;

    -------------------------------------
    -- Génération de la fin du fichier --
    -------------------------------------
    Vv_Line := 'echo Génération du bordereau';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := 'ksh $DKA_TOP/bin/DKA_SARREFAC_ETAT_BOR.sh ' || Vv_Code_Bande;
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := 'echo';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := 'if [ $? -eq 0 ]';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := 'then';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := '   echo Génération du bordereau terminée';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := 'else';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := '   echo Erreur lors de la génération du bordereau';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Vv_Line := 'fi';
    Utl_File.Put_Line(Vf_Myfile, Vv_Line);
    Utl_File.Fflush(Vf_Myfile);

    ---------------------------------------
    -- Fermeture du fichier de commandes --
    ---------------------------------------
    Utl_File.Fclose_All;

    Dbms_Output.Put_Line(Chr(10) || '==> Nombre de fichiers a copier  : ' || To_Char(Vn_Nb_Fic_A_Copier, '99990'));
    Dbms_Output.Put_Line('==> Nombre de fichiers copiés    : ' || To_Char(Vn_Nb_Fic_Copies, '99990'));

EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';

END;
/
COL :utl_file_name NEW_VALUE utl_file_name;
COL :code_bande    NEW_VALUE code_bande;
SELECT :utl_file_name
FROM   DUAL;
SELECT :code_bande
FROM   DUAL;
HOST ls &utl_file_name;
HOST sh &utl_file_name;

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
