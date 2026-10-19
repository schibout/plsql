CREATE OR REPLACE PACKAGE DKA_IARPAFAC_PKG AS
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		     : DKA_IARPAFAC_PKG.pks
-- DESCRIPTION	     : DKA_IARPAFAC_PKG package spec :
---
--- AUTEUR	     : Guillaume CHABRIER (CGEY)
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--  11/02/2003 EF      --> Passage de la date GL aux procedures:
---                             -- get_acct_area
---                             -- get_ccid_ttc
---                             -- get_ccid_tax
---                             -- load_invoice_line
---                             -- get_ccid_attriutes_line
---                             -- get_ccid_surtaxe
---                     --> Ajout du company_code dans l'appel de get_millesim_batch_id
---                         afin d'afficher le nom de l'organisation en cas de NO_DATA_FOUND
--- 20/06/2003 AD  Creation de la procédure run_recyclage_rejections afin de lancer le recyclage automatique
---                des lignes en rejets dans les tables d'open interface par le programme standart
--- 12/01/2004 GV  Ajout du paramètre pd_gl_date_OI dans les procédures suivantes :
---                - load_invoice_header
---                - load_invoice_line
---                - get_ar_gl_date
--- 17/06/2004 SFE Portage spécifique pour projet PHENIX 2004.
---                Impacts sur get_ccid_ttc, get_ccid_atriutes_line, get_ccid_tax, get_ccid_surtaxe
--- 03/05/2017 MEG artf2148883 : INT006 : Defect # 641 - La valeur du segment5 n'est pas determine
--- 06/08/2019 AAM artf07147612 : EDB233 : Détermination du code RUM et remontée de l¿information du mode de règlement lorsqu¿il s¿agit du prélèvement.
--- 17/01/2022 SELO EDB325
---------------------------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

---------------------------------------------------------------------------------------------------------------
-- NOM         :
-- DESCRIPTION :
--
-- PARAMETRES  :
--
-- VALEUR RETOURNEE :
---------------------------------------------------------------------------------------------------------------
--  Nom           : create_ext_instrument
--  Description   : Création de l'extension d'instrument de règlement 
--  PARAMETRES    : p_instrument_id
--                  p_client
--                  p_payment_channel 
--  VALEUR RETOURNEE :identifiant de l'extension de réglement

---------------------------------------------------------------------------------------------------------------
FUNCTION create_ext_instrument (    p_INSTRUMENT_PAYMENT_USE_ID   IN NUMBER
                                  , p_payment_channel             IN VARCHAR2
                                  , p_cust_account_id             IN NUMBER
                                  , p_account_site_id             IN NUMBER
                                  , p_org_id                      IN NUMBER
                                  , p_party_id                    IN NUMBER
								  , p_payer_id                    IN NUMBER
                                  , p_invoice_number              IN VARCHAR2)
RETURN NUMBER	;
---------------------------------------------------------------------------------------------------------------
--  Nom           : load_invoice_header
--  Description   : Procédure de controle de l'entête d'une facture
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE load_invoice_header(pr_rec_line     IN       dka_iarpafac_interface%ROWTYPE,
                              pn_org_id       IN       NUMBER,
                              pn_sob_id       IN       NUMBER,
                              pn_cust_acct_site_id OUT NUMBER,
                              pn_cust_account_id   OUT NUMBER,
                              pv_partner_code     OUT  VARCHAR2,
                              pv_acct_area        OUT  VARCHAR2,
                              pd_gl_date          OUT  DATE,
                              pd_gl_date_OI       OUT  DATE,
                              pv_errbuf       IN  OUT  VARCHAR2,
		              pn_retcode          OUT  NUMBER);
