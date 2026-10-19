CREATE OR REPLACE PACKAGE BODY dka_spowfmaster_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SPOWFMASTER_PKG.pkb 411 2007-10-23 14:18:49Z NORDEST\nboussek $
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : DKA_SPOWFMASTER_PKG.pkb
  -- DESCRIPTION       : DKA_SPOWFMASTER_PKG package body :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 27/08/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  -- 23/10/2007 NBO correction du FT 38, FT 22.
  -- 08/02/2010 MSL EID20090220 Evol 3-1 Modification des contrats et report sur la commande
  -- 15/06/2010 CDE EID20100127 Avenant évol 3-1 - procédure test_modif_champ - gestion attribute6
  -- 01/02/2011 CDE EARS00009407924 Correction procédure test_modif_champ quand ref contrat frs vide
  -- 24/03/2011 CDE Evol DGE20100001 Evolution interface utilisateur lot1
  -- 04/05/2011 CDE EARS00009474845 - Correctif calcul nouveau montant imputé suite modif
  --                + DGE20100001 Evol interface utilisateur Archivage table spécif
  -- 13/04/2012 BCO DGE20110033 Cycle de vie des contrats SSTR...
  -- 25/04/2012 JJA DGE20110030 : Ajout de la procedure : active_desactive_site_four
  -- 25/04/2012 JJA DGE20110030 : Modification de la procedure : active_desactive_site_four : ajout du flag site fournisseur
  -- 14/09/2012 BCO INC000000314568 : Modification de la procédure diminution_quantite + ajout de la procédure diminution_quantite_facture
  -- 13/03/2013 BCO DPE20120104 : Ajout de l'avenant par la prestation unitaire.
  -- 11/03/2013 BCO INC000000462675 : Anvoi du bon de commande par mail et par fax lorsque la case à coché Prestation unitaire est cochée.
  -- 31/01/2014 BCO Modification du montant d'un contrat
  -- 02/03/2017 RBE Migration R12 : artf2106737 
  -- 17/03/2017 YWA artf2120401 
  -- 18/05/2017 RBE Correction artf2154499
  -- 04/07/2017 RBE Correction artf2187880
  -- 12/02/2018 MEG artf2372180 : Correction du contexte dans le SPE061 et SPE119
  -- 15/02/2018 RBE artf2376255 : SPE119 - Correction de la sélection Employés
  -- 04/09/2018 RBE artf3025989 : INC0243936 - SPE119 - Problème recherche gestionnaire contrat SSTR
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_entete                    VARCHAR2(4000);
  gv_haut_page                 VARCHAR2(4000);
  gv_body                      VARCHAR2(10000);
  gv_pied_page                 VARCHAR2(4000);
  gv_conn                      VARCHAR2(30);
  gv_expediteur                VARCHAR2(50);
  gn_erreur                    PLS_INTEGER;
  gn_erreur_avert              PLS_INTEGER;
  gn_erreur_search         PLS_INTEGER;
  gv_mail_test                  VARCHAR2(240) := NULL;--YWA artf2120401 

  -- Read the profile option that enables/disables the debug log
  g_po_wf_debug VARCHAR2(1) := nvl(fnd_profile.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),
                                   'N');

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -------------------------------------------------------------------------------------
  --  Nom           : PRINT_LOG_MESSAGE
  --  Description   : Procédure insérant un message dans le log du traitement.
  --
  --  PARAMETRES :
  --     p_message   Entrée      Message à insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE print_log_message(p_message IN VARCHAR2) IS
    l_message VARCHAR2(1000);
  BEGIN

    l_message := substr(p_message, 1, 1000);

    IF (l_message IS NOT NULL)
    THEN
      l_message := to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                   l_message;
      dbms_output.put_line(l_message);
    END IF;

    fnd_file.put_line(fnd_file.log, l_message);

  END print_log_message;

  -------------------------------------------------------------------------------------
  --  Nom           : configure_env
  --  Description   : Procédure modifiant le contexte d'environnement.
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE configure_env(itemtype IN VARCHAR2,
                          itemkey  IN VARCHAR2,
                          user_id  OUT NUMBER,
                          resp_id  OUT NUMBER,
                          appl_id  OUT NUMBER) IS
    l_user_id  NUMBER;
    l_resp_id  NUMBER;
    l_appl_id  NUMBER;
    x_progress VARCHAR2(1000);
  BEGIN

    l_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'USER_ID');

    l_resp_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'RESPONSIBILITY_ID');

    l_appl_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'APPLICATION_ID');

    x_progress := 'DKA_SPOWFMASTER_PKG.configure_env: Result select=' ||
                  l_user_id || ':' || l_resp_id || ':' || l_appl_id;
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    IF (l_user_id IS NOT NULL AND l_resp_id IS NOT NULL AND
       l_appl_id IS NOT NULL)
    THEN

      --fnd_global.apps_initialize(l_user_id, l_resp_id, l_appl_id);
      user_id := l_user_id;
      resp_id := l_resp_id;
      appl_id := l_appl_id;
    END IF;

  END configure_env;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -------------------------------------------------------------------------------------
  --  Nom           : lance_approbation
  --  Description   : Procédure qui permet de lancer le workflow d'approbation des commandes.
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE lance_approbation(itemtype  IN VARCHAR2,
                              itemkey   IN VARCHAR2,
                              actid     IN NUMBER,
                              funcmode  IN VARCHAR2,
                              resultout OUT NOCOPY VARCHAR2) IS

    CURSOR cur_doc_type(p_document_type VARCHAR2, p_document_subtype VARCHAR2, p_org_id NUMBER) IS
      SELECT wf_approval_itemtype, wf_approval_process
        FROM po_document_types_all
       WHERE document_type_code = p_document_type AND
             document_subtype = p_document_subtype AND org_id = p_org_id;

    x_progress         VARCHAR2(1000);
    l_dummy            NUMBER;
    l_document_type    po_document_types.document_type_code%TYPE;
    l_document_subtype po_document_types.document_subtype%TYPE;
    l_type_lookup_code po_headers_all.type_lookup_code%TYPE;
    l_item_type        VARCHAR2(10);
    l_item_process     VARCHAR2(50);
    l_itemkey          VARCHAR2(80);
    l_commande_id      NUMBER;
    l_document_num     po_headers_all.segment1%TYPE;
    l_preparer_id      NUMBER;
    l_default_method   VARCHAR2(100);
    l_email_address    VARCHAR2(100);
    l_fax_number       VARCHAR2(100);
    l_doc_display_name VARCHAR2(200);
    l_org_id           NUMBER;
    l_user_id          NUMBER;
    l_resp_id          NUMBER;
    l_appl_id          NUMBER;
    l_contrat_id       NUMBER;

    vb_fac             BOOLEAN;
    
    l_adhocuser_lang WF_LANGUAGES.NLS_LANGUAGE%TYPE;
    l_adhocuser_territory WF_LANGUAGES.NLS_TERRITORY%TYPE;
    l_lang_code wf_languages.code%TYPE;
    l_ou_name     hr_all_organization_units_tl.name%type;
    l_vendor po_vendors.vendor_name%type; 
    l_vendor_site_code po_vendor_sites_all.vendor_site_code%type;

  BEGIN

    x_progress := 'DKA_SPOWFMASTER_PKG.lance_approbation: 01';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    SELECT to_char(po_wf_itemkey_s.NEXTVAL)
      INTO l_dummy
      FROM dual;

    l_commande_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'COMMANDE_ID');

    l_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'P_CONTRACT_ID');

    x_progress := 'DKA_SPOWFMASTER_PKG.lance_approbation: Recup Info Commande';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    --COMMIT; --RBE artf2106737 

    SELECT type_lookup_code, segment1, decode(type_lookup_code,
                   'BLANKET',
                   fnd_message.get_string('POS',
                                          'POS_POTYPE_BLKT'),
                   'CONTRACT',
                   fnd_message.get_string('POS',
                                          'POS_POTYPE_CNTR'),
                   'STANDARD',
                   fnd_message.get_string('POS',
                                          'POS_POTYPE_STD'),
                   'PLANNED',
                   fnd_message.get_string('POS',
                                          'POS_POTYPE_PLND')), org_id

      INTO l_type_lookup_code, l_document_num, l_doc_display_name, l_org_id
      FROM po_headers_all
     WHERE po_header_id = l_commande_id;

    IF l_org_id IS NOT NULL
    THEN

      --RBE MigR12 artf2106737 
      --fnd_client_info.set_org_context(to_char(l_org_id));
      mo_global.set_policy_context('S',to_char(l_org_id));

    END IF;

    configure_env(itemtype, itemkey, l_user_id, l_resp_id, l_appl_id);
    

    x_progress := 'DKA_SPOWFMASTER_PKG.lance_approbation: Result select=' ||
                  l_type_lookup_code || ':' || l_document_num || ':' ||
                  l_doc_display_name || ':' || l_org_id;
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    IF l_type_lookup_code = 'STANDARD'
    THEN
      l_document_type    := 'PO';
      l_document_subtype := 'STANDARD';
    ELSIF l_type_lookup_code = 'CONTRACT'
    THEN
      l_document_type    := 'PA';
      l_document_subtype := 'CONTRACT';
    END IF;

    x_progress := 'DKA_SPOWFMASTER_PKG.lance_approbation: Result select=' ||
                  l_document_type || l_document_subtype;
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    x_progress := 'DKA_SPOWFMASTER_PKG.lance_approbation: Recup wf type';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    FOR rec_doc_type IN cur_doc_type(l_document_type,
                                     l_document_subtype,
                                     l_org_id) LOOP
      l_item_type := rec_doc_type.wf_approval_itemtype;
      --l_item_process := rec_doc_type.wf_approval_process;
      l_item_process := 'DKA_SPOMASTDTL';
    END LOOP;

    x_progress := 'DKA_SPOWFMASTER_PKG.lance_approbation: Result select=' ||
                  l_item_type || ':' || l_item_process;
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    l_itemkey := to_char(l_commande_id) || '-' || l_dummy;
    
    -- Creation du process WF
    wf_engine.createprocess(itemtype => l_item_type,
                            itemkey  => l_itemkey,
                            process  => l_item_process);

                  
    -- Initialisation des attributs
    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'USER_ID',
                              avalue   => l_user_id);

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'RESPONSIBILITY_ID',
                              avalue   => l_resp_id);

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'APPLICATION_ID',
                              avalue   => l_appl_id);

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'INTERFACE_SOURCE_CODE',
                              avalue   => 'PO_FORM');

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'DOCUMENT_NUMBER',
                              avalue   => l_document_num);

    wf_engine.setitemattrnumber(itemtype => l_item_type,
                                itemkey  => l_itemkey,
                                aname    => 'DOCUMENT_ID',
                                avalue   => l_commande_id);

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'DOCUMENT_TYPE',
                              avalue   => l_document_type);

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'DOCUMENT_SUBTYPE',
                              avalue   => l_document_subtype);

    po_vendor_sites_sv.get_transmission_defaults(p_document_id      => l_commande_id,
                                                 p_document_type    => l_document_type,
                                                 p_document_subtype => l_document_subtype,
                                                 p_preparer_id      => l_preparer_id,
                                                 x_default_method   => l_default_method,
                                                 x_email_address    => l_email_address,
                                                 x_fax_number       => l_fax_number,
                                                 x_document_num     => l_document_num);

    wf_engine.setitemattrnumber(itemtype => l_item_type,
                                itemkey  => l_itemkey,
                                aname    => 'PREPARER_ID',
                                avalue   => l_preparer_id);

    /*wf_engine.setitemattrtext(itemtype => l_item_type,
    itemkey  => l_itemkey,
    aname    => 'DOCUMENT_DISPLAY_NAME',
    avalue   => l_doc_display_name);*/
    IF l_document_subtype = 'CONTRACT' THEN
       vb_fac := TRUE;
    ELSE
       vb_fac := test_modif_champ(l_commande_id,
                                  l_contrat_id);

    END IF;

    IF vb_fac = FALSE THEN
    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'FAX_DOCUMENT',
                              avalue   => 'N');

    ELSE
    -- FT 38 NBO Activation du fax
    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'FAX_DOCUMENT',
                              avalue   => 'Y');
    END IF;

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'FAX_NUMBER',
                              avalue   => l_fax_number);

    /*wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'EMAIL_DOCUMENT',
                              avalue   => 'N');

    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'EMAIL_ADDRESS',
                              avalue   => l_email_address);*/

    --PO_MOAC_UTILS_PVT.set_org_context(l_org_id) ; -- <R12 MOAC>
    wf_engine.setitemattrtext(itemtype => l_item_type,
                              itemkey  => l_itemkey,
                              aname    => 'ORG_ID',
                              avalue   => l_org_id);
      
    wf_engine.SetItemAttrText (itemtype        => l_item_type,
                         itemkey         => l_itemkey,
                         aname           => 'DOCUMENT_DISPLAY_NAME',
                         avalue          =>  l_doc_display_name);
                         
    begin
       select name
         into l_ou_name
         from hr_all_organization_units_tl ou
        where ou.language = 'F'
          and ou.organization_id = l_org_id;

       wf_engine.SetItemAttrText (itemtype => l_item_type,
                                  itemkey  => l_itemkey,
                                  aname    => 'OPERATING_UNIT_NAME',
                                  avalue   =>  l_ou_name);
     exception
       when no_data_found then
          null;
     end;
     
     begin
      SELECT pov.vendor_name,
        pvs.vendor_site_code
      INTO l_vendor,
        l_vendor_site_code
      FROM po_headers_all poh,
        po_vendors pov,
        po_vendor_sites_all pvs
      WHERE poh.po_header_id = l_commande_id
      AND poh.vendor_id       = pov.vendor_id
      AND poh.vendor_site_id  = pvs.vendor_site_id;
    exception
     when no_data_found then
          null;
    end;
         
    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_item_type, itemkey => l_itemkey, aname => 'SUPPLIER', avalue => l_vendor);
    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_item_type, itemkey => l_itemkey, aname => 'SUPPLIER_SITE', avalue => l_vendor_site_code);
 
    BEGIN
      wf_engine.setitemuserkey(itemtype => l_item_type,
                               itemkey  => l_itemkey,
                               userkey  => l_document_num);


    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    -- Lie le workflow au workflow Maître
    wf_engine.setitemparent(itemtype        => l_item_type,
                            itemkey         => l_itemkey,
                            parent_itemtype => itemtype,
                            parent_itemkey  => itemkey,
                            parent_context  => NULL);

    -- Lance le workflow détail
    wf_engine.startprocess(itemtype => l_item_type, itemkey => l_itemkey);

    -- Do nothing in cancel or timeout mode
    --
    IF (funcmode <> wf_engine.eng_run)
    THEN

      resultout := wf_engine.eng_null;
      RETURN;

    END IF;

    --COMMIT; --RBE artf2106737 

    --
    resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    --

    x_progress := 'DKA_SPOWFMASTER_PKG.lance_approbation: 02';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

  EXCEPTION

    WHEN OTHERS THEN
      resultout := wf_engine.eng_completed || ':' || 'FAIL';
      wf_core.CONTEXT('DKA_SPOWFMASTER_PKG',
                      'lance_approbation',
                      x_progress);
      RAISE;
  END lance_approbation;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : cree_commande
  --  Description   : Alimente l'open-interface des commandes
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE cree_commande(itemtype  IN VARCHAR2,
                          itemkey   IN VARCHAR2,
                          actid     IN NUMBER,
                          funcmode  IN VARCHAR2,
                          resultout OUT NOCOPY VARCHAR2) IS
    l_contrat_id NUMBER;
    l_group_id   NUMBER;
    l_errbuf     VARCHAR2(2000);
    l_retcode    NUMBER;
    x_progress   VARCHAR2(1000);
    l_user_id    NUMBER;
    l_resp_id    NUMBER;
    l_appl_id    NUMBER;
    l_org_id     NUMBER;
  BEGIN
    x_progress := 'DKA_SPOWFMASTER_PKG.cree_commande: 01';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    configure_env(itemtype, itemkey, l_user_id, l_resp_id, l_appl_id);

    l_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'P_CONTRACT_ID');

    x_progress := 'DKA_SPOWFMASTER_PKG.cree_commande: CONTRAT_ID=' ||
                  l_contrat_id;
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    dka_ipogencom_pkg.main(l_errbuf,
                           l_retcode,
                           FALSE,
                           l_contrat_id,
                           l_group_id);

    IF l_retcode = 0
    THEN
      x_progress := 'DKA_SPOWFMASTER_PKG.cree_commande: group_id=' ||
                    l_group_id;
      IF (g_po_wf_debug = 'Y')
      THEN
        /* DEBUG */
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      END IF;

      -- Affecte le nouveau groupe de commande
      wf_engine.setitemattrnumber(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'GROUP_ID',
                                  avalue   => l_group_id);
      /*wf_engine.setitemattrnumber(itemtype => itemtype,
      itemkey  => itemkey,
      aname    => 'REQUEST_ID',
      avalue   => l_group_id);*/

      resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    ELSE
      x_progress := substr('DKA_SPOWFMASTER_PKG.cree_commande: ' ||
                           l_errbuf,
                           1,
                           1000);
      IF (g_po_wf_debug = 'Y')
      THEN
        /* DEBUG */
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      END IF;

      resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      resultout  := wf_engine.eng_completed || ':' || 'FAIL';
      x_progress := substr('DKA_SPOWFMASTER_PKG.cree_commande: ' || SQLERRM,
                           1,
                           1000);
      IF (g_po_wf_debug = 'Y')
      THEN
        /* DEBUG */
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      END IF;

      wf_core.CONTEXT('DKA_SPOWFMASTER_PKG', 'cree_commande', x_progress);
      RAISE;
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : recupere_identifiant_commande
  --  Description   : Procédure récupérant l'identifiant de commande.
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE recup_commande(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2) IS
    x_progress       VARCHAR2(100);
    l_group_id       NUMBER;
    l_req_id         NUMBER;
    l_commande_id    NUMBER;
    l_revision_num   NUMBER;

    vn_contrat_id    NUMBER;
    vn_org_id        NUMBER;

  BEGIN
    x_progress := 'DKA_SPOWFMASTER_PKG.recup_commande: 01';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    l_group_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'GROUP_ID');
    /*l_req_id   := wf_engine.getitemattrnumber(itemtype => itemtype,
    itemkey  => itemkey,
    aname    => 'REQUEST_ID');*/
    BEGIN
      SELECT ph.po_header_id,
             ph.revision_num                                -- Ajout MSL -- 09/02/2010
        INTO l_commande_id,
             l_revision_num                                 -- Ajout MSL -- 09/02/2010
        FROM po_headers_interface phi, po_headers_all ph
       WHERE phi.batch_id = l_group_id AND ph.segment1 = phi.document_num;
      /*SELECT ph.po_header_id
       INTO l_commande_id
       FROM po_headers_all ph
      WHERE ph.request_id = l_req_id;*/

    EXCEPTION
      WHEN no_data_found THEN
        resultout := wf_engine.eng_completed || ':' || 'FAIL';
        RETURN;
    END;

    x_progress := 'DKA_SPOWFMASTER_PKG.recup_commande: COMMANDE_ID=' ||
                  l_commande_id;
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    -- Affecte le nouveau groupe de commande
    wf_engine.setitemattrnumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'COMMANDE_ANN_ID',
                                avalue   => l_commande_id);

    -- CDE Affecte le document_id pour édition et envoi du BdC
    wf_engine.setitemattrnumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'DOCUMENT_ID',
                                avalue   => l_commande_id);


    -- Debut Ajout MSL - 09/02/2010
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                          itemkey  => itemkey,
                                          aname    => 'P_CONTRACT_ID');



    UPDATE DKA_CONTRAT_SSTR dcs
       SET dcs.commande_id = l_commande_id,
           dcs.commande_version = l_revision_num
     WHERE dcs.po_header_id = vn_contrat_id;
    -- Fin Ajout MSL - 09/02/2010

    UPDATE DKA_CONTRAT_SSTR_ARCHI dcsa
       SET dcsa.commande_id = l_commande_id,
           dcsa.commande_version = l_revision_num
     WHERE dcsa.po_header_id = vn_contrat_id
       AND dcsa.revision_num = (SELECT dcs.revision_num
                                FROM DKA_CONTRAT_SSTR dcs
                                WHERE dcs.po_header_id = dcsa.po_header_id);

    COMMIT;

    resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

  EXCEPTION
    WHEN OTHERS THEN
      resultout  := wf_engine.eng_completed || ':' || 'FAIL';
      x_progress := substr('DKA_SPOWFMASTER_PKG.recup_commande: ' ||
                           SQLERRM,
                           1,
                           100);
      IF (g_po_wf_debug = 'Y')
      THEN
        /* DEBUG */
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      END IF;

      wf_core.CONTEXT('DKA_SPOWFMASTER_PKG', 'recup_commande', x_progress);
      RAISE;
  END recup_commande;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : cree_reception
  --  Description   : Réceptionne une commande
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE cree_reception(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2) IS
    x_progress    VARCHAR2(1000);
    l_commande_id NUMBER;
    l_batch_id    NUMBER;
    l_user_id     NUMBER;
    l_resp_id     NUMBER;
    l_appl_id     NUMBER;
    l_errbuf      VARCHAR2(2000);
    l_retcode     NUMBER;
  BEGIN

    x_progress := 'DKA_SPOWFMASTER_PKG.cree_reception: 01';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    configure_env(itemtype, itemkey, l_user_id, l_resp_id, l_appl_id);

    l_commande_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'COMMANDE_ANN_ID');

    x_progress := 'DKA_SPOWFMASTER_PKG.cree_reception: COMMANDE_ID=' ||
                  l_commande_id;
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    dka_iporecvtotal_pkg.main(l_errbuf,
                              l_retcode,
                              l_commande_id,
                              l_batch_id);

    IF l_retcode = 0
    THEN
      x_progress := 'DKA_SPOWFMASTER_PKG.cree_reception: batch_id=' ||
                    l_batch_id;
      IF (g_po_wf_debug = 'Y')
      THEN
        /* DEBUG */
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      END IF;

      -- Affecte le nouveau groupe de commande
      wf_engine.setitemattrnumber(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'BATCH_ID',
                                  avalue   => l_batch_id);

      resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    ELSE
      x_progress := substr('DKA_SPOWFMASTER_PKG.cree_reception: ' ||
                           l_errbuf,
                           1,
                           1000);
      IF (g_po_wf_debug = 'Y')
      THEN
        /* DEBUG */
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      END IF;

      resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      resultout  := wf_engine.eng_completed || ':' || 'FAIL';
      x_progress := substr('DKA_SPOWFMASTER_PKG.cree_reception: ' ||
                           SQLERRM,
                           1,
                           1000);
      IF (g_po_wf_debug = 'Y')
      THEN
        /* DEBUG */
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      END IF;

      wf_core.CONTEXT('DKA_SPOWFMASTER_PKG', 'cree_reception', x_progress);
      RAISE;

  END;

  -------------------------------------------------------------------------------------
  --  Nom           : archivage_contrat
  --  Description   : Procédure qui permet d'archiver le contrat modifié.
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE archivage_contrat(itemtype  IN VARCHAR2,
                              itemkey   IN VARCHAR2,
                              actid     IN NUMBER,
                              funcmode  IN VARCHAR2,
                              resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id    NUMBER;
    vp_authorization_status  VARCHAR2(15);

  BEGIN

    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

    BEGIN
        SELECT authorization_status
        INTO vp_authorization_status
        FROM po_headers_all
        WHERE po_header_id = vn_contrat_id;
    EXCEPTION
    WHEN OTHERS THEN
        vp_authorization_status := null;
    END;

    -- Archivage dans les tables d'interface seulement si le contrat est approuvé
    IF vp_authorization_status = 'APPROVED'
    THEN
         -- Archivage de dka_contrat_sstr
         INSERT INTO dka_contrat_sstr_archi
           (SELECT dcs.*
              FROM dka_contrat_sstr dcs
             WHERE dcs.po_header_id = vn_contrat_id
           );

         -- Archivage de dka_contrat_sstr_imputation
         INSERT INTO dka_contrat_sstr_imput_archi
           (SELECT dcsa.*
              FROM dka_contrat_sstr_imputation dcsa
             WHERE dcsa.po_header_id = vn_contrat_id
            );
    END IF;

    COMMIT;


  END;

  -------------------------------------------------------------------------------------
  --  Nom           : diminution_quantite
  --  Description   : Procédure qui permet de vérifier que la quantité des lignes
  --                  n'ont pas diminuer
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE diminution_quantite(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id           NUMBER;
    vn_quantity_delivered   po_distributions_all.quantity_delivered%TYPE;
    vb_quantity_diminue     BOOLEAN := FALSE;

    -- DPE20120104 - Variable contenant la valeur de la prestation unitaire
    vv_presta_unit            po_headers_all.attribute14%TYPE;
    vn_annulation            NUMBER;
    vn_amount_archi         PO_HEADERS_ARCHIVE_ALL.BLANKET_TOTAL_AMOUNT%TYPE;
    vn_amount               PO_HEADERS_ALL.BLANKET_TOTAL_AMOUNT%TYPE;
    
    CURSOR cur_contrat_imput(pn_contrat_id NUMBER) IS
    SELECT dcsi.po_header_id,
           dcsi.contrat_imputation_id,             -- Numero de ligne
           dcsi.project_id,                        -- Projet
           dcsi.location_id,                       -- Lieu de livraison
           dcsi.expenditure_type                   -- Type de dépense
      FROM dka_contrat_sstr_imputation dcsi
     WHERE dcsi.po_header_id = pn_contrat_id;

  BEGIN

    -- Récupération de l'id contrat
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'P_CONTRACT_ID');
    -- DGE20130037 - Modification du montant d'un contrat.
    BEGIN
        SELECT COUNT(1)
          INTO vn_annulation
          FROM DKA_CONTRAT_SSTR_ARCHI DCSA
         WHERE DCSA.PO_HEADER_ID = vn_contrat_id
           AND DCSA.REVISION_NUM = (SELECT decode(DCS.REVISION_NUM, 0, 0,  DCS.REVISION_NUM-1)
                                      FROM DKA_CONTRAT_SSTR DCS 
                                     WHERE DCS.PO_HEADER_ID = DCSA.PO_HEADER_ID)
           AND DCSA.ANNULATION     = 'OUI';
    EXCEPTION
        WHEN OTHERS THEN
            vn_annulation := 0;
    END;
    
    IF vn_annulation != 0 THEN
        BEGIN
          SELECT PHAA.BLANKET_TOTAL_AMOUNT, PHA.BLANKET_TOTAL_AMOUNT
            INTO vn_amount_archi, vn_amount
            FROM PO_HEADERS_ALL PHA, PO_HEADERS_ARCHIVE_ALL PHAA
           WHERE PHAA.PO_HEADER_ID = PHA.PO_HEADER_ID
             AND PHA.PO_HEADER_ID = vn_contrat_id
             AND PHAA.REVISION_NUM = (SELECT decode(PHA2.REVISION_NUM, 0, 0,  PHA2.REVISION_NUM-1)
                          FROM DKA_CONTRAT_SSTR PHA2
                         WHERE PHA2.PO_HEADER_ID = PHAA.PO_HEADER_ID);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            resultout := wf_engine.eng_completed || ':' || 'N';
          WHEN OTHERS THEN
            resultout := wf_engine.eng_completed || ':' || 'N';
        END;
        
        IF vn_amount_archi > vn_amount THEN
          resultout := wf_engine.eng_completed || ':' || 'Y';
        ELSE
              resultout := wf_engine.eng_completed || ':' || 'N';
        END IF;
        
    ELSE
        -- DPE20120104 - Recherche  s'il s'agit d'une prestation unitaire.
        BEGIN
            SELECT pha.attribute14
              INTO vv_presta_unit
              FROM po_headers_all pha
             WHERE pha.po_header_id = vn_contrat_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                vv_presta_unit := NULL;
            WHEN OTHERS THEN
                vv_presta_unit := NULL;
        END;
        
        -- Pour toutes les lignes
        FOR rec_contrat_imput IN cur_contrat_imput(vn_contrat_id)
            LOOP

            BEGIN
            -- On récupére le montant de la ligne
            SELECT pda.quantity_delivered
              INTO vn_quantity_delivered
            FROM dka_contrat_sstr_imputation dcsi,
                 po_line_locations_all pll,
                 po_distributions_all pda,
                 dka_contrat_sstr dcs
           WHERE pll.ship_to_location_id = dcsi.location_id                -- Lieu de livraison
             AND pda.line_location_id = pll.line_location_id
             AND dcsi.project_id = pda.project_id                          -- Projet
             AND dcsi.expenditure_type = pda.expenditure_type              -- Type de dépense
             and dcs.po_header_id = dcsi.po_header_id
             and dcs.commande_id = pda.po_header_id
             and dcs.commande_id = pll.po_header_id
             AND dcsi.po_header_id = rec_contrat_imput.po_header_id
             AND dcsi.contrat_imputation_id = rec_contrat_imput.contrat_imputation_id;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   vn_quantity_delivered := 0;

            END;
            -- DPE20120104 - Si l'avenant est une prestation unitaire alors:
            IF vv_presta_unit = 'OUI' THEN
                IF vn_quantity_delivered > get_montant_presta_unit(rec_contrat_imput.contrat_imputation_id) THEN
                  vb_quantity_diminue := TRUE;
                END IF;
            ELSE
                -- On compare les montants
                IF vn_quantity_delivered > get_montant_imput(rec_contrat_imput.contrat_imputation_id) THEN
                   vb_quantity_diminue := TRUE;
                END IF;
            END IF;

        END LOOP;

        -- Si le montant a diminué, on retourne 'oui'
        IF vb_quantity_diminue = TRUE THEN
          resultout := wf_engine.eng_completed || ':' || 'Y';
        ELSE
          resultout := wf_engine.eng_completed || ':' || 'N';
        END IF;
    END IF;
  END;
  
  -------------------------------------------------------------------------------------
  --  Nom           : diminution_quantite_facture
  --  Description   : Procédure qui permet de vérifier que la quantité des lignes
  --                  n'ont pas diminuer
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE diminution_quantite_facture(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id           NUMBER;
    vn_quantity_billed   po_distributions_all.quantity_delivered%TYPE;
    vb_quantity_diminue     BOOLEAN := FALSE;
    vv_presta_unit          po_headers_all.attribute14%TYPE;
    
    CURSOR cur_contrat_imput(pn_contrat_id NUMBER) IS
    SELECT dcsi.po_header_id,
           dcsi.contrat_imputation_id,             -- Numero de ligne
           dcsi.project_id,                        -- Projet
           dcsi.location_id,                       -- Lieu de livraison
           dcsi.expenditure_type                   -- Type de dépense
      FROM dka_contrat_sstr_imputation dcsi
     WHERE dcsi.po_header_id = pn_contrat_id;

  BEGIN

    -- Récupération de l'id contrat
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'P_CONTRACT_ID');

    -- DPE20120104 - Recherche  s'il s'agit d'une prestation unitaire.
    BEGIN
        SELECT pha.attribute14
          INTO vv_presta_unit
          FROM po_headers_all pha
         WHERE pha.po_header_id = vn_contrat_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vv_presta_unit := NULL;
        WHEN OTHERS THEN
            vv_presta_unit := NULL;
    END;
    
    -- Pour toutes les lignes
    FOR rec_contrat_imput IN cur_contrat_imput(vn_contrat_id)
        LOOP

        BEGIN
        -- On récupére le montant de la ligne
        SELECT pda.quantity_billed
          INTO vn_quantity_billed
        FROM dka_contrat_sstr_imputation dcsi,
             po_line_locations_all pll,
             po_distributions_all pda,
             dka_contrat_sstr dcs
       WHERE pll.ship_to_location_id = dcsi.location_id                -- Lieu de livraison
         AND pda.line_location_id = pll.line_location_id
         AND dcsi.project_id = pda.project_id                          -- Projet
         AND dcsi.expenditure_type = pda.expenditure_type              -- Type de dépense
         and dcs.po_header_id = dcsi.po_header_id
         and dcs.commande_id = pda.po_header_id
         and dcs.commande_id = pll.po_header_id
         AND dcsi.po_header_id = rec_contrat_imput.po_header_id
         AND dcsi.contrat_imputation_id = rec_contrat_imput.contrat_imputation_id;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
               vn_quantity_billed := 0;

        END;
        -- On compare les montants
        IF vv_presta_unit = 'OUI' THEN
            IF vn_quantity_billed > get_montant_presta_unit(rec_contrat_imput.contrat_imputation_id) THEN
              vb_quantity_diminue := TRUE;
            END IF;
        ELSE
            IF vn_quantity_billed > get_montant_imput(rec_contrat_imput.contrat_imputation_id) THEN
               vb_quantity_diminue := TRUE;
            END IF;
        END IF;
    END LOOP;

    -- Si le montant a diminué, on retourne 'oui'
    IF vb_quantity_diminue = TRUE THEN
      resultout := wf_engine.eng_completed || ':' || 'N';
    ELSE
      resultout := wf_engine.eng_completed || ':' || 'Y';
    END IF;
  END;


  -------------------------------------------------------------------------------------
  --  Nom           : reception_quantite
  --  Description   : Procédure qui permet de vérifier que des quantités n'ont pas été receptionné
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE reception_quantite(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,
                               resultout OUT NOCOPY VARCHAR2) IS

  vn_commande_id               NUMBER;
  vb_complement                BOOLEAN := FALSE;

  CURSOR cur_po_distribution IS
  SELECT pda.quantity_ordered,
         pda.quantity_delivered
    FROM po_distributions_all pda
   WHERE pda.po_header_id = vn_commande_id;

  BEGIN
    -- Récupération de l'id commande
    vn_commande_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'COMMANDE_ID');
    -- On vérifie chaque ligne de la commande
    FOR rec_po_distribution IN cur_po_distribution
    LOOP
        IF rec_po_distribution.quantity_ordered > rec_po_distribution.quantity_delivered
        THEN
           vb_complement := TRUE;
        END IF;
    END LOOP;

    -- Si un complement est nécessaire, on retourne 'oui'
    IF vb_complement = TRUE THEN
      resultout := wf_engine.eng_completed || ':' || 'Y';
    ELSE
      resultout := wf_engine.eng_completed || ':' || 'N';
    END IF;

  END;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_workflow_maitre
  --  Description   : Lance le workflow Maitre
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_workflow_maitre(p_errbuf     OUT VARCHAR2,
                                  p_retcode    IN OUT NUMBER,
                                  p_id_contrat IN NUMBER) IS
    l_step           VARCHAR2(50);
    l_dummy          NUMBER;
    l_org_id_contrat NUMBER;
    l_item_key       VARCHAR2(100);
    l_wf_itemtype    VARCHAR2(10);
    l_wf_process     VARCHAR2(20);

  BEGIN
    p_retcode := 0;

    -- Initialisation
    l_wf_itemtype := 'DKASPOMA';
    l_wf_process  := 'DKAPROCESSMAITRE';
    
    SELECT to_char(dka_spowfmaster_s.NEXTVAL)
      INTO l_dummy
      FROM dual;

    SELECT org_id
      INTO l_org_id_contrat
      FROM po_headers_all
     WHERE po_header_id = p_id_contrat;

    l_item_key := p_id_contrat || l_dummy;

    -- Creation du process WF
    wf_engine.createprocess(itemtype => l_wf_itemtype,
                            itemkey  => l_item_key,
                            process  => l_wf_process);

    -- Initialisation des attributs
    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'P_CONTRACT_ID',
                                avalue   => p_id_contrat);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'USER_ID',
                                avalue   => fnd_global.user_id);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'RESPONSIBILITY_ID',
                                avalue   => fnd_global.resp_id);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'APPLICATION_ID',
                                avalue   => fnd_global.resp_appl_id);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'ORG_ID',
                                avalue   => l_org_id_contrat /*fnd_global.org_id*/);

    -- Kick off the process
    wf_engine.startprocess(itemtype => l_wf_itemtype,
                           itemkey  => l_item_key);
    -- FT 22
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'lance_workflow_maitre =>' || l_step || '=>' || SQLERRM;
  END lance_workflow_maitre;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_workflow_approbation
  --  Description   : Lance le workflow de la phase d'approbation
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_wf_modif_approbation(p_errbuf     OUT VARCHAR2,
                                       p_retcode    IN OUT NUMBER,
                                       p_id_contrat IN NUMBER) IS

    l_step                             VARCHAR2(50);
    l_dummy                            NUMBER;
    l_item_key                         VARCHAR2(100);
    l_wf_itemtype                      VARCHAR2(10);
    l_wf_process                       VARCHAR2(20);
    vn_commande_id                     DKA_CONTRAT_SSTR.Commande_Id%TYPE;
    vn_org_id                          NUMBER; --RBE artf2187880 

  BEGIN
    p_retcode := 0;

    -- Initialisation
    l_step := 'Initialisation';
    l_wf_itemtype := 'DKASPAPR';
    l_wf_process  := 'DKAPROCESSAPPRO';

    l_step := 'Création de l''item_key';
    SELECT to_char(dka_spowfmaster_s.NEXTVAL)
      INTO l_dummy
      FROM dual;

    l_item_key := p_id_contrat || l_dummy;

    l_step := 'Récupération du commande_id';
    SELECT dcs.commande_id,org_id
      INTO vn_commande_id,vn_org_id --RBE artf2187880 
      FROM DKA_CONTRAT_SSTR dcs
     WHERE dcs.po_header_id = p_id_contrat;

    --RBE artf2187880 
    mo_global.set_policy_context('S',vn_org_id);
    
    -- Creation du process WF
    l_step := 'Creation du process WF';
    wf_engine.createprocess(itemtype => l_wf_itemtype,
                            itemkey  => l_item_key,
                            process  => l_wf_process);

    -- Initialisation des attributs
    l_step := 'Initialisation des attributs';
    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'P_CONTRACT_ID',
                                avalue   => p_id_contrat);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'COMMANDE_ID',
                                avalue   => vn_commande_id);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'USER_ID',
                                avalue   => fnd_global.user_id);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'RESPONSIBILITY_ID',
                                avalue   => fnd_global.resp_id);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'APPLICATION_ID',
                                avalue   => fnd_global.resp_appl_id);

    -- Kick off the process
    wf_engine.startprocess(itemtype => l_wf_itemtype,
                           itemkey  => l_item_key);
    -- FT 22
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'lance_wf_modif_approbation =>' || l_step || '=>' || SQLERRM;

  END;

    ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_wf_resil_annule
  --  Description   : Lance le workflow de la phase d'approbation
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_wf_resil_annule(p_errbuf     OUT VARCHAR2,
                                       p_retcode    IN OUT NUMBER,
                                       p_id_contrat IN NUMBER) IS

    l_step                             VARCHAR2(50);
    l_dummy                            NUMBER;
    l_item_key                         VARCHAR2(100);
    l_wf_itemtype                      VARCHAR2(10);
    l_wf_process                       VARCHAR2(20);
    vn_commande_id                     DKA_CONTRAT_SSTR.Commande_Id%TYPE;
    vn_org_id                          NUMBER; --RBE artf2187880 

  BEGIN
    p_retcode := 0;

    -- Initialisation
    l_step := 'Initialisation';
    l_wf_itemtype := 'DKASPORE';
    l_wf_process  := 'DKAPROCESSRESIL';

    l_step := 'Création de l''item_key';
    SELECT to_char(dka_spowfmaster_s.NEXTVAL)
      INTO l_dummy
      FROM dual;

    l_item_key := p_id_contrat || l_dummy;

    l_step := 'Récupération du commande_id';
    SELECT dcs.commande_id,org_id
      INTO vn_commande_id,vn_org_id --RBE artf2187880 
      FROM DKA_CONTRAT_SSTR dcs
     WHERE dcs.po_header_id = p_id_contrat;

    --RBE artf2187880 
    mo_global.set_policy_context('S',vn_org_id);
     
    -- Creation du process WF
    l_step := 'Creation du process WF';
    wf_engine.createprocess(itemtype => l_wf_itemtype,
                            itemkey  => l_item_key,
                            process  => l_wf_process);

    -- Initialisation des attributs
    l_step := 'Initialisation des attributs';
    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'P_CONTRACT_ID',
                                avalue   => p_id_contrat);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'COMMANDE_ID',
                                avalue   => vn_commande_id);

    wf_engine.setitemattrnumber(itemtype => l_wf_itemtype,
                                itemkey  => l_item_key,
                                aname    => 'USER_ID',
                                avalue   => fnd_global.user_id);

    -- Kick off the process
    wf_engine.startprocess(itemtype => l_wf_itemtype,
                           itemkey  => l_item_key);
    -- FT 22
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'lance_wf_resil_annule =>' || l_step || '=>' || SQLERRM;

  END;

  -------------------------------------------------------------------------------------
  --  Nom           : get_montant_presta_unit
  --  Description   : Fonction qui retourne le montant modifié de la ligne lorsque le contrat est une prestation unitaire
  --
  --  PARAMETRES : pn_contrat_imputation_id : Numéro de la ligne d'imputation
  --
  --  VALEUR RETOURNEE : Montant de la ligne
  --     N/A
  -------------------------------------------------------------------------------------
  FUNCTION get_montant_presta_unit(pn_contrat_imputation_id IN NUMBER)
  RETURN NUMBER
  IS

  CURSOR cur_imput(pn_contrat_imputation_id NUMBER) IS
        select pha.revision_num,
           pha.po_header_id,
           pha.blanket_total_amount amount,
           dcsi.unite_oeuvre,
           dcsia_sum.sum_unite_oeuvre
      from po_headers_all pha,
           dka_contrat_sstr_imputation dcsi,
           dka_contrat_sstr dcs,
           (SELECT po_header_id,
                   revision_num,
                   sum(unite_oeuvre) sum_unite_oeuvre
              FROM dka_contrat_sstr_imputation
             GROUP BY po_header_id, revision_num) dcsia_sum
     where pha.po_header_id = dcs.po_header_id
       and dcsi.po_header_id = pha.po_header_id
       and dcsi.revision_num = pha.revision_num
       and dcsia_sum.po_header_id = dcsi.po_header_id
       and dcsia_sum.revision_num = dcsi.revision_num
       and dcsi.contrat_imputation_id = pn_contrat_imputation_id;

  rec_imput cur_imput%ROWTYPE;

  BEGIN
    -- Calcul du nouveau montant de la ligne d'imputation
    FOR rec_imput IN cur_imput (pn_contrat_imputation_id)
    LOOP
      RETURN ROUND(rec_imput.amount * (rec_imput.unite_oeuvre / rec_imput.sum_unite_oeuvre), 2);
    END LOOP;
  END get_montant_presta_unit ;
  
  -------------------------------------------------------------------------------------
  --  Nom           : get_montant_imput
  --  Description   : Fonction qui retourne le montant modifié de la ligne
  --
  --  PARAMETRES : pn_contrat_imputation_id : Numéro de la ligne d'imputation
  --
  --  VALEUR RETOURNEE : Montant de la ligne
  --     N/A
  -------------------------------------------------------------------------------------
  FUNCTION get_montant_imput(pn_contrat_imputation_id IN NUMBER)
  RETURN NUMBER
  IS

  vn_amount_imputation NUMBER;
  vn_nbr_mois_contrat NUMBER;
  vd_date_effet_deb DATE;
  vd_date_effet_fin DATE;

  CURSOR cur_historique_imput(pn_contrat_imputation_id NUMBER) IS
    SELECT
         phaa.revision_num,
         phaa.po_header_id,
         phaa.blanket_total_amount amount,
         pha.start_date,
         pha.end_date,
         dcsa.date_effet,
         dcsa.date_resiliation,
         dcsa_RevSup.date_effet date_effet_revsup,
         dcsia.unite_oeuvre,
         dcsia_sum.sum_unite_oeuvre,
         dcsa_RevSup.revision_num revision_num_revsup
    FROM po_headers_all pha
        ,po_headers_archive_all phaa
        ,dka_contrat_sstr_archi dcsa
        ,dka_contrat_sstr_archi dcsa_RevSup
        ,dka_contrat_sstr_imput_archi dcsia
        ,(SELECT po_header_id, revision_num, sum(unite_oeuvre) sum_unite_oeuvre
          FROM dka_contrat_sstr_imput_archi
          GROUP BY po_header_id, revision_num) dcsia_sum
       WHERE dcsa.po_header_id = phaa.po_header_id
         AND dcsa.revision_num = phaa.revision_num
         AND dcsa_RevSup.po_header_id(+) = phaa.po_header_id
         AND dcsa_RevSup.revision_num(+) = phaa.revision_num + 1
         AND phaa.po_header_id = dcsia.po_header_id
         AND phaa.revision_num = dcsia.revision_num
         AND dcsia_sum.po_header_id = dcsia.po_header_id
         AND dcsia_sum.revision_num = dcsia.revision_num
         AND phaa.po_header_id = pha.po_header_id
         AND phaa.start_date = pha.start_date
         AND dcsia.contrat_imputation_id = pn_contrat_imputation_id
    ORDER BY phaa.revision_num;

  rec_historique_imput cur_historique_imput%ROWTYPE;

  BEGIN
  vn_amount_imputation := 0;

  -- Calcul du nouveau montant de la ligne d'imputation
  FOR rec_historique_imput IN cur_historique_imput (pn_contrat_imputation_id)
  LOOP
    BEGIN
    -- Nombre de mois du contrat
        vn_nbr_mois_contrat := round(months_between(trunc(rec_historique_imput.end_date), trunc(rec_historique_imput.start_date)));
    -- Nombre de mois compris entre date de début et date d'effet
        vd_date_effet_deb := nvl(rec_historique_imput.date_effet, rec_historique_imput.start_date);

    --
        IF rec_historique_imput.revision_num_revsup IS NULL
        THEN
            vd_date_effet_fin := nvl(rec_historique_imput.date_effet_revsup, rec_historique_imput.end_date);
        ELSE
            vd_date_effet_fin := nvl(rec_historique_imput.date_effet_revsup, rec_historique_imput.start_date);
        END IF;

        -- Pour éviter le cas où la somme des unites d'oeuvre = 0 => division par zéro
        -- EARS00009474845 contourner problème pour les cas de renouvellement par modif.
        IF (rec_historique_imput.sum_unite_oeuvre != 0 AND round(months_between(trunc(vd_date_effet_fin), trunc(vd_date_effet_deb))) > 0 AND rec_historique_imput.date_resiliation IS NULL)
        THEN
            vn_amount_imputation := vn_amount_imputation + ROUND((rec_historique_imput.amount
                                    * (round(months_between(trunc(vd_date_effet_fin), trunc(vd_date_effet_deb))))
                                        / vn_nbr_mois_contrat)
                                    * (rec_historique_imput.unite_oeuvre / rec_historique_imput.sum_unite_oeuvre)
                                      , 2);
        ELSIF (rec_historique_imput.date_resiliation IS NOT NULL)
        THEN
            vn_amount_imputation := vn_amount_imputation + ROUND((rec_historique_imput.amount
                                    * (round(months_between(trunc(rec_historique_imput.date_resiliation), trunc(vd_date_effet_deb))))
                                        / vn_nbr_mois_contrat)
                                    * (rec_historique_imput.unite_oeuvre / rec_historique_imput.sum_unite_oeuvre)
                                      , 2);
      END IF;
    END;
  END LOOP;
  ----- return value -----
  RETURN (vn_amount_imputation);

  END get_montant_imput ;

  -------------------------------------------------------------------------------------
  --  Nom           : test_modif_champ
  --  Description   : Fonction qui vérifie si le bon de commande doit etre renvoyé par fax
  --
  --  PARAMETRES : pn_commande_id : Id de la commande
  --               pn_contract_id : Id du contrat
  --
  --  VALEUR RETOURNEE : Montant de la ligne
  --     N/A
  -------------------------------------------------------------------------------------
  FUNCTION test_modif_champ(pn_commande_id IN NUMBER,
                            pn_contract_id IN NUMBER)
  RETURN BOOLEAN
  IS

  vv_step                                  VARCHAR2(200);

  vb_envoi_bdc                             BOOLEAN;
  vv_site_fournisseur                      po_headers_all.vendor_site_id%TYPE;
  vv_lieu_livraison                        po_headers_all.ship_to_location_id%TYPE;
  vv_lieu_facturation                      po_headers_all.bill_to_location_id%TYPE;
  vd_date_debut                            po_headers_all.start_date%TYPE;
  vd_date_fin                              po_headers_all.end_date%TYPE;
  vv_site_fournisseur_archi                po_headers_all.vendor_site_id%TYPE;
  vv_lieu_livraison_archi                  po_headers_all.ship_to_location_id%TYPE;
  vv_lieu_facturation_archi                po_headers_all.bill_to_location_id%TYPE;
  vd_date_debut_archi                      po_headers_all.start_date%TYPE;
  vd_date_fin_archi                        po_headers_all.end_date%TYPE;
  vv_attribute6                            po_headers_all.attribute6%TYPE;
  vn_revision_num                          po_lines_archive_all.revision_num%TYPE;
  vn_revision_num_contrat                  po_lines_archive_all.revision_num%TYPE;
  vv_description_contrat                   po_lines_all.item_description%TYPE;
  vv_montant_annuel                        po_lines_all.quantity%TYPE;
  vv_description_contrat_archi             po_lines_all.item_description%TYPE;
  vv_montant_annuel_archi                  po_lines_all.quantity%TYPE;
  vn_nbr_ligne_a                           NUMBER;
  vn_nbr_ligne_b                           NUMBER;
  vv_ref_contrat_four                      dka_contrat_sstr.ref_contrat_fournisseur%TYPE;
  vv_ref_contrat_four_archi                dka_contrat_sstr_archi.ref_contrat_fournisseur%TYPE;
  vv_attribute14_archi                        po_headers_archive_all.attribute14%TYPE;
  vv_attribute14                               po_headers_all.attribute14%TYPE;
  CURSOR cur_po_distribution(pn_commande NUMBER)
  IS
    SELECT pdaa.quantity_ordered as quantity_archi,
           pda.quantity_ordered as quantity
      FROM po_distributions_archive_all pdaa,
           po_distributions_all pda
     WHERE 1 = 1
       AND pdaa.po_distribution_id = pda.po_distribution_id
       AND pdaa.latest_external_flag = 'Y'
       AND pdaa.po_header_id = pn_commande;

  BEGIN

      vv_step := 'Recherche du numéro de révison en cours';
      BEGIN
        SELECT pha.revision_num
          INTO vn_revision_num
          FROM po_headers_all pha
        WHERE pha.po_header_id = pn_commande_id;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         vn_revision_num := 0;
      END;
      -- 11/03/2013 BCO INC000000462675 - Comparaison de la valeur du champ Prestation Unitaire dans la table de travail et dans la table d'archive.
      vv_step := 'Recherche du champ Prestation unitaire dans la table d''archive';
      BEGIN
        SELECT pha.attribute14,
               ph.attribute14
          INTO vv_attribute14_archi,
               vv_attribute14
          FROM po_headers_archive_all pha,
               po_headers_all ph
         WHERE ph.po_header_id = pha.po_header_id
           AND ph.po_header_id = pn_contract_id
           AND ph.revision_num = pha.revision_num - 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vv_attribute14_archi := 'NON';
          vv_attribute14 := 'NON';
      END;
      
      -- 11/03/2013 BCO INC000000462675 - si le champ a été modifié, le bon de commande est envoyé par mail et faxé.
      IF vn_revision_num = 0 or vv_attribute14_archi != vv_attribute14 THEN
          vb_envoi_bdc := TRUE;
          vv_attribute6 := 'OUI';
      ELSE
        vv_step := 'Recherche différence au niveau de la commande';
        -- Au niveau de la commande
        SELECT ph.vendor_site_id   AS site_fournisseur,
               ph.ship_to_location_id AS lieu_livraison,
               ph.bill_to_location_id AS lieu_facturation,
               pha.vendor_site_id   AS site_fournisseur_archi,
               pha.ship_to_location_id AS lieu_livraison_archi,
               pha.bill_to_location_id AS lieu_facturation_archi,
               pl.item_description  AS description_contrat,
               pl.quantity  AS montant_annuel,
               pla.item_description AS description_contrat_archi,
               pla.quantity AS montant_annuel_archi
          INTO vv_site_fournisseur,
               vv_lieu_livraison,
               vv_lieu_facturation,
               vv_site_fournisseur_archi,
               vv_lieu_livraison_archi,
               vv_lieu_facturation_archi,
               vv_description_contrat,
               vv_montant_annuel,
               vv_description_contrat_archi,
               vv_montant_annuel_archi
          FROM po_headers_all ph
               ,po_headers_archive_all pha
               ,po_lines_all pl
               ,po_lines_archive_all pla
         WHERE 1 = 1
           AND pha.revision_num = ph.revision_num - 1
           AND ph.po_header_id = pha.po_header_id
           AND ph.po_header_id = pl.po_header_id
           AND pl.po_line_id = pla.po_line_id
           AND pla.latest_external_flag = 'Y'
           AND ph.po_header_id = pn_commande_id;

      vv_step := 'Recherche différence au niveau du contrat';
      -- Au niveau du contrat
      SELECT ph.start_date AS date_debut,
             ph.end_date AS date_fin,
             pha.start_date AS date_debut_archi,
             pha.end_date AS date_fin_archi,
             dcs.ref_contrat_fournisseur ref_contrat_four,
             dcsa.ref_contrat_fournisseur  ref_contrat_four_archi
        INTO vd_date_debut,
             vd_date_fin,
             vd_date_debut_archi,
             vd_date_fin_archi,
             vv_ref_contrat_four,
             vv_ref_contrat_four_archi
        FROM po_headers_all ph
             ,po_headers_archive_all pha
             ,dka_contrat_sstr dcs
             ,dka_contrat_sstr_archi dcsa
       WHERE 1 = 1
         AND pha.revision_num = ph.revision_num - 1
         AND ph.po_header_id = pha.po_header_id
         AND dcs.po_header_id = ph.po_header_id
         AND dcsa.revision_num = dcs.revision_num - 1
         AND dcs.po_header_id = dcsa.po_header_id
         AND ph.po_header_id = pn_contract_id;


    IF ( vv_lieu_facturation <> vv_lieu_facturation_archi
          OR vd_date_debut <> vd_date_debut_archi
          OR vd_date_fin <> vd_date_fin_archi
          OR vv_montant_annuel <> vv_montant_annuel_archi
          OR nvl(vv_ref_contrat_four,'*') <> nvl(vv_ref_contrat_four_archi,'*'))
    THEN
        vb_envoi_bdc := TRUE;
        vv_attribute6 := 'OUI';
    ELSE
        vb_envoi_bdc := FALSE;
    END IF;

       IF vb_envoi_bdc = FALSE  THEN
         vv_step := 'Recherche ajout d''une ligne d''imputation';

           SELECT count(1)
             INTO vn_nbr_ligne_a
             FROM po_distributions_all pda
            WHERE pda.po_header_id = pn_commande_id;

           SELECT count(1)
             INTO vn_nbr_ligne_b
             FROM po_distributions_archive_all pda
            WHERE pda.po_header_id = pn_commande_id
              AND pda.latest_external_flag = 'Y';

            IF vn_nbr_ligne_a <> vn_nbr_ligne_b
            THEN
                vb_envoi_bdc := TRUE;
                vv_attribute6 := 'OUI';
            END IF;

         IF vb_envoi_bdc = FALSE THEN
           vv_step := 'Recherche différence dans po_distribution';

           FOR rec_po_distrib in cur_po_distribution(pn_commande_id)
           LOOP
             IF vb_envoi_bdc = FALSE
               AND rec_po_distrib.quantity_archi <> rec_po_distrib.quantity
             THEN
                  vb_envoi_bdc := TRUE;
                  vv_attribute6 := 'OUI';
             END IF;
           END LOOP;

           IF vb_envoi_bdc = FALSE THEN
              IF (vv_site_fournisseur <> vv_site_fournisseur_archi
                  OR vv_lieu_livraison <> vv_lieu_livraison_archi
                  OR nvl(vv_description_contrat,'*') <> nvl(vv_description_contrat_archi,'*'))
              THEN
                   vb_envoi_bdc := TRUE;
                   vv_attribute6 := 'NON';
              END IF;
           END IF;
         END IF;
    END IF;
    END IF;

   IF vv_attribute6 IS NOT NULL
   THEN
       UPDATE po_headers_all
          SET attribute6 = vv_attribute6
        WHERE po_header_id = pn_commande_id;
   END IF;

  ----- return value -----
  RETURN (vb_envoi_bdc);
  EXCEPTION WHEN others THEN
    -- Pas de modification de cette table
        print_log_message('Erreur lors de : ' || vv_step);
        print_log_message(SQLERRM);
  END test_modif_champ ;

  -------------------------------------------------------------------------------------
  --  Nom           : controle_statut
  --  Description   : Procédure qui récupère le statut du contrat.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE controle_statut(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id    NUMBER;
  vv_statut       po_headers_all.authorization_status%TYPE;

  BEGIN
  -- Récupérer l'identifiant de l'entête du contrat.
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');
    -- Recherche du statut d'authorisation
  SELECT decode(pha.authorization_status,'REQUIRES REAPPROVAL',decode(dcs.commande_id,NULL,'RENOUVELLEMENT',pha.authorization_status),pha.authorization_status)
  INTO vv_statut
  FROM po_headers_all pha, dka_contrat_sstr dcs
  WHERE pha.po_header_id = dcs.po_header_id
    AND pha.po_header_id = vn_contrat_id;

  -- le résultat de sortie correspond au statut du contrat recherché.
  resultout := wf_engine.eng_completed || ':' || vv_statut;
    RETURN;
  END;


  -------------------------------------------------------------------------------------
  --  Nom           : modif_statut_incomplet
  --  Description   : Fonction qui repositionne le statut à REJECTED et FINALLY CLOSED
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE modif_statut_incomplet(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id    NUMBER;
  vn_user_id     NUMBER;

  BEGIN

    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

  vn_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'USER_ID');

   UPDATE po_headers_all
   SET last_update_date = sysdate
     , last_updated_by = vn_user_id
     , authorization_status = 'REJECTED'
     , approved_flag = 'F'
     , closed_date = sysdate
     , closed_code = 'FINALLY CLOSED'
   WHERE po_header_id = vn_contrat_id ;

   INSERT INTO po_action_history
    (object_id,
     object_type_code,
     object_sub_type_code,
     sequence_num,
     last_update_date,
     last_updated_by,
     creation_date,
     created_by,
     action_code,
     action_date,
     employee_id,
     object_revision_num,
     last_update_login,
     request_id,
     program_application_id,
     program_id)
  VALUES(
     vn_contrat_id,
     'PA',
     'CONTRACT',
     (select decode(MAX(SEQUENCE_NUM),NULL,0,MAX(SEQUENCE_NUM))+1 from po_action_history pah where pah.object_id = vn_contrat_id and pah.object_type_code = 'PA' and pah.object_sub_type_code = 'CONTRACT'),
     SYSDATE,
     vn_user_id,
     SYSDATE,
     vn_user_id,
     'FINALLY CLOSE',
     SYSDATE,
     (select fu.employee_id from fnd_user fu where fu.user_id = vn_user_id),
     0,
     -1,
     0,
     0,
     0);

    commit;
  END;

  --------------------------------------------------------------------------------------------------
  --  Nom           : modif_statut_approuve
  --  Description   : Procédure qui modifie le statut de fermeture de l'entête du contrat en CLOSED.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  --------------------------------------------------------------------------------------------------
  PROCEDURE modif_statut_approuve(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id    NUMBER;
  vn_user_id     NUMBER;

  BEGIN
  -- Récupérer l'identifiant de l'entête du contrat.
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

  -- Récupérer l'identifiant de l'utilisateur.
  vn_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'USER_ID');

  -- Mise à jour du statut de fermeture de l'entête du contrat à CLOSED
   UPDATE po_headers_all
   SET last_update_date = sysdate
     , last_updated_by = vn_user_id
     , closed_date = sysdate
     , closed_code = 'CLOSED'
   WHERE po_header_id = vn_contrat_id ;

  -- Insertion de l'historisation des actions dans la table po_action_history
   INSERT INTO po_action_history
    (object_id,
     object_type_code,
     object_sub_type_code,
     sequence_num,
     last_update_date,
     last_updated_by,
     creation_date,
     created_by,
     action_code,
     action_date,
     employee_id,
     note,
     object_revision_num,
     last_update_login,
     request_id,
     program_application_id,
     program_id)
  VALUES(
     vn_contrat_id,
     'PA',
     'CONTRACT',
     (select decode(MAX(SEQUENCE_NUM),NULL,0,MAX(SEQUENCE_NUM))+1 from po_action_history pah where pah.object_id = vn_contrat_id and pah.object_type_code = 'PA' and pah.object_sub_type_code = 'CONTRACT'),
     SYSDATE,
     vn_user_id,
     SYSDATE,
     vn_user_id,
     'CLOSE',
     SYSDATE,
     (select fu.employee_id from fnd_user fu where fu.user_id = vn_user_id),
     decode((select date_resiliation from dka_contrat_sstr where po_header_id = vn_contrat_id),NULL,'Annulation du contrat','Résiliation du contrat'),
     0,
     -1,
     0,
     0,
     0);

    commit;
    resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : verif_date_resiliation
  --  Description   : Procédure qui détermine si une date de résiliation existe pour un contrat.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE verif_date_resiliation(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

  vn_date_resiliation  NUMBER;
  vn_contrat_id        NUMBER;
  BEGIN
  -- Récupérer l'identifiant de l'entête du contrat.
  vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');


  -- Recherche la date de résiliation du contrat.
  SELECT count(1)
  INTO   vn_date_resiliation
  FROM   dka_contrat_sstr dcs
  WHERE  dcs.po_header_id = vn_contrat_id
  AND    dcs.date_resiliation IS NULL;

  -- S'il n'existe pas une date de résiliation alors le résultat de sortie est Oui.
  IF vn_date_resiliation > 0 THEN
    resultout := wf_engine.eng_completed || ':' || 'N';
  -- Sinon le résultat de sortie est à Non.
  ELSE
    resultout := wf_engine.eng_completed || ':' || 'Y';
  END IF;

  END;

  -------------------------------------------------------------------------------------
  --  Nom           : verif_exist_facture
  --  Description   : Procédure qui détermine si une facture existe pour un contrat.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE verif_exist_facture(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

  vn_nbr_facture    NUMBER;
  vn_contrat_id      NUMBER;
  BEGIN

  -- Récupérer l'identifiant de l'entête du contrat.
  vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');


  -- Compter le nombre de facture pour un contrat.
  SELECT  count(1)
  INTO  vn_nbr_facture
    FROM   ap_invoices_all aia,
           ap_invoice_distributions_all aida,
           po_distributions_all pda,
           dka_contrat_sstr dcs
    WHERE   aia.invoice_id = aida.invoice_id
    AND   aida.po_distribution_id = pda.po_distribution_id
    AND   dcs.commande_id = pda.po_header_id
    AND   dcs.po_header_id = vn_contrat_id;

  -- Si il existe des factures alors le resultat en sortie est à 'OUI' et nous modifions l'attribut P_ACTION du Workflow (Paramétrage du mail).
  IF vn_nbr_facture > 0 THEN
    resultout := wf_engine.eng_completed || ':' || 'Y';
    wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'P_ACTION',
                              avalue   => 'ANNULER');
  -- Sinon le resultat de sortie est à 'NON'.
  ELSE
    resultout := wf_engine.eng_completed || ':' || 'N';
  END IF;

  END;


  -------------------------------------------------------------------------------------
  --  Nom           : archivage_date_resiliation
  --  Description   : Fonction qui incrémente de 1 la version du contrat et effectue
  --  l'archivage de la nouvelle version.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE archivage_date_resiliation(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS
    vn_contrat_id        NUMBER;
  vn_user_id         NUMBER;
  vb_archi_headers_all  BOOLEAN;
  pv_errbuf        VARCHAR2(100);
  e_err_archi_headers_all EXCEPTION;
  v_return_status         VARCHAR2(50);
  v_msg_count             NUMBER;
  v_msg_data              VARCHAR2(1000);
  BEGIN
  -- Récupérer l'identifiant de l'entête du contrat.
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

  -- Récupérer l'identifiant de l'utilisateur.
  vn_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'USER_ID');

  -- Incrémenter la version du contrat.
    -- Incrémentation pour la table po_headers_all
    UPDATE po_headers_all
    SET    last_update_date    = sysdate
         ,last_updated_by    = vn_user_id
         ,revision_num       = revision_num + 1
    WHERE  po_header_id     = vn_contrat_id;

    -- Incrémentation pour la table dka_contrat_sstr
    UPDATE   dka_contrat_sstr
    SET   last_update_date   = sysdate
        ,last_updated_by   = vn_user_id
        ,revision_num     = revision_num + 1
    WHERE  po_header_id     = vn_contrat_id;

    -- Incrémentation pour la table dka_contrat_sstr_imputation
    UPDATE dka_contrat_sstr_imputation
    SET    last_update_date   = sysdate
        ,last_updated_by   = vn_user_id
        ,revision_num     = revision_num + 1
    WHERE  po_header_id     = vn_contrat_id;
  commit;
  -- Archivage de la nouvelle version.
    -- Archivage de la version des tables dka_contrat_sstr / dka_contrat_sstr_imputation
      -- Voir procedure archivage_contrat
    -- Archivage de la version de la table po_headers_all
        
      --RBE artf2154499 
      --PO_ARCHIVE_DOCUMENT_SV.Archive_PO(vn_contrat_id, vb_archi_headers_all);

      PO_DOCUMENT_ARCHIVE_PVT.archive_po(p_api_version => 1.0,
            p_document_id           => vn_contrat_id,
            p_document_type         => 'PA',
            p_document_subtype      => 'CONTRACT',
            x_return_status         => v_return_status,
            x_msg_count             => v_msg_count,
            x_msg_data              => v_msg_data);
            
    --IF vb_archi_headers_all = FALSE THEN --RBE artf2154499 
    IF v_return_status != 'S' THEN
      Raise e_err_archi_headers_all;
    END IF;
  EXCEPTION
    WHEN e_err_archi_headers_all THEN
      pv_errbuf  := 'Erreur Archivage du contrat de la table po_headers_all.';
      log_msg(pv_errbuf);
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : approve_version_commande
  --  Description   : Fonction qui réapprouve manuellement les entêtes de commandes.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE approve_version_commande(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS
  vn_contrat_id           NUMBER;
  l_org_id                NUMBER;
  vn_commande_id          NUMBER;
  l_result                BOOLEAN;
  --RBE artf2154499
  v_return_status         VARCHAR2(50);
  v_msg_count             NUMBER;
  v_msg_data              VARCHAR2(1000);
  BEGIN
    -- Récupérer l'identifiant de l'entête du contrat.
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

    vn_commande_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'COMMANDE_ID');

  UPDATE PO_HEADERS_ALL ph
  SET    ph.authorization_status = 'APPROVED',
       ph.approved_flag        = 'Y',
       ph.approved_date        = SYSDATE
  WHERE  ph.po_header_id         = vn_commande_id;

  --RBE artf2154499 
  --PO_ARCHIVE_DOCUMENT_SV.Archive_PO(vn_commande_id, l_result);
    PO_DOCUMENT_ARCHIVE_PVT.archive_po(p_api_version => 1.0,
        p_document_id           => vn_commande_id,
        p_document_type         => 'PO',
        p_document_subtype      => 'STANDARD',
        x_return_status         => v_return_status,
        x_msg_count             => v_msg_count,
        x_msg_data              => v_msg_data);

  commit;

    SELECT org_id
    INTO l_org_id
    FROM po_headers_all
    WHERE po_header_id = vn_commande_id;

  wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ORG_ID',
                              avalue   => l_org_id);

  wf_engine.setitemattrnumber(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'DOCUMENT_ID',
                              avalue   => vn_commande_id);
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : mise_a_jour_action_noneffec
  --  Description   : Fonction qui met à jour de l'attribut P_ACTION à NON_EFFECTUER
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE mise_a_jour_action_noneffec(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS
  BEGIN
    -- Affectation de la valeur 'NON_EFFECTUER' à l'attribut 'P_ACTION'.
    wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'P_ACTION',
                              avalue   => 'NON_EFFECTUER');
  END;


  -------------------------------------------------------------------------------------
  --  Nom           : mise_a_jour_action_resiliation
  --  Description   : Fonction qui met à jour de l'attribut P_ACTION à RESILIER
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE mise_a_jour_action_resiliation(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS
  BEGIN
    -- Affectation de la valeur 'RESILIER' à l'attribut 'P_ACTION'.
    wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'P_ACTION',
                              avalue   => 'RESILIER');
  END;


  -------------------------------------------------------------------------------------
  --  Nom           : mise_a_jour_statut_appro
  --  Description   : Repositionner le contrat dans sa version précédente approuvée pour
  --                  annuler le processus de renouvellement.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE mise_a_jour_statut_appro(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id    NUMBER;
  vn_user_id     NUMBER;

  BEGIN

    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

  vn_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'USER_ID');

  UPDATE po_headers_all pha
  SET last_update_date = sysdate
    , last_updated_by = vn_user_id
    , start_date = (select start_date from po_headers_archive_all where po_header_id = pha.po_header_id and revision_num = pha.revision_num-1)
    , end_date = (select end_date from po_headers_archive_all where po_header_id = pha.po_header_id and revision_num = pha.revision_num-1)
    , authorization_status = 'APPROVED'
    , revision_num = (select revision_num from po_headers_archive_all where po_header_id = pha.po_header_id and revision_num = pha.revision_num-1)
    , approved_flag = 'Y'
    , approved_date = (select approved_date from po_headers_archive_all where po_header_id = pha.po_header_id and revision_num = pha.revision_num-1)
    , blanket_total_amount = (select blanket_total_amount from po_headers_archive_all where po_header_id = pha.po_header_id and revision_num = pha.revision_num-1)
  WHERE pha.po_header_id = vn_contrat_id;

  UPDATE dka_contrat_sstr dcs
  SET commande_id = (select commande_id from dka_contrat_sstr_archi dsca
             where dsca.po_header_id = dcs.po_header_id and dsca.revision_num = dcs.revision_num-1)
  ,commande_version = (select commande_version from dka_contrat_sstr_archi dsca
             where dsca.po_header_id = dcs.po_header_id and dsca.revision_num = dcs.revision_num-1)
  ,revision_num = (select revision_num from dka_contrat_sstr_archi dsca
             where dsca.po_header_id = dcs.po_header_id and dsca.revision_num = dcs.revision_num-1)
  ,reconduction_num = (select reconduction_num from dka_contrat_sstr_archi dsca
             where dsca.po_header_id = dcs.po_header_id and dsca.revision_num = dcs.revision_num-1)
  ,date_effet = (select date_effet from dka_contrat_sstr_archi dsca
             where dsca.po_header_id = dcs.po_header_id and dsca.revision_num = dcs.revision_num-1)
  WHERE po_header_id = vn_contrat_id;

  UPDATE dka_contrat_sstr_imputation dcs
  SET revision_num = (select distinct revision_num from dka_contrat_sstr_imput_archi dsca
             where dsca.po_header_id = dcs.po_header_id and dsca.revision_num = dcs.revision_num-1)
  WHERE po_header_id = vn_contrat_id;

    commit;
  END;


  -----------------------------------------------------------------------------------------------------
  --  Nom           : action_fermer
  --  Description   : Positionnement du contrat au statut "Fermé" avec le motif "Annulation du contrat"
  --
  --  PARAMETRES : paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -----------------------------------------------------------------------------------------------------
  PROCEDURE action_fermer(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id    NUMBER;
  vn_user_id     NUMBER;

  BEGIN

  vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

  vn_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'USER_ID');

  UPDATE po_headers_all
  SET last_update_date = sysdate
     , last_updated_by = vn_user_id
     , closed_date = sysdate
     , closed_code = 'CLOSED'
  WHERE po_header_id = vn_contrat_id;

  INSERT INTO po_action_history
    (object_id,
     object_type_code,
     object_sub_type_code,
     sequence_num,
     last_update_date,
     last_updated_by,
     creation_date,
     created_by,
     action_code,
     action_date,
     note,
     employee_id,
     object_revision_num,
     last_update_login,
     request_id,
     program_application_id,
     program_id)
  VALUES(
     vn_contrat_id,
     'PA',
     'CONTRACT',
     (select decode(MAX(SEQUENCE_NUM),NULL,0,MAX(SEQUENCE_NUM))+1 from po_action_history pah where pah.object_id = vn_contrat_id and pah.object_type_code = 'PA' and pah.object_sub_type_code = 'CONTRACT'),
     SYSDATE,
     vn_user_id,
     SYSDATE,
     vn_user_id,
     'CLOSE',
     SYSDATE,
     'Annulation du contrat',
     (select fu.employee_id from fnd_user fu where fu.user_id = vn_user_id),
     0,
     -1,
     0,
     0,
     0);

  wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'P_ACTION',
                              avalue   => 'RENOUVELER');
    commit;
  END;


  -------------------------------------------------------------------------------------
  --  Nom           : modif_statut_nouvelle_appro
  --  Description   : Fonction qui repositionne le statut en nouvelle approbation requise
  --                : afin qu'il puisse être à nouveau accessible par le bouton "Modifier"
  --
  --  PARAMETRES : paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE modif_statut_nouvelle_appro(itemtype  IN VARCHAR2,
                         itemkey   IN VARCHAR2,
                         actid     IN NUMBER,
                         funcmode  IN VARCHAR2,
                         resultout OUT NOCOPY VARCHAR2) IS

    vn_contrat_id    NUMBER;

  BEGIN

    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');
    -- Recherche du statut d'authorisation
    UPDATE po_headers_all SET authorization_status = decode(Revision_Num,0,'INCOMPLETE','REQUIRES REAPPROVAL') WHERE po_header_id = vn_contrat_id;
      wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'P_ACTION',
                              avalue   => 'REJET');
    commit;
  END;


  ------------------------------------------------------------------------------------------------------------
  --  Nom           : annuler_commande_sans_facture
  --  Description   : Fonction qui met à jour les tables po_headers_all / po_lines_all / po_line_locations_all
  --                : afin d'annuler la commande au niveau en-tête pour les commande ne possédant
  --                : aucune facture.
  --
  --  PARAMETRES : paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  ------------------------------------------------------------------------------------------------------------
  PROCEDURE annuler_commande_sans_facture(itemtype  IN VARCHAR2,
                         itemkey   IN VARCHAR2,
                         actid     IN NUMBER,
                         funcmode  IN VARCHAR2,
                         resultout OUT NOCOPY VARCHAR2) IS

  id_commande      NUMBER;
  vn_user_id       NUMBER;
  vn_contrat_id    NUMBER;
  l_org_id         po_headers_all.org_id%type;

  BEGIN

    vn_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'USER_ID');


    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');


    SELECT dcs.commande_id
    INTO id_commande
    FROM dka_contrat_sstr dcs
    WHERE dcs.po_header_id = vn_contrat_id;


    UPDATE po_headers_all
    SET cancel_flag = 'Y'
    , closed_code = 'FINALLY CLOSED'
    , closed_date = sysdate
    , last_update_date = sysdate
    , last_updated_by = vn_user_id
    WHERE po_header_id = id_commande;


    UPDATE po_lines_all
    SET cancel_flag = 'Y'
    , cancelled_by = vn_user_id
    , cancel_date = sysdate
    , cancel_reason = 'Annulation du contrat SSTR'
    , closed_code = 'FINALLY CLOSED'
    , closed_date = sysdate
    , last_update_date = sysdate
    , last_updated_by = vn_user_id
    , quantity = 0
    WHERE po_header_id = id_commande;


    UPDATE po_line_locations_all
    SET cancel_flag = 'Y'
    , cancelled_by = vn_user_id
    , cancel_date = sysdate
    , cancel_reason = 'Annulation du contrat SSTR'
    , closed_code = 'FINALLY CLOSED'
    , closed_date = sysdate
    , last_update_date = sysdate
    , last_updated_by = vn_user_id
    , quantity_received = 0
    , quantity_cancelled = quantity
    WHERE po_header_id = id_commande;

  SELECT org_id
  INTO   l_org_id
    FROM   po_headers_all
    WHERE  po_header_id = id_commande;

    wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'ORG_ID',
                              avalue   => l_org_id);

  wf_engine.setitemattrnumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'DOCUMENT_ID',
                                avalue   => id_commande);

    wf_engine.setitemattrnumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'COMMANDE_ID',
                                avalue   => id_commande);

    wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'P_ACTION',
                              avalue   => 'FERMER');
  END;


  ----------------------------------------------------------------------------
  --  Nom           : LOG_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   pv_message      texte a imprimer dans le log
  --
  ----------------------------------------------------------------------------
    PROCEDURE log_msg(pv_message in varchar2) IS
      l_message VARCHAR2(1000);
    BEGIN

      l_message := SUBSTR(pv_message, 1, 1000);

      IF (l_message IS NULL) THEN
        l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
      END IF;

      fnd_file.put_line(fnd_file.LOG, l_message);
      --dbms_output.put_line('LOG : '||substr(l_message,1,253));
    END log_msg;


  ----------------------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : Procedure d'initialisation
  --
  --  PARAMETRES :
  --  pv_errbuf   Entree/Sortie          message d'erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) IS
      l_param           VARCHAR2(100);
      rec_param         dka_parameters%ROWTYPE;
      e_err_param       EXCEPTION;
    gv_base             VARCHAR2(50);
    BEGIN
      gn_erreur := 0;
      gn_erreur_avert := 0;
    gn_erreur_search := 0;
      IF pn_retcode != 0 THEN
        RAISE e_err_param;
      END IF;
    --Récupération du nom de la base de données concernée
      BEGIN
        SELECT name
        INTO gv_base
        FROM v$database;
      EXCEPTION
          WHEN OTHERS THEN
              pv_errbuf := 'ERREUR lors de la recherche du nom de la base de données';
              pn_retcode := 2;
              RAISE;
      END;

      --Recuperation des parametres de connexion
      l_param := 'SMTP_CONNECTION';
    IF gv_base = 'DT1OAP' THEN
      gv_conn := 'kriek.nord-est.capgemini.fr';
    ELSE
    Dka_Tools_Pkg.get_parameter ('SPORES_CONTRAT', 'SMTP_CONNECTION', rec_param, pv_errbuf, pn_retcode);
    gv_conn := rec_param.varchar2_value;
    END IF;
      log_msg('Connexion SMTP : '||gv_conn);
      IF pn_retcode != 0 THEN
        RAISE e_err_param;
      END IF;

      --Recuperation du nombre de reconduction max
      l_param := 'EXPEDITEUR_MAIL';
      Dka_Tools_Pkg.get_parameter ('SPORES_CONTRAT', 'EXPEDITEUR_MAIL', rec_param, pv_errbuf, pn_retcode);
      gv_expediteur := rec_param.varchar2_value;
      log_msg('Expediteur mail : '||gv_expediteur);

      IF pn_retcode != 0 THEN
        RAISE e_err_param;
      END IF;

    EXCEPTION
      WHEN e_err_param THEN
         pv_errbuf  := 'Erreur parametre '||l_param||' : '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
      WHEN OTHERS THEN
         pv_errbuf  := 'Erreur procedure INIT '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
    END init;


  -------------------------------------------------------------------------------------
  --  Nom           : GET_MESSAGE
  --  Description   : procedure de recuperation des messages
  --
  --  PARAMETRES    :
  --  pn_header_id IN       identifiant du contrat
  --  pv_entete    OUT      message de l'entete
  --  pv_haut_page OUT      message de haut de page
  --  pv_body      OUT      message de corps
  --  pv_pied_page OUT      message de pied de page
  --  pv_errbuf    IN OUT   message de sortie
  --  pn_retcode   OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  --------------------------------------------------------------------------------------
   PROCEDURE get_message_mail (
    pv_header_id    IN     NUMBER,
    pv_action       IN     VARCHAR2,
    pv_entete       OUT    VARCHAR2,
    pv_haut_page    OUT    VARCHAR2,
    pv_body         OUT    VARCHAR2,
    pv_pied_page    OUT    VARCHAR2,
    pv_errbuf       OUT    VARCHAR2,
    pn_retcode      OUT    NUMBER
   ) IS
   -- Variable sur le Contrat
     Num_Contrat      po_headers_all.segment1%TYPE;
   Montant_Contrat    po_headers_all.Blanket_Total_Amount%TYPE;
   Date_Effet        dka_contrat_sstr.date_effet%TYPE;
   Num_Fournisseur    po_vendors.segment1%TYPE;
   Name_Fournisseur    po_vendors.vendor_name%TYPE;
   Ref_Fournisseur    dka_contrat_sstr.ref_contrat_fournisseur%TYPE;
   Description_Contrat  dka_contrat_sstr.description_specifique_contrat%TYPE;
   Date_Deb_Periode    po_headers_all.start_date%TYPE;
   Date_Fin_Periode    po_headers_all.end_date%TYPE;
   Nb_Reconduction    dka_contrat_sstr.nb_reconduction%TYPE;
   Num_Reconduction    dka_contrat_sstr.reconduction_num%TYPE;
   Date_Deb_Contrat    DATE;
   Date_Fin_Contrat    DATE;
   Date_Resiliation    DATE;
   -- Variable sur la Commande
   Commande         po_headers_all.segment1%TYPE;
   Creation_Id       po_headers_all.creation_date%TYPE;
   Statut_Approbation   po_headers_all.authorization_status%TYPE;
   Statut_Fermeture     po_headers_all.closed_code%TYPE;
   Montant        po_lines_all.unit_price%TYPE;
   Periode_Debut       po_headers_all.start_date%TYPE;
   Periode_Fin       po_headers_all.end_date%TYPE;

   -- Variable sur les Factures
   Blocage        NUMBER;

   -- Variable Body Out
   pv_body_contrat      VARCHAR2(2000);
   pv_body_commande_entete  VARCHAR2(2000);
   pv_body_commande      VARCHAR2(2000);
   pv_body_facture_entete    VARCHAR2(2000);
   pv_body_facture      VARCHAR2(2000);
   pv_body_project_entete    VARCHAR2(2000);
   pv_body_project    VARCHAR2(2000);
   
   -- Variable sur le Montant recalculer
   Montant_Recalculer  po_lines_all.unit_price%TYPE;
   CONTRAT_IMPUTATION_ID dka_contrat_sstr_imputation.contrat_imputation_id%TYPE;

   -- RECHERCHE DES FACTURES
    --SELECT   aia.invoice_num,
    --    aia.invoice_date,
    --    aia.gl_date,
    --    aia.invoice_amount,
    --    aia.amount_paid,
    --    count(ahv.invoice_id)
    --INTO     Num_Fact,
    --    Date_Fact,
    --    Date_Gl,
    --    Montant_Fact,
    --    Montant_Paye,
    --    Blocage
    --FROM   ap_invoices_all aia,
    --    ap_invoice_distributions_all aida,
    --    po_distributions_all pda,
    --    ap_holds_v ahv
    --WHERE   aia.invoice_id = aida.invoice_id
    --AND   aida.po_distribution_id = pda.po_distribution_id
    --AND   ahv.invoice_id = aia.invoice_id
    --AND   ahv.release_date IS NULL
    --AND   pda.po_header_id = pv_header_id
    --GROUP BY aia.invoice_num,
    --     aia.invoice_date,
    --     aia.gl_date,
    --     aia.invoice_amount,
    --     aia.amount_paid;

  CURSOR Cur_Factures IS
    SELECT   aia.invoice_num Num_Fact,
        aia.invoice_date Date_Fact,
        aia.gl_date Date_Gl,
        aia.invoice_amount Montant_Fact,
        decode(aia.amount_paid,NULL,0,aia.amount_paid) Montant_Paye
    FROM   ap_invoices_all aia,
        ap_invoice_distributions_all aida,
        po_distributions_all pda,
        dka_contrat_sstr dcs
    WHERE   aia.invoice_id = aida.invoice_id
    AND     aida.po_distribution_id = pda.po_distribution_id
    AND     dcs.commande_id = pda.po_header_id
    AND     dcs.po_header_id = pv_header_id
    GROUP BY aia.invoice_num,
         aia.invoice_date,
         aia.gl_date,
         aia.invoice_amount,
         aia.amount_paid;
  Rec_Factures                    Cur_Factures%ROWTYPE;
     
     -- Curseur de recherche des codes projets concernés par le contrat avec leur description. --
     CURSOR Cur_Projects IS
       SELECT    ppa.segment1, -- code projet
                ppa.description -- description projet
       FROM        dka_contrat_sstr_imputation dcsi, pa_projects_all ppa
       WHERE    ppa.project_id = dcsi.project_id
       AND        dcsi.po_header_id = pv_header_id;
     
     Rec_Projects                    Cur_Projects%ROWTYPE;
      
   BEGIN
      SELECT pha.segment1,
        pha.Blanket_Total_Amount,
      dcs.date_effet,
      pv.segment1,
      pv.vendor_name,
      dcs.ref_contrat_fournisseur,
      dcs.description_specifique_contrat,
      pha.start_date,
      pha.end_date,
      dcs.nb_reconduction,
      dcs.reconduction_num,
      dcs.date_resiliation
   INTO  Num_Contrat,
      Montant_Contrat,
      Date_Effet,
      Num_Fournisseur,
      Name_Fournisseur,
      Ref_Fournisseur,
      Description_Contrat,
      Date_Deb_Periode,
      Date_Fin_Periode,
      Nb_Reconduction,
      Num_Reconduction,
      Date_Resiliation
   FROM   po_headers_all pha,
        po_vendors pv,
        dka_contrat_sstr dcs
   WHERE  pha.vendor_id = pv.vendor_id
   AND    dcs.po_header_id = pha.po_header_id
   AND    pha.po_header_id    = pv_header_id;

   DKA_SPOCONTRAT_SSTR_PKG.get_contrat_end_date(pv_header_id,Date_Fin_Periode,Nb_Reconduction,Num_Reconduction,Date_Fin_Contrat,pn_retcode,pv_errbuf);

   DKA_SPOCONTRAT_SSTR_PKG.get_contrat_start_date(pv_header_id,Date_Deb_Periode,Num_Reconduction,Date_Deb_Contrat,pn_retcode,pv_errbuf);

   if pv_action = 'REJET' THEN
        --GET MESSAGE
     pv_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_REJET_TITRE',
                        'NO_CONTRAT',Num_Contrat);

     pv_haut_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_REJET_CORPS');

     pv_body := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_CONTRAT',
                        'NO_CONTRAT',Num_Contrat,
                        'REF_FOURNISSEUR',Ref_Fournisseur,
                        'NUM_FOURNISSEUR',Num_Fournisseur,
                        'NOM_FOURNISSEUR',Name_Fournisseur,
                        'MONTANT_CONTRAT',Montant_Contrat,
                        'DATE_EFFET',Date_Effet,
                        'DESCRIPTION_CONTRAT',Description_Contrat,
                        'DATE_DEB_CONTRAT',Date_Deb_Contrat,
                        'DATE_FIN_CONTRAT',Date_Fin_Contrat);

     pv_pied_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_REJET_FIN');
  ELSE
        -- RECHERCHE DES COMMANDES
    SELECT   pha_commande.segment1,
        pha_commande.creation_date,
        pha_commande.authorization_status,
        pha_commande.closed_code,
        pla.unit_price * pla.quantity,
        pha_contrat.start_date,
        pha_contrat.end_date
    INTO  Commande,
        Creation_Id,
        Statut_Approbation,
        Statut_Fermeture,
        Montant,
        Periode_Debut,
        Periode_Fin
    FROM     po_headers_all pha_commande,
        po_headers_all pha_contrat,
        dka_contrat_sstr dcs,
        po_lines_all pla
    WHERE    dcs.commande_id  = pha_commande.po_header_id
    AND      dcs.po_header_id = pha_contrat.po_header_id
    AND      pha_commande.po_header_id     = pla.po_header_id
    AND      pha_contrat.po_header_id = pv_header_id;

    IF pv_action = 'RENOUVELER' THEN
              --GET MESSAGE
       pv_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_RENOU_TITRE',
                          'NO_CONTRAT',Num_Contrat);

       pv_haut_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_RENOU_CORPS');

       pv_body_contrat := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_CONTRAT',
                          'NO_CONTRAT',Num_Contrat,
                          'REF_FOURNISSEUR',Ref_Fournisseur,
                          'NUM_FOURNISSEUR',Num_Fournisseur,
                          'NOM_FOURNISSEUR',Name_Fournisseur,
                          'MONTANT_CONTRAT',Montant_Contrat,
                          'DATE_EFFET',Date_Effet,
                          'DESCRIPTION_CONTRAT',Description_Contrat,
                          'DATE_DEB_CONTRAT',Date_Deb_Contrat,
                          'DATE_FIN_CONTRAT',Date_Fin_Contrat);
                          
       pv_body_project_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_PROJECT_EN');
       
       pv_body := pv_body_contrat || utl_tcp.CRLF || pv_body_project_entete;
       
       OPEN Cur_Projects;
        LOOP
        FETCH Cur_Projects INTO Rec_Projects;
        EXIT WHEN Cur_Projects%NOTFOUND;
          pv_body_project := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_PROJECT',
                              'CODE_PROJ',Rec_Projects.segment1,
                              'DESC_PROJ',Rec_Projects.description);
          
          pv_body := pv_body || utl_tcp.CRLF || pv_body_project;
        END LOOP;
       CLOSE Cur_Projects;
       
       pv_body := pv_body || '</TABLE>';
       
       pv_body_commande_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE_EN');

       pv_body_commande := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE',
                           'NO_COMMANDE',Commande,
                           'DATE_COMMANDE',Creation_Id,
                           'STATUT_APPRO',Statut_Approbation,
                           'STATUT_FERME',Statut_Fermeture,
                           'DATE_DEB_PERIODE',Periode_Debut,
                           'DATE_FIN_PERIODE',Periode_Fin,
                           'MONTANT',Montant);

       pv_body_facture_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE_EN');

       pv_body := pv_body || utl_tcp.CRLF || pv_body_commande_entete || utl_tcp.CRLF || pv_body_commande || utl_tcp.CRLF || pv_body_facture_entete;
       OPEN Cur_Factures;
        LOOP
        FETCH Cur_Factures INTO Rec_Factures;
        EXIT WHEN Cur_Factures%NOTFOUND;
           SELECT  count(ahv.invoice_id)
           INTO    Blocage
           FROM    ap_invoices_all aia,
                   ap_invoice_distributions_all aida,
                   po_distributions_all pda,
                   dka_contrat_sstr dcs,
                   ap_holds_v ahv
           WHERE   aia.invoice_id = aida.invoice_id
           AND     aida.po_distribution_id = pda.po_distribution_id
           AND     dcs.commande_id = pda.po_header_id
           AND     dcs.po_header_id = pv_header_id
           AND     ahv.invoice_id = aia.invoice_id
           AND     aia.invoice_num = Rec_Factures.Num_Fact
           AND     ahv.release_date IS NULL;

           pv_body_facture := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE',
                              'NUM_FACT',Rec_Factures.Num_Fact,
                              'DATE_FACT',Rec_Factures.Date_Fact,
                              'DATE_GL',Rec_Factures.Date_Gl,
                              'MONTANT_FACT',Rec_Factures.Montant_Fact,
                              'MONTANT_PAYE',Rec_Factures.Montant_Paye,
                              'NBR_BLOCAGE',Blocage);
           pv_body := pv_body || utl_tcp.CRLF || pv_body_facture;
        END LOOP;
       CLOSE Cur_Factures;
       pv_body := pv_body || '</TABLE></TABLE><br />';
       pv_pied_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FER_FIN');

  ELSIF pv_action = 'ANNULER' THEN
    pv_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_ANN_TITRE',
                        'NO_CONTRAT',Num_Contrat);


    pv_haut_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_ANN_CORPS');

    pv_body_contrat := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_CONTRAT',
                            'NO_CONTRAT',Num_Contrat,
                            'REF_FOURNISSEUR',Ref_Fournisseur,
                            'NUM_FOURNISSEUR',Num_Fournisseur,
                            'NOM_FOURNISSEUR',Name_Fournisseur,
                            'MONTANT_CONTRAT',Montant_Contrat,
                            'DATE_EFFET',Date_Effet,
                            'DESCRIPTION_CONTRAT',Description_Contrat,
                            'DATE_DEB_CONTRAT',Date_Deb_Contrat,
                            'DATE_FIN_CONTRAT',Date_Fin_Contrat);

    pv_body_commande_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE_EN');

    pv_body_commande := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE',
                             'NO_COMMANDE',Commande,
                             'DATE_COMMANDE',Creation_Id,
                             'STATUT_APPRO',Statut_Approbation,
                             'STATUT_FERME',Statut_Fermeture,
                             'DATE_DEB_PERIODE',Periode_Debut,
                             'DATE_FIN_PERIODE',Periode_Fin,
                             'MONTANT',Montant);

    pv_body_facture_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE_EN');

    pv_body := pv_body_contrat || utl_tcp.CRLF || pv_body_commande_entete || utl_tcp.CRLF || pv_body_commande || utl_tcp.CRLF || pv_body_facture_entete;

    OPEN Cur_Factures;
         LOOP
            FETCH Cur_Factures INTO Rec_Factures;
            EXIT WHEN Cur_Factures%NOTFOUND;
           SELECT  count(ahv.invoice_id)
           INTO    Blocage
           FROM    ap_invoices_all aia,
                   ap_invoice_distributions_all aida,
                   po_distributions_all pda,
                   dka_contrat_sstr dcs,
                   ap_holds_v ahv
           WHERE   aia.invoice_id = aida.invoice_id
           AND     aida.po_distribution_id = pda.po_distribution_id
           AND     dcs.commande_id = pda.po_header_id
           AND     dcs.po_header_id = pv_header_id
           AND     ahv.invoice_id = aia.invoice_id
           AND     aia.invoice_num = Rec_Factures.Num_Fact
           AND     ahv.release_date IS NULL;
         pv_body_facture := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE',
                            'NUM_FACT',Rec_Factures.Num_Fact,
                            'DATE_FACT',Rec_Factures.Date_Fact,
                            'DATE_GL',Rec_Factures.Date_Gl,
                            'MONTANT_FACT',Rec_Factures.Montant_Fact,
                            'MONTANT_PAYE',Rec_Factures.Montant_Paye,
                            'NBR_BLOCAGE',Blocage);
         pv_body := pv_body || utl_tcp.CRLF || pv_body_facture;
     END LOOP;
        CLOSE Cur_Factures;
        pv_body := pv_body || '</TABLE></TABLE><br />';

    pv_pied_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FER_FIN');
  ELSIF pv_action = 'RESILIER' THEN
    pv_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_NEF_TITRE',
                        'NO_CONTRAT',Num_Contrat);

    pv_haut_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_RES_CORPS',
                          'DATE_RESILIATION', Date_Resiliation);

    pv_body_contrat := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_CONTRAT',
                            'NO_CONTRAT',Num_Contrat,
                            'REF_FOURNISSEUR',Ref_Fournisseur,
                            'NUM_FOURNISSEUR',Num_Fournisseur,
                            'NOM_FOURNISSEUR',Name_Fournisseur,
                            'MONTANT_CONTRAT',Montant_Contrat,
                            'DATE_EFFET',Date_Effet,
                            'DESCRIPTION_CONTRAT',Description_Contrat,
                            'DATE_DEB_CONTRAT',Date_Deb_Contrat,
                            'DATE_FIN_CONTRAT',Date_Fin_Contrat);

    pv_body_commande_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE_EN');

    pv_body_commande := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE',
                             'NO_COMMANDE',Commande,
                             'DATE_COMMANDE',Creation_Id,
                             'STATUT_APPRO',Statut_Approbation,
                             'STATUT_FERME',Statut_Fermeture,
                             'DATE_DEB_PERIODE',Periode_Debut,
                             'DATE_FIN_PERIODE',Periode_Fin,
                             'MONTANT',Montant);

    pv_body_facture_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE_EN');

    pv_body := pv_body_contrat || utl_tcp.CRLF || pv_body_commande_entete || utl_tcp.CRLF || pv_body_commande || utl_tcp.CRLF || pv_body_facture_entete;

    OPEN Cur_Factures;
         LOOP
            FETCH Cur_Factures INTO Rec_Factures;
            EXIT WHEN Cur_Factures%NOTFOUND;
           SELECT  count(ahv.invoice_id)
           INTO    Blocage
           FROM    ap_invoices_all aia,
                   ap_invoice_distributions_all aida,
                   po_distributions_all pda,
                   dka_contrat_sstr dcs,
                   ap_holds_v ahv
           WHERE   aia.invoice_id = aida.invoice_id
           AND     aida.po_distribution_id = pda.po_distribution_id
           AND     dcs.commande_id = pda.po_header_id
           AND     dcs.po_header_id = pv_header_id
           AND     ahv.invoice_id = aia.invoice_id
           AND     aia.invoice_num = Rec_Factures.Num_Fact
           AND     ahv.release_date IS NULL;
         pv_body_facture := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE',
                            'NUM_FACT',Rec_Factures.Num_Fact,
                            'DATE_FACT',Rec_Factures.Date_Fact,
                            'DATE_GL',Rec_Factures.Date_Gl,
                            'MONTANT_FACT',Rec_Factures.Montant_Fact,
                            'MONTANT_PAYE',Rec_Factures.Montant_Paye,
                            'NBR_BLOCAGE',Blocage);
         pv_body := pv_body || utl_tcp.CRLF || pv_body_facture;
     END LOOP;
        CLOSE Cur_Factures;
    pv_body := pv_body || '</TABLE></TABLE><br />';
    pv_pied_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FER_FIN');

  ELSIF pv_action = 'NON_EFFECTUER' THEN
    SELECT dcsi.contrat_imputation_id             -- Numero de ligne
     INTO   CONTRAT_IMPUTATION_ID
     FROM   dka_contrat_sstr_imputation dcsi
     WHERE  dcsi.po_header_id = pv_header_id;

    Montant_Recalculer := dka_spowfmaster_pkg.get_montant_imput(CONTRAT_IMPUTATION_ID);

    pv_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_NEF_TITRE',
                        'NO_CONTRAT',Num_Contrat);

    pv_haut_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_NEF_CORPS',
                            'DATE_RESILIATION',Date_Resiliation,
                            'MONTANT_COMMANDE',Montant_Recalculer);

    pv_body_contrat := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_CONTRAT',
                            'NO_CONTRAT',Num_Contrat,
                            'REF_FOURNISSEUR',Ref_Fournisseur,
                            'NUM_FOURNISSEUR',Num_Fournisseur,
                            'NOM_FOURNISSEUR',Name_Fournisseur,
                            'MONTANT_CONTRAT',Montant_Contrat,
                            'DATE_EFFET',Date_Effet,
                            'DESCRIPTION_CONTRAT',Description_Contrat,
                            'DATE_DEB_CONTRAT',Date_Deb_Contrat,
                            'DATE_FIN_CONTRAT',Date_Fin_Contrat);

    pv_body_commande_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE_EN');

    pv_body_commande := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE_NE',
                             'NO_COMMANDE',Commande,
                             'DATE_COMMANDE',Creation_Id,
                             'STATUT_APPRO',Statut_Approbation,
                             'STATUT_FERME',Statut_Fermeture,
                             'DATE_DEB_PERIODE',Periode_Debut,
                             'DATE_FIN_PERIODE',Periode_Fin,
                             'MONTANT',Montant_Recalculer);

    pv_body_facture_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE_EN');

    pv_body := pv_body_contrat || utl_tcp.CRLF || pv_body_commande_entete || utl_tcp.CRLF || pv_body_commande || utl_tcp.CRLF || pv_body_facture_entete;

    OPEN Cur_Factures;
         LOOP
            FETCH Cur_Factures INTO Rec_Factures;
            EXIT WHEN Cur_Factures%NOTFOUND;
           SELECT  count(ahv.invoice_id)
           INTO    Blocage
           FROM    ap_invoices_all aia,
                   ap_invoice_distributions_all aida,
                   po_distributions_all pda,
                   dka_contrat_sstr dcs,
                   ap_holds_v ahv
           WHERE   aia.invoice_id = aida.invoice_id
           AND     aida.po_distribution_id = pda.po_distribution_id
           AND     dcs.commande_id = pda.po_header_id
           AND     dcs.po_header_id = pv_header_id
           AND     ahv.invoice_id = aia.invoice_id
           AND     aia.invoice_num = Rec_Factures.Num_Fact
           AND     ahv.release_date IS NULL;
         pv_body_facture := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FACTURE',
                            'NUM_FACT',Rec_Factures.Num_Fact,
                            'DATE_FACT',Rec_Factures.Date_Fact,
                            'DATE_GL',Rec_Factures.Date_Gl,
                            'MONTANT_FACT',Rec_Factures.Montant_Fact,
                            'MONTANT_PAYE',Rec_Factures.Montant_Paye,
                            'NBR_BLOCAGE',Blocage);
         pv_body := pv_body || utl_tcp.CRLF || pv_body_facture;
     END LOOP;
        CLOSE Cur_Factures;
    pv_body := pv_body || '</TABLE></TABLE><br />';
    pv_pied_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FER_FIN');
  ELSIF pv_action = 'FERMER' THEN
    pv_entete := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FER_TITRE',
                        'NO_CONTRAT',Num_Contrat,'NO_COMMANDE',Commande);

    pv_haut_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FER_CORPS');

    pv_body_contrat := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_CONTRAT',
                            'NO_CONTRAT',Num_Contrat,
                            'REF_FOURNISSEUR',Ref_Fournisseur,
                            'NUM_FOURNISSEUR',Num_Fournisseur,
                            'NOM_FOURNISSEUR',Name_Fournisseur,
                            'MONTANT_CONTRAT',Montant_Contrat,
                            'DATE_EFFET',Date_Effet,
                            'DESCRIPTION_CONTRAT',Description_Contrat,
                            'DATE_DEB_CONTRAT',Date_Deb_Contrat,
                            'DATE_FIN_CONTRAT',Date_Fin_Contrat);

    pv_body_commande := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_COMMANDE',
                             'NO_COMMANDE',Commande,
                             'DATE_COMMANDE',Creation_Id,
                             'STATUT_APPRO',Statut_Approbation,
                             'STATUT_FERME',Statut_Fermeture,
                             'DATE_DEB_PERIODE',Periode_Debut,
                             'DATE_FIN_PERIODE',Periode_Fin,
                             'MONTANT',Montant);

    pv_body := pv_body_contrat || utl_tcp.CRLF || pv_body_commande_entete || utl_tcp.CRLF || pv_body_commande || utl_tcp.CRLF || pv_body_facture_entete || '</TABLE><br />';

    pv_pied_page := Dka_Tools_Pkg.get_message('DKA','DKA_SPOWFMASTER_FERM_FIN');
    END IF;

  END IF;

   EXCEPTION
    WHEN OTHERS THEN
     pv_errbuf  := 'Erreur procedure GET_MESSAGE '|| SQLERRM;
     pn_retcode := 2;
     log_msg(pv_errbuf);

   END get_message_mail;


  -------------------------------------------------------------------------------------
  --  Nom           : SEARCH_ID_DESTINATAIRE_MAIL
  --  Description   : Recherche des adresses mails et des noms des destinataires/
  --
  --  PARAMETRES    :
  --
  --  pv_header_id  Identifiant de l'entête
  --  pv_mail_name  Liste des mails et des noms des destinataires concaténés
  --  pv_name       Liste des noms des destinataires concaténés
  --  pv_errbuf     Sortie
  --  pn_retcode    Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 1: erreur ou code erreur ORA
  --------------------------------------------------------------------------------------
  PROCEDURE search_id_destinataire_mail (
    pv_header_id  IN  NUMBER,
    pv_entete    IN  VARCHAR2,
    pv_haut_page  IN  VARCHAR2,
    pv_body      IN  VARCHAR2,
    pv_pied_page  IN  VARCHAR2,
    pv_action     IN  VARCHAR2,
    pv_errbuf     OUT VARCHAR2,
    pn_retcode    OUT NUMBER
    ) IS
  Id_Createur            fnd_user.employee_id%TYPE;
  Id_Gestionnaire        dka_contrat_sstr.signataire_contrat%TYPE;
  Id_Correspondant_Sstr  fnd_flex_values.attribute1%TYPE;
  Id_Correspondant_Csp   fnd_flex_values.attribute2%TYPE;
  Id_User_Last_Update    po_headers_all.last_updated_by%TYPE;
  Id_Last_Update         fnd_user.employee_id%TYPE;

  pv_mail_name                VARCHAR2(4000);
  pv_mail_name_create         VARCHAR2(1000);
  pv_mail_name_gestion        VARCHAR2(1000);
  pv_mail_name_csp            VARCHAR2(1000);
  pv_mail_name_sstr           VARCHAR2(1000);
  pv_mail_name_update         VARCHAR2(1000);

  pv_mail              VARCHAR2(2000);
  pv_mail_create       VARCHAR2(500);
  pv_mail_gestion      VARCHAR2(500);
  pv_mail_csp          VARCHAR2(500);
  pv_mail_sstr         VARCHAR2(500);
  pv_mail_update       VARCHAR2(500);
  BEGIN

     select fu.employee_id,
        dcs.signataire_contrat,
        ffv.attribute2, --ffv.attribute1, --RBE artf2154499 
        ffv.attribute3, --ffv.attribute2, --RBE artf2154499 
        pha.last_updated_by
     into   Id_Createur,
        Id_Gestionnaire,
        Id_Correspondant_Sstr,
        Id_Correspondant_Csp,
        Id_User_Last_Update
     from   po_headers_all pha,
        fnd_user fu,
        dka_contrat_sstr dcs,
        --per_all_people_f papf, -- RBE artf2376255
        per_people_f papf, -- RBE artf2376255 --artf3025989
        fnd_flex_values ffv,
        fnd_flex_value_sets ffvs
     where   pha.created_by = fu.user_id
     and   dcs.po_header_id = pha.po_header_id
     and   papf.person_id = dcs.signataire_contrat
     AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date) AND NVL(papf.effective_end_date,SYSDATE) --RBE artf3025989
     and   ffv.flex_value_set_id = ffvs.flex_value_set_id
     and   ffvs.flex_value_set_name = 'DAOPCCF_UO' --'DKA_REGION' --RBE artf2154499 
     and   papf.attribute2 = ffv.flex_value
     and   pha.po_header_id = pv_header_id;


  search_mail(Id_Createur,pv_mail_name_create,pv_mail_create,pv_errbuf,pn_retcode);
  search_mail(Id_Gestionnaire,pv_mail_name_gestion,pv_mail_gestion,pv_errbuf,pn_retcode);
  search_mail(Id_Correspondant_Sstr,pv_mail_name_sstr,pv_mail_sstr,pv_errbuf,pn_retcode);
  search_mail(Id_Correspondant_Csp,pv_mail_name_csp,pv_mail_csp,pv_errbuf,pn_retcode);

  -- création et renouvellement de contrat --
  IF pv_action = 'REJET' THEN
     pv_mail_name := pv_mail_name_gestion || '; ' || pv_mail_name_sstr || '; ' || pv_mail_name_create;
     pv_mail      := '<' || pv_mail_gestion || '>; <' || pv_mail_sstr || '>; <'|| pv_mail_create || '>';
  ELSE
     select fu.employee_id
     into   Id_Last_Update
     from   fnd_user fu
     where  fu.user_id = Id_User_Last_Update;

     search_mail(Id_Last_Update,pv_mail_name_update,pv_mail_update,pv_errbuf,pn_retcode);
    IF pv_action = 'RENOUVELER' THEN
     pv_mail_name := pv_mail_name_gestion || '; ' || pv_mail_name_sstr || '; ' || pv_mail_name_csp || '; ' || pv_mail_name_update;
     pv_mail      := '<' || pv_mail_gestion || '>; <' || pv_mail_sstr || '>; <'|| pv_mail_csp || '>; <'|| pv_mail_update || '>';
    -- mail d'annulation --
    ELSIF pv_action = 'ANNULER' THEN
       pv_mail_name := pv_mail_name_gestion || '; ' || pv_mail_name_sstr || '; ' || pv_mail_name_update || '; ' || pv_mail_name_csp;
       pv_mail      := '<' || pv_mail_gestion || '>; <' || pv_mail_sstr || '>; <'|| pv_mail_update || '>; <'|| pv_mail_csp || '>';
    -- mail de fermeture --
    ELSIF pv_action = 'FERMER' THEN
       pv_mail_name := pv_mail_name_gestion || '; ' || pv_mail_name_sstr || '; ' || pv_mail_name_update || '; ' || pv_mail_name_csp;
       pv_mail      := '<' || pv_mail_gestion || '>; <' || pv_mail_sstr || '>; <'|| pv_mail_update || '>; <'|| pv_mail_csp || '>';
    -- mail de résiliation non effectuée
    ELSIF pv_action = 'NON_EFFECTUER' THEN
       pv_mail_name := pv_mail_name_gestion || '; ' || pv_mail_name_sstr || '; ' || pv_mail_name_update || '; ' || pv_mail_name_csp;
       pv_mail      := '<' || pv_mail_gestion || '>; <' || pv_mail_sstr || '>; <'|| pv_mail_update || '>; <'|| pv_mail_csp || '>';
    -- mail de résiliation
    ELSIF pv_action = 'RESILIER' THEN
       pv_mail_name := pv_mail_name_gestion || '; ' || pv_mail_name_sstr || '; ' || pv_mail_name_update || '; ' || pv_mail_name_csp;
       pv_mail      := '<' || pv_mail_gestion || '>; <' || pv_mail_sstr || '>; <'|| pv_mail_update || '>; <'|| pv_mail_csp || '>';
    END IF;
  END IF;

  envoi_notif_mail(pv_entete,pv_haut_page,pv_body,pv_pied_page,nvl(gv_mail_test,pv_mail_name),nvl(gv_mail_test,pv_mail),pv_errbuf,pn_retcode);--YWA artf2120401 
  EXCEPTION
    WHEN OTHERS THEN
     pv_errbuf  :=  'Erreur procedure search_id_destinataire_mail ' || SQLERRM;
     pn_retcode  :=  1;
     log_msg(pv_errbuf);
  END search_id_destinataire_mail;


  -------------------------------------------------------------------------------------
  --  Nom           : SEARCH_MAIL
  --  Description   :
  --
  --  PARAMETRES    :
  --  pv_id_employe  Entree
  --  pv_user_name  Sortie
  --  pv_user_mail  Sortie
  --  pv_errbuf     Sortie
  --  pv_retcode    Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  --------------------------------------------------------------------------------------

   PROCEDURE search_mail (
    pv_id_employe  IN      VARCHAR2,
    pv_mail_name   OUT    VARCHAR2,
    pv_mail       OUT    VARCHAR2,
    pv_errbuf       OUT       VARCHAR2,
    pn_retcode      OUT       NUMBER
   ) IS
   pv_user_mail VARCHAR2(2000);
   pv_user_name VARCHAR2(2000);
   BEGIN

    SELECT   trim(' ' FROM nvl(ppf.EMAIL_ADDRESS,fu.email_address)), ppf.FULL_NAME
    INTO   pv_user_mail,
        pv_user_name
    FROM     fnd_user fu,
        --per_people_f ppf -- RBE artf2376255
        per_people_f ppf  -- RBE artf2376255 --artf3025989
    WHERE    fu.employee_id = ppf.person_id 
    AND     TRUNC(SYSDATE) BETWEEN TRUNC(ppf.effective_start_date) AND NVL(ppf.effective_end_date,SYSDATE) --RBE artf3025989
    AND     ppf.person_id = pv_id_employe;

    pv_mail_name := pv_user_name || ' <' ||  pv_user_mail || '>';
    pv_mail := pv_user_mail;
   EXCEPTION
  WHEN OTHERS THEN
     pv_errbuf  := 'Erreur procedure search_mail '|| SQLERRM;
     pn_retcode := 1;
     log_msg(pv_errbuf);
   END search_mail;


  -------------------------------------------------------------------------------------
  --  Nom           : CHECK_CONTRAT_AVERT
  --  Description   :
  --
  --  PARAMETRES    :
  --  itemtype       Entree
  --  itemkey        Entree
  --  actid          Entree
  --  funcmode       Sortie
  --  resultout      Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  --------------------------------------------------------------------------------------

    PROCEDURE mail_notification (itemtype  IN VARCHAR2,
                          itemkey   IN VARCHAR2,
                          actid     IN NUMBER,
                          funcmode  IN VARCHAR2,
                          resultout OUT NOCOPY VARCHAR2) IS

    ln_retcode         NUMBER;
    lv_errbuf          VARCHAR2(2000);
    e_init            EXCEPTION;
    e_send_mail          EXCEPTION;
    e_search_mail      EXCEPTION;
    e_get_message      EXCEPTION;
    vn_contrat_id      NUMBER;
    vv_action          VARCHAR2(20);
    pv_errbuf          VARCHAR2(2000);
    pn_retcode           NUMBER;
    gv_mail_name         VARCHAR2(4000);
    gv_mail              VARCHAR2(4000);
    gv_base             VARCHAR2(50);
    pv_mail_test   VARCHAR2(240) := null;
    rec_param   dka_parameters%ROWTYPE;
    BEGIN
     vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                          itemkey  => itemkey,
                          aname    => 'P_CONTRACT_ID');


     vv_action := wf_engine.GetItemAttrText(itemtype => itemtype,
                        itemkey  => itemkey,
                        aname    => 'P_ACTION');
                        
    --YWA artf2120401 
    Dka_Tools_Pkg.get_parameter ('DKA_SPOWFMASTER', 'MAIL_TEST', rec_param, pv_errbuf, pn_retcode);
    pv_mail_test                := rec_param.varchar2_value;
     
    ------------------------------------
    --INITIALISATION ADRESSE MAIL TEST--
    ------------------------------------
    DKA_SEND_MAIL_PKG.mail_test(pv_mail_test,gv_mail_test);
    log_msg('Mail de test :'||gv_mail_test);                   
       BEGIN
        
        
        
     --INITIALISATION DES VARIABLES
     log_msg('Initialisation des variables de connections...');
         init(lv_errbuf,ln_retcode);
         IF ln_retcode != 0 THEN
          RAISE e_init;
         END IF;
         log_msg('Initialisation des variables de connections...');
         --RECUPERATION DES MESSAGES
         log_msg('Recuperation des messages...');
         get_message_mail(vn_contrat_id,vv_action,gv_entete,gv_haut_page,gv_body,gv_pied_page,lv_errbuf,ln_retcode);

         IF ln_retcode != 0 THEN
          RAISE e_get_message;
         END IF;
         log_msg('Recuperation des messages OK...');
     --RECHERCHE DU NOM DE LA BASE DE DONNEES CONCERNEE
    BEGIN
      SELECT name
      INTO gv_base
      FROM v$database;
      EXCEPTION
        WHEN OTHERS THEN
        pv_errbuf := 'ERREUR lors de la recherche du nom de la base de données';
        pn_retcode := 2;
        RAISE;
    END;
      --IF gv_base = 'DT1OAP' THEN
   -- log_msg('Mail perso ...');
   -- gv_mail_name  := 'COUDRIER, Benjamin <benjamin.coudrier@capgemini.com>';
   -- gv_mail      := 'benjamin.coudrier@capgemini.com';
   -- IF ln_retcode != 0 THEN
   --        RAISE e_search_mail;
   --     END IF;
   --     log_msg('Recherche des adresses mail OK...');

        --ENVOI MAIL AVERTISSEMENT
   --     log_msg('Envoi mail...');
   --     envoi_notif_mail(gv_entete,gv_haut_page,gv_body,gv_pied_page,gv_mail_name,gv_mail,lv_errbuf,ln_retcode);
   --     IF ln_retcode != 0 THEN
   --        RAISE e_send_mail;
   --     END IF;
   --     log_msg('Envoi mail avertissement OK...');
   --     COMMIT;
   --ELSE
    --RECHERCHE DES ADRESSES MAIL
    log_msg('Recherche des adresses mail ...');
    search_id_destinataire_mail(vn_contrat_id,gv_entete,gv_haut_page,gv_body,gv_pied_page,vv_action,lv_errbuf,ln_retcode);
   --END IF;



       EXCEPTION
    WHEN e_init THEN
         lv_errbuf  := 'Erreur dans la procedure d''initialisation de variables : '|| SQLERRM;
         pn_retcode := 1;
         log_msg(lv_errbuf);
         --CONTINUE
         gn_erreur := gn_erreur + 1 ;
      WHEN e_get_message THEN
         lv_errbuf  := 'Erreur dans la procedure de recuperation des messages : '|| SQLERRM;
         pn_retcode := 1;
         log_msg(lv_errbuf);
         --CONTINUE
         gn_erreur := gn_erreur + 1 ;
    WHEN e_search_mail THEN
     lv_errbuf  := 'Erreur dans la procedure de recherche de mail : '|| SQLERRM;
         pn_retcode := 1;
         log_msg(lv_errbuf);
         --CONTINUE
         gn_erreur_search := gn_erreur_search + 1 ;
       WHEN e_send_mail THEN
         lv_errbuf  := 'Erreur dans la procedure d''envoi des notifications : '|| SQLERRM;
         pn_retcode := 1;
         log_msg(lv_errbuf);
         --CONTINUE
         gn_erreur_avert := gn_erreur_avert + 1 ;
       END;

     IF  pn_retcode = 1 THEN
      pv_errbuf := 'Erreur dans la verification des contrats';
      log_msg(pv_errbuf);
     END IF;

    EXCEPTION
      WHEN OTHERS THEN
         pv_errbuf  := 'Erreur procedure mail_notification '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
    END mail_notification;


  -------------------------------------------------------------------------------------
  --  Nom           : ENVOI_NOTIF_MAIL
  --  Description   : procedure d'envoi de notification par mail
  --
  --  PARAMETRES    :
  --  pv_entete      IN       Sujet du courriel
  --  pv_haut_page  IN     Corps Haut du courriel
  --  pv_body       IN       Corps du courriel
  --  pv_pied_page  IN     Corps Fin du courriel
  --  pv_mail_name  IN     Ensemble mail et nom des destinataires
  --  pv_mail    IN     Ensemble mail des destinataires
  --  pv_errbuf     IN OUT   message de sortie
  --  pn_retcode    OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------

    PROCEDURE envoi_notif_mail (
    pv_entete    IN     VARCHAR2,
    pv_haut_page  IN      VARCHAR2,
        pv_body         IN       VARCHAR2,
    pv_pied_page  IN     VARCHAR2,
    pv_mail_name  IN     VARCHAR2,
    pv_mail      IN     VARCHAR2,
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    ) IS

      l_email            fnd_user.email_address%TYPE;
      l_mesg VARCHAR2( 24000 );
      l_conn UTL_SMTP.CONNECTION;
      v_mail           varchar2(1000); -- RBE artf2154499 
      v_dest           varchar2(200);  -- RBE artf2154499 
    BEGIN

     -- Création et envoi du mail au créateur
     l_conn:= utl_smtp.open_connection( gv_conn, 25 );
     utl_smtp.helo( l_conn , gv_conn );
     utl_smtp.mail( l_conn , gv_expediteur );
     --RBE artf2154499 
      v_mail := TRIM(pv_mail);
      
      while length (v_mail) > 0 LOOP
        select trim(substr(v_mail,0,INSTR(v_mail,'>'))),trim(substr(v_mail,INSTR(v_mail,'>')+2))
        INTO v_dest,v_mail
        from dual;
        utl_smtp.rcpt( l_conn , v_dest);
      END LOOP;
      --fin rbe artf2154499 
     --utl_smtp.rcpt( l_conn , pv_mail); --rbe artf2154499 
     utl_smtp.open_data(l_conn);
     -- l_mesg:= 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || utl_tcp.CRLF ||
     -- l_mesg:= 'Date: ' || to_char(systimestamp, 'dd Mon yy hh24:mi:ss tzhtzm') || utl_tcp.CRLF ||
     l_mesg:= 'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm','NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
         'From: ' || gv_expediteur || utl_tcp.CRLF ||
         'To: ' || pv_mail  || utl_tcp.CRLF ||
         'Subject:' || pv_entete || utl_tcp.CRLF ||
         'content-type: text/html; charset=windows-1252' || utl_tcp.CRLF || utl_tcp.CRLF ||
         --'Content-Type: text/plain;  '|| utl_tcp.CRLF ||
         --' charset="iso-8859-1"' || utl_tcp.CRLF || utl_tcp.CRLF ||
     pv_haut_page || utl_tcp.CRLF || utl_tcp.CRLF ||
         pv_body || utl_tcp.CRLF || utl_tcp.CRLF ||
     pv_pied_page || utl_tcp.CRLF;

     utl_smtp.write_data(l_conn, l_mesg);
     utl_smtp.close_data(l_conn);
     utl_smtp.quit( l_conn );
     log_msg('Mail envoye a : '|| pv_mail_name);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         pv_errbuf  := 'Aucune adresse mail trouvee.';
         pn_retcode := 2;
         log_msg(pv_errbuf);
      WHEN OTHERS THEN
         pv_errbuf  := 'Erreur procedure ENVOI_MAIL '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
    END envoi_notif_mail;

      ------------------------------------------------------------------------------------------------------------
    --  Nom           : active_desactive_site_four
    --  Description   : Procedure qui va activer le site fournisseur s'il est désactivé ou inversemment
    --                :
    --
    --  PARAMETRES : paramètre obligatoire du workflow.
    --
    --  VALEUR RETOURNEE :
    --     N/A
    ------------------------------------------------------------------------------------------------------------

    PROCEDURE active_desactive_site_four(itemtype  IN VARCHAR2,
                                       itemkey   IN VARCHAR2,
                                       actid     IN NUMBER,
                                       funcmode  IN VARCHAR2,
                                       resultout OUT NOCOPY VARCHAR2) IS

   vn_contrat_id          NUMBER;
   vv_desact_date_four    VARCHAR2(10);
   vv_desact_site_four    VARCHAR2(1);
   vv_purchase_flag       po_vendor_sites_all.PURCHASING_SITE_FLAG%TYPE;
   vd_inactive_date       po_vendor_sites_all.INACTIVE_DATE%TYPE;
   vn_vendor_site_id      po_vendor_sites_all.vendor_site_id%TYPE;
   l_commit               NUMBER;

  BEGIN
  
  l_commit := 0;
  
  --Récupération du contrat
  vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'P_CONTRACT_ID');

  --Récupération de la date
  vv_desact_date_four := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'PV_DESACT_FOUR');
  
  --Récupération de la date
  vv_desact_site_four := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'PV_PURCHASING_SITE');

  --Recherche de la date de désactivation et du site fournisseur
  SELECT
    INACTIVE_DATE,
    PURCHASING_SITE_FLAG,
    pvsa.vendor_site_id
  INTO
    vd_inactive_date,
    vv_purchase_flag,
    vn_vendor_site_id
  FROM
    po_headers_all pha,
    dka_contrat_sstr dcs ,
    po_vendor_sites_all pvsa
  WHERE pha.po_header_id = dcs.po_header_id
    AND pha.po_header_id = vn_contrat_id
    AND pha.vendor_site_id = pvsa.vendor_site_id;

  --DATE DESACTIVATION
  IF vv_desact_date_four IS NULL THEN

    IF NVL(vd_inactive_date,SYSDATE+1) < SYSDATE THEN
      --Mise à jour du site fournisseur
      UPDATE po_vendor_sites_all
      SET
       INACTIVE_DATE = null
      WHERE
       vendor_site_id = vn_vendor_site_id;
      
      l_commit := 1;
      
      --Sauvegarde de la valeur dans le process du workflow
      wf_engine.setitemattrtext(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'PV_DESACT_FOUR',
                                avalue   => to_char(vd_inactive_date,'dd/mm/yyyy'));

      
    ELSE
      --Rien à faire
      NULL;
    END IF;

  ELSE
    --Le site a été réactivé, il faut le désactiver
    --Mise à jour du site fournisseur
    UPDATE po_vendor_sites_all
    SET
     INACTIVE_DATE = to_date(vv_desact_date_four,'dd/mm/yyyy')
    WHERE
     vendor_site_id = vn_vendor_site_id;


    --Effacement de la valeur dans le process du workflow
    wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'PV_DESACT_FOUR',
                              avalue   => NULL);

    l_commit := 1;

  END IF;
  
  --SITE D'ACHAT
  IF vv_desact_site_four IS NULL THEN

    IF vv_purchase_flag = 'N' THEN
      --Mise à jour du site fournisseur
      UPDATE po_vendor_sites_all
      SET
       PURCHASING_SITE_FLAG = 'Y'
      WHERE
       vendor_site_id = vn_vendor_site_id;

      --Sauvegarde de la valeur dans le process du workflow
      wf_engine.setitemattrtext(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'PV_PURCHASING_SITE',
                                avalue   => 'N');

      l_commit := 1;
    ELSE
      --Rien à faire
      NULL;
    END IF;

  ELSE
    --Le site a été réactivé, il faut le désactiver
    --Mise à jour du site fournisseur
    UPDATE po_vendor_sites_all
    SET
     PURCHASING_SITE_FLAG = vv_desact_site_four
    WHERE
     vendor_site_id = vn_vendor_site_id;


    --Effacement de la valeur dans le process du workflow
    wf_engine.setitemattrtext(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'PV_PURCHASING_SITE',
                              avalue   => NULL);

    l_commit := 1;

  END IF;
  
  IF l_commit = 1 THEN
   COMMIT;
  END IF;
  
  EXCEPTION
       WHEN OTHERS THEN
         wf_core.CONTEXT('DKA_SPOWFMASTER_PKG', 'active_desactive_site_four',
           itemtype, itemkey, actid, funcmode);
         RAISE;
  END active_desactive_site_four;

END dka_spowfmaster_pkg; -- Spécification du package
/
SHOW ERRORS PACKAGE BODY dka_spowfmaster_pkg;
EXIT
