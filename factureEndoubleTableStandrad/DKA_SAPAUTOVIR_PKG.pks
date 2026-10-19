CREATE OR REPLACE PACKAGE BODY APPS.DKA_IEOAPSAT01_APIMP_PKG AS
--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IEOAPSAT01_APIMP_PKG.pkb 
-- DESCRIPTION       : DKA_IEOAPSAT01_APIMP_PKG package body : 
---
--- AUTEUR           : J.JARDEZ (CG)
--- DATE DE CREATION : 17/07/2012
--- DOC. ASSOCIEE    : 
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
--- 17/07/2012 JJA Création
--- 15/10/2012 BCO DPE20120100: Ajout des champs société et région de la banque.
--- 05/11/2012 JJA Correction de get_code_agora
--- 06/12/2012 JJA Correction de get_code_agora (BD SOCIETE) + modification du champ banque
--- 15/11/2012 JJA DGE20120044 :création de nouvelles Uos
--- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
--- 02/02/2017 RBE artf2090995,artf2092291 
--  25/12/2023 ARA EDB295 Lot3 - Ajout d¿une nouvelle campagne de règlement / Remboursements client
--  04/12/2024 ARA EDB295 Lot1A
--------------------------------------------------------------------------------------------------------------- 

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gv_separateur CONSTANT   VARCHAR2(1)  := ';';
gv_ext        CONSTANT   VARCHAR2(10) := '.txt';

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

----------------------------------------------------------------
--  Nom           : TRANSLATE_TEXT
--  Description   : fonction qui va supprimer les caractères non valide
--
--  PARAMETRES :
--     pv_text               Entrée
--     pv_caractere_autorise Entrée
-- VALEUR RETOURNEE :
--     Description       : VARCHAR2
--     Valeurs possibles : text
----------------------------------------------------------------
FUNCTION translate_text (pv_text                VARCHAR2,
                         pv_caractere_autorise  VARCHAR2) RETURN VARCHAR2 IS

 lv_text VARCHAR2(4000);
 vv_step VARCHAR2(500);    
                     
BEGIN
  vv_step := '001 : TRANSLATE_TEXT début';
  --dka_tools_pkg.put_debug_message(vv_step);
  
  vv_step := '002 : paramètres : '||pv_text||'/'||pv_caractere_autorise;
  --dka_tools_pkg.put_debug_message(vv_step);
  
  lv_text := translate(pv_text,
                       translate(' '||REPLACE(pv_text,' '),
                                 pv_caractere_autorise,
                                 ' '),
                       ' ');  
  
  vv_step := '999 : TRANSLATE_TEXT fin';
  --dka_tools_pkg.put_debug_message(vv_step);
  
  return lv_text;
  
EXCEPTION
 WHEN OTHERS THEN
  --dka_tools_pkg.put_debug_message(vv_step || ' : ' || SQLERRM);
  return pv_text;
END translate_text;                         

/* RBE MigR12 fonction n'est plus utiisée.
----------------------------------------------------------------
--  Nom           : GET_CODE_AGORA
--  Description   : fonction qui va retourner le code AGORA
--
--  PARAMETRES :
--     pv_type               Entrée
--     pv_division           Entrée
--     pv_region             Entrée
--     pv_societe            Entrée
--     pv_default            Entrée
-- VALEUR RETOURNEE :
--     Description       : VARCHAR2
--     Valeurs possibles : text
----------------------------------------------------------------
FUNCTION get_code_agora (pv_type                VARCHAR2,
                         pv_division            VARCHAR2,
                         pv_region              VARCHAR2,
                         pv_societe             VARCHAR2,
                         pv_default             VARCHAR2) RETURN VARCHAR2 IS

 vv_step          VARCHAR2(500);
 
 CURSOR c_select_agora(cv_code_conso VARCHAR2) IS  
  SELECT dsl.param1_value
  FROM
   dka_stransco_lines dsl,
   dka_stransco_headers dsh
  WHERE    
    dsh.set_id = dsl.set_id
    AND trunc(SYSDATE) <= trunc(nvl(dsh.inactive_date,SYSDATE))
    AND (trunc(SYSDATE) between trunc(dsl.start_date)
                           AND trunc(nvl(dsl.end_date,SYSDATE))
       )
    AND dsh.set_name = 'DKA_STE_AGORA_CONSO'
    AND dsl.return_value = cv_code_conso
    AND dsl.enable = 'Y';              
  
 CURSOR c_select_conso(cv_region   VARCHAR2,
                       cv_societe  VARCHAR2) IS
  SELECT 
   code_conso,segmented_company
  FROM
   (SELECT ffvv.flex_value societe,
           'DCW' region,
           ffvv.attribute3 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute3 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
    UNION
    SELECT ffvv.flex_value societe,
           'DLS' region,
           ffvv.attribute4 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute4 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
    UNION
    SELECT ffvv.flex_value societe,
           'DMS' region,
           ffvv.attribute5 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute5 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
    UNION
    SELECT ffvv.flex_value societe,
           'DRW' region,
           ffvv.attribute6 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute6 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
    UNION
    SELECT ffvv.flex_value societe,
           'DSW' region,
           ffvv.attribute7 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute7 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
    UNION
    SELECT ffvv.flex_value societe,
           'GFK' region,
           ffvv.attribute8 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute8 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
     --> JJA 15/11/2012
    UNION
    SELECT ffvv.flex_value societe,
           'DEW' region,
           ffvv.attribute11 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute11 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
    UNION
    SELECT ffvv.flex_value societe,
           'DNA' region,
           ffvv.attribute12 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute12 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value)
    UNION
    SELECT ffvv.flex_value societe,
           'DOS' region,
           ffvv.attribute13 code_conso,
           dbc.segmented_company
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv,
           dka_bdste_comptable dbc
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.attribute13 IS NOT NULL
       AND dbc.company_code = ffvv.flex_value  
       AND dbc.effective_date = (SELECT MAX (dbc_d.effective_date)
                                 FROM dka_bdste_comptable dbc_d
                                 WHERE dbc_d.company_code = ffvv.flex_value) 
       --< JJA 15/11/2012
    ) v
   WHERE 
        v.societe = cv_societe
    and v.region = cv_region; 
 
 CURSOR c_db_select_conso(cv_societe  VARCHAR2) IS
   SELECT dbdg.consumption_code,dbdg.company_type
   FROM dka_bdste_donnees_gen dbdg
   WHERE
    dbdg.company_code = cv_societe
    AND dbdg.effective_date = ( SELECT MAX(d.effective_date)
                                FROM dka_bdste_donnees_gen d
                                WHERE d.company_code = dbdg.company_code);
                                
  CURSOR c_select_carat(cv_societe  VARCHAR2,
                        cv_set_name VARCHAR2) IS
    SELECT ffvv.attribute1 code_conso
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvv
     WHERE ffvs.flex_value_set_name = cv_set_name
       AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
       AND ffvv.enabled_flag = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.start_date_active,SYSDATE) 
                       AND nvl(ffvv.end_date_active,SYSDATE)
       AND ffvv.flex_value = cv_societe;                            
 
 --
 lv_code_conso       fnd_flex_values_vl.attribute1%TYPE;
 lv_code_conso_bd    fnd_flex_values_vl.attribute1%TYPE;
 lv_code_conso_cible fnd_flex_values_vl.attribute1%TYPE;
 l_code_agora        VARCHAR2(50);
 lv_segmente         dka_bdste_comptable.segmented_company%TYPE;
 lv_gere             dka_bdste_donnees_gen.company_type%TYPE;          
                     
BEGIN
  vv_step := '001 : GET_CODE_AGORA début';
  dka_tools_pkg.put_debug_message(vv_step);
  
  vv_step := '002 : paramètres : '||pv_type||'/'||pv_division||'/'||pv_region||'/'||pv_societe;
  dka_tools_pkg.put_debug_message(vv_step);
  
  vv_step := '003 : récupération des valeurs';
  dka_tools_pkg.put_debug_message(vv_step);
  
  --CODE CONSO
  OPEN c_select_conso(pv_region,pv_societe);
  FETCH c_select_conso INTO lv_code_conso,lv_segmente;
  CLOSE c_select_conso;
  
  vv_step := '004 : code conso JDV / SEGMENTEE : '||lv_code_conso||'/'||lv_segmente;
  dka_tools_pkg.put_debug_message(vv_step);
  
  --CODE CONSO DB
  OPEN c_db_select_conso(pv_societe);
  FETCH c_db_select_conso INTO lv_code_conso_bd,lv_gere;
  CLOSE c_db_select_conso;
  
  vv_step := '005 : code conso BD / GEREE : '||lv_code_conso_bd||'/'||lv_gere;
  dka_tools_pkg.put_debug_message(vv_step);
  
  vv_step := '006 : Début condition';
  dka_tools_pkg.put_debug_message(vv_step);
  IF pv_division = 'DK' THEN
    
    IF pv_type IS NULL THEN
      
      IF lv_segmente = 'N' THEN
        lv_code_conso_cible := lv_code_conso_bd;
      ELSE
        lv_code_conso_cible := lv_code_conso;
      END IF;
       
    ELSIF pv_type = 'GROUPE' THEN
      --RG GROUPE
      --1)
      IF nvl(lv_segmente,'#') = 'O' THEN
        lv_code_conso_cible := lv_code_conso;
      --2)
      ELSIF nvl(lv_segmente,'#') = 'N' AND nvl(lv_gere,-1) IN (0,1) --05/11/2012 JJA
      THEN
        lv_code_conso_cible := lv_code_conso_bd;
        --3)
        IF  lv_code_conso_cible IS NULL THEN
          OPEN c_select_carat(pv_societe,'DAOPCCF_COMPLEMENT');
          FETCH c_select_carat INTO lv_code_conso_cible;
          CLOSE c_select_carat;
        END IF;--fin 3)
      ELSE
        OPEN c_select_carat(pv_societe,'DAOPCCF_COMPLEMENT');
        FETCH c_select_carat INTO lv_code_conso_cible;
        CLOSE c_select_carat;
      END IF; --fin 1) et 2)
    
    END IF;  
  
  ELSIF pv_division IN ('VT','VP') THEN
  
    IF pv_type is null then
      
      lv_code_conso_cible := lv_code_conso_bd;
    
    ELSIF pv_type = 'GROUPE' THEN
    
      IF lv_gere in ('0','1') THEN
        lv_code_conso_cible := lv_code_conso_bd;
      ELSE
      
        IF pv_division = 'VP' THEN
          OPEN c_select_carat(pv_societe,'VPOPCCF_COMPLEMENT');
          FETCH c_select_carat INTO lv_code_conso_cible;
          CLOSE c_select_carat;
        ELSIF pv_division = 'VT' THEN
          OPEN c_select_carat(pv_societe,'VTOPCCF_COMPLEMENT');
          FETCH c_select_carat INTO lv_code_conso_cible;
          CLOSE c_select_carat;
        END IF;
        
      END IF; --lv_gere
    END IF; --pv_type
  END IF; --pv_division
  
  vv_step := '007 : code conso cible : '||lv_code_conso_cible;
  dka_tools_pkg.put_debug_message(vv_step);
  
  OPEN c_select_agora(lv_code_conso_cible);
  FETCH c_select_agora INTO l_code_agora;
  
  vv_step := '008 : Controle de valeur multiple';
  dka_tools_pkg.put_debug_message(vv_step);
  IF l_code_agora IS NOT NULL THEN
   FETCH c_select_agora INTO l_code_agora;
   IF c_select_agora%FOUND THEN
    vv_step := '009 : valeur multiple';
    dka_tools_pkg.put_debug_message(vv_step);
    l_code_agora := pv_default;
   END IF;
  END IF;
  
  CLOSE c_select_agora;
  
  vv_step := '010 : code agora cible : '||l_code_agora;
  dka_tools_pkg.put_debug_message(vv_step);
  
  vv_step := '999 : GET_CODE_AGORA fin';
  dka_tools_pkg.put_debug_message(vv_step);
  
  RETURN nvl(l_code_agora,pv_default);
  
EXCEPTION
 WHEN OTHERS THEN
  dka_tools_pkg.put_debug_message(vv_step || ' : ' || SQLERRM);
  RAISE;
END get_code_agora;  
*/
--Fin RBE MigR12

----------------------------------------------------------------
--  Nom           : CREATE_AP_IMPORT_FILE
--  Description   : Procédure qui génère le fichier AP_IMPORT 
--
--  PARAMETRES :
--     pv_errbuf          Sortie
--     pn_retcode         Sortie
--     pv_type_campagne   Entrée
--     pv_code_entite     Entrée
-- VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------
PROCEDURE create_ap_import_file (
    pv_errbuf          IN  OUT VARCHAR2,
    pn_retcode             OUT NUMBER,
    pn_reprise         IN      VARCHAR2,
    pv_entite          IN      VARCHAR2) IS   
       
  CURSOR cur_entete (cv_entite DKA_IEOAPSAT01_APIMP_HDR.DIV_CODE%TYPE) IS
    SELECT *             
    FROM DKA_IEOAPSAT01_APIMP_HDR dih
    WHERE STATUS = 'NEW'
     AND DIV_CODE = cv_entite 
  ;
  
  CURSOR cur_ligne (pn_header_id DKA_IEOAPSAT01_APIMP_LINE.header_id%TYPE) IS
    SELECT *             
    FROM DKA_IEOAPSAT01_APIMP_LINE dil
    WHERE header_id = pn_header_id
  ;
  
  CURSOR c_param IS
  SELECT lookup_code,DESCRIPTION
  FROM fnd_lookup_values_vl flvv
  WHERE
   flvv.lookup_type = 'DKA_AP_IMPORT'
   AND flvv.lookup_code LIKE 'FILE_LAYOUT%'
  ORDER BY lookup_code DESC;
  
  vv_value_date      VARCHAR2(10);
  vv_transactiondate VARCHAR2(10);
  vv_amount          VARCHAR2(17);
  vv_creation_date   VARCHAR2(10);
  vn_request_id      NUMBER;
  
  File_Handle           utl_file.file_type;
  vv_FILE_LAYOUT        VARCHAR2(2000);
  vv_file_name          VARCHAR2(100);
  vv_buffer             VARCHAR2(4000);
  
  vn_nb_lignes          PLS_INTEGER;
  vn_nb_lignes_tot      PLS_INTEGER;
  vn_nb_fichier         PLS_INTEGER;
  
  vv_step               VARCHAR2(500);
  
  
