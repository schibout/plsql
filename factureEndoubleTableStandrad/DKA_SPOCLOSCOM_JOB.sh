CREATE OR REPLACE PACKAGE BODY dka_sglreflettrage_pkg IS

  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : DALKIA Oracle Applications
  -- NOM              : DKA_SGLREFLETTRAGE.pkb
  -- DESCRIPTION      : DKA_SGLREFLETTRAGE Package Body
  --
  -- AUTEUR           : C.DEFAUX (Capgemini)
  -- DATE DE CREATION : 23/02/2012
  -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 31/05/2012 JJA Correction de la sélection de la période par défaut
  -- 19/06/2012 JJA Correction de la selection des pièces contrepassées
  -- 18/07/2017 OBE artf2194894 : SPE177 : DKA_SGLREFLETTRAGE_JOB.sh : Amélioration des logs
  -- 03/06/2019 SFA artf07230964 : INC0299084 - SPE0177 - Ajout de référence de lettrage
  -- 07/01/2019 MTIA artf07230964 : INC0299084 - SPE0177 - Ajout de référence de lettrage - Provision
  -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
  -- -----------------------------------------------------------------------------

  -- -----------------------------------------------------------------------------
  -- Nom              : main
  -- Description      : effectue le lettrage GL
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --                    pv_societe
  --                    pv_uo
  --                    pv_periode
  --                    pv_folio
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  OUT VARCHAR2,
                 pn_retcode OUT NUMBER,
                 pv_societe IN VARCHAR2,
                 pv_uo      IN VARCHAR2,
                 pv_periode IN VARCHAR2,
                 pv_folio   IN VARCHAR2) IS
  
    vn_compteur     NUMBER;
    ln_pas          PLS_INTEGER;
    vv_periode_name VARCHAR2(10);
    vv_manuel CONSTANT VARCHAR2(10) := 'MANUEL';
    vv_cappo  CONSTANT VARCHAR2(10) := 'CAPPO';
    -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
    gn_gl_access_set_id NUMBER := fnd_profile.value('GL_ACCESS_SET_ID');
    
    CURSOR cur_lettrage IS
      SELECT gjl.je_header_id,
             gjl.je_line_num,
             gjh.je_source,
             gjl.attribute9,
             gjh.period_name,
             gcc.segment1,
             gcc.segment2
        FROM gl_je_lines          gjl,
             gl_je_lines_recon    gjlr, -- OBE
             gl_je_headers        gjh,
             gl_code_combinations gcc,
             fnd_flex_value_sets  ffvs,
             fnd_flex_values_vl   ffvv,
             --gl_sets_of_books       gsob,  -- OBE
             gl_periods             gp,
             gl_autoreverse_options gao,
             gl_access_sets         glas, -- OBE
             GL_ACCESS_SET_LEDGERS  glasl, -- OBE
             gl_ledgers             gll -- OBE
       WHERE gjlr.je_header_id(+) = gjl.je_header_id -- OBE
         AND gjlr.je_line_num(+) = gjl.je_line_num -- OBE
            --gjl.jgzz_recon_ref IS NULL --rg02         -- OBE
            --AND gjl.jgzz_recon_id IS NULL             -- OBE
         AND gjlr.jgzz_recon_ref IS NULL --rg02      -- OBE
         AND gjlr.jgzz_recon_id IS NULL -- OBE
         AND gcc.code_combination_id = gjl.code_combination_id
         AND gjh.je_header_id = gjl.je_header_id
         and gll.LEDGER_ID = GJH.ledger_id
         -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
         AND glas.access_set_id = gn_gl_access_set_id --fnd_profile.VALUE('GL_ACCESS_SET_ID') -- OBE
         AND glas.period_set_name = gp.period_set_name -- OBE
            --AND gsob.set_of_books_id = 1                                 -- OBE
            --AND gsob.period_set_name = gp.period_set_name                -- OBE
         AND gjh.period_name = vv_periode_name --rg01 arg4
         AND gjh.period_name = gp.period_name
         AND gcc.segment1 = nvl(pv_societe, gcc.segment1) --arg1
         AND gcc.segment2 = nvl(pv_uo, gcc.segment2) --arg2
         AND (gjl.attribute9 LIKE nvl(pv_folio, '%') OR
              gjl.attribute9 IS NULL) --arg3
            -- CPTE LETTRABLE
         AND ffvv.flex_value = gcc.segment3
         AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
         AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
          and substr(ffvv.compiled_value_attributes, 9, 1) = 'Y'
            -- PIECE CONTRPASSABLE
            --AND gao.set_of_books_id = gsob.set_of_books_id    -- OBE
         AND glasl.access_set_id = glas.access_set_id -- OBE
         AND glasl.ledger_id = gll.ledger_id -- OBE
         AND glasl.ledger_id = gjh.ledger_id 
         AND gao.criteria_set_id = gll.criteria_set_id --SFA  artf07230964  --AND gao.criteria_set_id  (+) = gll.criteria_set_id  -- OBE
         AND gao.je_category_name = gjh.je_category --SFA  artf07230964  -- AND gao.je_category_name (+) = gjh.je_category
         AND gao.autoreverse_flag = 'Y'; --SFA  artf07230964  -- AND gao.autoreverse_flag (+) = 'Y';
  
    CURSOR cur_lettrage_ctr IS
      SELECT gjh_ctr.je_header_id,
             gjl_ctr.je_line_num,
             --gjl_ctr.attribute9,
             --gjh.period_name,
             --gcc.segment1,
             --gcc.segment2,
             gjlr.jgzz_recon_ref
        FROM gl_je_lines          gjl,
             gl_je_headers        gjh,
             gl_je_headers        gjh_ctr,
             gl_je_lines          gjl_ctr,
             gl_je_lines_recon    gjlr, -- OBE
             gl_je_lines_recon    gjlr_ctr, -- OBE
             gl_code_combinations gcc,
             fnd_flex_value_sets  ffvs,
             fnd_flex_values_vl   ffvv,
             --gl_sets_of_books       gsob,     -- OBE
             gl_periods gp,
             --   gl_periods             gp_1,
             gl_autoreverse_options gao,
             gl_access_sets         glas, -- OBE
             GL_ACCESS_SET_LEDGERS  glasl, -- OBE              
             gl_ledgers             gll -- OBE
       WHERE
      --< OBE
       gjlr_ctr.jgzz_recon_ref IS NULL --rg02      
       AND gjlr_ctr.jgzz_recon_id IS NULL
       AND gjlr.jgzz_recon_ref IS NOT NULL
       AND gjlr.je_header_id = gjl.je_header_id
       AND gjlr.je_line_num = gjl.je_line_num
       AND gjlr_ctr.je_header_id = gjl_ctr.je_header_id
       AND gjlr_ctr.je_line_num = gjl_ctr.je_line_num
      /*gjl_ctr.jgzz_recon_ref IS NULL --rg02
      AND gjl_ctr.jgzz_recon_id IS NULL
      and gjl.jgzz_recon_ref IS NOT NULL */
      --> OBE
       AND gcc.code_combination_id = gjl.code_combination_id
       AND gjh.je_header_id = gjl.je_header_id
       -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
       AND glas.access_set_id =  gn_gl_access_set_id --fnd_profile.VALUE('GL_ACCESS_SET_ID') -- OBE
       and gll.LEDGER_ID = GJH.ledger_id
       AND glas.period_set_name = gp.period_set_name -- OBE
      --AND gsob.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID')  -- OBE
      --AND gsob.period_set_name = gp.period_set_name                     -- OBE
       AND gp.period_name = vv_periode_name --rg01 arg4
       AND gjh_ctr.period_name = gp.period_name
      --
      /*AND gp_1.period_num = decode(gp.period_num - 1,
                               0,
                               (SELECT number_per_fiscal_year
                                  FROM gl_period_types gpt
                                 WHERE gpt.period_type = gp.period_type),
                               gp.period_num - 1)
      AND gp_1.period_year =
      decode(gp.period_num - 1, 0, gp.period_year - 1, gp.period_year)*/
       AND gjh.period_name =
       (select gp_1.period_name
          from GL_PERIODS gp_1
         where GP_1.PERIOD_NUM =
              
               DECODE(GP.PERIOD_NUM - 1,
                      0,
                      (SELECT NUMBER_PER_FISCAL_YEAR
                         FROM GL_PERIOD_TYPES GPT
                        WHERE GPT.PERIOD_TYPE = GP.PERIOD_TYPE),
                      GP.PERIOD_NUM - 1)
           and GP_1.PERIOD_YEAR = DECODE(GP.PERIOD_NUM - 1,
                                         0,
                                         GP.PERIOD_YEAR - 1,
                                         GP.PERIOD_YEAR)
           AND GP_1.PERIOD_SET_NAME = GP.PERIOD_SET_NAME)
    --   AND gp_1.period_set_name = gp.period_set_name
      --  
       AND gcc.segment1 = nvl(pv_societe, gcc.segment1) --arg1
       AND gcc.segment2 = nvl(pv_uo, gcc.segment2) --arg2
       AND (gjl.attribute9 LIKE nvl(pv_folio, '%') OR gjl.attribute9 IS NULL) --arg3
      --
       AND gjh_ctr.reversed_je_header_id = gjh.je_header_id
       AND gjh_ctr.je_header_id = gjl_ctr.je_header_id
       AND gjl_ctr.je_line_num = gjl.je_line_num
      -- CPTE LETTRABLE
       AND ffvv.flex_value = gcc.segment3
       AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
        and substr(ffvv.compiled_value_attributes, 9, 1) = 'Y'
      -- PIECE CONTRPASSABLE
      --AND gao.set_of_books_id = gsob.set_of_books_id    -- OBE
       AND glasl.access_set_id = glas.access_set_id -- OBE
       AND glasl.ledger_id = gll.ledger_id -- OBE
       and glasl.ledger_id = gjh.LEDGER_ID
       AND gao.criteria_set_id = gll.criteria_set_id --SFA  artf07230964 AND gao.criteria_set_id  (+) = gll.criteria_set_id  -- OBE
       AND gao.je_category_name = gjh.je_category --SFA  artf07230964  --AND gao.je_category_name (+) = gjh.je_category 
       AND gao.autoreverse_flag = 'Y'; --SFA  artf07230964  -- AND gao.autoreverse_flag (+) = 'Y';
  
    -- 07/01/2019 MTIA artf07230964 : INC0299084 - SPE0177 - Ajout de référence de lettrage - Provision
    CURSOR cur_lettrage_prov IS
      select gjh.je_header_id     id_ori,
             gjh.je_source,
             gjl.JE_line_num      line_ori,
             gjh_ctr.je_header_id id_ctr,
             gjl_ctr.je_line_num  line_ctr,
             gjl.attribute9,
             gjh.period_name,
             gcc.segment1,
             gcc.segment2,
             gzz.jgzz_recon_ref
        from gl_je_batches gjb
        join gl_je_headers gjh
          on gjb.JE_BATCH_ID = gjh.JE_BATCH_ID
         and gjb.name not like '%LEGAL%'
         and gjh.PERIOD_NAME = vv_periode_name
        join gl_je_categories_vl jecat
          on gjh.je_category = jecat.je_category_name
         and jecat.user_je_category_name = 'Provision'
        join gl_je_lines gjl
          on gjl.JE_HEADER_ID = gjh.JE_HEADER_ID
        join gl_code_combinations_kfv gcc
          on gcc.CODE_COMBINATION_ID = gjl.CODE_COMBINATION_ID
        join gl_periods gp
          on gjh.period_name = gp.period_name
        join gl_periods gp_1
          on gp_1.period_num =
             decode(gp.period_num + 1, 13, 1, gp.period_num + 1)
         AND gp_1.period_year = decode(gp.period_num + 1,
                                       13,
                                       gp.period_year + 1,
                                       gp.period_year)
        join gl_access_sets glas
          -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
          on glas.access_set_id = gn_gl_access_set_id --fnd_profile.VALUE('GL_ACCESS_SET_ID')
         AND glas.period_set_name = gp.period_set_name
        join (select ffvt.flex_value_meaning,
                     substr(ffv.compiled_value_attributes, 7, 1) as Compte_Collectif,
                     substr(ffv.compiled_value_attributes, 9, 1) as Compte_Lettrable
                from fnd_flex_value_sets ffvs,
                     fnd_flex_values_vl  ffv,
                     fnd_flex_values_tl  ffvt
               where flex_value_set_name = 'DAOPCCF_LOCAL'
                 AND ffvs.flex_value_set_id = ffv.FLEX_VALUE_SET_ID
                 and ffv.flex_value_id = ffvt.flex_value_id
                 and ffvt.language = 'F'
                 and substr(ffv.compiled_value_attributes, 9, 1) = 'Y') flex
          on gcc.segment3 = flex.flex_value_meaning
        join gl_je_lines_recon gzz
          on gzz.JE_HEADER_ID = gjl.JE_HEADER_ID
         and gzz.JE_LINE_NUM = gjl.JE_LINE_NUM
        join gl_je_batches gjb_ctr
          on gjb.NAME = gjb_ctr.NAME
         and gjb.RUNNING_TOTAL_DR = gjb_ctr.RUNNING_TOTAL_DR
         and gjb_ctr.DEFAULT_PERIOD_NAME = gp_1.period_name
         and gjb.DEFAULT_PERIOD_NAME <> gjb_ctr.DEFAULT_PERIOD_NAME
        join gl_je_headers gjh_ctr
          on gjb_ctr.JE_BATCH_ID = gjh_ctr.JE_BATCH_ID
         and gjh.ledger_id = gjh_ctr.ledger_id
        join gl_je_lines gjl_ctr
          on gjl_ctr.JE_HEADER_ID = gjh_ctr.JE_HEADER_ID
         and gjl.je_line_num = gjl_ctr.je_line_num
        join gl_je_lines_recon gzz_ctr
          on gzz_ctr.JE_HEADER_ID = gjl_ctr.JE_HEADER_ID
         and gzz_ctr.JE_LINE_NUM = gjl_ctr.JE_LINE_NUM
         and gzz_ctr.je_line_num = gzz.je_line_num
       where gcc.segment1 = nvl(pv_societe, gcc.segment1) --arg1
         AND gcc.segment2 = nvl(pv_uo, gcc.segment2) --arg2
         AND (gjl.attribute9 LIKE nvl(pv_folio, '%') OR
             gjl.attribute9 IS NULL);
  
    TYPE t_cur_lettrage_tab IS TABLE OF cur_lettrage%ROWTYPE;
    TYPE t_cur_lettrage_ctr_tab IS TABLE OF cur_lettrage_ctr%ROWTYPE;
    TYPE t_cur_lettrage_prov_tab IS TABLE OF cur_lettrage_prov%ROWTYPE;
  
    cur_lettrage_tab      t_cur_lettrage_tab;
    cur_lettrage_ctr_tab  t_cur_lettrage_ctr_tab;
    cur_lettrage_prov_tab t_cur_lettrage_prov_tab;
    vv_ref_lettrage       gl_je_lines_recon.jgzz_recon_ref%TYPE;
    -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
    c_limit   CONSTANT PLS_INTEGER DEFAULT 1000;
    e_periode EXCEPTION;
  
  BEGIN
    dka_tools_pkg.put_out_header;
  
    vn_compteur := 0;
    ln_pas      := 10000;
  
    vv_periode_name := pv_periode;
  
    IF vv_periode_name IS NULL THEN
    
      BEGIN
        SELECT gp.period_name
          INTO vv_periode_name
          FROM --gl_sets_of_books gsob, --OBE
               gl_access_sets glas, --OBE
               gl_periods     gp
         -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
         WHERE glas.access_set_id = gn_gl_access_set_id --fnd_profile.VALUE('GL_ACCESS_SET_ID') -- OBE
           AND glas.period_set_name = gp.period_set_name
              --gsob.set_of_books_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID')         --OBE
              --AND gsob.period_set_name = gp.period_set_name                        --OBE
           AND trunc(SYSDATE) BETWEEN gp.start_date AND gp.end_date;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          dka_tools_pkg.put_log_message('Aucune période trouvée');
          RAISE e_periode;
      END;
    
    END IF;
  
    dka_tools_pkg.put_log_message('La période de lettrage est : ' ||
                                  vv_periode_name);
  
    dka_tools_pkg.put_log_message('**********************************************************************');
    dka_tools_pkg.put_log_message('Début du lettrage : écritures contrepassées sur la période précédentes');
    dka_tools_pkg.put_log_message('**********************************************************************');
    
    -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
    dka_tools_pkg.put_log_message('Début : ' || TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI'));
  
    OPEN cur_lettrage_ctr;
    
    LOOP
      FETCH cur_lettrage_ctr BULK COLLECT INTO cur_lettrage_ctr_tab LIMIT c_limit;
      EXIT WHEN cur_lettrage_ctr_tab.COUNT = 0;
      
      dka_tools_pkg.put_debug_message('cur_lettrage_ctr_tab.COUNT : ' || cur_lettrage_ctr_tab.COUNT);
      
      --
      FOR i IN cur_lettrage_ctr_tab.first .. cur_lettrage_ctr_tab.last LOOP
      
        --------------------------------
        -- Insertion du lettrage rg03 --
        --------------------------------
        vn_compteur := vn_compteur + 1;
      
        UPDATE --gl_je_lines --OBE
               gl_je_lines_recon --OBE
           SET jgzz_recon_ref    = cur_lettrage_ctr_tab(i).jgzz_recon_ref,
               LAST_UPDATE_DATE  = sysdate,
               LAST_UPDATED_BY   = fnd_profile.value('USER_ID'),
               LAST_UPDATE_LOGIN = fnd_profile.value('LOGIN_ID')
         WHERE je_header_id = cur_lettrage_ctr_tab(i).je_header_id
           AND je_line_num = cur_lettrage_ctr_tab(i).je_line_num;
      
        dka_tools_pkg.put_debug_message('lettrage effectué :' || cur_lettrage_ctr_tab(i).jgzz_recon_ref ||
                                        ' | je_header_id : ' || cur_lettrage_ctr_tab(i).je_header_id ||
                                        ' | je_line_num : ' || cur_lettrage_ctr_tab(i).je_line_num); -- OBE artf2194894
      
        IF (MOD(vn_compteur, ln_pas) = 0) THEN
          dka_tools_pkg.put_log_message('Etape n° ' ||
                                        vn_compteur / ln_pas || 'avec ' ||
                                        vn_compteur || 'lignes lettrées');
          COMMIT;
        END IF;
      END LOOP;
    
      --Commit!
      COMMIT;
    END LOOP;
      
    CLOSE cur_lettrage_ctr;
    
    dka_tools_pkg.put_log_message('Fin : ' || TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI'));

  
    dka_tools_pkg.put_log_message('*************************************************************************');
    dka_tools_pkg.put_log_message('Début du lettrage : écritures contrepassables sur la période en paramètre');
    dka_tools_pkg.put_log_message('*************************************************************************');
    
    -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
    dka_tools_pkg.put_log_message('Début : ' || TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI'));
      
    OPEN cur_lettrage;
    LOOP
      
      FETCH cur_lettrage BULK COLLECT INTO cur_lettrage_tab LIMIT c_limit;
      EXIT WHEN cur_lettrage_tab.COUNT = 0;
      
      dka_tools_pkg.put_debug_message('cur_lettrage_tab.COUNT : ' || cur_lettrage_tab.COUNT);

      --
      FOR i IN cur_lettrage_tab.first .. cur_lettrage_tab.last LOOP
      
        --------------------------------
        -- Insertion du lettrage rg03 --
        --------------------------------
        vn_compteur     := vn_compteur + 1;
        vv_ref_lettrage := null;
      
        IF cur_lettrage_tab(i).attribute9 IS NULL AND cur_lettrage_tab(i).je_source = 'Manual' THEN
        
          vv_ref_lettrage := cur_lettrage_tab(i).segment1 || '_' || cur_lettrage_tab(i).segment2 || '_' ||
                              vv_manuel || '_' || cur_lettrage_tab(i).period_name;
        
        ELSIF cur_lettrage_tab(i).attribute9 IS NULL THEN
        
          vv_ref_lettrage := cur_lettrage_tab(i).segment1 || '_' || cur_lettrage_tab(i).segment2 || '_' ||
                              vv_cappo || '_' || cur_lettrage_tab(i).period_name;
        
        ELSE
        
          vv_ref_lettrage := cur_lettrage_tab(i).segment1 || '_' || cur_lettrage_tab(i).segment2 || '_' || cur_lettrage_tab(i).attribute9 || '_' || cur_lettrage_tab(i).period_name;
        
        END IF;
      
        UPDATE --gl_je_lines --OBE
               gl_je_lines_recon --OBE
           SET jgzz_recon_ref    = vv_ref_lettrage,
               LAST_UPDATE_DATE  = sysdate,
               LAST_UPDATED_BY   = fnd_profile.value('USER_ID'),
               LAST_UPDATE_LOGIN = fnd_profile.value('LOGIN_ID')
         WHERE je_header_id = cur_lettrage_tab(i).je_header_id
           AND je_line_num = cur_lettrage_tab(i).je_line_num;
      
        dka_tools_pkg.put_debug_message('lettrage effectué :' ||
                                        vv_ref_lettrage ||
                                        ' | je_header_id : ' || cur_lettrage_tab(i).je_header_id ||
                                        ' | je_line_num : ' || cur_lettrage_tab(i).je_line_num); -- OBE artf2194894
      
        IF (MOD(vn_compteur, ln_pas) = 0) THEN
          dka_tools_pkg.put_log_message('Etape n° ' ||
                                        vn_compteur / ln_pas || 'avec ' ||
                                        vn_compteur || 'lignes lettrées');
          COMMIT;
        END IF;
      END LOOP;
    
      --Commit!
      COMMIT;
    
    END LOOP;
    CLOSE cur_lettrage;
    
    dka_tools_pkg.put_log_message('Fin : ' || TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI'));
  
    -- 07/01/2019 MTIA artf07230964 : INC0299084 - SPE0177 - Ajout de référence de lettrage - Provision
    dka_tools_pkg.put_log_message('*****************************************************************************************************');
    dka_tools_pkg.put_log_message('Début du lettrage : écritures contrepassées - contrepassables sur la période en paramètre (Provision)');
    dka_tools_pkg.put_log_message('*****************************************************************************************************');

    -- 31/03/2021 NBO artf07446888 : INC0521937 - SPE177 - Correctif traitement d'ajout de référence de lettrage qui n'aboutit pas (ticket INC0417667 fermé à tort)
    dka_tools_pkg.put_log_message('Début : ' || TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI'));
    
  
    OPEN cur_lettrage_prov;
    LOOP
      FETCH cur_lettrage_prov BULK COLLECT INTO cur_lettrage_prov_tab LIMIT c_limit;
      EXIT WHEN cur_lettrage_prov_tab.COUNT = 0;
      
      dka_tools_pkg.put_debug_message('cur_lettrage_tab.COUNT : ' || cur_lettrage_tab.COUNT);

      --
      FOR i IN cur_lettrage_prov_tab.first .. cur_lettrage_prov_tab.last LOOP
      
        --------------------------------
        -- Insertion du lettrage rg03 --
        --------------------------------
        vn_compteur     := vn_compteur + 1;
        vv_ref_lettrage := null;
      
        IF cur_lettrage_prov_tab(i).attribute9 IS NULL AND cur_lettrage_prov_tab(i)
           .je_source = 'Manual' THEN
        
          vv_ref_lettrage := cur_lettrage_prov_tab(i).segment1 || '_' || cur_lettrage_prov_tab(i).segment2 || '_' ||
                              vv_manuel || '_' || cur_lettrage_prov_tab(i).period_name;
        
        ELSIF cur_lettrage_prov_tab(i).attribute9 IS NULL THEN
        
          vv_ref_lettrage := cur_lettrage_prov_tab(i).segment1 || '_' || cur_lettrage_prov_tab(i).segment2 || '_' ||
                              vv_cappo || '_' || cur_lettrage_prov_tab(i).period_name;
        
        ELSE
        
          vv_ref_lettrage := cur_lettrage_prov_tab(i).segment1 || '_' || cur_lettrage_prov_tab(i).segment2 || '_' || cur_lettrage_prov_tab(i).attribute9 || '_' || cur_lettrage_prov_tab(i).period_name;
        
        END IF;
      
        UPDATE --gl_je_lines --OBE
               gl_je_lines_recon --OBE
           SET jgzz_recon_ref    = vv_ref_lettrage,
               LAST_UPDATE_DATE  = sysdate,
               LAST_UPDATED_BY   = fnd_profile.value('USER_ID'),
               LAST_UPDATE_LOGIN = fnd_profile.value('LOGIN_ID')
         WHERE je_header_id = cur_lettrage_prov_tab(i).id_ori
           AND je_line_num = cur_lettrage_prov_tab(i).line_ori;
      
        UPDATE --gl_je_lines --OBE
               gl_je_lines_recon --OBE
           SET jgzz_recon_ref    = vv_ref_lettrage,
               LAST_UPDATE_DATE  = sysdate,
               LAST_UPDATED_BY   = fnd_profile.value('USER_ID'),
               LAST_UPDATE_LOGIN = fnd_profile.value('LOGIN_ID')
         WHERE je_header_id = cur_lettrage_prov_tab(i).id_ctr
           AND je_line_num = cur_lettrage_prov_tab(i).line_ctr;
      
        dka_tools_pkg.put_debug_message('lettrage effectué :' ||
                                        vv_ref_lettrage ||
                                        ' | je_header_id : ' || cur_lettrage_prov_tab(i).id_ori ||
                                        ' | je_line_num : ' || cur_lettrage_prov_tab(i).line_ori); -- OBE artf2194894
      
        dka_tools_pkg.put_debug_message('lettrage effectué :' ||
                                        vv_ref_lettrage ||
                                        ' | je_header_id : ' || cur_lettrage_prov_tab(i).id_ctr ||
                                        ' | je_line_num : ' || cur_lettrage_prov_tab(i).line_ctr);
      
        IF (MOD(vn_compteur, ln_pas) = 0) THEN
          dka_tools_pkg.put_log_message('Etape n° ' ||
                                        vn_compteur / ln_pas || 'avec ' ||
                                        vn_compteur || 'lignes lettrées');
          COMMIT;
        END IF;
      END LOOP;
    
      --Commit!
      COMMIT;
    END LOOP;
      
    CLOSE cur_lettrage_prov;
   
    dka_tools_pkg.put_log_message('Fin : ' || TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI'));
  
    IF vn_compteur = 0 THEN
      pn_retcode := 1;
      dka_tools_pkg.put_log_message('Aucune ligne traité');
    END IF;
  
    dka_tools_pkg.put_outdebug_message('*********************************');
    dka_tools_pkg.put_outdebug_message('Fin de lettrage');
    dka_tools_pkg.put_outdebug_message('Les paramètres d''entrés sont :');
    dka_tools_pkg.put_outdebug_message('Société :' ||
                                       nvl(pv_societe, 'non renseigné'));
    dka_tools_pkg.put_outdebug_message('UO :' ||
                                       nvl(pv_uo, 'non renseigné'));
    dka_tools_pkg.put_outdebug_message('Période :' ||
                                       nvl(vv_periode_name,
                                           'non renseigné'));
    dka_tools_pkg.put_outdebug_message('Folio :' ||
                                       nvl(pv_folio, 'non renseigné'));
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('Nombre de lettrages effectués : ' ||
                                       vn_compteur);
    dka_tools_pkg.put_outdebug_message('*********************************');
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'ERREUR lettrage : ' || substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_log_message(pv_errbuf);
      ROLLBACK;
  END main;

END dka_sglreflettrage_pkg;
/
SHOW ERRORS;

EXIT
