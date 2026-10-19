CREATE OR REPLACE PACKAGE dka_spobon_stocimg_pkg AS
------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_STOCIMG_PKG.pks
-- DESCRIPTION       : DKA_SPOBON_STOCIMG_PKG package :
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 02/03/2007
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
------------------------------------------------------------------------------------------


----------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

----------------------------------------------------------------------------
--  Nom           : get_po_header_id
--  Description   : Fonction qui renvoie en retour l'Id de la commande
--
--  PARAMETRES :
--    
--    VALEUR RETOURNEE :  pv_numero_cde
--  
----------------------------------------------------------------------------
    FUNCTION get_po_header_id (
        pv_numero_cde   IN   VARCHAR2
    )
    RETURN NUMBER;


----------------------------------------------------------------------------
--  Nom           : get_doc_bdc
--  Description   : Procédure permettant de récupérer les info d'un document
--                  attaché de type Bdc s'il existe
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------

    PROCEDURE get_doc_bdc (
        pv_po_header_id   IN   NUMBER,
        pv_media_id       OUT  NUMBER,
        pv_document_id    OUT  NUMBER,
        pv_errbuf      IN OUT  VARCHAR2,
        pn_retcode        OUT  NUMBER        
        );    


---------------------------------------------------------------------------
--  Nom           : chargement_image
--  Description   : procédure qui charge une image de bon de commande en table
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
  PROCEDURE chargement_image
                   (pv_nom_fichier IN  VARCHAR2, 
                    pb_existe      OUT BOOLEAN, 
                    pn_file_id     OUT NUMBER, 
                    pv_errbuf      OUT VARCHAR2, 
                    pn_retcode     IN OUT NUMBER) ;

----------------------------------------------------------------------------
--  Nom           : create_attached_document_bdc
--  Description   : procédure qui crée le document attaché
--
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
  PROCEDURE create_attached_document_bdc
                (pv_filename     IN VARCHAR2, 
                 pn_po_header_id IN NUMBER, 
                 pn_file_id      IN NUMBER, 
                 pv_errbuf       OUT VARCHAR2, 
                 pn_retcode      IN OUT NUMBER); 

----------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du stockage des bons de commande
--
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------

  PROCEDURE main
           (pv_errbuf IN OUT VARCHAR2,
            pn_retcode OUT NUMBER);
            
END dka_spobon_stocimg_pkg;
/

SHOW ERROR

EXIT
