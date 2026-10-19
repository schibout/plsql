------------------------------------------------------------------------------------
-- $Id: DKA_PO_LINES_TMP.ind $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_PO_LINES_TMP.ind
-- DESCRIPTION       : Création des index de la table specifique DKA_PO_LINES_TMP
---
--- AUTEUR           : R.BELAYACHI (Capgemini)
--- DATE DE CREATION : 05/12/2016
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
PROMPT CREATION DE INDEX PO_LINES_TMP_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX PO_LINES_TMP_N1;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX PO_LINES_TMP_N2
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX PO_LINES_TMP_N2;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX PO_LINES_TMP_N3
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX PO_LINES_TMP_N3;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX PO_LINES_TMP_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX PO_LINES_TMP_N1 ON DKA.PO_LINES_TMP ( DOCUMENT_NUM, LOAD_REQUEST_ID )
TABLESPACE &2 ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX PO_LINES_TMP_N2
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX PO_LINES_TMP_N2 ON DKA.PO_LINES_TMP ( STATUT )   
TABLESPACE &2;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX PO_LINES_TMP_N3
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX PO_LINES_TMP_N3 ON DKA.PO_LINES_TMP ( DOCUMENT_NUM, LINE_NUM )  
TABLESPACE &2;


EXIT
