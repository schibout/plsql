/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE BODY DKA_SAPWFAG_PKG AS
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPWFAG_PKG.pkb
-- DESCRIPTION	     : package body pour le workflow de génération de compte AP
--
-- AUTEUR            : Evelyne SIMON
-- DATE DE CREATION  : 24/01/2002
-- DOC. ASSOCIEE     : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 12/07/04   SLE Portage spécifique pour projet PHENIX 2004
---		             Modification des procédures GET_AP_SEGMENT1_VALUE, GET_AP_SEGMENT2_VALUE,	 
---                GET_AP_SEGMENT4_VALUE, GET_AP_SEGMENT5_VALUE, GET_AP_SEGMENT6_VALUE,  
--- 07/07/16  MEG  Migration R12
--- 06/07/17  MEG  artf2191189 : EDB078 LOT1 - Alimentation code Flux pour investissement
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT1_VALUE
--  Description   : Procédure de détermination de la valeur du segment1 :
--                  Société
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
-- PHENIX 2004 Mise à jour de l’attribut 'LOOKUP_SET_VALUE' du workflow avec les 3 derniers caractères de la valeur
-- retournée par la fonction « Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f »

PROCEDURE get_ap_segment1_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
                                
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vd_expenditure_date DATE;
  vd_ap_period_date   DATE;
  vv_segment1_value   VARCHAR2(50);
  -- PHENIX 2004 
/*  vv_size_seg1 NUMBER(2);
  vv_size_seg2 NUMBER(2);
  vv_pos_seg1  NUMBER(2);
  c_pos_seg2 CONSTANT NUMBER := 1;*/
  -- fin PHENIX 2004 
  
BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT1_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */
  -- PHENIX 2004 
/*  vv_size_seg1 := dka_tools_pkg.segment_size(1);
  vv_size_seg2 := dka_tools_pkg.segment_size(2);
  vv_pos_seg1  := c_pos_seg2 + vv_size_seg2;*/
  -- fin PHENIX 2004 

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress    := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

/*
  x_progress          := 'RECUPERATION DATE DE DEPENSE';
  vd_expenditure_date := wf_engine.GetItemAttrDate(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'EXPENDITURE_ITEM_DATE');

  ----- Calcul de la date de référence : date de fin de la 1ère période ouverte AP -----
  x_progress        := 'CALCUL DATE DE REFERENCE';
  vd_ap_period_date := dka_tools_pkg.get_ap_period_date_f(vd_expenditure_date);

  IF vd_ap_period_date IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
*/

  ----- Détermination de la Société -----
  x_progress        := 'DETERMINATION DE LA SOCIETE';
  /*
  vv_segment1_value := dka_ibdsoc_tools_pkg.get_proj_acct_area_company_f(vn_project_id,
                                                                         '0',
                                                                         vd_ap_period_date,
                                                                         NULL);
  */
  vv_segment1_value := DKA_SPAAUTOACCOUNTING_PKG.societe_projet(vn_project_id);

  IF vv_segment1_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E002');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
    
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => /*substr(*/vv_segment1_value/*,
                                                 vv_pos_seg1,
                                                 vv_size_seg1)*/); -- PHENIX 2004 
    result := 'COMPLETE:SUCCESS';
    RETURN;
    
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT1_VALUE', x_progress);
    RAISE;
END get_ap_segment1_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT2_VALUE
--  Description   : Procédure de détermination de la valeur du segment2 :
--                  UO
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
-- PHENIX 2004 Procédure « get_ap_segment1_value » dupliquée en « get_ap_segment2_value »
-- et mise à jour de l’attribut 'LOOKUP_SET_VALUE' du workflow avec les 4 premiers caractères de la valeur retournée
-- par la fonction « Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f » 

PROCEDURE get_ap_segment2_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
                                
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vd_expenditure_date DATE;
  vd_ap_period_date   DATE;
  vv_segment2_value   VARCHAR2(50);
  -- PHENIX 2004 
/*  vv_size_seg2 NUMBER(2);
  c_pos_seg2 CONSTANT NUMBER := 1;*/
  -- fin PHENIX 2004 
  
BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT2_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  --vv_size_seg2 := dka_tools_pkg.segment_size(2); -- PHENIX 2004   

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress    := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

