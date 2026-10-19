---------------------------------------------------------------------------------------------------------------
--- Capgemini
--- PROJET           : DALKIA Oracle Applications HELIOS
--- NOM              : DKA_AUTO_SARRECOUVREMENT.sql
--- DESCRIPTION      : Lancement automatique des traitements d'alimentation des tableaux de recouvrement
---
--- AUTEUR           : H Descroizette
--- DATE DE CREATION : 17/11/2016
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS. Les traitements sont lancés avec la repsonsabilité TOUT_AR_ADMINISTRATEUR et le user EXPLOITATION
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
--- 07/02/2017 OBE Modification - artf2091046
---------------------------------------------------------------------------------------------------------------


SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);

DECLARE
    K_PROG_APPL         constant varchar2(50) := '&&1';                     -- Application short name du programme à lancer. Ex : DKA    
    K_PROG_NAME         constant varchar2(50) := '&&2';                     -- Nom du programme à lancer. Ex : DKA_ENCOURS_RECOUVREMENT
    K_MODE              constant varchar2(50) := upper(nvl('&&3', 'ORG'));  -- Mode de lancement. ORG => toutes les UO une à une ; ALL ou FRANCE => un seul lancement portant sur toutes les UO
    K_DEFAULT_RESP_KEY  constant varchar2(50) := 'TOUT_AR_ADMINISTRATEUR';
    K_DEFAULT_USER_NAME constant varchar2(50) := 'EXPLOITATION';
    K_DEFAULT_APPL      constant varchar2(50) := 'AR';
    
    l_instance          varchar2(200);
    l_prog              fnd_concurrent_programs%ROWTYPE;
    l_tab_orgid         mo_global.OrgIdTab;
    l_request_id        fnd_concurrent_requests.request_id%type;
    
    type TAB_REQUESTS is table of fnd_concurrent_requests.request_id%type index by pls_integer;
    l_requests          TAB_REQUESTS;
    l_success           boolean;
    l_phase             varchar2(500);
    l_status            varchar2(500);
    l_dev_phase         varchar2(500);
    l_dev_status        varchar2(500);
    l_message           varchar2(2000);
    
    --< OBE
    vn_trt_a_lancer     NUMBER:=0;
    vn_trt_lances       NUMBER:=0;
    vn_trt_normal       NUMBER:=0;
    vn_trt_erreur       NUMBER:=0;
    vn_trt_warning      NUMBER:=0;    
    --> OBE
    
    
    -------------------------------------------------------
    -- Procédure de positionnement dans le contexte O.A. --
    -------------------------------------------------------
    PROCEDURE Positionnement_Contexte(Pv_User_Name IN VARCHAR2 default NULL, Pv_Resp_Name IN VARCHAR2 default NULL, pv_appl_short_name in varchar2 default null) IS
      l_user   fnd_user%ROWTYPE;
      l_resp   fnd_responsibility%ROWTYPE;
      l_appl   fnd_application%ROWTYPE;
    BEGIN        
        -- Recherche de l'utilisateur         
        BEGIN
            SELECT * INTO l_user
            FROM   Fnd_User
            WHERE  User_Name = Nvl(Pv_User_Name, K_DEFAULT_USER_NAME);        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                dbms_output.put_line('==> Impossible de trouver les informations liees a l''utilisateur : ' || Nvl(Pv_User_Name, K_DEFAULT_RESP_KEY));
                RAISE;
        END;
    
        -- Récupération des informations liées a la responsabilite --
        BEGIN
            SELECT * into l_resp
            FROM   Fnd_Responsibility Fr
            WHERE  Fr.Responsibility_Key = nvl(Pv_Resp_Name, K_DEFAULT_RESP_KEY);        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                dbms_output.put_line('==> Impossible de trouver les informations liees a la responsabilite : ' || nvl(Pv_Resp_Name, K_DEFAULT_USER_NAME));
                RAISE;
        END;    
        
        -- Récupération des informations liées a l'application --
        begin
          select * into l_appl
          from fnd_application
          where application_short_name = nvl(pv_appl_short_name, K_DEFAULT_APPL);
        exception
          when NO_DATA_FOUND then 
            dbms_output.put_line('==> Impossible de trouver les informations liees a l''application : ' || nvl(pv_appl_short_name, K_DEFAULT_APPL));
            RAISE;      
        end;
        
        -- Positionnement dans le contexte O.A. --
        dbms_output.put_line('Connexion au contexte : ' || l_user.User_name || '/' || l_resp.Responsibility_key || '/' || l_appl.application_short_name);
        Fnd_Global.Apps_Initialize(l_user.User_Id, l_resp.Responsibility_Id, l_appl.application_id);    
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.VALUE('ICX_LANGUAGE') || '''';
        
        -- MOAC
        mo_global.init(l_appl.application_short_name);
        dbms_output.put_line('Connecté : ' ||nvl(mo_global.get_ou_count, 0) || ' Unité(s) opérationnelle(s) accessible(s).');    
    END Positionnement_Contexte;
    
    -------------------------------------------------------
    -- Lancement d'un traitement                         --
    -------------------------------------------------------
    function soumission_traitement(Pn_Prog_Application_Id in number, Pn_Program_Id in number, p_org_id in number) return fnd_concurrent_requests.request_id%type
    is
      Vv_Errbuf     varchar2(2000);
      Vn_Retcode    number;
      l_etape       varchar2(100) := 'init';
      l_request_id  fnd_concurrent_requests.request_id%type;
      l_appl_name   fnd_application.application_short_name%type;
      l_prog_name   fnd_concurrent_programs.concurrent_program_name%type;
    begin
      l_etape := 'Get_Request_Set_Params';
      Dka_Tools_Pkg.Get_Request_Set_Params(
        Pv_Errbuf                 => Vv_Errbuf,
        Pn_Retcode                => Vn_Retcode,
        Pn_Application_Id         => NULL,
        Pn_Prog_Application_Id    => Pn_Prog_Application_Id,
        Pn_Program_Id             => Pn_Program_Id);  
      IF Vn_Retcode != 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Impossible de récupérer les paramètres :' || Vv_Errbuf);
      end if;
      
      l_etape := 'prog';
      select fa.application_short_name, fcp.concurrent_program_name into l_appl_name, l_prog_name
      from fnd_concurrent_programs fcp
      join fnd_application         fa  on (fa.application_id = fcp.application_id)
      where fa.application_id         = Pn_Prog_Application_Id
        and fcp.concurrent_program_id = Pn_Program_Id;    
      
      l_etape := 'submit_request ' ||l_appl_name || '/' ||l_prog_name;        
      l_request_id := Fnd_Request.Submit_Request(
        application           => l_appl_name,
			  program               => l_prog_name,
			  description           => null,
			  start_time            => null,
			  sub_request           => null,
			  argument1             => Dka_Tools_Pkg.Tab_Request_Params(1),
			  argument2             => p_org_id,
			  argument3             => Dka_Tools_Pkg.Tab_Request_Params(3),
			  argument4             => Dka_Tools_Pkg.Tab_Request_Params(4),
			  argument5             => Dka_Tools_Pkg.Tab_Request_Params(5),
			  argument6             => Dka_Tools_Pkg.Tab_Request_Params(6),
			  argument7             => Dka_Tools_Pkg.Tab_Request_Params(7),
			  argument8             => Dka_Tools_Pkg.Tab_Request_Params(8),
			  argument9             => Dka_Tools_Pkg.Tab_Request_Params(9),
			  argument10            => Dka_Tools_Pkg.Tab_Request_Params(10));
        
      commit;
      return l_request_id;
    exception
      when others then
        fnd_message.set_name('FND', 'FND_GENERIC_MESSAGE');
        fnd_message.set_token('MESSAGE', 'Erreur à l''étape ' || l_etape || ' : ' || SQLERRM);
        return null;
    end soumission_traitement;
    
-- Programme principal    
BEGIN
  dbms_output.put_line('===============================================================================');
  dbms_output.put_line('Lancement du programme ' || K_PROG_APPL || '/"' || K_PROG_NAME || '"    mode="' || K_MODE || '"');  
  dbms_output.put_line('  ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
  select instance_name into l_instance from v$instance;
  dbms_output.put_line('  ' || l_instance);  
  dbms_output.put_line('===============================================================================');

  if trim(K_PROG_APPL) is null then
    dbms_output.put_line('Paramètre manquant : PROG_APPL');  
    raise PROGRAM_ERROR;
  elsif trim(K_PROG_NAME) is null then
    dbms_output.put_line('Paramètre manquant : PROG_NAME');  
    raise PROGRAM_ERROR;    
  else
    begin
      select fcp.* into l_prog 
      from fnd_concurrent_programs fcp
      join fnd_application         fa  on (fa.application_id = fcp.application_id)
      where fa.application_short_name   = trim(K_PROG_APPL)
        and fcp.concurrent_program_name = trim(K_PROG_NAME);
    exception
      when no_data_found then 
        dbms_output.put_line('==> Le programme n''existe pas : ' || K_PROG_APPL || '/' || K_PROG_NAME);
        raise;
    end;
  end if;
  
  if K_MODE is null then 
    dbms_output.put_line('==> Mode de lancement non fourni');    
    raise PROGRAM_ERROR;      
  elsif K_MODE not in ('ORG', 'ALL', 'FRANCE') then 
    dbms_output.put_line('==> Valeur du mode de lancement invalide : "' || K_MODE || '". Valeurs autorisées=ORG, ALL ou FRANCE');
    raise PROGRAM_ERROR;        
  end if;
  
  -- connexion dans la responsabilité
  Positionnement_Contexte;  
  
  if K_MODE = 'ORG' then 
    -- récupération des UO accessibles
    l_tab_orgid := mo_global.get_ou_tab;
  elsif K_MODE in ('ALL', 'FRANCE') then 
    -- un seul lancement pour toutes les UO
    l_tab_orgid(1) := null;
  else
    raise PROGRAM_ERROR;     -- on ne devrait jamais arriver ici ...
  end if;
  
  -- Boucle sur les UO
  for i in l_tab_orgid.FIRST .. l_tab_orgid.LAST loop
  
    vn_trt_a_lancer := vn_trt_a_lancer + 1; -- OBE
    -- lancement du traitement pour l'org_id l_tab_orgid(i)
    dbms_output.put_line('Lancement du traitement pour ' ||
      case 
        when l_tab_orgid(i) is null then 'toutes les UO.'
        else 'l''org_id ' || l_tab_orgid(i) || ' (' || mo_global.get_ou_name(l_tab_orgid(i)) ||')'
      end);
    l_request_id := soumission_traitement(l_prog.application_id, l_prog.concurrent_program_id, l_tab_orgid(i));
    if l_request_id is not null then 
      dbms_output.put_line('  Traitement lancé : request_id = ' ||l_request_id);
      l_requests(l_requests.count+1) := l_request_id;
      vn_trt_lances := vn_trt_lances + 1; -- OBE
    else
      dbms_output.put_line('  Echec : ' || fnd_message.get);
    end if;    
  end loop;
  
  -- Attente de la fin de tous les traitements
  :ret_code := 'SUCCESS';  
  for i in l_requests.FIRST .. l_requests.LAST loop
    l_success := Fnd_Concurrent.Wait_For_Request(
       request_id   => l_requests(i),
       phase        => l_phase,
       status       => l_status,
       dev_phase    => l_dev_phase,
       dev_status   => l_dev_status,
       message      => l_message);
    if not l_success then 
      dbms_output.put_line('>>> Impossible de déterminer le status du traitement ' || l_requests(i));      
      :ret_code := 'FAILURE';
    else
       --< OBE 
       IF l_dev_status = 'NORMAL' THEN
          DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||l_requests(i)||' terminé avec le statut Normal');
          vn_trt_normal := vn_trt_normal + 1;
       ELSIF l_dev_status = 'WARNING' THEN
          DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||l_requests(i)||' terminé avec le statut en Warning');
          vn_trt_warning := vn_trt_warning + 1;
       ELSIF l_dev_status != 'NORMAL' THEN
          DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||l_requests(i)||' terminé avec le statut en Erreur');
          vn_trt_erreur := vn_trt_erreur + 1;
          dbms_output.put_line('>>>    message = "' || l_message || '"');
          :ret_code := 'FAILURE';
       END IF;    
      /*dbms_output.put_line('>>> ' || to_char(SYSDATE, 'HH24:MI:SS') || ' : Traitement ' || l_requests(i) || ' terminé avec le statut ' || l_status); 
      if l_dev_status != 'NORMAL' then 
        dbms_output.put_line('>>>    message = "' || l_message || '"');
        :ret_code := 'FAILURE';
      end if;*/
      --> OBE
    end if;
  end loop;
  
  --< OBE
    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));  
  --> OBE
  
EXCEPTION
  when others then 
    dbms_output.put_line('>>> Erreur : ' || SQLERRM);
    :ret_code := 'FAILURE';
END;
/

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;

EXIT &ret_code