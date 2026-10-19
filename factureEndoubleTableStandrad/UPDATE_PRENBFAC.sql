		---------------------------------------------------------------------------------------------
		--
		--
		-- DESCRIPTION       : Script de création de l'attribut de Sécurité DKA_TYPE_PROFIL et
		--                      attribution aux utilisateurs système
		--- AUTEUR           : Benoit COPIN (Capgemini)
		--- DATE DE CREATION : 05/03/2009
		--- DOC. ASSOCIEE    :
		---
		----------------------------------------------------------------------------------------------
		--- NOM DU PROGRAMME :
		--- PARAMETRES       :
		---
		--- HISTORIQUE DES MODIFICATIONS
		--- Date       Qui Description
		--- ---------- --- -------------------------------------------------------------------------

SET SERVEROUTPUT ON
declare
  v_application_id fnd_application_vl.application_id%type;

  v_compteur NUMBER := 0;
  v_exists   NUMBER := 0;
  vv_mesg    VARCHAR2(240);

  v_user_name    fnd_user.user_name%TYPE;
  v_user_id      fnd_user.user_id%TYPE;
  v_language     fnd_request_sets_TL.Language%TYPE;
  v_nls_language fnd_languages.nls_language%TYPE;
  v_msg_error    VARCHAR2(250);
  e_error_fatal EXCEPTION;
  v_rowid                     ROWID;
  v_attribute_code            ak_attributes.attribute_code%type;
  v_nb_attributesCrees        number := 0;
  v_nb_attributesModifies     number := 0;
  v_nb_attributesUserCrees    number := 0;
  v_nb_attributesUserModifies number := 0;
