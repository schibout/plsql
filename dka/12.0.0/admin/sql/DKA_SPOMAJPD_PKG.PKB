CREATE OR REPLACE PACKAGE BODY DKA_SPOMAJPD_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SPOMAJPD_PKG 
  -- Nom              : DKA_SPOMAJPD_PKG 
  -- Description      : Body du package DKA_SPOMAJPD_PKG ( IMPORT DES RECEPTIONS PO )
  -- Auteur           : SELO
  -- Date de création : 17/07/2020
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 
  --------------------------------------------------------------------------------  
  
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
        cv_line                     VARCHAR2 (100);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '----------------------------------------------------------------------------------';

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
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Mise à jour commande - CUF Paiement Direct »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        --Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;
   
 /*
 *************************************************************************
 * PROCEDURE NAME : main
 * 
 * DESCRIPTION
 *  Procédure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

PROCEDURE main(
                p_Errbuf            IN OUT  VARCHAR2,
                p_retcode           OUT     NUMBER,
                p_commande          IN      NUMBER,
                p_paiement_direct   IN      VARCHAR2
              )

IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  error                       EXCEPTION;
  v_current_program_unit      VARCHAR2(30);
  v_ATTRIBUTE13               VARCHAR2(10); 
  v_segment1                  VARCHAR2(15);
  g_user_id                   fnd_user.user_id%TYPE;
  
BEGIN
     ----------------------------
      -- PHASE D'INITIALISATION --
      ----------------------------
      
      v_current_program_unit := 'main';
      g_user_id                      := fnd_global.user_id;	  
      
      Output_Header;
    BEGIN
	     select ATTRIBUTE13, segment1 into v_ATTRIBUTE13, v_segment1
                from PO_HEADERS_ALL PHA
               where PHA.PO_header_id=  p_commande;
    exception
        when others then
            fnd_file.put_line(fnd_file.OUTPUT,'   . Commande n''existe pas');	
            p_retcode := 1;	
            p_Errbuf := '   . Commande n''existe pas';			
    END;
    IF v_ATTRIBUTE13 = p_paiement_direct then
        fnd_file.put_line(fnd_file.OUTPUT,v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre est déjà celle présente sur la commande.');	
        p_retcode := 1;	
        p_Errbuf := v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre est déjà celle présente sur la commande.';	
        --Fnd_File.Put_Line(Fnd_File.LOG,  '==> '||v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre est déjà celle présente sur la commande.');		
    ELSE
        update PO_HEADERS_ALL PHA
		   set ATTRIBUTE13=p_paiement_direct
		     , LAST_UPDATE_DATE= SYSDATE
			 ,  LAST_UPDATED_BY= g_user_id
		 where PHA.PO_header_id= p_commande;
		 p_retcode := 0;
        fnd_file.put_line(fnd_file.OUTPUT,v_segment1 ||' : La valeur ' ||p_paiement_direct||' indiquée en paramètre a été mise à jour sur la commande.');	
		p_Errbuf := v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre est déjà celle présente sur la commande.';	
        --Fnd_File.Put_Line(Fnd_File.LOG, '==> '||v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre a été mise à jour sur la commande.');
    END IF;	
	
 
    

  EXCEPTION
        WHEN Erreur_Programme THEN
            p_retcode   := 2;
            p_errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
			
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SPOMAJPD_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main; 

------------------------------------------------------
END DKA_SPOMAJPD_PKG;



/
SHOW ERRORS;

EXIT