----------------------------------------------------------------------------------------------------------------
--  Nom           : load_invoice_line
--  Description   : Procédure de controle d'une ligne de facture et chargement dans
--                  les tables d'open interface AR : RA_INTERFACE_LINES_ALL
--                                              et : RA_INTERFACE_DISTRIBUTIONS_ALL
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE load_invoice_line (
        pr_rec_line            IN       dka_iarpafac_interface%ROWTYPE,
        pn_line_num_cnt        IN       NUMBER,
        pn_link_to_line        IN       NUMBER,
        pn_cust_acct_site_id   IN       NUMBER,
        pn_cust_account_id     IN       NUMBER,
        pv_partner_code        IN       VARCHAR2,
        pv_acct_area           IN       VARCHAR2,
        pd_gl_date             IN       DATE,
        pd_gl_date_OI          IN       DATE,
        pv_typmvt              IN       VARCHAR2,
        pn_org_id              IN       NUMBER,
        pv_batch_source_name   IN       VARCHAR2,
        pn_project_id_majo     IN       NUMBER,
        pn_task_id_majo        IN       NUMBER,
        pv_indicage            IN       VARCHAR2,
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    );
---------------------------------------------------------------------------------------------------------------
--  Nom           : get_acct_area
--  Description   : Procédure qui détermine le centre de gestion à partir du type d'info et du champs segmentation
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_acct_area(pr_rec_line  IN         dka_iarpafac_interface%ROWTYPE,
                        Pd_Date      IN     DATE,
			pv_acct_area     OUT    VARCHAR2,
			pv_errbuf    IN  OUT    VARCHAR2,
                        pn_retcode       OUT    NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ar_gl_date
--  Description   : Procédure de transcodage de la date GL
--                  Le mois de invoice_date est comparé au mois de gl_date
--                  selon qu'il soit : IDENTIQUE  => pd_gl_date := SYSDATE
--                           ou bien : ANTÉRIEUR  => pd_gl_date := 1er jour de la periode ouverte en cours
--                           ou bien : POSTÉRIEUR => pd_gl_date := RAISE e_error
--
--                  Si aucune période AR n'est ouverte => rejet de la facture
--                  L'exception NO_DATA_FOUND gére l'insertion et l'affichage du message d'erreur
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     Description       : pd_gl_date
--     Valeurs possibles : DATE
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_ar_gl_date (  pr_rec_line      IN       dka_iarpafac_interface%ROWTYPE,
                            pd_gl_date           OUT  DATE,
                            pd_gl_date_OI        OUT  DATE,
                            pn_sob_id        IN NUMBER,
                            pv_errbuf        IN  OUT  VARCHAR2,
		            pn_retcode           OUT  NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : get_transaction_type
--  Description   : Procédure qui détermine le type de transaction (evenement ou depense)
--                  Selon la classe de compte(6 ou 7)un type de context différent est passé
--                  en parametre dka_stransco_pkg.get_value_f
--                          Classe 6  => 'PA_EXPENDITURE_TYPE'
--                          Classe 7  => 'PA_EVENT_TYPE'
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_transaction_type(pr_rec_line                IN         dka_iarpafac_interface%ROWTYPE,
			       pv_expenditure_type            OUT    VARCHAR2,
			       pv_event_type                  OUT    VARCHAR2,
			       pv_errbuf                  IN  OUT    VARCHAR2,
                               pn_retcode                     OUT    NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_ttc
--  Description   : Procedure qui ramene la clé comptable pour une ligne CLIENT(ttc)
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_ccid_ttc (
        pr_rec_line       IN       dka_iarpafac_interface%ROWTYPE,
        pv_acct_area      IN       VARCHAR2,
        pv_partner_code   IN       VARCHAR2,
        pd_date           IN       DATE,
        pn_cust_acct_site_id IN    NUMBER, -- R12
        pv_segment1       OUT      VARCHAR2,
        pv_segment2       OUT      VARCHAR2,
        pv_segment3       OUT      VARCHAR2,
        pv_segment4       OUT      VARCHAR2,
        pv_segment5       OUT      VARCHAR2,
        pv_segment6       OUT      VARCHAR2,
        pv_segment7       OUT      VARCHAR2,
        pv_segment8       OUT      VARCHAR2,
        pv_segment9       OUT      VARCHAR2,     -- PHENIX 2004: Ajout.
        pv_segment10      OUT      VARCHAR2,     -- PHENIX 2004: Ajout.
        pv_segment11      OUT      VARCHAR2, --R12
        pv_segment12      OUT      VARCHAR2, --R12
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    );

---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_tax
--  Description   : Procedure qui ramene la clé comptable pour une ligne de TAX(tva)
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_ccid_tax(pr_rec_line      IN       dka_iarpafac_interface%ROWTYPE,
                       pv_acct_area     IN      VARCHAR2,
                       pn_org_id        IN      NUMBER,
                       vv_tax_code      IN      VARCHAR2,
                       pv_tax_type      IN      VARCHAR2,
                       pn_tax_id        IN      VARCHAR2,
                       Pd_Date          IN      DATE,
                       pv_segment1         OUT  VARCHAR2,
                       pv_segment2         OUT  VARCHAR2,
                       pv_segment3         OUT  VARCHAR2,
                       pv_segment4         OUT  VARCHAR2,
                       pv_segment5         OUT  VARCHAR2,
                       pv_segment6         OUT  VARCHAR2,
                       pv_segment7         OUT  VARCHAR2,
                       pv_segment8         OUT  VARCHAR2,
                       pv_segment9         OUT  VARCHAR2,       -- PHENIX 2004: Ajout.
                       pv_segment10        OUT  VARCHAR2,       -- PHENIX 2004: Ajout.
                       pv_segment11      OUT      VARCHAR2,     -- R12
                       pv_segment12      OUT      VARCHAR2,     -- R12
                       pv_int_segment1         OUT  VARCHAR2,
                       pv_int_segment2         OUT  VARCHAR2,
                       pv_int_segment3         OUT  VARCHAR2,
                       pv_int_segment4         OUT  VARCHAR2,
                       pv_int_segment5         OUT  VARCHAR2,
                       pv_int_segment6         OUT  VARCHAR2,
                       pv_int_segment7         OUT  VARCHAR2,
                       pv_int_segment8         OUT  VARCHAR2,
                       pv_int_segment9         OUT  VARCHAR2,   -- PHENIX 2004: Ajout.
                       pv_int_segment10        OUT  VARCHAR2,   -- PHENIX 2004: Ajout.
                       pv_int_segment11  OUT      VARCHAR2, --R12
                       pv_int_segment12  OUT      VARCHAR2, --R12
                       pv_errbuf        IN  OUT  VARCHAR2,
		       pn_retcode           OUT  NUMBER);

---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_attriutes_line
--  Description   : Procedure qui ramene la clé comptable pour une ligne de PRODUIT
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_ccid_attributes_line(pr_rec_line          IN   dka_iarpafac_interface%ROWTYPE,
                                  pn_project_id        IN   NUMBER,
                                  pn_project_id_case_REFAC IN   NUMBER,
                                  pn_task_id            IN  NUMBER,
                                  pn_task_id_case_refac IN  NUMBER,   --R12
                                  pn_cust_acct_site_id  IN NUMBER, --R12
                                  pv_acct_area         IN   VARCHAR2, --R12
                                  pv_partner_code      IN   VARCHAR2,
                                  Pd_Date              IN   DATE,
                                  pv_segment1          OUT  VARCHAR2,
                                  pv_segment2          OUT  VARCHAR2,
                                  pv_segment3          OUT  VARCHAR2,
                                  pv_segment4          OUT  VARCHAR2,
                                  pv_segment5          OUT  VARCHAR2,
                                  pv_segment6          OUT  VARCHAR2,
                                  pv_segment7          OUT  VARCHAR2,
                                  pv_segment8          OUT  VARCHAR2,
                                  pv_segment9          OUT  VARCHAR2,   -- PHENIX 2004: Ajout.
                                  pv_segment10         OUT  VARCHAR2,   -- PHENIX 2004: Ajout.
                                  pv_segment11               OUT      VARCHAR2,     -- R12.
                                  pv_segment12               OUT      VARCHAR2,     -- R12
                                  pv_attribute1        OUT  VARCHAR2,
                                  pv_attribute2        OUT  VARCHAR2,
                                  pv_attribute3        OUT  VARCHAR2,
                                  pv_attribute4        OUT  VARCHAR2,
                                  pv_attribute5        OUT  VARCHAR2,
                                  pv_attribute6        OUT  VARCHAR2,
                                  pv_attribute7        OUT  VARCHAR2,
                                  pv_attribute8        OUT  VARCHAR2,
                                  pv_attribute12       OUT  VARCHAR2,
                                  pv_attribute_category OUT VARCHAR2,
                                  pv_errbuf            IN OUT  VARCHAR2,
		                  pn_retcode           OUT  NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_surtaxe
--  Description   : Procedure qui ramene la clé comptable pour une ligne de PRODUIT(surtaxe)
--                  Compte dont la racine est '467'
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_ccid_surtaxe(pr_rec_line      IN       dka_iarpafac_interface%ROWTYPE,
                           pv_acct_area     IN      VARCHAR2,
                           Pd_Date          IN      DATE,
                           pv_segment1         OUT  VARCHAR2,
                           pv_segment2         OUT  VARCHAR2,
                           pv_segment3         OUT  VARCHAR2,
                           pv_segment4         OUT  VARCHAR2,
                           pv_segment5         OUT  VARCHAR2,
                           pv_segment6         OUT  VARCHAR2,
                           pv_segment7         OUT  VARCHAR2,
                           pv_segment8         OUT  VARCHAR2,
                           pv_segment9         OUT  VARCHAR2,   -- PHENIX 2004: Ajout.
                           pv_segment10        OUT  VARCHAR2,   -- PHENIX 2004: Ajout.
                           pv_segment11   OUT      VARCHAR2, --R12
                           pv_segment12   OUT      VARCHAR2, --R12
                           pv_attribute8  OUT      VARCHAR2, --R12
                           pv_errbuf        IN  OUT  VARCHAR2,
		           pn_retcode           OUT  NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ar_tax
--  Description   : procedure de controle et de transcodage du code TVA
--                  via les tables AP_TAX_CODES_ALL et GL_CODE_COMBINATIONS
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_ar_tax (
        pr_rec_line    IN       dka_iarpafac_interface%ROWTYPE,
        pn_org_id      IN       NUMBER,
        pv_acct_area   IN       VARCHAR2,
        pn_tax_id      OUT      NUMBER,
        pv_tax_code    OUT      VARCHAR2,
        pv_tax_type    OUT      VARCHAR2,
        pv_errbuf      IN OUT   VARCHAR2,
        pn_retcode     OUT      NUMBER
    );
---------------------------------------------------------------------------------------------------------------
--  Nom           : get_customer_info
--  Description   : Procédure de controle des informations concernant le client
--                  (existance de la reference anael(sub_account) dans OA)
--                  Un client doit être référencé dans OA. (si non => rejet) Si oui nous controlons
--                  qu'il a bien une adresse qui lui est attribuée. Si ce n'est pas le cas c'est que
--                  le client est nouveau (mais déjà connu)avec une adresse par défaut. Nous lui attribuons
--                  donc une nouvelle adresse grace à la procedure dka_iclientifs_pkg.duplicate_addr.
--
--
--  PARAMETRES    :      pn_cust_acct_site_id,
--                       pn_cust_account_id,
--                       pv_partner_code
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_customer_info(pr_rec_line           IN       dka_iarpafac_interface%ROWTYPE,
                            pv_acct_area          IN        VARCHAR2,
                            pn_org_id             IN        NUMBER,
                            pn_cust_acct_site_id       OUT  NUMBER,
                            pn_cust_account_id         OUT  NUMBER,
                            pv_partner_code            OUT  VARCHAR2,
                            pv_errbuf             IN   OUT  VARCHAR2,
  		            pn_retcode                 OUT  NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : check_project
--  Description   : Procedure permettant de déterminer le code projet correspondant à l'unité opérationnelle
--                  L'org_id est dédiut du code_société(société emmétrice de la facture),
--                  le code_projet pointe sur une organisation mais elle peut être differente de celle
--                  de la ligne, il s'agit là d'un projet "à refacturer"
--                  La determination du type de traitement s'effectue comme suit :
--                   Comparaison entre la société emmétrice(org_id) et la société déduite du projet(project_code)
--                   Deux traitements possiles :
--
--                    -société emmétrice(org_id)  IDENTIQUE   société déduite du projet(project_code)
--                       => traitement AR_NORMAL
--
--                    -société emmétrice(org_id)  DIFFERENTE  société déduite du projet(project_code)
--                       => traitement AR_REFAC
--
--  PARAMETRES
-- 	************************
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE check_project (pr_rec_line                IN       dka_iarpafac_interface%ROWTYPE,
                          pv_acct_area               IN       VARCHAR2,
                          pn_org_id                  IN       NUMBER,
                          pn_project_id              OUT      NUMBER,
                          pn_project_id_case_refac   OUT      NUMBER,
                          pn_task_id                 OUT      NUMBER,
                          pn_task_id_case_refac      OUT      NUMBER,
                          --pn_project_appart           OUT  NUMBER,
                          pv_errbuf                  IN OUT   VARCHAR2,
                          pn_retcode                 OUT      NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : update_request_id
--  Description   : Procédure de mise à jour de la colonne OA_REQUEST_ID pour les enregs
--                  à traiter
--
--  PARAMETRES    :
--     pv_errbuf                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE update_request_id( 
                             pv_errbuf             IN      OUT       VARCHAR2,
                             pn_retcode                    OUT       NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : update_group_id
--  Description   : Procédure de mise à jour la colonne GROUP_ID des enregistrements pour une même
--                  origine OA
--
--
--  PARAMETRES    :
--     pv_company_code           Entrée
--     pv_fmt_origin             Entrée
--     pn_group_id               Entrée
--     pv_errbuf                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE update_group_id (
        pr_rec_line       IN       NUMBER,
		pv_company_code   IN       VARCHAR2,
        pv_region         IN       VARCHAR2,
        pv_fmt_origin     IN       VARCHAR2,
        pn_group_id       IN       NUMBER,
        pv_millesim       IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    );

---------------------------------------------------------------------------------------------------------------
--  Nom           : get_millesim_batch_id
--  Description   : Procédure de mise à jour du du batch_source_name et id comme parametres de lancement
--                  de l'open interface.
--
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_millesim_batch_id( pr_rec_line           IN               NUMBER,
                                 pn_org_id             IN               NUMBER,
                                 pv_fmt_origin         IN               VARCHAR2,
                                 pv_millesim           IN               VARCHAR2,
                                 pv_company_code       IN               VARCHAR2,
                                 pv_batch_source_name          OUT      VARCHAR2,
                                 pn_batch_source_id            OUT      NUMBER,
                                 pv_errbuf             IN      OUT      VARCHAR2,
                                 pn_retcode                    OUT      NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation du package
--                  Génère l'entête du fichier de sortie
--
--  PARAMETRES    :
-- 	************************
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE init (pv_errbuf             IN OUT 	VARCHAR2,
                pn_retcode               OUT       NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : run_import
--  Description   : lancement procédure standard du traitement standard RAXTRX
--                  de l'open interface avec la procédure du package standard
--                  FND_REQUEST.SUBMIT_REQUEST
--
--  PARAMETRES    :pv_company_code Entrée
--                 pv_source       Entrée
--                 pn_group_id     Entrée
--                 --pv_hold_code    Entrée
--                 pn_request_id   Sortie
--                 pv_errbuf       Entrée/Sortie    message d'erreur
--                 pn_retcode      Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE run_import (
                      pv_company_code IN         VARCHAR2,
                      pv_fmt_origin   IN         VARCHAR2,
                      pn_group_id     IN         NUMBER,
                      pn_org_id       IN         NUMBER,
                      pn_request_id         OUT  NUMBER,
                      pv_batch_source_name  IN   VARCHAR2,
                      pv_batch_source_id    IN   NUMBER,
                      pv_errbuf         IN  OUT  VARCHAR2,
                      pn_retcode            OUT  NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : run_recyclage_rejections
--  Description   : lancement procédure standard du traitement standard RAXTRX
--                  de l'open interface avec la procédure du package standard
--                  FND_REQUEST.SUBMIT_REQUEST pour recyclage des traitements des
--                  imports précédents.
--
--  PARAMETRES    :pv_company_code        Entrée
--                 pv_batch_source_name   Entrée
--                 pn_request_id          Sortie
--                 pv_errbuf       Entrée/Sortie    message d'erreur
--                 pn_retcode      Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE run_recyclage_rejections (pv_company_code IN         VARCHAR2,
                                    pv_batch_source_name  IN   VARCHAR2,
                                    pn_batch_source_id    IN   NUMBER,
                                    pn_org_id             IN   NUMBER,
                                    pn_request_id         OUT  NUMBER,
                                    pv_errbuf       IN    OUT  VARCHAR2,
                                    pn_retcode            OUT  NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : update_prlvt_invoice
--  Description   : Procédure de mise à jour des factures en mode prélèvement
--                  Renseigne les informations relatives au prélèvement dans AR pour les factures concernées
--
--  PARAMETRES    :
-- 	************************
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE update_prlvt_invoice (pv_errbuf             IN OUT 	VARCHAR2,
                                pn_retcode               OUT NUMBER);
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES :
--    pv_errbuf            		Entrée/Sortie		retour de message eventuel
--	pn_retcode          		Sortie			status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
---------------------------------------------------------------------------------------------------------------
PROCEDURE main (pv_errbuf          IN OUT 	VARCHAR2,
                pn_retcode            OUT   NUMBER);
---------------------------------------------------------------------------------------------------------------
END DKA_IARPAFAC_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;