BEGIN
 pv_errbuf  := NULL;
 pn_retcode := 0;
 
 -----  Initialisation des variables -----
 vv_step := '001 : Initialisation des variables';
 dka_tools_pkg.put_debug_message(vv_step);
 vn_nb_lignes     := 0;
 vn_nb_lignes_tot := 0;
 vn_nb_fichier    := 0;
 
 -----  Récupération des constantes -----
 vv_step := '002 : Récupération des constantes';
 dka_tools_pkg.put_debug_message(vv_step);

 vv_step := '003 : Parametres inconnus : ';
 FOR l IN c_param LOOP    
  
  CASE 
   WHEN l.lookup_code LIKE 'FILE_LAYOUT%'  THEN vv_FILE_LAYOUT := l.DESCRIPTION || gv_separateur || vv_FILE_LAYOUT;        
   ELSE vv_step := vv_step || ' ' || l.lookup_code || '/' || l.DESCRIPTION;
  END CASE;
  
 END LOOP;
 
 --On retire le gv_separateur ;
 vv_FILE_LAYOUT := substr(vv_FILE_LAYOUT,1,length(vv_FILE_LAYOUT)-length(gv_separateur)) ||CHR(13);
 
 dka_tools_pkg.put_debug_message(vv_step);
 
 
 -----  Parcours des entêtes -----
 vv_step := '004 : Parcours des entêtes';
 dka_tools_pkg.put_debug_message(vv_step);   
  
 FOR h IN cur_entete(pv_entite) LOOP
       
   vn_nb_lignes := 0;
   
   --REQUEST_ID
   vv_step := '005 : Détermination du request_id';
   dka_tools_pkg.put_debug_message(vv_step);           
   IF pn_reprise = 'OUI' THEN
    vn_request_id := fnd_global.CONC_REQUEST_ID;
   ELSE
    vn_request_id := h.reg_request_id;
   END IF;
     
   vv_file_name := h.div_code || '_' ||
                   h.code_banque || '-' ||
                   h.societe ||
                   h.region ||
                   h.type_campagne  || '-' ||
                   to_char(h.creation_date,'YYYYMMDD') || '-' ||
                   vn_request_id|| '_' ||
                   to_char(SYSDATE,'YYYYMMDD-HH24MISS') || gv_ext;
    
    vv_step := '006 : Nom du fichier n°'||vn_nb_fichier||' : '||vv_file_name;
    dka_tools_pkg.put_debug_message(vv_step);                         
                              
    File_Handle := UTL_FILE.FOPEN ('DKA_APIMPORT_DIR', vv_file_name, 'w');
    
    --FORMAT
    vv_amount        := trim(' ' FROM to_char(h.ctrl_amount,'99999999999999.99'));
    vv_creation_date := to_char(h.creation_date,'YYYYMMDD');
    
    --LIGNE D'ENTETE    
    vv_buffer :=  h.FILE_INFORMATION_INDICATOR || gv_separateur ||
                  h.div_code    ||'_'||
                  h.agora_code  ||'_'||
                  h.code_banque ||'-'||
                  h.societe||h.region||h.type_campagne ||'-'||
                  vv_creation_date ||'-'|| vn_request_id || gv_separateur ||   
                  vv_amount                    || gv_separateur ||
                  h.type_indicator             || gv_separateur ||
                  h.external_system_appl_id    || gv_separateur ||   
                  h.external_system_id ||CHR(13);
                  
    UTL_FILE.PUT_LINE(File_Handle,vv_buffer);
                      
    --LIGNE DE COLONNE
    UTL_FILE.PUT_LINE(File_Handle,vv_FILE_LAYOUT);
    
    FOR l IN cur_ligne(h.header_id) LOOP
      
      --FORMAT
      vv_value_date      := to_char(l.VALUEDATE,'MM/DD/YYYY');
      vv_transactiondate := to_char(l.TRANSACTIONDATE,'MM/DD/YYYY');
      vv_amount          := trim(' ' FROM to_char(l.AMOUNT,'99999999999999.99'));
      
      vv_buffer :=  l.ENTITYID                              || gv_separateur ||
                    l.COUNTERPARTYID                        || gv_separateur ||
                    l.CASHFLOWTYPE                          || gv_separateur ||
                    l.PAYMENTMETHOD                         || gv_separateur ||
                    l.PRIORITYID                            || gv_separateur ||
                    vv_value_date                           || gv_separateur ||
                    vv_transactiondate                      || gv_separateur ||
                    l.ENTITYBANKACCOUNTNUMBER               || gv_separateur ||
                    l.CURRENCYCODE                          || gv_separateur ||
                    vv_amount                               || gv_separateur ||
                    l.COUNTERPARTYNAME                      || gv_separateur ||
                    l.COUNTERPARTYBANKACCOUNTNUMBER         || gv_separateur ||
                    l.CPTYSECONDARYACCOUNTNUMBER            || gv_separateur ||
                    l.COUNTERPARTYBANKACCOUNTCOUNTRY        || gv_separateur ||
                    l.COUNTERPARTYBANKCODE                  || gv_separateur ||
                    l.COUNTERPARTYBANKBRANCHID              || gv_separateur ||
                    l.COUNTERPARTYADDRESS1                  || gv_separateur ||
                    l.COUNTERPARTYADDRESS2                  || gv_separateur ||
                    l.COUNTERPARTYADDRESS3                  || gv_separateur ||
                    l.COUNTERPARTYADDRESS4                  || gv_separateur ||
                    l.COUNTERPARTYSTATE                     || gv_separateur ||
                    l.COUNTERPARTYCITY                      || gv_separateur ||
                    l.COUNTERPARTYCOUNTRYCODE               || gv_separateur ||
                    l.COUNTERPARTYMESSAGE                   || gv_separateur ||
                    l.FINANCIALCHARGEALLOCATION             || gv_separateur ||
                    l.CUSTOMERREFERENCENUMBER               || gv_separateur ||
                    l.BANKINSTRUCTIONS                      || gv_separateur ||
                    l.DESCRIPTION_REFERENCE                 || gv_separateur ||
                    l.TRANSACTIONTYPECODE                   || gv_separateur ||
                    l.INTERMEDIARYBANKSWIFTCODE             || gv_separateur ||
                    l.INTERMEDIARYBANKNAME                  || gv_separateur ||
                    l.INTERMEDIARYBANKADRESSE1              || gv_separateur ||
                    l.INTERMEDIARYBANKADRESSE2              || gv_separateur ||
                    l.INTERMEDIARYBANKADRESSE3              || gv_separateur ||
                    l.INTERMEDIARYBANKADRESSE4              || gv_separateur ||
                    l.SECONDINTERMEDIARYBANKSWIFT           || gv_separateur ||
                    l.SECONDINTERMEDIARYBANKNAME            || gv_separateur ||
                    l.SECONDINTERMEDIARYBANKADRESSE1        || gv_separateur ||
                    l.SECONDINTERMEDIARYBANKADRESSE2        || gv_separateur ||
                    l.SECONDINTERMEDIARYBANKADRESSE3        || gv_separateur ||
                    l.SECONDINTERMEDIARYBANKADRESSE4        || gv_separateur ||
                    l.CHEQUENUMBER                          || gv_separateur ||
                    l.COMMENTS                              || gv_separateur ||
                    l.RESERVE9                              || gv_separateur ||
                    l.RESERVE8                              || gv_separateur ||
                    l.RESERVE7                              || gv_separateur ||
                    l.RESERVE6                              || gv_separateur ||
                    l.RESERVE5                              || gv_separateur ||
                    l.RESERVE4                              || gv_separateur ||
                    l.RESERVE3                              || gv_separateur ||
                    l.RESERVE2                              || gv_separateur ||
                    l.RESERVE1 ||CHR(13);
      
      --LIGNE DE DONNEES
      UTL_FILE.PUT_LINE(File_Handle,vv_buffer);
                        
      vn_nb_lignes := vn_nb_lignes + 1;
      
    END LOOP;
    
    vv_step := '007 : Nombre de lignes dans le fichier : '||vn_nb_lignes;
    dka_tools_pkg.put_debug_message(vv_step);   
    
    --
    vv_step := '008 : Fermeture du fichier';
    dka_tools_pkg.put_debug_message(vv_step);   
    UTL_FILE.fclose(File_Handle);
    
    vn_nb_fichier    := vn_nb_fichier + 1;
    vn_nb_lignes_tot := vn_nb_lignes_tot + vn_nb_lignes;
                      
 END LOOP;
 
 --Mise jour des en-têtes à PRINT
  vv_step := '009 : Nombre d''entete mis à PRINT';
 dka_tools_pkg.put_debug_message(vv_step);
 UPDATE DKA_IEOAPSAT01_APIMP_HDR
 SET STATUS = 'PRINT'
 WHERE
  STATUS = 'NEW'
 ;
 vv_step := '010 : '||SQL%ROWCOUNT;
 dka_tools_pkg.put_debug_message(vv_step);
 
 
 --COMPTE-RENDU
 vv_step := '011 : COMPTE-RENDU';
 dka_tools_pkg.put_debug_message(vv_step);
 
 dka_tools_pkg.put_out_header;
 dka_tools_pkg.put_outdebug_message('Nombre de fichiers créés : '||vn_nb_fichier);
 dka_tools_pkg.put_outdebug_message('Nombre de lignes créées  : '||vn_nb_lignes_tot);
 
 IF vn_nb_fichier = 0 THEN
   Pn_RetCode := 1;
   Pv_ErrBuf  := '==> Aucun fichier créé';
   dka_tools_pkg.put_outdebug_message('Nombre de lignes créées  : '||vn_nb_lignes_tot);
 END IF;
   
   
 vv_step := '999 : FIN';
 dka_tools_pkg.put_debug_message(vv_step);
 
EXCEPTION
  WHEN UTL_FILE.INVALID_PATH THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER : INVALID PATH';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN UTL_FILE.INVALID_MODE THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER : INVALID MODE';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER : INVALID FILEHANDLE';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN UTL_FILE.INVALID_OPERATION THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER : INVALID OPERATION';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN UTL_FILE.READ_ERROR THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER : READ ERROR';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN UTL_FILE.WRITE_ERROR THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER : WRITE ERROR';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER : INTERNAL ERROR';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT FICHIER: INVALID MAXLINESIZE';
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);
  WHEN OTHERS THEN
       Pn_RetCode := 2;
       Pv_ErrBuf  := '==> ERREUR LORS DU TRAITEMENT : '||SUBSTR(SqlErrm, 1, 80);   
       dka_tools_pkg.put_log_message(pv_errbuf);
       UTL_FILE.fclose(File_Handle);        
END create_ap_import_file;
                   
