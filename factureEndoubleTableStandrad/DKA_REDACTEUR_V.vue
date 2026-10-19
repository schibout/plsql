CREATE OR REPLACE PACKAGE BODY DKA_SFND_DESACTIV_USERS_PKG
AS
--------------------------------------------------------------------------------
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFND_DESACTIV_USERS.pkb
-- DESCRIPTION       : DKA_SFND_DESACTIV_USERS_PKG package body
--
-- AUTEUR            : B COPIN, Q VANHOUTE
-- DATE DE CREATION  : 18/03/2009
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : À exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- ---------- --------- --------------------------------------------------------
-- 06/03/2013 BCOUDRIER INC000000375077 - Désactivation des utilisateurs inactif
--						lorsque le TP est ouvert et lorsque le TP est fermé.
-- 06/03/2013 BCOUDRIER DPE20130017 - Procédure get_employee_users: Désactivation 
--						des comptes des employés sortis.
-- 12/09/2018 OBE       Migration R12
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PROCEDURE main (pn_retcode           OUT NUMBER,
                                 pv_err_msg           OUT VARCHAR2,
                                 pn_nb_jours          IN NUMBER)
                                     
IS

pn_count_pusers  NUMBER;
pn_count_pusers_err  NUMBER;
pn_count_fusers  NUMBER;
pn_count_fusers_err  NUMBER;
pn_count_eusers  NUMBER;
pn_count_eusers_err  NUMBER;
pn_jours  NUMBER;

BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;
        
pn_jours := pn_nb_jours;        
        
IF pn_jours < 180 THEN
    pn_jours := 180; -- on force la valeur à 180 si le paramètre saisi en est inférieur
END IF;
DKA_tools_pkg.put_outdebug_message('SOX : RAPPORT DES UTILISATEURS DESACTIVES LE '|| sysdate);
DKA_tools_pkg.put_outdebug_message('Paramètre de durée d''inactivité : '||pn_jours || ' jours');
DKA_tools_pkg.put_outdebug_message('');

get_purchasing_users (pn_retcode, pv_err_msg, pn_count_pusers, pn_count_pusers_err, pn_jours);
get_financial_users (pn_retcode, pv_err_msg, pn_count_fusers, pn_count_fusers_err, pn_jours);
get_employee_users (pn_retcode, pv_err_msg, pn_count_eusers, pn_count_eusers_err);

DKA_tools_pkg.put_outdebug_message('');
DKA_tools_pkg.put_outdebug_message('Nombre d utilisateurs Achats désactivés : '||pn_count_pusers);
DKA_tools_pkg.put_outdebug_message('Nombre d utilisateurs Achats en erreur : '||pn_count_pusers_err);
DKA_tools_pkg.put_outdebug_message('Nombre d utilisateurs Finance désactivés : '||pn_count_fusers);
DKA_tools_pkg.put_outdebug_message('Nombre d utilisateurs Finance en erreur : '||pn_count_fusers_err);
DKA_tools_pkg.put_outdebug_message('Nombre d utilisateurs désactivés pour les comptes des employés sortis : ' || pn_count_eusers);
DKA_tools_pkg.put_outdebug_message('Nombre d utilisateurs en erreur pour les comptes des employés sortis : ' || pn_count_eusers_err);
commit;
END main
;


PROCEDURE get_purchasing_users (pn_retcode                     OUT  NUMBER,
                                                                pv_err_msg                     OUT  VARCHAR2,
                                                                pn_count_pusers           OUT  NUMBER,
                                                                pn_count_pusers_err     OUT  NUMBER,
                                                                pn_nb_jours                  IN  NUMBER)

IS

CURSOR cur_line IS

SELECT  distinct fu.user_id, fu.user_name, pap.full_name, pap.attribute2 --, pap.attribute3, pap.attribute1 -- OBE R12
,fu.last_logon_date, paa.ass_attribute5, haou.name
FROM fnd_user fu, ak_web_user_sec_attr_values awu1, fnd_user_resp_groups fur, per_all_people_f pap, per_all_assignments_f paa, hr_all_organization_units haou
WHERE fu.user_id = awu1.web_user_id
AND fur.user_id (+) = fu.user_id
AND pap.person_id = fu.employee_id
AND pap.person_type_id = 6
AND not exists (SELECT 1
                           FROM ak_web_user_sec_attr_values awu2
                           WHERE awu2.attribute_code = 'DKA_TYPE_PROFIL' 
                           AND awu2.varchar2_value = 'SYS' 
                           AND awu2.web_user_id = fu.user_id) -- exclusion des profils de type SYS
