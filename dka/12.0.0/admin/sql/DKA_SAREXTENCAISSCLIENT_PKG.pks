CREATE OR REPLACE PACKAGE APPS.DKA_SAREXTENCAISSCLIENT_PKG
AS
---------------------------------------------------------------------------------------------------------------
 -- CAP GEMINI ERNST AND YOUNG
 -- PROJET            : DALKIA Oracle Applications
 -- NOM               : DKA_SAREXTENCAISSCLIENT_PKG.pkb
 -- DESCRIPTION       : Identification des DA saisies dans Oracle sur un périmètre fermé
 --
 --- AUTEUR           : SALOUA HAHIOUI
 --- DATE DE CREATION : 27/10/2023
 --- DOC. ASSOCIEE    :
 -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'

--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------

PROCEDURE Extraction_encaissements_clients
            (pv_errbuf  OUT VARCHAR2,
             pn_retcode OUT NUMBER,
			       pn_date_pivot IN OUT VARCHAR2,
			       pn_nb_lignes_ec    IN OUT NUMBER
            );
PROCEDURE output_end;
PROCEDURE output_header;

    
PROCEDURE main(pv_errbuf          IN  OUT VARCHAR2,
               pn_retcode         IN    OUT NUMBER
               );
END DKA_SAREXTENCAISSCLIENT_PKG;


/

SHOW ERRORS

EXIT
