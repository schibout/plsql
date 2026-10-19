CREATE OR REPLACE PACKAGE DKA_IAPBANK_PKG
AS
------------------------------------------------------------------------
-- $Id: DKA_IAPBANK_PKG.pks
-- Capgemini
-- Nom              : DKA_IAPBANK_PKG.pks
-- Description      : Spécification du package DKA_IAPBANK_PKG
-- Auteur           : Coudrier Benjamin
-- Date de création : 27/04/2012
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------
 

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


------------------------------------------------------------------------------------
--  Nom           : historize_file_tmp_gui
--					Historise les données de la table DKA_IAPBANK_GUI_TMP 
--					dans la table DKA_IAPBANK_GUI_TMP_HIST
--  PARAMETRES    :
--      vn_error  : numéro du problème.
--      vv_ch_pb :  description du problème.
--  VALEUR RETOURNEE :
------------------------------------------------------------------------------------
PROCEDURE historize_file_tmp_gui ( vn_error IN OUT NUMBER,
								   vv_ch_pb IN OUT VARCHAR2);

------------------------------------------------------------------------------------
--  Nom           : historize_file_tmp_etab
--					Historise les données de la table DKA_IAPBANK_ETAB_TMP 
--					dans la tables DKA_IAPBANK_ETAB_TMP_HIST
--  PARAMETRES    :
--      vn_error  : numéro du problème.
--      vv_ch_pb :  description du problème.
--  VALEUR RETOURNEE :
------------------------------------------------------------------------------------
PROCEDURE historize_file_tmp_etab (	vn_error IN OUT NUMBER,
									vv_ch_pb IN OUT VARCHAR2);

------------------------------------------------------------------------------------
--  Nom           : dka_chgt_file_situa_gui
--					Chargement fichier Guichets (FGD Banque de France)
--					Fichier Situation
--
--  PARAMETRES    :
--      access_id  : id du fichier
--      pv_file_id : nom du fichier
--  VALEUR RETOURNEE :
------------------------------------------------------------------------------------
FUNCTION dka_chgt_file_situa_gui(access_id   IN           NUMBER,
								 pv_file_id OUT           VARCHAR2) RETURN VARCHAR2;

------------------------------------------------------------------------------------
--  Nom           : dka_chgt_file_situa_etab
--					Chargement fichier Etablissement (FGD Banque de France)
--					Fichier Situation
--
--  PARAMETRES    :
--      access_id  : id du fichier
--      pv_file_id : nom du fichier
--  VALEUR RETOURNEE :
------------------------------------------------------------------------------------
FUNCTION dka_chgt_file_situa_etab(access_id   IN           NUMBER,
    							  pv_file_id OUT           VARCHAR2) RETURN VARCHAR2;

/*
------------------------------------------------------------------------------------
--  Nom           : dka_chgt_file_mvt_etab
--					Chargement fichier Etablissement (FGD Banque de France)
--					Fichier Mouvement
--
--  PARAMETRES    :
--      access_id  : id du fichier
--      pv_file_id : nom du fichier
--  VALEUR RETOURNEE :
------------------------------------------------------------------------------------
FUNCTION dka_chgt_file_mvt_etab(access_id   IN           NUMBER,
								pv_file_id  OUT          VARCHAR2) RETURN VARCHAR2 ;
								
------------------------------------------------------------------------------------
--  Nom           : xxve_chgt_file_mvt_gui
--					Chargement fichier Guichets (FGD Banque de France)
--					Fichier Mouvement
--
--  PARAMETRES    :
--      access_id  : id du fichier
--      pv_file_id : nom du fichier
--  VALEUR RETOURNEE :
------------------------------------------------------------------------------------
FUNCTION dka_chgt_file_mvt_gui(access_id   IN           NUMBER,
								pv_file_id  OUT          VARCHAR2) RETURN VARCHAR2 ;

*/
-----------------------------------------------------------------
--  NOM           : controle_nbr_enreg_file
--  DESCRIPTION   : Procédure de contrôle du nombre d'enregistrement.
--
--  PARAMETRES :  P_RETCODE             code retour out
--  			  P_ERRBUF              description de l'erreur out
--
-----------------------------------------------------------------
PROCEDURE controle_nbr_enreg_file(p_errbuf        OUT NOCOPY VARCHAR2,
								  p_retcode       OUT NOCOPY NUMBER);

-----------------------------------------------------------------
--  NOM           : controle_coherence_file
--  DESCRIPTION   : Procédure de contrôle de la cohérence de certains enregistrement.
--
--  PARAMETRES :  p_retcode             code retour out.
--  			  p_errbuf              description de l'erreur out.
--				  p_maj					flag de mise à jour des données.
--
-----------------------------------------------------------------
PROCEDURE controle_coherence_file (p_errbuf        	OUT NOCOPY VARCHAR2,
								   p_retcode       	OUT NOCOPY NUMBER);

-----------------------------------------------------------------
--  NOM           : verif_end_guichet.
--  DESCRIPTION   : Procédure de vérification de l'existance d'une
--                  date de fin dans Oracle Application.
--
--  PARAMETRES :  p_retcode             code retour out.
--  			  p_errbuf              description de l'erreur out.
--				  p_maj					flag de mise à jour des données.
--
-----------------------------------------------------------------
PROCEDURE verif_end_guichet (p_errbuf        	OUT NOCOPY VARCHAR2,
							 p_retcode       	OUT NOCOPY NUMBER,
							 p_maj				IN	VARCHAR2);
								 
------------------------------------------------------------------------------------
--  Nom           : dka_date_fin_guichet
--
--  PARAMETRES    :
--      code_enregistrement  : code banque
--      code_guichet : code agence bancaire
--  VALEUR RETOURNEE :
--		return true s'il existe une date de fin sur le guichet dans le fichier FGD.
------------------------------------------------------------------------------------
/*FUNCTION dka_date_fin_guichet(pv_code_etablis  	IN     VARCHAR2,
						   pv_code_guichet		IN     VARCHAR2,
						   pn_errbuf			OUT	   NOCOPY VARCHAR2,
						   pn_retcode			OUT	   NOCOPY NUMBER) RETURN BOOLEAN;*/
							   
-----------------------------------------------------------------
--  NOM           : simulation_insert_file
--  DESCRIPTION   : Procédure de contrôle des règles de gestion.
--
--  PARAMETRES :  p_retcode             code retour out.
--  			  p_errbuf              description de l'erreur out.
--				  p_maj					flag de mise à jour des données.
--
-----------------------------------------------------------------
PROCEDURE simulation_insert_file (p_errbuf        	OUT NOCOPY VARCHAR2,
								   p_retcode       	OUT NOCOPY NUMBER,
								   p_maj			IN	VARCHAR2);
					
-----------------------------------------------------------------
--  NOM           : main
--  DESCRIPTION   : Procédure principale de mise à jour du référentiel bancaire.
--
--  PARAMETRES 	: pv_retcode          code retour out
--             	  pn_errbuf           description de l'erreur out
--				  pv_maj			  flag de mise à jour ou de contrôle
-----------------------------------------------------------------
PROCEDURE main(pv_errbuf   OUT VARCHAR2,
				pn_retcode  OUT NUMBER,
				PV_MAJ		IN VARCHAR2);

			   
END DKA_IAPBANK_PKG;
/
show errors

exit;