AND fu.start_date <= sysdate - pn_nb_jours  -- exclusion des profils récemment créés
--AND fu.end_date is null -- exclusion des profils déjà désactivés
-- INC000000375077 - Insertion d'un contrôle sur la fermeture du TP.
AND (trunc(fu.end_date) = to_date('01/01/2003', 'DD/MM/YYYY') 
	OR  fu.end_date IS NULL)
AND (fu.last_logon_date <= sysdate - pn_nb_jours
          OR fu.last_logon_date is null) -- sélection des profils non connectés depuis pn_nb_jours ou jamais connectés
AND  fur.responsibility_application_id IN ( 178, 201) -- sélection des profils ayant au moins une responsabilité PO ou SSP
--< OBE R12
--AND trunc(sysdate) between trunc(pap.effective_start_date) and trunc(pap.effective_end_date)
and trunc(pap.effective_start_date) = (select max(trunc(a.effective_start_date)) from per_all_people_f a where a.person_id = pap.person_id and a.person_type_id = 6)
AND  pap.person_id = paa.person_id
--AND trunc(sysdate) between trunc(paa.effective_start_date) and trunc(paa.effective_end_date)
and trunc(paa.effective_start_date) = (select max(trunc(b.effective_start_date)) from per_all_assignments_f b where b.person_id = paa.person_id)
AND haou.organization_id = paa.organization_id
--> OBE R12
order by fu.user_name
;

rec_line     cur_line%ROWTYPE;


BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;
         pn_count_pusers:=0;
          pn_count_pusers_err:=0;



DKA_tools_pkg.put_outdebug_message('Liste des utilisateurs Achats désactivés :');
DKA_tools_pkg.put_outdebug_message('');
DKA_tools_pkg.put_outdebug_message(rpad ('Matricule',16,' ')||' - '||rpad('Nom, Prénom', 50, ' ')||' - '||rpad('Région', 10, ' ')||' - '||rpad('Centre', 10, ' ')||' - '||rpad('Tâche',12,' ')||' - '||rpad('Dernière connexion',20,' '));
        
OPEN cur_line;       
LOOP
               
    FETCH cur_line INTO rec_line;
    EXIT WHEN cur_line%NOTFOUND;

         BEGIN
                    update fnd_user
                    set end_date = sysdate, last_update_date = sysdate
                    where user_id = rec_line.user_id;
                    pn_count_pusers := pn_count_pusers +1;
                   
                   DKA_tools_pkg.put_outdebug_message(rpad(rec_line.user_name,16,' ')||' - '||rpad(rec_line.full_name, 50, ' ')||' - '||rpad(rec_line.attribute2, 10, ' ')||' - '||rpad(rec_line.name,10,' ')||' - '||rpad(rec_line.ass_attribute5, 12, ' ')||' - '||rpad(rec_line.last_logon_date,20,' '));
                   
                   EXCEPTION
                   when others then
                   pn_count_pusers_err:= pn_count_pusers_err +1;
                   pn_retcode:= 2;
                   pv_err_msg:= sqlerrm;
         END;

END LOOP;
CLOSE cur_line;

END get_purchasing_users
;


PROCEDURE get_financial_users (pn_retcode           OUT NUMBER,
                                                            pv_err_msg            OUT VARCHAR2,
                                                            pn_count_fusers OUT NUMBER,
                                                            pn_count_fusers_err OUT NUMBER,
                                                            pn_nb_jours IN NUMBER)

IS

CURSOR cur_line IS

