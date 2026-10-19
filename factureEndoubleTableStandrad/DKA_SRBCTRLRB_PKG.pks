/*<TOAD_FILE_CHUNK>*/
/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE BODY DKA_SAPCREATE_BLOCAGES_ALL_PKG AS
  --------------------------------------------------------------------------------------------------------------- 
  -- CAPGEMINI 
  -- PROJET            : DALKIA Oracle Applications HELIOS
  -- NOM         : DKA_SAPCREATE_BLOCAGES_ALL_PKG.pks
  -- DESCRIPTION       : DKA_SAPCREATE_BLOCAGES_ALL_PKG package spec : 
  ---
  --- AUTEUR       : Bastien DELATTRE
  --- DATE DE CREATION : 31/05/2016
  --- DOC. ASSOCIEE    : 
  --  COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  --------------------------------------------------------------------------------------------------------------- 
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --  24/11/2016 NBO SPE001 - defect 388 Prise en compte des données AP du jour en erreur
  ---
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
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER)
  
   IS
    vn_responsibility_id NUMBER;
    vn_application_id    NUMBER;
    vv_ap_responsibility VARCHAR2(100);
    rec_param            dka_parameters%ROWTYPE;
    vn_request_id        NUMBER;
    vn_approval_org_id   NUMBER;
    vv_phase             VARCHAR2(100);
    vv_status            VARCHAR2(100);
    vv_dev_phase         VARCHAR2(100);
    vv_dev_status        VARCHAR2(100);
    va_request_ids       pa_utils.IdTabTyp; ---Tableau
    vn_requests_cnt      NUMBER;
    vv_errbuf            VARCHAR2(150);
    /* ETANCHEITE DALKIA 2007 */
    vv_parameter dka_parameters.parameter_name%TYPE;
  
    --curseur sur le regroupement de factures avec status d'approbation NULL (jamais approuvé)
    CURSOR cur_approval IS
      SELECT DISTINCT aia.org_id, hou.NAME
      /* ETANCHEITE DALKIA 2007 */
        FROM ap_invoices_all aia, hr_all_organization_units hou
       WHERE aia.org_id = hou.organization_id;
    --AND   hou.attribute3 = 'Y';
  
  BEGIN
    pn_retcode := 0;
    pv_errbuf  := NULL;
  
    vv_parameter := 'AP_RESPONSIBILITY_KEY';
    --récupération des parametres utilisés par le traitement
    dka_tools_pkg.get_parameter('SAPCREATE_BLOCAGES',
                                vv_parameter,
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      RETURN;
    END IF;
  
    vn_requests_cnt := 0;
  
    FOR rec_approval IN cur_approval LOOP
      vn_approval_org_id   := rec_approval.org_id;
      -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
      --vv_ap_responsibility := rec_approval.name || '_' ||
      --                        rec_param.varchar2_value;
      vv_ap_responsibility :='TOUT_' ||
                              rec_param.varchar2_value;
    
      -- PHENIX 2004 
      --récupération des variables nécessaires au lancement du traitement
      SELECT fr.responsibility_id, fr.application_id
        INTO vn_responsibility_id, vn_application_id
        FROM fnd_responsibility fr
       WHERE fr.responsibility_key = vv_ap_responsibility;
    
      -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
      fnd_global.apps_initialize(fnd_global.user_id,
                                 vn_responsibility_id,
                                 vn_application_id);
      
      -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
      fnd_request.set_org_id(rec_approval.org_id);
       
      --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
      vn_request_id := fnd_request.submit_request('DKA', --APPLICATION
                                                  'DKA_SAPCREATE_BLOCAGES', --PROGRAM
                                                  NULL, --PROGRAM_NAME
                                                  NULL, --START_TIME
                                                  FALSE --SUB_REQUEST
                                                  );
    
      IF vn_request_id IS NULL THEN
        pn_retcode := 1;
        pv_errbuf  := 'Le traitement d''approbation n''a pas pu être lancé pour la société  ' ||
                      rec_approval.name;
      ELSE
        pn_retcode := 0;
        pv_errbuf  := 'Traitement d''approbation : ' ||
                      TO_CHAR(vn_request_id) || ' lancé sur la société ' ||
                      rec_approval.name;
        dka_tools_pkg.put_debug_message(pv_errbuf);
      
        vn_requests_cnt := vn_requests_cnt + 1;
        va_request_ids(vn_requests_cnt) := vn_request_id;
      
      END IF;
    
      COMMIT;
    
    END LOOP;
  
    WHILE vn_requests_cnt > 0 LOOP
      IF NOT (fnd_concurrent.wait_for_request(va_request_ids(vn_requests_cnt),
                                              15,
                                              0,
                                              vv_phase,
                                              vv_status,
                                              vv_dev_phase,
                                              vv_dev_status,
                                              vv_errbuf)) THEN
        dka_tools_pkg.put_outdebug_message('Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                           ' trop long ou tombé en erreur');
        pv_errbuf := 'Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                           ' trop long ou tombé en erreur';
        pn_retcode := 1;
      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
        dka_tools_pkg.put_debug_message('Traitement numéro ' ||
                                        TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                        ' correctement exécuté');
      END IF;
    
      vn_requests_cnt := vn_requests_cnt - 1;
    
    END LOOP;
  
    IF pn_retcode = 0 THEN
      UPDATE hr_all_organization_units hou
         SET hou.attribute3 = 'N'
       WHERE hou.organization_id = vn_approval_org_id;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 2;
    
  END main;
  --------------------------------------------------------------------------------------------------------------
END DKA_SAPCREATE_BLOCAGES_ALL_PKG;


/
/*<TOAD_FILE_CHUNK>*/
SHOW ERROR
EXIT;
