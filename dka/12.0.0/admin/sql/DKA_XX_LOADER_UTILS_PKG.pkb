SET verify off
   
define package_name = "DKA_XX_LOADER_UTILS_PKG"

create or replace package body &&PACKAGE_NAME as
---------------------------------------------------------------------------------------------- 
-- $ $
--
-- NOM		        : DKA_XX_LOADER_UTILS_PKG.pkb
-- DESCRIPTION	    : DKA_XX_LOADER_UTILS_PKG package body (FNDXLOAD utilities)
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
--------------------------------------------------------------------------------------------
/* ------------------------------------------------------------ */
/*  globals                                                     */
/* ------------------------------------------------------------ */

/* START_PUBLIC */
bad_parameter EXCEPTION;
PRAGMA EXCEPTION_INIT(bad_parameter, -06501);
/* END_PUBLIC */

value_too_large EXCEPTION;
PRAGMA EXCEPTION_INIT(value_too_large, -01401);

internal_messages VARCHAR2(10000);
debug_mode_on BOOLEAN := FALSE;

TYPE VCHAR30_ARRAY IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;

TYPE RequestGroupsRec IS RECORD
    (array_size        INTEGER
    ,group_application VCHAR30_ARRAY
    ,request_group     VCHAR30_ARRAY
    );

/* ------------------------------------------------------------ */

/* START_PUBLIC */
PROCEDURE debug_on IS
BEGIN
   debug_mode_on := TRUE;
END;

PROCEDURE debug_off IS
BEGIN
   debug_mode_on := FALSE;
END;
/* END_PUBLIC */


PROCEDURE println(msg IN VARCHAR2) IS
BEGIN
   IF(debug_mode_on) THEN
      dbms_output.enable;
      dbms_output.put_line(msg);
   END IF;
END;

/* ------------------------------------------------------------ */
/*  messaging                                                   */
/* ------------------------------------------------------------ */

PROCEDURE message(msg VARCHAR2) IS
BEGIN
   internal_messages := internal_messages || msg || Chr(10);
END;

PROCEDURE message_init IS
BEGIN
   internal_messages := '';
END;

/* ------------------------------------------------------------ */
/* lookups                                                      */
/* ------------------------------------------------------------ */

FUNCTION get_meaning(p_type IN VARCHAR2, p_code IN VARCHAR2) RETURN VARCHAR2
IS
  l_meaning fnd_lookup_values.meaning%type;
BEGIN
   SELECT meaning 
     INTO l_meaning
     FROM fnd_lookup_values
    WHERE lookup_type = p_type
      AND lookup_code = p_code
      AND rownum = 1;

   return l_meaning;
EXCEPTION
   WHEN OTHERS THEN
     return NULL;
END;


FUNCTION invert_flag_f(flag IN VARCHAR2)
  RETURN VARCHAR2
  IS
BEGIN
   IF(flag = 'Y') THEN
      RETURN 'N';
    ELSIF(flag = 'N') THEN      
      RETURN 'Y';
    ELSE
      message('bad Y/N value:' || flag);
      RAISE bad_parameter;
   END IF;
END;

FUNCTION get_where_clause (p_value_set_id in number) 
RETURN VARCHAR2
IS
  tempo long;
BEGIN
  if p_value_set_id is null then
    return NULL;
  else
    SELECT additional_where_clause
      INTO tempo
      FROM fnd_flex_validation_tables
     WHERE flex_value_set_id = p_value_set_id;
  end if;
 return tempo;
EXCEPTION
 when others then return null;
END;

FUNCTION get_user_exit (p_value_set_id in number, p_event_code in varchar2) 
RETURN VARCHAR2
IS
  tempo long;
BEGIN
  if (p_value_set_id is null or p_event_code is null) then
    return NULL;
  else
    SELECT user_exit
      INTO tempo
      FROM fnd_flex_validation_events
     WHERE flex_value_set_id = p_value_set_id
       AND event_code        = p_event_code;
  end if;
 return tempo;
EXCEPTION
 when others then return null;
END;


PROCEDURE add_event (p_value_set varchar2,p_event varchar2,p_function varchar2)
IS
BEGIN
   if (p_function is null) then return; end if;

   DELETE fnd_flex_validation_events
    WHERE flex_value_set_id=(SELECT flex_value_set_id 
                               FROM fnd_flex_value_sets
                              WHERE flex_value_set_name=p_value_set)
      AND event_code = p_event;

   fnd_flex_val_api.add_event (p_value_set,p_event,p_function);

END;

PROCEDURE get_request_groups (p_unit_type        IN     VARCHAR2
                             ,p_unit_name        IN     VARCHAR2
                             ,p_unit_application IN     VARCHAR2
                             ,p_request_groups   IN OUT RequestGroupsRec
                             ) IS

  TYPE CReqGroupType IS REF CURSOR;

  CReqGroup       CReqGroupType;
  l_idx           INTEGER := 0;

BEGIN

  p_request_groups.array_size := 0;

  IF (p_unit_type = 'S') THEN

    OPEN CReqGroup FOR
    SELECT rga.application_short_name,
           rg.request_group_name
      FROM fnd_application         rga,
           fnd_request_groups      rg,
           fnd_request_group_units rgu,
           fnd_request_sets        rs,
           fnd_application         rsa
     WHERE rsa.application_short_name = p_unit_application
       AND rs.application_id          = rsa.application_id
       AND rs.request_set_name        = p_unit_name
       AND rgu.request_unit_type      = 'S'
       AND rgu.unit_application_id    = rs.application_id
       AND rgu.request_unit_id        = rs.request_set_id
       AND rg.application_id          = rgu.application_id
       AND rg.request_group_id        = rgu.request_group_id
       AND rga.application_id         = rg.application_id
    ORDER BY 1,2;

  ELSE

    OPEN CReqGroup FOR
    SELECT rga.application_short_name,
           rg.request_group_name
      FROM fnd_application         rga,
           fnd_request_groups      rg,
           fnd_request_group_units rgu,
           fnd_concurrent_programs cp,
           fnd_application         cpa
     WHERE cpa.application_short_name = p_unit_application
       AND cp.application_id          = cpa.application_id
       AND cp.concurrent_program_name = p_unit_name
       AND rgu.request_unit_type      = 'P'
       AND rgu.unit_application_id    = cp.application_id
       AND rgu.request_unit_id        = cp.concurrent_program_id
       AND rg.application_id          = rgu.application_id
       AND rg.request_group_id        = rgu.request_group_id
       AND rga.application_id         = rg.application_id
    ORDER BY 1,2;

  END IF;

  LOOP
    l_idx := l_idx + 1;
    FETCH CReqGroup 
     INTO p_request_groups.group_application(l_idx),
          p_request_groups.request_group(l_idx)
    ;
    EXIT WHEN CReqGroup%NOTFOUND;

  p_request_groups.array_size := l_idx;

  END LOOP;
  CLOSE CReqGroup;

 
EXCEPTION
  WHEN others THEN
   IF CReqGroup%ISOPEN THEN
     CLOSE CReqGroup;
   END IF;
   raise; 
END get_request_groups;


/* START_PUBLIC */

/* ------------------------------------------------------------ */
/*  public function definitions                                 */
/* ------------------------------------------------------------ */

FUNCTION version RETURN VARCHAR2 IS
BEGIN
   RETURN('$Header: SPE000 - Communs\Sources\DKA_XX_TOOLS\sql\DKA_XX_LOADER_UTILS_PKG.pkb,v 1.1.1.1 2004/07/05 11:48:40 flechene Exp $');
END;

FUNCTION message RETURN VARCHAR2 IS
BEGIN
   RETURN internal_messages;
END;

FUNCTION get_element (p_str    in varchar2,
                      p_sep    in varchar2 default chr(10),
                      p_pos    in number default 1)
RETURN VARCHAR2
IS
  l_pos number := trunc(nvl(p_pos,0));
BEGIN
  if (l_pos <= 0 or p_str is null ) then
     return NULL;
  elsif not (instr(p_sep||p_str,p_sep,1,l_pos) > 0) then
     return NULL; 
  elsif l_pos = 1 then
     return substr(p_str,1,instr(p_str||p_sep,p_sep,1)-1);
  else
     return get_element(substr(p_str,instr(p_str||p_sep,p_sep)+1),
                        p_sep,
                        l_pos-1);
  end if;
END;

FUNCTION get_appl_short_name (p_application_id in number)
RETURN VARCHAR2
IS
  appsname fnd_application.application_short_name%type;
BEGIN
  SELECT application_short_name
    INTO appsname
    FROM fnd_application
   WHERE application_id = p_application_id;

  return appsname;

EXCEPTION
 when others then return null;
END;

FUNCTION get_vset_long (p_value_set_id in number,
                        p_type         in varchar2,
                        p_subtype      in varchar2 DEFAULT 'E')
RETURN VARCHAR2
IS
BEGIN
 if (upper(p_type) = 'T') then
   return get_where_clause(p_value_set_id);
 elsif (upper(p_type) = 'E') then
   return get_user_exit(p_value_set_id,p_subtype);
 else
   return NULL;
 end if;
END;

--------------------------------------------------------------------------------------
-- FLEX VALUE SETS (FND_FLEX_VAL_API api)
--------------------------------------------------------------------------------------
PROCEDURE create_value_set (p_NAME                   varchar2
                           ,p_DESCRIPTION            varchar2
                           ,p_VALIDATION_TYPE        varchar2
                           ,p_PROPERTIES             varchar2
                           ,p_NUMBER_PRECISION       varchar2
                           ,p_MINIMUM_VALUE          varchar2
                           ,p_MAXIMUM_VALUE          varchar2
                           ,p_DEPENDENT_PROPERTIES   varchar2
                           ,p_APPLICATION_TABLE_NAME varchar2
                           ,p_ALLOW_PARENT_VALUES    varchar2
                           ,p_VALUE_COLUMN           varchar2
                           ,p_MEANING_COLUMN         varchar2
                           ,p_ID_COLUMN              varchar2
                           ,p_WHERE_ORDER_BY         varchar2
                           ,p_ADDITIONAL_COLUMNS     varchar2
                           ,p_E_FUNCTION_TEXT        varchar2
                           ,p_V_FUNCTION_TEXT        varchar2
                           ,p_L_FUNCTION_TEXT        varchar2 default NULL
                           )
