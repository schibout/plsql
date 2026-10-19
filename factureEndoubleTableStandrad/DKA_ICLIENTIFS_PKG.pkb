create or replace PACKAGE DKA_SAPFRSDUPLI_PKG IS
--------------------------------------------------------------------------------------------
-- F-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SAPFRSDUPLI_PKG.pkb
-- Description      : DKA_SAPFRSDUPLI_PKG package body
-- Auteur           : S.HAHIOUI(Capgemini)
-- Date de création : 13/12/2019
-- Doc. associée    :
-- Commentaire      : à exécuter sous SQLPLUS avec l'utilisateur APPS
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Date           Qui Description
-- -------------- --- ---------------------------------------------------------------
------------------------------------------------------------------------------------
-- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
--                    pn_retcode     Sortie Code Retour de la procédure
--                                   '0' : Normal
--                                   '1' : Avertissement
--                                   '2' : Erreur
--                  
-- VALEUR RETOURNEE :
-- Description       :
-- Valeurs possibles :
------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*
 *************************************************************************
 * PROCEDURE NAME : 
 * 
 * DESCRIPTION
 *  Procédure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

 TYPE tabtype is  table OF VARCHAR2(20);

 PROCEDURE CONTROLE_SITE_FOURNISSEUR(
                                      p_retcode                OUT NUMBER,
                                      pv_id_site_fournisseur   IN  NUMBER,
									                    pn_resultat_controle     OUT Varchar2,
                                      pv_id_liste_erreur       OUT NUMBER
								     );
 PROCEDURE DUPLICATION_SITE_FOURNISSEUR ( 
                                      p_retcode      			      OUT NUMBER,
									                    p_perimetre 			        IN  tabtype,
                                      pv_id_site_fournisseur    IN  NUMBER,
									                    pv_nombre_succes          OUT NUMBER,
									                    pv_nombre_echoues         OUT NUMBER,
                                      pv_nombre_ignores         OUT NUMBER,
									                    pn_resultat_duplication   OUT Varchar2,
									                    pv_nombre_existe          OUT NUMBER,
                                      pv_id_liste_erreur        OUT NUMBER,
                                      pv_id_site_cree           OUT NUMBER
								     );
 PROCEDURE COMPARE_VALUE(p_vendor_id_ref IN NUMBER,
                        p_vendor_id_dup IN NUMBER) ;									 
 PROCEDURE MAJ_SITE_FOURNISSEUR (
                                   p_id_site_frns_ref    IN  NUMBER,
                                   p_result_maj          OUT VARCHAR2,
                                   p_nbr_maj_succes      OUT NUMBER,
                                   p_nbr_maj_echec       OUT NUMBER,
                                   p_maj_code_echec      OUT NUMBER,
								                   p_id_liste_erreur     OUT NUMBER);									 
 END DKA_SAPFRSDUPLI_PKG;
/
SHOW ERRORS
EXIT