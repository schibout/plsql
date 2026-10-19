CREATE OR REPLACE PACKAGE dka_sapwfcsp_ivalua_pkg AS
  --------------------------------------------------------------------------------
  -- $Id: DKA_SAPWFCSP_IVALUA_PKG.pks  $
  -- Capgemini
  -- Projet           :
  -- Nom              : DKA_SAPWFCSP_IVALUA_PKG.pks
  -- Description      : Spécification du package DKA_SAPWFCSP_IVALUA_PKG
  -- Auteur           : Asma AMENKOUR
  -- Date de création : 12/10/2020
  -- Commentaires     :
  --------------------------------------------------------------------------------

  -------------------------------------------------------------------------------------
  --  Nom           : insert_DKA_SICXRECHCAT_HIST
  --  Description   : 

  -------------------------------------------------------------------------------------
  PROCEDURE update_data(p_user_id    IN NUMBER,
                        p_facture_id IN NUMBER,
                        p_emp        IN VARCHAR2,
                        p_return_status OUT NUMBER,
                        p_error_message OUT VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_IMPUT_ATT_IVALUA
  --  Description   :   Procedure gérant la notification que recoit CSP_ANO
  --                            pour une ano INPUTATION_EN_ATTENTE (etape 5)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_csp_ano_imput_att_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                           pv_itemkey   IN wf_items.item_key%TYPE,
                                           pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                                           pv_funcmode  IN VARCHAR2,
                                           pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : pose_blocage
  --  Description   : Procédure creant un blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE pose_blocage(pv_itemtype  IN wf_items.item_type%TYPE,
                         pv_itemkey   IN wf_items.item_key%TYPE,
                         pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                         pv_funcmode  IN VARCHAR2,
                         pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : maj_blocage
  --  Description   : Procédure pour mettre à jour un blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE maj_blocage(pv_itemtype  IN wf_items.item_type%TYPE,
                        pv_itemkey   IN wf_items.item_key%TYPE,
                        pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                        pv_funcmode  IN VARCHAR2,
                        pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_IMPUT_ATT_IVALUA
  --  Description   :   Procedure gérant la notification que recoit CSP_ANO
  --                            pour une ano INPUTATION_EN_ATTENTE (etape 5)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_dest_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                              pv_itemkey   IN wf_items.item_key%TYPE,
                              pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                              pv_funcmode  IN VARCHAR2,
                              pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : insert_history_ivalua
  --  Description   : Procédure insérant un message dans l'historique de la facture.
  --
  --  PARAMETRES :
  --     p_message   Entrée      Message a insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE insert_history_ivalua(pv_itemtype     IN wf_items.item_type%TYPE,
                                  pv_itemkey      IN wf_items.item_key%TYPE,
                                  pv_status       IN ap_inv_aprvl_hist.response%TYPE,
                                  pv_code_blocage IN VARCHAR2,
                                  pv_comments     IN ap_inv_aprvl_hist.approver_comments%TYPE,
                                  pv_destinataire IN VARCHAR2 DEFAULT NULL);

  -------------------------------------------------------------------------------------
  --  Nom           : pre_notification_ivalua
  --  Description   : Procédure pour mettre a jour certains champs des notifs
  --                        - URL de l'image qui a une durée de validité limitée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup Sucess/fail
  -------------------------------------------------------------------------------------
  PROCEDURE pre_notification_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                    pv_itemkey   IN wf_items.item_key%TYPE,
                                    pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : get_action_history_ivalua
  --  Description   : Procédure utilisée pour afficher le tableau d'historique
  --                    des actions sur la facture dans les notifications
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE get_action_history_ivalua(pv_document_id   IN VARCHAR2,
                                      pv_display_type  IN VARCHAR2,
                                      pv_document      IN OUT NOCOPY CLOB,
                                      pv_document_type IN OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : get_infos_AP_ivalua
  --  Description   : Procédure utilisée pour afficher le tableau d'informations
  --                    sur la facture AP dans les notifications
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE get_infos_ap_ivalua(pv_document_id   IN VARCHAR2,
                                pv_display_type  IN VARCHAR2,
                                pv_document      IN OUT NOCOPY CLOB,
                                pv_document_type IN OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_reponse_ivalua
  --  Description   : Procedure gérant la notification dans le retour Ivalua
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_reponse_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                 pv_itemkey   IN wf_items.item_key%TYPE,
                                 pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                                 pv_funcmode  IN VARCHAR2,
                                 pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : traitement_blocage_ivalua
  --  Description   : Procedure de traitement du blocage « En attente » conformément à la réponse au BAP reçue d’IVALUA
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE traitement_blocage_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                      pv_itemkey   IN wf_items.item_key%TYPE,
                                      pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                                      pv_funcmode  IN VARCHAR2,
                                      pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : debloque_null
  --  Description   : Procédure enlevant un blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup Sucess/fail
  -------------------------------------------------------------------------------------
  PROCEDURE debloque_null(pv_itemtype  IN wf_items.item_type%TYPE,
                          pv_itemkey   IN wf_items.item_key%TYPE,
                          pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                          pv_funcmode  IN VARCHAR2,
                          pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : is_ivalua_order
  --  Description   : Procedure de traitement du blocage « En attente » conformément à la réponse au BAP reçue d¿IVALUA
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE is_ivalua_order(pv_itemtype  IN wf_items.item_type%TYPE,
                            pv_itemkey   IN wf_items.item_key%TYPE,
                            pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                            pv_funcmode  IN VARCHAR2,
                            pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_ecartprix_ivalua
  --  Description   : Procedure gérant la notification dans le transfert Ivalua
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_ecartprix_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                   pv_itemkey   IN wf_items.item_key%TYPE,
                                   pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : get_ecart_prix_valua
  --  Description   : Procédure utilisée pour afficher le tableau des écart de prix sur
  --                  la facture
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE get_ecart_prix_ivalua(pv_document_id   IN VARCHAR2,
                                  pv_display_type  IN VARCHAR2,
                                  pv_document      IN OUT NOCOPY CLOB,
                                  pv_document_type IN OUT NOCOPY VARCHAR2);

  PROCEDURE insert_history_wf_ivalua(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_QTY_REC_IV
    --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
    --                     anomalie quantité facturée dépasse la quantité réceptionnée
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_QTY_REC_IV(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                    pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                    pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2);

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_ORD_REC_IV
    --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
    --                     anomalie quantité commandée dépasse la quantité réceptionnée
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_QTY_ORD_IV(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                    pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                    pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2);  

  -------------------------------------------------------------------------------------
  --  Nom           : get_reponse_blocage_ivalua
  --  Description   : Procedure de verification du blocage « En attente »avec le flag 'Y'
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE get_reponse_blocage_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                 pv_itemkey   IN wf_items.item_key%TYPE,
                                 pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                 pv_funcmode  IN VARCHAR2, -- Ignore
                                 pv_resultout OUT NOCOPY VARCHAR2);
								 
  -------------------------------------------------------------------------------------
  --  Nom           : verif_blocage_ivalua
  --  Description   : Procedure de verification du blocage « En attente »avec le flag 'Y'
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE verif_blocage_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                 pv_itemkey   IN wf_items.item_key%TYPE,
                                 pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                 pv_funcmode  IN VARCHAR2, -- Ignore
                                 pv_resultout OUT NOCOPY VARCHAR2);                                 
END dka_sapwfcsp_ivalua_pkg;
/
show error;
exit;
