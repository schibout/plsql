SET verify off
whenever sqlerror EXIT failure ROLLBACK;
   
define package_name = "DKA_XX_LOADER_UTILS_PKG"

create or replace package &&PACKAGE_NAME as
---------------------------------------------------------------------------------------------- 
-- $ $
--
-- NOM		        : DKA_XX_LOADER_UTILS_PKG.pks
-- DESCRIPTION	    : DKA_XX_LOADER_UTILS_PKG package spec (FNDXLOAD utilities)
---
--- AUTEUR	        : K.Helali (CGEY) (version originale MEL-Oracle + BH-Cgey)
--- DATE DE CREATION : 08/11/2001
--- DOC. ASSOCIEE    : 
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME : 
--- PARAMETRES       : 
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  28/01/2001 KH  Ajout de la procédure DKA_PARAMETER 
--------------------------------------------------------------------------------------------

 
PROCEDURE debug_on;
PROCEDURE debug_off;

FUNCTION version RETURN VARCHAR2;
FUNCTION message RETURN VARCHAR2;

FUNCTION get_element (p_str    in varchar2,
                      p_sep    in varchar2 default chr(10),
                      p_pos    in number default 1)
         RETURN VARCHAR2;
pragma restrict_references (get_element, WNDS, WNPS);

FUNCTION get_appl_short_name (p_application_id in number)
RETURN VARCHAR2;
pragma restrict_references (get_appl_short_name, WNDS, WNPS);

FUNCTION get_vset_long (p_value_set_id in number,
                        p_type         in varchar2,
                        p_subtype      in varchar2 DEFAULT 'E')
 RETURN VARCHAR2;
pragma restrict_references (get_vset_long, WNDS, WNPS);

--------------------------------------------------------------------------------------
-- FLEX VALUE SETS (FND_FLEX_VAL_API api)
--------------------------------------------------------------------------------------
PROCEDURE create_value_set (p_NAME varchar2
                           ,p_DESCRIPTION varchar2
                           ,p_VALIDATION_TYPE varchar2
                           ,p_PROPERTIES varchar2
                           ,p_NUMBER_PRECISION varchar2
                           ,p_MINIMUM_VALUE varchar2
                           ,p_MAXIMUM_VALUE varchar2
                           ,p_DEPENDENT_PROPERTIES varchar2
                           ,p_APPLICATION_TABLE_NAME varchar2
                           ,p_ALLOW_PARENT_VALUES varchar2
                           ,p_VALUE_COLUMN varchar2
                           ,p_MEANING_COLUMN varchar2
                           ,p_ID_COLUMN varchar2
                           ,p_WHERE_ORDER_BY varchar2
                           ,p_ADDITIONAL_COLUMNS varchar2
                           ,p_E_FUNCTION_TEXT varchar2
                           ,p_V_FUNCTION_TEXT varchar2
                           ,p_L_FUNCTION_TEXT varchar2 default NULL
                           );

--------------------------------------------------------------------------------------
-- DESCRIPTIVE_FLEXFIELD (FND_FLEX_DSC_API api)
--------------------------------------------------------------------------------------
PROCEDURE df_setup (p_appsname          varchar2
                   ,p_flexfield_name    varchar2
                   ,p_segment_separator varchar2
                   ,p_default_value     varchar2
                   ,p_reference_field   varchar2
                   ,p_value_required    varchar2
                   ,p_override_allowed  varchar2
                   ,p_prompt            varchar2
                   );

PROCEDURE df_context (p_appsname          varchar2
                     ,p_flexfield_name    varchar2
                     ,p_context_code      varchar2
                     ,p_enabled           varchar2
                     ,p_global_flag       varchar2
                     ,p_context_name      varchar2
                     ,p_description       varchar2
                     );

PROCEDURE df_segment (p_APPSNAME          varchar2
                     ,p_FLEXFIELD_NAME    varchar2
                     ,p_CONTEXT_CODE      varchar2
                     ,p_NAME              varchar2
                     ,p_COLUMN            varchar2
                     ,p_SEQUENCE_NUMBER   varchar2
                     ,p_ENABLED           varchar2
                     ,p_DISPLAYED         varchar2
                     ,p_VALUE_SET         varchar2
                     ,p_DEFAULT_TYPE      varchar2
                     ,p_DEFAULT_VALUE     varchar2
                     ,p_REQUIRED          varchar2
                     ,p_SECURITY_ENABLED  varchar2
                     ,p_DISPLAY_SIZE      varchar2
                     ,p_DESCRIPTION_SIZE  varchar2
                     ,p_CONCAT_DESC_SIZE  varchar2
                     ,p_RANGE             varchar2
                     ,p_LOV_PROMPT        varchar2
                     ,p_WIN_PROMPT        varchar2
                     ,p_DESCRIPTION       varchar2
                     );

