CREATE OR REPLACE PACKAGE dka_iaploadimg_xerox_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET            : VEOLIA Oracle Applications
  -- NOM               : DKA_IAPLOADIMG_XEROX_PKG.pks
  -- DESCRIPTION       : DKA_IAPLOADIMG_XEROX_PKG package spec :
  --
  -- AUTEUR            : CDE (CAPGEMINI)
  -- DATE DE CREATION  : 04/03/2008
  -- DOC. ASSOCIEE     :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- ---------------------------------------------------------------------------------------------
  --   
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : procédure d'initialisation
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------

    PROCEDURE init (pv_errbuf    IN OUT   VARCHAR2
                  , pn_retcode   OUT      NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : chargement_image
  --  Description   : procédure qui charge une image de facture en table
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE chargement_image(pn_nom_image IN VARCHAR2
                           , pb_existe    OUT BOOLEAN
                           , pn_file_id   OUT NUMBER
                           , pv_errbuf    OUT VARCHAR2
                           , pn_retcode   IN OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : create_attached_doc
  --  Description   : procédure qui crée le document joint
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE create_attached_doc(pv_filename     IN VARCHAR2
                              , pv_entity_name  IN VARCHAR2
                              , pn_invoice_id   IN NUMBER
                              , pn_file_id      IN NUMBER
                              , pv_description  IN VARCHAR2
                              , pv_errbuf       OUT VARCHAR2
                              , pn_retcode      IN OUT NUMBER);


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : delete_attached_doc
  --  Description   : procédure de suppression d'un document joint
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------


  PROCEDURE delete_attached_doc (pn_document_id      IN NUMBER
                               , pv_errbuf           OUT VARCHAR2
                               , pn_retcode          IN OUT NUMBER);


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Stockage_image_facture_AP
  --  Description   : procédure de stockage d'image pour les factures insérées dans AP
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE stockage_image_facture_AP(pv_errbuf  IN OUT VARCHAR2
                                    , pn_retcode OUT NUMBER);
                                     

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Stockage_image_facture_OI
  --  Description   : procédure de stockage des images pour les factures en rejet dans l'open interface
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE Stockage_image_facture_OI(pv_errbuf  IN OUT VARCHAR2
                                    , pn_retcode OUT NUMBER) ;
                                           
                                           
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Purge_document_joint_oi
  --  Description   : procédure de stockage des images pour les factures en rejet dans l'open interface
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE Purge_document_joint_oi (pv_errbuf  IN OUT VARCHAR2
                                   , pn_retcode OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2
               , pn_retcode OUT NUMBER) ;

                                
END dka_iaploadimg_xerox_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE dka_iaploadimg_xerox_pkg;
EXIT
