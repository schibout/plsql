CREATE OR REPLACE PACKAGE BODY DKA_SPOWFAG_PKG AS
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOWFAG_PKG.pkb
-- DESCRIPTION	     : package body pour les workflows de génération de comptes PO
--
-- AUTEUR            : Evelyne SIMON
-- DATE DE CREATION  : 11/02/2002
-- DOC. ASSOCIEE     : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  19/02/2002 KH   MODIF TEMPORAIRE JUSTE POUR COMPILER !!!
--                  On a remplacé l'appel à DKA_TOOLS_PKG.get_po_eca_period_date_f 
--                  par DKA_TOOLS_PKG.get_po_period_date_f => OK ! (ES)
--  25/02/2002 ES   - Modification de la valeur retournée de IS_PO_PROJECT_RELATED : il faut
--                  impérativement sortir "COMPLETE:T" et non pas "COMPLETE:TRUE" qui génère
--                  un VARCHAR et non pas un booléen comme prévu dans le LOOKUP_TYPE du workflow
--                  - Ajout vérification existence du projet et du fournisseur
--  11/06/2002 ES   - Modification du segment4 : Quand l'Id du fourniseur pour l'AG DA
--                    est NULL la valeur du segement est '0'.
--                  - Ajout des messages de debugage dans la procédure de calcul du segment4
--                    qui renseigne la table po_wf_debug si l'option de profil 'PO_SET_DEBUG_WORKFLOW_ON'
--                    est à 'Y'
--  13/07/2004 STI  - Portage spécifique pour projet PHENIX 2004
--						- segment1 :Mise à jour de 'LOOK_UP_SET_VALUE' par les 3 derniers caracteres
--						de la chaine renvoyee par Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f
--						- segment2 : Mise à jour de 'LOOK_UP_SET_VALUE' par les 4 premiers caracteres du segment (idem segment1)
--						- segment4 : GET_PO_ECA_SEGMENT2_VALUE devient GET_PO_ECA_SEGMENT4_VALUE
--						- segment5 : GET_PO_ECA_SEGMENT4_VALUE devient GET_PO_ECA_SEGMENT5_VALUE
--						- segment6 : GET_PO_ECA_SEGMENT5_VALUE devient GET_PO_ECA_SEGMENT6_VALUE
--						- segment7 : GET_PO_ECA_SEGMENT6_VALUE devient GET_PO_ECA_SEGMENT7_VALUE
--  22/08/2016 MEG  Migration R12
--  09/11/2016 MEG  Correction artf2041528 (Messages)
--  14/11/2016 MEG  Correction artf2039720
--  28/12/2016 MEG  Correction artf2072001 (Org_id)
--  06/07/2017 MEG  artf2191189 : EDB078 LOT1 - Alimentation code Flux pour investissement
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


--> OBE

-------------------------------------------------------------------------------------
--  Nom           : get_po_cp_segment3_value
--  Description   : Procédure de détermination de la valeur du segment3 du compte provision
--                  SOCIETE
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
PROCEDURE get_po_cp_segment3_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS

  x_progress        VARCHAR2(100);
  vv_supplier_type  VARCHAR2(25);
  vv_segment3_value VARCHAR2(50);

BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT1_VALUE : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;
  
  
  x_progress := 'RECUPERATION TYPE DU FOURNISSEUR';
  
  vv_supplier_type := wf_engine.GetItemAttrText( itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'VENDOR_TYPE');
  
  x_progress := 'TYPE DU FOURNISSEUR (vv_supplier_type) : ' || vv_supplier_type;
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);


  IF vv_supplier_type in ('PARTENAIRE','EXTERNAL  PARTNER') THEN
	vv_segment3_value := '408450';
  ELSE
    vv_segment3_value := '408400';
  END IF;  

 

  x_progress := 'COMPTE LOCAL (vv_segment3_value) : ' || vv_segment3_value;
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  IF vv_segment3_value IS NULL THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001_2');
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
                              avalue   => vv_segment3_value);
  
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_CP_SEGMENT3_VALUE : ' ||
                  vv_segment3_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
    result := 'COMPLETE:SUCCESS';
    RETURN;
  
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT1_VALUE',
                    x_progress);
    RAISE;
END get_po_cp_segment3_value;




