SET VERIFY OFF;

CREATE OR REPLACE PACKAGE DKA_SAPGETIMG_WF_PKG
AS
   
----------------------------------------------------------------------------------------------
-- $Id: DKA_SAPGETIMG_WF_PKG.pks 434 2008-04-10 08:38:15Z CORP\jjardez $
-- CAPGEMINI
-- PROJET            : VEOLIA Oracle Applications
-- NOM               : DKA_SAPGETIMG_WF_PKG.pks
-- DESCRIPTION       : DKA_SAPGETIMG_WF_PKG package spec Création des liens url pour la 
--                          visualisation des images dans le WF AP 
-- AUTEUR            : CDE (CAPGEMINI)
-- DATE DE CREATION  : 06/03/2008
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
-- HISTORIQUE  DES MODIFICATIONS
-- Date        Qui Description
-- ----------- --- -------------------------------------------------------------------------
-- 2016/07/05 JJA Portage Helios R12
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-------------------------------------------------------------------------------------------------------------------
--  Nom           : get_url_image_facture
--  Description   : renvoie l'URL permettant d'ouvrir l'image des factures AP ou en rejet dans l'OI
--
--  PARAMETRES    :
--    pn_invoice_id      number 
--  VALEUR RETOURNEE :
--     url       : varchar2
--        cas particulier : -1 : Aucune image n'est rattachée a cette facture
--                          -2 : Erreur
-------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_facture (pn_invoice_id  IN NUMBER
                                 , pv_entity_type IN VARCHAR2)
        RETURN VARCHAR2;
        
  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : get_url_image_bdc
  --  Description   : renvoie l'URL permettant d'ouvrir le bon de commande
  --
  --  PARAMETRES    :
  --    pn_po_header_id      number 
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  --        cas particulier : -1 : Aucune image n'est rattachée a cette commande
  --                          -2 : Erreur
  -------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_bdc (pn_po_header_id  IN NUMBER)
        RETURN VARCHAR2;
        
  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : GET_URL_IMAGE_FACTURE_IVALUA
  --  Description   : renvoie l'URL permettant d'ouvrir l'image des factures AP ou en rejet dans l'OI IVALUA
  --
  --  PARAMETRES    :
  --    pn_invoice_id      number 
  --    pv_entity_type     varchar2 (AP ou OI)
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  --        cas particulier : -1 : Aucune image n'est rattachée a cette facture
  --                          -2 : Erreur
  -------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_facture_ivalua (pn_invoice_id  IN NUMBER 
                                        , pv_entity_type IN VARCHAR2)
        RETURN VARCHAR2;

  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : get_url_image_bdc_ivalua
  --  Description   : renvoie l'URL permettant d'ouvrir le bon de commande
  --
  --  PARAMETRES    :
  --    pn_po_header_id      number 
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  --        cas particulier : -1 : Aucune image n'est rattachée a cette commande
  --                          -2 : Erreur
  -------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_bdc_ivalua (pn_po_header_id  IN NUMBER)
        RETURN VARCHAR2;
                
END DKA_SAPGETIMG_WF_PKG;
/
SHOW ERRORS;

EXIT