SELECT distinct fu.user_id, fu.user_name, pap.full_name, pap.attribute2--, pap.attribute3, pap.attribute1
, fu.last_logon_date, paa.ass_attribute5, haou.name
FROM fnd_user fu, ak_web_user_sec_attr_values awu1, fnd_user_resp_groups fur, per_all_people_f pap, per_all_assignments_f paa, hr_all_organization_units haou
WHERE fu.user_id = awu1.web_user_id
AND fur.user_id (+) = fu.user_id
AND pap.person_id = fu.employee_id
AND pap.person_type_id = 6
AND not exists (SELECT 1
                           FROM ak_web_user_sec_attr_values awu2
                           WHERE awu2.attribute_code = 'DKA_TYPE_PROFIL' 
                           AND awu2.varchar2_value = 'SYS' 
                           AND awu2.web_user_id = fu.user_id) -- exclusion des profils de type SYS
AND fu.start_date <= sysdate - pn_nb_jours -- exclusion des profils récemment créés
--AND fu.end_date is null -- exclusion des profils déjà désactivés
-- INC000000375077 - Insertion d'un contrôle sur la fermeture du TP.
AND (trunc(fu.end_date) = to_date('01/01/2003', 'DD/MM/YYYY') 
	OR  fu.end_date IS NULL)
AND (fu.last_logon_date <= sysdate - pn_nb_jours
           OR fu.last_logon_date is null)  -- sélection des profils non connectés depuis pn_nb_jours ou jamais connectés
AND  not exists (SELECT 1
                            FROM fnd_user_resp_groups fur2
                            WHERE fur2.user_id = fu.user_id
                            AND fur2.responsibility_application_id  IN ( 178, 201)) -- sélection des profils n'ayant pas de responsabilité PO ou SSP
--< OBE R12
--AND trunc(sysdate) between trunc(pap.effective_start_date) and trunc(pap.effective_end_date)
and trunc(pap.effective_start_date) = (select max(trunc(a.effective_start_date)) from per_all_people_f a where a.person_id = pap.person_id and a.person_type_id = 6)
AND  pap.person_id = paa.person_id
--AND trunc(sysdate) between trunc(paa.effective_start_date) and trunc(paa.effective_end_date)
and trunc(paa.effective_start_date) = (select max(trunc(b.effective_start_date)) from per_all_assignments_f b where b.person_id = paa.person_id)
AND haou.organization_id = paa.organization_id
--> OBE R12							
order by fu.user_name
; 

rec_line     cur_line%ROWTYPE;

BEGIN
        pn_retcode := 0;
        pv_err_msg := NULL;
        pn_count_fusers:=0;
        pn_count_fusers_err:=0;

DKA_tools_pkg.put_outdebug_message('');
DKA_tools_pkg.put_outdebug_message('Liste des utilisateurs Finance désactivés :');
DKA_tools_pkg.put_outdebug_message('');
DKA_tools_pkg.put_outdebug_message(rpad ('Matricule',16,' ')||' - '||rpad('Nom, Prénom', 50, ' ')||' - '||rpad('Région', 10, ' ')||' - '||rpad('Centre', 10, ' ')||' - '||rpad('Tâche',12,' ')||' - '||rpad('Dernière connexion',20,' '));
        
OPEN cur_line;       
LOOP
               
    FETCH cur_line INTO rec_line;
    EXIT WHEN cur_line%NOTFOUND;

         BEGIN
                    update fnd_user
                    set end_date = sysdate, last_update_date = sysdate
                    where user_id = rec_line.user_id;
                    pn_count_fusers := pn_count_fusers +1;
                   
                   DKA_tools_pkg.put_outdebug_message(rpad(rec_line.user_name,16,' ')||' - '||rpad(rec_line.full_name, 50, ' ')||' - '||rpad(rec_line.attribute2, 10, ' ')||' - '||rpad(rec_line.name,10,' ')||' - '||rpad(rec_line.ass_attribute5, 12, ' ')||' - '||rpad(rec_line.last_logon_date,20,' '));
                   
                   EXCEPTION
                   when others then
                   pn_count_fusers_err := pn_count_fusers_err +1;
                   pn_retcode:= 2;
                   pv_err_msg:= sqlerrm;
         END;

END LOOP;
CLOSE cur_line;

END get_financial_users
;

