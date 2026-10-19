------------------------------------------------------------------------------------
-- $Id: DKA_AP_SUPPLIER_SITES_N1.ind 1798 2020-11-11 10:24:06Z CORP\araouf $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_AP_SUPPLIER_SITES_N1.ind
-- DESCRIPTION       : Création des index de la table DKA_AP_SUPPLIER_SITES_N1 
---
--- AUTEUR           : Anas RAOUF (Capgemini)
--- DATE DE CREATION : 11/11/2020
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


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE L'INDEX DKA_AP_SUPPLIER_SITES_N1 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA_AP_SUPPLIER_SITES_N1;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_AP_SUPPLIER_SITES_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA.DKA_AP_SUPPLIER_SITES_N1 ON ap.AP_SUPPLIER_SITES_ALL(ATTRIBUTE4);

EXIT