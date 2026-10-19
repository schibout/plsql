SET VERIFY OFF;
DEFINE package_name = "DKA_SPOBON_WF_PKG";

CREATE OR REPLACE PACKAGE BODY &&package_name
AS
----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_WF_PKG.pkb
-- DESCRIPTION       : DKA_SPOBON_WF_PKG package  :procedure utiliser dans le workflow
---                     PO Approval
--- AUTEUR           : Bernard HANQUIER (CGEY)
--- DATE DE CREATION : 29/02/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 14/03/2002 BHA Le numero de traitement est positionne sur l'entete de DA et non plus sur
---                l'entete de commande
--- 17/04/2002 BHA Le numero de traitement est positionne sur l'entete de la commande et non plus sur
---                l'entete de la DA + envoi par fax
--- 07/06/2002 BHA Lors du test de l'origine de la commande, test du NO_DATA_FOUND
--- 05/03/2007 CDE Procédure PRINT_AND_FAX_ORDER_PDF : Ajout du lancement du STAGE30 (stockage BdC)
--- 07/08/2009 CDE Procédure PRINT_AND_FAX_ORDER_PDF : Ajout du lancement du STAGE40 (Envoi dupli BdC par mail)
--- 21/09/2011 CDE DGE20110006 - Ajout de la Procédure is_asset_order
--- 12/04/2013 JJA DGE20130002 - Ajout de la phase d'exécution XML
--- 01/06/2016 MEG Migration R12 
--- 16/03/2016 MEG Modification artf2120388 
--- 12/02/2018 MEG artf2372180 : Correction du contexte dans le SPE061 et SPE119
--- 15/02/2018 MEG artf2377434 : SPE061 - Approbateur de la commande pour commande issues de DA hors catalogue
--- 08/03/2018 MEG artf2420479 : Problème de generation des bons de commandes en anglais (INC0196270) 
--- 04/04/2018 NBO artf2496480 : INC0202401 4 commande qui reste bloquée chez Laurence Mottez
--- 11/11/2019 SEL artf07322210: INC0321013 Problème de détermination de la responsabilité dans le workflow DKA_POAP
--- 26/06/2020 NBO EDB267 - PFAD - Adaptations Oracle SPE061-SPE063-SPE100
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : IS_ORDER_SSP_APPROVED
        --  Description   : Verification si DA origine SSP5 et approuvee
        --
        --  PARAMETRES    :
        --    itemtype        varchar2
        --    itemkey         varchar2
        --    actid           number
        --    funcmode        varchar2
        --  VALEUR RETOURNEE :
        --     Description       : Resultat de la verification
        --     Valeurs possibles : Yes: 
        --                         No : 
        -------------------------------------------------------------------------------------------------------------------
   PROCEDURE is_order_ssp_approved (
      itemtype    IN       VARCHAR2
     ,itemkey     IN       VARCHAR2
     ,actid       IN       NUMBER
     ,funcmode    IN       VARCHAR2
     ,resultout   OUT      VARCHAR2
   )
   IS
      v_order_approved         VARCHAR2 (1);
      v_po_header_id           po_headers_all.po_header_id%TYPE;
      v_progress               VARCHAR2 (300);
      v_apps_source_code       po_requisition_headers_all.apps_source_code%TYPE;
      v_authorization_status   po_headers_all.authorization_status%TYPE;
   BEGIN
      /* This decision is made by simply looking at an item atrribute,
       * which has a default value. All the user needs to do is change
       * that attribute according to their needs.
       */

      v_po_header_id    :=
                   wf_engine.getitemattrnumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
      v_progress        := '10: is_order_ssp_approved: po_header_id = ' || TO_CHAR (v_po_header_id);
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);

      SELECT prh.apps_source_code
            ,ph.authorization_status
        INTO v_apps_source_code
            ,v_authorization_status
        FROM po_requisition_headers_all prh
            ,po_requisition_lines_all prl
            ,po_line_locations_all pll
            ,po_lines_all pl
            ,po_headers_all ph
       WHERE prh.requisition_header_id = prl.requisition_header_id
         AND prl.line_location_id = pll.line_location_id
         AND pll.po_line_id = pl.po_line_id
         AND pl.po_header_id = ph.po_header_id
         AND ph.po_header_id = v_po_header_id
         AND ROWNUM = 1;

      v_progress        :=    '20: is_order_ssp_approved: apps_source_code = '
                           || v_apps_source_code
                           || ' - v_authorization_status = '
                           || v_authorization_status;

      IF      v_apps_source_code = 'POR'
          AND v_authorization_status = 'APPROVED'
      THEN
         v_progress    := '30: is_order_ssp_approved: return = Y';
         resultout     := wf_engine.eng_completed || ':' || 'Y';
      ELSE
         v_progress    := '30: is_order_ssp_approved: return = N';
         resultout     := wf_engine.eng_completed || ':' || 'N';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_progress    := '30: is_order_ssp_approved: return = N';
         resultout     := wf_engine.eng_completed || ':' || 'N';
      WHEN OTHERS
      THEN
         wf_core.CONTEXT ('DKA_SPOBON_WF_PKG', 'is_order_ssp_approved', v_progress);
         RAISE;
   END is_order_ssp_approved;


        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : PRINT_ORDER_PDF
        --  Description   : Lancement de l'impression du bon de commande au format PDF
        --
        --  PARAMETRES    :
        --    itemtype        varchar2
        --    itemkey         varchar2
        --    actid           number
        --    funcmode        varchar2
        --  VALEUR RETOURNEE :
        --     Description       : 
        --     Valeurs possibles : Activity Performed: 
        -------------------------------------------------------------------------------------------------------------------
   PROCEDURE print_order_pdf (
      itemtype    IN       VARCHAR2
     ,itemkey     IN       VARCHAR2
     ,actid       IN       NUMBER
     ,funcmode    IN       VARCHAR2
     ,resultout   OUT      VARCHAR2
   )
   IS
      v_orgid           NUMBER;
      v_po_header_id    po_headers_all.po_header_id%TYPE;
      v_segment1        po_headers_all.segment1%TYPE;
      v_qty_precision   VARCHAR2 (30);
      v_user_id         VARCHAR2 (30);
      v_request_id      NUMBER := 0;
      v_boolean         BOOLEAN;
      v_progress        VARCHAR2 (300);
      v_success         BOOLEAN;
      e_error_set_lang  EXCEPTION;
	  v_resp_id                NUMBER;
      v_resp_appl_id           NUMBER;
      
   BEGIN
   
      v_progress        := '10 : DKA_SPOBON_WF_PKG.print_order_pdf';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      
      v_po_header_id    := wf_engine.getitemattrnumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');

      SELECT segment1, org_id
        INTO v_segment1, v_orgid
        FROM po_headers_all
       WHERE po_header_id = v_po_header_id;

      v_progress        :=
                  '20 : DKA_SPOBON_WF_PKG.print_order_pdf: po_header_id = ' || TO_CHAR (v_po_header_id) || ' - segment1 = ' || v_segment1;
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);

      -- Do nothing in cancel or timeout mode
      --
      IF (funcmode <> wf_engine.eng_run)
      THEN
         resultout    := wf_engine.eng_null;
         RETURN;
      END IF;

      --v_orgid           := wf_engine.getitemattrnumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');

      IF v_orgid IS NOT NULL
      THEN
         --fnd_client_info.set_org_context (TO_CHAR (v_orgid));
         PO_MOAC_UTILS_PVT.set_org_context(v_orgid) ;       -- <R12 MOAC>
	    
		-- SEL - Debut - artf07322210
		BEGIN 
			SELECT responsibility_id, application_id
			  INTO v_resp_id, v_resp_appl_id
			  FROM fnd_responsibility fr, hr_operating_units hou
			 WHERE hou.organization_id = v_orgid
			   AND fr.responsibility_key = hou.name || '_IP_GEST_DA_RECEPTION';
            
		fnd_profile.get ('USER_ID', v_user_id);
              
              APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                              RESP_ID      => v_resp_id,
                                              RESP_APPL_ID => v_resp_appl_id
                                              );
                                              
              -- positionnement du contexte pour la phase
              Fnd_Request.set_org_id(org_id => v_orgid); 

            EXCEPTION
            WHEN OTHERS THEN
                v_resp_id   := NULL; 
                v_resp_appl_id := NULL; 
               
                fnd_file.put_line(fnd_file.OUTPUT, '. Problème de recupération de la responsabilité ');
                fnd_file.put_line(fnd_file.LOG, '. Problème de recupération de la responsabilité ');
            END;	
			-- SEL - Fin - artf07322210		 
      END IF;

      v_progress        := '30 : DKA_SPOBON_WF_PKG.print_order_pdf';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      -- Get the profile option report_quantity_precision

      fnd_profile.get ('REPORT_QUANTITY_PRECISION', v_qty_precision);
         -- Get the user id for the current user.  This information
      -- is used when sending concurrent request.

      --positionnement de la langue
      v_success := fnd_request.set_options('NO', 'NO', 'FRENCH', 'FRANCE', NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));
                 
      IF (NOT v_success) THEN
         RAISE e_error_set_lang;
      END IF;

      fnd_profile.get ('USER_ID', v_user_id);
      v_boolean         := fnd_request.set_print_options (copies => 0);
      v_progress        := '40 : DKA_SPOBON_WF_PKG.print_order_pdf : set_print_options';
	

      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      v_request_id      := fnd_request.submit_request (
                              'DKA'
                             ,'DKA_SPOBON_PDF'
                             ,NULL
                             ,NULL
                             ,FALSE
                             ,'R'
                             ,NULL
                             ,v_segment1
                             ,v_segment1
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,'Y'
                             ,NULL
                             ,v_user_id
                             ,v_qty_precision
                             ,'N'
                             ,NULL
                             ,'Y'
                             ,'N'
                           );
      v_progress        := '50 : DKA_SPOBON_WF_PKG.print_order_pdf : request_id : ' || TO_CHAR (v_request_id);
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);

      UPDATE po_headers_all
         SET attribute15 = to_char(v_request_id)
       WHERE po_header_id           = v_po_header_id;
   
      resultout         := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
      v_progress        := '60 : DKA_SPOBON_WF_PKG.print_order_pdf PERFORMED';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      
   EXCEPTION
      WHEN e_error_set_lang 
      THEN
        wf_core.CONTEXT ('DKA_SPOBON_WF_PKG.print_order_pdf', 'Erreur lors du positionnement de la langue');
        RAISE;
      WHEN OTHERS
      THEN
         wf_core.CONTEXT ('DKA_SPOBON_WF_PKG.print_order_pdf', v_progress);
         RAISE;
   END print_order_pdf;
   
        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : PRINT_AND_FAX_ORDER_PDF
        --  Description   : Lancement du jeu de traitement d'impression du bon de commande au format PDF et 
        --                  de sa preparation d'envoi par fax
        --
        --  PARAMETRES    :
        --    itemtype        varchar2
        --    itemkey         varchar2
        --    actid           number
        --    funcmode        varchar2
        --  VALEUR RETOURNEE :
        --     Description       :
        --     Valeurs possibles : Activity Performed:
        -------------------------------------------------------------------------------------------------------------------
   PROCEDURE print_and_fax_order_pdf (
      itemtype    IN       VARCHAR2
     ,itemkey     IN       VARCHAR2
     ,actid       IN       NUMBER
     ,funcmode    IN       VARCHAR2
     ,resultout   OUT      VARCHAR2
   )   IS
      v_orgid            NUMBER;
      v_po_header_id     po_headers_all.po_header_id%TYPE;
      v_segment1         po_headers_all.segment1%TYPE;
      v_qty_precision    VARCHAR2 (30);
      vv_dupli_mail_test VARCHAR2(150);
      v_user_id          VARCHAR2 (30);
      v_request_id       NUMBER := 0;
      v_boolean          BOOLEAN;
      v_progress         VARCHAR2 (300);
      v_success          BOOLEAN;
      e_error_set_lang   EXCEPTION;
	  v_resp_id                NUMBER;
      v_resp_appl_id           NUMBER;
      
   BEGIN
   
      v_progress        := '10 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      
      v_po_header_id    := wf_engine.getitemattrnumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');

      SELECT segment1, org_id
        INTO v_segment1, v_orgid
        FROM po_headers_all
       WHERE po_header_id = v_po_header_id;

      v_progress        :=
                  '20 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: po_header_id = ' || TO_CHAR (v_po_header_id) || ' - segment1 = ' || v_segment1;
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);

      -- Do nothing in cancel or timeout mode
      --
      IF (funcmode <> wf_engine.eng_run)
      THEN
         resultout    := wf_engine.eng_null;
         RETURN;
      END IF;

      --v_orgid           := wf_engine.getitemattrnumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');

      IF v_orgid IS NOT NULL
      THEN
         --fnd_client_info.set_org_context (TO_CHAR (v_orgid));
         PO_MOAC_UTILS_PVT.set_org_context(v_orgid) ;       -- <R12 MOAC>
		 
        -- SEL - Debut - artf07322210
		BEGIN 
			SELECT responsibility_id, application_id
			  INTO v_resp_id, v_resp_appl_id
			  FROM fnd_responsibility fr, hr_operating_units hou
			 WHERE hou.organization_id = v_orgid
			   AND fr.responsibility_key = hou.name || '_IP_GEST_DA_RECEPTION';
                
			fnd_profile.get ('USER_ID', v_user_id);  
			
            APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                            RESP_ID      => v_resp_id,
                                            RESP_APPL_ID => v_resp_appl_id
                                            );
                                              
              -- positionnement du contexte pour la phase
              Fnd_Request.set_org_id(org_id => v_orgid); 

            EXCEPTION
            WHEN OTHERS THEN
                v_resp_id   := NULL; 
                v_resp_appl_id := NULL; 
                fnd_file.put_line(fnd_file.OUTPUT, '. Problème de recupération de la responsabilité ');
                fnd_file.put_line(fnd_file.LOG, '. Problème de recupération de la responsabilité ');
            END;
        -- SEL - Fin - artf07322210
		 
      END IF;
	  

      v_progress        := '30 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      -- Get the profile option report_quantity_precision

      fnd_profile.get ('REPORT_QUANTITY_PRECISION', v_qty_precision);
      -- Get the user id for the current user.  This information
      -- is used when sending concurrent request.

      -- Recupere le parametre par defaut pour la phase DKA_SPOBON_DUPLI_MAIL
      BEGIN
        SELECT default_value
          INTO vv_dupli_mail_test
          FROM FND_DESCR_FLEX_COL_USAGE_VL
         WHERE APPLICATION_ID = '50001'
           AND DESCRIPTIVE_FLEXFIELD_NAME LIKE '$SRS$.DKA_SPOBON_DUPLI_MAIL'
           AND end_user_column_name = 'PV_MAIL_TEST';
      EXCEPTION
        WHEN OTHERS THEN
          vv_dupli_mail_test := NULL;
      END;
      
      fnd_profile.get ('USER_ID', v_user_id);
      v_boolean         := fnd_request.set_print_options (copies => 0);
      v_progress        := '40 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf : set_print_options';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      
      -- positionnement du contexte pour le jeu de traitements
      v_progress        := '41 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel set_org_id';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
      fnd_submit.set_org_id(v_orgid);
      
      -- Appel au jeu de traitements
      v_progress        := '42 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel set_request_set';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);  

      --positionnement de la langue
      v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
             
      IF (NOT v_success) THEN
         RAISE e_error_set_lang;
      END IF;

      v_success := fnd_submit.set_request_set('DKA','DKA_SPOBON_PDF_FAX');
      
      IF (v_success) THEN
      
         -- positionnement du contexte pour la phase
         fnd_submit.set_org_id(v_orgid);
         
         --positionnement de la langue
         v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
         
         IF (NOT v_success) THEN
            RAISE e_error_set_lang;
         END IF;
         
         -- appel du programme d'edition au format PDF
         v_progress        := '44 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel submit_program stage10';
         po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
         
          v_success := fnd_submit.submit_program (
                              'DKA'
                             ,'DKA_SPOBON_PDF'
                             ,'STAGE10'
                             ,'R'
                             ,NULL
                             ,v_segment1
                             ,v_segment1
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,'Y'
                             ,NULL
                             ,v_user_id
                             ,v_qty_precision
                             ,'N'
                             ,NULL
                             ,'Y'
                             ,'N'
                           );

        /*
           IF (v_success) THEN
              -- appel du programme de preparation de l'envoi par fax
          
               v_progress        := '46 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel submit_program stage20';
               po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
              v_success := fnd_submit.submit_program (
                              'DKA'
                             ,'DKA_SPOBON_FAX'
                             ,'STAGE20'
                           );
        */
           -->12/04/2013 JJA
           IF (v_success) THEN
               -- appel du programme Imprimer bon de commande en XML

              -- positionnement du contexte pour la phase
              fnd_submit.set_org_id(v_orgid);

              --positionnement de la langue
              v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
             
              IF (NOT v_success) THEN
                 RAISE e_error_set_lang;
              END IF;

              v_progress        := '465 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel submit_program stage25';
              po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
              
              v_success := fnd_submit.submit_program (
                              'DKA'
                             ,'DKA_SPOBON_XML'
                             ,'STAGE25'
                             ,NULL
                             ,NULL
                           );
                           
            --<12/04/2013 JJA
             IF (v_success) THEN
                  -- appel du programme de stockage des bons de commande
          
                  -- positionnement du contexte pour la phase
                  fnd_submit.set_org_id(v_orgid);

                  --positionnement de la langue
                  v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
                 
                  IF (NOT v_success) THEN
                     RAISE e_error_set_lang;
                  END IF;

                  v_progress        := '47 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel submit_program stage30';
                  po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
                  
                  v_success := fnd_submit.submit_program (
                                 'DKA'
                                ,'DKA_SPOBON_STOCIMG'
                                ,'STAGE30'
                              );

                   IF (v_success) THEN
                        -- appel du programme de stockage des bons de commande

                        -- positionnement du contexte pour la phase
                        fnd_submit.set_org_id(v_orgid);

                        --positionnement de la langue
                        v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
                       
                        IF (NOT v_success) THEN
                           RAISE e_error_set_lang;
                        END IF;

                        v_progress        := '48 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel submit_program stage40';
                        po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
                        
                        v_success := fnd_submit.submit_program (
                                       'DKA'
                                      ,'DKA_SPOBON_DUPLI_MAIL'
                                      ,'STAGE40'
                                      ,vv_dupli_mail_test
                                    );

                       IF (v_success) THEN
                            v_progress        := '49 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf: appel submit_set';
                            po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
                            v_request_id := fnd_submit.submit_set(null,FALSE);
                    
                            v_progress        := '50 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf : request_id : ' || TO_CHAR (v_request_id);
                            po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
              
              
                         UPDATE po_headers_all
                            SET attribute15 = to_char(v_request_id)
                          WHERE po_header_id = v_po_header_id;
  
                       END IF; --SUBMIT
                   END IF; --STAGE40
               END IF; --STAGE30
           END IF; --STAGE25
         --END IF; --STAGE20
      END IF; --STAGE10
   
      resultout         := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
      v_progress        := '60 : DKA_SPOBON_WF_PKG.print_and_fax_order_pdf PERFORMED';
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);
   EXCEPTION
      WHEN e_error_set_lang 
      THEN
         wf_core.CONTEXT ('DKA_SPOBON_WF_PKG.print_and_fax_order_pdf', 'Erreur du positionnement de la langue');
         RAISE;
      WHEN OTHERS
      THEN
         wf_core.CONTEXT ('DKA_SPOBON_WF_PKG.print_and_fax_order_pdf', v_progress);
         RAISE;
   END print_and_fax_order_pdf;
   
   
        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : IS_ASSET_ORDER
        --  Description   : Est-ce une commande d'immobilisation ?
        --
        --  PARAMETRES    :
        --    itemtype        varchar2
        --    itemkey         varchar2
        --    actid           number
        --    funcmode        varchar2
        --  VALEUR RETOURNEE :
        --     Description       :
        --     Valeurs possibles : Activity Performed:
        -------------------------------------------------------------------------------------------------------------------
   PROCEDURE is_asset_order (
      itemtype    IN       VARCHAR2
     ,itemkey     IN       VARCHAR2
     ,actid       IN       NUMBER
     ,funcmode    IN       VARCHAR2
     ,resultout   OUT      VARCHAR2
   ) IS
      v_asset_order            VARCHAR2 (1);
      v_po_header_id           po_headers_all.po_header_id%TYPE;
      v_progress               VARCHAR2 (300);
      
   BEGIN


      v_po_header_id    := wf_engine.getitemattrnumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
      v_progress        := '10: is_asset_order: po_header_id = ' || TO_CHAR (v_po_header_id);
      po_wf_debug_pkg.insert_debug (itemtype, itemkey, v_progress);

      BEGIN
      -- Vérification si c'est une commande d'immo ou pas
           SELECT 'Y'
             INTO v_asset_order
             FROM po_headers_all ph
            WHERE ph.po_header_id = v_po_header_id
              AND EXISTS (SELECT 'x' FROM po_distributions_all pda,
                                          gl_code_combinations gcc
                                    WHERE gcc.code_combination_id = pda.code_combination_id
                                      AND pda.po_header_id = ph.po_header_id
                                      AND gcc.segment3 like '2%');

      EXCEPTION    
      WHEN OTHERS THEN
            v_asset_order := 'N';
      
      END;

      v_progress        :=    '20: is_asset_order: v_asset_order = '
                           || v_asset_order;

      IF      v_asset_order = 'Y'
      THEN
         v_progress    := '30: is_asset_order: return = Y';
         resultout     := wf_engine.eng_completed || ':' || 'Y';
      ELSE
         v_progress    := '30: is_asset_order: return = N';
         resultout     := wf_engine.eng_completed || ':' || 'N';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_progress    := '30: is_asset_order: return = N';
         resultout     := wf_engine.eng_completed || ':' || 'N';
      WHEN OTHERS
      THEN
         wf_core.CONTEXT ('DKA_SPOBON_WF_PKG', 'is_asset_order', v_progress);
         RAISE;   
   END is_asset_order;   

   
        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : last_approb_da
        --  Description   : Recherche du dernier approbateur de la DA
        --
        --  PARAMETRES    :
        --    itemtype        varchar2
        --    itemkey         varchar2
        --    actid           number
        --    funcmode        varchar2
        --  VALEUR RETOURNEE :
        --     Description       :
        --     Valeurs possibles : Activity Performed:
        -------------------------------------------------------------------------------------------------------------------
  PROCEDURE last_approb_da(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2) IS
                           
    l_document_id          NUMBER;
    l_orgid                NUMBER;
    x_CanOwnerApproveFlag  VARCHAR2(1);
    l_interface_source     VARCHAR2(30);
    x_progress             VARCHAR2(100);
    l_doc_string           VARCHAR2(200);
    l_preparer_user_name   VARCHAR2(100);
    Vn_employee_id         NUMBER;
    Vn_sequence_num        NUMBER;
    Vn_cpt                 NUMBER;
    Vn_cpt_da_catalog      NUMBER;
    v_progress             VARCHAR2(300);
    Vv_fullname            VARCHAR2(300);
    Vn_seq_cpt             NUMBER;
    Vn_user_id             NUMBER;
    Vv_user_name           VARCHAR2(50);
    Vn_req_distribution_id NUMBER;

  BEGIN

    --debug
    x_progress := 'DKA_SPOBON_WF_PKG.last_approb_da: 01';
    po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);

    --recherche de l'id de la commande (po_header_id)
    l_document_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'DOCUMENT_ID');

    --debug
    x_progress := 'DKA_SPOBON_WF_PKG.last_approb_da: 03 ' || l_document_id;
    po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);

    --recherche de l'org_id de la commande
    l_orgid := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'ORG_ID');

    --debug
    x_progress := 'DKA_SPOBON_WF_PKG.last_approb_da: 04 ' || l_orgid;
    po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);

    --verifie que la commande provient d'une DA
    SELECT COUNT(1)
      INTO Vn_cpt
      FROM po_distributions_all pda
     WHERE pda.po_header_id = l_document_id
       AND pda.req_distribution_id IS NOT NULL;

    --debug
    x_progress := 'DKA_SPOBON_WF_PKG.last_approb_da: 05 ' || Vn_cpt;
    po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);

    --verifie que la commande provient d'une DA catalogue  
    IF l_document_id IS NOT NULL AND l_orgid IS NOT NULL AND Vn_cpt > 0 THEN
    
      SELECT COUNT(1)
        INTO Vn_cpt_da_catalog
        FROM po_distributions_all pda, po_req_distributions_all prda, po_requisition_lines_all prla
       WHERE pda.req_distribution_id = prda.distribution_id
         AND prda.requisition_line_id = prla.requisition_line_id
         AND prla.catalog_type = 'NONCATALOG'
         AND pda.po_header_id = l_document_id;
      
      --debug
      x_progress := 'DKA_SPOBON_WF_PKG.last_approb_da: 04.5 ' || Vn_cpt_da_catalog;
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      
    END IF;

    IF l_document_id IS NOT NULL AND l_orgid IS NOT NULL AND Vn_cpt > 0 AND Vn_cpt_da_catalog = 0 THEN
    
      --recherche du dernier approbateur de la DA
      SELECT a.employee_id, a.full_name, fu.user_id, fu.user_name
        INTO Vn_employee_id, Vv_fullname, Vn_user_id, Vv_user_name
        FROM (SELECT pah.employee_id, popf.full_name
                FROM po_line_locations_all      ploc,
                     po_lines_all               pol,
                     po_headers_all             poh,
                     mtl_system_items_b         mtl,
                     po_requisition_lines_all   prl,
                     po_requisition_headers_all prh,
                     fnd_user                   fnd,
                     po_action_history          pah,
                     per_all_people_f           popf
               WHERE poh.po_header_id = pol.po_header_id
                 AND pol.po_line_id = ploc.po_line_id
                 AND pol.item_id = mtl.inventory_item_id(+)
                 AND ploc.line_location_id = prl.line_location_id
                 AND prl.requisition_header_id = prh.requisition_header_id
                 AND prh.preparer_id = fnd.employee_id
                 AND pah.object_id(+) = prh.requisition_header_id
                 AND pah.employee_id = popf.person_id
                 AND poh.po_header_id = l_document_id
                 AND mtl.organization_id(+) = l_orgid
                 AND pah.object_type_code = 'REQUISITION'
                 AND pah.action_code = 'APPROVE'
               ORDER BY pah.sequence_num DESC) a,
             fnd_user fu
       WHERE a.employee_id = fu.employee_id
         AND rownum = 1;
    
      --debug
      x_progress := 'DKA_SPOBON_WF_PKG.last_approb_da: 06 ' || Vn_employee_id;
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    
      --modification des attributs
    
      --> ID employé de l'approbateur
      wf_engine.SetItemAttrNumber(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'APPROVER_EMPID',
                                  avalue   => Vn_employee_id);
    
      --> Nom utilisateur de l'approbateur
      wf_engine.SetItemAttrText(itemtype => itemType,
                                itemkey  => itemkey,
                                aname    => 'APPROVER_USER_NAME',
      --- 04/04/2018 NBO artf2496480 : INC0202401 4 commande qui reste bloquée chez Laurence Mottez
      --                          avalue   => Vv_fullname);
                                avalue   => Vv_user_name);
    
      --> Nom d'affichage de l'approbateur
      wf_engine.SetItemAttrText(itemtype => itemType,
                                itemkey  => itemkey,
                                aname    => 'APPROVER_DISPLAY_NAME',
                                avalue   => Vv_fullname);
    
      --> ID émetteur
      wf_engine.SetItemAttrNumber(itemtype => itemType,
                                  itemkey  => itemkey,
                                  aname    => 'PREPARER_ID',
                                  avalue   => Vn_employee_id);
    
      --> Nom d'affichage de l'émetteur                      
      wf_engine.SetItemAttrText(itemtype => itemType,
                                itemkey  => itemkey,
                                aname    => 'PREPARER_DISPLAY_NAME',
                                avalue   => Vv_fullname);
    
      --> Nom utilisateur de l'émetteur                   
      wf_engine.SetItemAttrText(itemtype => itemType,
                                itemkey  => itemkey,
                                aname    => 'PREPARER_USER_NAME',
      --- 04/04/2018 NBO artf2496480 : INC0202401 4 commande qui reste bloquée chez Laurence Mottez
      --                          avalue   => Vv_fullname);
                                avalue   => Vv_user_name);
    
      --> ID utilisateur acheteur                        
      wf_engine.SetItemAttrText(itemtype => itemType,
                                itemkey  => itemkey,
                                aname    => 'BUYER_USER_ID',
                                avalue   => Vn_user_id);
    
      --> Nom utilisateur de l'acheteur                       
      wf_engine.SetItemAttrText(itemtype => itemType,
                                itemkey  => itemkey,
                                aname    => 'BUYER_USER_NAME',
                                avalue   => Vv_user_name);

      UPDATE PO_ACTION_HISTORY pah
         SET pah.employee_id = Vn_employee_id,
             pah.object_revision_num = object_revision_num + 1
       WHERE pah.object_id = l_document_id;
      
      COMMIT;
    
      resultout := wf_engine.eng_completed || ':' || 'Y';
    
    ELSE
    
      resultout := wf_engine.eng_completed || ':' || 'N';
    
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_progress := '99: last_approb_da: return = N';
      resultout  := wf_engine.eng_completed || ':' || 'N';
    WHEN OTHERS THEN
      wf_core.CONTEXT('DKA_SPOBON_WF_PKG', 'last_approb_da', v_progress);
      RAISE;
  END last_approb_da;
  
