SET VERIFY OFF;
DEFINE package_name = "DKA_SPOBON_WF_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS
----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_WF_PKG.pks
-- DESCRIPTION       : DKA_SPOBON_WF_PKG package spec :procedure utiliser dans le workflow
---                     PO Approval
--- AUTEUR           : Bernard HANQUIER (CGEY)
--- DATE DE CREATION : 29/02/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 17/04/2002 BHA Le numero de traitement est positionne sur l'entete de la commande et non plus sur
---                l'entete de la DA + envoi par fax
--- 21/09/2011 CDE DGE20110006 - Ajout de la Procédure is_asset_order
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
   );

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
   );
   
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
   );


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
   );

   PROCEDURE last_approb_da  (
     itemtype     IN       VARCHAR2
    ,itemkey      IN       VARCHAR2
    ,actid        IN       NUMBER
    ,funcmode     IN       VARCHAR2
    ,resultout    OUT      VARCHAR2
   );

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
  PROCEDURE is_ivalua_order(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2);
                           
END &&package_name;
/
SHOW ERRORS;

EXIT
