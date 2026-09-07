-- Version finale, telle qu'intégrée dans DKA_IHREMP_PKG (body.sql, avant reactivate_employee).
-- ATTENTION : vérifier la signature exacte sur l'instance avant compilation :
--   SELECT argument_name, in_out, data_type
--   FROM   all_arguments
--   WHERE  package_name = 'HR_EX_EMPLOYEE_API'
--   AND    object_name  = 'REVERSE_TERMINATE_EMPLOYEE'
--   ORDER  BY sequence;

  PROCEDURE reverse_termination(pn_person_id IN per_all_people_f.person_id%TYPE) IS

    lv_current_program_unit  VARCHAR2(30) := 'reverse_termination';

    ln_period_of_service_id  per_periods_of_service.period_of_service_id%TYPE;
    ln_service_ovn           per_periods_of_service.object_version_number%TYPE;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    --Sélection de la dernière période de service clôturée (celle à annuler)
    gv_step  := lv_current_program_unit||' 001 : Sélection de la dernière période de service clôturée';log_message(gv_step);
    BEGIN
      SELECT period_of_service_id, object_version_number
      INTO   ln_period_of_service_id, ln_service_ovn
      FROM
       (SELECT period_of_service_id, object_version_number
        FROM   per_periods_of_service
        WHERE  person_id = pn_person_id
        AND    actual_termination_date IS NOT NULL
        ORDER BY date_start DESC, period_of_service_id DESC)
      WHERE ROWNUM = 1;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      --Aucune sortie a annuler
      ln_period_of_service_id := NULL;
    END;

    log_message(ln_period_of_service_id ||':' || ln_service_ovn);

    IF ln_period_of_service_id IS NOT NULL THEN
      gv_step  := lv_current_program_unit||' 002 : HR_EX_EMPLOYEE_API.REVERSE_TERMINATE_EMPLOYEE';log_message(gv_step);
      hr_ex_employee_api.reverse_terminate_employee
        ( -- Input data elements
          -- -----------------------------
         p_validate              => FALSE
        ,p_period_of_service_id  => ln_period_of_service_id
        ,p_object_version_number => ln_service_ovn
        ,p_clear_details         => 'Y' --Efface les informations de départ associées
        );
    END IF;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END reverse_termination;
