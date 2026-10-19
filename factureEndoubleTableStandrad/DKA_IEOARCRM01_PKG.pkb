CREATE OR REPLACE PACKAGE BODY dka_spocreatepo_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id$
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : DKA_SPOCREATEPO_PKG.pkb
  -- DESCRIPTION       : DKA_SPOCREATEPO_PKG package body :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 13/09/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---------------------------------------------------------------------------------------------------------------
  --- 20/09/11   CDE DGE20110006 - Ajout de la Prodédure is_autocreation_authorized
  --- 05/03/13   BCO INC000000384457 - Correctif pour modification des informations du bon de commande lorsqu'une
  ---                DA est de type HORS CATALOGUE et liée à un contrat.
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

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -------------------------------------------------------------------------------------
  --  Nom           : does_contract_exist
  --  Description   : Procédure de recherche du contrat lié à la DA.
  --
  --  PARAMETRES : paramètre standard workflow
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE does_contract_exist(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS
  
    x_contract_id      NUMBER;
    x_supplier_id      NUMBER;
    x_supplier_site_id NUMBER;
  
    x_use_contract_flag VARCHAR2(1);
  
    --< Bug 3560447 > Do not initialize variables in DECLARE section.
    x_progress VARCHAR2(300);
	
    -- INC000000384457 - Ajout de la variable de récupération du type de DA.
	x_catalog_type    	varchar2(30);
	x_req_line_id   	number;
	
  BEGIN
    x_progress := '000'; --< Bug 3560447 >
  
    x_supplier_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype,
                                                      itemkey  => itemkey,
                                                      aname    => 'SUGGESTED_VENDOR_ID');
  
    x_supplier_site_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype,
                                                           itemkey  => itemkey,
                                                           aname    => 'SUGGESTED_VENDOR_SITE_ID');
  
    x_use_contract_flag := po_wf_util_pkg.getitemattrtext(itemtype => itemtype,
                                                          itemkey  => itemkey,
                                                          aname    => 'USE_CONTRACT_FLAG');
  
    -- INC000000384457 - Récupération de la valeur du type de catalogue et de l'identifiant de la ligne de DA.
    x_catalog_type := po_wf_util_pkg.GetItemAttrText (itemtype => itemtype,
													  itemkey  => itemkey,
													  aname    => 'CATALOG_TYPE');
	
	x_req_line_id := po_wf_util_pkg.GetItemAttrNumber (itemtype => itemtype,
													   itemkey  => itemkey,
													   aname    => 'REQ_LINE_ID');
													   
    IF nvl(x_use_contract_flag, 'N') <> 'Y'
    THEN
    
      resultout := wf_engine.eng_completed || ':' || 'N';
    
      RETURN;
    
    END IF;
  
    BEGIN
    
      x_progress := '001';
    
      -- Modification du standard
      SELECT MAX(po_header_id)
        INTO x_contract_id
        FROM po_headers
       WHERE vendor_id = x_supplier_id AND
             vendor_site_id = x_supplier_site_id AND
             type_lookup_code = 'CONTRACT' AND nvl(cancel_flag, 'N') = 'N' AND
             SYSDATE BETWEEN nvl(start_date, SYSDATE - 1) AND
             nvl(end_date, SYSDATE + 1) AND
             authorization_status = 'APPROVED' AND
             nvl(closed_code, 'OPEN') = 'OPEN'
            -- Vérifie que le contrat est bien du type contrat standard et pas un sosu-type
             AND attribute4 IS NULL;
      ---------------------------
    
    EXCEPTION
    
      WHEN OTHERS THEN
        x_contract_id := NULL;
      
    END;
  
    x_progress := '002';
  
    IF x_contract_id IS NOT NULL
    THEN
    
      po_wf_util_pkg.setitemattrnumber(itemtype => itemtype,
                                       itemkey  => itemkey,
                                       aname    => 'CONTRACT_ID',
                                       avalue   => x_contract_id);
      po_wf_util_pkg.setitemattrtext(itemtype => itemtype,
                                     itemkey  => itemkey,
                                     aname    => 'SOURCE_DOCUMENT_TYPE_CODE',
                                     avalue   => 'CONTRACT');
      
	  -- INC000000384457 - Vérifier que le contrat est de type hors catalogue.
	  IF x_catalog_type = 'NONCATALOG' THEN
	    -- Modification du cuf ATTRIBUTE15 = 'OUI' pour la prise en compte de l'auteur de la DA sur la ligne de DA.
		x_progress := '003';
	    BEGIN
		  UPDATE  PO_REQUISITION_LINES_ALL
		  SET	  ATTRIBUTE15		  = 'OUI'
		  WHERE	  REQUISITION_LINE_ID = x_req_line_id;
		EXCEPTION
		  WHEN OTHERS THEN
			  wf_core.CONTEXT('dka_spocreatepo_pkg',
							  'does_contract_exist',
							  x_progress);
		END;
	  END IF;
      resultout := wf_engine.eng_completed || ':' || 'Y';
    
    ELSE
    
      resultout := wf_engine.eng_completed || ':' || 'N';
    
    END IF;
  
  EXCEPTION
  
    WHEN OTHERS THEN
      wf_core.CONTEXT('dka_spocreatepo_pkg',
                      'does_contract_exist',
                      x_progress);
      RAISE;
    
  END does_contract_exist;


  -------------------------------------------------------------------------------------
  --  Nom           : is_autocreation_authorized
  --  Description   : Procédure de recherche si la DA Hors Catalogue peut être autocréée.
  --
  --  PARAMETRES : paramètre standard workflow
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE is_autocreation_authorized(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS

    x_supplier_id      NUMBER;
    x_supplier_site_id NUMBER;
    x_commande_auto    VARCHAR2(5);
    x_progress VARCHAR2(300);

  BEGIN
    x_progress := '000'; 
  
    x_supplier_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype,
                                                      itemkey  => itemkey,
                                                      aname    => 'SUGGESTED_VENDOR_ID');
  
    x_supplier_site_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype,
                                                           itemkey  => itemkey,
                                                           aname    => 'SUGGESTED_VENDOR_SITE_ID');

    x_progress := '001';
 
    IF (x_supplier_site_id IS NULL OR x_supplier_id IS NULL)
    THEN 
    
        -- Si aucun site fournisseur n'a été rattaché à la DA : autocréation non autorisée
        resultout := wf_engine.eng_completed || ':' || 'N'; 
    ELSE
              
       BEGIN    
            x_progress := '002';
            
            -- Recherche de la valeur du CUF "Création automatique des commandes" 
            SELECT attribute7
            INTO x_commande_auto
            FROM po_vendors
            WHERE vendor_id = x_supplier_id;
   
       EXCEPTION    
       WHEN OTHERS THEN
            x_commande_auto := NULL;
      
       END;
  
       x_progress := '003';
  
       IF x_commande_auto = 'NON'
       THEN
            resultout := wf_engine.eng_completed || ':' || 'N';
       ELSE
            resultout := wf_engine.eng_completed || ':' || 'Y'; 
       END IF;
    END IF;
  
  EXCEPTION
  
    WHEN OTHERS THEN
      wf_core.CONTEXT('dka_spocreatepo_pkg',
                      'is_autocreation_authorized',
                      x_progress);
      RAISE;

  END is_autocreation_authorized;

END dka_spocreatepo_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE dka_spocreatepo_pkg;
EXIT