/*
  x_progress          := 'RECUPERATION DATE DE DEPENSE';
  vd_expenditure_date := wf_engine.GetItemAttrDate(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'EXPENDITURE_ITEM_DATE');

  ----- Calcul de la date de référence : date de fin de la 1ère période ouverte AP -----
  x_progress        := 'CALCUL DATE DE REFERENCE';
  vd_ap_period_date := dka_tools_pkg.get_ap_period_date_f(vd_expenditure_date);

  IF vd_ap_period_date IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
*/

  ----- Détermination de l'UO -----
  --x_progress        := 'DETERMINATION CENTRE DE GESTION';
  x_progress        := 'DETERMINATION DE L''UO';
  /*
  vv_segment2_value := dka_ibdsoc_tools_pkg.get_proj_acct_area_company_f(vn_project_id,
                                                                         '0',
                                                                         vd_ap_period_date,
                                                                         NULL);
  */
  vv_segment2_value := DKA_SPAAUTOACCOUNTING_PKG.uo_projet(vn_project_id);

  IF vv_segment2_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E002');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => /*substr(*/vv_segment2_value/*,
                                                 c_pos_seg2,
                                                 vv_size_seg2)*/); -- PHENIX 2004
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT2_VALUE', x_progress);
    RAISE;
END get_ap_segment2_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT3_VALUE
--  Description   : Procédure de détermination de la valeur du segment3 :
--                  COMPTE LOCAL
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       

PROCEDURE get_ap_segment3_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS

  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vn_task_id          NUMBER;
  vd_expenditure_date DATE;
  vd_ap_period_date   DATE;
  vv_segment3_value   VARCHAR2(50);
  vv_expenditure_type VARCHAR2(100);
/*  vv_size_seg3        NUMBER(2);
  c_pos_seg3 CONSTANT NUMBER := 1;*/

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT3_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  --vv_size_seg3 := dka_tools_pkg.segment_size(3); -- PHENIX 2004   

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress    := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

  x_progress          := 'RECUPERATION TYPE DE DEPENSE';
  vv_expenditure_type := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'EXPENDITURE_TYPE');

  x_progress := 'RECUPERATION ID TACHE';
  vn_task_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'TASK_ID');

  x_progress := 'DETERMINATION DU COMPTE LOCAL';

  vv_segment3_value := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(pn_project_id       => vn_project_id,
                                                                 pv_expenditure_type => vv_expenditure_type,
                                                                 pn_task_id          => vn_task_id);

  IF vv_segment3_value IS NULL THEN
  
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E003');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
  
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => /*substr(*/vv_segment3_value/*,
                                                 c_pos_seg3,
                                                 vv_size_seg3)*/);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT3_VALUE', x_progress);
    RAISE;
END get_ap_segment3_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT4_VALUE
--  Description   : Procédure de détermination de la valeur du segment4 :
--                  Compte analytique
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
-- PHENIX 2004 Cette procédure est l’ancienne « get_ap_segment2_value »
-- vv_segment2_value renommé en vv_segment4_value

PROCEDURE get_ap_segment4_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2)
IS

	x_progress			            VARCHAR2(100);
	vn_project_id			          NUMBER;
	vd_expenditure_date		      DATE;
	vv_expenditure_type		      VARCHAR2(30);
	vd_ap_period_date		        DATE;
	vn_back_billing_project_id	NUMBER;
	vv_segment4_value		        VARCHAR2(50);
  vn_task_id                  NUMBER;
  
BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT4_VALUE : DEBUT'; 
  /* DEBUG */  /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */


  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run)
  THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PROJECT_ID');
