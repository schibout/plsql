CREATE OR REPLACE PACKAGE DKA_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_TOOLS_PKG.pks
-- DESCRIPTION       : DKA_TOOLS_PKG package spec : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  07/06/2016 MEG Ajout de la procedure Create_Table_Online_Patching
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Types globaux
-----------------------------------------------------------------
    TYPE char255tabtyp IS TABLE OF VARCHAR2 (255) INDEX BY BINARY_INTEGER;

-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------

    gv_debug_mode        VARCHAR2 (1);
    
    tab_request_params   char255tabtyp;
    tab_cuf_flex_value   char255tabtyp;


-----------------------------------------------------------------
--  Nom           : NUMERIC_CHECK
--  Description   : Fonction de contrôle de la présence exclusive
--                  de caracteres numériques dans un champ
--
--  PARAMETRES :
--     pv_field     Entrée      Champ a contrôler
--
--  VALEUR RETOURNEE :
--     Description       :  code retour de validité
--     Valeurs possibles :  '0'=OK, '1'=contient des caracteres non numériques
-----------------------------------------------------------------
    FUNCTION numeric_check (
        pv_field   IN   VARCHAR2
    )
        RETURN VARCHAR2;

    --PRAGMA RESTRICT_REFERENCES (NUMERIC_CHECK, RNDS, RNPS, WNDS, WNPS);


-----------------------------------------------------------------
--  Nom           : PUT_LOG_MESSAGE
--  Description   : Procédure insérant un message dans le log du
--                  traitement.
--
--  PARAMETRES :
--     pv_message   Entrée      Message a insérer
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_log_message (
        pv_message   IN   VARCHAR2
    );


-----------------------------------------------------------------
--  Nom           : PUT_DEBUG_MESSAGE
--  Description   : Procédure insérant un message dans le log du
--                  traitement si on est en mode debug
--
--  PARAMETRES :
--     pv_message   Entrée      Message a insérer
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_debug_message (
        pv_message   IN   VARCHAR2
    );

    --PRAGMA RESTRICT_REFERENCES (PUT_DEBUG_MESSAGE, WNDS);

    -----------------------------------------------------------------
--  Nom           : PUT_OUTDEBUG_MESSAGE
--  Description   : Procédure insérant un message a la fois dans le log du
--                  traitement si on est en mode debug et dans le fichier
--                  de sortie
--
--  PARAMETRES :
--     pv_message   Entrée      Message a insérer
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_outdebug_message (
        pv_message   IN   VARCHAR2
    );


-----------------------------------------------------------------
--  Nom           : PUT_OUT_HEADER
--  Description   : Procédure insérant une entete dans le fichier
--                  de sortie avec comme titre le nom du traitement
--                  la date et l'heure de lancement.
--
--  PARAMETRES :
--     N/A
--
--  VALEUR RETOURNEE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_out_header;

-----------------------------------------------------------------
--  Nom           : GET_FILENAME
--  Description   : Fonction qui détermine le nom d'un fichier a partir
--                  de son masque
--
--  PARAMETRES :
--     pv_filename_format Entrée     Masque
--
--  VALEUR RETOURNEE :
--     Description       :  Nom du fichier
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION get_filename (
        pv_filename_format   IN   VARCHAR2
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_filename, WNDS);


-----------------------------------------------------------------
--  Nom           : GET_ENVIRONMENT_VARIABLE
--  Description   : Fonction qui détermine la valeur d'une variable
--                  d'environnement
--                  /!\ Ne fonctionne que dans un traitement simultané
--
--  PARAMETRES :
--     pv_variable_name   Entrée      Nom de la variable
--
--  VALEUR RETOURNEE :
--     Description       :  Valeur de la variable
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION get_environment_variable (
        pv_variable_name   IN   VARCHAR2
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_environment_variable, WNDS);