PROCEDURE df_setup_tl 
                   (p_appsname          varchar2
                   ,p_flexfield_name    varchar2
                   ,p_language          varchar2
                   ,p_prompt            varchar2
                   ,p_title             varchar2
                   );

PROCEDURE df_context_tl
                     (p_appsname          varchar2
                     ,p_flexfield_name    varchar2
                     ,p_context_code      varchar2
                     ,p_language          varchar2
                     ,p_context_name      varchar2
                     ,p_description       varchar2
                     );

PROCEDURE df_segment_tl
                     (p_appsname          varchar2
                     ,p_flexfield_name    varchar2
                     ,p_context_code      varchar2
                     ,p_column            varchar2
                     ,p_language          varchar2
                     ,p_lov_prompt        varchar2
                     ,p_win_prompt        varchar2
                     ,p_description       varchar2
                     );

--------------------------------------------------------------------------------------
-- CONCURRENT PROGRAMS (FND_PROGRAM api)
--------------------------------------------------------------------------------------
PROCEDURE executable (p_APPSNAME    varchar2
                     ,p_NAME        varchar2
                     ,p_SHORT_NAME  varchar2
                     ,p_METHOD_CODE varchar2
                     ,p_FILE_NAME   varchar2
                     ,p_SUBROUTINE  varchar2
                     ,p_ICONE       varchar2
                     ,p_SOURCE_LANG varchar2
                     ,p_DESCRIPTION varchar2
                     );

PROCEDURE executable_desc (p_APPSNAME    varchar2
                          ,p_SHORT_NAME  varchar2
                          ,p_LANGUAGE    varchar2
                          ,p_NAME        varchar2
                          ,p_DESCRIPTION varchar2
                          ,p_SOURCE_LANG varchar2
                          );

PROCEDURE program (p_APPL_SHORT_NAME           varchar2
                  ,p_NAME                      varchar2
                  ,p_ENABLED                   varchar2
                  ,p_SHORT_NAME                varchar2
                  ,p_DESCRIPTION               varchar2
                  ,p_EXECUTABLE_NAME           varchar2
                  ,p_EXECUTABLE_APPLICATION    varchar2
                  ,p_EXECUTION_OPTIONS         varchar2
                  ,p_PRIORITY                  varchar2
                  ,p_SAVE_OUTPUT_PRINT         varchar2
                  ,p_COLS_ROWS                 varchar2
                  ,p_STYLE_INFOS               varchar2
                  ,p_PRINTER                   varchar2
                  ,p_REQUEST_TYPE              varchar2
                  ,p_USE_IN_SRS                varchar2
                  ,p_ALLOW_DISABLED_VALUES     varchar2
                  ,p_RUN_ALONE                 varchar2
                  ,p_OUTPUT_TYPE               varchar2
                  ,p_ENABLE_TRACE              varchar2
                  ,p_RESTART                   varchar2
                  ,p_NLS_COMPLIANT             varchar2
                  ,p_ICONE_NAME                varchar2
                  ,p_LANGUAGE_CODE             varchar2
                  );

PROCEDURE program_desc (p_APPL_SHORT_NAME           varchar2
                       ,p_SHORT_NAME                varchar2
                       ,p_LANGUAGE_CODE             varchar2
                       ,p_NAME                      varchar2
                       ,p_DESCRIPTION               varchar2
                       ,p_SOURCE_LANG               varchar2
                       );

PROCEDURE parameter (p_APPL_SHORT_NAME           varchar2
                    ,p_PROGRAM_SHORT_NAME        varchar2
                    ,p_PARAMETER                 varchar2
                    ,p_SEQUENCE                  varchar2
                    ,p_DESCRIPTION               varchar2
                    ,p_ENABLED                   varchar2
                    ,p_VALUE_SET                 varchar2
                    ,p_DEFAULT_TYPE              varchar2
                    ,p_DEFAULT_VALUE             varchar2
                    ,p_REQUIRED                  varchar2
                    ,p_ENABLE_SECURITY           varchar2
                    ,p_RANGE                     varchar2
                    ,p_DISPLAY                   varchar2
                    ,p_DISPLAY_SIZE              varchar2
                    ,p_DESCRIPTION_SIZE          varchar2
                    ,p_CONCAT_DESCRIPTION_SIZE   varchar2
                    ,p_PROMPT                    varchar2
                    ,p_TOKEN                     varchar2
                    );

