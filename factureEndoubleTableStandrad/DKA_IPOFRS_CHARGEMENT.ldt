CREATE OR REPLACE PACKAGE DKA_SAPWFCSP_pkg AS
---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SAPWFCSP_PKG.pks 1668 2009-03-27 14:53:15Z CORP\viknab $
  --
  -- CAPGEMINI
  -- PROJET      : VEOLIA Puissance 4
  -- NOM         : DKA_SAPWFCSP_PKG.pks
  -- DESCRIPTION : DKA_SAPWFCSP_PKG package spec :
  ---
  --- AUTEUR       : Vincent Knab (CAPGEMINI)
  --- DATE DE CREATION : 16/01/2008
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 2016/07/05 JJA Portage Helios R12
  --- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
  --- 2021/10/06 AFE -  artf07468199  - Correctif - Autoriser comptabilisation suite déblocage Affacturage
  --- 2025/01/22 SHA - EDB408 - Oracle WF AP - Approbation du BAP SSTR dans D@cshop - DSP 1454
  ---------------------------------------------------------------------------------------------------------------
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  cv_contexte_OSC AP_INVOICES_INTERFACE.ATTRIBUTE_CATEGORY%type := 'OSC';
  cv_contexte_XGS AP_INVOICES_INTERFACE.ATTRIBUTE_CATEGORY%type := 'XGS';
  cv_user_blocage fnd_user.user_name%type := 'EXPLOITATION';

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
  --                           la sequence DKA_wf_debug_seq
  cn_mode_debug number := 2;
--class="OraDataText"
--L_TITRE_STYLE VARCHAR2(100) := ' class="OraGlobalPageTitle"  align=center ';

L_TABLE_STYLE VARCHAR2(100) := ' cellspacing=0 cellpadding=5 border=1 bordercolor=#000000 width=100% ';

L_TABLE_HEADER_STYLE VARCHAR2(100) := ' valign=bottom BGCOLOR=#cccc99  ';


L_FONT_HEADER_STYLE VARCHAR2(100):= ' size=-1  color=#336699 ';

L_FONT_CELL_STYLE VARCHAR2(100):= ' size=-1  color=black ';


--L_FONT_LITIGE_STYLE VARCHAR2(100):= ' size=+1  color=red STYLE=text-decoration:underline ';

-- L_FONT_TEXTE_A_RESSORTIR_STYLE VARCHAR2(100):= ' size=+1  color=black  ';

L_TABLE_LABEL_STYLE VARCHAR2(100) := '   align=right ';

L_TABLE_CELL_STYLE VARCHAR2(100) := '   align=left ';

L_TABLE_CELL_UNIQUE_STYLE VARCHAR2(100) := '   align=left valign=top rowspan=50 ';


L_TABLE_CELL_WRAP_STYLE VARCHAR2(100) := ' align=left ';

L_TABLE_CELL_RIGHT_STYLE VARCHAR2(100) := ' cellspacing=0 cellpadding=2   align=right ';

L_TABLE_CELL_CENTER_STYLE VARCHAR2(100) := '   align=center ';

L_TABLE_CELL_HIGH_STYLE VARCHAR2(100) := '   align=left ';

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  type tableau is TABLE OF VARCHAR2(20);


