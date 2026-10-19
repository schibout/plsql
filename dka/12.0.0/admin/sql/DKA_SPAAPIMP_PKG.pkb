CREATE OR REPLACE PACKAGE BODY DKA_SPAAPIMP_PKG
AS

---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI 
-- PROJET            : HELIOS
-- NOM           	 : DKA_SPAAPIMP_PKG.pkb
-- DESCRIPTION       : Approbation toutes sociétés des factures fournisseurs
---
--- AUTEUR       : Guillaume Chabrier
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
-------------- --- --------------------------------------------------------------------------------------------
--  26/08/2002 GLN Modification de l'application PA au lieu de SQLAP lors du lancement du submit_request
--  10/09/2003 XD  Modification du curseur de sélection
--  08/06/2005 EB  Modification du curseur de sélection
--  30/10/2007 ADR ETANCHEITE DALKIA 2007
--  30/05/2016 BDE HELIOS Modification de la responsabilité avant de lancer le traitement pour chaque UO
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
        pv_period_name         VARCHAR2(25);
        vv_parameter           dka_parameters.parameter_name%TYPE;
  --AND   hou.attribute3 = 'Y';

        
        CURSOR cur_approved
        IS                                                   
           SELECT hou.organization_id,
                  hou.NAME
           /* ETANCHEITE DALKIA 2007 */       
           FROM   ap_invoices_all ai,
                  ap_invoice_distributions_all aid,
                  hr_all_organization_units hou,
                  gl_period_statuses gps
           WHERE  invoice_type_lookup_code = 'EXPENSE REPORT'
           AND    ai.org_id = hou.organization_id
           AND    aid.invoice_id = ai.invoice_id
           --AND    gps.set_of_books_id = gn_sob
           AND    gps.application_id = 200
           AND    gps.closing_status = 'O'
           AND    aid.accounting_date between gps.start_date AND gps.end_date
		   AND 	  gps.set_of_books_id=ai.set_of_books_id
           --AND    gps.period_name = pv_period_name
           AND    aid.line_type_lookup_code = 'ITEM'
           AND    aid.project_id IS NOT NULL
           AND    aid.pa_addition_flag NOT IN ('E', 'T', 'Y', 'Z')
           GROUP BY hou.organization_id,
                    hou.name;
                                                   
    BEGIN
        
      
        vv_parameter := 'AP_RESPONSIBILITY_KEY';
        --récupération des parametres utilisés par le traitement
        dka_tools_pkg.get_parameter ('SPAAPIMP',vv_parameter, rec_param, pn_retcode, pv_errbuf);

        IF pn_retcode != 0
        THEN
            pn_retcode    := 1;
            RETURN;
        END IF;

       
        
        /* SELECT period_name 
        INTO   pv_period_name
        FROM   gl_period_statuses
        WHERE  application_id = 200
        AND    closing_status = 'O'
        ETANCHEITE DALKIA 2007 
        AND    set_of_books_id = gn_sob;*/
        --fnd_profile.value('GL_SET_OF_BKS_ID');
        
        FOR rec_approved IN cur_approved()
        LOOP
		
		
			-- Formation du nom de la responsabilité 
             -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
			 --vv_ap_responsibility    := rec_approved.name||'_'||rec_param.varchar2_value;
			 vv_ap_responsibility    := 'TOUT_'||rec_param.varchar2_value;
			 
            --récupération des variables nécessaires au lancement du traitement
            SELECT fr.responsibility_id,
                   fr.application_id
            INTO   vn_responsibility_id,
                   vn_application_id
            FROM   fnd_responsibility fr
            WHERE  fr.responsibility_key = vv_ap_responsibility;

            -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
            fnd_global.apps_initialize (fnd_global.user_id, vn_responsibility_id, vn_application_id);

            -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
            fnd_request.set_org_id(rec_approved.organization_id);

            --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
            vn_request_id    :=
                    fnd_request.submit_request (
                        'PA', --APPLICATION
                        'PAAPIMP', --PROGRAM
                        NULL, --PROGRAM_NAME
                        NULL, --START_TIME
                        FALSE, --SUB_REQUEST
                        'EXPENSE REPORT', --ATT 1 : Le type de facture que vous transférez.
                        NULL, --Saisissez le numéro du projet associé aux notes de frais à extraire.
                        NULL, --Saisissez le nom du lot que vous voulez créer pour cette interface
                        NULL, --Date GL d'imputation de facture à utiliser pour le transfert des dépenses
                        NULL, --Date d'imputation de facture à utiliser pour le transfert des dépenses
                        NULL --Debug Mode
                    );

            IF vn_request_id IS NULL
            THEN
                pn_retcode    := 1;
                pv_errbuf     := 'Le traitement n''a pas pu être lancé pour la société  ' || rec_approved.NAME;
            ELSE
                pn_retcode    := 0;
                pv_errbuf     :=
                             'Traitement : ' || TO_CHAR (vn_request_id) || ' lancé sur la société ' || rec_approved.NAME;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := SQLERRM (SQLCODE);
            pn_retcode    := 2;
    END main;
-------------------------------------------------------------------------------------------------------------------
END DKA_SPAAPIMP_PKG;
/
SHOW ERROR
EXIT;
