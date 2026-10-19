CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAPEXTDATABLOC_PKG AS
  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : Projet Hélios
  -- NOM              : DKA_SAPEXTDATABLOC_PKG
  -- DESCRIPTION      : DKA_SAPEXTDATABLOC_PKG Package Body
  --
  -- AUTEUR           : IKRAME BALKHITY(Capgemini)
  -- DATE DE CREATION : 05/09/2023
  -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- -----------------------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (1000);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '+-----------------------------------------------------------------------------------------------------------------+';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????????????????????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line );
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Export de Blocages Factures pour le Datalake »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END output_header;

/*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '---------------------------------------------------------------------------';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

  -- -----------------------------------------------------------------------------
  -- Nom              : extraction_blocage
  --
  -- PARAMETRES       : Pv_Errbuf              Sortie Message d'erreur
  --                    Pn_Retcode             Sortie Code Retour de la procédure
  --                                                  '0' : Normal
  --                                                  '1' : Avertissement
  --                                                  '2' : Erreur
  --                    Pv_Debug_Mode Entrée          Mode debug
  --                    Pv_Region     Entrée          Centre de gestion
  --                    Pv_Periode    Entrée          Période
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE extraction_blocage(pv_errbuf  OUT VARCHAR2,
                               pn_retcode OUT NUMBER,
							   p_file_blocage OUT VARCHAR2) IS
  
    e_file EXCEPTION;
    pv_fin_periode   VARCHAR2(15);
    pv_fin_periode_1 VARCHAR2(15);
    pv_mois          VARCHAR2(10);
    l_message        VARCHAR2(4000);
    vn_date_pivot  VARCHAR2(20);
    vn_date_pivot_fin  VARCHAR2(20);
	is_found_rec boolean := false;
    -----------------------------------------------------------------
    -- Curseur de lecture des factures a la date du jour --
    -----------------------------------------------------------------
    CURSOR cur_blocage  IS
      select aha.INVOICE_ID ID_FACTURE,
       aha.HOLD_ID ID_BLOCAGE,
       aha.HOLD_DATE DATE_BLOCAGE,
       aha.HOLD_LOOKUP_CODE NOM_BLOCAGE,
       aha.HOLD_REASON MOTIF_BLOCAGE,
       aha.LINE_LOCATION_ID ID_LIGNE_COMMANDE,
       aha.ATTRIBUTE1 TYPE_WKF,
       --aha.ATTRIBUTE2 ATTRIBUTE2,
       --aha.ATTRIBUTE4 ATTRIBUTE4,
       aha.CREATION_DATE DATE_CREATION,
       aha.HELD_BY HELD_BY,
       aha.attribute5 TYPE_BLOCAGE_EN_ATTENTE,
       aha.LAST_UPDATED_BY LAST_UPDATED_BY,
       aha.last_update_date DERNIERE_MODIF_BLOCAGE,
       aha.RELEASE_LOOKUP_CODE CODE_DEBLOCAGE,
       aha.RELEASE_REASON MOTIF_DEBLOCAGE,

		(SELECT fu.user_name
          FROM apps.fnd_user fu
         WHERE fu.user_id = aha.LAST_UPDATED_BY
		 and aha.release_reason is not null) DEBLOQUE_PAR,
					 
       aha.ATTRIBUTE2 ID_WKF_FACTURE,
       aha.ATTRIBUTE4 A_TRAITER_IVALUA,
       --ppf.employee_number NOTIFIEE_IVA_BLC_EN_ATTENTE
	   (SELECT DISTINCT ppf.employee_number
          FROM apps.per_people_f ppf
         WHERE ppf.person_id = aha.attribute6) NOTIFIEE_IVA_BLC_EN_ATTENTE
  from AP_HOLDS_ALL    aha,
       ap_invoices_all aia
 where aha.INVOICE_ID = aia.invoice_id
   --and aia.last_update_date >= to_date(vn_date_pivot, 'DD/MM/YYYY');
   and ((aia.last_update_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS') and vn_date_pivot_fin is null)   
		 OR (aia.last_update_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS') and vn_date_pivot_fin is not null and aia.last_update_date <= to_date(vn_date_pivot_fin , 'DD/MM/YYYY HH24:MI:SS')));
     
    ------------------------------------------------------------------
    -- Curseur de lecture des lignes de la table  --
    ------------------------------------------------------------------
    CURSOR cur_fichier_blocage IS
      SELECT
        /* 1*/                                                              
        DEC.ID_FACTURE                        || ';' ||
      /* 2*/  
        DEC.ID_BLOCAGE                        || ';' ||
      /* 3*/  
        TO_CHAR(DEC.DATE_BLOCAGE, 'DD/MM/YYYY HH24:MI:SS')                      || ';' ||
    /* 4*/  
       '"'||DEC.NOM_BLOCAGE||'"'                      || ';' ||
    /* 5*/  
        '"'||DEC.MOTIF_BLOCAGE||'"'                     || ';' ||
    /* 6*/  
        DEC.ID_LIGNE_COMMANDE                 || ';' ligne1,
    /* 7*/  
        '"'||DEC.TYPE_WKF||'"'                       || ';' ||
    /* 8*/  
     --   '"'||DEC.ATTRIBUTE2||'"'                        || ';' ||
    /* 9*/  
       -- '"'||DEC.ATTRIBUTE4||'"'                        || ';' ||
    /* 10*/  
        TO_CHAR(DEC.DATE_CREATION, 'DD/MM/YYYY HH24:MI:SS')                     || ';' ||
    /* 11*/  
        DEC.HELD_BY                           || ';' ||
    /* 12*/  
        '"'||DEC.TYPE_BLOCAGE_EN_ATTENTE||'"'          || ';' ||
    /* 13*/  
        DEC.LAST_UPDATED_BY                   || ';' ligne2,
    /* 14*/  
        '"'||TO_CHAR(DEC.DERNIERE_MODIF_BLOCAGE, 'DD/MM/YYYY HH24:MI:SS')||'"'            || ';' ||
    /* 15*/  
        '"'||DEC.CODE_DEBLOCAGE||'"'                    || ';' ||
    /* 16*/  
        '"'||DEC.MOTIF_DEBLOCAGE||'"'                  || ';' ||
    /* 17*/  
        '"'||DEC.DEBLOQUE_PAR||'"'                      || ';' ||
    /* 18*/  
        '"'||DEC.ID_WKF_FACTURE||'"'                    || ';' ||
    /* 19*/  
        '"'||DEC.A_TRAITER_IVALUA||'"'                  || ';' ||
    /* 20*/  
        '"'||DEC.NOTIFIEE_IVA_BLC_EN_ATTENTE||'"'        ligne3
        FROM dka_sblocage DEC
       WHERE DEC.request_id = fnd_global.conc_request_id;
     
    rec_fichier_blocage cur_fichier_blocage%ROWTYPE;
  
    
  
    cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';
    vv_buffer      VARCHAR2(4000);
    vn_buffer_size PLS_INTEGER;
  
  vv_buffer_L      VARCHAR2(4000);
    vn_buffer_size_L PLS_INTEGER;
  
  vv_buffer_R      VARCHAR2(4000);
    vn_buffer_size_R PLS_INTEGER;
  
    vv_requested_by VARCHAR2(100);
    vn_org_id       NUMBER; 
  
    
    va_file_id utl_file.file_type;
  
    vv_filename VARCHAR2(80);
  
  
    vv_directory_name dba_directories.directory_path%TYPE;
    vv_period_name    VARCHAR2(60); 
    vv_end_date       VARCHAR2(10);
  BEGIN
  
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    dka_tools_pkg.put_debug_message('==> Début du traitement');
       BEGIN
    select  varchar2_value
      into vn_date_pivot
      from dka_parameters
         WHERE program_code = 'DKA_SAPEXTDATABLOC'
           AND parameter_name = 'Last_Extbloc_Date';
	
	select  varchar2_value
      into vn_date_pivot_fin
      from dka_parameters
         WHERE program_code = 'DKA_SAPEXTDATABLOC'
           AND parameter_name = 'Last_Extbloc_Date_Fin';
    EXCEPTION
      WHEN OTHERS THEN
        l_message  := 'erreur lors de la recuperation de parametre de derniere mise a jour';
        pn_retcode := 2;

    END;
    --------------------------------------------------------------
    -- Suppression des données de tous les traitements terminés --
    --------------------------------------------------------------
    dka_tools_pkg.put_debug_message('Suppression des données des traitements précédents');
  
    DELETE FROM dka_sblocage DEC
     WHERE EXISTS
     (SELECT 'X'
              FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
             WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
               AND fcr.phase_code = 'C'
               AND fcp.concurrent_program_name =
                   'DKA_SAPEXTDATABLOC'
               AND fcr.request_id = DEC.request_id);
  
    dka_tools_pkg.put_debug_message('==> ' || SQL%ROWCOUNT ||
                                    ' enregistrements supprimés');
  
    COMMIT;
  
    -------------------------------------------------------------------
    -- Recherche de la période en fonction de la date en entrée      --
    -------------------------------------------------------------------
    
     
    -----------------------------
    -- Traitement des factures --
    -----------------------------
    dka_tools_pkg.put_debug_message('Traitement des factures');
  
    -- Extraction des donnees

        
    for rec_blocage in    cur_blocage  loop
	
			  is_found_rec := true;
            
              dka_tools_pkg.put_debug_message('insertion facture : ' ||
                                              rec_blocage.ID_FACTURE);
              ------------------------------------------------
              -- Insertion dans la table dka_sextfacture_entete --
              ------------------------------------------------
			  BEGIN
			  
              INSERT INTO dka_sblocage
                (request_id,
                 ID_FACTURE                    ,
                 ID_BLOCAGE                    ,
                 DATE_BLOCAGE                  ,
                 NOM_BLOCAGE                   ,
                 MOTIF_BLOCAGE                 ,
                 ID_LIGNE_COMMANDE             ,
                 TYPE_WKF                    ,
                 --ATTRIBUTE2                    ,
                 --ATTRIBUTE4                    ,
                 DATE_CREATION                 ,
                 HELD_BY                       ,
                 TYPE_BLOCAGE_EN_ATTENTE       ,
                 LAST_UPDATED_BY               ,
                 DERNIERE_MODIF_BLOCAGE        ,
                 CODE_DEBLOCAGE                ,
                 MOTIF_DEBLOCAGE               ,
                 DEBLOQUE_PAR                  ,
                 ID_WKF_FACTURE                ,
                 A_TRAITER_IVALUA              ,
                 NOTIFIEE_IVA_BLC_EN_ATTENTE   

         )
              VALUES
                (fnd_global.conc_request_id,
                rec_blocage.ID_FACTURE               ,
                rec_blocage.ID_BLOCAGE               ,
                rec_blocage.DATE_BLOCAGE             ,
                rec_blocage.NOM_BLOCAGE              ,
                rec_blocage.MOTIF_BLOCAGE            ,
                rec_blocage.ID_LIGNE_COMMANDE        ,
                rec_blocage.TYPE_WKF               ,
                --rec_blocage.ATTRIBUTE2               ,
                --rec_blocage.ATTRIBUTE4               ,
                rec_blocage.DATE_CREATION            ,
                rec_blocage.HELD_BY                  ,
                rec_blocage.TYPE_BLOCAGE_EN_ATTENTE  ,
                rec_blocage.LAST_UPDATED_BY          ,
                rec_blocage.DERNIERE_MODIF_BLOCAGE   ,
                rec_blocage.CODE_DEBLOCAGE           ,
                rec_blocage.MOTIF_DEBLOCAGE          ,
                rec_blocage.DEBLOQUE_PAR             ,
                rec_blocage.ID_WKF_FACTURE           ,
                rec_blocage.A_TRAITER_IVALUA         ,
                rec_blocage.NOTIFIEE_IVA_BLC_EN_ATTENTE        

			);
			EXCEPTION
			 WHEN OTHERS THEN
			   pv_errbuf  := 'Erreur dans insert dans dka_sblocage : ' || SQLERRM;
               dka_tools_pkg.put_log_message(pv_errbuf);
			   pn_retcode := 2;
			 END;
           commit; 
          
     
     
    
    END LOOP;
	
	IF NOT is_found_rec THEN 
       pn_retcode:= 1;
	 ELSE
	   dka_tools_pkg.put_debug_message(' factures insérées dans la table de blocages');
	 END IF;
	
    
 
  
    -- Extraction des donnees
    
  
      ------------------------
      -- Edition du fichier --
      ------------------------
      dka_tools_pkg.put_debug_message('Edition du fichier');
    
      vv_filename := 'DKA_EXP_BLOCAGE_'||TO_CHAR(SYSDATE,'DDMMYYYY-HH24MISS')||'.csv'; 
	  p_file_blocage:= vv_filename;
	  
      -----------------------------------------
      -- Recherche du fichier de destination --
      -----------------------------------------
     
    
      --------------------------------------------------------
      -- Recherche du répertoire de destination du fichier. --
      --------------------------------------------------------
      SELECT dd.directory_path
        INTO vv_directory_name
        FROM dba_directories dd
       WHERE dd.directory_name = 'DKA_OUT_DIR';
    
      ---------------------------------------------------
      -- Vérifie que le fichier n'est pas déja ouvert. --
      ---------------------------------------------------
      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fermeture du fichier pour l''extraction RA.');
        --------------------------
        -- fermeture du fichier --
        --------------------------
        utl_file.fclose(va_file_id);
        dka_tools_pkg.put_log_message('  fichier fermé');
      END IF;
    
      -------------------------------------------
      -- Ouverture du fichier en Mode Ecriture --
      -------------------------------------------
      va_file_id := utl_file.fopen(cv_directory, vv_filename, 'w',5000); 
    
      ------------------------------------------------------------
      -- Vérifie que l'on a bien ouvert le fichier en écriture. --
      ------------------------------------------------------------
      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fichier ' || vv_directory_name || '/' ||
                                      vv_filename || ' ouvert en écriture');
      ELSE
        RAISE e_file;
      END IF;
    
      ---------------------------------------------------------------------
      -- Parcours du curseur contenant les différentes lignes a insérer. --
      ---------------------------------------------------------------------
	  
	  utl_file.put_line(va_file_id, 'ID_FACTURE;ID_BLOCAGE;DATE_BLOCAGE;NOM_BLOCAGE;MOTIF_BLOCAGE;ID_LIGNE_COMMANDE;TYPE_WKF;DATE_CREATION;HELD_BY;TYPE_BLOCAGE_EN_ATTENTE;LAST_UPDATED_BY;DERNIERE_MODIF_BLOCAGE;CODE_DEBLOCAGE;MOTIF_DEBLOCAGE;DEBLOQUE_PAR;ID_WKF_FACTURE;A_TRAITER_IVALUA;NOTIFIEE_IVA_BLC_EN_ATTENTE;');
	  
	  
      FOR rec_fichier_blocage IN cur_fichier_blocage LOOP
      
        
        begin 
  
        vv_buffer      := rec_fichier_blocage.ligne1 || rec_fichier_blocage.ligne2 || rec_fichier_blocage.ligne3;
    
     dka_tools_pkg.put_debug_message(vv_buffer);
   
        EXCEPTION WHEN OTHERS THEN
         l_message  := 'erreur vv_buffer';
        dka_tools_pkg.put_debug_message(l_message);
        end;    
              
        vn_buffer_size := length(vv_buffer);
      
        IF vn_buffer_size > 1023 THEN
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          vv_buffer := rec_fichier_blocage.ligne1 ||
                       substr(rec_fichier_blocage.ligne2,
                              0,
                              length(rec_fichier_blocage.ligne2) -
                              (length(vv_buffer) - 1023)) ||
                       rec_fichier_blocage.ligne3;
        
          utl_file.put_line(va_file_id, vv_buffer);
        
        
        ELSE
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          utl_file.put_line(va_file_id, vv_buffer);
        END IF;
      END LOOP;
    
      ---------------------------------------
      -- Fermeture du fichier en écriture. --
      ---------------------------------------
      utl_file.fclose(va_file_id);
    
   
  ----------------------------------------------------------
  dka_tools_pkg.put_debug_message('==> Mise à jour du paramètre Last_ExtFact_Date dans la table dka_parameters');
  -- Mise à jour du paramètre Last_ExtFact_Date dans la table dka_parameters
         UPDATE dka_parameters
         SET varchar2_value = to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')
         WHERE program_code = 'DKA_SAPEXTDATABLOC'
           AND parameter_name = 'Last_Extbloc_Date';
		   
		 UPDATE dka_parameters
         SET varchar2_value = null
         WHERE program_code = 'DKA_SAPEXTDATABLOC'
           AND parameter_name = 'Last_Extbloc_Date_Fin';
    commit;
    dka_tools_pkg.put_debug_message('==> Fin du traitement');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLCODE || ' - ' || substr(SQLERRM, 1, 80);
      pn_retcode := 2;
  
  END extraction_blocage;

