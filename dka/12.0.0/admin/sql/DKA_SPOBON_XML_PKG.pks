SET VERIFY OFF;
DEFINE package_name = "DKA_SPOBON_XML_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI 
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_XML_PKG.pks
-- DESCRIPTION       : DKA_SPOBON_XML_PKG package spec :
--                     Edition du bon de commande en XML
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 26/03/2013
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procedure principale
--
--  PARAMETRES    :
--    p_order_number        VARCHAR2
--    p_envoi_mail          VARCHAR2
--  VALEUR RETOURNEE : N/A
-------------------------------------------------------------------------------------------------------------------
PROCEDURE main(p_errbuf        OUT NOCOPY VARCHAR2,
               p_retcode       OUT NOCOPY NUMBER,
               p_order_number  IN         VARCHAR2,
               p_envoi_mail    IN         VARCHAR2);
    

END &&package_name;
/

SHOW ERRORS;
EXIT