IS
  l_value_set_name          varchar2(60)  := p_name;
  l_description             varchar2(240) := p_description;
  l_validation_type         varchar2(1)   := upper(p_validation_type);

  l_security_available      varchar2(1) := substr(p_PROPERTIES,1,1);
  l_enable_longlist         varchar2(1) := substr(p_PROPERTIES,3,1);
  l_format_type             varchar2(1) := substr(p_PROPERTIES,5,1);
  l_numbers_only            varchar2(1) := substr(p_PROPERTIES,7,1);
  l_uppercase_only          varchar2(1) := substr(p_PROPERTIES,9,1);
  l_right_justify_zero_fill varchar2(1) := substr(p_PROPERTIES,11,1);
  l_maximum_size            number      := substr(p_PROPERTIES,13,3);

  l_format_type_disp        varchar2(80);
  l_min_value               varchar2(60) := p_MINIMUM_VALUE;
  l_max_value               varchar2(60) := p_MAXIMUM_VALUE;
  l_precision               number       := p_NUMBER_PRECISION;

  l_parent_flex_value_set fnd_flex_value_sets.flex_value_set_name%type;
  l_dependent_default_value fnd_flex_value_sets.dependant_default_value%type;
  l_dependent_default_meaning fnd_flex_value_sets.dependant_default_meaning%type;

  l_table_appl_short_name   fnd_application.application_short_name%type;
  l_table_name              fnd_flex_validation_tables.application_table_name%type;
  l_allow_parent_values     varchar2(1);
  l_value_column_name       fnd_flex_validation_tables.value_column_name%type;
  l_value_column_type       fnd_flex_validation_tables.value_column_type%type;
  l_value_column_size       fnd_flex_validation_tables.value_column_size%type;
  l_meaning_column_name     fnd_flex_validation_tables.meaning_column_name%type;
  l_meaning_column_type     fnd_flex_validation_tables.meaning_column_type%type;
  l_meaning_column_size     fnd_flex_validation_tables.meaning_column_size%type;
  l_id_column_name          fnd_flex_validation_tables.id_column_name%type;
  l_id_column_type          fnd_flex_validation_tables.id_column_type%type;
  l_id_column_size          fnd_flex_validation_tables.id_column_size%type;
  l_where_order_by          long;
  l_additional_columns      fnd_flex_validation_tables.additional_quickpick_columns%type;
  l_value_column_type_disp  varchar2(80);
  l_meaning_column_type_disp varchar2(80);
  l_id_column_type_disp     varchar2(80);

  l_valueset_exists         boolean := FALSE;
  l_old_vset_id             fnd_flex_value_sets.flex_value_set_id%type;
  l_old_vset_name           fnd_flex_value_sets.flex_value_set_name%type;
BEGIN

 begin
   if fnd_flex_val_api.valueset_exists(l_value_set_name) then 
 
      l_valueset_exists := TRUE;
      l_old_vset_name   := l_value_set_name;
    
      SELECT flex_value_set_id
        INTO l_old_vset_id
        FROM fnd_flex_value_sets
       WHERE flex_value_set_name = l_value_set_name;
    
      l_value_set_name := 'Z'||l_old_vset_id;

   end if; 

 exception
   when others then
      message('Impossible de mettre a jour '||l_old_vset_name||chr(10)
              ||SQLERRM);
      raise bad_parameter;
 end;

 BEGIN
  fnd_flex_val_api.set_session_mode('customer_data'); 

  l_format_type_disp := get_meaning('FIELD_TYPE',l_format_type); 

  if (p_validation_type = fnd_flex_types.val_none) then 
     fnd_flex_val_api.create_valueset_none(
	     value_set_name          => l_value_set_name,
	     description             => l_description,
	     security_available      => l_security_available,
	     enable_longlist	     => l_enable_longlist,
	     format_type             => l_format_type_disp,
	     maximum_size            => l_maximum_size,
	     precision               => l_precision,
	     numbers_only            => l_numbers_only,
	     uppercase_only          => l_uppercase_only,
	     right_justify_zero_fill => l_right_justify_zero_fill,
	     min_value               => l_min_value,
             max_value               => l_max_value);
  elsif (l_validation_type = fnd_flex_types.val_independent) then 
     fnd_flex_val_api.create_valueset_independent(
	     value_set_name          => l_value_set_name,
	     description             => l_description,
	     security_available      => l_security_available,
	     enable_longlist	     => l_enable_longlist,
	     format_type             => l_format_type_disp,
	     maximum_size            => l_maximum_size,
	     precision               => l_precision,
	     numbers_only            => l_numbers_only,
	     uppercase_only          => l_uppercase_only,
	     right_justify_zero_fill => l_right_justify_zero_fill,
	     min_value               => l_min_value,
             max_value               => l_max_value);
  elsif (l_validation_type = fnd_flex_types.val_special) then 
     fnd_flex_val_api.create_valueset_special(
	     value_set_name          => l_value_set_name,
	     description             => l_description,
	     security_available      => l_security_available,
	     enable_longlist	     => l_enable_longlist,
	     format_type             => l_format_type_disp,
	     maximum_size            => l_maximum_size,
	     precision               => l_precision,
	     numbers_only            => l_numbers_only,
	     uppercase_only          => l_uppercase_only,
	     right_justify_zero_fill => l_right_justify_zero_fill,
	     min_value               => l_min_value,
             max_value               => l_max_value);
  elsif (l_validation_type = fnd_flex_types.val_pair) then 
     fnd_flex_val_api.create_valueset_pair(
	     value_set_name          => l_value_set_name,
	     description             => l_description,
	     security_available      => l_security_available,
	     enable_longlist	     => l_enable_longlist,
	     format_type             => l_format_type_disp,
	     maximum_size            => l_maximum_size,
	     precision               => l_precision,
	     numbers_only            => l_numbers_only,
	     uppercase_only          => l_uppercase_only,
	     right_justify_zero_fill => l_right_justify_zero_fill,
	     min_value               => l_min_value,
             max_value               => l_max_value);
  elsif (l_validation_type = fnd_flex_types.val_dependent) then 
     l_parent_flex_value_set     := get_element(p_DEPENDENT_PROPERTIES,'*',1);
     l_dependent_default_value   := get_element(p_DEPENDENT_PROPERTIES,'*',2);
     l_dependent_default_meaning := get_element(p_DEPENDENT_PROPERTIES,'*',3);
     fnd_flex_val_api.create_valueset_dependent(
	     value_set_name          => l_value_set_name,
	     description             => l_description,
	     security_available      => l_security_available,
	     enable_longlist	     => l_enable_longlist,
	     format_type             => l_format_type_disp,
	     maximum_size            => l_maximum_size,
	     precision               => l_precision,
	     numbers_only            => l_numbers_only,
	     uppercase_only          => l_uppercase_only,
	     right_justify_zero_fill => l_right_justify_zero_fill,
	     min_value               => l_min_value,
             max_value               => l_max_value,
	     parent_flex_value_set   => l_parent_flex_value_set,
	     dependent_default_value => l_dependent_default_value,
	     dependent_default_meaning => l_dependent_default_meaning);
  elsif (l_validation_type = fnd_flex_types.val_table) then 
     l_table_appl_short_name    := get_element(p_APPLICATION_TABLE_NAME,'*',1);
     l_table_name               := get_element(p_APPLICATION_TABLE_NAME,'*',2);
     l_allow_parent_values      := p_ALLOW_PARENT_VALUES;
     l_value_column_name        := get_element(p_VALUE_COLUMN,'*',1);
     l_value_column_type        := get_element(p_VALUE_COLUMN,'*',2);
     l_value_column_size        := get_element(p_VALUE_COLUMN,'*',3);
     l_meaning_column_name      := get_element(p_MEANING_COLUMN,'*',1);
     l_meaning_column_type      := get_element(p_MEANING_COLUMN,'*',2);
     l_meaning_column_size      := get_element(p_MEANING_COLUMN,'*',3);
     l_id_column_name           := get_element(p_ID_COLUMN,'*',1);
     l_id_column_type           := get_element(p_ID_COLUMN,'*',2);
     l_id_column_size           := get_element(p_ID_COLUMN,'*',3);
     l_value_column_type_disp   := get_meaning('COLUMN_TYPE',l_value_column_type);
     l_id_column_type_disp      := get_meaning('COLUMN_TYPE',l_id_column_type);
     l_meaning_column_type_disp := get_meaning('COLUMN_TYPE',l_meaning_column_type);
     l_where_order_by           := p_WHERE_ORDER_BY;
     l_additional_columns       := p_ADDITIONAL_COLUMNS;

     fnd_flex_val_api.create_valueset_table(
	     value_set_name          => l_value_set_name,
	     description             => l_description,
	     security_available      => l_security_available,
	     enable_longlist	     => l_enable_longlist,
	     format_type             => l_format_type_disp,
	     maximum_size            => l_maximum_size,
	     precision               => l_precision,
	     numbers_only            => l_numbers_only,
	     uppercase_only          => l_uppercase_only,
	     right_justify_zero_fill => l_right_justify_zero_fill,
	     min_value               => l_min_value,
             max_value               => l_max_value,
             table_appl_short_name   => l_table_appl_short_name,
	     table_name              => l_table_name,
	     allow_parent_values     => l_allow_parent_values,
	     value_column_name       => l_value_column_name,
	     value_column_type       => l_value_column_type_disp,
	     value_column_size       => l_value_column_size,
	     meaning_column_name     => l_meaning_column_name,
	     meaning_column_type     => l_meaning_column_type_disp,
	     meaning_column_size     => l_meaning_column_size,
	     id_column_name          => l_id_column_name,
	     id_column_type          => l_id_column_type_disp,
	     id_column_size          => l_id_column_size,
	     where_order_by          => l_where_order_by,
	     additional_columns      => l_additional_columns);
  end if; 

  if (l_validation_type in (fnd_flex_types.val_special,fnd_flex_types.val_pair)) then 
    add_event(l_value_set_name,get_meaning('FLEX_VALIDATION_EVENTS','E'),
              p_E_FUNCTION_TEXT);
    add_event(l_value_set_name,get_meaning('FLEX_VALIDATION_EVENTS','V'),
              p_V_FUNCTION_TEXT);
    add_event(l_value_set_name,get_meaning('FLEX_VALIDATION_EVENTS','L'),
              p_L_FUNCTION_TEXT);
  end if;

  if l_valueset_exists then
    fnd_flex_val_api.destructive_rename(l_old_vset_name, l_value_set_name);
  end if;
 
 EXCEPTION
   when bad_parameter then
      message(fnd_flex_val_api.message);
      raise;
   when others then
      message('Erreur: '||SQLERRM);
      raise;
 END;


