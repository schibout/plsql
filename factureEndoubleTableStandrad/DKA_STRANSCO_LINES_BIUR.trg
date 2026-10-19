---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		         : DKA_STRANSCO_LINES_u1.ind 
-- DESCRIPTION	     : creation d'un index sur la table dka_stransco_lines
---
--- AUTEUR	         : S BERTHEAS (CGEY)
--- DATE DE CREATION : 20/12/2001
--- DOC. ASSOCIEE    : 
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA
--  PARAMETRES       : 1 : Nom du tablespace des index       
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 13/02/2002 SYB utilisation de start_date au lieu de enable
--------------------------------------------------------------------------------------------

DROP INDEX DKA_STRANSCO_LINES_U1 ;

CREATE UNIQUE INDEX DKA_STRANSCO_LINES_U1 ON 
  DKA_STRANSCO_LINES(set_id asc , params_value, start_date) 
  TABLESPACE &1 ;

SHOW ERRORS;
EXIT;

