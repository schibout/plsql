-- =====================================================================
-- DKA_SAPWFCSP_PKG
-- Telecharge depuis Oracle EBS Production (APPS)
-- Date : 15/04/2026 11:50
-- =====================================================================

CREATE OR REPLACE 
PACKAGE DKA_SAPWFCSP_pkg AS
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
--class=""OraDataText""
--L_TITRE_STYLE VARCHAR2(100) := ' class=""OraGlobalPageTitle""  align=center ';

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

END DKA_SAPWFCSP_pkg; -- Spécification du package"
1,257 rows selected. 

/

CREATE OR REPLACE 
PACKAGE BODY      DKA_SAPWFCSP_PKG AS
    ---------------------------------------------------------------------------------------------------------------
    -- $Id: DKA_SAPWFCSP_PKG.pkb 2104 2009-09-14 12:19:28Z CORP\mslama $
    --
    -- CAPGEMINI
    -- PROJET      : VEOLIA Puissance 4
    -- NOM         : DKA_SAPWFCSP_PKG.pkb
    -- DESCRIPTION : DKA_SAPWFCSP_PKG package body :
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
    --- 2017/03/17 EFL artf2123489: Lors au tests sur l'artifact, erreur conversion numerique -> ajout de to_char(vt_org_id_ap(i))
    --- 2017/04/03 JJA artf2133477 : correction de la recherche du nom du role (Any security group)
    --- 2017/06/14 NBO artf2171340 - SPE129 - WF Factures - Actions Refus Reglement - Le blocage Litige ne se crée pas Defect 618
    --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
    --- 2018/03/14 OBE artf2435790 : INC0198297 : Correctifs sur le WF FActures - Simplifcation du WF
    --- 2018/10/04 OBE artf2899273 : INC0233671 : Correctif sur WF Factures - Simplification du WF
  --- 2019/02/12 SFA artf07151619: SPE129 - INC0288855 - Correctif sur notification écart de prix
  --- 2019/02/25 SFA INC0290921 - Problème d'alignement statut sur une facture
  --- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
  --  2020/06/02 MTIA - INC0362538 - artf07321575 - Correctif - ne pas approuver la facture si pas d'image facture Valide
  --- 2021/04/20 JWYC - INC0535674 - artf07453360 - Correctif - Approbation des factures AMONTS sans image
  --- 2021/10/06 AFE -  artf07468199  - Correctif - Autoriser comptabilisation suite déblocage Affacturage
  --- 2021/12/01 AFE - TASK0159118 - Exclusion classe employé contrôle image approbation workflow
  --- 2021/12/29 SELO TASK0162874
  --- 2025/01/22 SHA - EDB408 - Oracle WF AP - Approbation du BAP SSTR dans D@cshop - DSP 1454
  --- 2025/07/16 SHA - KDFI3035 - INC - Correctif WF lié au jira 3024
    ---------------------------------------------------------------------------------------------------------------

    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    cv_valeur_op_prof_CSP_ano fnd_profile_option_values.profile_option_value%type := 'CSP anomalie';
    cv_valeur_op_prof_CSP_ref fnd_profile_option_values.profile_option_value%type := 'CSP référentiel';

    -- les anomalies
    cv_ano_qty_ord           ap_holds_all.hold_lookup_code%type := 'QTY ORD'; -- blocage standard AP non present dans Xerox
    cv_ano_qty_rec           ap_holds_all.hold_lookup_code%type := 'QTY REC'; -- blocage standard AP non present dans Xerox
    cv_ano_rib               ap_holds_all.hold_lookup_code%type := 'Blocage Fres RIB'; -- code xerox 39
    cv_ano_fact_3_tamp       ap_holds_all.hold_lookup_code%type := 'Incohérence commande'; -- code xerox 36
    cv_ano_date_hors_per     ap_holds_all.hold_lookup_code%type := 'Blocage Date Facture'; -- code xerox 12
    cv_ano_affact            ap_holds_all.hold_lookup_code%type := 'Blocage Fres Affact'; -- code xerox 40 ou 41
    cv_ano_prlv_abs          ap_holds_all.hold_lookup_code%type := 'Blocage Fres Prelevt'; -- code xerox 42
    cv_ano_region_abs        ap_holds_all.hold_lookup_code%type := 'Région absente'; -- code xerox 44
    cv_ano_region_inc        ap_holds_all.hold_lookup_code%type := 'Région inconnue'; -- code xerox 43
    cv_ano_fourn_abs         ap_holds_all.hold_lookup_code%type := 'Blocage Pb Fournisseur'; -- code xerox 31 ou 32
    cv_ano_cmd_multi         ap_holds_all.hold_lookup_code%type := 'Blocage Fres Multi Cde'; -- code xerox 45
    cv_ano_cmd_multi2        ap_holds_all.hold_lookup_code%type := 'Blocage Fres Multi BL'; -- code xerox 46
    cv_ano_cmd_multi3        ap_holds_all.hold_lookup_code%type := 'Multi-commandes'; --
    cv_ano_soc_diff          ap_holds_all.hold_lookup_code%type := '';
    cv_ano_bon_apayer        ap_holds_all.hold_lookup_code%type := 'En attente';
    cv_ano_ecart_prix        ap_holds_all.hold_lookup_code%type := 'PRICE'; -- blocage standard AP non present dans Xerox
    cv_ano_imput_attente     ap_holds_all.hold_lookup_code%type := 'Imputation en attente';
    cv_ano_cmd_inconnue      ap_holds_all.hold_lookup_code%type := 'Commande inconnue'; -- code xerox 38
    cv_ano_motant_livre_maxi ap_holds_all.hold_lookup_code%type := 'MAX SHIP AMOUNT';

    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    PROCEDURE print_log_message(pv_message    IN VARCHAR2,
                                pn_mode_debug IN NUMBER) IS
        vv_message VARCHAR2(1000);
    BEGIN

        vv_message := substr(pv_message, 1, 1000);

        IF (vv_message IS NOT NULL) THEN

            vv_message := to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' || vv_message;
            --dbms_output.put_line(vv_message);
            wf_core.CONTEXT('DKA_SAPWFCSP_PKG', vv_message, vv_message);
            IF pn_mode_debug >= 1 THEN
                fnd_file.put_line(fnd_file.log, vv_message);
            END IF;
        END IF;
    END print_log_message;

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
    PROCEDURE print_wf_message(pv_itemtype   IN VARCHAR2,
                               pv_itemkey    IN WF_ITEMS.ITEM_KEY%type,
                               pv_message    IN VARCHAR2,
                               pn_mode_debug IN NUMBER) IS
        pragma AUTONOMOUS_TRANSACTION;
        vv_message VARCHAR2(4000);
    vn_mode_debug NUMBER;
    BEGIN
        vv_message := substr(pv_message, 1, 4000);
        print_log_message(pv_message, vn_mode_debug);-- SELO TASK0162874

     SELECT fpov.profile_option_value
       INTO vn_mode_debug
      FROM fnd_profile_options fpo,
         fnd_profile_option_values fpov,
         fnd_profile_options_tl fpot
     WHERE fpo.profile_option_id = fpov.profile_option_id(+)
       AND fpo.profile_option_name = fpot.profile_option_name
       and fpot.language = 'F'
       and fpov.level_id = 10001
       AND fpot.user_profile_option_name IN ('DKA : TRACE WORKFLOW') ;

        --IF pn_mode_debug = 2 THEN
    IF vn_mode_debug = 2 and pn_mode_debug <> 3 THEN -- SELO TASK0162874
            insert into DKA_WF_DEBUG      values
              (pv_itemtype || ':' || pv_itemkey, vv_message, sysdate, DKA_wf_debug_seq.nextval);
            commit;
            --null;
        END IF;
    END print_wf_message;

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
                               pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                               pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                               pv_funcmode  IN VARCHAR2,
                               pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_num_facture  AP_INVOICES_ALL.INVOICE_NUM%TYPE;
        vn_po_header_id po_headers_all.po_header_id%type;
        vn_invoice_id   AP_INVOICES_ALL.invoice_id%type;
        vv_url_facture  varchar2(1000);
        vv_url_commande varchar2(1000);
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        vv_num_facture := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                    itemkey  => pv_itemkey,
                                                    aname    => 'INVOICE_OI_NUM');
        vn_invoice_id  := substr(pv_itemkey, 1, instr(pv_itemkey, '_') - 1);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'pre_notif   vn_invoice_id = ' || vn_invoice_id ||
                         'vv_num_facture =  ' || vv_num_facture,
                         cn_mode_debug);

        BEGIN
            IF vv_num_facture is null then
                vv_url_facture := DKA_SAPGETIMG_WF_PKG.get_url_image_facture(vn_invoice_id,
                                                                              'AP');
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'pre_notif    AP ' || vv_url_facture,
                                 cn_mode_debug);

            else
                vv_url_facture := DKA_SAPGETIMG_WF_PKG.get_url_image_facture(vn_invoice_id,
                                                                              'OI');
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'pre_notif    OI ' || vv_url_facture,
                                 cn_mode_debug);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                vv_url_facture := null;
        END;

        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DKA_INVOICE_URL',
                                  avalue   => vv_url_facture);

        vn_po_header_id := wf_engine.getItemAttrNumber(itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'COMMANDE_ID');

        BEGIN
            vv_url_commande := DKA_SAPGETIMG_WF_PKG.GET_URL_IMAGE_BDC(vn_po_header_id);
        EXCEPTION
            WHEN OTHERS THEN
                vv_url_commande := null;
        END;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_url_commande ' || vv_url_commande,
                         cn_mode_debug);
        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DKA_PURCHASE_ORDER_URL',
                                  avalue   => vv_url_commande);

    END pre_notification;

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
    PROCEDURE insert_history(pv_itemtype     IN WF_ITEMS.ITEM_TYPE%TYPE,
                             pv_itemkey      IN WF_ITEMS.ITEM_KEY%TYPE,
                             pv_status       IN AP_INV_APRVL_HIST.RESPONSE%TYPE,
                             pv_code_blocage IN VARCHAR2,
                             pv_COMMENTS     IN AP_INV_APRVL_HIST.APPROVER_COMMENTS%TYPE,
                             pv_destinataire IN VARCHAR2 DEFAULT NULL) IS

        vn_iteration     AP_INV_APRVL_HIST.ITERATION%type;
        vn_invoice_id    ap_invoices_all.invoice_id%TYPE;
        vn_invoice_oi_id ap_invoices_all.invoice_id%TYPE;
        vn_org_id        ap_invoices_all.org_id%TYPE;
        vn_amount        ap_invoices_all.invoice_amount%type;
        vn_nid           wf_notifications.notification_id%type;

        vn_hist_id   AP_INV_APRVL_HIST.APPROVAL_HISTORY_ID%type;
        vv_employee  per_all_people_f.full_name%type;
        vv_matricule fnd_user.user_name%type;

    BEGIN

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history  debut pv_itemtype = ' ||
                         pv_itemtype || 'pv_itemkey =  ' || pv_itemkey,
                         cn_mode_debug);

        vn_invoice_id := substr(pv_itemkey, 1, instr(pv_itemkey, '_') - 1);
        vn_iteration  := substr(pv_itemkey, instr(pv_itemkey, '_') + 1);
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history  vn_invoice_id avec substr ' ||
                         vn_invoice_id,
                         cn_mode_debug);
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history  iteration avec substr ' ||
                         vn_iteration,
                         cn_mode_debug);

        vn_org_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'DKA_ORG_ID');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history  vn_org_id= ' || vn_org_id ||
                         'user ' || fnd_global.user_name,
                         cn_mode_debug);

        vn_amount := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'DKA_INVOICE_AMOUNT');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history  vn_amount= ' || vn_amount,
                         cn_mode_debug);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history  pv_destinataire ' ||
                         pv_destinataire || '  profile = ' ||
                         fnd_global.user_name,
                         cn_mode_debug);

        IF pv_destinataire is null then
            BEGIN
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'insert_history pas de destinataire de renseigné',
                                 cn_mode_debug);

                vn_nid := WF_ENGINE.context_nid;
                IF vn_nid IS NOT NULL THEN
                    vv_matricule := wf_notification.Responder(vn_nid);

                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'insert_history employe trouve pour le responder de la notif ' ||
                                     vn_nid || ' : ' || vv_employee,
                                     cn_mode_debug);

                END IF;

                --  IF vv_employee is null then
                select full_name
                  into vv_employee
                  FROM per_all_people_f pap, fnd_user fu
                 WHERE fu.employee_id = pap.person_id
                   and sysdate between pap.effective_start_date and
                       pap.effective_end_date
                   and fu.user_name = vv_matricule;

                /*             print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                              'insert_history employe trouve pour l''utilisateur ' || fnd_global.user_name || ' : ' ||vv_employee ,cn_mode_debug);
                */
                --END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'insert_history: l''utilisateur ' ||
                                     vv_matricule ||
                                     ' n''est pas rattaché a un employé actif ',
                                     3);

            END;
        ELSE
            vv_employee := pv_destinataire;
        END IF;

        --vn_invoice_oi_id not null si WF OI
        vn_invoice_oi_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                        itemkey  => pv_itemkey,
                                                        aname    => 'INVOICE_OI_ID');

        IF vn_invoice_oi_id IS NULL THEN
            --FACTURE AP

            -- INC0298239 - Violation d'option de contrôle
            --MOAC
            --MO_GLOBAL.INIT (p_appl_short_name => 'SQLAP');

            --insert into the history table
            SELECT AP_INV_APRVL_HIST_S.nextval INTO vn_hist_id FROM dual;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'insert_history  vn_hist_id = ' || vn_hist_id,
                             cn_mode_debug);

            -- INC0298239 - Violation d'option de contrôle
            INSERT INTO AP_INV_APRVL_HIST_ALL
                (APPROVAL_HISTORY_ID,
                 INVOICE_ID,
                 ITERATION,
                 RESPONSE,
                 APPROVER_ID,
                 APPROVER_NAME,
                 AMOUNT_APPROVED,
                 APPROVER_COMMENTS,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATE_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_LOGIN,
                 ORG_ID)
            VALUES
                (vn_hist_id,
                 vn_invoice_id,
                 vn_iteration,
                 pv_status,
                 NULL,
                 vv_employee,
                 vn_amount,
                 pv_code_blocage || ' - ' || pv_COMMENTS,
                 nvl(fnd_global.user_id, -1),
                 sysdate,
                 sysdate,
                 nvl(fnd_global.user_id, -1),
                 nvl(fnd_global.login_id, -1),
                 vn_org_id);
        ELSE
            --FACTURE OI
            --insert into the history table
            SELECT DKA_AP_INV_APRVL_HIST_S.nextval
              INTO vn_hist_id
              FROM dual;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'insert_history  vn_hist_id = ' || vn_hist_id,
                             cn_mode_debug);

            INSERT INTO DKA_AP_INV_APRVL_HIST_ALL
                (APPROVAL_HISTORY_ID,
                 INVOICE_ID,
                 ITERATION,
                 RESPONSE,
                 APPROVER_ID,
                 APPROVER_NAME,
                 AMOUNT_APPROVED,
                 APPROVER_COMMENTS,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATE_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_LOGIN,
                 ORG_ID)
            VALUES
                (vn_hist_id,
                 vn_invoice_id,
                 vn_iteration,
                 pv_status,
                 NULL,
                 vv_employee,
                 vn_amount,
                 pv_code_blocage || ' - ' || pv_COMMENTS,
                 nvl(fnd_global.user_id, -1),
                 sysdate,
                 sysdate,
                 nvl(fnd_global.user_id, -1),
                 nvl(fnd_global.login_id, -1),
                 vn_org_id);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'insert_history: INSERT ERREUR : ' ||
                             'APPROVAL_HISTORY_ID = ' || vn_hist_id ||
                             chr(10) || 'INVOICE_ID = ' || vn_invoice_id ||
                             chr(10) || 'ITERATION = ' || vn_iteration ||
                             chr(10) || 'STATUS = ' || pv_status ||
                             chr(10) || 'EMPLOYEE = ' || vv_employee ||
                             chr(10) || 'AMOUNT = ' || vn_amount ||
                             chr(10) || 'COMMENT = ' || pv_code_blocage ||
                             ' - ' || pv_COMMENTS,
                             3);
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'Erreur : ' || SQLERRM,
                             3);
            RAISE;
    END insert_history;

    PROCEDURE insert_history_wf(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_code_blocage VARCHAR2(30);
        vv_destinataire VARCHAR2(100);
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history  debut pv_itemtype = ' ||
                         pv_itemtype || 'pv_itemkey =  ' || pv_itemkey,
                         cn_mode_debug);

        vv_code_blocage := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                         itemtype => pv_itemtype,
                                                         itemkey  => pv_itemkey,
                                                         aname    => 'CODE_BLOCAGE');

        vv_destinataire := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                         itemtype => pv_itemtype,
                                                         itemkey  => pv_itemkey,
                                                         aname    => 'DESTINATAIRE_NOTIF');
        insert_history(pv_itemtype,
                       pv_itemkey,
                       'DKA_SOUMIS',
                       vv_code_blocage,
                       '',
                       WF_DIRECTORY.GetRoleDisplayName(vv_destinataire));

    END insert_history_wf;

    -------------------------------------------------------------------------------------
    --  Nom           : get_full_name
    --  Description   : Fonction utilisée pour déterminer le full_name d'un employé avec
    --                  son username
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --
    -------------------------------------------------------------------------------------
    FUNCTION get_full_name(pv_user_name VARCHAR2) return VARCHAR2 is
        vv_nom_employe per_all_people_f.full_name%TYPE;
    BEGIN
        select full_name
          into vv_nom_employe
          from per_all_people_f pap, fnd_user fu
         where fu.employee_id = pap.person_id
           and sysdate between pap.effective_start_date and
               pap.effective_end_date
           and fu.user_name = pv_user_name;

        return vv_nom_employe;

    EXCEPTION
        WHEN OTHERS THEN
            print_wf_message('get_full_name',
                             NULL,
                             'get_full_name: l''utilisateur ' ||
                             pv_user_name ||
                             ' n''est pas rattaché a un employé actif ',
                             3);
            return pv_user_name;
    END get_full_name;

    procedure get_item_info(pv_document_id in varchar2,
                            pv_itemtype    out nocopy wf_items.item_type%TYPE,
                            pv_itemkey     out nocopy wf_items.item_key%TYPE,
                            vn_nid         out nocopy number) is

        firstcolon  pls_integer;
        secondcolon pls_integer;

    begin

        /* format like REQAPPRV:12719-23684:67694*/
        firstcolon  := instr(pv_document_id, ':', 1, 1);
        secondcolon := instr(pv_document_id, ':', 1, 2);

        pv_itemtype := substr(pv_document_id, 1, firstcolon - 1);

        if (secondcolon = 0) then
            pv_itemkey := substr(pv_document_id,
                                 firstcolon + 1,
                                 length(pv_document_id) - 2);
            vn_nid     := null;
        else
            pv_itemkey := substr(pv_document_id,
                                 firstcolon + 1,
                                 secondcolon - firstcolon - 1);
            begin
                vn_nid := to_number(substr(pv_document_id,
                                           secondcolon + 1,
                                           length(pv_document_id) -
                                           secondcolon));
            exception
                when others then
                    vn_nid := null;
            end;
        end if;

    end get_item_info;

    -------------------------------------------------------------------------------------
    --  Nom           : get_action_history
    --  Description   : Procédure utilisée pour afficher le tableau d'historique
    --                    des actions sur la facture dans les notifications
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --
    -------------------------------------------------------------------------------------
    PROCEDURE get_action_history(pv_document_id   in varchar2,
                                 pv_display_type  in varchar2,
                                 pv_document      in out NOCOPY varchar2,
                                 pv_document_type in out NOCOPY varchar2) IS

        vv_item_type      wf_items.item_type%TYPE;
        vv_item_key       wf_items.item_key%TYPE;
        vv_document       VARCHAR2(32000) := '';
        NL                VARCHAR2(1) := fnd_global.newline;
        l_notification_id number;
        vn_invoice_id     number;
        vn_invoice_oi_id  ap_invoices_all.invoice_id%TYPE;

        nb_hist_fact number;
        CURSOR c_histo_ap_1(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
            select aiah.APPROVER_NAME,
                   flv.meaning as response,
                   to_char(aiah.CREATION_DATE, 'dd/mm/yyyy hh24:mi:ss') CREATION_DATE,
                   aiah.APPROVER_COMMENTS
              from AP_INV_APRVL_HIST_all aiah, fnd_lookup_values_vl flv
             where aiah.INVOICE_ID = pn_invoice_id
               and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               and flv.lookup_code = aiah.RESPONSE
               and flv.enabled_flag = 'Y'
               and sysdate between nvl(flv.start_date_active, sysdate) and
                   nvl(flv.end_date_active, sysdate)
             order by aiah.APPROVAL_HISTORY_ID DESC;

        CURSOR c_histo_ap_2(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
            select aiah.APPROVER_NAME,
                   flv.meaning as response,
                   to_char(aiah.CREATION_DATE, 'dd/mm/yyyy hh24:mi:ss') CREATION_DATE,
                   aiah.APPROVER_COMMENTS
              from AP_INV_APRVL_HIST_all aiah, fnd_lookup_values_vl flv
             where aiah.INVOICE_ID = pn_invoice_id
               and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               and flv.lookup_code = aiah.RESPONSE
               and flv.enabled_flag = 'Y'
               and sysdate between nvl(flv.start_date_active, sysdate) and
                   nvl(flv.end_date_active, sysdate)
               and aiah.response IS NOT NULL
               and aiah.approver_name IS NOT NULL
             order by aiah.APPROVAL_HISTORY_ID DESC;

        CURSOR c_histo_ap_3(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
            select aiah.APPROVER_NAME,
                   flv.meaning as response,
                   to_char(aiah.CREATION_DATE, 'dd/mm/yyyy hh24:mi:ss') CREATION_DATE,
                   aiah.APPROVER_COMMENTS
              from AP_INV_APRVL_HIST_all aiah, fnd_lookup_values_vl flv
             where aiah.INVOICE_ID = pn_invoice_id
               and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               and flv.lookup_code = aiah.RESPONSE
               and flv.enabled_flag = 'Y'
               and sysdate between nvl(flv.start_date_active, sysdate) and
                   nvl(flv.end_date_active, sysdate)
               and aiah.response IS NOT NULL
               and aiah.approver_name IS NOT NULL
               and aiah.response != 'DKA_SOUMIS'
               and rownum <= 60
             order by aiah.APPROVAL_HISTORY_ID DESC;

        CURSOR c_histo_oi_1(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
            select aiah.APPROVER_NAME,
                   flv.meaning as response,
                   to_char(aiah.CREATION_DATE, 'dd/mm/yyyy hh24:mi:ss') CREATION_DATE,
                   aiah.APPROVER_COMMENTS
              from DKA_AP_INV_APRVL_HIST_all aiah,
                   fnd_lookup_values_vl       flv
             where aiah.INVOICE_ID = pn_invoice_id
               and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               and flv.lookup_code = aiah.RESPONSE
               and flv.enabled_flag = 'Y'
               and sysdate between nvl(flv.start_date_active, sysdate) and
                   nvl(flv.end_date_active, sysdate)
             order by aiah.APPROVAL_HISTORY_ID DESC;

        CURSOR c_histo_oi_2(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
            select aiah.APPROVER_NAME,
                   flv.meaning as response,
                   to_char(aiah.CREATION_DATE, 'dd/mm/yyyy hh24:mi:ss') CREATION_DATE,
                   aiah.APPROVER_COMMENTS
              from DKA_AP_INV_APRVL_HIST_all aiah,
                   fnd_lookup_values_vl       flv
             where aiah.INVOICE_ID = pn_invoice_id
               and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               and flv.lookup_code = aiah.RESPONSE
               and flv.enabled_flag = 'Y'
               and sysdate between nvl(flv.start_date_active, sysdate) and
                   nvl(flv.end_date_active, sysdate)
               and aiah.response IS NOT NULL
               and aiah.approver_name IS NOT NULL
             order by aiah.APPROVAL_HISTORY_ID DESC;

        CURSOR c_histo_oi_3(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
            select aiah.APPROVER_NAME,
                   flv.meaning as response,
                   to_char(aiah.CREATION_DATE, 'dd/mm/yyyy hh24:mi:ss') CREATION_DATE,
                   aiah.APPROVER_COMMENTS
              from DKA_AP_INV_APRVL_HIST_all aiah,
                   fnd_lookup_values_vl       flv
             where aiah.INVOICE_ID = pn_invoice_id
               and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               and flv.lookup_code = aiah.RESPONSE
               and flv.enabled_flag = 'Y'
               and sysdate between nvl(flv.start_date_active, sysdate) and
                   nvl(flv.end_date_active, sysdate)
               and aiah.response IS NOT NULL
               and aiah.response != 'DKA_SOUMIS'
               and aiah.approver_name IS NOT NULL
               and rownum <= 60
             order by aiah.APPROVAL_HISTORY_ID DESC;

    BEGIN
        get_item_info(pv_document_id,
                      vv_item_type,
                      vv_item_key,
                      l_notification_id);
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_action_history  document_id= ' ||
                         pv_document_id || 'pv_display_type ' ||
                         pv_display_type,
                         cn_mode_debug);

        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_action_history  vv_item_type= ' ||
                         vv_item_type || 'vv_item_key ' || vv_item_key,
                         cn_mode_debug);

        vn_invoice_id := substr(vv_item_key,
                                1,
                                instr(vv_item_key, '_') - 1);

        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_action_history  vn_invoice_id= ' ||
                         vn_invoice_id,
                         cn_mode_debug);

        if (pv_display_type = 'text/html') then

            vv_document := NL || NL || '<!-- ACTION_HISTORY -->' || NL || NL;
            vv_document := vv_document || '<TABLE ' || L_TABLE_STYLE ||
                           ' summary=""' ||
                           fnd_message.get_string('ICX',
                                                  'ICX_POR_TBL_OF_APPROVERS') || '"">' || NL;
            vv_document := vv_document || '<TR>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=20% id=""employee_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('PO',
                                                  'PO_WF_NOTIF_EMPLOYEE') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=12% id=""action_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('PO',
                                                  'PO_WF_NOTIF_ACTION') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=12% id=""date_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('PO', 'PO_WF_NOTIF_DATE') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=35% id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('PO',
                                                  'PO_WF_NOTIF_ACTION_NOTE') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '</TR>' || NL;

            --vn_invoice_oi_id not null si WF OI
            vn_invoice_oi_id := wf_engine.getitemattrnumber(itemtype => vv_item_type,
                                                            itemkey  => vv_item_key,
                                                            aname    => 'INVOICE_OI_ID');

            IF vn_invoice_oi_id IS NULL THEN
                nb_hist_fact := 0;
                BEGIN
                    select count(1)
                      into nb_hist_fact
                      from AP_INV_APRVL_HIST_all aiah,
                           fnd_lookup_values_vl  flv
                     where aiah.INVOICE_ID = vn_invoice_id
                       and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
                       and flv.lookup_code = aiah.RESPONSE
                       and flv.enabled_flag = 'Y'
                       and sysdate between
                           nvl(flv.start_date_active, sysdate) and
                           nvl(flv.end_date_active, sysdate)
                     order by aiah.APPROVAL_HISTORY_ID DESC;
                EXCEPTION
                    WHEN OTHERS THEN
                        nb_hist_fact := 0;
                END;
                IF nb_hist_fact <= 60 THEN
                    --FACTURE AP
                    for histo1 in c_histo_ap_1(vn_invoice_id) LOOP
                        vv_document := vv_document || NL || '<TR>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""employee_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       nvl(histo1.APPROVER_NAME, ' exit;') ||
                                       '</font></td>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""action_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       nvl(histo1.RESPONSE, 'exit; ') ||
                                       '</font></td>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""date_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       histo1.CREATION_DATE ||
                                       '</font></td>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""actioNote_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       nvl(histo1.APPROVER_COMMENTS,
                                           ' ') || '</font></td>' || NL;
                        vv_document := vv_document || '</TR>' || NL;
                    end loop;
                ELSE
                    nb_hist_fact := 0;
                    BEGIN
                        select count(1)
                          into nb_hist_fact
                          from AP_INV_APRVL_HIST_all aiah,
                               fnd_lookup_values_vl  flv
                         where aiah.INVOICE_ID = vn_invoice_id
                           and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
                           and flv.lookup_code = aiah.RESPONSE
                           and flv.enabled_flag = 'Y'
                           and sysdate between
                               nvl(flv.start_date_active, sysdate) and
                               nvl(flv.end_date_active, sysdate)
                           and aiah.response IS NOT NULL
                           and aiah.approver_name IS NOT NULL
                         order by aiah.APPROVAL_HISTORY_ID DESC;
                    EXCEPTION
                        WHEN OTHERS THEN
                            nb_hist_fact := 0;
                    END;

                    IF nb_hist_fact <= 60 THEN
                        --FACTURE AP
                        for histo2 in c_histo_ap_2(vn_invoice_id) LOOP
                            vv_document := vv_document || NL || '<TR>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""employee_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo2.APPROVER_NAME,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""action_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo2.RESPONSE, ' ') ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""date_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           histo2.CREATION_DATE ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""actioNote_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo2.APPROVER_COMMENTS,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || '</TR>' || NL;
                        end loop;
                    ELSE
                        --FACTURE AP
                        for histo3 in c_histo_ap_3(vn_invoice_id) LOOP
                            vv_document := vv_document || NL || '<TR>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""employee_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo3.APPROVER_NAME,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""action_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo3.RESPONSE, ' ') ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""date_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           histo3.CREATION_DATE ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""actioNote_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo3.APPROVER_COMMENTS,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || '</TR>' || NL;
                        end loop;
                    END IF;
                END IF;

            ELSE
                ----------------
                -- ---------- --
                -- FACTURE OI --
                -- ---------- --
                ----------------
                nb_hist_fact := 0;
                BEGIN
                    select count(1)
                      into nb_hist_fact
                      from DKA_AP_INV_APRVL_HIST_all aiah,
                           fnd_lookup_values_vl       flv
                     where aiah.INVOICE_ID = vn_invoice_oi_id
                       and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
                       and flv.lookup_code = aiah.RESPONSE
                       and flv.enabled_flag = 'Y'
                       and sysdate between
                           nvl(flv.start_date_active, sysdate) and
                           nvl(flv.end_date_active, sysdate)
                     order by aiah.APPROVAL_HISTORY_ID DESC;
                EXCEPTION
                    WHEN OTHERS THEN
                        nb_hist_fact := 0;
                END;
                IF nb_hist_fact <= 60 THEN

                    for histo1 in c_histo_oi_1(vn_invoice_oi_id) LOOP
                        vv_document := vv_document || NL || '<TR>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""employee_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       nvl(histo1.APPROVER_NAME, ' ') ||
                                       '</font></td>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""action_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       nvl(histo1.RESPONSE, ' ') ||
                                       '</font></td>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""date_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       histo1.CREATION_DATE ||
                                       '</font></td>' || NL;
                        vv_document := vv_document || NL || '<td ' ||
                                       L_TABLE_CELL_STYLE ||
                                       ' headers=""actioNote_3""><font ' ||
                                       L_FONT_CELL_STYLE || '>' ||
                                       nvl(histo1.APPROVER_COMMENTS,
                                           ' ') || '</font></td>' || NL;
                        vv_document := vv_document || '</TR>' || NL;
                    end loop;
                ELSE
                    nb_hist_fact := 0;
                    BEGIN
                        select count(1)
                          into nb_hist_fact
                          from DKA_AP_INV_APRVL_HIST_all aiah,
                               fnd_lookup_values_vl       flv
                         where aiah.INVOICE_ID = vn_invoice_oi_id
                           and flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
                           and flv.lookup_code = aiah.RESPONSE
                           and flv.enabled_flag = 'Y'
                           and sysdate between
                               nvl(flv.start_date_active, sysdate) and
                               nvl(flv.end_date_active, sysdate)
                           and aiah.response IS NOT NULL
                           and aiah.approver_name IS NOT NULL
                         order by aiah.APPROVAL_HISTORY_ID DESC;
                    EXCEPTION
                        WHEN OTHERS THEN
                            nb_hist_fact := 0;
                    END;
                    IF nb_hist_fact <= 60 THEN
                        for histo2 in c_histo_oi_2(vn_invoice_oi_id) LOOP
                            vv_document := vv_document || NL || '<TR>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""employee_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo2.APPROVER_NAME,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""action_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo2.RESPONSE, ' ') ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""date_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           histo2.CREATION_DATE ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""actioNote_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo2.APPROVER_COMMENTS,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || '</TR>' || NL;
                        end loop;
                    ELSE
                        for histo3 in c_histo_oi_3(vn_invoice_oi_id) LOOP
                            vv_document := vv_document || NL || '<TR>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""employee_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo3.APPROVER_NAME,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""action_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo3.RESPONSE, ' ') ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""date_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           histo3.CREATION_DATE ||
                                           '</font></td>' || NL;
                            vv_document := vv_document || NL || '<td ' ||
                                           L_TABLE_CELL_STYLE ||
                                           ' headers=""actioNote_3""><font ' ||
                                           L_FONT_CELL_STYLE || '>' ||
                                           nvl(histo3.APPROVER_COMMENTS,
                                               ' ') || '</font></td>' || NL;
                            vv_document := vv_document || '</TR>' || NL;
                        end loop;
                    END IF;
                END IF;
            END IF;
            vv_document := vv_document || '</TABLE>' || NL;

            pv_document := vv_document;

        elsif (pv_display_type = 'text/plain') then
            pv_document := '';
        end if;
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_action_history  end',
                         cn_mode_debug);
    END get_action_history;

    FUNCTION get_blocages_AP(pn_invoice_id in number,
                             pv_type_notif VARCHAR2,
                             pv_item_key   in varchar2) RETURN varchar2 IS

        vv_document        VARCHAR2(32000) := '';
        NL                 VARCHAR2(1) := fnd_global.newline;
        vn_blocage_courant number := 1;
    BEGIN
        print_wf_message('DKA_CSP',
                         pv_item_key,
                         'get_blocages_AP  pn_invoice_id= ' ||
                         pn_invoice_id || ' pv_item_key=' || pv_item_key,
                         cn_mode_debug);

        vv_document := NL || NL || '<!-- BLOCAGES -->' || NL || NL;
        --    vv_document := vv_document || '<TABLE >' || NL;

        -- ATTENTION. LA requete est différente suivante le LOT qui est a installer.
        -- Le lot 2 et 3 gerant de plus en plus de types de blocages, la notifications diverses en gere de moins en moins par rapport au lot 1
        for histo1 in (
                       -- LOT 3
                       SELECT distinct APLC.LOOKUP_CODE,
                                        APLC.DISPLAYED_FIELD
                         FROM AP_LOOKUP_CODES APLC, AP_HOLDS_ALL AH
                        WHERE AH.HOLD_LOOKUP_CODE = APLC.LOOKUP_CODE
                          AND APLC.LOOKUP_TYPE = 'HOLD CODE'
                          AND AH.RELEASE_LOOKUP_CODE IS NULL
                          AND AH.INVOICE_ID = PN_INVOICE_ID
                          AND ((nvl(pv_type_notif, 'ECART_PRIX') =
                              'ECART_PRIX' and
                              (APLC.LOOKUP_CODE = cv_ano_ecart_prix OR
                              APLC.LOOKUP_CODE = cv_ano_motant_livre_maxi)) OR
                              (nvl(pv_type_notif, 'CMD_MULT') = 'CMD_MULT' and
                              (APLC.LOOKUP_CODE = cv_ano_cmd_multi or
                              APLC.LOOKUP_CODE = cv_ano_cmd_multi2 or
                              APLC.LOOKUP_CODE = cv_ano_cmd_multi3)) OR
                              (nvl(pv_type_notif, 'QTY_REC') = 'QTY_REC' and
                              APLC.LOOKUP_CODE = cv_ano_qty_rec) OR
                              (nvl(pv_type_notif, 'QTY_ORD') = 'QTY_ORD' and
                              APLC.LOOKUP_CODE = cv_ano_qty_ord) OR
                              (nvl(pv_type_notif, 'PRLV') = 'PRLV' and
                              APLC.LOOKUP_CODE = cv_ano_prlv_abs) OR
                              (nvl(pv_type_notif, 'AFFACT') = 'AFFACT' and
                              APLC.LOOKUP_CODE = cv_ano_affact) OR
                              (nvl(pv_type_notif, 'RIB') = 'RIB' and
                              APLC.LOOKUP_CODE = cv_ano_rib) OR
                              (nvl(pv_type_notif, 'BAP') = 'BAP' and
                              (APLC.LOOKUP_CODE = cv_ano_bon_apayer OR
                              APLC.LOOKUP_CODE = cv_ano_imput_attente)) OR
                              (nvl(pv_type_notif, 'IMPUT') = 'IMPUT' and
                              (APLC.LOOKUP_CODE = cv_ano_bon_apayer OR
                              APLC.LOOKUP_CODE = cv_ano_imput_attente)) OR
                              (nvl(pv_type_notif, 'DIVERS') = 'DIVERS' and
                              APLC.LOOKUP_CODE <> cv_ano_ecart_prix and
                              APLC.LOOKUP_CODE <> cv_ano_cmd_multi and
                              APLC.LOOKUP_CODE <> cv_ano_cmd_multi and
                              APLC.LOOKUP_CODE <> cv_ano_cmd_multi and
                              APLC.LOOKUP_CODE <> cv_ano_cmd_multi2 and
                              APLC.LOOKUP_CODE <> cv_ano_cmd_multi3 and
                              APLC.LOOKUP_CODE <> cv_ano_qty_rec and
                              APLC.LOOKUP_CODE <> cv_ano_qty_ord and
                              APLC.LOOKUP_CODE <> cv_ano_prlv_abs and
                              APLC.LOOKUP_CODE <> cv_ano_affact and
                              APLC.LOOKUP_CODE <> cv_ano_rib and
                              APLC.LOOKUP_CODE <> cv_ano_bon_apayer and
                              APLC.LOOKUP_CODE <> cv_ano_imput_attente and
                              APLC.LOOKUP_CODE <> cv_ano_motant_livre_maxi))

                       -- LOT 2
                       --        SELECT distinct APLC.LOOKUP_CODE, APLC.DISPLAYED_FIELD
                       --        FROM AP_LOOKUP_CODES APLC, AP_HOLDS_ALL AH
                       --       WHERE AH.HOLD_LOOKUP_CODE = APLC.LOOKUP_CODE
                       --         AND APLC.LOOKUP_TYPE = 'HOLD CODE'
                       --         AND AH.RELEASE_LOOKUP_CODE IS NULL
                       --         AND AH.INVOICE_ID = PN_INVOICE_ID
                       --         AND (
                       --                  ( nvl(pv_type_notif,'ECART_PRIX') ='ECART_PRIX' and APLC.LOOKUP_CODE = cv_ano_ecart_prix)
                       --               OR ( nvl(pv_type_notif, 'QTY_REC') ='QTY_REC' and APLC.LOOKUP_CODE = cv_ano_qty_rec)
                       --               OR ( nvl(pv_type_notif, 'QTY_ORD') ='QTY_ORD' and APLC.LOOKUP_CODE = cv_ano_qty_ord)
                       --               OR ( nvl(pv_type_notif,'BAP') ='BAP' and ( APLC.LOOKUP_CODE = cv_ano_bon_apayer OR APLC.LOOKUP_CODE = cv_ano_imput_attente))
                       --               OR ( nvl(pv_type_notif, 'IMPUT') ='IMPUT' and ( APLC.LOOKUP_CODE = cv_ano_bon_apayer OR APLC.LOOKUP_CODE = cv_ano_imput_attente))
                       --               OR ( nvl(pv_type_notif, 'DIVERS') ='DIVERS' and APLC.LOOKUP_CODE <> cv_ano_ecart_prix
                       --               and APLC.LOOKUP_CODE <> cv_ano_qty_rec and APLC.LOOKUP_CODE <> cv_ano_qty_ord and APLC.LOOKUP_CODE <> cv_ano_bon_apayer and APLC.LOOKUP_CODE <> cv_ano_imput_attente )
                       --               )
                       --
                       -- LOT1
                       /*     SELECT distinct APLC.LOOKUP_CODE, APLC.DISPLAYED_FIELD
                                                      FROM AP_LOOKUP_CODES APLC, AP_HOLDS_ALL AH
                                                     WHERE AH.HOLD_LOOKUP_CODE = APLC.LOOKUP_CODE
                                                       AND APLC.LOOKUP_TYPE = 'HOLD CODE'
                                                       AND AH.RELEASE_LOOKUP_CODE IS NULL
                                                       AND AH.INVOICE_ID = PN_INVOICE_ID
                                                       AND (
                                                             ( nvl(pv_type_notif,'BAP') ='BAP' and ( APLC.LOOKUP_CODE = cv_ano_bon_apayer OR APLC.LOOKUP_CODE = cv_ano_imput_attente))
                                                             OR ( nvl(pv_type_notif, 'IMPUT') ='IMPUT' and ( APLC.LOOKUP_CODE = cv_ano_bon_apayer OR APLC.LOOKUP_CODE = cv_ano_imput_attente))
                                                             OR ( nvl(pv_type_notif, 'DIVERS') ='DIVERS' and ah.attribute2 = pv_item_key and APLC.LOOKUP_CODE <> cv_ano_bon_apayer and APLC.LOOKUP_CODE <> cv_ano_imput_attente )
                                                             )
                                              */
                       ) LOOP
            IF vn_blocage_courant > 1 THEN
                vv_document := vv_document || NL || '<TR>' || NL;
            END IF;
            --      vv_document :=  vv_document || NL || '<TR>' || NL;
            --      vv_document :=  vv_document || NL ||   '<td ' || L_TABLE_CELL_STYLE || ' headers=""employee_3"">'|| nvl(histo1.displayed_field, ' ') ||'</td>' || NL;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""action_3""><font ' ||
                                  L_FONT_CELL_STYLE || '>' ||
                                  nvl(histo1.displayed_field, ' ') ||
                                  '</font></td>' || NL;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""action_3""><font ' ||
                                  L_FONT_CELL_STYLE || '>' ||
                                  nvl(histo1.lookup_code, ' ') ||
                                  '</font></td>' || NL;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""action_3""><font ' ||
                                  L_FONT_CELL_STYLE ||
                                  '>  </font></td>' || NL;
            vv_document        := vv_document || '</TR>' || NL;
            vn_blocage_courant := vn_blocage_courant + 1;
        end loop;

        --    vv_document := vv_document || '</TABLE> ' || NL;
        return vv_document;
    END get_blocages_AP;

    FUNCTION get_blocages_OI(pn_invoice_id in number) RETURN varchar2 IS

        vv_document        VARCHAR2(32000) := '';
        NL                 VARCHAR2(1) := fnd_global.newline;
        vn_blocage_courant number := 1;

    BEGIN
        vv_document := NL || NL || '<!-- BLOCAGES -->' || NL || NL;
        --    vv_document := vv_document || '<TABLE ' || L_TABLE_STYLE || ' >' || NL;
        /*
        vv_document := vv_document || '<TR>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=20% id=""employee_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E026') || '</TH>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=12% id=""action_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E027') || '</TH>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=35% id=""actionNote_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E028') || '</TH>' || NL;
        vv_document := vv_document || '</TR>' || NL;
        */

        for histo1 in (
                       --rejets OI lignes de facture
                       select distinct aili.invoice_id,
                                        alc.lookup_code,
                                        alc.displayed_field
                         from ap_interface_rejections    air,
                               ap_lookup_codes            alc,
                               AP_INVOICE_LINES_INTERFACE aili
                        where alc.lookup_code = air.reject_lookup_code
                          and alc.lookup_type = 'REJECT CODE'
                          and air.parent_id = aili.invoice_line_id
                          and air.parent_table =
                              'AP_INVOICE_LINES_INTERFACE'
                          and aili.invoice_id = pn_invoice_id
                       union
                       --rejets OI facture
                       select air.parent_id,
                              alc.lookup_code,
                              alc.displayed_field
                         from ap_interface_rejections air,
                              ap_lookup_codes         alc
                        where alc.lookup_code = air.reject_lookup_code
                          and alc.lookup_type = 'REJECT CODE'
                          and air.parent_table = 'AP_INVOICES_INTERFACE'
                          and air.parent_id = pn_invoice_id) LOOP
            IF vn_blocage_courant > 1 THEN
                vv_document := vv_document || NL || '<TR>' || NL;
            END IF;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""employee_3""><font ' ||
                                  L_FONT_CELL_STYLE || '>' ||
                                  nvl(histo1.displayed_field, ' ') ||
                                  '</font></td>' || NL;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""action_3""><font ' ||
                                  L_FONT_CELL_STYLE || '>' ||
                                  nvl(histo1.lookup_code, ' ') ||
                                  '</font></td>' || NL;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""action_3""><font ' ||
                                  L_FONT_CELL_STYLE ||
                                  '>  </font></td>' || NL;
            vv_document        := vv_document || '</TR>' || NL;
            vn_blocage_courant := vn_blocage_courant + 1;
        end loop;

        --rejets Xerox
        for histo2 in (select dsl.return_value, dsl.param1_value
                         from dka_stransco_headers dsh,
                              dka_stransco_lines   dsl
                        where dsh.Set_Id = dsl.set_id
                          AND dsh.set_name = 'CODE REJET XEROX / ORACLE'
                          and dsl.return_value in
                              (select attribute4
                                 from AP_INVOICES_INTERFACE aii
                                where aii.invoice_id = pn_invoice_id
                               union
                               select attribute5
                                 from AP_INVOICES_INTERFACE aii
                                where aii.invoice_id = pn_invoice_id
                               union
                               select attribute6
                                 from AP_INVOICES_INTERFACE aii
                                where aii.invoice_id = pn_invoice_id
                               /*union
                               select attribute7
                                 from AP_INVOICES_INTERFACE aii
                                where aii.invoice_id = pn_invoice_id
                               union
                               select attribute11
                                 from AP_INVOICES_INTERFACE aii
                                where aii.invoice_id = pn_invoice_id*/)) LOOP
            IF vn_blocage_courant > 1 THEN
                vv_document := vv_document || NL || '<TR>' || NL;
            END IF;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""employee_3""><font ' ||
                                  L_FONT_CELL_STYLE || '>' ||
                                  nvl(histo2.return_value, ' ') ||
                                  '</font></td>' || NL;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""action_3""><font ' ||
                                  L_FONT_CELL_STYLE || '>' ||
                                  nvl(histo2.param1_value, ' ') ||
                                  '</font></td>' || NL;
            vv_document        := vv_document || NL || '<td ' ||
                                  L_TABLE_CELL_STYLE ||
                                  ' headers=""action_3""><font ' ||
                                  L_FONT_CELL_STYLE ||
                                  '>  </font></td>' || NL;
            vv_document        := vv_document || '</TR>' || NL;
            vn_blocage_courant := vn_blocage_courant + 1;
        end loop;

        --   vv_document := vv_document || '</TABLE> ' || NL;
        return vv_document;
    END get_blocages_OI;

    -------------------------------------------------------------------------------------
    --  Nom           : get_infos_OI
    --  Description   : Procédure utilisée pour afficher le tableau d'informations
    --                    sur la facture de l'open interface dans les notifications
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --
    -------------------------------------------------------------------------------------
    PROCEDURE get_infos_OI(pv_document_id   in varchar2,
                           pv_display_type  in varchar2,
                           pv_document      in out NOCOPY varchar2,
                           pv_document_type in out NOCOPY varchar2) IS
        vv_item_type      WF_ITEMS.ITEM_TYPE%TYPE;
        vv_item_key       WF_ITEMS.ITEM_KEY%TYPE;
        vv_document       VARCHAR2(32000) := '';
        NL                VARCHAR2(1) := FND_GLOBAL.NEWLINE;
        l_notification_id WF_NOTIFICATIONS.NOTIFICATION_ID%TYPE;
        vn_invoice_id     AP_INVOICES_ALL.INVOICE_ID%TYPE;
        vn_invoice_amount AP_INVOICES_ALL.INVOICE_AMOUNT%TYPE;
        vv_invoice_num    AP_INVOICES_ALL.INVOICE_NUM%TYPE;
        vv_num_vendeur    AP_SUPPLIERS.SEGMENT1%TYPE;
        vd_invoice_date   AP_INVOICES_ALL.INVOICE_DATE%TYPE;
        vv_invoice_type   AP_INVOICES_ALL.INVOICE_TYPE_LOOKUP_CODE%TYPE;
        vv_pay_group      AP_INVOICES_INTERFACE.PAY_GROUP_LOOKUP_CODE%TYPE;
        vv_desc           AP_INVOICES_INTERFACE.DESCRIPTION%TYPE;
        vv_nom_fourn      AP_SUPPLIERS.VENDOR_NAME%TYPE;
        vv_num_command    PO_HEADERS.SEGMENT1%TYPE;
        vv_code_sitefourn AP_SUPPLIER_SITES.VENDOR_SITE_CODE%TYPE;
    begin
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_infos_AP  document_id= ' || pv_document_id ||
                         'pv_display_type ' || pv_display_type,
                         cn_mode_debug);
        get_item_info(pv_document_id,
                      vv_item_type,
                      vv_item_key,
                      l_notification_id);
        vn_invoice_id := substr(vv_item_key,
                                1,
                                instr(vv_item_key, '_') - 1);
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_infos_AP  vv_item_type= ' || vv_item_type ||
                         'vv_item_key ' || vv_item_key || 'vn_invoice_id ' ||
                         vn_invoice_id,
                         cn_mode_debug);

        vv_invoice_num := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                    itemkey  => vv_item_key,
                                                    aname    => 'INVOICE_OI_NUM');

        vv_num_vendeur := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                    itemkey  => vv_item_key,
                                                    aname    => 'VENDOR_SEGMENT1');

        vn_invoice_amount := wf_engine.getitemattrnumber(itemtype => vv_item_type,
                                                         itemkey  => vv_item_key,
                                                         aname    => 'DKA_INVOICE_AMOUNT');

        vd_invoice_date := wf_engine.getItemAttrDate(itemtype => vv_item_type,
                                                     itemkey  => vv_item_key,
                                                     aname    => 'DKA_INVOICE_DATE');

        vv_invoice_type := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                     itemkey  => vv_item_key,
                                                     aname    => 'INVOICE_TYPE');

        vv_pay_group := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                  itemkey  => vv_item_key,
                                                  aname    => 'PAY_GROUP');

        vv_desc := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                             itemkey  => vv_item_key,
                                             aname    => 'DESCRIPT');

        vv_nom_fourn := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                  itemkey  => vv_item_key,
                                                  aname    => 'VENDOR_NAME');

        vv_num_command := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                    itemkey  => vv_item_key,
                                                    aname    => 'COMMANDE_NUM');

        vv_code_sitefourn := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                       itemkey  => vv_item_key,
                                                       aname    => 'VENDOR_SITE_CODE');

        if (pv_display_type = 'text/html') then

            vv_document := NL || NL || '<!-- BLOCAGES -->' || NL || NL;
            vv_document := vv_document || '<TABLE ' || L_TABLE_STYLE || '>' || NL;
            vv_document := vv_document || '<TR>' || NL;

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""employee_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E015') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' || --desc
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E019') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E030') ||
                           '</font></TH>' || NL; --N° fourn

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E031') ||
                           '</font></TH>' || NL; -- code fourn

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E034') ||
                           '</font></TH>' || NL; -- nom fourn

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E032') ||
                           '</font></TH>' || NL; -- classe regl

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E033') ||
                           '</font></TH>' || NL; --type fact

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E017') ||
                           '</font></TH>' || NL; --date

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E035') ||
                           '</font></TH>' || NL; -- N° comm

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E018') ||
                           '</font></TH>' || NL; -- ID

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E016') ||
                           '</font></TH>' || NL; -- montant

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""employee_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E026') ||
                           '</font></TH><font ' || L_FONT_HEADER_STYLE || '>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E027') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E028') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '</TR>' || NL;

            vv_document := vv_document || NL || '<TR>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_invoice_num, ' ') || '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_desc, ' ') || '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_num_vendeur, ' ') || '</font></td>' || NL;

            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_code_sitefourn, ' ') ||
                           '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_nom_fourn, ' ') || '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_pay_group, ' ') || '</font></td>' || NL;

            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_invoice_type, ' ') ||
                           '</font></td>' || NL;

            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(to_char(vd_invoice_date), ' ') ||
                           '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_num_command, ' ') || '</font></td>' || NL;

            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(to_char(vn_invoice_id), ' ') ||
                           '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(to_char(vn_invoice_amount), ' ') ||
                           '</font></td>' || NL;

            print_wf_message(vv_item_type,
                             vv_item_key,
                             'get_infos_OI avant appel get_blocages_OI ',
                             cn_mode_debug);

            --      vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' colspan=""3"" headers=""action_3"">'|| NL;
            --      vv_document :=  vv_document || get_blocages_OI( vn_invoice_id);
            --      vv_document :=  vv_document || NL ||'</td>'|| NL;
            --      vv_document := vv_document || '</TR>' || NL;

            vv_document := vv_document || get_blocages_OI(vn_invoice_id);

            vv_document := vv_document || '</TABLE> ' || NL;
            pv_document := vv_document;
        elsif (pv_display_type = 'text/plain') then
            pv_document := '';
        end if;
    end get_infos_OI;

    -------------------------------------------------------------------------------------
    --  Nom           : get_infos_AP
    --  Description   : Procédure utilisée pour afficher le tableau d'informations
    --                    sur la facture AP dans les notifications
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --
    -------------------------------------------------------------------------------------
    PROCEDURE get_infos_AP(pv_document_id   in varchar2,
                           pv_display_type  in varchar2,
                           pv_document      in out NOCOPY varchar2,
                           pv_document_type in out NOCOPY varchar2) IS

        vv_item_type wf_items.item_type%TYPE;
        vv_item_key  wf_items.item_key%TYPE;

        vv_document       VARCHAR2(32000) := '';
        NL                VARCHAR2(1) := fnd_global.newline;
        l_notification_id wf_notifications.notification_id%type;
        vn_invoice_id     ap_invoices_all.invoice_id%type;
        vn_invoice_amount ap_invoices_all.invoice_amount%type;
        vv_invoice_num    ap_invoices_all.invoice_num%type;
        vv_num_vendeur    AP_SUPPLIERS.segment1%type;
        vd_invoice_date   ap_invoices_all.invoice_date%type;
        vv_invoice_type   ap_invoices_all.invoice_type_lookup_code%type;
        vv_pay_group      ap_invoices_interface.pay_group_lookup_code%type;
        vv_desc           ap_invoices_interface.description%type;
        vv_nom_fourn      AP_SUPPLIERS.vendor_name%type;
        vv_num_command    po_headers.segment1%type;
        vv_code_sitefourn AP_SUPPLIER_sites.vendor_site_code%type;
        vv_type_notif     varchar2(2000);
    BEGIN
        get_item_info(pv_document_id,
                      vv_item_type,
                      vv_item_key,
                      l_notification_id);
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_infos_AP  document_id= ' || pv_document_id ||
                         'pv_display_type ' || pv_display_type,
                         cn_mode_debug);

        vn_invoice_id := substr(vv_item_key,
                                1,
                                instr(vv_item_key, '_') - 1);
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_infos_AP  vv_item_type= ' || vv_item_type ||
                         'vv_item_key ' || vv_item_key || 'vn_invoice_id ' ||
                         vn_invoice_id || 'l_notification_id' ||
                         l_notification_id,
                         cn_mode_debug);

        BEGIN
            vv_type_notif := wf_notification.GetAttrText(l_notification_id,
                                                         'TYPE_NOTIF');
        EXCEPTION
            WHEN OTHERS THEN
                vv_type_notif := null;
        END;

        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_infos_AP  vv_type_notif = ' || vv_type_notif,
                         cn_mode_debug);

        vv_invoice_num := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                    itemkey  => vv_item_key,
                                                    aname    => 'INVOICE_NUM');

        vv_num_vendeur := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                    itemkey  => vv_item_key,
                                                    aname    => 'VENDOR_SEGMENT1');

        vn_invoice_amount := wf_engine.getitemattrnumber(itemtype => vv_item_type,
                                                         itemkey  => vv_item_key,
                                                         aname    => 'DKA_INVOICE_AMOUNT');

        vd_invoice_date := wf_engine.getItemAttrDate(itemtype => vv_item_type,
                                                     itemkey  => vv_item_key,
                                                     aname    => 'DKA_INVOICE_DATE');

        vv_invoice_type := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                     itemkey  => vv_item_key,
                                                     aname    => 'INVOICE_TYPE');

        vv_pay_group := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                  itemkey  => vv_item_key,
                                                  aname    => 'PAY_GROUP');

        vv_desc := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                             itemkey  => vv_item_key,
                                             aname    => 'DESCRIPT');

        vv_nom_fourn := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                  itemkey  => vv_item_key,
                                                  aname    => 'VENDOR_NAME');

        vv_num_command := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                    itemkey  => vv_item_key,
                                                    aname    => 'COMMANDE_NUM');

        vv_code_sitefourn := wf_engine.getItemAttrText(itemtype => vv_item_type,
                                                       itemkey  => vv_item_key,
                                                       aname    => 'VENDOR_SITE_CODE');

        if (pv_display_type = 'text/html') then

            vv_document := NL || NL || '<!-- BLOCAGES -->' || NL || NL;
            vv_document := vv_document || '<TABLE ' || L_TABLE_STYLE || '>' || NL;
            vv_document := vv_document || '<TR>' || NL;

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""employee_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E015') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' || --desc
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E019') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E030') ||
                           '</font></TH>' || NL; --N° fourn

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E031') ||
                           '</font></TH>' || NL; -- code fourn
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E034') ||
                           '</font></TH>' || NL; -- nom fourn

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E032') ||
                           '</font></TH>' || NL; -- classe regl

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E033') ||
                           '</font></TH>' || NL; --type fact

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E017') ||
                           '</font></TH>' || NL; --date

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E035') ||
                           '</font></TH>' || NL; -- N° comm

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E018') ||
                           '</font></TH>' || NL; -- ID

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E016') ||
                           '</font></TH>' || NL; -- montant

            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""employee_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E026') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""action_3""><font ' || L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E027') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           '  id=""actionNote_3""><font ' ||
                           L_FONT_HEADER_STYLE || '>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E028') ||
                           '</font></TH>' || NL;
            vv_document := vv_document || '</TR>' || NL;

            vv_document := vv_document || NL || '<TR>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_invoice_num, ' ') || '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_desc, ' ') || '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_num_vendeur, ' ') || '</font></td>' || NL;

            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_code_sitefourn, ' ') ||
                           '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_nom_fourn, ' ') || '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""employee_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_pay_group, ' ') || '</font></td>' || NL;

            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_invoice_type, ' ') ||
                           '</font></td>' || NL;

            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(to_char(vd_invoice_date), ' ') ||
                           '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(vv_num_command, ' ') || '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(to_char(vn_invoice_id), ' ') ||
                           '</font></td>' || NL;
            vv_document := vv_document || NL || '<td ' ||
                           L_TABLE_CELL_UNIQUE_STYLE ||
                           ' headers=""action_3""><font ' ||
                           L_FONT_CELL_STYLE || '>' ||
                           nvl(to_char(vn_invoice_amount), ' ') ||
                           '</font></td>' || NL;
            --      vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' colspan=""3"" headers=""action_3"">'|| NL;
            --      vv_document :=  vv_document || get_blocages_AP( vn_invoice_id);
            --      vv_document :=  vv_document || NL ||'</td>'|| NL;
            --      vv_document := vv_document || '</TR>' || NL;

            vv_document := vv_document ||
                           get_blocages_AP(vn_invoice_id,
                                           vv_type_notif,
                                           vv_item_key);
            vv_document := vv_document || '</TABLE> ' || NL;
            pv_document := vv_document;
        elsif (pv_display_type = 'text/plain') then
            pv_document := '';
        end if;
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_infos_AP  fin ',
                         cn_mode_debug);

    END get_infos_AP;

    /*
    PROCEDURE get_blocages_AP(pv_document_id        in      varchar2,
                                     pv_display_type   in      varchar2,
                                     pv_document       in out NOCOPY  varchar2,
                                     pv_document_type  in out NOCOPY  varchar2) IS

      vv_item_type    wf_items.item_type%TYPE;
      vv_item_key     wf_items.item_key%TYPE;
     -- l_org_id           po_requisition_lines.org_id%TYPE;
      vv_document         VARCHAR2(32000) := '';
      NL                 VARCHAR2(1) := fnd_global.newline;
      l_notification_id number;
      vn_invoice_id number;

    BEGIN
      print_wf_message(vv_item_type,
                               vv_item_key, 'get_blocages  document_id= ' || pv_document_id ||'pv_display_type ' ||pv_display_type, cn_mode_debug );

      get_item_info(pv_document_id, vv_item_type, vv_item_key, l_notification_id);


      vn_invoice_id := substr(vv_item_key, 1, instr(vv_item_key,'_')-1);

      -- fnd_client_info.set_org_context(to_char(l_org_id));

      print_wf_message(vv_item_type,
                               vv_item_key, 'get_blocages  vv_item_type= ' || vv_item_type ||'vv_item_key ' ||vv_item_key ||'vn_invoice_id ' ||vn_invoice_id, cn_mode_debug);
      if (pv_display_type = 'text/html') then

        vv_document := NL || NL || '<!-- BLOCAGES -->'|| NL || NL ;
        vv_document := vv_document || '<TABLE ' || L_TABLE_STYLE || '>' || NL;
        vv_document := vv_document || '<TR>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=20% id=""employee_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E026') || '</TH>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=12% id=""action_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E027') || '</TH>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=35% id=""actionNote_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E028') || '</TH>' || NL;
        vv_document := vv_document || '</TR>' || NL;

        for histo1 in (
          select aplc.lookup_code, aplc.displayed_field
          from  ap_lookup_codes aplc, ap_holds_all ah
          where  ah.hold_lookup_code = aplc.lookup_code
          and ah.invoice_id = vn_invoice_id
      )    LOOP
          vv_document :=  vv_document || NL || '<TR>' || NL;
          vv_document :=  vv_document || NL ||   '<td ' || L_TABLE_CELL_STYLE || ' headers=""employee_3"">'|| nvl(histo1.displayed_field, ' ') ||'</td>' || NL;
          vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' headers=""action_3"">' || nvl(histo1.lookup_code, ' ') ||'</td>'|| NL;
          vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' headers=""action_3"">  </td>'|| NL;
          vv_document := vv_document || '</TR>' || NL;
        end loop;

        vv_document := vv_document || '</TABLE> ' || NL;
        pv_document := vv_document;
      elsif (pv_display_type = 'text/plain') then
        pv_document := '';
      end if;
    END get_blocages_AP;

    */
    /*
    PROCEDURE get_blocages_OI(pv_document_id        in      varchar2,
                                     pv_display_type   in      varchar2,
                                     pv_document       in out NOCOPY  varchar2,
                                     pv_document_type  in out NOCOPY  varchar2) IS

      vv_item_type    wf_items.item_type%TYPE;
      vv_item_key     wf_items.item_key%TYPE;
     -- l_org_id           po_requisition_lines.org_id%TYPE;
      vv_document         VARCHAR2(32000) := '';
      NL                 VARCHAR2(1) := fnd_global.newline;
      l_notification_id number;
      vn_invoice_id number;

    BEGIN
    print_wf_message(vv_item_type,
                               vv_item_key, 'get_blocages  document_id= ' || pv_document_id ||'pv_display_type ' ||pv_display_type , cn_mode_debug);

      get_item_info(pv_document_id, vv_item_type, vv_item_key, l_notification_id);


    vn_invoice_id := substr(vv_item_key, 1, instr(vv_item_key,'_')-1);

     -- fnd_client_info.set_org_context(to_char(l_org_id));
    print_wf_message(vv_item_type,
                               vv_item_key, 'get_blocages  vv_item_type= ' || vv_item_type ||'vv_item_key ' ||vv_item_key ||'vn_invoice_id ' ||vn_invoice_id, cn_mode_debug);

      if (pv_display_type = 'text/html') then

        vv_document := NL || NL || '<!-- BLOCAGES -->'|| NL || NL ;
        vv_document := vv_document || '<TABLE ' || L_TABLE_STYLE || ' >' || NL;
        vv_document := vv_document || '<TR>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=20% id=""employee_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E026') || '</TH>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=12% id=""action_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E027') || '</TH>' || NL;
        vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=35% id=""actionNote_3"">' ||
                      fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E028') || '</TH>' || NL;
        vv_document := vv_document || '</TR>' || NL;

        for histo1 in (
         --rejets OI lignes de facture
        select aili.invoice_id, alc.lookup_code, alc.displayed_field
         from ap_interface_rejections air, ap_lookup_codes alc, AP_INVOICE_LINES_INTERFACE aili
         where
          alc.lookup_code = air.reject_lookup_code
         and alc.lookup_type = 'REJECT CODE'
         and air.parent_id =aili.invoice_line_id
         and air.parent_table = 'AP_INVOICE_LINES_INTERFACE'
         and  aili.invoice_id = vn_invoice_id
        union
        --rejets OI facture
        select air.parent_id, alc.lookup_code, alc.displayed_field
         from ap_interface_rejections air, ap_lookup_codes alc
         where alc.lookup_code = air.reject_lookup_code
         and alc.lookup_type = 'REJECT CODE'
         and air.parent_table = 'AP_INVOICES_INTERFACE'
         and air.parent_id = vn_invoice_id)
        LOOP
          vv_document :=  vv_document || NL || '<TR>' || NL;
          vv_document :=  vv_document || NL ||   '<td ' || L_TABLE_CELL_STYLE || ' headers=""employee_3"">'|| nvl(histo1.displayed_field, ' ') ||'</td>' || NL;
          vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' headers=""action_3"">' || nvl(histo1.lookup_code, ' ') ||'</td>'|| NL;
          vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' headers=""action_3"">  </td>'|| NL;
          vv_document := vv_document || '</TR>' || NL;
        end loop;

        --rejets Xerox
        for histo2 in (
          select dsl.return_value , dsl.param1_value
          from   dka_stransco_headers dsh, dka_stransco_lines dsl
          where dsh.Set_Id = dsl.set_id
          AND dsh.set_name = 'CODE REJET XEROX / ORACLE'
          and dsl.return_value in (select attribute4
                                  from  AP_INVOICES_INTERFACE aii
                                  where  aii.invoice_id  = vn_invoice_id
                              union
                              select attribute5
                                  from  AP_INVOICES_INTERFACE aii
                                  where  aii.invoice_id  = vn_invoice_id
                               union select attribute6
                                  from  AP_INVOICES_INTERFACE aii
                                  where  aii.invoice_id  = vn_invoice_id
                               union select attribute7
                                  from  AP_INVOICES_INTERFACE aii
                                  where  aii.invoice_id  = vn_invoice_id
                               union select attribute11
                                  from  AP_INVOICES_INTERFACE aii
                                  where  aii.invoice_id  = vn_invoice_id
                              )
            ) LOOP
          vv_document :=  vv_document || NL || '<TR>' || NL;
          vv_document :=  vv_document || NL ||   '<td ' || L_TABLE_CELL_STYLE || ' headers=""employee_3"">'|| nvl(histo2.return_value, ' ') ||'</td>' || NL;
          vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' headers=""action_3"">' || nvl(histo2.param1_value, ' ') ||'</td>'|| NL;
          vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' headers=""action_3"">  </td>'|| NL;
          vv_document := vv_document || '</TR>' || NL;
        end loop;

        vv_document := vv_document || '</TABLE> ' || NL;

        pv_document := vv_document;
      elsif (pv_display_type = 'text/plain') then
        pv_document := '';
      end if;
    END get_blocages_OI;
    */
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
                                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                       pv_funcmode  IN VARCHAR2,
                                       pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_reponse VARCHAR2(2000);
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'reponse_notif_precedente debut ',
                         cn_mode_debug);

        vv_reponse := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                    itemtype => pv_itemtype,
                                                    itemkey  => pv_itemkey,
                                                    aname    => 'REPONSE_PRECEDENTE');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'reponse_notif_precedente reponse =  ' ||
                         vv_reponse,
                         cn_mode_debug);

        pv_resultout := vv_reponse;
        return;
    END reponse_notif_precedente;

    PROCEDURE string_to_table(vv_chaine     IN VARCHAR2,
                              vv_separateur IN VARCHAR2,
                              l_tab         OUT tableau,
                              vn_tablen     OUT number) AS
        l_string      VARCHAR2(32767) := vv_chaine || vv_separateur;
        l_comma_index PLS_INTEGER;
        l_index       PLS_INTEGER := 1;
    BEGIN
        l_tab := tableau();
        LOOP
            l_comma_index := INSTR(l_string, vv_separateur, l_index);
            EXIT WHEN l_comma_index = 0;
            l_tab.EXTEND;
            l_tab(l_tab.COUNT) := SUBSTR(l_string,
                                         l_index,
                                         l_comma_index - l_index);
            l_index := l_comma_index + 1;
        END LOOP;

        vn_tablen := l_tab.COUNT;

    END string_to_table;

    -------------------------------------------------------------------------------------
    --  Nom           : contexte_PNC
    --  Description   :
    --
    --  PARAMETRES :
    --
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE contexte_PNC(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                           pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                           pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                           pv_funcmode  IN VARCHAR2,
                           pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_oi_id  ap_invoices_all.invoice_id%type;
        vv_blocagesXerox  ap_invoices_interface.attribute1%type;
        vn_blocage_actuel number;
        l_tab             tableau;
        l_tablen          number;
        vv_req_sql_maj    varchar2(4000);
        vv_blocage_desc   AP_INVOICES_INTERFACE.ATTRIBUTE4%type;
        vv_source         AP_INVOICES_INTERFACE.SOURCE%type;
        vn_idx            PLS_INTEGER;
        vv_blocage_oi     dka_stransco_lines.param2_value%TYPE;
    BEGIN

        -- Do nothing in cancel or timeout mode
        --
        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'context pnc debut',
                         cn_mode_debug);

        vn_invoice_oi_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                        itemkey  => pv_itemkey,
                                                        aname    => 'INVOICE_OI_ID');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'context pnc vn_invoice_oi_id' ||
                         vn_invoice_oi_id,
                         cn_mode_debug);

        vv_blocagesXerox := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'BLOCAGES_XEROX');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'context pnc vv_blocagesXerox' ||
                         vv_blocagesXerox,
                         cn_mode_debug);

        IF vv_blocagesXerox is not null then
            select source
              into vv_source
              from ap_invoices_interface
             where invoice_id = vn_invoice_oi_id;
            IF vv_source = 'SCAN' then
                vv_req_sql_maj := ' update AP_INVOICES_INTERFACE aii set  ATTRIBUTE_CATEGORY = ''' ||
                                  cv_contexte_OSC || ''' ';
            ELSE
                vv_req_sql_maj := ' update AP_INVOICES_INTERFACE aii set  ATTRIBUTE_CATEGORY = ''' ||
                                  cv_contexte_XGS || ''' ';
            END IF;
            /*      dbms_utility.comma_to_table(replace(vv_blocagesXerox, '.', ','),
            l_tablen,
            l_tab);
            */
            string_to_table(vv_blocagesXerox, '.', l_tab, l_tablen);
            vn_idx := 1;

            for vn_blocage_actuel in 1 .. least(l_tablen, 3/*5*/) loop
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'context pnc vn_blocage_actuel' ||
                                 vn_blocage_actuel || '  ' ||
                                 l_tab(vn_blocage_actuel),
                                 cn_mode_debug);
                BEGIN
                    select fvs.description, upper(dsl.param2_value)
                      into vv_blocage_desc, vv_blocage_oi
                      from fnd_flex_value_sets  ffs,
                           fnd_flex_values_vl   fvs,
                           dka_stransco_headers dsh,
                           dka_stransco_lines   dsl
                     where ffs.flex_value_set_name = 'DKA_CODES_XEROX'
                       and fvs.flex_value_set_id = ffs.flex_value_set_id
                       and fvs.flex_value = dsl.param1_value -- code xerox
                       and dsh.Set_Id = dsl.set_id
                       AND dsh.set_name = 'CODE REJET XEROX / ORACLE'
                       and dsl.param1_value = l_tab(vn_blocage_actuel);

                    IF nvl(vv_blocage_oi, 'NON') = 'OUI' THEN

                        CASE vn_idx
                            WHEN 1 THEN
                                vv_req_sql_maj := vv_req_sql_maj ||
                                                  ', ATTRIBUTE4 =''' ||
                                                  vv_blocage_desc || '''';
                            WHEN 2 Then
                                vv_req_sql_maj := vv_req_sql_maj ||
                                                  ', ATTRIBUTE5 =''' ||
                                                  vv_blocage_desc || '''';
                            WHEN 3 Then
                                vv_req_sql_maj := vv_req_sql_maj ||
                                                  ', ATTRIBUTE6 =''' ||
                                                  vv_blocage_desc || '''';
                            /*WHEN 4 Then
                                vv_req_sql_maj := vv_req_sql_maj ||
                                                  ', ATTRIBUTE7 =''' ||
                                                  vv_blocage_desc || '''';
                            WHEN 5 Then
                                vv_req_sql_maj := vv_req_sql_maj ||
                                                  ', ATTRIBUTE11 =''' ||
                                                  vv_blocage_desc || '''';*/
                            ELSE
                                print_wf_message(pv_itemtype,
                                                 pv_itemkey,
                                                 'contexte_PNC case DEFAULT vn_idx = ' ||
                                                 vn_idx,
                                                 3);
                        END CASE;

                        vn_idx := vn_idx + 1;

                    END IF;

                exception
                    when NO_DATA_FOUND then
                        print_wf_message(pv_itemtype,
                                         pv_itemkey,
                                         'contexte_PNC, aucun blocage trouve pour  ' ||
                                         l_tab(vn_blocage_actuel),
                                         3);
                        /*pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
                        RETURN;*/
                end;
            end loop;

            vv_req_sql_maj := vv_req_sql_maj || ' where invoice_id = ' ||
                              vn_invoice_oi_id;
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             vv_req_sql_maj,
                             cn_mode_debug);
            execute immediate vv_req_sql_maj;

        end if;

        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DOC_HISTO',
                                  avalue   => 'PLSQL:DKA_SAPWFCSP_pkg.GET_ACTION_HISTORY/' ||
                                              pv_itemtype || ':' ||
                                              pv_itemkey);

        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DOC_BLOCAGES',
                                  avalue   => 'PLSQL:DKA_SAPWFCSP_pkg.GET_INFOS_OI/' ||
                                              pv_itemtype || ':' ||
                                              pv_itemkey);

        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DOC_BLOCAGES_OI',
                                  avalue   => 'PLSQL:DKA_SAPWFCSP_pkg.GET_INFOS_OI/' ||
                                              pv_itemtype || ':' ||
                                              pv_itemkey);

        insert_history(pv_itemtype,
                       pv_itemkey,
                       'DKA_SOUMIS',
                       wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'BLOCAGES_XEROX'),
                       '',
                       WF_DIRECTORY.GetRoleDisplayName(wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                                                 itemkey  => pv_itemkey,
                                                                                 aname    => 'DKA_RESP_CSP_ANO')

                                                       ));
        pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

    EXCEPTION
        WHEN OTHERS THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'contexte_PNC erreur : ' || SQLERRM,
                             3);
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END contexte_PNC;

    PROCEDURE recupere_transmis_a(itemtype     IN VARCHAR2,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) IS

        vv_forward_to_username_respons varchar2(100);

    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        vv_forward_to_username_respons := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                                    itemkey  => pv_itemkey,
                                                                    aname    => 'FORWARD_TO_USERNAME_RESPONSE');

        /* Set the FORWARD-TO */

        wf_engine.SetItemAttrText(itemtype => itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'FORWARD_TO_USERNAME',
                                  avalue   => vv_forward_to_username_respons);

        /*  wf_engine.SetItemAttrNumber ( itemtype   => itemType,
                                           itemkey    => itemkey,
                                           aname      => 'FORWARD_TO_ID',
                                           avalue     => x_user_id);
        */
        /* Get the Display name for the user from the WF Directory  */
        wf_engine.SetItemAttrText(itemtype => itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'FORWARD_TO_DISPLAY_NAME',
                                  avalue   => wf_directory.GetRoleDisplayName(vv_forward_to_username_respons));

        pv_resultout := wf_engine.eng_completed || ':' || 'Y';

    END recupere_transmis_a;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_OI
    --  Description   :   Procedure gérant la notification que recoit CSP_ANO
    --                            pour une ano OI (etape 2)
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_OI(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                               pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                               pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                               pv_funcmode  IN VARCHAR2,
                               pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin




        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);


            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_OI en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        -- if (pv_funcmode = wf_engine.eng_run) then
        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if vv_commentaires is null then

                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'Pas de commentaires',
                                 cn_mode_debug);
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');

            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

        end if;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'BLOCAGES_XEROX'),
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_OI fin',
                         cn_mode_debug);
    end notif_CSP_ANO_OI;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_REF_OI
    --  Description   :   Procedure gérant la notification que recoit CSP REF
    --                            en trsnfert de CSP ANO pour une ano OI  (etape 3)
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_REF_OI(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                               pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                               pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                               pv_funcmode  IN VARCHAR2,
                               pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_fournisseur_cree            varchar2(100);
        vv_site_fournisseur_cree       varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin


        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_REF_OI en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        -- 04072013   BCO   nombre de caractere limité a 100 pour commentaire et a 20 pour fournisseur et site fournisseur.
        vv_commentaires := substr(wf_notification.GetAttrText(vn_nid,
                                                              'DKA_COMMENTS'),
                                  0,
                                  100);

        vv_fournisseur_cree      := substr(wf_notification.GetAttrText(vn_nid,
                                                                       'DKA_FOURN_CREE_CSP_REF_OI'),
                                           0,
                                           20);
        vv_site_fournisseur_cree := substr(wf_notification.GetAttrText(vn_nid,
                                                                       'DKA_SITEFOURN_CREE_CSP_REF_OI'),
                                           0,
                                           20);

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if vv_commentaires is null then
                if vv_result = 'DKA_ATTENTE' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E052');
                    return;
                elsif vv_result = 'DKA_REFUS_CREATION' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E066');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'commentaires null pour refus => DKA_SAPWFCSP_E066',
                                     cn_mode_debug);
                    return;
                else
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E051');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'commentaires null ',
                                     cn_mode_debug);
                    return;
                end if;
            end if;

            if vv_fournisseur_cree is null or
               vv_site_fournisseur_cree is null then
                if vv_result = 'DKA_FOURN_CREE' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E057');

                    return;
                end if;
            end if;

            -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey =>  pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then
            -- traitement
            if vv_result = 'DKA_FOURN_CREE' then
                --Recherche du nombre de caractere lors de l'affichage du message.
                vv_commentaires := substr(dka_tools_pkg.get_message('DKA',
                                                                    'DKA_SAPWFCSP_E058',
                                                                    'CMPT_FOURN',
                                                                    vv_fournisseur_cree,
                                                                    'SITE_FOURN',
                                                                    vv_site_fournisseur_cree),
                                          0,
                                          200);
            end if;

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'BLOCAGES_XEROX'),
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_REF_OI fin',
                         cn_mode_debug);
    end notif_CSP_REF_OI;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_OI_REP
    --  Description   :   Procedure gérant la notification que recoit CSP ANO
    --                            en réponse au CSP REF pour une ano OI  (apres l'etape 3)
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_OI_REP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                   pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                   pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_nom_item_wf_stockage_action varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin


        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);
        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        IF (pv_funcmode = 'RESPOND') THEN
            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        END IF;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'BLOCAGES_XEROX'),
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_OI_REP fin',
                         cn_mode_debug);
    end notif_CSP_ANO_OI_REP;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_IMPUT_ATT
    --  Description   :   Procedure gérant la notification que recoit CSP_ANO
    --                            pour une ano INPUTATION_EN_ATTENTE (etape 5)
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_IMPUT_ATT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                      pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                      pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                      pv_funcmode  IN VARCHAR2,
                                      pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        vv_nom_employe                 varchar2(240);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin


        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_IMPUT_ATT en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if vv_result = 'DKA_FORWARD_BAP' AND vv_nom_employe is null then
                --          pv_resultout :='ERROR: You must enter an employee  if forwarding.';
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E050');
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'retransmettre vide => DKA_SAPWFCSP_E050',
                                 cn_mode_debug);
                return;
            end if;

            if vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
                /*
                if vv_result = 'DKA_ATTENTE' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    'Vous devez donner une raison a la mise en attente.';
                    return;
                elsif vv_result = 'DKA_FORWARD' then
                       pv_resultout := wf_engine.eng_error || ':' ||
                                    'Vous devez donner une raison au transert.';
                       return;
                end if;
                */
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);

        end if;

        if (pv_funcmode = wf_engine.eng_run) then
            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);



            -- stocke qui fait l'action
            BEGIN
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'VALIDEUR_IMPUT',
                                          avalue   => wf_notification.Responder(vn_nid));
            EXCEPTION
                WHEN OTHERS THEN
                    -- gestion de l'exception pour que l'ancien WF fonctionne
                    null;
            END;
            -- stocke l'employe vers qui on transfere
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VALIDEUR_BAP',
                                      avalue   => vv_nom_employe);

            --19012011 MT Resetting LIB_TITRE_DEMANDE_IMPUT_BAP itemkey value
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_DEMANDE_IMPUT_BAP',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E012'));

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           cv_ano_imput_attente,
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_IMPUT_ATT fin',
                         cn_mode_debug);
    end notif_CSP_ANO_IMPUT_ATT;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_EXPLOIT_IMPUT_ATT
    --  Description   :   Procedure gérant la notification que recoit le chef d'exploitation
    --                            pour une ano INPUTATION_EN_ATTENTE (etape 6)
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_EXPLOIT_IMPUT_ATT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                      pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                      pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                      pv_funcmode  IN VARCHAR2,
                                      pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        vv_code_projet                 varchar2(2000);
        vv_type_depense                varchar2(2000);
        vv_message_name                wf_notifications.message_name%TYPE;
        vv_nom_employe                 VARCHAR2(240);
        vv_comment_temp                varchar2(2000);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin


        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
        -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_EXPLOIT_IMPUT_ATT en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        --Recupere le nom de la notification
        SELECT wn.message_name
          INTO vv_message_name
          FROM wf_notifications wn
         WHERE notification_id = vn_nid
           AND wn.message_type = 'DKA_CSP';

        --AND message_name IN (,'DKA_MSG_FWD_BAP')

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'avant comment',
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'commentaires = ' || vv_commentaires,
                         cn_mode_debug);
        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF vv_message_name in
           ('DKA_MSG_FWD_ANO_IMPUT_ATT', 'DKA_MSG_FWD_ANO_IMPUT_ATT2',
            'DKA_MSG_FWD_ANO_IMPUT_ATT_RET') THEN
            vv_code_projet := wf_notification.GetAttrText(vn_nid,
                                                          'DKA_CODE_PROJET');

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'vv_code_projet = ' || vv_code_projet,
                             cn_mode_debug);

            vv_type_depense := wf_notification.GetAttrText(vn_nid,
                                                           'DKA_TYPE_DEP');

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'vv_type_depense = ' || vv_type_depense,
                             cn_mode_debug);
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'vv_result = ' || vv_result,
                             cn_mode_debug);

        END IF;

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if vv_commentaires is null then
                if vv_result = 'DKA_ATTENTE' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E052');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'commentaires null pour en attente => DKA_SAPWFCSP_E052',
                                     cn_mode_debug);
                    return;
                else
                    -- modif VK suite artf484697. Le commentaires est toujours obligatoire
                    --if vv_result <>'DKA_APPROVE'  then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E051');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'commentaires null pour refus => DKA_SAPWFCSP_E051',
                                     cn_mode_debug);
                    return;
                    --end if;
                end if;
            end if;

            if vv_result IN
               ('DKA_REFUSE', 'DKA_APPROVE', 'DKA_ERR_RETRANSMIS') then

                if (vv_code_projet is null or vv_type_depense is null) AND
                   vv_message_name in ('DKA_MSG_FWD_ANO_IMPUT_ATT',
                    'DKA_MSG_FWD_ANO_IMPUT_ATT2') then
                    --            pv_resultout :='ERROR: You must enter rejection reason if rejecting.';
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E053');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'infos projet ou/et type depense non renseignes => DKA_SAPWFCSP_E053',
                                     cn_mode_debug);
                    return;
                end if;
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                IF vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    RETURN;
                END IF;
            end if;

            IF vv_message_name in
               ('DKA_MSG_FWD_ANO_IMPUT_ATT2', 'DKA_MSG_FWD_ANO_IMPUT_ATT',
                'DKA_MSG_FWD_ANO_IMPUT_ATT_RET') THEN
                vv_comment_temp := dka_tools_pkg.get_message('DKA',
                                                             'DKA_SAPWFCSP_E054',
                                                             'CODE_PROJET',
                                                             vv_code_projet,
                                                             'TYPE_DEPENSE',
                                                             vv_type_depense) || ' ' ||
                                   vv_commentaires;
                IF length(cv_ano_imput_attente || ' - ' || vv_comment_temp) > 238 THEN
                    -- changement de la taille du message
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E067');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'infos projet, type depense, commentaires trop longs => DKA_SAPWFCSP_E067',
                                     cn_mode_debug);
                    return;
                END IF;
            END IF;
            --fin 05012008   VKN artf428924 : Erreur lors de la Réponse suite a demande d'imputationORA-06502: PL/SQL: numeric or value error

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) AND
           vv_message_name in
           ('DKA_MSG_FWD_ANO_IMPUT_ATT', 'DKA_MSG_FWD_ANO_IMPUT_ATT2') then
            --traitement
            if vv_result = 'DKA_REFUSE' then
                vv_commentaires := dka_tools_pkg.get_message('DKA',
                                                             'DKA_SAPWFCSP_E055',
                                                             'REFUS_COMMENT',
                                                             vv_commentaires);

                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_BLOCAGE_IMPUT',
                                          avalue   => vv_commentaires);
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                -- stocke l'employe vers qui on retransmet
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'VALIDEUR_BAP',
                                          avalue   => vv_nom_employe);

            end if;

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result IN
               ('DKA_REFUSE', 'DKA_APPROVE', 'DKA_ERR_RETRANSMIS') THEN
                --- 19012011   MT
                vv_commentaires := dka_tools_pkg.get_message('DKA',
                                                             'DKA_SAPWFCSP_E054',
                                                             'CODE_PROJET',
                                                             vv_code_projet,
                                                             'TYPE_DEPENSE',
                                                             vv_type_depense) || ' ' ||
                                   vv_commentaires;
            END IF;

            --- 19012011   MT
            IF vv_result = 'DKA_ERR_RETRANSMIS' THEN

                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'LIB_TITRE_DEMANDE_IMPUT_BAP',
                                          avalue   => 'RETOUR CSP - ' ||
                                                      dka_tools_pkg.get_message('DKA',
                                                                                'DKA_SAPWFCSP_E012'));
            END IF;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           cv_ano_imput_attente,
                           vv_commentaires);
        ELSIF (pv_funcmode = wf_engine.eng_run) AND
              vv_message_name = 'DKA_MSG_FWD_BAP' then
            --traitement
            if vv_result = 'DKA_REFUSE' then
                vv_commentaires := dka_tools_pkg.get_message('DKA',
                                                             'DKA_SAPWFCSP_E055',
                                                             'REFUS_COMMENT',
                                                             vv_commentaires);
            end if;

            -- stocke le commentaire de refus
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_RAISON_BLOCAGE_IMPUT',
                                      avalue   => vv_commentaires);

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Bon à Payer',
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_EXPLOIT_IMPUT_ATT fin',
                         cn_mode_debug);
    end notif_EXPLOIT_IMPUT_ATT;

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
                                pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        vv_nom_employe                 per_all_people_f.full_name%TYPE;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_EXPLOIT_BAP en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if vv_commentaires is null then
                if vv_result = 'DKA_ATTENTE' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E052');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'commentaires null pour en attente => DKA_SAPWFCSP_E052',
                                     cn_mode_debug);
                    return;
                else
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E051');
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'commentaires null=> DKA_SAPWFCSP_E051',
                                     cn_mode_debug);
                    return;

                end if;
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                IF vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    RETURN;
                END IF;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then
            --traitement
            if vv_result = 'DKA_REFUSE' then
                vv_commentaires := dka_tools_pkg.get_message('DKA',
                                                             'DKA_SAPWFCSP_E055',
                                                             'REFUS_COMMENT',
                                                             vv_commentaires);
            end if;

            -- stocke le commentaire de refus
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_RAISON_BLOCAGE_IMPUT',
                                      avalue   => vv_commentaires);

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'VALIDEUR_BAP',
                                          avalue   => vv_nom_employe);
            end if;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Bon à Payer',
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_EXPLOIT_BAP fin',
                         cn_mode_debug);
    end notif_EXPLOIT_BAP;

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
                                       pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        vv_nom_employe                 per_all_people_f.full_name%TYPE;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_HIERAR_EXPLOIT_BAP en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if vv_commentaires is null then
                if vv_result = 'DKA_ATTENTE' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E052');
                    return;
                else
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E051');
                    return;
                end if;
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                IF vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    RETURN;
                END IF;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then
            --traitement

            if vv_result = 'DKA_REFUSE' then
                vv_commentaires := dka_tools_pkg.get_message('DKA',
                                                             'DKA_SAPWFCSP_E055',
                                                             'REFUS_COMMENT',
                                                             vv_commentaires);

                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_BLOCAGE_IMPUT',
                                          avalue   => vv_commentaires);

            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'VALIDEUR_BAP',
                                          avalue   => vv_nom_employe);
            end if;

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Bon à Payer',
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_HIERAR_EXPLOIT_BAP fin',
                         cn_mode_debug);
    end notif_HIERAR_EXPLOIT_BAP;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_BAP
    --  Description   :   Procedure gérant la notification que recoit CSP_ANO
    --                            pour une ano BAP (etape 13)
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_BAP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_nom_employe                 varchar2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN

           l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_BAP en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        --    vv_result := wf_notification.GetAttrText(vn_nid,'Z_ACTION');
        vv_result := wf_notification.GetAttrText(vn_nid, 'RESULT');
        --    print_wf_message(pv_itemtype, pv_itemkey, 'vv_result = ' || vv_result ||
        --                                       'commentaires = ' ||  vv_commentaires);

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;
            -- if  vv_result = 'DKA_FORWARD' and vv_nom_employe is null then
            if vv_nom_employe is null then
                --            pv_resultout :='ERROR: You must enter an employee  if forwarding.';
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E050');
                return;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- stocke l'employe vers qui on transfere
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VALIDEUR_BAP',
                                      avalue   => vv_nom_employe);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Bon à Payer',
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_BAP fin',
                         cn_mode_debug);
    end notif_CSP_ANO_BAP;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_RET_IMPUT_ATT
    --  Description   :   Procedure gérant la notification que recoit CSP_ANO
    --                            en retour d'une ano INPUTATION_EN_ATTENTE (etape 11)
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_RET_IMPUT_ATT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                          pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                          pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                          pv_funcmode  IN VARCHAR2,
                                          pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid          wf_notifications.notification_id%type;
        vv_result       varchar2(100);
        vv_commentaires AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_RET_IMPUT_ATT en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        --    vv_result := wf_notification.GetAttrText(vn_nid,'Z_ACTION');

        vv_result := wf_notification.GetAttrText(vn_nid, 'RESULT');

        IF (pv_funcmode = 'RESPOND') THEN
            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        END IF;

        if (pv_funcmode = wf_engine.eng_run) then
            BEGIN
                -- stocke qui fait l'action
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'VALIDEUR_IMPUT',
                                          avalue   => wf_notification.Responder(vn_nid));
            EXCEPTION
                WHEN OTHERS THEN
                    -- gestion de l'exception pour que l'ancien WF fonctionne
                    null;
            END;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Imputation en attente',
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_RET_IMPUT_ATT fin',
                         cn_mode_debug);
    end notif_CSP_ANO_RET_IMPUT_ATT;

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
                                 pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_PRLV en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        -- if (pv_funcmode = wf_engine.eng_run) then
        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if /*vv_result = 'DKA_ATTENTE' AND*/
             vv_commentaires is null then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'Pas de commentaires pour mise en attente',
                                 cn_mode_debug);
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            -- stocke qui fait l'action
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VALIDEUR_ANO_PRLVT',
                                      avalue   => wf_notification.Responder(vn_nid));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_ANO_PRLV_ABS'),
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_PRLV fin',
                         cn_mode_debug);

    END notif_CSP_ANO_PRLV;

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
                                   pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_nid          wf_notifications.notification_id%type;
        vv_result       varchar2(100);
        vv_commentaires AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_AFFACT en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        IF (pv_funcmode = 'RESPOND') THEN
            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        END IF;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke qui fait l'action
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VALIDEUR_AFFACT',
                                      avalue   => wf_notification.Responder(vn_nid));

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_ANO_AFFFACT'),
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_AFFACT fin',
                         cn_mode_debug);

    END notif_CSP_ANO_AFFACT;

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
                                   pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_compte_cree                 varchar2(100);
        vv_site_cree                   varchar2(100);
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_REF_AFFACT en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);

        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        -- 04072013   BCO   nombre de caractere limité a 100 pour commentaire et a 20 pour fournisseur et site fournisseur.
        vv_commentaires := substr(wf_notification.GetAttrText(vn_nid,
                                                              'DKA_COMMENTS'),
                                  0,
                                  100);

        vv_compte_cree := substr(wf_notification.GetAttrText(vn_nid,
                                                             'DKA_COMPTE_FOURN_AFFACT'),
                                 0,
                                 20);
        vv_site_cree   := substr(wf_notification.GetAttrText(vn_nid,
                                                             'DKA_SITE_FOURN_AFFACT'),
                                 0,
                                 20);

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if /*vv_result = 'DKA_ATTENTE' AND*/
             vv_commentaires is NULL then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'Pas de commentaires pour mise en attente',
                                 cn_mode_debug);
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

            if vv_compte_cree is null or vv_site_cree is null then
                if vv_result = 'DKA_NOTIF_TRAITEE' then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E065');
                    return;
                end if;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then
            -- traitement
            if vv_result = 'DKA_NOTIF_TRAITEE' then
                vv_commentaires := substr(dka_tools_pkg.get_message('DKA',
                                                                    'DKA_SAPWFCSP_E058',
                                                                    'CMPT_FOURN',
                                                                    vv_compte_cree,
                                                                    'SITE_FOURN',
                                                                    vv_site_cree) || ' ' ||
                                          vv_commentaires,
                                          0,
                                          200);
            end if;

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_ANO_AFFFACT'),
                           vv_commentaires);
        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_REF_AFFACT fin',
                         cn_mode_debug);
    END notif_CSP_REF_AFFACT;

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
                                pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_RIB en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);

        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        -- if (pv_funcmode = wf_engine.eng_run) then
        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if /*vv_result = 'DKA_ATTENTE' AND */
             vv_commentaires is null then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'Pas de commentaires',
                                 cn_mode_debug);
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then
            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- stocke qui fait l'action
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VALIDEUR_ANO_RIB',
                                      avalue   => wf_notification.Responder(vn_nid));

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_ANO_RIB'),
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_RIB fin',
                         cn_mode_debug);

    END notif_CSP_ANO_RIB;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_DIVERS
    --  Description   :   Procedure gérant la notification que recoit le CSP ANO
    --                            pour une ano diverses
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_DIVERS(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                   pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                   pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        vv_code_projet                 varchar2(240);
        vv_type_depense                varchar2(240);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_DIVERS en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'vv_result = ' || vv_result || 'commentaires = ' ||
                         vv_commentaires,
                         cn_mode_debug);

        if (pv_funcmode = 'RESPOND') then
            -- Verifications
            if vv_commentaires is null then
                --        if vv_result = 'DKA_ATTENTE' then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'commentaires null pour en attente => DKA_SAPWFCSP_E052',
                                 cn_mode_debug);
                return;
                --      end if;
            end if;

          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONSIBILITY_ID',
                                        avalue  => l_session_resp_id);

                                        wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'APPLICATION_ID',
                                        avalue  => l_session_appl_id);
        end if;

        if (pv_funcmode = wf_engine.eng_run) then
            --traitement
            /*      if vv_result = 'DKA_REFUSE' then
                        vv_commentaires := dka_tools_pkg.get_message('DKA', 'DKA_SAPWFCSP_E054',  'CODE_PROJET',vv_code_projet, 'TYPE_DEPENSE', vv_type_depense) ||' '|| dka_tools_pkg.get_message('DKA', 'DKA_SAPWFCSP_E055', 'REFUS_COMMENT', vv_commentaires);
                  elsif vv_result = 'DKA_APPROVE' then
                        vv_commentaires :=
                        dka_tools_pkg.get_message('DKA', 'DKA_SAPWFCSP_E054', 'CODE_PROJET',vv_code_projet, 'TYPE_DEPENSE', vv_type_depense);
                  end if;
            */
            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Blocages Divers',
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_DIVERS fin',
                         cn_mode_debug);
    end notif_CSP_ANO_DIVERS;

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
                           pv_release_reason in varchar2 default null) IS

        vv_code_deblocage ap_lookup_codes.lookup_code%type;
        vv_desc_deblocage ap_lookup_codes.description%type;
    BEGIN
        print_wf_message(pv_wf_item_type,
                         pv_wf_item_key,
                         'leve_blocage debut code blocage = ' ||
                         pv_blocage_AP || ', code deblocage = ' ||
                         pv_deblocage || ', userID = ' || pn_user_id,
                         3);

        pn_retcode := 0;
        begin
            SELECT lookup_code, description
              into vv_code_deblocage, vv_desc_deblocage
              FROM ap_lookup_codes
             WHERE lookup_type = 'HOLD CODE'
               and lookup_code = nvl(pv_deblocage, 'APPROVED');

            IF pv_release_reason is not null THEN
                vv_desc_deblocage := pv_release_reason;
            END IF;

            print_wf_message(pv_wf_item_type,
                             pv_wf_item_key,
                             'leve_blocage code deblocage = ' ||
                             vv_code_deblocage || ', desc deblocage = ' ||
                             vv_desc_deblocage,
                             3);

            IF pn_verif_orig = 1 THEN
                update ap_holds_all
                   set last_update_date    = SYSDATE,
                       last_updated_by     = pn_user_id,
                       release_lookup_code = vv_code_deblocage,
                       release_reason      = vv_desc_deblocage,
                       status_flag         = 'R' /*,
                                               attribute1          =  pv_wf_item_type,
                                               attribute2          = pv_wf_item_key*/
                 where invoice_id = pn_invoice_id
                   and release_lookup_code is null
                   and attribute1 = pv_wf_item_type
                   and attribute2 = pv_wf_item_key
                   and hold_lookup_code = pv_blocage_AP;
            ELSE
                update ap_holds_all
                   set last_update_date    = SYSDATE,
                       last_updated_by     = pn_user_id,
                       release_lookup_code = vv_code_deblocage,
                       release_reason      = vv_desc_deblocage,
                       status_flag         = 'R',
                       attribute1          = pv_wf_item_type,
                       attribute2          = pv_wf_item_key
                 where invoice_id = pn_invoice_id
                   and release_lookup_code is null
                   and hold_lookup_code = pv_blocage_AP;
            END IF;
            print_wf_message(pv_wf_item_type,
                             pv_wf_item_key,
                             'leve_blocage fin ',
                             3);
        EXCEPTION
            when NO_DATA_FOUND then
                pv_errbuf := 'leve_blocage : Deblocage ' || pv_deblocage ||
                             ' non trouve ';
                print_wf_message(pv_wf_item_type,
                                 pv_wf_item_key,
                                 pv_errbuf,
                                 3);

                pn_retcode := 1;
            when OTHERS then
                print_wf_message(pv_wf_item_type,
                                 pv_wf_item_key,
                                 'leve_blocage : erreur innatendue ' ||
                                 SQLERRM,
                                 3);

        END;
    END leve_blocage;

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
                           pv_release_reason in varchar2 default null) IS

        vv_code_deblocage ap_lookup_codes.lookup_code%type;
        vv_desc_deblocage ap_lookup_codes.description%type;
    BEGIN
        print_wf_message(pv_wf_item_type,
                         pv_wf_item_key,
                         'leve_blocage debut code blocage = ' ||
                         pv_blocage_AP || ', code deblocage = ' ||
                         pv_deblocage || ', userID = ' || pn_user_id,
                         3);

        pn_retcode := 0;
        begin
            SELECT lookup_code, description
              into vv_code_deblocage, vv_desc_deblocage
              FROM ap_lookup_codes
             WHERE lookup_type = 'HOLD CODE'
               and lookup_code = nvl(pv_deblocage, 'APPROVED');

            IF pv_release_reason is not null THEN
                vv_desc_deblocage := pv_release_reason;
            END IF;

            print_wf_message(pv_wf_item_type,
                             pv_wf_item_key,
                             'leve_blocage code deblocage = ' ||
                             vv_code_deblocage || ', desc deblocage = ' ||
                             vv_desc_deblocage,
                             3);

            IF pn_verif_orig = 1 THEN
                update ap_holds_all
                   set last_update_date    = SYSDATE,
                       last_updated_by     = pn_user_id,
                       release_lookup_code = vv_code_deblocage,
                       release_reason      = vv_desc_deblocage,
                       status_flag         = 'R' /*,
                                               attribute1          =  pv_wf_item_type,
                                               attribute2          = pv_wf_item_key*/
                 where invoice_id = pn_invoice_id
                   and release_lookup_code is null
                   and attribute1 = pv_wf_item_type
                   and attribute2 = pv_wf_item_key
                   and hold_lookup_code = pv_blocage_AP;


                  UPDATE xla_events xe
                  SET EVENT_STATUS_CODE = 'U' ,
                      last_update_date    = SYSDATE,
                      last_updated_by     = pn_user_id
                  WHERE EXISTS(SELECT 1
                               from ap_invoice_distributions_all aida
                               where aida.accounting_event_id = xe.event_id
                               and aida.invoice_id = pn_invoice_id);

            ELSE
                update ap_holds_all
                   set last_update_date    = SYSDATE,
                       last_updated_by     = pn_user_id,
                       release_lookup_code = vv_code_deblocage,
                       release_reason      = vv_desc_deblocage,
                       status_flag         = 'R',
                       attribute1          = pv_wf_item_type,
                       attribute2          = pv_wf_item_key
                 where invoice_id = pn_invoice_id
                   and release_lookup_code is null
                   and hold_lookup_code = pv_blocage_AP;
            END IF;

                  UPDATE xla_events xe
                  SET EVENT_STATUS_CODE = 'U'   ,
                      last_update_date    = SYSDATE,
                      last_updated_by     = pn_user_id
                  WHERE EXISTS(SELECT 1
                               from ap_invoice_distributions_all aida
                               where aida.accounting_event_id = xe.event_id
                               and aida.invoice_id = pn_invoice_id);


            print_wf_message(pv_wf_item_type,
                             pv_wf_item_key,
                             'leve_blocage fin ',
                             3);
        EXCEPTION
            when NO_DATA_FOUND then
                pv_errbuf := 'leve_blocage : Deblocage ' || pv_deblocage ||
                             ' non trouve ';
                print_wf_message(pv_wf_item_type,
                                 pv_wf_item_key,
                                 pv_errbuf,
                                 3);

                pn_retcode := 1;
            when OTHERS then
                print_wf_message(pv_wf_item_type,
                                 pv_wf_item_key,
                                 'leve_blocage : erreur innatendue ' ||
                                 SQLERRM,
                                 3);

        END;
    END leve_blocage_aff;
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
                              pn_retcode        OUT NOCOPY NUMBER) IS
        v_blocage_reason ap_lookup_codes.displayed_field%type;
    BEGIN
        pn_retcode := 0;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'cree_blocage_AP debut pv_blocage_AP = ' ||
                         pv_blocage_AP || ',  pv_blocage_reason = ' ||
                         pv_blocage_reason || ',  pn_user_id = ' ||
                         pn_user_id,
                         cn_mode_debug);

        IF (pv_blocage_reason is null) THEN
            begin
                select displayed_field
                  into v_blocage_reason
                  from ap_lookup_codes aplc
                 where aplc.lookup_type = 'HOLD CODE'
                   and aplc.lookup_code = pv_blocage_AP;
            EXCEPTION
                when NO_DATA_FOUND then
                    pv_errbuf := 'blocage AP non trouve pour  ' ||
                                 pv_blocage_AP;

                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     pv_errbuf,
                                     3);
                    pn_retcode := 1;
                    RETURN;
            END;
        END IF;

        BEGIN
            -- INC0298239 - Violation d'option de contrôle
            --MOAC
            --MO_GLOBAL.INIT (p_appl_short_name => 'SQLAP');

            INSERT INTO ap_holds_all
                (invoice_id,
                 org_id,
                 hold_lookup_code,
                 line_location_id,
                 last_update_date,
                 last_updated_by,
                 creation_date,
                 created_by,
                 held_by,
                 hold_date,
                 hold_reason,
                 status_flag,
                 ATTRIBUTE1,
                 ATTRIBUTE2,
                 --- 2017/06/14 NBO artf2171340 - SPE129 - WF Factures - Actions Refus Reglement - Le blocage Litige ne se crée pas Defect 618
                 hold_id)
            VALUES
                (pn_invoice_id,
                 wf_engine.getitemattrnumber(pv_itemtype,
                                             pv_itemkey,
                                             'DKA_ORG_ID'),
                 pv_blocage_AP,
                 pv_line_loc_id,
                 SYSDATE,
                 pn_user_id,
                 SYSDATE,
                 pn_user_id,
                 pn_user_id,
                 SYSDATE,
                 nvl(ltrim(rtrim(pv_blocage_reason)), v_blocage_reason),
                 null, /* --'S',*/
                 decode(pv_source, 'AP', pv_itemtype, null),
                 decode(pv_source, 'AP', pv_itemkey, null),
                 --- 2017/06/14 NBO artf2171340 - SPE129 - WF Factures - Actions Refus Reglement - Le blocage Litige ne se crée pas Defect 618
                 ap_holds_s.nextval);

        EXCEPTION
            when OTHERS then
                pv_errbuf := 'cree_blocage_AP: erreur lors de la creation du blocage ' ||
                             pv_blocage_AP || ' pour facture ' ||
                             pn_invoice_id || 'avec user_id = ' ||
                             pn_user_id || ' et raison ' ||
                             nvl(pv_blocage_reason, v_blocage_reason);

                print_wf_message(pv_itemtype, pv_itemkey, pv_errbuf, 3);
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'cree_blocage_AP: erreur lors de la creation du blocage (2) ' ||
                                 SQLERRM,
                                 3);
                pn_retcode := 1;
                RETURN;
        END;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'cree_blocage_AP fin',
                         cn_mode_debug);
    END cree_blocage_AP;

    /*
      -------------------------------------------------------------------------------------
      --  Nom           : cree_blocage_AP_OI
      --  Description   : Cree le blocage AP sur la facture  pn_invoice_id
      --                      en passant par la table de transco blocage Xerox -> blocage AP
      --  PARAMETRES :
      --
      --  VALEUR RETOURNEE :
      --     N/A
      -------------------------------------------------------------------------------------
      PROCEDURE cree_blocage_AP_OI(pn_invoice_id IN ap_invoices_all.invoice_id%type,
                                   p_blocage_OI  IN ap_invoices_interface.attribute1%type,
                                   pn_user_id    IN fnd_user.user_id%type,
                                   pv_itemtype   IN VARCHAR2,
                                   pv_itemkey    IN VARCHAR2,
                                   pv_errbuf     OUT NOCOPY VARCHAR2,
                                   pn_retcode    OUT NOCOPY NUMBER) IS
        v_blocage_AP     ap_holds_all.hold_lookup_code%type;
        v_blocage_reason ap_lookup_codes.displayed_field%type;
      BEGIN
        pn_retcode := 0;
        IF (p_blocage_OI is not null) THEN
          begin
            -- TODO: recuperer dans la table de transco le blocage AP correspondant au blocage OI
            -- et le mettre dans v_blocage_AP
            --  select  , displayed_field
            --  into v_blocage_reason, v_blocage_AP
            --  from ap_lookup_codes aplc
            --  where aplc.lookup_type = 'HOLD CODE' and  aplc.lookup_code =
            -- and aplc.lookup_code =
            -- and    =  p_blocage_OI;

            cree_blocage_AP(pn_invoice_id,
                            v_blocage_AP,
                            v_blocage_reason,
                            pn_user_id,
                            pv_itemtype,
                            pv_itemkey,
                            pv_errbuf,
                            pn_retcode);

            -- TODO: debloquer les blocages AP qui sont dans la table de transco le blocage AP en blocage OI = Oui

          EXCEPTION
            when NO_DATA_FOUND then
              pv_errbuf := 'Equivalence blocage OI- blocage AP non trouve pour  ' ||
                           p_blocage_OI;

              print_wf_message(pv_itemtype,
                           pv_itemkey,'cree_blocage_AP fin', 3);
              pn_retcode := 1;
              raise;
          END;
        END IF;
      END cree_blocage_AP_OI;
    */
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
                         pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id AP_INVOICES_INTERFACE.invoice_id%type;
        vn_fact_OI    number;
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => itemkey,
                                                     aname    => 'INVOICE_OI_ID');

        select count(1)
          into vn_fact_OI
          from AP_INVOICES_INTERFACE
         where invoice_id = vn_invoice_id
           and status = 'PROCESSED'
           and rownum < 2;

        IF vn_fact_OI = 1 THEN
            pv_resultout := 'COMPLETE:' || 'Y';
        ELSE
            pv_resultout := 'COMPLETE:' || 'N';
        END IF;
    END facture_OI;

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
                                   pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id   ap_invoices_all.invoice_id%type;
        vn_fact_OI      number;
        vv_code_blocage ap_lookup_codes.lookup_code%type;
        vn_user_id      fnd_user.user_id%type;

    l_po_segment1     po_headers_all.segment1%TYPE;
    l_po_attribute7   po_headers_all.attribute7%TYPE;
    lv_user           VARCHAR2(50);
     gc_debug_mode     CONSTANT NUMBER := 1;
   v_deliver_to_person_id po_distributions_all.deliver_to_person_id%type;

    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'demarque_blocage_BAP sur la facture  ' ||
                         vn_invoice_id,
                         cn_mode_debug);

        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'USER_ID');
        --Début SHA EDB408
          BEGIN

      BEGIN
        SELECT poh.segment1, poh.attribute7
        INTO l_po_segment1, l_po_attribute7
        FROM po_headers_all poh
        WHERE poh.po_header_id = (
                        SELECT poh.po_header_id
                        FROM po_headers_all poh
                        JOIN ap_invoices_all aia ON poh.segment1 = aia.attribute13
                        WHERE aia.invoice_id = vn_invoice_id
        );
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
     SELECT poh.segment1, poh.attribute7
         INTO l_po_segment1, l_po_attribute7
        FROM po_headers_all poh
        WHERE poh.po_header_id IN (SELECT aia.po_header_id
                            FROM  ap_invoice_lines_all aia
                            WHERE aia.invoice_id = vn_invoice_id
        );

    END;

        -- Add debug log
        print_wf_message(
            pv_itemtype,
            pv_itemkey,
            'PO details - Segment: ' || l_po_segment1 || ', Attribute7: ' || l_po_attribute7,
            gc_debug_mode
        );

        -- Check if PO is SSTR
        IF l_po_segment1 LIKE 'ST%' AND l_po_attribute7 = 'IVALUA' THEN
            -- Debug message
            print_wf_message(
                pv_itemtype,
                pv_itemkey,
                'Processing SSTR IVALUA PO',
                gc_debug_mode
            );

      begin

                    SELECT MIN(deliver_to_person_id)
          into v_deliver_to_person_id
                    FROM po_distributions_all
                    WHERE po_header_id = (
                        SELECT poh.po_header_id
                        FROM po_headers_all poh
                        JOIN ap_invoices_all aia ON poh.segment1 = aia.attribute13
                        WHERE aia.invoice_id = vn_invoice_id);
         if    v_deliver_to_person_id IS NULL THEN

     SELECT MIN(deliver_to_person_id)
          into v_deliver_to_person_id
                    FROM po_distributions_all
                    WHERE po_header_id in (SELECT aia.po_header_id
                            FROM  ap_invoice_lines_all aia
                            WHERE aia.invoice_id = vn_invoice_id
        );
    END IF;
    end;
            -- Update hold for SSTR
            UPDATE ap_holds_all
            SET attribute4 = 'Y',
                attribute5 = 'BAP',
                attribute6 = v_deliver_to_person_id,
                last_update_date = SYSDATE,
                last_updated_by = vn_user_id
            WHERE invoice_id = vn_invoice_id
            AND hold_lookup_code = 'En attente';

            -- Get user name for history
            SELECT user_name
            INTO lv_user
            FROM fnd_user
            WHERE user_id = vn_user_id;

            -- Add history record
            insert_history(
                pv_itemtype,
                pv_itemkey,
                'DKA_TRANSFERT_IVALUA',
                cv_ano_bon_apayer,
                'Transfert du blocage vers IVALUA',
                WF_DIRECTORY.GetRoleDisplayName(lv_user)
            );
        ELSE
            -- Standard processing for non-SSTR PO
            UPDATE ap_holds_all
            SET last_update_date = SYSDATE,
                last_updated_by  = vn_user_id,
                attribute1       = NULL,
                attribute2       = NULL
            WHERE invoice_id = vn_invoice_id
            AND release_lookup_code IS NULL
            AND hold_lookup_code = cv_ano_bon_apayer;
        END IF;
 --Fin SHA EDB408
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Log the error
            print_wf_message(
                pv_itemtype,
                pv_itemkey,
                'Aucune commande SSTR Ivalua trouvée pour cette facture.',
                3
            );

    END;



    END demarque_blocage_BAP;

    -------------------------------------------------------------------------------------
    --  Nom           : exists_blocage
    --  Description   : Procédure vérifiant si la facture a un blocage
    --                     non leve
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup YES/NO
    -------------------------------------------------------------------------------------
    PROCEDURE exists_blocage(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                             pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                             pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                             pv_funcmode  IN VARCHAR2,
                             pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id ap_invoices_all.invoice_id%type;
        vn_user_id    fnd_user.user_id%type;
        vn_fact_OI    number;
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'USER_ID');

        select count(1)
          into vn_fact_OI
          from AP_HOLDS_ALL
         where invoice_id = vn_invoice_id
           and (release_lookup_code is null -- blocage non leve )
               --  or attribute1 is null
               )
              --and upper(HOLD_LOOKUP_CODE) not like upper('En litige%')
           and rownum < 2;

        IF vn_fact_OI = 1 THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'exists_blocage : retourne oui',
                             cn_mode_debug);
            pv_resultout := 'COMPLETE:' || 'Y';
        ELSE
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'exists_blocage : retourne faux',
                             cn_mode_debug);
            pv_resultout := 'COMPLETE:' || 'N';
        END IF;
    END exists_blocage;

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
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id   ap_invoices_all.invoice_id%type;
        vn_fact_OI      number;
        vv_code_blocage ap_lookup_codes.lookup_code%type;
        vn_user_id      fnd_user.user_id%type;

        --28022012   BCO EARS00009628327 - Variable déterminant le litige PRICE ou MAX SHIP AMOUNT.
        vv_litige                 ap_holds_all.hold_lookup_code%type;
        vv_litige_PRICE           varchar2(50);
        vv_litige_MAX_SHIP_AMOUNT varchar2(50);
    BEGIN
        if (pv_funcmode <> wf_engine.eng_run) then
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        vv_code_blocage := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                         itemtype => pv_itemtype,
                                                         itemkey  => pv_itemkey,
                                                         aname    => 'DKA_TYPE_BLOCAGE');

        vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'USER_ID');

        -- si vv_code_blocage est rempli filtre les blocages pour ne chercher que celui-la

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'exists_blocage_type : recherche du code blocage : ' ||
                         vv_code_blocage || 'sur la facture  ' ||
                         vn_invoice_id,
                         cn_mode_debug);

        IF vv_code_blocage is null THEN
            -- pas de type de blocage precise pour le WF10
            -- affiche tous les blocages non gérés pour la notification du WF10
            select count(1)
              into vn_fact_OI
              from AP_HOLDS_ALL
             where invoice_id = vn_invoice_id
               and release_lookup_code is null
                  -- le workflow n'a pas encore pris en compte ces blocages
               and attribute1 is null
               and upper(HOLD_LOOKUP_CODE) not like upper('En litige%')
               and upper(HOLD_LOOKUP_CODE) <> upper('En attente')
               and attribute2 is null
               and rownum < 2;

            IF vn_fact_OI = 1 then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'exists_blocage_type : update',
                                 cn_mode_debug);
                -- renseigne les attribute1 et 2 de ap_holds pour indiquer qu'un workflow traite ces blocages
                -- et qu'ils ne doivent pas etre rejoues lors d'un prochain passage du traitement
                update ap_holds_all
                   set last_update_date = SYSDATE,
                       last_updated_by  = vn_user_id,
                       attribute1       = pv_itemtype,
                       attribute2       = pv_itemkey
                 where invoice_id = vn_invoice_id
                   and attribute1 is null
                   and release_lookup_code is null;
            END IF;
        ELSE
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'exists_blocage_type : code blocage non null : ' ||
                             vv_code_blocage,
                             cn_mode_debug);
            select count(1)
              into vn_fact_OI
              from AP_HOLDS_ALL
             where invoice_id = vn_invoice_id
               and HOLD_LOOKUP_CODE = vv_code_blocage
               and release_lookup_code is null
                  -- le workflow n'a pas encore pris en compte ces blocages
               and nvl(attribute1, pv_itemtype) = pv_itemtype
               and nvl(attribute2, pv_itemkey) = pv_itemkey
               and rownum < 2;

            IF vn_fact_OI = 1 then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'exists_blocage_type : update',
                                 cn_mode_debug);
                -- renseigne les attribute1 et 2 de ap_holds pour indiquer qu'un workflow traite ces blocages
                -- et qu'ils ne doivent pas etre rejoues lors d'un prochain passage du traitement
                update ap_holds_all
                   set last_update_date = SYSDATE,
                       last_updated_by  = vn_user_id,
                       attribute1       = pv_itemtype,
                       attribute2       = pv_itemkey
                 where invoice_id = vn_invoice_id
                   and release_lookup_code is null
                   and attribute1 is null
                   and hold_lookup_code = vv_code_blocage;

                -- cas special de l'imputation en attente
                -- on marque aussi celui du Bon à Payer
                IF vv_code_blocage = cv_ano_imput_attente THEN
                    update ap_holds_all
                       set last_update_date = SYSDATE,
                           last_updated_by  = vn_user_id,
                           attribute1       = pv_itemtype,
                           attribute2       = pv_itemkey
                     where invoice_id = vn_invoice_id
                       and release_lookup_code is null
                       and hold_lookup_code = cv_ano_bon_apayer;
                END IF;
            END IF;
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'exists_blocage_type : presence de blocage : ' ||
                         vn_fact_OI,
                         cn_mode_debug);

        IF vn_fact_OI = 1 THEN
            -- DEBUT 28022012   BCO EARS00009628327 - Initialisation de l'attribut DKA_LITIGE pour la procédure pose_blocage_litige lorsque le litige est de type PRICE ou MAX SHIP AMOUNT.
            IF vv_code_blocage = cv_ano_ecart_prix THEN
                BEGIN
                    vv_litige_PRICE := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                                 itemkey  => pv_itemkey,
                                                                 aname    => 'DKA_LITIGE_PRIX');

                    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'DKA_LITIGE',
                                              avalue   => vv_litige_PRICE);
                EXCEPTION
                    WHEN OTHERS THEN
                        vv_litige_PRICE := 'En litige Prix';
                END;

            ELSIF vv_code_blocage = cv_ano_motant_livre_maxi THEN
                -- 26092013  BCO  AJOUT GESTION DES EXCEPTIONS
                BEGIN
                    vv_litige_MAX_SHIP_AMOUNT := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                                           itemkey  => pv_itemkey,
                                                                           aname    => 'DKA_LITIGE_MAX_SHIP_AMOUNT');

                    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'DKA_LITIGE',
                                              avalue   => vv_litige_MAX_SHIP_AMOUNT);
                EXCEPTION
                    WHEN OTHERS THEN
                        vv_litige_MAX_SHIP_AMOUNT := 'En litige Prix';
                END;
            END IF;
            -- FIN 28022012   BCO EARS00009628327 - Initialisation de l'attribut DKA_LITIGE pour la procédure pose_blocage_litige lorsque le litige est de type PRICE ou MAX SHIP AMOUNT.
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'exists_blocage_type : retourne oui',
                             cn_mode_debug);
            pv_resultout := 'COMPLETE:' || 'Y';
        ELSE
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'exists_blocage_type : retourne faux',
                             cn_mode_debug);
            pv_resultout := 'COMPLETE:' || 'N';
        END IF;
    END exists_blocage_type;

    -------------------------------------------------------------------------------------
    --  Nom           : exists_misc_holds
    --  Description   : Procedure to check for mislanious open hold codes
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup YES/NO
    -------------------------------------------------------------------------------------
    PROCEDURE exists_misc_holds(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_fact_OI number;
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        select count(1)
          into vn_fact_OI
          from ap_holds_all aha
         where aha.attribute2 = pv_itemkey
           and invoice_id =
               substr(pv_itemkey, 1, instr(pv_itemkey, '_') - 1)
           and release_lookup_code is null
           and exists
         (select 1
                  from dka_stransco_headers dsh, dka_stransco_lines dsl
                 where dsh.set_name = 'DKA_BLOCAGES_NOTIFS'
                   and dsh.set_id = dsl.set_id
                   and return_value = '10'
                   and aha.hold_lookup_code = dsl.param1_value)
           and not exists
         (select 1
                  from wf_item_activity_statuses wias,
                       wf_notifications          wn,
                       dka_stransco_headers      dsh,
                       dka_stransco_lines        dsl,
                       dka_stransco_headers      dsh2,
                       dka_stransco_lines        dsl2
                 where aha.hold_lookup_code = dsl.param1_value
                   and wias.item_key = aha.attribute2
                   and wias.notification_id = wn.notification_id
                   and wn.message_type = 'DKA_CSP'
                   and wn.status = 'OPEN'
                   and dsh.set_name = 'DKA_BLOCAGES_NOTIFS'
                   and dsh.set_id = dsl.set_id
                   and dsh2.set_name = 'DKA_NOTIF_METIER'
                   and dsh2.set_id = dsl2.set_id
                   and dsl.return_value = dsl2.param2_value
                   and dsl2.PARAM1_VALUE = wn.message_name);

        IF vn_fact_OI > 0 Then
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'exists_misc_holds : retourne oui',
                             cn_mode_debug);
            pv_resultout := 'COMPLETE:' || 'Y';
        ELSE
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'exists_misc_holds : retourne faux',
                             cn_mode_debug);
            pv_resultout := 'COMPLETE:' || 'N';
        END IF;

    END exists_misc_holds;

    -------------------------------------------------------------------------------------
    --  Nom           : get_habilitation
    --  Description   : Function vérifiant si l'employé a les droits d'habilitation
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup YES/NO
    -------------------------------------------------------------------------------------
    FUNCTION get_habilitation(pv_itemtype     IN WF_ITEMS.ITEM_TYPE%type,
                              pv_itemkey      IN WF_ITEMS.ITEM_KEY%type,
                              pv_user_name    IN VARCHAR2,
                              pn_montant_fact IN NUMBER) RETURN VARCHAR2 IS
        vn_montant_seuil number;
    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'get_habilitation debut ',
                         cn_mode_debug);

        -- pj.attribute1 ramene le montant max de la fact
        select nvl(to_number(pj.attribute1), 0) as montant_seuil
          into vn_montant_seuil
          from per_all_people_f      pap,
               per_all_assignments_f paf,
               per_jobs              pj,
               fnd_user              fu
         where fu.user_name = pv_user_name
           and fu.employee_id = pap.person_id
           and sysdate between pap.effective_start_date and
               nvl(pap.effective_end_date, sysdate)
           and sysdate between paf.effective_start_date and
               nvl(paf.effective_end_date, sysdate)
           and pj.job_id = paf.job_id
           and paf.person_id = pap.person_id;

        IF vn_montant_seuil >= pn_montant_fact then
            RETURN 'COMPLETE:' || 'Y';
        ELSE
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'get_habilitation l''utilisateur ' ||
                             pv_user_name ||
                             ' ne possede pas les droits d''habilitation pour cette facture ',
                             3);
            RETURN 'COMPLETE:' || 'N';
        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'get_habilitation fin',
                         cn_mode_debug);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'get_habilitation l''utilisateur ' ||
                             pv_user_name ||
                             ' ne possede pas d''affectation a ce jour, ou n''est pas rattaché a un employé',
                             cn_mode_debug);
            RETURN 'COMPLETE:' || 'N';
        WHEN OTHERS THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'get_habilitation erreur : ' || SQLERRM,
                             cn_mode_debug);
            RETURN 'COMPLETE:' || 'N';
    END get_habilitation;

    -------------------------------------------------------------------------------------
    --  Nom           : employe_Droit_habilitation
    --  Description   : Procédure vérifiant si l'employé a les droits d'habilitation
    --                    pour positionner le BAP pour cette facture
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup YES/NO
    -------------------------------------------------------------------------------------
    PROCEDURE employe_droit_habilitation(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                         pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                         pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                         pv_funcmode  IN VARCHAR2,
                                         pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_montant_fact ap_invoices_all.invoice_amount%type;
        vv_user_name    fnd_user.user_name%type;

    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_Droit_habilitation debut',
                         cn_mode_debug);
        vn_montant_fact := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'DKA_INVOICE_AMOUNT');

        vv_user_name := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'VALIDEUR_BAP');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_Droit_habilitation montant = ' ||
                         vn_montant_fact || 'vv_user_name ' ||
                         vv_user_name,
                         cn_mode_debug);

        pv_resultout := get_habilitation(pv_itemtype,
                                         pv_itemtype,
                                         vv_user_name,
                                         vn_montant_fact);



    END employe_droit_habilitation;

    -------------------------------------------------------------------------------------
    --  Nom           : determine_role_associe_facture
    --  Description   : Procédure utilisée pour déterminer les responsabilites CSP
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
        return varchar2 IS
        vv_role_notif varchar2(100);

    BEGIN
        pv_errbuf  := 'pv_region = ' || pv_region || 'pn_org_id = ' ||
                      pn_org_id || 'pv_societe = ' || pv_societe ||
                      'pv_resp_csp = ' || pv_resp_csp;
        pn_retcode := 0;
        BEGIN
            select /*'FND_RESP' || to_char(fr.application_id) || ':' ||
                   to_char(fr.responsibility_id)*/
                   'FND_RESP|'||fa.APPLICATION_SHORT_NAME||'|'||fr.RESPONSIBILITY_KEY||'|'||upper(fdg.DATA_GROUP_NAME) --JJA 2017/04/03
              into vv_role_notif
              from
               fnd_responsibility fr,
               fnd_application fa,
               fnd_data_groups fdg
             where
               sysdate between nvl(fr.start_date, sysdate) and nvl(fr.end_date, sysdate)
               AND fr.application_id = fa.application_id
               AND fdg.DATA_GROUP_ID = fr.DATA_GROUP_ID
               AND exists
            -- recherche les reponsabilités ayant l'option de profil ORG_ID renseigné
            -- avec l'org_id de la facture
             (select pov.level_value, pov.profile_option_value
                      from fnd_profile_options_vl    fpo,
                           fnd_profile_option_values pov,
                           fnd_application           app
                     where pov.level_id = 10003
                       and app.application_id =
                           pov.level_value_application_id
                       and app.application_short_name = 'SQLAP'
                       and pov.profile_option_id = fpo.profile_option_id
                       and fpo.profile_option_name = 'ORG_ID'
                       and fr.responsibility_id = pov.level_value
                       and fr.application_id = app.application_id
                       and pov.profile_option_value = to_char(pn_org_id))
               and exists
            -- recherche les reponsabilités ayant l'option de profil DKA_CSP_RESPONSIBILITY renseigné
            -- avec CSP anomalies ou CSP référetiel  suivant le param pv_resp_csp
             (select pov.level_value, pov.profile_option_value
                      from fnd_profile_options_vl    fpo,
                           fnd_profile_option_values pov,
                           fnd_application           app
                     where pov.level_id = 10003
                       and app.application_id =
                           pov.level_value_application_id
                       and app.application_short_name = 'SQLAP'
                       and pov.profile_option_id = fpo.profile_option_id
                       and fpo.profile_option_name =
                           'DKA_CSP_RESPONSIBILITY'
                       and fr.responsibility_id = pov.level_value
                       and fr.application_id = app.application_id
                       and pov.profile_option_value = pv_resp_csp)
               and rownum = 1;
            return vv_role_notif;
        EXCEPTION
            WHEN NO_DATA_FOUND then
                pv_errbuf  := pv_errbuf ||
                              'Aucune responsabilité trouvée pour la région' ||
                              pv_region || ', org_id =' || pn_org_id ||
                              ', doc_category_code =' || pv_societe ||
                              ', CSP =' || pv_resp_csp;
                pn_retcode := 1;
                return null;
            WHEN OTHERS then
                pv_errbuf  := pv_errbuf || 'ERREUR ' || SQLCODE ||
                              ' dans determine_role_associe_facture pour ' ||
                              pv_region || ', org_id =' || pn_org_id ||
                              ', doc_category_code =' || pv_societe ||
                              ', CSP =' || pv_resp_csp;
                pn_retcode := 1;
                return null;
        END;

    END determine_role_associe_facture;

    -------------------------------------------------------------------------------------
    --  Nom           : initialise_workflow
    --  Description   :
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --
    -------------------------------------------------------------------------------------
    PROCEDURE initialise_workflow(pv_itemtype     IN VARCHAR2,
                                  pv_itemkey      IN WF_ITEMS.ITEM_KEY%type,
                                  pn_org_id       in ap_invoices_all.org_id%type,
                                  pv_region       in varchar2,
                                  pv_code_societe in ap_invoices_all.doc_category_code%type,
                                  pv_errbuf       OUT VARCHAR2,
                                  pn_retcode      IN OUT NUMBER) IS
        vn_appl_id fnd_responsibility.application_id%type;

        -- les responsabilites
        vn_resp_csp_ano_id fnd_responsibility.responsibility_id%type;
        vn_resp_csp_ref_id fnd_responsibility.responsibility_id%type;
        vv_resp_csp_ano    varchar2(100);
        vv_resp_csp_ref    varchar2(100);

        -- les litiges
        vv_litige_BAP             ap_holds_all.hold_lookup_code%type;
        vv_litige_QTE             ap_holds_all.hold_lookup_code%type;
        vv_litige_QTE_ORD         ap_holds_all.hold_lookup_code%type;
        vv_litige_QTE_REC         ap_holds_all.hold_lookup_code%type;
        vv_litige_PRICE           ap_holds_all.hold_lookup_code%type;
        vv_litige_MAX_SHIP_AMOUNT ap_holds_all.hold_lookup_code%type;

        -- les codes déblocages
        vv_code_deblocage_PRICE        ap_holds_all.release_lookup_code%type;
        vv_code_deblocage_QTY_ORD      ap_holds_all.release_lookup_code%type;
        vv_code_deblocage_BAP          ap_holds_all.release_lookup_code%type;
        vv_code_deblocage_max_ship_amt ap_holds_all.release_lookup_code%type;

        -- durée de relance
        vn_duree_avant_timeout_terrain dka_parameters.number_value%type;
        vn_duree_avant_timeout_csp     dka_parameters.number_value%type;

    BEGIN
        begin

            /*
            determine quel CSP ano et ref sont associes a la facture pour recuperer leurs responsabilites
            pour pouvoir envoyer les notifs au format FND_RESP178:21584    FND_RESP||application_id||':'||responsibility_id
              appliquer regle pour trouver les resp en attendant en dur internet procurement
            */

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'Appel a determine_role_associe_facture  pv_region = ' ||
                             pv_region || ',   pn_org_id = ' || pn_org_id ||
                             ',   cv_valeur_op_prof_CSP_ano = ' ||
                             cv_valeur_op_prof_CSP_ano ||
                             ',   pv_code_societe = ' || pv_code_societe,
                             cn_mode_debug);

            vv_resp_csp_ano := determine_role_associe_facture(pv_region,
                                                              pn_org_id,
                                                              pv_code_societe,
                                                              cv_valeur_op_prof_CSP_ano,
                                                              pv_errbuf,
                                                              pn_retcode);
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'Resp CSP Ano = ' || vv_resp_csp_ano,
                             cn_mode_debug);
            IF pn_retcode <> 0 THEN
                print_wf_message(pv_itemtype, pv_itemkey, pv_errbuf, 3);
                return;
            END IF;
            vv_resp_csp_ref := determine_role_associe_facture(pv_region,
                                                              pn_org_id,
                                                              pv_code_societe,
                                                              cv_valeur_op_prof_CSP_ref,
                                                              pv_errbuf,
                                                              pn_retcode);

            IF pn_retcode <> 0 THEN
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 pv_errbuf,
                                 cn_mode_debug);
                return;
            END IF;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'Resp CSP Ref = ' || vv_resp_csp_ref,
                             cn_mode_debug);
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_RESP_CSP_ANO',
                                      avalue   => vv_resp_csp_ano);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_RESP_CSP_REF',
                                      avalue   => vv_resp_csp_ref);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'SOCIETE_FACTURE',
                                      avalue   => substr(pv_code_societe,
                                                         1,
                                                         4));

            SELECT dp.number_value
              into vn_duree_avant_timeout_csp
              FROM dka_parameters dp
             WHERE dp.program_code = 'DKA_SAPWFCSP'
               AND dp.parameter_name = 'NB_JOURS_REL_MOTIF_CSP';

            SELECT dp.number_value
              into vn_duree_avant_timeout_terrain
              FROM dka_parameters dp
             WHERE dp.program_code = 'DKA_SAPWFCSP'
               AND dp.parameter_name = 'NB_JOURS_REL_MOTIF_TERRAIN';

            wf_engine.SetItemAttrNumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'DUREE_AVANT_TIMEOUT_CSP',
                                        avalue   => vn_duree_avant_timeout_csp);

            wf_engine.SetItemAttrNumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'DUREE_AVANT_TIMEOUT_EXP',
                                        avalue   => vn_duree_avant_timeout_terrain);

            -- blocages a creer
            vv_litige_BAP     := 'En litige BAP';
            vv_litige_QTE     := 'En litige Quantité';
            vv_litige_QTE_REC := 'En litige Quantité REC';
            vv_litige_QTE_ORD := 'En litige Quantité CDE';
            vv_litige_PRICE   := 'En litige Prix';
            vv_litige_MAX_SHIP_AMOUNT := 'En litige Prix';

            -- codes déblocages
            vv_code_deblocage_PRICE        := 'MATCH OVERRIDE';
            vv_code_deblocage_BAP          := 'Bon à payer';
            vv_code_deblocage_QTY_ORD      := 'MATCH OVERRIDE';
            vv_code_deblocage_max_ship_amt := 'MATCH OVERRIDE';

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_CODE_DEBLOCAGE_PRICE',
                                      avalue   => vv_code_deblocage_PRICE);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_CODE_DEBLOCAGE_SHIP_AMT',
                                      avalue   => vv_code_deblocage_max_ship_amt);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_CODE_DEBLOCAGE_QTY_ORD',
                                      avalue   => vv_code_deblocage_QTY_ORD);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_CODE_DEBLOCAGE_BAP',
                                      avalue   => vv_code_deblocage_BAP);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_QTY_ORD',
                                      avalue   => cv_ano_qty_ord);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_QTY_REC',
                                      avalue   => cv_ano_qty_rec);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_RIB',
                                      avalue   => cv_ano_rib);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_FACT_3_TAMP',
                                      avalue   => cv_ano_fact_3_tamp);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_DATE_HORS_PER',
                                      avalue   => cv_ano_date_hors_per);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_AFFFACT',
                                      avalue   => cv_ano_affact);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_PRLV_ABS',
                                      avalue   => cv_ano_prlv_abs);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_REGION_ABS',
                                      avalue   => cv_ano_region_abs);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_REGION_INC',
                                      avalue   => cv_ano_region_inc);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_FOURN_ABS',
                                      avalue   => cv_ano_fourn_abs);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_CMD_MULT',
                                      avalue   => cv_ano_cmd_multi);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_CMD_MULT2',
                                      avalue   => cv_ano_cmd_multi2);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_CMD_MULT3',
                                      avalue   => cv_ano_cmd_multi3);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_SOC_DIFF',
                                      avalue   => cv_ano_soc_diff);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_BON_A_PAYER',
                                      avalue   => cv_ano_bon_apayer);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_ECART_PRIX',
                                      avalue   => cv_ano_ecart_prix);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_MAX_SHIP_AMOUNT',
                                      avalue   => cv_ano_motant_livre_maxi);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ANO_IMPUT_ATTENTE',
                                      avalue   => cv_ano_imput_attente);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_LITIGE_BAP',
                                      avalue   => vv_litige_BAP);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_LITIGE_QTE',
                                      avalue   => vv_litige_QTE);


            --Nouvel Attribute pour Simplification de l'axe métier
            BEGIN
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_LITIGE_QTE_ORD',
                                          avalue   => vv_litige_QTE_ORD);

                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_LITIGE_QTE_REC',
                                          avalue   => vv_litige_QTE_REC);
            EXCEPTION
                WHEN OTHERS THEN
                    --l'exception permet de gérer les anciennes versions du WF.
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'Utilisation ancienne version Workflow',
                                     cn_mode_debug);
            END;

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_LITIGE_PRIX',
                                      avalue   => vv_litige_PRICE);

            -- 28022012   BCO EARS00009628327 - récupere la valeur pour le blocage montant livr maxi.
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_LITIGE_MAX_SHIP_AMOUNT',
                                      avalue   => vv_litige_MAX_SHIP_AMOUNT);

            wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'USER_ID',
                                        avalue   => fnd_global.user_id);

            -- les libelles

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_HISTO_ACTIONS',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E020'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_DEMANDE_INFO',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E021'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_MESG_DEMANDE_INFO',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E022'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_HIERAR_DEMANDE_INFO',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E023'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_MESG_HIERAR_DEMANDE_INFO',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E024'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_RETOUR_IMPUT_ATTENT',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E025'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_RETOUR_OI',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E004'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_BAP_AUTRES',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E029'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_ANO_OI',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E001'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_ANO_OI_REF',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E002'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_ANO_DIVERSES',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E003'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_DEMANDE_IMPUT_BAP',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E012'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_LITIGE',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E013'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_ANO_QTY_REC',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E014'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_FACT_NUM',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E015'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_CSP_ECART_PRIX',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E041'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_ACH_ECART_PRIX',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E039'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_DDEUR_ECART_PRIX',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E040'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NC_ECART_PRIX',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E070'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_INTIATEUR_DA_NC_PRIX',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E071'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_DDEUR_QTY_REC',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E043'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_DDEUR_QTY_ORD',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E044'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_CSP_ANO_AFFACTURAGE',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E063'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_CSP_REF_AFFACTURAGE',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E062'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_CSP_ANO_CMD_MULT',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E059'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_CSP_REF_RIB',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E061'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_CSP_ANO_PRLV',
                                      avalue   => dka_tools_pkg.get_message('DKA',
                                                                            'DKA_SAPWFCSP_E064'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_QTY_REC',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E045'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_CSP_QTY_REC',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E046'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_CHEF_EXPLOIT_QTY_REC',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E047'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_CSP_QTY_ORD',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E048'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_QTY_ORD',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E049'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_CMD_MULT',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E060'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_EXPL_IMP_ATT',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E072'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_HIERA_ATT_BAP',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E073'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_CSP_RET_IMPUT',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E074'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_DDR_QTY_REC',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E075'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_CSP_QTY_REC',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E076'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_EXPL_QTY_REC',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E077'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_CSP_QTY_ORD',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E078'));

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'LIB_TITRE_NOTIF_DDR_QTY_ORD',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E079'));

            if wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                         itemkey  => pv_itemkey,
                                         aname    => 'COMMANDE_NUM') is not null then
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'TXT_ABC_OU_SBC',
                                          avalue   => 'ABC');
            else
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'TXT_ABC_OU_SBC',
                                          avalue   => 'SBC');
            end if;

        EXCEPTION
            WHEN OTHERS THEN
                pn_retcode := 1;
                pv_errbuf  := SQLERRM;
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 pv_errbuf,
                                 cn_mode_debug);
        END;
    END initialise_workflow;

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
                                  pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id ap_invoices_interface.invoice_id%TYPE;
    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'termine_workflow_OI debut',
                         cn_mode_debug);
        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_OI_ID');

        -- RAZ des global_attribute pour rejouer le wrokflow
        -- au cas ou la correction soit insufissante et que le 2° OI rejette
        update ap_invoices_interface
           set GLOBAL_ATTRIBUTE2 = null, GLOBAL_ATTRIBUTE3 = null
         where invoice_id = vn_invoice_id;

        pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    exception
        when others then
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'termine_workflow_OI exception' || SQLERRM,
                             3);
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END termine_workflow_OI;

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
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id     ap_invoices_interface.invoice_id%type;
        vn_org_id         ap_invoices_interface.org_id%type;
        vv_division       hr_all_organization_units.attribute10%type;
        vv_region         varchar2(3);
        vv_errbuf         varchar2(1000);
        vn_retcode        number;
        vv_blocagesXerox  ap_invoices_interface.attribute1%type;
        vv_url_facture    varchar2(1000);
        vv_code_societe   ap_invoices_interface.doc_category_code%type;
        vn_invoice_amount ap_invoices_all.invoice_amount%type;
        vd_invoice_date   ap_invoices_all.invoice_date%type;
        vv_num_vendeur    ap_invoices_interface.vendor_num%type;
        vv_num_facture    ap_invoices_interface.invoice_num%type;
        vv_invoice_type   ap_invoices_interface.invoice_type_lookup_code%type;
        vv_pay_group      ap_invoices_interface.pay_group_lookup_code%type;
        vv_desc           ap_invoices_interface.description%type;
        vv_nom_fourn      AP_SUPPLIERS.vendor_name%type;
        vv_num_command    po_headers.segment1%type;
        vv_code_sitefourn AP_SUPPLIER_sites.vendor_site_code%type;
        vv_vendor_id      ap_invoices_interface.vendor_id%type;
    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'initialise_workflow_OI debut',
                         cn_mode_debug);
        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_OI_ID');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'initialise_workflow_OI vn_invoice_id' ||
                         vn_invoice_id,
                         cn_mode_debug);
        begin

            /*
            1) determine quel CSP ano et ref sont associes a la facture pour recuperer leurs responsabilites
            pour pouvoir envoyer les notifs au format FND_RESP178:21584    FND_RESP||application_id||':'||responsibility_id
            */
            -- factures avec site vendeur renseigné => on passe par le site pour trouver la region
            select ai.org_id,
                   hou.attribute10,
                   substr(hou.name, 1, 3),
                   ai.attribute1,
                   substr(hou.name, 4, 4),--doc_category_code,
                   ai.invoice_num,
                   ai.vendor_num,
                   ai.invoice_type_lookup_code,
                   ai.pay_group_lookup_code, --classe de reglements
                   ai.description,
                   ai.vendor_name,
                   ai.vendor_site_code,
                   ai.invoice_date,
                   ai.invoice_amount,
                   ai.vendor_id
              into vn_org_id,
                   vv_division,
                   vv_region,
                   vv_blocagesXerox,
                   vv_code_societe,
                   vv_num_facture,
                   vv_num_vendeur,
                   vv_invoice_type,
                   vv_pay_group,
                   vv_desc,
                   vv_nom_fourn,
                   vv_code_sitefourn,
                   vd_invoice_date,
                   vn_invoice_amount,
                   vv_vendor_id
              from hr_all_organization_units hou,
                   ap_invoices_interface     ai
             where hou.organization_id = ai.org_id
               and invoice_id = vn_invoice_id;

            --Détermination du numéro de commande
            BEGIN
                SELECT DISTINCT po_number
                  INTO vv_num_command
                  FROM ap_invoice_lines_interface ail
                 WHERE invoice_id = vn_invoice_id
                   AND ail.line_type_lookup_code != 'TAX';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'initialise_workflow_OI PO_NUMBER vide' ||
                                     vn_invoice_id,
                                     cn_mode_debug);
                    vv_num_command := NULL;
                WHEN OTHERS THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'initialise_workflow_OI erreur commandes multiples' ||
                                     vn_invoice_id,
                                     cn_mode_debug);
                    vv_num_command := 'Commandes multiples';
            END;

            IF vv_vendor_id is not null and
               (vv_nom_fourn is null or vv_num_vendeur is null) then
                BEGIN
                    select segment1, vendor_name
                      into vv_num_vendeur, vv_nom_fourn
                      from ap_suppliers
                     where vendor_id = vv_vendor_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        print_wf_message(pv_itemtype,
                                         pv_itemkey,
                                         'initialise_workflow_OI fournisseur d''ID =' ||
                                         vv_vendor_id || ' introuvable ',
                                         3);
                        pv_resultout := wf_engine.eng_completed || ':' ||
                                        'FAIL';
                        return;
                    WHEN OTHERS THEN
                        print_wf_message(pv_itemtype,
                                         pv_itemkey,
                                         'initialise_workflow_OI fournisseur d''ID =' ||
                                         vv_vendor_id || ' Exception' ||
                                         SQLERRM,
                                         3);
                        pv_resultout := wf_engine.eng_completed || ':' ||
                                        'FAIL';
                        return;
                END;
            END If;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'initialise_workflow_OI vn_org_id' ||
                             vn_org_id || 'vv_division' || vv_division ||
                             'vv_region' || vv_region ||
                             'vv_blocagesXerox ' || vv_blocagesXerox ||
                             'vv_code_societe ' || vv_code_societe,
                             cn_mode_debug);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DESCRIPT',
                                      avalue   => vv_desc);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'PAY_GROUP',
                                      avalue   => vv_pay_group);

            wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'DKA_ORG_ID',
                                        avalue   => vn_org_id);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'BLOCAGES_XEROX',
                                      avalue   => vv_blocagesXerox);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'INVOICE_OI_NUM',
                                      avalue   => vv_num_facture);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VENDOR_SEGMENT1',
                                      avalue   => vv_num_vendeur);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VENDOR_SITE_CODE',
                                      avalue   => vv_code_sitefourn);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'COMMANDE_NUM',
                                      avalue   => vv_num_command);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VENDOR_NAME',
                                      avalue   => vv_nom_fourn);

            wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'DKA_INVOICE_AMOUNT',
                                        avalue   => vn_invoice_amount);

            wf_engine.SetItemAttrDate(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_INVOICE_DATE',
                                      avalue   => vd_invoice_date);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'INVOICE_TYPE',
                                      avalue   => vv_invoice_type);

            begin
                vv_url_facture := DKA_SAPGETIMG_WF_PKG.get_url_image_facture(vn_invoice_id,
                                                                              'OI');
            EXCEPTION
                WHEN OTHERS THEN
                    vv_url_facture := null;
            END;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'initialise_workflow_OI vv_url_facture' ||
                             vv_url_facture,
                             cn_mode_debug);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_INVOICE_URL',
                                      avalue   => vv_url_facture);

            initialise_workflow(pv_itemtype,
                                pv_itemkey,
                                vn_org_id,
                                vv_region,
                                vv_code_societe,
                                vv_errbuf,
                                vn_retcode);
            IF vn_retcode <> 0 THEN
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
            ELSE
                -- mise a jour des global_attribute comme indique en 2.4.3.3
                -- pour ne pas que 2 traitements lancent 2 workflows pour la meme facture
                update ap_invoices_interface
                   set GLOBAL_ATTRIBUTE2 = pv_itemtype,
                       GLOBAL_ATTRIBUTE3 = pv_itemkey
                 where invoice_id = vn_invoice_id;

                pv_resultout := wf_engine.eng_completed || ':' ||
                                'SUCCESS';
            END IF;
        exception
            when NO_DATA_FOUND then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'Facture d''ID =  ' || vn_invoice_id ||
                                 ' non trouvée dans Open Interface',
                                 3);
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
            when others then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'Facture d''ID =  ' || vn_invoice_id ||
                                 ' Exception ' || SQLERRM,
                                 3);
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        end;
    END initialise_workflow_OI;

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
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id     ap_invoices_all.invoice_id%type;
        vn_org_id         ap_invoices_all.org_id%type;
        vv_division       hr_all_organization_units.attribute10%type;
        vv_region         varchar2(3);
        vv_invoice_num    ap_invoices_all.invoice_num%type;
        vn_invoice_amount ap_invoices_all.invoice_amount%type;
        vd_invoice_date   ap_invoices_all.invoice_date%type;
        vv_vendeur        ap_suppliers.vendor_name%type;
        vv_codes_blocages varchar2(2000);
        vv_lib_blocages   varchar2(2000);
        vv_errbuf         varchar2(1000);
        vn_retcode        number;
        vv_blocagesXerox  ap_invoices_interface.attribute1%type;
        vv_url_facture    varchar2(1000);
        vv_url_commande   varchar2(1000);
        vv_code_societe   ap_invoices_interface.doc_category_code%type;
        vv_num_vendeur    ap_suppliers.segment1%type;
        vv_invoice_type   ap_invoices_interface.invoice_type_lookup_code%type;
        vv_pay_group      ap_invoices_interface.pay_group_lookup_code%type;
        vv_desc           ap_invoices_interface.description%type;
        vv_num_command    po_headers.segment1%type;
        vv_code_sitefourn ap_supplier_sites.vendor_site_code%type;
        vn_po_header_id   po_headers_all.po_header_id%TYPE;
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'initialise_workflow_AP',
                         cn_mode_debug);
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         ' facture ID = ' || vn_invoice_id,
                         cn_mode_debug);
        BEGIN

            SELECT ai.org_id,
                   hou.attribute10,
                   substr(hou.name, 1, 3),
                   ai.invoice_num,
                   ai.invoice_amount,
                   ai.invoice_date,
                   pv.vendor_name,
                   ai.attribute1,
                   substr(hou.name, 4, 4),--doc_category_code,
                   pv.segment1,
                   ai.invoice_type_lookup_code,
                   ai.pay_group_lookup_code, --classe de reglements
                   ai.description,
                   pvs.vendor_site_code
              INTO vn_org_id,
                   vv_division,
                   vv_region,
                   vv_invoice_num,
                   vn_invoice_amount,
                   vd_invoice_date,
                   vv_vendeur,
                   vv_blocagesXerox,
                   vv_code_societe,
                   vv_num_vendeur,
                   vv_invoice_type,
                   vv_pay_group,
                   vv_desc,
                   vv_code_sitefourn
              FROM hr_all_organization_units hou,
                   AP_INVOICES_all           ai,
                   ap_supplier_sites_all       pvs,
                   ap_suppliers                pv
             WHERE hou.organization_id = ai.org_id
               AND ai.vendor_site_id = pvs.vendor_site_id
               AND ai.org_id = pvs.org_id
               AND pv.vendor_id = ai.vendor_id
               AND ai.invoice_id = vn_invoice_id;

            BEGIN
                SELECT DISTINCT pha.segment1, -- num commande
                                pha.po_header_id -- num commande
                  INTO vv_num_command, vn_po_header_id
                  FROM ap_invoice_distributions_all aida,
                       po_distributions_all         pda,
                       po_headers_all               pha
                 WHERE aida.po_distribution_id = pda.po_distribution_id
                   AND aida.invoice_id = vn_invoice_id
                   AND pda.po_header_id = pha.po_header_id
                   AND aida.line_type_lookup_code not in ('NONREC_TAX','REC_TAX') --!= 'TAX' -- OBE artf2435790
           ;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'initialise_workflow_AP PO_NUMBER vide' ||
                                     vn_invoice_id,
                                     cn_mode_debug);
                    vv_num_command  := NULL;
                    vn_po_header_id := NULL;
                WHEN OTHERS THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'initialise_workflow_AP erreur commandes multiples' ||
                                     vn_invoice_id,
                                     cn_mode_debug);
                    vv_num_command  := 'Commandes multiples';
                    vn_po_header_id := NULL;
            END;

            wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'DKA_ORG_ID',
                                        avalue   => vn_org_id);

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             ' vn_org_id= ' || vn_org_id,
                             cn_mode_debug);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DESCRIPT',
                                      avalue   => vv_desc);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'PAY_GROUP',
                                      avalue   => vv_pay_group);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'INVOICE_TYPE',
                                      avalue   => vv_invoice_type);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'INVOICE_NUM',
                                      avalue   => vv_invoice_num);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VENDOR_SEGMENT1',
                                      avalue   => vv_num_vendeur);

            wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'DKA_INVOICE_AMOUNT',
                                        avalue   => vn_invoice_amount);

            wf_engine.SetItemAttrDate(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_INVOICE_DATE',
                                      avalue   => vd_invoice_date);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'BLOCAGES_XEROX',
                                      avalue   => vv_blocagesXerox);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VENDOR_SITE_CODE',
                                      avalue   => vv_code_sitefourn);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'COMMANDE_NUM',
                                      avalue   => vv_num_command);

            wf_engine.SetItemAttrNumber(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'COMMANDE_ID',
                                        avalue   => vn_po_header_id);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VENDOR_NAME',
                                      avalue   => vv_vendeur);

            --URL FACTURE
            begin
                vv_url_facture := DKA_SAPGETIMG_WF_PKG.get_url_image_facture(vn_invoice_id,
                                                                              'AP');
            EXCEPTION
                WHEN OTHERS THEN
                    vv_url_facture := null;
            END;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'vv_url_facture ' || vv_url_facture,
                             cn_mode_debug);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_INVOICE_URL',
                                      avalue   => vv_url_facture);
            --URL COMMANDE
            begin
                vv_url_commande := DKA_SAPGETIMG_WF_PKG.GET_URL_IMAGE_BDC(vn_po_header_id);
            EXCEPTION
                WHEN OTHERS THEN
                    vv_url_commande := null;
            END;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'vv_url_commande ' || vv_url_commande,
                             cn_mode_debug);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_PURCHASE_ORDER_URL',
                                      avalue   => vv_url_commande);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DOC_HISTO',
                                      avalue   => 'PLSQL:DKA_SAPWFCSP_pkg.GET_ACTION_HISTORY/' ||
                                                  pv_itemtype || ':' ||
                                                  pv_itemkey);

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DOC_BLOCAGES',
                                      avalue   => 'PLSQL:DKA_SAPWFCSP_pkg.get_infos_AP/' ||
                                                  pv_itemtype || ':' ||
                                                  pv_itemkey || ':' || '&' ||
                                                  '#NID');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DOC_ECART_PRIX',
                                      avalue   => 'PLSQL:DKA_SAPWFCSP_pkg.get_ecart_prix/' ||
                                                  pv_itemtype || ':' ||
                                                  pv_itemkey);

            initialise_workflow(pv_itemtype,
                                pv_itemkey,
                                vn_org_id,
                                vv_region,
                                vv_code_societe,
                                vv_errbuf,
                                vn_retcode);

            IF vn_retcode <> 0 THEN
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
            ELSE
                -- mise a jour des attribute comme indique en 2.4.3.3
                -- pour ne pas que 2 traitements lancent 2 workflows pour la meme facture
                --        update ap_holds_all
                --           set ATTRIBUTE1 = pv_itemtype,
                --               ATTRIBUTE2 = pv_itemkey
                --         where invoice_id = vn_invoice_id;
                pv_resultout := wf_engine.eng_completed || ':' ||
                                'SUCCESS';
            END IF;
        exception
            when NO_DATA_FOUND then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'initialise_workflow_AP  NO DATA FOUND  ',
                                 cn_mode_debug);
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
            when TOO_MANY_ROWS then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'initialise_workflow_AP  INVOICE_ID : ' ||
                                 vn_invoice_id ||
                                 ' doit etre attachée a plusieurs commandes ',
                                 cn_mode_debug);
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        end;
    END initialise_workflow_AP;

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
                                 pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_texte_relance              VARCHAR2(2000);
        vn_num_relance                number;
        vv_nom_item_wf_stockage_motif varchar2(40);
    BEGIN
        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'incremente_relance  debut ',
                         cn_mode_debug);
        vv_nom_item_wf_stockage_motif := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                                       itemtype => pv_itemtype,
                                                                       itemkey  => pv_itemkey,
                                                                       aname    => 'TEXTE_RELANCE');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'incremente_relance  vv_nom_item_wf_stockage_motif =  ' ||
                         vv_nom_item_wf_stockage_motif,
                         cn_mode_debug);

        pv_resultout     := wf_engine.eng_completed || ':' || 'SUCCESS';
        vv_texte_relance := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => vv_nom_item_wf_stockage_motif);
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'incremente_relance  vv_texte_relance =  ' ||
                         vv_texte_relance,
                         cn_mode_debug);

        IF vv_texte_relance is null then
            vv_texte_relance := 'RELANCE N°01'; --- modif a faire NE PAS OUBLIER
        ELSE
            --        vv_texte_relance := 'RELANCE N°' || to_char(to_number(substr(vv_texte_relance ,-1)) +1); --24092008
            vv_texte_relance := 'RELANCE N°' || substr(to_char(to_number(substr(vv_texte_relance,
                                                                                -2) + 1),
                                                               '000'),
                                                       -2); -- 2 positions

        END IF;
        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => vv_nom_item_wf_stockage_motif,
                                  avalue   => vv_texte_relance);
    END incremente_relance;

    ------------------------------------------------------------------------------------
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
                         pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_nom_item_wf_stockage_motif varchar2(40);
    BEGIN
        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'en_attente  debut ',
                         cn_mode_debug);
        vv_nom_item_wf_stockage_motif := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                                       itemtype => pv_itemtype,
                                                                       itemkey  => pv_itemkey,
                                                                       aname    => 'TXT_ENATTENTE');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'en_attente  vv_nom_item_wf_stockage_motif =  ' ||
                         vv_nom_item_wf_stockage_motif,
                         cn_mode_debug);

        pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => vv_nom_item_wf_stockage_motif,
                                  avalue   => 'EN ATTENTE - ');
    END en_attente;

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
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_exists_BR  number;
        vn_invoice_id ap_invoices_all.invoice_id%type;
    BEGIN
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        select count(rsh.shipment_header_id)
          into vn_exists_BR
          from ap_invoices_all              aia,
               ap_invoice_distributions_all aida,
               po_distributions_all         pda,
               rcv_shipment_headers         rsh,
               rcv_shipment_lines           rsl
         where aida.invoice_id = aia.invoice_id
           and aida.po_distribution_id = pda.po_distribution_id
           and rsh.shipment_header_id = rsl.shipment_header_id
           and rsl.PO_HEADER_ID = pda.po_header_id
           and aia.invoice_id = vn_invoice_id
           and rownum < 2;

        --     vn_exists_BR  :=1;

        IF vn_exists_BR = 1 THEN
            pv_resultout := 'COMPLETE:' || 'Y';
        ELSE
            pv_resultout := 'COMPLETE:' || 'N';

        END IF;
    END exists_BR_ligne_Cmd;

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
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_acheteur   fnd_user.user_name%type;
        vn_invoice_id ap_invoices_all.invoice_id%type;
        vv_agent_id   po_headers_all.agent_id%type; ---11082011 JB
        vv_created_by po_headers_all.created_by%type; ---11082011 JB

    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'acheteur_commande  debut',
                         cn_mode_debug);

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'acheteur_commande  vn_invoice_id = ' ||
                         vn_invoice_id,
                         cn_mode_debug);

        -- on va chercher celui qui a cree la 1° DA d'ou est issue la commande
        BEGIN
            select fu.user_name
              into vv_acheteur
              from ap_invoice_distributions_all aida,
                   po_distributions_all         pda,
                   po_headers_all               pha,
                   po_req_distributions_all     prd,
                   po_requisition_lines_all     prl,
                   po_requisition_headers_all   prh,
                   fnd_user                     fu
             where aida.invoice_id = vn_invoice_id
               and aida.po_distribution_id = pda.po_distribution_id
               and pda.po_header_id = pha.po_header_id
               and prd.distribution_id = pda.req_distribution_id
               and prl.requisition_line_id = prd.requisition_line_id
               and prh.requisition_header_id = prl.requisition_header_id
               and prh.preparer_id = fu.employee_id
               and rownum < 2;

        EXCEPTION
            WHEN NO_DATA_FOUND then
                -- non trouve parce que pas de DA mais seulement une commande
                select DISTINCT pha.AGENT_ID, pha.created_by
                  into vv_agent_id, vv_created_by
                  from ap_invoice_distributions_all aida,
                       po_distributions_all         pda,
                       po_headers_all               pha,
                       fnd_user                     fu
                 where aida.invoice_id = vn_invoice_id
                   and aida.po_distribution_id = pda.po_distribution_id
                   and pda.po_header_id = pha.po_header_id
                   and rownum < 2;

                IF vv_agent_id is not null then


                    select fu.user_name
                      into vv_acheteur
                      from fnd_user fu
                     where fu.employee_id = vv_agent_id
                       and rownum < 2;

                ELSE

                    select fu.user_name
                      into vv_acheteur
                      from fnd_user fu
                     where fu.user_id = vv_created_by;

                END IF;

        END;

        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DKA_ACHETEUR_COMMANDE',
                                  avalue   => vv_acheteur);

        -- on positionne l'acheteur comme N°1 de la hierarchie pour envoyer la notif a ce gars la
        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE',
                                  avalue   => vv_acheteur);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'acheteur_commande  vv_acheteur = ' ||
                         vv_acheteur,
                         cn_mode_debug);

        pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'acheteur_commande  fin ',
                         cn_mode_debug);

    EXCEPTION
        WHEN OTHERS THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'acheteur_commande  erreur : ' || SQLERRM,
                             cn_mode_debug);

            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END acheteur_commande;

    -------------------------------------------------------------------------------------
    --  Nom           : pose_blocage_litige
    --  Description   : Procédure creant un blocage en litige avec motif
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup YES/NO
    -------------------------------------------------------------------------------------
    PROCEDURE pose_blocage_litige(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                  pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                  pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                  pv_funcmode  IN VARCHAR2,
                                  pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id                 ap_invoices_all.invoice_id%type;
        vv_nom_item_wf_stockage_motif varchar2(40);
        vv_motif_blocage              ap_holds_all.hold_reason%type;
        vn_user_id                    fnd_user.user_id%type;
        vn_retcode                    number;
        vv_errbuf                     varchar2(100);
        vv_code_blocage               ap_lookup_codes.lookup_code%type;
        vv_user_name                  fnd_user.user_name%type;
        vv_litiage_count              number := 0;
        TYPE t_line_loc_id IS TABLE OF ap_holds_all.line_location_id%TYPE;
        va_line_loc_id    t_line_loc_id;
        vv_litige_QTE_REC varchar2(50);
        vv_litige_QTE_ORD varchar2(50);
        vv_litige_PRICE   varchar2(50);

        -- 28022012   BCO EARS00009628327 - récupere la valeur pour le blocage montant livr maxi.
        vv_litige_MAX_SHIP_AMOUNT varchar2(50);
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'pose_blocage_litige debut',
                         cn_mode_debug);
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'pose_blocage_litige  vn_invoice_id= ' ||
                         vn_invoice_id,
                         cn_mode_debug);

        vv_code_blocage := nvl(wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                             itemtype => pv_itemtype,
                                                             itemkey  => pv_itemkey,
                                                             aname    => 'DKA_TYPE_BLOCAGE'),
                               'En litige');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'pose_blocage_litige  vv_code_blocage= ' ||
                         vv_code_blocage,
                         cn_mode_debug);

        vv_user_name := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                      itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'BLOQUEUR');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'pose_blocage_litige  vv_user_name= ' ||
                         vv_user_name,
                         cn_mode_debug);

        IF vv_user_name is not null then
            SELECT u.user_id
              INTO vn_user_id
              FROM fnd_user u
             WHERE u.user_name = vv_user_name;
        ELSE
            vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'USER_ID');
        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'pose_blocage_litige  vn_user_id= ' || vn_user_id,
                         cn_mode_debug);

        vv_nom_item_wf_stockage_motif := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                                       itemtype => pv_itemtype,
                                                                       itemkey  => pv_itemkey,
                                                                       aname    => 'DKA_G_W_ITEMATTR_STOCK');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'pose_blocage_litige  vv_nom_item_wf_stockage_motif= ' ||
                         vv_nom_item_wf_stockage_motif,
                         cn_mode_debug);

        vv_motif_blocage := substr(wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                             itemkey  => pv_itemkey,
                                                             aname    => vv_nom_item_wf_stockage_motif),
                                   1,
                                   240);

        vv_litige_QTE_REC := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'DKA_LITIGE_QTE_REC');

        vv_litige_QTE_ORD := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'DKA_LITIGE_QTE_ORD');

        vv_litige_PRICE := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_LITIGE_PRIX');

        -- 28022012   BCO EARS00009628327 - récupere la valeur pour le blocage montant livr maxi.
        -- 26092013  BCO  AJOUT GESTION DES EXCEPTIONS
        BEGIN
            vv_litige_MAX_SHIP_AMOUNT := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                                   itemkey  => pv_itemkey,
                                                                   aname    => 'DKA_LITIGE_MAX_SHIP_AMOUNT');
        EXCEPTION
            WHEN OTHERS THEN
                vv_litige_MAX_SHIP_AMOUNT := 'En litige Prix';
        END;

        IF vv_code_blocage in (vv_litige_QTE_REC, vv_litige_QTE_ORD,
            vv_litige_PRICE, vv_litige_MAX_SHIP_AMOUNT) then

            select line_location_id bulk collect
              into va_line_loc_id
              from ap_holds_all
             where invoice_id = vn_invoice_id
               and release_lookup_code is null
               and (hold_lookup_code = decode(vv_code_blocage,
                                              vv_litige_QTE_ORD,
                                              cv_ano_qty_ord,
                                              vv_litige_QTE_REC,
                                              cv_ano_qty_rec,
                                              vv_litige_PRICE,
                                              cv_ano_ecart_prix --,
                                              -- vv_litige_MAX_SHIP_AMOUNT,
                                              --cv_ano_motant_livre_maxi
                                              )
                   /* below added by javed on 11-APR to get the condition
                                                hold_lookup_code='PRICE' or hold_lookup_code='MAX SHIP AMOUNT'*/
                   or hold_lookup_code =
                   decode(vv_code_blocage,
                              vv_litige_MAX_SHIP_AMOUNT,
                              cv_ano_motant_livre_maxi));

            IF va_line_loc_id.COUNT != 0 THEN

                FOR i IN va_line_loc_id.FIRST .. va_line_loc_id.LAST LOOP

                    select count(1)
                      into vv_litiage_count
                      from ap_holds_all
                     where invoice_id = vn_invoice_id
                       and hold_lookup_code = vv_code_blocage
                       and line_location_id = va_line_loc_id(i);

                    IF vv_litiage_count = 0 then
                        print_wf_message(pv_itemtype,
                                         pv_itemkey,
                                         'pose_blocage_litige line_location_id=' ||
                                         va_line_loc_id(i) ||
                                         ' vv_motif_blocage= ' ||
                                         vv_motif_blocage,
                                         cn_mode_debug);

                        cree_blocage_AP('AP',
                                        vn_invoice_id,
                                        vv_code_blocage,
                                        vv_motif_blocage,
                                        va_line_loc_id(i),
                                        vn_user_id,
                                        pv_itemtype,
                                        pv_itemkey,
                                        vv_errbuf,
                                        vn_retcode);

                        IF vn_retcode <> 0 THEN
                            pv_resultout := wf_engine.eng_completed || ':' ||
                                            'FAIL';
                        END IF;
                    END IF;
                END LOOP;

            END IF;

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

        ELSE

            select count(1)
              into vv_litiage_count
              from ap_holds_all
             where invoice_id = vn_invoice_id
               and hold_lookup_code = vv_code_blocage
               and release_lookup_code is null;

            IF vv_litiage_count = 0 or
               vv_code_blocage not like 'En litige%' then
                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'pose_blocage_litige  vv_motif_blocage= ' ||
                                 vv_motif_blocage,
                                 cn_mode_debug);

                cree_blocage_AP('AP',
                                vn_invoice_id,
                                vv_code_blocage,
                                vv_motif_blocage,
                                NULL, --- 07022011   MT
                                vn_user_id,
                                pv_itemtype,
                                pv_itemkey,
                                vv_errbuf,
                                vn_retcode);

                IF vn_retcode = 0 THEN
                    pv_resultout := wf_engine.eng_completed || ':' ||
                                    'SUCCESS';
                ELSE
                    pv_resultout := wf_engine.eng_completed || ':' ||
                                    'FAIL';
                END IF;
            ELSE
                pv_resultout := wf_engine.eng_completed || ':' ||
                                'SUCCESS';
            END IF;
        END IF;
    END pose_blocage_litige;

    -------------------------------------------------------------------------------------
    --  Nom           : debloque
    --  Description   : Procédure enlevant un type de blocage
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup Sucess/fail
    -------------------------------------------------------------------------------------
    PROCEDURE debloque(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                       pv_funcmode  IN VARCHAR2,
                       pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id                 ap_invoices_all.invoice_id%type;
        vv_nom_item_wf_stockage_motif varchar2(40);
        vv_blocage                    ap_lookup_codes.lookup_code%type;
        vn_user_id                    fnd_user.user_id%type;
        vv_user_name                  fnd_user.user_name%type;
        vn_retcode                    number;
        vv_errbuf                     varchar2(100);
        vv_code_deblocage             varchar2(100);
        vv_release_reason             varchar2(100);

    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  debut ',
                         cn_mode_debug);
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        vv_blocage := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                    itemtype => pv_itemtype,
                                                    itemkey  => pv_itemkey,
                                                    aname    => 'DKA_CODE_BLOCAGE');

        vv_code_deblocage := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                           itemtype => pv_itemtype,
                                                           itemkey  => pv_itemkey,
                                                           aname    => 'DKA_CODE_DEBLOCAGE');

        vv_user_name := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                      itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'PERSONNE_DEBLOQUEUR');

        --Nouvel NodeAttribute pour Simplification de l'axe métier
        BEGIN
            vv_release_reason := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                               itemtype => pv_itemtype,
                                                               itemkey  => pv_itemkey,
                                                               aname    => 'DKA_RELEASE_REASON');
        EXCEPTION
            WHEN OTHERS THEN
                --l'exception permet de gérer les anciennes versions du WF.
                vv_release_reason := null;
        END;

        IF vv_user_name is not null then
            SELECT u.user_id
              INTO vn_user_id
              FROM fnd_user u
             WHERE u.user_name = vv_user_name;
        ELSE
            vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'USER_ID');
        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  vn_user_id= ' || vn_user_id,
                         cn_mode_debug);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  vv_blocage =  ' || vv_blocage ||
                         '  vv_code_deblocage =  ' || vv_code_deblocage ||
                         '  vn_user_id =  ' || vn_user_id,
                         cn_mode_debug);

        leve_blocage(vn_invoice_id,
                     vv_blocage,
                     vv_code_deblocage,
                     vn_user_id,
                     vv_errbuf,
                     vn_retcode,
                     1,
                     pv_itemtype,
                     pv_itemkey,
                     vv_release_reason);

        IF vn_retcode = 0 THEN
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
        ELSE
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  fin ',
                         cn_mode_debug);
    END debloque;

    -------------------------------------------------------------------------------------
    --  Nom           : debloque_aff
    --  Description   : Procédure enlevant un type de blocage
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup Sucess/fail
    -------------------------------------------------------------------------------------
    PROCEDURE debloque_aff(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                       pv_funcmode  IN VARCHAR2,
                       pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id                 ap_invoices_all.invoice_id%type;
        vv_nom_item_wf_stockage_motif varchar2(40);
        vv_blocage                    ap_lookup_codes.lookup_code%type;
        vn_user_id                    fnd_user.user_id%type;
        vv_user_name                  fnd_user.user_name%type;
        vn_retcode                    number;
        vv_errbuf                     varchar2(100);
        vv_code_deblocage             varchar2(100);
        vv_release_reason             varchar2(100);

    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  debut ',
                         cn_mode_debug);
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        vv_blocage := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                    itemtype => pv_itemtype,
                                                    itemkey  => pv_itemkey,
                                                    aname    => 'DKA_CODE_BLOCAGE');

        vv_code_deblocage := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                           itemtype => pv_itemtype,
                                                           itemkey  => pv_itemkey,
                                                           aname    => 'DKA_CODE_DEBLOCAGE');

        vv_user_name := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                      itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'PERSONNE_DEBLOQUEUR');

        --Nouvel NodeAttribute pour Simplification de l'axe métier
        BEGIN
            vv_release_reason := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                               itemtype => pv_itemtype,
                                                               itemkey  => pv_itemkey,
                                                               aname    => 'DKA_RELEASE_REASON');
        EXCEPTION
            WHEN OTHERS THEN
                --l'exception permet de gérer les anciennes versions du WF.
                vv_release_reason := null;
        END;

        IF vv_user_name is not null then
            SELECT u.user_id
              INTO vn_user_id
              FROM fnd_user u
             WHERE u.user_name = vv_user_name;
        ELSE
            vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'USER_ID');
        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  vn_user_id= ' || vn_user_id,
                         cn_mode_debug);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  vv_blocage =  ' || vv_blocage ||
                         '  vv_code_deblocage =  ' || vv_code_deblocage ||
                         '  vn_user_id =  ' || vn_user_id,
                         cn_mode_debug);

        leve_blocage_aff(vn_invoice_id,
                     vv_blocage,
                     vv_code_deblocage,
                     vn_user_id,
                     vv_errbuf,
                     vn_retcode,
                     1,
                     pv_itemtype,
                     pv_itemkey,
                     vv_release_reason);

        IF vn_retcode = 0 THEN
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
        ELSE
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'debloque  fin ',
                         cn_mode_debug);
    END debloque_aff;

    -------------------------------------------------------------------------------------
    --  Nom           : get_superieur_hierachique
    --  Description   : Fonction amenant le supérieur de l'employé.
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --
    -------------------------------------------------------------------------------------
    FUNCTION get_superieur_hierachique(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                       pv_user_name IN FND_USER.USER_NAME%type)
        RETURN VARCHAR2 IS
        vv_superieur FND_USER.USER_NAME%type;

    BEGIN
        --Determine le superieur et le reinjecter dans le workflow
        SELECT fu_superieur.user_name
          INTO vv_superieur
          from per_all_people_f      pap,
               per_all_assignments_f paf,
               per_all_people_f      superieur,
               fnd_user              fu,
               fnd_user              fu_superieur
         where fu.user_name = pv_user_name
           and fu.employee_id = pap.person_id
           and sysdate between pap.effective_start_date and
               nvl(pap.effective_end_date, sysdate)
           and sysdate between paf.effective_start_date and
               nvl(paf.effective_end_date, sysdate)
           and paf.person_id = pap.person_id
           and superieur.person_id = paf.ass_attribute3
           and sysdate between superieur.effective_start_date and
               nvl(superieur.effective_end_date, sysdate)
           and fu_superieur.employee_id = superieur.person_id
           and rownum = 1; -- un employe peut etre rattache a plusieurs utilisateurs, on prend le premier utilisateur rattache a l'employe superieur

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_de_employe, superieur de ' ||
                         pv_user_name || ' trouve pour  ' || vv_superieur,
                         cn_mode_debug);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_de_employe fin ',
                         cn_mode_debug);

        RETURN vv_superieur;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'superieur_de_employe, aucun superieur trouve pour  ' ||
                             pv_user_name,
                             3);
            RETURN NULL;
        WHEN OTHERS THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'superieur_de_employe erreur : ' || SQLERRM,
                             3);
            RETURN NULL;
    END get_superieur_hierachique;

    -------------------------------------------------------------------------------------
    --  Nom           : superieur_bap
    --  Description   : Procédure amenant le supérieur de l'employé.
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --
    -------------------------------------------------------------------------------------
    PROCEDURE superieur_bap(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                            pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                            pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                            pv_funcmode  IN VARCHAR2,
                            pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_user_name FND_USER.USER_NAME%type;
        vv_superieur FND_USER.USER_NAME%type;
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        vv_user_name := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'VALIDEUR_BAP');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_bap, debut  ' || vv_user_name,
                         cn_mode_debug);

        vv_superieur := get_superieur_hierachique(pv_itemtype,
                                                  pv_itemkey,
                                                  vv_user_name);

        IF vv_superieur IS NULL THEN
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'superieur_bap, aucun superieur trouve pour  ' ||
                             vv_user_name,
                             3);

            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        ELSE
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VALIDEUR_BAP',
                                      avalue   => vv_superieur);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_bap, fin  ' || vv_user_name,
                         cn_mode_debug);

    END superieur_bap;

    -------------------------------------------------------------------------------------
    --  Nom           : facture_traitee
    --  Description   : Procédure vérifiant si la facture est arrivée jusqu'aux tables
    --                   AP_INVOICES suite a l'import dans l'Open Interface
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup YES/NO
    -------------------------------------------------------------------------------------
    PROCEDURE facture_traitee(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                              pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                              pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                              pv_funcmode  IN VARCHAR2,
                              pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_oi_id ap_invoices_all.invoice_id%type;
        vn_fact_OI       number;
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        vn_invoice_oi_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                        itemkey  => pv_itemkey,
                                                        aname    => 'INVOICE_OI_ID');

        select count(1)
          into vn_fact_OI
          from ap_invoices_interface aii
         where aii.invoice_id = vn_invoice_oi_id
           and aii.status = 'PROCESSED';

        IF vn_fact_OI = 1 THEN
            pv_resultout := 'COMPLETE:' || 'Y';
        ELSE
            pv_resultout := 'COMPLETE:' || 'N';

        END IF;
    END facture_traitee;

   --début SHA EDB408
  -------------------------------------------------------------------------------------
    --  Nom           : CommandeSSTR_ivalua
    --  Description   : Procédure creant les blocages AP a partir des blacages OI
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
    ) IS
        l_po_segment1    VARCHAR2(100);
        l_po_attribute7  VARCHAR2(100);
        l_exists         NUMBER;
        l_user          VARCHAR2(50);
    v_deliver_to_person_id po_distributions_all.deliver_to_person_id%type;
    BEGIN
        -- Get PO information
    BEGIN
        SELECT poh.segment1, poh.attribute7
        INTO l_po_segment1, l_po_attribute7
        FROM po_headers_all poh
        WHERE poh.po_header_id IN (SELECT poh.po_header_id
                            FROM po_headers_all poh
                            JOIN ap_invoices_all aia ON poh.segment1 = aia.attribute13
                            WHERE aia.invoice_id = p_invoice_id
        );

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT poh.segment1, poh.attribute7
          INTO l_po_segment1, l_po_attribute7
        FROM po_headers_all poh
        WHERE poh.po_header_id IN (SELECT aia.po_header_id
                            FROM  ap_invoice_lines_all aia
                            WHERE aia.invoice_id = p_invoice_id
        );

    END;


        IF l_po_segment1 LIKE 'ST%' AND l_po_attribute7 = 'IVALUA' THEN
            -- Check for existing hold
            SELECT COUNT(1) INTO l_exists
            FROM ap_holds_all
            WHERE invoice_id = p_invoice_id
            AND hold_lookup_code = 'Imputation en attente';

 begin

                    SELECT MIN(deliver_to_person_id)
          into v_deliver_to_person_id
                    FROM po_distributions_all
                    WHERE po_header_id = (
                        SELECT poh.po_header_id
                        FROM po_headers_all poh
                        JOIN ap_invoices_all aia ON poh.segment1 = aia.attribute13
                        WHERE aia.invoice_id = p_invoice_id);
         if    v_deliver_to_person_id IS NULL THEN

     SELECT MIN(deliver_to_person_id)
          into v_deliver_to_person_id
                    FROM po_distributions_all
                    WHERE po_header_id in (SELECT aia.po_header_id
                            FROM  ap_invoice_lines_all aia
                            WHERE aia.invoice_id = p_invoice_id
        );
    END IF;
    end;
            IF l_exists = 0 THEN
                -- Update hold attributes
                UPDATE ap_holds_all
                SET attribute4 = 'Y',
                    attribute5 = 'BAP',
                    attribute6 = v_deliver_to_person_id

                WHERE invoice_id = p_invoice_id
                AND hold_lookup_code = 'En attente';

                -- Add to history
                SELECT user_name INTO l_user
                FROM fnd_user
                WHERE user_id = fnd_global.user_id;

                insert_history(
                    p_itemtype,
                    p_itemkey,
                    'DKA_TRANSFERT_IVALUA',
                    'En attente',
                    'Transfert du blocage vers IVALUA',
                    WF_DIRECTORY.GetRoleDisplayName(l_user)
                );
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END CommandeSSTR_ivalua;
 --Fin SHA EDB408
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
                                             pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                             pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                             pv_funcmode  IN VARCHAR2,
                                             pv_resultout OUT NOCOPY VARCHAR2) IS
        x_progress       VARCHAR2(100);
        l_group_id       NUMBER;
        l_req_id         NUMBER;
        vn_invoice_id    ap_invoices_all.invoice_id%type;
        vn_invoice_oi_id ap_invoices_interface.invoice_id%type;
        --  vn_user_id_blocage    fnd_user.user_id%type;
        vv_blocage_imputation ap_invoices_interface.attribute14%type;
        vn_retcode            number;
        vv_errbuf             VARCHAR2(1000);
        vv_blocagesXerox      ap_invoices_interface.attribute1%type;
        vv_blocage_code       ap_lookup_codes.lookup_code%type;
        vv_blocage_desc       fnd_flex_values_vl.description%type;
        l_tablen              number;
        l_tab                 tableau;
        vv_deblocage_ap       dka_stransco_lines.param3_value%type;
        vn_user_deblocage_id  fnd_user.user_id%type;
        vn_user_exploit       fnd_user.user_id%type;
        vn_blocage_inexistant boolean := false;
        vn_exists             number;

    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        x_progress := 'DKA_SAPWFCSP_PKG.transfert_codes_blocages_OI_AP: 01';

        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'transfert_codes_blocages_OI_AP debut vn_invoice_id  ' ||
                         vn_invoice_id,
                         cn_mode_debug);


        vv_blocagesXerox := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                      itemkey  => pv_itemkey,
                                                      aname    => 'BLOCAGES_XEROX');

        BEGIN

            BEGIN
                select user_id
                  into vn_user_exploit
                  from fnd_user
                 where user_name = cv_user_blocage;

                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'transfert_codes_blocages_OI_AP  vn_user_exploit  ' ||
                                 vn_user_exploit,
                                 cn_mode_debug);
            EXCEPTION
                WHEN no_data_found THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'Utilisateur ' || cv_user_blocage ||
                                     ' non trouvé ',
                                     3);
                    pv_resultout          := wf_engine.eng_completed || ':' ||
                                             'FAIL';
                    vn_blocage_inexistant := true;
                    RETURN;
            END;

            /*
                  SELECT aii.attribute14, nvl( u.user_id, vn_user_exploit)
                    INTO vv_blocage_imputation, vn_user_deblocage_id
                    FROM ap_invoices_all aii, fnd_user u
                   WHERE aii.invoice_id = vn_invoice_id
                     and u.user_name (+)= aii.ATTRIBUTE12;
            */
            SELECT aii.attribute14, nvl(aii.ATTRIBUTE12, vn_user_exploit)
              INTO vv_blocage_imputation, vn_user_deblocage_id
              FROM ap_invoices_all aii
             WHERE aii.invoice_id = vn_invoice_id;

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'transfert_codes_blocages_OI_AP  vv_blocage_imputation  ' ||
                             vv_blocage_imputation ||
                             '  vn_user_deblocage_id  ' ||
                             vn_user_deblocage_id,
                             cn_mode_debug);

            IF vv_blocagesXerox is not null then
                string_to_table(vv_blocagesXerox, '.', l_tab, l_tablen);
                for vn_blocage_actuel in 1 .. least(l_tablen, 3/*5*/) loop
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'vn_blocage_actuel' ||
                                     vn_blocage_actuel || '  ' ||
                                     l_tab(vn_blocage_actuel),
                                     cn_mode_debug);
                    begin
                        select fvs.description,
                               dsl.return_value,
                               upper(dsl.param3_value)
                          into vv_blocage_desc,
                               vv_blocage_code,
                               vv_deblocage_ap
                          from fnd_flex_value_sets  ffs,
                               fnd_flex_values_vl   fvs,
                               dka_stransco_headers dsh,
                               dka_stransco_lines   dsl
                         where ffs.flex_value_set_name =
                               'DKA_CODES_XEROX'
                           and fvs.flex_value_set_id =
                               ffs.flex_value_set_id
                           and fvs.flex_value = dsl.param1_value -- code xerox
                           and dsh.Set_Id = dsl.set_id
                           AND dsh.set_name = 'CODE REJET XEROX / ORACLE'
                           and dsl.param1_value = l_tab(vn_blocage_actuel);

                        select count(1)
                          into vn_exists
                          from ap_holds_all ah
                         where ah.invoice_id = vn_invoice_id
                           and ah.hold_lookup_code = vv_blocage_code;

                        IF vn_exists = 0 THEN
                            cree_blocage_AP('OI',
                                            vn_invoice_id,
                                            vv_blocage_code,
                                            vv_blocage_desc,
                                            NULL, --- 07022011   MT
                                            vn_user_exploit,
                                            pv_itemtype,
                                            pv_itemkey,
                                            vv_errbuf,
                                            vn_retcode);

                            IF vn_retcode <> 0 THEN
                                print_wf_message(pv_itemtype,
                                                 pv_itemkey,
                                                 vv_errbuf,
                                                 3);
                                pv_resultout := wf_engine.eng_completed || ':' ||
                                                'FAIL';
                                return;
                            END IF;
                        END IF;

                        IF nvl(vv_deblocage_ap, 'NON') = 'OUI' THEN
                            -- on debloque
                            leve_blocage(vn_invoice_id,
                                         vv_blocage_code,
                                         'APPROVED',
                                         vn_user_deblocage_id,
                                         vv_errbuf,
                                         vn_retcode,
                                         0,
                                         pv_itemtype,
                                         pv_itemkey);

                            IF vn_retcode <> 0 THEN
                                print_wf_message(pv_itemtype,
                                                 pv_itemkey,
                                                 vv_errbuf,
                                                 3);
                                pv_resultout := wf_engine.eng_completed || ':' ||
                                                'FAIL';
                                return;
                            END IF;
                        END IF;

                    exception
                        when NO_DATA_FOUND then
                            print_wf_message(pv_itemtype,
                                             pv_itemkey,
                                             'contexte_PNC, aucun blocage trouve pour  ' ||
                                             l_tab(vn_blocage_actuel),
                                             3);
                    end;
                end loop;
            end if;

            IF vv_blocage_imputation IS NOT NULL THEN
                cree_blocage_AP('OI',
                                vn_invoice_id,
                                vv_blocage_imputation,
                                null,
                                NULL, --- 07022011   MT
                                vn_user_exploit,
                                pv_itemtype,
                                pv_itemkey,
                                vv_errbuf,
                                vn_retcode);

                IF vn_retcode <> 0 THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     vv_errbuf,
                                     3);
                    pv_resultout := wf_engine.eng_completed || ':' ||
                                    'FAIL';
                    return;
                END IF;
            END IF;

            if vn_blocage_inexistant = false then
                update ap_invoices_all
                   set attribute1        = null,
                       attribute4        = null,
                       attribute5        = null,
                       attribute6        = null,
                       --attribute7        = null,
                       --attribute11       = null,
                       attribute12       = null,
                       attribute14       = null,
                       LAST_UPDATE_DATE  = sysdate,
                       LAST_UPDATED_BY   = nvl(fnd_global.user_id, -1),
                       LAST_UPDATE_LOGIN = nvl(fnd_global.login_id, -1)
                 where invoice_id = vn_invoice_id;
            else
                update ap_invoices_all
                   set attribute4        = null,
                       attribute5        = null,
                       attribute6        = null,
                       --attribute7        = null,
                       --attribute11       = null,
                       attribute12       = null,
                       attribute14       = null,
                       LAST_UPDATE_DATE  = sysdate,
                       LAST_UPDATED_BY   = nvl(fnd_global.user_id, -1),
                       LAST_UPDATE_LOGIN = nvl(fnd_global.login_id, -1)
                 where invoice_id = vn_invoice_id;
            end if;
 -- SHA EDB408
        CommandeSSTR_ivalua(vn_invoice_id, pv_itemtype, pv_itemkey);
        EXCEPTION
            WHEN no_data_found THEN
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
                RETURN;
            WHEN OTHERS THEN
                pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
                x_progress   := substr('DKA_SAPWFCSP_PKG.transfert_codes_blocages_OI_AP: ' ||
                                       vv_errbuf || SQLERRM,
                                       1,
                                       100);

                wf_core.CONTEXT('DKA_SAPWFCSP_PKG',
                                'transfert_codes_blocages_OI_AP',
                                x_progress);
                RAISE;
        END;
        pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

    END transfert_codes_blocages_OI_AP;

    ---------------------------------------------------------------------------------------------------------------
    --  Nom           : lance_workflow_CSP_PL
    --  Description   : Lance le workflow CSP depuis du PL (servira pour l'open interface)
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
                                    pn_fact_AP_OI IN number default 0) IS
        vv_step       VARCHAR2(50);
        vn_dummy      NUMBER;
        vv_itemkey    VARCHAR2(100);
        vv_itemtype   VARCHAR2(10);
        vv_wf_process VARCHAR2(20);

    BEGIN
        pn_retcode := 0;

        -- Initialisation
        vv_itemtype := 'DKA_CSP';
        dbms_output.put_line('lancement de DKA_CSP pour fact' ||
                             pn_id_facture);
        IF pn_fact_AP_OI = 0 THEN
            vv_wf_process := 'DKA_PROCESS_OI';
        ELSE
            vv_wf_process := 'DKA_PROCESS_AP';
        END IF;
        SELECT to_char(DKA_SAPWFCSP_s.NEXTVAL) INTO vn_dummy FROM dual;
        vv_itemkey := pn_id_facture || '_' || vn_dummy;
        dbms_output.put_line('lancement de DKA_CSP ' || vv_wf_process ||
                             'itemkey = ' || vv_itemkey);
        -- Creation du process WF
        wf_engine.createprocess(itemtype => vv_itemtype,
                                itemkey  => vv_itemkey,
                                process  => vv_wf_process);

        /*   IF pv_itemtype is not null and pv_itemkey is not null then
            -- Lie le workflow au workflow Maître
            wf_engine.setitemparent(itemtype        => vv_itemtype,
                                    itemkey         => vv_itemkey,
                                    parent_itemtype => pv_itemtype,
                                    parent_itemkey  => pv_itemkey,
                                    parent_context  => NULL);
          end if;
        */
        -- Initialisation des attributs
        IF pn_fact_AP_OI = 0 THEN
            wf_engine.setitemattrnumber(itemtype => vv_itemtype,
                                        itemkey  => vv_itemkey,
                                        aname    => 'INVOICE_OI_ID',
                                        avalue   => pn_id_facture);
        ELSE
            wf_engine.setitemattrnumber(itemtype => vv_itemtype,
                                        itemkey  => vv_itemkey,
                                        aname    => 'INVOICE_ID',
                                        avalue   => pn_id_facture);
        END IF;
        /*
          wf_engine.setitemattrnumber(itemtype => vv_itemtype,
                                      itemkey  => vv_itemkey,
                                      aname    => 'RESPONSIBILITY_ID',
                                      avalue   => fnd_global.resp_id);

          wf_engine.setitemattrnumber(itemtype => vv_itemtype,
                                      itemkey  => vv_itemkey,
                                      aname    => 'APPLICATION_ID',
                                      avalue   => fnd_global.resp_appl_id);
        */
        -- Kick off the process
        wf_engine.startprocess(itemtype => vv_itemtype,
                               itemkey  => vv_itemkey);

        -- FT 22
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            pn_retcode := 2;
            pv_errbuf  := 'lance_workflow_CSP_PL =>' || vv_step || '=>' ||
                          SQLERRM;
    END lance_workflow_CSP_PL;

    -------------------------------------------------------------------------------------
    --  Nom           : fermeture_notif_diverse
    --  Description   : Procédure de retraitement des notifications liées
    --                       au blocage variance
    --
    --  PARAMETRES :
    --                    pn_notification_id  la notification diverse a fermer en auto
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    procedure fermeture_notif_diverse(pn_notification_id wf_notifications.notification_id%type,
                                      pn_repondeur_id    fnd_user.user_id%type) is
        v_action wf_lookups.lookup_code%type;
        v_result wf_lookups.lookup_code%type;
        v_user   fnd_user.user_name%type;
    begin
        wf_engine.preserved_context := TRUE;

        -- choix de l'action
        SELECT wl.lookup_code
          into v_action
          FROM wf_lookups wl
         WHERE wl.lookup_type = 'DKA_NOTIF_TRAITEE_ATTENTE'
           and wl.meaning = '2-Notification traitée';

        -- resultat de l'activité
        SELECT wl.lookup_code
          into v_result
          FROM wf_lookups wl
         WHERE wl.lookup_type = 'DKA_UNIQUE_CHOIX';

        --Getting the USER NAME  --PN artf606594
        SELECT user_name
          into v_user
          FROM fnd_user
         WHERE user_id = pn_repondeur_id;

        wf_notification.setattrtext(pn_notification_id,
                                    'Z_ACTION',
                                    v_action);
        wf_notification.setattrtext(pn_notification_id,
                                    'RESULT',
                                    v_result);

        wf_notification.setattrtext(pn_notification_id,
                                    'DKA_COMMENTS',
                                    ' Traitement notification dans le cadre des regles de la simplication du WF ');

        /*wf_notification.respond(nid       => pn_notification_id,
        responder => pn_repondeur_id);*/ --PN Commented artf606594
        wf_notification.respond(nid       => pn_notification_id,
                                responder => v_user);

        Dka_Tools_Pkg.put_log_message(' fermeture_notif_diverse -  notif  ' ||
                                       pn_notification_id || ' fermée');
    end fermeture_notif_diverse;

    -------------------------------------------------------------------------------------
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
    PROCEDURE gestion_deblocage_variance(pv_errbuf   OUT VARCHAR2,
                                         pn_retcode  IN OUT NUMBER,
                                         pv_CSP      IN VARCHAR2,
                                         pv_division IN VARCHAR2) IS
        vv_errbuf                    varchar2(1000);
        vn_retcode                   number := 0;
        rec_param                    dka_parameters%ROWTYPE;
        vv_methode_traitement        dka_parameters.varchar2_value%type;
        vn_nb_lignes_non_rapprochées number;
        vn_user_exploit              fnd_user.user_id%type;
        TYPE t_item_key IS TABLE OF ap_holds_all.attribute2%type;
        va_item_key t_item_key;
        TYPE t_item_key_unique IS TABLE OF ap_holds_all.attribute2%type index by ap_holds_all.attribute2%type;
        va_item_key_unique t_item_key_unique;
        vv_item_key        ap_holds_all.attribute2%type;
        vn_notif_a_fermer  wf_notifications.notification_id%type;
        vv_order_type             VARCHAR2(5);
    --sha EDB408
    vv_order_ivalua_type      VARCHAR2(5);
   v_deliver_to_person_id po_distributions_all.deliver_to_person_id%type;
    l_po_attribute7   po_headers_all.attribute7%TYPE;
    --fin sha EDB408
        vv_too_many_orders BOOLEAN := FALSE;
        vn_org_id          NUMBER := fnd_profile.value('ORG_ID');
        vn_org_id_dal      NUMBER;
        vn_org_id_tra      NUMBER;
        vn_org_id_pro      NUMBER;
       v_attribute5        ap_holds_all.attribute5%type;
          --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image + Optimisation
        CURSOR c_facture_init_variance(pv_methode in dka_parameters.varchar2_value%type) IS
            select ai.invoice_id
              from ap_invoices_all ai,
              dka_stransco_headers      dsh,
                           dka_stransco_lines        dsl,
                           gl_code_combinations      gcc,
                           hr_all_organization_units hou
             where NOT EXISTS
             (select 'X'
                      from ap_holds_all ah
                     where ah.hold_lookup_code in
                           ('DIST VARIANCE', 'TAX AMOUNT RANGE', 'LINE VARIANCE') -- OBE artf2435790
                       and ah.release_lookup_code is null
                       and ah.invoice_id = ai.invoice_id)
               and (2 = (select count(distinct ah.hold_lookup_code)
                           from ap_holds_all ah
                          where ah.hold_lookup_code in
                                ('DIST VARIANCE', 'TAX AMOUNT RANGE', 'LINE VARIANCE') -- OBE artf2435790
                            and ah.release_lookup_code is not null
                            and ((pv_methode = 'JOURNALIER' and
                                trunc(ah.last_update_date) >=
                                trunc(sysdate - case when
                                        to_number(to_char(sysdate, 'HH24')) - 12 > 0 then 0 else 1 end)) or
                                pv_methode = 'REPRISE')
                            and ah.invoice_id = ai.invoice_id) --(les 2 codes blocages ""DIST VARIANCE"" et ""TAX AMOUNT RANGE"" sont présents sur la facture.).
                   or
                   1 = (select count(distinct ah.hold_lookup_code)
                           from ap_holds_all ah
                          where ah.hold_lookup_code in
                                ('DIST VARIANCE', 'TAX AMOUNT RANGE', 'LINE VARIANCE') -- OBE artf2435790
                            and ah.release_lookup_code is not null
                            and ((pv_methode = 'JOURNALIER' and
                                trunc(ah.last_update_date) >=
                                trunc(sysdate - case when
                                        to_number(to_char(sysdate, 'HH24')) - 12 > 0 then 0 else 1 end)) or
                                pv_methode = 'REPRISE')
                            and ah.invoice_id = ai.invoice_id) or
                   0 = (select count(distinct ah.hold_lookup_code)
                           from ap_holds_all ah
                          where ah.hold_lookup_code in
                                ('DIST VARIANCE', 'TAX AMOUNT RANGE', 'LINE VARIANCE') -- OBE artf2435790
                            and ah.invoice_id = ai.invoice_id)) --(les 2 codes blocages ""DIST VARIANCE"" et ""TAX AMOUNT RANGE"" ne sont pas présents sur la facture.).

                  -- verif que les blocages sur lesquels on va travailler sont toujours actifs
                  -- pour ne pas traités 15 fois les meme a chaque REPRISE.
               and exists (select 1
                      from ap_holds_all ah
                     where ah.invoice_id = ai.invoice_id
                       and hold_lookup_code in
                           ('Imputation en attente',
                            'En attente', 'Commande inconnue')
                       and release_lookup_code is null
                          -- verif que c'est bien une facture traitée par un workflow CSP
                       and ah.attribute1 = 'DKA_CSP'
                       and rownum < 2)
             --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
             /*  and exists --QVA 18/08/2010
             (SELECT ----+INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     1
                      FROM dka_stransco_headers      dsh,
                           dka_stransco_lines        dsl,
                           gl_code_combinations      gcc,
                           hr_all_organization_units hou
                     WHERE dsl.return_value = nvl(pv_CSP, dsl.return_value)
                       AND dsl.param1_value =
                           nvl(pv_division, dsl.param1_value)
                       AND ai.accts_pay_code_combination_id =
                           gcc.code_combination_id
                       AND dsl.param2_value = gcc.segment2
                       AND hou.organization_id = ai.org_id
                       AND dsl.param1_value = hou.attribute10
                       AND dsh.set_id = dsl.set_id
                       AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                       AND dsl.start_date <= trunc(sysdate)
                       AND nvl(dsl.end_date, trunc(sysdate)) >=
                           trunc(sysdate))*/
               AND dsl.return_value = nvl(pv_CSP, dsl.return_value)
               AND dsl.param1_value =
                   nvl(pv_division, dsl.param1_value)
               AND ai.accts_pay_code_combination_id =
                   gcc.code_combination_id
               AND dsl.param2_value = gcc.segment2
               AND hou.organization_id = ai.org_id
               AND dsl.param1_value = hou.attribute10
               AND dsh.set_id = dsl.set_id
               AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
               AND dsl.start_date <= trunc(sysdate)
               AND nvl(dsl.end_date, trunc(sysdate)) >=
                   trunc(sysdate)
             ;
    BEGIN

        Dka_Tools_Pkg.get_parameter('DKA_SAPWFCSP',
                                    'METHODE_'||vn_org_id,
                                    rec_param,
                                    vn_retcode,
                                    vv_errbuf);
        vv_methode_traitement := rec_param.varchar2_value;

        IF vn_retcode != 0 THEN
            pv_errbuf := 'Parametre METHODE_ORG absent : ';

            Dka_Tools_Pkg.get_parameter('DKA_SAPWFCSP',
                                        'METHODE',
                                        rec_param,
                                        vn_retcode,
                                        vv_errbuf);

            vv_methode_traitement := rec_param.varchar2_value;

            IF vn_retcode != 0 THEN
              pv_errbuf := 'Parametre METHODE absent : ';
              RETURN;
            END IF;
        END IF;

        Dka_Tools_Pkg.put_log_message('Methode : ' ||
                                       vv_methode_traitement);
        IF fnd_global.user_id is null THEN
            select user_id
              into vn_user_exploit
              from fnd_user
             where user_name = DKA_SAPWFCSP_pkg.cv_user_blocage;
        END IF;

        FOR fact in c_facture_init_variance(vv_methode_traitement) LOOP
            -- facture totalement rapprochée ?
            select count(1)
              into vn_nb_lignes_non_rapprochées
              from ap_invoice_distributions_all aid
             where aid.line_type_lookup_code not in ('NONREC_TAX','REC_TAX')--!= 'TAX' -- OBE artf2435790
               and po_distribution_id is null
               and invoice_id = fact.invoice_id
               and rownum < 2;

            vv_too_many_orders := FALSE;
            BEGIN
                select distinct substr(pha.segment1, -6, 2),  --SHA EDB408
        substr(pha.segment1, 0, 2), pha.attribute7
                  INTO vv_order_type , vv_order_ivalua_type , l_po_attribute7
                  from ap_invoice_distributions_all aida,
                       po_distributions_all         pda,
                       po_headers_all               pha
                 where aida.po_distribution_id = pda.po_distribution_id
                   and pha.po_header_id = pda.po_header_id
                   and aida.invoice_id = fact.invoice_id;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    vv_order_type := NULL;
          vv_order_ivalua_type := NULL;
                WHEN TOO_MANY_ROWS THEN
                    vv_order_type      := NULL;
          vv_order_ivalua_type      := NULL;
                    vv_too_many_orders := TRUE;
                    Dka_Tools_Pkg.put_log_message('This invoice is associated with more than one order type');
            END;

            va_item_key_unique.delete;
            IF vv_too_many_orders = FALSE THEN
                --MT
                IF vn_nb_lignes_non_rapprochées = 0 then
                --début SHA EDB408
        IF  vv_order_ivalua_type = 'ST' AND l_po_attribute7 = 'IVALUA' THEN
         Dka_Tools_Pkg.put_log_message(' facture ' ||
                                                       fact.invoice_id ||
                                                       ' of type SSTR IVALUA ');
                        Dka_Tools_Pkg.put_log_message('Releasing hold type Commande inconnue  ');
                        update ap_holds_all ah
                           set release_lookup_code = 'APPROVED',
                               release_reason      = 'Facture totalement imputée',
                               last_update_date    = sysdate,
                               last_updated_by     = nvl(fnd_global.user_id,
                                                         vn_user_exploit)
                         where invoice_id = fact.invoice_id
                           and hold_lookup_code = 'Commande inconnue'
                           and release_lookup_code is null
                        returning attribute2 bulk collect into va_item_key;

                        Dka_Tools_Pkg.put_log_message('  ' ||
                                                       to_char(SQL%ROWCOUNT) ||
                                                       ' blocage(s) levé(s) ');

                        IF va_item_key.COUNT != 0 THEN
                            -- on insere les item_keys dans un tableau indexé pour supprimer les doublons
                            FOR i IN va_item_key.FIRST .. va_item_key.LAST LOOP
                                IF va_item_key(i) is not null and
                                   (va_item_key_unique.COUNT = 0 OR NOT
                                     va_item_key_unique.EXISTS(va_item_key(i))) THEN
                                    Dka_Tools_Pkg.put_log_message(' ajout dans unique  ' ||
                                                                   va_item_key(i));
                                    va_item_key_unique(va_item_key(i)) := va_item_key(i);
                                END IF;
                            END LOOP;

                            vv_item_key := va_item_key_unique.FIRST;
                            WHILE vv_item_key IS NOT NULL LOOP
                                -- reinit des blocages divers
                                update ap_holds_all ah
                                   set attribute1       = null,
                                       attribute2       = null,
                                       last_update_date = sysdate,
                                       last_updated_by  = nvl(fnd_global.user_id,
                                                              vn_user_exploit)
                                 where attribute2 = vv_item_key
                                   and attribute1 = 'DKA_CSP'
                                   and invoice_id = fact.invoice_id
                                   and release_lookup_code is null
                                      -- blocages divers uniquement
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_ecart_prix
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi2
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi3
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_qty_rec
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_qty_ord
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_prlv_abs
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_affact
                                   and ah.hold_LOOKUP_CODE <> cv_ano_rib
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_bon_apayer
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_imput_attente
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_motant_livre_maxi;

                                Dka_Tools_Pkg.put_log_message('  ' ||
                                                               to_char(SQL%ROWCOUNT) ||
                                                               ' blocage(s) réinitialisé(s) ');
                                -- reponse a la notif diverse
                                begin
                                    select notification_id
                                      into vn_notif_a_fermer
                                      from wf_notifications wn
                                     where wn.message_type = 'DKA_CSP'
                                       and message_name =
                                           'DKA_MSG_CSP_ANO_DIVERS'
                                       and context like
                                           'DKA_CSP:' || vv_item_key || '%'
                                       and status = 'OPEN';



                                    fermeture_notif_diverse(vn_notif_a_fermer,
                                                            nvl(fnd_global.user_id,
                                                                vn_user_exploit));
                                exception
                                    when no_data_found then
                                        Dka_Tools_Pkg.put_log_message(' Pas de notif de type divers a fermer pour item_key ' ||
                                                                       vv_item_key);
                                end;
                                vv_item_key := va_item_key_unique.NEXT(vv_item_key);
                            END LOOP;
                        END IF;

                        --Releasing hold code Imputation en attente if exists
                        Dka_Tools_Pkg.put_log_message('Releasing hold type Imputation en attente  ');
                        update ap_holds_all ah
                           set release_lookup_code = 'APPROVED',
                               release_reason      = 'Facture totalement imputée',
                               last_update_date    = sysdate,
                               last_updated_by     = nvl(fnd_global.user_id,
                                                         vn_user_exploit)
                         where invoice_id = fact.invoice_id
                           and hold_lookup_code = 'Imputation en attente'
                           and release_lookup_code is null;

        begin
       v_attribute5 := null; -- SHA KDFI3035

         select attribute5
        into v_attribute5
        from ap_holds_all ah
        where invoice_id = fact.invoice_id
        AND hold_lookup_code = 'En attente'
        and release_lookup_code is null -- SHA KDFI3035
        and release_reason is null ;-- SHA KDFI3035

        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_attribute5 := NULL;

        end;

     if v_attribute5  is  NULL then
     begin

                    SELECT MIN(deliver_to_person_id)
          into v_deliver_to_person_id
                    FROM po_distributions_all
                    WHERE po_header_id = (
                        SELECT poh.po_header_id
                        FROM po_headers_all poh
                        JOIN ap_invoices_all aia ON poh.segment1 = aia.attribute13
                        WHERE aia.invoice_id = fact.invoice_id);
         if    v_deliver_to_person_id IS NULL THEN

     SELECT MIN(deliver_to_person_id)
          into v_deliver_to_person_id
                    FROM po_distributions_all
                    WHERE po_header_id in (SELECT aia.po_header_id
                            FROM  ap_invoice_lines_all aia
                            WHERE aia.invoice_id = fact.invoice_id
        );
    END IF;
    end;
         -- Update hold for SSTR

            UPDATE ap_holds_all
            SET attribute4 = 'Y',
                attribute5 = 'BAP',
                attribute6 = v_deliver_to_person_id,
                last_update_date = SYSDATE,
                last_updated_by = nvl(fnd_global.user_id,
                                                              vn_user_exploit)
            WHERE invoice_id = fact.invoice_id
            AND hold_lookup_code = 'En attente';

           end if;
      -- fermer la notification

         begin
                  select notification_id
                    into vn_notif_a_fermer
                    from wf_notifications wn
                   where wn.message_type = 'DKA_CSP'
                     and message_name =
                         'DKA_MSG_CSP_IMPUT_ATTENTE_IV'
                     and context like
                         'DKA_CSP:' || fact.invoice_id || '%'
                     and status = 'OPEN';

                  fermeture_notif_diverse(vn_notif_a_fermer,
                                          nvl(fnd_global.user_id,
                                              vn_user_exploit));
              exception
                  when no_data_found then
                      Dka_Tools_Pkg.put_log_message(' Pas de notif de type divers a fermer pour item_key ' ||
                                                     fact.invoice_id);
              end;


     ELSIF vv_order_type = 'ST'  THEN

                        Dka_Tools_Pkg.put_log_message(' facture ' ||
                                                       fact.invoice_id ||
                                                       ' of type SSTR ');
                        Dka_Tools_Pkg.put_log_message('Releasing hold type Commande inconnue  ');
                        update ap_holds_all ah
                           set release_lookup_code = 'APPROVED',
                               release_reason      = 'Facture totalement imputée',
                               last_update_date    = sysdate,
                               last_updated_by     = nvl(fnd_global.user_id,
                                                         vn_user_exploit)
                         where invoice_id = fact.invoice_id
                           and hold_lookup_code = 'Commande inconnue'
                           and release_lookup_code is null
                        returning attribute2 bulk collect into va_item_key;

                        Dka_Tools_Pkg.put_log_message('  ' ||
                                                       to_char(SQL%ROWCOUNT) ||
                                                       ' blocage(s) levé(s) ');

                        IF va_item_key.COUNT != 0 THEN
                            -- on insere les item_keys dans un tableau indexé pour supprimer les doublons
                            FOR i IN va_item_key.FIRST .. va_item_key.LAST LOOP
                                IF va_item_key(i) is not null and
                                   (va_item_key_unique.COUNT = 0 OR NOT
                                     va_item_key_unique.EXISTS(va_item_key(i))) THEN
                                    Dka_Tools_Pkg.put_log_message(' ajout dans unique  ' ||
                                                                   va_item_key(i));
                                    va_item_key_unique(va_item_key(i)) := va_item_key(i);
                                END IF;
                            END LOOP;

                            vv_item_key := va_item_key_unique.FIRST;
                            WHILE vv_item_key IS NOT NULL LOOP
                                -- reinit des blocages divers
                                update ap_holds_all ah
                                   set attribute1       = null,
                                       attribute2       = null,
                                       last_update_date = sysdate,
                                       last_updated_by  = nvl(fnd_global.user_id,
                                                              vn_user_exploit)
                                 where attribute2 = vv_item_key
                                   and attribute1 = 'DKA_CSP'
                                   and invoice_id = fact.invoice_id
                                   and release_lookup_code is null
                                      -- blocages divers uniquement
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_ecart_prix
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi2
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_cmd_multi3
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_qty_rec
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_qty_ord
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_prlv_abs
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_affact
                                   and ah.hold_LOOKUP_CODE <> cv_ano_rib
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_bon_apayer
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_imput_attente
                                   and ah.hold_LOOKUP_CODE <>
                                       cv_ano_motant_livre_maxi;

                                Dka_Tools_Pkg.put_log_message('  ' ||
                                                               to_char(SQL%ROWCOUNT) ||
                                                               ' blocage(s) réinitialisé(s) ');
                                -- reponse a la notif diverse
                                begin
                                    select notification_id
                                      into vn_notif_a_fermer
                                      from wf_notifications wn
                                     where wn.message_type = 'DKA_CSP'
                                       and message_name =
                                           'DKA_MSG_CSP_ANO_DIVERS'
                                       and context like
                                           'DKA_CSP:' || vv_item_key || '%'
                                       and status = 'OPEN';

                                    fermeture_notif_diverse(vn_notif_a_fermer,
                                                            nvl(fnd_global.user_id,
                                                                vn_user_exploit));
                                exception
                                    when no_data_found then
                                        Dka_Tools_Pkg.put_log_message(' Pas de notif de type divers a fermer pour item_key ' ||
                                                                       vv_item_key);
                                end;
                                vv_item_key := va_item_key_unique.NEXT(vv_item_key);
                            END LOOP;
                        END IF;

                        --Releasing hold code Imputation en attente if exists
                        Dka_Tools_Pkg.put_log_message('Releasing hold type Imputation en attente  ');
                        update ap_holds_all ah
                           set release_lookup_code = 'APPROVED',
                               release_reason      = 'Facture totalement imputée',
                               last_update_date    = sysdate,
                               last_updated_by     = nvl(fnd_global.user_id,
                                                         vn_user_exploit)
                         where invoice_id = fact.invoice_id
                           and hold_lookup_code = 'Imputation en attente'
                           and release_lookup_code is null;

                    ELSE
                        --IF vv_order_type='ST' THEN
                        Dka_Tools_Pkg.put_log_message(' facture ' ||
                                                       fact.invoice_id ||
                                                       ' totalement rapprochée ');
                        update ap_holds_all ah
                           set release_lookup_code = 'APPROVED',
                               release_reason      = 'Facture totalement imputée',
                               last_update_date    = sysdate,
                               last_updated_by     = nvl(fnd_global.user_id,
                                                         vn_user_exploit)
                         where invoice_id = fact.invoice_id
                           and hold_lookup_code in
                               ('Imputation en attente', 'En attente',
                                'Commande inconnue')
                           and release_lookup_code is null
                        returning attribute2 bulk collect into va_item_key;

                        Dka_Tools_Pkg.put_log_message('  ' ||
                                                       SQL%ROWCOUNT ||
                                                       ' blocage(s) levé(s) ');

                        IF va_item_key.COUNT != 0 THEN

                            -- on insere les item_keys dans un tableau indexé pour supprimer les doublons
                            FOR i IN va_item_key.FIRST .. va_item_key.LAST LOOP
                                IF va_item_key(i) is not null and
                                   (va_item_key_unique.COUNT = 0 OR NOT
                                     va_item_key_unique.EXISTS(va_item_key(i))) THEN
                                    Dka_Tools_Pkg.put_log_message(' ajout dans unique  ' ||
                                                                   va_item_key(i));
                                    va_item_key_unique(va_item_key(i)) := va_item_key(i);
                                END IF;
                            END LOOP;

                            vv_item_key := va_item_key_unique.FIRST;
                            WHILE vv_item_key IS NOT NULL LOOP
                                update ap_holds_all ah
                                   set attribute1       = null,
                                       attribute2       = null,
                                       last_update_date = sysdate,
                                       last_updated_by  = nvl(fnd_global.user_id,
                                                              vn_user_exploit)
                                 where attribute2 = vv_item_key
                                   and attribute1 = 'DKA_CSP'
                                   and invoice_id = fact.invoice_id
                                   and release_lookup_code is null;

                                Dka_Tools_Pkg.put_log_message('  ' ||
                                                               SQL%ROWCOUNT ||
                                                               ' blocage(s) réinitialisé(s) ');

                                BEGIN
                                    wf_engine.AbortProcess(itemtype => 'DKA_CSP',
                                                           itemkey  => vv_item_key);
                                    Dka_Tools_Pkg.put_log_message(' workflow ' ||
                                                                   vv_item_key ||
                                                                   ' annulé ');
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        Dka_Tools_Pkg.put_log_message('Erreur annulation wkf : DKA_CSP / ' ||
                                                                       vv_item_key ||
                                                                       ' : ' ||
                                                                       SQLERRM);
                                END;
                                vv_item_key := va_item_key_unique.NEXT(vv_item_key);
                            END LOOP;
                        END IF; -- IF va_item_key.COUNT != 0 THEN
                    END IF;
                ELSE
                    -- IF  vn_nb_lignes_non_rapprochées = 0 then
                    Dka_Tools_Pkg.put_log_message(' facture ' ||
                                                   fact.invoice_id ||
                                                   ' non totalement rapprochée ');
                    update ap_holds_all ah
                       set release_lookup_code = 'APPROVED',
                           release_reason      = 'Facture totalement imputée',
                           last_update_date    = sysdate,
                           last_updated_by     = nvl(fnd_global.user_id,
                                                     vn_user_exploit)
                     where invoice_id = fact.invoice_id
                       and hold_lookup_code = 'Commande inconnue'
                       and release_lookup_code is null
                    returning attribute2 bulk collect into va_item_key;

                    Dka_Tools_Pkg.put_log_message('  ' ||
                                                   to_char(SQL%ROWCOUNT) ||
                                                   ' blocage(s) levé(s) ');
                    IF va_item_key.COUNT != 0 THEN
                        -- on insere les item_keys dans un tableau indexé pour supprimer les doublons
                        FOR i IN va_item_key.FIRST .. va_item_key.LAST LOOP
                            IF va_item_key(i) is not null and
                               (va_item_key_unique.COUNT = 0 OR NOT
                                 va_item_key_unique.EXISTS(va_item_key(i))) THEN
                                Dka_Tools_Pkg.put_log_message(' ajout dans unique  ' ||
                                                               va_item_key(i));
                                va_item_key_unique(va_item_key(i)) := va_item_key(i);
                            END IF;
                        END LOOP;

                        vv_item_key := va_item_key_unique.FIRST;
                        WHILE vv_item_key IS NOT NULL LOOP
                            -- reinit des blocages divers
                            update ap_holds_all ah
                               set attribute1       = null,
                                   attribute2       = null,
                                   last_update_date = sysdate,
                                   last_updated_by  = nvl(fnd_global.user_id,
                                                          vn_user_exploit)
                             where attribute2 = vv_item_key
                               and attribute1 = 'DKA_CSP'
                               and invoice_id = fact.invoice_id
                               and release_lookup_code is null
                                  -- blocages divers uniquement
                               and ah.hold_LOOKUP_CODE <>
                                   cv_ano_ecart_prix
                               and ah.hold_LOOKUP_CODE <> cv_ano_cmd_multi
                               and ah.hold_LOOKUP_CODE <> cv_ano_cmd_multi
                               and ah.hold_LOOKUP_CODE <> cv_ano_cmd_multi
                               and ah.hold_LOOKUP_CODE <>
                                   cv_ano_cmd_multi2
                               and ah.hold_LOOKUP_CODE <>
                                   cv_ano_cmd_multi3
                               and ah.hold_LOOKUP_CODE <> cv_ano_qty_rec
                               and ah.hold_LOOKUP_CODE <> cv_ano_qty_ord
                               and ah.hold_LOOKUP_CODE <> cv_ano_prlv_abs
                               and ah.hold_LOOKUP_CODE <> cv_ano_affact
                               and ah.hold_LOOKUP_CODE <> cv_ano_rib
                               and ah.hold_LOOKUP_CODE <>
                                   cv_ano_bon_apayer
                               and ah.hold_LOOKUP_CODE <>
                                   cv_ano_imput_attente;

                            Dka_Tools_Pkg.put_log_message('  ' ||
                                                           to_char(SQL%ROWCOUNT) ||
                                                           ' blocage(s) réinitialisé(s) ');
                            -- reponse a la notif diverse
                            begin
                                select notification_id
                                  into vn_notif_a_fermer
                                  from wf_notifications wn
                                 where wn.message_type = 'DKA_CSP'
                                   and message_name =
                                       'DKA_MSG_CSP_ANO_DIVERS'
                                   and context like
                                       'DKA_CSP:' || vv_item_key || '%'
                                   and status = 'OPEN';

                                fermeture_notif_diverse(vn_notif_a_fermer,
                                                        nvl(fnd_global.user_id,
                                                            vn_user_exploit));
                            exception
                                when no_data_found then
                                    Dka_Tools_Pkg.put_log_message(' Pas de notif de type divers a fermer pour item_key ' ||
                                                                   vv_item_key);
                            end;
                            vv_item_key := va_item_key_unique.NEXT(vv_item_key);
                        END LOOP;
                    END IF; --IF va_item_key.COUNT != 0 THEN
                END IF; -- IF  vn_nb_lignes_non_rapprochées = 0 then
            END IF; --IF vv_too_many_orders=FALSE THEN
        END LOOP;
        commit;
    END gestion_deblocage_variance;

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
    PROCEDURE batch_traite_factures(pv_errbuf   OUT VARCHAR2,
                                    pn_retcode  IN OUT NUMBER,
                                    pv_CSP      IN VARCHAR2,
                                    pv_division IN VARCHAR2) IS
        vv_errbuf   varchar2(1000);
        vn_retcode  number := 0;
        vn_blocages number;
        vn_CSP      number;

        CURSOR c_facture_oi IS
            select aii.invoice_id
              from ap_invoices_interface aii
             where aii.GLOBAL_ATTRIBUTE2 is null -- workflow non deja en cours
               and aii.status = 'REJECTED'
               and aii.source like 'SCAN%'
               and (invoice_type_lookup_code = 'STANDARD' or
                   invoice_type_lookup_code = 'CREDIT')
               and doc_category_code not like '%REPRISE%'
               and nvl(aii.description, 'OK') not like '%*ERREUR REGION%'
               and exists
             (SELECT 1
                      FROM dka_stransco_headers      dsh,
                           dka_stransco_lines        dsl,
                           hr_all_organization_units hou
                     WHERE dsl.return_value = nvl(pv_CSP, dsl.return_value)
                       AND dsl.param1_value =
                           nvl(pv_division, dsl.param1_value)
                       AND dsh.Set_Id = dsl.set_id
                       AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                       and hou.organization_id = aii.org_id
                       and dsl.param1_value = hou.attribute10
                       and dsl.start_date <= trunc(sysdate)
                       and nvl(dsl.end_date, trunc(sysdate)) >= trunc(sysdate)
                       and dsl.param2_value = substr(hou.name, 1, 3) )
               and (exists -- exists invoice image
                    (select 1
                       from fnd_attached_documents fad,
                            fnd_documents          fd,
                            fnd_document_datatypes fdd,
                            fnd_documents_tl       fdt
                      where fad.entity_name = 'AP_INVOICES_INTERFACE'
                        and fad.document_id = fd.document_id
                        and fd.category_id = 1
                        and fd.datatype_id = fdd.datatype_id
                        and fdd.language = 'F'
                        and fdd.user_name = 'Fichier'
                        and fdt.language = 'F'
                        and fad.document_id = fdt.document_id
                        and fd.document_id = fdt.document_id
                        and fdt.description = 'IMAGE FACTURE'
                        and fad.pk1_value = to_char(aii.invoice_id)) or
                    exists -- part of excluded legal entities
                    (select 1
                       --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
                       from DKA_STRANSCO_HEADERS DSH, DKA_STRANSCO_LINES DSL, hr_all_organization_units hou
                      where dsh.set_name = 'DKA_STES_EXCLUES'
                        and dsh.set_id = dsl.set_id
                        and hou.organization_id = aii.org_id
                        and dsl.param1_value = hou.attribute10
                        and ((dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value IS NULL)
                            or (dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value = substr(hou.name,1,3)))));
                        --and dsl.param1_value =
                        --    nvl(aii.attribute15,
                        --        substr(aii.doc_category_code, 1, 4))
                        --and dsl.return_value = to_char(aii.org_id)));

        CURSOR c_facture_ap IS
            SELECT ai.invoice_id,
                   ai.vendor_site_id,
                   ai.invoice_type_lookup_code,
                   ai.org_id,
                   ai.doc_category_code,
                   ai.source,
                   ai.attribute9,
                   ai.pay_group_lookup_code -- AFE : TASK0159118
              FROM ap_invoices_all ai
             WHERE
            --    ai.wfapproval_status = 'REQUIRED'
             ai.wfapproval_status <> 'NOT REQUIRED'
             AND ai.wfapproval_status <> 'WFAPPROVED'
             and exists --MT
             (SELECT 1
                FROM dka_stransco_headers      dsh,
                     dka_stransco_lines        dsl,
                     gl_code_combinations      gcc,
                     hr_all_organization_units hou
               WHERE dsl.return_value = nvl(pv_CSP, dsl.return_value)
                 AND dsl.param1_value = nvl(pv_division, dsl.param1_value)
                 AND ai.accts_pay_code_combination_id =
                     gcc.code_combination_id
                 AND dsl.param2_value = gcc.segment2
                 AND hou.organization_id = ai.org_id
                 AND dsl.param1_value = hou.attribute10
                 AND dsh.set_id = dsl.set_id
                 AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                 AND dsl.start_date <= trunc(sysdate)
                 AND nvl(dsl.end_date, trunc(sysdate)) >= trunc(sysdate))
            ;


        CURSOR c_facture_ap_hcsp IS
            SELECT ai.invoice_id,
                   ai.vendor_site_id,
                   ai.invoice_type_lookup_code,
                   ai.org_id,
                   ai.doc_category_code
              FROM ap_invoices_all ai
             WHERE
             ai.wfapproval_status <> 'NOT REQUIRED'
             AND ai.wfapproval_status <> 'WFAPPROVED'
             and not exists
             (SELECT 1
                FROM dka_stransco_headers      dsh,
                     dka_stransco_lines        dsl,
                     gl_code_combinations      gcc,
                     hr_all_organization_units hou
               WHERE dsl.return_value = nvl(pv_CSP, dsl.return_value)
                 AND dsl.param1_value = nvl(pv_division, dsl.param1_value)
                 AND ai.accts_pay_code_combination_id =
                     gcc.code_combination_id
                 AND dsl.param2_value = gcc.segment2
                 AND hou.organization_id = ai.org_id
                 AND dsl.param1_value = hou.attribute10
                 AND dsh.set_id = dsl.set_id
                 AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                 AND dsl.start_date <= trunc(sysdate)
                 AND nvl(dsl.end_date, trunc(sysdate)) >= trunc(sysdate))
             and not exists
             (SELECT 1
                FROM dka_stransco_headers      dsh,
                     dka_stransco_lines        dsl,
                     gl_code_combinations      gcc,
                     hr_all_organization_units hou
               WHERE dsl.param1_value = nvl(pv_division, dsl.param1_value)
                 AND ai.accts_pay_code_combination_id =
                     gcc.code_combination_id
                 AND dsl.param2_value = gcc.segment2
                 AND hou.organization_id = ai.org_id
                 AND dsl.param1_value = hou.attribute10
                 AND dsh.set_id = dsl.set_id
                 AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                 AND dsl.start_date <= trunc(sysdate)
                 AND nvl(dsl.end_date, trunc(sysdate)) >= trunc(sysdate))
             and org_id = fnd_profile.VALUE('ORG_ID');

        TYPE t_facture_oi IS TABLE OF ap_invoices_interface.invoice_id%TYPE INDEX BY BINARY_INTEGER;
        vt_facture_oi t_facture_oi;

        TYPE t_invoice_id_ap IS TABLE OF ap_invoices_all.invoice_id%TYPE INDEX BY BINARY_INTEGER;
        TYPE t_vendor_site_id_ap IS TABLE OF ap_invoices_all.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
        TYPE t_invoice_type_lookup_code_ap IS TABLE OF ap_invoices_all.invoice_type_lookup_code%TYPE INDEX BY BINARY_INTEGER;
        TYPE t_org_id_ap IS TABLE OF ap_invoices_all.org_id%TYPE INDEX BY BINARY_INTEGER;
        TYPE t_doc_category_code_ap IS TABLE OF ap_invoices_all.doc_category_code%TYPE INDEX BY BINARY_INTEGER;
        TYPE t_source_ap IS TABLE OF ap_invoices_all.source%TYPE INDEX BY BINARY_INTEGER;
        TYPE t_attribute9_ap IS TABLE OF ap_invoices_all.attribute9%TYPE INDEX BY BINARY_INTEGER;
        TYPE t_pay_group_lookup_code_ap IS TABLE OF ap_invoices_all.pay_group_lookup_code%TYPE INDEX BY BINARY_INTEGER; -- AFE : TASK0159118

        vt_invoice_id_ap               t_invoice_id_ap;
        vt_vendor_site_id_ap           t_vendor_site_id_ap;
        vt_invoice_type_lookup_code_ap t_invoice_type_lookup_code_ap;
        vt_org_id_ap                   t_org_id_ap;
        vt_doc_category_code_ap        t_doc_category_code_ap;
        vt_source_ap                   t_source_ap;
        vt_attribute9_ap               t_attribute9_ap;
        vt_pay_group_lookup_code_ap    t_pay_group_lookup_code_ap; -- AFE : TASK0159118

        vn_blocages_non_initialises    number;
        vv_attribute1                  ap_invoices_all.attribute1%type;
        vv_attribute14                 ap_invoices_all.attribute14%type;
        vv_exclude_count               number := 0;
        vv_image_count                 number := 0;
        vv_image_check_pass            boolean := TRUE;

    vn_exist_lines  NUMBER := 0; -- OBE artf2899273
    BEGIN

        -- boucle sur les factures rejetees par OI
        --    et non encore traitées par une instance du workflow (GLOBAL_ATTRIBUTE2 vide )
        Dka_Tools_Pkg.put_log_message('1 - Boucle sur les factures rejetees par OI et non encore traitées par une instance du workflow (GLOBAL_ATTRIBUTE2 vide )');
        OPEN c_facture_oi;
        FETCH c_facture_oi BULK COLLECT
            INTO vt_facture_oi;
        CLOSE c_facture_oi;

        IF vt_facture_oi.COUNT > 0 THEN
            FOR i in vt_facture_oi.FIRST .. vt_facture_oi.LAST LOOP
                --lance_workflow_CSP_OI(vv_errbuf, vn_retcode, factureOI.invoice_id );
                lance_workflow_CSP_PL(vv_errbuf,
                                      vn_retcode,
                                      vt_facture_oi(i),
                                      0);
                IF vn_retcode <> 0 then
                    Dka_Tools_Pkg.put_log_message('Retour pour le workflow de la facture ' ||
                                                   vt_facture_oi(i) ||
                                                   ' :  ' || vv_errbuf);
                    IF pn_retcode = 0 then
                        pn_retcode := vn_retcode;
                        pv_errbuf  := vv_errbuf;
                    END IF;
                END IF;
                COMMIT;
            END LOOP;
        END IF;

        Dka_Tools_Pkg.put_log_message('2 - Gestion deblocage variance');
        gestion_deblocage_variance(vv_errbuf,
                                   vn_retcode,
                                   pv_CSP,
                                   pv_division);
        IF vn_retcode <> 0 then
            Dka_Tools_Pkg.put_log_message('Retour pour gestion_deblocage_variance :  ' ||
                                           vv_errbuf);
            IF pn_retcode = 0 then
                pn_retcode := vn_retcode;
                pv_errbuf  := vv_errbuf;
            END IF;
        END IF;
        -- boucle sur les factures rentrées dans AP
        --    (soit venant de l'OI
        --     soit manuelles )

        /*Debut QVA 18/08/2010*/
        IF pv_CSP = 'HORS_CSP' THEN

            Dka_Tools_Pkg.put_log_message('3 - Traitement HORS_CSP');

            OPEN c_facture_ap_hcsp;
            FETCH c_facture_ap_hcsp BULK COLLECT
                INTO vt_invoice_id_ap, vt_vendor_site_id_ap, vt_invoice_type_lookup_code_ap, vt_org_id_ap, vt_doc_category_code_ap;

            CLOSE c_facture_ap_hcsp;

            IF vt_invoice_id_ap.COUNT > 0 THEN
                FOR i in vt_invoice_id_ap.FIRST .. vt_invoice_id_ap.LAST LOOP

                    -- cas HORS CSP => approuve la facture en direct
                    Dka_Tools_Pkg.put_log_message(' facture ' ||
                                                   vt_invoice_id_ap(i) ||
                                                   ' hors CSP : => A approuver ');
                    DKA_SAPIAWIE_pkg.approuve_facture_auto_pl(pn_invoice_id => vt_invoice_id_ap(i));

                    IF vn_retcode <> 0 then
                        Dka_Tools_Pkg.put_log_message('Retour pour le workflow de la facture ' ||
                                                       vt_invoice_id_ap(i) ||
                                                       ' :  ' ||
                                                       vv_errbuf);
                        IF pn_retcode = 0 then
                            pn_retcode := vn_retcode;
                            pv_errbuf  := vv_errbuf;
                        END IF;
                    END IF;

                    COMMIT;
                END LOOP;
            END IF;
            /*Fin QVA 18/08/2010*/
        ELSE

            Dka_Tools_Pkg.put_log_message('3 - Traitement CSP');

            OPEN c_facture_ap;
            FETCH c_facture_ap BULK COLLECT
                INTO vt_invoice_id_ap, vt_vendor_site_id_ap, vt_invoice_type_lookup_code_ap, vt_org_id_ap, vt_doc_category_code_ap, vt_source_ap, vt_attribute9_ap, vt_pay_group_lookup_code_ap;

            CLOSE c_facture_ap;

            IF vt_invoice_id_ap.COUNT > 0 THEN
                FOR i in vt_invoice_id_ap.FIRST .. vt_invoice_id_ap.LAST LOOP

                    SELECT count(1)
                      into vn_blocages_non_initialises
                      FROM ap_holds_all ah
                     WHERE ah.invoice_id = vt_invoice_id_ap(i)
                       AND ah.attribute1 is null
                       AND UPPER(ah.hold_lookup_code) NOT LIKE
                           UPPER('En litige%') -- Pour éviter de lancer le WF pour les fact avec seulement un litige
                       AND rownum < 2;

                    SELECT count(1)
                      into vn_blocages
                      from ap_holds_all ah
                     where ah.invoice_id = vt_invoice_id_ap(i)
                       and ah.release_lookup_code is null;

                    SELECT count(1)
                      into vn_CSP
                      FROM dka_stransco_headers      dsh,
                           dka_stransco_lines        dsl,
                           ap_supplier_sites_all       pvs,
                           hr_all_organization_units hou
                     WHERE dsh.Set_Id = dsl.set_id
                       AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
                       AND hou.organization_id = vt_org_id_ap(i)
                       AND dsl.param1_value = hou.attribute10
                       AND pvs.vendor_site_id = vt_vendor_site_id_ap(i)
                       and pvs.org_id = hou.organization_id
                       AND dsl.param2_value =
                           substr(hou.name, 1, 3)
                       AND dsl.start_date <= trunc(sysdate)
                       AND nvl(dsl.end_date, trunc(sysdate)) >=
                           trunc(sysdate);

                    SELECT attribute1, attribute14
                      into vv_attribute1, vv_attribute14
                      from ap_invoices_all ai
                     where ai.invoice_id = vt_invoice_id_ap(i);

                    --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
                    select count(1)
                      into vv_exclude_count
                      from DKA_STRANSCO_HEADERS DSH,
                           DKA_STRANSCO_LINES   DSL,
                           hr_all_organization_units hou
                     where dsh.set_name = 'DKA_STES_EXCLUES'
                       and dsh.set_id = dsl.set_id
                       and hou.organization_id = vt_org_id_ap(i)
                       and ((dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value IS NULL)
                        or (dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value = substr(hou.name,1,3)));
                       --and dsl.param1_value =
                       --    substr(substr(hou.name, 1, 3), 4, 4)
                       --and dsl.return_value = to_char(vt_org_id_ap(i));

                    vv_image_check_pass := TRUE;

                    IF vv_exclude_count = 0 Then
                        --not in excluded leagal entitiy list
                        IF (vt_source_ap(i) = 'SCAN_XGS' OR
                           vt_source_ap(i) = 'SCAN' OR
                           vt_source_ap(i) = 'Manual Invoice Entry' OR
                           vt_source_ap(i) = 'EDI' OR
                          (vt_source_ap(i) = 'Invoice Gateway' and (vt_attribute9_ap(i) not in ('HAC', 'HAF') OR vt_attribute9_ap(i) is NULL)))
                          AND vt_pay_group_lookup_code_ap(i) <>'EMPLOYE' -- AFE : TASK0159118
                          /* OR
                          (vt_source_ap(i) = 'AMONTS'          and (vt_attribute9_ap(i) not in ('HAC', 'HAF') OR vt_attribute9_ap(i) is NULL)) */ -- JWYC - INC0535674
                          THEN

                            select count(1)
                              into vv_image_count
                              from fnd_attached_documents fad,
                                   fnd_documents          fd,
                                   fnd_document_datatypes fdd,
                                   fnd_documents_tl       fdt
                             where fad.entity_name = 'AP_INVOICES'
                               and fad.document_id = fd.document_id
                               and fd.category_id = 1
                               and fd.datatype_id = fdd.datatype_id
                               and fdd.language = 'F'
                               and fdd.user_name = 'Fichier'
                               and fad.document_id = fdt.document_id
                               and fd.document_id = fdt.document_id
                               and fdt.language = 'F'
                               and fdt.description = 'IMAGE FACTURE'
                               and fad.pk1_value =
                                   to_char(vt_invoice_id_ap(i));

                            IF vv_image_count = 0 THEN
                                vv_image_check_pass := FALSE;
                            END IF;
                        END IF;
                    END IF;

                    IF /*  on ne filtre plus par rapport au type de facture
                                                        ( vt_invoice_type_lookup_code_ap(i) = 'STANDARD'
                                                        OR  vt_invoice_type_lookup_code_ap(i) = 'CREDIT')
                                                        AND*/
                     vn_CSP >= 1 AND
                     vt_doc_category_code_ap(i) NOT LIKE '%REPRISE%' THEN
                        IF (vn_blocages_non_initialises >= 1 OR
                           vv_attribute1 is not null -- blocage venant  de OI
                           OR vv_attribute14 is not null -- blocage venant d'imputation en attente
                           ) AND vv_image_check_pass THEN
                            lance_workflow_CSP_PL(vv_errbuf,
                                                  vn_retcode,
                                                  vt_invoice_id_ap(i),
                                                  1);
                        ELSE

                --< OBE artf2899273

              BEGIN
                  select 1
                into vn_exist_lines
                                from ap_invoices_all a
                                where a.invoice_id = vt_invoice_id_ap(i)
                                and exists (select 1
                                            from  AP_INVOICE_LINES_ALL b
                                            where a.invoice_id = b.invoice_id
                                            );
              EXCEPTION
               WHEN OTHERS THEN
                  vn_exist_lines := 0;
              END;

                --> OBE artf2899273

              -- MTIA - INC0362538 - artf07321575 - Correctif - ne pas approuver la facture si pas d'image facture Valide
                            IF vn_blocages = 0 AND vn_exist_lines = 1 AND vv_image_check_pass THEN -- OBE artf2899273
                                Dka_Tools_Pkg.put_log_message(' facture ' ||
                                                               vt_invoice_id_ap(i) ||
                                                               ' sans blocage restant : => A approuver ');
                                DKA_SAPIAWIE_pkg.approuve_facture_auto_pl(pn_invoice_id => vt_invoice_id_ap(i));

                                for workflows_facture in (select distinct wias.item_type,
                                                                          wias.item_key
                                                            from WF_ITEM_ACTIVITY_STATUSES wias
                                                           where wias.item_type =
                                                                 'DKA_CSP'
                                                             and wias.item_key like
                                                                 vt_invoice_id_ap(i) || '%'
                                                             and wias.activity_status =
                                                                 'ACTIVE') LOOP
                                    BEGIN
                                        wf_engine.AbortProcess(workflows_facture.item_type,
                                                               workflows_facture.item_key,
                                                               null,
                                                               null);
                                        Dka_Tools_Pkg.put_log_message('Workflow ' ||
                                                                       workflows_facture.item_key ||
                                                                       ' annulé');
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                            Dka_Tools_Pkg.put_log_message('Erreur annulation wkf : DKA_CSP / ' ||
                                                                           workflows_facture.item_key ||
                                                                           ' : ' ||
                                                                           SQLERRM);
                                    END;
                                END LOOP;
                            END IF;


                        END IF;
                    ELSE
                        -- cas HORS CSP => approuve la facture en direct
                        Dka_Tools_Pkg.put_log_message(' facture ' ||
                                                       vt_invoice_id_ap(i) ||
                                                       ' hors CSP : => A approuver ');
                        DKA_SAPIAWIE_pkg.approuve_facture_auto_pl(pn_invoice_id => vt_invoice_id_ap(i));
                    END IF;
                    IF vn_retcode <> 0 then
                        Dka_Tools_Pkg.put_log_message('Retour pour le workflow de la facture ' ||
                                                       vt_invoice_id_ap(i) ||
                                                       ' :  ' ||
                                                       vv_errbuf);
                        --IF pn_retcode = 0 then
                        --       pn_retcode := vn_retcode;
                        --       pv_errbuf := vv_errbuf ;
                        --END IF;
                    END IF;

                    COMMIT;

                END LOOP;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pn_retcode := 2;
            pv_errbuf  := 'Erreur exécution : ' || SQLERRM;
    END batch_traite_factures;

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
                                   pv_resultout OUT NOCOPY VARCHAR2) IS

        vv_user_name fnd_user.user_name%type;
        vv_superieur fnd_user.user_name%type;

    BEGIN

        IF (pv_funcmode <> wf_engine.eng_run) THEN

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;
        END IF;

        vv_user_name := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'DKA_ACHETEUR_REGION_COMMANDE');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_ecart_prix, debut  ' || vv_user_name,
                         cn_mode_debug);

        vv_superieur := get_superieur_hierachique(pv_itemtype,
                                                  pv_itemkey,
                                                  vv_user_name);

        IF vv_superieur IS NULL THEN
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        ELSE
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                      avalue   => vv_superieur);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_ecart_prix, fin  ',
                         cn_mode_debug);

    END superieur_ecart_prix;

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
                                         pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_montant_fact  AP_INVOICES_ALL.INVOICE_AMOUNT%TYPE;
        vv_user_name     FND_USER.USER_NAME%TYPE;
        vn_montant_seuil NUMBER;
    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_price_habilitation debut',
                         cn_mode_debug);

        vn_montant_fact := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'DKA_INVOICE_AMOUNT');

        vv_user_name := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'DKA_ACHETEUR_REGION_COMMANDE');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_price_habilitation montant = ' ||
                         vn_montant_fact || ' vv_user_name ' ||
                         vv_user_name,
                         cn_mode_debug);

        pv_resultout := get_habilitation(pv_itemtype,
                                         pv_itemtype,
                                         vv_user_name,
                                         vn_montant_fact);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_price_habilitation fin',
                         cn_mode_debug);

    END employe_price_habilitation;

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
                                  pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_nom_employe                 VARCHAR2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
                l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN


        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
          l_session_resp_id := fnd_global.resp_id;
          l_session_appl_id := fnd_global.resp_appl_id;

          IF (l_session_resp_id = -1) THEN
              l_session_resp_id := NULL;
          END IF;

          IF (l_session_appl_id = -1) THEN
              l_session_appl_id := NULL;
          END IF;

          wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'RESPONSIBILITY_ID',
                              avalue  => l_session_resp_id);

                              wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                              itemkey => pv_itemkey,
                              aname   => 'APPLICATION_ID',
                              avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_PRICE en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_result = 'DKA_REAFFECTATION' and vv_nom_employe is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E050');
                RETURN;
            END IF;

            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REAFFECTATION' THEN
                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => vv_nom_employe);
            ELSE
                -- stocke l'employe qui fait l'action pour debloqueur
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => wf_notification.Responder(vn_nid));
            END IF;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Ecart de prix',
                           vv_commentaires);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_PRICE fin',
                         cn_mode_debug);
    END notif_CSP_ANO_PRICE;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_PRICE
    --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
    --                     anomalie d'écart de prix pour non catalogue
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_PRICE_NC(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_nom_employe                 VARCHAR2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
        -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_PRICE_NC en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_result = 'DKA_REAFFECTATION' and vv_nom_employe is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E050');
                RETURN;
            END IF;

            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REAFFECTATION' THEN
                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => vv_nom_employe);
            ELSE
                -- stocke l'employe qui fait l'action pour debloqueur
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => wf_notification.Responder(vn_nid));
            END IF;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Ecart de prix',
                           vv_commentaires);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_PRICE_NC fin',
                         cn_mode_debug);
    END notif_CSP_ANO_PRICE_NC;

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
                                           pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_nom_employe                 varchar2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_NC_PRICE_INTIATEUR en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_NC_PRICE_INTIATEUR vv_nom_employe = ' ||
                         vv_nom_employe,
                         cn_mode_debug);

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        if (pv_funcmode = 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF /*vv_result = 'DKA_REFUS' and*/
             vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                if vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    return;
                end if;
            end if;
        end if;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_REFUS_ECART_PRIX',
                                          avalue   => vv_commentaires);
            END IF;

            if vv_result in ('DKA_RETRANS') then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => vv_nom_employe);
            end if;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Ecart de prix',
                           vv_commentaires /*,
                                                                           get_full_name(vv_nom_employe)*/);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_NC_PRICE_INTIATEUR fin',
                         cn_mode_debug);
    END notif_CSP_NC_PRICE_INTIATEUR;

    ------------------------------------------------------------------------------------
    --  Nom           : is_catalogue_order
    --  Description   :
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE is_catalogue_order(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                 pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                 pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                 pv_funcmode  IN VARCHAR2,
                                 pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_invoice_id   Ap_holds_all.Invoice_Id%type;
        vn_contract_num po_headers_all.segment1%type;
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;
        end if;

        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');
        BEGIN
          select phag.segment1
            into vn_contract_num
            from ap_holds_all          aha,
                 po_line_locations_all plla,
                 po_lines_all          pla,
                 po_headers_all        pha,
                 po_headers_all        phag
           where aha.line_location_id = plla.line_location_id
             and plla.po_line_id = pla.po_line_id
             and plla.po_header_id = pla.po_header_id
             and HOLD_LOOKUP_CODE in ('PRICE', 'MAX SHIP AMOUNT')
             and aha.invoice_id = vn_invoice_id
             --
             and pla.po_header_id = pha.po_header_id --lien pour commande ouverte global
             and pha.from_header_id = phag.po_header_id
             and nvl(phag.GLOBAL_AGREEMENT_FLAG,'N') = 'Y'
             --
             and pla.line_num =
                 (select min(pla2.line_num)
                    from ap_holds_all          aha2,
                         po_line_locations_all plla2,
                         po_lines_all          pla2
                   where aha2.line_location_id = plla2.line_location_id
                     and plla2.po_line_id = pla2.po_line_id
                     and plla2.po_header_id = pla2.po_header_id
                     and aha2.invoice_id = aha.invoice_id
                     and aha2.HOLD_LOOKUP_CODE in
                         ('PRICE', 'MAX SHIP AMOUNT'))
             and rownum = 1;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vn_contract_num := null;
        END;

        If vn_contract_num is not null then
            pv_resultout := 'COMPLETE:' || 'Y';
        else
            pv_resultout := 'COMPLETE:' || 'N';
        end if;

    END is_catalogue_order;

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
                                  pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_nom_employe                 varchar2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_ACH_ANO_PRICE en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        --    print_wf_message(pv_itemtype, pv_itemkey, 'vv_result = ' || vv_result ||
        --                                       'commentaires = ' ||  vv_commentaires);

        if (pv_funcmode = 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            if vv_result in ('DKA_REAFFECTATION', 'DKA_RETRANS') and
               vv_nom_employe is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E050');
                return;
            ELSIF /*vv_result = 'DKA_REFUS' and*/
             vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;
        end if;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            if vv_result in ('DKA_REAFFECTATION', 'DKA_RETRANS') then
                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => vv_nom_employe);
            end if;

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_REFUS_ECART_PRIX',
                                          avalue   => vv_commentaires);
            END IF;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Ecart de prix',
                           vv_commentaires);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_ACH_ANO_PRICE fin',
                         cn_mode_debug);
    END notif_ACH_ANO_PRICE;

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
                                           pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_nom_employe                 varchar2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_HIERAR_DDEUR_ANO_PRICE en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');
        /*
            vv_nom_employe  :=  wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                          itemkey  => pv_itemkey,
                                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE');

            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'notif_HIERAR_DDEUR_ANO_PRICE vv_nom_employe = ' || vv_nom_employe, cn_mode_debug);
        */

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        --    print_wf_message(pv_itemtype, pv_itemkey, 'vv_result = ' || vv_result ||
        --                                       'commentaires = ' ||  vv_commentaires);

        if (pv_funcmode = 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF /*vv_result = 'DKA_REFUS' and*/
             vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                IF vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    RETURN;
                END IF;
            end if;
        end if;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_REFUS_ECART_PRIX',
                                          avalue   => vv_commentaires);
            END IF;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => vv_nom_employe);
            end if;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Ecart de prix',
                           vv_commentaires /*,
                                                                           get_full_name(vv_nom_employe)*/);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_HIERAR_DDEUR_ANO_PRICE fin',
                         cn_mode_debug);
    END notif_HIERAR_DDEUR_ANO_PRICE;

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
                                    pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      varchar2(100);
        vv_nom_employe                 varchar2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action varchar2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    begin

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        if (pv_funcmode <> wf_engine.eng_run and pv_funcmode <> 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_DDEUR_ANO_PRICE en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        /*    vv_nom_employe  :=  wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                          itemkey  => pv_itemkey,
                                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE');
        */

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_DDEUR_ANO_PRICE vv_nom_employe = ' ||
                         vv_nom_employe,
                         cn_mode_debug);

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');
        --    print_wf_message(pv_itemtype, pv_itemkey, 'vv_result = ' || vv_result ||
        --                                       'commentaires = ' ||  vv_commentaires);

        if (pv_funcmode = 'RESPOND') then
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
            l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF /*vv_result = 'DKA_REFUS' and*/
             vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                if vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    return;
                end if;
            end if;
        end if;

        if (pv_funcmode = wf_engine.eng_run) then

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_REFUS_ECART_PRIX',
                                          avalue   => vv_commentaires);
            END IF;

            if vv_result in ('DKA_RETRANS') then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                -- stocke l'employe vers qui on transfere
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_ACHETEUR_REGION_COMMANDE',
                                          avalue   => vv_nom_employe);
            end if;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Ecart de prix',
                           vv_commentaires /*,
                                                                           get_full_name(vv_nom_employe)*/);
        end if;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_DDEUR_ANO_PRICE fin',
                         cn_mode_debug);
    END notif_DDEUR_ANO_PRICE;

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
    PROCEDURE get_ecart_prix(pv_document_id   in varchar2,
                             pv_display_type  in varchar2,
                             pv_document      in out NOCOPY varchar2,
                             pv_document_type in out NOCOPY varchar2) IS

        CURSOR c_ecart(p_invoice_id NUMBER) IS
            SELECT DISTINCT to_char(pl.line_num) line_num,
                            pha.segment1 num_de_commande,
                            trim(to_char(pl.unit_price, '999999990.90')) prix_commande,
                            trim(to_char(aid.unit_price, '999999990.90')) prix_facture,
                            trim(to_char((aid.unit_price - pl.unit_price),
                                         '999999990.90')) ecart
              FROM ap_holds_all                 ah,
                   po_line_locations_all        pll,
                   po_lines_all                 pl,
                   ap_invoice_distributions_all aid,
                   po_distributions_all         pd,
                   po_headers_all               pha
             WHERE ah.hold_lookup_code = 'PRICE'
               and pha.po_header_id = pl.po_header_id
               and pll.line_location_id = ah.line_location_id
               and pll.po_line_id = pl.po_line_id
               and aid.invoice_id = ah.invoice_id
               and aid.po_distribution_id = pd.po_distribution_id
               and pl.po_line_id = pd.po_line_id
               and ah.invoice_id = p_invoice_id
               and  nvl(reversal_flag,'@@@')!='Y'  --and reversal_flag is null   SFA -- artf07151619
               and aid.unit_price <> pl.unit_price
             ORDER BY pl.line_num;

        vv_item_type      wf_items.item_type%TYPE;
        vv_item_key       wf_items.item_key%TYPE;
        vv_document       VARCHAR2(32000) := '';
        NL                VARCHAR2(1) := fnd_global.newline;
        l_notification_id number;
        vn_invoice_id     number;

    BEGIN
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_ecart_prix  document_id= ' || pv_document_id ||
                         'pv_display_type ' || pv_display_type,
                         cn_mode_debug);

        get_item_info(pv_document_id,
                      vv_item_type,
                      vv_item_key,
                      l_notification_id);

        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_ecart_prix  vv_item_type= ' || vv_item_type ||
                         'vv_item_key ' || vv_item_key,
                         cn_mode_debug);

        vn_invoice_id := substr(vv_item_key,
                                1,
                                instr(vv_item_key, '_') - 1);

        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_ecart_prix  vn_invoice_id= ' ||
                         vn_invoice_id,
                         cn_mode_debug);

        if (pv_display_type = 'text/html') then

            vv_document := NL || NL || '<!-- LIGNE ECART PRIX -->' || NL || NL;
            vv_document := vv_document || '<TABLE ' || L_TABLE_STYLE || '>' || NL;
            vv_document := vv_document || '<TR>' || NL;
            --      vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=25%> </TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=20%>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E068') ||
                           '</TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=20%>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E069') ||
                           '</TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=20%>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E036') ||
                           '</TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=20%>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E037') ||
                           '</TH>' || NL;
            vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE ||
                           ' width=20%>' ||
                           fnd_message.get_string('DKA',
                                                  'DKA_SAPWFCSP_E038') ||
                           '</TH>' || NL;
            vv_document := vv_document || '</TR>' || NL;

            for l in c_ecart(vn_invoice_id) LOOP
                vv_document := vv_document || NL || '<TR>' || NL;
                vv_document := vv_document || NL || '<td ' ||
                               L_TABLE_CELL_CENTER_STYLE || ' >' ||
                               nvl(l.line_num, ' ') || '</td>' || NL;
                vv_document := vv_document || NL || '<td ' ||
                               L_TABLE_CELL_CENTER_STYLE || '>' ||
                               NVL(L.NUM_DE_COMMANDE, ' ') || '</td>' || NL;
                vv_document := vv_document || NL || '<td ' ||
                               L_TABLE_CELL_RIGHT_STYLE || ' >' ||
                               nvl(l.prix_commande, ' ') || '</td>' || NL;
                vv_document := vv_document || NL || '<td ' ||
                               L_TABLE_CELL_RIGHT_STYLE || ' >' ||
                               nvl(l.prix_facture, ' ') || '</td>' || NL;
                vv_document := vv_document || NL || '<td ' ||
                               L_TABLE_CELL_RIGHT_STYLE || ' >' ||
                               nvl(l.ecart, ' ') || '</td>' || NL;
                vv_document := vv_document || '</TR>' || NL;
            end loop;

            vv_document := vv_document || '</TABLE>' || NL;

            pv_document := vv_document;
        elsif (pv_display_type = 'text/plain') then
            pv_document := '';
        end if;
        print_wf_message(vv_item_type,
                         vv_item_key,
                         'get_ecart_prix  end',
                         cn_mode_debug);
    END get_ecart_prix;

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
                                    pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_nom_employe                 VARCHAR2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_REC en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_result = 'DKA_REAFFECTATION' and vv_nom_employe is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E050');
                RETURN;
            END IF;

            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- stocke l'employe vers qui on transfere
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_CHEF_EXPLOT_QTY_REC',
                                      avalue   => vv_nom_employe);

            -- EID20080224_CSP - FACTURES BLOQUEES NE FAISANT PLUS L'OBJET D'UNE NOTIFICATION
            -- c'est bien DKA_APPROVE_ECART_PRIX meme si on est dans QTY_REC, c'est le meme jeu de valeurs
            IF vv_result = 'DKA_APPROVE_ECART_PRIX' THEN
                update ap_holds_all
                   set attribute3 = to_char(vn_nid) || '_' ||
                                    to_char(sysdate, 'DDMMYYYY')
                 where attribute1 = pv_itemtype
                   and attribute2 = pv_itemkey
                   and release_lookup_code is null
                   and hold_lookup_code = cv_ano_qty_rec;
            END IF;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'QTY_REC',
                           vv_commentaires);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_REC fin',
                         cn_mode_debug);
    END notif_CSP_ANO_QTY_REC;

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
                                        pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_nom_employe                 VARCHAR2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_REC en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF /*vv_result = 'DKA_REFUS' and */
             vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_BLOCAGE_QTY_REC',
                                          avalue   => vv_commentaires);
            END IF;
            /*
                  -- stocke l'employe vers qui on transfere
                  wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                            itemkey  => pv_itemkey,
                                            aname    => 'DKA_CHEF_EXPLOT_QTY_REC',
                                            avalue   => vv_nom_employe);
            */
            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'QTY_REC',
                           vv_commentaires);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CHEF_EXPLOT_QTY_REC fin',
                         cn_mode_debug);
    END notif_CHEF_EXPLOT_QTY_REC;

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
                                      pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_nom_employe                 VARCHAR2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        vv_message_name                wf_notifications.message_name%TYPE;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_DDEUR_ANO_QTY_REC en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF /* vv_result = 'DKA_REFUS' and */
             vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                IF vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    RETURN;
                END IF;
            end if;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_BLOCAGE_QTY_REC',
                                          avalue   => vv_commentaires);
            END IF;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                --Recupere le nom de la notification
                SELECT wn.message_name
                  INTO vv_message_name
                  FROM wf_notifications wn
                 WHERE notification_id = vn_nid
                   AND wn.message_type = 'DKA_CSP';

                print_wf_message(pv_itemtype,
                                 pv_itemkey,
                                 'notif_DDEUR_ANO_QTY_REC vv_nom_employe' ||
                                 vv_nom_employe || ' vv_message_name  ' ||
                                 vv_message_name,
                                 cn_mode_debug);

                IF vv_message_name in
                   ('DKA_MSG_FWD_ANO_QTY_REC', 'DKA_MSG_FWD_ANO_QTY_REC2') THEN
                    -- stocke l'employe vers qui on transfere
                    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'DKA_CHEF_EXPLOT_QTY_REC',
                                              avalue   => vv_nom_employe);
                ELSIF vv_message_name in
                      ('DKA_MSG2_ANO_QTY_REC', 'DKA_MSG2_ANO_QTY_REC2') THEN
                    -- stocke l'employe vers qui on transfere
                    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'DKA_ACHETEUR_COMMANDE',
                                              avalue   => vv_nom_employe);
                end if;
            end if;

            -- EID20080224_CSP - FACTURES BLOQUEES NE FAISANT PLUS L'OBJET D'UNE NOTIFICATION
            -- c'est bien DKA_APPROVE_ECART_PRIX meme si on est dans QTY_REC, c'est le meme jeu de valeurs
            IF vv_result = 'DKA_APPROVE_ECART_PRIX' or
               vv_result = 'DKA_SAISIE_RECEPT' THEN
                update ap_holds_all
                   set attribute3 = to_char(vn_nid) || '_' ||
                                    to_char(sysdate, 'DDMMYYYY')
                 where attribute1 = pv_itemtype
                   and attribute2 = pv_itemkey
                   and release_lookup_code is null
                   and hold_lookup_code = cv_ano_qty_rec;
            END IF;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'QTY_REC',
                           vv_commentaires);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_DDEUR_ANO_QTY_REC fin',
                         cn_mode_debug);
    END notif_DDEUR_ANO_QTY_REC;

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
                                    pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_nom_employe                 VARCHAR2(240);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_ORD en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                      'FORWARD_TO_USERNAME_RESPONSE');
        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_result = 'DKA_REAFFECTATION' and vv_nom_employe is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E050');
                RETURN;
            END IF;

            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- stocke l'employe vers qui on transfere
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE',
                                      avalue   => vv_nom_employe);

            -- EID20080224_CSP - FACTURES BLOQUEES NE FAISANT PLUS L'OBJET D'UNE NOTIFICATION
            -- c'est bien DKA_APPROVE_ECART_PRIX meme si on est dans QTY_REC, c'est le meme jeu de valeurs
            IF vv_result = 'DKA_APPROVE_ECART_PRIX' THEN
                update ap_holds_all
                   set attribute3 = to_char(vn_nid) || '_' ||
                                    to_char(sysdate, 'DDMMYYYY')
                 where attribute1 = pv_itemtype
                   and attribute2 = pv_itemkey
                   and release_lookup_code is null
                   and hold_lookup_code = cv_ano_qty_ord;
            END IF;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'QTY_ORD',
                           vv_commentaires);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_ORD fin',
                         cn_mode_debug);
    END notif_CSP_ANO_QTY_ORD;

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
                                           pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        vv_user_name                   VARCHAR2(240);
        vv_nom_employe                 per_all_people_f.full_name%TYPE;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_HIERAR_ACH_ANO_QTY_ORD en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');
        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        vv_user_name := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                RETURN;
            END IF;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                IF vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    RETURN;
                END IF;
            end if;

            /*  IF  vv_result = 'DKA_REFUS' and vv_commentaires is null then
               pv_resultout := wf_engine.eng_error || ':' || fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E051');
               RETURN;
             END IF;
             IF  vv_result = 'DKA_ATTENTE' and vv_commentaires is null then
               pv_resultout := wf_engine.eng_error || ':' || fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E052');
               RETURN;
             END IF;
            */
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_BLOCAGE_QTY_ORD',
                                          avalue   => vv_commentaires);
            END IF;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                -- stocke l'employe vers qui on retransmet
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE',
                                          avalue   => vv_nom_employe);

            end if;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'QTY_ORD',
                           vv_commentaires /*,
                                                                           vv_user_name*/);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_HIERAR_ACH_ANO_QTY_ORD fin',
                         cn_mode_debug);
    END notif_HIERAR_ACH_ANO_QTY_ORD;

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
                                    pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        vv_user_name                   VARCHAR2(240);
        vv_nom_employe                 per_all_people_f.full_name%TYPE;
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
       l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_ACH_ANO_QTY_ORD en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');
        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        vv_user_name := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                RETURN;
            END IF;
            /*  IF  vv_result = 'DKA_REFUS' and vv_commentaires is null then
               pv_resultout := wf_engine.eng_error || ':' || fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E051');
               RETURN;
             END IF;
             IF  vv_result = 'DKA_ATTENTE' and vv_commentaires is null then
               pv_resultout := wf_engine.eng_error || ':' || fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E052');
               RETURN;
             END IF;
            */

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');
                IF vv_nom_employe is null then
                    pv_resultout := wf_engine.eng_error || ':' ||
                                    fnd_message.get_string('DKA',
                                                           'DKA_SAPWFCSP_E050');
                    RETURN;
                END IF;
            end if;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            IF vv_result = 'DKA_REFUS' THEN
                -- stocke le commentaire de refus
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_RAISON_BLOCAGE_QTY_ORD',
                                          avalue   => vv_commentaires);
            END IF;

            if vv_result = 'DKA_RETRANS' then
                vv_nom_employe := wf_notification.GetAttrText(vn_nid,
                                                              'FORWARD_TO_USERNAME_RESPONSE');

                -- stocke l'employe vers qui on retransmet
                wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                          itemkey  => pv_itemkey,
                                          aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE',
                                          avalue   => vv_nom_employe);

            end if;

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'QTY_ORD',
                           vv_commentaires /*,
                                                                          get_full_name(vv_user_name)*/);
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_ACH_ANO_QTY_ORD fin',
                         cn_mode_debug);
    END notif_ACH_ANO_QTY_ORD;

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
                                           pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_montant_fact AP_INVOICES_ALL.INVOICE_AMOUNT%TYPE;
        vv_user_name    FND_USER.USER_NAME%TYPE;
    BEGIN
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_qty_ord_habilitation debut',
                         cn_mode_debug);

        vn_montant_fact := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'DKA_INVOICE_AMOUNT');

        vv_user_name := wf_engine.getItemAttrText(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE');

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_qty_ord_habilitation montant = ' ||
                         vn_montant_fact || ' vv_user_name ' ||
                         vv_user_name,
                         cn_mode_debug);

        pv_resultout := get_habilitation(pv_itemtype,
                                         pv_itemtype,
                                         vv_user_name,
                                         vn_montant_fact);

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'employe_qty_ord_habilitation fin',
                         cn_mode_debug);

    END employe_qty_ord_habilitation;

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
                                pv_resultout OUT NOCOPY VARCHAR2) IS

        vv_user_name fnd_user.user_name%type;
        vv_superieur fnd_user.user_name%type;

    BEGIN

        IF (pv_funcmode <> wf_engine.eng_run) THEN

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;
        END IF;

        vv_user_name := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE');
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_qty_ord, debut  ' || vv_user_name,
                         cn_mode_debug);

        vv_superieur := get_superieur_hierachique(pv_itemtype,
                                                  pv_itemkey,
                                                  vv_user_name);

        IF vv_superieur IS NULL THEN
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        ELSE
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'DKA_HIERAR_ACHETEUR_COMMANDE',
                                      avalue   => vv_superieur);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'superieur_qty_ord, fin  ',
                         cn_mode_debug);

    END superieur_qty_ord;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_CMD_MULT
    --  Description   :   Procedure gérant la notification que reçoit CSP pour une
    --                     anomalie de commande multiple
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_CMD_MULT(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                     pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                     pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                     pv_funcmode  IN VARCHAR2,
                                     pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        vv_destinataire                VARCHAR2(240);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
        l_responder_id      NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_CMD_MULT en pv_funcmode = ' ||
                         pv_funcmode,
                         cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');
        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        vv_destinataire := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_RESP_CSP_ANO');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF /*vv_result = 'DKA_ATTENTE' and*/
             vv_commentaires is null THEN
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                RETURN;
            END IF;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- stocke qui fait l'action
            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'VALIDEUR_CDE_MULTI',
                                      avalue   => wf_notification.Responder(vn_nid));

            -- historise l'action
            insert_history(pv_itemtype,
                           pv_itemkey,
                           vv_result,
                           'Multi-commandes',
                           vv_commentaires,
                           WF_DIRECTORY.GetRoleDisplayName(vv_destinataire));
        END IF;
        print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_CMD_MULT fin',
                         cn_mode_debug);
    END notif_CSP_ANO_CMD_MULT;

    -------------------------------------------------------------------------------------
    --  Nom           : abort_previous_workflow
    --  Description   :   Procedure annulant les workflows précédents sur la facture
    --
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE abort_previous_workflow(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                      pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                      pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                      pv_funcmode  IN VARCHAR2,
                                      pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_invoice_id ap_invoices_all.invoice_id%TYPE;

        CURSOR c_select(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
            SELECT DISTINCT w.item_type, w.item_key
              FROM WF_ITEM_ACTIVITY_STATUSES w
             WHERE w.item_type = pv_itemtype
               AND w.item_key LIKE pn_invoice_id || '%'
               AND w.activity_status != 'COMPLETE'
               AND w.item_key != pv_itemkey;

    BEGIN
        IF (pv_funcmode <> wf_engine.eng_run) THEN
            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;
        END IF;

        --Recuperation de l'id de la facture
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        --Pour tous les wf actifs sur la facture
        FOR l IN c_select(vn_invoice_id) LOOP
            BEGIN
                wf_engine.AbortProcess(itemtype => l.item_type,
                                       itemkey  => l.item_key);
            EXCEPTION
                WHEN OTHERS THEN
                    print_wf_message(pv_itemtype,
                                     pv_itemkey,
                                     'Erreur annulation wkf : ' ||
                                     l.item_type || ' / ' || l.item_key ||
                                     ' : ' || SQLERRM,
                                     cn_mode_debug);
            END;
        END LOOP;

        pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

    EXCEPTION
        WHEN OTHERS THEN
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'Erreur abort_previous_workflow : ' ||
                             SQLERRM,
                             cn_mode_debug);
    END abort_previous_workflow;

    -----------------------------------------------------------------------------------
    --  Nom           : asset_invocie
    --  Description   : Procédure to check whether any of the invoice lines consists asset codes
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup YES/NO
    -------------------------------------------------------------------------------------
    PROCEDURE Asset_invoice(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                            pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                            pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                            pv_funcmode  IN VARCHAR2,
                            pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_asset_lines number;
        vn_invoice_id  ap_invoices_all.invoice_id%type;
    BEGIN
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        select count(1)
          into vn_asset_lines
          from ap_invoices_all              aia,
               ap_invoice_distributions_all aida,
               gl_code_combinations_kfv     gcck,
               hr_all_organization_units    hou
         where aida.invoice_id = aia.invoice_id
           and aida.dist_code_combination_id = gcck.code_combination_id
           and aida.line_type_lookup_code = 'ITEM'
           and substr(gcck.segment3, 1, 1) = '2'
           and aia.invoice_id = vn_invoice_id
           and aia.org_id = hou.organization_id
           and hou.attribute10 in ('PROPRETE', 'TRANSPORT')
           and rownum < 2;

        IF vn_asset_lines = 1 THEN
            pv_resultout := 'COMPLETE:' || 'Y';
        ELSE
            pv_resultout := 'COMPLETE:' || 'N';

        END IF;
    END Asset_invoice;
    -------------------------------------------------------------------------------------
    --  Nom           : add_hold_code
    --  Description   : procedure to add hold code at invoice header level
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --                   Lookup SUCCESS/FAIL
    -------------------------------------------------------------------------------------
    PROCEDURE add_hold_code(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                            pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                            pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                            pv_funcmode  IN VARCHAR2,
                            pv_resultout OUT NOCOPY VARCHAR2) IS
        vn_hold_code  Varchar2(5) := '99';
        vn_attribute1 varchar2(20);
        vn_invoice_id ap_invoices_all.invoice_id%type;
    BEGIN
        vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'INVOICE_ID');

        select attribute1
          into vn_attribute1
          from ap_invoices_all
         where invoice_id = vn_invoice_id;

        IF vn_attribute1 is null then
            vn_attribute1 := vn_hold_code;
        ELSE
            vn_attribute1 := vn_attribute1 || '.' || vn_hold_code;
        END IF;

        update ap_invoices_all
           set attribute1 = vn_attribute1
         where invoice_id = vn_invoice_id;

        wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'BLOCAGES_XEROX',
                                  avalue   => vn_attribute1);

        pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';

    EXCEPTION
        WHEN OTHERS THEN
            pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
            print_wf_message(pv_itemtype,
                             pv_itemkey,
                             'Erreur add_hold_code : ' || SQLERRM,
                             cn_mode_debug);
    END add_hold_code;

-- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
    PROCEDURE AP_SELECTOR ( -- Added as a part of bug 3540107
      p_itemtype   IN VARCHAR2,
      p_itemkey    IN VARCHAR2,
      p_actid      IN NUMBER,
      p_funcmode   IN VARCHAR2,
      p_x_result   IN OUT NOCOPY VARCHAR2
    ) IS

      -- Context setting revamp <declare variables start>
      l_session_user_id               NUMBER;
      l_session_resp_id               NUMBER;
      l_responder_id      NUMBER;
      l_user_id_to_set      NUMBER;
      l_resp_id_to_set                NUMBER;
      l_appl_id_to_set                NUMBER;
      l_progress        VARCHAR2(1000);
      l_preserved_ctx                 VARCHAR2(5):= 'TRUE';
      l_org_id        NUMBER;
      l_is_supplier_context           VARCHAR2(10); -- Bug 6144768
      -- Context setting revamp <declare variables end>

    BEGIN
       --Context setting revamp <start>

    -- <debug start>
       print_wf_message(p_itemtype,
                         p_itemkey,
                         'AP_SELECTOR called with mode: '||p_funcmode,
                         cn_mode_debug);
    -- <debug end>


       l_org_id := wf_engine.getitemattrnumber (
                            itemtype => p_itemtype,
                                            itemkey  => p_itemkey,
                                            aname    => 'DKA_ORG_ID');

       l_session_user_id := fnd_global.user_id;
       l_session_resp_id := fnd_global.resp_id;

        IF (l_session_user_id = -1) THEN
            l_session_user_id := NULL;
        END IF;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

       l_responder_id :=  wf_engine.getitemattrnumber(
                                       itemtype => p_itemtype,
                                       itemkey  => p_itemkey,
                                       aname    => 'RESPONDER_USER_ID');

    --<debug start>
       l_progress :='010 selector fn - sess_user_id:'||l_session_user_id
                ||' ses_resp_id '||l_session_resp_id||' responder id '
            ||l_responder_id;

       print_wf_message(p_itemtype,
                     p_itemkey,
                     l_progress,
                     cn_mode_debug);
    --<debug end>



       IF (p_funcmode = 'TEST_CTX') THEN
         l_progress := 'POREQ_SELECTOR: inside Test Ctx ';
         print_wf_message(p_itemtype,
                          p_itemkey,
                          l_progress,
                          cn_mode_debug);

         -- we cannot afford to run the wf without the session user, hence
         -- always set the ctx if session user id is null.
         if (l_session_user_id is null) then
           p_x_result := 'NOTSET';
           return;
         else
           if (l_responder_id is not null) then
             if (l_responder_id <> l_session_user_id) then
                p_x_result := 'FALSE';
                return;
             else
               if (l_session_resp_id is Null) then
                  p_x_result := 'NOTSET';
                  return;
               else
               -- if the selector fn is called from a background ps/
               -- notif mailer then force the session to use preparer's or responder
               -- context. This is required since the mailer/bckgrnd ps carries the
               -- context from the last wf processed and hence even if the context values
               -- are present, they might not be correct.

              if (wf_engine.preserved_context = TRUE) then
                     p_x_result := 'TRUE';
              else
                 p_x_result:= 'NOTSET';
              end if;

               -- introduce an org context setting call here-
               -- required in the case when the right resonder makes a response
               -- from a NON-PO RESP.
              IF l_org_id is NOT NULL THEN
                     PO_MOAC_UTILS_PVT.set_org_context(l_org_id) ;
                  END IF;

              return;
                   end if;
            end if;
         else
                -- always setting the ctx at the start of the wf
            p_x_result := 'NOTSET';
            return;
         end if;
          end if;  -- l_session_user_id is null

       ELSIF (p_funcmode = 'SET_CTX') THEN
       if l_responder_id is not null then
          l_user_id_to_set := l_responder_id;
          l_resp_id_to_set :=wf_engine.GetItemAttrNumber (
                                 itemtype  => p_itemtype,
                                              itemkey  => p_itemkey,
                                                    aname  => 'RESPONDER_RESP_ID');
          l_appl_id_to_set :=wf_engine.GetItemAttrNumber (
                                 itemtype  => p_itemtype,
                                              itemkey  => p_itemkey,
                                                    aname  => 'RESPONDER_APPL_ID');
    --<debug start>
          l_progress := '020 selection fn responder id not null';
          print_wf_message(p_itemtype,
                           p_itemkey,
                           l_progress,
                           cn_mode_debug);
    --<debug end>

    --<debug start>
           l_progress :='030 selector fn : setting user id :'||l_responder_id
                    ||' resp id '||l_resp_id_to_set||' l_appl id '||l_appl_id_to_set;
           print_wf_message(p_itemtype,
                           p_itemkey,
                           l_progress,
                           cn_mode_debug);
    --<debug end>

       else
          l_user_id_to_set := wf_engine.GetItemAttrNumber (
                                 itemtype  => p_itemtype,
                                              itemkey  => p_itemkey,
                                                    aname  => 'USER_ID');
          l_resp_id_to_set := wf_engine.GetItemAttrNumber (
                                 itemtype  => p_itemtype,
                                              itemkey  => p_itemkey,
                                                    aname  => 'RESPONSIBILITY_ID');
          l_appl_id_to_set := wf_engine.GetItemAttrNumber (
                                 itemtype  => p_itemtype,
                                              itemkey  => p_itemkey,
                                                    aname  => 'APPLICATION_ID');
    --<debug start>
          l_progress := '040 selector fn responder id null';
          print_wf_message(p_itemtype,
                           p_itemkey,
                           l_progress,
                           cn_mode_debug);
    --<debug end>

    --<debug start>
          l_progress := '050 selector fn : set user '||l_user_id_to_set||' resp id '
                    ||l_resp_id_to_set||' appl id '||l_appl_id_to_set;
          print_wf_message(p_itemtype,
                           p_itemkey,
                           l_progress,
                           cn_mode_debug);
    --<debug end>
       end if;

       fnd_global.apps_initialize(l_user_id_to_set, l_resp_id_to_set,l_appl_id_to_set);

       -- obvious place to make such a call, since we are using an apps_initialize,
       -- this is required since the responsibility might have a different OU attached
       -- than what is required.

       IF l_org_id is NOT NULL THEN
          PO_MOAC_UTILS_PVT.set_org_context(l_org_id) ;
       END IF;

       END IF;
    -- Context setting revamp <end>

    EXCEPTION

      WHEN OTHERS THEN

        print_wf_message(p_itemtype,
                         p_itemkey,
                         'Exception in Selector',
                         cn_mode_debug);

        WF_CORE.context('DKA_SAPWFCSP_PKG',
                        'AP_SELECTOR',
                        p_itemtype,
                        p_itemkey,
                        p_actid,
                        p_funcmode);
        RAISE;

    END AP_SELECTOR;


END DKA_SAPWFCSP_pkg; -- Corps du package


/

SHOW ERRORS
