------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOOUVFERCOM.sql
-- DESCRIPTION       : 
--
--- AUTEUR           : Anthony Deltour (Capgemini)
--- DATE DE CREATION : 26/09/2007
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A executer sous SQLPLUS avec le user APPS
--                 EX: sqlplus apps/<mot_de_passe_apps> @DKA_SPOOUVFERCOM.sql OUVRIR 324998
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 26/05/2010 QVA Modification pour tenir compte de l'organisation pour laquelle le 
---                traitement est lancé.
--- 07/06/2010 QVA Modification pour que lors de déblocages, on purge les workflow en
---                erreur.
--- 14/11/2013 JJA INC000000471973 : Suppresion du contrôle sur Attribute9
--- 16/05/2016 RAZ Migration - R12 - DALKIA ( Modification Concernant l’option de profile DKA_REGION) 
--- 04/07/2017 ADE Correction de la recherche par ORG_ID
------------------------------------------------------------------------------------
set serveroutput ON SIZE 1000000
SET echo ON
set feedback OFF
set verify OFF
set heading OFF
set timing ON
set lin 180
VAR ret_code VARCHAR2(10);

prompt

DECLARE
  
  vv_action             VARCHAR2(100)                      := '&1';
  vv_segment1           PO_HEADERS_ALL.SEGMENT1%TYPE       := '&2';
  vn_header_id          PO_HEADERS_ALL.PO_HEADER_ID%TYPE   := NULL;
  vv_cancel_flag        PO_HEADERS_ALL.CANCEL_FLAG%TYPE    := NULL;
  vv_closed_code        PO_HEADERS_ALL.closed_code%TYPE    := NULL;
  vv_attribute9         PO_HEADERS_ALL.attribute9%TYPE     := NULL;
  vd_closed_date        PO_HEADERS_ALL.Closed_Date%TYPE    := NULL;
  vv_item_type          PO_HEADERS_ALL.Wf_Item_Type%TYPE   := NULL;
  vv_item_key           PO_HEADERS_ALL.Wf_Item_Key%TYPE   := NULL;
  vv_message            FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE := NULL;
  vv_authorization_status PO_HEADERS_ALL.Authorization_Status%TYPE := NULL;
  --vv_region             VARCHAR2(10) := fnd_profile.value('DKA_REGION');    RAZ Migration - R12 -  Concernant l’option de profile DKA_REGION, elle n’existera plus en R12 
  --vn_security_profile   NUMBER := fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL');          
  vd_end_date           DATE;
  docommit boolean :=False;
  force boolean :=True;


  
  vn_count              INTEGER := 0;
   
  TYPE NumList IS TABLE OF PO_HEADERS_ALL.SEGMENT1%TYPE INDEX BY BINARY_INTEGER;
  init  NUmlist;
  enums NumList;  
  
  excep_option_profil EXCEPTION;