/*
  x_progress := 'RECUPERATION DATE DE DEPENSE';
  vd_expenditure_date := wf_engine.GetItemAttrDate( itemtype => itemtype,
                                                    itemkey  => itemkey,
                                                    aname    => 'EXPENDITURE_ITEM_DATE');

  ----- Calcul de la date de référence : date de fin de la 1ère période ouverte AP -----
  x_progress := 'CALCUL DATE DE LA PERIODE AP';
  vd_ap_period_date := dka_tools_pkg.get_ap_period_date_f(vd_expenditure_date);

  IF vd_ap_period_date IS NULL
  THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
*/

  x_progress := 'RECUPERATION TYPE DE DEPENSE';
  vv_expenditure_type := wf_engine.GetItemAttrText( itemtype => itemtype,
                                                    itemkey  => itemkey,
                                                    aname    => 'EXPENDITURE_TYPE');
  

  x_progress := 'RECUPERATION ID TACHE';
  vn_task_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'TASK_ID');

  
  x_progress := 'RECUPERATION ID DU PROJET A REFACTURER';
  ----- Il se trouve dans l'attribute1 de la ligne de distribution
  ----- Attention, le workflow de génération des comptes employés et celui des factures AP n'ont pas le même
  ----- nom d'attribut item pour désigner le même champ -----
  IF itemtype = 'PAAPINVW'
  THEN
    vn_back_billing_project_id := TO_NUMBER(wf_engine.GetItemAttrText( itemtype => itemtype,
                                                                       itemkey  => itemkey,
                                                                       aname    => 'DIST_ATTRIBUTE1'));
  ELSIF itemtype = 'PAAPWEBX'
  THEN
    vn_back_billing_project_id := TO_NUMBER(wf_engine.GetItemAttrText( itemtype => itemtype,
                                                                       itemkey  => itemkey,
                                                                       aname    => 'LINE_ATTRIBUTE1'));
  ELSE
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E004');
    fnd_message.set_token('ITEM_TYPE', itemtype);
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;

  ----- Détermination du compte analytique en appelant une sous procédure de la règle d'autoaccounting PA
  ----- 'CPT_GROUP_COUTS' -----
  x_progress := 'DETERMINATION DU COMPTE ANALYTIQUE';
  vv_segment4_value := dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f(pn_project_id          => vn_project_id,
                                                                        pv_expenditure_type    => vv_expenditure_type,
                                                                        pn_expenditure_item_id => NULL,
                                                                        pn_task_id             => vn_task_id,
                                                                        pn_refac_project_id    => vn_back_billing_project_id);

  IF vv_segment4_value IS NULL
  THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E004');
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'LOOKUP_SET_VALUE',
                               avalue	=> vv_segment4_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;
 
EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG','GET_SEGMENT4_VALUE',x_progress); -- PHENIX 2004
    RAISE;
END get_ap_segment4_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT5_VALUE
--  Description   : Procédure de détermination de la valeur du segment5
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
-- PHENIX 2004 Cette procédure est l’ancienne « get_ap_segment4_value »
-- « vv_segment4_value » renommé en « vv_segment5_value »

PROCEDURE get_ap_segment5_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress          VARCHAR2(100);
  --vv_supplier_type  VARCHAR2(25);
  --vn_supplier_id    NUMBER;
  vv_segment5_value   VARCHAR2(50);
  vn_project_id			  NUMBER;
  vv_attribute2       VARCHAR2(250);

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT5_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
/*
  x_progress     := 'RECUPERATION ID DU FOURNISSEUR';
  vn_supplier_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'VENDOR_ID');

  x_progress       := 'RECUPERATION TYPE DU FOURNISSEUR';
  vv_supplier_type := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'VENDOR_TYPE');
*/

  x_progress       := 'RECUPERATION DE L''ATTRIBUTE2 (VENDOR_SITE_ID)';
  vv_attribute2 := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'ATTRIBUTE2');
  
  x_progress := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PROJECT_ID');
                                                
  --x_progress        := 'DETERMINATION DU CODE PARTENAIRE';
  x_progress        := 'DETERMINATION DU CODE INTERCO';
  /*vv_segment5_value := dka_spaautoaccounting_pkg.get_code_partenaire_f(vv_supplier_type,
                                                                       vn_supplier_id);*/
                                                                       
  vv_segment5_value := dka_spaautoaccounting_pkg.code_interco(pn_project_id => vn_project_id,
                                                              pn_id_site_fourn => to_number(vv_attribute2));
  
  IF vv_segment5_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E005');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment5_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT5_VALUE', x_progress);
    RAISE;
END get_ap_segment5_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT6_VALUE
--  Description   : Procédure de détermination de la valeur du segment6
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
-- PHENIX 2004 Cette procédure est l’ancienne « get_ap_segment5_value »
-- « vv_segment5_value » renommé en « vv_segment6_value »

PROCEDURE get_ap_segment6_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vd_expenditure_date DATE;
  vd_ap_period_date   DATE;
  vv_segment6_value   VARCHAR2(50);
BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT6_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress    := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

/*
  x_progress          := 'RECUPERATION DATE DE DEPENSE';
  vd_expenditure_date := wf_engine.GetItemAttrDate(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'EXPENDITURE_ITEM_DATE');

  ----- Calcul de la date de référence : date de fin de la 1ère période ouverte AP -----
  x_progress        := 'CALCUL DATE DE LA PERIODE AP';
  vd_ap_period_date := dka_tools_pkg.get_ap_period_date_f(vd_expenditure_date);

  IF vd_ap_period_date IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
*/

  ----- Détermination du centre de coûts -----
  --x_progress        := 'DETERMINATION DU CENTRE DE COUTS';
  x_progress        := 'DETERMINATION DU CENTRE FI';
  
  /*vv_segment6_value := dka_spaautoaccounting_pkg.get_cost_center_f(vn_project_id,
                                                                   vd_ap_period_date);*/
                                                                   
  vv_segment6_value := dka_spaautoaccounting_pkg.centrefi(pn_project_id => vn_project_id);

  IF vv_segment6_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E006');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment6_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT6_VALUE', x_progress);
    RAISE;
