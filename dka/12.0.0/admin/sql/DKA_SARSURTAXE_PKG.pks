/*<TOAD_FILE_CHUNK>*/
/* Formatted on 02/15/2002 11:07 (Formatter Plus v4.5.2) */
-------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- Projet : DALKIA Oracle Applications
-- Auteur : Guilhem LE NEZET
-- Date Création : 11/10/2001
-- Version livrables : V01
--------------------------------------------------------------------------------
-- NOM : dka_sarsurtaxe_pkg.pks
-- DESCRIPTION : Package
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 10/10/02   CD  Procedure update_gl_je_lines : pv_ccid VARCHAR2 => NUMBER
--------------------------------------------------------------------------------
-- 18/04/03   CD  Ajout procédure get_segment2
--------------------------------------------------------------------------------
-- 20/07/04   STI  Remplacement de getSegment2 par getSegment4
-- 			  	   procedure insert_ap_inv_lines_interface : ajout de 2 arguments (segment9, segment10)  
--                 procédure insert_ap_invoices_interface : ajout de 2 arguments (segment1, segment2)
--------------------------------------------------------------------------------
-- 04/10/05   EMA Ajout de la procedure main7 qui permet le lancement des 
--                éditions par centre de gestion.
--------------------------------------------------------------------------------
-- 15/08/16   OBE  Migration R12
--------------------------------------------------------------------------------

DEFINE package_name = "DKA_SARSURTAXE_PKG";

--************************************************************************************--
--******************** Spécification du package **************************************--
--************************************************************************************--

CREATE OR REPLACE PACKAGE Dka_Sarsurtaxe_Pkg
AS

-------------------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : Procédure d'initialisation des variables du package
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : GET_SEGMENT4
--  Description   : Procédure de récupération du segment4 en fonction du segment3 à 
--					partir de la table de transco
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE get_segment4 ( -- PHENIX 2004
        pv_segment3   			IN   VARCHAR2,
		pv_segment4   			OUT  VARCHAR2, -- PHENIX 2004
		pv_errbuf               OUT  VARCHAR2,
        pn_retcode              OUT  NUMBER
    );
	


-------------------------------------------------------------------------------------
 --  Nom           : INSERT_DKA_SARSURTAXE_TMP
 --  Description   : Procédure d'insertion dans la table dka_sarsurtaxe_tmp de lignes
 --                  de surtaxe communale issues des factures AR.
 --  PARAMETRES    :
 --    pv_errbuf       Sortie
 --    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE insert_dka_sarsurtaxe_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : PURGE_DKA_SARSURTAXE_TMP
--  Description   : Procédure purgeant les factures de la table dka_sarsurtaxe_tmp_all pour
--              lesquelles le traitement s'est déroulé normalement.
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE purge_dka_sarsurtaxe_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


 -------------------------------------------------------------------------------------
