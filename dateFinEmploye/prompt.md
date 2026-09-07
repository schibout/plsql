# [BUG] Interface Employés (Kador -> EBS) : Mauvaise gestion des annulations de sortie (Date de fin NULL)

## 1. Contexte et Description du Problème
Dans le cadre de l'interface des employés (Kador vers Oracle HRMS), un problème de synchronisation survient lorsque le système source (Kador) envoie une date de fin de contrat par erreur, puis corrige cette erreur dans un flux ultérieur en envoyant une date de fin vide (`NULL`).

**Comportement actuel du package `DKA_IHREMP_PKG` :**
1. **Flux Erreur :** Kador envoie une date de fin (ex: 15/05/2024). L'employé est traité par la procédure `terminate_employee`. L'API `hr_ex_employee_api.actual_termination_emp` est appelée, l'employé devient inactif (`EX_EMP`) et sa période de service est clôturée.
2. **Flux Correction :** Kador envoie un flux correctif avec une date de fin vide (`NULL`). 
3. **Anomalie :** Le code actuel identifie l'employé comme `EX_EMP` et appelle la procédure `reactivate_employee`, qui utilise l'API `hr_employee_api.re_hire_ex_employee`. 

**Conséquences :** 
Au lieu d'annuler la sortie erronée, Oracle crée une **nouvelle période de service** (réembauche). Cela pollue l'historique RH de l'employé (rupture d'ancienneté, doublons de contrats, impacts potentiels sur la paie et les droits).

---

## 2. Solution Proposée
Il faut modifier le comportement de la procédure `maj_employe` pour distinguer une véritable réembauche (Re-Hire) d'une annulation de fin de contrat (Reverse Termination). 

Pour annuler une sortie, nous devons utiliser l'API standard Oracle `hr_ex_employee_api.reverse_terminate_employee` qui restaure la période de service initiale et efface la date de fin, rendant l'historique parfaitement propre.

### 2.1. Création de la procédure `reverse_termination`
Ajouter cette nouvelle procédure dans le *Body* du package `DKA_IHREMP_PKG` (par exemple au-dessus de `reactivate_employee`) :

```sql
  -----------------------------------------------------------------
  --  Nom           : reverse_termination
  --  Description   : procédure qui annule la sortie d'un employé envoyé par erreur
  --  PARAMETRES    : pn_person_id IN NUMBER
  -----------------------------------------------------------------
  PROCEDURE reverse_termination(pn_person_id IN per_all_people_f.person_id%TYPE) IS
    lv_current_program_unit  VARCHAR2(30) := 'reverse_termination';
    ln_period_of_service_id  NUMBER;
  BEGIN
    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    -- Récupération de la dernière période de service clôturée
    SELECT period_of_service_id
    INTO ln_period_of_service_id
    FROM (SELECT period_of_service_id
          FROM per_periods_of_service
          WHERE person_id = pn_person_id
          ORDER BY date_start DESC)
    WHERE ROWNUM = 1;

    gv_step  := lv_current_program_unit||' 001 : Appel API reverse_terminate_employee';
    log_message(gv_step);

    -- Annulation de la sortie
    hr_ex_employee_api.reverse_terminate_employee(
      p_validate              => FALSE,
      p_period_of_service_id  => ln_period_of_service_id,
      p_clear_details         => 'Y' -- Efface les informations de départ associées
    );

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);
  EXCEPTION
    WHEN OTHERS THEN
      gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
      log_message(gv_step,'Y');
      log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
      RAISE;
  END reverse_termination;