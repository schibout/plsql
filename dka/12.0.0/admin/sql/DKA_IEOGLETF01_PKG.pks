CREATE OR REPLACE PACKAGE DKA_IEOGLETF01_PKG AS
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		         : DKA_IEOGLETF01_PKG.pks
-- DESCRIPTION	     : DKA_IEOGLETF01_PKG package spec : package pour altaven: Extraction vers altaven  
---
--- AUTEUR	         : AZIZ NOUJOUD(CGEY)
--- DATE DE CREATION : 29/05/2002
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 21/08/2003 ADR MAIN : Ajout du paramètre d'entrée pv_company_num.
---                INIT : Declaration de la procédure.
--- 04/08/2016 JPE MIGRATION R12   
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---------------------------------------------------------------------------------------------------
--  Nom           : Init
--  Description   : Procédure d'initialisation des varaibles globales
--                 

--  PARAMETRES    :
--  pv_errbuf    		Entrée/Sortie		message d'erreur

--  VALEUR RETOURNEE :	pn_retcode
--     Description       : code de retour => Statut du traitement OA
--     Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------------------------------------
PROCEDURE init(pv_errbuf             IN      OUT       VARCHAR2,
               pn_retcode                    OUT       NUMBER,
               pv_company_num        IN                VARCHAR2,
			   pv_type_livre 	  IN                VARCHAR2);
               
---------------------------------------------------------------------------------------------------
--  Nom           : extraction_altaven
--  Description   : Procédure permet de produire le fichier altaven
--                 

--  PARAMETRES    :
--  pv_errbuf    		Entrée/Sortie		message d'erreur

--  VALEUR RETOURNEE :	pn_retcode
--     Description       : code de retour => Statut du traitement OA
--     Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------------------------------------
PROCEDURE extraction_altaven(  pv_period_year    IN            NUMBER,
                             pv_period_name    IN            VARCHAR2,
                             pv_errbuf        IN    OUT     VARCHAR2,
                             pn_retcode             OUT     NUMBER);
                                                                                                    			                                                  
---------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale du traitement d'extraction de GL vers altaven
--                 

--  PARAMETRES    :
--  pv_errbuf    		Entrée/Sortie		message d'erreur

--  VALEUR RETOURNEE :	pn_retcode
--     Description       : code de retour => Statut du traitement OA
--     Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------------------------------------
PROCEDURE main( pv_errbuf         IN    OUT     VARCHAR2,
                pn_retcode        IN    OUT     NUMBER,
                pv_period_year    IN            NUMBER,
                pv_period_name    IN            VARCHAR2,
                pv_company_num    IN            VARCHAR2,
				pv_type_livre 	  IN                VARCHAR2);
                
------------------------------------------------------------------------------------------------------

END DKA_IEOGLETF01_PKG;
/
SHOW ERROR
EXIT;
/
