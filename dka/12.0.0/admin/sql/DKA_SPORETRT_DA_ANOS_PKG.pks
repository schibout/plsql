-----------------------------------------------------------------------------------------------
-- CAPGEMINI NORD
-- PROJET 				: HELIOS.
-- NOM					: DKA_SPORETRT_DA_ANOS_PKG.pkg
-- DESCRIPTION			: DKA_SPORETRT_DA_ANOS_PKG package body
--				  		  package contenant les procédures de traitements des anomalies sur DA
--- AUTEUR				: Benjamin COUDRIER
--- DATE DE CREATION	: 15 juin 2012
-- COMMENTAIRE			: A exécuter sur SQLPLUS avec le user APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 18/05/2016 BDE Modification du nom du package 
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE DKA_SPORETRT_DA_ANOS_PKG
AS

	--------------------------------------------------------------------------------
	--  Nom           : init
	--  Description   : Procédure d'initialisation pour l'envoi de mail.
	--
	--  Paramètres    : pv_errbuf     	message d'erreur
	--                  pn_retcode   	code de retour
	--------------------------------------------------------------------------------
    PROCEDURE init (pv_errbuf    IN OUT   VARCHAR2,
					pn_retcode   OUT      NUMBER
					);

	--------------------------------------------------------------------------------
	--  Nom           : DA_Catalog_Non_Trans_Commande_Relance
	--  Description   : DA Catalogue non transformée automatiquement en commande.
	--
	--  Paramètres    : pv_errbuf     message d'erreur
	--                  pn_retcode    code de retour
	--------------------------------------------------------------------------------
	PROCEDURE DA_Catalog_Non_Trans_Cmd_Relan (pv_errbuf       OUT VARCHAR2,
											  pn_retcode      OUT NUMBER
											  );
													
													
	--------------------------------------------------------------------------------
	--  Nom           : DA_Catalog_Non_Trans_Commande_Notif
	--  Description   : DA Catalogue non transformée automatiquement en commande.
	--
	--  Paramètres    : pv_errbuf     message d'erreur
	--                  pn_retcode    code de retour
	--------------------------------------------------------------------------------
	PROCEDURE DA_Catalog_Non_Trans_Cmd_Notif (pv_errbuf       OUT VARCHAR2,
													 pn_retcode      OUT NUMBER
													);
	
	
	--------------------------------------------------------------------------------
	--  Nom           : DA_Statut_Incomplet
	--  Description   : DA en statut "INCOMPLET".
	--
	--  Paramètres    : pv_errbuf     message d'erreur
	--                  pn_retcode    code de retour
	--------------------------------------------------------------------------------
	PROCEDURE DA_Statut_Incomplet (pv_errbuf       OUT VARCHAR2,
								   pn_retcode      OUT NUMBER
								  );
	
	
	--------------------------------------------------------------------------------
	--  Nom           : DA_Statut_System_Saved
	--  Description   : DA en statut "SYSTEM SAVED".
	--
	--  Paramètres    : pv_errbuf     message d'erreur
	--                  pn_retcode    code de retour
	--------------------------------------------------------------------------------
	PROCEDURE DA_Statut_System_Saved (pv_errbuf       OUT VARCHAR2,
								                    pn_retcode      OUT NUMBER,
									                  pv_mail_envoi   IN VARCHAR2,
                                    pv_mail_test    IN VARCHAR2
								     );
	
	
	--------------------------------------------------------------------------------
	--  Nom           : recherche_mail
	--  Description   : Recherche de l'adresse mail ainsi que du nom de l'utilisateur
	--					qui a fait la demande d'achat.
	--
	--  Paramètres    : pv_errbuf     	message d'erreur
	--                  pn_retcode   	code de retour
	--					pv_mail			mail de l'utilisateur qui a fait la DA.
	--					pv_name_mail	mail et nom de l'utilisateur qui a fait la DA.
	--					pn_header_id	identifiant de l'entête de la DA
	--------------------------------------------------------------------------------
	PROCEDURE recherche_mail (pv_errbuf			    	OUT	VARCHAR2,
                            pn_retcode			    OUT NUMBER,
                            pv_mail				      OUT VARCHAR2,
                            pv_name_mail			  OUT VARCHAR2,
                            pv_appart_demandeur	OUT	VARCHAR2,
                            pn_header_id			  IN	NUMBER,
                            pv_mail_test        IN  VARCHAR2
                            );
	
	
	--------------------------------------------------------------------------------
	--  Nom           : envoi_mail
	--  Description   : Envoi d'un mail à l'utilisateur qui a fait la demande de DA.
	--
	--  Paramètres    : pv_errbuf     	message d'erreur
	--                  pn_retcode   	code de retour
	--					pv_mail			mail de l'utilisateur qui a fait la DA.
	--					pv_name_mail	mail et nom de l'utilisateur qui a fait la DA.
	--------------------------------------------------------------------------------
    PROCEDURE envoi_mail (pv_errbuf       		OUT     VARCHAR2,
						  pn_retcode      		OUT     NUMBER,
						  pv_mail		  		IN		VARCHAR2,
						  pv_name_mail	  		IN		VARCHAR2,
						  pv_appart_demandeur	IN		VARCHAR2,
						  pv_segment1	  		IN		VARCHAR2,
						  pv_description  		IN		VARCHAR2
						  );
	
	
END DKA_SPORETRT_DA_ANOS_PKG;
/
SHOW ERROR

EXIT