-----------------------------------------------------------------
--  Nom           : OPEN_UTL_FILE
--  Description   : Procédure qui ouvre un fichier pour UTL_FILE
--                  en écriture
--
--  PARAMETRES :
--      pv_path             Entrée      Répertoire du fichier
--      pv_filename         Entrée      Nom du fichier
--      pv_file             Sortie      Fichier
--      pv_err_msg          Sortie      Message d'erreur
--
--  VALEUR RETOURNEE :
--     Description       :  Fichier
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE open_utl_file (
        pv_path       IN       VARCHAR2,
        pv_filename   IN       VARCHAR2,
        pv_file       OUT      UTL_FILE.file_type,
        pv_err_msg    OUT      VARCHAR2
    );


-----------------------------------------------------------------
--  Nom           : OPEN_UTL_FILE_APPEND
--  Description   : Procédure qui ouvre un fichier pour UTL_FILE
--                  en écriture en Mode APPEND
--
--  PARAMETRES :
--      pv_path             Entrée      Répertoire du fichier
--      pv_filename         Entrée      Nom du fichier
--      pv_file             Sortie      Fichier
--      pv_err_msg          Sortie      Message d'erreur
--
--  VALEUR RETOURNEE :
--     Description       :  Fichier
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE open_utl_file_append (
        pv_path       IN       VARCHAR2,
        pv_filename   IN       VARCHAR2,
        pv_file       OUT      UTL_FILE.file_type,
        pv_err_msg    OUT      VARCHAR2
    );


-----------------------------------------------------------------
--  Nom           : GET_MESSAGE
--  Description   : Procédure qui récupere un message OA
--
--  PARAMETRES :
--      pv_application           Entrée      Code de l'application
--      pv_name                  Entrée      Nom du message
--      pv_tokenx                Entrée      Nom des parametres dans le message
--      pv_valuex                Entrée      Valeur des parametres dans le message
--
--  VALEUR RETOURNEE :
--     Description       : Libellé du message
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION get_message (
        pv_application   IN   VARCHAR2,
        pv_name          IN   VARCHAR2,
        pv_token1        IN   VARCHAR2 DEFAULT NULL,
        pv_value1        IN   VARCHAR2 DEFAULT NULL,
        pv_token2        IN   VARCHAR2 DEFAULT NULL,
        pv_value2        IN   VARCHAR2 DEFAULT NULL,
        pv_token3        IN   VARCHAR2 DEFAULT NULL,
        pv_value3        IN   VARCHAR2 DEFAULT NULL,
        pv_token4        IN   VARCHAR2 DEFAULT NULL,
        pv_value4        IN   VARCHAR2 DEFAULT NULL,
        pv_token5        IN   VARCHAR2 DEFAULT NULL,
        pv_value5        IN   VARCHAR2 DEFAULT NULL,
        pv_token6        IN   VARCHAR2 DEFAULT NULL,
        pv_value6        IN   VARCHAR2 DEFAULT NULL,
        pv_token7        IN   VARCHAR2 DEFAULT NULL,
        pv_value7        IN   VARCHAR2 DEFAULT NULL,
        pv_token8        IN   VARCHAR2 DEFAULT NULL,
        pv_value8        IN   VARCHAR2 DEFAULT NULL,
        pv_token9        IN   VARCHAR2 DEFAULT NULL,
        pv_value9        IN   VARCHAR2 DEFAULT NULL,
        pv_token10       IN   VARCHAR2 DEFAULT NULL,
        pv_value10       IN   VARCHAR2 DEFAULT NULL
    )
        RETURN VARCHAR2;

    PRAGMA RESTRICT_REFERENCES (get_message, WNDS);


-----------------------------------------------------------------
--  Nom           : GET_PARAMETER
--  Description   : Procédure qui récupere des parametres
--
--  PARAMETRES :
--      pv_program_code          Entrée      Nom du programme
--      pv_parameter_name        Entrée      Nom des parametres
--      pv_data                  Sortie      listes des parametres
--      pn_retcode               Sortie      Code erreur
--      pv_err_msg               Sortie      Message d'erreur
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE get_parameter (
        pv_program_code     IN       VARCHAR2,
        pv_parameter_name   IN       VARCHAR2,
        pr_data             OUT      dka_parameters%ROWTYPE,
        pn_retcode          OUT      NUMBER,
        pv_err_msg          OUT      VARCHAR2
    );

    PRAGMA RESTRICT_REFERENCES (get_parameter, WNDS);