PROCEDURE get_employee_users(pn_retcode          OUT NUMBER,
                             pv_err_msg          OUT VARCHAR2,
                             pn_count_eusers     OUT NUMBER,
                             pn_count_eusers_err OUT NUMBER)

 IS

  CURSOR cur_line IS
  
    SELECT distinct fu.user_id,
                    fu.user_name,
                    pap.full_name,
                    pap.attribute2,
                    --pap.attribute3,
                    --pap.attribute1,
					paa.ass_attribute5, 
					haou.name,
                    fu.last_logon_date
      FROM fnd_user                    fu,
           ak_web_user_sec_attr_values awu1,
           per_people_v7	           pap,
		   per_all_assignments_f paa, 
		   hr_all_organization_units haou
     WHERE fu.user_id = awu1.web_user_id
       AND pap.person_id = fu.employee_id
       AND pap.d_termination_date < SYSDATE -- date de fin d'emploi < date de lancement du traitement
       --AND pap.person_type_id = 6 -- employé de type Dalkia
       AND not exists
     (SELECT 1
              FROM ak_web_user_sec_attr_values awu2
             WHERE awu2.attribute_code = 'DKA_TYPE_PROFIL'
               AND awu2.varchar2_value = 'SYS'
               AND awu2.web_user_id = fu.user_id) -- exclusion des profils de type SYS
       --< OBE R12
       AND  pap.person_id = paa.person_id
       --AND trunc(sysdate) between trunc(paa.effective_start_date) and trunc(paa.effective_end_date)
	   and trunc(paa.effective_start_date) = (select max(trunc(b.effective_start_date)) from per_all_assignments_f b where b.person_id = paa.person_id)
       AND haou.organization_id = paa.organization_id
       --> OBE R12					   
       -- Insertion d'un contrôle sur la fermeture du TP.
       AND (trunc(fu.end_date) = to_date('01/01/2003', 'DD/MM/YYYY')
	   OR  fu.end_date IS NULL)
	   
	   ;

  rec_line cur_line%ROWTYPE;

BEGIN
  pn_retcode          := 0;
  pv_err_msg          := NULL;
  pn_count_eusers     := 0;
  pn_count_eusers_err := 0;

  DKA_tools_pkg.put_outdebug_message('');
  DKA_tools_pkg.put_outdebug_message('Liste des utilisateurs désactivés dont l''employé a une date de fin d''emploi :');
  DKA_tools_pkg.put_outdebug_message('');
  DKA_tools_pkg.put_outdebug_message(rpad('Matricule', 16, ' ') || ' - ' ||
                                     rpad('Nom, Prénom', 50, ' ') || ' - ' ||
                                     rpad('Région', 10, ' ') || ' - ' ||
                                     rpad('Centre', 10, ' ') || ' - ' ||
                                     rpad('Tâche', 12, ' ') ||
                                     ' - ' ||
                                     rpad('Dernière connexion', 20, ' '));

  OPEN cur_line;
  LOOP
  
    FETCH cur_line
      INTO rec_line;
    EXIT WHEN cur_line%NOTFOUND;
  
    BEGIN
      update fnd_user
         set end_date = sysdate, last_update_date = sysdate
       where user_id = rec_line.user_id;
    
      pn_count_eusers := pn_count_eusers + 1;
    
      DKA_tools_pkg.put_outdebug_message(rpad(rec_line.user_name, 16, ' ') ||
                                         ' - ' ||
                                         rpad(rec_line.full_name, 50, ' ') ||
                                         ' - ' ||
                                         rpad(rec_line.attribute2, 10, ' ') ||
                                         ' - ' ||
                                         rpad(rec_line.name, 10, ' ') ||
                                         ' - ' ||
                                         rpad(rec_line.ass_attribute5, 12, ' ') ||
                                         ' - ' || rpad(rec_line.last_logon_date,
                                                       20,
                                                       ' '));
    
    EXCEPTION
      when others then
        pn_count_eusers_err := pn_count_eusers_err + 1;
        pn_retcode          := 2;
        pv_err_msg          := sqlerrm;
    END;
  
  END LOOP;
  CLOSE cur_line;

END get_employee_users;

END DKA_SFND_DESACTIV_USERS_PKG;
/

SHOW ERROR

EXIT