/*
 *************************************************************************
 * PROCEDURE NAME : main
 * 
 * DESCRIPTION
 *  Procédure générale du traitement
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
 
 PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER)
IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  cv_line                     VARCHAR2 (100);
  v_file_blocage     		  VARCHAR2(100);

  
BEGIN

      Output_Header;
							   
	  extraction_blocage(v_errbuf,v_retcode,v_file_blocage);
	  
	  IF v_retcode = 2 
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
          RAISE Erreur_Programme;
	  ELSIF v_retcode = 1
	  THEN
		  Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Il y''a aucune donnée à traiter.');
		  Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
	  ELSIF v_retcode = 0
	  THEN
	      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Date de dernière exécution de l''export : ' || to_char(SYSDATE, 'DD/MM/YYYY'));
		  Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Nom du fichier BLOCAGES : ' || v_file_blocage);
		  Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Fin normale du traitement.');
          Pn_Retcode := v_retcode;
      END IF;
  
      output_end;
	  
	EXCEPTION
        WHEN Erreur_Programme THEN
            Pn_Retcode   := 2;
            Pv_Errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||' extraction_blocage '||' : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||' extraction_blocage '||' : EXCEPTION Erreur_Traitement ');        
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           Pn_Retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SAPEXTDATABLOC_PKG.' || ' extraction_blocage '||CHR(10)||' A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           Pv_Errbuf := SQLERRM;
END main;


END DKA_SAPEXTDATABLOC_PKG;
/

SHOW ERRORS

EXIT
