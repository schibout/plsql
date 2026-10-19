CREATE OR REPLACE PACKAGE BODY dka_sglalirefemp_pkg AS
  --------------------------------------------------------------------------------
  -- Programme           : Corps du package DKA_SGLALIREFEMP_PKG
  -- Version             : 1.0
  -- Date de création    : 04/12/2019
  -- Auteur              : Capgemini
  -- Objet               : Alimenter la reference de lettrazge avec l'employee AP
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
  --  04/12/2019     1.0  | Capgemini     | Version creation      
  --  16/03/2022     1.1  | Anas RAOUF    | EDB281B - Retour arrière de la récupération du fournisseur AP
  ------------------------------------------------------------------------------
  g_pkg_name      CONSTANT VARCHAR2(30) := 'DKA_SGLALIREFEMP_PKG';
  g_module_prefix CONSTANT VARCHAR2(50) := 'gl.plsql.' || g_pkg_name || '.';

  FUNCTION main(run_id IN NUMBER, errbuf IN OUT NOCOPY VARCHAR2)
    RETURN BOOLEAN IS
  
    l_api_name CONSTANT VARCHAR2(1000) := 'MAIN (' || run_id || ')';
  
    -- l_module                FND_LOG_MESSAGES.MODULE%TYPE := G_MODULE_PREFIX || l_api_name;
    l_module fnd_log_messages.module%TYPE := substr(g_module_prefix ||
                                                    l_api_name,
                                                    1,
                                                    255);
  
    l_mesg  VARCHAR2(80);
    l_count NUMBER;
  
    CURSOR int_control(p_run_id IN NUMBER) IS
      SELECT group_id, set_of_books_id sob_id, interface_table_name
        FROM gl_interface_control
       WHERE interface_run_id = p_run_id;
  
    CURSOR gl_int(p_group_id IN NUMBER, p_sob_id IN NUMBER) IS
      SELECT gi.rowid rid, gcc.segment3, pv.segment1 emp_num
        FROM gl_interface                 gi,
             gl_code_combinations         gcc,
             xla_ae_lines                 xal,
             xla_distribution_links       xdl,
             ap_invoice_distributions_all aid,
             ap_invoices_all              aia,
             po_vendors                   pv
       WHERE gi.group_id = p_group_id
         AND gi.set_of_books_id =
             decode(p_sob_id, -1, gi.set_of_books_id, p_sob_id)
         AND gi.code_combination_id = gcc.code_combination_id
         AND xal.gl_sl_link_id = gi.gl_sl_link_id
         AND xal.gl_sl_link_table = gi.gl_sl_link_table
         AND xdl.ae_header_id = xal.ae_header_id
         AND xdl.ae_line_num = xal.ae_line_num
         AND xdl.source_distribution_type IN ('AP_INV_DIST', 'AP_PREPAY') --= 'AP_INV_DIST'
         AND xdl.source_distribution_id_num_1 = aid.invoice_distribution_id
         AND aid.invoice_id = aia.invoice_id
         AND pv.vendor_id = aia.vendor_id
         AND pv.vendor_type_lookup_code = 'EMPLOYEE'
         AND gcc.segment3 IN
             (SELECT ffv.flex_value
                FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
               WHERE ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
                 AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND ffv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffv.start_date_active, SYSDATE) AND
                     nvl(ffv.end_date_active, SYSDATE))
    UNION ALL
      SELECT DISTINCT gi.rowid rid, gcc.segment3, pv.segment1 emp_num
        FROM gl_interface           gi,
             gl_code_combinations   gcc,
             xla_distribution_links xdl,
             ap_payment_hist_dists  aphd,
             ap_payment_history_all apha,
             ap_checks_all          aca,
             xla_ae_lines           xal,
             po_vendors             pv
       WHERE gi.group_id = p_group_id
         AND gi.set_of_books_id =
             decode(p_sob_id, -1, gi.set_of_books_id, p_sob_id)
         AND gi.code_combination_id = gcc.code_combination_id
         AND xal.gl_sl_link_id = gi.gl_sl_link_id
         AND xal.gl_sl_link_table = gi.gl_sl_link_table
         AND xdl.source_distribution_type = 'AP_PMT_DIST'
         AND xdl.application_id = 200
         AND aphd.payment_hist_dist_id = xdl.source_distribution_id_num_1
         AND apha.payment_history_id = aphd.payment_history_id
         AND aca.check_id = apha.check_id
         AND xdl.ae_line_num = xal.ae_line_num
         AND xdl.ae_header_id = xal.ae_header_id
         AND pv.vendor_id = aca.vendor_id
         AND pv.vendor_type_lookup_code = 'EMPLOYEE'
         AND gcc.segment3 IN
             (SELECT ffv.flex_value
                FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
               WHERE ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
                 AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND ffv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffv.start_date_active, SYSDATE) AND
                     nvl(ffv.end_date_active, SYSDATE));

  
    CURSOR gl_int_xla(p_ccid             IN NUMBER,
                      p_sl_link_id       IN NUMBER,
                      p_gl_sl_link_table IN VARCHAR2) IS
      SELECT gcc.segment3, pv.segment1 emp_num
        FROM gl_code_combinations         gcc,
             xla_ae_lines                 xal,
             xla_distribution_links       xdl,
             ap_invoice_distributions_all aid,
             ap_invoices_all              aia,
             po_vendors                   pv
       WHERE gcc.code_combination_id = p_ccid
         AND xal.gl_sl_link_id = p_sl_link_id
         AND xal.gl_sl_link_table = p_gl_sl_link_table
         AND xdl.ae_header_id = xal.ae_header_id
         AND xdl.ae_line_num = xal.ae_line_num
         AND xdl.source_distribution_type IN ('AP_INV_DIST', 'AP_PREPAY') --= 'AP_INV_DIST'
         -- 06/07/2020 NBO Correction suite à un bug
         -- AND xdl.source_distribution_id_num_1 = aid.invoice_distribution_id
         AND DECODE(xdl.source_distribution_type, 'AP_INV_DIST', xdl.source_distribution_id_num_1, xdl.applied_to_dist_id_num_1) = aid.invoice_distribution_id
         AND aid.invoice_id = aia.invoice_id
         AND pv.vendor_id = aia.vendor_id
         AND pv.vendor_type_lookup_code = 'EMPLOYEE'
         AND gcc.segment3 IN
             (SELECT ffv.flex_value
                FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
               WHERE ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
                 AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                 AND ffv.enabled_flag = 'Y'
                 AND SYSDATE BETWEEN nvl(ffv.start_date_active, SYSDATE) AND
                     nvl(ffv.end_date_active, SYSDATE))
      UNION ALL
        SELECT DISTINCT gcc.segment3, pv.segment1 emp_num
          FROM gl_code_combinations   gcc,
               xla_distribution_links xdl,
               ap_payment_hist_dists  aphd,
               ap_payment_history_all apha,
               ap_checks_all          aca,
               xla_ae_lines           xal,
               po_vendors             pv
         WHERE gcc.code_combination_id = p_ccid
           AND xal.gl_sl_link_id = p_sl_link_id
           AND xal.gl_sl_link_table = p_gl_sl_link_table
           AND xdl.source_distribution_type = 'AP_PMT_DIST'
           AND xdl.application_id = 200
           AND aphd.payment_hist_dist_id = xdl.source_distribution_id_num_1
           AND apha.payment_history_id = aphd.payment_history_id
           AND aca.check_id = apha.check_id
           AND xdl.ae_line_num = xal.ae_line_num
           AND xdl.ae_header_id = xal.ae_header_id
           AND pv.vendor_id = aca.vendor_id
           AND pv.vendor_type_lookup_code = 'EMPLOYEE'
           AND gcc.segment3 IN
               (SELECT ffv.flex_value
                  FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
                 WHERE ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
                   AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                   AND ffv.enabled_flag = 'Y'
                   AND SYSDATE BETWEEN nvl(ffv.start_date_active, SYSDATE) AND
                       nvl(ffv.end_date_active, SYSDATE));
  
    TYPE xlacurtyp IS REF CURSOR; -- define weak REF CURSOR type
    xla_cv             xlacurtyp; -- declare cursor variable
    l_ccid             NUMBER;
    l_gl_sl_link_id    NUMBER;
    l_gl_sl_link_table VARCHAR2(30);
    l_rid              VARCHAR2(30);
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
                                    rec_int_control.sob_id);
        fnd_log.string(log_level => fnd_log.level_statement,
                       module    => l_module,
                       message   => 'table_name=' || rec_int_control.interface_table_name);
      END IF;
    
      IF rec_int_control.interface_table_name IS NOT NULL THEN
        OPEN xla_cv FOR -- open cursor variable
         'SELECT code_combination_id,   gl_sl_link_id, gl_sl_link_table, gi.rowid FROM ' || rec_int_control.interface_table_name || ' gi ';
        LOOP
          FETCH xla_cv
            INTO l_ccid, l_gl_sl_link_id, l_gl_sl_link_table, l_rid;
        
          EXIT WHEN xla_cv%NOTFOUND;
          
          IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.string(log_level => fnd_log.level_statement,
                           module    => l_module,
                           message   => l_ccid ||'/'|| l_gl_sl_link_id ||'/'|| l_gl_sl_link_table);
          END IF;
        
          /*FOR rec_gl_int_xla IN gl_int_xla(l_ccid,
                                           l_gl_sl_link_id,
                                           l_gl_sl_link_table) LOOP
          
            EXECUTE IMMEDIATE 'UPDATE ' || rec_int_control.interface_table_name ||
                              ' SET jgzz_recon_ref = ''' ||
                              rec_gl_int_xla.emp_num ||
                              ''' WHERE rowid = ''' || l_rid || '''';
          
          END LOOP;*/ --EDB281B
        END LOOP;
      
        CLOSE xla_cv;
      
      ELSE
        FOR rec_gl_int IN gl_int(rec_int_control.group_id,
                                 rec_int_control.sob_id) LOOP
        
          IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.string(log_level => fnd_log.level_statement,
                           module    => l_module,
                           message   => 'employee_num=' ||
                                        rec_gl_int.emp_num);
          END IF;
        
          /*UPDATE gl_interface
             SET jgzz_recon_ref = rec_gl_int.emp_num
           WHERE ROWID = rec_gl_int.rid;*/--EDB281B
        
        END LOOP;
      
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

END dka_sglalirefemp_pkg;
/
SHOW ERRORS PACKAGE DKA_SGLALIREFEMP_PKG;
EXIT