-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT5_VALUE
--  Description   : Procédure de détermination de la valeur du segment5
--                  INTERCO
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
PROCEDURE get_po_cp_segment5_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2)
IS
	x_progress			    VARCHAR2(100);
	vv_supplier_type		VARCHAR2(25);
	vn_supplier_id			NUMBER;
	vv_segment5_value		VARCHAR2(50); -- PHENIX 2004
  vn_project_id       NUMBER;
  vn_vendor_site_id   NUMBER;
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT5_VALUE : DEBUT'; -- PHENIX 2004
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----


  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID SITE FOURNISSEUR';

  vn_vendor_site_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'VENDOR_SITE_ID');

  /*
  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU FOURNISSEUR';
  
  ----- L'id du fournisseur n'est pas dans le même attribut pour le workflow des demandes d'achat
  ----- et celui des commandes -----
  IF itemtype = 'POWFRQAG'
  THEN
    vn_supplier_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'SUGGESTED_VENDOR_ID');
  ELSIF itemtype = 'POWFPOAG'
  THEN
    vn_supplier_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'VENDOR_ID');
  ELSE
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E009');
    fnd_message.set_token('ITEM_TYPE', itemtype);
    wf_engine.SetItemAttrText( itemtype => itemtype,
                               itemkey  => itemkey,
                               aname  => 'ERROR_MESSAGE',
                               avalue => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  
  x_progress := 'ID DU FOURNISSEUR (vn_supplier_id) : ' ||TO_CHAR(vn_supplier_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  
  IF vn_supplier_id IS NULL and itemtype = 'POWFPOAG'
  THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E008');
    wf_engine.SetItemAttrText( itemtype => itemtype,
                               itemkey  => itemkey,
                               aname  => 'ERROR_MESSAGE',
                               avalue => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  
  ----- Modification ES 11/06/2002 : si l'Id du fournisseur est null alors pour 
  --    l'Account Generator de la demande d'achat le segment 5 prend la valeur '0' -----
  IF vn_supplier_id IS NULL and itemtype = 'POWFRQAG'
  THEN
    wf_engine.SetItemAttrText( itemtype => itemtype,
                               itemkey  => itemkey,
                               aname  => 'LOOKUP_SET_VALUE',
                               avalue => '0');
    x_progress := 'powfrqag null';
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;
  
  ----- ************************************************** -----
  x_progress := 'RECUPERATION TYPE DU FOURNISSEUR';
  
  vv_supplier_type := wf_engine.GetItemAttrText( itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'VENDOR_TYPE');
  
  x_progress := 'TYPE DU FOURNISSEUR (vv_supplier_type) : ' || vv_supplier_type;
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  */

  ----- ************************************************** -----
  /*x_progress := 'DETERMINATION DU CODE PARTENAIRE';
  
  vv_segment5_value := dka_spaautoaccounting_pkg.get_code_partenaire_f(vv_supplier_type,
                                                                       vn_supplier_id); -- PHENIX 2004
  */

  x_progress := 'DETERMINATION DU CODE INTERCO';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  IF vn_vendor_site_id IS NULL THEN
  
    x_progress := 'PAS DE FOURNISSEUR, INTERCO=0';
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
    vv_segment5_value := 0;
  
  ELSE
  
    vv_segment5_value := dka_spaautoaccounting_pkg.get_interco_fourn_f(pn_vendor_site_id => vn_vendor_site_id);
  
    x_progress := 'CODE PARTENAIRE (vv_segment5_value) : ' || vv_segment5_value; -- PHENIX 2004
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
  END IF;

  IF vv_segment5_value IS NULL -- PHENIX 2004
   THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E005_1');
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
                              avalue   => vv_segment5_value); -- PHENIX 2004
  
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT5_VALUE : ' ||
                  vv_segment5_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
    result := 'COMPLETE:SUCCESS';
    RETURN;
  
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT5_VALUE',
                    x_progress); -- PHENIX 2004
    RAISE;
END get_po_cp_segment5_value;

--> OBE

-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT1_VALUE
--  Description   : Procédure de détermination de la valeur du segment1 du compte Expense Charge Account:
--                  SOCIETE
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
PROCEDURE get_po_eca_segment1_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS

  x_progress VARCHAR2(100);
  --vn_project_id       NUMBER;
  --vn_dest_org_id NUMBER;
  vn_org_id NUMBER;
  --vd_expenditure_date DATE;
  --vd_po_period_date   DATE;
  vv_segment1_value VARCHAR2(50);

BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT1_VALUE : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  ----- ************************************************** -----
  /*
  x_progress := 'RECUPERATION ID DU PROJET';
  
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');
  
  x_progress := 'ID DU PROJET (vn_project_id) : ' || TO_CHAR(vn_project_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
  IF vn_project_id IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  */

  /*
  x_progress := 'RECUPERATION DE L''ORG_ID_DEST';
  
  vn_dest_org_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'DESTINATION_ORGANIZATION_ID');

  x_progress := 'DEST_ORG_ID : ' || TO_CHAR(vn_dest_org_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  IF vn_dest_org_id IS NULL THEN
  */
  
  x_progress := 'RECUPERATION DE L''ORG_ID COURANT';
  
  vn_org_id := fnd_profile.value('ORG_ID');
    
  IF vn_org_id IS NULL THEN --artf2072001

    IF itemtype = 'POWFPOAG' THEN --WF des cmds stds

      vn_org_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PURCHASING_OU_ID');

    END IF;
    
  END IF;
  
  x_progress := 'ORG_ID : ' || TO_CHAR(vn_org_id);
  
  IF vn_org_id IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001_1');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;

  ----- ************************************************** -----
  /*
  x_progress := 'RECUPERATION DATE DE DEPENSE';
  
  vd_expenditure_date := wf_engine.GetItemAttrDate(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'EXPENDITURE_ITEM_DATE');
  
  x_progress := 'DATE DE DEPENSE (vd_expenditure_date) : ' ||
                TO_CHAR(vd_expenditure_date);
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
  ----- ************************************************** -----
  x_progress := 'CALCUL DATE DE REFERENCE';
  
  ----- La date de référence : date de fin de la 1ère période ouverte PO -----
  vd_po_period_date := dka_tools_pkg.get_po_period_date_f(vd_expenditure_date);
  
  x_progress := 'DATE DE REFERENCE (vd_po_period_date) : ' ||
                TO_CHAR(vd_po_period_date);
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
  IF vd_po_period_date IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  */

  ----- ************************************************** -----
  --x_progress := 'DETERMINATION CENTRE DE GESTION/SOCIETE';
  x_progress := 'DETERMINATION SOCIETE';

  SELECT substr(hou.name, -4)
    INTO vv_segment1_value
    FROM hr_all_organization_units hou
 --WHERE hou.organization_id = vn_dest_org_id;
   WHERE hou.organization_id = vn_org_id;

  /*
  vv_segment1_value := dka_ibdsoc_tools_pkg.get_proj_acct_area_company_f(vn_project_id,
                                                                         '0',
                                                                         vd_po_period_date,
                                                                         NULL);

  vv_segment1_value := DKA_SPAAUTOACCOUNTING_PKG.societe_projet(vn_project_id);
  */
  
  x_progress := 'SOCIETE (vv_segment1_value) : ' || vv_segment1_value;
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  IF vv_segment1_value IS NULL THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001_2');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
  
    result := 'COMPLETE:FAILURE';
    RETURN;
  
  ELSE
    /*
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => SUBSTR(vv_segment1_value,
                                                 dka_tools_pkg.segment_size(2) + 1,
                                                 dka_tools_pkg.segment_size(1))); -- PHENIX 2004   
    */
  
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'LOOKUP_SET_VALUE',
                              avalue   => vv_segment1_value);
  
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT1_VALUE : ' ||
                  vv_segment1_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
    result := 'COMPLETE:SUCCESS';
    RETURN;
  
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT1_VALUE',
                    x_progress);
    RAISE;
