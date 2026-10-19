create or replace PACKAGE  DKA_IPOEXTENGHERC_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IPOEXTENGHERC_PKG.pks
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_IPOEXTENGHERC_PKG.pks
-- DESCRIPTION       : DKA_IPOEXTENGHERC_PKG package créé pour l'interface DKA : Extraction des engagés vers Hercule 
---
--- AUTEUR           : F.Siham (Capgemini)
--- DATE DE CREATION : 21/05/2019
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 11/12/2020 ARA Evolution EDB248B - INT084 Engagés vers Hercule - complément

------------------------------------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement

  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) ;
  ------------------------------------------------------------------------------------
  --  Nom           : p_validate
-----------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN,
                       p_message   IN VARCHAR2 DEFAULT NULL);

  ------------------------------------------------------------------------------------
  --  Nom           : p_check_directory
  --  Description   : Verifie que le directory existe
  ------------------------------------------------------------------------------------
  PROCEDURE p_check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type);

  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_cmd
  --  Description   : Extrait des lignes de ventilations de commandes
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_cmd(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2, 
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2);

   ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_inv
  --  Description   : Extrait des lignes de ventilations des factures

  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_inv(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2, 
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2);

   ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_maind
  --  Description   : Extrait des lignes d'heure de main d'œuvre valorisées. 

  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_maind(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2, 
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2);


  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_refac
  --  Description   : Extrait des lignes de « refacturation interne ».
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --  11/12/2020 Evolution EDB248B - INT084 Engagés vers Hercule - complément
  ------------------------------------------------------------------------------------
  
  PROCEDURE p_extract_data_refac(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2, 
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2);

  ------------------------------------------------------------------------------------
  --  Nom           : Output_Header
  --  Description   : Procédure pour insérer une en-tête dans le fichier de sortie

  ------------------------------------------------------------------------------------  

  PROCEDURE output_header ;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT NOCOPY VARCHAR2, pn_retcode OUT NOCOPY NUMBER, P_DATE_DEBUT IN VARCHAR2, P_DATE_FIN IN VARCHAR2,P_EXTRACT_MAN IN VARCHAR2);
      ------------------------------------------------------------------------------------
  --  Nom           : bilan
  --  Description   : Affichage des stats

--- 11/12/2020 Evolution EDB248B - INT084 Engagés vers Hercule - complément
  ------------------------------------------------------------------------------------
  PROCEDURE bilan( p_date_debut varchar2,
                    p_date_fin varchar2,
                    p_extr_man varchar2,
                    p_file_name1 varchar2,
                    p_file_name2 varchar2,
                    p_file_name3 varchar2,
					p_file_name4 varchar2);
 procedure  compression_fichier_sortie;
END DKA_IPOEXTENGHERC_PKG;


/
SHOW ERRORS;

EXIT