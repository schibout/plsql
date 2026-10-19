------------------------------------------------------------------------------------
-- $Id: DKA_IAPFACXGS_REPORTING_ALL.ind 1798 2009-04-20 13:24:06Z CORP\mslama $
-- Capgemini
-- PROJET            : DALKIA PUISSANCE4
-- NOM               : DKA_IAPFACXGS_REPORTING_ALL_N1.ind
-- DESCRIPTION       : Création des index de la table DKA_IAPFACXGS_REPORTING_ALL
---
--- AUTEUR           : Mehdi Slama (Capgemini)
--- DATE DE CREATION : 10/12/2009
--- DOC. ASSOCIEE    : 
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user schema
--                     en lui passant en parametre :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en parametres
--                    1- Password DKA
--                    2- Password APPS
--                    3- Tablespace des index pour le schéma DKA
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
---
------------------------------------------------------------------------------------

CONNECT DKA/&1

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE L'INDEX DKA_IAPFACXGS_REPORTING_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA_IAPFACXGS_REPORTING_N1;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_IAPFACXGS_REPORTING_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA_IAPFACXGS_REPORTING_N1 ON DKA_IAPFACXGS_REPORTING_ALL (REFERENCE_LAD)
TABLESPACE &2;

EXIT
