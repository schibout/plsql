--------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_FND_DOCUMENTS_N1.ind
-- DESCRIPTION	     : Création index sur table std fnd_documents 
--                     pour optimisation
--
-- AUTEUR            : 
-- DATE DE CREATION  : 
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX dka_fnd_documents_n1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX applsys.dka_fnd_documents_n1
ON applsys.fnd_documents (category_id)
tablespace applsysx
storage ( initial 1M next 1M);

-- Début modif EMA du 25/10/2006 : Le calcul des statistiques devient obsolète
-- analyze table applsys.fnd_documents estimate statistics for columns category_id;
-- Fin modif EMA du 25/10/2006

EXIT;