--  Nom           : INSERT_AR_INVOICES
--  Description   : Procédure d'insertion dans la table dka_sarsurtaxe_tmp des lignes
--              de surtaxe communale des factures AR ayant les caractéristiques suivantes :
--            - solde nul
--            - de type avoir et facture
--            - comptes utilisés : 467300 et 467296 (GIE IVRY)
--                    - concernant un organisme collecteur ( code partenaire segment4 = CCS%)
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_ar_invoices (
        pn_count     IN    NUMBER,
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : INSERT_GL_INVOICES_GERICCO
--  Description   : Procédure d'insertion dans la table dka_sarsurtaxe_tmp des lignes
--              de surtaxe communale de GL pour les factures portant sur des
--                  clients GERICCO (types de mouvement = 'GERICCO%')
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_gl_invoices_gericco (
        pn_count     IN    NUMBER,
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : INSERT_AP_INVOICES_INTERFACE
--  Description   : Procédure d'insertion dans la table AP_INVOICES_INTERFACE
--  PARAMETRES    :
--    pr_ar_invoices      Entrée
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_ap_invoices_interface (
        pv_collectivite   IN       VARCHAR2,
        pn_vendor_site_id IN       NUMBER,
        pv_invoice_num    IN       VARCHAR2,
        pv_amount         IN       VARCHAR2,
        pv_segment1       IN       VARCHAR2, -- PHENIX 2004
        pv_segment2       IN       VARCHAR2, -- PHENIX 2004
        pn_invoice_id     OUT      NUMBER,
        pv_errbuf         OUT      VARCHAR2,
        pn_retcode        OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : INSERT_AP_INV_LINES_INTERFACE
--  Description   : Procédure d'insertion dans la table AP_INVOICE_LINES_INTERFACE
--  PARAMETRES    :
--    pr_ar_invoices      Entrée
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_ap_inv_lines_interface (
        pn_invoice_id             IN       NUMBER,
        pv_amount                 IN       VARCHAR2,
        pn_customer_trx_line_id   IN       NUMBER,
        pn_je_header_id           IN       NUMBER,
        pn_je_line_num            IN       NUMBER,
        pv_segment1               IN       VARCHAR2,
        pv_segment2               IN       VARCHAR2,
        pv_segment3               IN       VARCHAR2,
        pv_segment4               IN       VARCHAR2,
        pv_segment5               IN       VARCHAR2,
        pv_segment6               IN       VARCHAR2,
        pv_segment7               IN       VARCHAR2,
        pv_segment8               IN       VARCHAR2,
        pv_segment9               IN       VARCHAR2, --PHENIX 2004
        pv_segment10              IN       VARCHAR2, --PHENIX 2004
        pv_segment11              IN       VARCHAR2, --OBE
        pv_segment12              IN       VARCHAR2, --OBE
        pv_errbuf                 OUT      VARCHAR2,
        pn_retcode                OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : LOAD_AP_INVOICES_INTERFACES
--  Description   : Procédure de chargement des tables AP_INVOICES_INTERFACES et
--              AP_INVOICES_LINES_INTERFACES
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE load_ap_invoices_interfaces (
        pv_collectivite   IN       VARCHAR2,
        pn_vendor_site_id IN       NUMBER,
        pv_invoice_num    IN       VARCHAR2,
        pv_amount         IN       VARCHAR2,
        pv_errbuf         OUT      VARCHAR2,
        pn_retcode        OUT      NUMBER
    );


-------------------------------------------------------------------------------------
 --  Nom           : LOAD_DATA
 --  Description   : Procédure de traitement des données de la table dka_sarsurtaxe_tmp_all
 --
 --  PARAMETRES    :
 --    pv_errbuf       Sortie
 --    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE load_data (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : UPDATE_AFTER_IMPORT_AP
--  Description   : Procédure de mise à jour de la table dka_sarsurtaxe_tmp_all après le traitement
--              standard 'programme d'importation de l'interface coopérative d'Oracle Payables'
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_after_import_ap (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : UPDATE_RA_CUST_TRX_LINE_GL_DIS
--  Description   : Procédure de mise à jour de la table ra_cust_trx_line_gl_dist_all
--              apres le transfert des factures AR dans PA
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_ra_cust_trx_line_gl_dis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : UPDATE_GL_JE_LINES_CUF
--  Description   : Procédure de mise à jour du cuf 'transféré dans AP' de la table gl_je_lines
--              après le transfert des lignes de facture contenant de la surtaxe
--              pour les clients de type GERICCO dans AP
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_gl_je_lines_cuf (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : PURGE_AP_INVOICES_INTERFACE
--  Description   : Procédure de purge des tables d'interfaces AP
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE purge_ap_invoices_interface (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : MAIN2
--  Description   : Procédure
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main2 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : UPDATE_GL_JE_LINES
--  Description   : Procédure qui permet de renseigner la référence de lettrage.
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_gl_je_lines (
        pv_invoice_num    IN       VARCHAR2,
        pv_nom_collecti   IN       VARCHAR2,
        pv_ccid           IN       NUMBER,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : LOAD_REF_LET
--  Description   : Procédure qui permet de renseigner la référence de lettrage dans la
--              table GL_JE_LINES.
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE load_ref_let (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : MAIN3
--  Description   : Procédure
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main3 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : INSERT_GL_INTERFACE_CONTROL
--  Description   : Procédure permettant l'insertion dans la table GL_INTERFACE_CONTROL
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE insert_gl_interface_control (
        pn_group_id           OUT      NUMBER,
        pn_interface_run_id   OUT      NUMBER,
        pv_errbuf             IN OUT   VARCHAR2,
        pn_retcode            OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : INSERT_GL_INTERFACE
--  Description   : Procédure permettant l'insertion dans la table GL_INTERFACE
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE insert_gl_interface (
        pn_group_id   IN       NUMBER,
        pv_errbuf     IN OUT   VARCHAR2,
        pn_retcode    OUT      NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : MAIN4
--  Description   : Procédure
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main4 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


-------------------------------------------------------------------------------------
--  Nom           : UPDATE_DKA_SARSURTAXE_TMP
--  Description   : Procédure de mise à jour du statut dans la table dka_sarsurtaxe_tmp
--              à la fin du traitement
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE update_dka_sarsurtaxe_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : MAIN5
--  Description   : Procédure
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main5 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


-------------------------------------------------------------------------------------------------------------------
--  Nom           : INSERT_DKA_SARSURTAXE_CTL_TMP
--  Description   : Insertion des éléments de surtaxe dans la table temporaire de contrôle
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
     PROCEDURE insert_dka_sarsurtaxe_ctl_tmp ( 
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
     );


-------------------------------------------------------------------------------------
--  Nom           : CONTROLE_FOURNISSEUR_ABSENT
--  Description   : Procédure de vérification que les fournisseurs sont tous présents
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE  controle_fournisseur_absent (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONTROLE_FOURNISSEUR_DOUBLON
--  Description   : Vérification que le code partenaire est bien associé à un seul fournisseur
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE controle_fournisseur_doublon ( 
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONTROLE_SITE_FOURNISSEUR_ABSENT
--  Description   : Vérification que le fournisseur a bien un site dupliqué
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
     PROCEDURE controle_site_frs_absent ( 
				 	pv_errbuf 	OUT VARCHAR2,
                    pn_retcode   OUT   NUMBER
     );

	 
-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONTROLE_FACTURE_NEGATIVE
--  Description   : Liste des factures négatives
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
     PROCEDURE controle_facture_negative ( 
				 	pv_errbuf 	OUT VARCHAR2,
                    pn_retcode   OUT   NUMBER
     );

 
-------------------------------------------------------------------------------------------------------------------
--  Nom           : BILAN_SURTAXE
--  Description   : Synthèse des lignes traitées par la surtaxe
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE bilan_surtaxe ( 
				 	pv_errbuf 	OUT VARCHAR2,
                    pn_retcode   OUT   NUMBER
    );


--------------------------------------------------------------------------------------
--  Nom           : MAIN6
--  Description   : Procédure de controle des données
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main6 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : main7
--  Description   : Lancement des éditions par centre de gestion
--
--  PARAMETRES    :
--          pv_invoices  varchar2
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	 varchar2
--	      pv_status	 varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE main7 (
        pv_errbuf               IN OUT   VARCHAR2,
        pn_retcode                 OUT   NUMBER,
        pv_include_all_invoices IN       VARCHAR2
    );
    
-------------------------------------------------------------------------------------------------------------------
--  Nom           : launch_xlaaccpb
--  Description   : Lancement du traitement Créer une comptabilisation
--
--  PARAMETRES    :
--          pv_invoices  varchar2
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	 varchar2
--	    pv_status	 varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE launch_xlaaccpb (
    pv_errbuf               IN OUT   VARCHAR2,
    pn_retcode                 OUT   NUMBER
);   

-------------------------------------------------------------------------------------------------------------------
--  Nom           : launch_apprvl
--  Description   : Lancement du traitement Valider des factures
--
--  PARAMETRES    :
--          pv_invoices  varchar2
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	 varchar2
--	    pv_status	 varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE launch_apprvl (
    pv_errbuf               IN OUT   VARCHAR2,
    pn_retcode                 OUT   NUMBER
);

-------------------------------------------------------------------------------------------------------------------
--  Nom           : launch_glxrcaut
--  Description   : Lancement du traitement de rapprochement
--
--  PARAMETRES    :
--          pv_invoices  varchar2
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	 varchar2
--	    pv_status	 varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE launch_glxrcaut (
    pv_errbuf               IN OUT   VARCHAR2,
    pn_retcode                 OUT   NUMBER
);   
	
END Dka_Sarsurtaxe_Pkg; -- Spécification du package
/
/*<TOAD_FILE_CHUNK>*/

SHOW ERRORS;

EXIT;