END get_po_eca_segment1_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT2_VALUE
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
PROCEDURE get_po_eca_segment2_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2)
IS

	x_progress			VARCHAR2(100);
	--vn_project_id			NUMBER;
  --vn_dest_org_id NUMBER;
  vn_org_id NUMBER;
	--vd_expenditure_date		DATE;
	--vd_po_period_date		DATE;
	vv_segment2_value		VARCHAR2(50);--PHENIX 2004
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT2_VALUE : DEBUT'; -- PHENIX 2004
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);


  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run)
  THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  ----- ************************************************** -----
  /*
  x_progress := 'RECUPERATION ID DU PROJET';

  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PROJECT_ID');
                                                
  x_progress := 'ID DU PROJET (vn_project_id) : ' || TO_CHAR(vn_project_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vn_project_id IS NULL THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E002');
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
    
  END IF;
  */
  
  /*
  x_progress := 'RECUPERATION DE L''ORG_ID_DEST';
  
  vn_dest_org_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'DESTINATION_ORGANIZATION_ID');

  x_progress := 'DEST_ORG_ID : ' || TO_CHAR(vn_dest_org_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  IF vn_dest_org_id IS NULL THEN
  */
  
  x_progress := 'RECUPERATION DE L''ORG_ID COURANT';
  
  vn_org_id := fnd_profile.value('ORG_ID');
    
  IF vn_org_id IS NULL THEN --artf2072001

    IF itemtype = 'POWFPOAG' THEN --WF des cmds stds

      vn_org_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PURCHASING_OU_ID');
      
    END IF;
    
  END IF;
  
  x_progress := 'ORG_ID : ' || TO_CHAR(vn_org_id);
  
  IF vn_org_id IS NULL THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E002_1');
    wf_engine.SetItemAttrText(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ERROR_MESSAGE',
                              avalue   => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;

  ----- ************************************************** -----
  /*
  x_progress := 'RECUPERATION DATE DE DEPENSE';

  vd_expenditure_date := wf_engine.GetItemAttrDate( itemtype => itemtype,
                                                    itemkey  => itemkey,
                                                    aname    => 'EXPENDITURE_ITEM_DATE');

  x_progress := 'DATE DE DEPENSE (vd_expenditure_date) : ' || TO_CHAR(vd_expenditure_date);
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  ----- ************************************************** -----
  x_progress := 'CALCUL DATE DE REFERENCE';

  ----- La date de référence : date de fin de la 1ère période ouverte PO -----
  vd_po_period_date := dka_tools_pkg.get_po_period_date_f(vd_expenditure_date);

  x_progress := 'DATE DE REFERENCE (vd_po_period_date) : ' || TO_CHAR(vd_po_period_date);
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vd_po_period_date IS NULL
  THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  */
  
  ----- ************************************************** -----
  --x_progress := 'DETERMINATION CENTRE DE GESTION/SOCIETE';
  x_progress := 'DETERMINATION UO';
  /*
  vv_segment2_value := dka_ibdsoc_tools_pkg.get_proj_acct_area_company_f(vn_project_id,
                                                                         '0',
                                                                         vd_po_period_date,
                                                                         NULL); --PHENIX 2004
  
  vv_segment2_value := DKA_SPAAUTOACCOUNTING_PKG.uo_projet(vn_project_id);
  */
  
  SELECT substr(hou.name, 1, 3)
    INTO vv_segment2_value
    FROM hr_all_organization_units hou
 --WHERE hou.organization_id = vn_dest_org_id;
   WHERE hou.organization_id = vn_org_id;

  x_progress := 'UO (vv_segment2_value) : ' || vv_segment2_value;
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vv_segment2_value IS NULL    --PHENIX 2004
  THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E002_2');
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
    
  ELSE
    /*
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'LOOKUP_SET_VALUE',
                               avalue	=> SUBSTR(vv_segment2_value, 1, dka_tools_pkg.segment_size (2))); -- PHENIX 2004   
    */
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'LOOKUP_SET_VALUE',
                               avalue	=> vv_segment2_value); -- PHENIX 2004  
                               
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT2_VALUE : '||vv_segment2_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
                                                                         
    result := 'COMPLETE:SUCCESS';
    RETURN;
    
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG','GET_PO_ECA_SEGMENT2_VALUE',x_progress); -- PHENIX 2004
    RAISE;
END get_po_eca_segment2_value; -- PHENIX 2004


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT3_VALUE
--  Description   : Procédure de détermination de la valeur du segment3 du compte Expense Charge Account:
--                  COMPTE_LOCAL
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
PROCEDURE get_po_eca_segment3_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS
                                    
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vn_task_id          NUMBER;
  vd_expenditure_date DATE;
  vd_po_period_date   DATE;
  vv_segment3_value   VARCHAR2(50);
  vv_expenditure_type VARCHAR2(100);
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT3_VALUE : DEBUT'; -- PHENIX 2004
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run)
  THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----
  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU PROJET';
  
  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PROJECT_ID');
                                                
  x_progress := 'ID DU PROJET (vn_project_id) : ' || TO_CHAR(vn_project_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vn_project_id IS NULL THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E003_1');
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
    
  END IF;
  
  --------------------------------------------------------------------------------
  x_progress          := 'RECUPERATION TYPE DE DEPENSE';
  
  vv_expenditure_type := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'EXPENDITURE_TYPE');


  x_progress := 'TYPE DE DEPENSE (vv_expenditure_type) : ' || vv_expenditure_type;
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vv_expenditure_type IS NULL THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E003_2');
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
    
  END IF;

  --------------------------------------------------------------------------------
  x_progress := 'RECUPERATION ID TACHE';
  
  vn_task_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'TASK_ID');

  x_progress := 'ID TACHE (vn_task_id) : ' || TO_CHAR(vn_task_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vn_task_id IS NULL THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E003_3');
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
    
  END IF;

  ----- ************************************************** -----
  x_progress := 'DETERMINATION COMPTE LOCAL';

  vv_segment3_value := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(pn_project_id       => vn_project_id,
                                                                 pv_expenditure_type => vv_expenditure_type,
                                                                 pn_task_id          => vn_task_id);
  
  x_progress := 'COMPTE LOCAL (vv_segment3_value) : ' || vv_segment3_value;
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vv_segment3_value IS NULL    --PHENIX 2004
  THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E003_4');
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
                               avalue	=> vv_segment3_value); -- PHENIX 2004    
                               
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT3_VALUE : '||vv_segment3_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
                                                                       
    result := 'COMPLETE:SUCCESS';
    RETURN;
    
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT3_VALUE',
                    x_progress);
    RAISE;
