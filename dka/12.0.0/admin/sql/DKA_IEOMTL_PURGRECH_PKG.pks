create or replace PACKAGE DKA_IEOMTL_PURGRECH_PKG AS
------------------------------------------------------------------------
-- $Id: dka_ieomtl_purgrech_pkg.pks
-- Capgemini
-- Nom              : dka_ieomtl_purgrech_pkg.pks
-- Description      : Spécification du package dka_ieomtl_purgrech_pkg
-- Auteur           : F.Siham
-- Date de création : 26/04/2019
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------

-- ---------- --- ------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


 	---------------------------------------------------------------------------------------
	--  Nom           : purge_rech_catalog
	--	Description		:	procedure pour purge de la table temporaire DKA_SICXRECHCAT_HIST
    ----------------------------------------------------------------------------------------

    PROCEDURE purge_rech_catalog (
        P_NB_MOIS_SAUV          IN NUMBER
     );
	 
	 PROCEDURE MAIN (
        p_errbuf    OUT NOCOPY VARCHAR2,
        p_retcode   OUT NOCOPY NUMBER,
        P_NB_MOIS_SAUV IN NUMBER
    );
END DKA_IEOMTL_PURGRECH_PKG;
/
SHOW ERRORS

EXIT;