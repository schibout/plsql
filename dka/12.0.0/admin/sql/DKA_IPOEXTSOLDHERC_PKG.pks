create or replace PACKAGE  DKA_IPOEXTSOLDHERC_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IPOEXTENGHERC_PKG.pks
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_IPOEXTSOLDHERC_PKG.pks
-- DESCRIPTION       : DKA_IPOEXTSOLDHERC_PKG package créé pour l'interface DKA : Extraction des soldes des tâches travaux vers Hercule 
---
--- AUTEUR           : F.Siham (Capgemini)
--- DATE DE CREATION : 04/07/2019
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- 25/07/2019       : A.AMENKOUR correction des calcules des Soldes
--- ---------- --- -----------------------------------------------------------------

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
     --  Nom           : p_extract_data
  --  Description   : Alimentation de la table de travail
  ------------------------------------------------------------------------------------  
  PROCEDURE p_extract_data (P_PERIOD_NAME IN VARCHAR2) ;
  ------------------------------------------------------------------------------------
   --  Nom           : p_extract_data_type_p3
  --  Description   : Extrait des lignes des travaux de type P3
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_type_p3(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_PERIOD_NAME    IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2);

  ------------------------------------------------------------------------------------
   --  Nom           : p_extract_data_type_p6
  --  Description   : Extrait des lignes des travaux de type P6
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_type_p6(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_PERIOD_NAME    IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2);

  ------------------------------------------------------------------------------------
  --  Nom           : Output_Header
  --  Description   : Procédure pour insérer une en-tête dans le fichier de sortie

  ------------------------------------------------------------------------------------  

  PROCEDURE output_header ;
  ------------------------------------------------------------------------------------
  --  Nom           : PURGE_TABLE
  --  Description   : Vider la table de travail

  -----------------------------------------------------------------------------------  
  PROCEDURE PURGE_TABLE ;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT NOCOPY VARCHAR2, pn_retcode OUT NOCOPY NUMBER, P_PERIOD_NAME    IN VARCHAR2);
      ------------------------------------------------------------------------------------
  --  Nom           : bilan
  --  Description   : Affichage des stats

  ------------------------------------------------------------------------------------
  PROCEDURE bilan( P_PERIOD_NAME    IN VARCHAR2,
                    p_file_name1 varchar2,
                    p_file_name2 varchar2);
 procedure  compression_fichier_sortie;
END DKA_IPOEXTSOLDHERC_PKG;


/
SHOW ERRORS;

EXIT