END get_ap_segment6_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT7_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
-- PHENIX 2004 Cette procédure est l’ancienne « get_ap_segment6_value »
-- « vv_segment6_value » renommé en « vv_segment7_value »

PROCEDURE get_ap_segment7_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress        VARCHAR2(100);
  vv_segment7_value VARCHAR2(50);
  vn_project_id     NUMBER;

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT7_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress    := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

  ----- Détermination du code D en appelant la règle d'autoaccounting PA 'CODE_D'-----
  --x_progress        := 'DETERMINATION DU CODE D';
  x_progress        := 'DETERMINATION DE L''AFFAIRE';
  
  --vv_segment7_value := dka_spaautoaccounting_pkg.code_d(vn_project_id);
  vv_segment7_value := dka_spaautoaccounting_pkg.affaire(pn_project_id => vn_project_id);

  IF vv_segment7_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E007');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment7_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT7_VALUE', x_progress);
    RAISE;
END get_ap_segment7_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT8_VALUE
--  Description   : Procédure de détermination de la valeur du segment8
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       

PROCEDURE get_ap_segment8_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress        VARCHAR2(100);
  vv_segment8_value VARCHAR2(50);
  vn_project_id     NUMBER;

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT8_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress    := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

  ----- Détermination du code D en appelant la règle d'autoaccounting PA 'CODE_D'-----
  --x_progress        := 'DETERMINATION DU CODE D';
  x_progress        := 'DETERMINATION DU PROJET FI';
  
  --vv_segment7_value := dka_spaautoaccounting_pkg.code_d(vn_project_id);
  vv_segment8_value := dka_spaautoaccounting_pkg.projetfi(pn_project_id => vn_project_id);

  IF vv_segment8_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E008');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment8_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT8_VALUE', x_progress);
    RAISE;
END get_ap_segment8_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT9_VALUE
--  Description   : Procédure de détermination de la valeur du segment9
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       

PROCEDURE get_ap_segment9_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress        VARCHAR2(100);
  vv_segment9_value VARCHAR2(50);
  vn_project_id     NUMBER;

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT9_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  x_progress    := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

  x_progress    := 'DETERMINATION DU CODE FLUX';
  
  vv_segment9_value := dka_spaautoaccounting_pkg.flux(pn_project_id => vn_project_id);                                       
    
  IF vv_segment9_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E009');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment9_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT9_VALUE', x_progress);
    RAISE;
END get_ap_segment9_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT10_VALUE
--  Description   : Procédure de détermination de la valeur du segment10
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       

PROCEDURE get_ap_segment10_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress        VARCHAR2(100);
  vv_segment10_value VARCHAR2(50);
  vn_project_id     NUMBER;

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT10_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  vv_segment10_value := '0';

  IF vv_segment10_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E010');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment10_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT10_VALUE', x_progress);
    RAISE;
END get_ap_segment10_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT11_VALUE
--  Description   : Procédure de détermination de la valeur du segment11
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       

PROCEDURE get_ap_segment11_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress        VARCHAR2(100);
  vv_segment11_value VARCHAR2(50);
  vn_project_id     NUMBER;

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT11_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  vv_segment11_value := '0';

  IF vv_segment11_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E011');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment11_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT11_VALUE', x_progress);
    RAISE;
END get_ap_segment11_value;

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT12_VALUE
--  Description   : Procédure de détermination de la valeur du segment12
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       

PROCEDURE get_ap_segment12_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2) IS
  x_progress        VARCHAR2(100);
  vv_segment12_value VARCHAR2(50);
  vn_project_id     NUMBER;

BEGIN

  x_progress := 'DKA_SAPWFAG_PKG.GET_AP_SEGMENT12_VALUE : DEBUT';
  /* DEBUG */ /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  vv_segment12_value := '0';

  IF vv_segment12_value IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E012');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  ELSE
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment12_value);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SAPWFAG_PKG', 'GET_AP_SEGMENT12_VALUE', x_progress);
    RAISE;
END get_ap_segment12_value;

END DKA_SAPWFAG_PKG; -- Package body
/
/*<TOAD_FILE_CHUNK>*/


SHOW ERRORS;

EXIT
