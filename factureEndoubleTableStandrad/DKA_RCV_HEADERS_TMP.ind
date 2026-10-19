-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_APUREMENT_PASSE_POST_CUTOFF.sql
-- DESCRIPTION      : Mise à jour des lettrage post CUTOFF (après le 31/12/2004)
--
-- AUTEUR           : C.DEFAUX (Capgemini)
-- DATE DE CREATION : 27/02/2012
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------

SET HEADING ON
SET PAGESIZE 500
SET LINESIZE 150
SET SERVEROUTPUT ON SIZE 1000000
SET TRIMSPOOL ON

DECLARE
  vn_compteur        NUMBER;
  vn_compteur_ign    NUMBER;
  vn_compteur_ctr    NUMBER;
  pn_retcode         NUMBER;
  pv_errbuf          VARCHAR2(500);
  vn_pas             NUMBER;
  pv_periode         gl_periods.period_name%TYPE := '&1';
  vv_periode_ctr     gl_periods.period_name%TYPE;
  vn_header_id       NUMBER;
  
  --< OBE
  vv_user                          VARCHAR2 (80)  := 'CAPTECH';
  vv_resp                          VARCHAR2 (80)  := 'TOUT_GL_OPE_ADMINISTRATEUR';
  vn_responsibility_id             NUMBER (15);  
  vn_application_id                NUMBER (15);
  vn_user_id                       NUMBER (15);     
  --> OBE
          
  
  CURSOR cur_lettrage IS
    SELECT 
      gjl.je_header_id,
      gjl.je_line_num,
      gjh.je_source,
      gjl.attribute9,
      gjh.period_name,
      gcc.segment1,
      gcc.segment2,
      --
      gjh.default_effective_date,
      gjh.name,
      --gjl.jgzz_recon_ref -- OBE
      gjlr.jgzz_recon_ref  -- OBE
    FROM   
      gl_je_lines          gjl,
      gl_je_headers          gjh,
      gl_je_lines_recon      gjlr,        -- OBE
      gl_code_combinations   gcc,
      fnd_flex_value_sets    ffvs,
      fnd_flex_values_vl     ffvv,
      --gl_sets_of_books       gsob,      -- OBE
      gl_periods             gp,
      gl_autoreverse_options gao,
      gl_access_sets glas,                -- OBE
      GL_ACCESS_SET_LEDGERS glasl,        -- OBE
      gl_ledgers             gll          -- OBE
    WHERE gjlr.je_header_id(+) = gjl.je_header_id -- OBE
      AND gjlr.je_line_num (+) = gjl.je_line_num  -- OBE
      AND gjlr.jgzz_recon_ref IS NULL --rg02      -- OBE
      AND gjlr.jgzz_recon_id IS NULL              -- OBE
      --gjl.jgzz_recon_ref IS NULL --rg02         -- OBE
      --AND gjl.jgzz_recon_id IS NULL             -- OBE
      AND gcc.code_combination_id = gjl.code_combination_id
      AND gjh.je_header_id = gjl.je_header_id
      AND glas.access_set_id = fnd_profile.VALUE('GL_ACCESS_SET_ID') -- OBE
      AND glas.period_set_name = gp.period_set_name                  -- OBE
      --AND gsob.set_of_books_id = 1                                 -- OBE
      --AND gsob.period_set_name = gp.period_set_name                -- OBE
      AND gjh.period_name = pv_periode
      AND gjh.period_name = gp.period_name
      -- CPTE LETTRABLE
      AND ffvv.flex_value = gcc.segment3
      AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
      AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
      AND ffvv.compiled_value_attributes LIKE  '%' || chr(10) || '%' || chr(10) || '%' || chr(10) || 'Y' || chr(10) || '%'
      -- PIECE CONTRPASSABLE
      --AND gao.set_of_books_id = gsob.set_of_books_id    -- OBE      
      AND glasl.access_set_id      = glas.access_set_id   -- OBE
      AND glasl.ledger_id          = gll.ledger_id        -- OBE
      AND gao.criteria_set_id  (+) = gll.criteria_set_id  -- OBE      
      AND gao.je_category_name (+) = gjh.je_category      -- OBE      
      AND gao.autoreverse_flag (+) = 'Y'                  -- OBE      
      --TEST
      --AND gjh.name LIKE '%CPC074 CUT OFF PRELUDE EUR%'
      ORDER BY gjl.je_header_id
      ;
      
   CURSOR cur_lettrage_ctr( pn_je_header_id gl_je_headers.je_header_id%TYPE,
                            pn_region       gl_code_combinations.segment2%TYPE) IS
    SELECT /*+ INDEX(gcc GL_CODE_COMBINATIONS_U1)*/
      gjh_ctr.je_header_id,
      gjl_ctr.je_line_num
    FROM   
      gl_je_headers          gjh_ctr,
      gl_je_lines            gjl_ctr,
      gl_je_lines_recon      gjlr,        -- OBE
      gl_je_headers          gjh,
      gl_code_combinations   gcc
      --fnd_flex_value_sets    ffvs,
      --fnd_flex_values_vl     ffvv
    WHERE gjlr.je_header_id(+) = gjl_ctr.je_header_id -- OBE
      AND gjlr.je_line_num (+) = gjl_ctr.je_line_num  -- OBE
      AND gjlr.jgzz_recon_ref IS NULL --rg02          -- OBE
      AND gjlr.jgzz_recon_id IS NULL                  -- OBE 
      --gjl_ctr.jgzz_recon_ref IS NULL --rg02         -- OBE 
      --AND gjl_ctr.jgzz_recon_id  IS NULL            -- OBE 
      AND gcc.code_combination_id = gjl_ctr.code_combination_id
      AND gjh_ctr.period_name = vv_periode_ctr
      AND gjh_ctr.name LIKE 'Annulez la pièce "'||gjh.name||'%'
      AND gjh_ctr.je_header_id = gjl_ctr.je_header_id
      AND gjh.je_header_id = pn_je_header_id
      AND gcc.segment2 = pn_region
      -- CPTE LETTRABLE 
      --AND ffvv.flex_value = gcc.segment3
      --AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
      --AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
      --AND ffvv.compiled_value_attributes LIKE  '%' || chr(10) || '%' || chr(10) || '%' || chr(10) || 'Y' || chr(10) || '%'
      ;

  TYPE t_cur_lettrage_tab      IS TABLE OF cur_lettrage%ROWTYPE;
  TYPE t_cur_lettrage_ctr_tab  IS TABLE OF cur_lettrage_ctr%ROWTYPE;
  TYPE t_je_header_id          IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
  
  
  cur_lettrage_tab     t_cur_lettrage_tab;
  cur_lettrage_ctr_tab t_cur_lettrage_ctr_tab;
  vt_je_header_id      t_je_header_id;  
  