-------------------------------------------------------------------------------------------------------------------
--  Nom           : is_ivalua_order
--  Description   : Recuperation du flag de la commande
--
--  PARAMETRES    :
--    itemtype        varchar2
--    itemkey         varchar2
--    actid           number
--    funcmode        varchar2
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : Activity Performed:
-------------------------------------------------------------------------------------------------------------------
--- 26/06/2020 NBO EDB267 - PFAD - Adaptations Oracle SPE061-SPE063-SPE100
  PROCEDURE is_ivalua_order(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2) IS
    l_document_id NUMBER;
    l_typologie VARCHAR2(100);
	x_progress             VARCHAR2(100);
BEGIN
    --debug
    x_progress := 'DKA_SPOBON_WF_PKG.last_approb_da: 01';
    po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);

    --recherche de l'id de la commande (po_header_id)
    l_document_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'DOCUMENT_ID');
    
    SELECT ATTRIBUTE7 INTO l_typologie FROM PO_HEADERS_ALL WHERE PO_HEADER_ID = l_document_id;
    
    IF l_typologie IN ('REPRISE','IVALUA') THEN
      resultout  := wf_engine.eng_completed || ':' || 'Y'; 
    ELSE
      resultout  := wf_engine.eng_completed || ':' || 'N'; 
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_progress := '99: is_ivalua_order: return = N';
      resultout  := wf_engine.eng_completed || ':' || 'N';
    WHEN OTHERS THEN
      wf_core.CONTEXT('DKA_SPOBON_WF_PKG', 'is_ivalua_order', x_progress);
      RAISE;
  END is_ivalua_order;   
   
END &&package_name;
/
SHOW ERRORS;

EXIT
