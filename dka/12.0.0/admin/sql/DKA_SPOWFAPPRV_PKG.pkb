CREATE OR REPLACE PACKAGE BODY dka_spowfapprv_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SPOWFAPPRV_PKG.pkb 352 2007-10-02 14:19:00Z NORDEST\viknab $
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : dka_spowfapprv_pkg.pkb
  -- DESCRIPTION       : DKA_SPOWFMASTER_PKG package body :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 27/08/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---
  --- 18/03/2010 SRO Ajout de la procedure alim_description_contrat_sstr permettant
  ---                l alimentation dans le cas de contrat de sous-traitance la description 
  ---                du contrat et dans le cas des commandes annuelles de sous-traitance celle du contrat
  --- 
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- Read the profile option that enables/disables the debug log
  g_po_wf_debug VARCHAR2(1) := nvl(fnd_profile.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),
                                   'N');

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : updtpoitemtype
  --  Description   : procédure standard modifié, on a retiré l'autonomous transaction
  --
  --  PARAMETRES    : 
  --                  
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE updtpoitemtype(itemtype IN VARCHAR2,
                           itemkey  IN VARCHAR2,
                           p_doc_id IN NUMBER) IS
  
    x_progress VARCHAR2(3) := '000';
    l_call     VARCHAR2(4000) DEFAULT dbms_utility.format_call_stack;
  BEGIN
  
    x_progress := '001';
  
    UPDATE po_headers
       SET wf_item_type      = itemtype,
           wf_item_key       = itemkey,
           last_updated_by   = fnd_global.user_id,
           last_update_login = fnd_global.login_id,
           last_update_date  = SYSDATE
     WHERE po_header_id = p_doc_id;
  
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT('dka_spowfapprv_pkg', 'UpdtPOItemtype', SQLCODE);
      RAISE;
    
  END updtpoitemtype;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : updtreqitemtype
  --  Description   : procédure standard
  --
  --  PARAMETRES    : 
  --                  
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE updtreqitemtype(itemtype IN VARCHAR2,
                            itemkey  IN VARCHAR2,
                            p_doc_id IN NUMBER) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    x_progress VARCHAR2(3) := '000';
  
  BEGIN
  
    x_progress := '001';
  
    UPDATE po_requisition_headers
       SET wf_item_type      = itemtype,
           wf_item_key       = itemkey,
           last_updated_by   = fnd_global.user_id,
           last_update_login = fnd_global.login_id,
           last_update_date  = SYSDATE
     WHERE requisition_header_id = p_doc_id;
  
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT('dka_spowfapprv_pkg', 'UpdtReqItemtype', x_progress);
      RAISE;
    
  END updtreqitemtype;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : updtrelitemtype
  --  Description   : procédure standard
  --
  --  PARAMETRES    : 
  --                  
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE updtrelitemtype(itemtype IN VARCHAR2,
                            itemkey  IN VARCHAR2,
                            p_doc_id IN NUMBER) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  
    x_progress VARCHAR2(3) := '000';
  
  BEGIN
  
    x_progress := '001';
  
    UPDATE po_releases
       SET wf_item_type      = itemtype,
           wf_item_key       = itemkey,
           last_updated_by   = fnd_global.user_id,
           last_update_login = fnd_global.login_id,
           last_update_date  = SYSDATE
     WHERE po_release_id = p_doc_id;
  
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT('dka_spowfapprv_pkg', 'UpdtRelItemtype', SQLCODE);
      RAISE;
    
  END updtrelitemtype;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : register_doc_submitted
  --  Description   : procédure standard
  --
  --  PARAMETRES    : 
  --                  
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE register_doc_submitted(itemtype  IN VARCHAR2,
                                   itemkey   IN VARCHAR2,
                                   actid     IN NUMBER,
                                   funcmode  IN VARCHAR2,
                                   resultout OUT NOCOPY VARCHAR2) IS
    l_doc_id             NUMBER;
    l_doc_type           VARCHAR2(25);
    l_authorization_stat VARCHAR2(25);
    l_orgid              NUMBER;
    x_progress           VARCHAR2(100);
  
    l_doc_string         VARCHAR2(200);
    l_preparer_user_name VARCHAR2(100);
  
  BEGIN
  
    x_progress := 'dka_spowfapprv_pkg.Register_doc_submitted: 01';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;
  
    -- Do nothing in cancel or timeout mode
    --
    IF (funcmode <> wf_engine.eng_run)
    THEN
    
      resultout := wf_engine.eng_null;
      RETURN;
    
    END IF;
  
    -- Set the multi-org context
    l_orgid := wf_engine.getitemattrnumber(itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'ORG_ID');
  
    IF l_orgid IS NOT NULL
    THEN
    
      fnd_client_info.set_org_context(to_char(l_orgid));
    
    END IF;
  
    l_doc_id := wf_engine.getitemattrtext(itemtype => itemtype,
                                          itemkey  => itemkey,
                                          aname    => 'DOCUMENT_ID');
  
    l_doc_type := wf_engine.getitemattrtext(itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'DOCUMENT_TYPE');
  
    IF l_doc_type = 'REQUISITION'
    THEN
    
      updtreqitemtype(itemtype, itemkey, l_doc_id);
    
    ELSIF l_doc_type IN ('PO', 'PA')
    THEN
    
      updtpoitemtype(itemtype, itemkey, l_doc_id);
    
    ELSIF l_doc_type = 'RELEASE'
    THEN
    
      updtrelitemtype(itemtype, itemkey, l_doc_id);
    
    END IF;
  
    --
    resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
    --
  
    x_progress := 'dka_spowfapprv_pkg.Register_doc_submitted: 02';
    IF (g_po_wf_debug = 'Y')
    THEN
      /* DEBUG */
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      l_doc_string         := po_reqapproval_init1.get_error_doc(itemtype,
                                                                 itemkey);
      l_preparer_user_name := po_reqapproval_init1.get_preparer_user_name(itemtype,
                                                                          itemkey);
      wf_core.CONTEXT('dka_spowfapprv_pkg',
                      'Register_doc_submitted',
                      x_progress);
      po_reqapproval_init1.send_error_notif(itemtype,
                                            itemkey,
                                            l_preparer_user_name,
                                            l_doc_string,
                                            SQLERRM,
                                            'dka_spowfapprv_pkg.REGISTER_DOC_SUBMITTED');
      RAISE;
    
  END register_doc_submitted;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : alim_description_contrat_sstr
  --  Description   : alimentation dans le cas de contrat de sous-traitance la description 
  --  du contrat et dans le cas des commandes annuelles de sous-traitance celle du contrat
  --
  --  PARAMETRES    : 
  --                IN
  --                itemtype, itemkey, actid, funcmode
  --                OUT
  --                Resultout        
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  
procedure alim_description_contrat_sstr (     itemtype        in varchar2,
                                              itemkey         in varchar2,
                                              actid           in number,
                                              funcmode        in varchar2,
                                              resultout       out NOCOPY varchar2    ) is