EXCEPTION
  when others then
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  
END create_value_set;

--------------------------------------------------------------------------------------
-- DESCRIPTIVE FLEXFIELDS (FND_FLEX_DSC_API api)
--------------------------------------------------------------------------------------
PROCEDURE df_setup (p_appsname          varchar2
                   ,p_flexfield_name    varchar2
                   ,p_segment_separator varchar2
                   ,p_default_value     varchar2
                   ,p_reference_field   varchar2
                   ,p_value_required    varchar2
                   ,p_override_allowed  varchar2
                   ,p_prompt            varchar2
                   )
IS
BEGIN

  FND_FLEX_DSC_API.SET_SESSION_MODE ('customer_data');

  FND_FLEX_DSC_API.SET_VALIDATION (FALSE);

  FND_FLEX_DSC_API.SETUP_CONTEXT_FIELD (p_APPSNAME, 
       p_FLEXFIELD_NAME, p_SEGMENT_SEPARATOR, NULL, 
       p_DEFAULT_VALUE,  p_REFERENCE_FIELD,   p_VALUE_REQUIRED, 
       p_OVERRIDE_ALLOWED); 

  FND_FLEX_DSC_API.FREEZE (p_APPSNAME, p_FLEXFIELD_NAME);

EXCEPTION
  when bad_parameter then
    message(fnd_flex_dsc_api.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END df_setup;

PROCEDURE df_context (p_appsname          varchar2
                     ,p_flexfield_name    varchar2
                     ,p_context_code      varchar2
                     ,p_enabled           varchar2
                     ,p_global_flag       varchar2
                     ,p_context_name      varchar2
                     ,p_description       varchar2
                     )
IS
BEGIN

  FND_FLEX_DSC_API.SET_SESSION_MODE ('customer_data');

  FND_FLEX_DSC_API.DELETE_CONTEXT (p_APPSNAME, p_FLEXFIELD_NAME, p_CONTEXT_CODE); 

  FND_FLEX_DSC_API.CREATE_CONTEXT (
           appl_short_name          => p_APPSNAME,
           flexfield_name           => p_FLEXFIELD_NAME,
           context_code             => p_CONTEXT_CODE,
           context_name             => p_CONTEXT_NAME,
           description              => p_DESCRIPTION,
           enabled                  => p_ENABLED,
           global_flag              => 'N');

EXCEPTION
  when bad_parameter then
    message(fnd_flex_dsc_api.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END df_context;


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
                     )
IS
  l_default_type_disp fnd_lookups.meaning%type;
BEGIN

  IF length(p_default_type) <= 1 THEN
     l_default_type_disp := get_meaning('FLEX_DEFAULT_TYPE',p_default_type);
  ELSE
     l_default_type_disp := p_default_type;
  END IF;

  FND_FLEX_DSC_API.SET_SESSION_MODE ('customer_data');

  FND_FLEX_DSC_API.DELETE_SEGMENT (
              appl_short_name          => p_APPSNAME,
              flexfield_name           => p_FLEXFIELD_NAME,
              context                  => p_CONTEXT_CODE,
              segment                  => p_NAME);

  FND_FLEX_DSC_API.SET_VALIDATION (TRUE);

  FND_FLEX_DSC_API.CREATE_SEGMENT (
              appl_short_name          => p_APPSNAME,
              flexfield_name           => p_FLEXFIELD_NAME,
              context_name             => p_CONTEXT_CODE,
              name                     => p_NAME,
              column                   => p_COLUMN,
              description              => p_DESCRIPTION,
              sequence_number          => p_SEQUENCE_NUMBER,
              enabled                  => p_ENABLED,
              displayed                => p_DISPLAYED,
              value_set                => p_VALUE_SET,
              default_type             => l_DEFAULT_TYPE_DISP,
              default_value            => p_DEFAULT_VALUE,
              required                 => p_REQUIRED,
              security_enabled         => p_SECURITY_ENABLED,
              display_size             => p_DISPLAY_SIZE,
              description_size         => p_DESCRIPTION_SIZE,
              concatenated_description_size => p_CONCAT_DESC_SIZE,
              range                    => p_RANGE,
              list_of_values_prompt    => p_LOV_PROMPT,
              window_prompt            => p_WIN_PROMPT);

EXCEPTION
  when bad_parameter then
    message(fnd_flex_dsc_api.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END df_segment;

-- Translations

PROCEDURE df_setup_tl 
                   (p_appsname          varchar2
                   ,p_flexfield_name    varchar2
                   ,p_language          varchar2
                   ,p_prompt            varchar2
                   ,p_title             varchar2
                   )
IS
BEGIN

  UPDATE fnd_descriptive_flexs_tl
     SET source_lang          = nvl(p_language,language)
        ,form_context_prompt  = nvl(p_prompt,form_context_prompt)
        ,title                = nvl(p_title, title)
   WHERE language                   = p_language
     AND descriptive_flexfield_name = p_flexfield_name
     AND application_id            in (SELECT application_id 
                                         FROM fnd_application
                                        WHERE application_short_name = p_appsname)
   ;

EXCEPTION
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END df_setup_tl;

PROCEDURE df_context_tl
                     (p_appsname          varchar2
                     ,p_flexfield_name    varchar2
                     ,p_context_code      varchar2
                     ,p_language          varchar2
                     ,p_context_name      varchar2
                     ,p_description       varchar2
                     )
IS
BEGIN

  UPDATE fnd_descr_flex_contexts_tl
     SET source_lang                    = nvl(p_language,language)
        ,descriptive_flex_context_name  = nvl(p_context_name,descriptive_flex_context_name)
        ,description                    = nvl(p_description, description)
   WHERE language                      = p_language
     AND descriptive_flexfield_name    = p_flexfield_name
     AND descriptive_flex_context_code = p_context_code
     AND application_id               in (SELECT application_id 
                                            FROM fnd_application
                                           WHERE application_short_name = p_appsname)
   ;

EXCEPTION
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END df_context_tl;

PROCEDURE df_segment_tl
                     (p_appsname          varchar2
                     ,p_flexfield_name    varchar2
                     ,p_context_code      varchar2
                     ,p_column            varchar2
                     ,p_language          varchar2
                     ,p_lov_prompt        varchar2
                     ,p_win_prompt        varchar2
                     ,p_description       varchar2
                     )
IS
BEGIN

  UPDATE fnd_descr_flex_col_usage_tl
     SET source_lang                    = nvl(p_language,language)
        ,description                    = nvl(p_description, description)
        ,form_above_prompt              = nvl(p_lov_prompt, form_above_prompt)
        ,form_left_prompt               = nvl(p_win_prompt, form_left_prompt)
   WHERE language                      = p_language
     AND descriptive_flexfield_name    = p_flexfield_name
     AND descriptive_flex_context_code = p_context_code
     AND application_column_name       = p_column
     AND application_id               in (SELECT application_id 
                                            FROM fnd_application
                                           WHERE application_short_name = p_appsname)
   ;

EXCEPTION
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END df_segment_tl;

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
                     )
IS

lv_meaning           FND_LOOKUPS.MEANING%TYPE;

BEGIN

  FND_PROGRAM.SET_SESSION_MODE ('customer_data');

  if fnd_program.executable_exists(p_SHORT_NAME,p_APPSNAME) then

     delete_exe_prog_p(p_SHORT_NAME,p_APPSNAME,
                       p_NAME,p_DESCRIPTION,p_FILE_NAME,p_SUBROUTINE);
  else
     lv_meaning := NULL;
     IF p_METHOD_CODE IS NOT NULL THEN
        SELECT meaning
        INTO   lv_meaning
        FROM   fnd_lookups
        WHERE  lookup_type = 'CP_EXECUTION_METHOD_CODE'
        AND    (lookup_code = p_METHOD_CODE
                OR
                meaning = p_METHOD_CODE);
     END IF;
   
     fnd_program.executable(p_NAME,p_APPSNAME,p_SHORT_NAME,p_DESCRIPTION,
                            lv_meaning,p_FILE_NAME,p_SUBROUTINE,p_ICONE,
                            p_SOURCE_LANG);
  end if;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END executable;

/******************************************************************************\
 * 24/06/2000 Modification A.Sery Ajout de la procedure update_request_lines  *
 * Cette prodedure est appelée lors de la suppression d'un concurrent program *
\******************************************************************************/

PROCEDURE update_request_lines(p_SHORT_NAME              varchar2
			      ,p_APPL_SHORT_NAME         varchar2
			      ,p_CONCURRENT_PROGRAM_ID	 number
			      )
IS 
BEGIN

IF p_CONCURRENT_PROGRAM_ID < 0
THEN
  -- Identification des lignes de request par affectation d'un numero particulier
  update FND_CONCURRENT_REQUESTS
  set CONCURRENT_PROGRAM_ID = p_CONCURRENT_PROGRAM_ID
  where CONCURRENT_PROGRAM_ID = ( select fcp.concurrent_program_id 
				  from fnd_concurrent_programs fcp, fnd_application fa
                                  where fcp.concurrent_program_name = p_SHORT_NAME and
                                  fa.application_id = fcp.application_id and
				  fa.application_short_name = p_APPL_SHORT_NAME
			        );
ELSE
  -- Remise en etat des requests
  update FND_CONCURRENT_REQUESTS
  set CONCURRENT_PROGRAM_ID = p_CONCURRENT_PROGRAM_ID
  where CONCURRENT_PROGRAM_ID = -9999;
END IF;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);

END update_request_lines;

PROCEDURE executable_desc (p_APPSNAME    varchar2
                          ,p_SHORT_NAME  varchar2
                          ,p_LANGUAGE    varchar2
                          ,p_NAME        varchar2
                          ,p_DESCRIPTION varchar2
                          ,p_SOURCE_LANG varchar2
                     )
