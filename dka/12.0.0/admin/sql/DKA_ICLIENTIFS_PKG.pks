create or replace PACKAGE DKA_ICLIENTIFS_PKG AS
  -------------------------------------------------------------------------------
  -- CAP GEMINI ERNST AND YOUNG
  -- Projet                : DALKIA Oracle Applications
  -- Auteur              : Bertrand RENAUDIN
  -- Date Création      :
  -- Version livrables : V01
  --------------------------------------------------------------------------------
  -- NOM                  : dka_ICLIENTIFS_PKG.sql
  -- DESCRIPTION       : Package
  --------------------------------------------------------------------------------
  ---------------------------- M O D I F I C A T I O N S -------------------------
  -- Date                : 05/11/2019
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf07233449 - EDB242 - DGE20190012 - OracleR12_Finance_AR_Import factures client_Duplication automatique site client  
  --
  -------------------------------------------------------------------------
  -- Version             : ?
  -- Date                : jeudi 24 juin 2004
  -- Auteur              : SFE
  -- Problème            : Portage spécifique pour migration PHENIX 2004
  -- Solution            : Suppression déclaration DUPL_ADDR
  ------------------------------------------------------------------------------
  ---------------------------- M O D I F I C A T I O N S -------------------------
  -- Version             :
  -- Date                : 03/08/2005
  -- Auteur              : CD
  -- Problème            :
  -- Solution            : Report modif Sopra sur address_exists
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : Initialisation
  --  VALEUR RETOURNEE :
  --     Description       : Initialisation des variables globales par dka_parameter
  ------------------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf  OUT VARCHAR2,
				 pn_retcode OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : PRE_OI
  --  Description   : Traitement execute AVANT l Open Interface
  --                   -initialisation des parametres
  --             -controle des donnees
  --             -affichage des donnees en rejet
  --                   -chargement des tables standard d Open Interface
  ------------------------------------------------------------------------------------
  PROCEDURE pre_OI(pv_errbuf  IN OUT VARCHAR2,
				   pn_retcode OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : IN_OI
  --  Description   : Traitement execute dimport a partir de l Open Interface

  ------------------------------------------------------------------------------------
  PROCEDURE IN_OI(p_errbuf  IN OUT VARCHAR2,
                  p_retcode OUT NUMBER);
  
  -------------------------------------------------------------------------------------
  --  Nom           : POST_OI
  --  Description   : Traitement execute APRES l Open Interface
  --                   -initialisation des parametres
  --             -duplication des sites,fonctions economiques,profiles,relations
  --            par appel a duplicate_addr
  --             -propagation des updates sur les sites dupliques
  ------------------------------------------------------------------------------------
  PROCEDURE post_OI(pv_errbuf  IN OUT VARCHAR2,
					pn_retcode OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : ADDRESS_EXISTS
  --  Description   : Teste l existence de cette adresse dans une societe et un CDG
  --
  --  PARAMETRES    : Reference ANAEL de l adresse
  --            Code Centre de Gestion
  --            Code Societe
  --  VALEUR RETOURNEE :
  --     Description       : booleen
  ------------------------------------------------------------------------------------
  FUNCTION address_exists(pv_orig_ref IN VARCHAR2,
						   p_org_id      IN NUMBER /*, pv_soc IN VARCHAR2*/)
	RETURN BOOLEAN;

  -------------------------------------------------------------------------------------
  --  Nom           : DUPLICATE_ADDR
  --  Description   : Procedure de duplication de site client
  --            Duplique les sites,fonctions economiques,profiles,relations
  --             dans le couple societe/CDG souhaite
  --
  --  RESTRICTION   : Si elle est appelee dans le cadre d un traitement lance dans OA,
  --            ce traitement doit avoir ete lance dans une responsabilite
  --            de la societe nouvellement dupliquee ou dans une
  --            responsabilite sans regles de securite.
  --
  --  PARAMETRES    : Reference ANAEL de l adresse
  --            Code Centre de Gestion cible
  --            Code Societe cible
  --  VALEUR RETOURNEE :
  --     Description       : pv_ret : 0 si ok
  --               pv_errbuf : message d erreur
  ------------------------------------------------------------------------------------
  -- PHENIX 2004: Suppression de: PROCEDURE duplicate_addr ( pv_orig_ref IN VARCHAR2 , pv_cdg IN VARCHAR2 , pv_soc IN VARCHAR2 , pv_errbuf IN OUT VARCHAR2 ,pn_ret IN OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : GET_COLLECTOR_FROM_CUST_CDG
  --  Description   : Retourne un charge de recouvrement pour ce client
  --            et ce centre de gestion
  --            Se base sur la table DKA_ICLIENTIFS_COLLECTORS sinon retourne
  --            un charge de recouvrement par defaut
  --  PARAMETRES    : Reference ANAEL de l adresse
  --            Code Centre de Gestion
  --  VALEUR RETOURNEE :
  --     Description       : identifiant du charge de recouvrement (collector_id)
  ------------------------------------------------------------------------------------
  FUNCTION get_collector_from_cust_cdg(pv_customer_number IN VARCHAR2,
									   p_org_id      IN NUMBER)
	RETURN NUMBER;
  PRAGMA RESTRICT_REFERENCES(get_collector_from_cust_cdg, WNDS); --permet l utilisation dans la clause SELECT

  -------------------------------------------------------------------------------------
  --  Nom           : CUSTOMER_EXISTS
  --  Description   : Teste l existence de ce client
  --
  --  PARAMETRES    : Numero de client
  --
  --  VALEUR RETOURNEE :
  --     Description       : 0 si le client existe, 1 sinon
  ------------------------------------------------------------------------------------
  FUNCTION customer_exists(pv_orig_ref IN VARCHAR2) RETURN NUMBER;
  PRAGMA RESTRICT_REFERENCES(customer_exists, WNDS); --permet l utilisation dans la clause SELECT

  -------------------------------------------------------------------------------------
  --  Nom           : SHOW_REJECTED_RECORDS
  --  Description   : Affiche les enregistrements rejetes (clients + charge de rec.)
  ------------------------------------------------------------------------------------
  PROCEDURE show_rejected_records;

  -- RBE artf2100712
  --------------------------------------------------------------------------------------
  --  Nom           : delete_duplicate_data
  --  Description   : Nettoyage tables de travail : laisser les derniers enregistrements
  --------------------------------------------------------------------------------------
  PROCEDURE delete_duplicate_data (pv_errbuf  OUT VARCHAR2,
                                   pn_retcode OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : pre_import_client
  --  Description   : Duplication des sites non existant liés aux factures client
  ------------------------------------------------------------------------------------
  PROCEDURE pre_import_client(pv_errbuf  IN OUT VARCHAR2,
                              pn_retcode OUT NUMBER);
                              
END DKA_ICLIENTIFS_PKG; -- Spécification du package
/
SHOW ERRORS; 

EXIT