END get_po_eca_segment3_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT4_VALUE
--  Description   : Procédure de détermination de la valeur du segment4 :
--                  COMPTE_ANALYTIQUE
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
PROCEDURE get_po_eca_segment4_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2)
IS

	x_progress			     VARCHAR2(100);
	vn_project_id			   NUMBER;
  vn_task_id           NUMBER;
	--vd_expenditure_date	 DATE;
	vv_expenditure_type	 VARCHAR2(30);
	--vd_po_period_date		 DATE;
	--vn_back_billing_project_id	NUMBER;
	vv_segment4_value		        VARCHAR2(50); -- PHENIX 2004
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT4_VALUE : DEBUT'; -- PHENIX 2004
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run)
  THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----

  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU PROJET';

  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PROJECT_ID');

  ----- ************************************************** -----
  /*
  x_progress := 'RECUPERATION DATE DE DEPENSE';
  vd_expenditure_date := wf_engine.GetItemAttrDate( itemtype => itemtype,
                                                    itemkey  => itemkey,
                                                    aname    => 'EXPENDITURE_ITEM_DATE');
  */
  ----- ************************************************** -----
  /*
  x_progress := 'CALCUL DATE DE LA PERIODE PO';

-- KH 19/02/2002
--  vd_po_period_date := dka_tools_pkg.get_po_eca_period_date_f(vd_expenditure_date);
  ----- La date de référence : date de fin de la 1ère période ouverte PO -----
  vd_po_period_date := dka_tools_pkg.get_po_period_date_f(vd_expenditure_date);
  
  IF vd_po_period_date IS NULL
  THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  */
  
  ----- ************************************************** -----
  x_progress := 'RECUPERATION TYPE DE DEPENSE';
  vv_expenditure_type := wf_engine.GetItemAttrText( itemtype => itemtype,
                                                    itemkey  => itemkey,
                                                    aname    => 'EXPENDITURE_TYPE');

  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID TACHE';
  vn_task_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'TASK_ID');

  ----- ************************************************** -----
  ----- Détermination du compte groupe en appelant une sous procédure de la règle d'autoaccounting PA
  ----- 'CPT_GROUP_COUTS' -----
  /*
  x_progress := 'DETERMINATION DU COMPTE GROUPE';
  vv_segment4_value := dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f(vn_project_id,
                                                                        vv_expenditure_type,
                                                                        NULL,
                                                                        vd_po_period_date,
                                                                        NULL); -- PHENIX 2004
  */
  
  x_progress := 'DETERMINATION DU COMPTE ANALYTIQUE';
  vv_segment4_value := dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f(pn_project_id          => vn_project_id,
                                                                        pv_expenditure_type    => vv_expenditure_type,
                                                                        pn_expenditure_item_id => NULL,
                                                                        pn_task_id             => vn_task_id,
                                                                        pn_refac_project_id    => NULL);
  
  x_progress := 'COMPTE ANALYTIQUE (vv_segment4_value) : ' || vv_segment4_value;
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);

  IF vv_segment4_value IS NULL -- PHENIX 2004
  THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E004_1');
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
                               avalue	=> vv_segment4_value); -- PHENIX 2004
                               
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT4_VALUE : '||vv_segment4_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
                               
    result := 'COMPLETE:SUCCESS';
    RETURN;
    
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG','GET_SEGMENT4_VALUE',x_progress);  -- PHENIX 2004
    RAISE;
END get_po_eca_segment4_value; -- PHENIX 2004

