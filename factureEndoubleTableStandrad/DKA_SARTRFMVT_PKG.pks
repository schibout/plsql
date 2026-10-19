CREATE OR REPLACE PACKAGE BODY DKA_SPOMAJCP_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SPOMAJCP_PKG 
  -- Nom              : DKA_SPOMAJCP_PKG 
  -- Description      : Body du package DKA_SPOMAJCP_PKG ( IMPORT DES RECEPTIONS PO )
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
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Mise à jour commande - CUF Calcul des provisions »');
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
				p_Num_Ligne_de      IN      VARCHAR2,
				p_Num_Ligne_a       IN      VARCHAR2,
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

  CURSOR MAJ_LINES_PO IS
    select pla.line_num, pla.po_line_id, PLA.ATTRIBUTE2, pha.segment1
      from po_lines_all pla, 
	       PO_HEADERS_ALL PHA
     where pla.po_header_id= p_commande
	   and PHA.po_header_id = pla.po_header_id
       and nvl(pla.CLOSED_CODE,'A') not in ('CLOSED','FINALLY CLOSED')
       and PLA.CANCEL_FLAG <> 'Y'
	   and pla.po_line_id >= p_Num_Ligne_de
	   and pla.po_line_id <= p_Num_Ligne_a
	   order by pla.line_num
	   ;  
BEGIN
     ----------------------------
      -- PHASE D'INITIALISATION --
      ----------------------------
      
      v_current_program_unit := 'main';
      g_user_id                      := fnd_global.user_id;	  
      
      Output_Header;
     FOR rec_maj_lines_po IN MAJ_LINES_PO LOOP
         IF rec_maj_lines_po.ATTRIBUTE2 = p_paiement_direct then
             fnd_file.put_line(fnd_file.OUTPUT,'« '|| rec_maj_lines_po.segment1||' / '||rec_maj_lines_po.line_num||' : La valeur '||p_paiement_direct||' indiquée en paramètre est déjà celle présente sur la ligne de commande. »');	
             p_retcode := 1;	
			 -- p_retcode := 0;
             p_Errbuf := '« '|| rec_maj_lines_po.segment1||' / '||rec_maj_lines_po.line_num||' : La valeur '||p_paiement_direct||' indiquée en paramètre est déjà celle présente sur la ligne de commande. »';	
             --Fnd_File.Put_Line(Fnd_File.LOG,  '==> '||v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre est déjà celle présente sur la commande.');		
         ELSE
             update po_lines_all pla
	     	   set ATTRIBUTE2=p_paiement_direct
	     	     , LAST_UPDATE_DATE= SYSDATE
	     		 , LAST_UPDATED_BY= g_user_id
	     	 where pla.PO_header_id= p_commande
			   and pla.po_line_id=rec_maj_lines_po.po_line_id;
	     	 p_retcode := 0;
             fnd_file.put_line(fnd_file.OUTPUT,'« '|| rec_maj_lines_po.segment1||' / '||rec_maj_lines_po.line_num||' : La valeur '||p_paiement_direct||' indiquée en paramètre a été mise à jour sur la ligne de commande.');	
	     	p_Errbuf := '« '|| rec_maj_lines_po.segment1||' / '||rec_maj_lines_po.line_num||' : La valeur '||p_paiement_direct||' indiquée en paramètre a été mise à jour sur la ligne de commande.';	
             --Fnd_File.Put_Line(Fnd_File.LOG, '==> '||v_segment1 ||' : La valeur ' ||v_ATTRIBUTE13||' indiquée en paramètre a été mise à jour sur la commande.');
         END IF;	
	
     END LOOP;
    

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
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SPOMAJCP_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main; 

------------------------------------------------------
END DKA_SPOMAJCP_PKG;


/
SHOW ERRORS;

EXIT
