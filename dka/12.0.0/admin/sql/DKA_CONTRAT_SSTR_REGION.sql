----------------------------------------------------------------------------------------------      
-- $Id$                                                                                            
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_CONTRAT_SSTR_REGION.sql                                                            
-- DESCRIPTION      : Script de création de l'attribut de Sécurité DKA_CONTRAT_SSTR_REGION et 
--                        affectation des regions aux chefs de secteurs et/ou des Responsables Achats Etablissements 
-- AUTEUR           : V. KNAB                                                              
-- DATE DE CREATION : 02/12/2007                                                                       
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS                                      
--                                                       
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
-- 15-FEV-18  RBE artf2376255 : SPE119 - Correction de la sélection Employés
--------------------------------------------------------------------------------------------        
set serveroutput on size 1000000
declare
  vn_application_id fnd_application_vl.application_id%type;

  vn_compteur NUMBER := 0;
  vn_exists   NUMBER := 0;
  vv_mesg    VARCHAR2(240);

  vv_user_name    fnd_user.user_name%TYPE;
  vn_user_id      fnd_user.user_id%TYPE;
  vv_language     fnd_request_sets_TL.Language%TYPE;
  vv_nls_language fnd_languages.nls_language%TYPE;
  vv_msg_error    VARCHAR2(250);
  e_error_fatal EXCEPTION;
  v_rowid                     ROWID;
  vv_attribute_code            ak_attributes.attribute_code%type;
  vn_nb_attributesCrees        number := 0;
  vn_nb_attributesModifies     number := 0;
  vn_nb_attributesUserCrees    number := 0;
  vn_nb_attributesUserModifies number := 0;