PROCEDURE parameter_desc (p_APPL_SHORT_NAME           varchar2
                         ,p_PROGRAM_SHORT_NAME        varchar2
                         ,p_APPLI_COL_NAME            varchar2
                         ,p_LANGUAGE                  varchar2
                         ,p_DESCRIPTION               varchar2
                         ,p_PROMPT                    varchar2
                         ,p_SOURCE_LANG               varchar2
                         );

PROCEDURE request_group (p_APPL_SHORT_NAME           varchar2
                        ,p_REQUEST_GROUP             varchar2
                        ,p_DESCRIPTION               varchar2
                        ,p_CODE                      varchar2
                        );

PROCEDURE request_group_unit (p_GROUP_APPL_SHORT_NAME     varchar2
                             ,p_REQUEST_GROUP             varchar2
                             ,p_PROG_APPL_SHORT_NAME      varchar2
                             ,p_PROGRAM_SHORT_NAME        varchar2
                             );

PROCEDURE create_update_exe_p (p_APPSNAME    varchar2
                              ,p_NAME        varchar2
                              ,p_SHORT_NAME  varchar2
                              ,p_METHOD_CODE varchar2
                              ,p_FILE_NAME   varchar2
                              ,p_SUBROUTINE  varchar2
                              ,p_ICONE       varchar2
                              ,p_SOURCE_LANG varchar2
                              ,p_DESCRIPTION varchar2
                              );

PROCEDURE update_exe_p(p_executable_short_name     IN varchar2
                      ,p_executable_app_short_name IN varchar2
                      ,p_executable_name           IN varchar2
                      ,p_description               IN varchar2
                      ,p_file_name                 IN varchar2
                      ,p_subroutine                IN varchar2
                      );

PROCEDURE delete_exe_prog_p(pv_executable_short_name  IN varchar2
			   ,pv_executable_app_short_name             IN varchar2
                           ,pv_executable_name        IN varchar2
                           ,pv_description            IN varchar2
                           ,pv_file_name              IN varchar2
                           ,pv_subroutine             IN varchar2
			   );

PROCEDURE delete_params_prog_p( pv_prog_short_name IN varchar2
			      , pv_prog_app_short_name            IN varchar2
                           );


PROCEDURE request_set(
                     p_APPSNAME              IN varchar2 
                    ,p_SHORT_NAME            IN varchar2
                    ,p_NAME                  IN varchar2
                    ,p_OWNER                 IN varchar2
                    ,p_PRINT_TOGETHER        IN varchar2
                    ,p_ALLOW_INCOMPATIBILITY IN varchar2
                    ,p_DESCRIPTION           IN varchar2
                    );

PROCEDURE request_set_desc(
                           p_APPSNAME              IN varchar2 
                          ,p_SET_SHORT_NAME        IN varchar2
                          ,p_LANGUAGE              IN varchar2
                          ,p_NAME                  IN varchar2
                          ,p_DESCRIPTION           IN varchar2
                          ,p_SOURCE_LANG           IN varchar2
                          );

PROCEDURE request_stage(
                        p_APPSNAME              IN varchar2 
                       ,p_SET_SHORT_NAME        IN varchar2
                       ,p_STAGE_SHORT_NAME      IN varchar2 
                       ,p_STAGE_NAME            IN varchar2 
                       ,p_DISPLAY_SEQ           IN varchar2 
                       ,p_FUNC_APPLI            IN varchar2 
                       ,p_FUNCTION              IN varchar2 
                       ,p_CRITICAL              IN varchar2 
                       ,p_ALLOW_INCOMPATIBILITY IN varchar2 
                       ,p_FIRST_STAGE           IN varchar2 
                       ,p_DESCRIPTION           IN varchar2 
                       );

PROCEDURE request_stage_desc(
                             p_APPSNAME              IN varchar2 
                            ,p_SET_SHORT_NAME        IN varchar2
                            ,p_STAGE_SHORT_NAME      IN varchar2 
                            ,p_LANGUAGE              IN varchar2
                            ,p_STAGE_NAME            IN varchar2
                            ,p_DESCRIPTION           IN varchar2
                            ,p_SOURCE_LANG           IN varchar2
                            );
      
PROCEDURE link_stage(
                     p_APPSNAME         IN varchar2 
                    ,p_SET_SHORT_NAME   IN varchar2 
                    ,p_STAGE_NAME       IN varchar2 
                    ,p_SUCCESS_NAME     IN varchar2 
                    ,p_WARNING_NAME     IN varchar2 
                    ,p_ERROR_NAME       IN varchar2 
                    );

