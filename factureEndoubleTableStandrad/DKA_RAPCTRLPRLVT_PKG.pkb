CREATE OR REPLACE PACKAGE XXEAI_INTERFACE_TOOLS_PKG AS
     ----------------------------------------------------------------------------------------------
     -- $ $
     --
     -- NOM               : XXEAI_INTERFACE_TOOLS_PKG.pks
     -- DESCRIPTION       : XXEAI_INTERFACE_TOOLS_PKG package spec : fonctions communes aux interface EAI
     ---
     --- AUTEUR           : Julien Jardez
     --- DATE DE CREATION : 19/05/2014 
     --- DOC. ASSOCIEE    :
     ---
     ----------------------------------------------------------------------------------------------
     --- NOM DU PROGRAMME :
     --- PARAMETRES       :
     ---
     --- HISTORIQUE DES MODIFICATIONS
     --- Date       Qui Description
     --- ---------- --- -------------------------------------------------------------------------
     --  08/09/2014 BCO DPE20140079 - Evolution appel de fonction Banque pour l'EAI
     --  02/12/2014 BCO DPE20140088 - Evolution ajout des outils d'interface pour AP.
	   --  09/01/2015 BCO DPE20140114 - Trésorerie lot 2 - CAMT054 - Impayes Prélèvements clients.
     --  19/09/2016 HDE Modification pour HELIOS
     --  02/01/2016 MEG artf2071034 : ajout 
     --------------------------------------------------------------------------------------------

     -----------------------------------------------------------------
     --  Variables globales
     -----------------------------------------------------------------
     gv_debug_mode VARCHAR2(1);

     -----------------------------------------------------------------
     --  Nom           : Get_Infos_Banque
     --  Description   : Fonction qui retourne dans un objet XXEAI_INFOS_BANQUE_OBJ
     --                  les informations de la banque
     --
     --  PARAMETRES :
     --     pv_IBAN          Entrée      IBAN
     --     po_infos_banque  Sortie      Objet regroupant le code banque,
     --                                  le nom de la banque et le code BIC
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Infos_Banque(pv_IBAN         IN VARCHAR2,
                                po_infos_banque IN OUT NOCOPY XXEAI_INFOS_BANQUE_OBJ);

	 -----------------------------------------------------------------
     --  Nom           : Get_Infos_Banque_Interne
     --  Description   : Fonction qui retourne le nom de la banque interne DALKIA
     --
     --  PARAMETRES :
     --     pv_IBAN          Entrée      IBAN
     --     pv_Banque_Name   Sortie      Nom de la Banque INTERNE Dalkia
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
	PROCEDURE Get_Infos_Banque_Interne(pv_IBAN        IN VARCHAR2,
									   pv_Banque_Name IN OUT NOCOPY VARCHAR2);
	
	 -----------------------------------------------------------------
     --  Nom           : Get_Infos_Rejets_Sepa 
     --  Description   : Fonction qui retourne le nom de la banque interne DALKIA
     --
     --  PARAMETRES :
     --     pv_IBAN          Entrée      IBAN
     --     pv_Banque_Name   Sortie      Nom de la Banque INTERNE Dalkia
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
	PROCEDURE Get_Infos_Rejets_Sepa(pv_Code_Rejet        IN VARCHAR2,
									pv_Description_Rejet IN OUT NOCOPY VARCHAR2);
	
     -----------------------------------------------------------------
     --  Nom           : Get_Params_FOLIO_GL
     --  Description   : Fonction qui retourne dans un objet XXEAI_CST_FLUX_GL_OBJ
     --                  les valeurs constantes du flux pour les folio déterminé.
     --
     --  PARAMETRES :
     --     pv_FOLIO         Entrée      FOLIO
     --     po_cst_flux_gl   Sortie      Objet regroupant le code erreur, code folio oracle,
     --                  statut, id Livre Comptable, Devise, Type d¿écriture,
     --                  Type de la pièce et l'Origine de la pièce.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Params_FOLIO_GL(pv_FOLIO       IN VARCHAR2,
                                   po_cst_flux_gl IN OUT NOCOPY XXEAI_CST_FLUX_GL_OBJ);

     -----------------------------------------------------------------
     --  Nom           : Get_Societe_Projet
     --  Description   : Fonction qui retourne dans un objet XXEAI_SOCIETE_OBJ
     --                  les informations de la société du projet.
     --
     --  PARAMETRES :
     --     pv_projet    Entrée      projet
     --     po_societe   Sortie      Objet regroupant le code erreur et la société oracle du projet.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Societe_Projet(pv_projet  IN VARCHAR2,
                                  po_societe IN OUT NOCOPY XXEAI_SOCIETE_OBJ);

     -----------------------------------------------------------------
     --  FONCTIONNALITE 4 : DETERMINER LE TYPE DE DEPENSE / EVENEMENT
     --  Nom           : Get_Type_Depense_Evenement
     --  Description   : Fonction qui retourne dans un objet XXEAI_TYP_EVT_DEP_OBJ
     --                  le type de dépense ou d'évènement.
     --
     --  PARAMETRES :
     --     po_dep_evt   Entrée      Objet regroupant le Code PR, le Code produit et le Compte Local
     --     po_societe   Sortie      Objet regroupant le Code erreur et le type de dépense/évènement.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Type_Depense_Evenement(po_dep_evt     IN XXEAI_IN_TYP_EVT_DEP_TYP,
                                          po_typ_evt_dep IN OUT NOCOPY XXEAI_TYP_EVT_DEP_OBJ);

     -----------------------------------------------------------------
     --  Nom           : Get_Cle_Comptable_CUF
     --  Description   : Fonction qui retourne dans un objet XXEAI_CLE_COMPTABLE_CUF_OBJ
     --                  les valeurs de chaque segment de la clé comptable et les champs du CUF
     --          GL pour tous les comptes locaux et selon les règles de chaque folio.
     --
     --  PARAMETRES :
     --     po_info_cle            Entrée      Objet regroupant Folio AMONT, Société de l¿écriture,
     --                      Segmentation (Appartenance), Compte local, Code Partenaire,
     --                      Code projet, Type de dépense ou d¿évènement, Quantité
     --     po_cle_comptable_cuf   Sortie      Objet regroupant Code Erreur, Société, Région, Compte local,
     --                      Compte Groupe, Complément groupe, Centre de coût, Code Affaire,
     --                      Code Activité, Flux, Réserve, Contexte du CUF, Id du projet, Type d¿évènement,
     --                        Type de dépense, Quantité, Id du projet à refacturer
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Cle_Comptable_CUF(po_info_cle          IN XXEAI_INFO_CLE_TYP,
                                     po_cle_comptable_cuf IN OUT NOCOPY XXEAI_CLE_COMPTABLE_CUF_OBJ);

     -----------------------------------------------------------------
     --  Nom           : Get_Societe_Projet_Liste
     --  Description   : Fonction qui retourne dans un objet XXEAI_SOCIETE_LST
     --                  la liste de société du projet à partir d'une liste de code projet.
     --
     --  PARAMETRES :
     --     pt_projet        Entrée      Objet regroupant la liste des codes projet.
     --     po_societe_lst   Sortie      Objet regroupant la liste des codes erreur
     --                  et des sociétés Oracle du projet.
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Societe_Projet_Liste(pt_projet      IN XXEAI_PROJET_TAB,
                                        po_societe_lst IN OUT NOCOPY XXEAI_SOCIETE_LST);

     -----------------------------------------------------------------
     --  FONCTIONNALITE 7 : DETERMINER LE TYPE DE DEPENSE/EVENEMENT EN LISTE
     --  Nom           : Get_Type_Depense_Evt_Liste
     --  Description   : Fonction qui retourne dans un objet XXEAI_TYP_EVT_DEP_OBJ
     --                  une liste de type de dépense ou d'évènement.
     --
     --  PARAMETRES :
     --     pt_in_dep_evt    Entrée      Objet regroupant la liste des codes PR, codes produits et compte local.
     --     po_typ_evt_dep   Sortie      Objet regroupant Code Erreur et la liste des codes erreurs et type de dépense/évènement
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Type_Depense_Evt_Liste(pt_in_dep_evt  IN XXEAI_IN_TYP_EVT_DEP_TAB,
                                          po_typ_evt_dep IN OUT NOCOPY XXEAI_TYP_EVT_DEP_LST);

     -----------------------------------------------------------------
     --  Nom           : Get_Cle_Comptable_CUF_Liste
     --  Description   : Fonction qui retourne dans un objet XXEAI_TYP_EVT_DEP_OBJ
     --                  les valeurs de chaque segment de la cl comptable et les champs du CUF
     --          GL pour tous les comptes locaux et selon les règles de chaque folio.
     --
     --  PARAMETRES :
     --     pt_info_cle            Entrée      Objet regroupant la liste des Folio Amont, société de l'écriture,
     --                      segmentation, compte local, code partenaire, code projet,
     --                      type de dépense/évènement et quantité.
     --     po_cle_comptable_cuf   Sortie      Objet regroupant Code Erreur et la liste des Code Erreur, Société, Région, Compte local,
     --                      Compte Groupe, Complément groupe, Centre de coût, Code Affaire,
     --                      Code Activité, Flux, Réserve, Contexte du CUF, Id du projet, Type d¿évènement,
     --                        Type de dépense, Quantité, Id du projet à refacturer
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Cle_Comptable_CUF_Liste(pt_info_cle          IN XXEAI_INFO_CLE_TAB,
                                           po_cle_comptable_cuf IN OUT NOCOPY XXEAI_CLE_COMPTABLE_CUF_LST);

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 9 : DETERMINER L'IDENTIFIANT DE FACTURE/IDENTIFIANT DE LIGNE DE FACTURE.
     --  Nom           : Get_Invoice_Id
     --  Description   : Fonction qui génère dans un identifiant d'entête ou de ligne.
     --
     --  PARAMETRES :
     --     pv_Type            Entrée      valeur type ENTETE / LIGNE
     --
     --  VALEUR RETOURNEE : po_invoice_id
     --     Description       :  Si pv_Type = ENTETE alors génère l'identifiant de la facture
     --               Si pv_Type = LIGNE alors génère l'identifiant de la ligne de facture.
     --     Valeurs possibles :  Identifiant de l'entête/ligne de facture.
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Invoice_Id(pv_Type       IN VARCHAR2,
                              po_invoice_id IN OUT NOCOPY XXEAI_INVOICE_ID);

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 10 : DETERMINER LES INFORMATIONS POUR UN ENTETE DE FACTURE
     --  Nom           : Get_Info_Invoice_Header
     --  Description   : Fonction qui retourne les informations du fournisseur, le type (encaissement/
     --         décaissement), le nom du groupe de paiement et l'identifiant de la clé comptable
     --           pour l'entête de la facture selon les règles de chaque FOLIO.
     --
     --  PARAMETRES :
     --     pt_in_header    Entrée      Objet contenant la liste des informations suivantes:
     --                     Code Folio Oracle
     --                  Identifiant Fournisseur Externe
     --                  Société
     --                    Appartenance
     --                    Taux de TVA
     --                    Compte Local
     --  VALEUR RETOURNEE : po_info_invoice_header
     --     Description       :  Retourne l'ensemble des informations permettant de compléter l'entête de la facture.
     --     Valeurs possibles :  Identifiant du Fournisseur
     --             Identifiant du site fournisseur
     --               Type (Encaissement / Décaissement)
     --               Nom du groupe de paiement
     --               Identifiant de la clé comptable
     --               Type de document
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Header(pt_in_header           IN XXEAI_IN_INVOICE_HEADER_TYP,
                                       po_info_invoice_header IN OUT NOCOPY XXEAI_INFO_INVOICE_HEADER_OBJ);

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 11 : DETERMINER LES VALEURS CONSTANTES DU FLUX AP
     --  Nom           : Get_Params_FOLIO_AP
     --  Description   : Fonction qui retourne l'ensemble des valeurs constantes du flux pour un folio déterminé.
     --
     --  PARAMETRES :
     --     pv_Folio    Entrée      Code Folio Amont
     --  VALEUR RETOURNEE : po_cst_flux_ap
     --     Description       :  Retourne l'ensemble des constantes du flux.
     --     Valeurs possibles :  Code Erreur
     --             Code devise de la facture
     --               Code folio Oracle
     --               Catégorie de la structure du CUF dépendant de la localisation
     --               Origine de la facture
     --               Type de taux dérivés
     --               Taux dérivés
     --               Devise de règlement
     --               Nom de l'application permettant de déterminer le Type de document.
     --               Identifiant de l'organisation.
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Params_FOLIO_AP(pv_Folio       IN VARCHAR2,
                                   po_cst_flux_ap IN OUT NOCOPY XXEAI_CST_FLUX_AP_OBJ);

     ----------------------------------------------------------------------------------------------------
     --  FONCTIONNALITE 12 : DETERMINER LES INFORMATIONS POUR UNE LIGNE DE FACTURE
     --  Nom           : Get_Info_Invoice_Line
     --  Description   : Fonction qui retourne les informations pour les lignes de facture selon les règles de chaque Folio
     --
     --  PARAMETRES :
     --     pt_info_line    Entrée      Objet contenant la liste des informations suivantes:
     --                     Code FOLIO Oracle
     --                     Code du Projet / Appartenance
     --                     Nature1
     --                     Nature2
     --                     Identifiant Fournisseur Externe
     --                     Société
     --                     Compte Local
     --                     Taux de TVA
     --                     Date Comptable
     --  VALEUR RETOURNEE : po_info_invoice_line
     --     Description       :  Retourne l'ensemble des informations permettant de compléter l'entête de la facture.
     --     Valeurs possibles :  Code erreur
     --                Type de ligne de ventilation
     --                Identifiant de la clé comptable
     --                Catégorie de structure
     --                Identifiant du projet de refacturation
     --                Identifiant du projet
     --                Identifiant de tâche
     --                Type de dépense
     --                Identifiant de l¿organisation de dépense
     --                Code de TAX
     ---------------------------------------------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Line(pt_info_line         IN XXEAI_IN_INVOICE_LINE_TYP,
                                     po_info_invoice_line IN OUT NOCOPY XXEAI_INFO_INVOICE_LINE_OBJ);

     -----------------------------------------------------------------
     --  FONCTIONNALITE 13 : DETERMINER LES INFORMATIONS POUR DES ENTETES DE FACTURE EN LISTE
     --  Nom           : Get_Info_Invoice_Header_Liste
     --  Description   : Fonction qui retourne la liste de valeurs des informations fournisseurs,
     --           les types (encaissement/décaissement), les noms de groupe de paiement et
     --           les identifiants de clé comptable en fonction de la liste de paramètres en entrée.
     --
     --  PARAMETRES :
     --     pt_info_header_tab   Entrée      Objet contenant un tableau d'objet
     --     po_info_header_lst   Sortie      Objet contenant une liste d'objet XXEAI_INFO_INVOICE_HEADER_TAB
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Header_Liste(pt_info_header_tab IN XXEAI_IN_INVOICE_HEADER_TAB,
                                             po_info_header_lst IN OUT NOCOPY XXEAI_INFO_INVOICE_HEADER_LST);

     -----------------------------------------------------------------
     --  FONCTIONNALITE 14 : DETERMINER LES INFORMATIONS POUR LES LIGNES DE FACTURE EN LISTE
     --  Nom           : Get_Info_Invoice_Line_Liste
     --  Description   : Fonction qui retourne la liste de valeurs des informations pour les
     --           lignes de facture en fonction de la liste de paramètres en entrée.
     --
     --  PARAMETRES :
     --     pt_info_line_tab     Entrée        Objet contenant un tableau d'objet
     --     po_info_line_lst     Sortie        Objet contenant une liste d'objet XXEAI_INFO_INVOICE_LINE_LST
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Info_Invoice_Line_Liste(pt_info_line_tab IN XXEAI_IN_INVOICE_LINE_TAB,
                                           po_info_line_lst IN OUT NOCOPY XXEAI_INFO_INVOICE_LINE_LST);

     -----------------------------------------------------------------
     --  FONCTIONNALITE 15 : DETERMINER L'IDENTIFIANT DE FACTURE/IDENTIFIANT DE LIGNE DE FACTURE EN LISTE
     --  Nom           : Get_Invoice_Id_Liste
     --  Description   : Fonction qui retourne la liste de valeurs des nouveaux identifiants de factures
     --           ou des nouveaux identifiants de lignes de factures suivant la liste de paramètres en entrée.
     --
     --  PARAMETRES :
     --     pt_type         Entrée        Objet contenant un tableau d'objet
     --     po_invoice_id_lst     Sortie        Objet contenant une liste d'objet XXEAI_INVOICE_ID_LST
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_Invoice_Id_Liste(pt_type           IN XXEAI_TYPE_ENTETE_LIGNE_TAB,
                                    po_invoice_id_lst IN OUT NOCOPY XXEAI_INVOICE_ID_LST);
                                    
     -----------------------------------------------------------------
     --  FONCTIONNALITE 16 : DÉTERMINER LES TYPE ET NUMERO DE LIGNE ET LE TYPE DE MOUVEMENT AR
     --  Nom           : Get_type_num_ligne_mvt_AR
     --  Description   : Cette fonction sert à retourner le type de ligne, le numéro de ligne et le type de mouvement d’une 
     --                  facture AR en fonction du compte local, du sous compte, du signe, du débit/crédit et du montant 
     --                  fournis par les amonts.
     --
     --  PARAMETRES :
     --     pt_in_info_ligne         Entrée        Objet contenant le compte local, le sous-compte, le signe, Débit/crédit, et le montant
     --     po_info_ligne_mvt_ar     Sortie        Objet contenant le code erreur, le type de ligne, le numéro de ligne et le type de mouvement
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------
     PROCEDURE Get_type_num_ligne_mvt_AR(pt_in_info_ligne     IN XXEAI_IN_LIGNE_MVT_AR_TYP, 
                                         po_info_ligne_mvt_ar IN OUT NOCOPY XXEAI_TYPE_AR_OBJ);
     
     -----------------------------------------------------------------
     --  FONCTIONNALITE 17 : Déterminer la région à partir du DKCODE
     --  Nom           : Get_region_DKCODE 
     --  Description   : Cette fonction servira à retourner la région en fonction du DKcode. Chaque Unité Opérationnelle aura un DKcode 
     --                  (de type BxxxxxxxxK avec xxxxxxxx le code numérique et K le caractère de contrôle) et suivant le jeu de transcodification 
     --                  DKA_DKCODE_UO (DKCode <> UO_DALKIA)  on en déduira la région
     --
     --  PARAMETRES :
     --     pv_DKcode                Entrée        DKcode
     --     po_info_region           Sortie        Objet contenant le code erreur, et la région
     --
     --  VALEUR RETOURNEE :
     --     Description       :  N/A
     --     Valeurs possibles :  N/A
     -----------------------------------------------------------------    
     PROCEDURE Get_region_DKCODE(pv_DKcode IN VARCHAR2, 
                                 po_info_region IN OUT NOCOPY XXEAI_TYPE_INFO_REGION_OBJ);
                                 
                                 
END XXEAI_INTERFACE_TOOLS_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;
