CREATE OR REPLACE PACKAGE DKA_SPOASS_FOURN_PKG IS
------------------------------------------------------------------------------------
-- $Id: DKA_SPOASS_FOURN_PKG.pks 149 2008-03-12 16:52:16Z NORDEST\tbonduae $
-- Capgemini
-- PROJET            : VEOLIA Oracle Applications
-- NOM               : DKA_SPOASS_FOURN_PKG
-- DESCRIPTION       : package d'assainissement des référentiels fournisseurs
---
--- AUTEUR           : Jonathan Dequidt (Capgemini)
--- DATE DE CREATION : 26/02/2008
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
------------------------------------------------------------------------------------
--- 22/07/2020 SHA SPE130 - 0SPF20080028 DÉSACTIVATION/RÉACTIVATION D’UN SITE DE RÈGLEMENT FOURNISSEUR  : 3.3
----           MAIN4
--- ---------- --- -----------------------------------------------------------------
--- 23/08/2016 JPE MIGRATION R12
------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
--  Nom           : main_1
--  Description   : désactivation des sites fournisseurs jamais utilisés
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--      pn_org_ope      organisation opérationnelle
--      pd_date         date de validation
--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_1(pv_errbuf   OUT VARCHAR2,
                   pn_retcode  OUT NUMBER,
                   pn_org_ope  IN  NUMBER,
                   pd_date     IN  VARCHAR2);
                   
------------------------------------------------------------------------------------
--  Nom           : main_2
--  Description   : désactivation des sites fournisseurs plus utilisés et dont le 
--                  solde AX est à 0
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--      pn_org_ope      organisation opérationnelle
--      pd_date         date de validation
--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_2(pv_errbuf   OUT VARCHAR2,
                   pn_retcode  OUT NUMBER,
                   pn_org_ope  IN  NUMBER,
				   pn_ssmvt_mois IN VARCHAR2
                   -- pd_date_achat     IN  VARCHAR2,
				   --  pd_date_finance IN  VARCHAR2
				  );
                   
------------------------------------------------------------------------------------
--  Nom           : main_3
--  Description   : désactivation des entêtes fournisseurs qui n'ont plus de sites 
--                  actifs
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_3(pv_errbuf   OUT VARCHAR2,
                   pn_retcode  OUT NUMBER);
------------------------------------------------------------------------------------
--  Nom           : main_4
--  Description   : Désactivation/réactivation d’un site de règlement fournisseur
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--  VALEUR RETOURNEE :
--  Valeurs possibles : 0: deroulement correct
--                      2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_4(pv_errbuf          OUT VARCHAR2,
                   pn_retcode         OUT NUMBER,
				   p_perimetre        in VARCHAR2,
				   p_fournisseur      in varchar2,
				   p_site_fournisseur in varchar2,
				   p_action           in varchar2);				   

END DKA_SPOASS_FOURN_PKG;

/
SHOW ERRORS
EXIT;