----------------------------------------------------------------------------------------
--  Nom           : GET_CODE_COMBINATION_ID
--  Description   : Procédure permettant de déterminer le code_combination_id
--                  correspondant a la combinaison passée en parametre
--                  Si la combinaison n'existe pas, elle est créée
--  PARAMETRES :
--    pv_segment1       Entrée
--    pv_segment2       Entrée
--    pv_segment3       Entrée
--    pv_segment4       Entrée
--    pv_segment5       Entrée
--    pv_segment6       Entrée
--    pv_segment7       Entrée
--    pv_segment8       Entrée
--    pv_segment9       Entrée
--    pv_segment10      Entrée
--    pv_segment11      Entrée
--    pv_segment12      Entrée
--
--    pn_ccid           Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE get_code_combination_id (
        pv_segment1              IN       VARCHAR2,
        pv_segment2              IN       VARCHAR2,
        pv_segment3              IN       VARCHAR2,
        pv_segment4              IN       VARCHAR2,
        pv_segment5              IN       VARCHAR2,
        pv_segment6              IN       VARCHAR2,
        pv_segment7              IN       VARCHAR2,
        pv_segment8              IN       VARCHAR2,
        pv_segment9              IN       VARCHAR2,
        pv_segment10             IN       VARCHAR2,
        pv_segment11             IN       VARCHAR2,
        pv_segment12             IN       VARCHAR2,
        pn_code_combination_id   OUT      NUMBER,
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_validation_flag       IN       VARCHAR2 DEFAULT 'Y'
    );
    
----------------------------------------------------------------------------------------
--  Nom           : GET_CODE_COMBINATION_ID
--  Description   : Procédure permettant de déterminer le code_combination_id
--                  correspondant a la combinaison passée en parametre
--                  Si la combinaison n'existe pas, elle est créée
--                  Si la combinaison n'existe pas, elle est créée
--  PARAMETRES :
--    pv_clef       Entrée

--
--    pn_ccid           Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE get_code_combination_id (
		    pv_clef					         IN       VARCHAR2,
        pn_code_combination_id   OUT      NUMBER,
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_validation_flag       IN       VARCHAR2 DEFAULT 'Y'
    );
  
    

-----------------------------------------------------------------
--  Nom           : CHECK_DKA_PARAMETERS / TECHNIQUE
--  Description   : Procédure qui liste les parametres non valides
--                  dans la table dka_parameters
--
--  PARAMETRES :
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-----------------------------------------------------------------
    PROCEDURE check_dka_parameters (
        pv_program_code   VARCHAR2 DEFAULT NULL
    );

-------------------------------------------------------------------------------------------------------------------

--  Nom           : SEGMENT_SIZE 
--  Description   : Retourne la longueur d'un segment de clé passé en 
--  parametre
--
--  PARAMETRES    :
--    pn_segment_num  NUMBER
--  VALEUR RETOURNEE :
--     Valeurs possibles :     0 : ERREUR
--                         Autre : deroulement sans erreur
-------------------------------------------------------------------------------------------------------------------

    FUNCTION segment_size (pn_segment_num IN NUMBER) RETURN NUMBER;    

---------------------------------------------------------------------------------------
--  Nom           : get_flex_key_seg_value_set
--  Description   : Renvoie l'id et le nom du jeu de valeur d'un segment d'une des clés
---------------------------------------------------------------------------------------
    PROCEDURE get_flex_key_seg_value_set (
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_legal_flex_key_flag   IN       VARCHAR2 DEFAULT 'N' -- = 'Y' si on considere la ccf des organisations légales
                                                              ,
        pn_segment_num           IN       NUMBER,
        pn_flex_value_set_id     OUT      NUMBER,
        pv_flex_value_set_name   OUT      VARCHAR2
    );


