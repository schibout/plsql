----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOBON_ANNEXE_V.vue
-- DESCRIPTION      : Création de la vue DKA_SPOBON_ANNEXE_V
-- AUTEUR           : Benjamin COUDRIER (CGEY)
-- DATE DE CREATION : 29/12/2014
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SPOBON_ANNEXE_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_SPOBON_ANNEXE_V AS
SELECT Dsa.ORG_ID,
       Dsa.LANGUAGE,
       Dsa.DOCUMENT_ID,
       Dsa.DESCRIPTION,
       Dsa.DATATYPE_ID,
       Dsa.MEDIA_ID,
       Dsa.CREATION_DATE,
       Dsa.CREATED_BY,
       Dsa.LAST_UPDATE_DATE,
       Dsa.LAST_UPDATED_BY
FROM   DKA_SPOBON_ANNEXE Dsa
ORDER BY Dsa.DESCRIPTION;

EXIT;