---------------------------------------------------------------------------------------------------------------  
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur   
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur' 
--                  pv_p_payment_patch     Entrée
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
PROCEDURE main(pv_errbuf                IN  OUT VARCHAR2,
               pn_retcode                   OUT NUMBER--,
               --pv_p_payment_patch       IN      VARCHAR2
               )  IS

  --RBE MigR12
  ----- Cursor des demandes de reglement a traiter
  CURSOR cur_demandes IS
  SELECT *
  FROM dka_sapautorgt_tmp
  WHERE status_flag = 'P'
  and Substr(checkrun_name,Instr(checkrun_name, 'RBT'), INSTR(checkrun_name, 'NT') - INSTR(checkrun_name, 'RBT') +2 ) != 'RBTCLIENT' --EDB295
  ;
  
  --EDB295
  CURSOR cur_dem_rbt IS
  SELECT *
  FROM dka_sapautorgt_tmp
  WHERE status_flag = 'P'
  --and Substr(checkrun_name, 4, Instr(checkrun_name, 'X') - 3) = 'RBTCLIENTEX'
  and Substr(checkrun_name,Instr(checkrun_name, 'RBT'), INSTR(checkrun_name, 'NT') - INSTR(checkrun_name, 'RBT') +2 ) = 'RBTCLIENT'
  ;

  ----- Déclaration de curseur d'extraction des données de l'interface des règlements -----
  CURSOR cur_data (p_checkrun_id NUMBER) IS 
    /*
    SELECT 
      aisc.checkrun_name                        checkrun_name,
      asic.selected_check_id                    check_id,
      aisc.status                               statut,
      --
      haou.name                                 code_societe,
      gcchl.segment2                            region,
    
    -- DEB - 15/10/2012 - BCO - Ajout des champs société et région de la banque. --
    gccbq.Segment1              societe_bque,
    gccbq.Segment2              region_bque,
    -- FIN - 15/10/2012 - BCO - Ajout des champs société et région de la banque. --
    
      abb.bank_number                           code_banque, --06/12/2012 JJA - Banque interne
      --
      asic.vendor_name                          nom_destinataire,
      pvs.address_line1                         adresse1,
      pvs.address_line2                         adresse2,
      pvs.address_line3                         adresse3,
      pvs.address_line4                         adresse4,
      pvs.zip                                   cp,
      pvs.city                                  city,
      t.territory_short_name                    pays,
      t.territory_code                          code_pays,
      --
      aisc.vendor_pay_group                     type_fournisseur,
      nvl((CASE
            WHEN aisc.HI_PAYMENT_PRIORITY = 1 AND
                 aisc.LOW_PAYMENT_PRIORITY = 1 THEN 'TIERS EXPR'
            ELSE substr(aisc.VENDOR_PAY_GROUP,8)                
           END),
          (SELECT
            ffvv.FLEX_VALUE
           FROM
            fnd_flex_value_sets ffvs,
            fnd_flex_values_vl  ffvv
           WHERE
            ffvs.flex_value_set_name = 'DKA_VENDOR_PAY_GROUP'
            AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
            AND ffvv.ENABLED_FLAG = 'Y'
            AND SYSDATE BETWEEN nvl(ffvv.START_DATE_ACTIVE,SYSDATE)
                            AND nvl(ffvv.END_DATE_ACTIVE,SYSDATE)
            AND pvs.pay_group_lookup_code LIKE '%'||ffvv.FLEX_VALUE)) type_campagne,
      --
      asic.check_amount                         montant_paiement,
      aisc.check_date                           date_paiement,
      asic.currency_code                        code_devise,
      asic.status_lookup_code                   status_lookup_code,      
      --BANQUE EMETTEUR
      aba.IBAN_NUMBER                           emetteur_iban,
      --BANQUE BENEFICIAIRE
      abbd.bank_number||abbd.bank_num||abad.BANK_ACCOUNT_NUM benef_bban,
      abad.IBAN_NUMBER                          benef_iban,
      t_b.territory_code                        benef_code_pays,
      abbd.eft_swift_code                       benef_bic,
      --TECH
      pv.vendor_id                              vendor_id,
      pvs.vendor_site_id                        vendor_site_id,
      pvs.pay_group_lookup_code                 vendor_site_pay_group,
      pv.attribute2                             vendor_code_partenaire,
      pv.segment1                               vendor_code,
      pvs.vendor_site_code                      vendor_site_code
    FROM ap_selected_invoice_checks    asic,
         ap_invoice_selection_criteria aisc,
         po_vendor_sites_all           pvs, 
         po_vendors                    pv,
         gl_code_combinations          gcchl,
         hr_locations                  hl,
         dka_ibdsoc_general_info       digi,
         hr_all_organization_units     haou,
         ap_bank_accounts              abad,
         ap_bank_branches              abbd,
         ap_bank_branches              abb,
         ap_bank_accounts              aba,
         ap_check_stocks               acs,
         fnd_territories_vl            t,
         fnd_territories_vl            t_b,
         ap_lookup_codes               lc,
         financials_system_parameters  fsp,
     -- 15/10/2012 - BCO - Ajout de la table gl_code_combinations pour retourné la région et la société de la Banque. --
     gl_code_combinations      gccbq
    WHERE aisc.checkrun_name          = pv_p_payment_patch
      AND asic.checkrun_name          = aisc.checkrun_name
      AND (asic.ok_to_pay_flag = 'Y' OR
           asic.status_lookup_code = 'UNCONFIRMED SET UP')
      AND asic.check_number BETWEEN aisc.start_print_document
                                AND aisc.end_print_document
      --BANQUE FOURNISSEUR
      AND asic.external_bank_account_id = abad.bank_account_id(+)  
      AND abad.bank_branch_id           = abbd.bank_branch_id(+)   
      --BANQUE INTERNE  
      AND aisc.bank_account_id          = aba.bank_account_id
      AND aba.bank_branch_id            = abb.bank_branch_id
      --
      AND aisc.check_stock_id           = acs.check_stock_id
      AND haou.name                     = SUBSTR (acs.doc_category_code, 1, 4) 
      AND fsp.BUSINESS_GROUP_ID         = haou.business_group_id
      AND pvs.org_id                    = TO_NUMBER(fnd_profile.value('ORG_ID'))
      AND haou.name                     = digi.company_code         
      AND pv.vendor_id                  = pvs.vendor_id
      AND pvs.vendor_site_id            = asic.vendor_site_id
      AND pvs.accts_pay_code_combination_id = gcchl.code_combination_id
      AND hl.location_code              = gcchl.segment2
      AND hl.business_group_id          = TO_NUMBER(fnd_profile.value('PER_BUSINESS_GROUP_ID'))
      AND t.territory_code (+)          = asic.country
      AND t_b.territory_code (+)        = abbd.country
      AND lc.lookup_code (+)            = asic.withholding_status_lookup_code
      AND lc.lookup_type (+)            = 'WITHHOLDING STATUS'
      AND asic.check_amount             > 0
    -- 15/10/2012 - BCO.
    AND gccbq.code_combination_id     = aba.asset_code_combination_id
    ORDER BY 
      code_banque,
      code_societe,
      region,
      type_campagne
    ;
    */

   SELECT 
      Aisc.Checkrun_Name                        Checkrun_Name,
      TO_CHAR(Aisc.creation_date,'YYYYMMDD')||'-'||TO_CHAR(Aisc.creation_date,'HH24MI')||substr (Aisc.checkrun_name,0,INSTR(Aisc.checkrun_name,'-')-1) New_Checkrun_Name, --RBE artf2092291 
      Aisc.Checkrun_ID                          Checkrun_ID,
      --Asic.Selected_Check_Id                  Check_Id,       --RBE MigR12
      asic.check_id                             check_id,       --RBE MigR12
      aisc.status                               statut,
      --
      SUBSTR(haou.name,4,7)                     code_societe,   --RBE MigR12
      gcchl.segment2                            region,
    
      -- DEB - 15/10/2012 - BCO - Ajout des champs société et région de la banque. --
      --gccbq.Segment1                          societe_bque, --RBE MigR12
      SUBSTR(haou.name,4,7)                     societe_bque, --RBE MigR12
      --gccbq.Segment2                          region_bque,  --RBE MigR12
      SUBSTR(haou.name,1,3)                     region_bque,  --RBE MigR12
      -- FIN - 15/10/2012 - BCO - Ajout des champs société et région de la banque. --
      abb.bank_number                           code_banque, --06/12/2012 JJA - Banque interne
      --
      asic.vendor_name                          nom_destinataire,
      pvs.address_line1                         adresse1,
      pvs.address_line2                         adresse2,
      pvs.address_line3                         adresse3,
      pvs.address_line4                         adresse4,
      pvs.zip                                   cp,
      pvs.city                                  city,
      t.territory_short_name                    pays,
      t.territory_code                          code_pays,
      --
      aisc.vendor_pay_group                     type_fournisseur,
      --RBE MigR12 : artf2090995 
      /*nvl((CASE
            WHEN aisc.HI_PAYMENT_PRIORITY = 1 AND
                 aisc.LOW_PAYMENT_PRIORITY = 1 THEN 'TIERS EXPR'
            ELSE substr(aisc.VENDOR_PAY_GROUP,8)                
           END),
          (SELECT
            ffvv.FLEX_VALUE
           FROM
            fnd_flex_value_sets ffvs,
            fnd_flex_values_vl  ffvv
           WHERE
            ffvs.flex_value_set_name = 'DKA_VENDOR_PAY_GROUP'
            AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
            AND ffvv.ENABLED_FLAG = 'Y'
            AND SYSDATE BETWEEN nvl(ffvv.START_DATE_ACTIVE,SYSDATE)
                            AND nvl(ffvv.END_DATE_ACTIVE,SYSDATE)
            AND pvs.pay_group_lookup_code LIKE '%'||ffvv.FLEX_VALUE)) type_campagne, */
      ffvv.flex_value                           type_campagne,      --RBE MigR12
      --
      Asic.Amount                               Montant_Paiement,   --RBE MigR12
      --asic.check_amount                       montant_paiement,   --RBE MigR12
      Aisc.Check_Date                           Date_Paiement,
      Asic.Currency_Code                        Code_Devise,
      --asic.status_lookup_code                 status_lookup_code, --RBE MigR12
      asic.withholding_status_lookup_code       status_lookup_code, --RBE MigR12
      --BANQUE EMETTEUR
      aba.IBAN_NUMBER                           emetteur_iban,
      --BANQUE BENEFICIAIRE
      --abbd.bank_number||abbd.bank_num||abad.BANK_ACCOUNT_NUM benef_bban,    --RBE MigR12
      abbd.bank_number||abbd.branch_number||abad.BANK_ACCOUNT_NUM benef_bban, --RBE MigR12
      abad.IBAN                                 benef_iban,         --RBE MigR12
      --t_b.territory_code                      benef_code_pays,    --RBE MigR12
      abbd.bank_home_country                    benef_code_pays,    --RBE MigR12
      abbd.eft_swift_code                       benef_bic,
      --TECH
      pv.vendor_id                              vendor_id,
      --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
      pv.vendor_type_lookup_code                vendor_type_lookup_code,
      pvs.vendor_site_id                        vendor_site_id,
      pvs.pay_group_lookup_code                 vendor_site_pay_group,
      pv.attribute2                             vendor_code_partenaire,
      pv.segment1                               vendor_code,
      Pvs.Vendor_Site_Code                      Vendor_Site_Code,
      asic.org_id                               org_id,  --RBE MigR12
      --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
      t2.territory_short_name                   pays_emp,
      t2.territory_code                         code_pays_emp
    FROM ap_checks_all asic, --ap_selected_invoices_all asic,--ap_selected_invoice_checks    asic,
         --ap_invoice_selection_criteria aisc,  --RBE MigR12
         AP_INV_SELECTION_CRITERIA_ALL aisc,    --RBE MigR12
         po_vendor_sites_all           pvs, 
         po_vendors                    pv,
         Gl_Code_Combinations          Gcchl,
         --hr_locations                  hl,
         --dka_ibdsoc_general_info       digi,      --RBE MigR12
         --hr_all_organization_units     haou,      --RBE MigR12
         hr_operating_units              haou,      --RBE MigR12
         --ap_bank_accounts              abad,      --RBE MigR12
         IBY_EXT_BANK_ACCOUNTS              abad,   --RBE MigR12
         --ap_bank_branches              abbd,
         CE_BANK_BRANCHES_V            abbd,        --RBE MigR12
         --ap_bank_branches              abb,
         CE_BANK_BRANCHES_V            abb,         --RBE MigR12
         --ap_bank_accounts              aba,
         ce_bank_accounts              aba,         --RBE MigR12
         --ap_check_stocks               acs,       --RBE MigR12
         CE_PAYMENT_DOCUMENTS          acs,         --RBE MigR12 
         fnd_territories_vl            t,--,
         --Fnd_Territories_Vl            T_B--,
         --Ap_Lookup_Codes               Lc,
         --financials_system_parameters  fsp,
         -- 15/10/2012 - BCO - Ajout de la table gl_code_combinations pour retourné la région et la société de la Banque. --
         --gl_code_combinations      gccbq--,
         --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
         fnd_territories_vl            t2,
         PER_ADDRESSES per_addr,
         FND_FLEX_VALUE_SETS FFVS,      --RBE MigR12
         fnd_flex_values_vl ffvv        --RBE MigR12
    Where 1=1 
      AND Aisc.checkrun_id = p_checkrun_id
      --AND aisc.checkrun_name          = pv_p_payment_patch
      And Asic.Checkrun_Name          = Aisc.Checkrun_Name
      /*And (Asic.Ok_To_Pay_Flag = 'Y' Or
           Asic.Status_Lookup_Code = 'UNCONFIRMED SET UP') --RBE MigR12
           asic.withholding_status_lookup_code = 'UNCONFIRMED SET UP') */ --RBE MigR12
      /*AND asic.check_number BETWEEN aisc.start_print_document
                                AND aisc.end_print_document*/
      --BANQUE FOURNISSEUR
      AND asic.external_bank_account_id = abad.ext_bank_account_id(+)  
      --AND abad.bank_branch_id           = abbd.bank_branch_id(+)  --RBE MigR12
      AND abad.branch_id                = abbd.branch_party_id(+)   --RBE MigR12
      AND abad.bank_id                  = abbd.bank_party_id(+)     --RBE MigR12
      --BANQUE INTERNE  
      AND aisc.bank_account_id          = aba.bank_account_id
      --AND aba.bank_branch_id            = abb.bank_branch_id      --RBE MigR12
      AND aba.bank_branch_id                 = abb.branch_party_id  --RBE MigR12
      AND aba.bank_id                   = abb.bank_party_id         --RBE MigR12
      --
      --AND aisc.check_stock_id           = acs.check_stock_id      --RBE MigR12
      AND aisc.PAYMENT_DOCUMENT_ID = acs.PAYMENT_DOCUMENT_ID
      --AND haou.name                     = SUBSTR (acs.doc_category_code, 1, 4) 
      And Acs.Internal_Bank_Account_Id  = Aba.Bank_Account_Id
      --AND fsp.BUSINESS_GROUP_ID         = haou.business_group_id
      AND pvs.org_id                    = asic.org_id -- TO_NUMBER(fnd_profile.value('ORG_ID')) --RBE MigR12
      --AND haou.name                     = digi.company_code                                   --RBE MigR12       
      AND pv.vendor_id                  = pvs.vendor_id
      AND pvs.vendor_site_id            = asic.vendor_site_id
      And Pvs.Accts_Pay_Code_Combination_Id = Gcchl.Code_Combination_Id
      --AND hl.location_code              = gcchl.segment2
      --AND hl.business_group_id          = TO_NUMBER(fnd_profile.value('PER_BUSINESS_GROUP_ID'))
      AND t.territory_code (+)          = asic.country
      --And T_B.Territory_Code (+)        = Abbd.Country
      --And Lc.Lookup_Code (+)            = Asic.Withholding_Status_Lookup_Code
      --And Lc.Lookup_Type (+)            = 'WITHHOLDING STATUS'
      --And Asic.Check_Amount             > 0 --RBE MigR12
      AND asic.amount             > 0 --RBE MigR12
      --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
      AND pv.employee_id = per_addr.PERSON_ID (+)
      AND per_addr.primary_flag (+) = 'Y'
      AND t2.territory_code (+)          = per_addr.country
      -- 15/10/2012 - BCO.
      --And Gccbq.Code_Combination_Id     = Aba.Asset_Code_Combination_Id
      --RBE MigR12 : artf2090995 
      AND haou.organization_id = asic.org_id
      AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
      AND FFVS.FLEX_VALUE_SET_NAME = 'DKA_VENDOR_PAY_GROUP'
      and ffvv.enabled_flag = 'Y'
      AND SYSDATE BETWEEN NVL(FFVV.START_DATE_ACTIVE,SYSDATE) 
                      AND NVL(FFVV.END_DATE_ACTIVE,SYSDATE)
      AND Substr(aisc.checkrun_name,4,Instr(aisc.checkrun_name,'VIR')-4) = ffvv.attribute3
    
    ORDER BY 
      code_banque,
      code_societe,
      region,
      Type_Campagne
    ;
  
  
  --EDB295
  
  CURSOR cur_data_rbt(p_checkrun_id NUMBER)
  IS
