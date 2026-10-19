CREATE OR REPLACE PACKAGE DKA_SAPGETIMG_AL_PKG
AS

----------------------------------------------------------------------------------------------
-- $Id: DKA_SAPGETIMG_AL_PKG.pks 2772 2009-10-16 09:30:25Z CORP\mslama $
-- CAPGEMINI
-- PROJET            : VEOLIA Oracle Applications
-- NOM               : DKA_SAPGETIMG_AL_PKG.pkb
-- DESCRIPTION       : DKA_SAPGETIMG_AL_PKG package : Création des liens url pour la
--                          visualisation des images provenant d'Aladin
-- AUTEUR            : MSLA (CAPGEMINI)
-- DATE DE CREATION  : 26/06/2009
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
-- HISTORIQUE  DES MODIFICATIONS
-- Date        Qui Description
-- 23/09/2016  PBR Portage du composant (Migration 12.2.4)
-- ----------- --- -------------------------------------------------------------------------

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
--        cas particulier : -1 : Aucune image n'est rattachée à cette facture
--                          -2 : Erreur
-------------------------------------------------------------------------------------------------------------------
FUNCTION get_url_image_facture (pn_invoice_id  IN NUMBER,
                               pv_entity_type IN VARCHAR2,
                               pv_file_name IN VARCHAR2)
RETURN VARCHAR2;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : return_nom_image
--  Description   : Renvoie le nom de l'image de la facture
--
--  PARAMETRES    :
--    pn_id_facture      : number
--  VALEUR RETOURNEE :
--    vn_nom_image       : varchar2
-------------------------------------------------------------------------------------------------------------------
FUNCTION return_nom_image(pn_id_facture NUMBER)
RETURN VARCHAR2;

END DKA_SAPGETIMG_AL_PKG;
/
SHOW ERROR PACKAGE DKA_SAPGETIMG_AL_PKG;
EXIT
