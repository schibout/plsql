CREATE OR REPLACE PACKAGE dka_spowfmaster_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SPOWFMASTER_PKG.pks 263 2007-09-18 08:29:01Z NORDEST\nboussek $
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : DKA_SPOWFMASTER_PKG.pks
  -- DESCRIPTION       : DKA_SPOWFMASTER_PKG package spec :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 04/09/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 08/02/2010 MSL EID20090220 Evol 3-1 : Ajout des procédures liées au lancement du WF des modifications
  --- 25/04/2012 JJA DGE20110030 : Ajout de la procedure : active_desactive_site_four
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
  --  Nom           : lance_approbation
  --  Description   : Lance le workflow d'approbation
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_approbation(itemtype  IN VARCHAR2,
                              itemkey   IN VARCHAR2,
                              actid     IN NUMBER,
                              funcmode  IN VARCHAR2,
                              resultout OUT NOCOPY VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : cree_commande
  --  Description   : Alimente l'open-interface des commandes
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE cree_commande(itemtype  IN VARCHAR2,
                          itemkey   IN VARCHAR2,
                          actid     IN NUMBER,
                          funcmode  IN VARCHAR2,
                          resultout OUT NOCOPY VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : cree_reception
  --  Description   : Réceptionne une commande
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE cree_reception(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : recupere_identifiant_commande
  --  Description   : Procédure récupérant l'identifiant de commande.
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE recup_commande(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2);
  -------------------------------------------------------------------------------------
  --  Nom           : archivage_contrat
  --  Description   : Procédure qui permet d'archiver le contrat modifié.
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE archivage_contrat(itemtype  IN VARCHAR2,
                              itemkey   IN VARCHAR2,
                              actid     IN NUMBER,
                              funcmode  IN VARCHAR2,
                              resultout OUT NOCOPY VARCHAR2);

    -------------------------------------------------------------------------------------
  --  Nom           : diminution_quantite
  --  Description   : Procédure qui permet de vérifier que la quantité des lignes
  --                  n'ont pas diminuer
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE diminution_quantite(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : diminution_quantite_facture
  --  Description   : Procédure qui permet de vérifier que la quantité des lignes
  --                  n'ont pas diminuer
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE diminution_quantite_facture(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : reception_quantite
  --  Description   : Procédure qui permet de vérifier que des quantités n'ont pas été receptionné
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE reception_quantite(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,
                               resultout OUT NOCOPY VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_workflow_maitre
  --  Description   : Lance le workflow Maitre
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_workflow_maitre(p_errbuf     OUT VARCHAR2,
                                  p_retcode    IN OUT NUMBER,
                                  p_id_contrat IN NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_workflow_approbation
  --  Description   : Lance le workflow de la phase d'approbation
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_wf_modif_approbation(p_errbuf     OUT VARCHAR2,
                                       p_retcode    IN OUT NUMBER,
                                       p_id_contrat IN NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_wf_resil_annule
  --  Description   : Lance le workflow de la phase d'approbation
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE lance_wf_resil_annule(p_errbuf     OUT VARCHAR2,
                                       p_retcode    IN OUT NUMBER,
                                       p_id_contrat IN NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : get_montant_imput
  --  Description   : Fonction qui retourne le montant modifié de la ligne
  --
  --  PARAMETRES : pn_contrat_imputation_id : Numéro de la ligne d'imputation
  --
  --  VALEUR RETOURNEE : Montant de la ligne
  --     N/A
  -------------------------------------------------------------------------------------
  FUNCTION get_montant_imput(pn_contrat_imputation_id IN NUMBER)
  RETURN NUMBER ;

  -------------------------------------------------------------------------------------
  --  Nom           : get_montant_presta_unit
  --  Description   : Fonction qui retourne le montant modifié de la ligne lorsque le contrat est une prestation unitaire
  --
  --  PARAMETRES : pn_contrat_imputation_id : Numéro de la ligne d'imputation
  --
  --  VALEUR RETOURNEE : Montant de la ligne
  --     N/A
  -------------------------------------------------------------------------------------
  FUNCTION get_montant_presta_unit(pn_contrat_imputation_id IN NUMBER)
  RETURN NUMBER ;
  
  -------------------------------------------------------------------------------------
  --  Nom           : test_modif_champ
  --  Description   : Fonction qui si le bon de commande doit etre renvoyé par fax
  --
  --  PARAMETRES : pn_commande_id : Id de la commande
  --
  --  VALEUR RETOURNEE : Montant de la ligne
  --     N/A
  -------------------------------------------------------------------------------------
  FUNCTION test_modif_champ(pn_commande_id IN NUMBER,
                            pn_contract_id IN NUMBER)
  RETURN BOOLEAN ;


  -------------------------------------------------------------------------------------
  --  Nom           : controle_statut
  --  Description   : Procédure qui récupère le statut du contrat.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE controle_statut(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : modif_statut_incomplet
  --  Description   : Fonction qui repositionne le statut à REJECTED et FINALLY CLOSED
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE modif_statut_incomplet(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  --------------------------------------------------------------------------------------------------
  --  Nom           : modif_statut_approuve
  --  Description   : Procédure qui modifie le statut de fermeture de l'entête du contrat en CLOSED.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  --------------------------------------------------------------------------------------------------
  PROCEDURE modif_statut_approuve(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : verif_date_resiliation
  --  Description   : Procédure qui détermine si une date de résiliation existe pour un contrat.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE verif_date_resiliation(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : verif_exist_facture
  --  Description   : Procédure qui détermine si une facture existe pour un contrat.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE verif_exist_facture(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : archivage_date_resiliation
  --  Description   : Fonction qui incrémente de 1 la version du contrat et effectue
  --  l'archivage de la nouvelle version.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE archivage_date_resiliation(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : approve_version_commande
  --  Description   : Fonction qui réapprouve manuellement les entêtes de commandes.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE approve_version_commande(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : mise_a_jour_action_noneffec
  --  Description   : Fonction qui met à jour de l'attribut P_ACTION à NON_EFFECTUER
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE mise_a_jour_action_noneffec(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : mise_a_jour_action_resiliation
  --  Description   : Fonction qui met à jour de l'attribut P_ACTION à RESILIER
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE mise_a_jour_action_resiliation(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : mise_a_jour_statut_appro
  --  Description   : Repositionner le contrat dans sa version précédente approuvée pour
  --                  annuler le processus de renouvellement.
  --
  --  PARAMETRES :    paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE mise_a_jour_statut_appro(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -----------------------------------------------------------------------------------------------------
  --  Nom           : action_fermer
  --  Description   : Positionnement du contrat au statut "Fermé" avec le motif "Annulation du contrat"
  --
  --  PARAMETRES : paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -----------------------------------------------------------------------------------------------------
  PROCEDURE action_fermer(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : modif_statut_nouvelle_appro
  --  Description   : Fonction qui repositionne le statut en nouvelle approbation requise
  --                : afin qu'il puisse être à nouveau accessible par le bouton "Modifier"
  --
  --  PARAMETRES : paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE modif_statut_nouvelle_appro(itemtype  IN VARCHAR2,
                         itemkey   IN VARCHAR2,
                         actid     IN NUMBER,
                         funcmode  IN VARCHAR2,
                         resultout OUT NOCOPY VARCHAR2);


  ------------------------------------------------------------------------------------------------------------
  --  Nom           : annuler_commande_sans_facture
  --  Description   : Fonction qui met à jour les tables po_headers_all / po_lines_all / po_line_locations_all
  --                : afin d'annuler la commande au niveau en-tête pour les commande ne possédant
  --                : aucune facture.
  --
  --  PARAMETRES : paramètre obligatoire du workflow.
  --
  --  VALEUR RETOURNEE :
  --     N/A
  ------------------------------------------------------------------------------------------------------------

  PROCEDURE annuler_commande_sans_facture(itemtype  IN VARCHAR2,
                         itemkey   IN VARCHAR2,
                         actid     IN NUMBER,
                         funcmode  IN VARCHAR2,
                         resultout OUT NOCOPY VARCHAR2);


  ----------------------------------------------------------------------------
  --  Nom           : LOG_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   pv_message      texte a imprimer dans le log
  --
  ----------------------------------------------------------------------------
    PROCEDURE log_msg(pv_message in varchar2);


  ----------------------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : Procedure d'initialisation
  --
  --  PARAMETRES :
  --  pv_errbuf   Entree/Sortie          message d'erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------

    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


  -------------------------------------------------------------------------------------
  --  Nom           : GET_MESSAGE
  --  Description   : procedure de recuperation des messages
  --
  --  PARAMETRES    :
  --  pn_header_id IN       identifiant du contrat
  --  pv_entete	   OUT		  message de l'entete
  --  pv_haut_page OUT		  message de haut de page
  --  pv_body	     OUT		  message de corps
  --  pv_pied_page OUT		  message de pied de page
  --  pv_errbuf    IN OUT   message de sortie
  --  pn_retcode   OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  --------------------------------------------------------------------------------------
   PROCEDURE get_message_mail (
		pv_header_id	  IN		 NUMBER,
		pv_action		    IN 	   VARCHAR2,
		pv_entete		    OUT		 VARCHAR2,
		pv_haut_page	  OUT		 VARCHAR2,
		pv_body			    OUT		 VARCHAR2,
		pv_pied_page	  OUT		 VARCHAR2,
    pv_errbuf       OUT    VARCHAR2,
    pn_retcode      OUT    NUMBER
   );


  -------------------------------------------------------------------------------------
  --  Nom           : SEARCH_ID_DESTINATAIRE_MAIL
  --  Description   : Recherche des adresses mails et des noms des destinataires/
  --
  --  PARAMETRES    :
  --
  --	pv_header_id	Identifiant de l'entête
  --	pv_mail_name	Liste des mails et des noms des destinataires concaténés
  --	pv_mail			  Liste des mails des destinataires concaténés
  --	pv_errbuf		  Sortie
  -- 	pn_retcode		Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 1: erreur ou code erreur ORA
  --------------------------------------------------------------------------------------

  PROCEDURE search_id_destinataire_mail (
    pv_header_id  IN  NUMBER,
  pv_entete    IN  VARCHAR2,
  pv_haut_page  IN  VARCHAR2,
  pv_body      IN  VARCHAR2,
  pv_pied_page  IN  VARCHAR2,
  pv_action     IN  VARCHAR2,
    pv_errbuf     OUT VARCHAR2,
    pn_retcode    OUT NUMBER
    );


  -------------------------------------------------------------------------------------
  --  Nom           : SEARCH_MAIL
  --  Description   :
  --
  --  PARAMETRES    :
  --	pv_id_employe	Entree
  --	pv_mail_name	Sortie
  --	pv_mail			  Sortie
  --  pv_errbuf     Sortie
  --  pv_retcode    Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  --------------------------------------------------------------------------------------

   PROCEDURE search_mail (
		pv_id_employe	IN			VARCHAR2,
		pv_mail_name	OUT		VARCHAR2,
		pv_mail			OUT		VARCHAR2,
		pv_errbuf     OUT     	VARCHAR2,
		pn_retcode    OUT     	NUMBER
   );


  -------------------------------------------------------------------------------------
  --  Nom           : CHECK_CONTRAT_AVERT
  --  Description   :
  --
  --  PARAMETRES    :
  --	itemtype	   Entree
  --	itemkey	   	 Entree
  --	actid	   	   Entree
  --  funcmode     Sortie
  --  resultout    Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  --------------------------------------------------------------------------------------

    PROCEDURE mail_notification (itemtype  IN VARCHAR2,
                          itemkey   IN VARCHAR2,
                          actid     IN NUMBER,
                          funcmode  IN VARCHAR2,
                          resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : ENVOI_NOTIF_MAIL
  --  Description   : procedure d'envoi de notification par mail
  --
  --  PARAMETRES    :
  --  pv_entete    	IN       Sujet du courriel
  --  pv_haut_page	IN		   Corps Haut du courriel
  --  pv_body       IN       Corps du courriel
  --  pv_pied_page  IN		   Corps Fin du courriel
  --  pv_mail_name	IN		   Ensemble mail et nom des destinataires
  --  pv_mail		    IN		   Ensemble mail des destinataires
  --  pv_errbuf     IN OUT   message de sortie
  --  pn_retcode    OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------

    PROCEDURE envoi_notif_mail (
		  pv_entete		  IN		 VARCHAR2,
		  pv_haut_page	IN 		 VARCHAR2,
      pv_body       IN     VARCHAR2,
		  pv_pied_page	IN		 VARCHAR2,
		  pv_mail_name	IN		 VARCHAR2,
		  pv_mail			  IN		 VARCHAR2,
      pv_errbuf     OUT    VARCHAR2,
      pn_retcode    OUT    NUMBER
    );


    ------------------------------------------------------------------------------------------------------------
    --  Nom           : active_desactive_site_four
    --  Description   : Procedure qui va activer le site fournisseur s'il est désactivé ou inversemment
    --                :
    --
    --  PARAMETRES : paramètre obligatoire du workflow.
    --
    --  VALEUR RETOURNEE :
    --     N/A
    ------------------------------------------------------------------------------------------------------------

    PROCEDURE active_desactive_site_four(itemtype  IN VARCHAR2,
                                         itemkey   IN VARCHAR2,
                                         actid     IN NUMBER,
                                         funcmode  IN VARCHAR2,
                                         resultout OUT NOCOPY VARCHAR2);

END dka_spowfmaster_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE DKA_SPOWFMASTER_PKG;
EXIT