IS
BEGIN

    UPDATE fnd_executables_tl
    SET    description           = p_DESCRIPTION
          ,user_executable_name  = p_NAME
          ,last_update_date      = SYSDATE
          ,source_lang           = DECODE(language,p_LANGUAGE,language,source_lang)
    WHERE p_LANGUAGE in (language, source_lang)
    AND   (application_id,executable_id) IN
              (SELECT fe.application_id
                     ,fe.executable_id
               FROM   fnd_executables fe
                     ,fnd_application fa
               WHERE  fa.application_short_name    = p_APPSNAME
                 AND  fe.application_id            = fa.application_id
                 AND  fe.executable_name           = p_SHORT_NAME
              ); 

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END executable_desc;


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
                  )
IS

  l_request_groups  RequestGroupsRec;
  l_delete_flag     BOOLEAN := FALSE;
  l_concurrent_program_id fnd_concurrent_programs.concurrent_program_id%type;

BEGIN

  FND_PROGRAM.SET_SESSION_MODE ('customer_data');

  if fnd_program.program_exists(p_SHORT_NAME,p_APPL_SHORT_NAME)
  then 
     -- memorisation des request groups avant suppression
     get_request_groups ('P', p_short_name, p_appl_short_name,
                         l_request_groups);
     
     -- Identification des lignes de request par affectation d'un numero particulier
     update_request_lines( p_short_name, p_appl_short_name, -9999 );
                         
     FND_PROGRAM.DELETE_PROGRAM(
              program_short_name       => p_SHORT_NAME,
              application              => p_APPL_SHORT_NAME
              );

     l_delete_flag := TRUE;
  end if;

  FND_PROGRAM.REGISTER (
              program                  => p_NAME,
              application              => p_APPL_SHORT_NAME,
              enabled                  => p_ENABLED,
              short_name               => p_SHORT_NAME,
              description              => p_DESCRIPTION,
              executable_short_name    => p_EXECUTABLE_NAME,
              executable_application   => p_EXECUTABLE_APPLICATION,
              execution_options        => p_EXECUTION_OPTIONS,
              priority                 => p_PRIORITY,
              save_output              => get_element(p_SAVE_OUTPUT_PRINT,'*',1),
              print                    => get_element(p_SAVE_OUTPUT_PRINT,'*',2),
              cols                     => get_element(p_COLS_ROWS,'*',1),
              rows                     => get_element(p_COLS_ROWS,'*',2),
              style                    => get_element(p_STYLE_INFOS,'*',2),
              style_required           => get_element(p_STYLE_INFOS,'*',1),
              printer                  => p_PRINTER,
              request_type             => get_element(p_REQUEST_TYPE,'*',1),
              request_type_application => get_element(p_REQUEST_TYPE,'*',2),
              use_in_srs               => p_USE_IN_SRS,
              allow_disabled_values    => p_ALLOW_DISABLED_VALUES,
              run_alone                => p_RUN_ALONE,
              output_type              => p_OUTPUT_TYPE,
              enable_trace             => p_ENABLE_TRACE,
              restart                  => p_RESTART,
              nls_compliant            => p_NLS_COMPLIANT,
              icon_name                => p_ICONE_NAME,
              language_code            => p_LANGUAGE_CODE);

  -- Recuperation du nouvel identifiant du programme.
  select concurrent_program_id
  into l_concurrent_program_id
  from fnd_concurrent_programs fcp, fnd_application fa
  where fcp.concurrent_program_name = p_SHORT_NAME and
  fa.application_id = fcp.application_id and
  fa.application_short_name = p_APPL_SHORT_NAME;

  -- Remise dans l'état initiale de la table des requests.
  update_request_lines( p_short_name, p_appl_short_name, l_concurrent_program_id );
  
  IF (l_delete_flag AND nvl(l_request_groups.array_size,0) > 0) THEN

    FOR i IN 1..l_request_groups.array_size
    LOOP

      FND_PROGRAM.Add_To_Group (p_short_name, p_appl_short_name,
                                l_request_groups.request_group(i),
                                l_request_groups.group_application(i));
                             
    END LOOP;

  END IF;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END program;


PROCEDURE program_desc (p_APPL_SHORT_NAME           varchar2
                       ,p_SHORT_NAME                varchar2
                       ,p_LANGUAGE_CODE             varchar2
                       ,p_NAME                      varchar2
                       ,p_DESCRIPTION               varchar2
                       ,p_SOURCE_LANG               varchar2
                       )
IS
BEGIN

    UPDATE fnd_concurrent_programs_tl
    SET    description                    = p_DESCRIPTION
          ,user_concurrent_program_name   = p_NAME
          ,last_update_date               = SYSDATE
          ,source_lang                    = DECODE(language,p_LANGUAGE_CODE,language,source_lang)
    WHERE p_LANGUAGE_CODE in (language, source_lang)
    AND   (application_id,concurrent_program_id) IN
              (SELECT fcp.application_id
                     ,fcp.concurrent_program_id
               FROM   fnd_concurrent_programs fcp
                     ,fnd_application fa
               WHERE  fa.application_short_name    = p_APPL_SHORT_NAME
                 AND  fcp.application_id           = fa.application_id
                 AND  fcp.concurrent_program_name  = p_SHORT_NAME
              ); 

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END program_desc;



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
                    )
IS

lv_meaning_default_type    fnd_lookups.meaning%TYPE;
lv_meaning_range           fnd_lookups.meaning%TYPE;

BEGIN

  FND_PROGRAM.SET_SESSION_MODE ('customer_data');

  -- DELETE_PARAMS_PROG_P(p_PROGRAM_SHORT_NAME, p_APPL_SHORT_NAME); 

  if not fnd_program.parameter_exists(p_PROGRAM_SHORT_NAME,
                                      p_APPL_SHORT_NAME,
                                      p_PARAMETER) 
  then 
     
     lv_meaning_default_type := NULL;
     lv_meaning_range := NULL;
     
     IF p_DEFAULT_TYPE IS NOT NULL THEN
        SELECT meaning
        INTO   lv_meaning_default_type
        FROM   fnd_lookups
        WHERE  lookup_type = 'FLEX_DEFAULT_TYPE'
        AND    (lookup_code = p_DEFAULT_TYPE
                OR
                meaning = p_DEFAULT_TYPE);
     END IF;
     
     IF p_RANGE IS NOT NULL THEN
        SELECT meaning
        INTO   lv_meaning_range
        FROM   fnd_lookups
        WHERE  lookup_type = 'RANGE_CODES'
        AND    (lookup_code = p_RANGE
                OR
                meaning = p_RANGE);
     END IF;


    FND_PROGRAM.PARAMETER (
        program_short_name            => p_PROGRAM_SHORT_NAME,
        application                   => p_APPL_SHORT_NAME,
        sequence                      => p_SEQUENCE,
        parameter                     => p_PARAMETER,
        description                   => p_DESCRIPTION,
        enabled                       => p_ENABLED,
        value_set                     => p_VALUE_SET,
        default_type                  => lv_meaning_default_type,
        default_value                 => p_DEFAULT_VALUE,
        required                      => p_REQUIRED,
        enable_security               => p_ENABLE_SECURITY,
        range                         => lv_meaning_range,
        display                       => p_DISPLAY,
        display_size                  => p_DISPLAY_SIZE,
        description_size              => p_DESCRIPTION_SIZE,
        concatenated_description_size => p_CONCAT_DESCRIPTION_SIZE,
        prompt                        => p_PROMPT,
        token                         => p_TOKEN);
  end if;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END parameter;

PROCEDURE parameter_desc (p_APPL_SHORT_NAME           varchar2
                         ,p_PROGRAM_SHORT_NAME        varchar2
                         ,p_APPLI_COL_NAME            varchar2
                         ,p_LANGUAGE                  varchar2
                         ,p_DESCRIPTION               varchar2
                         ,p_PROMPT                    varchar2
                         ,p_SOURCE_LANG               varchar2
                         )
IS
ln_num_col        NUMBER;
BEGIN

   BEGIN
      ln_num_col := to_number(p_APPLI_COL_NAME);

      UPDATE fnd_descr_flex_col_usage_tl
      SET    description           = p_DESCRIPTION
            ,form_left_prompt      = p_PROMPT
            ,form_above_prompt     = p_PROMPT
            ,last_update_date      = SYSDATE
            ,source_lang           = DECODE(language,p_LANGUAGE,language,source_lang)
      WHERE p_LANGUAGE in (language, source_lang)
      AND   descriptive_flexfield_name = '$SRS$.'|| p_PROGRAM_SHORT_NAME
      AND   descriptive_flex_context_code = 'Global Data Elements'
      AND   (application_id) IN
                (SELECT application_id
                 FROM   fnd_application
                 WHERE  application_short_name    = p_APPL_SHORT_NAME
                )
      AND   (application_column_name) IN
               (SELECT application_column_name
                FROM   fnd_descr_flex_column_usages
                WHERE   (application_id) IN
                         (SELECT application_id
                          FROM   fnd_application
                          WHERE  application_short_name    = p_APPL_SHORT_NAME
                         )
                AND   descriptive_flexfield_name = '$SRS$.'|| p_PROGRAM_SHORT_NAME
                AND   descriptive_flex_context_code = 'Global Data Elements'
                AND   column_seq_num = p_APPLI_COL_NAME
               );

   EXCEPTION
      WHEN OTHERS THEN
         UPDATE fnd_descr_flex_col_usage_tl
         SET    description           = p_DESCRIPTION
               ,form_left_prompt      = p_PROMPT
               ,form_above_prompt     = p_PROMPT
               ,last_update_date      = SYSDATE
               ,source_lang           = DECODE(language,p_LANGUAGE,language,source_lang)
         WHERE p_LANGUAGE in (language, source_lang)
         AND   descriptive_flexfield_name = '$SRS$.'|| p_PROGRAM_SHORT_NAME
         AND   application_column_name    = p_APPLI_COL_NAME
         AND   (application_id) IN
                   (SELECT application_id
                    FROM   fnd_application
                    WHERE  application_short_name    = p_APPL_SHORT_NAME
                   ); 
   END;
   

   BEGIN
      DELETE fnd_compiled_descriptive_flexs
      WHERE  descriptive_flexfield_name = '$SRS$.'|| p_PROGRAM_SHORT_NAME
      AND   (application_id) IN
              (SELECT application_id
               FROM   fnd_application
               WHERE  application_short_name    = p_APPL_SHORT_NAME
              ); 

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         NULL;
   END;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END parameter_desc;



