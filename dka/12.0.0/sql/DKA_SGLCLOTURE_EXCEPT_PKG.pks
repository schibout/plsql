CREATE OR REPLACE PACKAGE DKA_SGLCLOTURE_EXCEPT_PKG AS
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SGLCLOTURE_EXCEPT_PKG
-- DESCRIPTION       : Traitement de fermeture exceptionnelle de GL
---
--- AUTEUR           : Guillaume LEBLON ( TEC ORACLE CGEY )
--- DATE DE CREATION : 20/01/2004
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       :
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure qui enchaine le reste des procedures
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE main (pv_errbuf IN OUT  VARCHAR2,
                pn_retcode   OUT  NUMBER);

---------------------------------------------------------------------------------------------------------------
END DKA_SGLCLOTURE_EXCEPT_PKG; -- Spécification du package
/
exit;
/



