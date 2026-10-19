------------------------------------------------------------------------------------
-- $Id: DKA_FND_ATTACHED_DOCUMENTS.ind 2010-05-17 
-- Capgemini
-- PROJET            : DALKIA PUISSANCE4
-- NOM               : DKA_FND_ATTACHED_DOCUMENTS.ind
-- DESCRIPTION       : Création des index de la table FND_ATTACHED_DOCUMENTS.ind
---
--- AUTEUR           : Prema Sagar (Capgemini)
--- DATE DE CREATION : 17/05/2010
--- DOC. ASSOCIEE    : 
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user schema
--                     en lui passant en paramètre :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Password APPS
--                    2- Tablespace des index pour le schéma APPLSYSX
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
---
------------------------------------------------------------------------------------

CONNECT APPS/&1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_FND_ATTACHED_DOCUMENTS_N3
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA_FND_ATTACHED_DOCUMENTS_N3;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_FND_ATTACHED_DOCUMENTS_N3
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA_FND_ATTACHED_DOCUMENTS_N3 ON APPLSYS.FND_ATTACHED_DOCUMENTS (PK1_VALUE)
TABLESPACE &2;

EXIT