SELECT Aisc.Checkrun_Name Checkrun_Name,
        TO_CHAR(Aisc.creation_date, 'YYYYMMDD') || '-' ||
        TO_CHAR(Aisc.creation_date, 'HH24MI') ||
        substr(Aisc.checkrun_name, 0, INSTR(Aisc.checkrun_name, '-') - 1) New_Checkrun_Name,
        Aisc.Checkrun_ID Checkrun_ID,
        asic.check_id check_id,
        aisc.status statut,
        --
        SUBSTR(haou.name, 4, 7) code_societe,
        SUBSTR(haou.name, 1, 3) region,
        
        SUBSTR(haou.name, 4, 7) societe_bque,
        SUBSTR(haou.name, 1, 3) region_bque,
        abb.bank_number code_banque,
        --
        arc.CUSTOMER_NAME nom_destinataire,
        hl.ADDRESS1 adresse1,
        hl.ADDRESS2 adresse2,
        hl.ADDRESS3 adresse3,
        hl.ADDRESS4 adresse4,
        hl.postal_code cp,
        hl.CITY city,
    hcas.attribute3 code_anael,
    hca.ORIG_SYSTEM_REFERENCE code_client,
        
        t.territory_short_name pays,
        t.territory_code       code_pays,

        aisc.vendor_pay_group type_fournisseur,
        
        ffvv.flex_value type_campagne,
        --
        Asic.Amount                         Montant_Paiement,
        Aisc.Check_Date                     Date_Paiement,
        Asic.Currency_Code                  Code_Devise,
        asic.withholding_status_lookup_code status_lookup_code,
        --BANQUE EMETTEUR
        aba.IBAN_NUMBER emetteur_iban,
        --BANQUE BENEFICIAIRE
        
        abbd.bank_number || abbd.branch_number || abad.BANK_ACCOUNT_NUM benef_bban,
        abad.IBAN benef_iban,
        abbd.bank_home_country benef_code_pays,
        abbd.eft_swift_code benef_bic,
        
        null        vendor_id,
        null        vendor_type_lookup_code,
        null        vendor_site_id,
        null        vendor_site_pay_group,
        null        vendor_code_partenaire,
        null        vendor_code,
        null        Vendor_Site_Code,
        asic.org_id org_id,
        null        pays_emp,
        null        code_pays_emp
 
   FROM ap_checks_all asic,
   
        ar_customers arc,
        
        AP_INV_SELECTION_CRITERIA_ALL aisc,
        
        hr_operating_units haou,
        
        IBY_EXT_BANK_ACCOUNTS abad,
        
        CE_BANK_BRANCHES_V abbd,
        
        CE_BANK_BRANCHES_V abb,
        
        ce_bank_accounts aba,
        
        CE_PAYMENT_DOCUMENTS acs,
        fnd_territories_vl   t,
        
        hz_party_sites         hps,
        hz_cust_acct_sites_all hcas,
        hz_cust_accounts       hca,
        
        hz_locations hl,
        
        FND_FLEX_VALUE_SETS FFVS,
        fnd_flex_values_vl  ffvv
  Where 1 = 1
    AND Aisc.checkrun_id = p_checkrun_id
       
    And Asic.Checkrun_Name = Aisc.Checkrun_Name
       
       --BANQUE FOURNISSEUR
    AND asic.external_bank_account_id = abad.ext_bank_account_id(+)
       
    AND abad.branch_id = abbd.branch_party_id(+)
    AND abad.bank_id = abbd.bank_party_id(+)
       --BANQUE INTERNE  
    AND aisc.bank_account_id = aba.bank_account_id
       
    AND aba.bank_branch_id = abb.branch_party_id
    AND aba.bank_id = abb.bank_party_id
       --
       
    AND aisc.PAYMENT_DOCUMENT_ID = acs.PAYMENT_DOCUMENT_ID
       
    And Acs.Internal_Bank_Account_Id = Aba.Bank_Account_Id
       
    AND t.territory_code = asic.country
       
    and hps.party_site_id = hcas.party_site_id
    AND haou.organization_id = hcas.org_id
    AND hca.cust_account_id = hcas.cust_account_id
    AND hcas.cust_account_id in
        (SELECT BILL_TO_CUSTOMER_ID
           FROM ra_customer_trx_all
          where customer_trx_id in
                (SELECT substr(ai.description,
                               -instr(reverse(ai.description), '_') + 1)
                   from AP_INVOICES_ALL         ai,
                        AP_INVOICE_PAYMENTS_ALL p,
                        ap_checks_all           c
                  where p.invoice_id = ai.invoice_id
                    and c.check_id = p.check_id
                    and c.checkrun_id = Aisc.checkrun_id
          ))
       
    and Asic.party_site_id = hps.party_site_id
    and Asic.party_id = hps.party_id
    AND hcas.org_id = asic.org_id
    
    ----
    and arc.orig_system_reference = hca.ORIG_SYSTEM_REFERENCE
    
    and hps.location_id = hl.location_id
    
    ----
       
    AND t.territory_code(+) = asic.country
       
    AND asic.amount > 0
       
    AND haou.organization_id = asic.org_id
    AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
    AND FFVS.FLEX_VALUE_SET_NAME = 'DKA_VENDOR_PAY_GROUP'
    and ffvv.enabled_flag = 'Y'
    AND SYSDATE BETWEEN NVL(FFVV.START_DATE_ACTIVE, SYSDATE) AND
        NVL(FFVV.END_DATE_ACTIVE, SYSDATE)
    AND ffvv.attribute1 = 'RBT'
  and Substr(aisc.checkrun_name,Instr(aisc.checkrun_name, 'RBT'), INSTR(aisc.checkrun_name, 'NT') - INSTR(aisc.checkrun_name, 'RBT') +2 ) =  ffvv.attribute3  
    ORDER BY code_banque, code_societe, region, Type_Campagne;
  
  

  CURSOR c_param IS
    SELECT lookup_code,DESCRIPTION
    FROM fnd_lookup_values_vl flvv
    WHERE
     flvv.lookup_type = 'DKA_AP_IMPORT'
     AND flvv.lookup_code NOT LIKE 'FILE_LAYOUT%'
    ORDER BY lookup_code DESC;

/************************************/
  -- Déclaration des variables

  vv_step                  VARCHAR2(500);
  vn_entete_cpt            PLS_INTEGER;
  vn_ligne_cpt             PLS_INTEGER;
  
  vv_CASHFLOWTYPE          fnd_lookup_values_vl.description%TYPE;
  vv_COUNTERPARTYID        fnd_lookup_values_vl.description%TYPE;
  vv_EXTERNAL_SYSTEM_ID    fnd_lookup_values_vl.description%TYPE;
  vv_FILE_INFORMATION_IND  fnd_lookup_values_vl.description%TYPE;
  vv_FINANCIALCHARGEALLOC  fnd_lookup_values_vl.description%TYPE;
  vv_LISTE_CARACT_AUTORISE fnd_lookup_values_vl.description%TYPE;
  vv_PAYMENTMETHOD         fnd_lookup_values_vl.description%TYPE;
  vv_PRIORITYID            fnd_lookup_values_vl.description%TYPE;
  vv_TYPE_INDICATOR        fnd_lookup_values_vl.description%TYPE;
  vv_default_address       fnd_lookup_values_vl.description%TYPE;
  
  vv_societe               hr_all_organization_units.name%TYPE;
  vv_region                gl_code_combinations.segment2%TYPE;
  vv_banque                ap_bank_branches.bank_number%TYPE;
  
  -- DEB - 15/10/2012 - BCO - Déclaration des variables contenant la valeur des champs région et société de la banque. --
  vv_region_bque       gl_code_combinations.segment2%TYPE;
  vv_societe_bque      gl_code_combinations.segment1%TYPE;
  -- FIN - 15/10/2012 - BCO - Déclaration des variables contenant la valeur des champs région et société de la banque. --
  
  vv_type                  fnd_flex_values.flex_value%TYPE;
  
  --ENTETE
  vn_header_id             PLS_INTEGER;
  vv_code_division         DKA_IEOAPSAT01_APIMP_HDR.DIV_CODE%TYPE;
  --vv_code_agora            DKA_IEOAPSAT01_APIMP_HDR.AGORA_CODE%TYPE;        --RBE MigR12
  vv_type_campagne         DKA_IEOAPSAT01_APIMP_HDR.TYPE_CAMPAGNE%TYPE;
  vn_reg_request_id        DKA_IEOAPSAT01_APIMP_HDR.REG_REQUEST_ID%TYPE;
  
  --LIGNE
  vn_line_id               PLS_INTEGER;
  --vv_counterpartyid_l      DKA_IEOAPSAT01_APIMP_LINE.Counterpartyid%TYPE;   --RBE MigR12
  ----
  vv_emetteur_iban        DKA_IEOAPSAT01_APIMP_LINE.ENTITYBANKACCOUNTNUMBER%TYPE;
  vv_code_devise          DKA_IEOAPSAT01_APIMP_LINE.CURRENCYCODE%TYPE;
  vv_nom_destinataire     DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYNAME%TYPE;
  vv_benef_bban           DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYBANKACCOUNTNUMBER%TYPE;
  vv_benef_iban           DKA_IEOAPSAT01_APIMP_LINE.CPTYSECONDARYACCOUNTNUMBER%TYPE;
  vv_benef_code_pays      DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYBANKACCOUNTCOUNTRY%TYPE;
  vv_benef_bic            DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYBANKCODE%TYPE;
  vv_adresse1             DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYADDRESS1%TYPE;
  vv_adresse2             DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYADDRESS2%TYPE;
  vv_adresse3             DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYADDRESS3%TYPE;
  vv_adresse4             DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYADDRESS4%TYPE;
  vv_cp                   DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYSTATE%TYPE;
  vv_city                 DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYCITY%TYPE;
  vv_code_pays            DKA_IEOAPSAT01_APIMP_LINE.COUNTERPARTYCOUNTRYCODE%TYPE;
  vv_value_date           DKA_IEOAPSAT01_APIMP_LINE.VALUEDATE%TYPE;
  vv_COUNTERPARTYMESSAGE  VARCHAR2(300);
  vv_CHECK_RUNNAME_GG     VARCHAR2(300); --RBE artf2092291 
  v_num_ref           VARCHAR2(200); --ARA EDB295LOT1A
  
  vb_valid                 BOOLEAN;
  vv_err_buf               VARCHAR2(500);
  vv_err                   VARCHAR2(500);
  
  E_ENTETE                 EXCEPTION; --ENTETE INVALIDE
  E_LIGNE                  EXCEPTION; --LIGNE INVALIDE
  
BEGIN

  vv_step := '000 : Début procédure DKA_IEOAPSAT01_APIMP_PKG.MAIN';
  dka_tools_pkg.put_debug_message(vv_step);
  
  -----  Initialisations des variables -----
  vv_step := '001 : Initialisations des variables';
  dka_tools_pkg.put_debug_message(vv_step);

  pv_errbuf      := NULL;
  pn_retcode     := 0;
  vn_entete_cpt  := 0;
  vn_ligne_cpt   := 0;

  -----  Récupération des constantes -----
  vv_step := '001 : Récupération des constantes';
  dka_tools_pkg.put_debug_message(vv_step);

  vv_step := '002 : Parametres inconnus : ';
  FOR l IN c_param LOOP
    
    CASE 
     WHEN l.lookup_code = 'CASHFLOWTYPE'                THEN vv_CASHFLOWTYPE := l.DESCRIPTION;
     WHEN l.lookup_code = 'COUNTERPARTYID'              THEN vv_COUNTERPARTYID := l.DESCRIPTION;
     WHEN l.lookup_code = 'EXTERNAL_SYSTEM_ID'          THEN vv_EXTERNAL_SYSTEM_ID := l.DESCRIPTION;
     WHEN l.lookup_code = 'FILE_INFORMATION_INDICATOR'  THEN vv_FILE_INFORMATION_IND := l.DESCRIPTION;
     WHEN l.lookup_code LIKE 'FILE_LAYOUT%'             THEN NULL;--vv_FILE_LAYOUT := vv_FILE_LAYOUT || ';' || l.DESCRIPTION;        
     WHEN l.lookup_code = 'FINANCIALCHARGEALLOCATION'   THEN vv_FINANCIALCHARGEALLOC := l.DESCRIPTION;
     WHEN l.lookup_code = 'LISTE_CARACTERE_AUTORISE'    THEN vv_LISTE_CARACT_AUTORISE := l.DESCRIPTION;
     WHEN l.lookup_code = 'PAYMENTMETHOD'               THEN vv_PAYMENTMETHOD := l.DESCRIPTION;
     WHEN l.lookup_code = 'PRIORITYID'                  THEN vv_PRIORITYID := l.DESCRIPTION;
     WHEN l.lookup_code = 'TYPE_INDICATOR'              THEN vv_TYPE_INDICATOR := l.DESCRIPTION;
     WHEN l.lookup_code = 'DEFAULT_ADDRESS'             THEN vv_default_address := l.DESCRIPTION;
     ELSE vv_step := vv_step || ' ' || l.lookup_code || '/' || l.DESCRIPTION;
    END CASE;
   
  END LOOP;
  dka_tools_pkg.put_debug_message(vv_step);
  
  vv_societe    := NULL;
  vv_region     := NULL;
  -- DEB - 15/10/2012 - BCO - Initialisation de la société et de la région de la banque. --
  vv_societe_bque := NULL;
  vv_region_bque  := NULL;
  -- FIN - 15/10/2012 - BCO - Initialisation de la société et de la région de la banque. --
  vv_banque     := NULL;
  vv_type       := NULL;
  