PROCEDURE request_group (p_APPL_SHORT_NAME           varchar2
                        ,p_REQUEST_GROUP             varchar2
                        ,p_DESCRIPTION               varchar2
                        ,p_CODE                      varchar2
                        )
IS
BEGIN

  if not fnd_program.request_group_exists(p_REQUEST_GROUP,
                                          p_APPL_SHORT_NAME)
   then 

     FND_PROGRAM.REQUEST_GROUP (
              request_group => p_REQUEST_GROUP,
              application   => p_APPL_SHORT_NAME,
              code          => p_CODE,
              description   => p_DESCRIPTION);
  end if;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END request_group;


PROCEDURE request_group_unit (p_GROUP_APPL_SHORT_NAME     varchar2
                             ,p_REQUEST_GROUP             varchar2
                             ,p_PROG_APPL_SHORT_NAME      varchar2
                             ,p_PROGRAM_SHORT_NAME        varchar2
                             )
IS
BEGIN

  FND_PROGRAM.SET_SESSION_MODE ('customer_data');

  if not fnd_program.program_in_group(p_PROGRAM_SHORT_NAME,
                                      p_PROG_APPL_SHORT_NAME,
                                      p_REQUEST_GROUP,
                                      p_GROUP_APPL_SHORT_NAME)
  then 

     FND_PROGRAM.ADD_TO_GROUP (
              program_short_name       => p_PROGRAM_SHORT_NAME,
              program_application      => p_PROG_APPL_SHORT_NAME,
              request_group            => p_REQUEST_GROUP,
              group_application        => p_GROUP_APPL_SHORT_NAME);
  end if;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END request_group_unit;

PROCEDURE create_update_exe_p (p_APPSNAME    varchar2
                              ,p_NAME        varchar2
                              ,p_SHORT_NAME  varchar2
                              ,p_METHOD_CODE varchar2
                              ,p_FILE_NAME   varchar2
                              ,p_SUBROUTINE  varchar2
                              ,p_ICONE       varchar2
                              ,p_SOURCE_LANG varchar2
                              ,p_DESCRIPTION varchar2
                              )
IS

lv_meaning           FND_LOOKUPS.MEANING%TYPE;