l_document_type     varchar2(25);
l_document_id       number;
l_document_number   po_headers_all.segment1%TYPE;
l_contract_number   po_headers_all.segment1%TYPE;
l_contract_comments dka_contrat_sstr.description_specifique_contrat%TYPE;
l_type_contrat      po_headers_all.attribute4%TYPE;
l_orgid     number;
l_doc_string varchar2(200);
l_preparer_user_name varchar2(100);
x_progress  varchar2(200);

BEGIN

  x_progress := 'dka_spowfapprv_pkg.alim_description_contrat_sstr: 01';
  IF (g_po_wf_debug = 'Y') 
  THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;


  if (funcmode <> wf_engine.eng_run) then

      resultout := wf_engine.eng_null;
      return;

  end if;


  PO_REQAPPROVAL_INIT1.Set_doc_mgr_context(itemtype, itemkey);

  -- Set the multi-org context
  l_orgid := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'ORG_ID');

  IF l_orgid is NOT NULL THEN

    fnd_client_info.set_org_context(to_char(l_orgid));

  END IF;

  l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_TYPE');

  l_document_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

                                       
  -- initialisation de la descrpition du contrat sstr dans les cas où cette zone doit rester vide 
  -- comme l'approbation du contrat hors SSTR ou l'approbation d'une commande hors SSTR
  wf_engine.SetItemAttrText ( itemtype   => itemType,
                              itemkey    => itemkey,
                              aname      => 'DKA_DESCRIPTION_CONTRAT_SSTR' ,
                              avalue     => '');                                            
                                         
 IF (l_document_type = 'PO') THEN  

    -- extraction du numero de la commande annuelle de sous-traitance                                                                
    select segment1
    into   l_document_number 
    from   po_headers_all ph
    where  ph.po_header_id = l_document_id
    and    ph.org_id = l_orgid;
      
     -- test si l'ordre d'achat est une commande annuelle de sous-traitance
    IF (substr(l_document_number,-6,2) = 'ST') THEN  
       BEGIN
  
          -- extraction du numero et de la description du contrat ayant généré la commande annuelle de sous-traitance                                                                
          select ph.segment1
                 ,nvl(dcs.description_specifique_contrat,'')
          into   l_contract_number 
                 ,l_contract_comments
          from   po_headers_all ph
                 ,dka_contrat_sstr dcs
          where  ph.segment1 = substr(l_document_number,0,length(l_document_number)-6)
          and    ph.org_id = l_orgid
          and    dcs.po_header_id = ph.po_header_id
          ;        
                                    
         wf_engine.SetItemAttrText ( itemtype   => itemType,
                                    itemkey    => itemkey,
                                    aname      => 'DKA_DESCRIPTION_CONTRAT_SSTR' ,
                                    avalue     => 'Description du contrat de sous-traitance de cette commande : '||l_contract_comments);                             

        EXCEPTION
          WHEN OTHERS THEN
                   wf_engine.SetItemAttrText (itemtype   => itemType,
                                              itemkey    => itemkey,
                                              aname      => 'DKA_DESCRIPTION_CONTRAT_SSTR' ,
                                              avalue     => '');


       END;
    END IF;  
 ELSIF (l_document_type = 'PA') 
 THEN  
    -- extraction des informations du contrat de sous-traitance   
    select ph.segment1
           ,nvl(dcs.description_specifique_contrat,' ')
           ,nvl(ph.attribute4,' ')
    into   l_document_number 
           ,l_contract_comments
           ,l_type_contrat
    from   po_headers_all ph
           ,dka_contrat_sstr dcs
    where  ph.po_header_id = l_document_id
    and    ph.org_id = l_orgid
    and    dcs.po_header_id = ph.po_header_id; 
 
   -- test si le contrat  est un contrat dependant ou independant de sous-traitance 
   IF l_type_contrat IN ('CONTRAT DEPENDANT','CONTRAT SOUS-TRAITANCE') THEN

      wf_engine.SetItemAttrText ( itemtype   => itemType,
                                  itemkey    => itemkey,
                                  aname      => 'DKA_DESCRIPTION_CONTRAT_SSTR' ,
                                  avalue     => 'Description du contrat de sous-traitance : '||l_contract_comments);   
    END IF;    
 END IF;    

 
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  --

  x_progress := 'dka_spowfapprv_pkg.alim_description_contrat_sstr: 02';
  IF (g_po_wf_debug = 'Y')
  THEN
    /* DEBUG */
    po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
  END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      l_doc_string         := po_reqapproval_init1.get_error_doc(itemtype,
                                                                 itemkey);
      l_preparer_user_name := po_reqapproval_init1.get_preparer_user_name(itemtype,
                                                                          itemkey);
      wf_core.CONTEXT('dka_spowfapprv_pkg',
                      'alim_description_contrat_sstr',
                      x_progress);
      po_reqapproval_init1.send_error_notif(itemtype,
                                            itemkey,
                                            l_preparer_user_name,
                                            l_doc_string,
                                            SQLERRM,
                                            'dka_spowfapprv_pkg.alim_description_contrat_sstr');
      RAISE;
    