FOR rec_demandes IN cur_demandes LOOP 
  
  FOR l IN cur_data (rec_demandes.checkrun_id) LOOP
    
    vb_valid := TRUE;
    
        
    IF    l.code_banque   !=  nvl(vv_banque,'#')
       OR l.code_societe  !=  nvl(vv_societe,'#')
       OR l.region        !=  nvl(vv_region,'#')
       /*-- DEB - 15/10/2012 - BCO - Vérification de l'existance d'une société et d'une région sur la Banque. --
       AND l.societe_bque  !=  nvl(vv_societe_bque,'#') 
       AND l.region_bque   !=  nvl(vv_region_bque,'#')
       -- FIN - 15/10/2012 - BCO - Vérification de l'existance d'une société et d'une région sur la Banque. --*/
       OR l.type_campagne !=  nvl(vv_type,'#') THEN   
     
      vv_societe    := l.code_societe;
      vv_region     := l.region;
      -- DEB - 15/10/2012 - BCO - Initialisation des variable de la société et la région de la Banque. --
      vv_societe_bque := l.societe_bque;
      vv_region_bque    := l.region_bque;
      -- FIN - 15/10/2012 - BCO - Initialisation des variable de la société et la région de la Banque. --
      vv_banque     := l.code_banque;
      vv_type       := l.type_campagne;
     
      vv_code_division := NULL;
      --vv_code_agora    := NULL; --RBE MigR12
      vv_type_campagne := NULL;
     
      vv_err_buf := 'ENTETE : '|| vv_societe || '/' ||
                                 vv_region  || '/' ||
      -- DEB - 15/10/2012 - BCO - Ajout de la log d'entête de la société et la région de la Banque. --
      vv_societe_bque || '/' ||
      vv_region_bque  || '/' ||
      -- FIN - 15/10/2012 - BCO - Ajout de la log d'entête de  la société et la région de la Banque. --
                     vv_banque  || '/' ||
                     vv_type ;
      dka_tools_pkg.put_debug_message(vv_err_buf);
     
      -----  Création de l'entete -----
      vv_step := '003 : Création de l''entete';
      dka_tools_pkg.put_debug_message(vv_step);

     --Récupération des valeurs
     --Code division
     --------------------------------------------------------------------------
     vv_step := '004 : Code division :';
     dka_tools_pkg.put_debug_message(vv_step);
     
     /* RBE - MigR12
     vv_code_division := dka_stransco_pkg.get_value_f('DKA_AP_IMPORT_DIVISION',
                                                       sysdate,
                                                       vv_err,
                                                       fnd_profile.value('ORG_ID'));
                                                       */
     vv_code_division := 'DK';
     
     dka_tools_pkg.put_log_message('Code division de l''organisation : '|| vv_code_division);
     
     IF vv_code_division IS NULL THEN
       vb_valid := FALSE;
       vv_err_buf := vv_err_buf || chr(10) || vv_err;
     END IF;
     vv_step := '004 : '||vv_code_division;
     dka_tools_pkg.put_debug_message(vv_step);
     
     /* --RBE MigR12 
     --Code agora
     --------------------------------------------------------------------------
     vv_step := '005 : Code AGORA :';
     dka_tools_pkg.put_debug_message(vv_step);
     -- DEB - 15/10/2012 - BCO - recherche du code agora pour la banque. --
     -- vv_code_agora := get_code_agora (NULL,vv_code_division,vv_region,vv_societe,vv_counterpartyid);
     vv_code_agora := get_code_agora (NULL,vv_code_division,vv_region_bque,vv_societe_bque,vv_counterpartyid);
   -- FIN - 15/10/2012 - BCO - recherche du code agora pour la banque. --
     IF vv_code_agora IS NULL THEN
       vb_valid := FALSE;
       vv_err_buf := vv_err_buf || chr(10) || 'Le code AGORA ne doit pas être nul';
     END IF;
     
     vv_step := '005 : '||vv_code_agora;
     dka_tools_pkg.put_debug_message(vv_step);
     */
     --Type campagne
     --------------------------------------------------------------------------
     vv_step := '006 : Type campagne :';
     dka_tools_pkg.put_debug_message(vv_step);
     BEGIN   
      
      SELECT attribute1
      INTO vv_type_campagne
      FROM
       fnd_flex_value_sets ffvs,
       fnd_flex_values_vl  ffvv
      WHERE
       ffvs.flex_value_set_name = 'DKA_VENDOR_PAY_GROUP'
       AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
       AND ffvv.ENABLED_FLAG = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.START_DATE_ACTIVE,SYSDATE)
                       AND nvl(ffvv.END_DATE_ACTIVE,SYSDATE)
       AND ffvv.FLEX_VALUE = vv_type;
          
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
       vb_valid := FALSE;
       vv_err_buf := vv_err_buf || chr(10) || 'Aucun type de campagne trouvé pour '|| vv_type;
     END; 
     
     IF vv_type_campagne IS NULL THEN
       vb_valid := FALSE;
       vv_err_buf := vv_err_buf || chr(10) || 'Le type de campagne ne doit pas être nul';
     END IF;
     
     vv_step := '006 : '||vv_type_campagne;
     dka_tools_pkg.put_debug_message(vv_step);
     
     /* RBE - MigR12
     --N° de traitement
     --------------------------------------------------------------------------
     vv_step := '007 : N° de traitement du "Registre des propositions de règlement" ';
     dka_tools_pkg.put_debug_message(vv_step);
     BEGIN
     
      SELECT fcr.request_id
      INTO vn_reg_request_id
      FROM fnd_concurrent_requests fcr,
      fnd_concurrent_requests fcr_p,
      fnd_concurrent_programs_vl fcp
      WHERE
       fcr.concurrent_program_id = fcp.CONCURRENT_PROGRAM_ID
       AND fcp.CONCURRENT_PROGRAM_NAME = 'APXPBPPR'
       AND fcr_p.request_id = fnd_global.CONC_REQUEST_ID
       AND fcr.parent_request_id = fcr_p.parent_request_id
       ;
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
       vn_reg_request_id := fnd_global.CONC_REQUEST_ID;
       vv_step := 'Aucun traitement "Registre des propositions de règlement" trouvé';
       dka_tools_pkg.put_debug_message(vv_step);
     END;
     vv_step := '007 : '||vn_reg_request_id;
     dka_tools_pkg.put_debug_message(vv_step);
     */
     vn_reg_request_id := fnd_global.CONC_REQUEST_ID; 
     
     --TRANSLATE
     vv_step := '008a : vv_FILE_INFORMATION_IND :'; vv_FILE_INFORMATION_IND := vv_FILE_INFORMATION_IND;--TRANSLATE_TEXT(vv_FILE_INFORMATION_IND,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008b : vv_code_division :';        vv_code_division        := TRANSLATE_TEXT(vv_code_division       ,vv_LISTE_CARACT_AUTORISE);
     --vv_step := '008c : vv_code_agora :';           vv_code_agora           := TRANSLATE_TEXT(vv_code_agora          ,vv_LISTE_CARACT_AUTORISE); --RBE MigR12 
     vv_step := '008d : vv_banque :';               vv_banque               := TRANSLATE_TEXT(vv_banque              ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008e : vv_societe :';              vv_societe              := TRANSLATE_TEXT(vv_societe             ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008f : vv_region :';               vv_region               := TRANSLATE_TEXT(vv_region              ,vv_LISTE_CARACT_AUTORISE);
     -- DEB - 15/10/2012 - BCO - Ajout de la log sur la société et la région de la Banque. --
     vv_step := '008g : vv_societe_bque :';         vv_societe_bque         := TRANSLATE_TEXT(vv_societe_bque        ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008h : vv_region_bque :';          vv_region_bque          := TRANSLATE_TEXT(vv_region_bque         ,vv_LISTE_CARACT_AUTORISE);
     -- FIN - 15/10/2012 - BCO - Ajout de la log sur la société et la région de la Banque. --
     vv_step := '008i : vv_type_campagne :';        vv_type_campagne        := TRANSLATE_TEXT(vv_type_campagne       ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008j : vv_TYPE_INDICATOR :';       vv_TYPE_INDICATOR       := TRANSLATE_TEXT(vv_TYPE_INDICATOR      ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008k : vv_EXTERNAL_SYSTEM_ID :';   vv_EXTERNAL_SYSTEM_ID   := TRANSLATE_TEXT(vv_EXTERNAL_SYSTEM_ID  ,vv_LISTE_CARACT_AUTORISE);
     --
     
     --VALIDATION
     vv_step := '009 : VALIDATION';
     dka_tools_pkg.put_debug_message(vv_step);
     IF vb_valid THEN
     
       SELECT DKA_IEOAPSAT01_APIMP_HDR_S.Nextval
       INTO vn_header_id
       FROM DUAL;
       
       vv_step := '010 : vn_header_id :'||vn_header_id;
       dka_tools_pkg.put_debug_message(vv_step);
       
       INSERT INTO DKA_IEOAPSAT01_APIMP_HDR
        (HEADER_ID,
         REQUEST_ID,
         ORG_ID,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
         LAST_UPDATE_LOGIN,
         REG_REQUEST_ID,
         FILE_INFORMATION_INDICATOR,
         DIV_CODE,
         AGORA_CODE,
         CODE_BANQUE,
         SOCIETE,
         REGION,
         -- DEB - 15/10/2012 - BCO - Ajout de la société et de la région de la Banque. --
         SOCIETE_BQUE,
         REGION_BQUE,
         -- FIN - 15/10/2012 - BCO - Ajout de la société et de la région de la Banque. --
         TYPE_CAMPAGNE,
         CTRL_AMOUNT,
         TYPE_INDICATOR,
         EXTERNAL_SYSTEM_APPL_ID,
         EXTERNAL_SYSTEM_ID,
         STATUS --'NEW','ERROR','PRINT'
        )
       VALUES
        (vn_header_id,                    --HEADER_ID
         fnd_global.CONC_REQUEST_ID,      --REQUEST_ID
         l.org_id, --fnd_profile.value('ORG_ID'),     --ORG_ID --RBE MigR12
         fnd_profile.value('USER_ID'),    --CREATED_BY
         SYSDATE,                         --CREATION_DATE
         fnd_profile.value('USER_ID'),    --LAST_UPDATED_BY
         SYSDATE,                         --LAST_UPDATE_DATE
         fnd_profile.value('LOGIN_ID'),   --LAST_UPDATE_LOGIN
         vn_reg_request_id,               --REG_REQUEST_ID
         vv_FILE_INFORMATION_IND,         --FILE_INFORMATION_INDICATOR
         vv_code_division,                --DIV_CODE
         --vv_code_agora,                   --AGORA_CODE --RBE MigR12
         vv_societe,                      --AGORA_CODE  --RBE MigR12
         vv_banque,                       --CODE_BANQUE
         vv_societe,                      --SOCIETE
         vv_region,                       --REGION
         -- DEB - 15/10/2012 - BCO - Insertion de la société et de la région pour la banque. --
         vv_societe_bque,         --SOCIETE_BQUE
         vv_region_bque,          --REGION_BQUE
         -- FIN - 15/10/2012 - BCO - Insertion de la société et de la région pour la banque. --
         vv_type_campagne,                --TYPE_CAMPAGNE
         NULL,                            --CTRL_AMOUNT
         vv_TYPE_INDICATOR,               --TYPE_INDICATOR
         NULL,                            --EXTERNAL_SYSTEM_APPL_ID
         vv_EXTERNAL_SYSTEM_ID,           --EXTERNAL_SYSTEM_ID
         'NEW'                            --STATUS --'NEW','ERROR','PRINT'
        );
       
       vn_entete_cpt := vn_entete_cpt + 1;
       
     ELSE
      --Entête non valide
      --On sort de la boucle en erreur
      vv_step := '011 : Entête non valide';
      dka_tools_pkg.put_debug_message(vv_step);
      
      RAISE E_ENTETE;
      
     END IF;  
     
    ELSE 
    
     --Entête existe déjà 
     vv_step := '012 : Entête existe déjà ';
     dka_tools_pkg.put_debug_message(vv_step); 
     
    END IF;
    
    -----  Création des lignes -----
    vv_step := '013 : Création des lignes';
    dka_tools_pkg.put_debug_message(vv_step);
    
    vb_valid := TRUE;
    
    --
    --vv_counterpartyid_l := NULL; --RBE MigR12
    -------
    vv_emetteur_iban    := NULL;
    vv_code_devise      := NULL;
    vv_nom_destinataire := NULL;
    vv_benef_bban       := NULL;
    vv_benef_iban       := NULL;
    vv_benef_code_pays  := NULL;
    vv_benef_bic        := NULL;
    vv_adresse1         := NULL;
    vv_adresse2         := NULL;
    vv_adresse3         := NULL;
    vv_adresse4         := NULL;
    vv_cp               := NULL;
    vv_city             := NULL;
    vv_code_pays        := NULL;
    vv_COUNTERPARTYMESSAGE := NULL;
    vv_CHECK_RUNNAME_GG := NULL;  --RBE artf2092291
    
    
    vv_err_buf := 'LIGNE : '|| l.nom_destinataire || '/' ||
                               l.montant_paiement;
    dka_tools_pkg.put_debug_message(vv_err_buf);

/* RBE MigR12
    --Récupération des valeurs
    --Counter party ID
    --------------------------------------------------------------------------
    vv_step := '014 : Counter party ID : '||l.type_campagne;
    dka_tools_pkg.put_debug_message(vv_step);
    
    vv_counterpartyid_l := get_code_agora (l.type_campagne,vv_code_division,vv_region,l.vendor_code_partenaire,vv_counterpartyid);
    
    IF vv_counterpartyid_l IS NULL THEN
      vb_valid := FALSE;
      vv_err_buf := vv_err_buf || chr(10) || 'Le Counter party ID ne doit pas être nul';
    END IF;
    vv_step := '014 : '||vv_counterpartyid_l;
    dka_tools_pkg.put_debug_message(vv_step);
*/
    --Counter party ID
    --------------------------------------------------------------------------
    vv_step := '015 : Value date : trx_date = '||l.date_paiement;
    dka_tools_pkg.put_debug_message(vv_step);
    vv_value_date := l.date_paiement + 1;
    --Dka_Dnx_Tools_Pkg.Get_Next_Working_Day(vv_value_date); --RBE MigR12
    DKA_TOOLS_PKG.Get_Next_Working_Day(vv_value_date); --RBE MigR12
    vv_step := '015 : Value date : '||vv_value_date;
    dka_tools_pkg.put_debug_message(vv_step);
    
    --Counter party message
    --------------------------------------------------------------------------
    vv_step := '016 : Counter party message';
    dka_tools_pkg.put_debug_message(vv_step);
    vv_COUNTERPARTYMESSAGE := dka_tools_pkg.get_message('DKA','DKA_IEOAPSAT01_APIMP_MESSAGE',
                                                        'LOT',  l.New_Checkrun_Name, -- RBE artf2092291 
                                                        'DATE', to_char(l.date_paiement,'dd/mm/yyyy'),
                                                        'FOURN',l.vendor_code,
                                                        'SITE', l.vendor_site_code);
    vv_step := '016 : '||vv_COUNTERPARTYMESSAGE;
    dka_tools_pkg.put_debug_message(vv_step);
    
    -- RBE artf2092291 
    -- CHECK_RUNNAME_GG
    --------------------------------------------------------------------------
    vv_CHECK_RUNNAME_GG := dka_tools_pkg.get_message('DKA','DKA_IEOAPSAT01_APIMP_MESSAGE',
                                                    'LOT',  l.Checkrun_Name, 
                                                    'DATE', to_char(l.date_paiement,'dd/mm/yyyy'),
                                                    'FOURN',l.vendor_code,
                                                    'SITE', l.vendor_site_code);
    vv_step := '016-bis : '||vv_CHECK_RUNNAME_GG;
    dka_tools_pkg.put_debug_message(vv_step);
    
    --TRANSLATE
     --vv_step := '016a : vv_code_agora :';           vv_code_agora           := substr(TRANSLATE_TEXT(vv_code_agora          ,vv_LISTE_CARACT_AUTORISE),1,8  );
     --vv_step := '016b : vv_counterpartyid :';       vv_counterpartyid       := substr(TRANSLATE_TEXT(vv_counterpartyid      ,vv_LISTE_CARACT_AUTORISE),1,8  ); --RBE MigR12
     vv_step := '016c : vv_CASHFLOWTYPE :';         vv_CASHFLOWTYPE         := substr(TRANSLATE_TEXT(vv_CASHFLOWTYPE        ,vv_LISTE_CARACT_AUTORISE),1,10 );
     vv_step := '016d : vv_PAYMENTMETHOD :';        vv_PAYMENTMETHOD        := substr(TRANSLATE_TEXT(vv_PAYMENTMETHOD       ,vv_LISTE_CARACT_AUTORISE),1,10 );
     vv_step := '016e : vv_PRIORITYID :';           vv_PRIORITYID           := substr(TRANSLATE_TEXT(vv_PRIORITYID          ,vv_LISTE_CARACT_AUTORISE),1,1  );
     vv_step := '016f : vv_emetteur_iban :';        vv_emetteur_iban        := substr(TRANSLATE_TEXT(l.emetteur_iban        ,vv_LISTE_CARACT_AUTORISE),1,60 );
     vv_step := '016g : vv_code_devise :';          vv_code_devise          := substr(TRANSLATE_TEXT(l.code_devise          ,vv_LISTE_CARACT_AUTORISE),1,3  );
     vv_step := '016h : vv_nom_destinataire :';     vv_nom_destinataire     := substr(TRANSLATE_TEXT(l.nom_destinataire     ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016i : vv_benef_bban :';           vv_benef_bban           := substr(TRANSLATE_TEXT(l.benef_bban           ,vv_LISTE_CARACT_AUTORISE),1,30 );
     vv_step := '016j : vv_benef_iban :';           vv_benef_iban           := substr(TRANSLATE_TEXT(l.benef_iban           ,vv_LISTE_CARACT_AUTORISE),1,60 );
     vv_step := '016k : vv_benef_code_pays :';      vv_benef_code_pays      := substr(TRANSLATE_TEXT(l.benef_code_pays      ,vv_LISTE_CARACT_AUTORISE),1,2  );
     vv_step := '016l : vv_benef_bic :';            vv_benef_bic            := substr(TRANSLATE_TEXT(l.benef_bic            ,vv_LISTE_CARACT_AUTORISE),1,20 );
     vv_step := '016m : vv_adresse1 :';             vv_adresse1             := substr(TRANSLATE_TEXT(l.adresse1             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016n : vv_adresse2 :';             vv_adresse2             := substr(TRANSLATE_TEXT(l.adresse2             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016o : vv_adresse3 :';             vv_adresse3             := substr(TRANSLATE_TEXT(l.adresse3             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016p : vv_adresse4 :';             vv_adresse4             := substr(TRANSLATE_TEXT(l.adresse4             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016q : vv_cp :';                   vv_cp                   := substr(TRANSLATE_TEXT(l.cp                   ,vv_LISTE_CARACT_AUTORISE),1,20 );
     vv_step := '016r : vv_city :';                 vv_city                 := substr(TRANSLATE_TEXT(l.city                 ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016s : vv_code_pays :';            vv_code_pays            := substr(TRANSLATE_TEXT(l.code_pays            ,vv_LISTE_CARACT_AUTORISE),1,2  );
     vv_step := '016t : vv_FINANCIALCHARGEALLOC :'; vv_FINANCIALCHARGEALLOC := substr(TRANSLATE_TEXT(vv_FINANCIALCHARGEALLOC,vv_LISTE_CARACT_AUTORISE),1,1  );
     vv_step := '016u : vv_COUNTERPARTYMESSAGE :';  vv_COUNTERPARTYMESSAGE  := substr(TRANSLATE_TEXT(vv_COUNTERPARTYMESSAGE ,vv_LISTE_CARACT_AUTORISE),1,100); 
     vv_step := '016v : vv_CHECK_RUNNAME_GG :';     vv_CHECK_RUNNAME_GG     := substr(TRANSLATE_TEXT(vv_CHECK_RUNNAME_GG    ,vv_LISTE_CARACT_AUTORISE),1,100); --RBE artf2092291
                                                                                                                                  
    --
    
    
    IF vb_valid THEN
     SELECT DKA_IEOAPSAT01_APIMP_LINE_S.Nextval
     INTO vn_line_id
     FROM DUAL;
       
     vv_step := '017 : vn_line_id :'||vn_line_id;
     dka_tools_pkg.put_debug_message(vv_step);
     
     INSERT INTO DKA_IEOAPSAT01_APIMP_LINE
       (HEADER_ID,
        LINE_ID,
        CREATED_BY,
        CREATION_DATE,
        LAST_UPDATED_BY,
        LAST_UPDATE_DATE,
        LAST_UPDATE_LOGIN,
        CHECKRUN_NAME,
        VENDOR_ID,
        VENDOR_SITE_ID,
        ENTITYID,
        COUNTERPARTYID,
        CASHFLOWTYPE,
        PAYMENTMETHOD,
        PRIORITYID,
        VALUEDATE,
        TRANSACTIONDATE,
        ENTITYBANKACCOUNTNUMBER,
        CURRENCYCODE,
        AMOUNT,
        COUNTERPARTYNAME,
        COUNTERPARTYBANKACCOUNTNUMBER,
        CPTYSECONDARYACCOUNTNUMBER,
        COUNTERPARTYBANKACCOUNTCOUNTRY,
        COUNTERPARTYBANKCODE,
        COUNTERPARTYBANKBRANCHID,
        COUNTERPARTYADDRESS1,
        COUNTERPARTYADDRESS2,
        COUNTERPARTYADDRESS3,
        COUNTERPARTYADDRESS4,
        COUNTERPARTYSTATE,
        COUNTERPARTYCITY,
        COUNTERPARTYCOUNTRYCODE,
        COUNTERPARTYMESSAGE,
        CHECK_RUNNAME_GG,   --RBE artf2092291
        FINANCIALCHARGEALLOCATION,
        CUSTOMERREFERENCENUMBER,
        BANKINSTRUCTIONS,
        DESCRIPTION_REFERENCE,
        TRANSACTIONTYPECODE,
        INTERMEDIARYBANKSWIFTCODE,
        INTERMEDIARYBANKNAME,
        INTERMEDIARYBANKADRESSE1,
        INTERMEDIARYBANKADRESSE2,
        INTERMEDIARYBANKADRESSE3,
        INTERMEDIARYBANKADRESSE4,
        SECONDINTERMEDIARYBANKSWIFT,
        SECONDINTERMEDIARYBANKNAME,
        SECONDINTERMEDIARYBANKADRESSE1,
        SECONDINTERMEDIARYBANKADRESSE2,
        SECONDINTERMEDIARYBANKADRESSE3,
        SECONDINTERMEDIARYBANKADRESSE4,
        CHEQUENUMBER,
        COMMENTS,
        RESERVE9,
        RESERVE8,
        RESERVE7,
        RESERVE6,
        RESERVE5,
        RESERVE4,
        RESERVE3,
        RESERVE2,
        RESERVE1
       )
     VALUES (
        vn_header_id,                  --HEADER_ID
        vn_line_id,                    --LINE_ID
        fnd_profile.value('USER_ID'),  --CREATED_BY
        SYSDATE,                       --CREATION_DATE
        fnd_profile.value('USER_ID'),  --LAST_UPDATED_BY
        SYSDATE,                       --LAST_UPDATE_DATE
        fnd_profile.value('LOGIN_ID'), --LAST_UPDATE_LOGIN
        l.checkrun_name,               --CHECKRUN_NAME
        l.vendor_id,                   --VENDOR_ID
        l.vendor_site_id,              --VENDOR_SITE_ID
        --vv_code_agora,                --ENTITYID --RBE MigR12
        vv_societe,                     --ENTITYID --RBE MigR12
        --vv_counterpartyid_l,           --COUNTERPARTYID --RBE MigR12
        'NO',           --COUNTERPARTYID --RBE MigR12
        vv_CASHFLOWTYPE,               --CASHFLOWTYPE
        vv_PAYMENTMETHOD,              --PAYMENTMETHOD
        vv_PRIORITYID,                 --PRIORITYID
        trunc(vv_value_date),          --VALUEDATE
        trunc(l.date_paiement),        --TRANSACTIONDATE
        vv_emetteur_iban,              --ENTITYBANKACCOUNTNUMBER
        vv_code_devise,                --CURRENCYCODE
        l.montant_paiement,            --AMOUNT
        vv_nom_destinataire,           --COUNTERPARTYNAME
        vv_benef_bban,                 --COUNTERPARTYBANKACCOUNTNUMBER
        vv_benef_iban,                 --CPTYSECONDARYACCOUNTNUMBER
        vv_benef_code_pays,            --COUNTERPARTYBANKACCOUNTCOUNTRY
        vv_benef_bic,                  --COUNTERPARTYBANKCODE
        NULL,                          --COUNTERPARTYBANKBRANCHID
        --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
        --decode(l.vendor_type_lookup_code, 'EMPLOYEE', NULL, nvl(vv_adresse1,vv_default_address)),--COUNTERPARTYADDRESS1
        decode(l.vendor_type_lookup_code, 'EMPLOYEE', vv_default_address, nvl(vv_adresse1,vv_default_address)),--COUNTERPARTYADDRESS1
        vv_adresse2,                   --COUNTERPARTYADDRESS2
        vv_adresse3,                   --COUNTERPARTYADDRESS3
        vv_adresse4,                   --COUNTERPARTYADDRESS4
        vv_cp,                         --COUNTERPARTYSTATE
        vv_city,                       --COUNTERPARTYCITY
        --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
        decode(l.vendor_type_lookup_code, 'EMPLOYEE', l.code_pays_emp, vv_code_pays),                  --COUNTERPARTYCOUNTRYCODE
        vv_COUNTERPARTYMESSAGE,        --COUNTERPARTYMESSAGE
        vv_CHECK_RUNNAME_GG,           --CHECK_RUNNAME_GG --RBE artf2092291 
        vv_FINANCIALCHARGEALLOC,       --FINANCIALCHARGEALLOCATION
        NULL,                          --CUSTOMERREFERENCENUMBER
        NULL,                          --BANKINSTRUCTIONS
        NULL,                          --DESCRIPTION_REFERENCE
        NULL,                          --TRANSACTIONTYPECODE
        NULL,                          --INTERMEDIARYBANKSWIFTCODE
        NULL,                          --INTERMEDIARYBANKNAME
        NULL,                          --INTERMEDIARYBANKADRESSE1
        NULL,                          --INTERMEDIARYBANKADRESSE2
        NULL,                          --INTERMEDIARYBANKADRESSE3
        NULL,                          --INTERMEDIARYBANKADRESSE4
        NULL,                          --SECONDINTERMEDIARYBANKSWIFT
        NULL,                          --SECONDINTERMEDIARYBANKNAME
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE1
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE2
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE3
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE4
        NULL,                          --CHEQUENUMBER
        NULL,                          --COMMENTS
        NULL,                          --RESERVE9
        NULL,                          --RESERVE8
        NULL,                          --RESERVE7
        NULL,                          --RESERVE6
        NULL,                          --RESERVE5
        NULL,                          --RESERVE4
        NULL,                          --RESERVE3
        NULL,                          --RESERVE2
        NULL                           --RESERVE1
     );
     
     vn_ligne_cpt := vn_ligne_cpt + 1;
    
    ELSE
     --Ligne non valide
     --On sort de la boucle en erreur
     vv_step := '018 : Ligne non valide';
     dka_tools_pkg.put_debug_message(vv_step);
      
     RAISE E_LIGNE;
     
    END IF;
    
    --LIGNE SUIVANTE
    vv_step := '019 : LIGNE SUIVANTE';
    dka_tools_pkg.put_debug_message(vv_step);
  
  END LOOP;

  --RBE MigR12
  UPDATE dka_sapautorgt_tmp
  SET status_flag = 'T'
  WHERE checkrun_id = rec_demandes.checkrun_id
  ;
  
END LOOP;

commit;-------
--ARA EDB295



  vv_societe    := NULL;
  vv_region     := NULL;
  vv_societe_bque := NULL;
  vv_region_bque  := NULL;
  vv_banque     := NULL;
  vv_type       := NULL;

FOR rec_dem_rbt IN cur_dem_rbt LOOP 

  
  FOR l IN cur_data_rbt(rec_dem_rbt.checkrun_id) LOOP

    
    vb_valid := TRUE;
    
        
    IF    l.code_banque   !=  nvl(vv_banque,'#')
       OR l.code_societe  !=  nvl(vv_societe,'#')
       OR l.region        !=  nvl(vv_region,'#')
       /*-- DEB - 15/10/2012 - BCO - Vérification de l'existance d'une société et d'une région sur la Banque. --
       AND l.societe_bque  !=  nvl(vv_societe_bque,'#') 
       AND l.region_bque   !=  nvl(vv_region_bque,'#')
       -- FIN - 15/10/2012 - BCO - Vérification de l'existance d'une société et d'une région sur la Banque. --*/
       OR l.type_campagne !=  nvl(vv_type,'#') THEN   
     
      vv_societe    := l.code_societe;
      vv_region     := l.region;
      -- DEB - 15/10/2012 - BCO - Initialisation des variable de la société et la région de la Banque. --
      vv_societe_bque := l.societe_bque;
      vv_region_bque    := l.region_bque;
      -- FIN - 15/10/2012 - BCO - Initialisation des variable de la société et la région de la Banque. --
      vv_banque     := l.code_banque;
      vv_type       := l.type_campagne;
     
      vv_code_division := NULL;
      --vv_code_agora    := NULL; --RBE MigR12
      vv_type_campagne := NULL;
     
      vv_err_buf := 'ENTETE : '|| vv_societe || '/' ||
                                 vv_region  || '/' ||
      -- DEB - 15/10/2012 - BCO - Ajout de la log d'entête de la société et la région de la Banque. --
      vv_societe_bque || '/' ||
      vv_region_bque  || '/' ||
      -- FIN - 15/10/2012 - BCO - Ajout de la log d'entête de  la société et la région de la Banque. --
                     vv_banque  || '/' ||
                     vv_type ;
      dka_tools_pkg.put_debug_message(vv_err_buf);
     
      -----  Création de l'entete -----
      vv_step := '003 : Création de l''entete';
      dka_tools_pkg.put_debug_message(vv_step);

     --Récupération des valeurs
     --Code division
     --------------------------------------------------------------------------
     vv_step := '004 : Code division :';
     dka_tools_pkg.put_debug_message(vv_step);
     
     vv_code_division := 'DK';
     
     dka_tools_pkg.put_log_message('Code division de l''organisation : '|| vv_code_division);
     
     IF vv_code_division IS NULL THEN
       vb_valid := FALSE;
       vv_err_buf := vv_err_buf || chr(10) || vv_err;
     END IF;
     vv_step := '004 : '||vv_code_division;
     dka_tools_pkg.put_debug_message(vv_step);
     
    
     --Type campagne
     --------------------------------------------------------------------------
     vv_step := '006 : Type campagne :';
     dka_tools_pkg.put_debug_message(vv_step);
     BEGIN   
      
      SELECT attribute1
      INTO vv_type_campagne
      FROM
       fnd_flex_value_sets ffvs,
       fnd_flex_values_vl  ffvv
      WHERE
       ffvs.flex_value_set_name = 'DKA_VENDOR_PAY_GROUP'
       AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
       AND ffvv.ENABLED_FLAG = 'Y'
       AND SYSDATE BETWEEN nvl(ffvv.START_DATE_ACTIVE,SYSDATE)
                       AND nvl(ffvv.END_DATE_ACTIVE,SYSDATE)
       AND ffvv.FLEX_VALUE = vv_type;
          
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
       vb_valid := FALSE;
       vv_err_buf := vv_err_buf || chr(10) || 'Aucun type de campagne trouvé pour '|| vv_type;
     END; 
     
     IF vv_type_campagne IS NULL THEN
       vb_valid := FALSE;
       vv_err_buf := vv_err_buf || chr(10) || 'Le type de campagne ne doit pas être nul';
     END IF;
     
     vv_step := '006 : '||vv_type_campagne;
     dka_tools_pkg.put_debug_message(vv_step);
     
     
     vn_reg_request_id := fnd_global.CONC_REQUEST_ID; 
     
     --TRANSLATE
     vv_step := '008a : vv_FILE_INFORMATION_IND :'; vv_FILE_INFORMATION_IND := vv_FILE_INFORMATION_IND;--TRANSLATE_TEXT(vv_FILE_INFORMATION_IND,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008b : vv_code_division :';        vv_code_division        := TRANSLATE_TEXT(vv_code_division       ,vv_LISTE_CARACT_AUTORISE);
     --vv_step := '008c : vv_code_agora :';           vv_code_agora           := TRANSLATE_TEXT(vv_code_agora          ,vv_LISTE_CARACT_AUTORISE); --RBE MigR12 
     vv_step := '008d : vv_banque :';               vv_banque               := TRANSLATE_TEXT(vv_banque              ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008e : vv_societe :';              vv_societe              := TRANSLATE_TEXT(vv_societe             ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008f : vv_region :';               vv_region               := TRANSLATE_TEXT(vv_region              ,vv_LISTE_CARACT_AUTORISE);
     -- DEB - 15/10/2012 - BCO - Ajout de la log sur la société et la région de la Banque. --
     vv_step := '008g : vv_societe_bque :';         vv_societe_bque         := TRANSLATE_TEXT(vv_societe_bque        ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008h : vv_region_bque :';          vv_region_bque          := TRANSLATE_TEXT(vv_region_bque         ,vv_LISTE_CARACT_AUTORISE);
     -- FIN - 15/10/2012 - BCO - Ajout de la log sur la société et la région de la Banque. --
     vv_step := '008i : vv_type_campagne :';        vv_type_campagne        := TRANSLATE_TEXT(vv_type_campagne       ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008j : vv_TYPE_INDICATOR :';       vv_TYPE_INDICATOR       := TRANSLATE_TEXT(vv_TYPE_INDICATOR      ,vv_LISTE_CARACT_AUTORISE);
     vv_step := '008k : vv_EXTERNAL_SYSTEM_ID :';   vv_EXTERNAL_SYSTEM_ID   := TRANSLATE_TEXT(vv_EXTERNAL_SYSTEM_ID  ,vv_LISTE_CARACT_AUTORISE);
     --
     
     --VALIDATION
     vv_step := '009 : VALIDATION';
     dka_tools_pkg.put_debug_message(vv_step);
     IF vb_valid THEN
     
       SELECT DKA_IEOAPSAT01_APIMP_HDR_S.Nextval
       INTO vn_header_id
       FROM DUAL;
       
       vv_step := '010 : vn_header_id :'||vn_header_id;
       dka_tools_pkg.put_debug_message(vv_step);
       
       INSERT INTO DKA_IEOAPSAT01_APIMP_HDR
        (HEADER_ID,
         REQUEST_ID,
         ORG_ID,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
         LAST_UPDATE_LOGIN,
         REG_REQUEST_ID,
         FILE_INFORMATION_INDICATOR,
         DIV_CODE,
         AGORA_CODE,
         CODE_BANQUE,
         SOCIETE,
         REGION,
       SOCIETE_BQUE,
       REGION_BQUE,
         TYPE_CAMPAGNE,
         CTRL_AMOUNT,
         TYPE_INDICATOR,
         EXTERNAL_SYSTEM_APPL_ID,
         EXTERNAL_SYSTEM_ID,
         STATUS --'NEW','ERROR','PRINT'
        )
       VALUES
        (vn_header_id,                    --HEADER_ID
         fnd_global.CONC_REQUEST_ID,      --REQUEST_ID
         l.org_id, --fnd_profile.value('ORG_ID'),     --ORG_ID --RBE MigR12
         fnd_profile.value('USER_ID'),    --CREATED_BY
         SYSDATE,                         --CREATION_DATE
         fnd_profile.value('USER_ID'),    --LAST_UPDATED_BY
         SYSDATE,                         --LAST_UPDATE_DATE
         fnd_profile.value('LOGIN_ID'),   --LAST_UPDATE_LOGIN
         vn_reg_request_id,               --REG_REQUEST_ID
         vv_FILE_INFORMATION_IND,         --FILE_INFORMATION_INDICATOR
         vv_code_division,                --DIV_CODE
         --vv_code_agora,                   --AGORA_CODE --RBE MigR12
         vv_societe,                      --AGORA_CODE  --RBE MigR12
         vv_banque,                       --CODE_BANQUE
         vv_societe,                      --SOCIETE
         vv_region,                       --REGION
         vv_societe_bque,         --SOCIETE_BQUE
       vv_region_bque,          --REGION_BQUE
         vv_type_campagne,                --TYPE_CAMPAGNE
         NULL,                            --CTRL_AMOUNT
         vv_TYPE_INDICATOR,               --TYPE_INDICATOR
         NULL,                            --EXTERNAL_SYSTEM_APPL_ID
         vv_EXTERNAL_SYSTEM_ID,           --EXTERNAL_SYSTEM_ID
         'NEW'                            --STATUS --'NEW','ERROR','PRINT'
        );
       
       vn_entete_cpt := vn_entete_cpt + 1;
       
     ELSE
      --Entête non valide
      --On sort de la boucle en erreur
      vv_step := '011 : Entête non valide';
      dka_tools_pkg.put_debug_message(vv_step);
      
      RAISE E_ENTETE;
      
     END IF;  
     
    ELSE 
    
     --Entête existe déjà 
     vv_step := '012 : Entête existe déjà ';
     dka_tools_pkg.put_debug_message(vv_step); 
     
    END IF;
    
    -----  Création des lignes -----
    vv_step := '013 : Création des lignes';
    dka_tools_pkg.put_debug_message(vv_step);
    
    vb_valid := TRUE;
    
    
    vv_emetteur_iban    := NULL;
    vv_code_devise      := NULL;
    vv_nom_destinataire := NULL;
    vv_benef_bban       := NULL;
    vv_benef_iban       := NULL;
    vv_benef_code_pays  := NULL;
    vv_benef_bic        := NULL;
    vv_adresse1         := NULL;
    vv_adresse2         := NULL;
    vv_adresse3         := NULL;
    vv_adresse4         := NULL;
    vv_cp               := NULL;
    vv_city             := NULL;
    vv_code_pays        := NULL;
    vv_COUNTERPARTYMESSAGE := NULL;
    vv_CHECK_RUNNAME_GG := NULL;
    
    
    vv_err_buf := 'LIGNE : '|| l.nom_destinataire || '/' ||
                               l.montant_paiement;
    dka_tools_pkg.put_debug_message(vv_err_buf);

    --Counter party ID
    --------------------------------------------------------------------------
    vv_step := '015 : Value date : trx_date = '||l.date_paiement;
    dka_tools_pkg.put_debug_message(vv_step);
    vv_value_date := l.date_paiement + 1;
    --Dka_Dnx_Tools_Pkg.Get_Next_Working_Day(vv_value_date); --RBE MigR12
    DKA_TOOLS_PKG.Get_Next_Working_Day(vv_value_date); --RBE MigR12
    vv_step := '015 : Value date : '||vv_value_date;
    dka_tools_pkg.put_debug_message(vv_step);
    
  --EDB295 LOT1A
  
  BEGIN
  SELECT NVL(ATTRIBUTE12,'X')
  INTO v_num_ref
  FROM ra_customer_trx_all
  WHERE customer_trx_id in
                 (SELECT substr(ai.description,
                        -instr(reverse(ai.description), '_') + 1)
                  from AP_INVOICES_ALL         ai,
                     AP_INVOICE_PAYMENTS_ALL p,
                     ap_checks_all           c
                 where p.invoice_id = ai.invoice_id
                   and c.check_id = p.check_id
                   and c.check_id = l.check_id
           and rownum = 1
           );
  
  
  EXCEPTION
  WHEN OTHERS THEN
  dka_tools_pkg.put_log_message('Erreur de récupération ATTRIBUTE12 : ' || SQLERRM);
  v_num_ref := 'X';
  END;
  
  --EDB295 LOT1A
  IF v_num_ref = 'X' THEN
        
    --Counter party message
    --------------------------------------------------------------------------
    vv_step := '016 : Counter party message';
    dka_tools_pkg.put_debug_message(vv_step);
    vv_COUNTERPARTYMESSAGE := dka_tools_pkg.get_message('DKA','DKA_IEOAPSAT01_MSG_RBT',
                                                        'LOT',  l.New_Checkrun_Name, 
                                                        'DATE', to_char(l.date_paiement,'dd/mm/yyyy'),
                                                        'CLI',l.code_client,
                                                        'SITE', l.code_anael); --EDB295
    
  
    vv_step := '016 : '||vv_COUNTERPARTYMESSAGE;
    dka_tools_pkg.put_debug_message(vv_step);
    
    -- CHECK_RUNNAME_GG
    --------------------------------------------------------------------------
    vv_CHECK_RUNNAME_GG := dka_tools_pkg.get_message('DKA','DKA_IEOAPSAT01_MSG_RBT',
                                                    'LOT',  l.Checkrun_Name, 
                                                    'DATE', to_char(l.date_paiement,'dd/mm/yyyy'),
                                                    'CLI',l.code_client,
                                                    'SITE', l.code_anael); --EDB295
                          
  ELSE
    
  --Counter party message
    --------------------------------------------------------------------------
    vv_step := '016 : Counter party message';
    dka_tools_pkg.put_debug_message(vv_step);
    vv_COUNTERPARTYMESSAGE := dka_tools_pkg.get_message('DKA','DKA_IEOAPSAT01_MSG_RBT',
                                                        'LOT',  l.New_Checkrun_Name, 
                                                        'DATE', to_char(l.date_paiement,'dd/mm/yyyy'),
                                                        'CLI',l.code_client,
                                                        'SITE', v_num_ref); --EDB295
    
  
    vv_step := '016 : '||vv_COUNTERPARTYMESSAGE;
    dka_tools_pkg.put_debug_message(vv_step);
    
    -- CHECK_RUNNAME_GG
    --------------------------------------------------------------------------
    vv_CHECK_RUNNAME_GG := dka_tools_pkg.get_message('DKA','DKA_IEOAPSAT01_MSG_RBT',
                                                    'LOT',  l.Checkrun_Name, 
                                                    'DATE', to_char(l.date_paiement,'dd/mm/yyyy'),
                                                    'CLI',l.code_client,
                                                    'SITE', v_num_ref); --EDB295
  
  
  
  
  END IF;
  
  
    vv_step := '016-bis : '||vv_CHECK_RUNNAME_GG;
    dka_tools_pkg.put_debug_message(vv_step);
    
    --TRANSLATE
     vv_step := '016c : vv_CASHFLOWTYPE :';         vv_CASHFLOWTYPE         := substr(TRANSLATE_TEXT(vv_CASHFLOWTYPE        ,vv_LISTE_CARACT_AUTORISE),1,10 );
     vv_step := '016d : vv_PAYMENTMETHOD :';        vv_PAYMENTMETHOD        := substr(TRANSLATE_TEXT(vv_PAYMENTMETHOD       ,vv_LISTE_CARACT_AUTORISE),1,10 );
     vv_step := '016e : vv_PRIORITYID :';           vv_PRIORITYID           := substr(TRANSLATE_TEXT(vv_PRIORITYID          ,vv_LISTE_CARACT_AUTORISE),1,1  );
     vv_step := '016f : vv_emetteur_iban :';        vv_emetteur_iban        := substr(TRANSLATE_TEXT(l.emetteur_iban        ,vv_LISTE_CARACT_AUTORISE),1,60 );
     vv_step := '016g : vv_code_devise :';          vv_code_devise          := substr(TRANSLATE_TEXT(l.code_devise          ,vv_LISTE_CARACT_AUTORISE),1,3  );
     vv_step := '016h : vv_nom_destinataire :';     vv_nom_destinataire     := substr(TRANSLATE_TEXT(l.nom_destinataire     ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016i : vv_benef_bban :';           vv_benef_bban           := substr(TRANSLATE_TEXT(l.benef_bban           ,vv_LISTE_CARACT_AUTORISE),1,30 );
     vv_step := '016j : vv_benef_iban :';           vv_benef_iban           := substr(TRANSLATE_TEXT(l.benef_iban           ,vv_LISTE_CARACT_AUTORISE),1,60 );
     vv_step := '016k : vv_benef_code_pays :';      vv_benef_code_pays      := substr(TRANSLATE_TEXT(l.benef_code_pays      ,vv_LISTE_CARACT_AUTORISE),1,2  );
     vv_step := '016l : vv_benef_bic :';            vv_benef_bic            := substr(TRANSLATE_TEXT(l.benef_bic            ,vv_LISTE_CARACT_AUTORISE),1,20 );
     vv_step := '016m : vv_adresse1 :';             vv_adresse1             := substr(TRANSLATE_TEXT(l.adresse1             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016n : vv_adresse2 :';             vv_adresse2             := substr(TRANSLATE_TEXT(l.adresse2             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016o : vv_adresse3 :';             vv_adresse3             := substr(TRANSLATE_TEXT(l.adresse3             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016p : vv_adresse4 :';             vv_adresse4             := substr(TRANSLATE_TEXT(l.adresse4             ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016q : vv_cp :';                   vv_cp                   := substr(TRANSLATE_TEXT(l.cp                   ,vv_LISTE_CARACT_AUTORISE),1,20 );
     vv_step := '016r : vv_city :';                 vv_city                 := substr(TRANSLATE_TEXT(l.city                 ,vv_LISTE_CARACT_AUTORISE),1,35 );
     vv_step := '016s : vv_code_pays :';            vv_code_pays            := substr(TRANSLATE_TEXT(l.code_pays            ,vv_LISTE_CARACT_AUTORISE),1,2  );
     vv_step := '016t : vv_FINANCIALCHARGEALLOC :'; vv_FINANCIALCHARGEALLOC := substr(TRANSLATE_TEXT(vv_FINANCIALCHARGEALLOC,vv_LISTE_CARACT_AUTORISE),1,1  );
     vv_step := '016u : vv_COUNTERPARTYMESSAGE :';  vv_COUNTERPARTYMESSAGE  := substr(TRANSLATE_TEXT(vv_COUNTERPARTYMESSAGE ,vv_LISTE_CARACT_AUTORISE),1,100); 
     vv_step := '016v : vv_CHECK_RUNNAME_GG :';     vv_CHECK_RUNNAME_GG     := substr(TRANSLATE_TEXT(vv_CHECK_RUNNAME_GG    ,vv_LISTE_CARACT_AUTORISE),1,100); 
                                                                                                                                  
    --
    
    
    IF vb_valid THEN
     SELECT DKA_IEOAPSAT01_APIMP_LINE_S.Nextval
     INTO vn_line_id
     FROM DUAL;
       
     vv_step := '017 : vn_line_id :'||vn_line_id;
     dka_tools_pkg.put_debug_message(vv_step);
     
     INSERT INTO DKA_IEOAPSAT01_APIMP_LINE
       (HEADER_ID,
        LINE_ID,
        CREATED_BY,
        CREATION_DATE,
        LAST_UPDATED_BY,
        LAST_UPDATE_DATE,
        LAST_UPDATE_LOGIN,
        CHECKRUN_NAME,
        VENDOR_ID,
        VENDOR_SITE_ID,
        ENTITYID,
        COUNTERPARTYID,
        CASHFLOWTYPE,
        PAYMENTMETHOD,
        PRIORITYID,
        VALUEDATE,
        TRANSACTIONDATE,
        ENTITYBANKACCOUNTNUMBER,
        CURRENCYCODE,
        AMOUNT,
        COUNTERPARTYNAME,
        COUNTERPARTYBANKACCOUNTNUMBER,
        CPTYSECONDARYACCOUNTNUMBER,
        COUNTERPARTYBANKACCOUNTCOUNTRY,
        COUNTERPARTYBANKCODE,
        COUNTERPARTYBANKBRANCHID,
        COUNTERPARTYADDRESS1,
        COUNTERPARTYADDRESS2,
        COUNTERPARTYADDRESS3,
        COUNTERPARTYADDRESS4,
        COUNTERPARTYSTATE,
        COUNTERPARTYCITY,
        COUNTERPARTYCOUNTRYCODE,
        COUNTERPARTYMESSAGE,
        CHECK_RUNNAME_GG,   
        FINANCIALCHARGEALLOCATION,
        CUSTOMERREFERENCENUMBER,
        BANKINSTRUCTIONS,
        DESCRIPTION_REFERENCE,
        TRANSACTIONTYPECODE,
        INTERMEDIARYBANKSWIFTCODE,
        INTERMEDIARYBANKNAME,
        INTERMEDIARYBANKADRESSE1,
        INTERMEDIARYBANKADRESSE2,
        INTERMEDIARYBANKADRESSE3,
        INTERMEDIARYBANKADRESSE4,
        SECONDINTERMEDIARYBANKSWIFT,
        SECONDINTERMEDIARYBANKNAME,
        SECONDINTERMEDIARYBANKADRESSE1,
        SECONDINTERMEDIARYBANKADRESSE2,
        SECONDINTERMEDIARYBANKADRESSE3,
        SECONDINTERMEDIARYBANKADRESSE4,
        CHEQUENUMBER,
        COMMENTS,
        RESERVE9,
        RESERVE8,
        RESERVE7,
        RESERVE6,
        RESERVE5,
        RESERVE4,
        RESERVE3,
        RESERVE2,
        RESERVE1
       )
     VALUES (
        vn_header_id,                  --HEADER_ID
        vn_line_id,                    --LINE_ID
        fnd_profile.value('USER_ID'),  --CREATED_BY
        SYSDATE,                       --CREATION_DATE
        fnd_profile.value('USER_ID'),  --LAST_UPDATED_BY
        SYSDATE,                       --LAST_UPDATE_DATE
        fnd_profile.value('LOGIN_ID'), --LAST_UPDATE_LOGIN
        l.checkrun_name,               --CHECKRUN_NAME
        l.vendor_id,                   --VENDOR_ID
        l.vendor_site_id,              --VENDOR_SITE_ID
        --vv_code_agora,                --ENTITYID --RBE MigR12
        vv_societe,                     --ENTITYID --RBE MigR12
        --vv_counterpartyid_l,           --COUNTERPARTYID --RBE MigR12
        'NO',           --COUNTERPARTYID --RBE MigR12
        vv_CASHFLOWTYPE,               --CASHFLOWTYPE
        vv_PAYMENTMETHOD,              --PAYMENTMETHOD
        vv_PRIORITYID,                 --PRIORITYID
        trunc(vv_value_date),          --VALUEDATE
        trunc(l.date_paiement),        --TRANSACTIONDATE
        vv_emetteur_iban,              --ENTITYBANKACCOUNTNUMBER
        vv_code_devise,                --CURRENCYCODE
        l.montant_paiement,            --AMOUNT
        vv_nom_destinataire,           --COUNTERPARTYNAME
        vv_benef_bban,                 --COUNTERPARTYBANKACCOUNTNUMBER
        vv_benef_iban,                 --CPTYSECONDARYACCOUNTNUMBER
        vv_benef_code_pays,            --COUNTERPARTYBANKACCOUNTCOUNTRY
        vv_benef_bic,                  --COUNTERPARTYBANKCODE
        NULL,                          --COUNTERPARTYBANKBRANCHID
        --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
        --decode(l.vendor_type_lookup_code, 'EMPLOYEE', NULL, nvl(vv_adresse1,vv_default_address)),--COUNTERPARTYADDRESS1
        decode(l.vendor_type_lookup_code, 'EMPLOYEE', vv_default_address, nvl(vv_adresse1,vv_default_address)),--COUNTERPARTYADDRESS1
        vv_adresse2,                   --COUNTERPARTYADDRESS2
        vv_adresse3,                   --COUNTERPARTYADDRESS3
        vv_adresse4,                   --COUNTERPARTYADDRESS4
        vv_cp,                         --COUNTERPARTYSTATE
        vv_city,                       --COUNTERPARTYCITY
        --- 04/01/2017 NBO artf2069726 - INT004 - Campagne de règlements - Employé - Defect Flux_Si_Dalkia #242
        decode(l.vendor_type_lookup_code, 'EMPLOYEE', l.code_pays_emp, vv_code_pays),                  --COUNTERPARTYCOUNTRYCODE
        vv_COUNTERPARTYMESSAGE,        --COUNTERPARTYMESSAGE
        vv_CHECK_RUNNAME_GG,           --CHECK_RUNNAME_GG --RBE artf2092291 
        vv_FINANCIALCHARGEALLOC,       --FINANCIALCHARGEALLOCATION
        NULL,                          --CUSTOMERREFERENCENUMBER
        NULL,                          --BANKINSTRUCTIONS
        NULL,                          --DESCRIPTION_REFERENCE
        NULL,                          --TRANSACTIONTYPECODE
        NULL,                          --INTERMEDIARYBANKSWIFTCODE
        NULL,                          --INTERMEDIARYBANKNAME
        NULL,                          --INTERMEDIARYBANKADRESSE1
        NULL,                          --INTERMEDIARYBANKADRESSE2
        NULL,                          --INTERMEDIARYBANKADRESSE3
        NULL,                          --INTERMEDIARYBANKADRESSE4
        NULL,                          --SECONDINTERMEDIARYBANKSWIFT
        NULL,                          --SECONDINTERMEDIARYBANKNAME
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE1
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE2
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE3
        NULL,                          --SECONDINTERMEDIARYBANKADRESSE4
        NULL,                          --CHEQUENUMBER
        NULL,                          --COMMENTS
        NULL,                          --RESERVE9
        NULL,                          --RESERVE8
        NULL,                          --RESERVE7
        NULL,                          --RESERVE6
        NULL,                          --RESERVE5
        NULL,                          --RESERVE4
        NULL,                          --RESERVE3
        NULL,                          --RESERVE2
        NULL                           --RESERVE1
     );
     
     vn_ligne_cpt := vn_ligne_cpt + 1;
    
    ELSE
     --Ligne non valide
     --On sort de la boucle en erreur
     vv_step := '018 : Ligne non valide';
     dka_tools_pkg.put_debug_message(vv_step);
      
     RAISE E_LIGNE;
     
    END IF;
    
    --LIGNE SUIVANTE
    vv_step := '019 : LIGNE SUIVANTE';
    dka_tools_pkg.put_debug_message(vv_step);
  
  END LOOP;

  --RBE MigR12
  UPDATE dka_sapautorgt_tmp
  SET status_flag = 'T'
  WHERE checkrun_id = rec_dem_rbt.checkrun_id
  ;
  
END LOOP;

--END EDB295



  --MAJ du montant sur l'entete
  vv_step := '020 : MAJ du montant sur l''entete';
  dka_tools_pkg.put_debug_message(vv_step);
  UPDATE DKA_IEOAPSAT01_APIMP_HDR dih
  SET
   dih.ctrl_amount = (SELECT SUM(dil.amount)
                      FROM DKA_IEOAPSAT01_APIMP_LINE dil
                      WHERE dih.header_id = dil.header_id)
  WHERE REQUEST_ID = fnd_global.CONC_REQUEST_ID;

  COMMIT; -------

  --COMPTE-RENDU
  vv_step := '021 : COMPTE-RENDU';
  dka_tools_pkg.put_debug_message(vv_step);
  
  dka_tools_pkg.put_out_header;
  dka_tools_pkg.put_outdebug_message('Nombre d''en-têtes créées : '||vn_entete_cpt);
  dka_tools_pkg.put_outdebug_message('Nombre de lignes créées  : '||vn_ligne_cpt);
  
  vv_step := '999 : FIN';
  dka_tools_pkg.put_debug_message(vv_step);

EXCEPTION
 WHEN E_ENTETE THEN
  --Entête non valide
  ROLLBACK;
  pn_retcode := 2;
  pv_errbuf  := vv_err_buf;
 WHEN E_LIGNE THEN
  --Ligne non valide
  ROLLBACK;
  pn_retcode := 2;
  pv_errbuf  := vv_err_buf;
 WHEN OTHERS THEN
  ---
  ROLLBACK;
  pn_retcode := 2;
  pv_errbuf  := vv_err_buf || chr(10) || vv_step || ' : ' || SQLERRM;
END main;


END DKA_IEOAPSAT01_APIMP_PKG ;

/
show errors
exit