-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT5_VALUE
--  Description   : Procédure de détermination de la valeur du segment5
--                  INTERCO
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
PROCEDURE get_po_eca_segment5_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2)
IS
	x_progress			    VARCHAR2(100);
	vv_supplier_type		VARCHAR2(25);
	vn_supplier_id			NUMBER;
	vv_segment5_value		VARCHAR2(50); -- PHENIX 2004
  vn_project_id       NUMBER;
  vn_vendor_site_id   NUMBER;
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT5_VALUE : DEBUT'; -- PHENIX 2004
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----

  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU PROJET';

  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID SITE FOURNISSEUR';

  vn_vendor_site_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'VENDOR_SITE_ID');

  /*
  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU FOURNISSEUR';
  
  ----- L'id du fournisseur n'est pas dans le même attribut pour le workflow des demandes d'achat
  ----- et celui des commandes -----
  IF itemtype = 'POWFRQAG'
  THEN
    vn_supplier_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'SUGGESTED_VENDOR_ID');
  ELSIF itemtype = 'POWFPOAG'
  THEN
    vn_supplier_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'VENDOR_ID');
  ELSE
    fnd_message.set_name('DKA', 'DKA_SAPWFAG_E009');
    fnd_message.set_token('ITEM_TYPE', itemtype);
    wf_engine.SetItemAttrText( itemtype => itemtype,
                               itemkey  => itemkey,
                               aname  => 'ERROR_MESSAGE',
                               avalue => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  
  x_progress := 'ID DU FOURNISSEUR (vn_supplier_id) : ' ||TO_CHAR(vn_supplier_id);
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  
  IF vn_supplier_id IS NULL and itemtype = 'POWFPOAG'
  THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E008');
    wf_engine.SetItemAttrText( itemtype => itemtype,
                               itemkey  => itemkey,
                               aname  => 'ERROR_MESSAGE',
                               avalue => fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  
  ----- Modification ES 11/06/2002 : si l'Id du fournisseur est null alors pour 
  --    l'Account Generator de la demande d'achat le segment 5 prend la valeur '0' -----
  IF vn_supplier_id IS NULL and itemtype = 'POWFRQAG'
  THEN
    wf_engine.SetItemAttrText( itemtype => itemtype,
                               itemkey  => itemkey,
                               aname  => 'LOOKUP_SET_VALUE',
                               avalue => '0');
    x_progress := 'powfrqag null';
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;
  
  ----- ************************************************** -----
  x_progress := 'RECUPERATION TYPE DU FOURNISSEUR';
  
  vv_supplier_type := wf_engine.GetItemAttrText( itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'VENDOR_TYPE');
  
  x_progress := 'TYPE DU FOURNISSEUR (vv_supplier_type) : ' || vv_supplier_type;
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  */

  ----- ************************************************** -----
  /*x_progress := 'DETERMINATION DU CODE PARTENAIRE';
  
  vv_segment5_value := dka_spaautoaccounting_pkg.get_code_partenaire_f(vv_supplier_type,
                                                                       vn_supplier_id); -- PHENIX 2004
  */

  x_progress := 'DETERMINATION DU CODE INTERCO';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  IF vn_vendor_site_id IS NULL THEN
  
    x_progress := 'PAS DE FOURNISSEUR, INTERCO=0';
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
    vv_segment5_value := 0;
  
  ELSE
  
    vv_segment5_value := dka_spaautoaccounting_pkg.code_interco(pn_project_id          => vn_project_id,
                                                                pn_id_site_fourn       => vn_vendor_site_id,
                                                                pn_expenditure_item_id => NULL);
  
    x_progress := 'CODE PARTENAIRE (vv_segment5_value) : ' || vv_segment5_value; -- PHENIX 2004
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
  END IF;

  IF vv_segment5_value IS NULL -- PHENIX 2004
   THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E005_1');
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
                              avalue   => vv_segment5_value); -- PHENIX 2004
  
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT5_VALUE : ' ||
                  vv_segment5_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
  
    result := 'COMPLETE:SUCCESS';
    RETURN;
  
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT5_VALUE',
                    x_progress); -- PHENIX 2004
    RAISE;
END get_po_eca_segment5_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT6_VALUE
--  Description   : Procédure de détermination de la valeur du segment6
--                  CENTRE_FI
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
PROCEDURE get_po_eca_segment6_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2)
IS

	x_progress			       VARCHAR2(100);
	vn_project_id			     NUMBER;
	--vd_expenditure_date	 DATE;
	--vd_po_period_date		 DATE;
	vv_segment6_value		   VARCHAR2(50);
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT6_VALUE : DEBUT'; -- PHENIX 2004
  /* DEBUG */  /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */


  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run)
  THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----

  ----- ************************************************** -----
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
  x_progress := 'CALCUL DATE DE LA PERIODE PO';
-- KH 19/02/2002
--  vd_po_period_date := dka_tools_pkg.get_po_eca_period_date_f(vd_expenditure_date);
  vd_po_period_date := dka_tools_pkg.get_po_period_date_f(vd_expenditure_date);

  IF vd_po_period_date IS NULL
  THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E001');
    fnd_message.set_token('EXPENDITURE_DATE', TO_CHAR(vd_expenditure_date));
    wf_engine.SetItemAttrText( itemtype	=> itemtype,
                               itemkey 	=> itemkey,
                               aname	=> 'ERROR_MESSAGE',
                               avalue	=> fnd_message.get_encoded);
    result := 'COMPLETE:FAILURE';
    RETURN;
  END IF;
  */
  
  ----- Détermination du centre de coûts -----
  /*
  x_progress := 'DETERMINATION DU CENTRE DE COUTS';
  vv_segment6_value := dka_spaautoaccounting_pkg.get_cost_center_f(vn_project_id,
                                                                   vd_po_period_date); -- PHENIX 2004
  */
  
  x_progress := 'DETERMINATION DU CENTRE_FI';                                                                
  vv_segment6_value := dka_spaautoaccounting_pkg.centrefi(pn_project_id => vn_project_id);

  IF vv_segment6_value IS NULL -- PHENIX 2004
  THEN
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E006_1');
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
                               avalue	=> vv_segment6_value); -- PHENIX 2004
                               
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT6_VALUE : '||vv_segment6_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
                               
    result := 'COMPLETE:SUCCESS';
    RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG','GET_PO_ECA_SEGMENT6_VALUE',x_progress);-- PHENIX 2004
    RAISE;
