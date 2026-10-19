CREATE OR REPLACE PACKAGE DKA_IAPFACTTDS_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI AMS1
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_IAPFACTTDS_PKG.pks
  -- DESCRIPTION       : DKA_IAPFACTTDS_PKG package spec :
  ---
  --- AUTEUR       : Jerome WYCKAERT (JWYC)
  --- DATE DE CREATION : 24/07/2017
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --
  -- MODIFICATION
  --
  ---------------------------------------------------------------------------------------------------------------
  -- Version     : 1.1
  -- Date        : 23/11/2017 
  -- Auteur      : Maxime EGOT
  -- Description : HELIOS Migration R12
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  TYPE STATUS_COMMENT_TYP IS RECORD(
    STATUS  VARCHAR2(50),
    COMMENT VARCHAR2(250));

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : determination_statut_comm
  --  Description   : Fonction afin de retourner le statut et le commentaire de la facture placée en paramètre

  --  PARAMETRES    :    pn_invoice_id   Entrée           Identifiant de la facture
  --                     pn_fact_ok      Sortie           Flag indiquant si la facture peut-être archivée
  --                     pv_errbuf       Entrée/Sortie    message d'erreur
  --                     pn_retcode      Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE : Type contenant le statut et le commentaire associé
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION determination_statut_comm(pn_invoice_id IN NUMBER,
                                     pn_fact_ok    OUT NUMBER,
                                     pv_errbuf     IN OUT VARCHAR2,
                                     pn_retcode    OUT NUMBER)
    RETURN STATUS_COMMENT_TYP;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : update_factures
  --  Description   : Procédure de mise à jour du statut/commentaire d'une facture déjà existante dans la table de travail

  --  PARAMETRES    :
  --                     pv_errbuf     Entrée/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE update_factures(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insert_factures
  --  Description   : Procédure d'ajout d'une nouvelle facture existante dans la table de travail

  --  PARAMETRES    :
  --                     pv_errbuf     Entrée/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE insert_factures(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insert_factures
  --  Description   : Procédure pour déplacer les nouveaux status/commentaires du traitement précédent
  --                dans les colonnes courantes

  --  PARAMETRES    :
  --                     pv_errbuf     Entrée/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------                                                    
  PROCEDURE reinitialisation_statuts(pv_errbuf  IN OUT VARCHAR2,
                                     pn_retcode OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : archivage_factures
  --  Description   : Procédure d'archivage des factures totalement réglées ou définitivement rejetées

  --  PARAMETRES    :
  --                     pv_errbuf     Entrée/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE archivage_factures(pv_errbuf  IN OUT VARCHAR2,
                               pn_retcode OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : verif_factures_archivees
  --  Description   : Procédure qui vérifie si il n'y a pas eu de modifications sur les factures archivées

  --  PARAMETRES    :
  --                     pv_errbuf     Entrée/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------                             

  PROCEDURE verif_factures_archivees(pv_errbuf  IN OUT VARCHAR2,
                                     pn_retcode OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : creation_fichier
  --  Description   : Procédure de creation du fichier de sortie

  --  PARAMETRES    :
  --                     pv_errbuf     Entrée/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE creation_fichier(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER);

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

END DKA_IAPFACTTDS_PKG;
/
SHOW ERRORS
EXIT;
