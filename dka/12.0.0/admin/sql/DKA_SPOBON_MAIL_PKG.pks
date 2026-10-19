CREATE OR REPLACE PACKAGE dka_spobon_mail_pkg AS
------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_MAIL_PKG.pks
-- DESCRIPTION       : DKA_SPOBON_MAIL_PKG package :
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 30/07/2009
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
------------------------------------------------------------------------------------------

BOUNDARY CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';
FIRST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || BOUNDARY || utl_tcp.CRLF;
LAST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||utl_tcp.CRLF;
MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="'||BOUNDARY || '"';
MAX_LINE_WIDTH PLS_INTEGER := 54;

----------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode      OUT   NUMBER,
        pv_mail_test IN       VARCHAR2
    );

----------------------------------------------------------------------------
--  Nom           : get_po_header_id
--  Description   : Fonction qui renvoie en retour l'Id de la commande
--
--  PARAMETRES :
--
--    VALEUR RETOURNEE :  pv_numero_cde
--
----------------------------------------------------------------------------
    FUNCTION get_po_header_id (
        pv_numero_cde   IN   VARCHAR2
    )
    RETURN NUMBER;

----------------------------------------------------------------------------
--  Nom           : get_po_org_name
--  Description   : Fonction qui renvoie en retour le nom de l'org de la cmd
--
--  PARAMETRES :
--
--    VALEUR RETOURNEE :  pv_numero_cde
--
----------------------------------------------------------------------------
    FUNCTION get_po_org_name (
        pv_id_cde   IN   VARCHAR2
    )
    RETURN VARCHAR2;

----------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du stockage des bons de commande
--
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------

  PROCEDURE main
           (pv_errbuf    IN OUT VARCHAR2,
            pn_retcode      OUT NUMBER,
            pv_mail_test IN     VARCHAR2);         
            
END dka_spobon_mail_pkg;
/
SHOW ERRORS
EXIT