END get_po_eca_segment6_value; -- PHENIX 2004

-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT7_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--                  AFFAIRE
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
-- PHENIX 2004
PROCEDURE get_po_eca_segment7_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2)
IS

	x_progress			   VARCHAR2(100);
	vv_segment7_value  VARCHAR2(50);
	vn_project_id			 NUMBER;
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT7_VALUE : DEBUT';
  /* DEBUG */  /* PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress); */


  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run)
  THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----

  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'PROJECT_ID');

  /*
  ----- ************************************************** -----
  x_progress := 'DETERMINATION DU CODE D';
  ----- code D déterminé en appelant la règle d'autoaccounting PA 'CODE_D'-----
  vv_segment7_value := dka_spaautoaccounting_pkg.code_d(vn_project_id);
  */
  
  x_progress := 'DETERMINATION DE L''AFFAIRE';

  vv_segment7_value := dka_spaautoaccounting_pkg.affaire(pn_project_id => vn_project_id);

  IF vv_segment7_value IS NULL
  THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E007_1');
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
                               avalue	=> vv_segment7_value);

    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT7_VALUE : '||vv_segment7_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

    result := 'COMPLETE:SUCCESS';
    RETURN;
    
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG','GET_PO_ECA_SEGMENT7_VALUE',x_progress);
    RAISE;
END get_po_eca_segment7_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT8_VALUE
--  Description   : Procédure de détermination de la valeur du segment8 du compte Expense Charge Account:
--                  PROJET_FI
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
PROCEDURE get_po_eca_segment8_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS
                                    
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vv_segment8_value   VARCHAR2(50);
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT8_VALUE : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----

  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'PROJECT_ID');
                                                 
  x_progress := 'DETERMINATION DU PROJET_FI';

  vv_segment8_value := dka_spaautoaccounting_pkg.projetfi(pn_project_id => vn_project_id);

  IF vv_segment8_value IS NULL
  THEN
  
    fnd_message.set_name('DKA', 'DKA_SPOWFAG_E008_1');
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
                               avalue	=> vv_segment8_value);
                               
    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT8_VALUE : '||vv_segment8_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
                               
    result := 'COMPLETE:SUCCESS';
    RETURN;
    
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT8_VALUE',
                    x_progress);
    RAISE;
END get_po_eca_segment8_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT8_VALUE
--  Description   : Procédure de détermination de la valeur du segment9 du compte Expense Charge Account:
--                  FLUX
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
PROCEDURE get_po_eca_segment9_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vd_expenditure_date DATE;
  vd_po_period_date   DATE;
  vv_segment9_value   VARCHAR2(50);
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT9_VALUE : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  ----- Récupération des valeurs des attributs du workflow -----

  ----- ************************************************** -----
  x_progress := 'RECUPERATION ID DU PROJET';
  vn_project_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'PROJECT_ID');

  x_progress := 'DETERMINATION DU CODE FLUX';

  vv_segment9_value := dka_spaautoaccounting_pkg.flux(pn_project_id => vn_project_id);

  wf_engine.SetItemAttrText(itemtype => itemtype,
                            itemkey  => itemkey,
                            aname    => 'LOOKUP_SET_VALUE',
                            avalue   => vv_segment9_value);

    x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT9_VALUE : '||vv_segment9_value;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  result := 'COMPLETE:SUCCESS';
  RETURN;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT9_VALUE',
                    x_progress);
    RAISE;
END get_po_eca_segment9_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT10_VALUE
--  Description   : Procédure de détermination de la valeur du segment10 du compte Expense Charge Account:
--                  RESERVE1
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
PROCEDURE get_po_eca_segment10_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS
                                    
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vd_expenditure_date DATE;
  vd_po_period_date   DATE;
  vv_segment10_value   VARCHAR2(50);
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT10_VALUE : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  vv_segment10_value := '0';

  wf_engine.SetItemAttrText(itemtype => itemtype,
                            itemkey  => itemkey,
                            aname    => 'LOOKUP_SET_VALUE',
                            avalue   => vv_segment10_value);

  result := 'COMPLETE:SUCCESS';
  RETURN;

    

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT10_VALUE',
                    x_progress);
    RAISE;
END get_po_eca_segment10_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT11_VALUE
--  Description   : Procédure de détermination de la valeur du segment11 du compte Expense Charge Account:
--                  RESERVE2
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
PROCEDURE get_po_eca_segment11_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS
                                    
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vd_expenditure_date DATE;
  vd_po_period_date   DATE;
  vv_segment11_value   VARCHAR2(50);
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT11_VALUE : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  vv_segment11_value := '0';

  wf_engine.SetItemAttrText(itemtype => itemtype,
                            itemkey  => itemkey,
                            aname    => 'LOOKUP_SET_VALUE',
                            avalue   => vv_segment11_value);

  result := 'COMPLETE:SUCCESS';
  RETURN;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT11_VALUE',
                    x_progress);
    RAISE;