END alim_description_contrat_sstr;

PROCEDURE PO_NEW_COMMUNICATION (itemtype IN VARCHAR2,
                                  itemkey IN VARCHAR2,
                                  actid IN NUMBER,
                                  funcmode IN VARCHAR2,
                                  resultout OUT NOCOPY VARCHAR2) is
  x_progress varchar2(100);
  l_document_subtype po_headers.type_lookup_code%TYPE;
  l_document_type po_headers.type_lookup_code%TYPE;

  Begin
    x_progress := 'dka_spowfapprv_pkg.PO_NEW_COMMUNICATION';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
    END IF;


  -- <Bug 4100416 Start>: Do nothing in cancel or timeout modes.
    IF (funcmode <> wf_engine.eng_run)
      THEN
      resultout := wf_engine.eng_null;
      return;
    END IF;
  -- <Bug 4100416 End>

    resultout := wf_engine.eng_completed || ':' || 'N';

  EXCEPTION

    WHEN OTHERS THEN
      x_progress := 'dka_spowfapprv_pkg.PO_NEW_COMMUNICATION: In Exception handler';
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('dka_spowfapprv_pkg', 'PO_NEW_COMMUNICATION', x_progress);
      raise;

  END PO_NEW_COMMUNICATION;
   

END dka_spowfapprv_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE dka_spowfapprv_pkg;
EXIT
