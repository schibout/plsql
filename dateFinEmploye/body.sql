create or replace PACKAGE BODY      DKA_IHREMP_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IHREMP_PKG.pkb
-- DESCRIPTION       : DKA_IHREMP_PKG package body :
---
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 11/04/2016
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
--- 11/04/2016 JJA Portage HELIOS R12 (Réécriture)
--- 03/07/2016 JJA Correction get_period_gl : recherche de la période ouverte la plus ancienne (start_date)
---                           Creation_employe : modification du controle de l'API
---                           *Compte Bancaire : Renvoi des messages d'erreur
---                           *Affectation : CUF Obligatoire
--- 18/10/2016 JJA Ajout de la création en fonction de la hiérarchie des employés
---                Lors de la création, si un employé a un compte bancaire invalide, on poursuit la création
--- 09/05/2017 MEG artf2151094 : EDB067_INT076 - Modification du contrôle sur le champ SOURCE
--- 07/06/2017 YWA EDB072 INT076_évolution interface ressources et données bancaires ressources
--- 28/07/2017 ADE artf2200909 : Reprise des employés - Correction de l'ordre de la requete de création
--- 04/09/2017 NBO artf2216362 - INT076 - Problème de numérotation des fournisseurs en mode quotidien
--- 13/11/2017 JJA artf2275018 - Correction numérotation des fournisseurs en mode quotidien
--- 13/12/2017 JJA artf2275018 - Correction sur la mise à jour des comptes bancaires - Defect Beb #1144
--- 22/02/2018 OBE artf2391673 : INT076 - Mise à jour des données affectations
--- 27/03/2018 JJA artf2473330 : INT076 - Corrections diverses
--- 28/05/2018 RBE artf2688394 : INC0219044 : Correctif sur l'interface Employé - Interface GXP => Oracle ?? Matricule 63309B
--- 04/06/2018 NBO artf2646661 : TASK0056324  l'interface Employés, en cas d'erreur bloquante sur les changements d'organisations
--- 11/06/2018 OBE artf2745655 : INC0223479 - INT076 - Interface Employés vers Oracle
--- 20/06/2018 JJA INT076  : Corrections mise à jour du fournisseur et activation/désactivation d'un employé
--- 05/07/2018 NBO artf2848681 : INC0230966 - Problème de mise à jour interface employé
--- 23/07/2018 NBO artf2646661 : TASK0056324  l'interface Employés, en cas d'erreur bloquante sur les changements d'organisations
--- 29/05/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
--- 04/06/2019 NBO artf07257953 : INC0319624 - Problème interface employé
--- 01/08/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
--- 27/09/2019 NBO artf07283364 : INC0327452 -  plusieurs ressources ont été rejetées dans l'interface avec l'erreur "erreur de désactivation".
--- 11/11/2021 ARA EDB281 - DGE20210006 - Alimentation du segment5 de la clé comptable
--- 26/06/2024 ARA KDFI-2084 Correctif pour prise en compte des employées actif dans le futur
--- 10/12/2024 SHA KAFI-877  Interface Employée INT076 - Accostage Ressource V2 - Gestion Code Société
--- 19/11/2025 ARA FIX-ROLLBACK-REGRESSION-MIGRATION R12.2.13
----------------------------------------------------------------------------------------------

  --TYPE

  --CONSTANTE
  cv_package_name      CONSTANT VARCHAR2(30)  := 'DKA_IHREMP_PKG';

  --CONSTANTE JEU DE VALEUR, TRANSCO ....
  cv_program_name      CONSTANT VARCHAR2(30)  := 'DKA_IHREMP';
  cv_line              CONSTANT VARCHAR2(75)  := '+-------------------------------------------------------------------------+';

  --cv_assignment_type   CONSTANT VARCHAR2(1)   := 'E';
  cd_date_fin          CONSTANT DATE          := TO_DATE ('31/12/4712', 'DD/MM/YYYY');

  --VARIABLE GLOBALES
  gn_conc_request_id            FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;

  gn_user_id                    NUMBER;
  gn_login_id                   NUMBER;
  gn_business_group_id          NUMBER;
  gn_job_group_id               NUMBER;

  gv_style                      VARCHAR2(50);
  gv_default_job                per_jobs.name%TYPE;

  gv_vendor_type_lookup_code      ap_suppliers.vendor_type_lookup_code%TYPE;
  gn_term_id                      ap_terms.term_id%TYPE;
  gv_term_name                    ap_terms.name%TYPE;
  gn_payment_priority             ap_suppliers.payment_priority%TYPE;
  gv_pay_group_lookup_code        ap_suppliers.pay_group_lookup_code%TYPE;
  gv_pay_date_basis_lookup_code   ap_suppliers.pay_date_basis_lookup_code%TYPE;
  gv_terms_date_basis             ap_suppliers.terms_date_basis%TYPE;
  gv_payment_method_cheque        ap_suppliers.payment_method_lookup_code%TYPE;
  gv_payment_method_virement      ap_suppliers.payment_method_lookup_code%TYPE;

  gv_vendor_attribute_category    ap_suppliers.attribute_category%TYPE;

  gv_vendor_site_code             ap_supplier_sites_all.vendor_site_code%TYPE;
  gv_vendor_site_ctry             ap_supplier_sites_all.country%TYPE;
  gv_ccid_defaut                  VARCHAR2(150);
  gv_accts_local                  VARCHAR2(150);
  gv_accts_anal                   VARCHAR2(150);
  gv_prepay_local                 VARCHAR2(150);
  gv_prepay_anal                  VARCHAR2(150);

  gv_source_contact               VARCHAR2(150);
  gv_source_employe               VARCHAR2(150);

  --gv_step                       VARCHAR2(500);
    gv_step                       VARCHAR2(4000);


  --PARAMETRES
  gv_debug            VARCHAR2(10);

  -----------------------------------------------------------------------
  -- GET_TIME
  ----------------------------------------------------------------------
  --  fonction qui retourne la date et l'heure actuelle
  --
  --  Parametres : N/A
  --
  -----------------------------------------------------------------
  FUNCTION get_time RETURN VARCHAR2 IS
  BEGIN
    RETURN to_char(sysdate,'DD/MM/YYYY HH24:MI:SS');
  END get_time;

  -----------------------------------------------------------------------
  -- LOG_MESSAGE
  ----------------------------------------------------------------------
  --  fonction qui affiche dans le fichier LOG
  --
  --  Parametres : N/A
  --
  -----------------------------------------------------------------
  PROCEDURE log_message (pv_message            IN      VARCHAR2               -- Message a afficher dans le log
                        ,pv_force              IN      VARCHAR2 DEFAULT NULL  -- force l'affichage dans le log
                        ) IS
  BEGIN
   IF gv_debug = 'Y' or nvl(pv_force,'#') = 'Y' then
     dka_tools_pkg.put_log_message(pv_message);
   END IF;
  END log_message;

  -----------------------------------------------------------------------
  -- OUT_MESSAGE
  ----------------------------------------------------------------------
  --  fonction qui affiche dans le fichier OUT
  --
  --  Parametres : N/A
  --
  -----------------------------------------------------------------
  PROCEDURE out_message  (pv_message            IN      VARCHAR2               -- Message a afficher dans le fichier de sortie
                          )  IS
  BEGIN
     dka_tools_pkg.put_outdebug_message(pv_message);
  END out_message;

  -----------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : procedure d'initialisation
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE init(pv_errbuf        OUT NOCOPY VARCHAR2,
                 pn_retcode       OUT NOCOPY NUMBER) IS

    lv_current_program_unit  VARCHAR2(30) := 'init';
    rec_param                dka_parameters%ROWTYPE;

  BEGIN



    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    gv_step  := lv_current_program_unit||' 001 : Init variables';
    log_message(gv_step);

    pn_retcode         := 0;
    pv_errbuf          := NULL;
    gn_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;

    gn_user_id           := fnd_profile.value('USER_ID');
    gn_login_id          := fnd_profile.value('LOGIN_ID');
    gn_business_group_id := fnd_profile.value('PER_BUSINESS_GROUP_ID');

    gv_style             := 'FR';
    gv_default_job       := 'TECH';

    gv_vendor_type_lookup_code      := 'EMPLOYEE';
    gv_term_name                    := 'Comptant';
    gn_payment_priority             := 99;
    gv_pay_group_lookup_code        := 'EMPLOYE';
    gv_pay_date_basis_lookup_code   := 'DUE';
    gv_terms_date_basis             := 'Invoice';
    gv_payment_method_cheque        := 'CHECK';
    gv_payment_method_virement      := 'EFT';
    gv_vendor_attribute_category    := 'EMPLOYEE';

    gv_vendor_site_code             := 'OFFICE';
    gv_vendor_site_ctry             := 'FR';
    gv_ccid_defaut                  := '0';
    gv_accts_local                  := '425550';
    gv_accts_anal                   := '25080';
    gv_prepay_local                 := '425503';
    gv_prepay_anal                  := '14300';

    gv_step  := lv_current_program_unit||' 002 : Détermination des conditions de reglement';
    log_message(gv_step);
    SELECT t.term_id
    INTO   gn_term_id
    FROM   ap_terms t
    WHERE  t.name = gv_term_name;

    gv_step  := lv_current_program_unit||' 003 : Détermination du JOB_GROUP_ID';
    log_message(gv_step);
    SELECT job_group_id
    into gn_job_group_id
    FROM PER_JOB_GROUPS
    WHERE internal_name = 'HR_0'
    AND business_group_id = gn_business_group_id;

    gv_step  := lv_current_program_unit||' 004 : Mise a jour du flag INSERT_UPDATE_FLAG';
    log_message(gv_step);

    --XXEAI_HR_PEOPLE_INT
    UPDATE xxeai_hr_people_int hpi
    SET
     INSERT_UPDATE_FLAG = DECODE((SELECT COUNT(1)
                                  FROM per_all_people_f papf
                                  WHERE papf.employee_number = hpi.employee_number
                                  AND business_group_id= gn_business_group_id),
                                 0,'I',
                                 'U')
    WHERE
     INTERFACE_STATUS != 'TRAITE'
    ;

    --XXEAI_HR_BANK_INT_ALL
    UPDATE xxeai_hr_bank_int_all hbi
    SET
     INSERT_UPDATE_FLAG = DECODE((SELECT COUNT(1)
                                  FROM per_all_people_f papf
                                  WHERE papf.employee_number = hbi.employee_number
                                  AND business_group_id= gn_business_group_id),
                                 0,'I',
                                 'U')
    WHERE
     INTERFACE_STATUS != 'TRAITE'
    ;

    --XXEAI_HR_ASSIGNMENT_INT
    UPDATE xxeai_hr_assignment_int hai
    SET
     INSERT_UPDATE_FLAG = DECODE((SELECT COUNT(1)
                                  FROM per_all_people_f papf
                                  WHERE papf.employee_number = hai.employee_number
                                  AND business_group_id= gn_business_group_id),
                                 0,'I',
                                 'U')
    WHERE
     INTERFACE_STATUS != 'TRAITE'
    ;

    gv_step  := lv_current_program_unit||' 005 : Récupération des variables spécifiques';
    log_message(gv_step);

    -- Param SOURCE_CONTACT
    Dka_Tools_Pkg.get_parameter ('DKA_IHREMP', 'SOURCE_CONTACT', rec_param, pv_errbuf, pn_retcode);
    gv_source_contact                  := rec_param.varchar2_value;

    IF pn_retcode != 0
    THEN
        pv_errbuf    := 'Paramètre SOURCE_CONTACT : ' || pv_errbuf;
        RETURN;
    ELSIF gv_source_contact IS NULL
    THEN
        pv_errbuf    := 'Paramètre SOURCE_CONTACT : Aucune donnée trouvée';
        pn_retcode   := 2;
        RETURN;
    END IF;

    -- Param SOURCE_EMPLOYE
    Dka_Tools_Pkg.get_parameter ('DKA_IHREMP', 'SOURCE_EMPLOYE', rec_param, pv_errbuf, pn_retcode);
    gv_source_employe                  := rec_param.varchar2_value;

    IF pn_retcode != 0
    THEN
        pv_errbuf    := 'Paramètre SOURCE_EMPLOYE : ' || pv_errbuf;
        RETURN;
    ELSIF gv_source_employe IS NULL
    THEN
        pv_errbuf    := 'Paramètre SOURCE_EMPLOYE : Aucune donnée trouvée';
        pn_retcode   := 2;
        RETURN;
    END IF;


    --YWA EDB072
    gv_step  := lv_current_program_unit||' 006 : Enrichissement des données bancaires';
    log_message(gv_step);
    UPDATE XXEAI_HR_BANK_INT_ALL hbi
    SET hbi.BANK_ACCOUNT_NUM        = NVL(hbi.BANK_ACCOUNT_NUM,SUBSTR(IBAN_NUMBER,15,11)),
      hbi.BANK_ACCOUNT_CHECK_DIGITS = NVL(hbi.BANK_ACCOUNT_CHECK_DIGITS,SUBSTR(IBAN_NUMBER,26,2)),
      hbi.BANK_BRANCH_COUNTRY       = NVL(hbi.BANK_BRANCH_COUNTRY,SUBSTR(IBAN_NUMBER,0,2)),
      hbi.BANK_ACCOUNT_NAME         = NVL(hbi.BANK_ACCOUNT_NAME,
      (SELECT first_name
        ||' '
        ||last_name
      FROM per_all_people_f
      WHERE employee_number = hbi.employee_number
      AND    business_group_id = gn_business_group_id
      AND SYSDATE BETWEEN effective_start_date AND effective_end_date
      ))
    WHERE (hbi.BANK_ACCOUNT_NUM      IS NULL
    OR hbi.BANK_ACCOUNT_CHECK_DIGITS IS NULL
    OR hbi.BANK_BRANCH_COUNTRY       IS NULL
    OR hbi.BANK_ACCOUNT_NAME         IS NULL)
    AND (hbi.IBAN_NUMBER             IS NOT NULL
    AND hbi.IBAN_NUMBER              != 'NO_IBAN_NUMBER')
    AND hbi.INTERFACE_STATUS         != 'TRAITE';



    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    log_message(pv_errbuf,'Y');
    pn_retcode := 2;
  END init;

  ---SHA EDB402 Début
  -----------------------------------------------------------------
  --  Nom           : get_value_from_set
  --  Description   : Récupération de l'ancien code société en se basant sur le DK code.
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------

  FUNCTION get_value_from_set (
    p_value        IN VARCHAR2
   ) RETURN VARCHAR2 IS
    l_return_value VARCHAR2(100);
BEGIN
    SELECT  FLEX_VALUE
    into l_return_value

    FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv --, DKA_DK_CODES dka
    WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
    AND ffvs.flex_value_set_id = ffv.flex_value_set_id
    AND ffv.attribute14 = p_value;


    RETURN l_return_value;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;

---SHA EDB402 Fin
  -----------------------------------------------------------------
  --  Nom           : purge_table_xxeai
  --  Description   : procedure de purge des tables de travail
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE purge_table_xxeai(pv_errbuf        OUT NOCOPY VARCHAR2,
                              pn_retcode       OUT NOCOPY NUMBER) IS

    lv_current_program_unit  VARCHAR2(30) := 'purge_table_xxeai';

    CURSOR c_purge IS
     SELECT
      employee_number
     FROM
      XXEAI_HR_PEOPLE_INT hpi
     WHERE
      hpi.INTERFACE_STATUS = 'TRAITE'
      AND EXISTS  (SELECT NULL FROM XXEAI_HR_ASSIGNMENT_INT hai WHERE hpi.employee_number = hai.employee_number and hai.INTERFACE_STATUS = 'TRAITE')
      AND (EXISTS (SELECT NULL FROM XXEAI_HR_BANK_INT_ALL hbi WHERE hpi.employee_number = hbi.employee_number and hbi.INTERFACE_STATUS = 'TRAITE')
           OR NOT EXISTS (SELECT NULL FROM XXEAI_HR_BANK_INT_ALL hbi WHERE hpi.employee_number = hbi.employee_number)
      )
      AND SOURCE = gv_source_employe
     ;
  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    gv_step  := lv_current_program_unit||' 001 : Boucle purge ';log_message(gv_step);
    FOR emp in c_purge LOOP

      gv_step  := lv_current_program_unit||' 001 : DELETE XXEAI_HR_PEOPLE_INT - '||gv_source_employe;--log_message(gv_step);
      DELETE FROM XXEAI_HR_PEOPLE_INT WHERE INTERFACE_STATUS = 'TRAITE' and employee_number = emp.employee_number AND SOURCE = gv_source_employe;

      gv_step  := lv_current_program_unit||' 002 : DELETE XXEAI_HR_ASSIGNMENT_INT';--log_message(gv_step);
      DELETE FROM XXEAI_HR_ASSIGNMENT_INT WHERE INTERFACE_STATUS = 'TRAITE' and employee_number = emp.employee_number  ;

      gv_step  := lv_current_program_unit||' 003 : DELETE XXEAI_HR_BANK_INT_ALL';--log_message(gv_step);
      DELETE FROM XXEAI_HR_BANK_INT_ALL WHERE INTERFACE_STATUS = 'TRAITE' and employee_number = emp.employee_number ;

    END LOOP;

    gv_step  := lv_current_program_unit||' 001 : DELETE XXEAI_HR_PEOPLE_INT - SESAME';--log_message(gv_step);
    DELETE FROM XXEAI_HR_PEOPLE_INT WHERE INTERFACE_STATUS = 'TRAITE' AND SOURCE = gv_source_contact;

    --YWA EDB072
    gv_step  := lv_current_program_unit||' 002 : DELETE XXEAI_HR_BANK_INT_ALL - RHAPSODY';--log_message(gv_step);
    DELETE FROM XXEAI_HR_BANK_INT_ALL HBI WHERE HBI.INTERFACE_STATUS = 'TRAITE'  AND  NOT EXISTS
      (SELECT 1
      FROM XXEAI_HR_PEOPLE_INT HPI
      WHERE HPI.EMPLOYEE_NUMBER=HBI.EMPLOYEE_NUMBER
      --AND source = gv_source_employe
      ) ;

    gv_step  := lv_current_program_unit||' 004 : Purge des erreurs précedentes'; log_message(gv_step);
    DELETE FROM XXEAI_HR_INT_ERRORS_ALL;

    gv_step  := lv_current_program_unit||' 005 : Suppression des doublons on conserve le plus récent'; log_message(gv_step);
    DELETE FROM XXEAI_HR_PEOPLE_INT xhpi
     WHERE xxeai_person_id IN (SELECT  xxeai_person_id
                               from  XXEAI_HR_PEOPLE_INT hpi
                               WHERE
                                xhpi.employee_number = hpi.employee_number
                                AND SOURCE = gv_source_employe
                                AND hpi.xxeai_person_id != (SELECT MAX(hpi2.xxeai_person_id)
                                                            FROM  XXEAI_HR_PEOPLE_INT hpi2
                                                            WHERE
                                                             hpi2.employee_number = hpi.employee_number
                                                             AND SOURCE = gv_source_employe)  )
      ;

    DELETE FROM XXEAI_HR_PEOPLE_INT xhpi
     WHERE xxeai_person_id IN (SELECT  xxeai_person_id
                               from  XXEAI_HR_PEOPLE_INT hpi
                               WHERE
                                xhpi.employee_number = hpi.employee_number
                                AND SOURCE = gv_source_contact
                                AND hpi.xxeai_person_id != (SELECT MAX(hpi2.xxeai_person_id)
                                                            FROM  XXEAI_HR_PEOPLE_INT hpi2
                                                            WHERE
                                                             hpi2.employee_number = hpi.employee_number
                                                             AND SOURCE = gv_source_contact)  )
      ;

     DELETE FROM XXEAI_HR_BANK_INT_ALL xhbi
     WHERE xxeai_bank_id IN (SELECT  xxeai_bank_id
                               FROM  XXEAI_HR_BANK_INT_ALL hbi
                               WHERE
                                xhbi.employee_number = hbi.employee_number
                                AND hbi.xxeai_bank_id != (SELECT MAX(hbi2.xxeai_bank_id)
                                                            FROM  XXEAI_HR_BANK_INT_ALL hbi2
                                                            WHERE hbi2.employee_number = hbi.employee_number)  )
      ;

    DELETE FROM XXEAI_HR_ASSIGNMENT_INT xhai
     WHERE xxeai_assignment_id IN (SELECT  xxeai_assignment_id
                               from  XXEAI_HR_ASSIGNMENT_INT hai
                               WHERE
                                xhai.employee_number = hai.employee_number
                                AND hai.xxeai_assignment_id != (SELECT MAX(hai2.xxeai_assignment_id)
                                                            FROM  XXEAI_HR_ASSIGNMENT_INT hai2
                                                            WHERE hai2.employee_number = hai.employee_number)  )
      ;


    gv_step  := lv_current_program_unit||' 006 : RECYCLAGE';log_message(gv_step);
    UPDATE XXEAI_HR_PEOPLE_INT     SET INTERFACE_STATUS = 'RECY' WHERE INTERFACE_STATUS != 'NEW';
    UPDATE XXEAI_HR_ASSIGNMENT_INT SET INTERFACE_STATUS = 'RECY' WHERE INTERFACE_STATUS != 'NEW';
    UPDATE XXEAI_HR_BANK_INT_ALL   SET INTERFACE_STATUS = 'RECY' WHERE INTERFACE_STATUS != 'NEW';

    gv_step  := lv_current_program_unit||' 007 : COMMIT';log_message(gv_step);
    COMMIT;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    log_message(pv_errbuf,'Y');
    pn_retcode := 2;
  END purge_table_xxeai;


  -----------------------------------------------------------------
  --  Nom           : insert_error
  --  Description   : procedure d'insertion dans la table d'erreur
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE insert_error(pv_matricule  XXEAI_HR_INT_ERRORS_ALL.MATRICULE%TYPE,
                         pv_table_name XXEAI_HR_INT_ERRORS_ALL.TABLE_NAME%TYPE,
                         pn_table_id   XXEAI_HR_INT_ERRORS_ALL.TABLE_ID%TYPE,
                         pv_flag_error XXEAI_HR_INT_ERRORS_ALL.FLAG_ERROR%TYPE,
                         pv_message    XXEAI_HR_INT_ERRORS_ALL.ERROR_MESSAGE%TYPE,
                         pv_step       XXEAI_HR_INT_ERRORS_ALL.STEP%TYPE,
                         pv_source     VARCHAR2 DEFAULT gv_source_employe
                         ) IS
   PRAGMA AUTONOMOUS_TRANSACTION;

   lv_current_program_unit  VARCHAR2(30) := 'insert_error';
   lv_step                  VARCHAR2(500);
  BEGIN

    lv_step := pv_step;

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    gv_step  := lv_current_program_unit||' 001 : INSERTION XXEAI_HR_INT_ERRORS_ALL';log_message(gv_step);
    INSERT
     INTO XXEAI_HR_INT_ERRORS_ALL
      ( MATRICULE         ,
        TABLE_NAME        ,
        TABLE_ID          ,
        FLAG_ERROR        ,
        ERROR_MESSAGE     ,
        STEP              ,
        CREATION_DATE     ,
        CREATED_BY        ,
        LAST_UPDATE_DATE  ,
        LAST_UPDATED_BY   ,
        LAST_UPDATE_LOGIN
      )
    VALUES
      ( pv_matricule,
        pv_table_name,
        pn_table_id,
        pv_flag_error,
        substr(pv_message,1,500),
        substr(lv_step,1,500),
        SYSDATE,
        gn_user_id,
        sysdate,
        gn_user_id,
        gn_login_id
       );

    gv_step  := lv_current_program_unit||' 002 : UPDATE '||pv_table_name;log_message(gv_step);
    IF  pv_flag_error = 'E' THEN
      CASE
       WHEN pv_table_name = 'XXEAI_HR_PEOPLE_INT'     THEN
         UPDATE XXEAI_HR_PEOPLE_INT     SET INTERFACE_STATUS = 'ERROR' WHERE XXEAI_PERSON_ID     = pn_table_id AND SOURCE = pv_source;
         IF pv_source = gv_source_employe THEN
           UPDATE XXEAI_HR_ASSIGNMENT_INT SET INTERFACE_STATUS = 'ERROR' WHERE employee_number = (select employee_number from XXEAI_HR_PEOPLE_INT where XXEAI_PERSON_ID  = pn_table_id);
           UPDATE XXEAI_HR_BANK_INT_ALL   SET INTERFACE_STATUS = 'ERROR' WHERE employee_number = (select employee_number from XXEAI_HR_PEOPLE_INT where XXEAI_PERSON_ID  = pn_table_id);
         END IF;
       WHEN pv_table_name = 'XXEAI_HR_ASSIGNMENT_INT' THEN
         UPDATE XXEAI_HR_ASSIGNMENT_INT SET INTERFACE_STATUS = 'ERROR' WHERE XXEAI_ASSIGNMENT_ID = pn_table_id;
         UPDATE XXEAI_HR_PEOPLE_INT     SET INTERFACE_STATUS = 'ERROR' WHERE employee_number = (select employee_number from XXEAI_HR_ASSIGNMENT_INT where XXEAI_ASSIGNMENT_ID  = pn_table_id)  AND SOURCE = pv_source;
         UPDATE XXEAI_HR_BANK_INT_ALL   SET INTERFACE_STATUS = 'ERROR' WHERE employee_number = (select employee_number from XXEAI_HR_ASSIGNMENT_INT where XXEAI_ASSIGNMENT_ID  = pn_table_id);
       WHEN pv_table_name = 'XXEAI_HR_BANK_INT_ALL'   THEN
         UPDATE XXEAI_HR_BANK_INT_ALL   SET INTERFACE_STATUS = 'ERROR' WHERE XXEAI_BANK_ID       = pn_table_id;
         UPDATE XXEAI_HR_PEOPLE_INT     SET INTERFACE_STATUS = 'ERROR' WHERE employee_number = (select employee_number from XXEAI_HR_BANK_INT_ALL where XXEAI_BANK_ID  = pn_table_id)  AND SOURCE = pv_source;
         UPDATE XXEAI_HR_ASSIGNMENT_INT SET INTERFACE_STATUS = 'ERROR' WHERE employee_number = (select employee_number from XXEAI_HR_BANK_INT_ALL where XXEAI_BANK_ID  = pn_table_id);
      END CASE;
    ELSIF  pv_flag_error = 'P' THEN
      CASE
       WHEN pv_table_name = 'XXEAI_HR_PEOPLE_INT'     THEN
         UPDATE XXEAI_HR_PEOPLE_INT     SET INTERFACE_STATUS = 'ERROR' WHERE XXEAI_PERSON_ID     = pn_table_id AND SOURCE = pv_source;
       WHEN pv_table_name = 'XXEAI_HR_ASSIGNMENT_INT' THEN
         UPDATE XXEAI_HR_ASSIGNMENT_INT SET INTERFACE_STATUS = 'ERROR' WHERE XXEAI_ASSIGNMENT_ID = pn_table_id;
       WHEN pv_table_name = 'XXEAI_HR_BANK_INT_ALL'   THEN
         UPDATE XXEAI_HR_BANK_INT_ALL   SET INTERFACE_STATUS = 'ERROR' WHERE XXEAI_BANK_ID       = pn_table_id;
      END CASE;
    END IF;

    gv_step  := lv_current_program_unit||' 003 : COMMIT ';log_message(gv_step);
    COMMIT;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    ROLLBACK;
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
  END insert_error;

  -----------------------------------------------------------------
  --  Nom           : flag_traite
  --  Description   : procedure mise a jour du flag
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE flag_traite(pv_employee_number    XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE,
                        pv_insert_update_flag XXEAI_HR_PEOPLE_INT.INSERT_UPDATE_FLAG%TYPE,
                        pv_table_name         VARCHAR2 DEFAULT 'ALL',
                        pv_source             VARCHAR2 DEFAULT gv_source_employe) IS

   PRAGMA AUTONOMOUS_TRANSACTION;

   lv_current_program_unit  VARCHAR2(30) := 'flag_traite';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    IF pv_table_name IN ('ALL','XXEAI_HR_PEOPLE_INT') THEN
      gv_step  := lv_current_program_unit||' 001 : MISE A JOUR XXEAI_HR_PEOPLE_INT'; log_message(gv_step);
      UPDATE XXEAI_HR_PEOPLE_INT
       SET
        INTERFACE_STATUS  = decode(INTERFACE_STATUS,'ERROR','ERROR','TRAITE'),
        LAST_UPDATE_DATE  = SYSDATE,
        LAST_UPDATED_BY   = gn_user_id,
        LAST_UPDATE_LOGIN = gn_login_id
      WHERE
       EMPLOYEE_NUMBER = pv_employee_number
       AND INSERT_UPDATE_FLAG = pv_insert_update_flag
       AND SOURCE = pv_source
      ;
    END IF;

    IF pv_table_name IN ('ALL','XXEAI_HR_ASSIGNMENT_INT') AND pv_source = gv_source_employe THEN
      gv_step  := lv_current_program_unit||' 002 : MISE A JOUR XXEAI_HR_ASSIGNMENT_INT'; log_message(gv_step);
      UPDATE XXEAI_HR_ASSIGNMENT_INT
       SET
        INTERFACE_STATUS  = decode(INTERFACE_STATUS,'ERROR','ERROR','TRAITE'),
        LAST_UPDATE_DATE  = SYSDATE,
        LAST_UPDATED_BY   = gn_user_id,
        LAST_UPDATE_LOGIN = gn_login_id
      WHERE
       EMPLOYEE_NUMBER = pv_employee_number
       AND INSERT_UPDATE_FLAG = pv_insert_update_flag
      ;
    END IF;

    IF pv_table_name IN ('ALL','XXEAI_HR_BANK_INT_ALL') AND pv_source = gv_source_employe THEN
      gv_step  := lv_current_program_unit||' 003 : MISE A JOUR XXEAI_HR_BANK_INT_ALL'; log_message(gv_step);
      UPDATE XXEAI_HR_BANK_INT_ALL
       SET
        INTERFACE_STATUS  = decode(INTERFACE_STATUS,'ERROR','ERROR','TRAITE'),
        LAST_UPDATE_DATE  = SYSDATE,
        LAST_UPDATED_BY   = gn_user_id,
        LAST_UPDATE_LOGIN = gn_login_id
      WHERE
       EMPLOYEE_NUMBER = pv_employee_number
       AND INSERT_UPDATE_FLAG = pv_insert_update_flag
      ;
    END IF;

    gv_step  := lv_current_program_unit||' 004 : COMMIT ';log_message(gv_step);
    COMMIT;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END flag_traite;

  -----------------------------------------------------------------
  --  Nom           : get_person_id
  --  Description   : fonction qui retourne l'identifiant de l'employé
  --
  --  PARAMETRES :
  --   pv_employee_number       IN XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE
  --
  --  VALEURS RETOURNEES :
  --   identifiant de l'employé
  -----------------------------------------------------------------
  FUNCTION get_person_id(pv_employee_number XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE) RETURN NUMBER IS

    lv_current_program_unit  VARCHAR2(30) := 'get_person_id';
    ln_person_id             PER_ALL_PEOPLE_F.PERSON_ID%TYPE;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT person_id
    INTO   ln_person_id
    FROM   per_all_people_f papf
    WHERE  employee_number = pv_employee_number
    AND    papf.business_group_id = gn_business_group_id
    AND    SYSDATE BETWEEN papf.effective_start_date and effective_end_date;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

    return ln_person_id;

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas le matricule
    return NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur fonction '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_person_id;

  -----------------------------------------------------------------
  --  Nom           : get_person_info
  --  Description   : procedure qui retourne l'identifiant de l'employé et
  --                  la version
  --
  --  PARAMETRES :
  --   pv_employee_number       IN XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE
  --
  --  VALEURS RETOURNEES :
  --   identifiant de l'employé et la version
  -----------------------------------------------------------------
  PROCEDURE get_person_info(pv_employee_number IN     XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE,
                            pn_person_id          OUT per_all_people_f.person_id%TYPE,
                            pn_object_version     OUT per_all_people_f.object_version_number%TYPE,
                            pr_person_row         OUT per_all_people_f%ROWTYPE) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_person_info';

    CURSOR c_select IS
     SELECT papf.*
     FROM   per_all_people_f papf
     WHERE  employee_number = pv_employee_number
     AND    papf.business_group_id = gn_business_group_id
     AND    SYSDATE BETWEEN papf.effective_start_date and effective_end_date
      ;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    OPEN c_select;
    FETCH c_select INTO pr_person_row;

    IF c_select%FOUND THEN
      pn_person_id := pr_person_row.person_id;
      pn_object_version := pr_person_row.object_version_number;
    ELSE
      --On ne trouve pas le matricule
      pn_person_id      := NULL;
      pn_object_version := NULL;
    END IF;

    CLOSE c_select;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_person_info;

  -----------------------------------------------------------------
  --  Nom           : get_assign_info
  --  Description   : procedure qui retourne les informations d'affectation
  --                  de l'employé
  --
  --  PARAMETRES :
  --   pv_employee_number       IN XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE
  --
  --  VALEURS RETOURNEES :
  --   la tache du projet organique et la version
  -----------------------------------------------------------------
  PROCEDURE get_assign_info(pv_employee_number IN     XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE,
                            pn_assignment_id      OUT per_all_assignments_f.assignment_id%TYPE,
                            pn_object_version     OUT per_all_assignments_f.object_version_number%TYPE,
                            pd_start_date         OUT per_all_assignments_f.effective_start_date%TYPE,
                            pd_end_date           OUT per_all_assignments_f.effective_end_date%TYPE,
                            pn_job_id             OUT per_all_assignments_f.job_id%TYPE,
                            pv_job_name           OUT per_jobs.name%TYPE,
                            pv_fct                OUT per_jobs.name%TYPE,
                            pn_organization_id    OUT hr_all_organization_units.organization_id%TYPE,
                            pv_organization_name  OUT hr_all_organization_units.name%TYPE,
                            pn_supervisor_id      OUT per_all_assignments_f.supervisor_id%TYPE,
                            pv_ass_attribute1     OUT per_all_assignments_f.ass_attribute1%TYPE,
                            pv_ass_attribute2     OUT per_all_assignments_f.ass_attribute2%TYPE,
                            pv_ass_attribute3     OUT per_all_assignments_f.ass_attribute3%TYPE,
                            pv_ass_attribute4     OUT per_all_assignments_f.ass_attribute4%TYPE,
                            pv_ass_attribute5     OUT per_all_assignments_f.ass_attribute5%TYPE,
                            pd_effective_start_date_date IN per_all_assignments_f.effective_start_date%TYPE DEFAULT NULL -- OBE artf2391673
                            ) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_assign_info';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    gv_step  := lv_current_program_unit||' 001 : Recherche de l''affectation au :'||to_char(pd_effective_start_date_date,'dd/mm/yyyy');
    log_message(gv_step);

    SELECT
     paaf.assignment_id,
     paaf.object_version_number,
     paaf.effective_start_date,
     paaf.effective_end_date,
     paaf.job_id,
     pj.name,
     substr(pj.name,instr(pj.name,'.')+1),
     paaf.organization_id,
     haou.name,
     paaf.supervisor_id,
     paaf.ass_attribute1,
     paaf.ass_attribute2,
     paaf.ass_attribute3, -- OBE artf2391673
     paaf.ass_attribute4,
     paaf.ass_attribute5
    INTO
     pn_assignment_id,
     pn_object_version,
     pd_start_date,
     pd_end_date,
     pn_job_id,
     pv_job_name,
     pv_fct,
     pn_organization_id,
     pv_organization_name,
     pn_supervisor_id,
     pv_ass_attribute1,
     pv_ass_attribute2,
     pv_ass_attribute3, -- OBE artf2391673
     pv_ass_attribute4,
     pv_ass_attribute5
    FROM   per_all_people_f papf,
           per_person_types ppt,
           per_all_assignments_f paaf,
           per_jobs pj,
           hr_all_organization_units haou
    WHERE  employee_number = pv_employee_number
    AND    papf.business_group_id = gn_business_group_id
    AND    SYSDATE BETWEEN papf.effective_start_date and papf.effective_end_date
    AND    ppt.person_type_id = papf.person_type_id
    and    paaf.person_id = papf.person_id
    and    SYSDATE BETWEEN paaf.effective_start_date and paaf.effective_end_date
    --- 23/07/2018 NBO artf2646661 : TASK0056324  l'interface Employés, en cas d'erreur bloquante sur les changements d'organisations
    AND NVL(pd_effective_start_date_date,SYSDATE) between paaf.effective_start_date and paaf.effective_end_date -- OBE artf2391673
    --- 04/06/2019 NBO artf07257953 : INC0319624 - Problème interface employé
    /*AND    paaf.object_version_number = (select max(paaf2.object_version_number)
      from per_all_assignments_f paaf2 where paaf2.person_id =  papf.person_id)*/
    AND (paaf.assignment_id, paaf.object_version_number) IN (select assignment_id, object_version_number
     from ( select assignment_id, object_version_number from per_all_assignments_f where person_id = papf.person_id order by assignment_id desc, object_version_number desc) v
     where rownum = 1)
    --- Fin 04/06/2019 NBO artf07257953
    AND    paaf.business_group_id = gn_business_group_id
    and    paaf.job_id = pj.job_id
    and    pj.business_group_id = gn_business_group_id
    and    paaf.organization_id = haou.organization_id
    ;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
     BEGIN
        gv_step  := lv_current_program_unit||' 002 : Recherche de l''affectation à la date du jour';
        log_message(gv_step);

        SELECT
         paaf.assignment_id,
         paaf.object_version_number,
         paaf.effective_start_date,
         paaf.effective_end_date,
         paaf.job_id,
         pj.name,
         substr(pj.name,instr(pj.name,'.')+1),
         paaf.organization_id,
         haou.name,
         paaf.supervisor_id,
         paaf.ass_attribute1,
         paaf.ass_attribute2,
         paaf.ass_attribute3, -- OBE artf2391673
         paaf.ass_attribute4,
         paaf.ass_attribute5
        INTO
         pn_assignment_id,
         pn_object_version,
         pd_start_date,
         pd_end_date,
         pn_job_id,
         pv_job_name,
         pv_fct,
         pn_organization_id,
         pv_organization_name,
         pn_supervisor_id,
         pv_ass_attribute1,
         pv_ass_attribute2,
         pv_ass_attribute3, -- OBE artf2391673
         pv_ass_attribute4,
         pv_ass_attribute5
        FROM   per_all_people_f papf,
               per_person_types ppt,
               per_all_assignments_f paaf,
               per_jobs pj,
               hr_all_organization_units haou
        WHERE  employee_number = pv_employee_number
        AND    papf.business_group_id = gn_business_group_id
        AND    SYSDATE BETWEEN papf.effective_start_date and papf.effective_end_date
        AND    ppt.person_type_id = papf.person_type_id
        AND    paaf.person_id = papf.person_id
        AND    paaf.effective_start_date = (SELECT MAX(paaf2.effective_start_date)
                                            FROM per_all_assignments_f paaf2
                                            WHERE paaf2.person_id = papf.person_id)
        AND    paaf.business_group_id = gn_business_group_id
        AND    paaf.job_id = pj.job_id
        AND    pj.business_group_id = gn_business_group_id
        AND    paaf.organization_id = haou.organization_id
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --On ne trouve pas l'affectation
        pv_ass_attribute5 := NULL;
        pn_object_version := NULL;
      WHEN OTHERS THEN
        gv_step  := lv_current_program_unit||' EE2 : ERREUR lors de :'||gv_step;
        log_message(gv_step,'Y');
        log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
        RAISE;
    END;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_assign_info;

  -----------------------------------------------------------------
  --  Nom           : get_supplier_info
  --  Description   : procedure qui retourne l'identifiant du fournisseur et
  --                  son party_id
  --
  --  PARAMETRES :
  --   pv_EMPLOYEE_ID       IN XXEAI_HR_PEOPLE_INT.EMPLOYEE_ID%TYPE
  --
  --  VALEURS RETOURNEES :
  --   identifiant du fournisseur et le party_id
  -----------------------------------------------------------------
  PROCEDURE get_supplier_info(pn_employee_id     IN     ap_suppliers.EMPLOYEE_ID%TYPE,
                              pn_vendor_id          OUT ap_suppliers.VENDOR_ID%TYPE,
                              pn_party_id           OUT ap_suppliers.PARTY_ID%TYPE) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_supplier_info';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT VENDOR_ID,PARTY_ID
    INTO pn_vendor_id,pn_party_id
    FROM ap_suppliers
    WHERE EMPLOYEE_ID = pn_employee_id ;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas le fournisseur
    pn_vendor_id      := NULL;
    pn_party_id       := NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_supplier_info;

  -----------------------------------------------------------------
  --  Nom           : get_supplier_site_info
  --  Description   : procedure qui retourne l'identifiant du site fournisseur et
  --                  ses party_id
  --
  --  PARAMETRES :
  --   pv_EMPLOYEE_ID       IN XXEAI_HR_PEOPLE_INT.EMPLOYEE_ID%TYPE
  --
  --  VALEURS RETOURNEES :
  --   identifiant du fournisseur et le party_id
  -----------------------------------------------------------------
  PROCEDURE get_supplier_site_info( pn_employee_id     IN     ap_suppliers.EMPLOYEE_ID%TYPE,
                                    pn_org_id          IN     hr_all_organization_units.organization_id%TYPE,
                                    pn_vendor_id          OUT ap_suppliers.VENDOR_ID%TYPE,
                                    pn_party_id           OUT ap_suppliers.PARTY_ID%TYPE,
                                    pn_vendor_site_id     OUT ap_supplier_sites_all.VENDOR_SITE_ID%TYPE,
                                    pn_party_site_id      OUT ap_supplier_sites_all.PARTY_SITE_ID%TYPE
                                    ) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_supplier_site_info';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT aps.VENDOR_ID,aps.PARTY_ID,apssa.vendor_site_id,apssa.party_site_id
    INTO pn_vendor_id,pn_party_id,pn_vendor_site_id,pn_party_site_id
    FROM
     ap_suppliers aps,
     ap_supplier_sites_all apssa
    WHERE EMPLOYEE_ID = pn_employee_id
    and aps.vendor_id = apssa.vendor_id
    and apssa.vendor_site_code = gv_vendor_site_code
    and apssa.org_id =  pn_org_id;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas le fournisseur
    pn_vendor_id      := NULL;
    pn_party_id       := NULL;
    pn_vendor_site_id := NULL;
    pn_party_site_id  := NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_supplier_site_info;

  -----------------------------------------------------------------
  --  Nom           : get_currency_code
  --  Description   : fonction qui retourne la devise de l'entité comptable
  --
  --  PARAMETRES :
  --   pv_societe   IN   VARCHAR2
  --
  --  VALEURS RETOURNEES :
  --   identifiant de l'employé
  -----------------------------------------------------------------
  FUNCTION get_currency_code (pn_ledger_id   IN   NUMBER) RETURN VARCHAR2 IS

    lv_current_program_unit  VARCHAR2(30) := 'get_currency_code';
    lv_currency_code          ap_suppliers.invoice_currency_code%TYPE;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT gl.currency_code
    INTO   lv_currency_code
    FROM   gl_ledgers gl
    WHERE  ledger_id = pn_ledger_id;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

    RETURN lv_currency_code;

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas l'entité
    return NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur fonction '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_currency_code;

  -----------------------------------------------------------------
  --  Nom           : get_job_id
  --  Description   : fonction qui retourne l'identifiant du job
  --
  --  PARAMETRES :
  --   pv_employee_number       IN XXEAI_HR_PEOPLE_INT.EMPLOYEE_NUMBER%TYPE
  --
  --  VALEURS RETOURNEES :
  --   identifiant de l'employé
  -----------------------------------------------------------------
  FUNCTION get_job_id (pv_region VARCHAR2,
                       pv_poste  VARCHAR2) RETURN NUMBER IS

    lv_current_program_unit  VARCHAR2(30) := 'get_job_id';
    ln_job_id                NUMBER;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    BEGIN
        SELECT pj.job_id
        INTO   ln_job_id
        FROM   per_jobs pj
        WHERE  pj.name = (pv_region || '.' || pv_poste)
        AND    pj.business_group_id = gn_business_group_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT pj.job_id
          INTO   ln_job_id
          FROM   per_jobs pj
          WHERE  pj.name = (pv_region || '.' || gv_default_job)
          AND    pj.business_group_id = gn_business_group_id;
    END;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

    RETURN ln_job_id;

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas le job
    return NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur fonction '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_job_id;

  -----------------------------------------------------------------
  --  Nom           : get_bank_info
  --  Description   : procédure qui retourne l'identifiant de la banque et de l'agence
  --
  --  PARAMETRES :
  --  pv_bank_number    IN VARCHAR2
  --  pv_branch_number  IN VARCHAR2
  --
  --  VALEURS RETOURNEES :
  --   identifiant banque et agence
  -----------------------------------------------------------------
  PROCEDURE get_bank_info ( pv_bank_number    IN VARCHAR2,
                            pv_branch_number  IN VARCHAR2,
                            pn_bank_id        OUT VARCHAR2,
                            pn_branch_id      OUT VARCHAR2
                            ) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_bank_info';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT bank_party_id, branch_party_id
    INTO pn_bank_id, pn_branch_id
    FROM CE_BANK_BRANCHES_V
    WHERE
     bank_number = pv_bank_number
     AND branch_number = pv_branch_number
     AND SYSDATE BETWEEN NVL(start_date,SYSDATE)
                     AND NVL(end_date,SYSDATE)
     AND rownum = 1 --on ne sélectionne qu'une banque/agence valide
     ;


    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas la banque
    gv_step  := lv_current_program_unit||' : On ne trouve pas la banque';
    pn_bank_id   := NULL;
    pn_branch_id := NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_bank_info;

  -----------------------------------------------------------------
  --  Nom           : get_info_compte_bank
  --  Description   : procédure qui retourne l'identifiant du compte bancaire s'il existe
  --
  --  PARAMETRES :
  --   pn_bank_id       NUMBER
  --   pn_branch_id     NUMBER
  --   pv_iban          VARCHAR2
  --   pv_country       VARCHAR2
  --   pv_type          VARCHAR2
  --
  --  VALEURS RETOURNEES :
  --   identifiant du compte bancaire
  -----------------------------------------------------------------
  PROCEDURE get_info_compte_bank(pn_bank_id       IN  NUMBER,
                                 pn_branch_id     IN  NUMBER,
                                 pv_iban          IN  VARCHAR2,
                                 pv_country       IN  VARCHAR2,
                                 pv_type          IN  VARCHAR2,
                                 pn_bank_acct_id  OUT NUMBER) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_info_compte_bank';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT EXT_BANK_ACCOUNT_ID
    INTO pn_bank_acct_id
    FROM IBY_EXT_BANK_ACCOUNTS
    WHERE
        iban               = pv_iban
    AND bank_id            = pn_bank_id
    AND branch_id          = pn_branch_id
    AND country_code       = pv_country
    AND nvl(bank_account_type,pv_type)  = nvl(pv_type,'#');

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas le compte
    pn_bank_acct_id   := NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_info_compte_bank;

  -----------------------------------------------------------------
  --  Nom           : get_info_acct_emp
  --  Description   : procédure qui retourne l'identifiant du compte bancaire s'il existe
  --                  sur le fournisseur/site fournisseur
  --
  --  PARAMETRES :
  --   pn_bank_id       NUMBER
  --   pn_branch_id     NUMBER
  --   pv_iban          VARCHAR2
  --   pv_country       VARCHAR2
  --   pv_type          VARCHAR2
  --
  --  VALEURS RETOURNEES :
  --   identifiant du compte bancaire
  -----------------------------------------------------------------
  PROCEDURE get_info_acct_emp (pn_frs_party_id         IN     NUMBER,
                               pn_vendor_site_id       IN     NUMBER,
                               pn_site_party_id       IN     NUMBER, --YWA EDB072
                               pn_ext_bank_account_id     OUT NUMBER,
                               pd_start_date              OUT DATE,
                               pn_object_version_number   OUT NUMBER) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_info_acct_emp';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT accts.ext_bank_account_id,accts.start_date,accts.OBJECT_VERSION_NUMBER
    INTO
     pn_ext_bank_account_id,pd_start_date,pn_object_version_number
    FROM iby_pmt_instr_uses_all   uses,
         iby_external_payees_all  payee,
         iby_ext_bank_accounts    accts
   WHERE uses.instrument_type = 'BANKACCOUNT'
     AND payee.ext_payee_id = uses.ext_pmt_party_id
     AND payee.payee_party_id = pn_frs_party_id
     AND payee.payment_function = 'PAYABLES_DISB'
     AND payee.supplier_site_id = pn_vendor_site_id
     AND uses.instrument_id = accts.ext_bank_account_id
     AND uses.ORDER_OF_PREFERENCE = 1
     AND (payee.party_site_id = nvl(pn_site_party_id,payee.party_site_id)  OR payee.party_site_id IS NULL);--YWA EDB072

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas le compte
    pn_ext_bank_account_id   := NULL;
    pd_start_date            := NULL;
    pn_object_version_number := NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_info_acct_emp;

  -----------------------------------------------------------------
  --  Nom           : get_cpt_bank_emp
  --  Description   : procédure qui retourne l'identifiant du compte bancaire s'il existe
  --                  pour un employé
  --  PARAMETRES :
  --   pn_employee_id          NUMBER
  --   pn_ext_bank_account_id  NUMBER
  --
  --  VALEURS RETOURNEES :
  --   identifiant du compte bancaire
  -----------------------------------------------------------------
  PROCEDURE get_cpt_bank_emp (pn_employee_id             IN     NUMBER,
                              pn_ext_bank_account_id     OUT NUMBER) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_cpt_bank_emp';

    vn_cptid NUMBER;

    CURSOR c_select_cpt IS
      SELECT accts.ext_bank_account_id
        FROM iby_pmt_instr_uses_all   uses,
             iby_external_payees_all  payee,
             iby_ext_bank_accounts    accts,
             ap_suppliers             aps,
             ap_supplier_sites_all    apsa
       WHERE uses.instrument_type = 'BANKACCOUNT'
         AND payee.ext_payee_id = uses.ext_pmt_party_id
         AND payee.payee_party_id = aps.PARTY_ID
         AND payee.payment_function = 'PAYABLES_DISB'
         AND payee.supplier_site_id = apsa.VENDOR_SITE_ID
         AND uses.instrument_id = accts.ext_bank_account_id
         AND aps.vendor_id = apsa.vendor_id
         AND aps.EMPLOYEE_ID = pn_employee_id
         AND uses.ORDER_OF_PREFERENCE = 1
        ORDER BY apsa.creation_date DESC
        ;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);


    gv_step  := lv_current_program_unit||' 001 : Sélection';log_message(gv_step);
    OPEN  c_select_cpt;
    FETCH c_select_cpt INTO vn_cptid;

    IF c_select_cpt%FOUND THEN
      gv_step  := lv_current_program_unit||' 002 : Compte trouvé : '||vn_cptid;log_message(gv_step);
      pn_ext_bank_account_id := vn_cptid;
    ELSE
      gv_step  := lv_current_program_unit||' 003 : Compte non trouvé';log_message(gv_step);
      pn_ext_bank_account_id := NULL;
    END IF;

    CLOSE c_select_cpt;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_cpt_bank_emp;

  -----------------------------------------------------------------
  --  Nom           : get_period_gl
  --  Description   : procédure qui retourne la dernier periode GL
  --                  ouverte pour le livre avec les dates de début et fin
  --
  --  PARAMETRES :
  --   pn_bank_id       NUMBER
  --   pn_branch_id     NUMBER
  --   pv_iban          VARCHAR2
  --   pv_country       VARCHAR2
  --   pv_type          VARCHAR2
  --
  --  VALEURS RETOURNEES :
  --
  -----------------------------------------------------------------
  PROCEDURE get_period_gl (pn_set_of_books_id         IN     NUMBER,
                           pv_period_name                OUT VARCHAR2,
                           pd_start_date                 OUT DATE,
                           pd_end_date                   OUT DATE) IS

    lv_current_program_unit  VARCHAR2(30) := 'get_period_gl';

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT period_name, start_date,end_date
    INTO   pv_period_name, pd_start_date, pd_end_date
    FROM
    (SELECT period_name, start_date,end_date,
        RANK() OVER(PARTITION BY set_of_books_id, application_id
                    ORDER BY start_date DESC) seq
      FROM gl_period_statuses
      WHERE
       application_id = 101 --GL
       AND set_of_books_id = pn_set_of_books_id
       AND closing_status IN ('O')
       AND adjustment_period_flag = 'N' ) v
    WHERE seq = 1;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas la periode GL
    pv_period_name   := NULL;
    pd_start_date    := NULL;
    pd_end_date      := NULL;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur fonction '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END get_period_gl;

  -----------------------------------------------------------------
  --  Nom           : is_EX_employee
  --  Description   : fonction qui le type de l'employé est actif ou non
  --
  --  PARAMETRES :
  --   pv_person_type       IN per_person_types.person_type_id%TYPE
  --
  --  VALEURS RETOURNEES :
  --   VRAI ou FAUX
  -----------------------------------------------------------------
  FUNCTION is_EX_employee (pv_person_type per_person_types.person_type_id%TYPE) return boolean is
    lv_current_program_unit  VARCHAR2(30) := 'is_EX_employee';
    lv_person_type_id        per_person_types.person_type_id%TYPE;
  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    SELECT person_type_id
    INTO  lv_person_type_id
    FROM per_person_types
    WHERE system_person_type  IN ('EX_APL','EX_EMP','EX_EMP_APL')
    AND business_group_id = 0
    AND active_flag = 'Y'
    AND person_type_id = pv_person_type;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

    RETURN TRUE;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
    --On ne trouve pas le type
    return FALSE;
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur fonction '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END is_EX_employee;

  -----------------------------------------------------------------
  --  Nom           : terminate_employee
  --  Description   : procédure qui fait sortir un employé
  --
  --  PARAMETRES :
  --
  --
  --  VALEURS RETOURNEES :
  --
  -----------------------------------------------------------------
  PROCEDURE terminate_employee(pn_person_id             IN     per_all_people_f.person_id%TYPE,
                               pd_effective_start_date  IN     DATE,
                               pd_termination_date      IN     DATE) IS

    lv_current_program_unit  VARCHAR2(30) := 'terminate_employee';

    ld_per_eff_start                 DATE;
    ln_period_of_service_id          NUMBER;
    ln_service_ovn                   NUMBER;
    ld_last_std_process_dt           DATE;
    lb_supervisor_warning            BOOLEAN;
    lb_event_warning                 BOOLEAN;
    lb_interview_warning             BOOLEAN;
    lb_review_warning                BOOLEAN;
    lb_recruiter_warning             BOOLEAN;
    lb_asgfuture_changes_warning     BOOLEAN;
    lv_entries_changed_warning       VARCHAR2(100);
    lb_pay_proposal_warning          BOOLEAN;
    lb_dod_warning                   BOOLEAN;
    ld_termination_date              DATE;
    l_user_name                      VARCHAR2(100);
    ld_emp_eff_date                  DATE;
    l_org_now_no_manager_warning     BOOLEAN;
    l_f_asg_future_changes_warning   BOOLEAN;
    l_f_entries_changed_warning      VARCHAR2(255);

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    --Sélection des identifiants périod de service
    gv_step  := lv_current_program_unit||' 001 : Sélection des identifiants périod de service';log_message(gv_step);
    -- NBO 27/09/19 - INC0327452 -  plusieurs ressources ont été rejetées dans l'interface avec l'erreur "erreur de désactivation".
    /*SELECT MAX(period_of_service_id) ,
           MAX(object_version_number)
    INTO ln_period_of_service_id,
         ln_service_ovn
    FROM per_periods_of_service
    WHERE person_id = pn_person_id;*/

    SELECT DISTINCT period_of_service_id, object_version_number
  INTO ln_period_of_service_id, ln_service_ovn
  FROM (SELECT first_value(period_of_service_id) over(ORDER BY period_of_service_id DESC, object_version_number DESC) period_of_service_id,
               first_value(object_version_number) over(ORDER BY period_of_service_id DESC, object_version_number DESC) object_version_number
          FROM per_periods_of_service
         WHERE person_id = pn_person_id) v;

    log_message(ln_period_of_service_id ||':' || ln_service_ovn);

    --Détermination de la fin en fonction du dernier évenement
    gv_step  := lv_current_program_unit||' 002 : Détermination de la fin en fonction du dernier évenement '||
                                         'eff_start_date : '||to_char(pd_effective_start_date,'dd/mm/yyyy')||
                                         ' / Term_date '||to_char(pd_termination_date,'dd/mm/yyyy');log_message(gv_step);
    IF pd_termination_date <= pd_effective_start_date THEN
     ld_termination_date := pd_effective_start_date;
    ELSE
     ld_termination_date := pd_termination_date;
    END IF;

    gv_step  := lv_current_program_unit||' 003 : La date de fin est a la fin mois suivant si différent de 31/12/4712';log_message(gv_step);
    IF ld_termination_date != TO_DATE ('31/12/4712', 'DD/MM/YYYY') THEN
     ld_termination_date := ADD_MONTHS (LAST_DAY (ld_termination_date), 1);
    END IF;

    IF ln_period_of_service_id IS NOT NULL THEN
      gv_step  := lv_current_program_unit||' 004 : HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP';log_message(gv_step);
      hr_ex_employee_api.actual_termination_emp
        ( -- Input data elements
          -- -----------------------------
         p_validate                   => FALSE
        ,p_effective_date             => ld_termination_date
        ,p_period_of_service_id       => ln_period_of_service_id
        ,p_object_version_number      => ln_service_ovn
        ,p_actual_termination_date    => ld_termination_date
        ,p_last_standard_process_date => ld_last_std_process_dt
          -- Output data elements
          -- -----------------------------
        ,p_supervisor_warning => lb_supervisor_warning
        ,p_event_warning => lb_event_warning
        ,p_interview_warning => lb_interview_warning
        ,p_review_warning => lb_review_warning
        ,p_recruiter_warning => lb_recruiter_warning
        ,p_asg_future_changes_warning => lb_asgfuture_changes_warning
        ,p_entries_changed_warning => lv_entries_changed_warning
        ,p_pay_proposal_warning => lb_pay_proposal_warning
        ,p_dod_warning => lb_dod_warning);

      gv_step  := lv_current_program_unit||' 005 : HR_EX_EMPLOYEE_API.UPDATE_TERM_DETAILS_EMP';log_message(gv_step);
      hr_ex_employee_api.update_term_details_emp
        (p_validate => FALSE
        ,p_effective_date => ld_termination_date
        ,p_period_of_service_id => ln_period_of_service_id
        ,p_object_version_number => ln_service_ovn
        ,p_accepted_termination_date => ld_termination_date
        ,p_leaving_reason => NULL
        ,p_notified_termination_date => ld_termination_date
        ,p_projected_termination_date => ld_termination_date
        );


      gv_step  := lv_current_program_unit||' 006 : HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP';log_message(gv_step);
      hr_ex_employee_api.final_process_emp
        (p_validate => FALSE
        ,p_period_of_service_id => ln_period_of_service_id
        ,p_object_version_number => ln_service_ovn
        ,p_final_process_date => ld_termination_date
        ,p_org_now_no_manager_warning => l_org_now_no_manager_warning
        ,p_asg_future_changes_warning => l_f_asg_future_changes_warning
        ,p_entries_changed_warning => l_f_entries_changed_warning
        );

    END IF;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur fonction '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END terminate_employee;

  -----------------------------------------------------------------
  --  Nom           : reverse_termination
  --  Description   : procédure qui annule la sortie d'un employé envoyée par
  --                  erreur par Cador (flux correctif avec date de fin vide).
  --                  Contrairement a reactivate_employee (re_hire_ex_employee)
  --                  qui cree une NOUVELLE periode de service, l'API
  --                  reverse_terminate_employee restaure la periode de service
  --                  initiale et efface la date de fin : pas de rupture
  --                  d'anciennete, pas de doublon de contrat.
  --
  --  PARAMETRES :
  --   pn_person_id  IN per_all_people_f.person_id%TYPE
  --
  --  VALEURS RETOURNEES :
  --
  -----------------------------------------------------------------
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

  -----------------------------------------------------------------
  --  Nom           : reactivate_employee
  --  Description   : procédure qui réactive un employé
  --
  --  PARAMETRES :
  --
  --
  --  VALEURS RETOURNEES :
  --
  -----------------------------------------------------------------
  PROCEDURE reactivate_employee(pn_person_id             IN     NUMBER,
                                pd_rehire_date           IN     DATE,
                                pn_object_version_number IN     NUMBER,
                                pv_rehire_reason         IN     VARCHAR2) IS

    lv_current_program_unit  VARCHAR2(30) := 'reactivate_employee';

    ln_per_object_version_number   per_all_people_f.object_version_number%TYPE;
    ln_assg_object_version_number  per_all_assignments_f.object_version_number%TYPE;
    ln_assignment_id               per_all_assignments_f.assignment_id%TYPE;
    ld_per_effective_start_date    per_all_people_f.effective_start_date%TYPE;
    ld_per_effective_end_date      per_all_people_f.effective_end_date%TYPE;
    ln_assignment_sequence         per_all_assignments_f.assignment_sequence%TYPE;
    lb_assign_payroll_warning      BOOLEAN;
    lc_assignment_number           per_all_assignments_f.assignment_number%TYPE;

    lr_assignment                  per_all_assignments_f%ROWTYPE;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    ln_per_object_version_number := pn_object_version_number;

    gv_step  := lv_current_program_unit||' 001 : Lancement de hr_employee_api.re_hire_ex_employee';
    log_message(gv_step);


    hr_employee_api.re_hire_ex_employee
     (    -- Input data elements
          -- -----------------------------
        p_hire_date                      => pd_rehire_date,
        p_person_id                      => pn_person_id,
        p_rehire_reason                  => pv_rehire_reason,
         -- Output data elements
         -- --------------------------------
        p_assignment_id                   => ln_assignment_id,
        p_per_object_version_number       => ln_per_object_version_number,
        p_asg_object_version_number       => ln_assg_object_version_number,
        p_per_effective_start_date        => ld_per_effective_start_date,
        p_per_effective_end_date          => ld_per_effective_end_date,
        p_assignment_sequence             => ln_assignment_sequence,
        p_assignment_number               => lc_assignment_number,
        p_assign_payroll_warning          => lb_assign_payroll_warning
    );

    --Correction de l'affectation de l'employé avec l'affectation précédente:
    gv_step  := lv_current_program_unit||' 002 : Sélection avant dernière affectation';
    log_message(gv_step);
    SELECT *
    INTO lr_assignment
    FROM
     (SELECT *
      FROM per_all_assignments_f
      WHERE
       person_id = pn_person_id
       AND EFFECTIVE_END_DATE != to_date('31/12/4712','dd/mm/yyyy')
      ORDER BY EFFECTIVE_END_DATE DESC)
    WHERE ROWNUM = 1;

    gv_step  := lv_current_program_unit||' 003 : Correction de la dernière ligne d''affectation';
    log_message(gv_step);
    UPDATE per_all_assignments_f
    SET
     job_id            = lr_assignment.job_id,
     supervisor_id     = lr_assignment.supervisor_id,
     organization_id   = lr_assignment.organization_id,
     people_group_id   = lr_assignment.people_group_id,
     assignment_number = lr_assignment.assignment_number,
     change_reason     = substr(pv_rehire_reason,1,30),
     set_of_books_id   = lr_assignment.set_of_books_id,
     ass_attribute1    = lr_assignment.ass_attribute1,
     ass_attribute2    = lr_assignment.ass_attribute2,
     ass_attribute3    = lr_assignment.ass_attribute3,
     ass_attribute4    = lr_assignment.ass_attribute4,
     ass_attribute5    = lr_assignment.ass_attribute5
    WHERE
         person_id = pn_person_id
     AND EFFECTIVE_END_DATE = to_date('31/12/4712','dd/mm/yyyy');

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    log_message('Erreur fonction '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM,'Y');
    RAISE;
  END reactivate_employee;

  -----------------------------------------------------------------
  --  Nom           : CREATION_EMPLOYE
  --  Description   : procedure de creation des employes
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE creation_employe(pv_errbuf        OUT NOCOPY VARCHAR2,
                             pn_retcode       OUT NOCOPY NUMBER) IS

    lv_current_program_unit  VARCHAR2(30) := 'creation_employe';

    /*CURSOR C_EMPLOYE IS
      SELECT hpi.employee_number
        FROM xxeai_hr_people_int     hpi,
             xxeai_hr_assignment_int hai
       WHERE hpi.insert_update_flag = 'I'
         AND hai.employee_number = hpi.employee_number
         AND hpi.interface_status != 'ERROR'
         AND SOURCE = gv_source_employe
       START WITH orig_system_supervisor_ref IS NULL
      CONNECT BY orig_system_supervisor_ref = PRIOR hai.employee_number
      UNION ALL (SELECT hpi.employee_number
                   FROM xxeai_hr_people_int hpi
                  WHERE hpi.insert_update_flag = 'I'
                    AND hpi.interface_status != 'ERROR'
                    AND SOURCE = gv_source_employe
                 MINUS
                 SELECT hpi.employee_number
                   FROM xxeai_hr_people_int     hpi,
                        xxeai_hr_assignment_int hai
                  WHERE hpi.insert_update_flag = 'I'
                    AND hai.employee_number = hpi.employee_number
                    AND hpi.interface_status != 'ERROR'
                    AND SOURCE = gv_source_employe
                  START WITH orig_system_supervisor_ref IS NULL
                 CONNECT BY orig_system_supervisor_ref = PRIOR hai.employee_number); */

    --artf2200909
    CURSOR C_EMPLOYE IS
     WITH arbre AS ( SELECT employee_number,
                        NULL AS orig_system_supervisor_ref
                   FROM xxeai_hr_assignment_int hai1
                  WHERE NOT EXISTS (SELECT 1
                           FROM xxeai_hr_assignment_int hai2
                          WHERE hai1.orig_system_supervisor_ref = hai2.employee_number)
                 UNION
                 SELECT employee_number,
                        orig_system_supervisor_ref
                   FROM xxeai_hr_assignment_int hai1
                  WHERE EXISTS (SELECT 1
                           FROM xxeai_hr_assignment_int hai2
                          WHERE hai1.orig_system_supervisor_ref = hai2.employee_number))
   SELECT hpi.employee_number,rownum
     FROM xxeai_hr_people_int hpi,
          arbre               hai
    WHERE 1 = 1
      AND hpi.insert_update_flag = 'I'
      AND hai.employee_number = hpi.employee_number
      AND hpi.interface_status != 'ERROR'
      AND SOURCE = gv_source_employe
    START WITH hai.orig_system_supervisor_ref IS NULL
   CONNECT BY hai.orig_system_supervisor_ref = PRIOR hai.employee_number
   UNION ALL
   ( SELECT hpi.employee_number,99999
       FROM xxeai_hr_people_int hpi
      WHERE 1 = 1
        AND hpi.insert_update_flag = 'I'
        AND hpi.interface_status != 'ERROR'
        AND SOURCE = gv_source_employe
     MINUS
    SELECT hpi.employee_number,99999
      FROM xxeai_hr_people_int hpi,
           arbre               hai
     WHERE 1 = 1
       AND hpi.insert_update_flag = 'I'
       AND hai.employee_number = hpi.employee_number
       AND hpi.interface_status != 'ERROR'
       AND SOURCE = gv_source_employe
     START WITH hai.orig_system_supervisor_ref IS NULL
    CONNECT BY hai.orig_system_supervisor_ref = PRIOR hai.employee_number)
   ;

    TYPE t_employe IS TABLE OF XXEAI_HR_PEOPLE_INT.employee_number%Type index by binary_integer;
    lt_employe t_employe;

    TYPE t_rownum IS TABLE OF PLS_INTEGER index by binary_integer;
    lt_rownum t_rownum;

    l_emp        XXEAI_HR_PEOPLE_INT%ROWTYPE;
    l_assignment XXEAI_HR_ASSIGNMENT_INT%ROWTYPE;
    l_bank       XXEAI_HR_BANK_INT_ALL%ROWTYPE;

    e_emp_error EXCEPTION;
    e_continue  EXCEPTION;

    vv_message  VARCHAR2(5000);
    vv_emp_num  VARCHAR2(50);
    vv_table    VARCHAR2(30);
    vn_table_id NUMBER;
    vv_type     varchar2(10);
    vv_source   varchar2(30);

    vv_errbuf               VARCHAR2(500);
    vn_retcode              NUMBER;

  --EDB281 ARA API
    l_row_id              VARCHAR2 (500) := NULL;
    l_flex_value_set_id   NUMBER := NULL;
    l_flex_value_id       NUMBER := NULL;
    l_err_msg             VARCHAR2 (500) := NULL;

    --EMPLOYE
    vn_person_id                    number;
    vn_per_object_version_number    number;
    vn_asg_object_version_number    number;
    vd_per_effective_start_date     date;
    vd_per_effective_end_date       date;
    vv_full_name                    varchar2(500);
    vn_per_comment_id               number;
    vn_assignment_sequence          number;
    vv_assignment_number            varchar2(100);
    vb_name_combination_warning     boolean;
    vb_assign_payroll_warning       boolean;
    vb_orig_hire_warning            boolean;

    vv_currency_code                ap_suppliers.invoice_currency_code%TYPE;

    vn_address_id                   NUMBER;
    vn_object_version_number        NUMBER;

    --ASSIGNMENT
    vv_task_number          pa_tasks.task_number%TYPE;
    vv_task_id              pa_tasks.task_id%TYPE;
    vn_task_project_id      pa_projects_all.project_id%TYPE;
    vv_task_project_name    pa_projects_all.segment1%TYPE;
    vv_task_project_type    pa_projects_all.project_type%TYPE;
    vd_task_start_date      DATE;
    vd_task_completion_date DATE;
    vd_task_closed_date     DATE;
    vv_task_org_projet      hr_all_organization_units.name%TYPE;
    vn_task_org_projet_id   hr_all_organization_units.organization_id%TYPE;
    vv_task_societe         VARCHAR2(10);
    vv_task_region          VARCHAR2(10);
    vv_task_org_fin         hr_all_organization_units.name%TYPE;
    vn_task_org_fin_id      hr_all_organization_units.organization_id%TYPE;

    vn_ledger_id            gl_ledgers.ledger_id%TYPE;
    vn_job_id               per_jobs.job_id%TYPE;

    vn_superviseur          NUMBER;
    vn_sup_hierar           NUMBER;

    vn_assignment_id   PER_ALL_ASSIGNMENTS_F.ASSIGNMENT_ID%TYPE;
    vn_people_group_id NUMBER;
    vb_update_change_insert BOOLEAN;
    vb_correction      BOOLEAN;
    vb_update          BOOLEAN;
    vb_update_override BOOLEAN;
    vv_dt_ud_mode      VARCHAR2(100);

    vn_soft_coding_keyflex_id  HR_SOFT_CODING_KEYFLEX.SOFT_CODING_KEYFLEX_ID%TYPE;
    vc_concatenated_segments   hr_soft_coding_keyflex.concatenated_segments%TYPE;
    vn_comment_id              PER_ALL_ASSIGNMENTS_F.COMMENT_ID%TYPE;
    vb_no_managers_warning     BOOLEAN;
    vb_other_manager_warning   BOOLEAN;
    vd_effective_start_date    DATE;
    vd_effective_end_date      DATE;
    vn_special_ceiling_step_id NUMBER;
    vc_group_name                  VARCHAR2(500);
    vb_org_now_no_manager_warning  BOOLEAN;
    vb_spp_delete_warning          BOOLEAN;
    vc_entries_changed_warning     VARCHAR2(500);
    vb_tax_district_changed_warn   BOOLEAN;

    --API
    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2 (200);
    vv_commit             VARCHAR2 (200);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2 (200);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2 (4000);
    VN_MSG_INDEX_OUT      NUMBER;

    --VENDOR
    vr_vendor_rec         ap_vendor_pub_pkg.r_vendor_rec_type;
    vn_vendor_id          NUMBER;
    vn_party_id           NUMBER;

    --VENDOR SITE
    vr_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_vendor_site_id     NUMBER;
    vn_party_site_id      NUMBER;
    vn_location_id        NUMBER;
    vv_calling_prog      VARCHAR2(200);

    vn_PREPAY_CCID    gl_code_combinations.code_combination_id%TYPE;
    vn_ACCTS_PAY_CCID gl_code_combinations.code_combination_id%TYPE;

    --LOCATION ID
    vr_location_rec hz_location_v2pub.location_rec_type;
    vr_party_site_rec  hz_party_site_v2pub.party_site_rec_type;
    vv_party_site_number VARCHAR2 (2000);

    --BANK
    vb_info_bank           BOOLEAN;
    vr_ext_bank_acct_rec   iby_ext_bankacct_pub.extbankacct_rec_type;
    vn_bank_id             NUMBER;
    vn_branch_id           NUMBER;
    vn_bank_acct_id        NUMBER;
    vv_association_level   VARCHAR2(50);
    vn_acct_id             NUMBER;
    vn_joint_acct_id       NUMBER;
    vr_response            iby_fndcpt_common_pub.result_rec_type;
    vv_org_type            VARCHAR2(50);

    vn_assign_id           NUMBER ;
    vr_payee_context_rec  IBY_DISBURSEMENT_SETUP_PUB.PayeeContext_rec_type;
    vr_assignment_attribs IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_rec_type;

    --MAJ BANQUE
    vn_ext_payee_id               iby_external_payees_all.EXT_PAYEE_ID%TYPE;
    vt_External_Payee_Tab_Type    IBY_DISBURSEMENT_SETUP_PUB.External_Payee_Tab_Type;
    vt_Ext_Payee_ID_Tab_Type      IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_ID_Tab_Type;
    vt_Ext_Payee_Update_Tab_Type  IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_Update_Tab_Type;
    vt_Ext_Payee_Create_Tab_Type  IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_Create_Tab_Type;
    vr_External_Payee_Rec         IBY_DISBURSEMENT_SETUP_PUB.External_Payee_Rec_Type;

    vv_payment_method             ap_suppliers.payment_method_lookup_code%TYPE;

  --KDFI-2084 ARA
  vv_date_debut_ex DATE;
  vv_date_debut_new DATE;

  BEGIN

  gv_step  := lv_current_program_unit||' 000 : DEBUT';
  log_message(gv_step);

  --BOUCLE POUR CHAQUE EMPLOYE
  gv_step  := lv_current_program_unit||' 000 : initialisation pour boucle : C_EMPLOYE';log_message(gv_step);
  OPEN  C_EMPLOYE;
  FETCH C_EMPLOYE BULK COLLECT INTO lt_employe,lt_rownum;
  CLOSE C_EMPLOYE;

  IF lt_employe.COUNT > 0 THEN
    FOR i in lt_employe.FIRST..lt_employe.LAST LOOP
      BEGIN

      --REINIT VARIABLE
      --EMPLOYE
      vn_person_id                    := NULL;
      vn_per_object_version_number    := NULL;
      vn_asg_object_version_number    := NULL;
      vd_per_effective_start_date     := NULL;
      vd_per_effective_end_date       := NULL;
      vv_full_name                    := NULL;
      vn_per_comment_id               := NULL;
      vn_assignment_sequence          := NULL;
      vv_assignment_number            := NULL;
      vb_name_combination_warning     := NULL;
      vb_assign_payroll_warning       := NULL;
      vb_orig_hire_warning            := NULL;

      vv_currency_code                := NULL;

      vn_address_id                   := NULL;
      vn_object_version_number        := NULL;

      --ASSIGNMENT
      vv_task_number          := NULL;
      vv_task_id              := NULL;
      vn_task_project_id      := NULL;
      vv_task_project_name    := NULL;
      vv_task_project_type    := NULL;
      vd_task_start_date      := NULL;
      vd_task_completion_date := NULL;
      vd_task_closed_date     := NULL;
      vv_task_org_projet      := NULL;
      vn_task_org_projet_id   := NULL;
      vv_task_societe         := NULL;
      vv_task_region          := NULL;
      vv_task_org_fin         := NULL;
      vn_task_org_fin_id      := NULL;

      vn_ledger_id            := NULL;
      vn_job_id               := NULL;

      vn_superviseur          := NULL;
      vn_sup_hierar           := NULL;

      vn_assignment_id   := NULL;
      vn_people_group_id := NULL;
      vb_update_change_insert :=NULL;
      vb_correction      := NULL;
      vb_update          := NULL;
      vb_update_override := NULL;
      vv_dt_ud_mode      := NULL;

      vn_soft_coding_keyflex_id  := NULL;
      vc_concatenated_segments   := NULL;
      vn_comment_id              := NULL;
      vb_no_managers_warning     := NULL;
      vb_other_manager_warning   := NULL;
      vd_effective_start_date    := NULL;
      vd_effective_end_date      := NULL;
      vn_special_ceiling_step_id := NULL;
      vc_group_name                  := NULL;
      vb_org_now_no_manager_warning  := NULL;
      vb_spp_delete_warning          := NULL;
      vc_entries_changed_warning     := NULL;
      vb_tax_district_changed_warn   := NULL;

      --API
      vn_api_version        := NULL;
      vv_init_msg_list      := NULL;
      vv_commit             := NULL;
      vn_validation_level   := NULL;
      vv_return_status      := NULL;
      vn_msg_count          := NULL;
      vv_msg_data           := NULL;
      VN_MSG_INDEX_OUT      := NULL;



      --VENDOR
      vr_vendor_rec         := NULL;
      vn_vendor_id          := NULL;
      vn_party_id           := NULL;

      --VENDOR SITE
      vr_vendor_site_rec  := NULL;
      vn_vendor_site_id   := NULL;
      vn_party_site_id    := NULL;
      vn_location_id      := NULL;
      vv_calling_prog     := NULL;

      vn_PREPAY_CCID    := NULL;
      vn_ACCTS_PAY_CCID := NULL;

      vr_location_rec      := NULL;
      vr_party_site_rec    := NULL;
      vv_party_site_number := NULL;


      --BANK
      vb_info_bank           := NULL;
      vr_ext_bank_acct_rec   := NULL;
      vn_bank_id             := NULL;
      vn_branch_id           := NULL;
      vn_bank_acct_id        := NULL;
      vv_association_level   := NULL;
      vn_acct_id             := NULL;
      vn_joint_acct_id       := NULL;
      vr_response            := NULL;
      vv_org_type            := NULL;

      vn_assign_id          := NULL;
      vr_payee_context_rec  := NULL;
      vr_assignment_attribs := NULL;

      vv_payment_method     := NULL;

    --KDFI-2084 ARA
    vv_date_debut_ex := NULL;
    vv_date_debut_new := NULL;

      --######################################################################################
      -- EMPLOYE
      --######################################################################################
      gv_step  := lv_current_program_unit||' 001 : sélection de l''employé : '||lt_employe(i);log_message(gv_step);
      SELECT *
      INTO l_emp
      FROM XXEAI_HR_PEOPLE_INT HPI
      WHERE
       HPI.INSERT_UPDATE_FLAG = 'I'
       AND HPI.INTERFACE_STATUS != 'ERROR'
       AND HPI.EMPLOYEE_NUMBER = lt_employe(i)
       AND SOURCE = gv_source_employe
      ;

    --KDFI-2084 ARA
    IF l_emp.EFFECTIVE_START_DATE > SYSDATE THEN
      gv_step  := lv_current_program_unit||' : l''employé '||lt_employe(i) || ' a une date de début postérieure à la date du jour : ' || l_emp.EFFECTIVE_START_DATE;log_message(gv_step);
      gv_step  := 'Création de l''employé ' ||lt_employe(i) || ' avec la date du jour' ;log_message(gv_step);

    vv_date_debut_ex := l_emp.EFFECTIVE_START_DATE;
    vv_date_debut_new := SYSDATE;
    ELSE
    vv_date_debut_new := l_emp.EFFECTIVE_START_DATE;
    END IF;


      --Init pour message
      vv_message  := '';
      vv_emp_num  := l_emp.employee_number;
      vv_table    := 'XXEAI_HR_PEOPLE_INT';
      vn_table_id := l_emp.XXEAI_PERSON_ID;
      vv_source   := gv_source_employe;

      --///VALIDATION EMPLOYE
      gv_step  := lv_current_program_unit||' 002 : Existence de l''employé';log_message(gv_step);
      IF get_person_id(l_emp.employee_number) IS NOT NULL then
        --Création de l'employé impossible, le matricule existe déja
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0001',
                                                 'EMPNUM',l_emp.EMPLOYEE_NUMBER);
        vv_type     := 'E';
        RAISE e_emp_error;
      END IF;

      --///CREATION DE L'EMPLOYE
      BEGIN
        gv_step  := lv_current_program_unit||' 003 : création employé ';log_message(gv_step);
        hr_employee_api.create_employee  ( p_validate                      => FALSE
                                          ,p_hire_date                     => vv_date_debut_new
                                          ,p_business_group_id             => gn_business_group_id
                                          ,p_last_name                     => l_emp.LAST_NAME
                                          ,p_sex                           => l_emp.SEX
                                          ,p_person_type_id                => l_emp.PERSON_TYPE_ID
                                          ,p_date_of_birth                 => l_emp.DATE_OF_BIRTH
                                          ,p_email_address                 => l_emp.EMAIL_ADDRESS
                                          ,p_employee_number               => l_emp.EMPLOYEE_NUMBER
                                          ,p_expense_check_send_to_addres  => l_emp.EXPENSE_CHECK_SEND_TO_ADDRESS
                                          ,p_first_name                    => l_emp.FIRST_NAME
                                          ,p_nationality                   => l_emp.NATIONALITY
                                          ,p_national_identifier           => translate(l_emp.NATIONAL_IDENTIFIER,'1234567890 |','1234567890')
                                          ,p_title                         => l_emp.TITLE
                                          ,p_work_telephone                => l_emp.WORK_TELEPHONE
                                          ,p_attribute2                    => l_emp.ATTRIBUTE2
                                          ,p_attribute4                    => l_emp.ATTRIBUTE4
                                          ,p_attribute11                   => l_emp.ORIG_SYSTEM_PERSON_REF
                                          ,p_person_id                     => vn_person_id
                                          ,p_assignment_id                 => vn_assignment_id
                                          ,p_per_object_version_number     => vn_per_object_version_number
                                          ,p_asg_object_version_number     => vn_asg_object_version_number
                                          ,p_per_effective_start_date      => vd_per_effective_start_date
                                          ,p_per_effective_end_date        => vd_per_effective_end_date
                                          ,p_full_name                     => vv_full_name
                                          ,p_per_comment_id                => vn_per_comment_id
                                          ,p_assignment_sequence           => vn_assignment_sequence
                                          ,p_assignment_number             => vv_assignment_number
                                          ,p_name_combination_warning      => vb_name_combination_warning
                                          ,p_assign_payroll_warning        => vb_assign_payroll_warning
                                          ,p_orig_hire_warning             => vb_orig_hire_warning
                                          );
        --
        gv_step  := lv_current_program_unit||' 004 : création employé ID : ' || vn_person_id;log_message(gv_step);

    --- 29/05/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
        IF /*vb_name_combination_warning or*/ vb_orig_hire_warning then
          --Création de l'employé impossible : erreur dans l'API
          gv_step  := lv_current_program_unit||' 005 : Création de l''employé impossible : erreur dans l''API';log_message(gv_step);

          --- 29/05/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
          /*IF vb_name_combination_warning THEN
            vv_message := 'Un employé existe déja pour ce nom, prénom et date de naissance';
          ELS*/
      IF vb_orig_hire_warning THEN
            vv_message := 'Date d''embauche renseigné et type d''employé incohérent';
          END IF;

          vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0002',
                                                  'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                  'MESSAGE',vv_message);
          vv_type     := 'E';
          RAISE e_emp_error;
        ELSE
      --- 29/05/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
          IF vb_name_combination_warning THEN
                vv_message := 'Un employé existe déja pour ce nom, prénom et date de naissance';
                vv_type     := 'W';
                insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
          END IF;

          --Création OK
          gv_step  := lv_current_program_unit||' 006 : Création de l''employé OK';log_message(gv_step);
          NULL; --on passe a la suite
        END IF;

      EXCEPTION
       WHEN e_emp_error THEN
        RAISE e_emp_error;
       WHEN OTHERS THEN
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0002',
                                                  'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                  'MESSAGE',SQLERRM);
        vv_type     := 'E';
        RAISE e_emp_error;
      END;


      --///CREATION DE L'ADRESSE
      gv_step  := lv_current_program_unit||' 007 : création de l''adresse employé';log_message(gv_step);
      BEGIN
        hr_person_address_api.create_person_address (  p_validate       => FALSE
                                                      ,p_effective_date => vv_date_debut_new
                                                      ,p_person_id      => vn_person_id
                                                      ,p_primary_flag   => 'Y'
                                                      ,p_style          => gv_style
                                                      ,p_date_from      => vv_date_debut_new
                                                      ,p_address_line1  => '.'
                                                      ,p_country        => 'FR'
                                                      ,p_address_id     => vn_address_id
                                                      ,p_object_version_number=> vn_object_version_number
                                                      );
      EXCEPTION
       WHEN OTHERS THEN
        ROLLBACK;
        --Création de l'employé impossible : erreur dans la création de l'adresse employé
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0003',
                                                 'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                 'MESSAGE',SQLERRM);
        vv_type     := 'E';
        raise e_emp_error;
      END;

      --######################################################################################
      --AFFECTATION EMPLOYE
      --######################################################################################
      gv_step  := lv_current_program_unit||' 008 : Sélection de l''affectation de l''employé';log_message(gv_step);


      BEGIN

        SELECT *
        INTO l_assignment
        FROM
         XXEAI_HR_ASSIGNMENT_INT HAI
        WHERE
             HAI.INSERT_UPDATE_FLAG = 'I'
         AND HAI.INTERFACE_STATUS != 'ERROR'
         AND HAI.EMPLOYEE_NUMBER = vv_emp_num;


      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        --Création de l'employé impossible : Pas d'info affectation

        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0004','EMPNUM',l_emp.EMPLOYEE_NUMBER);
        vv_type     := 'E';
        raise e_emp_error;
       WHEN TOO_MANY_ROWS THEN
        --Création de l'employé impossible : Doublon dans les infos affectations

        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0005','EMPNUM',l_emp.EMPLOYEE_NUMBER);
        vv_type     := 'E';
        raise e_emp_error;
      END;

   --SHA EDB402 Début
    l_assignment.ASS_ATTRIBUTE1 := get_value_from_set(
        p_value    => l_assignment.ASS_ATTRIBUTE1
    );
    --SHA EDB402 fin
      --Init pour message
      vv_table    := 'XXEAI_HR_ASSIGNMENT_INT';
      vn_table_id := l_assignment.XXEAI_ASSIGNMENT_ID;

      --///VALIDATION AFFECTATION
      --Récupération info tache
      gv_step  := lv_current_program_unit||' 009 : Récupération info tache : '||l_assignment.ass_attribute5;log_message(gv_step);
      DKA_PA_TOOLS_PKG.pa_get_info_task(vv_errbuf,
                                        vn_retcode,
                                        l_assignment.ass_attribute5,
                                        vv_task_id,
                                        vn_task_project_id,
                                        vv_task_project_name,
                                        vv_task_project_type,
                                        vd_task_start_date,
                                        vd_task_completion_date,
                                        vd_task_closed_date,
                                        vv_task_org_projet,
                                        vn_task_org_projet_id,
                                        vv_task_societe,
                                        vv_task_region,
                                        vv_task_org_fin,
                                        vn_task_org_fin_id);

      IF vn_retcode != 0 THEN
         --Création de l'affectation employé impossible : Erreur lors de la détermination des informations projet
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0006',
                                                 'EMPNUM',l_emp.employee_number,
                                                 'TACHE',l_assignment.ass_attribute5,'MESSAGE',vv_errbuf);
        vv_type     := 'E';
        raise e_emp_error;
      END IF;

      --Superviseur
      gv_step  := lv_current_program_unit||' 010 : Validation superviseur : '||l_assignment.ORIG_SYSTEM_SUPERVISOR_REF;log_message(gv_step);
      IF l_assignment.ORIG_SYSTEM_SUPERVISOR_REF is not null THEN
         vn_superviseur :=  get_person_id(l_assignment.ORIG_SYSTEM_SUPERVISOR_REF);

         IF vn_superviseur IS NULL THEN
           --Création de l'affectation employé impossible, le superviseur n'existe pas ou est inactif
           vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0007',
                                                    'EMPNUM',l_emp.employee_number,
                                                    'SUP',l_assignment.ORIG_SYSTEM_SUPERVISOR_REF);
           vv_type     := 'E';
           RAISE e_emp_error;
         END IF;
      END IF;

      --Superviseur Hiérarchique
      gv_step  := lv_current_program_unit||' 011 : Validation superviseur hiérarchique: '||l_assignment.ASS_ATTRIBUTE3;log_message(gv_step);
      IF l_assignment.ASS_ATTRIBUTE3 is not null THEN
         vn_sup_hierar :=  get_person_id(l_assignment.ASS_ATTRIBUTE3);

         IF vn_sup_hierar IS NULL THEN
           --Création de l'affectation employé impossible, le superviseur hierarchique n'existe pas ou est inactif
           vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0008',
                                                    'EMPNUM',l_emp.employee_number,
                                                    'SUP',l_assignment.ASS_ATTRIBUTE3);
           vv_type     := 'E';
           RAISE e_emp_error;
        END IF;
      END IF;

    -- EDB281 ARA

    IF REGEXP_LIKE(SUBSTR(l_emp.EMPLOYEE_NUMBER,1, 1), '^[0-9]+$') THEN
    --DBMS_OUTPUT.PUT_LINE('Numeric');

    gv_step  := ' 012-1 : Ajout du matricule employé dans le jeu de valeurs DAOPCCF_INTERCO';
    log_message(gv_step);

    -- Get Value Set ID
    SELECT flex_value_set_id
     INTO l_flex_value_set_id
    FROM apps.fnd_flex_value_sets
    WHERE flex_value_set_name = 'DAOPCCF_INTERCO';


      -- Get Next Sequence Number
      SELECT apps.fnd_flex_values_s.NEXTVAL INTO l_flex_value_id FROM DUAL;

      BEGIN
         apps.fnd_flex_values_pkg.
          insert_row (
            x_rowid                        => l_row_id,
            x_flex_value_id                => l_flex_value_id,
            x_attribute_sort_order         => NULL,
            x_flex_value_set_id            => l_flex_value_set_id,
            x_flex_value                   => 'P' || l_emp.EMPLOYEE_NUMBER,
            x_enabled_flag                 => 'Y',
            x_summary_flag                 => 'N',
            x_start_date_active            => NULL, --TO_DATE ('01-JUL-2019', 'DD-MON-YYYY'),
            x_end_date_active              => NULL,
            x_parent_flex_value_low        => NULL,
            x_parent_flex_value_high       => NULL,
            x_structured_hierarchy_level   => NULL,
            x_hierarchy_level              => NULL,
            x_compiled_value_attributes    =>  'Y'||CHR(10)||'Y',
            x_value_category               => NULL,
            x_attribute1                   => NULL,
            x_attribute2                   => NULL,
            x_attribute3                   => NULL,
            x_attribute4                   => NULL,
            x_attribute5                   => NULL,
            x_attribute6                   => NULL,
            x_attribute7                   => NULL,
            x_attribute8                   => NULL,
            x_attribute9                   => NULL,
            x_attribute10                  => NULL,
            x_attribute11                  => NULL,
            x_attribute12                  => NULL,
            x_attribute13                  => NULL,
            x_attribute14                  => NULL,
            x_attribute15                  => NULL,
            x_attribute16                  => NULL,
            x_attribute17                  => NULL,
            x_attribute18                  => NULL,
            x_attribute19                  => NULL,
            x_attribute20                  => NULL,
            x_attribute21                  => NULL,
            x_attribute22                  => NULL,
            x_attribute23                  => NULL,
            x_attribute24                  => NULL,
            x_attribute25                  => NULL,
            x_attribute26                  => NULL,
            x_attribute27                  => NULL,
            x_attribute28                  => NULL,
            x_attribute29                  => NULL,
            x_attribute30                  => NULL,
            x_attribute31                  => NULL,
            x_attribute32                  => NULL,
            x_attribute33                  => NULL,
            x_attribute34                  => NULL,
            x_attribute35                  => NULL,
            x_attribute36                  => NULL,
            x_attribute37                  => NULL,
            x_attribute38                  => NULL,
            x_attribute39                  => NULL,
            x_attribute40                  => NULL,
            x_attribute41                  => NULL,
            x_attribute42                  => NULL,
            x_attribute43                  => NULL,
            x_attribute44                  => NULL,
            x_attribute45                  => NULL,
            x_attribute46                  => NULL,
            x_attribute47                  => NULL,
            x_attribute48                  => NULL,
            x_attribute49                  => NULL,
            x_attribute50                  => NULL,
            x_flex_value_meaning           => 'P' || l_emp.EMPLOYEE_NUMBER,
            x_description                  => l_emp.LAST_NAME || ' ' || l_emp.FIRST_NAME,
            x_creation_date                => SYSDATE,
            x_created_by                   => fnd_global.user_id,
            x_last_update_date             => SYSDATE,
            x_last_updated_by              => fnd_global.user_id,
            x_last_update_login            => fnd_global.user_id);

            COMMIT;
        EXCEPTION
         WHEN OTHERS
         THEN

            --DBMS_OUTPUT.PUT_LINE(SQLERRM);
      gv_step  := ' 012-2 : Erreur dans l''API de l''ajout du matricule employé dans le jeu de valeurs DAOPCCF_INTERCO : ' || SQLERRM;
      log_message(gv_step);
      END;

    ELSE
    --DBMS_OUTPUT.PUT_LINE('char');
    --DBMS_OUTPUT.PUT_LINE('on peut pas insérer l''employé');
    gv_step  := '012-3 : Erreur dans l''ajout du matricule employé dans le jeu de valeurs DAOPCCF_INTERCO : ' || 'le premier caractère du matricule employé : ' || l_emp.EMPLOYEE_NUMBER || ' n''est pas numérique !';
    log_message(gv_step);
      END IF;

    --END EDB281 ARA



      --Entité comptable
      gv_step  := lv_current_program_unit||' 012 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
      vn_ledger_id := dka_gl_tools_pkg.get_legder_id(vv_task_societe);

      IF vn_ledger_id IS NULL THEN
         --Création de l'affectation employé impossible, entité comptable n'existe pas pour la société
         vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0009',
                                                  'EMPNUM',l_emp.employee_number,
                                                  'SOCIETE',vv_task_societe);
         vv_type     := 'E';
         RAISE e_emp_error;
      END IF;

      --Devise Entité comptable
      gv_step  := lv_current_program_unit||' 012 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
      vv_currency_code := get_currency_code(vn_ledger_id);

      IF vv_currency_code IS NULL THEN
         --Création de l'employé impossible : Erreur sur la devise de l'entité comptable
         vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0023',
                                                  'EMPNUM',l_emp.employee_number,
                                                  'SOCIETE',vv_task_societe);
         vv_type     := 'E';
         RAISE e_emp_error;
      END IF;

      --Fonction
      gv_step  := lv_current_program_unit||' 013 : Recherche de la fonction: '||l_emp.attribute2||'.'||gv_default_job;log_message(gv_step);
      vn_job_id := get_job_id(l_emp.attribute2,gv_default_job);

      IF vn_job_id IS NULL THEN
         --Création de l'affectation employé impossible, le poste n'existe pas
         vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0010',
                                                  'EMPNUM',l_emp.employee_number,
                                                  'FCT',l_emp.attribute2|| '.' || gv_default_job);
         vv_type     := 'E';
         RAISE e_emp_error;
      END IF;


      --//AFFECTATION - API STD
      gv_step  := lv_current_program_unit||' 014 : AFFECTATION - API STD';log_message(gv_step);

      BEGIN
       -- Find Date Track Mode
       -- --------------------------------
       dt_api.find_dt_upd_modes
       (    p_effective_date                  => TRUNC(SYSDATE),
            p_base_table_name                 => 'PER_ALL_ASSIGNMENTS_F',
            p_base_key_column                 => 'ASSIGNMENT_ID',
            p_base_key_value                  => vn_assignment_id,
             -- Output data elements
             -- --------------------------------
             p_correction                          => vb_correction,
             p_update                              => vb_update,
             p_update_override                     => vb_update_override,
             p_update_change_insert                => vb_update_change_insert
         );

      IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE ) THEN
      -- UPDATE_OVERRIDE
          vv_dt_ud_mode := 'UPDATE_OVERRIDE';
      END IF;

      IF ( vb_correction = TRUE ) THEN
      -- CORRECTION
         vv_dt_ud_mode := 'CORRECTION';
      END IF;

      IF ( vb_update = TRUE ) THEN
      -- UPDATE
          vv_dt_ud_mode := 'UPDATE';
      END IF;

      -- Update Employee Assignment
      -- ---------------------------------------------
      gv_step  := lv_current_program_unit||' 015 : AFFECTATION - API STD : Update Employee Assignment ';log_message(gv_step);
      hr_assignment_api.update_emp_asg
       ( p_effective_date               => TRUNC(SYSDATE)
        ,p_datetrack_update_mode        => vv_dt_ud_mode
        ,p_assignment_id                => vn_assignment_id
        ,p_object_version_number        => vn_asg_object_version_number
        ,p_supervisor_id                => vn_superviseur
        ,p_assignment_number            => l_emp.employee_number
        ,p_set_of_books_id              => vn_ledger_id
        ,p_ass_attribute1               => nvl(l_assignment.ASS_ATTRIBUTE1,vv_task_societe)
        ,p_ass_attribute2               => l_assignment.ASS_ATTRIBUTE2
        ,p_ass_attribute3               => vn_sup_hierar
        ,p_ass_attribute4               => l_assignment.ASS_ATTRIBUTE4
        ,p_ass_attribute5               => l_assignment.ASS_ATTRIBUTE5
        ,p_concatenated_segments        => vc_concatenated_segments
        ,p_soft_coding_keyflex_id       => vn_soft_coding_keyflex_id
        ,p_comment_id                   => vn_comment_id
        ,p_effective_start_date         => vd_effective_start_date
        ,p_effective_end_date           => vd_effective_end_date
        ,p_no_managers_warning          => vb_no_managers_warning
        ,p_other_manager_warning        => vb_other_manager_warning
        );

      EXCEPTION
       WHEN OTHERS THEN
        --Création de l'affectation employé impossible, erreur dans l'API : Update Employee Assignment
         vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0011',
                                                  'EMPNUM',l_emp.employee_number,
                                                  'MESSAGE',SQLERRM);
         vv_type     := 'E';
         RAISE e_emp_error;
      END;

       -- Find Date Track Mode for Second API
       -- ------------------------------------------------------
      gv_step  := lv_current_program_unit||' 016 : AFFECTATION - API STD';log_message(gv_step);

      BEGIN

      dt_api.find_dt_upd_modes
        (  p_effective_date             => TRUNC(SYSDATE),
           p_base_table_name            => 'PER_ALL_ASSIGNMENTS_F',
           p_base_key_column            => 'ASSIGNMENT_ID',
           p_base_key_value             => vn_assignment_id,
           -- Output data elements
           -- -------------------------------
           p_correction                 => vb_correction,
           p_update                     => vb_update,
           p_update_override            => vb_update_override,
           p_update_change_insert       => vb_update_change_insert
        );

      IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE )
      THEN  -- UPDATE_OVERRIDE
        vv_dt_ud_mode := 'UPDATE_OVERRIDE';
      END IF;
       IF ( vb_correction = TRUE )
       THEN -- CORRECTION
         vv_dt_ud_mode := 'CORRECTION';
      END IF;
      IF ( vb_update = TRUE )
      THEN -- UPDATE
        vv_dt_ud_mode := 'UPDATE';
      END IF;

       -- Update Employee Assgment Criteria
       -- -----------------------------------------------------
      gv_step  := lv_current_program_unit||' 017 : AFFECTATION - API STD : Update Employee Assgment Criteria ';log_message(gv_step);

       hr_assignment_api.update_emp_asg_criteria
       ( -- Input data elements
        -- ------------------------------
        p_effective_date                      => TRUNC(SYSDATE),
        p_datetrack_update_mode               => vv_dt_ud_mode,
        p_assignment_id                       => vn_assignment_id,
        p_organization_id                     => vn_task_org_fin_id,
        p_job_id                              => vn_job_id,
        p_segment1                            => 'N/A',
        -- Output data elements
        -- -------------------------------
        p_people_group_id                     => vn_people_group_id,
        p_object_version_number               => vn_asg_object_version_number,
        p_special_ceiling_step_id             => vn_special_ceiling_step_id,
        p_group_name                          => vc_group_name,
        p_effective_start_date                => vd_effective_start_date,
        p_effective_end_date                  => vd_effective_end_date,
        p_org_now_no_manager_warning          => vb_org_now_no_manager_warning,
        p_other_manager_warning               => vb_other_manager_warning,
        p_spp_delete_warning                  => vb_spp_delete_warning,
        p_entries_changed_warning             => vc_entries_changed_warning,
        p_tax_district_changed_warning        => vb_tax_district_changed_warn
       );

      EXCEPTION
       WHEN OTHERS THEN
        --Création de l'affectation employé impossible, erreur dans l'API : Update Employee Assgment Criteria
         vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0012',
                                                  'EMPNUM',l_emp.employee_number,
                                                  'MESSAGE',SQLERRM);
         vv_type     := 'E';
         RAISE e_emp_error;
      END;

      --######################################################################################
      --CREATION FOURNISSEUR EMPLOYE
      --######################################################################################
      gv_step  := lv_current_program_unit||' 018 : Creation fournisseur employe';log_message(gv_step);

      --Init pour message
      vv_table    := 'XXEAI_HR_PEOPLE_INT';
      vn_table_id := l_emp.XXEAI_PERSON_ID;

      --Init valeur fournisseur
      vn_api_version      := 1.0;
      vv_init_msg_list    :=FND_API.G_TRUE;
      vv_commit           := FND_API.G_FALSE;
      vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
      vv_return_status    := NULL;
      vn_msg_count        := NULL;
      vv_msg_data         := NULL;

      vn_vendor_id := NULL;
      vn_party_id := NULL;

      vr_vendor_rec.vendor_name               := l_emp.last_name ||' '|| l_emp.first_name ||' '|| l_emp.employee_number;
      --vr_vendor_rec.segment1                  := l_emp.employee_number; --artf2275018
      vr_vendor_rec.vendor_type_lookup_code   := gv_vendor_type_lookup_code;
      vr_vendor_rec.employee_id               := vn_person_id;
      vr_vendor_rec.vat_registration_num      := translate(l_emp.NATIONAL_IDENTIFIER,'1234567890 |','1234567890');
      vr_vendor_rec.set_of_books_id           := vn_ledger_id;

      vr_vendor_rec.summary_flag               := 'N';
      vr_vendor_rec.enabled_flag               := 'Y';
      vr_vendor_rec.TERMS_ID                   := gn_term_id;
      vr_vendor_rec.PAYMENT_PRIORITY           := gn_payment_priority;
      vr_vendor_rec.PAY_GROUP_LOOKUP_CODE      := gv_pay_group_lookup_code;
      vr_vendor_rec.PAY_DATE_BASIS_LOOKUP_CODE := gv_pay_date_basis_lookup_code;
      vr_vendor_rec.TERMS_DATE_BASIS           := gv_terms_date_basis;
      vr_vendor_rec.hold_all_payments_flag     := 'N';
      vr_vendor_rec.one_time_flag              := 'N';
      vr_vendor_rec.always_take_disc_flag      := 'N';
      vr_vendor_rec.invoice_currency_code      := vv_currency_code;
      vr_vendor_rec.payment_currency_code      := vv_currency_code;
      vr_vendor_rec.small_business_flag        := 'Y';
      vr_vendor_rec.women_owned_flag           := 'N';
      vr_vendor_rec.hold_flag                  := 'N';
      vr_vendor_rec.hold_unmatched_invoices_flag := 'N';
      vr_vendor_rec.exclude_freight_from_discount := 'N';
      vr_vendor_rec.auto_tax_calc_flag         := 'N';
      vr_vendor_rec.match_option               := 'P';
      vr_vendor_rec.hold_future_payments_flag  := 'N';
      vr_vendor_rec.attribute_category         := gv_vendor_attribute_category;
      vr_vendor_rec.attribute1                 := 'N';
      vr_vendor_rec.attribute3                 := 'N';
      vr_vendor_rec.attribute4                 := NULL;
      vr_vendor_rec.attribute8                 := 'E';

      --///Création du fournisseur - API
      gv_step  := lv_current_program_unit||' 019 : Création du fournisseur - API';log_message(gv_step);

      ap_vendor_pub_pkg.create_vendor (vn_api_version,
                                       vv_init_msg_list,
                                       vv_commit,
                                       vn_validation_level,
                                       vv_return_status,
                                       vn_msg_count,
                                       vv_msg_data,
                                       vr_vendor_rec,
                                       vn_vendor_id,
                                       vn_party_id
                                      );

      IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
        --On continue
        gv_step  := lv_current_program_unit||' 020 : Création du fournisseur - API : Success';log_message(gv_step);

        NULL;

        --- 04/09/2017 NBO artf2216362 - INT076 - Problème de numérotation des fournisseurs en mode quotidien
        update ap.ap_suppliers
        set segment1 = l_emp.EMPLOYEE_NUMBER
        where employee_id = vn_person_id;

        gv_step  := lv_current_program_unit||' 020.1 : Renommage du fournisseur employé OK :' || l_emp.EMPLOYEE_NUMBER;log_message(gv_step);
      ELSE
        vv_message := '';
        IF vn_msg_count > 0 THEN

          FOR v_index IN 1 .. vn_msg_count LOOP
            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
            vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

          END LOOP;

        END IF;

        --Création du fournisseur impossible : message
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0013',
                                                 'EMPNUM',l_emp.employee_number,
                                                 'MESSAGE',vv_message);
        vv_type     := 'E';
        RAISE e_emp_error;

      END IF;

      --######################################################################################
      --CREATION SITE FOURNISSEUR EMPLOYE
      --######################################################################################
      gv_step  := lv_current_program_unit||' 021 : CREATION SITE FOURNISSEUR EMPLOYE';log_message(gv_step);

      --Init pour message
      vv_table    := 'XXEAI_HR_PEOPLE_INT';
      vn_table_id := l_emp.XXEAI_PERSON_ID;

      --Compte GL founisseur
      gv_step  := lv_current_program_unit||' 022 : Compte GL founisseur';log_message(gv_step);
      Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => vv_task_societe,
                                            pv_segment2              => vv_task_region,
                                            pv_segment3              => gv_accts_local,
                                            pv_segment4              => gv_accts_anal,
                                            pv_segment5              => gv_ccid_defaut,
                                            pv_segment6              => gv_ccid_defaut,
                                            pv_segment7              => gv_ccid_defaut,
                                            pv_segment8              => gv_ccid_defaut,
                                            pv_segment9              => gv_ccid_defaut,
                                            pv_segment10             => gv_ccid_defaut,
                                            pv_segment11             => gv_ccid_defaut,
                                            pv_segment12             => gv_ccid_defaut,
                                            pn_code_combination_id   => vn_ACCTS_PAY_CCID,
                                            pv_errbuf                => vv_errbuf,
                                            pn_retcode               => vn_retcode);

      gv_step  := lv_current_program_unit||' 024 : Compte GL founisseur : '||vn_ACCTS_PAY_CCID;log_message(gv_step);

      IF  vn_retcode != 0 THEN
         --Création du site fournisseur impossible : recherche de la clé comptable fournisseur en erreur : message
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0014',
                                                 'EMPNUM',l_emp.employee_number,
                                                 'MESSAGE',vv_errbuf);
        vv_type     := 'E';
        RAISE e_emp_error;
      END IF;

      --Compte GL acompte
      gv_step  := lv_current_program_unit||' 023 : Compte GL acompte';log_message(gv_step);
      Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => vv_task_societe,
                                            pv_segment2              => vv_task_region,
                                            pv_segment3              => gv_prepay_local,
                                            pv_segment4              => gv_prepay_anal,
                                            pv_segment5              => 'P' || l_emp.EMPLOYEE_NUMBER,-- EDB281 ARA
                                            pv_segment6              => gv_ccid_defaut,
                                            pv_segment7              => gv_ccid_defaut,
                                            pv_segment8              => gv_ccid_defaut,
                                            pv_segment9              => gv_ccid_defaut,
                                            pv_segment10             => gv_ccid_defaut,
                                            pv_segment11             => gv_ccid_defaut,
                                            pv_segment12             => gv_ccid_defaut,
                                            pn_code_combination_id   => vn_PREPAY_CCID,
                                            pv_errbuf                => vv_errbuf,
                                            pn_retcode               => vn_retcode);

      gv_step  := lv_current_program_unit||' 024 : Compte GL acompte : '||vn_PREPAY_CCID;log_message(gv_step);


      IF  vn_retcode != 0 THEN
         --Création du site fournisseur impossible : recherche de la clé comptable acompte fournisseur en erreur : message
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0015',
                                                 'EMPNUM',l_emp.employee_number,
                                                 'MESSAGE',vv_errbuf);
        vv_type     := 'E';
        RAISE e_emp_error;
      END IF;

      --Init valeur site fournisseur
      vn_api_version      := 1.0;
      vv_init_msg_list    := FND_API.G_TRUE;
      vv_commit           := FND_API.G_FALSE;
      vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
      vv_return_status    := NULL;
      vn_msg_count        := NULL;
      vv_msg_data         := NULL;

      vn_vendor_site_id     := NULL;
      vn_party_site_id      := NULL;
      vn_location_id        := NULL;

      vr_vendor_site_rec.VENDOR_ID        := vn_vendor_id;
      vr_vendor_site_rec.ATTRIBUTE4       := 'P'||l_emp.employee_number;

      vr_vendor_site_rec.ACCTS_PAY_CODE_COMBINATION_ID := vn_ACCTS_PAY_CCID;
      vr_vendor_site_rec.PREPAY_CODE_COMBINATION_ID    := vn_PREPAY_CCID;
      vr_vendor_site_rec.ORG_ID           := vn_task_org_projet_id;

      vr_vendor_site_rec.VENDOR_SITE_CODE := gv_vendor_site_code;
      vr_vendor_site_rec.COUNTRY          := gv_vendor_site_ctry;
      vr_vendor_site_rec.ADDRESS_LINE1    := '.';
      vr_vendor_site_rec.PAY_GROUP_LOOKUP_CODE :=   gv_pay_group_lookup_code;
      vr_vendor_site_rec.PAYMENT_PRIORITY := gn_payment_priority;
      vr_vendor_site_rec.TERMS_ID         := gn_term_id;

      vr_vendor_site_rec.INVOICE_CURRENCY_CODE  := vv_currency_code;
      vr_vendor_site_rec.PAYMENT_CURRENCY_CODE  := vv_currency_code;
      vr_vendor_site_rec.PAY_DATE_BASIS_LOOKUP_CODE := gv_pay_date_basis_lookup_code;
      vr_vendor_site_rec.TERMS_DATE_BASIS           := gv_terms_date_basis;
      --vr_vendor_site_rec.ext_payee_rec.default_pmt_method := gv_payment_method_cheque; --On crée le fournisseur avec la methode CHECK
      --                                                                      --qu'on mettra a jour apres le rattachement
      --                                                                      --d'un compte bancaire s'il existe
      vr_vendor_site_rec.Purchasing_site_flag          := 'N';
      vr_vendor_site_rec.pay_site_flag                 := 'Y';
      vr_vendor_site_rec.attention_ar_flag             := 'N';
      vr_vendor_site_rec.rfq_only_site_flag            := 'N';
      vr_vendor_site_rec.always_take_disc_flag         := 'N';
      vr_vendor_site_rec.hold_all_payments_flag        := 'N';
      vr_vendor_site_rec.hold_future_payments_flag     := 'N';
      vr_vendor_site_rec.hold_unmatched_invoices_flag  := 'N';
      vr_vendor_site_rec.exclude_freight_from_discount := 'N';
      vr_vendor_site_rec.auto_tax_calc_flag            := 'Y';
      vr_vendor_site_rec.match_option                  := 'P';

      --///Création du site fournisseur - API
      gv_step  := lv_current_program_unit||' 025 : Création du site fournisseur - API';log_message(gv_step);
      ap_vendor_pub_pkg.create_vendor_site (vn_api_version,
                                            vv_init_msg_list,
                                            vv_commit,
                                            vn_validation_level,
                                            vv_return_status,
                                            vn_msg_count,
                                            vv_msg_data,
                                            vr_vendor_site_rec,
                                            vn_vendor_site_id,
                                            vn_party_site_id,
                                            vn_location_id
                                             );

      IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
        --On continue
        gv_step  := lv_current_program_unit||' 026 : Création du site fournisseur - API : Success';log_message(gv_step);
        NULL;
      ELSE
        vv_message := '';
        IF vn_msg_count > 0 THEN

          FOR v_index IN 1 .. vn_msg_count LOOP
            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
            vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

          END LOOP;

        END IF;

        --Création du site fournisseur impossible : message
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0016',
                                                 'EMPNUM',l_emp.employee_number,
                                                 'MESSAGE',vv_message);
        vv_type     := 'E';
        RAISE e_emp_error;

      END IF;

      --######################################################################################
      --AJOUT DU LOCATION_ID
      --######################################################################################

      gv_step  := lv_current_program_unit||' 026A : Création du LOCATION_ID - API';log_message(gv_step);
      vr_location_rec.country := gv_vendor_site_ctry;
      vr_location_rec.address1 := '.';
      vr_location_rec.created_by_module := 'TCA_V2_API';

      hz_location_v2pub.create_location (p_init_msg_list      => vv_init_msg_list,
                                         p_location_rec       => vr_location_rec,
                                         x_location_id        => vn_location_id,
                                         x_return_status      => vv_return_status,
                                         x_msg_count          => vn_msg_count,
                                         x_msg_data           => vv_msg_data
                                        );
      IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
        --On continue
        gv_step  := lv_current_program_unit||' 026A : Création du LOCATION_ID - API : Success';log_message(gv_step);
        NULL;
      ELSE
        vv_message := '';
        IF vn_msg_count > 0 THEN

          FOR v_index IN 1 .. vn_msg_count LOOP
            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
            vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

          END LOOP;

        END IF;

        --Création du lieu fournisseur impossible : message
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0059',
                                                 'EMPNUM',l_emp.employee_number,
                                                 'MESSAGE',vv_message);
        vv_type     := 'E';
        RAISE e_emp_error;

      END IF;

      gv_step  := lv_current_program_unit||' 026C : Maj du site fournisseur avec LOCATION_ID - API';log_message(gv_step);

      vr_vendor_site_rec                := NULL;
      vr_vendor_site_rec.vendor_id      := vn_vendor_id;
      vr_vendor_site_rec.org_id         := vn_task_org_projet_id;
      vr_vendor_site_rec.vendor_site_id := vn_vendor_site_id;
      vr_vendor_site_rec.location_id    := vn_location_id;

      ap_vendor_pub_pkg.Update_Vendor_Site
                                     (p_api_version          => vn_api_version,
                                      x_return_status        => vv_return_status,
                                      x_msg_count            => vn_msg_count,
                                      x_msg_data             => vv_msg_data,
                                      p_vendor_site_rec      => vr_vendor_site_rec,
                                      p_vendor_site_id       => vn_vendor_site_id
                                     );

      IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
        --On continue
        gv_step  := lv_current_program_unit||' 026C : Maj du site fournisseur avec LOCATION_ID - API : Success';log_message(gv_step);

        NULL;
      ELSE
        vv_message := '';
        IF vn_msg_count > 0 THEN

          FOR v_index IN 1 .. vn_msg_count LOOP
            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
            vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

          END LOOP;

        END IF;

        --Mise a jour du site fournisseur avec LOCATION_ID impossible : message
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0061',
                                                 'EMPNUM',l_emp.employee_number,
                                                 'MESSAGE',vv_message);
        vv_type     := 'E';
        RAISE e_emp_error;

      END IF;

      --######################################################################################
      --CREATION COMPTE BANCAIRE EMPLOYE
      --######################################################################################
      gv_step  := lv_current_program_unit||' 027 : Creation compte bancaire employe';log_message(gv_step);

      BEGIN
        SELECT *
        INTO l_bank
        FROM
         XXEAI_HR_BANK_INT_ALL HBI
        WHERE
             HBI.INSERT_UPDATE_FLAG = 'I'
         AND HBI.INTERFACE_STATUS != 'ERROR'
         AND HBI.EMPLOYEE_NUMBER = vv_emp_num
        ;

        vb_info_bank := TRUE;

      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        --Pas d'info bank
        vb_info_bank := false;
       WHEN TOO_MANY_ROWS THEN
        --Création de l'employé impossible : Doublon dans les infos bank
        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0017','EMPNUM',l_emp.EMPLOYEE_NUMBER);
        vv_type     := 'E';
        raise e_emp_error;
      END;

      IF vb_info_bank THEN
        BEGIN
          gv_step  := lv_current_program_unit||' 028 : Info bancaire présente';log_message(gv_step);

          --Init pour message
          vv_table    := 'XXEAI_HR_BANK_INT_ALL';
          vn_table_id := l_bank.XXEAI_BANK_ID ;


          --Existence BANQUE/AGENCE
          gv_step  := lv_current_program_unit||' 029 : Existence BANQUE/AGENCE';log_message(gv_step);
          get_bank_info ( pv_bank_number   => l_bank.bank_number,
                          pv_branch_number => l_bank.bank_num,
                          pn_bank_id       => vn_bank_id,
                          pn_branch_id     => vn_branch_id
                              );

          IF vn_bank_id IS NULL THEN
            --Création de l'employé impossible :La banque n'existe pas ou est inactive
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0018',
                                                     'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                     'BANKNUM',l_bank.bank_number,
                                                     'BRANCHNUM',l_bank.bank_num);
            vv_type     := 'E';

            --raise e_emp_error;
            raise e_continue; --on ne stoppe plus la création

          END IF;

          --Existence du compte bancaire
          gv_step  := lv_current_program_unit||' 030 : compte bancaire';log_message(gv_step);
          get_info_compte_bank(pn_bank_id       => vn_bank_id,
                               pn_branch_id     => vn_branch_id,
                               pv_iban          => l_bank.iban_number,
                               pv_country       => l_bank.bank_branch_country,
                               pv_type          => 'SUPPLIER',
                               pn_bank_acct_id  => vn_bank_acct_id);


          IF vn_bank_acct_id IS NULL THEN
            --Création du compte bancaire
            gv_step  := lv_current_program_unit||' 031 : Création du compte bancaire';log_message(gv_step);

            vr_ext_bank_acct_rec.object_version_number    := 1.0;
            vr_ext_bank_acct_rec.acct_owner_party_id      := vn_party_id; --site

            vr_ext_bank_acct_rec.bank_account_name        := l_bank.bank_account_name;
            vr_ext_bank_acct_rec.bank_account_num         := l_bank.bank_account_num;

            vr_ext_bank_acct_rec.alternate_acct_name      := NULL;
            vr_ext_bank_acct_rec.bank_id                  := vn_bank_id ;
            vr_ext_bank_acct_rec.branch_id                := vn_branch_id ;
            vr_ext_bank_acct_rec.start_date               := TRUNC(SYSDATE);
            vr_ext_bank_acct_rec.country_code             := gv_vendor_site_ctry;
            vr_ext_bank_acct_rec.currency                 := vv_currency_code;
            vr_ext_bank_acct_rec.iban                     := l_bank.iban_number;
            vr_ext_bank_acct_rec.acct_type                := 'SUPPLIER';

            --Init valeur API
            vn_api_version       := 1.0;
            vv_init_msg_list     := FND_API.G_TRUE;
            vv_commit            := FND_API.G_FALSE;
            vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
            vv_return_status     := NULL;
            vn_msg_count         := NULL;
            vv_msg_data          := NULL;
            vv_association_level := 'SS';
            vv_org_type          := 'OPERATING_UNIT';

            --Création COMPTE
            gv_step  := lv_current_program_unit||' 032 : Création du compte bancaire - API';log_message(gv_step);
            IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT (p_api_version            => vn_api_version,
                                                       p_init_msg_list          => vv_init_msg_list,
                                                       p_ext_bank_acct_rec      => vr_ext_bank_acct_rec,
                                                       p_association_level      => vv_association_level,
                                                       p_supplier_site_id       => vn_vendor_site_id,
                                                       p_party_site_id          => NULL,
                                                       p_org_id                 => vn_task_org_projet_id,
                                                       p_org_type               => vv_org_type,
                                                       x_acct_id                => vn_acct_id,
                                                       x_return_status          => vv_return_status,
                                                       x_msg_count              => vn_msg_count,
                                                       x_msg_data               => vv_msg_data,
                                                       x_response               => vr_response
                                                      );

            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              gv_step  := lv_current_program_unit||' 033 : Création du compte bancaire - API : Success';log_message(gv_step);

              vn_bank_acct_id:= vn_acct_id;

              NULL;
            ELSE
              vv_message := '';
              IF fnd_msg_pub.count_msg > 0 THEN

                FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                  vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                END LOOP;

              END IF;

              --Création du compte bancaire impossible : message
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0019',
                                                       'EMPNUM',l_emp.employee_number,
                                                       'IBAN',l_bank.iban_number,
                                                       'MESSAGE',substr(vv_message,1,500));
              vv_type     := 'E';

              --raise e_emp_error;
              raise e_continue; --on ne stoppe plus la création

            END IF;

          ELSE
            gv_step  := lv_current_program_unit||' 034 : Rattachement du compte bancaire : '||vn_bank_acct_id;log_message(gv_step);


            vn_api_version       := 1.0;
            vv_init_msg_list     := FND_API.G_TRUE;
            vv_commit            := FND_API.G_FALSE;
            vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
            vv_return_status     := NULL;
            vn_msg_count         := NULL;
            vv_msg_data          := NULL;

            --Rattachement du compte bancaire
            gv_step  := lv_current_program_unit||' 035 : Controle proprietaire compte bancaire - API';log_message(gv_step);
            IBY_EXT_BANKACCT_PUB.check_bank_acct_owner   (p_api_version         => vn_api_version,
                                                          p_init_msg_list       => FND_API.G_TRUE,
                                                          p_bank_acct_id        => vn_bank_acct_id,
                                                          p_acct_owner_party_id => vn_party_id,  --site
                                                          x_return_status       => vv_return_status,
                                                          x_msg_count           => vn_msg_count,
                                                          x_msg_data            => vv_msg_data,
                                                          x_response            => vr_response
                                                          );

            IF  vv_return_status <> 'S' THEN
              gv_step  := lv_current_program_unit||' 036 : Controle proprietaire compte bancaire KO';log_message(gv_step);


              vn_api_version       := 1.0;
              vv_init_msg_list     := FND_API.G_TRUE;
              vv_commit            := FND_API.G_FALSE;
              vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
              vv_return_status     := NULL;
              vn_msg_count         := NULL;
              vv_msg_data          := NULL;

              vn_joint_acct_id     := NULL;

              gv_step  := lv_current_program_unit||' 037 : liaison compte bancaire - API';log_message(gv_step);
              IBY_EXT_BANKACCT_PUB.add_joint_account_owner( p_api_version         => vn_api_version,
                                                            p_init_msg_list       => vv_init_msg_list,
                                                            p_bank_account_id     => vn_bank_acct_id,
                                                            p_acct_owner_party_id => vn_party_id,    --site
                                                            x_joint_acct_owner_id => vn_joint_acct_id,
                                                            x_return_status       => vv_return_status,
                                                            x_msg_count           => vn_msg_count,
                                                            x_msg_data            => vv_msg_data,
                                                            x_response            => vr_response
                                                           );

              IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                --On continue
                gv_step  := lv_current_program_unit||' 038 : liaison compte bancaire - API : Success';log_message(gv_step);
                NULL;
              ELSE
                vv_message := '';
                IF fnd_msg_pub.count_msg > 0 THEN

                  FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                    vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                  END LOOP;

                END IF;

                --Rattachement du compte bancaire impossible : message
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0020',
                                                         'EMPNUM',l_emp.employee_number,
                                                         'IBAN',l_bank.iban_number,
                                                         'MESSAGE',substr(vv_message,1,500));
                vv_type     := 'E';

                --raise e_emp_error;
                raise e_continue; --on ne stoppe plus la création

              END IF;

            ELSE

              --Cet employé est déja propriétaire de son compte bancaire
              gv_step  := lv_current_program_unit||' 039 : Controle proprietaire compte bancaire OK';log_message(gv_step);
              NULL;

            END IF;

          END IF; --vn_bank_acct_id IS NULL

          --//Finalisation lien site - employé
          gv_step  := lv_current_program_unit||' 040 : Finalisation lien site - employé';log_message(gv_step);

          vn_api_version       := 1.0;
          vv_init_msg_list     := FND_API.G_TRUE;
          vv_commit            := FND_API.G_FALSE;
          vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
          vv_return_status     := NULL;
          vn_msg_count         := NULL;
          vv_msg_data          := NULL;

          vr_payee_context_rec.Party_Id                     := vn_party_id;
          vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
          vr_payee_context_rec.party_site_id                := vn_party_site_id;
          vr_payee_context_rec.Supplier_Site_id             := vn_vendor_site_id;
          vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
          vr_payee_context_rec.Org_Id                       := vn_task_org_projet_id;

          vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
          vr_assignment_attribs.instrument.instrument_id    := vn_bank_acct_id;
          vr_assignment_attribs.start_date                  := TRUNC(SYSDATE);

          -- map account to site supplier
          gv_step  := lv_current_program_unit||' 040 : Finalisation lien site - employé - API';log_message(gv_step);
          IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => vn_api_version,
                                                                 p_init_msg_list      => vv_init_msg_list,
                                                                 p_commit             => vv_commit,
                                                                 x_return_status      => vv_return_status,
                                                                 x_msg_count          => vn_msg_count,
                                                                 x_msg_data           => vv_msg_data,
                                                                 p_payee              => vr_payee_context_rec,
                                                                 p_assignment_attribs => vr_assignment_attribs,
                                                                 x_assign_id          => vn_assign_id,
                                                                 x_response           => vr_response
                                                                 );

          IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
            --On continue
            gv_step  := lv_current_program_unit||' 040 : Finalisation lien site - employé - API : Success';log_message(gv_step);
            NULL;
          ELSE
            vv_message := '';
            IF fnd_msg_pub.count_msg > 0 THEN

              FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
              END LOOP;

            END IF;

            --Rattachement du compte bancaire au site employé impossible : message
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0021',
                                                     'EMPNUM',l_emp.employee_number,
                                                     'IBAN',l_bank.iban_number,
                                                     'MESSAGE',substr(vv_message,1,500));
            vv_type     := 'E';

            --raise e_emp_error;
            raise e_continue; --on ne stoppe plus la création

          END IF;

          gv_step  := lv_current_program_unit||' 041 : Mode de reglement = EFT';log_message(gv_step);
          vv_payment_method := gv_payment_method_virement;

          EXCEPTION
           WHEN e_continue THEN
            gv_step  := lv_current_program_unit||' 042 : On continue suite a l''étape : '||gv_step;log_message(gv_step);
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            NULL;
          END;

      ELSE --vb_info_bank
        --Pas d'information banque
        gv_step  := lv_current_program_unit||' 043 : Pas d''information banque';log_message(gv_step);
        gv_step  := lv_current_program_unit||' 043 : Mode de reglement = CHECK';log_message(gv_step);
        vv_payment_method := gv_payment_method_cheque;
      END IF;

      BEGIN
        --Modification site fournisseur
        gv_step  := lv_current_program_unit||' 044 : Modification site fournisseur : EFT / CHECK';log_message(gv_step);

        vn_api_version      := 1.0;
        vv_init_msg_list    := FND_API.G_TRUE;
        vv_commit           := FND_API.G_FALSE;
        vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
        vv_return_status    := NULL;
        vn_msg_count        := NULL;
        vv_msg_data         := NULL;

        vn_ext_payee_id := NULL;
        vt_External_Payee_Tab_Type.DELETE;
        vt_Ext_Payee_ID_Tab_Type.DELETE;
        vt_Ext_Payee_Update_Tab_Type.DELETE;
        vt_Ext_Payee_Create_Tab_Type.DELETE;

        BEGIN

          SELECT
               payee.EXT_PAYEE_ID,
               payee.payee_party_id,
               payee.PAYMENT_FUNCTION,
               payee.ORG_ID,
               payee.org_type,
               payee.SUPPLIER_SITE_ID,
               assa.party_site_id
          INTO
               vn_ext_payee_id,
               vr_External_Payee_Rec.payee_party_id,
               vr_External_Payee_Rec.payment_function,
               vr_External_Payee_Rec.payer_org_id,
               vr_External_Payee_Rec.payer_org_type,
               vr_External_Payee_Rec.supplier_site_id,
               vr_External_Payee_Rec.Payee_Party_Site_Id
          FROM iby_external_payees_all  payee,
               ap_supplier_sites_all    assa
         WHERE payee.payment_function = 'PAYABLES_DISB'
           AND payee.supplier_site_id = vn_vendor_site_id
           AND payee.supplier_site_id = assa.vendor_site_id;

        EXCEPTION
         WHEN TOO_MANY_ROWS THEN
          BEGIN
            SELECT
                 payee.EXT_PAYEE_ID,
                 payee.payee_party_id,
                 payee.PAYMENT_FUNCTION,
                 payee.ORG_ID,
                 payee.org_type,
                 payee.SUPPLIER_SITE_ID,
                 assa.party_site_id
            INTO
                 vn_ext_payee_id,
                 vr_External_Payee_Rec.payee_party_id,
                 vr_External_Payee_Rec.payment_function,
                 vr_External_Payee_Rec.payer_org_id,
                 vr_External_Payee_Rec.payer_org_type,
                 vr_External_Payee_Rec.supplier_site_id,
                 vr_External_Payee_Rec.Payee_Party_Site_Id
            FROM iby_external_payees_all  payee,
                 ap_supplier_sites_all    assa
           WHERE payee.payment_function = 'PAYABLES_DISB'
             AND payee.supplier_site_id = vn_vendor_site_id
             AND payee.supplier_site_id = assa.vendor_site_id
             AND (payee.party_site_id = assa.party_site_id or payee.party_site_id is null)
             AND payee.EXT_PAYEE_ID = (select max(iep.EXT_PAYEE_ID)
                                       from iby_external_payees_all iep
                                       where iep.supplier_site_id = vn_vendor_site_id)
              ;
          EXCEPTION
           WHEN OTHERS THEN
            --Modification de la methode de paiement du site fournisseur impossible : message
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0022',
                                                     'EMPNUM',l_emp.employee_number,
                                                     'MESSAGE','Erreur lors de la recherche des informations bancaires (TOO_MANY_ROWS) :'||SQLERRM);
            vv_type     := 'E';
            RAISE e_emp_error;
          END;
         WHEN OTHERS THEN
          --Modification de la methode de paiement du site fournisseur impossible : message
          vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0022',
                                                   'EMPNUM',l_emp.employee_number,
                                                   'MESSAGE','Erreur lors de la recherche des informations bancaires (OTHERS) :'||SQLERRM);
          vv_type     := 'E';
          RAISE e_emp_error;
        END;

        vr_External_Payee_Rec.default_pmt_method  := vv_payment_method;
        vr_External_Payee_Rec.exclusive_pay_flag  := 'N';

        vt_External_Payee_Tab_Type(1):= vr_External_Payee_Rec;

        IF vv_payment_method =  gv_payment_method_cheque THEN
          --CHECK CREATION
          gv_step  := lv_current_program_unit||' 045 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee - API';log_message(gv_step);
          IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee(p_api_version           => vn_api_version,
                                                           p_init_msg_list         => vv_init_msg_list,
                                                           p_ext_payee_tab         => vt_External_Payee_Tab_Type,
                                                           x_return_status         => vv_return_status,
                                                           x_msg_count             => vn_msg_count,
                                                           x_msg_data              => vv_msg_data,
                                                           x_ext_payee_id_tab      => vt_Ext_Payee_ID_Tab_Type,
                                                           x_ext_payee_status_tab  => vt_Ext_Payee_Create_Tab_Type
                                                        );

          IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
            --On continue
            gv_step  := lv_current_program_unit||' 045 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee - API : Success';log_message(gv_step);
            NULL;
          ELSE
            vv_message := '';
            IF vn_msg_count > 0 THEN

              FOR v_index IN 1 .. vn_msg_count LOOP
                fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

              END LOOP;

            END IF;

            --Error Message from table type
            IF vt_Ext_Payee_Create_Tab_Type.count > 0 THEN
              FOR j IN vt_Ext_Payee_Create_Tab_Type.FIRST .. vt_Ext_Payee_Create_Tab_Type.LAST LOOP
                vv_message := substr(vv_message || chr(10) ||  vt_Ext_Payee_Create_Tab_Type (j).Payee_Creation_Msg,1,500);
              END LOOP;
            END IF;

            --Modification de la methode de paiement du site fournisseur impossible : message
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0022',
                                                     'EMPNUM',l_emp.employee_number,
                                                     'MESSAGE',vv_message);
            vv_type     := 'E';
            RAISE e_emp_error;

          END IF;

        ELSIF vv_payment_method =  gv_payment_method_virement THEN
          --EFT - UPDATE
          vt_Ext_Payee_ID_Tab_Type(1).ext_payee_id := vn_ext_payee_id;


          gv_step  := lv_current_program_unit||' 045 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API';log_message(gv_step);
          IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee(p_api_version           => vn_api_version,
                                                           p_init_msg_list         => vv_init_msg_list,
                                                           p_ext_payee_tab         => vt_External_Payee_Tab_Type,
                                                           p_ext_payee_id_tab      => vt_Ext_Payee_ID_Tab_Type,
                                                           x_return_status         => vv_return_status,
                                                           x_msg_count             => vn_msg_count,
                                                           x_msg_data              => vv_msg_data,
                                                           x_ext_payee_status_tab  => vt_Ext_Payee_Update_Tab_Type
                                                        );



          IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
            --On continue
            gv_step  := lv_current_program_unit||' 045 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API : Success';log_message(gv_step);
            NULL;
          ELSE
            vv_message := '';
            IF vn_msg_count > 0 THEN

              FOR v_index IN 1 .. vn_msg_count LOOP
                fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

              END LOOP;

            END IF;

            --Error Message from table type
            IF vt_Ext_Payee_Update_Tab_Type.count > 0 THEN
              FOR j IN vt_Ext_Payee_Update_Tab_Type.FIRST .. vt_Ext_Payee_Update_Tab_Type.LAST LOOP
                vv_message := substr(vv_message || chr(10) ||  vt_Ext_Payee_Update_Tab_Type (j).payee_update_msg,1,500);
              END LOOP;
            END IF;

            --Modification de la methode de paiement du site fournisseur impossible : message
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0022',
                                                     'EMPNUM',l_emp.employee_number,
                                                     'MESSAGE',vv_message);
            vv_type     := 'E';
            RAISE e_emp_error;

          END IF;
        END IF; --vv_payment_method

      EXCEPTION
       WHEN e_continue THEN
        gv_step  := lv_current_program_unit||' 046 : On continue suite a l''étape : '||gv_step;log_message(gv_step);
        insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
        NULL;
      END;

      --///FIN CREATION COMMIT!!!
      gv_step  := lv_current_program_unit||' 099 : COMMIT CREATION EMPLOYE ';log_message(gv_step);

      insert_error(vv_emp_num,'XXEAI_HR_PEOPLE_INT',l_emp.XXEAI_PERSON_ID,'S',
                   'Création employé complet : '||vv_emp_num||' avec succes',gv_step,vv_source);

      flag_traite(pv_employee_number    => vv_emp_num,
                  pv_insert_update_flag => 'I',
                  pv_source             => vv_source);

      COMMIT;


      EXCEPTION
        WHEN e_emp_error THEN
          gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
          insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
          ROLLBACK;
          --Suivant
        WHEN OTHERS THEN
          vv_type     := 'E';

          gv_step  := lv_current_program_unit||' EEE : EXCEPTION OTHERS gv_step :'||gv_step||chr(10)||SQLERRM;
          vv_message := gv_step;

          log_message(gv_step);
          insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
          ROLLBACK;
          --Suivant
      END;


   --KDFI-2084 ARA


   IF l_emp.EFFECTIVE_START_DATE > SYSDATE THEN
   gv_step  := lv_current_program_unit||' : la mise à jour de la date de début pour l''employé : ' || l_emp.employee_number ;log_message(gv_step);

   BEGIN

     update PER_PERIODS_OF_SERVICE
     set DATE_START = l_emp.EFFECTIVE_START_DATE
     WHERE person_id = (
             select PERSON_ID from PER_ALL_PEOPLE_F where EMPLOYEE_NUMBER = l_emp.employee_number
     );

     update PER_ALL_PEOPLE_F
     set EFFECTIVE_START_DATE = l_emp.EFFECTIVE_START_DATE,
     START_DATE = l_emp.EFFECTIVE_START_DATE
     ,ORIGINAL_DATE_OF_HIRE = l_emp.EFFECTIVE_START_DATE
     where EMPLOYEE_NUMBER = l_emp.employee_number;

     update PER_ALL_ASSIGNMENTS_F
     set EFFECTIVE_START_DATE = l_emp.EFFECTIVE_START_DATE
     where PERSON_ID = (
     select PERSON_ID from PER_ALL_PEOPLE_F where EMPLOYEE_NUMBER = l_emp.employee_number
     );

   update PER_ADDRESSES
     set DATE_FROM = l_emp.EFFECTIVE_START_DATE
     where PERSON_ID = (
     select PERSON_ID from PER_ALL_PEOPLE_F where EMPLOYEE_NUMBER = l_emp.employee_number
     );

   COMMIT;

   END;

   END IF;

    END LOOP; --lt_global

   END IF;

   gv_step  := lv_current_program_unit||' 999 : FIN';
   log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    ROLLBACK;
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    log_message(pv_errbuf,'Y');
    pn_retcode := 2;
  END creation_employe;

  -----------------------------------------------------------------
  --  Nom           : maj_employe
  --  Description   : procedure de mise a jour des employes
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE maj_employe(pv_errbuf        OUT NOCOPY VARCHAR2,
                        pn_retcode       OUT NOCOPY NUMBER) IS

    lv_current_program_unit  VARCHAR2(30) := 'maj_employe';

    CURSOR C_EMPLOYE_REF IS
     SELECT employee_number
     FROM XXEAI_HR_PEOPLE_INT HPI
     WHERE
      HPI.INSERT_UPDATE_FLAG = 'U'
      AND HPI.INTERFACE_STATUS != 'ERROR'
      AND SOURCE = gv_source_employe;

    CURSOR C_EMPLOYE_SESAME IS
     SELECT employee_number
     FROM XXEAI_HR_PEOPLE_INT HPI
     WHERE
      HPI.INSERT_UPDATE_FLAG = 'U'
      AND HPI.INTERFACE_STATUS != 'ERROR'
      AND SOURCE = gv_source_contact;

    CURSOR C_EMPLOYE_IN_OUT IS
     SELECT employee_number
     FROM XXEAI_HR_PEOPLE_INT HPI
     WHERE
      HPI.INSERT_UPDATE_FLAG = 'U'
      AND HPI.INTERFACE_STATUS != 'ERROR'
      AND SOURCE = gv_source_employe;

    --YWA EDB072
    CURSOR C_BANK_ONLY IS
    SELECT *
    FROM XXEAI_HR_BANK_INT_ALL HBI
    WHERE NOT EXISTS
      (SELECT *
      FROM XXEAI_HR_PEOPLE_INT HPI
      WHERE HPI.EMPLOYEE_NUMBER=HBI.EMPLOYEE_NUMBER
      --AND source = gv_source_employe
      --AND HPI.INTERFACE_STATUS != 'ERROR'
      )
    AND HBI.INSERT_UPDATE_FLAG = 'U'
    --AND HBI.INTERFACE_STATUS != 'ERROR';
    ;
    TYPE t_employe IS TABLE OF XXEAI_HR_PEOPLE_INT.employee_number%Type index by binary_integer;
    lt_employe t_employe;

    l_emp        XXEAI_HR_PEOPLE_INT%ROWTYPE;
    l_assignment XXEAI_HR_ASSIGNMENT_INT%ROWTYPE;
    l_bank       XXEAI_HR_BANK_INT_ALL%ROWTYPE;

    e_emp_error EXCEPTION;
    e_bankacc_error EXCEPTION;
    vv_message  VARCHAR2(500);
    vv_emp_num  VARCHAR2(50);
    vv_table    VARCHAR2(30);
    vn_table_id NUMBER;
    vv_type     varchar2(10);
    vv_source   varchar2(30);

    vv_errbuf               VARCHAR2(500);
    vn_retcode              NUMBER;

    --EMPLOYE
    vn_person_id                    number;
    vn_per_object_version_number    number;
    vd_per_effective_start_date     date;
    vd_per_effective_end_date       date;
    vv_full_name                    varchar2(500);
    vn_per_comment_id               number;
    vb_name_combination_warning     boolean;
    vb_assign_payroll_warning       boolean;
    vb_orig_hire_warning            boolean;
    vr_person_row                   per_all_people_f%ROWTYPE;

    --VENDOR
    vr_vendor_rec         ap_vendor_pub_pkg.r_vendor_rec_type;
    vn_vendor_id          NUMBER;
    vn_party_id           NUMBER;

    --VENDOR SITE
    vr_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_vendor_site_id     NUMBER;
    vn_party_site_id      NUMBER;
    vn_location_id        NUMBER;
    vv_calling_prog      VARCHAR2(200);

    vn_PREPAY_CCID    gl_code_combinations.code_combination_id%TYPE;
    vn_ACCTS_PAY_CCID gl_code_combinations.code_combination_id%TYPE;

    --LOCATION ID
    vr_location_rec hz_location_v2pub.location_rec_type;
    vr_party_site_rec  hz_party_site_v2pub.party_site_rec_type;
    vv_party_site_number VARCHAR2 (2000);

    --BANK
    vb_info_bank           BOOLEAN;
    vr_ext_bank_acct_rec   iby_ext_bankacct_pub.extbankacct_rec_type;
    vn_bank_id             NUMBER;
    vn_branch_id           NUMBER;
    vn_bank_acct_id        NUMBER;
    vn_exist_bank_acct_id  NUMBER;
    vn_bk_object_version_number NUMBER;
    vd_bk_start_date       date;
    vv_association_level   VARCHAR2(50);
    vn_acct_id             NUMBER;
    vn_joint_acct_id       NUMBER;
    vr_response            iby_fndcpt_common_pub.result_rec_type;
    vv_org_type            VARCHAR2(50);

    vn_assign_id           NUMBER ;
    vr_payee_context_rec  IBY_DISBURSEMENT_SETUP_PUB.PayeeContext_rec_type;
    vr_assignment_attribs IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_rec_type;

    --AFFECTATION
    vv_ne_rien_faire        BOOLEAN;
    vv_task_number          pa_tasks.task_number%TYPE;
    vv_task_id              pa_tasks.task_id%TYPE;
    vn_task_project_id      pa_projects_all.project_id%TYPE;
    vv_task_project_name    pa_projects_all.segment1%TYPE;
    vv_task_project_type    pa_projects_all.project_type%TYPE;
    vd_task_start_date      DATE;
    vd_task_completion_date DATE;
    vd_task_closed_date     DATE;
    vv_task_org_projet      hr_all_organization_units.name%TYPE;
    vn_task_org_projet_id   hr_all_organization_units.organization_id%TYPE;
    vv_task_societe         VARCHAR2(10);
    vv_task_region          VARCHAR2(10);
    vv_task_org_fin         hr_all_organization_units.name%TYPE;
    vn_task_org_fin_id      hr_all_organization_units.organization_id%TYPE;

    vn_superviseur          NUMBER;
    vn_sup_hierar           NUMBER;
    vn_people_group_id      NUMBER;

    vv_new_task_id              pa_tasks.task_id%TYPE;
    vn_new_task_project_id      pa_projects_all.project_id%TYPE;
    vv_new_task_project_name    pa_projects_all.segment1%TYPE;
    vv_new_task_project_type    pa_projects_all.project_type%TYPE;
    vd_new_task_start_date      DATE;
    vd_new_task_completion_date DATE;
    vd_new_task_closed_date     DATE;
    vv_new_task_org_projet      hr_all_organization_units.name%TYPE;
    vn_new_task_org_projet_id   hr_all_organization_units.organization_id%TYPE;
    vv_new_task_societe         VARCHAR2(10);
    vv_new_task_region          VARCHAR2(10);
    vv_new_task_org_fin         hr_all_organization_units.name%TYPE;
    vn_new_task_org_fin_id      hr_all_organization_units.organization_id%TYPE;

    vn_assignment_id       per_all_assignments_f.assignment_id%TYPE;
    vn_asg_object_version_number number;
    vd_ass_start_date      per_all_assignments_f.effective_start_date%TYPE;
    vd_ass_end_date        per_all_assignments_f.effective_end_date%TYPE;
    vn_job_id              per_all_assignments_f.job_id%TYPE;
    vn_job_id_new          per_all_assignments_f.job_id%TYPE;
    vv_job_name            per_jobs.name%TYPE;
    vv_fct                 per_jobs.name%TYPE;
    vn_organization_id     hr_all_organization_units.organization_id%TYPE;
    vv_organization_name   hr_all_organization_units.name%TYPE;
    vn_supervisor_id       per_all_assignments_f.supervisor_id%TYPE;
    vv_ass_attribute1      per_all_assignments_f.ass_attribute1%TYPE;
    vv_ass_attribute2      per_all_assignments_f.ass_attribute2%TYPE;
    vv_ass_attribute3      per_all_assignments_f.ass_attribute3%TYPE;
    vv_ass_attribute4      per_all_assignments_f.ass_attribute4%TYPE;
    vv_ass_attribute5      per_all_assignments_f.ass_attribute5%TYPE;

    vn_ledger_id            gl_ledgers.ledger_id%TYPE;
    vv_currency_code        ap_suppliers.invoice_currency_code%TYPE;

    vd_def_ass_effective_date DATE;
    vn_def_task_org_fin_id    NUMBER;

    vv_period_name          gl_period_statuses.period_name%TYPE;
    vd_period_start_date    gl_period_statuses.start_date%TYPE;
    vd_period_end_date      gl_period_statuses.end_date%TYPE;

    --API
    vb_update_change_insert BOOLEAN;
    vb_correction      BOOLEAN;
    vb_update          BOOLEAN;
    vb_update_override BOOLEAN;
    vv_dt_ud_mode      VARCHAR2(100);

    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2 (200);
    vv_commit             VARCHAR2 (200);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2 (200);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2 (4000);
    VN_MSG_INDEX_OUT      NUMBER;

    vn_soft_coding_keyflex_id  HR_SOFT_CODING_KEYFLEX.SOFT_CODING_KEYFLEX_ID%TYPE;
    vc_concatenated_segments   hr_soft_coding_keyflex.concatenated_segments%TYPE;
    vn_comment_id              PER_ALL_ASSIGNMENTS_F.COMMENT_ID%TYPE;
    vb_no_managers_warning     BOOLEAN;
    vb_other_manager_warning   BOOLEAN;
    vd_effective_start_date    DATE;
    vd_effective_end_date      DATE;
    vn_special_ceiling_step_id NUMBER;
    vc_group_name                  VARCHAR2(500);
    vb_org_now_no_manager_warning  BOOLEAN;
    vb_spp_delete_warning          BOOLEAN;
    vc_entries_changed_warning     VARCHAR2(500);
    vb_tax_district_changed_warn   BOOLEAN;

    --MAJ BANQUE
    vn_ext_payee_id               iby_external_payees_all.EXT_PAYEE_ID%TYPE;
    vt_External_Payee_Tab_Type    IBY_DISBURSEMENT_SETUP_PUB.External_Payee_Tab_Type;
    vt_Ext_Payee_ID_Tab_Type      IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_ID_Tab_Type;
    vt_Ext_Payee_Create_Tab_Type  IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_Create_Tab_Type;
    vt_Ext_Payee_Update_Tab_Type  IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_Update_Tab_Type;
    vr_External_Payee_Rec         IBY_DISBURSEMENT_SETUP_PUB.External_Payee_Rec_Type;

    vv_payment_method             ap_suppliers.payment_method_lookup_code%TYPE;
    vv_bank_acc_num      VARCHAR2(50);
    vn_party_id_old                   NUMBER;
    vn_vendor_site_id_old             NUMBER;
    vn_exist_bank_acct_id_old         NUMBER;
    vd_bk_start_date_old              DATE;
    vn_bk_object_version_number_od   NUMBER;
    vn_bank_acct_id_old   NUMBER;
    vn_party_site_id_old  NUMBER;

    vn_vendor_id_old   NUMBER;
    vvn_vendor_id    NUMBER;
    vvn_party_id  NUMBER;
    l_effective_date DATE;
  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    --BOUCLE POUR CHAQUE EMPLOYE REF
    gv_step  := lv_current_program_unit||' 001 : initialisation pour boucle : C_EMPLOYE_REF';log_message(gv_step);
    OPEN  C_EMPLOYE_REF;
    FETCH C_EMPLOYE_REF BULK COLLECT INTO lt_employe;
    CLOSE C_EMPLOYE_REF;

    IF lt_employe.COUNT > 0 THEN
      FOR i in lt_employe.FIRST..lt_employe.LAST LOOP
        BEGIN
          gv_step  := lv_current_program_unit||' 002 : sélection de l''employé : '||lt_employe(i);log_message(gv_step);

          --REINIT VARIABLE
          gv_step  := lv_current_program_unit||' 003 :Reinit variable ';log_message(gv_step);
          vv_emp_num := lt_employe(i);

          --EMPLOYE
          vn_person_id                    := NULL;
          vn_per_object_version_number    := NULL;
          vd_per_effective_start_date     := NULL;
          vd_per_effective_end_date       := NULL;
          vv_full_name                    := NULL;
          vn_per_comment_id               := NULL;
          vb_name_combination_warning     := NULL;
          vb_assign_payroll_warning       := NULL;
          vb_orig_hire_warning            := NULL;
          vr_person_row                   := NULL;

          --VENDOR
          vr_vendor_rec         := NULL;
          vn_vendor_id          := NULL;
          vn_party_id           := NULL;

          --VENDOR SITE
          vr_vendor_site_rec    := NULL;
          vn_vendor_site_id     := NULL;
          vn_party_site_id      := NULL;
          vn_location_id        := NULL;
          vv_calling_prog       := NULL;

          vn_PREPAY_CCID    := NULL;
          vn_ACCTS_PAY_CCID := NULL;

          vr_location_rec      := NULL;
          vr_party_site_rec    := NULL;
          vv_party_site_number := NULL;


          --BANK
          vb_info_bank           := NULL;
          vr_ext_bank_acct_rec   := NULL;
          vn_bank_id             := NULL;
          vn_branch_id           := NULL;
          vn_bank_acct_id        := NULL;
          vn_exist_bank_acct_id  := NULL;
          vn_bk_object_version_number := NULL;
          vd_bk_start_date       := NULL;
          vv_association_level   := NULL;
          vn_acct_id             := NULL;
          vn_joint_acct_id       := NULL;
          vr_response            := NULL;
          vv_org_type            := NULL;

          vn_assign_id           := NULL;
          vr_payee_context_rec   := NULL;
          vr_assignment_attribs  := NULL;

          --AFFECTATION
          vv_ne_rien_faire        := FALSE;
          vv_task_number          := NULL;
          vv_task_id              := NULL;
          vn_task_project_id      := NULL;
          vv_task_project_name    := NULL;
          vv_task_project_type    := NULL;
          vd_task_start_date      := NULL;
          vd_task_completion_date := NULL;
          vd_task_closed_date     := NULL;
          vv_task_org_projet      := NULL;
          vn_task_org_projet_id   := NULL;
          vv_task_societe         := NULL;
          vv_task_region          := NULL;
          vv_task_org_fin         := NULL;
          vn_task_org_fin_id      := NULL;

          vn_superviseur          := NULL;
          vn_sup_hierar           := NULL;
          vn_people_group_id      := NULL;

          vv_new_task_id              := NULL;
          vn_new_task_project_id      := NULL;
          vv_new_task_project_name    := NULL;
          vv_new_task_project_type    := NULL;
          vd_new_task_start_date      := NULL;
          vd_new_task_completion_date := NULL;
          vd_new_task_closed_date     := NULL;
          vv_new_task_org_projet      := NULL;
          vn_new_task_org_projet_id   := NULL;
          vv_new_task_societe         := NULL;
          vv_new_task_region          := NULL;
          vv_new_task_org_fin         := NULL;
          vn_new_task_org_fin_id      := NULL;

          vn_assignment_id             := NULL;
          vn_asg_object_version_number := NULL;
          vd_ass_start_date            := NULL;
          vd_ass_end_date              := NULL;
          vn_job_id                    := NULL;
          vv_job_name                  := NULL;
          vv_fct                       := NULL;
          vn_organization_id           := NULL;
          vv_organization_name         := NULL;
          vn_supervisor_id             := NULL;
          vv_ass_attribute1            := NULL;
          vv_ass_attribute2            := NULL;
          vv_ass_attribute3            := NULL;
          vv_ass_attribute4            := NULL;
          vv_ass_attribute5            := NULL;

          vn_ledger_id            := NULL;
          vv_currency_code        := NULL;

          vd_def_ass_effective_date := NULL;
          vn_def_task_org_fin_id    := NULL;

          vv_period_name          := NULL;
          vd_period_start_date    := NULL;
          vd_period_end_date      := NULL;

          --API
          vb_update_change_insert := NULL;
          vb_correction           := NULL;
          vb_update               := NULL;
          vb_update_override      := NULL;
          vv_dt_ud_mode           := NULL;

          vn_api_version        := NULL;
          vv_init_msg_list      := NULL;
          vv_commit             := NULL;
          vn_validation_level   := NULL;
          vv_return_status      := NULL;
          vn_msg_count          := NULL;
          vv_msg_data           := NULL;
          VN_MSG_INDEX_OUT      := NULL;

          vn_soft_coding_keyflex_id  := NULL;
          vc_concatenated_segments   := NULL;
          vn_comment_id              := NULL;
          vb_no_managers_warning     := NULL;
          vb_other_manager_warning   := NULL;
          vd_effective_start_date    := NULL;
          vd_effective_end_date      := NULL;
          vn_special_ceiling_step_id := NULL;
          vc_group_name                  := NULL;
          vb_org_now_no_manager_warning  := NULL;
          vb_spp_delete_warning          := NULL;
          vc_entries_changed_warning     := NULL;
          vb_tax_district_changed_warn   := NULL;


         --YWA EDB072
          vn_party_id_old                 := NULL;
          vn_vendor_site_id_old          := NULL;
          vn_exist_bank_acct_id_old      := NULL;
          vd_bk_start_date_old           := NULL;
          vn_bk_object_version_number_od := NULL;
          vn_vendor_id_old              := NULL;
          vvn_vendor_id       := null;
          vvn_party_id   := null;
          vn_party_site_id_old   := NULL;--YWA EDB072
          vn_bank_acct_id_old    := NULL;--YWA EDB072

          vv_payment_method := NULL;
          --//FIN REINIT

          gv_step  := lv_current_program_unit||' 004 : sélection des donnée de l''employé : '||lt_employe(i);log_message(gv_step);
          SELECT *
          INTO l_emp
          FROM XXEAI_HR_PEOPLE_INT HPI
          WHERE
           HPI.INSERT_UPDATE_FLAG = 'U'
           AND HPI.INTERFACE_STATUS != 'ERROR'
           AND HPI.EMPLOYEE_NUMBER = lt_employe(i)
           AND SOURCE = gv_source_employe
          ;

          gv_step  := lv_current_program_unit||' 005 : initialisation SAVEPOINT SAVE_EMPLOYE';log_message(gv_step);
          SAVEPOINT SAVE_EMPLOYE;

          --Init pour message
          vv_message  := '';
          vv_emp_num  := lt_employe(i);
          vv_table    := 'XXEAI_HR_PEOPLE_INT';
          vn_table_id := l_emp.XXEAI_PERSON_ID;
          vv_source   := gv_source_employe;

          --///VALIDATION EMPLOYE
          gv_step  := lv_current_program_unit||' 006 : Existence de l''employé';log_message(gv_step);
          get_person_info(vv_emp_num,vn_person_id,vn_per_object_version_number,vr_person_row);
          IF vn_person_id IS NULL then
            --Mise a jour de l'employé impossible, le matricule n'existe pas
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0024',
                                                     'EMPNUM',l_emp.EMPLOYEE_NUMBER);
            vv_type     := 'E';
            RAISE e_emp_error;
          END IF;

          --######################################################################################
          -- EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 007 : Mise a jour employe';log_message(gv_step);

          gv_step  := lv_current_program_unit||' 008 : reinitialisation SAVEPOINT SAVE_EMPLOYE';log_message(gv_step);
          SAVEPOINT SAVE_EMPLOYE;

          BEGIN

            --Init pour message
            vv_message  := '';
            vv_emp_num  := l_emp.employee_number;
            vv_table    := 'XXEAI_HR_PEOPLE_INT';
            vn_table_id := l_emp.XXEAI_PERSON_ID;
            vv_source   := gv_source_employe;

            IF  nvl(vr_person_row.FIRST_NAME   ,'1') != nvl(l_emp.FIRST_NAME,'1')
             OR nvl(vr_person_row.LAST_NAME    ,'1') != nvl(l_emp.LAST_NAME ,'1')
             OR nvl(vr_person_row.SEX          ,'1') != nvl(l_emp.SEX       ,'1')
             OR nvl(vr_person_row.DATE_OF_BIRTH,to_date('01/01/1900','dd/mm/yyyy')) != nvl(l_emp.DATE_OF_BIRTH,to_date('01/01/1900','dd/mm/yyyy'))
             OR (nvl(translate(l_emp.NATIONAL_IDENTIFIER,'1234567890 |','1234567890'),'1')
                                            != nvl(vr_person_row.NATIONAL_IDENTIFIER,'1') AND l_emp.NATIONAL_IDENTIFIER IS NOT NULL)
             OR (nvl(vr_person_row.EMAIL_ADDRESS,'1') != nvl(l_emp.EMAIL_ADDRESS,'1')  AND l_emp.EMAIL_ADDRESS IS NOT NULL)
             --- 05/07/2018 NBO artf2848681 : INC0230966 - Problème de mise à jour interface employé
             OR (nvl(vr_person_row.ATTRIBUTE2   ,'1') != nvl(l_emp.ATTRIBUTE2   ,'1') AND l_emp.ATTRIBUTE2 IS NOT NULL)
             OR (nvl(vr_person_row.ATTRIBUTE4   ,'1') != nvl(l_emp.ATTRIBUTE4   ,'1') AND l_emp.ATTRIBUTE4 IS NOT NULL)
             OR (nvl(vr_person_row.ATTRIBUTE11  ,'1') != nvl(l_emp.ORIG_SYSTEM_PERSON_REF,'1') AND l_emp.ORIG_SYSTEM_PERSON_REF IS NOT NULL)
            THEN

            --- 05/07/2018 NBO artf2848681 : INC0230966 - Problème de mise à jour interface employé
            select max(effective_start_date) into l_effective_date
            from per_all_people_f where person_id = vn_person_id;

            --
            -- --------------------------------
            -- Find Date Track Mode
            -- --------------------------------
            dt_api.find_dt_upd_modes
            (
                --- 05/07/2018 NBO artf2848681 : INC0230966 - Problème de mise à jour interface employé
                p_effective_date               => l_effective_date,--TRUNC(SYSDATE),
                p_base_table_name              => 'PER_ALL_PEOPLE_F',
                p_base_key_column              => 'PERSON_ID',
                p_base_key_value               => vn_person_id,
                 -- Output data elements
                 -- --------------------------------
                 p_correction                   => vb_correction,
                 p_update                       => vb_update,
                 p_update_override              => vb_update_override,
                 p_update_change_insert         => vb_update_change_insert
             );

            IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE )
            THEN -- UPDATE_OVERRIDE
               vv_dt_ud_mode := 'UPDATE_OVERRIDE';
            END IF;
            IF ( vb_correction = TRUE )
            THEN -- CORRECTION
             vv_dt_ud_mode := 'CORRECTION';
            END IF;
            IF ( vb_update = TRUE )
            THEN -- UPDATE
              vv_dt_ud_mode := 'UPDATE';
            END IF;

            log_message('vv_dt_ud_mode : ' || vv_dt_ud_mode);

            --///UPDATE DE L'EMPLOYE
            gv_step  := lv_current_program_unit||' 009 : Mise a jour de l''employé ';log_message(gv_step);

            hr_person_api.update_person
                      (p_validate                      => FALSE,
                       p_first_name                    => l_emp.FIRST_NAME,
                       p_last_name                     => l_emp.LAST_NAME,
                       p_sex                           => nvl(l_emp.SEX,vr_person_row.SEX),
                       p_date_of_birth                 => nvl(l_emp.DATE_OF_BIRTH,vr_person_row.DATE_OF_BIRTH),
                       p_national_identifier           => nvl(translate(l_emp.NATIONAL_IDENTIFIER,'1234567890 |','1234567890')
                                                              ,vr_person_row.NATIONAL_IDENTIFIER),
                       p_email_address                 => nvl(l_emp.EMAIL_ADDRESS,vr_person_row.EMAIL_ADDRESS),
                       p_attribute2                    => nvl(l_emp.ATTRIBUTE2,vr_person_row.ATTRIBUTE2),
                       p_attribute4                    => nvl(l_emp.ATTRIBUTE4,vr_person_row.ATTRIBUTE4),
                       p_attribute11                   => nvl(l_emp.ORIG_SYSTEM_PERSON_REF,vr_person_row.ATTRIBUTE11),
                       --- 05/07/2018 NBO artf2848681 : INC0230966 - Problème de mise à jour interface employé
                       p_effective_date                => l_effective_date, --TRUNC(SYSDATE),
                       p_datetrack_update_mode         => vv_dt_ud_mode,
                       p_person_id                     => vn_person_id,
                       p_object_version_number         => vn_per_object_version_number,
                       p_employee_number               => l_emp.EMPLOYEE_NUMBER,
                       p_full_name                     => vv_full_name,
                       p_effective_start_date          => vd_per_effective_start_date,
                       p_effective_end_date            => vd_per_effective_end_date,
                       p_comment_id                    => vn_per_comment_id,
                       p_name_combination_warning      => vb_name_combination_warning,
                       p_assign_payroll_warning        => vb_assign_payroll_warning,
                       p_orig_hire_warning             => vb_orig_hire_warning
                       );

            --- 01/08/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
            IF /*vb_name_combination_warning or*/ vb_orig_hire_warning then
              --Mise a jour de l'employé impossible : erreur dans l'API
              gv_step  := lv_current_program_unit||' 010 : Mise a jour de l''employé impossible : erreur dans l''API';log_message(gv_step);

              /*IF vb_name_combination_warning THEN
                vv_message := 'Un employé existe déja pour ce nom, prénom et date de naissance';
              ELS*/IF vb_orig_hire_warning THEN
                vv_message := 'Date d''embauche renseigné et type d''employé incohérent';
              END IF;

              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0025',
                                                      'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                      'MESSAGE',vv_message);
              vv_type     := 'P';
              RAISE e_emp_error;
            ELSE
              --- 01/08/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
              IF vb_name_combination_warning THEN
                vv_message := 'Un employé existe déja pour ce nom, prénom et date de naissance';
                vv_type     := 'W';
                insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
              END IF;

                --Mise à jour OK
              gv_step  := lv_current_program_unit||' 009 : Mise a jour de l''employé OK';log_message(gv_step);

              BEGIN

                  IF nvl(vr_person_row.EMAIL_ADDRESS,'1') != nvl(l_emp.EMAIL_ADDRESS,'1') and FND_USER_PKG.userExists(l_emp.EMPLOYEE_NUMBER) THEN
                    gv_step  := lv_current_program_unit||' 011 : Mise a jour de l''adresse mail de l''utilisateur';log_message(gv_step);
                    --Mise a jour de l'adresse mail de l'utilisateur
                    FND_USER_PKG.UpdateUser(x_user_name => l_emp.EMPLOYEE_NUMBER,
                                            x_owner => fnd_global.user_name,
                                            x_email_address => nvl(l_emp.email_address,vr_person_row.email_address));

                  END IF;

              EXCEPTION
                WHEN OTHERS THEN
                  --Mise a jour de l'adresse mail de l'utilisateur de l'employé impossible
                  vv_message  := dka_tools_pkg.get_message( 'DKA','DKA_IHREMP_REF_0026',
                                                            'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                            'MESSAGE',SQLERRM);
                  vv_type     := 'P';
                  insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
                  --RAISE e_emp_error;  --insertion de l'erreur mais pas de propagation
              END;
            END IF;

            ELSE
              --Pas de mise a jour de l'employé a réaliser
              gv_step  := lv_current_program_unit||' - Pas de mise a jour de l''employé a réaliser';log_message(gv_step);
            END IF;

            insert_error(vv_emp_num,vv_table,vn_table_id,'S',
                         'Mise a jour employé (Informations générales) terminée : '||vv_emp_num||' avec succes',gv_step,vv_source);

            flag_traite(pv_employee_number    => vv_emp_num,
                        pv_insert_update_flag => 'U',
                        pv_table_name         => vv_table,
                        pv_source             => vv_source);

          EXCEPTION
           WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            vv_type     := 'E';
            ROLLBACK TO SAVE_EMPLOYE;
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
           WHEN OTHERS THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            vv_type     := 'E';
            ROLLBACK TO SAVE_EMPLOYE;
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
          END;

          --######################################################################################
          --AFFECTATION EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 012 : Mise a jour affectation employe';log_message(gv_step);

          gv_step  := lv_current_program_unit||' 013 : reintialisation SAVEPOINT SAVE_EMPLOYE';log_message(gv_step);
          SAVEPOINT SAVE_EMPLOYE;

          BEGIN

            gv_step  := lv_current_program_unit||' 014 : Sélection de l''affectation de l''employé';log_message(gv_step);
            BEGIN

              SELECT *
              INTO l_assignment
              FROM
               XXEAI_HR_ASSIGNMENT_INT HAI
              WHERE
                   HAI.INSERT_UPDATE_FLAG = 'U'
               AND HAI.INTERFACE_STATUS != 'ERROR'
               AND HAI.EMPLOYEE_NUMBER = vv_emp_num;


            EXCEPTION
             WHEN NO_DATA_FOUND THEN
              --Modification de l'employé impossible : Pas d'info affectation
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0027','EMPNUM',l_emp.EMPLOYEE_NUMBER);
              vv_type     := 'P';
              raise e_emp_error;
             WHEN TOO_MANY_ROWS THEN
              --Modification de l'employé impossible : Doublon dans les infos affectations
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0028','EMPNUM',l_emp.EMPLOYEE_NUMBER);
              vv_type     := 'P';
              raise e_emp_error;
            END;

            --Init pour message
            vv_table    := 'XXEAI_HR_ASSIGNMENT_INT';
            vn_table_id := l_assignment.XXEAI_ASSIGNMENT_ID;

      --SHA EDB402 Début
            l_assignment.ASS_ATTRIBUTE1 := get_value_from_set(
            p_value    => l_assignment.ASS_ATTRIBUTE1
              );
            --SHA EDB402 fin

            --Recherche de l'affectation courante
            gv_step  := lv_current_program_unit||' 015 : Recherche de l''affectation courante';log_message(gv_step);
            get_assign_info(l_emp.employee_number,
                            vn_assignment_id,
                            vn_asg_object_version_number,
                            vd_ass_start_date,
                            vd_ass_end_date,
                            vn_job_id,
                            vv_job_name,
                            vv_fct,
                            vn_organization_id,
                            vv_organization_name,
                            vn_supervisor_id,
                            vv_ass_attribute1,
                            vv_ass_attribute2,
                            vv_ass_attribute3,
                            vv_ass_attribute4,
                            vv_ass_attribute5,
                            l_assignment.effective_start_date -- OBE artf2391673
                            );

            IF vn_asg_object_version_number IS NULL THEN
              --Mise a jour de l'employé impossible : Recherche de la tache du projet en erreur
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0029',
                                                       'EMPNUM',l_emp.EMPLOYEE_NUMBER);
              vv_type     := 'P';
              raise e_emp_error;

            END IF;


            --Recherche des infos de la tache du projet
            gv_step  := lv_current_program_unit||' 016 : Recherche des infos de la tache du projet actuel';log_message(gv_step);
            DKA_PA_TOOLS_PKG.pa_get_info_task(vv_errbuf,
                                              vn_retcode,
                                              vv_ass_attribute5,
                                              vv_task_id,
                                              vn_task_project_id,
                                              vv_task_project_name,
                                              vv_task_project_type,
                                              vd_task_start_date,
                                              vd_task_completion_date,
                                              vd_task_closed_date,
                                              vv_task_org_projet,
                                              vn_task_org_projet_id,
                                              vv_task_societe,
                                              vv_task_region,
                                              vv_task_org_fin,
                                              vn_task_org_fin_id);

            IF vn_retcode != 0 THEN
               --Mise a jour de l'employé impossible : Erreur lors de la détermination des informations projet actuel
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0030',
                                                       'EMPNUM',l_emp.employee_number,
                                                       'TACHE',vv_ass_attribute5,'MESSAGE',vv_errbuf);
              vv_type     := 'P';
              raise e_emp_error;
            END IF;

            --Recherche des infos de la tache du projet
            gv_step  := lv_current_program_unit||' 017 : Recherche des infos de la tache du projet reçu';log_message(gv_step);
            DKA_PA_TOOLS_PKG.pa_get_info_task(vv_errbuf,
                                              vn_retcode,
                                              l_assignment.ass_attribute5,
                                              vv_new_task_id,
                                              vn_new_task_project_id,
                                              vv_new_task_project_name,
                                              vv_new_task_project_type,
                                              vd_new_task_start_date,
                                              vd_new_task_completion_date,
                                              vd_new_task_closed_date,
                                              vv_new_task_org_projet,
                                              vn_new_task_org_projet_id,
                                              vv_new_task_societe,
                                              vv_new_task_region,
                                              vv_new_task_org_fin,
                                              vn_new_task_org_fin_id);

            IF vn_retcode != 0 THEN
               --Mise a jour de l'employé impossible : Erreur lors de la détermination des informations projet reçu
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0031',
                                                       'EMPNUM',l_emp.employee_number,
                                                       'TACHE',l_assignment.ass_attribute5,'MESSAGE',vv_errbuf);
              vv_type     := 'P';
              raise e_emp_error;
            END IF;

            --Entité comptable
            gv_step  := lv_current_program_unit||' 018 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
            vn_ledger_id := dka_gl_tools_pkg.get_legder_id(vv_task_societe);

            IF vn_ledger_id IS NULL THEN
               --Mise a jour employé impossible, entité comptable n'existe pas pour la société
               vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0032',
                                                        'EMPNUM',l_emp.employee_number,
                                                        'SOCIETE',vv_task_societe);
               vv_type     := 'P';
               RAISE e_emp_error;
            END IF;

            --Derniere periode GL
            gv_step  := lv_current_program_unit||' 019 : Recherche de la derniere période ouverte de l''entité comptable: '||vv_task_societe;log_message(gv_step);
            get_period_gl (vn_ledger_id,
                           vv_period_name,
                           vd_period_start_date,
                           vd_period_end_date);

            IF vv_period_name IS NULL THEN
               --Mise a jour employé impossible, derniere periode ouverte non trouvée
               vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0033',
                                                        'EMPNUM',l_emp.employee_number,
                                                        'SOCIETE',vv_task_societe);
               vv_type     := 'P';
               RAISE e_emp_error;
            END IF;

            --Superviseur
            gv_step  := lv_current_program_unit||' 020 : Validation superviseur : '||l_assignment.ORIG_SYSTEM_SUPERVISOR_REF;log_message(gv_step);
            IF l_assignment.ORIG_SYSTEM_SUPERVISOR_REF is not null THEN
               vn_superviseur :=  get_person_id(l_assignment.ORIG_SYSTEM_SUPERVISOR_REF);

               IF vn_superviseur IS NULL THEN
                 --Mise a jour de l'affectation employé impossible, le superviseur n'existe pas ou est inactif
                 vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0034',
                                                          'EMPNUM',l_emp.employee_number,
                                                          'SUP',l_assignment.ORIG_SYSTEM_SUPERVISOR_REF);
                 vv_type     := 'P';
                 RAISE e_emp_error;
               END IF;
            END IF;

            --Superviseur Hiérarchique
            gv_step  := lv_current_program_unit||' 021 : Validation superviseur hiérarchique: '||l_assignment.ASS_ATTRIBUTE3;log_message(gv_step);
            IF l_assignment.ASS_ATTRIBUTE3 is not null THEN
               vn_sup_hierar :=  get_person_id(l_assignment.ASS_ATTRIBUTE3);

               IF vn_sup_hierar IS NULL THEN
                 --Mise a jour de l'affectation employé impossible, le superviseur hierarchique n'existe pas ou est inactif
                 vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0035',
                                                          'EMPNUM',l_emp.employee_number,
                                                          'SUP',l_assignment.ASS_ATTRIBUTE3);
                 vv_type     := 'P';
                 RAISE e_emp_error;
               END IF;
            END IF;

            --Fonction
            gv_step  := lv_current_program_unit||' 022 : Recherche de la fonction: '||l_emp.attribute2||'.'||vv_fct;log_message(gv_step);
            vn_job_id_new := get_job_id(l_emp.attribute2,vv_fct);

            IF vn_job_id_new IS NULL THEN
               --Mise a jour de l'affectation employé impossible, le poste n'existe pas
               vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0036',
                                                        'EMPNUM',l_emp.employee_number,
                                                        'FCT',l_emp.attribute2|| '.' || gv_default_job);
               vv_type     := 'P';
               RAISE e_emp_error;
            END IF;

            --Détermination des dates d'affectation
            gv_step  := lv_current_program_unit||' 023 : Détermination des dates d''affectation';log_message(gv_step);

            --REJET DIRECT
            --- 04/06/2018 NBO artf2646661 : TASK0056324  l'interface Employés, en cas d'erreur bloquante sur les changements d'organisations
            IF l_assignment.ORIG_SYSTEM_SUPERVISOR_REF is null AND l_assignment.ASS_ATTRIBUTE3 is null THEN
              IF  l_assignment.effective_start_date <= vd_period_end_date
                  and vv_organization_name/*org actuelle*/ !=  vv_new_task_org_fin /*org reçue*/ THEN
                  --Mise a jour de l'affectation employé impossible, la date de début de l'affectation reçue
                  --est inférieur au dernier jour de la période comptable en cours
                  gv_step  := lv_current_program_unit||' 024 : Rejet - Mise a jour de l''affectation employé impossible, la date '||
                                                       'de début de l''affectation reçue est inférieur au dernier jour de la'||
                                                       ' période comptable en cours';log_message(gv_step);
                 vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0037',
                                                          'EMPNUM',l_emp.employee_number);
                  vv_type     := 'P';
                  RAISE e_emp_error;
              END IF;
            END IF;

            log_message('org actuelle : '||vv_organization_name);
            log_message('new org      : '||vv_new_task_org_fin);
            log_message('vd_ass_start_date      : '||to_char(vd_ass_start_date,'YYYY/MM/DD'));
            log_message('vd_period_end_date     : '||to_char(vd_period_end_date,'YYYY/MM/DD'));

            IF  vv_organization_name/*org actuelle*/ !=  vv_new_task_org_fin /*org reçue*/ THEN

              IF  l_assignment.effective_start_date > vd_ass_start_date AND
                  l_assignment.effective_start_date > vd_period_end_date THEN
                  --CAS 1
                  gv_step  := lv_current_program_unit||' 025 : CAS 1';log_message(gv_step);
                  vd_def_ass_effective_date := l_assignment.effective_start_date;
                  vn_def_task_org_fin_id    := vn_new_task_org_fin_id;

              ELSIF  l_assignment.effective_start_date > vd_ass_start_date AND
                     l_assignment.effective_start_date < vd_period_end_date THEN
                  --CAS 2
                  gv_step  := lv_current_program_unit||' 026 : CAS 2';log_message(gv_step);
                  vd_def_ass_effective_date := vd_period_end_date + 1;
                  vn_def_task_org_fin_id    := vn_new_task_org_fin_id;

              ELSIF  l_assignment.effective_start_date = vd_ass_start_date AND
                     l_assignment.effective_start_date > vd_period_end_date THEN
                  --CAS 3
                  gv_step  := lv_current_program_unit||' 027 : CAS 3';log_message(gv_step);
                  vd_def_ass_effective_date := TRUNC(SYSDATE);
                  vn_def_task_org_fin_id    := vn_new_task_org_fin_id;

              ELSIF  l_assignment.effective_start_date = vd_ass_start_date AND
                     l_assignment.effective_start_date < vd_period_end_date THEN
                  --CAS 4
                  gv_step  := lv_current_program_unit||' 028 : CAS 4';log_message(gv_step);
                  vd_def_ass_effective_date := vd_period_end_date + 1;
                  vn_def_task_org_fin_id    := vn_new_task_org_fin_id;

              ELSIF  l_assignment.effective_start_date < vd_ass_start_date AND
                     l_assignment.effective_start_date < vd_period_end_date  THEN
                  --CAS 5
                  --Mise a jour de l'affectation employé impossible, la date de début du centre financier
                  --est inférieur a la date de début de la derniere ligne d'affectation
                  gv_step  := lv_current_program_unit||' 029 : CAS 5 - Mise a jour de l''affectation employé impossible, la date de début du centre financier'||
                                                       'est inférieur a la date de début de la derniere ligne d''affectation';log_message(gv_step);
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0038',
                                                          'EMPNUM',l_emp.employee_number);
                  vv_type     := 'P';
                  RAISE e_emp_error;
              END IF;


            ELSE --vv_organization_name/*org actuelle*/ != vv_new_task_org_projet /*org reçue*/

              IF  l_assignment.effective_start_date > vd_ass_start_date THEN
                  --CAS 6
                  --Envoi d'une nouvelle affectation identique a la précédente
                  --mais avec une nouvelle date de début de validité
                  gv_step  := lv_current_program_unit||' 030 : CAS 6 - Envoi d''une nouvelle affectation identique a la précédente '||
                                                       'mais avec une nouvelle date de début de validité';log_message(gv_step);
                  vv_ne_rien_faire := TRUE;
              ELSIF l_assignment.effective_start_date = vd_ass_start_date THEN
                  --CAS 7
                  --Résiliation de l'affectation courante ou
                  --Renvoi d'une ligne déja envoyée
                  gv_step  := lv_current_program_unit||' 031 : CAS 7 - Résiliation de l''affectation courante ou Renvoi d''une ligne'||
                                                       ' déja envoyée';log_message(gv_step);
                  vv_ne_rien_faire := TRUE;
              ELSIF l_assignment.effective_start_date < vd_ass_start_date THEN
                  --CAS 8
                  gv_step  := lv_current_program_unit||' 032 : CAS 8';log_message(gv_step);
                  vv_ne_rien_faire := TRUE;
              END IF;

            END IF;

              --

            IF NOT vv_ne_rien_faire
              OR NVL(vv_ass_attribute3,'1') != NVL(TO_CHAR(vn_sup_hierar),'1')    -- OBE artf2391673
              OR NVL(vn_superviseur,1)      != NVL(vn_supervisor_id,1)               -- OBE artf2391673
              OR NVL(vn_job_id,1)           != NVL(vn_job_id_new,1)               -- OBE artf2391673
              OR NVL(vv_ass_attribute1,'1') != NVL(l_assignment.ASS_ATTRIBUTE1,'1') -- OBE artf2391673
              OR NVL(vv_ass_attribute2,'1') != NVL(l_assignment.ASS_ATTRIBUTE2,'1') -- OBE artf2391673
              OR NVL(vv_ass_attribute4,'1') != NVL(l_assignment.ASS_ATTRIBUTE4,'1') -- OBE artf2391673
              OR NVL(vv_ass_attribute5,'1') != NVL(l_assignment.ASS_ATTRIBUTE5,'1') -- OBE artf2391673
            THEN
              --//AFFECTATION - API STD
              gv_step  := lv_current_program_unit||' 033 : AFFECTATION - API STD';log_message(gv_step);

              BEGIN

                --YWA EDB072
                --vn_organization_id_old := vn_organization_id;--YWA

                --Recherche du fournisseur et site fournisseur
                gv_step := lv_current_program_unit ||' 033.1 : Recherche du fournisseur et site fournisseur '||vn_person_id ;
                log_message(gv_step);
                get_supplier_site_info( vn_person_id,
                                        vn_task_org_projet_id,
                                        vn_vendor_id_old,
                                        vn_party_id_old,
                                        vn_vendor_site_id_old,
                                        vn_party_site_id_old);
                 gv_step := lv_current_program_unit ||' 033.0 : Le site fournisseur et fournisseur '||vn_vendor_id_old ||' site '||vn_vendor_site_id_old;
                 log_message(gv_step);

                 IF vn_vendor_site_id_old IS NULL OR vn_vendor_id_old IS NULL THEN
                    gv_step := lv_current_program_unit ||' 033.2 : Le site fournisseur ou le founisseur n''existe pas';
                    log_message(gv_step);

                 END IF;

                --YWA

               -- Find Date Track Mode
               -- --------------------------------
               dt_api.find_dt_upd_modes
               (    p_effective_date                  => NVL(vd_def_ass_effective_date,vd_ass_start_date), -- OBE artf2391673
                    p_base_table_name                 => 'PER_ALL_ASSIGNMENTS_F',
                    p_base_key_column                 => 'ASSIGNMENT_ID',
                    p_base_key_value                  => vn_assignment_id,
                     -- Output data elements
                     -- --------------------------------
                     p_correction                          => vb_correction,
                     p_update                              => vb_update,
                     p_update_override                     => vb_update_override,
                     p_update_change_insert                => vb_update_change_insert
                 );

                IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE ) THEN
                -- UPDATE_OVERRIDE
                    vv_dt_ud_mode := 'UPDATE_OVERRIDE';
                END IF;

                IF ( vb_correction = TRUE ) THEN
                -- CORRECTION
                   vv_dt_ud_mode := 'CORRECTION';
                END IF;

                IF ( vb_update = TRUE ) THEN
                -- UPDATE
                    vv_dt_ud_mode := 'UPDATE';
                END IF;

                -- Update Employee Assignment
                -- ---------------------------------------------
                gv_step  := lv_current_program_unit||' 034 : AFFECTATION - API STD : Update Employee Assignment ';log_message(gv_step);

                --- 23/07/2018 NBO artf2646661 : TASK0056324  l'interface Employés, en cas d'erreur bloquante sur les changements d'organisations
                log_message('vd_def_ass_effective_date : '||vd_def_ass_effective_date);
                log_message('vd_ass_start_date : '||vd_ass_start_date);
                log_message('vv_dt_ud_mode : '||vv_dt_ud_mode);
                log_message('vn_assignment_id : '||vn_assignment_id);
                log_message('vn_asg_object_version_number : '||vn_asg_object_version_number);
                log_message('vn_superviseur : '||vn_superviseur);
                log_message('vn_supervisor_id : '||vn_supervisor_id);
                log_message('l_emp.employee_number : '||l_emp.employee_number);
                log_message('vn_ledger_id : '||vn_ledger_id);
                log_message('vd_effective_start_date : '||vd_effective_start_date);
                log_message('vd_effective_end_date : '||vd_effective_end_date);

                hr_assignment_api.update_emp_asg
                 ( p_effective_date               => NVL(vd_def_ass_effective_date,vd_ass_start_date) -- OBE artf2391673
                  ,p_datetrack_update_mode        => vv_dt_ud_mode
                  ,p_assignment_id                => vn_assignment_id
                  ,p_object_version_number        => vn_asg_object_version_number
                  ,p_supervisor_id                => nvl(vn_superviseur,vn_supervisor_id)
                  ,p_assignment_number            => l_emp.employee_number
                  ,p_set_of_books_id              => vn_ledger_id
                  ,p_ass_attribute1               => l_assignment.ASS_ATTRIBUTE1
                  ,p_ass_attribute2               => l_assignment.ASS_ATTRIBUTE2
                  ,p_ass_attribute3               => nvl(vn_sup_hierar,vv_ass_attribute3)
                  ,p_ass_attribute4               => nvl(l_assignment.ASS_ATTRIBUTE4,vv_ass_attribute4)
                  ,p_ass_attribute5               => l_assignment.ASS_ATTRIBUTE5
                  ,p_concatenated_segments        => vc_concatenated_segments
                  ,p_soft_coding_keyflex_id       => vn_soft_coding_keyflex_id
                  ,p_comment_id                   => vn_comment_id
                  ,p_effective_start_date         => vd_effective_start_date
                  ,p_effective_end_date           => vd_effective_end_date
                  ,p_no_managers_warning          => vb_no_managers_warning
                  ,p_other_manager_warning        => vb_other_manager_warning
                  );

                EXCEPTION
                 WHEN OTHERS THEN
                  --Mise a jour de l'affectation employé impossible, erreur dans l'API : Update Employee Assignment
                   vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0039',
                                                            'EMPNUM',l_emp.employee_number,
                                                            'MESSAGE',SQLERRM);
                   vv_type     := 'P';
                   RAISE e_emp_error;
                END;

                 -- Find Date Track Mode for Second API
                 -- ------------------------------------------------------
                gv_step  := lv_current_program_unit||' 035 : AFFECTATION - API STD';log_message(gv_step);

                BEGIN

                dt_api.find_dt_upd_modes
                  (  p_effective_date             => NVL(vd_def_ass_effective_date,vd_ass_start_date), -- OBE artf2391673
                     p_base_table_name            => 'PER_ALL_ASSIGNMENTS_F',
                     p_base_key_column            => 'ASSIGNMENT_ID',
                     p_base_key_value             => vn_assignment_id,
                     -- Output data elements
                     -- -------------------------------
                     p_correction                 => vb_correction,
                     p_update                     => vb_update,
                     p_update_override            => vb_update_override,
                     p_update_change_insert       => vb_update_change_insert
                  );

                IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE )
                THEN  -- UPDATE_OVERRIDE
                  vv_dt_ud_mode := 'UPDATE_OVERRIDE';
                END IF;
                 IF ( vb_correction = TRUE )
                 THEN -- CORRECTION
                   vv_dt_ud_mode := 'CORRECTION';
                END IF;
                IF ( vb_update = TRUE )
                THEN -- UPDATE
                  vv_dt_ud_mode := 'UPDATE';
                END IF;

                 -- Update Employee Assgment Criteria
                 -- -----------------------------------------------------
                gv_step  := lv_current_program_unit||' 036 : AFFECTATION - API STD : Update Employee Assgment Criteria ';log_message(gv_step);


                 hr_assignment_api.update_emp_asg_criteria
                 ( -- Input data elements
                  -- ------------------------------
                  p_effective_date                      => NVL(vd_def_ass_effective_date,vd_ass_start_date), -- OBE artf2391673
                  p_datetrack_update_mode               => vv_dt_ud_mode,
                  p_assignment_id                       => vn_assignment_id,
                  p_organization_id                     => NVL(vn_def_task_org_fin_id,vn_task_org_fin_id), -- OBE artf2391673
                  p_job_id                              => vn_job_id_new,
                  -- Output data elements
                  -- -------------------------------
                  p_people_group_id                     => vn_people_group_id,
                  p_object_version_number               => vn_asg_object_version_number,
                  p_special_ceiling_step_id             => vn_special_ceiling_step_id,
                  p_group_name                          => vc_group_name,
                  p_effective_start_date                => vd_effective_start_date,
                  p_effective_end_date                  => vd_effective_end_date,
                  p_org_now_no_manager_warning          => vb_org_now_no_manager_warning,
                  p_other_manager_warning               => vb_other_manager_warning,
                  p_spp_delete_warning                  => vb_spp_delete_warning,
                  p_entries_changed_warning             => vc_entries_changed_warning,
                  p_tax_district_changed_warning        => vb_tax_district_changed_warn
                 );
               EXCEPTION
               WHEN OTHERS THEN
                --Mise a jour de l'affectation employé impossible, erreur dans l'API : Update Employee Assgment Criteria
                 vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0040',
                                                          'EMPNUM',l_emp.employee_number,
                                                          'MESSAGE',SQLERRM);
                 vv_type     := 'P';
                 RAISE e_emp_error;
              END;

            ELSE
              --Pas de mise a jour affectation a réaliser
              gv_step  := lv_current_program_unit||' - Pas de mise a jour affectation a réaliser';log_message(gv_step);
            END IF; --vv_ne_rien_faire

            insert_error(vv_emp_num,vv_table,vn_table_id,'S',
                         'Mise a jour employé (Affectation) terminée : '||vv_emp_num||' avec succes',gv_step,vv_source);

            flag_traite(pv_employee_number    => vv_emp_num,
                        pv_insert_update_flag => 'U',
                        pv_table_name         => vv_table,
                        pv_source             => vv_source);

          EXCEPTION
           WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            ROLLBACK TO SAVE_EMPLOYE;
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
          END;

          --######################################################################################
          --MISE A JOUR FOURNISSEUR EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 037 : Mise a jour fournisseur employe';log_message(gv_step);

          gv_step  := lv_current_program_unit||' 038 : reintialisation SAVEPOINT SAVE_EMPLOYE';log_message(gv_step);
          SAVEPOINT SAVE_EMPLOYE;

          BEGIN

            --Init pour message
            vv_message  := '';
            vv_emp_num  := l_emp.employee_number;
            vv_table    := 'XXEAI_HR_PEOPLE_INT';
            vn_table_id := l_emp.XXEAI_PERSON_ID;
            vv_source   := gv_source_employe;

            --NATIONAL_IDENTIFIER
            gv_step  := lv_current_program_unit||' 039 : Vérification NATIONAL_IDENTIFIER';log_message(gv_step);
            IF l_emp.NATIONAL_IDENTIFIER is null then
              --Pas de mise a jour de du fournisseur , numéro d'identification natinal vide
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0041',
                                                       'EMPNUM',l_emp.EMPLOYEE_NUMBER);
              vv_type     := 'P';
              --RAISE e_emp_error; --on continue, pas de rejet
            END IF;


            --Infos fournisseur
            gv_step  := lv_current_program_unit||' 040 : Recherche des infos fournisseurs';log_message(gv_step);
            get_supplier_info(vn_person_id,vn_vendor_id ,vn_party_id);
            IF vn_vendor_id IS NULL OR vn_party_id IS NULL then
              --Mise a jour de du fournisseur impossible, le fournisseur n'existe pas
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0042',
                                                       'EMPNUM',l_emp.EMPLOYEE_NUMBER);
              vv_type     := 'P';
              RAISE e_emp_error;
            END IF;

            --Init valeur fournisseur
            vn_api_version      := 1.0;
            vv_init_msg_list    := FND_API.G_TRUE;
            vv_commit           := FND_API.G_FALSE;
            vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
            vv_return_status    := NULL;
            vn_msg_count        := NULL;
            vv_msg_data         := NULL;

            vr_vendor_rec.vat_registration_num      := nvl(translate(l_emp.NATIONAL_IDENTIFIER,'1234567890 |','1234567890')
                                                           ,vr_person_row.national_identifier);

            --///Update du fournisseur - API
            gv_step  := lv_current_program_unit||' 041 : Update du fournisseur - API';log_message(gv_step);
            ap_vendor_pub_pkg.Update_Vendor(vn_api_version,
                                            vv_init_msg_list,
                                            vv_commit,
                                            vn_validation_level,
                                            vv_return_status,
                                            vn_msg_count,
                                            vv_msg_data,
                                            vr_vendor_rec,
                                            vn_vendor_id
                                            );


            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              gv_step  := lv_current_program_unit||' 042 : Update du fournisseur - API : Success';log_message(gv_step);

              --VENDOR_NAME
              --RBE artf2688394 : API update_vendor ne met pas à jour le vendor_name, donc on le fait directement en cas de succes
              gv_step  := lv_current_program_unit||' 042b : Vérification VENDOR_NAME';log_message(gv_step);
              IF  nvl(vr_person_row.FIRST_NAME   ,'1') != nvl(l_emp.FIRST_NAME,'1')
               OR nvl(vr_person_row.LAST_NAME    ,'1') != nvl(l_emp.LAST_NAME ,'1') then
                update ap_suppliers
                set vendor_name = substr(l_emp.last_name ||' '|| l_emp.first_name ||' '|| l_emp.employee_number,1,30)
                where vendor_id = vn_vendor_id;
              END IF;

            ELSE
              vv_message := '';
              IF vn_msg_count > 0 THEN

                FOR v_index IN 1 .. vn_msg_count LOOP
                  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                END LOOP;

              END IF;

              --Mise a jour du fournisseur impossible : message
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0043',
                                                       'EMPNUM',l_emp.employee_number,
                                                       'MESSAGE',vv_message);
              vv_type     := 'E';
              RAISE e_emp_error;

            END IF;

            insert_error(vv_emp_num,vv_table,vn_table_id,'S',
                         'Mise a jour employé (Fournisseur) terminée : '||vv_emp_num||' avec succes',gv_step,vv_source);

            flag_traite(pv_employee_number    => vv_emp_num,
                        pv_insert_update_flag => 'U',
                        pv_table_name         => vv_table,
                        pv_source             => vv_source);

          EXCEPTION
           WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            ROLLBACK TO SAVE_EMPLOYE;
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
          END;

          --######################################################################################
          --MISE A JOUR SITE FOURNISSEUR EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 043 : Mise a jour site fournisseur employe';log_message(gv_step);

          gv_step  := lv_current_program_unit||' 044 : reintialisation SAVEPOINT SAVE_EMPLOYE';log_message(gv_step);
          SAVEPOINT SAVE_EMPLOYE;

          BEGIN
              vv_table    := 'XXEAI_HR_PEOPLE_INT';
              vn_table_id := l_emp.XXEAI_PERSON_ID;

              --Recherche de la tache du projet
              gv_step  := lv_current_program_unit||' 045 : Recherche de la tache du projet';log_message(gv_step);
              get_assign_info(l_emp.employee_number,
                              vn_assignment_id,
                              vn_asg_object_version_number,
                              vd_ass_start_date,
                              vd_ass_end_date,
                              vn_job_id,
                              vv_job_name,
                              vv_fct,
                              vn_organization_id,
                              vv_organization_name,
                              vn_supervisor_id,
                              vv_ass_attribute1,
                              vv_ass_attribute2,
                              vv_ass_attribute3,
                              vv_ass_attribute4,
                              vv_ass_attribute5);

              IF vn_asg_object_version_number IS NULL THEN
                --Mise a jour de l'employé impossible : Recherche de la tache du projet en erreur
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0044',
                                                         'EMPNUM',l_emp.EMPLOYEE_NUMBER);
                vv_type     := 'P';
                raise e_emp_error;

              END IF;

              --Recherche des infos de la tache du projet
              gv_step  := lv_current_program_unit||' 046 : Recherche des infos de la tache du projet '||vv_ass_attribute5;log_message(gv_step);
              DKA_PA_TOOLS_PKG.pa_get_info_task(vv_errbuf,
                                                vn_retcode,
                                                vv_ass_attribute5,
                                                vv_task_id,
                                                vn_task_project_id,
                                                vv_task_project_name,
                                                vv_task_project_type,
                                                vd_task_start_date,
                                                vd_task_completion_date,
                                                vd_task_closed_date,
                                                vv_task_org_projet,
                                                vn_task_org_projet_id,
                                                vv_task_societe,
                                                vv_task_region,
                                                vv_task_org_fin,
                                                vn_task_org_fin_id);

              IF vn_retcode != 0 THEN
                 --Mise a jour de l'employé impossible : Erreur lors de la détermination des informations projet
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0045',
                                                         'EMPNUM',l_emp.employee_number,
                                                         'TACHE',l_assignment.ass_attribute5,'MESSAGE',vv_errbuf);
                vv_type     := 'P';
                raise e_emp_error;
              END IF;

              --Infos fournisseur
              gv_step  := lv_current_program_unit||' 040 : Recherche des infos fournisseurs';log_message(gv_step);
              get_supplier_info(vn_person_id,vn_vendor_id ,vn_party_id);
              IF vn_vendor_id IS NULL OR vn_party_id IS NULL THEN
                --Mise a jour de du fournisseur impossible, le fournisseur n'existe pas
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0042',
                                                         'EMPNUM',l_emp.EMPLOYEE_NUMBER);
                vv_type     := 'P';
                RAISE e_emp_error;
              END IF;

              --Recherche du fournisseur et site fournisseur
              gv_step  := lv_current_program_unit||' 047 : Recherche du fournisseur et site fournisseur dans l''org :'||vn_task_org_projet_id;log_message(gv_step);
              get_supplier_site_info(vn_person_id,vn_task_org_projet_id, vvn_vendor_id , vvn_party_id,vn_vendor_site_id,vn_party_site_id );

              IF vn_vendor_site_id IS NULL AND vvn_vendor_id IS NULL THEN --YWA EDB072 AND vvn_vendor_id IS not NULL
                --Le site n'existe pas, création
                gv_step  := lv_current_program_unit||' 048 : Le site fournisseur n''existe pas ==> création';log_message(gv_step);

                --Entité comptable
                gv_step  := lv_current_program_unit||' 049 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
                vn_ledger_id := dka_gl_tools_pkg.get_legder_id(vv_task_societe);

                IF vn_ledger_id IS NULL THEN
                   --Mise a jour employé impossible, entité comptable n'existe pas pour la société
                   vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0046',
                                                            'EMPNUM',l_emp.employee_number,
                                                            'SOCIETE',vv_task_societe);
                   vv_type     := 'P';
                   RAISE e_emp_error;
                END IF;

                --Devise Entité comptable
                gv_step  := lv_current_program_unit||' 050 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
                vv_currency_code := get_currency_code(vn_ledger_id);

                IF vv_currency_code IS NULL THEN
                   --Mise a jour employé impossible : Erreur sur la devise de l'entité comptable
                   vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0047',
                                                            'EMPNUM',l_emp.employee_number,
                                                            'SOCIETE',vv_task_societe);
                   vv_type     := 'P';
                   RAISE e_emp_error;
                END IF;

                --Compte GL founisseur
                gv_step  := lv_current_program_unit||' 051 : Compte GL founisseur';log_message(gv_step);
                Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => vv_task_societe,
                                                      pv_segment2              => vv_task_region,
                                                      pv_segment3              => gv_accts_local,
                                                      pv_segment4              => gv_accts_anal,
                                                      pv_segment5              => gv_ccid_defaut,
                                                      pv_segment6              => gv_ccid_defaut,
                                                      pv_segment7              => gv_ccid_defaut,
                                                      pv_segment8              => gv_ccid_defaut,
                                                      pv_segment9              => gv_ccid_defaut,
                                                      pv_segment10             => gv_ccid_defaut,
                                                      pv_segment11             => gv_ccid_defaut,
                                                      pv_segment12             => gv_ccid_defaut,
                                                      pn_code_combination_id   => vn_ACCTS_PAY_CCID,
                                                      pv_errbuf                => vv_errbuf,
                                                      pn_retcode               => vn_retcode);

                gv_step  := lv_current_program_unit||' 052 : Compte GL founisseur : '||vn_ACCTS_PAY_CCID;log_message(gv_step);

                IF  vn_retcode != 0 THEN
                   --Création du site fournisseur impossible : recherche de la clé comptable fournisseur en erreur : message
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0014',
                                                           'EMPNUM',l_emp.employee_number,
                                                           'MESSAGE',vv_errbuf);
                  vv_type     := 'P';
                  RAISE e_emp_error;
                END IF;

                --Compte GL acompte
                gv_step  := lv_current_program_unit||' 053 : Compte GL acompte';log_message(gv_step);
                Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => vv_task_societe,
                                                      pv_segment2              => vv_task_region,
                                                      pv_segment3              => gv_prepay_local,
                                                      pv_segment4              => gv_prepay_anal,
                                                      pv_segment5              => gv_ccid_defaut,
                                                      pv_segment6              => gv_ccid_defaut,
                                                      pv_segment7              => gv_ccid_defaut,
                                                      pv_segment8              => gv_ccid_defaut,
                                                      pv_segment9              => gv_ccid_defaut,
                                                      pv_segment10             => gv_ccid_defaut,
                                                      pv_segment11             => gv_ccid_defaut,
                                                      pv_segment12             => gv_ccid_defaut,
                                                      pn_code_combination_id   => vn_PREPAY_CCID,
                                                      pv_errbuf                => vv_errbuf,
                                                      pn_retcode               => vn_retcode);

                gv_step  := lv_current_program_unit||' 054 : Compte GL acompte : '||vn_PREPAY_CCID;log_message(gv_step);


                IF  vn_retcode != 0 THEN
                   --Création du site fournisseur impossible : recherche de la clé comptable acompte fournisseur en erreur : message
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0015',
                                                           'EMPNUM',l_emp.employee_number,
                                                           'MESSAGE',vv_errbuf);
                  vv_type     := 'P';
                  RAISE e_emp_error;
                END IF;

                --Init valeur site fournisseur
                vn_api_version      := 1.0;
                vv_init_msg_list    := FND_API.G_TRUE;
                vv_commit           := FND_API.G_FALSE;
                vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
                vv_return_status    := NULL;
                vn_msg_count        := NULL;
                vv_msg_data         := NULL;

                vn_vendor_site_id     := NULL;
                vn_party_site_id      := NULL;
                vn_location_id        := NULL;

                vr_vendor_site_rec.VENDOR_ID        := vn_vendor_id;
                vr_vendor_site_rec.ATTRIBUTE4       := 'P'||l_emp.employee_number;
                vr_vendor_site_rec.ACCTS_PAY_CODE_COMBINATION_ID := vn_ACCTS_PAY_CCID;
                vr_vendor_site_rec.PREPAY_CODE_COMBINATION_ID    := vn_PREPAY_CCID;
                vr_vendor_site_rec.ORG_ID           := vn_task_org_projet_id;

                vr_vendor_site_rec.VENDOR_SITE_CODE := gv_vendor_site_code;
                vr_vendor_site_rec.COUNTRY          := gv_vendor_site_ctry;
                vr_vendor_site_rec.ADDRESS_LINE1    := '.';
                vr_vendor_site_rec.PAY_GROUP_LOOKUP_CODE :=   gv_pay_group_lookup_code;
                vr_vendor_site_rec.PAYMENT_PRIORITY := gn_payment_priority;
                vr_vendor_site_rec.TERMS_ID         := gn_term_id;

                vr_vendor_site_rec.INVOICE_CURRENCY_CODE  := vv_currency_code;
                vr_vendor_site_rec.PAYMENT_CURRENCY_CODE  := vv_currency_code;
                vr_vendor_site_rec.PAY_DATE_BASIS_LOOKUP_CODE := gv_pay_date_basis_lookup_code;
                vr_vendor_site_rec.TERMS_DATE_BASIS           := gv_terms_date_basis;
                --vr_vendor_site_rec.ext_payee_rec.default_pmt_method := gv_payment_method_cheque; --On crée le fournisseur avec la methode CHECK
                --                                                                      --qu'on mettra a jour apres la rattachement
                --                                                                      --d'un compte bancaire s'il existe
                vr_vendor_site_rec.Purchasing_site_flag          := 'N';
                vr_vendor_site_rec.pay_site_flag                 := 'Y';
                vr_vendor_site_rec.attention_ar_flag             := 'N';
                vr_vendor_site_rec.rfq_only_site_flag            := 'N';
                vr_vendor_site_rec.always_take_disc_flag         := 'N';
                vr_vendor_site_rec.hold_all_payments_flag        := 'N';
                vr_vendor_site_rec.hold_future_payments_flag     := 'N';
                vr_vendor_site_rec.hold_unmatched_invoices_flag  := 'N';
                vr_vendor_site_rec.exclude_freight_from_discount := 'N';
                vr_vendor_site_rec.auto_tax_calc_flag            := 'Y';
                vr_vendor_site_rec.match_option                  := 'P';

                --///Création du site fournisseur - API
                gv_step  := lv_current_program_unit||' 055 : Création du site fournisseur - API';log_message(gv_step);
                ap_vendor_pub_pkg.create_vendor_site (vn_api_version,
                                                      vv_init_msg_list,
                                                      vv_commit,
                                                      vn_validation_level,
                                                      vv_return_status,
                                                      vn_msg_count,
                                                      vv_msg_data,
                                                      vr_vendor_site_rec,
                                                      vn_vendor_site_id,
                                                      vn_party_site_id,
                                                      vn_location_id
                                                       );

                IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  --On continue
                  gv_step  := lv_current_program_unit||' 056 : Création du site fournisseur - API : Success';log_message(gv_step);
                  NULL;
                ELSE
                  vv_message := '';
                  IF vn_msg_count > 0 THEN

                    FOR v_index IN 1 .. vn_msg_count LOOP
                      fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                      vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                    END LOOP;

                  END IF;

                  --Création du site fournisseur impossible : message
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0016',
                                                           'EMPNUM',l_emp.employee_number,
                                                           'MESSAGE',vv_message);
                  log_message(vv_message);
                  vv_type     := 'P';
                  RAISE e_emp_error;
                log_message(SQLERRM);
                END IF;

                --######################################################################################
                --AJOUT DU LOCATION_ID
                --######################################################################################

                gv_step  := lv_current_program_unit||' 056A : Création du LOCATION_ID - API';log_message(gv_step);
                vr_location_rec.country := gv_vendor_site_ctry;
                vr_location_rec.address1 := '.';
                vr_location_rec.created_by_module := 'TCA_V2_API';

                hz_location_v2pub.create_location (p_init_msg_list      => vv_init_msg_list,
                                                   p_location_rec       => vr_location_rec,
                                                   x_location_id        => vn_location_id,
                                                   x_return_status      => vv_return_status,
                                                   x_msg_count          => vn_msg_count,
                                                   x_msg_data           => vv_msg_data
                                                  );
                IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  --On continue
                  gv_step  := lv_current_program_unit||' 056A : Création du LOCATION_ID - API : Success';log_message(gv_step);
                  NULL;
                ELSE
                  vv_message := '';
                  IF vn_msg_count > 0 THEN

                    FOR v_index IN 1 .. vn_msg_count LOOP
                      fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                      vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                    END LOOP;

                  END IF;

                  --Création du lieu fournisseur impossible : message
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0059',
                                                           'EMPNUM',l_emp.employee_number,
                                                           'MESSAGE',vv_message);
                  vv_type     := 'P';
                  RAISE e_emp_error;

                END IF;

                gv_step  := lv_current_program_unit||' 056C : Maj du site fournisseur avec LOCATION_ID - API';log_message(gv_step);

                vr_vendor_site_rec                := NULL;
                vr_vendor_site_rec.vendor_id      := vn_vendor_id;
                vr_vendor_site_rec.org_id         := vn_task_org_projet_id;
                vr_vendor_site_rec.vendor_site_id := vn_vendor_site_id;
                vr_vendor_site_rec.location_id    := vn_location_id;

                ap_vendor_pub_pkg.Update_Vendor_Site
                                               (p_api_version          => vn_api_version,
                                                x_return_status        => vv_return_status,
                                                x_msg_count            => vn_msg_count,
                                                x_msg_data             => vv_msg_data,
                                                p_vendor_site_rec      => vr_vendor_site_rec,
                                                p_vendor_site_id       => vn_vendor_site_id
                                               );

                IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  --On continue
                  gv_step  := lv_current_program_unit||' 056C : Maj du site fournisseur avec LOCATION_ID - API : Success';log_message(gv_step);

                  NULL;
                ELSE
                  vv_message := '';
                  IF vn_msg_count > 0 THEN

                    FOR v_index IN 1 .. vn_msg_count LOOP
                      fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                      vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                    END LOOP;

                  END IF;

                  --Mise a jour du site fournisseur avec LOCATION_ID impossible : message
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0061',
                                                           'EMPNUM',l_emp.employee_number,
                                                           'MESSAGE',vv_message);
                  vv_type     := 'P';
                  RAISE e_emp_error;

                END IF;

              ELSE
                --Le site existe déja, on ne fait rien
                gv_step  := lv_current_program_unit||' 057 : Le site fournisseur existe déja, on ne fait rien';log_message(gv_step);
              END IF;

            insert_error(vv_emp_num,vv_table,vn_table_id,'S',
                         'Mise a jour employé (Site fournisseur) terminée : '||vv_emp_num||' avec succes',gv_step,vv_source);

            flag_traite(pv_employee_number    => vv_emp_num,
                        pv_insert_update_flag => 'U',
                        pv_table_name         => vv_table,
                        pv_source             => vv_source);

          EXCEPTION
           WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            ROLLBACK TO SAVE_EMPLOYE;
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
          END;

          --######################################################################################
          --MISE A JOUR COMPTE BANCAIRE EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 058 : Mise a jour compte bancaire employe';log_message(gv_step);

          gv_step  := lv_current_program_unit||' 059 : reintialisation SAVEPOINT SAVE_EMPLOYE';log_message(gv_step);
          SAVEPOINT SAVE_EMPLOYE;

          BEGIN

            gv_step  := lv_current_program_unit||' 060 : sélection des donnée bancaire de l''employé : '||lt_employe(i);log_message(gv_step);
            BEGIN
              SELECT *
              INTO l_bank
              FROM
               XXEAI_HR_BANK_INT_ALL HBI
              WHERE
                   HBI.INSERT_UPDATE_FLAG = 'U'
               AND HBI.INTERFACE_STATUS != 'ERROR'
               AND HBI.EMPLOYEE_NUMBER = vv_emp_num
              ;

              vb_info_bank := TRUE;

            EXCEPTION
             WHEN NO_DATA_FOUND THEN
              --Pas d'info bank
              vb_info_bank := false;
             WHEN TOO_MANY_ROWS THEN
              --Mise a jour de l'employé impossible : Doublon dans les infos bank
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0048','EMPNUM',l_emp.EMPLOYEE_NUMBER);
              vv_type     := 'P';
              raise e_emp_error;
            END;

            IF vb_info_bank THEN
              gv_step  := lv_current_program_unit||' 061 : Info bancaire présente';log_message(gv_step);

              --Init pour message
              vv_table    := 'XXEAI_HR_BANK_INT_ALL';
              vn_table_id := l_bank.XXEAI_BANK_ID ;

              --Recherche de la tache du projet
              gv_step  := lv_current_program_unit||' 062 : Recherche de la tache du projet';log_message(gv_step);
              get_assign_info(l_emp.employee_number,
                              vn_assignment_id,
                              vn_asg_object_version_number,
                              vd_ass_start_date,
                              vd_ass_end_date,
                              vn_job_id,
                              vv_job_name,
                              vv_fct,
                              vn_organization_id,
                              vv_organization_name,
                              vn_supervisor_id,
                              vv_ass_attribute1,
                              vv_ass_attribute2,
                              vv_ass_attribute3,
                              vv_ass_attribute4,
                              vv_ass_attribute5);


              IF vn_asg_object_version_number IS NULL THEN
                --Mise a jour de l'employé impossible : Recherche l'affectation employé en erreur
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0049',
                                                         'EMPNUM',l_emp.EMPLOYEE_NUMBER);
                vv_type     := 'P';
                raise e_emp_error;

              END IF;

              --Recherche des infos de la tache du projet
              gv_step  := lv_current_program_unit||' 063 : Recherche des infos de la tache du projet';log_message(gv_step);
              DKA_PA_TOOLS_PKG.pa_get_info_task(vv_errbuf,
                                                vn_retcode,
                                                vv_ass_attribute5,
                                                vv_task_id,
                                                vn_task_project_id,
                                                vv_task_project_name,
                                                vv_task_project_type,
                                                vd_task_start_date,
                                                vd_task_completion_date,
                                                vd_task_closed_date,
                                                vv_task_org_projet,
                                                vn_task_org_projet_id,
                                                vv_task_societe,
                                                vv_task_region,
                                                vv_task_org_fin,
                                                vn_task_org_fin_id);

              IF vn_retcode != 0 THEN
                 --Mise a jour de l'employé impossible : Erreur lors de la détermination des informations projet
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0050',
                                                         'EMPNUM',l_emp.employee_number,
                                                         'TACHE',l_assignment.ass_attribute5,'MESSAGE',vv_errbuf);
                vv_type     := 'P';
                raise e_emp_error;
              END IF;

              --Recherche du fournisseur et site fournisseur
              gv_step  := lv_current_program_unit||' 064 : Recherche du fournisseur et site fournisseur';log_message(gv_step);
              get_supplier_site_info(vn_person_id,vn_task_org_projet_id, vn_vendor_id , vn_party_id,vn_vendor_site_id,vn_party_site_id );
              IF vn_vendor_id IS NULL THEN
                --Mise a jour de l'employé impossible : Recherche du fournisseur / site fournisseur en erreur
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0051',
                                                         'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                         'ORG',vv_task_org_projet);
                vv_type     := 'P';
                raise e_emp_error;
              END IF;

              --Entité comptable
              gv_step  := lv_current_program_unit||' 065 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
              vn_ledger_id := dka_gl_tools_pkg.get_legder_id(vv_task_societe);

              IF vn_ledger_id IS NULL THEN
                 --Mise a jour employé impossible, entité comptable n'existe pas pour la société
                 vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0052',
                                                          'EMPNUM',l_emp.employee_number,
                                                          'SOCIETE',vv_task_societe);
                 vv_type     := 'P';
                 RAISE e_emp_error;
              END IF;

              --Devise Entité comptable
              gv_step  := lv_current_program_unit||' 066 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
              vv_currency_code := get_currency_code(vn_ledger_id);

              IF vv_currency_code IS NULL THEN
                 --Mise a jour employé impossible : Erreur sur la devise de l'entité comptable
                 vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0047',
                                                          'EMPNUM',l_emp.employee_number,
                                                          'SOCIETE',vv_task_societe);
                 vv_type     := 'P';
                 RAISE e_emp_error;
              END IF;

              --Existence BANQUE/AGENCE
              gv_step  := lv_current_program_unit||' 067 : Existence BANQUE/AGENCE';log_message(gv_step);
              get_bank_info ( pv_bank_number   => l_bank.bank_number,
                              pv_branch_number => l_bank.bank_num,
                              pn_bank_id       => vn_bank_id,
                              pn_branch_id     => vn_branch_id
                                  );

              IF vn_bank_id IS NULL THEN
                --Mise a jour employé impossible :La banque n'existe pas ou est inactive
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0053',
                                                         'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                         'BANKNUM',l_bank.bank_number,
                                                         'BRANCHNUM',l_bank.bank_num);
                vv_type     := 'P';
                raise e_emp_error;

              END IF;

              --Existence du compte bancaire
              gv_step  := lv_current_program_unit||' 068 : compte bancaire';log_message(gv_step);
              get_info_compte_bank(pn_bank_id       => vn_bank_id,
                                   pn_branch_id     => vn_branch_id,
                                   pv_iban          => l_bank.iban_number,
                                   pv_country       => l_bank.bank_branch_country,
                                   pv_type          => 'SUPPLIER',
                                   pn_bank_acct_id  => vn_bank_acct_id);


              --Recherche du compte actuel sur le site
              gv_step  := lv_current_program_unit||' 069 : Recherche du compte actuel sur le site';log_message(gv_step);
              get_info_acct_emp (vn_party_id,vn_vendor_site_id,vn_party_site_id,vn_exist_bank_acct_id,vd_bk_start_date,vn_bk_object_version_number);

              gv_step  := lv_current_program_unit||' 069 : vn_exist_bank_acct_id : '||vn_exist_bank_acct_id;log_message(gv_step);
              gv_step  := lv_current_program_unit||' 069 : vn_bank_acct_id : '||vn_bank_acct_id;log_message(gv_step);

              IF nvl(vn_exist_bank_acct_id,-1) != nvl(vn_bank_acct_id,-1) THEN
                --Changement du compte bancaire, on désactive l'ancien

                IF vn_exist_bank_acct_id IS NOT NULL THEN

                  --Init valeur API
                  vn_api_version       := 1.0;
                  vv_init_msg_list     := FND_API.G_TRUE;
                  vv_commit            := FND_API.G_FALSE;
                  vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                  vv_return_status     := NULL;
                  vn_msg_count         := NULL;
                  vv_msg_data          := NULL;

                  gv_step  := lv_current_program_unit||' 070 : Mise a jour de la date de fin du compte bancaire - API';log_message(gv_step);
                  IBY_EXT_BANKACCT_PUB.set_ext_bank_acct_dates(p_api_version           => vn_api_version,
                                                               p_init_msg_list         => vv_init_msg_list,
                                                               p_acct_id               => vn_exist_bank_acct_id,
                                                               p_start_date            => vd_bk_start_date,
                                                               p_end_date              => sysdate-1,
                                                               p_object_version_number => vn_bk_object_version_number,
                                                               x_return_status         => vv_return_status,
                                                               x_msg_count             => vn_msg_count,
                                                               x_msg_data              => vv_msg_data,
                                                               x_response              => vr_response
                                                              );

                  IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                    --On continue
                    gv_step  := lv_current_program_unit||' 071 : Mise a jour de la date de fin du compte bancaire - API : Success';log_message(gv_step);

                  ELSE
                    vv_message := '';
                    IF fnd_msg_pub.count_msg > 0 THEN

                      FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                        vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                      END LOOP;

                    END IF;

                    --Mise a jour de la date de fin du compte bancaire impossible : message
                    vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0054',
                                                             'EMPNUM',l_emp.employee_number,
                                                             'IBAN',l_bank.iban_number,
                                                             'MESSAGE',substr(vv_message,1,500));
                    vv_type     := 'P';
                    RAISE e_emp_error;

                  END IF;

                END IF; --vn_exist_bank_acct_id IS NOT NULL
              ELSE
                --Meme compte, on ne fait rien
                gv_step  := lv_current_program_unit||' 072 : Meme compte bancaire ou précédent inexistant';log_message(gv_step);
              END IF;

              IF vn_bank_acct_id IS NULL THEN
                --Création du compte bancaire
                gv_step  := lv_current_program_unit||' 073 : Création du compte bancaire';log_message(gv_step);

                vr_ext_bank_acct_rec.object_version_number    := 1.0;
                vr_ext_bank_acct_rec.acct_owner_party_id      := vn_party_id; --site
                vr_ext_bank_acct_rec.bank_account_name        := l_bank.bank_account_name;
                vr_ext_bank_acct_rec.bank_account_num         := l_bank.bank_account_num;
                vr_ext_bank_acct_rec.alternate_acct_name      := NULL;
                vr_ext_bank_acct_rec.bank_id                  := vn_bank_id ;
                vr_ext_bank_acct_rec.branch_id                := vn_branch_id ;
                vr_ext_bank_acct_rec.start_date               := TRUNC(SYSDATE);
                vr_ext_bank_acct_rec.acct_type                := 'SUPPLIER';
                vr_ext_bank_acct_rec.country_code             := gv_vendor_site_ctry;
                vr_ext_bank_acct_rec.currency                 := vv_currency_code;
                vr_ext_bank_acct_rec.iban                     := l_bank.iban_number;

                --Init valeur API
                vn_api_version       := 1.0;
                vv_init_msg_list     := FND_API.G_TRUE;
                vv_commit            := FND_API.G_FALSE;
                vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                vv_return_status     := NULL;
                vn_msg_count         := NULL;
                vv_msg_data          := NULL;
                vv_association_level := 'SS';
                vv_org_type          := 'OPERATING_UNIT';

                --Création COMPTE
                gv_step  := lv_current_program_unit||' 074 : Création du compte bancaire - API';log_message(gv_step);
                IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT (p_api_version            => vn_api_version,
                                                           p_init_msg_list          => vv_init_msg_list,
                                                           p_ext_bank_acct_rec      => vr_ext_bank_acct_rec,
                                                           p_association_level      => vv_association_level,
                                                           p_supplier_site_id       => vn_vendor_site_id,
                                                           p_party_site_id          => NULL,
                                                           p_org_id                 => vn_task_org_projet_id,
                                                           p_org_type               => vv_org_type,
                                                           x_acct_id                => vn_acct_id,
                                                           x_return_status          => vv_return_status,
                                                           x_msg_count              => vn_msg_count,
                                                           x_msg_data               => vv_msg_data,
                                                           x_response               => vr_response
                                                          );

                IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  --On continue
                  gv_step  := lv_current_program_unit||' 075 : Création du compte bancaire - API : Success';log_message(gv_step);

                  vn_bank_acct_id:= vn_acct_id;

                  NULL;
                ELSE
                  vv_message := '';
                  IF fnd_msg_pub.count_msg > 0 THEN

                    FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                      vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                    END LOOP;

                  END IF;

                  --Création du compte bancaire impossible : message
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0055',
                                                           'EMPNUM',l_emp.employee_number,
                                                           'IBAN',l_bank.iban_number,
                                                           'MESSAGE',substr(vv_message,1,500));
                  vv_type     := 'P';
                  RAISE e_emp_error;

                END IF;

              ELSE --vn_bank_acct_id IS NULL
                gv_step  := lv_current_program_unit||' 076 : Rattachement du compte bancaire : '||vn_bank_acct_id;log_message(gv_step);


                vn_api_version       := 1.0;
                vv_init_msg_list     := FND_API.G_TRUE;
                vv_commit            := FND_API.G_FALSE;
                vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                vv_return_status     := NULL;
                vn_msg_count         := NULL;
                vv_msg_data          := NULL;

                --Rattachement du compte bancaire
                gv_step  := lv_current_program_unit||' 077 : Controle proprietaire compte bancaire - API';log_message(gv_step);
                IBY_EXT_BANKACCT_PUB.check_bank_acct_owner   (p_api_version         => vn_api_version,
                                                              p_init_msg_list       => FND_API.G_TRUE,
                                                              p_bank_acct_id        => vn_bank_acct_id,
                                                              p_acct_owner_party_id => vn_party_id,  --site
                                                              x_return_status       => vv_return_status,
                                                              x_msg_count           => vn_msg_count,
                                                              x_msg_data            => vv_msg_data,
                                                              x_response            => vr_response
                                                              );

                IF  vv_return_status <> 'S' THEN
                  gv_step  := lv_current_program_unit||' 078 : Controle proprietaire compte bancaire KO';log_message(gv_step);


                  vn_api_version       := 1.0;
                  vv_init_msg_list     := FND_API.G_TRUE;
                  vv_commit            := FND_API.G_FALSE;
                  vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                  vv_return_status     := NULL;
                  vn_msg_count         := NULL;
                  vv_msg_data          := NULL;

                  vn_joint_acct_id     := NULL;

                  gv_step  := lv_current_program_unit||' 079 : liaison compte bancaire - API';log_message(gv_step);
                  IBY_EXT_BANKACCT_PUB.add_joint_account_owner( p_api_version         => vn_api_version,
                                                                p_init_msg_list       => vv_init_msg_list,
                                                                p_bank_account_id     => vn_bank_acct_id,
                                                                p_acct_owner_party_id => vn_party_id,    --site
                                                                x_joint_acct_owner_id => vn_joint_acct_id,
                                                                x_return_status       => vv_return_status,
                                                                x_msg_count           => vn_msg_count,
                                                                x_msg_data            => vv_msg_data,
                                                                x_response            => vr_response
                                                               );

                  IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                    --On continue
                    gv_step  := lv_current_program_unit||' 080 : liaison compte bancaire - API : Success';log_message(gv_step);
                    NULL;
                  ELSE
                    vv_message := '';
                    IF fnd_msg_pub.count_msg > 0 THEN

                      FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                        vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                      END LOOP;

                    END IF;

                    --Rattachement du compte bancaire impossible : message
                    vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0056',
                                                             'EMPNUM',l_emp.employee_number,
                                                             'IBAN',l_bank.iban_number,
                                                             'MESSAGE',substr(vv_message,1,500));
                    vv_type     := 'P';
                    RAISE e_emp_error;

                  END IF;

                ELSE

                  --Cet employé est déja propriétaire de son compte bancaire
                  gv_step  := lv_current_program_unit||' 081 : Controle proprietaire compte bancaire OK';log_message(gv_step);
                  NULL;

                END IF;

              END IF; --vn_bank_acct_id IS NULL

              --//Finalisation lien site - employé
              gv_step  := lv_current_program_unit||' 082 : Finalisation lien site - employé';log_message(gv_step);

              vn_api_version       := 1.0;
              vv_init_msg_list     := FND_API.G_TRUE;
              vv_commit            := FND_API.G_FALSE;
              vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
              vv_return_status     := NULL;
              vn_msg_count         := NULL;
              vv_msg_data          := NULL;

              vr_payee_context_rec.Party_Id                     := vn_party_id;
              vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
              vr_payee_context_rec.party_site_id                := vn_party_site_id;
              vr_payee_context_rec.Supplier_Site_id             := vn_vendor_site_id;
              vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
              vr_payee_context_rec.Org_Id                       := vn_task_org_projet_id;

              vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
              vr_assignment_attribs.instrument.instrument_id    := vn_bank_acct_id;
              vr_assignment_attribs.start_date                  := TRUNC(SYSDATE);

              -- map account to site supplier
              gv_step  := lv_current_program_unit||' 083 : Finalisation lien site - employé - API';log_message(gv_step);
              IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => vn_api_version,
                                                                     p_init_msg_list      => vv_init_msg_list,
                                                                     p_commit             => vv_commit,
                                                                     x_return_status      => vv_return_status,
                                                                     x_msg_count          => vn_msg_count,
                                                                     x_msg_data           => vv_msg_data,
                                                                     p_payee              => vr_payee_context_rec,
                                                                     p_assignment_attribs => vr_assignment_attribs,
                                                                     x_assign_id          => vn_assign_id,
                                                                     x_response           => vr_response
                                                                     );

              IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                --On continue
                gv_step  := lv_current_program_unit||' 084 : Finalisation lien site - employé - API : Success';log_message(gv_step);
                NULL;
              ELSE
                vv_message := '';
                IF fnd_msg_pub.count_msg > 0 THEN

                  FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                    vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                  END LOOP;

                END IF;

                --Rattachement du compte bancaire au site employé impossible : message
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0057',
                                                         'EMPNUM',l_emp.employee_number,
                                                         'IBAN',l_bank.iban_number,
                                                         'MESSAGE',substr(vv_message,1,500));
                vv_type     := 'P';
                RAISE e_emp_error;

              END IF;

              gv_step  := lv_current_program_unit||' 085 : Mode de reglement = EFT';log_message(gv_step);
              vv_payment_method := gv_payment_method_virement;

            ELSE --vb_info_bank
                --Pas d'information banque
                gv_step  := lv_current_program_unit||' 089 : Pas d''information banque';log_message(gv_step);
                gv_step  := lv_current_program_unit||' 090 : Mode de reglement = CHECK';log_message(gv_step);
                vv_payment_method := gv_payment_method_cheque;

                --ywa RG_U17

                IF NOT vv_ne_rien_faire and vn_vendor_site_id_old IS NOT NULL THEN
                    get_info_acct_emp (vn_party_id_old,vn_vendor_site_id_old,vn_party_site_id_old,vn_bank_acct_id_old,vd_bk_start_date_old,vn_bk_object_version_number_od);
                    IF vn_bank_acct_id_old IS NOT NULL THEN
                        gv_step  := lv_current_program_unit||' 090.1 : vn_bank_acct_id_old : '||vn_bank_acct_id_old;log_message(gv_step);
                        gv_step  := lv_current_program_unit||' 090.2 : Rattachement du compte bancaire : '||vn_bank_acct_id_old;log_message(gv_step);

                        vn_api_version       := 1.0;
                        vv_init_msg_list     := FND_API.G_TRUE;
                        vv_commit            := FND_API.G_FALSE;
                        vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                        vv_return_status     := NULL;
                        vn_msg_count         := NULL;
                        vv_msg_data          := NULL;

                        --Rattachement du compte bancaire
                        gv_step  := lv_current_program_unit||' 090.3 : Controle proprietaire compte bancaire - API';log_message(gv_step);
                        IBY_EXT_BANKACCT_PUB.check_bank_acct_owner   (p_api_version         => vn_api_version,
                                                                      p_init_msg_list       => FND_API.G_TRUE,
                                                                      p_bank_acct_id        => vn_bank_acct_id_old,
                                                                      p_acct_owner_party_id => vn_party_id,  --site
                                                                      x_return_status       => vv_return_status,
                                                                      x_msg_count           => vn_msg_count,
                                                                      x_msg_data            => vv_msg_data,
                                                                      x_response            => vr_response
                                                                      );

                        IF  vv_return_status <> 'S' THEN
                            gv_step  := lv_current_program_unit||' 090.4 : Controle proprietaire compte bancaire KO';log_message(gv_step);


                            vn_api_version       := 1.0;
                            vv_init_msg_list     := FND_API.G_TRUE;
                            vv_commit            := FND_API.G_FALSE;
                            vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                            vv_return_status     := NULL;
                            vn_msg_count         := NULL;
                            vv_msg_data          := NULL;

                            vn_joint_acct_id     := NULL;

                            gv_step  := lv_current_program_unit||' 090.5 : liaison compte bancaire - API';log_message(gv_step);
                            IBY_EXT_BANKACCT_PUB.add_joint_account_owner( p_api_version         => vn_api_version,
                                                                        p_init_msg_list       => vv_init_msg_list,
                                                                        p_bank_account_id     => vn_bank_acct_id_old,
                                                                        p_acct_owner_party_id => vn_party_id,    --site
                                                                        x_joint_acct_owner_id => vn_joint_acct_id,
                                                                        x_return_status       => vv_return_status,
                                                                        x_msg_count           => vn_msg_count,
                                                                        x_msg_data            => vv_msg_data,
                                                                        x_response            => vr_response
                                                                       );

                            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                                --On continue
                                gv_step  := lv_current_program_unit||' 090.6 : liaison compte bancaire - API : Success';log_message(gv_step);
                                NULL;
                            ELSE
                                vv_message := '';
                                IF fnd_msg_pub.count_msg > 0 THEN

                                    FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                                         vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                                    END LOOP;

                                END IF;

                                --Rattachement du compte bancaire impossible : message
                                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0056',
                                                                         'EMPNUM',l_emp.employee_number,
                                                                         'IBAN',l_bank.iban_number,
                                                                         'MESSAGE',substr(vv_message,1,500));
                                vv_type     := 'P';
                                RAISE e_emp_error;

                            END IF;

                        ELSE

                            --Cet employé est déja propriétaire de son compte bancaire
                            gv_step  := lv_current_program_unit||' 090.7 : Controle proprietaire compte bancaire OK';log_message(gv_step);
                            NULL;

                        END IF;


                        --//Finalisation lien site - employé
                        gv_step  := lv_current_program_unit||' 090.8 : Finalisation lien site - employé';log_message(gv_step);

                        vn_api_version       := 1.0;
                        vv_init_msg_list     := FND_API.G_TRUE;
                        vv_commit            := FND_API.G_FALSE;
                        vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                        vv_return_status     := NULL;
                        vn_msg_count         := NULL;
                        vv_msg_data          := NULL;

                        vr_payee_context_rec.Party_Id                     := vn_party_id;
                        vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
                        vr_payee_context_rec.party_site_id                := vn_party_site_id;
                        vr_payee_context_rec.Supplier_Site_id             := vn_vendor_site_id;
                        vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
                        vr_payee_context_rec.Org_Id                       := vn_task_org_projet_id;

                        vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
                        vr_assignment_attribs.instrument.instrument_id    := vn_bank_acct_id_old;
                        vr_assignment_attribs.start_date                  := TRUNC(SYSDATE);

                        -- map account to site supplier
                        gv_step  := lv_current_program_unit||' 090.9 : Finalisation lien site - employé - API';log_message(gv_step);
                        IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => vn_api_version,
                                                                             p_init_msg_list      => vv_init_msg_list,
                                                                             p_commit             => vv_commit,
                                                                             x_return_status      => vv_return_status,
                                                                             x_msg_count          => vn_msg_count,
                                                                             x_msg_data           => vv_msg_data,
                                                                             p_payee              => vr_payee_context_rec,
                                                                             p_assignment_attribs => vr_assignment_attribs,
                                                                             x_assign_id          => vn_assign_id,
                                                                             x_response           => vr_response
                                                                             );

                        IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                            --On continue
                            gv_step  := lv_current_program_unit||' 090.10 : Finalisation lien site - employé - API : Success';log_message(gv_step);
                            NULL;
                        ELSE
                            vv_message := '';
                            IF fnd_msg_pub.count_msg > 0 THEN

                                FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                                    vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                                END LOOP;

                            END IF;

                            --Rattachement du compte bancaire au site employé impossible : message
                            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0057',
                                                                     'EMPNUM',l_emp.employee_number,
                                                                     'IBAN',l_bank.iban_number,
                                                                     'MESSAGE',substr(vv_message,1,500));
                            vv_type     := 'P';
                            RAISE e_emp_error;

                        END IF;
                        gv_step  := lv_current_program_unit||' 090.11 : Mode de reglement = EFT';log_message(gv_step);
                        vv_payment_method := gv_payment_method_virement;
                    ELSE
                        gv_step  := lv_current_program_unit||' 090.12 : le site fournisseur de l''affectation précédente n''a pas de compte bancaire';log_message(gv_step);
                    END IF;
                END IF;
              --YWA RG_U17


            END IF;

            --Modification site fournisseur
            gv_step  := lv_current_program_unit||' 091 : Modification site fournisseur : EFT';log_message(gv_step);

            vn_api_version      := 1.0;
            vv_init_msg_list    := FND_API.G_TRUE;
            vv_commit           := FND_API.G_FALSE;
            vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
            vv_return_status    := NULL;
            vn_msg_count        := NULL;
            vv_msg_data         := NULL;

            vn_ext_payee_id := NULL;
            vt_External_Payee_Tab_Type.DELETE;
            vt_Ext_Payee_ID_Tab_Type.DELETE;
            vt_Ext_Payee_Update_Tab_Type.DELETE;
            vt_Ext_Payee_Create_Tab_Type.DELETE;

            BEGIN

              SELECT
                   payee.EXT_PAYEE_ID,
                   payee.payee_party_id,
                   payee.PAYMENT_FUNCTION,
                   payee.ORG_ID,
                   payee.org_type,
                   payee.SUPPLIER_SITE_ID,
                   assa.party_site_id
              INTO
                   vn_ext_payee_id,
                   vr_External_Payee_Rec.payee_party_id,
                   vr_External_Payee_Rec.payment_function,
                   vr_External_Payee_Rec.payer_org_id,
                   vr_External_Payee_Rec.payer_org_type,
                   vr_External_Payee_Rec.supplier_site_id,
                   vr_External_Payee_Rec.Payee_Party_Site_Id
              FROM iby_external_payees_all  payee,
                   ap_supplier_sites_all    assa
             WHERE payee.payment_function = 'PAYABLES_DISB'
               AND payee.supplier_site_id = vn_vendor_site_id
               AND payee.supplier_site_id = assa.vendor_site_id;

            EXCEPTION
             WHEN TOO_MANY_ROWS THEN
              BEGIN
                SELECT
                     payee.EXT_PAYEE_ID,
                     payee.payee_party_id,
                     payee.PAYMENT_FUNCTION,
                     payee.ORG_ID,
                     payee.org_type,
                     payee.SUPPLIER_SITE_ID,
                     assa.party_site_id
                INTO
                     vn_ext_payee_id,
                     vr_External_Payee_Rec.payee_party_id,
                     vr_External_Payee_Rec.payment_function,
                     vr_External_Payee_Rec.payer_org_id,
                     vr_External_Payee_Rec.payer_org_type,
                     vr_External_Payee_Rec.supplier_site_id,
                     vr_External_Payee_Rec.Payee_Party_Site_Id
                FROM iby_external_payees_all  payee,
                     ap_supplier_sites_all    assa
               WHERE payee.payment_function = 'PAYABLES_DISB'
                 AND payee.supplier_site_id = vn_vendor_site_id
                 AND payee.supplier_site_id = assa.vendor_site_id
                 AND (payee.party_site_id = assa.party_site_id or payee.party_site_id IS NULL)
                 AND payee.EXT_PAYEE_ID = (select max(iep.EXT_PAYEE_ID)
                                           from iby_external_payees_all iep
                                           where iep.supplier_site_id = vn_vendor_site_id)
                  ;
              EXCEPTION
                WHEN OTHERS THEN
                  --Modification de la methode de paiement du site fournisseur impossible : message
                  vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0058',
                                                           'EMPNUM',l_emp.employee_number,
                                                           'MESSAGE','Erreur lors de la recherche des informations bancaires (TOO_MANY_ROWS) :'||SQLERRM);
                  vv_type     := 'P';
                  RAISE e_emp_error;
                END;
             WHEN OTHERS THEN
              --Modification de la methode de paiement du site fournisseur impossible : message
              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0058',
                                                       'EMPNUM',l_emp.employee_number,
                                                       'MESSAGE','Erreur lors de la recherche des informations bancaires (OTHERS) :'||SQLERRM);
              vv_type     := 'P';
              RAISE e_emp_error;
            END;

            vr_External_Payee_Rec.default_pmt_method := vv_payment_method;
            vr_External_Payee_Rec.exclusive_pay_flag := 'N';

            vt_External_Payee_Tab_Type(1):= vr_External_Payee_Rec;

            vt_Ext_Payee_ID_Tab_Type(1).ext_payee_id := vn_ext_payee_id;

            IF vv_payment_method =  gv_payment_method_cheque THEN
              --CHECK CREATION
              gv_step  := lv_current_program_unit||' 092 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee - API';log_message(gv_step);
              IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee(p_api_version           => vn_api_version,
                                                               p_init_msg_list         => vv_init_msg_list,
                                                               p_ext_payee_tab         => vt_External_Payee_Tab_Type,
                                                               x_return_status         => vv_return_status,
                                                               x_msg_count             => vn_msg_count,
                                                               x_msg_data              => vv_msg_data,
                                                               x_ext_payee_id_tab      => vt_Ext_Payee_ID_Tab_Type,
                                                               x_ext_payee_status_tab  => vt_Ext_Payee_Create_Tab_Type
                                                            );

              IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                --On continue
                gv_step  := lv_current_program_unit||' 092 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee - API : Success';log_message(gv_step);
                NULL;
              ELSE
                vv_message := '';
                IF vn_msg_count > 0 THEN

                  FOR v_index IN 1 .. vn_msg_count LOOP
                    fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                    vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                  END LOOP;

                END IF;

                --Error Message from table type
                IF vt_Ext_Payee_Create_Tab_Type.count > 0 THEN
                  FOR j IN vt_Ext_Payee_Create_Tab_Type.FIRST .. vt_Ext_Payee_Create_Tab_Type.LAST LOOP
                    vv_message := substr(vv_message || chr(10) ||  vt_Ext_Payee_Create_Tab_Type (j).Payee_Creation_Msg,1,500);
                  END LOOP;
                END IF;

                --Modification de la methode de paiement du site fournisseur impossible : message
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0058',
                                                         'EMPNUM',l_emp.employee_number,
                                                         'MESSAGE',vv_message);
                vv_type     := 'P';
                RAISE e_emp_error;

              END IF;

            ELSIF vv_payment_method =  gv_payment_method_virement THEN
              --EFT - UPDATE
              vt_Ext_Payee_ID_Tab_Type(1).ext_payee_id := vn_ext_payee_id;


              gv_step  := lv_current_program_unit||' 092 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API';log_message(gv_step);
              IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee(p_api_version           => vn_api_version,
                                                               p_init_msg_list         => vv_init_msg_list,
                                                               p_ext_payee_tab         => vt_External_Payee_Tab_Type,
                                                               p_ext_payee_id_tab      => vt_Ext_Payee_ID_Tab_Type,
                                                               x_return_status         => vv_return_status,
                                                               x_msg_count             => vn_msg_count,
                                                               x_msg_data              => vv_msg_data,
                                                               x_ext_payee_status_tab  => vt_Ext_Payee_Update_Tab_Type
                                                            );



              IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                --On continue
                gv_step  := lv_current_program_unit||' 092 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API : Success';log_message(gv_step);
                NULL;
              ELSE
                vv_message := '';
                IF vn_msg_count > 0 THEN

                  FOR v_index IN 1 .. vn_msg_count LOOP
                    fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                    vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                  END LOOP;

                END IF;

                --Error Message from table type
                IF vt_Ext_Payee_Update_Tab_Type.count > 0 THEN
                  FOR j IN vt_Ext_Payee_Update_Tab_Type.FIRST .. vt_Ext_Payee_Update_Tab_Type.LAST LOOP
                    vv_message := substr(vv_message || chr(10) ||  vt_Ext_Payee_Update_Tab_Type (j).payee_update_msg,1,500);
                  END LOOP;
                END IF;

                --Modification de la methode de paiement du site fournisseur impossible : message
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0058',
                                                         'EMPNUM',l_emp.employee_number,
                                                         'MESSAGE',vv_message);
                vv_type     := 'P';
                RAISE e_emp_error;

              END IF;
            END IF; --vv_payment_method


            -- Mise a jour des factures non réglées
            IF nvl(vn_exist_bank_acct_id,-1) != vn_bank_acct_id AND
               vv_payment_method = gv_payment_method_virement THEN
              gv_step  := lv_current_program_unit||' 094 : Mise a jour des factures non réglées';log_message(gv_step);
              UPDATE ap_payment_schedules_all aps
              SET
                aps.external_bank_account_id = vn_bank_acct_id,
                aps.payment_method_code = gv_payment_method_virement,
                aps.last_update_date = SYSDATE,
                aps.last_updated_by = gn_user_id,
                aps.last_update_login = gn_login_id
              WHERE  aps.external_bank_account_id = vn_exist_bank_acct_id
              AND    aps.amount_remaining != 0
              AND    aps.invoice_id IN ( SELECT ai.invoice_id
                                         FROM   ap_invoices_all ai
                                         WHERE  ai.vendor_id = vn_vendor_id);
             END IF;

            insert_error(vv_emp_num,vv_table,vn_table_id,'S',
                         'Mise a jour employé (Compte bancaire) terminée : '||vv_emp_num||' avec succes',gv_step,vv_source);

            flag_traite(pv_employee_number    => vv_emp_num,
                        pv_insert_update_flag => 'U',
                        pv_table_name         => vv_table,
                        pv_source             => vv_source);

          EXCEPTION
           WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            ROLLBACK TO SAVE_EMPLOYE;
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
          END;

          --///FIN UPDATE COMMIT!!!
          gv_step  := lv_current_program_unit||' 099 : COMMIT UPDATE EMPLOYE ';log_message(gv_step);

          insert_error(vv_emp_num,'XXEAI_HR_PEOPLE_INT',l_emp.XXEAI_PERSON_ID,'S',
                       'Update employé terminé : '||vv_emp_num||' avec succes',gv_step,vv_source);
          COMMIT;


        EXCEPTION
          WHEN OTHERS THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION OTHERS gv_step :'||gv_step||chr(10)||SQLERRM;
            log_message(gv_step);
            vv_type := 'E';
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            ROLLBACK;
            --Suivant
        END;

      END LOOP; --lt_employe_REF

    END IF;

    --BOUCLE POUR CHAQUE EMPLOYE SESAME
    gv_step  := lv_current_program_unit||' 100 : initialisation pour boucle : C_EMPLOYE_SESAME';log_message(gv_step);
    OPEN  C_EMPLOYE_SESAME;
    FETCH C_EMPLOYE_SESAME BULK COLLECT INTO lt_employe;
    CLOSE C_EMPLOYE_SESAME;

    IF lt_employe.COUNT > 0 THEN
      FOR i in lt_employe.FIRST..lt_employe.LAST LOOP
        BEGIN

          --Init pour message
          vv_message  := '';
          vv_emp_num  := l_emp.employee_number;
          vv_table    := 'XXEAI_HR_PEOPLE_INT';
          vn_table_id := l_emp.XXEAI_PERSON_ID;
          vv_source   := gv_source_contact;

          --///VALIDATION EMPLOYE
          gv_step  := lv_current_program_unit||' 101 : Existence de l''employé';log_message(gv_step);
          get_person_info(l_emp.employee_number,vn_person_id,vn_per_object_version_number,vr_person_row);
          IF vn_person_id IS NULL then
            --Mise a jour de l'employé impossible, le matricule n'existe pas
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0024',
                                                     'EMPNUM',l_emp.EMPLOYEE_NUMBER);
            vv_type     := 'P';
            RAISE e_emp_error;
          END IF;

          --######################################################################################
          -- EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 102 : Mise a jour employe';log_message(gv_step);

          gv_step  := lv_current_program_unit||' 103 : reintialisation SAVEPOINT SAVE_EMPLOYE';log_message(gv_step);
          SAVEPOINT SAVE_EMPLOYE;

          BEGIN

            gv_step  := lv_current_program_unit||' 104 : sélection des donnée de l''employé : '||lt_employe(i);log_message(gv_step);
            SELECT *
            INTO l_emp
            FROM XXEAI_HR_PEOPLE_INT HPI
            WHERE
             HPI.INSERT_UPDATE_FLAG = 'U'
             AND HPI.INTERFACE_STATUS != 'ERROR'
             AND HPI.EMPLOYEE_NUMBER = lt_employe(i)
             AND SOURCE = gv_source_contact
            ;

            --Init pour message
            vv_message  := '';
            vv_emp_num  := l_emp.employee_number;
            vv_table    := 'XXEAI_HR_PEOPLE_INT';
            vn_table_id := l_emp.XXEAI_PERSON_ID;
            vv_source   := gv_source_contact;

            --
            -- --------------------------------
            -- Find Date Track Mode
            -- --------------------------------
            dt_api.find_dt_upd_modes
            (    p_effective_date               => TRUNC(SYSDATE),
                p_base_table_name              => 'PER_ALL_PEOPLE_F',
                p_base_key_column              => 'PERSON_ID',
                p_base_key_value               => vn_person_id,
                 -- Output data elements
                 -- --------------------------------
                 p_correction                   => vb_correction,
                 p_update                       => vb_update,
                 p_update_override              => vb_update_override,
                 p_update_change_insert         => vb_update_change_insert
             );

            IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE )
            THEN -- UPDATE_OVERRIDE
               vv_dt_ud_mode := 'UPDATE_OVERRIDE';
            END IF;
            IF ( vb_correction = TRUE )
            THEN -- CORRECTION
             vv_dt_ud_mode := 'CORRECTION';
            END IF;
            IF ( vb_update = TRUE )
            THEN -- UPDATE
              vv_dt_ud_mode := 'UPDATE';
            END IF;

            --///UPDATE DE L'EMPLOYE
            gv_step  := lv_current_program_unit||' 105 : Mise a jour de l''employé ';log_message(gv_step);

            hr_person_api.update_person
                      (p_validate                      => FALSE,
                       p_email_address                 => nvl(l_emp.email_address,vr_person_row.email_address),
                       p_expense_check_send_to_addres  => nvl(l_emp.expense_check_send_to_address,vr_person_row.expense_check_send_to_address),
                       p_internal_location             => nvl(l_emp.work_telephone,vr_person_row.work_telephone),
                       p_work_telephone                => nvl(l_emp.work_telephone,vr_person_row.work_telephone),
                       p_attribute4                    => nvl(l_emp.attribute4,vr_person_row.attribute4),
                       p_effective_date                => SYSDATE,
                       p_datetrack_update_mode         => vv_dt_ud_mode,
                       p_person_id                     => vn_person_id,
                       p_object_version_number         => vn_per_object_version_number,
                       p_employee_number               => l_emp.EMPLOYEE_NUMBER,
                       p_full_name                     => vv_full_name,
                       p_effective_start_date          => vd_per_effective_start_date,
                       p_effective_end_date            => vd_per_effective_end_date,
                       p_comment_id                    => vn_per_comment_id,
                       p_name_combination_warning      => vb_name_combination_warning,
                       p_assign_payroll_warning        => vb_assign_payroll_warning,
                       p_orig_hire_warning             => vb_orig_hire_warning
                       );

            --- 29/05/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
            --IF vb_name_combination_warning or vb_orig_hire_warning then
            IF vb_orig_hire_warning then
              --Mise a jour de l'employé impossible : erreur dans l'API
              gv_step  := lv_current_program_unit||' 106 : Mise a jour de l''employé impossible : erreur dans l''API';log_message(gv_step);

              /*IF vb_name_combination_warning THEN
                vv_message := 'Un employé existe déja pour ce nom, prénom et date de naissance';
              ELS*/
          IF vb_orig_hire_warning THEN
                vv_message := 'Date d''embauche renseigné et type d''employé incohérent';
              END IF;

              vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0025',
                                                      'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                      'MESSAGE',vv_message);
              vv_type     := 'P';
              RAISE e_emp_error;
            ELSE
        --- 29/05/2019 NBO artf07150239 : INC0258862 Dysfonctionnement interface employé
              IF vb_name_combination_warning THEN
                vv_message := 'Un employé existe déja pour ce nom, prénom et date de naissance';
                vv_type     := 'W';
                insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
              END IF;

              --Mise a jour OK
              gv_step  := lv_current_program_unit||' 107 : Mise a jour de l''employé OK';log_message(gv_step);

              BEGIN
                --Mise a jour de l'adresse mail de l'utilisateur
                IF FND_USER_PKG.userExists(l_emp.EMPLOYEE_NUMBER) THEN
                  gv_step  := lv_current_program_unit||' 108 : Mise a jour de l''utilisateur de l''employé';log_message(gv_step);
                  FND_USER_PKG.UpdateUser(x_user_name => l_emp.EMPLOYEE_NUMBER,
                                          --x_owner => NULL,
                                          x_owner => fnd_global.user_name,
                                          x_email_address => nvl(l_emp.email_address,vr_person_row.email_address));
                END IF;

              EXCEPTION
                WHEN OTHERS THEN
                  --Mise a jour de l'adresse mail de l'utilisateur de l'employé impossible
                  vv_message  := dka_tools_pkg.get_message( 'DKA','DKA_IHREMP_REF_0026',
                                                            'EMPNUM',l_emp.EMPLOYEE_NUMBER,
                                                            'MESSAGE',SQLERRM);
                  vv_type     := 'P';
                  RAISE e_emp_error;
              END;
            END IF;

          EXCEPTION
           WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            ROLLBACK TO SAVE_EMPLOYE;
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
          END;

          --///FIN UPDATE COMMIT!!!
          gv_step  := lv_current_program_unit||' 199 : COMMIT UPDATE EMPLOYE ';log_message(gv_step);

          insert_error(vv_emp_num,vv_table,vn_table_id,'S',
                       'Mise a jour employé '||vv_emp_num||' (Moyen de contact) avec succes',vv_source);

          flag_traite(pv_employee_number    => vv_emp_num,
                      pv_insert_update_flag => 'U',
                      pv_table_name         => vv_table,
                      pv_source             => vv_source);

          COMMIT;

        EXCEPTION
          WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            ROLLBACK;
            --Suivant
          WHEN OTHERS THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION OTHERS gv_step :'||gv_step||chr(10)||SQLERRM;
            log_message(gv_step);
            vv_type := 'E';
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            ROLLBACK;
            --Suivant
        END;

      END LOOP; --lt_employe_SESAME

    END IF;


    --BOUCLE POUR CHAQUE EMPLOYE ENTREE OU SORTIE
    gv_step  := lv_current_program_unit||' 200 : initialisation pour boucle : C_EMPLOYE_IN_OUT';log_message(gv_step);
    OPEN  C_EMPLOYE_IN_OUT;
    FETCH C_EMPLOYE_IN_OUT BULK COLLECT INTO lt_employe;
    CLOSE C_EMPLOYE_IN_OUT;

    IF lt_employe.COUNT > 0 THEN
      FOR i in lt_employe.FIRST..lt_employe.LAST LOOP
        BEGIN

          --Init pour message
          vv_message  := '';
          vv_emp_num  := l_emp.employee_number;
          vv_table    := 'XXEAI_HR_PEOPLE_INT';
          vn_table_id := l_emp.XXEAI_PERSON_ID;
          vv_source   := gv_source_employe;

          gv_step  := lv_current_program_unit||' 008 : sélection des donnée de l''employé : '||lt_employe(i);log_message(gv_step);
          SELECT *
          INTO l_emp
          FROM XXEAI_HR_PEOPLE_INT HPI
          WHERE
           HPI.INSERT_UPDATE_FLAG = 'U'
           AND HPI.INTERFACE_STATUS != 'ERROR'
           AND HPI.EMPLOYEE_NUMBER = lt_employe(i)
           AND SOURCE = gv_source_employe
          ;

          --///VALIDATION EMPLOYE
          gv_step  := lv_current_program_unit||' 201 : Existence de l''employé';log_message(gv_step);
          get_person_info(l_emp.employee_number,vn_person_id,vn_per_object_version_number,vr_person_row);
          IF vn_person_id IS NULL then
            --Mise a jour de l'employé impossible, le matricule n'existe pas
            vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0024',
                                                     'EMPNUM',l_emp.EMPLOYEE_NUMBER);
            vv_type     := 'P';
            RAISE e_emp_error;
          END IF;

          --######################################################################################
          --ANNULATION DE SORTIE EMPLOYE (Cador renvoie une date de fin vide)
          --######################################################################################
          gv_step  := lv_current_program_unit||' 206 : Validation annulation de sortie employé  (type/date fin): '||l_emp.employee_number||
                                               ' ('||vr_person_row.person_type_id||'/'||l_emp.effective_end_date||')';log_message(gv_step);
          --Une date de fin vide (NULL ou 31/12/4712) sur un employé déjà sorti = correction d'une
          --sortie envoyée par erreur : on annule la sortie (reverse) au lieu de réembaucher.
          IF is_EX_employee(vr_person_row.person_type_id)
             AND NVL(l_emp.effective_end_date,TO_DATE('31/12/4712','dd/mm/yyyy')) = TO_DATE('31/12/4712','dd/mm/yyyy') THEN
            BEGIN
              gv_step  := lv_current_program_unit||' 207 : Sortie a annuler';log_message(gv_step);
              reverse_termination(vr_person_row.person_id);

              --Rechargement des infos : l'employé n'est plus EX_EMP, les traitements
              --suivants doivent travailler sur la ligne person a jour.
              get_person_info(l_emp.employee_number,vn_person_id,vn_per_object_version_number,vr_person_row);

            EXCEPTION
             WHEN OTHERS THEN
               vv_message  := 'Erreur dans l''annulation de la sortie de l''employé';
               vv_type     := 'P';
               RAISE e_emp_error;
            END;
          END IF;

          --######################################################################################
          --REACTIVATION EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 202 : Validation réactivation employé  (type/date): '||l_emp.employee_number||
                                               ' ('||vr_person_row.person_type_id||'/'||vr_person_row.effective_start_date||')';log_message(gv_step);
          IF is_EX_employee(vr_person_row.person_type_id) and l_emp.EFFECTIVE_START_DATE >= vr_person_row.effective_start_date THEN
            BEGIN
              gv_step  := lv_current_program_unit||' 203 : Employé a réactiver';log_message(gv_step);
              reactivate_employee(vr_person_row.person_id,
                                  l_emp.EFFECTIVE_START_DATE,
                                  vr_person_row.object_version_number,
                                  'REACTIVATION INTERFACE EMPLOYEE '||gv_source_employe);

            EXCEPTION
             WHEN OTHERS THEN
               vv_message  := 'Erreur dans la réactivation de l''employé';
               vv_type     := 'P';
               RAISE e_emp_error;
            END;
          END IF;

          --######################################################################################
          --DESACTIVATION EMPLOYE
          --######################################################################################
          gv_step  := lv_current_program_unit||' 204 : Validation désactivation employé  (eff_start/term_date): '||l_emp.employee_number||
                                               ' ('||vr_person_row.effective_start_date||'/'||l_emp.effective_end_date||')';log_message(gv_step);
          IF NOT is_EX_employee(vr_person_row.person_type_id) and l_emp.effective_end_date < vr_person_row.effective_end_date THEN
            BEGIN
              gv_step  := lv_current_program_unit||' 205 : Employé a désactiver';log_message(gv_step);
              terminate_employee(vn_person_id,
                                 vr_person_row.effective_start_date,
                                 l_emp.effective_end_date);
            EXCEPTION
             WHEN OTHERS THEN
               vv_message  := 'Erreur dans la désactivation de l''employé';
               vv_type     := 'P';
               RAISE e_emp_error;
            END;
          END IF;


          --///FIN UPDATE COMMIT!!!
          gv_step  := lv_current_program_unit||' 299 : COMMIT UPDATE EMPLOYE ';log_message(gv_step);

          insert_error(vv_emp_num,vv_table,vn_table_id,'S',
                       'Mise a jour employé '||vv_emp_num||' (Date de fin) avec succes',gv_step,vv_source);

          flag_traite(pv_employee_number    => vv_emp_num,
                      pv_insert_update_flag => 'U',
                      pv_table_name         => vv_table,
                      pv_source             => vv_source);

          COMMIT;

        EXCEPTION
          WHEN e_emp_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_EMP_ERROR gv_step :'||gv_step;log_message(gv_step);

            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            ROLLBACK;
            --Suivant
          WHEN OTHERS THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION OTHERS gv_step :'||gv_step||chr(10)||SQLERRM;
            log_message(gv_step);
            vv_type     := 'E';
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            ROLLBACK;
            --Suivant
        END;

      END LOOP; --lt_employe_IN_OUT

    END IF;


    --YWA EDB072 BOUCLE POUR CHAQUE COORDONNÉES BANCAIRES ISSUE DE RHAPSODY
    gv_step  := lv_current_program_unit||' 300 : initialisation pour boucle : C_BANK_ONLY';log_message(gv_step);
    FOR cbo IN  C_BANK_ONLY LOOP

        gv_step  := lv_current_program_unit||' 301 : sélection de l''employé : '||cbo.employee_number;log_message(gv_step);

        --REINIT VARIABLE
        gv_step  := lv_current_program_unit||' 302 :Reinit variable ';log_message(gv_step);
        vv_emp_num := cbo.employee_number;

        --EMPLOYE
        vn_person_id                    := NULL;
        vn_per_object_version_number    := NULL;
        vd_per_effective_start_date     := NULL;
        vd_per_effective_end_date       := NULL;
        vv_full_name                    := NULL;
        vn_per_comment_id               := NULL;
        vb_name_combination_warning     := NULL;
        vb_assign_payroll_warning       := NULL;
        vb_orig_hire_warning            := NULL;
        vr_person_row                   := NULL;

        --VENDOR
        vr_vendor_rec         := NULL;
        vn_vendor_id          := NULL;
        vn_party_id           := NULL;

        --VENDOR SITE
        vr_vendor_site_rec    := NULL;
        vn_vendor_site_id     := NULL;
        vn_party_site_id      := NULL;
        vn_location_id        := NULL;
        vv_calling_prog       := NULL;

        vn_PREPAY_CCID    := NULL;
        vn_ACCTS_PAY_CCID := NULL;

        vr_location_rec      := NULL;
        vr_party_site_rec    := NULL;
        vv_party_site_number := NULL;


        --BANK
        vb_info_bank           := NULL;
        vr_ext_bank_acct_rec   := NULL;
        vn_bank_id             := NULL;
        vn_branch_id           := NULL;
        vn_bank_acct_id        := NULL;
        vn_exist_bank_acct_id  := NULL;
        vn_bk_object_version_number := NULL;
        vd_bk_start_date       := NULL;
        vv_association_level   := NULL;
        vn_acct_id             := NULL;
        vn_joint_acct_id       := NULL;
        vr_response            := NULL;
        vv_org_type            := NULL;

        vn_assign_id           := NULL;
        vr_payee_context_rec   := NULL;
        vr_assignment_attribs  := NULL;

        --AFFECTATION
        vv_ne_rien_faire        := FALSE;
        vv_task_number          := NULL;
        vv_task_id              := NULL;
        vn_task_project_id      := NULL;
        vv_task_project_name    := NULL;
        vv_task_project_type    := NULL;
        vd_task_start_date      := NULL;
        vd_task_completion_date := NULL;
        vd_task_closed_date     := NULL;
        vv_task_org_projet      := NULL;
        vn_task_org_projet_id   := NULL;
        vv_task_societe         := NULL;
        vv_task_region          := NULL;
        vv_task_org_fin         := NULL;
        vn_task_org_fin_id      := NULL;

        vn_superviseur          := NULL;
        vn_sup_hierar           := NULL;
        vn_people_group_id      := NULL;

        vv_new_task_id              := NULL;
        vn_new_task_project_id      := NULL;
        vv_new_task_project_name    := NULL;
        vv_new_task_project_type    := NULL;
        vd_new_task_start_date      := NULL;
        vd_new_task_completion_date := NULL;
        vd_new_task_closed_date     := NULL;
        vv_new_task_org_projet      := NULL;
        vn_new_task_org_projet_id   := NULL;
        vv_new_task_societe         := NULL;
        vv_new_task_region          := NULL;
        vv_new_task_org_fin         := NULL;
        vn_new_task_org_fin_id      := NULL;

        vn_assignment_id             := NULL;
        vn_asg_object_version_number := NULL;
        vd_ass_start_date            := NULL;
        vd_ass_end_date              := NULL;
        vn_job_id                    := NULL;
        vv_job_name                  := NULL;
        vv_fct                       := NULL;
        vn_organization_id           := NULL;
        vv_organization_name         := NULL;
        vn_supervisor_id             := NULL;
        vv_ass_attribute1            := NULL;
        vv_ass_attribute2            := NULL;
        vv_ass_attribute3            := NULL;
        vv_ass_attribute4            := NULL;
        vv_ass_attribute5            := NULL;

        vn_ledger_id            := NULL;
        vv_currency_code        := NULL;

        vd_def_ass_effective_date := NULL;
        vn_def_task_org_fin_id    := NULL;

        vv_period_name          := NULL;
        vd_period_start_date    := NULL;
        vd_period_end_date      := NULL;

        --API
        vb_update_change_insert := NULL;
        vb_correction           := NULL;
        vb_update               := NULL;
        vb_update_override      := NULL;
        vv_dt_ud_mode           := NULL;

        vn_api_version        := NULL;
        vv_init_msg_list      := NULL;
        vv_commit             := NULL;
        vn_validation_level   := NULL;
        vv_return_status      := NULL;
        vn_msg_count          := NULL;
        vv_msg_data           := NULL;
        VN_MSG_INDEX_OUT      := NULL;

        vn_soft_coding_keyflex_id  := NULL;
        vc_concatenated_segments   := NULL;
        vn_comment_id              := NULL;
        vb_no_managers_warning     := NULL;
        vb_other_manager_warning   := NULL;
        vd_effective_start_date    := NULL;
        vd_effective_end_date      := NULL;
        vn_special_ceiling_step_id := NULL;
        vc_group_name                  := NULL;
        vb_org_now_no_manager_warning  := NULL;
        vb_spp_delete_warning          := NULL;
        vc_entries_changed_warning     := NULL;
        vb_tax_district_changed_warn   := NULL;

        vv_payment_method := NULL;
        --//FIN REINIT

        --Init pour message
        vv_message  := '';
        vv_bank_acc_num  := cbo.bank_account_num;
        vv_table    := 'XXEAI_HR_BANK_INT_ALL';
        vn_table_id := cbo.XXEAI_BANK_ID;
        vv_source   := gv_source_employe;

        --------------controle younes--------------------------
        --######################################################################################
        --Existence de lemploye via le champ EMPLOYE_NUMBER
        --######################################################################################
        BEGIN
            gv_step  := lv_current_program_unit||' 303 : Existence de l''employé '||cbo.employee_number;
            log_message(gv_step);
            get_person_info(cbo.employee_number,vn_person_id,vn_per_object_version_number,vr_person_row);
            IF vn_person_id IS NULL then
                --Mise a jour de l'employé impossible, le matricule n'existe pas
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0024',
                                                         'EMPNUM',cbo.employee_number);
                vv_type     := 'E';
                RAISE e_bankacc_error;
            END IF;


          --Recherche de la tache du projet
            gv_step  := lv_current_program_unit||' 304 : Recherche de la tache du projet';log_message(gv_step);
            get_assign_info(cbo.employee_number,
                          vn_assignment_id,
                          vn_asg_object_version_number,
                          vd_ass_start_date,
                          vd_ass_end_date,
                          vn_job_id,
                          vv_job_name,
                          vv_fct,
                          vn_organization_id,
                          vv_organization_name,
                          vn_supervisor_id,
                          vv_ass_attribute1,
                          vv_ass_attribute2,
                          vv_ass_attribute3,
                          vv_ass_attribute4,
                          vv_ass_attribute5);

            IF vn_asg_object_version_number IS NULL THEN
                --Recherche de la tache du projet en erreur
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0044',
                                                         'EMPNUM',cbo.employee_number);
                vv_type     := 'P';
                raise e_bankacc_error;

            END IF;

            --Recherche des infos de la tache du projet
            gv_step  := lv_current_program_unit||' 305 : Recherche des infos de la tache du projet';log_message(gv_step);
            DKA_PA_TOOLS_PKG.pa_get_info_task(vv_errbuf,
                                            vn_retcode,
                                            vv_ass_attribute5,
                                            vv_task_id,
                                            vn_task_project_id,
                                            vv_task_project_name,
                                            vv_task_project_type,
                                            vd_task_start_date,
                                            vd_task_completion_date,
                                            vd_task_closed_date,
                                            vv_task_org_projet,
                                            vn_task_org_projet_id,
                                            vv_task_societe,
                                            vv_task_region,
                                            vv_task_org_fin,
                                            vn_task_org_fin_id);

            IF vn_retcode != 0 THEN
                 --Erreur lors de la détermination des informations projet
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0045',
                                                         'EMPNUM',cbo.employee_number,
                                                         'TACHE',l_assignment.ass_attribute5,'MESSAGE',vv_errbuf);
                vv_type     := 'P';
                raise e_bankacc_error;
            END IF;

            --Infos fournisseur
            gv_step  := lv_current_program_unit||' 306 : Recherche des infos fournisseurs';log_message(gv_step);
            get_supplier_info(vn_person_id,vn_vendor_id ,vn_party_id);
            IF vn_vendor_id IS NULL OR vn_party_id IS NULL then
                -- le fournisseur n'existe pas
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0042',
                                                         'EMPNUM',cbo.employee_number);
                vv_type     := 'P';
                RAISE e_bankacc_error;
            END IF;

            --Recherche du fournisseur et site fournisseur
            gv_step  := lv_current_program_unit||' 307 : Recherche du fournisseur et site fournisseur';log_message(gv_step);
            get_supplier_site_info(vn_person_id,vn_task_org_projet_id, vn_vendor_id , vn_party_id,vn_vendor_site_id,vn_party_site_id );

            IF vn_vendor_site_id IS NULL AND vn_vendor_id IS NOT NULL THEN
                -- le site fournisseur n'existe pas
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0042',
                                                         'EMPNUM',cbo.employee_number);
                vv_type     := 'P';
                RAISE e_bankacc_error;
            END IF;

            --Entité comptable
            gv_step  := lv_current_program_unit||' 308 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
            vn_ledger_id := dka_gl_tools_pkg.get_legder_id(vv_task_societe);

            IF vn_ledger_id IS NULL THEN
                --Mise a jour employé impossible, entité comptable n'existe pas pour la société
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0046',
                                                        'EMPNUM',cbo.employee_number,
                                                        'SOCIETE',vv_task_societe);
                vv_type     := 'P';
                RAISE e_bankacc_error;
            END IF;

            --Devise Entité comptable
            gv_step  := lv_current_program_unit||' 309 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
            vv_currency_code := get_currency_code(vn_ledger_id);

            IF vv_currency_code IS NULL THEN
                --Mise a jour employé impossible : Erreur sur la devise de l'entité comptable
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0047',
                                                        'EMPNUM',cbo.employee_number,
                                                        'SOCIETE',vv_task_societe);
                vv_type     := 'P';
                RAISE e_bankacc_error;
            END IF;

          --------------controle younes--------------------------


        EXCEPTION
            WHEN e_bankacc_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION e_bankacc_error gv_step :'||gv_step;log_message(gv_step);
            insert_error(cbo.employee_number,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            continue;
        END;

        --######################################################################################
        --MISE A JOUR COMPTE BANCAIRE EMPLOYE
        --######################################################################################
        gv_step  := lv_current_program_unit||' 311 : Mise a jour compte bancaire employe';log_message(gv_step);

        gv_step  := lv_current_program_unit||' 312 : reintialisation SAVEPOINT SAVE_BANK';log_message(gv_step);
        SAVEPOINT SAVE_BANK;

        BEGIN

            gv_step  := lv_current_program_unit||' 313 : sélection des donnée bancaire de l''employé : '||cbo.employee_number;log_message(gv_step);


            --Existence BANQUE/AGENCE
            gv_step  := lv_current_program_unit||' 314 : Existence BANQUE/AGENCE';
            log_message(gv_step);
            get_bank_info ( pv_bank_number   => cbo.bank_number,
                          pv_branch_number => cbo.bank_num,
                          pn_bank_id       => vn_bank_id,
                          pn_branch_id     => vn_branch_id
                              );

            IF vn_bank_id IS NULL THEN
                --Mise a jour employé impossible :La banque n'existe pas ou est inactive
                vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0053',
                                                         'EMPNUM',cbo.employee_number,
                                                         'BANKNUM',cbo.bank_number,
                                                         'BRANCHNUM',cbo.bank_num);
                vv_type     := 'P';
                raise e_bankacc_error;

            END IF;

            BEGIN
              --Existence du compte bancaire
              gv_step  := lv_current_program_unit||' 315 : compte bancaire';log_message(gv_step);
              get_info_compte_bank(pn_bank_id       => vn_bank_id,
                                 pn_branch_id     => vn_branch_id,
                                 pv_iban          => cbo.iban_number,
                                 pv_country       => cbo.bank_branch_country,
                                 pv_type          => 'SUPPLIER',
                                 pn_bank_acct_id  => vn_bank_acct_id);
            EXCEPTION
             WHEN OTHERS THEN
              gv_step  := lv_current_program_unit||' 315 : EXCEPTION OTHERS gv_step :'||gv_step||chr(10)||SQLERRM;
              vv_message := gv_step;
              RAISE;
            END;

            BEGIN
              --Recherche du compte actuel sur le site
              gv_step  := lv_current_program_unit||' 316 : Recherche du compte actuel sur le site';log_message(gv_step);
              get_info_acct_emp (vn_party_id,vn_vendor_site_id,vn_party_site_id,vn_exist_bank_acct_id,vd_bk_start_date,vn_bk_object_version_number);
            EXCEPTION
             WHEN OTHERS THEN
              gv_step  := lv_current_program_unit||' 316 : EXCEPTION OTHERS gv_step :'||gv_step||chr(10)||SQLERRM;
              vv_message := gv_step;
              RAISE;
            END;

            gv_step  := lv_current_program_unit||' 317 : vn_exist_bank_acct_id : '||vn_exist_bank_acct_id;log_message(gv_step);
            gv_step  := lv_current_program_unit||' 318 : vn_bank_acct_id : '||vn_bank_acct_id;log_message(gv_step);



            IF nvl(vn_exist_bank_acct_id,-1) != nvl(vn_bank_acct_id,-1) THEN
                --Changement du compte bancaire, on désactive l'ancien
                IF  vn_exist_bank_acct_id IS NOT NULL THEN
                    --Init valeur API
                    vn_api_version       := 1.0;
                    vv_init_msg_list     := FND_API.G_TRUE;
                    vv_commit            := FND_API.G_FALSE;
                    vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                    vv_return_status     := NULL;
                    vn_msg_count         := NULL;
                    vv_msg_data          := NULL;

                    gv_step  := lv_current_program_unit||' 319 : Mise a jour de la date de fin du compte bancaire - API';log_message(gv_step);
                    IBY_EXT_BANKACCT_PUB.set_ext_bank_acct_dates(p_api_version           => vn_api_version,
                                                                 p_init_msg_list         => vv_init_msg_list,
                                                                 p_acct_id               => vn_exist_bank_acct_id,
                                                                 p_start_date            => vd_bk_start_date,
                                                                 p_end_date              => sysdate,
                                                                 p_object_version_number => vn_bk_object_version_number,
                                                                 x_return_status         => vv_return_status,
                                                                 x_msg_count             => vn_msg_count,
                                                                 x_msg_data              => vv_msg_data,
                                                                 x_response              => vr_response
                                                                );

                    IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                      --On continue
                      gv_step  := lv_current_program_unit||' 320 : Mise a jour de la date de fin du compte bancaire - API : Success';log_message(gv_step);

                    ELSE
                      vv_message := '';
                      IF fnd_msg_pub.count_msg > 0 THEN

                        FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                          vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                        END LOOP;

                      END IF;

                      --Mise a jour de la date de fin du compte bancaire impossible : message
                      vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0054',
                                                               'EMPNUM',cbo.employee_number,
                                                               'IBAN',cbo.iban_number,
                                                               'MESSAGE',substr(vv_message,1,500));
                      vv_type     := 'P';
                      RAISE e_bankacc_error;

                    END IF;
                END IF;

                --Création - Rattachement du compte

                IF vn_bank_acct_id IS NULL THEN
                  --Création du compte bancaire
                  gv_step  := lv_current_program_unit||' 321 : Création du compte bancaire';log_message(gv_step);

                  vr_ext_bank_acct_rec.object_version_number    := 1.0;
                  vr_ext_bank_acct_rec.acct_owner_party_id      := vn_party_id; --site
                  vr_ext_bank_acct_rec.bank_account_name        := cbo.bank_account_name;
                  vr_ext_bank_acct_rec.bank_account_num         := cbo.bank_account_num;
                  vr_ext_bank_acct_rec.alternate_acct_name      := NULL;
                  vr_ext_bank_acct_rec.bank_id                  := vn_bank_id ;
                  vr_ext_bank_acct_rec.branch_id                := vn_branch_id ;
                  vr_ext_bank_acct_rec.start_date               := TRUNC(SYSDATE);
                  vr_ext_bank_acct_rec.acct_type                := 'SUPPLIER';
                  vr_ext_bank_acct_rec.country_code             := gv_vendor_site_ctry;
                  vr_ext_bank_acct_rec.currency                 := vv_currency_code;
                  vr_ext_bank_acct_rec.iban                     := cbo.iban_number;

                  --Init valeur API
                  vn_api_version       := 1.0;
                  vv_init_msg_list     := FND_API.G_TRUE;
                  vv_commit            := FND_API.G_FALSE;
                  vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                  vv_return_status     := NULL;
                  vn_msg_count         := NULL;
                  vv_msg_data          := NULL;
                  vv_association_level := 'SS';
                  vv_org_type          := 'OPERATING_UNIT';

                  --Création COMPTE
                  gv_step  := lv_current_program_unit||' 322 : Création du compte bancaire - API';log_message(gv_step);
                  IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT (p_api_version            => vn_api_version,
                                                             p_init_msg_list          => vv_init_msg_list,
                                                             p_ext_bank_acct_rec      => vr_ext_bank_acct_rec,
                                                             p_association_level      => vv_association_level,
                                                             p_supplier_site_id       => vn_vendor_site_id,
                                                             p_party_site_id          => NULL,
                                                             p_org_id                 => vn_task_org_projet_id,
                                                             p_org_type               => vv_org_type,
                                                             x_acct_id                => vn_acct_id,
                                                             x_return_status          => vv_return_status,
                                                             x_msg_count              => vn_msg_count,
                                                             x_msg_data               => vv_msg_data,
                                                             x_response               => vr_response
                                                            );

                  IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                    --On continue
                    gv_step  := lv_current_program_unit||' 323 : Création du compte bancaire - API : Success';log_message(gv_step);

                    vn_bank_acct_id:= vn_acct_id;

                    NULL;
                  ELSE
                      vv_message := '';
                      IF fnd_msg_pub.count_msg > 0 THEN

                      FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                        vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                      END LOOP;

                      END IF;

                      --Création du compte bancaire impossible : message
                      vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0055',
                                                             'EMPNUM',cbo.employee_number,
                                                             'IBAN',cbo.iban_number,
                                                             'MESSAGE',substr(vv_message,1,500));
                      vv_type     := 'P';
                      RAISE e_bankacc_error;

                  END IF;
                END IF; --vn_bank_acct_id IS NULL

                gv_step  := lv_current_program_unit||' 324 : Rattachement du compte bancaire : '||vn_bank_acct_id;log_message(gv_step);

                vn_api_version       := 1.0;
                vv_init_msg_list     := FND_API.G_TRUE;
                vv_commit            := FND_API.G_FALSE;
                vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                vv_return_status     := NULL;
                vn_msg_count         := NULL;
                vv_msg_data          := NULL;

                --Rattachement du compte bancaire
                gv_step  := lv_current_program_unit||' 325 : Controle proprietaire compte bancaire - API';log_message(gv_step);
                IBY_EXT_BANKACCT_PUB.check_bank_acct_owner   (p_api_version         => vn_api_version,
                                                              p_init_msg_list       => FND_API.G_TRUE,
                                                              p_bank_acct_id        => vn_bank_acct_id,
                                                              p_acct_owner_party_id => vn_party_id,  --site
                                                              x_return_status       => vv_return_status,
                                                              x_msg_count           => vn_msg_count,
                                                              x_msg_data            => vv_msg_data,
                                                              x_response            => vr_response
                                                              );

                IF  vv_return_status <> 'S' THEN
                    gv_step  := lv_current_program_unit||' 326 : Controle proprietaire compte bancaire KO';log_message(gv_step);


                    vn_api_version       := 1.0;
                    vv_init_msg_list     := FND_API.G_TRUE;
                    vv_commit            := FND_API.G_FALSE;
                    vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                    vv_return_status     := NULL;
                    vn_msg_count         := NULL;
                    vv_msg_data          := NULL;

                    vn_joint_acct_id     := NULL;

                    gv_step  := lv_current_program_unit||' 327 : liaison compte bancaire - API';log_message(gv_step);
                    IBY_EXT_BANKACCT_PUB.add_joint_account_owner( p_api_version         => vn_api_version,
                                                                p_init_msg_list       => vv_init_msg_list,
                                                                p_bank_account_id     => vn_bank_acct_id,
                                                                p_acct_owner_party_id => vn_party_id,    --site
                                                                x_joint_acct_owner_id => vn_joint_acct_id,
                                                                x_return_status       => vv_return_status,
                                                                x_msg_count           => vn_msg_count,
                                                                x_msg_data            => vv_msg_data,
                                                                x_response            => vr_response
                                                               );

                    IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                        --On continue
                        gv_step  := lv_current_program_unit||' 328 : liaison compte bancaire - API : Success';log_message(gv_step);
                        NULL;
                    ELSE
                        vv_message := '';
                        IF fnd_msg_pub.count_msg > 0 THEN

                            FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                                vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                            END LOOP;

                        END IF;

                        --Rattachement du compte bancaire impossible : message
                        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0056',
                                                                 'EMPNUM',cbo.employee_number,
                                                                 'IBAN',cbo.iban_number,
                                                                 'MESSAGE',substr(vv_message,1,500));
                        vv_type     := 'P';
                        RAISE e_bankacc_error;

                    END IF;

                    --//Finalisation lien site - employé
                    gv_step  := lv_current_program_unit||' 329 : Finalisation lien site - employé';log_message(gv_step);

                    vn_api_version       := 1.0;
                    vv_init_msg_list     := FND_API.G_TRUE;
                    vv_commit            := FND_API.G_FALSE;
                    vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
                    vv_return_status     := NULL;
                    vn_msg_count         := NULL;
                    vv_msg_data          := NULL;

                    vr_payee_context_rec.Party_Id                     := vn_party_id;
                    vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
                    vr_payee_context_rec.party_site_id                := vn_party_site_id;
                    vr_payee_context_rec.Supplier_Site_id             := vn_vendor_site_id;
                    vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
                    vr_payee_context_rec.Org_Id                       := vn_task_org_projet_id;

                    vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
                    vr_assignment_attribs.instrument.instrument_id    := vn_bank_acct_id;
                    vr_assignment_attribs.start_date                  := TRUNC(SYSDATE);

                    -- map account to site supplier
                    gv_step  := lv_current_program_unit||' 330 : Finalisation lien site - employé - API';log_message(gv_step);
                    IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => vn_api_version,
                                                                         p_init_msg_list      => vv_init_msg_list,
                                                                         p_commit             => vv_commit,
                                                                         x_return_status      => vv_return_status,
                                                                         x_msg_count          => vn_msg_count,
                                                                         x_msg_data           => vv_msg_data,
                                                                         p_payee              => vr_payee_context_rec,
                                                                         p_assignment_attribs => vr_assignment_attribs,
                                                                         x_assign_id          => vn_assign_id,
                                                                         x_response           => vr_response
                                                                         );

                    IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                        --On continue
                        gv_step  := lv_current_program_unit||' 331 : Finalisation lien site - employé - API : Success';log_message(gv_step);
                        NULL;
                        ELSE
                        vv_message := '';
                        IF fnd_msg_pub.count_msg > 0 THEN

                            FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                                vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                            END LOOP;

                        END IF;

                        --Rattachement du compte bancaire au site employé impossible : message
                        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0057',
                                                                 'EMPNUM',cbo.employee_number,
                                                                 'IBAN',cbo.iban_number,
                                                                 'MESSAGE',substr(vv_message,1,500));
                        vv_type     := 'P';
                        RAISE e_bankacc_error;

                    END IF;

                ELSE

                    --Cet employé est déja propriétaire de son compte bancaire
                    gv_step  := lv_current_program_unit||' 332 : Controle proprietaire compte bancaire OK';log_message(gv_step);
                    NULL;

                END IF;

                gv_step  := lv_current_program_unit||' 333 : Modification du site pour ajouter le mode de règlement EFT';log_message(gv_step);
                IF  vn_exist_bank_acct_id IS NULL THEN --Modification du site pour ajouter le mode de règlement EFT

                  --Modification site fournisseur
                  gv_step  := lv_current_program_unit||' 334 : Modification site fournisseur : EFT';log_message(gv_step);

                  vn_api_version      := 1.0;
                  vv_init_msg_list    := FND_API.G_TRUE;
                  vv_commit           := FND_API.G_FALSE;
                  vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
                  vv_return_status    := NULL;
                  vn_msg_count        := NULL;
                  vv_msg_data         := NULL;

                  vn_ext_payee_id := NULL;
                  vt_External_Payee_Tab_Type.DELETE;
                  vt_Ext_Payee_ID_Tab_Type.DELETE;
                  vt_Ext_Payee_Update_Tab_Type.DELETE;
                  vt_Ext_Payee_Create_Tab_Type.DELETE;

                  BEGIN

                    SELECT
                         payee.EXT_PAYEE_ID,
                         payee.payee_party_id,
                         payee.PAYMENT_FUNCTION,
                         payee.ORG_ID,
                         payee.org_type,
                         payee.SUPPLIER_SITE_ID,
                         assa.party_site_id
                    INTO
                         vn_ext_payee_id,
                         vr_External_Payee_Rec.payee_party_id,
                         vr_External_Payee_Rec.payment_function,
                         vr_External_Payee_Rec.payer_org_id,
                         vr_External_Payee_Rec.payer_org_type,
                         vr_External_Payee_Rec.supplier_site_id,
                         vr_External_Payee_Rec.Payee_Party_Site_Id
                    FROM iby_external_payees_all  payee,
                         ap_supplier_sites_all    assa
                   WHERE payee.payment_function = 'PAYABLES_DISB'
                     AND payee.supplier_site_id = vn_vendor_site_id
                     AND payee.supplier_site_id = assa.vendor_site_id;

                  EXCEPTION
                   WHEN TOO_MANY_ROWS THEN
                    BEGIN
                      SELECT
                           payee.EXT_PAYEE_ID,
                           payee.payee_party_id,
                           payee.PAYMENT_FUNCTION,
                           payee.ORG_ID,
                           payee.org_type,
                           payee.SUPPLIER_SITE_ID,
                           assa.party_site_id
                      INTO
                           vn_ext_payee_id,
                           vr_External_Payee_Rec.payee_party_id,
                           vr_External_Payee_Rec.payment_function,
                           vr_External_Payee_Rec.payer_org_id,
                           vr_External_Payee_Rec.payer_org_type,
                           vr_External_Payee_Rec.supplier_site_id,
                           vr_External_Payee_Rec.Payee_Party_Site_Id
                      FROM iby_external_payees_all  payee,
                           ap_supplier_sites_all    assa
                     WHERE payee.payment_function = 'PAYABLES_DISB'
                       AND payee.supplier_site_id = vn_vendor_site_id
                       AND payee.supplier_site_id = assa.vendor_site_id
                       AND (payee.party_site_id = assa.party_site_id or payee.party_site_id IS NULL)
                       AND payee.EXT_PAYEE_ID = (select max(iep.EXT_PAYEE_ID)
                                                 from iby_external_payees_all iep
                                                 where iep.supplier_site_id = vn_vendor_site_id)
                        ;
                    EXCEPTION
                      WHEN OTHERS THEN
                        --Modification de la methode de paiement du site fournisseur impossible : message
                        vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0058',
                                                                 'EMPNUM',cbo.employee_number,
                                                                 'MESSAGE','Erreur lors de la recherche des informations bancaires (TOO_MANY_ROWS) :'||SQLERRM);
                        vv_type     := 'P';
                        RAISE e_bankacc_error;
                      END;
                   WHEN OTHERS THEN
                    --Modification de la methode de paiement du site fournisseur impossible : message
                    vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0058',
                                                             'EMPNUM',cbo.employee_number,
                                                             'MESSAGE','Erreur lors de la recherche des informations bancaires (OTHERS) :'||SQLERRM);
                    vv_type     := 'P';
                    RAISE e_bankacc_error;
                  END;

                  vr_External_Payee_Rec.default_pmt_method := gv_payment_method_virement;
                  vr_External_Payee_Rec.exclusive_pay_flag := 'N';

                  vt_External_Payee_Tab_Type(1):= vr_External_Payee_Rec;

                  vt_Ext_Payee_ID_Tab_Type(1).ext_payee_id := vn_ext_payee_id;



                  gv_step  := lv_current_program_unit||' 335 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API';log_message(gv_step);
                  IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee(p_api_version           => vn_api_version,
                                                                 p_init_msg_list         => vv_init_msg_list,
                                                                 p_ext_payee_tab         => vt_External_Payee_Tab_Type,
                                                                 p_ext_payee_id_tab      => vt_Ext_Payee_ID_Tab_Type,
                                                                 x_return_status         => vv_return_status,
                                                                 x_msg_count             => vn_msg_count,
                                                                 x_msg_data              => vv_msg_data,
                                                                 x_ext_payee_status_tab  => vt_Ext_Payee_Update_Tab_Type
                                                              );



                  IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                      --On continue
                      gv_step  := lv_current_program_unit||' 336 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API : Success';log_message(gv_step);
                      NULL;
                  ELSE
                      vv_message := '';
                      IF vn_msg_count > 0 THEN

                          FOR v_index IN 1 .. vn_msg_count LOOP
                              fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                              vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                          END LOOP;

                      END IF;

                      --Error Message from table type
                      IF vt_Ext_Payee_Update_Tab_Type.count > 0 THEN
                          FOR j IN vt_Ext_Payee_Update_Tab_Type.FIRST .. vt_Ext_Payee_Update_Tab_Type.LAST LOOP
                              vv_message := substr(vv_message || chr(10) ||  vt_Ext_Payee_Update_Tab_Type (j).payee_update_msg,1,500);
                          END LOOP;
                      END IF;

                      --Modification de la methode de paiement du site fournisseur impossible : message
                      vv_message  := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0058',
                                                               'EMPNUM',cbo.employee_number,
                                                               'MESSAGE',vv_message);
                      vv_type     := 'P';
                      RAISE e_bankacc_error;

                  END IF;

                  gv_step  := lv_current_program_unit||' 337 : Mise a jour des factures non réglées';log_message(gv_step);
                  UPDATE ap_payment_schedules_all aps
                  SET aps.external_bank_account_id = vn_bank_acct_id,
                      aps.payment_method_code = gv_payment_method_virement,
                      aps.last_update_date = SYSDATE,
                      aps.last_updated_by = gn_user_id,
                      aps.last_update_login = gn_login_id
                  WHERE  aps.amount_remaining != 0
                  AND    aps.invoice_id IN ( SELECT ai.invoice_id
                                           FROM   ap_invoices_all ai
                                           WHERE  ai.vendor_id = vn_vendor_id);

                ELSE
                  gv_step  := lv_current_program_unit||' 338 : Mise a jour des factures non réglées';log_message(gv_step);
                  UPDATE ap_payment_schedules_all aps
                  SET aps.external_bank_account_id = vn_bank_acct_id,
                      --aps.payment_method_code = gv_payment_method_virement,
                      aps.last_update_date = SYSDATE,
                      aps.last_updated_by = gn_user_id,
                      aps.last_update_login = gn_login_id
                  WHERE  aps.external_bank_account_id = vn_exist_bank_acct_id
                  AND    aps.amount_remaining != 0
                  AND    aps.invoice_id IN ( SELECT ai.invoice_id
                                           FROM   ap_invoices_all ai
                                           WHERE  ai.vendor_id = vn_vendor_id);
                END IF;--vn_exist_bank_acct_id IS NULL


            ELSE
                --Meme compte, on ne fait rien
                gv_step  := lv_current_program_unit||' 339 : Meme compte bancaire ou précédent inexistant';log_message(gv_step);
            END IF;


            insert_error(cbo.employee_number,vv_table,vn_table_id,'S',
                         'Mise a jour employé (Compte bancaire) terminée : '||cbo.employee_number||' avec succes',gv_step,vv_source);

            flag_traite(pv_employee_number    => cbo.employee_number,
                        pv_insert_update_flag => 'U',
                        pv_table_name         => vv_table,
                        pv_source             => vv_source);

        EXCEPTION
           WHEN e_bankacc_error THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION e_bankacc_error gv_step :'||gv_step;log_message(gv_step);
            ROLLBACK TO SAVE_BANK;
            insert_error(cbo.employee_number,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            --Suivant
           WHEN OTHERS THEN
            gv_step  := lv_current_program_unit||' EEE : EXCEPTION OTHERS gv_step :'||gv_step||chr(10)||SQLERRM;
            log_message(gv_step);
            vv_type     := 'E';
            insert_error(vv_emp_num,vv_table,vn_table_id,vv_type,vv_message,gv_step,vv_source);
            ROLLBACK;
            --Suivant
        END;

        --///FIN UPDATE COMMIT!!!
        gv_step  := lv_current_program_unit||' 338 : COMMIT UPDATE  (Compte bancaire) ';log_message(gv_step);


        COMMIT;

    END LOOP;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    ROLLBACK;
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    log_message(pv_errbuf,'Y');
    pn_retcode := 2;
  END maj_employe;


  -----------------------------------------------------------------
  --  Nom           : daily_internal_updates
  --  Description   : procedure de mise a jour quotidienne
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE daily_internal_updates(pv_errbuf        OUT NOCOPY VARCHAR2,
                                   pn_retcode       OUT NOCOPY NUMBER) IS

   lv_current_program_unit  VARCHAR2(30) := 'daily_internal_updates';

   vv_errbuf               VARCHAR2(500);
   vn_retcode              NUMBER;
   vv_message              VARCHAR2(5000);

   e_daily_error           EXCEPTION;

   CURSOR c_fonction_vide IS
    SELECT
     papf.person_id,paaf.assignment_id,papf.employee_number,papf.attribute2,paaf.object_version_number
    FROM
     per_all_assignments_f paaf,
     per_all_people_f      papf
    WHERE
     paaf.job_id IS NULL
     AND SYSDATE BETWEEN paaf.EFFECTIVE_START_DATE AND paaf.EFFECTIVE_END_DATE
     AND papf.person_id = paaf.person_id
     AND SYSDATE BETWEEN papf.EFFECTIVE_START_DATE AND papf.EFFECTIVE_END_DATE
     AND    papf.person_type_id NOT IN
                                  (SELECT person_type_id
                                    FROM per_person_types
                                    WHERE system_person_type  IN ('EX_APL','EX_EMP','EX_EMP_APL')
                                    AND business_group_id = gn_business_group_id
                                    AND active_flag = 'Y');

    CURSOR c_date_affectation IS
     SELECT
       papf.person_id,
       papf.employee_number,
       papf.person_type_id,
       papf.effective_start_date papf_effective_start_date,
       papf.effective_end_date   papf_effective_end_date,
       paaf.assignment_id,
       paaf.effective_start_date paaf_effective_start_date,
       paaf.effective_end_date   paaf_effective_end_date,
       paaf.object_version_number
      FROM   per_all_people_f papf,
             per_person_types ppt,
             per_all_assignments_f paaf,
             per_jobs pj,
             hr_all_organization_units haou
      WHERE  papf.business_group_id = gn_business_group_id
      AND    SYSDATE BETWEEN papf.effective_start_date and papf.effective_end_date
      AND    ppt.person_type_id = papf.person_type_id
      AND    paaf.person_id = papf.person_id
      AND    paaf.effective_end_date = (select max(effective_end_date) from per_all_assignments_f s_paaf
                                        where s_paaf.business_group_id = gn_business_group_id
                                        and s_paaf.person_id = papf.person_id)
      AND    paaf.business_group_id = gn_business_group_id
      AND    paaf.job_id = pj.job_id
      AND    pj.business_group_id = gn_business_group_id
      AND    paaf.organization_id = haou.organization_id
      AND    papf.effective_end_date != paaf.effective_end_date
      AND    papf.person_type_id NOT IN
                                  (SELECT person_type_id
                                    FROM per_person_types
                                    WHERE system_person_type  IN ('EX_APL','EX_EMP','EX_EMP_APL')
                                    AND business_group_id = gn_business_group_id
                                    AND active_flag = 'Y')
      ;

    CURSOR c_site_manquant IS
      SELECT aps.vendor_id,papf.person_id,papf.employee_number,ass_attribute5,aps.party_id --YWA
        FROM per_all_assignments_f paaf,
             per_all_people_f      papf,
             ap_suppliers          aps,
             pa_tasks              pt,
             pa_projects_all       ppa
       WHERE SYSDATE BETWEEN paaf.effective_start_date AND paaf.effective_end_date
         AND paaf.ass_attribute5 IS NOT NULL
         AND papf.person_id = paaf.person_id
         AND aps.employee_id = paaf.person_id
         AND SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date
         AND pt.task_number = paaf.ass_attribute5
         AND SYSDATE BETWEEN nvl(pt.start_date,
                                 SYSDATE) AND nvl(pt.completion_date,
                                                  SYSDATE)
         AND ppa.project_id = pt.project_id
         AND ppa.enabled_flag = 'Y'
         AND ppa.summary_flag = 'N'
         AND ppa.template_flag = 'N'
         AND SYSDATE BETWEEN nvl(ppa.start_date,
                                 SYSDATE) AND nvl(ppa.closed_date,
                                                  SYSDATE)
         AND NOT EXISTS (SELECT NULL
                            FROM ap_supplier_sites_all apsa
                           WHERE aps.vendor_id = apsa.vendor_id
                             AND apsa.org_id = ppa.org_id
                             )
         AND    papf.person_type_id NOT IN
                                  (SELECT person_type_id
                                    FROM per_person_types
                                    WHERE system_person_type  IN ('EX_APL','EX_EMP','EX_EMP_APL')
                                    AND business_group_id = gn_business_group_id
                                    AND active_flag = 'Y');

    CURSOR c_site_a_desactiver IS
     SELECT
      papf.employee_number,
      papf.effective_end_date,
      apssa.vendor_site_id
     FROM per_person_types ppt,
      per_all_people_f papf,
      ap_suppliers aps,
      ap_supplier_sites_all apssa
     WHERE ppt.system_person_type  IN ('EX_APL','EX_EMP','EX_EMP_APL')
      AND ppt.business_group_id = 0
      AND ppt.active_flag = 'Y'
      AND papf.PERSON_TYPE_ID = ppt.PERSON_TYPE_ID
      AND SYSDATE BETWEEN papf.effective_start_date and effective_end_date
      AND aps.EMPLOYEE_ID = papf.person_id
      AND aps.vendor_id = apssa.vendor_id
      AND apssa.vendor_site_code = gv_vendor_site_code
      AND NVL(apssa.INACTIVE_DATE,SYSDATE) > papf.effective_end_date
      AND    papf.person_type_id NOT IN
                                  (SELECT person_type_id
                                    FROM per_person_types
                                    WHERE system_person_type  IN ('EX_APL','EX_EMP','EX_EMP_APL')
                                    AND business_group_id = gn_business_group_id
                                    AND active_flag = 'Y');

    CURSOR c_site_a_reactiver IS
     SELECT
      papf.employee_number,
      papf.effective_end_date,
      apssa.vendor_site_id
     FROM
      per_person_types      ppt,
      per_all_people_f      papf,
      per_all_assignments_f paaf,
      ap_suppliers          aps,
      ap_supplier_sites_all apssa
     WHERE ppt.system_person_type  NOT IN ('EX_APL','EX_EMP','EX_EMP_APL')
      AND ppt.business_group_id = 0
      AND ppt.active_flag = 'Y'
      AND papf.PERSON_TYPE_ID = ppt.PERSON_TYPE_ID
      AND SYSDATE BETWEEN papf.effective_start_date and papf.effective_end_date
      and paaf.person_id = papf.person_id
      and paaf.effective_end_date = (select max(effective_end_date) from per_all_assignments_f s_paaf
                                     where s_paaf.business_group_id = gn_business_group_id
                                     and s_paaf.person_id = papf.person_id)
      AND EXISTS (SELECT NULL
               FROM
                 pa_tasks              pt,
                 pa_projects_all       ppa
               WHERE
                 pt.task_number = paaf.ass_attribute5
                 AND apssa.org_id = ppa.org_id
                 AND SYSDATE BETWEEN nvl(pt.start_date,
                                         SYSDATE) AND nvl(pt.completion_date,
                                                          SYSDATE)
                 AND ppa.project_id = pt.project_id
                 AND ppa.enabled_flag = 'Y'
                 AND ppa.summary_flag = 'N'
                 AND ppa.template_flag = 'N'
                 AND SYSDATE BETWEEN nvl(ppa.start_date,
                                         SYSDATE) AND nvl(ppa.closed_date,
                                                          SYSDATE))
      AND aps.EMPLOYEE_ID = papf.person_id
      AND aps.vendor_id = apssa.vendor_id
      AND apssa.vendor_site_code = gv_vendor_site_code
      AND NVL(apssa.INACTIVE_DATE,papf.effective_end_date) < papf.effective_end_date
      AND    papf.person_type_id NOT IN
                                  (SELECT person_type_id
                                    FROM per_person_types
                                    WHERE system_person_type  IN ('EX_APL','EX_EMP','EX_EMP_APL')
                                    AND business_group_id = gn_business_group_id
                                    AND active_flag = 'Y');

    vn_assignment_id   PER_ALL_ASSIGNMENTS_F.ASSIGNMENT_ID%TYPE;
    vb_update_change_insert BOOLEAN;
    vb_correction      BOOLEAN;
    vb_update          BOOLEAN;
    vb_update_override BOOLEAN;
    vv_dt_ud_mode      VARCHAR2(100);
    vn_people_group_id             NUMBER;
    vn_asg_object_version_number   NUMBER;
    vn_special_ceiling_step_id     NUMBER;
    vc_group_name                  VARCHAR2(500);
    vd_effective_start_date        DATE;
    vd_effective_end_date          DATE;
    vb_org_now_no_manager_warning  BOOLEAN;
    vb_other_manager_warning       BOOLEAN;
    vb_spp_delete_warning          BOOLEAN;
    vc_entries_changed_warning     VARCHAR2(500);
    vb_tax_district_changed_warn   BOOLEAN;

    vd_ass_start_date      per_all_assignments_f.effective_start_date%TYPE;
    vd_ass_end_date        per_all_assignments_f.effective_end_date%TYPE;
    vn_job_id              per_all_assignments_f.job_id%TYPE;
    vv_job_name            per_jobs.name%TYPE;
    vv_fct                 per_jobs.name%TYPE;
    vn_organization_id     hr_all_organization_units.organization_id%TYPE;
    vv_organization_name   hr_all_organization_units.name%TYPE;
    vn_supervisor_id       per_all_assignments_f.supervisor_id%TYPE;
    vv_ass_attribute1      per_all_assignments_f.ass_attribute1%TYPE;
    vv_ass_attribute2      per_all_assignments_f.ass_attribute2%TYPE;
    vv_ass_attribute3      per_all_assignments_f.ass_attribute3%TYPE;
    vv_ass_attribute4      per_all_assignments_f.ass_attribute4%TYPE;
    vv_ass_attribute5      per_all_assignments_f.ass_attribute5%TYPE;

    --AFFECTATION
    vv_task_number          pa_tasks.task_number%TYPE;
    vv_task_id              pa_tasks.task_id%TYPE;
    vn_task_project_id      pa_projects_all.project_id%TYPE;
    vv_task_project_name    pa_projects_all.segment1%TYPE;
    vv_task_project_type    pa_projects_all.project_type%TYPE;
    vd_task_start_date      DATE;
    vd_task_completion_date DATE;
    vd_task_closed_date     DATE;
    vv_task_org_projet      hr_all_organization_units.name%TYPE;
    vn_task_org_projet_id   hr_all_organization_units.organization_id%TYPE;
    vv_task_societe         VARCHAR2(10);
    vv_task_region          VARCHAR2(10);
    vv_task_org_fin         hr_all_organization_units.name%TYPE;
    vn_task_org_fin_id      hr_all_organization_units.organization_id%TYPE;

    --VENDOR
    vn_vendor_id          NUMBER;
    vn_party_id           NUMBER;

    --VENDOR SITE
    vr_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_vendor_site_id     NUMBER;
    vn_party_site_id      NUMBER;
    vn_location_id        NUMBER;
    vv_calling_prog      VARCHAR2(200);

    vn_ledger_id      gl_ledgers.ledger_id%TYPE;
    vv_currency_code  ap_suppliers.invoice_currency_code%TYPE;
    vn_PREPAY_CCID    gl_code_combinations.code_combination_id%TYPE;
    vn_ACCTS_PAY_CCID gl_code_combinations.code_combination_id%TYPE;

    --LOCATION ID et PARTY_SITE_ID
    vr_location_rec hz_location_v2pub.location_rec_type;
    vr_party_site_rec  hz_party_site_v2pub.party_site_rec_type;
    vv_party_site_number VARCHAR2 (2000);

    --BANK
    vn_bank_acct_id        NUMBER;
    vv_association_level   VARCHAR2(50);
    vn_acct_id             NUMBER;
    vn_joint_acct_id       NUMBER;
    vr_response            iby_fndcpt_common_pub.result_rec_type;
    vv_org_type            VARCHAR2(50);

    vn_assign_id           NUMBER ;
    vr_payee_context_rec  IBY_DISBURSEMENT_SETUP_PUB.PayeeContext_rec_type;
    vr_assignment_attribs IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_rec_type;


    --API
    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2 (200);
    vv_commit             VARCHAR2 (200);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2 (200);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2 (4000);
    VN_MSG_INDEX_OUT      NUMBER;

    --MAJ BANQUE
    vn_ext_payee_id               iby_external_payees_all.EXT_PAYEE_ID%TYPE;
    vt_External_Payee_Tab_Type    IBY_DISBURSEMENT_SETUP_PUB.External_Payee_Tab_Type;
    vt_Ext_Payee_ID_Tab_Type      IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_ID_Tab_Type;
    vt_Ext_Payee_Create_Tab_Type  IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_Create_Tab_Type;
    vt_Ext_Payee_Update_Tab_Type  IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_Update_Tab_Type;
    vr_External_Payee_Rec         IBY_DISBURSEMENT_SETUP_PUB.External_Payee_Rec_Type;

    vv_payment_method     ap_suppliers.payment_method_lookup_code%TYPE;

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    --######################################################################################
    -- FONCTIONS
    --######################################################################################
    gv_step  := lv_current_program_unit||' 001 : Mise a jour des employés ayant des fonctions non renseignées';log_message(gv_step);

    FOR l_emp in c_fonction_vide LOOP
      BEGIN

        gv_step  := lv_current_program_unit||' 002 : Fonction non renseignée pour l''employé : '||l_emp.employee_number;log_message(gv_step);

        vn_asg_object_version_number := l_emp.object_version_number;

        gv_step  := lv_current_program_unit||' 003 : Recherche de la fonction: '||l_emp.attribute2||'.'||gv_default_job;log_message(gv_step);
        vn_job_id := get_job_id(l_emp.attribute2,gv_default_job);

        IF vn_job_id IS NULL THEN
         --Le poste n'existe pas
         RAISE e_daily_error;
        END IF;

         -- Find Date Track Mode for Second API
         -- ------------------------------------------------------
        gv_step  := lv_current_program_unit||' 004 : AFFECTATION - API STD';log_message(gv_step);

        BEGIN

          vn_assignment_id := l_emp.assignment_id;

          dt_api.find_dt_upd_modes
            (  p_effective_date             => TRUNC(SYSDATE),
               p_base_table_name            => 'PER_ALL_ASSIGNMENTS_F',
               p_base_key_column            => 'ASSIGNMENT_ID',
               p_base_key_value             => vn_assignment_id,
               -- Output data elements
               -- -------------------------------
               p_correction                 => vb_correction,
               p_update                     => vb_update,
               p_update_override            => vb_update_override,
               p_update_change_insert       => vb_update_change_insert
            );

          IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE )
          THEN  -- UPDATE_OVERRIDE
            vv_dt_ud_mode := 'UPDATE_OVERRIDE';
          END IF;
           IF ( vb_correction = TRUE )
           THEN -- CORRECTION
             vv_dt_ud_mode := 'CORRECTION';
          END IF;
          IF ( vb_update = TRUE )
          THEN -- UPDATE
            vv_dt_ud_mode := 'UPDATE';
          END IF;

           -- Update Employee Assgment Criteria
           -- -----------------------------------------------------
          gv_step  := lv_current_program_unit||' 005 : AFFECTATION - API STD : Update Employee Assgment Criteria ';log_message(gv_step);


           hr_assignment_api.update_emp_asg_criteria
           ( -- Input data elements
            -- ------------------------------
            p_effective_date                      => TRUNC(SYSDATE),
            p_datetrack_update_mode               => vv_dt_ud_mode,
            p_job_id                              => vn_job_id,
            p_assignment_id                       => l_emp.assignment_id,
            p_object_version_number               => vn_asg_object_version_number,
            -- Output data elements
            -- -------------------------------
            p_people_group_id                     => vn_people_group_id,
            p_special_ceiling_step_id             => vn_special_ceiling_step_id,
            p_group_name                          => vc_group_name,
            p_effective_start_date                => vd_effective_start_date,
            p_effective_end_date                  => vd_effective_end_date,
            p_org_now_no_manager_warning          => vb_org_now_no_manager_warning,
            p_other_manager_warning               => vb_other_manager_warning,
            p_spp_delete_warning                  => vb_spp_delete_warning,
            p_entries_changed_warning             => vc_entries_changed_warning,
            p_tax_district_changed_warning        => vb_tax_district_changed_warn
           );


        EXCEPTION
        WHEN OTHERS THEN
         --Mise a jour de l'affectation employé impossible, erreur dans l'API : Update Employee Assgment Criteria
         gv_step  := lv_current_program_unit||' 005 : AFFECTATION - API STD : Erreur :'||SQLERRM;log_message(gv_step);
         RAISE e_daily_error;
        END;

        gv_step  := lv_current_program_unit||' 099 : COMMIT MISE A JOUR FONCTION ';log_message(gv_step);
        COMMIT;

      EXCEPTION
       WHEN e_daily_error THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_DAILY_ERROR gv_step :'||gv_step;log_message(gv_step);
        ROLLBACK;
        --Suivant
       WHEN OTHERS THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION gv_step :'||gv_step||chr(10)||SQLERRM;
        log_message(gv_step);
        ROLLBACK;
        --Suivant
      END;

    END LOOP;

    --######################################################################################
    -- SITES MANQUANTS
    --######################################################################################
    gv_step  := lv_current_program_unit||' 101 : Créations des sites fournisseurs employé manquant';log_message(gv_step);

    FOR l_site IN c_site_manquant LOOP
      BEGIN

        --REINIT
        vv_payment_method := NULL;

        --Recherche de la tache du projet
        gv_step  := lv_current_program_unit||' 102 : Recherche de l''affectation';log_message(gv_step);
        get_assign_info(l_site.employee_number,
                        vn_assignment_id,
                        vn_asg_object_version_number,
                        vd_ass_start_date,
                        vd_ass_end_date,
                        vn_job_id,
                        vv_job_name,
                        vv_fct,
                        vn_organization_id,
                        vv_organization_name,
                        vn_supervisor_id,
                        vv_ass_attribute1,
                        vv_ass_attribute2,
                        vv_ass_attribute3,
                        vv_ass_attribute4,
                        vv_ass_attribute5);

        IF vn_asg_object_version_number IS NULL THEN
          gv_step  := lv_current_program_unit||'  102 : Recherche de l''affectation non trouvée';log_message(gv_step);
          raise e_daily_error;
        END IF;

        --Recherche des infos de la tache du projet
        gv_step  := lv_current_program_unit||' 103 : Recherche des infos de la tache du projet';log_message(gv_step);
        DKA_PA_TOOLS_PKG.pa_get_info_task(vv_errbuf,
                                          vn_retcode,
                                          l_site.ass_attribute5,
                                          vv_task_id,
                                          vn_task_project_id,
                                          vv_task_project_name,
                                          vv_task_project_type,
                                          vd_task_start_date,
                                          vd_task_completion_date,
                                          vd_task_closed_date,
                                          vv_task_org_projet,
                                          vn_task_org_projet_id,
                                          vv_task_societe,
                                          vv_task_region,
                                          vv_task_org_fin,
                                          vn_task_org_fin_id);

        IF vn_retcode != 0 THEN
          gv_step  := lv_current_program_unit||' 103 : Recherche des infos de la tache du projet non trouvée';log_message(gv_step);
          raise e_daily_error;
        END IF;

        --Recherche du fournisseur et site fournisseur
        gv_step  := lv_current_program_unit||' 104 : Recherche du fournisseur et site fournisseur';log_message(gv_step);
        get_supplier_site_info(l_site.person_id,vn_task_org_projet_id, vn_vendor_id , vn_party_id,vn_vendor_site_id,vn_party_site_id );

        IF vn_vendor_site_id IS NULL THEN
          --Le site n'existe pas, création
          gv_step  := lv_current_program_unit||' 105 : Le site fournisseur n''existe pas ==> création';log_message(gv_step);

          --Entité comptable
          gv_step  := lv_current_program_unit||' 106 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
          vn_ledger_id := dka_gl_tools_pkg.get_legder_id(vv_task_societe);

          IF vn_ledger_id IS NULL THEN
             RAISE e_daily_error;
          END IF;

          --Devise Entité comptable
          gv_step  := lv_current_program_unit||' 107 : Recherche de l''entité comptable: '||vv_task_societe;log_message(gv_step);
          vv_currency_code := get_currency_code(vn_ledger_id);

          IF vv_currency_code IS NULL THEN
             RAISE e_daily_error;
          END IF;

          --Compte GL founisseur
          gv_step  := lv_current_program_unit||' 108 : Compte GL founisseur';log_message(gv_step);
          Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => vv_task_societe,
                                                pv_segment2              => vv_task_region,
                                                pv_segment3              => gv_accts_local,
                                                pv_segment4              => gv_accts_anal,
                                                pv_segment5              => gv_ccid_defaut,
                                                pv_segment6              => gv_ccid_defaut,
                                                pv_segment7              => gv_ccid_defaut,
                                                pv_segment8              => gv_ccid_defaut,
                                                pv_segment9              => gv_ccid_defaut,
                                                pv_segment10             => gv_ccid_defaut,
                                                pv_segment11             => gv_ccid_defaut,
                                                pv_segment12             => gv_ccid_defaut,
                                                pn_code_combination_id   => vn_ACCTS_PAY_CCID,
                                                pv_errbuf                => vv_errbuf,
                                                pn_retcode               => vn_retcode);

          gv_step  := lv_current_program_unit||' 109 : Compte GL founisseur : '||vn_ACCTS_PAY_CCID;log_message(gv_step);

          IF  vn_retcode != 0 THEN
            RAISE e_daily_error;
          END IF;

          --Compte GL acompte
          gv_step  := lv_current_program_unit||' 110 : Compte GL acompte';log_message(gv_step);
          Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => vv_task_societe,
                                                pv_segment2              => vv_task_region,
                                                pv_segment3              => gv_prepay_local,
                                                pv_segment4              => gv_prepay_anal,
                                                pv_segment5              => gv_ccid_defaut,
                                                pv_segment6              => gv_ccid_defaut,
                                                pv_segment7              => gv_ccid_defaut,
                                                pv_segment8              => gv_ccid_defaut,
                                                pv_segment9              => gv_ccid_defaut,
                                                pv_segment10             => gv_ccid_defaut,
                                                pv_segment11             => gv_ccid_defaut,
                                                pv_segment12             => gv_ccid_defaut,
                                                pn_code_combination_id   => vn_PREPAY_CCID,
                                                pv_errbuf                => vv_errbuf,
                                                pn_retcode               => vn_retcode);

          gv_step  := lv_current_program_unit||' 111 : Compte GL acompte : '||vn_PREPAY_CCID;log_message(gv_step);


          IF  vn_retcode != 0 THEN
            RAISE e_daily_error;
          END IF;

          --Init valeur site fournisseur
          vn_api_version      := 1.0;
          vv_init_msg_list    := FND_API.G_TRUE;
          vv_commit           := FND_API.G_FALSE;
          vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
          vv_return_status    := NULL;
          vn_msg_count        := NULL;
          vv_msg_data         := NULL;

          vn_vendor_site_id     := NULL;
          vn_party_site_id      := NULL;
          vn_location_id        := NULL;

          vr_vendor_site_rec.VENDOR_ID        := l_site.vendor_id;--YWA
          vr_vendor_site_rec.ATTRIBUTE4       := 'P'||l_site.employee_number;
          vr_vendor_site_rec.ACCTS_PAY_CODE_COMBINATION_ID := vn_ACCTS_PAY_CCID;
          vr_vendor_site_rec.PREPAY_CODE_COMBINATION_ID    := vn_PREPAY_CCID;
          vr_vendor_site_rec.ORG_ID           := vn_task_org_projet_id;

          vr_vendor_site_rec.VENDOR_SITE_CODE := gv_vendor_site_code;
          vr_vendor_site_rec.COUNTRY          := gv_vendor_site_ctry;
          vr_vendor_site_rec.ADDRESS_LINE1    := '.';
          vr_vendor_site_rec.PAY_GROUP_LOOKUP_CODE :=   gv_pay_group_lookup_code;
          vr_vendor_site_rec.PAYMENT_PRIORITY := gn_payment_priority;
          vr_vendor_site_rec.TERMS_ID         := gn_term_id;

          vr_vendor_site_rec.INVOICE_CURRENCY_CODE  := vv_currency_code;
          vr_vendor_site_rec.PAYMENT_CURRENCY_CODE  := vv_currency_code;
          vr_vendor_site_rec.PAY_DATE_BASIS_LOOKUP_CODE := gv_pay_date_basis_lookup_code;
          vr_vendor_site_rec.TERMS_DATE_BASIS           := gv_terms_date_basis;
          --vr_vendor_site_rec.ext_payee_rec.default_pmt_method := gv_payment_method_cheque; --On crée le fournisseur avec la methode CHECK
          --                                                                      --qu'on mettra a jour apres la rattachement
          --                                                                      --d'un compte bancaire s'il existe
          vr_vendor_site_rec.Purchasing_site_flag          := 'N';
          vr_vendor_site_rec.pay_site_flag                 := 'Y';
          vr_vendor_site_rec.attention_ar_flag             := 'N';
          vr_vendor_site_rec.rfq_only_site_flag            := 'N';
          vr_vendor_site_rec.always_take_disc_flag         := 'N';
          vr_vendor_site_rec.hold_all_payments_flag        := 'N';
          vr_vendor_site_rec.hold_future_payments_flag     := 'N';
          vr_vendor_site_rec.hold_unmatched_invoices_flag  := 'N';
          vr_vendor_site_rec.exclude_freight_from_discount := 'N';
          vr_vendor_site_rec.auto_tax_calc_flag            := 'Y';
          vr_vendor_site_rec.match_option                  := 'P';

          --///Création du site fournisseur - API
          gv_step  := lv_current_program_unit||' 112 : Création du site fournisseur - API';log_message(gv_step);
          ap_vendor_pub_pkg.create_vendor_site (vn_api_version,
                                                vv_init_msg_list,
                                                vv_commit,
                                                vn_validation_level,
                                                vv_return_status,
                                                vn_msg_count,
                                                vv_msg_data,
                                                vr_vendor_site_rec,
                                                vn_vendor_site_id,
                                                vn_party_site_id,
                                                vn_location_id
                                                 );

          IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
            --On continue
            gv_step  := lv_current_program_unit||' 113 : Création du site fournisseur - API : Success';log_message(gv_step);
            NULL;
          ELSE
            vv_message := '';
            IF vn_msg_count > 0 THEN

              FOR v_index IN 1 .. vn_msg_count LOOP
                fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

              END LOOP;

            END IF;

            --Création du site fournisseur impossible : message
            gv_step  := lv_current_program_unit||' 113 : Création du site fournisseur - API : Erreur :'||vv_message;
            RAISE e_daily_error;

          END IF;

          --######################################################################################
          --AJOUT DU LOCATION_ID
          --######################################################################################

          gv_step  := lv_current_program_unit||' 056A : Création du LOCATION_ID - API';log_message(gv_step);
          vr_location_rec.country := gv_vendor_site_ctry;
          vr_location_rec.address1 := '.';
          vr_location_rec.created_by_module := 'TCA_V2_API';

          hz_location_v2pub.create_location (p_init_msg_list      => vv_init_msg_list,
                                             p_location_rec       => vr_location_rec,
                                             x_location_id        => vn_location_id,
                                             x_return_status      => vv_return_status,
                                             x_msg_count          => vn_msg_count,
                                             x_msg_data           => vv_msg_data
                                            );
          IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
            --On continue
            gv_step  := lv_current_program_unit||' 056A : Création du LOCATION_ID - API : Success';log_message(gv_step);
            NULL;
          ELSE
            vv_message := '';
            IF vn_msg_count > 0 THEN

              FOR v_index IN 1 .. vn_msg_count LOOP
                fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

              END LOOP;

            END IF;

            --Création du lieu fournisseur impossible : message
            gv_step  := lv_current_program_unit||' 056A : Création du LOCATION_ID - API : Erreur :'||vv_message;
            RAISE e_daily_error;

          END IF;

          gv_step  := lv_current_program_unit||' 056C : Maj du site fournisseur avec LOCATION_ID - API';log_message(gv_step);

          vr_vendor_site_rec                := NULL;
          vr_vendor_site_rec.vendor_id      := l_site.vendor_id;--YWA vn_vendor_id;
          vr_vendor_site_rec.org_id         := vn_task_org_projet_id;
          vr_vendor_site_rec.vendor_site_id := vn_vendor_site_id;
          vr_vendor_site_rec.location_id    := vn_location_id;

          ap_vendor_pub_pkg.Update_Vendor_Site
                                         (p_api_version          => vn_api_version,
                                          x_return_status        => vv_return_status,
                                          x_msg_count            => vn_msg_count,
                                          x_msg_data             => vv_msg_data,
                                          p_vendor_site_rec      => vr_vendor_site_rec,
                                          p_vendor_site_id       => vn_vendor_site_id
                                         );

          IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
            --On continue
            gv_step  := lv_current_program_unit||' 056C : Maj du site fournisseur avec LOCATION_ID - API : Success';log_message(gv_step);

            NULL;
          ELSE
            vv_message := '';
            IF vn_msg_count > 0 THEN

              FOR v_index IN 1 .. vn_msg_count LOOP
                fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

              END LOOP;

            END IF;

            --Mise a jour du site fournisseur avec LOCATION_ID impossible : message
            gv_step  := lv_current_program_unit||' 056C : Maj du site fournisseur avec LOCATION_ID - API : Erreur :'||vv_message;
            RAISE e_daily_error;

          END IF;

          ----------
          --Compte bancaire
          --Recherche du compte bancaire sur un site de l'employé
          gv_step  := lv_current_program_unit||' 114 : Recherche du compte bancaire sur un site de l''employé';log_message(gv_step);
          get_cpt_bank_emp (l_site.person_id,vn_bank_acct_id);

          IF vn_bank_acct_id IS NOT NULL THEN

            gv_step  := lv_current_program_unit||' 115 : Rattachement du compte bancaire : '||vn_bank_acct_id;log_message(gv_step);


            vn_api_version       := 1.0;
            vv_init_msg_list     := FND_API.G_TRUE;
            vv_commit            := FND_API.G_FALSE;
            vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
            vv_return_status     := NULL;
            vn_msg_count         := NULL;
            vv_msg_data          := NULL;

            --Rattachement du compte bancaire
            gv_step  := lv_current_program_unit||' 116 : Controle proprietaire compte bancaire - API';log_message(gv_step);
            IBY_EXT_BANKACCT_PUB.check_bank_acct_owner   (p_api_version         => vn_api_version,
                                                          p_init_msg_list       => FND_API.G_TRUE,
                                                          p_bank_acct_id        => vn_bank_acct_id,
                                                          p_acct_owner_party_id => l_site.party_id,--YWA vn_party_id,  --site
                                                          x_return_status       => vv_return_status,
                                                          x_msg_count           => vn_msg_count,
                                                          x_msg_data            => vv_msg_data,
                                                          x_response            => vr_response
                                                          );

            IF  vv_return_status <> 'S' THEN
              gv_step  := lv_current_program_unit||' 117 : Controle proprietaire compte bancaire KO';log_message(gv_step);


              vn_api_version       := 1.0;
              vv_init_msg_list     := FND_API.G_TRUE;
              vv_commit            := FND_API.G_FALSE;
              vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
              vv_return_status     := NULL;
              vn_msg_count         := NULL;
              vv_msg_data          := NULL;

              vn_joint_acct_id     := NULL;

              gv_step  := lv_current_program_unit||' 118 : liaison compte bancaire - API';log_message(gv_step);
              IBY_EXT_BANKACCT_PUB.add_joint_account_owner( p_api_version         => vn_api_version,
                                                            p_init_msg_list       => vv_init_msg_list,
                                                            p_bank_account_id     => vn_bank_acct_id,
                                                            p_acct_owner_party_id => l_site.party_id,--YWA vn_party_id,    --site
                                                            x_joint_acct_owner_id => vn_joint_acct_id,
                                                            x_return_status       => vv_return_status,
                                                            x_msg_count           => vn_msg_count,
                                                            x_msg_data            => vv_msg_data,
                                                            x_response            => vr_response
                                                           );

              IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                --On continue
                gv_step  := lv_current_program_unit||' 119 : liaison compte bancaire - API : Success';log_message(gv_step);
                NULL;
              ELSE
                vv_message := '';
                IF fnd_msg_pub.count_msg > 0 THEN

                  FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                    vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                  END LOOP;

                END IF;

                --Rattachement du compte bancaire impossible : message
                gv_step  := 'Rattachement du compte bancaire impossible : '||vv_message;
                RAISE e_daily_error;

              END IF;

            ELSE

              --Cet employé est déja propriétaire de son compte bancaire
              gv_step  := lv_current_program_unit||' 120 : Controle proprietaire compte bancaire OK';log_message(gv_step);
              NULL;

            END IF;

            --//Finalisation lien site - employé
            gv_step  := lv_current_program_unit||' 121 : Finalisation lien site - employé';log_message(gv_step);

            vn_api_version       := 1.0;
            vv_init_msg_list     := FND_API.G_TRUE;
            vv_commit            := FND_API.G_FALSE;
            vn_validation_level  := FND_API.G_VALID_LEVEL_FULL;
            vv_return_status     := NULL;
            vn_msg_count         := NULL;
            vv_msg_data          := NULL;

            vr_payee_context_rec.Party_Id                     := l_site.party_id;--YWA vn_party_id;
            vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
            vr_payee_context_rec.party_site_id                := vn_party_site_id;
            vr_payee_context_rec.Supplier_Site_id             := vn_vendor_site_id;
            vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
            vr_payee_context_rec.Org_Id                       := vn_task_org_projet_id;

            vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
            vr_assignment_attribs.instrument.instrument_id    := vn_bank_acct_id;
            vr_assignment_attribs.start_date                  := TRUNC(SYSDATE);

            -- map account to site supplier
            gv_step  := lv_current_program_unit||' 122 : Finalisation lien site - employé - API';log_message(gv_step);
            IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => vn_api_version,
                                                                   p_init_msg_list      => vv_init_msg_list,
                                                                   p_commit             => vv_commit,
                                                                   x_return_status      => vv_return_status,
                                                                   x_msg_count          => vn_msg_count,
                                                                   x_msg_data           => vv_msg_data,
                                                                   p_payee              => vr_payee_context_rec,
                                                                   p_assignment_attribs => vr_assignment_attribs,
                                                                   x_assign_id          => vn_assign_id,
                                                                   x_response           => vr_response
                                                                   );

            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              gv_step  := lv_current_program_unit||' 123 : Finalisation lien site - employé - API : Success';log_message(gv_step);
              NULL;
            ELSE
              vv_message := '';
              IF fnd_msg_pub.count_msg > 0 THEN

                FOR v_index IN 1 .. fnd_msg_pub.count_msg LOOP
                  vv_message := fnd_msg_pub.get(p_msg_index => v_index,p_encoded   => fnd_api.g_false)||' '||vv_message;
                END LOOP;

              END IF;

              --Rattachement du compte bancaire au site employé impossible : message
              gv_step := 'Rattachement du compte bancaire au site employé impossible : '||vv_message;
              RAISE e_daily_error;

            END IF;

            gv_step  := lv_current_program_unit||' 124 : Mode de reglement = EFT';log_message(gv_step);
            vv_payment_method := gv_payment_method_virement;


          ELSE
           --Pas de compte, on ne fait rien
           gv_step  := lv_current_program_unit||' 125 : Pas de compte bancaire sur un site de l''employé';log_message(gv_step);
           gv_step  := lv_current_program_unit||' 126 : Mode de reglement = CHECK';log_message(gv_step);
           vv_payment_method := gv_payment_method_cheque;
          END IF;

          --Modification site fournisseur
          gv_step  := lv_current_program_unit||' 127 : Modification site fournisseur : EFT';log_message(gv_step);

          vn_api_version      := 1.0;
          vv_init_msg_list    := FND_API.G_TRUE;
          vv_commit           := FND_API.G_FALSE;
          vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
          vv_return_status    := NULL;
          vn_msg_count        := NULL;
          vv_msg_data         := NULL;

          vn_ext_payee_id := NULL;
          vt_External_Payee_Tab_Type.DELETE;
          vt_Ext_Payee_ID_Tab_Type.DELETE;
          vt_Ext_Payee_Update_Tab_Type.DELETE;
          vt_Ext_Payee_Create_Tab_Type.DELETE;

          BEGIN

            SELECT
                 payee.EXT_PAYEE_ID,
                 payee.payee_party_id,
                 payee.PAYMENT_FUNCTION,
                 payee.ORG_ID,
                 payee.org_type,
                 payee.SUPPLIER_SITE_ID,
                 assa.party_site_id
            INTO
                 vn_ext_payee_id,
                 vr_External_Payee_Rec.payee_party_id,
                 vr_External_Payee_Rec.payment_function,
                 vr_External_Payee_Rec.payer_org_id,
                 vr_External_Payee_Rec.payer_org_type,
                 vr_External_Payee_Rec.supplier_site_id,
                 vr_External_Payee_Rec.Payee_Party_Site_Id
            FROM iby_external_payees_all  payee,
                 ap_supplier_sites_all    assa
           WHERE payee.payment_function = 'PAYABLES_DISB'
             AND payee.supplier_site_id = vn_vendor_site_id
             AND payee.supplier_site_id = assa.vendor_site_id;

          EXCEPTION
           WHEN TOO_MANY_ROWS THEN
            BEGIN
              SELECT
                   payee.EXT_PAYEE_ID,
                   payee.payee_party_id,
                   payee.PAYMENT_FUNCTION,
                   payee.ORG_ID,
                   payee.org_type,
                   payee.SUPPLIER_SITE_ID,
                   assa.party_site_id
              INTO
                   vn_ext_payee_id,
                   vr_External_Payee_Rec.payee_party_id,
                   vr_External_Payee_Rec.payment_function,
                   vr_External_Payee_Rec.payer_org_id,
                   vr_External_Payee_Rec.payer_org_type,
                   vr_External_Payee_Rec.supplier_site_id,
                   vr_External_Payee_Rec.Payee_Party_Site_Id
              FROM iby_external_payees_all  payee,
                   ap_supplier_sites_all    assa
             WHERE payee.payment_function = 'PAYABLES_DISB'
               AND payee.supplier_site_id = vn_vendor_site_id
               AND payee.supplier_site_id = assa.vendor_site_id
               AND (payee.party_site_id = assa.party_site_id or payee.party_site_id is null)
               AND payee.EXT_PAYEE_ID = (select max(iep.EXT_PAYEE_ID)
                                         from iby_external_payees_all iep
                                         where iep.supplier_site_id = vn_vendor_site_id)
                ;
            EXCEPTION
             WHEN OTHERS THEN
              --Modification de la methode de paiement du site fournisseur impossible : message
            gv_step := 'Erreur lors de la recherche des informations bancaires (TOO MANY ROWS) :'||SQLERRM;
            RAISE e_daily_error;
            END;
           WHEN OTHERS THEN
            --Modification de la methode de paiement du site fournisseur impossible : message
            gv_step := 'Erreur lors de la recherche des informations bancaires (OTHERS) :'||SQLERRM;
            RAISE e_daily_error;
          END;

          vr_External_Payee_Rec.default_pmt_method := vv_payment_method;
          vr_External_Payee_Rec.exclusive_pay_flag := 'N';

          vt_External_Payee_Tab_Type(1):= vr_External_Payee_Rec;

          vt_Ext_Payee_ID_Tab_Type(1).ext_payee_id := vn_ext_payee_id;


          IF vv_payment_method =  gv_payment_method_cheque THEN
            --CHECK CREATION
            gv_step  := lv_current_program_unit||' 128 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee - API';log_message(gv_step);
            IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee(p_api_version           => vn_api_version,
                                                             p_init_msg_list         => vv_init_msg_list,
                                                             p_ext_payee_tab         => vt_External_Payee_Tab_Type,
                                                             x_return_status         => vv_return_status,
                                                             x_msg_count             => vn_msg_count,
                                                             x_msg_data              => vv_msg_data,
                                                             x_ext_payee_id_tab      => vt_Ext_Payee_ID_Tab_Type,
                                                             x_ext_payee_status_tab  => vt_Ext_Payee_Create_Tab_Type
                                                          );

            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              gv_step  := lv_current_program_unit||' 128 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee - API : Success';log_message(gv_step);
              NULL;
            ELSE
              vv_message := '';
              IF vn_msg_count > 0 THEN

                FOR v_index IN 1 .. vn_msg_count LOOP
                  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                END LOOP;

              END IF;

              --Error Message from table type
              IF vt_Ext_Payee_Create_Tab_Type.count > 0 THEN
                FOR j IN vt_Ext_Payee_Create_Tab_Type.FIRST .. vt_Ext_Payee_Create_Tab_Type.LAST LOOP
                  vv_message := substr(vv_message || chr(10) ||  vt_Ext_Payee_Create_Tab_Type (j).Payee_Creation_Msg,1,500);
                END LOOP;
              END IF;

              --Modification de la methode de paiement du site fournisseur impossible : message
              gv_step := 'Modification de la methode de paiement du site fournisseur impossible'||chr(10)||vv_message;
              RAISE e_daily_error;

            END IF;

          ELSIF vv_payment_method =  gv_payment_method_virement THEN
            --EFT - UPDATE
            vt_Ext_Payee_ID_Tab_Type(1).ext_payee_id := vn_ext_payee_id;


            gv_step  := lv_current_program_unit||' 128 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API';log_message(gv_step);
            IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee(p_api_version           => vn_api_version,
                                                             p_init_msg_list         => vv_init_msg_list,
                                                             p_ext_payee_tab         => vt_External_Payee_Tab_Type,
                                                             p_ext_payee_id_tab      => vt_Ext_Payee_ID_Tab_Type,
                                                             x_return_status         => vv_return_status,
                                                             x_msg_count             => vn_msg_count,
                                                             x_msg_data              => vv_msg_data,
                                                             x_ext_payee_status_tab  => vt_Ext_Payee_Update_Tab_Type
                                                          );



            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              gv_step  := lv_current_program_unit||' 128 : Modification méthode de réglement : IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee - API : Success';log_message(gv_step);
              NULL;
            ELSE
              vv_message := '';
              IF vn_msg_count > 0 THEN

                FOR v_index IN 1 .. vn_msg_count LOOP
                  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

                END LOOP;

              END IF;

              --Error Message from table type
              IF vt_Ext_Payee_Update_Tab_Type.count > 0 THEN
                FOR j IN vt_Ext_Payee_Update_Tab_Type.FIRST .. vt_Ext_Payee_Update_Tab_Type.LAST LOOP
                  vv_message := substr(vv_message || chr(10) ||  vt_Ext_Payee_Update_Tab_Type (j).payee_update_msg,1,500);
                END LOOP;
              END IF;

              --Modification de la methode de paiement du site fournisseur impossible : message
              gv_step := 'Modification de la methode de paiement du site fournisseur impossible'||chr(10)||vv_message;
              RAISE e_daily_error;

            END IF;
          END IF; --vv_payment_method


        ELSE
          --Le site existe déja, on ne fait rien
          gv_step  := lv_current_program_unit||' 129 : Le site fournisseur existe déja, on ne fait rien';log_message(gv_step);
        END IF;


      EXCEPTION
       WHEN e_daily_error THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_DAILY_ERROR gv_step :'||gv_step;log_message(gv_step);
        --ROLLBACK; ARA MIGRATION
        --Suivant
       WHEN OTHERS THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION gv_step :'||gv_step||chr(10)||SQLERRM;
        log_message(gv_step);
        --ROLLBACK; ARA MIGRATION
        --Suivant
      END;

    END LOOP; -- fin loop c_site_manquant

    --######################################################################################
    -- REPORT DATE DE FIN
    --######################################################################################
    gv_step  := lv_current_program_unit||' 201 : Report des dates de fin de validité';log_message(gv_step);

    FOR l_date IN c_date_affectation LOOP

      vn_asg_object_version_number := l_date.object_version_number;


      IF l_date.papf_effective_end_date = cd_date_fin THEN
        --Mise a jour de la derniere affectation
        gv_step  := lv_current_program_unit||' 202 : Mise a jour de la derniere affectation';log_message(gv_step);


        -- Find Date Track Mode for Second API
        -- ------------------------------------------------------
        gv_step  := lv_current_program_unit||' 203 : AFFECTATION - API STD';log_message(gv_step);

        BEGIN


          dt_api.find_dt_upd_modes
          (  p_effective_date             => trunc(sysdate),
             p_base_table_name            => 'PER_ALL_ASSIGNMENTS_F',
             p_base_key_column            => 'ASSIGNMENT_ID',
             p_base_key_value             => l_date.assignment_id,
             -- Output data elements
             -- -------------------------------
             p_correction                 => vb_correction,
             p_update                     => vb_update,
             p_update_override            => vb_update_override,
             p_update_change_insert       => vb_update_change_insert
          );

          IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE )
          THEN  -- UPDATE_OVERRIDE
            vv_dt_ud_mode := 'UPDATE_OVERRIDE';
          END IF;
          IF ( vb_correction = TRUE )
          THEN -- CORRECTION
            vv_dt_ud_mode := 'CORRECTION';
          END IF;
          IF ( vb_update = TRUE )
          THEN -- UPDATE
            vv_dt_ud_mode := 'UPDATE';
          END IF;


          -- Update Employee Assgment Criteria
          -- -----------------------------------------------------
          gv_step  := lv_current_program_unit||' 204 : AFFECTATION - API STD : Update Employee Assgment Criteria ';log_message(gv_step);

          vd_effective_start_date := l_date.paaf_effective_start_date;
          vd_effective_end_date   := l_date.papf_effective_end_date;

          hr_assignment_api.update_emp_asg_criteria
          ( -- Input data elements
            -- ------------------------------
            p_effective_date                      => TRUNC(SYSDATE),
            p_datetrack_update_mode               => vv_dt_ud_mode,
            p_assignment_id                       => l_date.assignment_id,
            p_object_version_number               => vn_asg_object_version_number,
            -- Output data elements
            -- -------------------------------
            p_people_group_id                     => vn_people_group_id,
            p_special_ceiling_step_id             => vn_special_ceiling_step_id,
            p_group_name                          => vc_group_name,
            p_effective_start_date                => vd_effective_start_date,
            p_effective_end_date                  => vd_effective_end_date,
            p_org_now_no_manager_warning          => vb_org_now_no_manager_warning,
            p_other_manager_warning               => vb_other_manager_warning,
            p_spp_delete_warning                  => vb_spp_delete_warning,
            p_entries_changed_warning             => vc_entries_changed_warning,
            p_tax_district_changed_warning        => vb_tax_district_changed_warn
            );


        EXCEPTION
         WHEN OTHERS THEN
          gv_step  := lv_current_program_unit||' EEE : EXCEPTION gv_step :'||gv_step||chr(10)||SQLERRM;
          log_message(gv_step);
          --ROLLBACK; ARA MIGRATION
          --Suivant
        END;

      ELSIF l_date.papf_effective_end_date != cd_date_fin AND l_date.papf_effective_end_date < TRUNC(SYSDATE) THEN

         --Mise a jour de la derniere affectation a la date du jour +1
        gv_step  := lv_current_program_unit||' 202 : Mise a jour de la derniere affectation';log_message(gv_step);


        -- Find Date Track Mode for Second API
        -- ------------------------------------------------------
        gv_step  := lv_current_program_unit||' 203 : AFFECTATION - API STD';log_message(gv_step);

        BEGIN

          dt_api.find_dt_upd_modes
          (  p_effective_date             => trunc(sysdate),
             p_base_table_name            => 'PER_ALL_ASSIGNMENTS_F',
             p_base_key_column            => 'ASSIGNMENT_ID',
             p_base_key_value             => l_date.assignment_id,
             -- Output data elements
             -- -------------------------------
             p_correction                 => vb_correction,
             p_update                     => vb_update,
             p_update_override            => vb_update_override,
             p_update_change_insert       => vb_update_change_insert
          );

          IF ( vb_update_override = TRUE OR vb_update_change_insert = TRUE )
          THEN  -- UPDATE_OVERRIDE
            vv_dt_ud_mode := 'UPDATE_OVERRIDE';
          END IF;
          IF ( vb_correction = TRUE )
          THEN -- CORRECTION
            vv_dt_ud_mode := 'CORRECTION';
          END IF;
          IF ( vb_update = TRUE )
          THEN -- UPDATE
            vv_dt_ud_mode := 'UPDATE';
          END IF;


          -- Update Employee Assgment Criteria
          -- -----------------------------------------------------
          gv_step  := lv_current_program_unit||' 204 : AFFECTATION - API STD : Update Employee Assgment Criteria ';log_message(gv_step);

          vd_effective_start_date := l_date.paaf_effective_start_date;
          vd_effective_end_date   := TRUNC(SYSDATE);

          hr_assignment_api.update_emp_asg_criteria
          ( -- Input data elements
            -- ------------------------------
            p_effective_date                      => TRUNC(SYSDATE),
            p_datetrack_update_mode               => vv_dt_ud_mode,
            p_assignment_id                       => l_date.assignment_id,
            p_object_version_number               => vn_asg_object_version_number,
            -- Output data elements
            -- -------------------------------
            p_people_group_id                     => vn_people_group_id,
            p_special_ceiling_step_id             => vn_special_ceiling_step_id,
            p_group_name                          => vc_group_name,
            p_effective_start_date                => vd_effective_start_date,
            p_effective_end_date                  => vd_effective_end_date,
            p_org_now_no_manager_warning          => vb_org_now_no_manager_warning,
            p_other_manager_warning               => vb_other_manager_warning,
            p_spp_delete_warning                  => vb_spp_delete_warning,
            p_entries_changed_warning             => vc_entries_changed_warning,
            p_tax_district_changed_warning        => vb_tax_district_changed_warn
            );

        EXCEPTION
         WHEN OTHERS THEN
          gv_step  := lv_current_program_unit||' EEE : EXCEPTION gv_step :'||gv_step||chr(10)||SQLERRM;
          log_message(gv_step);
          --ROLLBACK; ARA MIGRATION
          --Suivant
        END;

      END IF;

    END LOOP; --fin loop date affectation


    --######################################################################################
    -- SITE A DESACTIVER
    --######################################################################################
    gv_step  := lv_current_program_unit||' 301 : Site a désactiver';log_message(gv_step);
    FOR l_site IN c_site_a_desactiver LOOP
      BEGIN

        --Désactivation du site fournisseur
        gv_step  := lv_current_program_unit||' 302 : Désactivation site fournisseur';log_message(gv_step);

        vn_api_version      := 1.0;
        vv_init_msg_list    :=FND_API.G_TRUE;
        vv_commit           := FND_API.G_FALSE;
        vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
        vv_return_status    := NULL;
        vn_msg_count        := NULL;
        vv_msg_data         := NULL;

        vr_vendor_site_rec.INACTIVE_DATE := l_site.effective_end_date;

        gv_step  := lv_current_program_unit||' 303 : Désactivation site fournisseur : Update_Vendor_Site - API';log_message(gv_step);
        ap_vendor_pub_pkg.Update_Vendor_Site (vn_api_version,
                                              vv_init_msg_list,
                                              vv_commit,
                                              vn_validation_level,
                                              vv_return_status,
                                              vn_msg_count,
                                              vv_msg_data,
                                              vr_vendor_site_rec,
                                              l_site.vendor_site_id,
                                              vv_calling_prog
                                             );

        IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
          --On continue
          gv_step  := lv_current_program_unit||' 304 : Modification site fournisseur : Update_Vendor_Site - API : Success';log_message(gv_step);
          NULL;
        ELSE
          vv_message := '';
          IF vn_msg_count > 0 THEN

            FOR v_index IN 1 .. vn_msg_count LOOP
              fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
              vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

            END LOOP;

          END IF;

          --Désactivation du site fournisseur impossible : message
          gv_step  := lv_current_program_unit||' 305 : Modification site fournisseur : Update_Vendor_Site - API : Error';log_message(gv_step);
          gv_step := 'Désactivation du site fournisseur impossible : '||vv_message;
          RAISE e_daily_error;

        END IF;

      EXCEPTION
       WHEN e_daily_error THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_DAILY_ERROR gv_step :'||gv_step;log_message(gv_step);
        --ROLLBACK; ARA MIGRATION
        --Suivant
       WHEN OTHERS THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION gv_step :'||gv_step||chr(10)||SQLERRM;
        log_message(gv_step);
        --ROLLBACK; ARA MIGRATION
        --Suivant
      END;

    END LOOP;

    --######################################################################################
    -- SITE A REACTIVER
    --######################################################################################
    gv_step  := lv_current_program_unit||' 401 : Site a réactiver';log_message(gv_step);
    FOR l_site IN c_site_a_reactiver LOOP
      BEGIN

        --Désactivation du site fournisseur
        gv_step  := lv_current_program_unit||' 402 : Réactivation site fournisseur';log_message(gv_step);

        vn_api_version      := 1.0;
        vv_init_msg_list    :=FND_API.G_TRUE;
        vv_commit           := FND_API.G_FALSE;
        vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
        vv_return_status    := NULL;
        vn_msg_count        := NULL;
        vv_msg_data         := NULL;

        vr_vendor_site_rec.INACTIVE_DATE := NULL;

        gv_step  := lv_current_program_unit||' 403 : Réactivation site fournisseur : Update_Vendor_Site - API ' || l_site.employee_number;log_message(gv_step);
        ap_vendor_pub_pkg.Update_Vendor_Site (vn_api_version,
                                              vv_init_msg_list,
                                              vv_commit,
                                              vn_validation_level,
                                              vv_return_status,
                                              vn_msg_count,
                                              vv_msg_data,
                                              vr_vendor_site_rec,
                                              l_site.vendor_site_id,
                                              vv_calling_prog
                                             );

        IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
          --On continue
          gv_step  := lv_current_program_unit||' 404 : Modification site fournisseur : Update_Vendor_Site - API : Success';log_message(gv_step);
          NULL;
        ELSE
          vv_message := '';
          IF vn_msg_count > 0 THEN

            FOR v_index IN 1 .. vn_msg_count LOOP
              fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
              vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);

            END LOOP;

          END IF;

          --Désactivation du site fournisseur impossible : message
          gv_step  := lv_current_program_unit||' 405 : Modification site fournisseur : Update_Vendor_Site - API : Error';log_message(gv_step);
          gv_step := 'Réactivation du site fournisseur impossible : '||vv_message;
          RAISE e_daily_error;

        END IF;

      EXCEPTION
       WHEN e_daily_error THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION E_DAILY_ERROR gv_step :'||gv_step;log_message(gv_step);
     --   ROLLBACK;
        --Suivant
       WHEN OTHERS THEN
        gv_step  := lv_current_program_unit||' EEE : EXCEPTION gv_step :'||gv_step||chr(10)||SQLERRM;
        log_message(gv_step);
      --  ROLLBACK;
        --SuivantRattachement du compte bancaire
      END;

    END LOOP;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    log_message(pv_errbuf,'Y');
    pn_retcode := 2;
  END daily_internal_updates;

  -----------------------------------------------------------------
  --  Nom           : AFFICHAGE_FICHIER_SORTIE
  --  Description   : procedure d'écriture dans le fichier de sortie
  --                  du traitement
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE affichage_fichier_sortie(pv_errbuf        OUT NOCOPY VARCHAR2,
                                     pn_retcode       OUT NOCOPY NUMBER) IS

   lv_current_program_unit  VARCHAR2(30) := 'affichage_fichier_sortie';

   CURSOR c_error IS
    SELECT *
    FROM XXEAI_HR_INT_ERRORS_ALL
    ORDER BY matricule,flag_error desc, table_name; --16/06/2015 JJA

   ln_creation PLS_INTEGER;
   ln_update   PLS_INTEGER;

   lv_buffer   VARCHAR2(500);

  BEGIN

    gv_step  := lv_current_program_unit||' 000 : DEBUT';
    log_message(gv_step);

    gv_step  := lv_current_program_unit||' 001 : INSERTION ENTETE';log_message(gv_step);
    dka_tools_pkg.put_out_header;

    gv_step  := lv_current_program_unit||' 002 : EMPLOYE CREE ET MAJ';log_message(gv_step);
    SELECT
     SUM(decode(INSERT_UPDATE_FLAG,'I',1,0)),
     SUM(decode(INSERT_UPDATE_FLAG,'U',1,0))
    INTO
     ln_creation,
     ln_update
    FROM
     XXEAI_HR_PEOPLE_INT HPI
    WHERE
      HPI.INTERFACE_STATUS = 'TRAITE';

    lv_buffer := dka_tools_pkg.get_message('DKA','DKA_IHREMP_REF_0000',
                                           'CREATION',nvl(ln_creation,0),
                                           'MAJ',     nvl(ln_update,0));
    out_message(lv_buffer||chr(10));

     gv_step  := lv_current_program_unit||' 002 : BANK RHAPSODY CREE ET MAJ';log_message(gv_step);

    --YWA EDB072
    SELECT nvl(SUM(1),0)
    INTO ln_update
    FROM XXEAI_HR_BANK_INT_ALL HBI
    WHERE NOT EXISTS
      (SELECT *
      FROM XXEAI_HR_PEOPLE_INT HPI
      WHERE HPI.EMPLOYEE_NUMBER=HBI.EMPLOYEE_NUMBER
      --AND source = gv_source_employe
      --AND HPI.INTERFACE_STATUS != 'ERROR'
      )
    AND HBI.INSERT_UPDATE_FLAG = 'U'
    AND HBI.INTERFACE_STATUS = 'TRAITE';


    lv_buffer :=  'Nombre de mise à jour des coordonnées bancaires issue de RHAPSODY : '||ln_update;
    out_message(lv_buffer||chr(10));

    gv_step  := lv_current_program_unit||' 003 : LISTE ERREUR';log_message(gv_step);
    lv_buffer := 'MATRICULE;TABLE_NAME;TABLE_ID;ERROR_MESSAGE;';
    out_message(lv_buffer);

    FOR l IN c_error LOOP
      lv_buffer := substr( l.MATRICULE||';'||
                           l.TABLE_NAME||';'||
                           l.TABLE_ID||';'||
                           l.ERROR_MESSAGE||';',1,500);
      out_message(lv_buffer);
    END LOOP;

    gv_step  := lv_current_program_unit||' 999 : FIN';
    log_message(gv_step);

  EXCEPTION
   WHEN OTHERS THEN
    gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
    log_message(gv_step,'Y');
    pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
    log_message(pv_errbuf,'Y');
    pn_retcode := 2;
  END affichage_fichier_sortie;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  -- Parametres
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_debug              Mode Debug (Oui / Non)
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_debug        IN         VARCHAR2) IS

    lv_current_program_unit  VARCHAR2(30) := 'main';

    --EXCEPTION
    e_init             EXCEPTION;
    e_purge            EXCEPTION;
    e_validate_data    EXCEPTION;
    e_insert           EXCEPTION;
    e_update           EXCEPTION;
    e_affichage_sortie EXCEPTION;

  BEGIN

    IF nvl(pv_debug,'#') = 'Y' then
      gv_debug := 'Y';
      --hr_utility.trace_on (null, 'ORACLE');
    END IF;

    ----------------------------------------------------------------
    --INITIALISATION DU TRAITEMENT
    ----------------------------------------------------------------
    log_message(cv_line,'Y');
    log_message('Initialisation','Y');
    log_message(cv_line,'Y');

    log_message('Debut : '||get_time,'Y');

    --procedure de initialisation
    init(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_init;
    END IF;

    log_message('Initialisation OK...');
    log_message('Fin   : '||get_time);

    ----------------------------------------------------------------
    --PURGE DES TABLES DE TRAVAIL XXEAI
    ----------------------------------------------------------------
    log_message(cv_line,'Y');
    log_message('Purge des tables de travail xxeai','Y');
    log_message(cv_line,'Y');

    log_message('Debut : '||get_time,'Y');

    --procedure de Purge des tables de travail xxeai
    purge_table_xxeai(pv_errbuf,
                      pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_purge;
    END IF;

    log_message('Purge des tables de travail xxeai OK...','Y');
    log_message('Fin   : '||get_time,'Y');

    ----------------------------------------------------------------
    --INSERTION EMPLOYEE
    ----------------------------------------------------------------
    log_message(cv_line,'Y');
    log_message('Insertion employe','Y');
    log_message(cv_line,'Y');


    log_message('Debut : '||get_time,'Y');

    --procedure de creation des employes
    creation_employe(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_insert;
    END IF;

    log_message('Insertion employe OK...','Y');
    log_message('Fin   : '||get_time,'Y');

    ----------------------------------------------------------------
    --MISE A JOUR EMPLOYEE
    ----------------------------------------------------------------
    log_message(cv_line,'Y');
    log_message('Mise a jour employe','Y');
    log_message(cv_line,'Y');


    log_message('Debut : '||get_time,'Y');

    --procedure de mise a jour employé
    maj_employe(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_update;
    END IF;

    log_message('Mise a jour employee OK...','Y');
    log_message('Fin   : '||get_time,'Y');

    /* ----------------------------------------------------------------
    --Mise a jour des coordonnées bancaires issue de RHAPSODY
    ----------------------------------------------------------------
    log_message(cv_line,'Y');
    log_message('Mise a jour des coordonnées bancaires','Y');
    log_message(cv_line,'Y');


    log_message('Debut : '||get_time,'Y');

    --
    maj_employe_only_bank(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_update;
    END IF;

    log_message('Mise a jour des coordonnées bancaires OK...','Y');
    log_message('Fin   : '||get_time,'Y');*/

    ----------------------------------------------------------------
    --MISE A JOUR QUOTIDIENNE
    ----------------------------------------------------------------
    log_message(cv_line,'Y');
    log_message('Mise a jour QUOTIDIENNE','Y');
    log_message(cv_line,'Y');


    log_message('Debut : '||get_time,'Y');

    --procedure de mise a jour quotidienne
    daily_internal_updates(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_update;
    END IF;

    log_message('Mise a jour quotidienne OK...','Y');
    log_message('Fin   : '||get_time,'Y');

    ----------------------------------------------------------------
    --AFFICHAGE DANS LE FICHIER DE SORTIE
    ----------------------------------------------------------------
    log_message(cv_line,'Y');
    log_message('Affichage dans le fichier de sortie','Y');
    log_message(cv_line,'Y');

    log_message('Debut : '||get_time);

    --procedure d'affichage dans le fichier de sortie
    affichage_fichier_sortie(pv_errbuf,pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_affichage_sortie;
    END IF;

    log_message('Affichage dans le fichier de sortie OK...','Y');
    log_message('Fin   : '||get_time,'Y');

  EXCEPTION
    WHEN e_init THEN
      gv_step  := lv_current_program_unit||' EE1 : ERREUR lors de :'||gv_step;
      log_message(gv_step,'Y');
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      log_message(pv_errbuf,'Y');
      pn_retcode := 2;
    WHEN e_insert THEN
      gv_step  := lv_current_program_unit||' EE4 : ERREUR lors de :'||gv_step;
      log_message(gv_step,'Y');
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      log_message(pv_errbuf,'Y');
      pn_retcode := 2;
    WHEN e_update THEN
      gv_step  := lv_current_program_unit||' EE5 : ERREUR lors de :'||gv_step;
      log_message(gv_step,'Y');
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      log_message(pv_errbuf,'Y');
      pn_retcode := 2;
    WHEN e_affichage_sortie THEN
      gv_step  := lv_current_program_unit||' EE7 : ERREUR lors de :'||gv_step;
      log_message(gv_step,'Y');
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      log_message(pv_errbuf,'Y');
      pn_retcode := 2;
    WHEN OTHERS THEN
      gv_step  := lv_current_program_unit||' EEE : ERREUR lors de :'||gv_step;
      log_message(gv_step,'Y');
      pv_errbuf  := 'Erreur procedure '|| cv_package_name ||'.' || lv_current_program_unit ||chr(10)||SQLERRM;
      log_message(pv_errbuf,'Y');
      pn_retcode := 2;
  END main;

END DKA_IHREMP_PKG;
