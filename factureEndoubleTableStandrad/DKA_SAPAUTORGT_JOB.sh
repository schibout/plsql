CREATE OR REPLACE PACKAGE BODY dka_srbrapauto_pkg AS
--------------------------------------------------------------------------------------------------------------- 
-- $Id: DKA_SRBRAPAUTO_PKG.pkb 299 2008-03-27 13:16:01Z NORDEST\jdequidt $
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		     : DKA_SRBRAPAUTO_PKG.pkb
-- DESCRIPTION	     : lancement du traitement "rapprochemnt automatique" en multi-org(certaines sociétés seulement)
--                     pour le module RB (rapprochement bancaire) 
---
--- AUTEUR	     : Guillaume Chabrier
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
--- 03/07/2002 EVS Modification curseur sociétés + Introduction du filtre des 26
--- 24/05/2005 CDE PHENIX 2005 : suppression appel table dka_active_companies et filtre des 26 et boucle sociétés
--- 14/09/2005 PJ  Prise en compte du paramètre liste des pointes
--- 27/03/2008 JDE CSP Portabilité modification du paramètre RB_RESPONSIBILITY_KEY selon la responsabilité
--- 18/11/2016 OBE Migration R12
--- 01/04/2021 NBO EDB279 - DGE20200021 - Automatisation du lettrage des prélèvements bancaires (ESFORA)
---------------------------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---------------------------------------------------------------------------------------------------------------  
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur   
--                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur' 
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
PROCEDURE main(pv_errbuf        IN  OUT VARCHAR2,
               pn_retcode           OUT NUMBER)

IS
vn_responsibility_id   NUMBER; 
vn_application_id      NUMBER;
vv_responsibility      VARCHAR2(100);
vr_rec_param           dka_parameters%ROWTYPE; 
  
vn_requests_cnt        NUMBER;
va_request_ids         pa_utils.IdTabTyp; ---Tableau	
vn_request_id          NUMBER;	
vv_phase	       VARCHAR2(100); 
vv_status	       VARCHAR2(100); 
vv_dev_phase	       VARCHAR2(100); 
vv_dev_status          VARCHAR2(100);
vv_errbuf              VARCHAR2(150);
vb_reduction_26        VARCHAR2(1);
vv_dummy               VARCHAR2(100);
vn_retcode             NUMBER;
e_next_rec             EXCEPTION;

vn_org_id              NUMBER;         /* CSP portabilité */
vn_sob_id              NUMBER;         /* CSP portabilité */
vv_responsibility_key  VARCHAR2(100);  /* CSP Portabilité */

-- PHENIX 2005 - Suppression boucle sociétés
-- boucle sur les sociétés sur lesquelles le traitement sera lancé
/*CURSOR cur_rbrapauto IS
SELECT haou.name
FROM   hr_all_organization_units haou
WHERE  haou.type='SOCIETE'
ORDER BY name;

CURSOR cur_rbtodelete IS
SELECT haou.organization_id 
FROM hr_all_organization_units haou
WHERE haou.type='SOCIETE' AND NOT EXISTS (SELECT dac.name FROM dka_active_companies dac WHERE dac.name = haou.name);
*/

BEGIN

-- PHENIX 2005 - suppression reduction_26
  ----- Récupération option de profil pour savoir si on réduit RB aux 26 sociétés cloturant fin juin -----
-- PHENIX 2005   vb_reduction_26 := fnd_profile.value('DKA_REDUCTION_26');

  -------------------------------------------------------------------------------------------------------
  --------------------- LANCEMENT DES TRAITEMENTS DE RAPPROCHEMENT AUTOMATIQUE RB -----------------------
  -------------------------------------------------------------------------------------------------------
  
  vn_requests_cnt := 0;

