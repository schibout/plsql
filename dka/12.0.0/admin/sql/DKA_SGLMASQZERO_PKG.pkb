CREATE OR REPLACE PACKAGE BODY dka_sglmasqzero_pkg AS
  --------------------------------------------------------------------------------
  -- Programme           : Corps du package DKA_SGLMASQZERO_PKG
  -- Version             : 1.0
  -- Date de création    : 13/01/2020
  -- Auteur              : Capgemini
  -- Objet               : Supprimer les lignrsà zéro sous certaines conditions
  --                       Ce package est appele par le package gl_import_hook_pkg
  --
  -- Remarques           :
  ------------------------------------------------------------------------------
  --                INFORMATION RELATIVE A LA MAINTENANCE
  ------------------------------------------------------------------------------
  --    Date         Ver  |      Nom      |   Description de l'intervention
  ------------------------------------------------------------------------------
  --                      |               |                                    |
  ------------------------------------------------------------------------------
  --  13/01/2020     1.0  |     Capgemini | Version creation                   |
  ------------------------------------------------------------------------------
  g_pkg_name      CONSTANT VARCHAR2(30) := 'DKA_SGLMASQZERO_PKG';
  g_module_prefix CONSTANT VARCHAR2(50) := 'gl.plsql.' || g_pkg_name || '.';

  FUNCTION main(run_id IN NUMBER, errbuf IN OUT NOCOPY VARCHAR2)
    RETURN BOOLEAN IS
  
    l_api_name CONSTANT VARCHAR2(1000) := 'MAIN (' || run_id || ')';
  
    -- l_module                FND_LOG_MESSAGES.MODULE%TYPE := G_MODULE_PREFIX || l_api_name;
    l_module fnd_log_messages.module%TYPE := substr(g_module_prefix ||
                                                    l_api_name,
                                                    1,
                                                    255);
  
    l_mesg VARCHAR2(80);
  
    CURSOR int_control(p_run_id IN NUMBER) IS
      SELECT group_id, set_of_books_id sob_id, interface_table_name
        FROM gl_interface_control
       WHERE interface_run_id = p_run_id;
  
    TYPE xlacurtyp IS REF CURSOR; -- define weak REF CURSOR type
  BEGIN
  
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
      fnd_log.string(log_level => fnd_log.level_statement,
                     module    => l_module,
                     message   => '->IN ' || l_module);
    END IF;
  
    FOR rec_int_control IN int_control(run_id) LOOP
    
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
        fnd_log.string(log_level => fnd_log.level_statement,
                       module    => l_module,
                       message   => rec_int_control.group_id || '/' ||
                                    rec_int_control.sob_id || '/' ||
                                    rec_int_control.interface_table_name);
      END IF;
    
      IF rec_int_control.interface_table_name IS NOT NULL THEN
        EXECUTE IMMEDIATE 'DELETE FROM ' ||
                          rec_int_control.interface_table_name ||
                          ' gi WHERE gi.group_id = ' || rec_int_control.group_id || '
         AND nvl(gi.set_of_books_id,-1) = decode('||rec_int_control.sob_id||', -1, nvl(gi.set_of_books_id,-1), '||rec_int_control.sob_id||') AND (gi.accounted_dr = 0 OR gi.accounted_cr = 0)
         AND gi.code_combination_id IN ( SELECT gcc.code_combination_id FROM gl_code_combinations gcc, fnd_flex_value_sets ffvs, fnd_flex_values ffv
         WHERE gcc.segment3 = ffv.flex_value AND ffvs.flex_value_set_name = ''DAOPCCF_LOCAL'' AND ffv.flex_value_set_id = ffvs.flex_value_set_id
         and nvl(FFV.ATTRIBUTE18,''Y'') = ''N'' AND ffv.enabled_flag = ''Y'' AND SYSDATE BETWEEN nvl(ffv.start_date_active, SYSDATE) AND nvl(ffv.end_date_active, SYSDATE))';
      
      ELSE
      
        DELETE FROM gl_interface gi
         WHERE gi.group_id = rec_int_control.group_id
           AND nvl(gi.set_of_books_id,-1) =
               decode(rec_int_control.sob_id, -1, nvl(gi.set_of_books_id,-1), rec_int_control.sob_id)
           AND (gi.accounted_dr = 0 OR gi.accounted_cr = 0)
           AND gi.code_combination_id IN
               (SELECT gcc.code_combination_id
                  FROM gl_code_combinations gcc,
                       fnd_flex_value_sets  ffvs,
                       fnd_flex_values      ffv
                 WHERE gcc.segment3 = ffv.flex_value
                   AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
                   AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                   AND nvl(ffv.attribute18, 'Y') = 'N'
                   AND ffv.enabled_flag = 'Y'
                   AND SYSDATE BETWEEN nvl(ffv.start_date_active, SYSDATE) AND
                       nvl(ffv.end_date_active, SYSDATE));
      
      END IF;
    END LOOP;
  
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
      fnd_log.string(log_level => fnd_log.level_statement,
                     module    => l_module,
                     message   => '<-OUT ' || l_module);
    END IF;
  
    RETURN(TRUE);
  EXCEPTION
    WHEN OTHERS THEN
      l_mesg := substr(SQLERRM, 1, 80);
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
        fnd_log.string(log_level => fnd_log.level_statement,
                       module    => l_module,
                       message   => 'l_mesg ' || l_mesg);
      END IF;
    
      errbuf := l_mesg;
      fnd_file.put_line(fnd_file.log,
                        'Erreur ' || g_pkg_name || '.MAIN : ' || errbuf);
      RETURN FALSE;
  END main;

END dka_sglmasqzero_pkg;
/
SHOW ERRORS PACKAGE DKA_SGLMASQZERO_PKG;
EXIT