begin
  DBMS_OUTPUT.ENABLE(200000);

  vv_attribute_code := 'DKA_CONTRAT_SSTR_REGION';
  /********** variable à paramétrer : ***************/
  vv_user_name := 'INITIAL SETUP'; -- utilisateur qui fait les modifications en base
  vv_language  := 'F'; -- langue d'insertion des données traduites
  /**************************************************/

  /********* Traitement des paramètres et positionnement de l'environement *********/
  -- recuperation du user_id
  BEGIN
    SELECT user_id
      INTO vn_user_id
      FROM fnd_user
     WHERE user_name = vv_user_name;
  EXCEPTION
    when others then
      vv_msg_error := 'Impossible de retrouver l''utilisateur : ' ||
                     vv_user_name;
      RAISE e_error_fatal;
  END;
  -- recuperation et positionnement de la langue
  BEGIN
    SELECT l.nls_language
      INTO vv_nls_language
      FROM fnd_languages l
     WHERE l.language_code = vv_language;
    execute immediate ('alter session set nls_language = ''' ||
                      vv_nls_language || '''');
  EXCEPTION
    when others then
      vv_msg_error := 'Impossible de retrouver la langue :' || vv_language;
      RAISE e_error_fatal;
  END;
  /*********************************************************************************/

  -- recuperation de l'applicationID
  BEGIN
    select application_id
      into vn_application_id
      from fnd_application_vl
     where application_short_name = 'ICX';
    EXCEPTION when others then 
    vv_msg_error := 'Impossible de retrouver l''application ICX ';
    RAISE e_error_fatal;
  END;
  /*********************************************************************************/
  
  -- generation de l'attribut de securite DKA_CONTRAT_SSTR_REGION
  begin
    select 1
      into vn_exists
      from ak_attributes avl
     where avl.ATTRIBUTE_CODE =  vv_attribute_code  and
          attribute_application_id = vn_application_id;
    ak_attributes_pkg.update_row(x_attribute_application_id  => vn_application_id,
                                 x_attribute_code            => vv_attribute_code,
                                 x_attribute_label_length    => 25,
                                 x_attribute_value_length    => 20,
                                 x_bold                      => 'N',
                                 x_italic                    => 'N',
                                 x_upper_case_flag           => 'N',
                                 x_vertical_alignment        => 'TOP',
                                 x_horizontal_alignment      => 'LEFT',
                                 x_default_value_varchar2    => NULL,
                                 x_default_value_number      => NULL,
                                 x_default_value_date        => NULL,
                                 x_lov_region_code           => NULL,
                                 x_lov_region_application_id => NULL,
                                 x_data_type                 => 'VARCHAR2',
                                 x_display_height            => NULL,
                                 x_item_style                => 'TEXT',
                                 x_css_class_name            => NULL,
                                 x_css_label_class_name      => NULL,
                                 x_precision                 => NULL,
                                 x_expansion                 => NULL,
                                 x_als_max_length            => NULL,
                                 x_poplist_viewobject        => NULL,
                                 x_poplist_display_attribute => NULL,
                                 x_poplist_value_attribute   => NULL,
                                 x_attribute_category        => NULL,
                                 x_attribute1                => null,
                                 x_attribute2                => null,
                                 x_attribute3                => null,
                                 x_attribute4                => null,
                                 x_attribute5                => null,
                                 x_attribute6                => null,
                                 x_attribute7                => null,
                                 x_attribute8                => null,
                                 x_attribute9                => null,
                                 x_attribute10               => null,
                                 x_attribute11               => null,
                                 x_attribute12               => null,
                                 x_attribute13               => null,
                                 x_attribute14               => null,
                                 x_attribute15               => null,
                                 x_name                      => vv_attribute_code,
                                 x_attribute_label_long      => null,
                                 x_attribute_label_short     => null,
                                 x_description               => 'REGIONS DES CONTRATS RECURRENTS VISIBLES',
                                 x_last_update_date          => sysdate,
                                 x_last_updated_by           => vn_user_id,
                                 x_last_update_login         => fnd_global.login_id);
    vn_nb_attributesModifies := 1;
  EXCEPTION
    when no_data_found then
      -- Call the procedure
      ak_attributes_pkg.insert_row(x_rowid                     => v_rowid,
                                   x_attribute_application_id  => vn_application_id,
                                   x_attribute_code            => vv_attribute_code,
                                   x_attribute_label_length    => 25,
                                   x_attribute_value_length    => 20,
                                   x_bold                      => 'N',
                                   x_italic                    => 'N',
                                   x_upper_case_flag           => 'N',
                                   x_vertical_alignment        => 'TOP',
                                   x_horizontal_alignment      => 'LEFT',
                                   x_default_value_varchar2    => NULL,
                                   x_default_value_number      => NULL,
                                   x_default_value_date        => NULL,
                                   x_lov_region_code           => NULL,
                                   x_lov_region_application_id => NULL,
                                   x_data_type                 => 'VARCHAR2',
                                   x_display_height            => NULL,
                                   x_item_style                => 'TEXT',
                                   x_css_class_name            => NULL,
                                   x_css_label_class_name      => NULL,
                                   x_precision                 => NULL,
                                   x_expansion                 => NULL,
                                   x_als_max_length            => NULL,
                                   x_poplist_viewobject        => NULL,
                                   x_poplist_display_attribute => NULL,
                                   x_poplist_value_attribute   => NULL,
                                   x_attribute_category        => NULL,
                                   x_attribute1                => null,
                                   x_attribute2                => null,
                                   x_attribute3                => null,
                                   x_attribute4                => null,
                                   x_attribute5                => null,
                                   x_attribute6                => null,
                                   x_attribute7                => null,
                                   x_attribute8                => null,
                                   x_attribute9                => null,
                                   x_attribute10               => null,
                                   x_attribute11               => null,
                                   x_attribute12               => null,
                                   x_attribute13               => null,
                                   x_attribute14               => null,
                                   x_attribute15               => null,
                                   x_name                      => vv_attribute_code,
                                   x_attribute_label_long      => null,
                                   x_attribute_label_short     => null,
                                   x_description               => 'REGIONS DES CONTRATS RECURRENTS VISIBLES',
                                   x_creation_date             => sysdate,
                                   x_created_by                => vn_user_id,
                                   x_last_update_date          => sysdate,
                                   x_last_updated_by           => vn_user_id,
                                   x_last_update_login         => fnd_global.login_id);
      vn_nb_attributesCrees := 1;
    when others then
      RAISE e_error_fatal;
  end;

  -- boucle sur les employés pour leur affecter leur appartennance à DKA_SECTEUR_RECEPTION
  FOR employee IN (
      SELECT  fu.user_id ,ppf.person_id, ppf.employee_number,
             ppf.last_name, ppf.first_name, ppf.full_name, ppf.attribute2
      FROM fnd_user fu, per_people_v7 ppf, per_assignments_f pav, --RBE artf2376255
           per_jobs pj
      WHERE ppf.person_id = pav.person_id
        AND pav.job_id = pj.job_id
        AND ppf.current_employee_FLAG = 'Y'
        AND sysdate between pav.effective_start_date and pav.effective_end_date 
        AND SUBSTR(pj.name, INSTR(pj.name, '.') + 1) IN
                                          ('CEX', 'RHA')     
        and   ppf.person_id = fu.employee_id                                     
       and ppf.attribute2 is not null
   ) LOOP
    begin
      select 1
        into vn_exists
        from ak_web_user_sec_attr_values
       where WEB_USER_ID = employee.user_id and
             ATTRIBUTE_APPLICATION_ID = vn_application_id and
             ATTRIBUTE_CODE = vv_attribute_code;
      update ak_web_user_sec_attr_values
         set VARCHAR2_VALUE = employee.attribute2,
             DATE_VALUE     = null,
              NUMBER_VALUE = null,
                             LAST_UPDATED_BY = vn_user_id,
                              LAST_UPDATE_DATE = sysdate,
                              LAST_UPDATE_LOGIN = fnd_global.login_id
       where WEB_USER_ID = employee.user_id and
             ATTRIBUTE_CODE = vv_attribute_code and
             ATTRIBUTE_APPLICATION_ID = vn_application_id;
      vn_nb_attributesUserModifies := vn_nb_attributesUserModifies + 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        insert into ak_web_user_sec_attr_values
          (WEB_USER_ID,
           ATTRIBUTE_CODE,
           ATTRIBUTE_APPLICATION_ID,
           VARCHAR2_VALUE,
           DATE_VALUE,
           NUMBER_VALUE,
           CREATED_BY,
           CREATION_DATE,
           LAST_UPDATED_BY,
           LAST_UPDATE_DATE,
           LAST_UPDATE_LOGIN)
        values
          (employee.user_id,
           vv_attribute_code,
           vn_application_id,
           employee.attribute2,
           null,
           null,
           vn_user_id,
           sysdate,
           vn_user_id,
           sysdate,
           fnd_global.login_id);
        vn_nb_attributesUserCrees := vn_nb_attributesUserCrees + 1;
    END;
  END LOOP;
  commit;
  dbms_output.put_line(' Nb d''attributs crees : ' || vn_nb_attributesCrees);
  dbms_output.put_line(' Nb d''attributs modifies : ' ||
                       vn_nb_attributesModifies);
  dbms_output.put_line(' Nb d''attributs User crees : ' ||
                       vn_nb_attributesUserCrees);
  dbms_output.put_line(' Nb d''attributs User modifies : ' ||
                       vn_nb_attributesUserModifies);
EXCEPTION
WHEN e_error_fatal then 
   dbms_output.put_line('Erreur survenue : ' ||' '||sqlcode||' '|| sqlerrm||' '||vv_msg_error);
   RAISE;
END;   
/ 

EXIT;
