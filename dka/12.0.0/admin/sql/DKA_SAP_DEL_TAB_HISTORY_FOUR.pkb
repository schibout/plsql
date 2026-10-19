create or replace PACKAGE BODY DKA_SAP_DEL_TAB_HISTORY_FOUR AS
--------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SAP_DEL_TAB_HISTORY_FOUR
  -- Nom              : DKA_SAP_DEL_TAB_HISTORY_FOUR
  -- Description      : ENTETE du package DKA_SAP_DEL_TAB_HISTORY_FOUR ( PURGE DES TABLES )
  -- Auteur           : SELO	
  -- Date de création : 21/12/2021
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  
  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --                    p_nbre_jours     Nombre de jours 
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
PROCEDURE main(
                p_Errbuf    IN OUT  VARCHAR2,
                p_retcode   OUT     NUMBER--,
                --p_nbre_jours   IN      NUMBER
              )

IS
      v_errbuf                    VARCHAR2(2500);
      v_retcode                   NUMBER;
      Erreur_Programme            EXCEPTION;
      error                       EXCEPTION;
      v_request_id NUMBER;
      rec_param                        dka_parameters%ROWTYPE;
	  pn_retcode                       NUMBER;
	  vv_nbre_jours                    dka_parameters.varchar2_value%type;
	  p_nbre_jours                NUMBER;
      cv_line                     VARCHAR2 (100);
      v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
      v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
	  NBR_SITE                    NUMBER;
	  NBR_HEADER                  NUMBER; 
    BEGIN

        cv_line    := '----------------------------------------------------------------------------------';
    
        Fnd_File.put_line (Fnd_File.output, cv_line );
		Fnd_File.put_line (Fnd_File.output, 'TRAITEMENT « DKA : Purge des tables historiques des modifications des fournisseurs »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));	
	    dka_tools_pkg.get_parameter ('DKA_SAP_DEL_TAB_HISTORY_FOUR', 'DKA_PURGE_HIST_MODIFICATIONS_REFERENTIEL', rec_param, pn_retcode, v_errbuf);
		IF pn_retcode != 0 THEN
		   p_retcode := 2;
		   RETURN;
		END IF;
		vv_nbre_jours := rec_param.varchar2_value;
		DBMS_OUTPUT.PUT_LINE ('=> nbre_jours: ' || vv_nbre_jours || '.');
 
	
	
	    p_nbre_jours := TO_NUMBER(vv_nbre_jours);
		
		Select count(1) into NBR_HEADER
		  from DKA_SAPFRS_MAJ_SITES where last_update_date < sysdate - p_nbre_jours;
		  
		Select count(1) into NBR_SITE
		  from DKA_SAPFRS_MAJ_HEADERS where last_update_date < sysdate - p_nbre_jours;
		
		insert into DKA_SAPFRS_MAJ_SITES_HIST 
		select * from DKA_SAPFRS_MAJ_SITES where last_update_date < sysdate - p_nbre_jours;
		
		insert into DKA_SAPFRS_MAJ_HEADERS_HIST 
		select * from DKA_SAPFRS_MAJ_HEADERS where last_update_date < sysdate - p_nbre_jours;
		
		delete from DKA_SAPFRS_MAJ_SITES where last_update_date < sysdate - p_nbre_jours;
		
		delete from DKA_SAPFRS_MAJ_HEADERS where last_update_date < sysdate - p_nbre_jours;	
		
        commit;
        
		fnd_file.put_line(fnd_file.OUTPUT,'   Compte rendu :'|| CHR(10));
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des enregistrements archivés et purgés dans la table historique des modifications des entêtes fournisseurs   : '||TO_CHAR(NBR_HEADER));
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des enregistrements archivés et purgés dans la table historique des modifications des sites fournisseurs     : '||TO_CHAR(NBR_SITE)|| CHR(10));		
        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DU TRAITEMENT');
        fnd_file.put_line(fnd_file.OUTPUT,'   Fin du traitement avec succès'|| CHR(10));
		
		
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
    EXCEPTION
       WHEN OTHERS
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique ' );
		   Fnd_File.put_line (Fnd_File.OUTPUT,'Erreur technique ' || CHR(10));
		   Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END main;

END DKA_SAP_DEL_TAB_HISTORY_FOUR;
/
SHOW ERRORS
EXIT