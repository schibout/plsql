-------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- Projet : DALKIA Oracle Applications
-- Auteur : Guilhem LE NEZET
-- Date Création : 12/11/2001
-- Version livrables : V01
--------------------------------------------------------------------------------
-- NOM : dka_cview_sarsurtaxe.sql
-- DESCRIPTION : Script de création de la vue DKA_SARSURTAXE_TMP pour stocker
--               de façon temporaire les informations nécessaires à la création
--               d'une facture.
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW dka_sarsurtaxe_tmp AS
SELECT *
FROM dka_sarsurtaxe_tmp_all
WHERE NVL(ORG_ID,NVL(TO_NUMBER(DECODE(SUBSTR(USERENV('CLIENT_INFO'),1,1), ' ',NULL,SUBSTR(USERENV('CLIENT_INFO'),1,10))), -99)) = NVL(TO_NUMBER(DECODE(SUBSTR(USERENV('CLIENT_INFO'),1,1), ' ',NULL,SUBSTR(USERENV('CLIENT_INFO'),1,10))),-99);

EXIT;