PROCEDURE string_to_table(vv_chaine IN VARCHAR2, vv_separateur IN VARCHAR2,
       l_tab OUT tableau,   vn_tablen OUT  number );


  -------------------------------------------------------------------------------------
  --  Nom           : print_wf_message
  --  Description   : Procédure insérant un message dans le log du traitement.
  --
  --  PARAMETRES :
  --     p_message   Entrée      Message a insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE print_wf_message(pv_itemtype IN VARCHAR2,
                             pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                             pv_message   IN VARCHAR2,
                             pn_mode_debug   IN NUMBER);

  PROCEDURE contexte_PNC(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                         pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                         pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                         pv_funcmode  IN VARCHAR2,
                         pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : debloque
  --  Description   : Procédure enlevant un blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup Sucess/fail
  -------------------------------------------------------------------------------------
  PROCEDURE debloque(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                     pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                     pv_funcmode  IN VARCHAR2,
                     pv_resultout OUT NOCOPY VARCHAR2);
  -------------------------------------------------------------------------------------
  --  Nom           : debloque_aff
  --  Description   : Procédure enlevant un blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup Sucess/fail
  -------------------------------------------------------------------------------------
  PROCEDURE debloque_aff(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                     pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                     pv_funcmode  IN VARCHAR2,
                     pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : pre_notification
  --  Description   : Procédure pour mettre a jour certains champs des notifs
  --                        - URL de l'image qui a une durée de validité limitée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup Sucess/fail
  -------------------------------------------------------------------------------------
  PROCEDURE pre_notification(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                     pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                     pv_funcmode  IN VARCHAR2,
                     pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : exists_blocage_type
  --  Description   : Procédure vérifiant si la facture a un blocage
  --                     du type spécifié
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE exists_blocage_type(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);

    -------------------------------------------------------------------------------------
  --  Nom           : exists_misc_holds
  --  Description   : Procedure to verify misc holds
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE exists_misc_holds(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : exists_blocage
  --  Description   : Procédure vérifiant si la facture a un blocage non marque et non leve
  --                    avant appro definitive
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE exists_blocage(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);
								
--SHA EDB408
------------------------------------------------------------------------------------
    --  Nom           : CommandeSSTR_ivalua
    --  Description   : Procédure creant les factures sur commandes SSTR IVALUA
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
PROCEDURE CommandeSSTR_ivalua(
        p_invoice_id IN NUMBER,
        p_itemtype   IN VARCHAR2,
        p_itemkey    IN VARCHAR2
    ) ;
  -------------------------------------------------------------------------------------
  --  Nom           : demarque_blocage_BAP
  --  Description   : Procédure suppimant l'indication que le blcage bap en attente
  --                     est en cours de traitement
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE demarque_blocage_BAP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2) ;

/*
  -------------------------------------------------------------------------------------
  --  Nom           : exists_blocage_a_traiter
  --  Description   : Procédure vérifiant si la facture a au moins un blocage
  --                     a traiter
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE exists_blocage_a_traiter(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                      pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                      pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                      pv_funcmode  IN VARCHAR2,
                                      pv_resultout OUT NOCOPY VARCHAR2);

*/
  -------------------------------------------------------------------------------------
  --  Nom           : superieur_bap
  --  Description   : Procédure amenant le supérieur de l'employé
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE superieur_bap (pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                           pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                           pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                           pv_funcmode  IN VARCHAR2,
                           pv_resultout OUT NOCOPY VARCHAR2);
/*
 PROCEDURE recup_reponse_Chef_Expl_Imput(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                       pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                       pv_funcmode  IN VARCHAR2,
                                       pv_resultout OUT NOCOPY VARCHAR2);
*/
 -------------------------------------------------------------------------------------
  --  Nom           : acheteur_commande
  --  Description   : Procédure retournant l'acheteur de la commande
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE acheteur_commande(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                              pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                              pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                              pv_funcmode  IN VARCHAR2,
                              pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : pose_blocage_litige
  --  Description   : Procédure creant un blocage en litiga avec motif
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE pose_blocage_litige(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : transfert_codes_blocages_OI_AP
  --  Description   : Procédure creant les blocages AP a partir des blacages OI
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE transfert_codes_blocages_OI_AP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                           pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                           pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                           pv_funcmode  IN VARCHAR2,
                                           pv_resultout OUT NOCOPY VARCHAR2);

 /* PROCEDURE recup_employe_A_trans(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : recupere_Motif_OU_Transfert
  --  Description   :
  --                    Methode qui recupere le motif du refus (si refuse)
  --                           ou la personne a qui on a transferer (si transfert)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE recupere_Motif_OU_Transfert(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                        pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                        pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                        pv_funcmode  IN VARCHAR2,
                                        pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : recupere_Motif_Litige
  --  Description   :
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE recupere_Motif_Litige(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);
*/
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_workflow_CSP
  --  Description   : Lance le workflow CSP depuis PLSQL
  --
  --  PARAMETRES    :
  --                     pn_fact_AP_OI  0 => OI , 1 => AP
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_workflow_CSP_PL(pv_errbuf     OUT VARCHAR2,
                                  pn_retcode    IN OUT NUMBER,
                                  pn_id_facture IN NUMBER,
                                  pn_fact_AP_OI IN number default 0);

   -------------------------------------------------------------------------------------
  --  Nom           : initialise_workflow_OI
  --  Description   :  procédure utilisée dans le Workflow CSP partie Open Interface
  --                     pour initialiser les items attributes du workflos
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
 PROCEDURE initialise_workflow_OI(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                   pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                   pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2);

 -------------------------------------------------------------------------------------
  --  Nom           : termine_workflow_OI
  --  Description   :
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE termine_workflow_OI(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                   pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                   pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2);
/*
PROCEDURE doc_histo(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                   pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                   pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2);
*/
  -------------------------------------------------------------------------------------
  --  Nom           :
  --  Description   : Procédure incrementant le N° relance
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE incremente_relance(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : initialise_workflow_AP
  --  Description   :  procédure utilisée dans le Workflow CSP partie factures AP
  --                     pour initialiser les items attributes du workflos
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE initialise_workflow_AP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                   pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                   pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : reponse_notif_precedente
  --  Description   :
  --
  --  PARAMETRES :
  --
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE reponse_notif_precedente(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                         pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                         pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                         pv_funcmode  IN VARCHAR2,
                         pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_OI
  --  Description   :   Procedure gérant la notification que recoit CSP ANO
  --                            pour une ano OI (etape 2 du WF n°1)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_OI(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_OI_REP
  --  Description   :   Procedure gérant la notification que recoit CSP ANO
  --                            en réponse au CSP REF pour une ano OI  (apres l'etape 3 du WF n°1)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_OI_REP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_REF_OI
  --  Description   :   Procedure gérant la notification que recoit CSP REF
  --                            en trsnfert de CSP ANO pour une ano OI  (etape 3 du WF n°1)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_REF_OI(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);


 -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_IMPUT_ATT
  --  Description   :   Procedure gérant la notification que recoit CSP_ANO
  --                            pour une ano INPUTATION_EN_ATTENTE (etape 5 du WF n°1)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_IMPUT_ATT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);



-------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_RET_IMPUT_ATT
  --  Description   :   Procedure gérant la notification que recoit CSP_ANO
  --                            en retour d'une ano INPUTATION_EN_ATTENTE (etape 11 du WF n°1)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_RET_IMPUT_ATT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

 -------------------------------------------------------------------------------------
  --  Nom           : notif_EXPLOIT_IMPUT_ATT
  --  Description   :   Procedure gérant la notification que recoit le chef d'exploitation
  --                            pour une ano INPUTATION_EN_ATTENTE (etape 6 du WF n°1)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_EXPLOIT_IMPUT_ATT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           :
  --  Description   : Procédure en attente
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE en_attente(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_EXPLOIT_BAP
  --  Description   :   Procedure gérant la notification que recoit le chef d'exploitation
  --                            pour une ano BAP
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_EXPLOIT_BAP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_PRLV
  --  Description   :   Procedure gérant la notification que recoit CSP ano pour ano Prelevement
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_PRLV(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);


 -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_AFFACT
  --  Description   :   Procedure gérant la notification que recoit CSP ano pour ano affacturage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_AFFACT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

 -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_REF_AFFACT
  --  Description   :   Procedure gérant la notification que recoit CSP REF pour ano affacturage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_REF_AFFACT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_RIB
  --  Description   :   Procedure gérant la notification que recoit CSP ano pour ano RIB
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_RIB(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : notif_HIERAR_EXPLOIT_BAP
  --  Description   :   Procedure gérant la notification que recoit la hierarchie du chef d'exploitation
  --                            pour une ano BAP
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_HIERAR_EXPLOIT_BAP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);


 -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_BAP
  --  Description   :   Procedure gérant la notification que recoit CSP_ANO
  --                            pour une ano BAP (etape 13 du WF n°1)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_BAP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) ;

 -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_DIVERS
  --  Description   :   Procedure gérant la notification que recoit le CSP ANO
  --                            pour une ano diverse (WF n°10)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_DIVERS(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) ;


  -------------------------------------------------------------------------------------
  --  Nom           : facture_OI
  --  Description   : Procédure vérifiant si la facture a été importée depuis
  --                    l'Open Interface
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE facture_OI(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                       itemkey      IN WF_ITEMS.ITEM_KEY%type,
                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                       pv_funcmode  IN VARCHAR2,
                       pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : exists_BR_ligne_Cmd
  --  Description   : Procédure vérifiant s'il existe un BR sur sur une ligne de la commande
  --                            qui a été rapprochée de la facture
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE exists_BR_ligne_Cmd(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey  IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);



  -------------------------------------------------------------------------------------
  --  Nom           : employe_Droit_habilitation
  --  Description   : Procédure vérifiant si l'employé a les droits d'habilitation
  --                    pour positionner le BAP pour cette facture
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE employe_Droit_habilitation(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                       pv_funcmode  IN VARCHAR2,
                                       pv_resultout OUT NOCOPY VARCHAR2);

  ---------------------------------------------------------------------------------
  --  Nom           : gestion_deblocage_variance
  --  Description   : Procédure de retraitement des notifications liées
  --                       au blocage variance
  --
  --  PARAMETRES :
  --
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE gestion_deblocage_variance ( pv_errbuf     OUT VARCHAR2,
                                  pn_retcode    IN OUT NUMBER,
                                  pv_CSP        IN VARCHAR2,
                                  pv_division   IN VARCHAR2);

-------------------------------------------------------------------------------------
  --  Nom           : batch_traite_factures
  --  Description   : Procédure de l'executable rattache au traitement DKA_SAPWFCSP
  --                lance le workflow spécifique d'approbation des factures pour chaque facture OI ou AP
  --                geree par CSP
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE batch_traite_factures ( pv_errbuf     OUT VARCHAR2,
                                  pn_retcode    IN OUT NUMBER,
                                  pv_CSP        IN VARCHAR2,
                                  pv_division   IN VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : determine_role_associe_facture
  --  Description   : Fonction utilisée pour déterminer les responsabilites CSP
  --                    associées a la facture
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  function determine_role_associe_facture(pv_region   IN varchar2,
                                          pn_org_id   IN ap_invoices_interface.org_id%type,
                                          pv_societe  IN ap_invoices_interface.doc_category_code%type,
                                          pv_resp_csp IN fnd_profile_option_values.profile_option_value%type,
                                          pv_errbuf   OUT VARCHAR2,
                                          pn_retcode  IN OUT NUMBER)
    return varchar2;


  -------------------------------------------------------------------------------------
  --  Nom           : get_action_history
  --  Description   : Procédure utilisée pour afficher le tableau d'historique
  --                    des actions sur la facture dans les notifications
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
   PROCEDURE get_action_history(pv_document_id        in      varchar2,
                                 pv_display_type   in      varchar2,
                                 pv_document       in out NOCOPY  varchar2,
                                 pv_document_type  in out NOCOPY  varchar2);


  -------------------------------------------------------------------------------------
  --  Nom           : get_infos_AP
  --  Description   : Procédure utilisée pour afficher le tableau d'informations
  --                    sur la facture AP dans les notifications
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
PROCEDURE   get_infos_AP (pv_document_id        in      varchar2,
                                 pv_display_type   in      varchar2,
                                 pv_document       in out NOCOPY  varchar2,
                                 pv_document_type  in out NOCOPY  varchar2);


  -------------------------------------------------------------------------------------
  --  Nom           : get_infos_OI
  --  Description   : Procédure utilisée pour afficher le tableau d'informations
  --                    sur la facture de l'open interface dans les notifications
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
PROCEDURE   get_infos_OI (pv_document_id        in      varchar2,
                                 pv_display_type   in      varchar2,
                                 pv_document       in out NOCOPY  varchar2,
                                 pv_document_type  in out NOCOPY  varchar2);

PROCEDURE insert_history_wf(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) ;

  -------------------------------------------------------------------------------------
  --  Nom           : insert_history
  --  Description   : Procédure insérant un message dans l'historique de la facture.
  --
  --  PARAMETRES :
  --     p_message   Entrée      Message a insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
PROCEDURE insert_history(pv_itemtype    IN WF_ITEMS.ITEM_TYPE%TYPE,
                         pv_itemkey     IN WF_ITEMS.ITEM_KEY%TYPE,
                         pv_status       IN AP_INV_APRVL_HIST.RESPONSE%TYPE,
                         pv_code_blocage IN VARCHAR2,
                         pv_COMMENTS     IN AP_INV_APRVL_HIST.APPROVER_COMMENTS%TYPE,
                         pv_destinataire IN VARCHAR2 DEFAULT NULL);
						 
						 
-------------------------------------------------------------------------------------
  --  Nom           : superieur_ecart_prix
  --  Description   : Procédure amenant le supérieur de l'acheteur
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE superieur_ecart_prix(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                 pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                 pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                 pv_funcmode  IN VARCHAR2,
                                 pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : employe_price_habilitation
  --  Description   : Procédure vérifiant si l'employé a les droits d'habilitation
  --                    pour approuver la facture
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE employe_price_habilitation(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                       pv_funcmode  IN VARCHAR2,
                                       pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_PRICE
  --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
  --                     anomalie d'écart de prix
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_PRICE(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);
  
  ----------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_PRICE_NC
  --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
  --                     anomalie d'écart de prix pour hors catalogue
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_PRICE_NC(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

-------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_NC_PRICE_INTIATEUR
  --  Description   :   Procedure gérant la notification que reçoit le initiateur DA
  --                    prix hors catalogue
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_NC_PRICE_INTIATEUR(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                         pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                         pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                         pv_funcmode  IN VARCHAR2,
                                         pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_ACH_ANO_PRICE
  --  Description   :   Procedure gérant la notification que reçoit l'acheteur pour une
  --                     anomalie d'écart de prix
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_ACH_ANO_PRICE(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_DDEUR_ANO_PRICE
  --  Description   :   Procedure gérant la notification que reçoit le demandeur pour une
  --                     anomalie d'écart de prix
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_DDEUR_ANO_PRICE(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : notif_HIERAR_DDEUR_ANO_PRICE
  --  Description   :   Procedure gérant la notification que reçoit la hierarchie du
  --                     demandeur pour une anomalie d'écart de prix
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_HIERAR_DDEUR_ANO_PRICE(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);


-------------------------------------------------------------------------------------
  --  Nom           : get_ecart_prix
  --  Description   : Procédure utilisée pour afficher le tableau des écart de prix sur
  --                  la facture
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
PROCEDURE get_ecart_prix(pv_document_id        in      varchar2,
                         pv_display_type   in      varchar2,
                         pv_document       in out NOCOPY  varchar2,
                         pv_document_type  in out NOCOPY  varchar2);

-------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_QTY_REC
  --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
  --                     anomalie quantité facturée dépasse la quantité réceptionnée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_QTY_REC(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

-------------------------------------------------------------------------------------
  --  Nom           : notif_DDEUR_ANO_QTY_REC
  --  Description   :   Procedure gérant la notification que reçoit le demandeur pour une
  --                     anomalie quantité facturée dépasse la quantité réceptionnée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_DDEUR_ANO_QTY_REC(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                    pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                    pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2);


 -------------------------------------------------------------------------------------
  --  Nom           : notif_CHEF_EXPLOT_QTY_REC
  --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
  --                     anomalie quantité facturée dépasse la quantité réceptionnée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CHEF_EXPLOT_QTY_REC(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) ;
  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_QTY_ORD
  --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
  --                     anomalie quantité facturée dépasse la quantité commandée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_QTY_ORD(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_ACH_ANO_QTY_ORD
  --  Description   :   Procedure gérant la notification que reçoit l'acheteur pour une
  --                     anomalie quantité facturée dépasse la quantité commandée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_ACH_ANO_QTY_ORD(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_HIERAR_ACH_ANO_QTY_ORD
  --  Description   : Procedure gérant la notification que reçoit la hierarchie de
  --                      l'acheteur pour une  anomalie quantité facturée dépasse
  --                      la quantité commandée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_HIERAR_ACH_ANO_QTY_ORD(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : employe_qty_ord_habilitation
  --  Description   : Procédure vérifiant si l'employé a les droits d'habilitation
  --                    pour approuver la facture
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE employe_qty_ord_habilitation(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                         pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                         pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                         pv_funcmode  IN VARCHAR2,
                                         pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : superieur_qty_ord
  --  Description   : Procédure amenant le supérieur de l'acheteur
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE superieur_qty_ord(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                              pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                              pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                              pv_funcmode  IN VARCHAR2,
                              pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_CMD_MULT
  --  Description   :   Procedure gérant la notification que reçoit CSP pour une
  --                     anomalie de commande multiple
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_CSP_ANO_CMD_MULT (pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                    pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                    pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : abort_previous_workflow
  --  Description   :   Procedure annulant les workflows précédents sur la facture
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE abort_previous_workflow (pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2);      
                         
  -------------------------------------------------------------------------------------
  --  Nom           : Asset_invoice
  --  Description   :   Procedure to check whether the invocie lines consist asset codes
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------

  PROCEDURE Asset_invoice(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2);
  -------------------------------------------------------------------------------------
  --  Nom           : ADD_HOLD_CODE
  --  Description   :   Procedure to add hold code at invocie header attribute1
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------


  PROCEDURE ADD_HOLD_CODE(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2);

 
  -------------------------------------------------------------------------------------
  --  Nom           : is_catalogue_order
  --  Description   :   procedure to check whether the invoice is linked to catalogue order or not
 --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE is_catalogue_order (pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2);                 
                                     
-- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
  PROCEDURE AP_SELECTOR (
  p_itemtype   IN VARCHAR2,
  p_itemkey    IN VARCHAR2,
  p_actid      IN NUMBER,
  p_funcmode   IN VARCHAR2,
  p_x_result   IN OUT NOCOPY VARCHAR2);    

  -------------------------------------------------------------------------------------
  --  Nom           : cree_blocage_AP
  --  Description   : Cree le blocage AP sur la facture  pn_invoice_id
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE cree_blocage_AP(pv_source         in varchar2,
                            pn_invoice_id     IN ap_invoices_all.invoice_id%type,
                            pv_blocage_AP     IN ap_invoices_interface.attribute1%type,
                            pv_blocage_reason IN ap_holds_all.hold_reason%type,
                            pv_line_loc_id    IN ap_holds_all.line_location_id%TYPE, --- 07022011   MT
                            pn_user_id        IN fnd_user.user_id%type,
                            pv_itemtype       IN VARCHAR2,
                            pv_itemkey        IN VARCHAR2,
                            pv_errbuf         OUT NOCOPY VARCHAR2,
                            pn_retcode        OUT NOCOPY NUMBER);  

  procedure get_item_info(pv_document_id in varchar2,
                          pv_itemtype    out nocopy wf_items.item_type%TYPE,
                          pv_itemkey     out nocopy wf_items.item_key%TYPE,
                          vn_nid         out nocopy number);

  FUNCTION get_blocages_AP(pn_invoice_id in number,
                           pv_type_notif VARCHAR2,
                           pv_item_key   in varchar2) RETURN varchar2;                                                              

    -------------------------------------------------------------------------------------
    --  Nom           : leve_blocage
    --  Description   :  leve_blocage le blocage de type pv_blocage_AP sur la facture  pn_invoice_id
    --                           avec l'utilisateur pn_user_id
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE leve_blocage(pn_invoice_id     IN ap_invoices_all.invoice_id%type,
                           pv_blocage_AP     IN ap_invoices_interface.attribute1%type,
                           pv_deblocage      IN ap_lookup_codes.displayed_field%type,
                           pn_user_id        IN fnd_user.user_id%type,
                           pv_errbuf         OUT NOCOPY VARCHAR2,
                           pn_retcode        OUT NOCOPY NUMBER,
                           pn_verif_orig     IN number default 1,
                           pv_wf_item_type   in varchar2,
                           pv_wf_item_key    in varchar2,
                           pv_release_reason in varchar2 default null);
                           
   -------------------------------------------------------------------------------------
    --  Nom           : leve_blocage_aff
    --  Description   :  leve_blocage le blocage de type pv_blocage_AP sur la facture  pn_invoice_id
    --                           avec l'utilisateur pn_user_id
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE leve_blocage_aff(pn_invoice_id     IN ap_invoices_all.invoice_id%type,
                           pv_blocage_AP     IN ap_invoices_interface.attribute1%type,
                           pv_deblocage      IN ap_lookup_codes.displayed_field%type,
                           pn_user_id        IN fnd_user.user_id%type,
                           pv_errbuf         OUT NOCOPY VARCHAR2,
                           pn_retcode        OUT NOCOPY NUMBER,
                           pn_verif_orig     IN number default 1,
                           pv_wf_item_type   in varchar2,
                           pv_wf_item_key    in varchar2,
                           pv_release_reason in varchar2 default null);                           

END DKA_SAPWFCSP_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE DKA_SAPWFCSP_PKG;
EXIT