-- --PHENIX 2005 - suppression reduction_26 et boucle  
/*  FOR rec_rbrapauto IN cur_rbrapauto
  LOOP
    BEGIN
      IF (vb_reduction_26 = 'Y')
      THEN
        BEGIN
          SELECT dac.name
          INTO vv_dummy
          FROM dka_active_companies dac
          WHERE dac.name = rec_rbrapauto.name;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
           RAISE e_next_rec;
          WHEN OTHERS THEN
            
            RAISE e_next_rec;
        END;
      END IF;
*/
      /* Début CSP Portabilité */
      --< OBE
      /*
      vn_org_id := fnd_profile.value('ORG_ID');
      IF vn_org_id IS NULL THEN
        pn_retcode := 2;
        dka_tools_pkg.put_log_message('L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée');
        RETURN;
      END IF;
      
      
      vn_sob_id := fnd_profile.value('GL_SET_OF_BKS_ID');
      IF vn_org_id IS NULL THEN
        pn_retcode := 2;
        dka_tools_pkg.put_log_message('L''option de profil 1_Nom de l''entité comptable GL n''est pas paramétrée');
        RETURN;
      END IF;*/
      --> OBE
      
      --vv_responsibility_key := 'RB_RESPONSIBILITY_KEY_' || LPAD(TO_CHAR(vn_org_id), 4, '0');  -- OBE
      vv_responsibility_key := 'RB_RESPONSIBILITY_KEY';                                         -- OBE
      
      ----- Récupération du radical de la  responsabilité RB  -----
      dka_tools_pkg.get_parameter( 'SRBRAPAUTO',
                                   vv_responsibility_key,
                                   vr_rec_param,
                                   pn_retcode,
                                   pv_errbuf);
      /* Fin CSP Portabilité */
      
      IF pn_retcode != 0
      THEN
        pn_retcode := 2;
        dka_tools_pkg.put_log_message(pv_errbuf);
        RETURN;
      END IF;
      
      vv_responsibility := vr_rec_param.varchar2_value;
      
      -- Récupération du contexte nécessaire au lancement du traitement RB -----
      BEGIN
        SELECT fr.responsibility_id, fr.application_id
        INTO vn_responsibility_id, vn_application_id
        FROM fnd_responsibility fr
        WHERE fr.responsibility_key = vv_responsibility; -- PHENIX 2005 || rec_rbrapauto.name;
      EXCEPTION
        WHEN OTHERS THEN
          pn_retcode := 2;
-- PHENIX 2005          pv_errbuf := 'Echec recherche responsabilité RB ' || vv_responsibility || rec_rbrapauto.name || ' : ' || SQLERRM;
          pv_errbuf := 'Echec recherche responsabilité RB ' || vv_responsibility || ' : ' || SQLERRM;
          dka_tools_pkg.put_log_message(pv_errbuf);
          RETURN;
      END;
      
      ----- Initialisation de l'environement OA -----
      fnd_global.apps_initialize(fnd_global.user_id, vn_responsibility_id, vn_application_id);
-- PJ prise en compte   du paramètre liste des pointes 14 sep 2005      
      --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST   
      vn_request_id := fnd_request.submit_request(
                                     'XXRB', --'RB', --APPLICATION -- OBE
                                     'RBMATRUN',     --PROGRAM
                                     NULL,           --PROGRAM_NAME
                                     NULL,           --START_TIME
                                     FALSE,          --SUB_REQUEST
                                     'N',            -- _SIMULATION
                                     TO_CHAR(SYSDATE,'YY/MM/DD HH24:MM'), -- _PROCESS_NAME
                                     'Y',            -- _REPORT_UNMATCHED
                                     'Y',            -- _REPORT_MATCHED
                                     'Y',            -- _REPORT pointe
                                     NULL,           -- _BANK_ACCOUNT
                                     NULL            -- _DATE 
                                     );
      IF vn_request_id IS NULL
      THEN
        pn_retcode := 1;
-- PHENIX 2005        pv_errbuf := 'Le traitement de rapprochement automatique RB n''a pas pu être lancé pour la société  '||rec_rbrapauto.name;
        pv_errbuf := 'Le traitement de rapprochement automatique RB n''a pas pu être lancé ';
        dka_tools_pkg.put_log_message(pv_errbuf);
      ELSE 