BEGIN

    --< OBE
    DBMS_OUTPUT.put_line ('Recuperation des identifiants user');
    SELECT fr.responsibility_id,
           fr.application_id
    INTO   vn_responsibility_id,
           vn_application_id
    FROM   fnd_responsibility fr
    WHERE  responsibility_key = vv_resp;

    SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = vv_user;
    
    DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
    fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);    
    --> OBE
    
  vn_header_id:= 0;
  vn_compteur := 0;
  vn_pas      := 0;
  
  dbms_output.put_line('*********************************');
  dbms_output.put_line('Début du lettrage : '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'));
  dbms_output.put_line('*********************************');
  
    
    vn_compteur := 0;
    vn_compteur_ctr := 0;
    vn_compteur_ign := 0;
    
    --Sélection de la période des contrepassation
    --< OBE
    /*SELECT
    gp_1.period_name
    INTO vv_periode_ctr
    FROM
    gl_sets_of_books       gsob,
    gl_periods             gp_1,
    gl_periods             gp
    WHERE
     gsob.set_of_books_id = 1
     AND gsob.period_set_name = gp.period_set_name
     AND gp_1.period_set_name = gp.period_set_name
     AND gp_1.period_num  = decode(gp.period_num + 1,13,1,gp.period_num + 1)
     AND gp_1.period_year = decode(gp.period_num + 1,13,gp.period_year+1,gp.period_year)
     AND gp.period_name = pv_periode;*/
     
    SELECT
    gp_1.period_name
    INTO vv_periode_ctr
    FROM
    gl_periods             gp_1,
    gl_periods             gp,
    gl_access_sets         glas
    WHERE 1=1
     AND glas.access_set_id   = fnd_profile.VALUE('GL_ACCESS_SET_ID')
     AND glas.period_set_name = gp.period_set_name    
     AND gp_1.period_set_name = gp.period_set_name
     AND gp_1.period_num  = decode(gp.period_num + 1,13,1,gp.period_num + 1)
     AND gp_1.period_year = decode(gp.period_num + 1,13,gp.period_year+1,gp.period_year)
     AND gp.period_name = pv_periode;      
    --> OBE
    
    --NORMALE
    OPEN cur_lettrage;
    FETCH cur_lettrage BULK COLLECT INTO cur_lettrage_tab;
    CLOSE cur_lettrage;
    

    IF cur_lettrage_tab.count > 0 THEN
      FOR i IN cur_lettrage_tab.first..cur_lettrage_tab.last LOOP
      
  
        IF (cur_lettrage_tab(i).default_effective_date = to_date('08/01/2005', 'DD/MM/YYYY')
            or cur_lettrage_tab(i).period_name = 'DEC-04') THEN
                   
          vn_compteur_ign := vn_compteur_ign + 1;
                      
        ELSE 
          
          --LETTRAGE ECRITURE
          UPDATE  --gl_je_lines --OBE
          gl_je_lines_recon     --OBE
          SET
           jgzz_recon_ref = cur_lettrage_tab(i).segment2 || cur_lettrage_tab(i).period_name,
           LAST_UPDATE_DATE  = sysdate,
           LAST_UPDATED_BY   = -1,
           LAST_UPDATE_LOGIN = -1
          WHERE
              je_header_id = cur_lettrage_tab(i).je_header_id
          AND je_line_num = cur_lettrage_tab(i).je_line_num ;
          
          vn_compteur := vn_compteur + SQL%ROWCOUNT;
          
          --VERIFICATION DE LA CONTREPASSATION POUR LA PERIODE N+1
          IF NOT (vt_je_header_id.exists(cur_lettrage_tab(i).je_header_id)) THEN
          
            OPEN cur_lettrage_ctr(cur_lettrage_tab(i).je_header_id,cur_lettrage_tab(i).segment2);
            FETCH cur_lettrage_ctr BULK COLLECT INTO cur_lettrage_ctr_tab;
            CLOSE cur_lettrage_ctr;
            
            IF cur_lettrage_ctr_tab.count > 0 THEN
              FOR j IN cur_lettrage_ctr_tab.first..cur_lettrage_ctr_tab.last LOOP
                
                UPDATE gl_je_lines_recon gjlr --OBE
                --gl_je_lines gjl             --OBE
                SET    
                 jgzz_recon_ref = cur_lettrage_tab(i).segment2 || cur_lettrage_tab(i).period_name,
                 LAST_UPDATE_DATE  = sysdate,
                 LAST_UPDATED_BY   = -1,
                 LAST_UPDATE_LOGIN = -1
                WHERE  je_header_id = cur_lettrage_ctr_tab(j).je_header_id
                   AND je_line_num = cur_lettrage_ctr_tab(j).je_line_num
                   AND EXISTS(SELECT NULL
                              FROM 
                               gl_code_combinations   gcc,
                               fnd_flex_value_sets    ffvs,
                               fnd_flex_values_vl     ffvv,
                               gl_je_lines gjl             --OBE
                              WHERE gjlr.je_header_id = gjl.je_header_id -- OBE
                               AND gjlr.je_line_num   = gjl.je_line_num  -- OBE
                               AND gcc.code_combination_id = gjl.code_combination_id
                               AND ffvv.flex_value = gcc.segment3
                               AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
                               AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                               AND ffvv.compiled_value_attributes LIKE  '%' || chr(10) || '%' || chr(10) || '%' || chr(10) || 'Y' || chr(10) || '%');
                
                vn_compteur_ctr := vn_compteur_ctr + SQL%ROWCOUNT;
                
              END LOOP;              
            END IF;
            
            vt_je_header_id(cur_lettrage_tab(i).je_header_id) := 'O';
            
          END IF; --VERIF
          
        END IF; --IGNORE
        
      END LOOP;
      
      -- COMMIT!
      COMMIT;
      
    END IF;
    dbms_output.put_line('*********************************');
    dbms_output.put_line('Nombre de lettrages effectués pour les écritures               : ' ||
                          vn_compteur || ' pour la période ' || pv_periode );
                          
    dbms_output.put_line('Nombre de lettrages effectués pour les écritures contrepassées : ' ||
                          vn_compteur_ctr || ' pour la période ' || vv_periode_ctr );                          
                          
    dbms_output.put_line('Nombre de lettrages ignorés pour les écritures                 : ' ||
                          vn_compteur_ign || ' pour la période ' || pv_periode );   
    dbms_output.put_line('*********************************');
    
    dbms_output.put_line('*********************************');
    dbms_output.put_line('Fin du lettrage : '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'));
    dbms_output.put_line('*********************************');      

EXCEPTION
  WHEN OTHERS THEN
    pn_retcode := 2;
    pv_errbuf  := 'ERREUR lettrage : ' || substr(SQLERRM, 1, 80);
    dbms_output.put_line(pv_errbuf);
ROLLBACK;
END;
/

SHOW ERRORS;

EXIT