begin
  DBMS_OUTPUT.ENABLE(200000);

  v_attribute_code := 'DKA_TYPE_PROFIL';
  /********** variable à paramétrer : ***************/
  v_user_name := 'INITIAL SETUP'; -- utilisateur qui fait les modifications en base
  v_language  := 'F'; -- langue d'insertion des données traduites
  /**************************************************/

  /********* Traitement des paramètres et positionnement de l'environement *********/
  -- recuperation du user_id
  BEGIN
    SELECT user_id
      INTO v_user_id
      FROM fnd_user
     WHERE user_name = v_user_name;
  EXCEPTION
    when others then
      v_msg_error := 'Impossible de retrouver l''utilisateur : ' ||
                     v_user_name;
      RAISE e_error_fatal;
  END;
  -- recuperation et positionnement de la langue
  BEGIN
    SELECT l.nls_language
      INTO v_nls_language
      FROM fnd_languages l
     WHERE l.language_code = v_language;
    execute immediate ('alter session set nls_language = ''' ||
                      v_nls_language || '''');
  EXCEPTION
    when others then
      v_msg_error := 'Impossible de retrouver la langue :' || v_language;
      RAISE e_error_fatal;
  END;
  /*********************************************************************************/

  -- recuperation de l'applicationID
  BEGIN
    select application_id
      into v_application_id
      from fnd_application_vl
     where application_short_name = 'DKA';
    EXCEPTION when others then 
    v_msg_error := 'Impossible de retrouver l''application DKA ';
    RAISE e_error_fatal;
  END;
  /*********************************************************************************/
  
  -- generation de l'attribut de securite DKA_TYPE_PROFIL
  begin
    select 1
      into v_exists
      from ak_attributes avl
     where avl.ATTRIBUTE_CODE = 'DKA_TYPE_PROFIL' and
          attribute_application_id = v_application_id;
    ak_attributes_pkg.update_row(x_attribute_application_id  => v_application_id,
                                 x_attribute_code            => v_attribute_code,
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
                                 x_name                      => v_attribute_code,
                                 x_attribute_label_long      => null,
                                 x_attribute_label_short     => null,
                                 x_description               => null,
                                 x_last_update_date          => sysdate,
                                 x_last_updated_by           => v_user_id,
                                 x_last_update_login         => fnd_global.login_id);
    v_nb_attributesModifies := 1;
  EXCEPTION
    when no_data_found then
      -- Call the procedure
      ak_attributes_pkg.insert_row(x_rowid                     => v_rowid,
                                   x_attribute_application_id  => v_application_id,
                                   x_attribute_code            => v_attribute_code,
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
                                   x_name                      => v_attribute_code,
                                   x_attribute_label_long      => null,
                                   x_attribute_label_short     => null,
                                   x_description               => null,
                                   x_creation_date             => sysdate,
                                   x_created_by                => v_user_id,
                                   x_last_update_date          => sysdate,
                                   x_last_updated_by           => v_user_id,
                                   x_last_update_login         => fnd_global.login_id);
      v_nb_attributesCrees := 1;
    when others then
      RAISE e_error_fatal;
  end;
  
  FOR employee IN ( select fu.user_id from fnd_user fu
where fu.user_name in ('ANONYMOUS', 
'ASGADM', 
'ASGUEST', 
'AUTOINSTALL', 
'FEEDER SYSTEM', 
'GUEST', 
'IBEGUEST', 
'IBE_ADMIN', 
'IBE_GUEST', 
'INITIAL SETUP', 
'IRC_EMP_GUEST', 
'IRC_EXT_GUEST', 
'MOBILEADM', 
'OP_CUST_CARE_ADMIN', 
'WIZARD',
'EXPLOITATION',
'EXPLOITATION VT',
'EXPLOITATION VP',
'SYSADMIN',
'VANTAGE',
'ORACLE12.0.0',
'ORACLE12.1.0',
'ORACLE12.2.0',
'ORACLE12.3.0',
'ORACLE12.4.0',
'ORACLE12.5.0',
'ORACLE12.6.0',
'ORACLE12.7.0',
'ORACLE12.8.0',
'ORACLE12.9.0',
'DATALOAD_PLAY',
'DATALOAD_PRO_PLAY_ADR',
'DATALOAD_PRO_PLAY_DID',
'DATALOAD_PRO_PLAY_LKI',
'DATALOAD_PRO_REC_DID',
'DATALOAD_PRO_REC_LKI',
'DATALOAD_REC',
'EAI',
'DKAEXPLOIT')
  
  ) LOOP
  begin
      select 1
        into v_exists
        from ak_web_user_sec_attr_values
       where WEB_USER_ID = employee.user_id and
             ATTRIBUTE_APPLICATION_ID = v_application_id and
             ATTRIBUTE_CODE = v_attribute_code;
      update ak_web_user_sec_attr_values
         set VARCHAR2_VALUE = 'SYS',
             DATE_VALUE     = null,
              NUMBER_VALUE = null,
                             LAST_UPDATED_BY = v_user_id,
                              LAST_UPDATE_DATE = sysdate,
                              LAST_UPDATE_LOGIN = fnd_global.login_id
       where WEB_USER_ID = employee.user_id and
             ATTRIBUTE_CODE = v_attribute_code and
             ATTRIBUTE_APPLICATION_ID = v_application_id;
      v_nb_attributesUserModifies := v_nb_attributesUserModifies + 1;
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
           v_attribute_code,
           v_application_id,
           'SYS',
           null,
           null,
           v_user_id,
           sysdate,
           v_user_id,
           sysdate,
           fnd_global.login_id);
        v_nb_attributesUserCrees := v_nb_attributesUserCrees + 1;
    END;
  END LOOP;
  
  commit;
  dbms_output.put_line(' Nb d''attributs crees : ' || v_nb_attributesCrees);
  dbms_output.put_line(' Nb d''attributs modifies : ' ||
                       v_nb_attributesModifies);
  dbms_output.put_line(' Nb d''attributs utilisateurs modifiés : ' || v_nb_attributesUserModifies); 
  dbms_output.put_line(' Nb d''attributs utilisateurs créés : ' || v_nb_attributesUserCrees);                     
  
EXCEPTION
WHEN e_error_fatal then 
   dbms_output.put_line('Erreur survenue : ' ||' '||sqlcode||' '|| sqlerrm||' '||v_msg_error);
   RAISE;
END;
/

exit;
