SELECT fu.user_name , resp.responsibility_name,
          'exec fnd_global.apps_initialize('
       || fu.user_id
       || ', '
       || resp.responsibility_id
       || ', '
       || furg.responsibility_application_id
       || ', '
       || furg.security_group_id
       || ');'
          text_apps_initialize,
       'exec mo_global.init(' || '''' || fa.application_short_name || ''');'
          mo_global_init
  FROM apps.fnd_user_resp_groups furg,
       fnd_application fa,
       apps.fnd_user fu,
       apps.fnd_responsibility_vl resp
 WHERE     furg.user_id = fu.user_id
       AND furg.responsibility_id = resp.responsibility_id
       AND fa.application_id = furg.responsibility_application_id       
       --AND resp.responsibility_key  like '%HR%'
       AND fu.user_name = 'DKAEXPLOIT'
       and  resp.responsibility_name like 'TOUT%'

select * from fnd_responsibility_vl

exec fnd_global.apps_initialize(1323, 50937, 222, 0);