PROCEDURE set_program(
            p_APPSNAME        IN varchar2 
           ,p_SET_SHORT_NAME  IN varchar2 
           ,p_STAGE_NAME      IN varchar2 
           ,p_PROG_SEQ        IN varchar2 
           ,p_PROG_APPSNAME   IN varchar2 
           ,p_PROG_NAME       IN varchar2 
           ,p_CRITICAL        IN varchar2 
           ,p_NB_COPIES       IN varchar2 
           ,p_PRINTER         IN varchar2 
           ,p_PRINT_STYLE     IN varchar2 
           ,p_SAVE_OUTPUT     IN varchar2 
           );

PROCEDURE set_program_param(
            p_APPSNAME              IN varchar2
           ,p_SET_SHORT_NAME        IN varchar2
           ,p_STAGE_NAME            IN varchar2
           ,p_PROG_SEQ              IN varchar2
           ,p_PARAM                 IN varchar2
           ,p_PROG_APPSNAME         IN varchar2
           ,p_PROG_NAME             IN varchar2
           ,p_DISPLAY               IN varchar2
           ,p_UPDATE                IN varchar2
           ,p_DEFAULT_VALUE         IN varchar2
           ,p_DEFAULT_TYPE          IN varchar2
           ,p_SHARED_PARAM          IN varchar2
           );

PROCEDURE set_incompatibility(
            p_APPSNAME                 IN varchar2
           ,p_SET_SHORT_NAME           IN varchar2
           ,p_STAGE_NAME               IN varchar2
           ,p_APPSNAME_INCOMP          IN varchar2
           ,p_SET_SHORT_NAME_INCOMP    IN varchar2
           ,p_STAGE_NAME_INCOMP        IN varchar2
           ,p_PROGRAM_INCOMP           IN varchar2
           );

PROCEDURE prog_incompatibility(
            p_APPSNAME                 IN varchar2
           ,p_PROG_SHORT_NAME          IN varchar2
           ,p_APPSNAME_INCOMP          IN varchar2
           ,p_SET_SHORT_NAME_INCOMP    IN varchar2
           ,p_STAGE_NAME_INCOMP        IN varchar2
           ,p_PROGRAM_INCOMP           IN varchar2
           );


--------------------------------------------------------------------------------------

PROCEDURE dka_fnd_lookup_type(
                           p_VIEW_APPSNAME          IN varchar2
                          ,p_LOOKUP_TYPE            IN varchar2
                          ,p_APPL_SHORT_NAME        IN varchar2
                          ,p_CUSTOMIZATION_LEVEL    IN varchar2
                          ,p_LOOKUP_TYPE_MEANING    IN varchar2
                          ,p_DESCRIPTION            IN varchar2
                          );

PROCEDURE dka_fnd_lookup_values_desc(
                           p_LOOKUP_CODE     IN varchar2
                          ,p_LOOKUP_TYPE     IN varchar2
                          ,p_LANGUAGE        IN varchar2
                          ,p_DESCRIPTION     IN varchar2
                          ,p_MEANING         IN varchar2
                          );

PROCEDURE dka_fnd_profile_options_desc(
                           p_PROFILE_OPTION_NAME          IN varchar2
                          ,p_LANGUAGE                     IN varchar2
                          ,p_USER_PROFILE_OPTION_NAME     IN varchar2
                          ,p_DESCRIPTION                  IN varchar2
                          );
                          
PROCEDURE message(
                   p_appsname       IN VARCHAR2
                   ,p_message_name  IN VARCHAR2
                   ,p_language_code IN VARCHAR2
                   ,p_message_text  IN VARCHAR2
                   );                          

PROCEDURE dka_parameter(
            p_program_code   IN VARCHAR2
           ,p_parameter_name IN VARCHAR2
           ,p_description    IN VARCHAR2
           ,p_table_name     IN VARCHAR2
           ,p_column_name    IN VARCHAR2
           ,p_data_type      IN VARCHAR2
           ,p_varchar2_value IN VARCHAR2
           ,p_number_value   IN NUMBER
           ,p_date_value     IN VARCHAR2
           ,p_boolean_value  IN VARCHAR2
           );
gv_program_short_name fnd_concurrent_programs.concurrent_program_name%TYPE;
gv_appl_short_name    fnd_application.application_short_name%TYPE;

END &&PACKAGE_NAME; /* package spec*/
/

show errors
EXIT;