BEGIN


  FND_PROGRAM.SET_SESSION_MODE ('customer_data');

  if fnd_program.executable_exists(p_SHORT_NAME,p_APPSNAME) then

        -- modification du nom du fichier execution si necessaire
        UPDATE fnd_executables
        SET    execution_file_name = p_file_name
              ,subroutine_name     = p_subroutine
              ,last_update_date    = sysdate	
	     WHERE executable_name      = p_short_name
        AND   (execution_file_name  <> p_file_name
               OR
               nvl(subroutine_name,0) <> nvl(p_subroutine,0)
              )
	AND   application_id in
           (SELECT  application_id
            FROM    fnd_application
            WHERE   application_short_name = p_appsname) ;

        -- modification du nom util executable et description si necessaire
        UPDATE fnd_executables_tl
        SET    description          = p_description
              ,user_executable_name = p_name
              ,last_update_date     = sysdate	
        WHERE  (description          <> p_description
        OR      user_executable_name <> p_name
               )
	AND   (application_id,executable_id) in
           (SELECT  fe.application_id
                   ,fe.executable_id
            FROM    fnd_executables fe
                   ,fnd_application fa
            WHERE   fa.application_short_name = p_appsname
            AND     fa.application_id         = fe.application_id
	    AND     fe.executable_name        = p_short_name);

  else
     lv_meaning := NULL;
     
     IF p_METHOD_CODE IS NOT NULL THEN
        SELECT meaning
        INTO   lv_meaning
        FROM   fnd_lookups
        WHERE  lookup_type = 'CP_EXECUTION_METHOD_CODE'
        AND    (lookup_code = p_METHOD_CODE
                OR
                meaning = p_METHOD_CODE);
     END IF;
                  
     fnd_program.executable(p_NAME,p_APPSNAME,p_SHORT_NAME,p_DESCRIPTION,
                            lv_meaning,p_FILE_NAME,p_SUBROUTINE,p_ICONE,
                            p_SOURCE_LANG);
  end if;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
 WHEN OTHERS THEN
    message('Erreur dans update_exe_p: '||SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END ; -- create_update_exe_p

PROCEDURE update_exe_p(p_executable_short_name IN varchar2
                      ,p_executable_app_short_name IN varchar2
                      ,p_executable_name IN varchar2
                      ,p_description  IN varchar2
                      ,p_file_name IN varchar2
                      ,p_subroutine IN varchar2
                      )
IS

BEGIN

        -- modification du nom du fichier execution si necessaire
        UPDATE fnd_executables
        SET    execution_file_name = p_file_name
              ,subroutine_name     = p_subroutine
              ,last_update_date    = sysdate	
	WHERE executable_name      = p_executable_short_name
        AND   (execution_file_name  <> p_file_name
               OR
               nvl(subroutine_name,0) <> nvl(p_subroutine,0)
              )
	AND   application_id in
           (SELECT  application_id
            FROM    fnd_application
            WHERE   application_short_name = p_executable_app_short_name) ;

        -- modification du nom util executable et description si necessaire
        UPDATE fnd_executables_tl
        SET    description          = p_description
              ,user_executable_name = p_executable_name
              ,last_update_date     = sysdate	
        WHERE  (description          <> p_description
        OR      user_executable_name <> p_executable_name
               )
	AND   (application_id,executable_id) in
           (SELECT  fe.application_id
                   ,fe.executable_id
            FROM    fnd_executables fe
                   ,fnd_application fa
            WHERE   fa.application_short_name = p_executable_app_short_name
            AND     fa.application_id         = fe.application_id
	    AND     fe.executable_name        = p_executable_short_name);

EXCEPTION
 WHEN OTHERS THEN
    message('Erreur dans update_exe_p: '||SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END ; -- update_exe_p


PROCEDURE delete_exe_prog_p(pv_executable_short_name IN varchar2
               		   ,pv_executable_app_short_name IN varchar2
                           ,pv_executable_name IN varchar2
                           ,pv_description  IN varchar2
                           ,pv_file_name IN varchar2
                           ,pv_subroutine IN varchar2
			   )
IS

-- recherche des programmes associes a l'executable
CURSOR cur_rech_progs IS
	SELECT fcp.concurrent_program_name
		,fa2.application_short_name
              ,fcp.application_id prog_application_id
              ,fcp.concurrent_program_id
	FROM
		fnd_concurrent_programs fcp
		,fnd_application fa2
		,fnd_executables fe
		,fnd_application fa
	WHERE
		fcp.application_id = fa2.application_id
	AND fcp.executable_id = fe.executable_id
	AND fe.application_id = fa.application_id
	AND fe.executable_name = pv_executable_short_name
	AND fa.application_short_name = pv_executable_app_short_name ;

rec_rech_progs cur_rech_progs%ROWTYPE;

BEGIN
	FOR rec_rech_progs IN cur_rech_progs LOOP

          -- suppression de tous les programmes rataches a l'executable
          /*-- Modif MEA : on ne supprime pas physiquement les programmes
            -- on coupe simplement le lien avec l'executable
	  FND_PROGRAM.DELETE_PROGRAM(
	     program_short_name	=> rec_rech_progs.concurrent_program_name
	    ,application	=> rec_rech_progs.application_short_name);
          */
          UPDATE fnd_concurrent_programs
             SET executable_application_id = -1
                ,executable_id             = -1
                ,attribute1                = to_char(executable_application_id)
                ,attribute2                = to_char(executable_id)
           WHERE application_id            = rec_rech_progs.prog_application_id
             AND concurrent_program_id     = rec_rech_progs.concurrent_program_id;

	END LOOP; -- rec_rech_progs

        -- mise a jour des informations sur l'executable
        update_exe_p(pv_executable_short_name
                    ,pv_executable_app_short_name 
                    ,pv_executable_name 
                    ,pv_description  
                    ,pv_file_name 
                    ,pv_subroutine
                    );

EXCEPTION
 WHEN OTHERS THEN
    message('Erreur dans delete_exe_prog_p: '||SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END ; -- delete_exe_prog_p

PROCEDURE delete_params_prog_p( pv_prog_short_name IN varchar2
			      , pv_prog_app_short_name IN varchar2)
IS

-- recherche des programmes associes a l'executable
CURSOR cur_rech_params IS
       SELECT p.end_user_column_name
       FROM   fnd_application a 
             ,fnd_descr_flex_column_usages p
       WHERE a.application_short_name = pv_prog_app_short_name
       AND p.descriptive_flexfield_name like '$SRS$.'||pv_prog_short_name
       AND p.application_id = a.application_id
       AND p.descriptive_flex_context_code = 'Global Data Elements';

rec_rech_params cur_rech_params%ROWTYPE;

BEGIN
	
   IF (gv_program_short_name IS NULL OR gv_appl_short_name IS NULL)   
   OR (gv_program_short_name <> pv_prog_short_name
       OR gv_appl_short_name <> pv_prog_app_short_name) THEN  

	FOR rec_rech_params IN cur_rech_params LOOP

          -- suppression de tous les parametres du programme
	  FND_PROGRAM.DELETE_PARAMETER(
	     program_short_name	=> pv_prog_short_name
	    ,application	=> pv_prog_app_short_name
            ,parameter          => rec_rech_params.end_user_column_name);

	END LOOP; -- rec_rech_params
	
      gv_program_short_name := pv_prog_short_name;
      gv_appl_short_name := pv_prog_app_short_name;

   END IF;

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
 WHEN OTHERS THEN
    message('Erreur dans delete_params_prog_p: '||SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
END ; -- delete_params_prog_p


PROCEDURE request_set(
                     p_APPSNAME              IN varchar2 
                    ,p_SHORT_NAME            IN varchar2
                    ,p_NAME                  IN varchar2
                    ,p_OWNER                 IN varchar2
                    ,p_PRINT_TOGETHER        IN varchar2
                    ,p_ALLOW_INCOMPATIBILITY IN varchar2
                    ,p_DESCRIPTION           IN varchar2
                    )
IS

  l_request_groups  RequestGroupsRec;
  l_delete_flag     BOOLEAN := FALSE;

BEGIN

   /* on detruit les jeux de traitements existants avec le meme nom */

   IF FND_SET.Request_Set_Exists(p_short_name, p_appsname) THEN

     -- memorisation des request groups avant suppression
     get_request_groups ('S', p_short_name, p_appsname,
                         l_request_groups);
                         
     FND_SET.DELETE_SET (p_SHORT_NAME,p_APPSNAME);

     l_delete_flag := TRUE;
   END IF;
   
   FND_SET.CREATE_SET (
                        NAME                       => p_NAME
                       ,SHORT_NAME                 => p_SHORT_NAME
                       ,APPLICATION                => p_APPSNAME 
                       ,DESCRIPTION                => p_DESCRIPTION
                       ,OWNER                      => p_OWNER
                       ,PRINT_TOGETHER             => p_PRINT_TOGETHER
                       ,INCOMPATIBILITIES_ALLOWED  => p_ALLOW_INCOMPATIBILITY
                       );
                       
   UPDATE   fnd_concurrent_programs
   SET      execution_method_code = 'I'
          , argument_method_code='4'
   WHERE concurrent_program_id 
          IN (SELECT concurrent_program_id
              FROM   fnd_request_sets
              WHERE  request_set_name = p_SHORT_NAME);

  IF (l_delete_flag AND nvl(l_request_groups.array_size,0) > 0) THEN

    FOR i IN 1..l_request_groups.array_size
    LOOP

      FND_SET.Add_Set_To_Group (p_short_name, p_appsname,
                                l_request_groups.request_group(i),
                                l_request_groups.group_application(i));
                             
    END LOOP;

  END IF;

EXCEPTION
   WHEN bad_parameter THEN
      raise_application_error(-20000,'request_set :'||chr(10)||fnd_set.message);
   WHEN OTHERS THEN
      raise_application_error(-20000,'request_set :'||chr(10)||fnd_set.message||
            chr(10)||SQLERRM);
END ; -- request_set



PROCEDURE request_set_desc(
                           p_APPSNAME              IN varchar2 
                          ,p_SET_SHORT_NAME        IN varchar2
                          ,p_LANGUAGE              IN varchar2
                          ,p_NAME                  IN varchar2
                          ,p_DESCRIPTION           IN varchar2
                          ,p_SOURCE_LANG           IN varchar2
                          )
IS
BEGIN

    UPDATE fnd_request_sets_tl
    SET    description           = p_DESCRIPTION
          ,user_request_set_name = p_NAME
          ,last_update_date      = SYSDATE
          ,source_lang           = DECODE(language,p_LANGUAGE,language,source_lang)
    WHERE p_LANGUAGE in (language, source_lang)
    AND   (application_id,request_set_id) IN
              (SELECT frs.application_id
                     ,frs.request_set_id
               FROM   fnd_request_sets frs
                     ,fnd_application fa
               WHERE  fa.application_short_name    = p_APPSNAME
                 AND  frs.application_id           = fa.application_id
                 AND  frs.request_set_name         = p_SET_SHORT_NAME
              ); 

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END request_set_desc;



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
                       )IS
BEGIN

   FND_SET.ADD_STAGE (
                     NAME                       => p_STAGE_NAME
                    ,REQUEST_SET                => p_SET_SHORT_NAME
                    ,SET_APPLICATION            => p_APPSNAME 
                    ,SHORT_NAME                 => p_STAGE_SHORT_NAME
                    ,DESCRIPTION                => p_DESCRIPTION
                    ,DISPLAY_SEQUENCE           => p_DISPLAY_SEQ
                    ,FUNCTION_SHORT_NAME        => p_FUNCTION
                    ,CRITICAL                   => p_CRITICAL
                    ,INCOMPATIBILITIES_ALLOWED  => p_ALLOW_INCOMPATIBILITY
                    ,START_STAGE                => p_FIRST_STAGE
                    );

EXCEPTION
   WHEN bad_parameter THEN
      raise_application_error(-20000,'request_stage :'||chr(10)||fnd_set.message);
   WHEN OTHERS THEN
      raise_application_error(-20000,'request_stage :'||chr(10)||fnd_set.message||
            chr(10)||SQLERRM);
END ; -- request_stage


PROCEDURE request_stage_desc(
                             p_APPSNAME              IN varchar2 
                            ,p_SET_SHORT_NAME        IN varchar2
                            ,p_STAGE_SHORT_NAME      IN varchar2 
                            ,p_LANGUAGE              IN varchar2
                            ,p_STAGE_NAME            IN varchar2
                            ,p_DESCRIPTION           IN varchar2
                            ,p_SOURCE_LANG           IN varchar2
                            )
IS
BEGIN

    UPDATE fnd_request_set_stages_tl
    SET    description           = p_DESCRIPTION
          ,user_stage_name       = p_STAGE_NAME
          ,last_update_date      = SYSDATE
          ,source_lang           = DECODE(language,p_LANGUAGE,language,source_lang)
    WHERE p_LANGUAGE in (language, source_lang)
    AND   (set_application_id,request_set_id,request_set_stage_id) IN
               (SELECT  frss.set_application_id
                       ,frss.request_set_id
                       ,frss.request_set_stage_id
                 FROM  fnd_application fa 
                      ,fnd_request_sets frs 
                      ,fnd_request_set_stages frss 
                 WHERE fa.application_short_name = p_APPSNAME 
                 AND   frs.application_id   = fa.application_id 
                 AND   frs.request_set_name = p_SET_SHORT_NAME 
                 AND   frs.application_id   = frss.set_application_id 
                 AND   frs.request_set_id   = frss.request_set_id
                 AND   frss.stage_name      = p_STAGE_SHORT_NAME
                );

EXCEPTION
  when bad_parameter then
    message(fnd_program.message);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
  when others then
    message(SQLERRM);
    raise_application_error(-20000,&&PACKAGE_NAME..message);
    
END request_stage_desc;



PROCEDURE link_stage(
                     p_APPSNAME     IN varchar2 
                    ,p_SET_SHORT_NAME     IN varchar2 
                    ,p_STAGE_NAME   IN varchar2 
                    ,p_SUCCESS_NAME IN varchar2 
                    ,p_WARNING_NAME IN varchar2 
                    ,p_ERROR_NAME   IN varchar2 
                    )IS
BEGIN

   IF p_SUCCESS_NAME IS NOT NULL THEN
      FND_SET.LINK_STAGES (
                           REQUEST_SET       => p_SET_SHORT_NAME
                          ,SET_APPLICATION   => p_APPSNAME 
                          ,FROM_STAGE        => p_STAGE_NAME
                          ,TO_STAGE          => p_SUCCESS_NAME
                          ,SUCCESS           => 'Y'
                          ,WARNING           => 'N'
                          ,ERROR             => 'N'
                          );
   END IF;

   IF p_WARNING_NAME IS NOT NULL THEN
      FND_SET.LINK_STAGES (
                        REQUEST_SET       => p_SET_SHORT_NAME
                       ,SET_APPLICATION   => p_APPSNAME 
                       ,FROM_STAGE        => p_STAGE_NAME
                       ,TO_STAGE          => p_WARNING_NAME
                       ,SUCCESS           => 'N'
                       ,WARNING           => 'Y'
                       ,ERROR             => 'N'
                       );
   END IF;

   IF p_ERROR_NAME IS NOT NULL THEN
      FND_SET.LINK_STAGES (
                        REQUEST_SET       => p_SET_SHORT_NAME
                       ,SET_APPLICATION   => p_APPSNAME 
                       ,FROM_STAGE        => p_STAGE_NAME
                       ,TO_STAGE          => p_ERROR_NAME
                       ,SUCCESS           => 'N'
                       ,WARNING           => 'N'
                       ,ERROR             => 'Y'
                       );
   END IF;

EXCEPTION
   WHEN bad_parameter THEN
      raise_application_error(-20000,'link_stage :'||chr(10)||fnd_set.message);
   WHEN OTHERS THEN
      raise_application_error(-20000,'link_stage :'||chr(10)||fnd_set.message||
            chr(10)||SQLERRM);
END ; -- link_stage


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
                    )IS
BEGIN

   FND_SET.ADD_PROGRAM (
                   PROGRAM                => p_PROG_NAME
                  ,PROGRAM_APPLICATION    => p_PROG_APPSNAME
                  ,REQUEST_SET            => p_SET_SHORT_NAME
                  ,SET_APPLICATION        => p_APPSNAME 
                  ,STAGE                  => p_STAGE_NAME
                  ,PROGRAM_SEQUENCE       => p_PROG_SEQ
                  ,CRITICAL               => p_CRITICAL
                  ,NUMBER_OF_COPIES       => p_NB_COPIES
                  ,SAVE_OUTPUT            => p_SAVE_OUTPUT
                  ,STYLE                  => p_PRINT_STYLE
                  ,PRINTER                => p_PRINTER
                 );

EXCEPTION
   WHEN bad_parameter THEN
      raise_application_error(-20000,'set_program :'||chr(10)||fnd_set.message);
   WHEN OTHERS THEN
      raise_application_error(-20000,'set_program :'||chr(10)||fnd_set.message||
            chr(10)||SQLERRM);
END ; -- set_program
           
PROCEDURE set_program_param(
                           p_APPSNAME        IN varchar2
                          ,p_SET_SHORT_NAME  IN varchar2
                          ,p_STAGE_NAME      IN varchar2
                          ,p_PROG_SEQ        IN varchar2
                          ,p_PARAM           IN varchar2
                          ,p_PROG_APPSNAME   IN varchar2
                          ,p_PROG_NAME       IN varchar2
                          ,p_DISPLAY         IN varchar2
                          ,p_UPDATE          IN varchar2
                          ,p_DEFAULT_VALUE   IN varchar2
                          ,p_DEFAULT_TYPE    IN varchar2
                          ,p_SHARED_PARAM    IN varchar2
                          ) IS
                          
lv_meaning_default_type    fnd_lookups.meaning%TYPE;

BEGIN
     lv_meaning_default_type := NULL;
    
     IF p_DEFAULT_TYPE IS NOT NULL THEN
        SELECT meaning
        INTO   lv_meaning_default_type
        FROM   fnd_lookups
        WHERE  lookup_type = 'FLEX_DEFAULT_TYPE'
        AND    (lookup_code = p_DEFAULT_TYPE
                OR
                meaning = p_DEFAULT_TYPE);
     END IF;
     
   FND_SET.PROGRAM_PARAMETER (
                      PROGRAM                => p_PROG_NAME
                     ,PROGRAM_APPLICATION    => p_PROG_APPSNAME
                     ,REQUEST_SET            => p_SET_SHORT_NAME
                     ,SET_APPLICATION        => p_APPSNAME 
                     ,STAGE                  => p_STAGE_NAME
                     ,PROGRAM_SEQUENCE       => p_PROG_SEQ
                     ,PARAMETER              => p_PARAM
                     ,DISPLAY                => p_DISPLAY
                     ,MODIFY                 => p_UPDATE
                     ,SHARED_PARAMETER       => p_SHARED_PARAM
                     ,DEFAULT_TYPE           => lv_meaning_default_type
                     ,DEFAULT_VALUE          => p_DEFAULT_VALUE
                    );

EXCEPTION
   WHEN bad_parameter THEN
      raise_application_error(-20000,'set_program_param :'||chr(10)||fnd_set.message);
   WHEN OTHERS THEN
      raise_application_error(-20000,'set_program_param :'||chr(10)||fnd_set.message||
            chr(10)||SQLERRM);
END ; -- set_program_param
           
PROCEDURE set_incompatibility(
                              p_APPSNAME                 IN varchar2
                             ,p_SET_SHORT_NAME           IN varchar2
                             ,p_STAGE_NAME               IN varchar2
                             ,p_APPSNAME_INCOMP          IN varchar2
                             ,p_SET_SHORT_NAME_INCOMP    IN varchar2
                             ,p_STAGE_NAME_INCOMP        IN varchar2
                             ,p_PROGRAM_INCOMP           IN varchar2
                             )IS
           
lv_prog_application     VARCHAR2(100);
lv_set_application     VARCHAR2(100);

BEGIN

   SELECT decode(p_PROGRAM_INCOMP,NULL,NULL,p_APPSNAME_INCOMP)
         ,decode(p_SET_SHORT_NAME_INCOMP,NULL,NULL,p_APPSNAME_INCOMP)
   INTO   lv_prog_application
         ,lv_set_application
   FROM DUAL;
   
   FND_SET.INCOMPATIBILITY (
                   REQUEST_SET            => p_SET_SHORT_NAME
                  ,APPLICATION            => p_APPSNAME 
                  ,STAGE                  => p_STAGE_NAME
                  ,INC_PROG               => p_PROGRAM_INCOMP
                  ,INC_PROG_APPLICATION   => lv_prog_application
                  ,INC_REQUEST_SET        => p_SET_SHORT_NAME_INCOMP
                  ,INC_SET_APPLICATION    => lv_set_application
                  ,INC_STAGE              => p_STAGE_NAME_INCOMP
                 );

EXCEPTION
   WHEN bad_parameter THEN
      raise_application_error(-20000,'set_incompatibility :'||chr(10)||fnd_set.message);
   WHEN OTHERS THEN
      raise_application_error(-20000,'set_incompatibility :'||chr(10)||fnd_set.message||
            chr(10)||SQLERRM);
END ; -- set_incompatibility


PROCEDURE prog_incompatibility(
            p_APPSNAME                 IN varchar2
           ,p_PROG_SHORT_NAME          IN varchar2
           ,p_APPSNAME_INCOMP          IN varchar2
           ,p_SET_SHORT_NAME_INCOMP    IN varchar2
           ,p_STAGE_NAME_INCOMP        IN varchar2
           ,p_PROGRAM_INCOMP           IN varchar2
                            )IS
           
lv_prog_application     VARCHAR2(100);
lv_set_application     VARCHAR2(100);

BEGIN

   IF p_SET_SHORT_NAME_INCOMP IS NOT NULL THEN
      -- le prog est incompatible avec un jeu d'etats ou une étape d'un jeu
      -- il faut appeler la proc d'incompatibilte des jeux
      
      FND_SET.INCOMPATIBILITY (
                      REQUEST_SET            => p_SET_SHORT_NAME_INCOMP
                     ,APPLICATION            => p_APPSNAME_INCOMP
                     ,STAGE                  => p_STAGE_NAME_INCOMP
                     ,INC_PROG               => p_PROG_SHORT_NAME
                     ,INC_PROG_APPLICATION   => p_APPSNAME
                     ,INC_REQUEST_SET        => NULL
                     ,INC_SET_APPLICATION    => NULL
                     ,INC_STAGE              => NULL
                    );
   ELSE
      -- incompatibilite entre programmes
      FND_PROGRAM.INCOMPATIBILITY(
                     PROGRAM_SHORT_NAME     => p_PROG_SHORT_NAME
                    ,APPLICATION            => p_APPSNAME
                    ,INC_PROG_SHORT_NAME    => p_PROGRAM_INCOMP
                    ,INC_PROG_APPLICATION   => p_APPSNAME_INCOMP
                    );
                    
   END IF;
   
EXCEPTION
   WHEN bad_parameter THEN
      raise_application_error(-20000,'prog_incompatibility :'||chr(10)||fnd_set.message);
   WHEN OTHERS THEN
      raise_application_error(-20000,'prog_incompatibility :'||chr(10)||fnd_set.message||
            chr(10)||SQLERRM);
END ; -- prog_incompatibility

-------------------------------------------------------------------------
PROCEDURE dka_fnd_lookup_type(
                           p_VIEW_APPSNAME          IN varchar2
                          ,p_LOOKUP_TYPE            IN varchar2
                          ,p_APPL_SHORT_NAME        IN varchar2
                          ,p_CUSTOMIZATION_LEVEL    IN varchar2
                          ,p_LOOKUP_TYPE_MEANING    IN varchar2
                          ,p_DESCRIPTION            IN varchar2
                          ) IS   

       secgrp_id    number;
       view_appid   number;  
       owner_appid  number;  
       user_id      number := 0;  
       row_id       varchar2(64); 
       db_owner_id  number;       
       l_exist      char(1);
       
       cursor cur_lookup_type is
         select '1'
         from FND_LOOKUP_TYPES LT
         where LT.LOOKUP_TYPE = p_LOOKUP_TYPE;

     begin  


       select APPLICATION_ID  
       into owner_appid  
       from FND_APPLICATION  
       where APPLICATION_SHORT_NAME = p_APPL_SHORT_NAME;

       select APPLICATION_ID  
       into view_appid  
       from FND_APPLICATION  
       where APPLICATION_SHORT_NAME = p_VIEW_APPSNAME;
      
        select SECURITY_GROUP_ID
        into secgrp_id
        from FND_SECURITY_GROUPS
        where SECURITY_GROUP_KEY = 'STANDARD';

       open cur_lookup_type;
       fetch cur_lookup_type into l_exist;
       if (cur_lookup_type%notfound) then
         -- No matching rows in any security group.  
         -- Insert a single row in requested security group
         Fnd_Lookup_Types_Pkg.Insert_Row(  
           x_rowid => row_id,  
           x_lookup_type => p_LOOKUP_TYPE,  
           x_security_group_id => secgrp_id,  
           x_view_application_id => view_appid,  
           x_application_id => owner_appid,  
           x_customization_level => p_CUSTOMIZATION_LEVEL,  
           x_meaning => p_LOOKUP_TYPE_MEANING,  
           x_description => p_DESCRIPTION,  
           x_creation_date => sysdate,  
           x_created_by => user_id,  
           x_last_update_date => sysdate,  
           x_last_updated_by => user_id,  
           x_last_update_login => 0);
       else
             -- Update row in all matching security groups.
             Fnd_Lookup_Types_Pkg.Update_Row(  
               x_lookup_type => p_LOOKUP_TYPE,  
               x_security_group_id => secgrp_id,  
               x_view_application_id => view_appid,  
               x_application_id => owner_appid,  
               x_customization_level => p_CUSTOMIZATION_LEVEL,  
               x_meaning => p_LOOKUP_TYPE_MEANING,  
               x_description => p_DESCRIPTION,  
               x_last_update_date => sysdate,  
               x_last_updated_by => user_id,  
               x_last_update_login => 0);  
       end if;

       close cur_lookup_type;
EXCEPTION
   WHEN OTHERS THEN
      message('Erreur dans DKA_FND_LOOKUP_TYPE: '||SQLERRM);
      raise_application_error(-20000,&&PACKAGE_NAME..message);
end dka_fnd_lookup_type; 
                

PROCEDURE dka_fnd_lookup_values_desc(
                           p_LOOKUP_CODE     IN varchar2
                          ,p_LOOKUP_TYPE     IN varchar2
                          ,p_LANGUAGE        IN varchar2
                          ,p_DESCRIPTION     IN varchar2
                          ,p_MEANING         IN varchar2
                          ) IS

       l_lookup_code    FND_LOOKUP_VALUES.lookup_code%TYPE;
       l_secgrp_id        number;
       l_view_appid       number;  
       l_user_id          number := 0;  
       l_row_id           varchar2(64); 
       

BEGIN

    SELECT  LT.security_group_id   ,   
            LT.view_application_id ,
            LV.lookup_code
    INTO    l_secgrp_id,
            l_view_appid,
            l_lookup_code    
    FROM    FND_LOOKUP_VALUES  LV, 
            FND_LOOKUP_TYPES   LT
    WHERE   LT.LOOKUP_TYPE       = p_LOOKUP_TYPE
    AND     LV.LOOKUP_TYPE   (+) = LT.LOOKUP_TYPE
    AND     LV.LANGUAGE      (+) = p_LANGUAGE
    AND     LV.LOOKUP_CODE   (+) = p_LOOKUP_CODE;


    IF (l_lookup_code IS NULL) THEN
         -- No matching rows in FND_LOOKUP_VALUES
         -- Insert a single row 
        Fnd_Lookup_Values_Pkg.Insert_Row(  
            x_rowid                 => l_row_id,  
            x_lookup_type           => p_LOOKUP_TYPE,  
            x_security_group_id     => l_secgrp_id,  
            x_view_application_id   => l_view_appid,  
            x_lookup_code           => p_LOOKUP_CODE,  
            x_meaning               => p_MEANING,  
            x_description           => p_DESCRIPTION,  
            x_enabled_flag          => 'Y',  
            x_start_date_active     => NULL, 
            x_end_date_active       => NULL, 
            x_creation_date         => sysdate,  
            x_created_by            => l_user_id,  
            x_last_update_date      => sysdate,  
            x_last_updated_by       => l_user_id,  
            x_last_update_login     => 0,
            x_territory_code        => NULL,  
            x_tag                   => NULL,  
            x_attribute_category    => NULL,  
            x_attribute1            => NULL,  
            x_attribute2            => NULL,  
            x_attribute3            => NULL,  
            x_attribute4            => NULL,  
            x_attribute5            => NULL,  
            x_attribute6            => NULL, 
            x_attribute7            => NULL, 
            x_attribute8            => NULL, 
            x_attribute9            => NULL, 
            x_attribute10           => NULL,  
            x_attribute11           => NULL,  
            x_attribute12           => NULL,  
            x_attribute13           => NULL,  
            x_attribute14           => NULL,   
            x_attribute15           => NULL  
            );  
    ELSE
        Fnd_Lookup_Values_Pkg.Update_Row(
            x_lookup_type           => p_LOOKUP_TYPE,  
            x_security_group_id     => l_secgrp_id,  
            x_view_application_id   => l_view_appid,  
            x_lookup_code           => p_LOOKUP_CODE,  
            x_meaning               => p_MEANING,  
            x_description           => p_DESCRIPTION,  
            x_enabled_flag          => 'Y',  
            x_start_date_active     => NULL, 
            x_end_date_active       => NULL, 
            x_last_update_date      => sysdate,  
            x_last_updated_by       => l_user_id,  
            x_last_update_login     => 0,
            x_territory_code        => NULL,  
            x_tag                   => NULL,  
            x_attribute_category    => NULL,  
            x_attribute1            => NULL,  
            x_attribute2            => NULL,  
            x_attribute3            => NULL,  
            x_attribute4            => NULL,  
            x_attribute5            => NULL,  
            x_attribute6            => NULL, 
            x_attribute7            => NULL, 
            x_attribute8            => NULL, 
            x_attribute9            => NULL, 
            x_attribute10           => NULL,  
            x_attribute11           => NULL,  
            x_attribute12           => NULL,  
            x_attribute13           => NULL,  
            x_attribute14           => NULL,   
            x_attribute15           => NULL  
        );
    END IF;
EXCEPTION
   WHEN OTHERS THEN
      message('Erreur dans FND_LOOKUP_VALUES_DESC: '||SQLERRM);
      raise_application_error(-20000,&&PACKAGE_NAME..message);
END dka_fnd_lookup_values_desc;

PROCEDURE dka_fnd_profile_options_desc(
                           p_PROFILE_OPTION_NAME          IN varchar2
                          ,p_LANGUAGE                     IN varchar2
                          ,p_USER_PROFILE_OPTION_NAME     IN varchar2
                          ,p_DESCRIPTION                  IN varchar2
                          ) IS
BEGIN

    UPDATE fnd_profile_options_tl
    SET    description                         = p_DESCRIPTION
          ,user_profile_option_name            = p_USER_PROFILE_OPTION_NAME
          ,last_update_date                    = SYSDATE
          ,source_lang                         = DECODE(language,p_LANGUAGE,language,source_lang)
    WHERE profile_option_name = p_PROFILE_OPTION_NAME
      AND p_LANGUAGE in (language, source_lang);

EXCEPTION
   WHEN OTHERS THEN
      message('Erreur dans fnd_lookup_values_desc: '||SQLERRM);
      raise_application_error(-20000,&&PACKAGE_NAME..message);
END ; -- fnd_profile_options_desc


PROCEDURE message(
                   p_appsname       IN VARCHAR2
                   ,p_message_name  IN VARCHAR2
                   ,p_language_code IN VARCHAR2
                   ,p_message_text  IN VARCHAR2
                   ) IS
    l_appl_id  fnd_new_messages.application_id%TYPE;
BEGIN
    -- On recherche l'application_id
    SELECT  a.application_id
    INTO    l_appl_id
    FROM    fnd_application  a
    WHERE   a.application_short_name = upper(p_APPSNAME);

    -- On essaie de mettre a jour le message    
    UPDATE  fnd_new_messages
    SET     message_text = p_message_text
    WHERE   application_id = l_appl_id
      AND   message_name = p_message_name
      AND   language_code = p_language_code;

    -- Si le message n'existait pas , on le crée
    IF SQL%ROWCOUNT = 0 THEN 
        INSERT INTO FND_NEW_MESSAGES( 
            application_id
            , language_code
            , message_number
            , message_name
            , message_text
            , creation_date
            , created_by
            , last_update_date
            , last_updated_by
            , last_update_login
            , description
            , type
            , max_length) 
        VALUES  ( 
            l_appl_id
            , p_language_code
            , NULL
            , p_message_name
            , p_message_text
            , trunc(sysdate)
            , 9999
            , trunc(sysdate)
            , 9999
            , NULL
            , NULL
            , 'OTHER'
            , NULL);


    END IF; -- SQL%ROWCOUNT = 0 THEN 
        
EXCEPTION
   WHEN OTHERS THEN
      message('Erreur dans message: '||SQLERRM);
      raise_application_error(-20000,&&PACKAGE_NAME..message);
     
END message ;

-----------------------------------------------------------------------
-- Procédure : dka_parameter
-- Objet     : upload dans la table DKA_PARAMETERS
-----------------------------------------------------------------------
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
           ) 
IS
  cv_date_format                CONSTANT VARCHAR2(30) := 'DD/MM/YYYY HH24:MI:SS';  
  lv_column_value               VARCHAR2(200);
  lv_select                     VARCHAR2(1000);
  ln_result                     NUMBER;
  lv_message                    VARCHAR2(255) := NULL;
  
BEGIN
    -- Contrôle de cohérence entre le type et la valeur du parametre
    IF (p_data_type  = 'VARCHAR2' AND p_varchar2_value IS NULL    ) OR
       (p_data_type  = 'NUMBER'   AND p_number_value   IS NULL    ) OR
       (p_data_type  = 'DATE'     AND p_date_value     IS NULL    ) OR
       (p_data_type  = 'BOOLEAN'  AND p_boolean_value  IS NULL    ) OR
       (p_data_type != 'VARCHAR2' AND p_varchar2_value IS NOT NULL) OR
       (p_data_type != 'NUMBER'   AND p_number_value   IS NOT NULL) OR
       (p_data_type != 'DATE'     AND p_date_value     IS NOT NULL) OR
       (p_data_type != 'BOOLEAN'  AND p_boolean_value  IS NOT NULL)
    THEN
        lv_message := lv_message || '   WARNING: Incohérence entre le type du parametre et sa valeur' || CHR(10);
    END IF;              
    
    -- Contrôle de cohérence par rapport au setup
    IF p_table_name IS NOT NULL THEN
        IF p_data_type = 'VARCHAR2' THEN
            lv_column_value := '''' || replace (p_varchar2_value, '''','''''') || '''';
        ELSIF p_data_type = 'NUMBER' THEN            
            lv_column_value := p_number_value;
        ELSIF p_data_type = 'DATE' THEN            
            lv_column_value := 'TO_DATE(''' || p_date_value || ''',''' || cv_date_format || ''')';
        ELSIF p_data_type = 'BOOLEAN' THEN            
            lv_column_value := '''' || p_boolean_value || '''';
        END IF;
        
        lv_select := 'SELECT COUNT(1)' 
                  || ' FROM dual'
                  || ' WHERE NOT EXISTS ( ' 
                  || '       SELECT 1'
                  || '       FROM  ' || p_table_name  || ' T'
                  || '       WHERE ' || p_column_name || ' = ' || lv_column_value
                  || ')' ;

        EXECUTE IMMEDIATE lv_select INTO ln_result;
        IF ln_result > 0 THEN
            lv_message := lv_message || '   WARNING: Incohérence entre le type du parametre et le setup' || CHR(10);
        END IF;    
    END IF;

    -- On essaie de mettre a jour le message    
    UPDATE  dka_parameters
    SET      description    = p_description   
            ,table_name     = p_table_name    
            ,column_name    = p_column_name   
            ,data_type      = p_data_type     
            ,varchar2_value = p_varchar2_value
            ,number_value   = p_number_value  
            ,date_value     = TO_DATE(p_date_value,cv_date_format)    
            ,boolean_value  = p_boolean_value 
    WHERE   program_code = p_program_code
      AND   parameter_name = p_parameter_name; 

    -- Si le message n'existait pas , on le crée
    IF SQL%ROWCOUNT = 0 THEN 
        INSERT INTO dka_parameters( 
              program_code  
            , parameter_name
            , description   
            , table_name    
            , column_name   
            , data_type     
            , varchar2_value
            , number_value  
            , date_value    
            , boolean_value 
        )
        VALUES  ( 
              p_program_code  
            , p_parameter_name
            , p_description   
            , p_table_name    
            , p_column_name   
            , p_data_type     
            , p_varchar2_value
            , p_number_value  
            , TO_DATE(p_date_value,cv_date_format)
            , p_boolean_value 
            );

    END IF; -- SQL%ROWCOUNT = 0 THEN 
    
    IF lv_message IS NOT NULL THEN
        lv_message := p_program_code || ' / ' || p_parameter_name || ':' || CHR(10) || lv_message;   
        fnd_file.put_line (fnd_file.Log, lv_message);
    END IF;
            
EXCEPTION
    WHEN OTHERS THEN
        message('Erreur dans dka_parameter: '||SQLERRM);
        raise_application_error(-20000,&&PACKAGE_NAME..message);
END dka_parameter ;

/* END_PUBLIC */

BEGIN

  gv_program_short_name:=NULL;
  gv_appl_short_name:=NULL;

END &&PACKAGE_NAME; /* package body*/

/

show errors package body &&PACKAGE_NAME

EXIT;
