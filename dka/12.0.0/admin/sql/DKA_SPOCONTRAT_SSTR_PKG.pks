CREATE OR REPLACE PACKAGE DKA_SPOCONTRAT_SSTR_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SPOCONTRAT_SSTR_PKG.pks 517 2007-12-07 16:16:23Z NORDEST\tbonduae $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOCONTRAT_SSTR_PKG.pks
-- DESCRIPTION       : DKA_SPOCONTRAT_SSTR_PKG package specifications
--
-- AUTEUR            : T. Bonduaeux
-- DATE DE CREATION  : 03/12/2007
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- ---------- --------- --------------------------------------------------------
-- 03-Dec-07  tbonduae  Création
-- 11-Jan-10  cde       Correction controle frs : ajout procedure Check_vendor
-- 02-Fev-10  cde       Correction controles validité : ajout procédures check_vendor_site, 
--                      check_lieu_livraison, check_lieu_facturation, check_gestionnaire
--                      check_projet, Check_nature_prestation
-- 26-Fev-10  cde       EID20090220 et EID20090323 : ajout procédures et fonctions
--                      check_expenditure_type, get_affich_imput, get_first_revnum_ctr_annuel
--                      get_last_revnum_ctr_annuel, get_invoices_count, check_montant_facture
--                      check_montant_imput_facture, get_ccid
-- 07-Mar-11  cde       Ajout Procédures get_contrat_start_date et get_contrat_end_date
-- 24-AOU-17  NBO       artf2212366 - SPE119 - Numérotation des contrats non conforme à la SFD
-- 25/08/2023 ARA       EDB364 - Contrats SSTR - Rajout d'une liste déroulante pour la région
--------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--------------------------------------------------------------------------------
--  Nom           : get_varchar2_parameter
--  Description   : Procédure récupérant un paramètre de type VARCHAR2
--  PARAMETRES    :
--                     pv_program_code      : Le code programme
--                     pv_parameter_name    : Le nom du paramètre
--                     pv_data              : La valeur du paramètre
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_varchar2_parameter(pv_program_code   IN     VARCHAR2,
                                     pv_parameter_name IN     VARCHAR2,
                                     pv_data              OUT VARCHAR2,
                                     pn_retcode           OUT NUMBER,
                                     pv_err_msg           OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : get_number_parameter
--  Description   : Procédure récupérant un paramètre de type NUMBER
--  PARAMETRES    :
--                     pv_program_code      : Le code programme
--                     pv_parameter_name    : Le nom du paramètre
--                     pv_data              : La valeur du paramètre
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_number_parameter(pv_program_code   IN     VARCHAR2,
                                   pv_parameter_name IN     VARCHAR2,
                                   pv_data              OUT NUMBER,
                                   pn_retcode           OUT NUMBER,
                                   pv_err_msg           OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : Check_vendor
--  Description   : Procédure de contrôle du fournisseur
--  PARAMETRES    :
--                     pv_vendor_id         : ID fournisseur
--                     pv_check             : variable de contrôle
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_vendor(pv_vendor_id      IN     NUMBER,
                           pv_check             OUT VARCHAR2,
                           pn_retcode           OUT NUMBER,
                           pv_err_msg           OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : Check_vendor_site
--  Description   : Procédure de contrôle du site fournisseur
--  PARAMETRES    :
--                     pv_vendor_site_id    : ID site fournisseur
--                     pv_check             : variable de contrôle
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_vendor_site(pn_vendor_site_id    IN     NUMBER,
                                pv_check             OUT VARCHAR2,
                                pn_retcode           OUT NUMBER,
                                pv_err_msg           OUT VARCHAR2);
                                
--------------------------------------------------------------------------------
--  Nom           : Check_lieu_livraison
--  Description   : Procédure de contrôle du lieu de livraison
--  PARAMETRES    :
--                     pn_ship_to_location_id  : ID lieu livraison
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_lieu_livraison(pn_ship_to_location_id   IN     NUMBER,
                                   pv_check                 OUT VARCHAR2,
                                   pn_retcode               OUT NUMBER,
                                   pv_err_msg               OUT VARCHAR2);
                                   
--------------------------------------------------------------------------------
--  Nom           : Check_lieu_facturation
--  Description   : Procédure de contrôle du lieu de facturation
--  PARAMETRES    :
--                     pn_bill_to_location_id  : ID lieu facturation
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_lieu_facturation(pn_bill_to_location_id   IN     NUMBER,
                                     pv_check                 OUT VARCHAR2,
                                     pn_retcode               OUT NUMBER,
                                     pv_err_msg               OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : check_nature_prestation
--  Description   : Procédure de contrôle de la nature de prestation
--  PARAMETRES    :
--                     pv_nature_prest         : Nature de prestation
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_nature_prestation(pv_nature_prest    IN     VARCHAR2,
                                 pv_check              OUT VARCHAR2,
                                 pn_retcode            OUT NUMBER,
                                 pv_err_msg            OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : check_gestionnaire
--  Description   : Procédure de contrôle du gestionnaire
--  PARAMETRES    :
--                     pn_gestionnaire_id      : ID gestionnaire
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_gestionnaire(pn_gestionnaire_id    IN     NUMBER,
                                 pv_check              OUT VARCHAR2,
                                 pn_retcode            OUT NUMBER,
                                 pv_err_msg            OUT VARCHAR2);
                                 
--------------------------------------------------------------------------------
--  Nom           : Check_projet
--  Description   : Procédure de contrôle du projet
--  PARAMETRES    :
--                     pn_project_id           : ID projet
--                     pv_project_readonly     : Balise code projet en lecture seule
--                     pn_org_id               : Id org
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_projet(pn_project_id       IN  NUMBER,
                           pv_project_readonly IN  VARCHAR2,
                           pn_org_id           IN  NUMBER,
                           pv_check            OUT VARCHAR2,
                           pn_retcode          OUT NUMBER,
                           pv_err_msg          OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : Check_expenditure_type
--  Description   : Procédure de contrôle du type de dépense
--  PARAMETRES    :
--                     pv_expenditure_type     : Type de dépense
--                     pn_project_id           : ID projet
--                     pn_task_id              : ID tache
--                     pv_check                : variable de contrôle
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_expenditure_type(pv_expenditure_type   IN     VARCHAR2,
                                     pn_project_id         IN     NUMBER,
                                     pn_task_id            IN     NUMBER, --RBE artf2080405
                                     pv_check              OUT VARCHAR2,
                                     pn_retcode            OUT NUMBER,
                                     pv_err_msg            OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : get_affich_imput
--  Description   : Fonction permettant de déterminer si les informations au niveau
--                  imputation doivent être modifiable ou pas
--  PARAMETRES    :
--                     pn_contrat_imput_id    : ID de la ligne d'imputation
--                     pv_champ               : nom du champ
--------------------------------------------------------------------------------
    FUNCTION get_affich_imput (
        pn_contrat_imput_id   IN   NUMBER,
        pv_champ              IN   VARCHAR2
        
    )
        RETURN VARCHAR2;

--------------------------------------------------------------------------------
--  Nom           : get_first_revnum_ctr_annuel
--  Description   : Fonction fournissant le numéro de la dernière révision approuvée
--                  d'un contrat annuel
--  PARAMETRES    :
--                     pn_contrat_id    : ID du contrat
--                     pd_start_date    : Date de début
--------------------------------------------------------------------------------
    FUNCTION get_first_revnum_ctr_annuel (
        pn_contrat_id   IN   NUMBER,
        pd_start_date   IN   DATE
    )
        RETURN NUMBER;

--------------------------------------------------------------------------------
--  Nom           : get_last_revnum_ctr_annuel
--  Description   : Fonction fournissant le numéro de la dernière révision approuvée
--                  d'un contrat annuel
--  PARAMETRES    :
--                     pn_contrat_id    : ID du contrat
--                     pd_start_date    : Date de début
--------------------------------------------------------------------------------
    FUNCTION get_last_revnum_ctr_annuel (
        pn_contrat_id   IN   NUMBER,
        pn_commande_id  IN   NUMBER
        -- pd_start_date   IN   DATE
    )
        RETURN NUMBER;

--------------------------------------------------------------------------------
--  Nom           : get_invoices_count
--  Description   : Procédure de comptage du nombre de factures
--  PARAMETRES    :
--                     pn_commande_id       : ID commande
--                     pn_nbr_facture       : Nombre de factures
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_invoices_count(pn_commande_id      IN     NUMBER,
                                 pn_nbr_facture      OUT NUMBER,
                                 pn_retcode          OUT NUMBER,
                                 pv_err_msg          OUT VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : check_montant_facture
--  Description   : Procédure de vérification du nouveau montant du contrat
--  PARAMETRES    :
--                     pn_contrat_id        : ID contrat
--                     pd_start_date        : Date de début
--                     pd_end_date          : Date de fin
--                     pn_amount            : Montant
--                     pd_date_effet        : Date d'effet
--                     pn_commande_id       : ID commande
--                     pv_check             : Variable de contrôle
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_montant_facture(pn_contrat_id      IN     NUMBER,
                                    pd_start_date      IN     DATE,
                                    pd_end_date        IN     DATE,
                                    pn_amount          IN     NUMBER,
                                    pd_date_effet      IN     DATE,
                                    pn_commande_id     IN     NUMBER,                        
                                    pv_check           OUT    VARCHAR2,
                                    pn_retcode         OUT    NUMBER,
                                    pv_err_msg         OUT    VARCHAR2);

--------------------------------------------------------------------------------
--  Nom           : check_montant_imput_facture
--  Description   : Procédure de vérification du nouveau montant du contrat
--  PARAMETRES    :
--                     pn_imputation_id        : ID imputation contrat
--                     pd_start_date           : Date de début
--                     pd_end_date             : Date de fin
--                     pn_amount               : Montant du contrat
--                     pd_date_effet           : Date d'effet
--                     pn_commande_id          : ID commande
--                     pn_unit_oeuvre          : Unite d'oeuvre
--                     pn_sum_unit_oeuvre      : Somme des unités d'oeuvre
--                     pv_check                : Variable de contrôle
--                     pn_amount_imputation    : Montant commandé
--                     pn_amount_imput_facture : Montant facturé
--                     pn_retcode              : Le code d'erreur
--                     pv_err_msg              : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE check_montant_imput_facture(pn_imputation_id         IN     NUMBER,
                                           pd_start_date           IN     DATE,
                                           pd_end_date             IN     DATE,
                                           pn_amount               IN     NUMBER,
                                           pd_date_effet           IN     DATE,
                                           pn_commande_id          IN     NUMBER, 
                                           pn_unit_oeuvre          IN     NUMBER,
                                           pn_sum_unit_oeuvre      IN     NUMBER,                      
                                           pv_check                OUT    VARCHAR2,
                                           pn_amount_imputation    OUT    NUMBER, 
                                           pn_amount_imput_facture OUT    NUMBER,
                                           pn_retcode              OUT    NUMBER,
                                           pv_err_msg              OUT    VARCHAR2);
                                
--------------------------------------------------------------------------------
--  Nom           : get_ccid
--  Description   : Procédure de calcul de la ccid
--  PARAMETRES    :
--                     pv_nature_prestation : Segments catégorie
--                     pv_expenditure_type  : Type de dépense
--                     pn_signataire_id     : Id du signataire
--                     pn_project_id        : Id du Projet
--                     pn_task_id           : Id de la tache
--                     pn_vendor_id         : Id du fournisseur
--                     pn_org_id            : Id Org
--                     pn_ccid              : Id de la clé comptable
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------

  PROCEDURE get_ccid(pv_nature_prestation          IN VARCHAR2,
                     pv_expenditure_type           IN VARCHAR2,
                     pn_signataire_id              IN NUMBER,
                     pn_project_id                 IN NUMBER,
                     pn_task_id                    IN NUMBER,
                     pn_vendor_id                  IN NUMBER,
                     pn_org_id                     IN  NUMBER,
                     pn_ccid                       OUT NUMBER,
                     pn_retcode                    OUT NUMBER,
                     pv_err_msg                    OUT VARCHAR2);     

--------------------------------------------------------------------------------
--  Nom           : get_contrat_end_date
--  Description   : Procédure de calcul de la date de fin du contrat
--  PARAMETRES    :
--                     pn_header_id         : Id du contrat
--                     pd_end_date          : Date fin de période
--                     pn_nb_reconduction   : Nombre de reconduction
--                     pn_reconduction_num  : Numéro de reconduction
--                     pd_contrat_end_date  : Date de fin du contrat
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_contrat_end_date(pn_header_id          IN  NUMBER,
                                   pd_end_date           IN  DATE,
                                   pn_nb_reconduction    IN  NUMBER,
                                   pn_reconduction_num   IN  NUMBER,
                                   pd_contrat_end_date   OUT DATE,
                                   pn_retcode            OUT NUMBER,
                                   pv_err_msg            OUT VARCHAR2); 

--------------------------------------------------------------------------------
--  Nom           : get_contrat_start_date
--  Description   : Procédure de calcul de la date de début du contrat
--  PARAMETRES    :
--                     pn_header_id         : Id du contrat
--                     pd_start_date        : Date début de période
--                     pn_reconduction_num  : Numéro de reconduction
--                     pd_contrat_start_date: Date de début du contrat
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
    PROCEDURE get_contrat_start_date(pn_header_id          IN  NUMBER,
                                         pd_start_date         IN  DATE,
                                         pn_reconduction_num   IN  NUMBER,
                                         pd_contrat_start_date OUT DATE,
                                         pn_retcode            OUT NUMBER,
                                         pv_err_msg            OUT VARCHAR2);       

-- 24-AOU-17  NBO       artf2212366 - SPE119 - Numérotation des contrats non conforme à la SFD
--------------------------------------------------------------------------------
--  Nom           : get_numcommande
--  Description   : Procédure de récupértion du numéro de commande
--  PARAMETRES    :
--                     pv_numcommande           : Numéro de commande
--------------------------------------------------------------------------------
    PROCEDURE get_numcommande(pv_numcommande OUT VARCHAR2);      

	
--EDB364
--------------------------------------------------------------------------------
--  Nom           : get_info_region
--  Description   : Procédure de récupértion de la région du contrat

--------------------------------------------------------------------------------
PROCEDURE get_info_region (pn_orgid      IN     NUMBER,
                             pn_verify      OUT NUMBER,
							 pn_entity  OUT VARCHAR2,
							 pv_err_msg            OUT VARCHAR2);


---ARA EDB364 
--------------------------------------------------------------------------------
--  Nom           : get_info_org
--  Description   : Procédure de récupértion de l'orgid du contrat

--------------------------------------------------------------------------------
PROCEDURE get_info_org (pn_idcontrat      IN     NUMBER,
                             pn_orgidcontrat      OUT NUMBER);

END DKA_SPOCONTRAT_SSTR_PKG;
/
SHOW ERRORS;

EXIT