---------------------------------------------------------------------------------------
--  Nom           : ins_prog_message
--  Description   : Insere un message dans la table d'erreurs DKA_PROGRAM_MESSAGES
---------------------------------------------------------------------------------------
    PROCEDURE ins_prog_message (
        pn_request_id     IN   NUMBER,
        pv_prog_name      IN   VARCHAR2,
        pv_source         IN   VARCHAR2 DEFAULT 'ETL',
        pv_table_name     IN   VARCHAR2,
        pv_table_id       IN   VARCHAR2,
        pv_column_name    IN   VARCHAR2,
        pv_column_value   IN   VARCHAR2,
        pv_message_type   IN   VARCHAR2 DEFAULT 'E',
        pv_message_text   IN   VARCHAR2
    );

------------------------------------------------------------------------------------
--  Nom           : GET_CUF_FLEX_VALUE
--  Description   : Cette procédure permet de récupérer les valeurs des CUF
--
--  PARAMETRES    :
--  pv_flex_value
--  pv_flex_value_set_name
--  VALEUR RETOURNEE :
--     CUF (tab_cuf_flex_value) : Tableau regroupant toutes les valeurs d'attributes
--     Description       : 0 si tout se deroule correctement, 2 sinon.
--     Valeurs possibles : En cas d'erreur elle retourne le message d'erreur ORA SQLERRM.
------------------------------------------------------------------------------------

    
    PROCEDURE get_cuf_flex_value (
               pv_flex_value          IN   VARCHAR2
             , pv_flex_value_set_name IN   VARCHAR2
             , pv_errbuf              OUT  VARCHAR2
             , pn_retcode             OUT  NUMBER     
    );

----------------------------------------------------------------------------------------
--  Nom           : GET_SEGMENTS_FROM_CCID
--  Description   : Procédure permettant de déterminer les segments
--                  correspondant a la combinaison a partir du code_combination_id
--  PARAMETRES :
--    pn_ccid                       Entrée
--    pv_segment1                   Sortie
--    pv_segment2                   Sortie
--    pv_segment3                   Sortie
--    pv_segment4                   Sortie
--    pv_segment5                   Sortie
--    pv_segment6                   Sortie
--    pv_segment7                   Sortie
--    pv_segment8                   Sortie
--    pv_segment9                   Sortie
--    pv_segment10                  Sortie
--    pv_segment11                  Sortie
--    pv_segment12                  Sortie
--    pv_concateneted_segments      Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE get_segments_from_ccid (
        pn_code_combination_id     IN       NUMBER,
        pv_segment1                OUT      VARCHAR2,
        pv_segment2                OUT      VARCHAR2,
        pv_segment3                OUT      VARCHAR2,
        pv_segment4                OUT      VARCHAR2,
        pv_segment5                OUT      VARCHAR2,
        pv_segment6                OUT      VARCHAR2,
        pv_segment7                OUT      VARCHAR2,
        pv_segment8                OUT      VARCHAR2,
        pv_segment9                OUT      VARCHAR2,
        pv_segment10               OUT      VARCHAR2,
        pv_segment11               OUT      VARCHAR2,
        pv_segment12               OUT      VARCHAR2,
        pv_concateneted_segments   OUT      VARCHAR2,
        pv_errbuf                  OUT      VARCHAR2,
        pn_retcode                 OUT      NUMBER
    );


-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_REQUEST_SET
--  Description   : Lancement d un jeu de traitement
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pv_program_code         IN      VARCHAR2    Code du Jeu de traitement a lancer
--  pv_user         IN  VARCHAR2    User qui lance le jeu
--  pv_resp         IN  VARCHAR2    Responsabilite
--      pn_request_id           OUT     NUMBER      ID du jeu lance
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    

    PROCEDURE get_request_set_params (
        pv_errbuf                   OUT      VARCHAR2,
        pn_retcode                  OUT      NUMBER,
        pn_application_id           IN       NUMBER,
        pn_request_set_id           IN       NUMBER DEFAULT NULL,
        pn_request_set_program_id   IN       NUMBER DEFAULT NULL,
        pn_prog_application_id      IN       NUMBER DEFAULT NULL,
        pn_program_id               IN       NUMBER DEFAULT NULL
    );

    PROCEDURE launch_request_set (
        pv_errbuf         OUT      VARCHAR2,
        pn_retcode        OUT      NUMBER,
        pv_application    IN       VARCHAR2,
        pv_program_code   IN       VARCHAR2,
        pv_user           IN       VARCHAR2,
        pv_resp           IN       VARCHAR2,
        pn_request_id     OUT      NUMBER
    );


