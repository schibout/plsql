create or replace PACKAGE DKA_SAPDUPLICATIONFRS_PKG
AS
------------------------------------------------------------------------
-- $Id: DKA_SAPDUPLICATIONFRS_PKG.pks
-- Capgemini
-- Nom              : DKA_SAPDUPLICATIONFRS_PKG.pks
-- Description      : Spécification du package DKA_SAPDUPLICATIONFRS_PKG
-- Auteur           : SELO
-- Date de création : 07/07/2020
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- fonction pour alimenation de la table temporaire DKA_IEOMTL_SYSTEM_ITEMS_TMP--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

FUNCTION CHARGER_AP_DUPLICA(        
        access_id          IN NUMBER,
        pv_file_id         OUT VARCHAR2,
        pv_message_erreur  OUT VARCHAR2) 
	RETURN VARCHAR2;

END DKA_SAPDUPLICATIONFRS_PKG;

/
SHOW ERRORS
EXIT
