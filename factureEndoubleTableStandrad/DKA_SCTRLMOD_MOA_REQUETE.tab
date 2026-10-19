CREATE OR REPLACE PACKAGE dka_spaploadimg_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : dka_spaploadimg_pkg.pks
  -- DESCRIPTION       : dka_spaploadimg_pkg package spec :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 10/05/2005
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 22/03/2006 GV  - Optimisation du package
  ---                   * suppression de la procédure verif_document, car elle revient à faire un test d'existence,
  ---                     qui peut être placé directement dans le curseur principal
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
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : verif_document
  --  Description   : procédure qui vérifie si il y a des docuementd attaché sur la facture
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
 -- PROCEDURE verif_document(pn_invoice_id IN NUMBER, pb_existe OUT BOOLEAN, pv_errbuf OUT VARCHAR2, pn_retcode IN OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : charge_image
  --  Description   : procédure qui charge une image de facture en table
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
    PROCEDURE charge_image(pn_invoice IN VARCHAR2, pb_existe OUT BOOLEAN, pn_file_id OUT NUMBER, pv_errbuf OUT VARCHAR2, pn_retcode IN OUT NUMBER);
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : attach_doc_facture
  --  Description   : procédure qui charge une image de facture en table
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE attach_doc_facture (pv_filename IN VARCHAR2, pv_urlname IN VARCHAR2, pn_invoice_id IN NUMBER, pn_file_id IN NUMBER, pv_errbuf OUT VARCHAR2, pn_retcode IN OUT NUMBER);
END dka_spaploadimg_pkg; -- Spécification du package

/
SHOW ERROR PACKAGE dka_spaloading_pkg;
EXIT
