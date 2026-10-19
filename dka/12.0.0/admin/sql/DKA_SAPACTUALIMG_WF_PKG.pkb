
CREATE OR REPLACE PACKAGE BODY DKA_SAPACTUALIMG_WF_PKG
AS     

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI
-- PROJET            : DALKIA/VEOLIA Oracle Applications
-- NOM               : DKA_sapactualimg_wf_pkg.pkb
-- DESCRIPTION       : DKA_sapactualimg_wf_pkg package body :
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description 
--- ---------- --- ---------------------------------------------------------------------------
--- 2016/07/05 JJA Portage Helios R12
----------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- CONSTANTES ET VARIABLES PRIVEES
  ----------------------------------------------------------------------------
  cb_debug constant boolean := FALSE;
  gn_nbre_jour   NUMBER;     


  ----------------------------------------------------------------------------
  --  Nom           : LOG_MSG
  --  Description   : procedure de log des messages
  --
  --  PARAMETRES :
  --   pv_message      texte a imprimer dans le log
  --
  ----------------------------------------------------------------------------
  PROCEDURE log_msg(pv_message in varchar2) IS
    vv_message VARCHAR2(1000);
  BEGIN
  
    vv_message := SUBSTR(pv_message, 1, 1000);
  
    IF (vv_message IS NULL) THEN
      vv_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
    END IF;
  
    IF not cb_debug THEN
      fnd_file.put_line(fnd_file.LOG, vv_message);
    ELSE
      dbms_output.put_line('LOG : ' || substr(vv_message, 1, 253));
    END IF;
  
  END log_msg;
 
  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : authorize
  --  Description   : Procedure donnant l'autorisation d'accA?s au lob
  --                           
  --  PARAMETRES    :
  --    vn_file_id      number
  --    vn_acces_id      number
  -------------------------------------------------------------------------------------------------------------------

  PROCEDURE authorize(vn_file_id number, vn_acces_id number)
  IS
  BEGIN
  
      DELETE FROM fnd_lob_access 
      WHERE     access_id =   vn_acces_id;
      
      INSERT INTO fnd_lob_access
           (access_id
          , file_id
          , timestamp)
      VALUES (vn_acces_id
          , vn_file_id
          , sysdate+gn_nbre_jour);
            
  EXCEPTION
  WHEN OTHERS THEN
      fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
      fnd_message.set_token('ROUTINE', 'DKA_SAPGETIMG_WF_PKG.authorize');
      fnd_message.set_token('ERRNO', SQLCODE);
      fnd_message.set_token('REASON', SQLERRM);
    raise;
  END authorize;        



  PROCEDURE get_access_id(url varchar2, vn_acces_id out number, vn_file_id out number )
  IS      
    vv_file_id   VARCHAR2(255);
    vv_access_id VARCHAR2(255);
  BEGIN
       
       
       vv_file_id := replace ( substr(url,
                                      instr(url,chr(38),1,1) + 1,
                                      instr(url,chr(38),1,2) - instr(url,chr(38),1,1) -1),
                                'fid=',
                                '');
       vn_file_id := to_number(vv_file_id);  
       
       
       vv_access_id := replace ( substr(url,
                                        instr(url,chr(38),1,2)+1),
                                  'accessid=',
                                  '');  
       vn_acces_id := to_number(vv_access_id);                          
  END get_access_id;        
  
  
  PROCEDURE actualise_url_notif(pn_retcode in out number , pv_errbuf out varchar2) IS   
   rec_param      dka_parameters%ROWTYPE;
   vn_file_id number;   
   vn_acces_id number;   
   vn_exists_access number;
  BEGIN
      Dka_Tools_Pkg.get_parameter ('SAPGETIMG_WF', 'NBRE_JOUR_ACCESS', rec_param, pv_errbuf, pn_retcode);
      gn_nbre_jour                  := rec_param.number_value;
      
      IF pn_retcode != 0
      THEN
          pv_errbuf    := 'Parametre NBRE_JOUR_ACCESS : ' || pv_errbuf;
          RETURN;
      ELSIF gn_nbre_jour IS NULL
      THEN
          pv_errbuf    := 'Parametre NBRE_JOUR_ACCESS : Aucune donnee trouvee';
          pn_retcode   := 2;
          RETURN;
      END IF;
      
      FOR facture in (
          -- wf attributes
          select wiav.text_value , wi.item_key
          from  wf_items wi, WF_ITEM_ATTRIBUTE_VALUES  wiav
          where  wi.item_type ='DKA_CSP' 
          and wiav.item_type= wi.item_type 
          and wiav.item_key= wi.item_key
          and wiav.name = 'DKA_INVOICE_URL'
          and wiav.text_value <> '-1'
          and wiav.text_value <> '-2'
          union
          -- notif attributes
          select wna.text_value , wi.item_key
          from  wf_items wi, Wf_Item_Activity_Statuses wias, wf_notification_attributes wna, wf_notifications wn
          where  wi.item_type ='DKA_CSP' 
          and wias.item_type= wi.item_type 
          and wias.item_key= wi.item_key
          and wna.notification_id = wias.notification_id
          and wn.notification_id = wna.notification_id
          and wn.status='OPEN'
          and wna.name = 'DKA_IMAGE_FACT'
          and wna.text_value <> '-1'
          and wna.text_value <> '-2'                    
      ) 
      LOOP      
        log_msg('facture :' ||facture.text_value);
        get_access_id(facture.text_value, vn_acces_id , vn_file_id);      
        
        log_msg('vn_acces_id : ' ||vn_acces_id);  
        log_msg('vn_file_id  : ' ||vn_file_id);   
           
        IF (vn_acces_id is not null) THEN
            select count(1) into vn_exists_access 
            from fnd_lob_access
            where file_id = vn_file_id
            and access_id = vn_acces_id
            and timestamp > sysdate;

            IF vn_exists_access =0  then
                    authorize (vn_file_id, vn_acces_id);     
                    log_msg('URL facture recalculee pour WF item_key ' ||facture.item_key);           
            END IF;       
          commit;  
        ELSE
            log_msg('Prb fact WF item_key ' ||facture.item_key || 'avec url ' || facture.text_value);
        END IF;        
      END LOOP;
      
      FOR bdc in (
          -- wf attributes
          select wiav.text_value , wi.item_key          
          from  wf_items wi, WF_ITEM_ATTRIBUTE_VALUES  wiav
          where  wi.item_type ='DKA_CSP' 
          and wiav.item_type= wi.item_type 
          and wiav.item_key= wi.item_key
          and wiav.name = 'DKA_PURCHASE_ORDER_URL'
          and wiav.text_value <> '-1'
          and wiav.text_value <> '-2'
          union
          -- notif attributes
          select wna.text_value , wi.item_key
          from  wf_items wi, Wf_Item_Activity_Statuses wias, wf_notification_attributes wna, wf_notifications wn
          where  wi.item_type ='DKA_CSP' 
          and wias.item_type= wi.item_type 
          and wias.item_key= wi.item_key
          and wna.notification_id = wias.notification_id
          and wn.notification_id = wna.notification_id
          and wn.status='OPEN'
          and wna.name = 'DKA_IMAGE_CDE'
          and wna.text_value <> '-1'
          and wna.text_value <> '-2'            
      ) 
      LOOP      
        log_msg('commande :' ||bdc.text_value);
        get_access_id(bdc.text_value, vn_acces_id , vn_file_id);        
        
        log_msg('vn_acces_id : ' ||vn_acces_id);  
        log_msg('vn_file_id  : ' ||vn_file_id);   
                
        IF (vn_acces_id is not null) THEN
          select count(1) into vn_exists_access 
          from fnd_lob_access
          where file_id = vn_file_id
          and access_id = vn_acces_id
          and timestamp <= sysdate;

          IF vn_exists_access =0  then          
                  authorize (vn_file_id, vn_acces_id);     
                  log_msg('URL BDC recalculee pour WF item_key ' ||bdc.item_key);           
          END IF;       
          commit;  
        ELSE
            log_msg('Prb BDC WF item_key ' ||bdc.item_key || 'avec url ' || bdc.text_value);
        END IF;        
      END LOOP;      
  END actualise_url_notif;
  

END DKA_SAPACTUALIMG_WF_PKG;
/
SHOW ERROR PACKAGE BODY DKA_SAPACTUALIMG_WF_PKG;
EXIT