END get_po_eca_segment11_value;


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT12_VALUE
--  Description   : Procédure de détermination de la valeur du segment12 du compte Expense Charge Account:
--                  RESERVE3
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
PROCEDURE get_po_eca_segment12_value(itemtype IN VARCHAR2,
                                    itemkey  IN VARCHAR2,
                                    actid    IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    result   OUT VARCHAR2) IS
                                    
  x_progress          VARCHAR2(100);
  vn_project_id       NUMBER;
  vd_expenditure_date DATE;
  vd_po_period_date   DATE;
  vv_segment12_value   VARCHAR2(50);
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.GET_PO_ECA_SEGMENT12_VALUE : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  ----- Do nothing in cancel or timeout mode -----
  IF (funcmode != wf_engine.eng_run) THEN
    result := wf_engine.eng_null;
    RETURN;
  END IF;

  vv_segment12_value := '0';

  wf_engine.SetItemAttrText(itemtype => itemtype,
                            itemkey  => itemkey,
                            aname    => 'LOOKUP_SET_VALUE',
                            avalue   => vv_segment12_value);

  result := 'COMPLETE:SUCCESS';
    
  RETURN;

EXCEPTION
  WHEN OTHERS THEN
    wf_core.context('DKA_SPOWFAG_PKG',
                    'GET_PO_ECA_SEGMENT12_VALUE',
                    x_progress);
    RAISE;
END get_po_eca_segment12_value;

-------------------------------------------------------------------------------------
--  Nom           : IS_PO_PROJECT_RELATED
--  Description   : Procédure retournant vrai si la génération du compte se fait sur projet
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
PROCEDURE is_po_project_related ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2)
IS

  x_progress     VARCHAR2(100);

BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.IS_PO_PROJECT_RELATED : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

	result := 'COMPLETE:T';
	RETURN;

END is_po_project_related;


-------------------------------------------------------------------------------------
--  Nom           : IS_PROJECT_TYPE_INVEST
--  Description   : Procédure retournant vrai si le type de projet est Investissement
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
PROCEDURE is_project_type_invest(itemtype IN VARCHAR2,
                                 itemkey  IN VARCHAR2,
                                 actid    IN NUMBER,
                                 funcmode IN VARCHAR2,
                                 result   OUT NOCOPY VARCHAR2) IS

  l_progress     WF_ITEM_ACTIVITY_STATUSES.error_stack%TYPE;
  vn_project_id  NUMBER;
  vv_type_projet VARCHAR2(20);
  x_progress     VARCHAR2(100);
  
  vn_debug1 VARCHAR2(50);
  vn_debug2 VARCHAR2(50);
  
BEGIN

  x_progress := 'DKA_SPOWFAG_PKG.IS_PROJECT_TYPE_INVEST : DEBUT';
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  l_progress := '010';

  -- Do nothing in cancel or timeout mode
  IF (funcmode <> WF_ENGINE.eng_run) THEN
    result := WF_ENGINE.eng_null;
    RETURN;
  END IF;

  l_progress := '015';

  ----- Recuperation des valeurs des attributs du workflow -----
  vn_project_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'PROJECT_ID');

  IF nvl(vn_project_id, 0) = 0 THEN
    result := WF_ENGINE.eng_completed || ':N';
    RETURN;
  END IF;

  l_progress := '020';

  vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(vn_project_id);

  l_progress := '025';

  IF nvl(vv_type_projet, 'N') = 'N' THEN
    result := WF_ENGINE.eng_completed || ':N';
    RETURN;
  END IF;

  l_progress := '030';

  IF vv_type_projet = 'Investissement' THEN
    result := WF_ENGINE.eng_completed || ':Y';
  ELSE
    result := WF_ENGINE.eng_completed || ':N';
  END IF;

  l_progress := '035';

  x_progress := 'DKA_SPOWFAG_PKG.IS_PROJECT_TYPE_INVEST : '||result;
  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

  RETURN;

EXCEPTION
  WHEN OTHERS THEN
  
    x_progress := 'DKA_SPOWFAG_PKG.IS_PROJECT_TYPE_INVEST : '||l_progress;
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);

    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, SQLERRM);

    WF_CORE.context('DKA_SPOWFAG_PKG',
                    'is_project_type_invest',
                    l_progress);
    RAISE;
END is_project_type_invest;


END DKA_SPOWFAG_PKG; -- Package body
/
SHOW ERRORS;

EXIT
