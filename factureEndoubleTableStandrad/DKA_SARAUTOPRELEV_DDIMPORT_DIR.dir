CREATE OR REPLACE PACKAGE DKA_SAPIAWIE_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SAPIAWIE_pkg.pks 437 2008-04-10 08:56:09Z NORDEST\viknab $
  --
  -- CAPGEMINI
  -- PROJET      : VEOLIA Puissance 4
  -- NOM         : DKA_SAPIAWIE_PKG.pks
  -- DESCRIPTION : DKA_SAPIAWIE_PKG package spec :
  ---              package spécifique utilisé dans le workflow remplacant le workflow approbation AP
  --- AUTEUR       : Vincent Knab (CAPGEMINI)
  --- DATE DE CREATION : 16/01/2008
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 2016/07/05 JJA Portage Helios R12
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- MODE DEBUG
  --      0 : Non
  --      1 : Partiel
  --      2 : Total, necessite la table     DKA_WF_DEBUG
  --                                            (
  --                                                ITEMKEY VARCHAR2(200),
  --                                                MESSAGE VARCHAR2(4000),
  --                                                HEURE   DATE default sysdate,
  --                                                ID      NUMBER
  --                                              )
  --                           la sequence DKA_WF_DEBUG_SEQ
  cn_mode_debug number := 0;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


  -------------------------------------------------------------------------------------
  --  Nom           : is_facture_perimetre_CSP
  --  Description   : Procédure vérifiant si la facture est dans le périmetre
  --                     d'un CSP
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
    PROCEDURE is_facture_perimetre_CSP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                       pv_funcmode  IN VARCHAR2,
                                       pv_resultout OUT NOCOPY VARCHAR2);



  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_workflow_CSP
  --  Description   : Lance le workflow CSP depuis le workflow standard
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_workflow_CSP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                               pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                               pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                               pv_funcmode  IN VARCHAR2,
                               pv_resultout OUT NOCOPY VARCHAR2);


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : approuve_facture_auto
  --  Description   : approuve la facture en automatique depuis le workflow
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE approuve_facture_auto( pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                   pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                   pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2);

 ---------------------------------------------------------------------------------------------------------------
  --  Nom           : approuve_facture_auto_pl
  --  Description   : approuve facture en automatique depuis le pl
  --                      procédure utilisée depuis le traitement DKA_SAPWFCSP
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE approuve_facture_auto_pl(pn_invoice_id IN ap_invoices_all.invoice_id%type,
           vn_iteration IN AP_INV_APRVL_HIST.ITERATION%type DEFAULT 1 );

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Invoice_image_exists
  --  Description   : Check if image is required and exist for the current invoice.
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE Invoice_image_exists(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                 pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                 pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                 pv_funcmode  IN VARCHAR2,
                                 pv_resultout OUT NOCOPY VARCHAR2);



END DKA_SAPIAWIE_pkg; -- Spécification du package
/

SHOW ERROR PACKAGE DKA_SAPIAWIE_pkg;
EXIT