----------------------------------------------------------------------------------------
--  Nom           : get_code_societe
--  Description   : Procédure qui donne le code societe a partir de l'org_id
--
--
--  PARAMETRES :
--          pn_org_id           Entrée
--          pv_soc                  Sortie
--          pv_errbuf           Entrée  Sortie
--              pn_retcode              Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_code_societe (
        pn_org_id    IN       NUMBER,
        pv_soc       OUT      VARCHAR2,
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


---------------------------------------------------------------------------------------
--  Nom           : get_org_id
--  Description   : Procédure permettant d'obtenir l'id l'organisation a partir du code societe
--
--  PARAMETRES :
--          pv_soc          Entrée
--          pn_org_id                  Sortie
--          pv_errbuf           Entrée  Sortie
--              pn_retcode              Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_org_id (
        pv_soc       IN       VARCHAR2,
        pn_org_id    OUT      NUMBER,
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

---------------------------------------------------------------------------------------------------------------
--  Nom           : trt_car_spec
--  Description   :  fonction qui permet de traiter les caracteres spéciaux      --                     
--
--  PARAMETRES    :
--                     pv_chaine
--
--  VALEUR RETOURNEE :
--                     chaine convertie
---------------------------------------------------------------------------------------------------------------
FUNCTION trt_car_spec (pv_chaine IN VARCHAR2)
RETURN VARCHAR2;

 ---------------------------------------------------------------------------------------------------------------
--  Nom           : is_bank_holiday
--  Description   :  fonction qui vérifie si la date passée en parametre est fériée
--
--  PARAMETRES    :
--                     pd_date  
--
--  VALEUR RETOURNEE :
--     Valeurs possibles :      0 non, 1 oui
---------------------------------------------------------------------------------------------------------------
FUNCTION is_bank_holiday(pd_date IN DATE)
RETURN NUMBER;

 ---------------------------------------------------------------------------------------------------------------
--  Nom           : get_next_working_day
--  Description   :  fonction qui retourne le jour ouvré le plus proche de la date passée en parametre
--
--  PARAMETRES    :
--                     pd_date  
--
--  VALEUR RETOURNEE :
--     Valeurs possibles :      date elle-meme ou le prochain jour ouvré
---------------------------------------------------------------------------------------------------------------
PROCEDURE get_next_working_day(pd_date IN OUT DATE)
;

---------------------------------------------------------------------------------------------------------------
--  Nom           : add_error_stack
--  Description   :  fonction qui ajoute un message en haut de la pile d'erreur.
--
--  PARAMETRES    :
--                     message  
--
--  VALEUR RETOURNEE :
---------------------------------------------------------------------------------------------------------------
PROCEDURE add_error_stack(pv_error_message IN VARCHAR2);

---------------------------------------------------------------------------------------------------------------
--  Nom           : print_error_stack
--  Description   :  fonction qui affiche la pile d'erreur.
--
--  PARAMETRES    :
--                     message  
--
--  VALEUR RETOURNEE :
---------------------------------------------------------------------------------------------------------------
PROCEDURE print_error_stack;

----------------------------------------------------------------------------
--  Nom           : clear_error_stack
--  Description   : Procédure
--
--  PARAMETRES :
----------------------------------------------------------------------------
PROCEDURE clear_error_stack;


-------------------------------------------------------------------------------
-- Nom              : Create_Table_Online_Patching
-- Description      : fonction permettant la création de la editioning view (EV) 
--                    + Ajout d'un enregistrement NULL 
--
-- PARAMETRES       : pv_owner           Proprietaire de la table
--                    pv_table_name      Nom de la table
--                    Pv_Errbuf          Sortie Message d'erreur
--                    Pn_Retcode         Sortie Code Retour de la procédure
--                                              '0' : Normal
--                                              '1' : Avertissement
--                                              '2' : Erreur
--  
-- VALEUR RETOURNEE :
-------------------------------------------------------------------------------
PROCEDURE Create_Table_Online_Patching(pv_owner      IN VARCHAR2,
                                       pv_table_name IN VARCHAR2,
                                       pn_retcode    OUT NUMBER,
                                       pv_Errbuf     OUT VARCHAR2);
								
-- -----------------------------------------------------------------------------
-- Nom              : check_directory
-- Description      : Vérifie de l'existence d'un directory et provoque une exception s'il n'existe pas
--
--  PARAMETRES      : p_directory_name : nom du directory
-- -----------------------------------------------------------------------------
procedure check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type);
                     
-- -----------------------------------------------------------------------------
-- Nom              : check_transco
-- Description      : Vérifie de l'existence d'un jeu de transco et provoque une exception s'il n'existe pas
--
--  PARAMETRES      : p_set_name : nom du jeu de transco
-- -----------------------------------------------------------------------------
procedure check_transco(p_set_name in dka_stransco_headers.set_name%type);             	   	 

-- -----------------------------------------------------------------------------
-- Nom              : check_value_set
-- Description      : Vérifie de l'existence d'un jeu de valeurs et provoque une exception s'il n'existe pas
--
--  PARAMETRES      : p_value_set_name : nom du jeu de valeurs
-- -----------------------------------------------------------------------------
procedure check_value_set(p_value_set_name in fnd_flex_value_sets.flex_value_set_name%type);

-- -----------------------------------------------------------------------------
-- Nom              : check_parameter
-- Description      : Vérifie de l'existence d'un parametre DKA et provoque une exception s'il n'existe pas
--
--  PARAMETRES      : p_program_code : nom du programme
--                    p_parameter_name : nom du parametre
-- -----------------------------------------------------------------------------
procedure check_parameter(p_program_code in DKA_PARAMETERS.PROGRAM_CODE%type, p_parameter_name in DKA_PARAMETERS.PARAMETER_NAME%type);

-- -----------------------------------------------------------------------------
-- Nom              : check_message
-- Description      : Vérifie de l'existence d'un message et provoque une exception s'il n'existe pas
--
--  PARAMETRES      : p_application_short_name : nom de l'application
--                    p_message_name : nom du mesage
-- -----------------------------------------------------------------------------
procedure check_message(p_application_short_name in FND_APPLICATION.APPLICATION_SHORT_NAME%type, p_message_name in FND_NEW_MESSAGES.MESSAGE_NAME%type);
 
-- -----------------------------------------------------------------------------
-- Nom              : check_parameter
-- Description      : Vérifie de l'existence d'un segment de CUF et provoque une exception s'il n'existe pas
--                  : Le segment peut etre désigné par son nom utilisateur, par la colonne (ATTRIBUTEn) qu'il occupe, ou les 2
--  PARAMETRES      : p_application_short_name : nom de l'application
--                    p_flexfield_name : nom du champ flexible utilisateur
--                    p_context_code : nom du contexte
--                    p_segment_name : nom du segment de CUF
--                    p_column_name : nom de la colonne qui porte le segment de CUF (facultatif. passer NULL si inconnu)
-- -----------------------------------------------------------------------------
procedure check_flex_segment(
  p_appl_short_name in FND_APPLICATION.APPLICATION_SHORT_NAME%type, 
  p_flexfield_name  in fnd_descriptive_flexs.descriptive_flexfield_name%type,
  p_context_code    in fnd_descr_flex_column_usages.descriptive_flex_context_code%type,
  p_segment_name    in fnd_descr_flex_column_usages.end_user_column_name%type,
  p_column_name     in fnd_descr_flex_column_usages.application_column_name%type);
 
      
END dka_tools_pkg; -- Spécification du package
/
SHOW ERRORS
EXIT;
