
     -- -----------------------------------------------------------------------------
     -- $$
     -- Capgemini
     -- PROJET           : DALKIA Oracle Applications
     -- NOM              : DKA_APUREMENT_PASSE_PRE_CUTOFF.sql
     -- DESCRIPTION      : Mise à jour des lettrage pre CUTOFF (avant le 31/12/2004)
     --
     -- AUTEUR           : C.DEFAUX (Capgemini)
     -- DATE DE CREATION : 27/02/2012
     -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
     -- ARGUMENT         : Mettre en paramètre l'année à lettrer
     -- -----------------------------------------------------------------------------
     -- -----------------------------------------------------------------------------
     -- HISTORIQUE DES MODIFICATIONS
     -- Date       Qui Description
     -- ---------- --- --------------------------------------------------------------
     -- 01/07/2012 JJA Extension toutes les catégories de pièces
     -- -----------------------------------------------------------------------------


SET HEADING ON
SET PAGESIZE 500
SET LINESIZE 150
SET SERVEROUTPUT ON SIZE 1000000
SET TRIMSPOOL ON

DECLARE
          
          ln_pas         CONSTANT PLS_INTEGER := 10000; 
          ln_cpt_update           PLS_INTEGER; 
          ln_cpt_total            PLS_INTEGER;
          ln_cpt                  PLS_INTEGER;
          pn_retcode Pls_Integer;
          pv_errbuf Varchar2(1000);
     
     
     BEGIN
     ln_cpt_update := 0;
     ln_cpt_total :=0;
     ln_cpt :=0;
     
     dbms_output.put_line('*********************************');
     dbms_output.put_line('Début de la procédure : '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'));
     dbms_output.put_line('*********************************');
     
     dbms_output.put_line('*********************************');
     dbms_output.put_line('Remise à null de jgzz_recon_ref où jgzz_recon_id est null');
     dbms_output.put_line('*********************************');

   LOOP
     -- Lettrage des lignes pre CUTOFF          
     UPDATE --GL_JE_LINES --OBE
     gl_je_lines_recon    --OBE
     SET    jgzz_recon_ref = null
     WHERE  
      rowid in (SELECT  gjl.ROWID
                 FROM   gl_je_lines          gjl,
                        gl_je_headers        gjh,
                        gl_je_lines_recon    gjlr,   --OBE
                        GL_ACCESS_SET_LEDGERS glasl, --OBE
                        fnd_flex_value_sets  ffvs,
                        fnd_flex_values_vl   ffvv,
                        gl_code_combinations gcc
                 WHERE  gjh.je_header_id = gjl.je_header_id
                        AND gcc.code_combination_id = gjl.code_combination_id
                        AND gjlr.je_header_id(+) = gjl.je_header_id -- OBE
                        AND gjlr.je_line_num(+) = gjl.je_line_num   -- OBE
                        AND gjlr.jgzz_recon_ref is not null         -- OBE
                        AND gjlr.jgzz_recon_id  is null             -- OBE          
                        --AND gjl.jgzz_recon_ref is not null        -- OBE
                        --AND gjl.jgzz_recon_id is null             -- OBE
                        AND gjh.default_effective_date <= to_date('31/12/2004','DD/MM/YYYY')
                        AND gjh.currency_code = 'EUR'
                        AND glasl.access_set_id = fnd_profile.VALUE('GL_ACCESS_SET_ID') -- OBE
                        AND gjh.ledger_id       = glasl.ledger_id                       -- OBE
                        --AND gjh.set_of_books_id = 1                                   -- OBE
                        --and gjh.je_category = '43' -- jja 01/07/2012
                        -- CPTE LETTRABLE
                        AND ffvv.flex_value = gcc.segment3
                        AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
                        AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                        AND ffvv.compiled_value_attributes LIKE
                        '%' || chr(10) || '%' || chr(10) || '%' || chr(10) || 'Y' || chr(10) || '%'
                        AND rownum <= ln_pas)
       ;
      ln_cpt:=ln_cpt+1;
               
     ln_cpt_update := SQL%rowcount;
     
     ln_cpt_total := ln_cpt_total + ln_cpt_update;
     
     dbms_output.put_line('Etape '|| ln_cpt ||'avec '||ln_cpt_total||' lignes lettrées');
     
     COMMIT;
               
     exit when ln_cpt_update < ln_pas;
          
  END LOOP;
          
                    
          IF ln_cpt=0 THEN
          Pn_Retcode := 1;
          END IF;
          dbms_output.put_line('*********************************');
          dbms_output.put_line('Nombre de remise à null pour les écritures pre CUTOFF : '||ln_cpt_total);
          dbms_output.put_line('*********************************');
          
          dbms_output.put_line('*********************************');
          dbms_output.put_line('Fin de la procédure : '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'));
          dbms_output.put_line('*********************************');
          
       EXCEPTION 
       WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR lettrage : ' || Substr(SQLERRM, 1, 80);
            dbms_output.put_line(Pv_Errbuf);
     
     END main;
     
/

SHOW ERRORS;

EXIT