BEGIN

  DBMS_OUTPUT.put_line('DKA : SOX - Ouverture/Fermeture/Deblocage de commande');
  DKA_TOOLS_PKG.put_debug_message('+ START');
  enums := init;
  
  /*IF vv_region IS NULL or vn_org_id IS NULL THEN    RAZ Migration - R12 -  Concernant l’option de profile DKA_REGION, elle n’existera plus en R12 
    RAISE excep_option_profil;
  END IF;*/
  
  /*IF vn_security_profile IS NULL THEN
    RAISE excep_option_profil;
  END IF;*/
     
  -- Determination de l'id de entete de commande
  SELECT ph.po_header_id,
         NVL(ph.cancel_flag,'N'),
         ph.closed_code,
         ph.attribute9,
         ph.wf_item_type,
         ph.wf_item_key
  INTO   vn_header_id,
         vv_cancel_flag,
         vv_closed_code,
         vv_attribute9,
         vv_item_type,
         vv_item_key 
  FROM   po_headers ph,
         po_vendor_sites pvsa
  WHERE  ph.segment1 = vv_segment1
  AND    ph.vendor_id = pvsa.vendor_id
  AND    ph.vendor_site_id = pvsa.vendor_site_id;
 -- AND    substr(pvsa.vendor_site_code,0,3) = vv_region   RAZ Migration - R12 -  Concernant l’option de profile DKA_REGION, elle n’existera plus en R12  

  DKA_TOOLS_PKG.put_debug_message('=> Reading header');
  
  DBMS_OUTPUT.put_line(vv_action || ' la commande standard numero ' || vv_segment1);
  DBMS_OUTPUT.put_line(CHR(10));
  DBMS_OUTPUT.put_line('Informations sur les lignes de livraison');
  DBMS_OUTPUT.put_line('-----------------------------------------');
  DBMS_OUTPUT.put_line(CHR(10));
  DBMS_OUTPUT.put_line(  'LINE_LOCATION_ID | ' 
                       ||'CLOSED_FLAG | ' 
                       || RPAD('CLOSED_CODE',30,' ') 
                       ||' | CLOSED_DATE | CLOSED_BY | ' 
                       || RPAD('CLOSED_REASON',50,' ') 
                       ||' | CANCEL_FLAG');
                           
  DKA_TOOLS_PKG.put_debug_message('=> Print title line location');
  
  -- Informations des lignes de livraisons
  FOR COMMANDE IN ( SELECT  pll.LINE_LOCATION_ID
                           ,NVL(pll.closed_flag,' ') closed_flag
                           ,pll.closed_code
                           ,NVL(TO_CHAR(pll.closed_date),' ')  closed_date
                           ,NVL(TO_CHAR(pll.closed_by),' ') closed_by
                           ,NVL(pll.closed_reason,' ') closed_reason
                           ,NVL(pll.cancel_flag,'N') cancel_flag
                    FROM   po_line_locations pll
                    WHERE  pll.po_header_id = vn_header_id )
  LOOP
    
    DKA_TOOLS_PKG.put_debug_message('=> Write line location');
                        
    DBMS_OUTPUT.put_line(RPAD(COMMANDE.LINE_LOCATION_ID,16,' ') 
                        || ' | ' 
                        || RPAD(COMMANDE.CLOSED_FLAG,11,' ') 
                        || ' | ' 
                        || RPAD(COMMANDE.CLOSED_CODE,30,' ') 
                        || ' | ' 
                        || RPAD(COMMANDE.CLOSED_DATE,11,' ') 
                        || ' | ' 
                        || RPAD(COMMANDE.CLOSED_BY,9,' ') 
                        || ' | ' 
                        || RPAD(SUBSTR(COMMANDE.CLOSED_REASON,1,50),50,' ') 
                        || ' | ' 
                        || RPAD(COMMANDE.CANCEL_FLAG,11,' '));                           
  END LOOP;
  
  DKA_TOOLS_PKG.put_debug_message('=> Print title line');
  
  DBMS_OUTPUT.put_line(CHR(10));
  DBMS_OUTPUT.put_line('Informations sur les lignes de commande');
  DBMS_OUTPUT.put_line('---------------------------------------');
  DBMS_OUTPUT.put_line(CHR(10));
  DBMS_OUTPUT.put_line(  'PO_LINE_ID | '
                       ||'CLOSED_FLAG | ' 
                       || RPAD('CLOSED_CODE',25,' ') 
                       ||' | CLOSED_DATE | CLOSED_BY | ' 
                       || RPAD('CLOSED_REASON',50,' ') 
                       ||' | CANCEL_FLAG');
                           
  DKA_TOOLS_PKG.put_debug_message('=> Read lines');
  
  -- Informations des lignes de commandes
  FOR LIGNES IN ( SELECT pla.po_line_id
                        ,NVL(pla.closed_flag,' ') closed_flag
                        ,pla.closed_code
                        ,NVL(TO_CHAR(pla.closed_date),' ') closed_date
                        ,NVL(pla.closed_reason,' ') closed_reason
                        ,NVL(TO_CHAR(pla.closed_by),' ') closed_by
                        ,NVL(pla.cancel_flag,'N')  cancel_flag                       
                  FROM  po_lines pla
                  WHERE pla.po_header_id = vn_header_id 
                  )
  LOOP
    
    DKA_TOOLS_PKG.put_debug_message('=> Write lines');
                        
    DBMS_OUTPUT.put_line(RPAD(LIGNES.PO_LINE_ID,10,' ') 
                        || ' | ' 
                        || RPAD(LIGNES.CLOSED_FLAG,11,' ') 
                        || ' | ' 
                        || RPAD(LIGNES.CLOSED_CODE,25,' ') 
                        || ' | ' 
                        || RPAD(LIGNES.CLOSED_DATE,11,' ') 
                        || ' | ' 
                        || RPAD(LIGNES.CLOSED_BY,9,' ') 
                        || ' | ' 
                        || RPAD(SUBSTR(LIGNES.CLOSED_REASON,1,50),50,' ') 
                        || ' | ' 
                        || RPAD(LIGNES.CANCEL_FLAG,11,' '));                           
  END LOOP;
  
  DKA_TOOLS_PKG.put_debug_message('=> Print title header');
  
  DBMS_OUTPUT.put_line(CHR(10));
  DBMS_OUTPUT.put_line('Informations sur l''entete de commande');
  DBMS_OUTPUT.put_line('---------------------------------------');
  DBMS_OUTPUT.put_line(CHR(10));
  DBMS_OUTPUT.put_line(  'PO_HEADER_ID | '
                       || RPAD('AUTHORIZATION_STATUS',25,' ')
                       ||' | CLOSED_DATE | ' 
                       || RPAD('CLOSED_CODE',25,' ') 
                       ||' | CANCEL_FLAG');    
  
  DKA_TOOLS_PKG.put_debug_message('=> Read header');
  
  -- Verification du statut au niveau entete de commande 
  SELECT ph.closed_date
        ,ph.authorization_status
  INTO   vd_closed_date
        ,vv_authorization_status
  FROM  po_headers ph
  WHERE po_header_id = vn_header_id;
  
  DKA_TOOLS_PKG.put_debug_message('=> Write header');
                        
  DBMS_OUTPUT.put_line(RPAD(VN_HEADER_ID,12,' ') 
                      || ' | '
                      || RPAD(VV_AUTHORIZATION_STATUS,25,' ')
                      || ' | ' 
                      || RPAD(VV_CLOSED_CODE,25,' ') 
                      || ' | ' 
                      || RPAD(NVL(TO_CHAR(VD_CLOSED_DATE),' '),11,' ') 
                      || ' | ' 
                      || RPAD(VV_CANCEL_FLAG,11,' '));                           
  
  DKA_TOOLS_PKG.put_debug_message('=> Choose Action');
  
  IF vv_action = 'OUVRIR' THEN
    IF     NVL(vv_cancel_flag,'N') <> 'Y' 
       AND vv_closed_code IN ('CLOSED' , 'FINALLY CLOSED')
       /*AND vv_attribute9 IS NULL JJA 2013/11/08*/ 
    THEN  
      
      DKA_TOOLS_PKG.put_debug_message('=> Open');
         
      -- MAJ des lignes de livraison     
      UPDATE po_line_locations
      SET    closed_code  = 'OPEN'
            ,closed_date = NULL
			,SHIPMENT_CLOSED_DATE = NULL --SNK artf07230322 27/03/2019
            ,last_update_date = sysdate
            ,last_updated_by = fnd_global.user_id
            ,last_update_login = fnd_global.login_id
      WHERE po_header_id = vn_header_id;
      
      DKA_TOOLS_PKG.put_debug_message('=> Lines location updated ' || SQL%ROWCOUNT );
      
      -- MAJ des lignes de commande 
      UPDATE po_lines
      SET    closed_code  = 'OPEN'
            ,closed_date = NULL
            ,last_update_date = sysdate
            ,last_updated_by = fnd_global.user_id
            ,last_update_login = fnd_global.login_id
      WHERE po_header_id = vn_header_id;
      
      DKA_TOOLS_PKG.put_debug_message('=> Lines updated ' || SQL%ROWCOUNT );
      
      -- MAJ entete de commande 
      UPDATE po_headers
      SET    closed_date = null
            ,closed_code = 'OPEN'
            ,attribute9 = 'OUI'
            ,last_update_date = sysdate
            ,last_updated_by = fnd_global.user_id
            ,last_update_login = fnd_global.login_id
      WHERE po_header_id = vn_header_id
      RETURNING segment1 BULK COLLECT INTO enums;
      
      DKA_TOOLS_PKG.put_debug_message('=> Header updated ' || SQL%ROWCOUNT );
      
    END IF;
  ELSIF vv_action = 'FERMER' THEN
    IF    /* vv_attribute9 = 'OUI' AND  JJA 2013/11/08*/ 
        vv_closed_code = 'OPEN' 
    THEN
      
      DKA_TOOLS_PKG.put_debug_message('=> Close');
      
      -- Recuperation du message de fermeture 
      Fnd_Message.set_name ('DKA', 'DKA_SPOOUVFERCOM_001');
      vv_message := Fnd_Message.get;
      
      DKA_TOOLS_PKG.put_debug_message('=> Get message ');
      
      -- MAJ ligne de livraison 
      UPDATE po_line_locations
      SET    closed_code  = 'FINALLY CLOSED'
            ,closed_date = sysdate
			,SHIPMENT_CLOSED_DATE = SYSDATE --SNK artf07230322 27/03/2019
            ,closed_by = fnd_global.user_id
            ,closed_reason = SUBSTR(vv_message,1,240)
            ,last_update_date = sysdate
            ,last_updated_by = fnd_global.user_id
            ,last_update_login = fnd_global.login_id
      WHERE po_header_id = vn_header_id;
      
      DKA_TOOLS_PKG.put_debug_message('=> Lines location updated ' || SQL%ROWCOUNT );
      
      -- MAJ des lignes de commande 
      UPDATE po_lines
      SET    closed_code  = 'FINALLY CLOSED'
            ,closed_date = sysdate
            ,closed_by = fnd_global.user_id
            ,closed_reason = SUBSTR(vv_message,1,240)
            ,last_update_date = sysdate
            ,last_updated_by = fnd_global.user_id
            ,last_update_login = fnd_global.login_id
      WHERE po_header_id = vn_header_id;
      
      DKA_TOOLS_PKG.put_debug_message('=> Lines updated ' || SQL%ROWCOUNT );
      
      -- MAJ entete de commande 
      UPDATE po_headers 
      SET    closed_date = sysdate
            ,closed_code = 'FINALLY CLOSED'
            ,attribute9 = NULL
            ,last_update_date = sysdate
            ,last_updated_by = fnd_global.user_id
            ,last_update_login = fnd_global.login_id
      WHERE po_header_id = vn_header_id
      RETURNING segment1 BULK COLLECT INTO enums;
      
      DKA_TOOLS_PKG.put_debug_message('=> Header updated ' || SQL%ROWCOUNT );
      
    ELSE
      dbms_output.put_line('La commande '|| vv_segment1 || ' ne peut etre fermee par ce traitement.');
      dbms_output.put_line('Seul les commandes re-ouvertes par le traitement DKA : SOX - Ouverture/Fermeture/Deblocage de commande peuvent etre fermees.');
    END IF;
  ELSIF vv_action = 'DEBLOQUER' THEN
    IF  /*   vv_attribute9 IS NULL AND  JJA 2013/11/08*/ 
           vv_closed_code = 'OPEN'
       AND vv_authorization_status = 'IN PROCESS'
       AND NVL(vv_cancel_flag,'N') <> 'Y'
    THEN
      
      DKA_TOOLS_PKG.put_debug_message('=> Reset');
      
      -- Vérification du workflow
      SELECT  COUNT(1)
      INTO    vn_count
      FROM    wf_item_activity_statuses ias,
              wf_process_activities pa,
              wf_activities_vl ac,
              wf_activities_vl ap,
              wf_items i
      WHERE   ias.item_type = vv_item_type
      AND     ias.item_key  = vv_item_key
      AND     ias.activity_status     = 'ERROR'
      AND     ias.process_activity    = pa.instance_id
      AND     pa.activity_name        = ac.name
      AND     pa.activity_item_type   = ac.item_type
      AND     pa.process_name         = ap.name
      AND     pa.process_item_type    = ap.item_type
      AND     pa.process_version      = ap.version
      AND     i.item_type             = vv_item_type
      AND     i.item_key              = ias.item_key
      AND     i.begin_date            >= ac.begin_date 
      AND     i.begin_date            < nvl(ac.end_date, i.begin_date+1)
      ORDER BY ias.execution_time;
      
      DKA_TOOLS_PKG.put_debug_message('=> Workflow activities errors ' || vn_count );
         
      IF vn_count != 0
      THEN-- MAJ entete de commande 
        UPDATE po_headers 
        SET    authorization_status = 'INCOMPLETE'
              ,approved_flag = NULL
              ,approved_date = NULL
              ,wf_item_type = NULL
              ,wf_item_key = NULL
              ,last_update_date = sysdate
              ,last_updated_by = fnd_global.user_id
              ,last_update_login = fnd_global.login_id
        WHERE po_header_id = vn_header_id 
        RETURNING segment1 BULK COLLECT INTO enums;
        
        DKA_TOOLS_PKG.put_debug_message('=> Header updated ' || SQL%ROWCOUNT );
        
        DKA_TOOLS_PKG.put_debug_message('Recherche et AbortProcess des WorkFlow enfants' );
        
        FOR WF IN (SELECT item_key,
                          end_date
                      FROM wf_items wi
                      WHERE wi.parent_item_key = vv_item_key
                      AND wi.parent_item_type = vv_item_type
                      )
                      
        LOOP
        
        IF WF.end_date is null THEN
          WF_ENGINE.abortProcess('WFERROR',WF.item_key);
          commit;
        ELSE
          WF_PURGE.items('WFERROR',WF.item_key,sysdate,docommit,force);
          commit;
        END IF;
        
        END LOOP;
        
        DKA_TOOLS_PKG.put_debug_message('AbortProcess du WorkFlow maître');
        
        SELECT end_date
        INTO vd_end_date
        FROM wf_items
        WHERE item_type = vv_item_type
        AND item_key = vv_item_key;
        
        IF vd_end_date is null THEN
          WF_ENGINE.abortProcess(vv_item_type,vv_item_key);
          commit;
        ELSE
          WF_PURGE.items(vv_item_type,vv_item_key,sysdate,docommit,force);
          commit;
        END IF;
        
      END IF;
    END IF;
  END IF;
    
  -- Alimentation de la table de trace sox
  IF enums.COUNT > 0 THEN 
    DKA_TOOLS_PKG.put_debug_message('=> Trace'); 
    FORALL i IN enums.FIRST..enums.LAST
      INSERT INTO Dka_Trace_For_Sox
       ( REQUEST_ID,
         PROGRAM_SHORT_NAME,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATE_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_LOGIN,
         ACTION,
         ORG_ID      
       )      
      VALUES 
       ( FND_GLOBAL.CONC_REQUEST_ID,
         'DKA_SPOOUVFERCOM',   
         FND_GLOBAL.USER_ID,
         SYSDATE,
         SYSDATE,
         FND_GLOBAL.USER_ID,
         FND_GLOBAL.LOGIN_ID,
         vv_action || ' la commande numero ' || enums(i),
         --TO_NUMBER(Fnd_Profile.VALUE('ORG_ID'))
         sys_context('multi_org2','current_org_id')				 
       );
    DKA_TOOLS_PKG.put_debug_message('+ Success' );     
  ELSE
    DKA_TOOLS_PKG.put_debug_message('*** FIN DU TRAITEMENT : POUR LA COMMANDE ' || vv_segment1 || '. Action demandée non effectuée.');   
  END IF;   
           
  
  COMMIT;
  
  DKA_TOOLS_PKG.put_debug_message('+ End Of Program' );
  :ret_code        := 'SUCCESS';
  
EXCEPTION
  WHEN excep_option_profil THEN
    DKA_TOOLS_PKG.put_outdebug_message('Les options de profils ne sont pas correctement renseignées');
    :ret_code    := 'WARNING';
  WHEN OTHERS THEN
    ROLLBACK;
    DKA_TOOLS_PKG.put_outdebug_message('ERREUR : ' || SQLCODE || ' est survenue.');
    DKA_TOOLS_PKG.put_outdebug_message(SQLERRM);
    :ret_code    := 'FAILURE';
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