-- PHENIX 2005        pv_errbuf := 'Rapprochement automatique RB : '||TO_CHAR(vn_request_id)||' lancé sur la société '||rec_rbrapauto.name;
        pv_errbuf := 'Rapprochement automatique RB : '||TO_CHAR(vn_request_id);
        dka_tools_pkg.put_log_message(pv_errbuf);
        vn_requests_cnt := vn_requests_cnt + 1;
        va_request_ids(vn_requests_cnt) := vn_request_id;
      END IF;
    
    COMMIT;
 
-- PHENIX 2005  
/*    EXCEPTION
      WHEN e_next_rec THEN
      NULL;
    END;

 END LOOP;
*/

  IF pn_retcode = 1
  THEN
    pv_errbuf := 'Des traitements de rapprochement n''ont pu être lancés';
  END IF;

  
  vn_retcode := 0;
  
  WHILE vn_requests_cnt > 0
  LOOP
    IF NOT (fnd_concurrent.wait_for_request(va_request_ids(vn_requests_cnt),
                                            15,
                                            0,
                                            vv_phase,
                                            vv_status,
                                            vv_dev_phase,
                                            vv_dev_status,
                                            vv_errbuf))
    THEN
      vn_retcode := 1;
      dka_tools_pkg.put_log_message('Traitement numéro ' || TO_CHAR(va_request_ids(vn_requests_cnt)) || ' trop long ou tombé en erreur');     
    ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL')
    THEN
      dka_tools_pkg.put_log_message('Traitement numéro ' || TO_CHAR(va_request_ids(vn_requests_cnt)) || ' correctement exécuté');
    END IF;

    vn_requests_cnt := vn_requests_cnt - 1;
  
  END LOOP;

  IF vn_retcode = 1
  THEN
    pn_retcode := 1;
    pv_errbuf := pv_errbuf || '- Des traitements de rapprochement automatique RB sont tombés en erreur';
  END IF;

  -------------------------------------------------------------------------------------------------------
  ---------------------------------- FILTRE EVENTUEL SUR LES 26 SOCIETES --------------------------------
  -------------------------------------------------------------------------------------------------------

-- PHENIX 2005 - suppression du filtre  
/*  IF vb_reduction_26 ='Y'
  THEN
    BEGIN
--      DELETE FROM rb_lines_all rla
--      WHERE rla.org_id NOT IN (SELECT haou.organization_id FROM dka_active_companies dac, hr_all_organization_units haou
--                           WHERE haou.type='SOCIETE' AND haou.name = dac.name);

      FOR rec_rbtodelete IN cur_rbtodelete
      LOOP
        dka_tools_pkg.put_log_message('Suppression lignes RB org_id : ' || TO_CHAR(rec_rbtodelete.organization_id));
        DELETE FROM rb_lines_all rla
        WHERE rla.org_id = rec_rbtodelete.organization_id;
        COMMIT;
      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        pn_retcode := 2;
        pv_errbuf := pv_errbuf || '- Problème sur le filtrage des 26 : ' || SQLERRM;
    END;
    
  END IF;
*/
  --- 01/04/2021 NBO EDB279 - DGE20200021 - Automatisation du lettrage des prélèvements bancaires (ESFORA)
  UPDATE dka_prel_ap_rb dpar
   SET dpar.statut_etape = 'E7',
       (dpar.matching_status_rb, dpar.rapproche_le) = (select nvl(rl.matching_status,'Y'), rl.matching_date from rb_lines rl
           WHERE rl.je_header_id = dpar.id_piece_gl
             AND rl.je_line_num = dpar.numero_ligne_gl)
   WHERE dpar.statut_etape = 'E6'
     AND EXISTS (SELECT 'x'
            FROM rb_lines rl
           WHERE rl.je_header_id = dpar.id_piece_gl
             AND rl.je_line_num = dpar.numero_ligne_gl
             AND rl.matching_status = 'Y');
           
  COMMIT;

END main;
--------------------------------------------------------------------------------------------------------------
END dka_srbrapauto_pkg;
/
SHOW ERROR;
EXIT;          
