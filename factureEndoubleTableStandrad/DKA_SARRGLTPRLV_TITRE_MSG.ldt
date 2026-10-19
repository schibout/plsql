/*<TOAD_FILE_CHUNK>*/
/* Formatted on 05/17/2002 17:26 (Formatter Plus v4.5.2) */
CREATE OR REPLACE PACKAGE BODY dka_spaapimp_si_pkg
AS

---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI 
-- PROJET            : DALKIA Oracle Applications
-- NOM           : DKA_SPAAPIMP_SI_PKG.pkb
-- DESCRIPTION       : Approbation toutes sociétés des factures fournisseurs
---
--- AUTEUR       : Guillaume Chabrier
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--  08/08/2002 GLN Modification fnd_request.submit_request (application PA au lieu de SQLAP)
--                 Ajout du wait_for_request
--  25/10/2002 XD  Modification de la requête de sélection
--  03/06/2003 AD  Modification du curseur de selection
--  25/06/2003 XD  Mise à jour des lignes à zéro en provenance de commandes PO
--  04/08/2004 SLE Portage spécifique pour projet PHENIX 2004 
--                 Modification et déplacement de la requête sur la table " fnd_responsibility " et de 
--                 l'appel à la procédure " fnd_global.apps_initialize
--  30/10/2007 AD  ETANCHEITE DALKIA 2007
--  31/05/2016 BDE HELIOS Modification de la responsibilité avant chaque lancement du traitement
--  24/11/2016 NBO SPE001 - defect 388 Prise en compte des données AP du jour en erreur
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
--                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_responsibility_id   NUMBER;
        vn_application_id      NUMBER;
        vv_ap_responsibility   VARCHAR2 (100);
        rec_param              dka_parameters%ROWTYPE;
        vn_request_id          NUMBER;

       ln_org_id   	       hr_all_organization_units.organization_id%TYPE;
       va_request_ids          pa_utils.idtabtyp;
       vv_phase                VARCHAR2(10);
       vv_status               VARCHAR2(10);
       vv_dev_phase            VARCHAR2(10);
       vv_dev_status           VARCHAR2(10);
       vv_errbuf               VARCHAR2(150);
       vn_erreur               NUMBER(15);
       vn_compteur	       NUMBER(15);
       vv_parameter            dka_parameters.parameter_name%TYPE;


          CURSOR cur_approved
        IS
            SELECT hou.organization_id,
                   hou.NAME
            FROM   hr_all_organization_units hou
            WHERE  hou.organization_id IN ( SELECT ai.org_id
                                            FROM   ap_invoices ai,
                                                   ap_invoice_distributions aid
                                            WHERE  ai.invoice_type_lookup_code != 'EXPENSE REPORT'
                                               AND aid.invoice_id = ai.invoice_id
                                               AND aid.line_type_lookup_code = 'ITEM'
                                               AND aid.project_id IS NOT NULL
                                               AND aid.pa_addition_flag NOT IN ('E', 'T', 'Y', 'Z'));



    BEGIN
        dka_tools_pkg.put_debug_message ('main+');
        dka_tools_pkg.put_log_message('main+');
        vv_parameter :=  'AP_RESPONSIBILITY_KEY' ;
        dka_tools_pkg.get_parameter ('SPAAPIMP_SI', vv_parameter, rec_param, pn_retcode, pv_errbuf);
        IF pn_retcode != 0
        THEN
            pn_retcode    := 1;
            RETURN;
        END IF;

        vn_compteur := 0;
        vn_erreur :=0;

        vv_ap_responsibility    := rec_param.varchar2_value;
        
        dka_tools_pkg.put_debug_message ('vv_ap_responsibility' ||vv_ap_responsibility);
 

		
        

        dka_tools_pkg.put_debug_message ('flag lignes à zéro +');

        /*UPDATE ap_invoice_distributions_all aid
        SET    aid.pa_addition_flag = 'Z'
        WHERE  aid.pa_addition_flag = 'N'
        AND    aid.amount = 0;*/

        dka_tools_pkg.put_debug_message ('--> ' || TO_CHAR (SQL%ROWCOUNT) || ' lignes');
        dka_tools_pkg.put_debug_message ('flag lignes à zéro -');

        FOR rec_approved IN cur_approved 
        LOOP
                -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
                --vv_ap_responsibility    := rec_approved.name||'_'||rec_param.varchar2_value;
                vv_ap_responsibility    := 'TOUT_'||rec_param.varchar2_value;
				dka_tools_pkg.put_log_message('vv_ap_responsibility :' ||vv_ap_responsibility || '           '||rec_approved.name||'              '||rec_param.varchar2_value);
				--récupération des variables nécessaires au lancement du traitement
				SELECT fr.responsibility_id,
					   fr.application_id
				INTO   vn_responsibility_id,
					   vn_application_id
				FROM   fnd_responsibility fr
				WHERE  fr.responsibility_key = vv_ap_responsibility;
				
				
				-- initialisation de l'environement OA pour correspondre a l'unité opérationnelle en cours de traitement
				fnd_global.apps_initialize (fnd_global.user_id, vn_responsibility_id, vn_application_id);
        
             -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
             fnd_request.set_org_id(rec_approved.organization_id);
				
             -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
            --fnd_global.apps_initialize (fnd_global.user_id, vn_responsibility_id, vn_application_id);
            --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
            vn_request_id    :=
                    fnd_request.submit_request (
                        'PA', --APPLICATION
                        'PAAPIMP_SI', --PROGRAM
                        NULL, --PROGRAM_NAME
                        NULL, --START_TIME
                        FALSE, --SUB_REQUEST
                        NULL, --'STANDARD', --ATT1 : Le type de facture que vous transférez.
                        NULL, --Saisissez le numéro du projet associé aux factures fournisseur à extraire.
                        NULL, --Saisissez le nom du lot que vous voulez créer pour cette interface
                        NULL, --Date GL d'imputation de facture à utiliser pour le transfert des factures fournisseur
                        NULL, --Date d'imputation de facture à utiliser pour le transfert des factures fournisseur
						'Y',
						'Y',--'N' --YWA artf2061509
						'N',

                        NULL --Debug mode
                    );

            dka_tools_pkg.put_debug_message ('Lancement du traitement '|| TO_CHAR (vn_request_id) || ' pour la société ' || rec_approved.NAME);
            vn_compteur                     := vn_compteur + 1;
            va_request_ids (vn_compteur)    := vn_request_id;


		END LOOP;


        /*********************** VERIFICATION ET ATTENTE >fin DES TRAITEMENTS  ***************************/
  ----- On part du dernier traitement lancé en pariant sur le fait que si le dernier traitement est terminé -----
  ----- il y a des chances que les précédents le soient aussi -----

    COMMIT;
    WHILE vn_compteur > 0
    LOOP

	      IF NOT (fnd_concurrent.wait_for_request(va_request_ids(vn_compteur),
	                                              15,
	                                              0,
	                                              vv_phase,
	                                              vv_status,
	                                              vv_dev_phase,
	                                              vv_dev_status,
	                                              vv_errbuf))
	      THEN
	        dka_tools_pkg.put_outdebug_message(vn_erreur||'Traitement numéro ' || TO_CHAR(va_request_ids(vn_compteur)) || ' trop long ou tombé en erreur');
	        vn_erreur := vn_erreur +1 ;
	      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL')
	      THEN
	        dka_tools_pkg.put_debug_message('Traitement numéro ' || TO_CHAR(va_request_ids(vn_compteur)) || ' correctement exécuté');
	      ELSE
	        dka_tools_pkg.put_outdebug_message(vn_erreur||'Traitement numéro ' || TO_CHAR(va_request_ids(vn_compteur)) || ' trop long ou tombé en erreur');
	        vn_erreur := vn_erreur +1;
	      END IF;  ----- >fin IF NOT -----

      	       vn_compteur := vn_compteur - 1;

   END LOOP;

  IF  vn_erreur != 0
   THEN
    pn_retcode := 1; -- toutes les imputations vers GL ne sont pas terminées correctement
   END IF;


    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := SQLERRM (SQLCODE);
            pn_retcode    := 2;
    END main;
-------------------------------------------------------------------------------------------------------------------
END dka_spaapimp_si_pkg;
/
/*<TOAD_FILE_CHUNK>*/
SHOW ERROR
EXIT;
