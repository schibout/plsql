CREATE OR REPLACE PACKAGE BODY dka_fusion_ap_pkg AS
  ---PROD------------------------------------------------------------------------------------------------------------
  -- CAP GEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_FUSION_AP_PKG.pks
  -- DESCRIPTION       : DKA_FUSION_AP_PKG package body :
  ---
  --- AUTEUR       : O.CLEMENT (Capgemini)
  --- DATE DE CREATION : 09/2019
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS

  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---------------------------------------------------------------------------------------------------------------

  -- Types tableaux de segments et CCIDs
  TYPE vt_segment_type IS TABLE OF gl_code_combinations.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE vt_ccid_type IS TABLE OF gl_code_combinations.code_combination_id%TYPE INDEX BY BINARY_INTEGER;

  -- Tableaux des combinaisons des segments / CCID des lignes de distribution deja traitees
  vt_segment1_dist  vt_segment_type;
  vt_segment2_dist  vt_segment_type;
  vt_segment3_dist  vt_segment_type;
  vt_segment4_dist  vt_segment_type;
  vt_segment5_dist  vt_segment_type;
  vt_segment6_dist  vt_segment_type;
  vt_segment7_dist  vt_segment_type;
  vt_segment8_dist  vt_segment_type;
  vt_segment9_dist  vt_segment_type;
  vt_segment10_dist vt_segment_type;
  vt_segment11_dist vt_segment_type;
  vt_segment12_dist vt_segment_type;
  vt_ccid_dist      vt_ccid_type;

  vn_nbre_rangs_dist BINARY_INTEGER := 0;

  -- Tableaux des combinaisons des segments / CCID PAY des entetes de factures deja traitees
  vt_segment1_pay  vt_segment_type;
  vt_segment2_pay  vt_segment_type;
  vt_segment3_pay  vt_segment_type;
  vt_segment4_pay  vt_segment_type;
  vt_segment5_pay  vt_segment_type;
  vt_segment6_pay  vt_segment_type;
  vt_segment7_pay  vt_segment_type;
  vt_segment8_pay  vt_segment_type;
  vt_segment9_pay  vt_segment_type;
  vt_segment10_pay vt_segment_type;
  vt_segment11_pay vt_segment_type;
  vt_segment12_pay vt_segment_type;
  vt_ccid_pay      vt_ccid_type;

  vn_nbre_rangs_pay BINARY_INTEGER := 0;

  -- Tableaux des classes de reglements deja traitees
  TYPE vt_pay_group_type IS TABLE OF fnd_doc_sequence_categories.code%TYPE INDEX BY BINARY_INTEGER;
  TYPE vt_pay_group_ok_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  vt_pay_group    vt_pay_group_type;
  vt_pay_group_ok vt_pay_group_ok_type;

  vn_nbre_rangs_pay_group BINARY_INTEGER := 0;

  -- Une erreur sur un controle fonctionnel ?
  vb_erreur_ctr BOOLEAN := FALSE;

  -- Nbre d'enregistrements inseres dans les table temporaire
  vn_nbre_entetes NUMBER := 0;
  vn_nbre_lignes  NUMBER := 0;

  -- Flag debug
  vv_debug_flag VARCHAR2(1) := 'N';

  -- Nveau du debug
  vn_position_debug NUMBER := 0;

  -- Tableau des categories/sequences n'existant pas
  TYPE vt_category_code_type IS TABLE OF fnd_doc_sequence_categories.name%TYPE INDEX BY BINARY_INTEGER;
  vt_category_code vt_category_code_type;

  vn_nbre_rangs_category BINARY_INTEGER := 0;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_PRINT_DEBUG_F
  --  Description   : Impression du message de debug
  --
  --  PARAMETRES    : Incrementation du niveau de debug
  --                  Caractere precedent de debug
  --                  Message de debug
  --                  Ex: > Message de niveau 1
  --                      >>> Message de niveau 2
  --                      >>>>> Message de niveau 3
  --                      >>>>> Fin de niveau 3
  --                      >>> Fin de niveau 2
  --                      < Fin de niveau 3
  --                  Si on ne veut pas gerer d'incrementation des messages,
  --                  passer 0 a Pv_Position_Debug
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_print_debug_f(pv_position_debug IN NUMBER,
                             pv_marque         IN VARCHAR2,
                             pv_msg            IN VARCHAR2)
  
   RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
  BEGIN
    IF pv_position_debug > 0 THEN
      vn_position_debug := vn_position_debug + pv_position_debug;
    END IF;
  
    IF nvl(vv_debug_flag, 'N') = 'Y' THEN
      dka_tools_pkg.put_debug_message(lpad(' ',
                                           2 * vn_position_debug,
                                           pv_marque) || pv_msg);
    END IF;
  
    IF pv_position_debug < 0 THEN
      vn_position_debug := vn_position_debug + pv_position_debug;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_PRINT_DEBUG_F (' ||
                                      pv_position_debug || ',' ||
                                      pv_marque || ',' || pv_msg || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_print_debug_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_VERIF_PARAM
  --  Description   : Ctrl du nombre de valeur active dans FUSION_SOCIETE_VERS_SOCIETE
  --
  --  PARAMETRES    : Numero de factuure (message)
  --                  Code journal
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_verif_param RETURN NUMBER IS
  
    dka_erreur_oracle VARCHAR2(80);
    vv_trash          VARCHAR2(1);
    vn_count          NUMBER;
  BEGIN
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_VERIF_PARAM') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    SELECT COUNT(*)
      INTO vn_count
      FROM dka_stransco_headers dsh, dka_stransco_lines dsl
     WHERE dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
       AND dsl.set_id = dsh.set_id
       AND dsl.enable = 'Y';
  
    RETURN vn_count;
  EXCEPTION
    WHEN no_data_found THEN
    
      RETURN 0;
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_VERIF_PARAM ');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN - 1;
  END dka_verif_param;

  -----------------------------------------------------------------
  --  Nom           : get_all_segments
  --  Description   : donne la valeur des segments  du ccid s'il existe
  --
  --  PARAMETRES :
  --     ccid            entrée     NUMBER   =>  code_combination
  --     seg1            sortie     VARCHAR2 =>  segment1
  --     seg2            sortie     VARCHAR2 =>  segment2
  --     seg3            sortie     VARCHAR2 =>  segment3
  --     seg4            sortie     VARCHAR2 =>  segment4
  --     seg5            sortie     VARCHAR2 =>  segment5
  --     seg6            sortie     VARCHAR2 =>  segment6
  --     seg7            sortie     VARCHAR2 =>  segment7
  --     seg8            sortie     VARCHAR2 =>  segment8
  --     seg9            sortie     VARCHAR2 =>  segment9
  --     seg10            sortie     VARCHAR2 =>  segment10
  --     seg11            sortie     VARCHAR2 =>  segment11
  --     seg12            sortie     VARCHAR2 =>  segment12
  --     errbuf          sortie     varchar2 =>  buffer du message de sortie
  --     retcode         sortie     number   =>  code de sortie
  --
  -----------------------------------------------------------------

  PROCEDURE get_all_segments(ccid    IN gl_code_combinations.code_combination_id%TYPE,
                             seg1    OUT VARCHAR2,
                             seg2    OUT VARCHAR2,
                             seg3    OUT VARCHAR2,
                             seg4    OUT VARCHAR2,
                             seg5    OUT VARCHAR2,
                             seg6    OUT VARCHAR2,
                             seg7    OUT VARCHAR2,
                             seg8    OUT VARCHAR2,
                             seg9    OUT VARCHAR2,
                             seg10   OUT VARCHAR2,
                             seg11   OUT VARCHAR2,
                             seg12   OUT VARCHAR2,
                             errbuf  OUT VARCHAR2,
                             retcode OUT NUMBER) IS
    error_get_e EXCEPTION;
  BEGIN
  
    errbuf  := '';
    retcode := 0;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'GET_ALL_SEGMENTS(' || ccid || ')') THEN
      -- Probleme
      retcode := 2;
      RAISE error_get_e;
    END IF;
  
    SELECT gcc.segment1,
           gcc.segment2,
           gcc.segment3,
           gcc.segment4,
           gcc.segment5,
           gcc.segment6,
           gcc.segment7,
           gcc.segment8,
           gcc.segment9,
           gcc.segment10,
           gcc.segment11,
           gcc.segment12
      INTO seg1,
           seg2,
           seg3,
           seg4,
           seg5,
           seg6,
           seg7,
           seg8,
           seg9,
           seg10,
           seg11,
           seg12
      FROM gl_code_combinations gcc
     WHERE gcc.code_combination_id = ccid;
  
    IF NOT dka_print_debug_f(pv_position_debug => 0,
                             pv_marque         => '*',
                             pv_msg            => 'segments found') THEN
      -- Probleme
      retcode := 2;
      RAISE error_get_e;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'GET_ALL_SEGMENTS(' || ccid || ')') THEN
      -- Probleme
      retcode := 2;
      RAISE error_get_e;
    END IF;
  
  EXCEPTION
    WHEN error_get_e THEN
      NULL;
    WHEN no_data_found THEN
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => 'segments not found') THEN
        NULL;
      END IF;
      errbuf  := 'CCID ' || ccid || ' inexistant';
      retcode := 1;
    WHEN OTHERS THEN
      errbuf  := SQLERRM || chr(10) ||
                 'erreur selection segments pour le ccid ' || ccid;
      retcode := 2;
    
  END get_all_segments;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_LOAD_TAB_CATEGORY_F
  --  Description   : Chargement du tableau referencant les categories/sequences n'existant pas
  --                  Infos a editer a la fin du traitement
  --
  --  PARAMETRES    : Id de la sequence origine
  --                  Numero de facture (Message)
  --                  Societe (Message)
  --                  SOB
  --                  Date
  --
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_load_tab_category_f(pn_doc_seq_id    IN NUMBER,
                                   pv_category_code IN VARCHAR2)
    RETURN BOOLEAN IS
  
    dka_erreur_oracle    VARCHAR2(80);
    vn_rang              BINARY_INTEGER := 0;
    vv_doc_sequence_name fnd_document_sequences.name%TYPE;
  
  BEGIN
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_LOAD_TAB_CATEGORY_F  (' ||
                                               pn_doc_seq_id || ',' ||
                                               pv_category_code || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    SELECT fds.name
      INTO vv_doc_sequence_name
      FROM fnd_document_sequences fds
     WHERE fds.doc_sequence_id = pn_doc_seq_id;
  
    FOR i IN 1 .. vn_nbre_rangs_category LOOP
      IF vt_category_code(i) = pv_category_code THEN
        -- Categorie/sequence deja traitee
        vn_rang := i;
      END IF;
    END LOOP;
  
    IF vn_rang = 0 THEN
      -- Categorie /sequence pas encore traitee
      -- -> Chargement dans les tableaux
      vn_nbre_rangs_category := vn_nbre_rangs_category + 1;
      vt_category_code(vn_nbre_rangs_category) := pv_category_code;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_LOAD_TAB_CATEGORY_F  (' ||
                                               pn_doc_seq_id || ',' ||
                                               pv_category_code || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_LOAD_TAB_CATEGORY_F  (' ||
                                      pn_doc_seq_id || ',' ||
                                      pv_category_code || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_load_tab_category_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_MVTS
  --  Description   : Ctrl des mouvements dont le fournisseur est l'une des sociétés
  --                  absorbante
  --  PARAMETRES    : Numero de factuure (message)
  --                  Code journal
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_mvts(pv_invoice_num        IN VARCHAR2,
                        pn_ccid               IN NUMBER,
                        pv_societe_absorbante IN VARCHAR2,
                        pv_invoice_id         IN NUMBER,
                        pv_name               IN VARCHAR2,
                        pv_amount             IN NUMBER,
                        pv_creation_date      IN DATE,
                        pv_source             IN VARCHAR2) RETURN BOOLEAN IS
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
    vv_errbuf    VARCHAR2(32000) := NULL;
    vn_retcode   NUMBER := 0;
  
  BEGIN
    -- récupération des segments
    get_all_segments(pn_ccid,
                     seg1    => vv_segment1,
                     seg2    => vv_segment2,
                     seg3    => vv_segment3,
                     seg4    => vv_segment4,
                     seg5    => vv_segment5,
                     seg6    => vv_segment6,
                     seg7    => vv_segment7,
                     seg8    => vv_segment8,
                     seg9    => vv_segment9,
                     seg10   => vv_segment10,
                     seg11   => vv_segment11,
                     seg12   => vv_segment12,
                     errbuf  => vv_errbuf,
                     retcode => vn_retcode);
    IF vn_retcode <> 0 THEN
      -- Probleme
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      RETURN FALSE;
    END IF;
  
    IF vv_segment5 = 'XXX' || pv_societe_absorbante THEN
      dka_tools_pkg.put_outdebug_message('Mouvement dont le code interco du fournisseur est sur societe absorbante : ' ||
                                         pv_invoice_num || '/' ||
                                         pv_invoice_id || '/' || pv_name || '/' ||
                                         pv_amount || '/' ||
                                         pv_creation_date || '/' ||
                                         pv_source);
      vb_erreur_ctr := TRUE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
  
    WHEN OTHERS THEN
      vv_errbuf := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_CTR_MVTS (' ||
                                      pv_invoice_num);
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      RETURN FALSE;
  END dka_ctr_mvts;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_FOURNISSEUR
  --  Description   : Ctrl compte fournisseur existant sur société absorbant|e
  --  PARAMETRES    : Numero de factuure (message)
  --                  Code journal
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_fournisseur(pv_invoice_num        IN VARCHAR2,
                               pn_ccid               IN NUMBER,
                               pv_societe_absorbante VARCHAR2,
                               pv_invoice_id         IN NUMBER,
                               pv_name               IN VARCHAR2,
                               pv_amount             IN NUMBER,
                               pv_creation_date      IN DATE,
                               pv_source             IN VARCHAR2)
    RETURN BOOLEAN IS
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
    vv_errbuf    VARCHAR2(32000) := NULL;
    vn_retcode   NUMBER := 0;
    vn_new_ccid  gl_code_combinations.code_combination_id%TYPE;
  
  BEGIN
    -- récupération des segments
    get_all_segments(pn_ccid,
                     seg1    => vv_segment1,
                     seg2    => vv_segment2,
                     seg3    => vv_segment3,
                     seg4    => vv_segment4,
                     seg5    => vv_segment5,
                     seg6    => vv_segment6,
                     seg7    => vv_segment7,
                     seg8    => vv_segment8,
                     seg9    => vv_segment9,
                     seg10   => vv_segment10,
                     seg11   => vv_segment11,
                     seg12   => vv_segment12,
                     errbuf  => vv_errbuf,
                     retcode => vn_retcode);
    IF vn_retcode <> 0 THEN
      -- Problème
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      RETURN FALSE;
    END IF;
    -- On remplace le segment1 par la société absorbante
    vv_segment1 := pv_societe_absorbante;
    -- 2. recherche du nouveau ccid
    dka_tools_pkg.get_code_combination_id(pv_segment1            => vv_segment1,
                                          pv_segment2            => vv_segment2,
                                          pv_segment3            => vv_segment3,
                                          pv_segment4            => vv_segment4,
                                          pv_segment5            => vv_segment5,
                                          pv_segment6            => vv_segment6,
                                          pv_segment7            => vv_segment7,
                                          pv_segment8            => vv_segment8,
                                          pv_segment9            => vv_segment9,
                                          pv_segment10           => vv_segment10,
                                          pv_segment11           => vv_segment11,
                                          pv_segment12           => vv_segment12,
                                          pn_code_combination_id => vn_new_ccid,
                                          pv_errbuf              => vv_errbuf,
                                          pn_retcode             => vn_retcode,
                                          pv_validation_flag     => 'Y');
    --   si combinaison inexistante
    IF nvl(vn_new_ccid, 0) = 0 THEN
      dka_tools_pkg.put_outdebug_message('Compte fournisseur inexistant sur société absorbante pour la facture');
      dka_tools_pkg.put_outdebug_message(pv_invoice_num || '/' ||
                                         pv_invoice_id || '/' || pv_amount || '/' ||
                                         pv_creation_date || '/' ||
                                         pv_source);
      vb_erreur_ctr := TRUE;
    END IF;
    RETURN TRUE;
  EXCEPTION
  
    WHEN OTHERS THEN
      vv_errbuf := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_CTR_FOURNISSEUR ' ||
                                      pv_invoice_num);
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      RETURN FALSE;
  END dka_ctr_fournisseur;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_FOURNISSEUR
  --  Description   : Ctrl compte fournisseur existant sur société absorbant|e
  --  PARAMETRES    : Numero de factuure (message)
  --                  Code journal
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_site_fournisseur(pn_vendor_id         IN NUMBER,
                                    pn_vendor_site_id    IN NUMBER,
                                    pv_vendor_name       IN VARCHAR2,
                                    pv_vendor_site_code  IN VARCHAR2,
                                    pv_segment1          IN VARCHAR2,
                                    pn_org_id_absorbante IN NUMBER)
    RETURN BOOLEAN IS
    vv_errbuf         VARCHAR2(32000) := NULL;
    vn_retcode        NUMBER := 0;
    vn_vendor_site_id NUMBER := 0;
    vn_party_site_id  NUMBER := 0;
    vv_pay_site_flag  VARCHAR(10) := 'N';
  BEGIN
  
    SELECT vendor_site_id, party_site_id, asa.PAY_SITE_FLAG
      INTO vn_vendor_site_id, vn_party_site_id, vv_pay_site_flag
      FROM ap_supplier_sites_all asa
     WHERE org_id = pn_org_id_absorbante
       AND vendor_id = pn_vendor_id
       AND location_id IN
           (SELECT location_id
              FROM ap_supplier_sites_all
             WHERE vendor_site_id = pn_vendor_site_id);
  
    IF vv_pay_site_flag = 'N' THEN
      dka_tools_pkg.put_outdebug_message('Attention , Site fournisseur existant société absorbante mais le site n''est pas site de règlement : ' ||
                                         pv_segment1 || '/' ||
                                         pv_vendor_name || '/' ||
                                         pn_vendor_id);
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --  dka_tools_pkg.put_outdebug_message('Site fournisseur inexistant sur société absorbante');
      dka_tools_pkg.put_outdebug_message(pv_segment1 || '/' ||
                                         pv_vendor_site_code || '/' ||
                                         pv_vendor_name || '/' ||
                                         pn_vendor_id || '/' ||
                                         pn_vendor_site_id);
      vb_erreur_ctr := TRUE;
      RETURN TRUE;
    WHEn TOO_MANY_ROWS then
      dka_tools_pkg.put_outdebug_message('Plusieurs site pour la même adresse  : ' ||
                                         pv_segment1 || '/' ||
                                         pv_vendor_site_code || '/' ||
                                         pv_vendor_name || '/' ||
                                         pn_vendor_id || '/' ||
                                         pn_vendor_site_id);
      return true;
    WHEN OTHERS THEN
      vv_errbuf := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_CTR_SITE_FOURNISSEUR ' ||
                                      pn_vendor_id);
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      RETURN FALSE;
  END dka_ctr_site_fournisseur;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_REJETS
  --  Description   : Ctrl des factures en rejet dans l'open interface AP
  --
  --  PARAMETRES    : Numero de factuure (message)
  --                  Code journal
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_rejets RETURN BOOLEAN IS
    CURSOR cur_rejets IS
      SELECT aii.invoice_num,
             aii.invoice_id,
             hou.name,
             aii.invoice_amount,
             air.reject_lookup_code motif
        FROM ap_invoices_interface   aii,
             dka_stransco_headers    dsh,
             dka_stransco_lines      dsl,
             hr_operating_units      hou,
             ap_interface_rejections air
       WHERE dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsl.set_id = dsh.set_id
         AND dsl.enable = 'Y'
         AND hou.name = dsl.param1_value
         AND aii.org_id = hou.organization_id
         AND aii.status = 'REJECTED'
         AND air.parent_table = 'AP_INVOICES_INTERFACE'
         AND air.parent_id = aii.invoice_id;
    vv_errbuf  VARCHAR2(32000);
    rec_rejets cur_rejets%ROWTYPE;
  BEGIN
  
    dka_tools_pkg.put_outdebug_message('Facture en rejet dans l''open interface AP : ');
    FOR rec_rejets IN cur_rejets LOOP
    
      dka_tools_pkg.put_outdebug_message(rec_rejets.invoice_num || '/' ||
                                         rec_rejets.invoice_id || '/' ||
                                         rec_rejets.name || '/' ||
                                         rec_rejets.invoice_amount || '/' ||
                                         rec_rejets.motif);
      -- Erreur lors d'un controle
      vb_erreur_ctr := TRUE;
    END LOOP;
    RETURN TRUE;
  EXCEPTION
    WHEN no_data_found THEN
    
      RETURN TRUE;
    WHEN OTHERS THEN
      vv_errbuf := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_CTR_REJETS ');
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      RETURN FALSE;
  END dka_ctr_rejets;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_CATEGORY_CODE_F
  --  Description   : Ctrl que le code journal passe en parametre existe
  --
  --  PARAMETRES    : Numero de factuure (message)
  --                  Code journal
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_category_code_f(pv_invoice_num   IN VARCHAR2,
                                   pv_category_code IN VARCHAR2)
    RETURN NUMBER IS
  
    dka_erreur_oracle VARCHAR2(80);
    vv_trash          VARCHAR2(1);
  
  BEGIN
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_CTR_CATEGORY_CODE_F(' ||
                                                  pv_invoice_num || ',' ||
                                                  pv_category_code) THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    SELECT 'X'
      INTO vv_trash
      FROM fnd_doc_sequence_categories fdsc
     WHERE fdsc.code = pv_category_code
       AND fdsc.application_id = 200;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => 'Categorie ' ||
                                               pv_category_code || ' found') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_CTR_CATEGORY_CODE_F(' ||
                                                  pv_invoice_num || ',' ||
                                                  pv_category_code) THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    RETURN 1;
  EXCEPTION
    WHEN no_data_found THEN
      dka_tools_pkg.put_outdebug_message('Facture ' || pv_invoice_num ||
                                         ' : Categorie ' ||
                                         pv_category_code ||
                                         ' n''existe pas');
    
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => 'Categorie ' ||
                                                    pv_category_code ||
                                                    ' not found') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => -1,
                               pv_marque         => '<',
                               pv_msg            => 'DKA_CTR_CATEGORY_CODE_F(' ||
                                                    pv_invoice_num || ',' ||
                                                    pv_category_code) THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      -- Erreur lors d'un controle
      vb_erreur_ctr := TRUE;
      RETURN 0;
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur Dka_Ctr_Category_Code_F (' ||
                                      pv_invoice_num || ',' ||
                                      pv_category_code || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN - 1;
  END dka_ctr_category_code_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_DOC_SEQ_ASS_F
  --  Description   : Ctrl que la sequence AP dont l'id est passe en parametre, est affectee a l'entite
  --                  et a la date passee en parametre ( Methode automatique)
  --
  --  PARAMETRES    : Id de la sequence origine
  --                  Numero de facture (Message)
  --                  Societe (Message)
  --                  SOB
  --                  Date
  --
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_doc_seq_ass_f(pn_doc_seq_id    IN NUMBER,
                                 pv_invoice_num   IN VARCHAR2,
                                 pv_societe       IN VARCHAR2,
                                 pn_sob_id        IN NUMBER,
                                 pd_date          IN DATE,
                                 pv_category_code IN VARCHAR2) RETURN BOOLEAN IS
  
    dka_erreur_oracle             VARCHAR2(80);
    vn_doc_sequence_assignment_id fnd_doc_sequence_assignments.doc_sequence_assignment_id%TYPE;
  
  BEGIN
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_CTR_DOC_SEQ_ASS_F (' ||
                                               pn_doc_seq_id || ',' ||
                                               pv_invoice_num || ',' ||
                                               pv_societe || ',' || pn_sob_id || ',' ||
                                               to_char(pd_date, 'DD/MM/YYYY') || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    BEGIN
      SELECT fdsa.doc_sequence_assignment_id
        INTO vn_doc_sequence_assignment_id
        FROM fnd_doc_sequence_assignments fdsa
       WHERE fdsa.application_id = 200
         AND fdsa.set_of_books_id = pn_sob_id
         AND trunc(pd_date) >= trunc(nvl(fdsa.start_date, SYSDATE))
            -- AND trunc(pd_date) <= trunc(nvl(fdsa.end_date, SYSDATE))
         AND fdsa.category_code = pv_category_code
         and rownum = 1;
      /*AND fdsa.method_code = 'A';*/
    EXCEPTION
      WHEN no_data_found THEN
        dka_tools_pkg.put_outdebug_message('Affectation de séquence manquante  ' ||
                                           pn_sob_id || ',' ||
                                           pv_invoice_num || ',' ||
                                           pv_societe || ',' ||
                                           pv_category_code || ',' ||
                                           to_char(pd_date, 'DD/MM/YYYY') || '');
        RETURN true;
      
      -- Erreur lors d'un controle
      -- Vb_Erreur_Ctr := TRUE;
      -- Ce n'est pas un ctrl bloquant
    END;
  
    IF vn_doc_sequence_assignment_id <> 0 THEN
    
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '*',
                               pv_msg            => 'Sequence ' ||
                                                    pv_category_code ||
                                                    ' assigned') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_CTR_DOC_SEQ_ASS_F (' ||
                                               pn_doc_seq_id || ',' ||
                                               pv_invoice_num || ',' ||
                                               pv_societe || ',' || pn_sob_id || ',' ||
                                               to_char(pd_date, 'DD/MM/YYYY') || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_CTR_DOC_SEQ_ASS_F  (' ||
                                      pn_doc_seq_id || ',' ||
                                      pv_invoice_num || ',' || pv_societe || ',' ||
                                      pn_sob_id || ',' ||
                                      to_char(pd_date, 'DD/MM/YYYY') || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_ctr_doc_seq_ass_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_DOC_SEQUENCE_F
  --  Description   : Ctrl que le code journal dont l'id est passe en parametre existe
  --                  sur la societe absorbante
  --
  --  PARAMETRES    : Id de la sequence origine
  --                  Numero de facture (Message)
  --                  Societe absorbee
  --                  Societe absorbante
  --                  Id de la sequence destination
  --
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_doc_sequence_f(pn_doc_seq_id_orig    IN NUMBER,
                                  pv_invoice_num        IN VARCHAR2,
                                  pv_societe_absorbee   IN VARCHAR2,
                                  pv_societe_absorbante IN VARCHAR2,
                                  pv_source             IN VARCHAR2,
                                  pn_soc_seq_id_dest    OUT NUMBER)
    RETURN BOOLEAN IS
  
    dka_erreur_oracle    VARCHAR2(80);
    vv_doc_sequence_name fnd_document_sequences.name%TYPE;
  
  BEGIN
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_CTR_DOC_SEQUENCE_F(' ||
                                               pn_doc_seq_id_orig || ',' ||
                                               pv_invoice_num ||
                                               pv_societe_absorbee || ',' ||
                                               pv_societe_absorbante || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
    IF pv_source = 'SCAN_XGS' THEN
      -- Si les 4 caracteres = societe absorbee, on remplace par societe absorbante
      SELECT REPLACE(substr(fdc_orig.name, 1, 4),
                     pv_societe_absorbee,
                     pv_societe_absorbante) || substr(fdc_orig.name, 5),
             nvl(fdc_dest.doc_sequence_id, 0)
        INTO vv_doc_sequence_name, pn_soc_seq_id_dest
        FROM fnd_document_sequences fdc_orig,
             fnd_document_sequences fdc_dest
       WHERE fdc_orig.doc_sequence_id = pn_doc_seq_id_orig
         AND fdc_dest.name(+) =
             REPLACE(substr(fdc_orig.name, 1, 4),
                     pv_societe_absorbee,
                     pv_societe_absorbante) || substr(fdc_orig.name, 5);
    
    ELSE
      --> Autre que XEROX, la séquence sera la même que l'originale
      pn_soc_seq_id_dest := -1;
    
    END IF;
  
    IF nvl(pn_soc_seq_id_dest, 0) = 0 THEN
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => 'Sequence ' ||
                                                    vv_doc_sequence_name ||
                                                    ' not found') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      dka_tools_pkg.put_outdebug_message('Facture ' || pv_invoice_num ||
                                         ' : Sequence ID ' ||
                                         pn_doc_seq_id_orig ||
                                         ' n''existe pas ' ||
                                         pn_soc_seq_id_dest);
      -- Erreur lors d'un controle
      vb_erreur_ctr := TRUE;
    ELSE
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '*',
                               pv_msg            => 'Sequence ' ||
                                                    vv_doc_sequence_name ||
                                                    ' found') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_CTR_DOC_SEQUENCE_F(' ||
                                               pn_doc_seq_id_orig || ',' ||
                                               pv_invoice_num ||
                                               pv_societe_absorbee || ',' ||
                                               pv_societe_absorbante || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_debug_message('Erreur DKA_CTR_DOC_SEQUENCE_F (' ||
                                      pn_doc_seq_id_orig || ',' ||
                                      pv_invoice_num || ',' ||
                                      pv_societe_absorbee || ',' ||
                                      pv_societe_absorbante || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_ctr_doc_sequence_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CTR_PAY_GROUP_F
  --  Description   : Ctrl que la classe de reglement passee en parametre existe
  --                  Si la classe a deja ete traitee ( presente dans le tableau VT_PAY_GROUP )
  --                  ALORS on renvoie la valeur du tableau VT_PAY_GROUP_OK
  --                  SINON on recherche s'il existe
  --                           - Si oui, on stocke 1 dans le tableau VT_PAY_GROUP_OK
  --                           - Si non, on stocke 0 dans le tableau VT_PAY_GROUP_OK
  --                        on stocke la classe de reglement dans VT_PAY_GROUP
  --                  FIN SI
  --
  --  PARAMETRES    :  Numero de facture (message)
  --                   Classe de reglement
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ctr_pay_group_f(pv_invoice_num IN VARCHAR2,
                               pv_pay_group   IN VARCHAR2) RETURN NUMBER IS
  
    dka_erreur_oracle VARCHAR2(80);
    vv_trash          VARCHAR2(1);
  
    vn_rang_trouve BINARY_INTEGER := 0;
  
  BEGIN
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_CTR_PAY_GROUP_F(' ||
                                                  pv_invoice_num || ',' ||
                                                  pv_pay_group || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'Search in VT_PAY_GROUP') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    FOR i IN 1 .. vn_nbre_rangs_pay_group LOOP
    
      IF vt_pay_group(i) = pv_pay_group THEN
        vn_rang_trouve := i;
      END IF;
    
    END LOOP;
  
    IF vn_rang_trouve <> 0 THEN
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'found in VT_PAY_GROUP(' ||
                                                 vn_rang_trouve || ')') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'Search in VT_PAY_GROUP') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => -1,
                               pv_marque         => '<',
                               pv_msg            => 'DKA_CTR_PAY_GROUP_F(' ||
                                                    pv_invoice_num || ',' ||
                                                    pv_pay_group || ')') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      RETURN nvl(vt_pay_group_ok(vn_rang_trouve), -1);
    ELSE
      /* Vn_Rang_Trouve <> 0 */
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'not found in VT_PAY_GROUP') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'Search in VT_PAY_GROUP') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
    END IF; /* Vn_Rang_Trouve <> 0 */
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'Search in Po_Lookup_Codes') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    SELECT 'X'
      INTO vv_trash
      FROM po_lookup_codes plc
     WHERE plc.lookup_type = 'PAY GROUP'
       AND plc.lookup_code = pv_pay_group;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => 'found in Po_Lookup_Codes') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'Search in Po_Lookup_Codes') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    vn_nbre_rangs_pay_group := vn_nbre_rangs_pay_group + 1;
    vt_pay_group(vn_nbre_rangs_pay_group) := pv_pay_group;
    vt_pay_group_ok(vn_nbre_rangs_pay_group) := 1;
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_CTR_PAY_GROUP_F(' ||
                                                  pv_invoice_num || ',' ||
                                                  pv_pay_group || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    RETURN 1;
  
  EXCEPTION
    WHEN no_data_found THEN
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '!',
                            pv_msg            => 'not found in Po_Lookup_Codes') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'Search in Po_Lookup_Codes') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      vn_nbre_rangs_pay_group := vn_nbre_rangs_pay_group + 1;
      vt_pay_group(vn_nbre_rangs_pay_group) := pv_pay_group;
      vt_pay_group_ok(vn_nbre_rangs_pay_group) := 0;
      dka_tools_pkg.put_outdebug_message('Facture ' || pv_invoice_num ||
                                         ' : La classe de reglement ' ||
                                         pv_pay_group || ' n''existe pas');
      -- Erreur lors d'un controle
      vb_erreur_ctr := TRUE;
      RETURN 0;
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur Dka_Ctr_Pay_Groupe_F (' ||
                                         pv_pay_group || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN - 1;
  END dka_ctr_pay_group_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_VALUE_VALID_F
  --  Description   : Ctr que la valeur du segment est valide (date de validite et enabled_flag)
  --                  Si vleur non valide alors sauvegarde des donnees dans table pour historisation ( valeur
  --                  a revalider apres le process ) et reactivation de la valeur
  --  PARAMETRES    : Valeur
  --                  Segment a controler
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_value_valid_f(pv_value IN VARCHAR2, pv_segment IN VARCHAR2)
    RETURN BOOLEAN IS
  
    dka_erreur_oracle    VARCHAR2(80);
    vr_rowid             ROWID;
    vv_enabled_flag      fnd_flex_values.enabled_flag%TYPE;
    vd_start_date_active DATE;
    vd_end_date_active   DATE;
    vn_flex_value_set_id fnd_flex_value_sets.flex_value_set_id%TYPE;
  
    vv_step VARCHAR2(30);
  
  BEGIN
  
    RETURN TRUE;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_VALUE_VALID_F(' ||
                                               pv_value || ',' || pv_segment || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'SELECT FND_FLEX_VALUES') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'SELECT';
    SELECT ffv.rowid,
           ffv.enabled_flag,
           ffv.start_date_active,
           ffv.end_date_active,
           ffv.flex_value_set_id
      INTO vr_rowid,
           vv_enabled_flag,
           vd_start_date_active,
           vd_end_date_active,
           vn_flex_value_set_id
      FROM fnd_id_flex_segments fifs,
           gl_sets_of_books     gsob,
           fnd_flex_values      ffv
     WHERE gsob.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID')
       AND fifs.application_id = 101
       AND fifs.id_flex_code = 'GL#'
       AND fifs.id_flex_num = gsob.chart_of_accounts_id
       AND fifs.application_column_name = pv_segment
       AND ffv.flex_value_set_id = fifs.flex_value_set_id
       AND ffv.flex_value = pv_value
       AND (nvl(ffv.enabled_flag, 'N') = 'N' OR
           ffv.end_date_active IS NOT NULL);
  
    IF NOT dka_print_debug_f(pv_position_debug => 0,
                             pv_marque         => '*',
                             pv_msg            => 'value inactive') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'SELECT FND_FLEX_VALUES') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    -- Valeur non valide : Insertion dans la table historique et revalidation de la valeur
    vv_step := 'INSERT';
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'INSERT DKA_FUSION_AP_FFV') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    INSERT INTO dka_fusion_ap_ffv
      (flex_value_set_id, flex_value, end_date_active, enabled_flag)
    VALUES
      (vn_flex_value_set_id, pv_value, vd_end_date_active, vv_enabled_flag);
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'INSERT DKA_FUSION_AP_FFV') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'UPDATE FND_FLEX_VALUES') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'UPDATE';
    UPDATE fnd_flex_values ffv
       SET ffv.enabled_flag = 'Y', ffv.end_date_active = NULL
     WHERE ROWID = vr_rowid;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'UPDATE FND_FLEX_VALUES') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_VALUE_VALID_F(' ||
                                               pv_value || ',' || pv_segment || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN no_data_found THEN
      -- Valeur valide : OK
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '*',
                               pv_msg            => 'value active') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'SELECT FND_FLEX_VALUES') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'DKA_VALUE_VALID_F(' ||
                                                 pv_value || ',' || pv_segment || ')') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      RETURN TRUE;
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_VALUE_VALID_F - Step ' ||
                                         vv_step || ' (' || pv_value || ',' ||
                                         pv_segment || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_value_valid_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CCID_VALID_F
  --  Description   : Ctr que CCID est valide (date de validite et enabled_flag)
  --                  Si le CCID non valide alors sauvegarde des donnees dans table pour historisation ( valeur
  --                  a revalider apres le process ) et reactivation du CCID
  --  PARAMETRES    : Valeur
  --                  Segment a controler
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ccid_valid_f(pv_segment1  IN VARCHAR2,
                            pv_segment2  IN VARCHAR2,
                            pv_segment3  IN VARCHAR2,
                            pv_segment4  IN VARCHAR2,
                            pv_segment5  IN VARCHAR2,
                            pv_segment6  IN VARCHAR2,
                            pv_segment7  IN VARCHAR2,
                            pv_segment8  IN VARCHAR2,
                            pv_segment9  IN VARCHAR2,
                            pv_segment10 IN VARCHAR2,
                            pv_segment11 IN VARCHAR2,
                            pv_segment12 IN VARCHAR2) RETURN BOOLEAN IS
  
    dka_erreur_oracle  VARCHAR2(80);
    vv_enabled_flag    fnd_flex_values.enabled_flag%TYPE;
    vd_end_date_active DATE;
    vn_ccid            gl_code_combinations.code_combination_id%TYPE;
  
    vv_step VARCHAR2(30);
  
  BEGIN
    RETURN TRUE;
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_CCID_VALID_F(' ||
                                                  pv_segment1 || ',' ||
                                                  pv_segment2 || ',' ||
                                                  pv_segment3 || ',' ||
                                                  pv_segment4 || ',' ||
                                                  pv_segment5 || ',' ||
                                                  pv_segment6 || ',' ||
                                                  pv_segment7 || ',' ||
                                                  pv_segment8 || ',' ||
                                                  pv_segment9 || ',' ||
                                                  pv_segment10 || ',' ||
                                                  pv_segment11 || ',' ||
                                                  pv_segment12 || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'SELECT GL_CODE_COMBINATIONS') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'SELECT';
    SELECT gcc.enabled_flag, gcc.end_date_active, gcc.code_combination_id
      INTO vv_enabled_flag, vd_end_date_active, vn_ccid
      FROM gl_sets_of_books gsob, gl_code_combinations gcc
     WHERE gsob.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID')
       AND gcc.chart_of_accounts_id = gsob.chart_of_accounts_id
       AND gcc.segment1 = pv_segment1
       AND gcc.segment2 = pv_segment2
       AND gcc.segment3 = pv_segment3
       AND gcc.segment4 = pv_segment4
       AND gcc.segment5 = pv_segment5
       AND gcc.segment6 = pv_segment6
       AND gcc.segment7 = pv_segment7
       AND gcc.segment8 = pv_segment8
       AND gcc.segment9 = pv_segment9
       AND gcc.segment10 = pv_segment10
       AND gcc.segment11 = pv_segment11
       AND gcc.segment12 = pv_segment12
       AND (nvl(gcc.enabled_flag, 'N') = 'N' OR
           gcc.end_date_active IS NOT NULL);
  
    IF NOT dka_print_debug_f(pv_position_debug => 0,
                             pv_marque         => '*',
                             pv_msg            => 'ccid inactif') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'SELECT GL_CODE_COMBINATIONS') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    -- Valeur non valide : Insertion dans la table historique et revalidation de la valeur
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'INSERT DKA_FUSION_AP_CCID') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'INSERT';
    INSERT INTO dka_fusion_ap_ccid
      (ccid, end_date_active, enabled_flag)
    VALUES
      (vn_ccid, vd_end_date_active, vv_enabled_flag);
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'INSERT DKA_FUSION_AP_CCID') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'UPDATE GL_CODE_COMBINATIONS') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'UPDATE';
    UPDATE gl_code_combinations gcc
       SET gcc.enabled_flag = 'Y', gcc.end_date_active = NULL
     WHERE gcc.code_combination_id = vn_ccid;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'UPDATE GL_CODE_COMBINATIONS') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_CCID_VALID_F(' ||
                                                  pv_segment1 || ',' ||
                                                  pv_segment2 || ',' ||
                                                  pv_segment3 || ',' ||
                                                  pv_segment4 || ',' ||
                                                  pv_segment5 || ',' ||
                                                  pv_segment6 || ',' ||
                                                  pv_segment7 || ',' ||
                                                  pv_segment8 || ',' ||
                                                  pv_segment9 || ',' ||
                                                  pv_segment10 || ',' ||
                                                  pv_segment11 || ',' ||
                                                  pv_segment12 || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN no_data_found THEN
      -- Valeur valide ou non existante : OK
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '*',
                               pv_msg            => 'ccid actif') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'SELECT GL_CODE_COMBINATIONS') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'DKA_CCID_VALID_F(' ||
                                                 pv_segment1 || ',' ||
                                                 pv_segment2 || pv_segment3 || ',' ||
                                                 pv_segment4 || pv_segment5 || ',' ||
                                                 pv_segment6 || pv_segment7 || ',' ||
                                                 pv_segment8 || pv_segment9 || ',' ||
                                                 pv_segment10 || pv_segment11 || ',' ||
                                                 pv_segment12 || ')') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      RETURN TRUE;
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_CCID_VALID_F - Step ' ||
                                         vv_step || ' (' || pv_segment1 || ',' ||
                                         pv_segment2 || pv_segment3 || ',' ||
                                         pv_segment4 || pv_segment5 || ',' ||
                                         pv_segment6 || pv_segment7 || ',' ||
                                         pv_segment8 || pv_segment9 || ',' ||
                                         pv_segment10 || pv_segment11 || ',' ||
                                         pv_segment12 || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_ccid_valid_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_NEW_PAY_CCID_F
  --  Description   : Nouveau Pay_Ccid (societe absorbante et absorbee)
  --                  1. recherche des segments du ccid d'origine
  --                     Si societe absorbante, segment1 devient la societe absorbante
  --                     Si la facture est de type PREPAYMENT (Accompte), on remplace les segment 3 et 4
  --                     par les comptes generiques (regle de tranco)
  --                  2. SI les segments on deja ete traites ( presents dans les tableau VT_SEGMENTX_PAY )
  --                     ALORS on renvoie le CCID de VT_CCID_PAY
  --                     SINON on recherche le CCID
  --                           on stocke les segments dans VT_SEGMENTX_PAY et
  --                           le CCID dans VT_CCID_PAY (0 si probleme lors de la recherche par l'API)
  --                  FIN SI
  --  PARAMETRES    : CCID d'origine (societe absorbee)
  --                  societe absorbante (segment1 de la nouvelle cle)
  --                  Numero de la facture d'origine (Message)
  --                  Type de la facture d'origine
  --                  Type de la recherche du nouveau CCID ( 1 : Societe absorbee
  --                                                         2 : Societe absorbante )
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_new_pay_ccid_f(pn_ccid_orig           IN NUMBER,
                              pv_societe_absorbante  VARCHAR2,
                              pv_invoice_num         VARCHAR2,
                              pv_invoice_type        VARCHAR2,
                              pv_cpt_local_generique VARCHAR2,
                              pv_cpt_grpe_generique  VARCHAR2,
                              pn_type_ccid           NUMBER) RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80) := NULL;
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle ACCOUNT_PAY_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000) := NULL;
    vn_retcode NUMBER := 0;
  
    vn_rang_trouve BINARY_INTEGER := 0;
  
  BEGIN
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_NEW_PAY_CCID_F(' ||
                                                  pn_ccid_orig || ',' ||
                                                  pv_societe_absorbante || ',' ||
                                                  pv_invoice_num || ',' ||
                                                  pv_invoice_type || ',' ||
                                                  pv_cpt_local_generique || ',' ||
                                                  pv_cpt_grpe_generique || ',' ||
                                                  pn_type_ccid || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      RETURN - 1;
    END IF;
  
    -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
    IF NOT
        dka_value_valid_f(pv_value => vv_segment1, pv_segment => 'SEGMENT1') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment2, pv_segment => 'SEGMENT2') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment3, pv_segment => 'SEGMENT3') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment4, pv_segment => 'SEGMENT4') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment5, pv_segment => 'SEGMENT5') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment6, pv_segment => 'SEGMENT6') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment7, pv_segment => 'SEGMENT7') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment8, pv_segment => 'SEGMENT8') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment9, pv_segment => 'SEGMENT9') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                             pv_segment => 'SEGMENT10') THEN
      RETURN - 1;
    END IF;
    IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                             pv_segment => 'SEGMENT11') THEN
      RETURN - 1;
    END IF;
    IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                             pv_segment => 'SEGMENT12') THEN
      RETURN - 1;
    END IF;
  
    -- Revalidation eventuelle du CCID
    IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                            pv_segment2  => vv_segment2,
                            pv_segment3  => vv_segment3,
                            pv_segment4  => vv_segment4,
                            pv_segment5  => vv_segment5,
                            pv_segment6  => vv_segment6,
                            pv_segment7  => vv_segment7,
                            pv_segment8  => vv_segment8,
                            pv_segment9  => vv_segment9,
                            pv_segment10 => vv_segment10,
                            pv_segment11 => vv_segment11,
                            pv_segment12 => vv_segment12) THEN
      RETURN - 1;
    END IF;
  
    -- Si societe absorbante -> Segment1 devient la societe absorbante
    IF pn_type_ccid = 2 THEN
      vv_segment1 := pv_societe_absorbante;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'Search ' || vv_segment1 || ',' ||
                                                  vv_segment2 || ',' ||
                                                  vv_segment3 || ',' ||
                                                  vv_segment4 || ',' ||
                                                  vv_segment5 || ',' ||
                                                  vv_segment6 || ',' ||
                                                  vv_segment7 || ',' ||
                                                  vv_segment8 || ',' ||
                                                  vv_segment9 || ',' ||
                                                  vv_segment10 || ',' ||
                                                  vv_segment11 || ',' ||
                                                  vv_segment12 ||
                                                  ' in VT_SEGMENT1_PAY') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    FOR i IN 1 .. vn_nbre_rangs_pay LOOP
      IF vv_segment1 = vt_segment1_pay(i) AND
         vv_segment2 = vt_segment2_pay(i) AND
         vv_segment3 = vt_segment3_pay(i) AND
         vv_segment4 = vt_segment4_pay(i) AND
         vv_segment5 = vt_segment5_pay(i) AND
         vv_segment6 = vt_segment6_pay(i) AND
         vv_segment7 = vt_segment7_pay(i) AND
         vv_segment8 = vt_segment8_pay(i) AND
         vv_segment9 = vt_segment9_pay(i) AND
         vv_segment10 = vt_segment10_pay(i) AND
         vv_segment11 = vt_segment11_pay(i) AND
         vv_segment12 = vt_segment12_pay(i) THEN
        vn_rang_trouve := i;
      END IF;
    
    END LOOP;
  
    IF vn_rang_trouve <> 0 THEN
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'found in  VT_SEGMENT_PAY(' ||
                                                 vn_rang_trouve || ')') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => -1,
                               pv_marque         => '<',
                               pv_msg            => 'Search ' || vv_segment1 || ',' ||
                                                    vv_segment2 || ',' ||
                                                    vv_segment3 || ',' ||
                                                    vv_segment4 || ',' ||
                                                    vv_segment5 || ',' ||
                                                    vv_segment6 || ',' ||
                                                    vv_segment7 || ',' ||
                                                    vv_segment8 || ',' ||
                                                    vv_segment9 || ',' ||
                                                    vv_segment10 || ',' ||
                                                    vv_segment11 || ',' ||
                                                    vv_segment12 ||
                                                    ' in VT_SEGMENT_PAY') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => -1,
                               pv_marque         => '<',
                               pv_msg            => 'DKA_NEW_PAY_CCID_F(' ||
                                                    pn_ccid_orig || ',' ||
                                                    pv_societe_absorbante || ',' ||
                                                    pv_invoice_num || ',' ||
                                                    pv_invoice_type || ',' ||
                                                    pv_cpt_local_generique || ',' ||
                                                    pv_cpt_grpe_generique || ',' ||
                                                    pn_type_ccid || ')')
      
       THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      -- Combinaison deja traitee, On sort de la fonction
      RETURN nvl(vt_ccid_pay(vn_rang_trouve), -1);
    
    ELSE
      /* Vn_Rang_Trouve <> 0 */
    
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'not found in VT_SEGMENT_PAY') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
    END IF; /* Vn_Rang_Trouve <> 0 */
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'Search ' || vv_segment1 || ',' ||
                                                  vv_segment2 || ',' ||
                                                  vv_segment3 || ',' ||
                                                  vv_segment4 || ',' ||
                                                  vv_segment5 || ',' ||
                                                  vv_segment6 || ',' ||
                                                  vv_segment7 || ',' ||
                                                  vv_segment8 || ',' ||
                                                  vv_segment9 || ',' ||
                                                  vv_segment10 || ',' ||
                                                  vv_segment11 || ',' ||
                                                  vv_segment12 ||
                                                  ' in VT_SEGMENT1_PAY') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    -- 3. Revalidation eventuelle des valeurs ( Valeurs destination )
    IF NOT
        dka_value_valid_f(pv_value => vv_segment1, pv_segment => 'SEGMENT1') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment2, pv_segment => 'SEGMENT2') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment3, pv_segment => 'SEGMENT3') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment4, pv_segment => 'SEGMENT4') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment5, pv_segment => 'SEGMENT5') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment6, pv_segment => 'SEGMENT6') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment7, pv_segment => 'SEGMENT7') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment8, pv_segment => 'SEGMENT8') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment9, pv_segment => 'SEGMENT9') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                             pv_segment => 'SEGMENT10') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                             pv_segment => 'SEGMENT11') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                             pv_segment => 'SEGMENT12') THEN
      RETURN - 1;
    END IF;
  
    -- Revalidation eventuelle du CCID
    IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                            pv_segment2  => vv_segment2,
                            pv_segment3  => vv_segment3,
                            pv_segment4  => vv_segment4,
                            pv_segment5  => vv_segment5,
                            pv_segment6  => vv_segment6,
                            pv_segment7  => vv_segment7,
                            pv_segment8  => vv_segment8,
                            pv_segment9  => vv_segment9,
                            pv_segment10 => vv_segment10,
                            pv_segment11 => vv_segment11,
                            pv_segment12 => vv_segment12) THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'Call dka_tools_pkg.get_code_combination_id(' ||
                                                  vv_segment1 || ',' ||
                                                  vv_segment2 || ',' ||
                                                  vv_segment3 || ',' ||
                                                  vv_segment4 || ',' ||
                                                  vv_segment5 || ',' ||
                                                  vv_segment6 || ',' ||
                                                  vv_segment7 || ',' ||
                                                  vv_segment8 || ',' ||
                                                  vv_segment9 || ',' ||
                                                  vv_segment10 || ',' ||
                                                  vv_segment11 || ',' ||
                                                  vv_segment12 || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    -- 2. recherche du nouveau ccid
    dka_tools_pkg.get_code_combination_id(pv_segment1            => vv_segment1,
                                          pv_segment2            => vv_segment2,
                                          pv_segment3            => vv_segment3,
                                          pv_segment4            => vv_segment4,
                                          pv_segment5            => vv_segment5,
                                          pv_segment6            => vv_segment6,
                                          pv_segment7            => vv_segment7,
                                          pv_segment8            => vv_segment8,
                                          pv_segment9            => vv_segment9,
                                          pv_segment10           => vv_segment10,
                                          pv_segment11           => vv_segment11,
                                          pv_segment12           => vv_segment12,
                                          pn_code_combination_id => vn_new_ccid,
                                          pv_errbuf              => vv_errbuf,
                                          pn_retcode             => vn_retcode,
                                          pv_validation_flag     => 'Y');
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'Call dka_tools_pkg.get_code_combination_id(' ||
                                                  vv_segment1 || ',' ||
                                                  vv_segment2 || ',' ||
                                                  vv_segment3 || ',' ||
                                                  vv_segment4 || ',' ||
                                                  vv_segment5 || ',' ||
                                                  vv_segment6 || ',' ||
                                                  vv_segment7 || ',' ||
                                                  vv_segment8 || ',' ||
                                                  vv_segment9 || ',' ||
                                                  vv_segment10 || ',' ||
                                                  vv_segment11 || ',' ||
                                                  vv_segment12 || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    vn_nbre_rangs_pay := vn_nbre_rangs_pay + 1;
  
    vt_segment1_pay(vn_nbre_rangs_pay) := vv_segment1;
    vt_segment2_pay(vn_nbre_rangs_pay) := vv_segment2;
    vt_segment3_pay(vn_nbre_rangs_pay) := vv_segment3;
    vt_segment4_pay(vn_nbre_rangs_pay) := vv_segment4;
    vt_segment5_pay(vn_nbre_rangs_pay) := vv_segment5;
    vt_segment6_pay(vn_nbre_rangs_pay) := vv_segment6;
    vt_segment7_pay(vn_nbre_rangs_pay) := vv_segment7;
    vt_segment8_pay(vn_nbre_rangs_pay) := vv_segment8;
    vt_segment9_pay(vn_nbre_rangs_pay) := vv_segment9;
    vt_segment10_pay(vn_nbre_rangs_pay) := vv_segment10;
    vt_segment11_pay(vn_nbre_rangs_pay) := vv_segment11;
    vt_segment12_pay(vn_nbre_rangs_pay) := vv_segment12;
  
    vt_ccid_pay(vn_nbre_rangs_pay) := vn_new_ccid;
  
    IF nvl(vn_new_ccid, 0) = 0 THEN
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => 'error Search Ccid') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => vv_errbuf) THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      -- Probleme lors de la recherche du noouveau CCID
      dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID compte collectif du fournisseur de la facture ' ||
                                         pv_invoice_num);
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      -- Erreur lors d'un controle
      vb_erreur_ctr := TRUE;
    
    ELSE
      /* NVL(Vn_New_CCID,0) = 0 */
    
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'ccid : ' || vn_new_ccid) THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
    END IF; /* NVL(Vn_New_CCID,0) = 0 */
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_NEW_PAY_CCID_F(' ||
                                                  pn_ccid_orig || ',' ||
                                                  pv_societe_absorbante || ',' ||
                                                  pv_invoice_num || ',' ||
                                                  pv_invoice_type || ',' ||
                                                  pv_cpt_local_generique || ',' ||
                                                  pv_cpt_grpe_generique || ',' ||
                                                  pn_type_ccid || ')')
    
     THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    RETURN nvl(vn_new_ccid, -1);
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_NEW_PAY_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_societe_absorbante || ',' ||
                                         pv_invoice_num || ',' ||
                                         pv_invoice_type || ',' ||
                                         pv_cpt_local_generique || ',' ||
                                         pv_cpt_grpe_generique || ',' ||
                                         pn_type_ccid || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN 0;
  END dka_new_pay_ccid_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INS_INV_INTERFACE_F
  --  Description   : Insertion dans la table dka_fusion_ap_inv_int
  --
  --  PARAMETRES    : Liste des champs a inserer
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Valeur Booleenne
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ins_inv_interface_f(pn_invoice_id                 IN NUMBER,
                                   pv_invoice_num                IN VARCHAR2,
                                   pv_invoice_type_lookup_code   IN VARCHAR2,
                                   pd_invoice_date               IN DATE,
                                   pn_vendor_id                  IN NUMBER,
                                   pv_vendor_name                IN VARCHAR2,
                                   pn_vendor_site_id             IN NUMBER,
                                   pv_vendor_site_code           IN VARCHAR2,
                                   pn_invoice_amount             IN NUMBER,
                                   pv_invoice_currency_code      IN VARCHAR2,
                                   pn_terms_id                   IN NUMBER,
                                   pn_terms_date                 IN DATE,
                                   pv_terms_name                 IN VARCHAR2,
                                   pv_description                IN VARCHAR2,
                                   pv_attribute_category         IN VARCHAR2,
                                   pv_attribute1                 IN VARCHAR2,
                                   pv_attribute2                 IN VARCHAR2,
                                   pv_attribute3                 IN VARCHAR2,
                                   pv_attribute4                 IN VARCHAR2,
                                   pv_attribute5                 IN VARCHAR2,
                                   pv_attribute6                 IN VARCHAR2,
                                   pv_attribute7                 IN VARCHAR2,
                                   pv_attribute8                 IN VARCHAR2,
                                   pv_attribute9                 IN VARCHAR2,
                                   pv_attribute10                IN VARCHAR2,
                                   pv_attribute11                IN VARCHAR2,
                                   pv_attribute12                IN VARCHAR2,
                                   pv_attribute13                IN VARCHAR2,
                                   pv_attribute14                IN VARCHAR2,
                                   pv_attribute15                IN VARCHAR2,
                                   pv_global_attribute_category  IN VARCHAR2,
                                   pv_global_attribute1          IN VARCHAR2,
                                   pv_global_attribute2          IN VARCHAR2,
                                   pv_global_attribute3          IN VARCHAR2,
                                   pv_global_attribute4          IN VARCHAR2,
                                   pv_global_attribute5          IN VARCHAR2,
                                   pv_global_attribute6          IN VARCHAR2,
                                   pv_global_attribute7          IN VARCHAR2,
                                   pv_global_attribute8          IN VARCHAR2,
                                   pv_global_attribute9          IN VARCHAR2,
                                   pv_global_attribute10         IN VARCHAR2,
                                   pv_global_attribute11         IN VARCHAR2,
                                   pv_global_attribute12         IN VARCHAR2,
                                   pv_global_attribute13         IN VARCHAR2,
                                   pv_global_attribute14         IN VARCHAR2,
                                   pv_global_attribute15         IN VARCHAR2,
                                   pv_global_attribute16         IN VARCHAR2,
                                   pv_global_attribute17         IN VARCHAR2,
                                   pv_global_attribute18         IN VARCHAR2,
                                   pv_global_attribute19         IN VARCHAR2,
                                   pv_global_attribute20         IN VARCHAR2,
                                   pv_status                     IN VARCHAR2,
                                   pv_source                     IN VARCHAR2,
                                   pv_payment_cross_rate_type    IN VARCHAR2,
                                   pv_payment_cross_rate_date    IN DATE,
                                   pn_payment_cross_rate         IN NUMBER,
                                   pv_payment_currency_code      IN VARCHAR2,
                                   pv_doc_category_code          IN VARCHAR2,
                                   pv_payment_method_lookup_code IN VARCHAR2,
                                   pv_pay_group_lookup_code      IN VARCHAR2,
                                   pn_account_pay_ccid           IN NUMBER,
                                   pn_org_id                     IN NUMBER,
                                   pd_gl_date                    IN DATE,
                                   pv_operating_unit             IN VARCHAR2,
                                   pv_payment_method_code        IN VARCHAR2,
                                   pn_payment_priority           IN NUMBER,
                                   pn_external_bank_account_id   IN NUMBER,
                                   pv_remit_to_supplier_name     IN VARCHAR2,
                                   pn_remit_to_supplier_id       IN NUMBER,
                                   pv_remit_to_supplier_site     IN VARCHAR2,
                                   pn_remit_to_supplier_site_id  IN NUMBER,
                                   pv_remit_to_supplier_num      IN VARCHAR2
                                   
                                   ) RETURN BOOLEAN IS
    dka_erreur_oracle VARCHAR2(80);
    vd_gl_date        DATE;
  
  BEGIN
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_INS_INV_INTERFACE_F(' ||
                                                  pn_invoice_id || ',' ||
                                                  pv_invoice_num || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    -- Récupération de la date_gl
    /*BEGIN
      SELECT start_date
        INTO vd_gl_date
        FROM gl_periods gp
       WHERE trunc(SYSDATE) BETWEEN gp.start_date AND gp.end_date
         AND period_set_name = 'GROUPE';
    EXCEPTION
      WHEN no_data_found THEN
        vd_gl_date := NULL;
      WHEN OTHERS THEN
        dka_erreur_oracle := substr(SQLERRM, 1, 80);
        dka_tools_pkg.put_debug_message('Erreur DKA_VERIF_PARAM ');
        dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
    END;*/
    vd_gl_date := pd_gl_date;
  
    INSERT INTO dka_fusion_ap_inv_int
      (invoice_num,
       invoice_id,
       invoice_type_lookup_code,
       invoice_date,
       vendor_id,
       vendor_name,
       vendor_site_id,
       vendor_site_code,
       invoice_amount,
       invoice_currency_code,
       terms_id,
       terms_date,
       terms_name,
       description,
       attribute_category,
       attribute1,
       attribute2,
       attribute3,
       attribute4,
       attribute5,
       attribute6,
       attribute7,
       attribute8,
       attribute9,
       attribute10,
       attribute11,
       attribute12,
       attribute13,
       attribute14,
       attribute15,
       global_attribute_category,
       global_attribute1,
       global_attribute2,
       global_attribute3,
       global_attribute4,
       global_attribute5,
       global_attribute6,
       global_attribute7,
       global_attribute8,
       global_attribute9,
       global_attribute10,
       global_attribute11,
       global_attribute12,
       global_attribute13,
       global_attribute14,
       global_attribute15,
       global_attribute16,
       global_attribute17,
       global_attribute18,
       global_attribute19,
       global_attribute20,
       status,
       SOURCE,
       payment_cross_rate_type,
       payment_cross_rate_date,
       payment_cross_rate,
       payment_currency_code,
       doc_category_code,
       payment_method_lookup_code,
       pay_group_lookup_code,
       accts_pay_code_combination_id,
       org_id,
       gl_date,
       creation_date,
       created_by,
       last_updated_by,
       last_update_date,
       calc_tax_during_import_flag,
       operating_unit,
       payment_method_code,
       payment_priority,
       external_bank_account_id,
       remit_to_supplier_name,
       remit_to_supplier_id,
       remit_to_supplier_site,
       remit_to_supplier_site_id,
       remit_to_supplier_num)
    VALUES
      (pv_invoice_num,
       pn_invoice_id,
       pv_invoice_type_lookup_code,
       pd_invoice_date,
       pn_vendor_id,
       pv_vendor_name,
       pn_vendor_site_id,
       pv_vendor_site_code,
       pn_invoice_amount,
       pv_invoice_currency_code,
       pn_terms_id,
       pn_terms_date,
       pv_terms_name,
       pv_description,
       pv_attribute_category,
       pv_attribute1,
       pv_attribute2,
       pv_attribute3,
       pv_attribute4,
       pv_attribute5,
       pv_attribute6,
       pv_attribute7,
       pv_attribute8,
       pv_attribute9,
       pv_attribute10,
       pv_attribute11,
       pv_attribute12,
       pv_attribute13,
       pv_attribute14,
       pv_attribute15,
       pv_global_attribute_category,
       pv_global_attribute1,
       pv_global_attribute2,
       pv_global_attribute3,
       pv_global_attribute4,
       pv_global_attribute5,
       pv_global_attribute6,
       pv_global_attribute7,
       pv_global_attribute8,
       pv_global_attribute9,
       pv_global_attribute10,
       pv_global_attribute11,
       pv_global_attribute12,
       pv_global_attribute13,
       pv_global_attribute14,
       pv_global_attribute15,
       pv_global_attribute16,
       pv_global_attribute17,
       pv_global_attribute18,
       pv_global_attribute19,
       pv_global_attribute20,
       pv_status,
       pv_source,
       pv_payment_cross_rate_type,
       pv_payment_cross_rate_date,
       pn_payment_cross_rate,
       pv_payment_currency_code,
       pv_doc_category_code,
       pv_payment_method_lookup_code,
       pv_pay_group_lookup_code,
       pn_account_pay_ccid,
       pn_org_id,
       vd_gl_date,
       SYSDATE,
       fnd_profile.value('USER_ID'),
       fnd_profile.value('USER_ID'),
       SYSDATE,
       'N',
       pv_operating_unit,
       pv_payment_method_code,
       pn_payment_priority,
       pn_external_bank_account_id,
       pv_remit_to_supplier_name,
       pn_remit_to_supplier_id,
       pv_remit_to_supplier_site,
       pn_remit_to_supplier_site_id,
       pv_remit_to_supplier_num
       
       );
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => '1 row inserted in DKA_FUSION_AP_INV_INT') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_INS_INV_INTERFACE_F(' ||
                                                  pn_invoice_id || ',' ||
                                                  pv_invoice_num || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vn_nbre_entetes := vn_nbre_entetes + 1;
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_INS_INV_INTERFACE_F(' ||
                                         pn_invoice_id || ',' ||
                                         pv_invoice_num || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_ins_inv_interface_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_NEW_DIST_CID_F
  --  Description   : Nouveau Dist_Code_Combination_Id (societe absorbante et absorbee)
  --                  1. recherche des segments du ccid d'origine
  --                  2. Sustitution des segments pour la nouvelle cle
  --                      -segment1 = Societe absorbante
  --                      Si Ligne de type TVA pas d'autre modif
  --                      Si ligne de type ITEM et facture de type PREPAYMENT (Acompte) pas d'autre modif
  --                      Sinon (ligne de type ITEM et facture autre que PREPAYMENT (Acompte))
  --                         -- Segment2(centre de gestion) = Pas de modifs
  --                         -- Segment3(compte local) = Compte generique contenu dans la table de transaco
  --                         -- Segment4(compte groupe) = Compte generique contenu dans la table de transaco
  --                         -- Autres segments = '0'
  --                  3. Revalidation eventuelle des segments et CCID
  --                  4. SI les segments on deja ete traites ( presents dans les tableau VT_SEGMENTX_DIST )
  --                     ALORS on renvoie le CCID de VT_CCID_DIST
  --                     SINON on lrecherche le CCID
  --                           on stocke les segments dans VT_SEGMENTX_DIST et
  --                           le CCID dans VT_CCID_DIST (0 si probleme lors de la recherche par l'API)
  --                  FIN SI
  --
  --  PARAMETRES    : CCID d'origine
  --                  Type de la ligne
  --                  societe absorbee
  --                  societe absorbante
  --                  Cpte Local Generique
  --                  Cpt Groupe Generique
  --                  Numero de la ligne
  --                  Numero de la facture (Message)
  --                  Type de facture
  --                  Type de la recherche du nouveau CCID ( 1 : Societe absorbee
  --                                                         2 : Societe absorbante )
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_new_dist_ccid_f(pn_ccid_orig                IN NUMBER,
                               pv_line_type_lookup_code    IN VARCHAR2,
                               pv_societe_absorbee         VARCHAR2,
                               pv_societe_absorbante       VARCHAR2,
                               pv_cpt_local_generique      VARCHAR2,
                               pv_cpt_grpe_generique       VARCHAR2,
                               pn_distribution_line_number NUMBER,
                               pv_invoice_num              VARCHAR2,
                               pv_invoice_type             VARCHAR2,
                               pn_type_ccid                NUMBER)
    RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle DIST_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000);
    vn_retcode NUMBER;
  
    vn_rang_trouve NUMBER := 0;
  
    vv_new_segment1 gl_code_combinations.segment1%TYPE;
  
  BEGIN
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_NEW_DIST_CCID_F(' ||
                                                  pn_ccid_orig || ',' ||
                                                  pv_line_type_lookup_code || ',' ||
                                                  pv_societe_absorbee || ',' ||
                                                  pv_societe_absorbante || ',' ||
                                                  pv_cpt_local_generique || ',' ||
                                                  pv_cpt_grpe_generique || ',' ||
                                                  pn_distribution_line_number || ',' ||
                                                  pv_invoice_num || ',' ||
                                                  pn_type_ccid || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    IF pn_type_ccid = 1 THEN
      -- Recherche du new CCID pour la societe absorbee
      -- > Segment1 = Societe absorbee
      vv_new_segment1 := pv_societe_absorbee;
    ELSE
      -- Recherche du new CCID pour la societe absorbante
      -- > Segment1 = Societe absorbante
      vv_new_segment1 := pv_societe_absorbante;
    END IF;
  
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
    IF NOT
        dka_value_valid_f(pv_value => vv_segment1, pv_segment => 'SEGMENT1') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment2, pv_segment => 'SEGMENT2') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment3, pv_segment => 'SEGMENT3') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment4, pv_segment => 'SEGMENT4') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment5, pv_segment => 'SEGMENT5') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment6, pv_segment => 'SEGMENT6') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment7, pv_segment => 'SEGMENT7') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment8, pv_segment => 'SEGMENT8') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment9, pv_segment => 'SEGMENT9') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                             pv_segment => 'SEGMENT10') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                             pv_segment => 'SEGMENT11') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                             pv_segment => 'SEGMENT12') THEN
      RETURN - 1;
    END IF;
  
    -- Revalidation eventuelle du CCID
    IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                            pv_segment2  => vv_segment2,
                            pv_segment3  => vv_segment3,
                            pv_segment4  => vv_segment4,
                            pv_segment5  => vv_segment5,
                            pv_segment6  => vv_segment6,
                            pv_segment7  => vv_segment7,
                            pv_segment8  => vv_segment8,
                            pv_segment9  => vv_segment9,
                            pv_segment10 => vv_segment10,
                            pv_segment11 => vv_segment11,
                            pv_segment12 => vv_segment12) THEN
      RETURN - 1;
    END IF;
    -- 3. Substitution des segments suivant type de ligne
    IF ((pv_line_type_lookup_code = 'TAX') OR
       (pv_line_type_lookup_code = 'ITEM' AND
       pv_invoice_type = 'PREPAYMENT')) THEN
      -- Pas de modif sauf segment1 (societe absorbante)
      NULL;
    ELSE
      --ITEM
      vv_segment3  := pv_cpt_local_generique;
      vv_segment4  := pv_cpt_grpe_generique;
      vv_segment5  := '0';
      vv_segment6  := '0';
      vv_segment7  := '0';
      vv_segment8  := '0';
      vv_segment9  := '0';
      vv_segment10 := '0';
      vv_segment11 := '0';
      vv_segment12 := '0';
    END IF; /* Pv_Line_Type_Lookup_Code = 'TAX' */
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'Search ' || vv_segment1 || ',' ||
                                                  vv_segment2 || vv_segment3 || ',' ||
                                                  vv_segment4 || vv_segment5 || ',' ||
                                                  vv_segment6 || vv_segment7 || ',' ||
                                                  vv_segment8 || vv_segment9 || ',' ||
                                                  vv_segment10 || vv_segment11 ||
                                                  ' in VT_SEGMENT_DIST') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    FOR i IN 1 .. vn_nbre_rangs_dist LOOP
      IF vv_new_segment1 = vt_segment1_dist(i) AND
         vv_segment2 = vt_segment2_dist(i) AND
         vv_segment3 = vt_segment3_dist(i) AND
         vv_segment4 = vt_segment4_dist(i) AND
         vv_segment5 = vt_segment5_dist(i) AND
         vv_segment6 = vt_segment6_dist(i) AND
         vv_segment7 = vt_segment7_dist(i) AND
         vv_segment8 = vt_segment8_dist(i) AND
         vv_segment9 = vt_segment9_dist(i) AND
         vv_segment10 = vt_segment10_dist(i) AND
         vv_segment11 = vt_segment11_dist(i) AND
         vv_segment12 = vt_segment12_dist(i) THEN
        vn_rang_trouve := i;
      END IF;
    END LOOP;
  
    -- Combinaison deja traitee
    IF vn_rang_trouve <> 0 THEN
    
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'found in  VT_SEGMENT_DIST(' ||
                                                 vn_rang_trouve || ')') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'Search ' || vv_new_segment1 || ',' ||
                                                 vv_segment2 || vv_segment3 || ',' ||
                                                 vv_segment4 || vv_segment5 || ',' ||
                                                 vv_segment6 || vv_segment7 || ',' ||
                                                 vv_segment8 || vv_segment9 || ',' ||
                                                 vv_segment10 || vv_segment11 || ',' ||
                                                 vv_segment12 ||
                                                 ' in VT_SEGMENT_DIST') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => -1,
                               pv_marque         => '<',
                               pv_msg            => 'DKA_NEW_DIST_CCID_F(' ||
                                                    pn_ccid_orig || ',' ||
                                                    pv_line_type_lookup_code || ',' ||
                                                    pv_societe_absorbee || ',' ||
                                                    pv_societe_absorbante || ',' ||
                                                    pv_cpt_local_generique || ',' ||
                                                    pv_cpt_grpe_generique || ',' ||
                                                    pn_distribution_line_number || ',' ||
                                                    pv_invoice_num || ',' ||
                                                    pn_type_ccid || ')') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      RETURN nvl(vt_ccid_dist(vn_rang_trouve), -1);
    
    ELSE
      /* Vn_Rang_Trouve <> 0 */
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'not found in VT_SEGMENT_PAY') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    END IF; /* Vn_Rang_Trouve <> 0 */
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'Search ' || vv_segment1 || ',' ||
                                                  vv_segment2 || vv_segment3 || ',' ||
                                                  vv_segment4 || vv_segment5 || ',' ||
                                                  vv_segment6 || vv_segment7 || ',' ||
                                                  vv_segment8 || vv_segment8 || ',' ||
                                                  vv_segment9 || vv_segment10 || ',' ||
                                                  vv_segment11 ||
                                                  ' in VT_SEGMENT_DIST') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    -- 4. Revalidation eventuelle des valeurs
    IF NOT dka_value_valid_f(pv_value   => vv_new_segment1,
                             pv_segment => 'SEGMENT1') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment2, pv_segment => 'SEGMENT2') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment3, pv_segment => 'SEGMENT3') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment4, pv_segment => 'SEGMENT4') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment5, pv_segment => 'SEGMENT5') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment6, pv_segment => 'SEGMENT6') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment7, pv_segment => 'SEGMENT7') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment8, pv_segment => 'SEGMENT8') THEN
      RETURN - 1;
    END IF;
  
    IF NOT
        dka_value_valid_f(pv_value => vv_segment9, pv_segment => 'SEGMENT9') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                             pv_segment => 'SEGMENT10') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                             pv_segment => 'SEGMENT11') THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                             pv_segment => 'SEGMENT12') THEN
      RETURN - 1;
    END IF;
  
    -- Revalidation eventuelle du CCID
    IF NOT dka_ccid_valid_f(pv_segment1  => vv_new_segment1,
                            pv_segment2  => vv_segment2,
                            pv_segment3  => vv_segment3,
                            pv_segment4  => vv_segment4,
                            pv_segment5  => vv_segment5,
                            pv_segment6  => vv_segment6,
                            pv_segment7  => vv_segment7,
                            pv_segment8  => vv_segment8,
                            pv_segment9  => vv_segment9,
                            pv_segment10 => vv_segment10,
                            pv_segment11 => vv_segment11,
                            pv_segment12 => vv_segment12) THEN
      RETURN - 1;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'Call dka_tools_pkg.get_code_combination_id(' ||
                                                  vv_new_segment1 || ',' ||
                                                  vv_segment2 || ',' ||
                                                  vv_segment3 || ',' ||
                                                  vv_segment4 || ',' ||
                                                  vv_segment5 || ',' ||
                                                  vv_segment6 || ',' ||
                                                  vv_segment7 || ',' ||
                                                  vv_segment8 || ',' ||
                                                  vv_segment9 || ',' ||
                                                  vv_segment10 || ',' ||
                                                  vv_segment11 || ',' ||
                                                  vv_segment12 || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    -- 5. Recherche du nouveau ccid
    dka_tools_pkg.get_code_combination_id(pv_segment1            => vv_new_segment1,
                                          pv_segment2            => vv_segment2,
                                          pv_segment3            => vv_segment3,
                                          pv_segment4            => vv_segment4,
                                          pv_segment5            => vv_segment5,
                                          pv_segment6            => vv_segment6,
                                          pv_segment7            => vv_segment7,
                                          pv_segment8            => vv_segment8,
                                          pv_segment9            => vv_segment9,
                                          pv_segment10           => vv_segment10,
                                          pv_segment11           => vv_segment11,
                                          pv_segment12           => vv_segment12,
                                          pn_code_combination_id => vn_new_ccid,
                                          pv_errbuf              => vv_errbuf,
                                          pn_retcode             => vn_retcode,
                                          pv_validation_flag     => 'Y');
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'Call dka_tools_pkg.get_code_combination_id(' ||
                                                  vv_new_segment1 || ',' ||
                                                  vv_segment2 || ',' ||
                                                  vv_segment3 || ',' ||
                                                  vv_segment4 || ',' ||
                                                  vv_segment5 || ',' ||
                                                  vv_segment6 || ',' ||
                                                  vv_segment7 || ',' ||
                                                  vv_segment8 || ',' ||
                                                  vv_segment9 || ',' ||
                                                  vv_segment10 || ',' ||
                                                  vv_segment11 || ',' ||
                                                  vv_segment12 || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    vn_nbre_rangs_dist := vn_nbre_rangs_dist + 1;
  
    vt_segment1_dist(vn_nbre_rangs_dist) := vv_new_segment1;
    vt_segment2_dist(vn_nbre_rangs_dist) := vv_segment2;
    vt_segment3_dist(vn_nbre_rangs_dist) := vv_segment3;
    vt_segment4_dist(vn_nbre_rangs_dist) := vv_segment4;
    vt_segment5_dist(vn_nbre_rangs_dist) := vv_segment5;
    vt_segment6_dist(vn_nbre_rangs_dist) := vv_segment6;
    vt_segment7_dist(vn_nbre_rangs_dist) := vv_segment7;
    vt_segment8_dist(vn_nbre_rangs_dist) := vv_segment8;
    vt_segment9_dist(vn_nbre_rangs_dist) := vv_segment9;
    vt_segment10_dist(vn_nbre_rangs_dist) := vv_segment10;
    vt_segment11_dist(vn_nbre_rangs_dist) := vv_segment11;
    vt_segment12_dist(vn_nbre_rangs_dist) := vv_segment12;
    vt_ccid_dist(vn_nbre_rangs_dist) := nvl(vn_new_ccid, 0);
  
    IF nvl(vn_new_ccid, 0) = 0 THEN
    
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => 'error Search Ccid') THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => vv_errbuf) THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
      -- Probleme lors de la recherche du noouveau CCID
      dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID de la ligne de distribution - Facture : ' ||
                                         pv_invoice_num || ' - Ligne : ' ||
                                         to_char(pn_distribution_line_number) || ')');
      dka_tools_pkg.put_outdebug_message(vv_errbuf);
      -- Erreur lors d'un controle
      vb_erreur_ctr := TRUE;
    
    ELSE
      /* NVL(Vn_New_CCID,0) = 0 */
    
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'ccid : ' || vn_new_ccid) THEN
        -- Probleme
        RETURN - 1;
      END IF;
    
    END IF; /*NVL(Vn_New_CCID,0) = 0 */
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_NEW_DIST_CCID_F(' ||
                                                  pn_ccid_orig || ',' ||
                                                  pv_line_type_lookup_code || ',' ||
                                                  pv_societe_absorbee || ',' ||
                                                  pv_societe_absorbante || ',' ||
                                                  pv_cpt_local_generique || ',' ||
                                                  pv_cpt_grpe_generique || ',' ||
                                                  pn_distribution_line_number || ',' ||
                                                  pv_invoice_num || ',' ||
                                                  pn_type_ccid || ')') THEN
      -- Probleme
      RETURN - 1;
    END IF;
  
    RETURN nvl(vn_new_ccid, -1);
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_NEW_DIST_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_line_type_lookup_code || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ',' ||
                                         pv_cpt_local_generique || ',' ||
                                         pv_cpt_grpe_generique || ',' ||
                                         pn_distribution_line_number || ',' ||
                                         pv_invoice_num || ',' ||
                                         pn_type_ccid || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN - 1;
  END dka_new_dist_ccid_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_NEW_TAX_ID_F
  --  Description   : Nouveau Tax_Code_Id (societe absorbante)
  --                  Code tax = Societe absorbante + reste du code
  --  PARAMETRES    : Code societe absorbante
  --                  Tax_Code_Id d'origine
  --                  Tax_Code OUT ( NULL si pas trouve )
  --
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre Nouveau Tax_Code_Id
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_new_tax_f(pv_societe_absorbee   IN VARCHAR2,
                         pv_societe_absorbante IN VARCHAR2,
                         pn_tax_code_id        IN NUMBER,
                         pv_tax_code           OUT VARCHAR2) RETURN BOOLEAN IS
  
    vv_erreur_oracle VARCHAR2(80);
    vn_tax_id        zx_lines.tax_id%TYPE;
    vv_tax_name      zx_lines.tax%TYPE;
  
  BEGIN
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_NEW_TAX_F (' ||
                                                  pv_societe_absorbee || ',' ||
                                                  pv_societe_absorbante || ',' ||
                                                  pn_tax_code_id || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    -- Si les 4 caracteres = societe absorbee, on remplace par societe absorbante
    SELECT zl_dest.tax_id,
           REPLACE(substr(zl_orig.tax, 1, 4),
                   pv_societe_absorbee,
                   pv_societe_absorbante) || substr(zl_orig.tax, 5) code_dest
      INTO vn_tax_id, vv_tax_name
      FROM zx_lines zl_orig, zx_lines zl_dest
     WHERE zl_orig.tax_id = pn_tax_code_id
       AND zl_dest.tax(+) =
           REPLACE(substr(zl_orig.tax, 1, 4),
                   pv_societe_absorbee,
                   pv_societe_absorbante) || substr(zl_orig.tax, 5);
  
    IF vn_tax_id IS NULL THEN
      IF NOT dka_print_debug_f(pv_position_debug => 0,
                               pv_marque         => '!',
                               pv_msg            => 'Code tax ' || vv_tax_name ||
                                                    ' not found') THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      dka_tools_pkg.put_outdebug_message('Code tax ' || vv_tax_name ||
                                         ' inexistant');
      pv_tax_code := NULL;
      -- Erreur lors d'un controle
      vb_erreur_ctr := TRUE;
    ELSE
      IF NOT
          dka_print_debug_f(pv_position_debug => 0,
                            pv_marque         => '*',
                            pv_msg            => 'Id Code tax ' || vv_tax_name || ': ' ||
                                                 vn_tax_id) THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      pv_tax_code := vv_tax_name;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_NEW_TAX_F (' ||
                                                  pv_societe_absorbee || ',' ||
                                                  pv_societe_absorbante || ',' ||
                                                  pn_tax_code_id || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_NEW_TAX_F (' ||
                                         pv_societe_absorbante || ',' ||
                                         pn_tax_code_id || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN FALSE;
  END dka_new_tax_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INS_INV_DIST_INT_F
  --  Description   : Insertion dans dka_fusion_ap_inv_lin_int
  --
  --  PARAMETRES    : Liste des champs
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ins_inv_dist_int_f(pn_invoice_id                IN NUMBER,
                                  pn_line_number               IN NUMBER,
                                  pn_invoice_line_id           IN NUMBER,
                                  pv_line_type_lookup_code     IN VARCHAR2,
                                  pn_amount                    IN NUMBER,
                                  pv_description               IN VARCHAR2,
                                  pv_amount_includes_tax_flag  IN VARCHAR2,
                                  pv_tax_code                  IN VARCHAR2,
                                  pn_dist_code_combination_id  IN NUMBER,
                                  pv_attribute_category        IN VARCHAR2,
                                  pv_attribute1                IN VARCHAR2,
                                  pv_attribute2                IN VARCHAR2,
                                  pv_attribute3                IN VARCHAR2,
                                  pv_attribute4                IN VARCHAR2,
                                  pv_attribute5                IN VARCHAR2,
                                  pv_attribute6                IN VARCHAR2,
                                  pv_attribute7                IN VARCHAR2,
                                  pv_attribute8                IN VARCHAR2,
                                  pv_attribute9                IN VARCHAR2,
                                  pv_attribute10               IN VARCHAR2,
                                  pv_attribute11               IN VARCHAR2,
                                  pv_attribute12               IN VARCHAR2,
                                  pv_attribute13               IN VARCHAR2,
                                  pv_attribute14               IN VARCHAR2,
                                  pv_attribute15               IN VARCHAR2,
                                  pv_global_attribute_category IN VARCHAR2,
                                  pv_global_attribute1         IN VARCHAR2,
                                  pv_global_attribute2         IN VARCHAR2,
                                  pv_global_attribute3         IN VARCHAR2,
                                  pv_global_attribute4         IN VARCHAR2,
                                  pv_global_attribute5         IN VARCHAR2,
                                  pv_global_attribute6         IN VARCHAR2,
                                  pv_global_attribute7         IN VARCHAR2,
                                  pv_global_attribute8         IN VARCHAR2,
                                  pv_global_attribute9         IN VARCHAR2,
                                  pv_global_attribute10        IN VARCHAR2,
                                  pv_global_attribute11        IN VARCHAR2,
                                  pv_global_attribute12        IN VARCHAR2,
                                  pv_global_attribute13        IN VARCHAR2,
                                  pv_global_attribute14        IN VARCHAR2,
                                  pv_global_attribute15        IN VARCHAR2,
                                  pv_global_attribute16        IN VARCHAR2,
                                  pv_global_attribute17        IN VARCHAR2,
                                  pv_global_attribute18        IN VARCHAR2,
                                  pv_global_attribute19        IN VARCHAR2,
                                  pv_global_attribute20        IN VARCHAR,
                                  pn_tax_recovery_rate         IN NUMBER,
                                  pn_org_id                    IN NUMBER,
                                  pv_type_1099                 IN VARCHAR2,
                                  pv_tax_recoverable_flag      IN VARCHAR2,
                                  pn_line_group_number         IN NUMBER,
                                  pd_accounting_date           IN DATE,
                                  pv_prorate_across_flag       IN VARCHAR2,
                                  pv_asset_tracking_flag       IN VARCHAR2,
                                  pv_tax_regime_code           IN VARCHAR2,
                                  pv_tax                       IN VARCHAR2,
                                  pv_tax_jurisdiction_code     IN VARCHAR2,
                                  pv_tax_status_code           IN VARCHAR2,
                                  pn_tax_rate_id               IN NUMBER,
                                  pv_tax_rate_code             IN VARCHAR2,
                                  pv_tax_classification_code   IN VARCHAR2)
    RETURN BOOLEAN IS
    dka_erreur_oracle VARCHAR2(80);
  BEGIN
    -- Erreur lors d'un controle -> ROLLBACK en fin de traitement
    /* IF Vb_Erreur_Ctr
    THEN
       RETURN TRUE;
    END IF;*/
  
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_INS_INV_DIST_INT_F (' ||
                                                  pn_invoice_id || ',' ||
                                                  pn_line_number || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    INSERT INTO dka_fusion_ap_inv_lin_int
      (invoice_id,
       invoice_line_id,
       line_number,
       line_type_lookup_code,
       amount,
       description,
       amount_includes_tax_flag,
       tax_code,
       dist_code_combination_id,
       attribute_category,
       attribute1,
       attribute2,
       attribute3,
       attribute4,
       attribute5,
       attribute6,
       attribute7,
       attribute8,
       attribute9,
       attribute10,
       attribute11,
       attribute12,
       attribute13,
       attribute14,
       attribute15,
       global_attribute_category,
       global_attribute1,
       global_attribute2,
       global_attribute3,
       global_attribute4,
       global_attribute5,
       global_attribute6,
       global_attribute7,
       global_attribute8,
       global_attribute9,
       global_attribute10,
       global_attribute11,
       global_attribute12,
       global_attribute13,
       global_attribute14,
       global_attribute15,
       global_attribute16,
       global_attribute17,
       global_attribute18,
       global_attribute19,
       global_attribute20,
       tax_recovery_rate,
       org_id,
       type_1099,
       line_group_number,
       accounting_date,
       prorate_across_flag,
       last_updated_by,
       last_update_date,
       creation_date,
       created_by,
       assets_tracking_flag,
       tax_regime_code,
       tax,
       tax_jurisdiction_code,
       tax_status_code,
       tax_rate_id,
       tax_rate_code,
       tax_classification_code
       
       )
    VALUES
      (pn_invoice_id,
       pn_invoice_line_id,
       pn_line_number,
       pv_line_type_lookup_code,
       pn_amount,
       pv_description,
       pv_amount_includes_tax_flag,
       pv_tax_code,
       pn_dist_code_combination_id,
       pv_attribute_category,
       pv_attribute1,
       pv_attribute2,
       pv_attribute3,
       pv_attribute4,
       pv_attribute5,
       pv_attribute6,
       pv_attribute7,
       pv_attribute8,
       pv_attribute9,
       pv_attribute10,
       pv_attribute11,
       pv_attribute12,
       pv_attribute13,
       pv_attribute14,
       pv_attribute15,
       pv_global_attribute_category,
       pv_global_attribute1,
       pv_global_attribute2,
       pv_global_attribute3,
       pv_global_attribute4,
       pv_global_attribute5,
       pv_global_attribute6,
       pv_global_attribute7,
       pv_global_attribute8,
       pv_global_attribute9,
       pv_global_attribute10,
       pv_global_attribute11,
       pv_global_attribute12,
       pv_global_attribute13,
       pv_global_attribute14,
       pv_global_attribute15,
       pv_global_attribute16,
       pv_global_attribute17,
       pv_global_attribute18,
       pv_global_attribute19,
       pv_global_attribute20,
       pn_tax_recovery_rate,
       pn_org_id,
       pv_type_1099,
       pn_line_group_number,
       pd_accounting_date,
       pv_prorate_across_flag,
       fnd_profile.value('USER_ID'),
       SYSDATE,
       SYSDATE,
       fnd_profile.value('USER_ID'),
       pv_asset_tracking_flag,
       pv_tax_regime_code,
       pv_tax,
       pv_tax_jurisdiction_code,
       pv_tax_status_code,
       pn_tax_rate_id,
       pv_tax_rate_code,
       pv_tax_classification_code);
  
    vn_nbre_lignes := vn_nbre_lignes + 1;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => '1 row inserted in DKA_FUSION_AP_INV_LIN_INT') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_INS_INV_DIST_INT_F (' ||
                                                  pn_invoice_id || ',' ||
                                                  pn_line_number || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
  
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_INS_INV_DIST_INT_F (' ||
                                         pn_invoice_id || ',' ||
                                         pn_line_number || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_ins_inv_dist_int_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_AP_INVOICE_LINES_INT_F
  --  Description   : Traitement des lignes de distribution
  --
  --  PARAMETRES    : Id de la facture d'origine
  --                  Societe absorbee
  --                  Societe absorbante
  --                  New Id de la facture de la societe absorbee
  --                  New Id de la facture de la societe absorbante
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ap_invoice_lines_int_f(pn_invoice_id_orig           IN NUMBER,
                                      pv_invoice_num_orig          IN VARCHAR2,
                                      pv_societe_absorbee          IN VARCHAR2,
                                      pv_societe_absorbante        IN VARCHAR2,
                                      pn_new_invoice_id_absorbee   IN NUMBER,
                                      pn_new_invoice_id_absorbante IN NUMBER,
                                      pv_cpt_local_generique       IN VARCHAR2,
                                      pv_cpt_grpe_generique        IN VARCHAR2,
                                      pd_accounting_date           IN DATE,
                                      pn_org_id_absorbee           IN NUMBER,
                                      pn_org_id_absorbante         IN NUMBER)
    RETURN BOOLEAN IS
  
    CURSOR cur_ap_inv_line_interface IS
      SELECT
      -- <> Acomptes
      -- 01/01/19 NBO Modification suite aux tests d'intégration
      --  Aida.Distribution_Line_Number
      -- RG7 : Montant au prorata
      -- Montant de la ligne = Montant restant a payer / Montant total de la facture * Montant de la ligne
      --, ROUND (NVL(Aida.Amount,0) * NVL(SUM(Apsa.Amount_Remaining),0) / NVL(Aia.Invoice_Amount,0),2) Amount
       SUM(round(nvl(aida.amount, 0) * nvl(apsa.amount_remaining, 0) /
                 nvl(aia.invoice_amount, 0),
                 2)) amount,
       aida.description,
       aida.amount_includes_tax_flag,
       aida.tax_code_id,
       aida.dist_code_combination_id,
       aida.attribute_category,
       aida.attribute1,
       aida.attribute2,
       aida.attribute3,
       aida.attribute4,
       aida.attribute5,
       aida.attribute6,
       aida.attribute7,
       aida.attribute8,
       aida.attribute9,
       aida.attribute10,
       aida.attribute11,
       aida.attribute12,
       aida.attribute13,
       aida.attribute14,
       aida.attribute15,
       aida.global_attribute_category,
       aida.global_attribute1,
       aida.global_attribute2,
       aida.global_attribute3,
       aida.global_attribute4,
       aida.global_attribute5,
       aida.global_attribute6,
       aida.global_attribute7,
       aida.global_attribute8,
       aida.global_attribute9,
       aida.global_attribute10,
       aida.global_attribute11,
       aida.global_attribute12,
       aida.global_attribute13,
       aida.global_attribute14,
       aida.global_attribute15,
       aida.global_attribute16,
       aida.global_attribute17,
       aida.global_attribute18,
       aida.global_attribute19,
       aida.global_attribute20,
       aida.tax_recovery_rate,
       aida.org_id,
       zrb.tax taxe_code_name
       --, Aida.Line_Type_Lookup_Code
      ,
       decode(aida.line_type_lookup_code,
              'NONREC_TAX',
              'TAX',
              'REC_TAX',
              'TAX',
              'IPV',
              'ITEM',
              aida.line_type_lookup_code) line_type_lookup_code,
       aida.type_1099,
       aia.invoice_type_lookup_code,
       aida.tax_recoverable_flag,
       aida.assets_tracking_flag,
       zrb.source_id,
       aila.line_group_number,
       decode(aila.line_type_lookup_code,
              'ITEM',
              aila.tax_classification_code,
              aila.tax_rate_code) tax_rate_code,
       aila.tax_classification_code
        FROM ap_invoice_distributions_all aida,
             ap_payment_schedules_all     apsa,
             ap_invoices_all              aia,
             zx_rates_b                   zrb,
             ap_invoice_lines_all         aila
       WHERE aida.invoice_id = pn_invoice_id_orig
         AND aida.accrual_posted_flag = 'Y'
         AND apsa.invoice_id = pn_invoice_id_orig
         AND aia.invoice_id = pn_invoice_id_orig
         AND zrb.source_id(+) = aida.tax_code_id
         AND aila.invoice_id = aida.invoice_id
         AND aila.line_number = aida.invoice_line_number
         AND aia.invoice_type_lookup_code <> 'PREPAYMENT'
         AND aida.line_type_lookup_code <> 'NONREC_TAX'
         AND nvl(aila.tax_status_code, 'ITEM') <> 'OFFSET'
            -- 03/01/19 NBO Rejet des lignes abandonnees
         AND nvl(aila.DISCARDED_FLAG, 'N') = 'N'
       GROUP BY --  Aida.Distribution_Line_Number
                --, Aida.Amount
                --, Aia.Invoice_Amount
                 aida.description,
                aida.amount_includes_tax_flag,
                aida.tax_code_id,
                aida.dist_code_combination_id,
                aida.attribute_category,
                aida.attribute1,
                aida.attribute2,
                aida.attribute3,
                aida.attribute4,
                aida.attribute5,
                aida.attribute6,
                aida.attribute7,
                aida.attribute8,
                aida.attribute9,
                aida.attribute10,
                aida.attribute11,
                aida.attribute12,
                aida.attribute13,
                aida.attribute14,
                aida.attribute15,
                aida.global_attribute_category,
                aida.global_attribute1,
                aida.global_attribute2,
                aida.global_attribute3,
                aida.global_attribute4,
                aida.global_attribute5,
                aida.global_attribute6,
                aida.global_attribute7,
                aida.global_attribute8,
                aida.global_attribute9,
                aida.global_attribute10,
                aida.global_attribute11,
                aida.global_attribute12,
                aida.global_attribute13,
                aida.global_attribute14,
                aida.global_attribute15,
                aida.global_attribute16,
                aida.global_attribute17,
                aida.global_attribute18,
                aida.global_attribute19,
                aida.global_attribute20,
                aida.tax_recovery_rate,
                aida.org_id,
                zrb.tax
                --, Aida.Line_Type_Lookup_Code
               ,
                decode(aida.line_type_lookup_code,
                       'NONREC_TAX',
                       'TAX',
                       'REC_TAX',
                       'TAX',
                       'IPV',
                       'ITEM',
                       aida.line_type_lookup_code),
                aida.type_1099,
                aia.invoice_type_lookup_code,
                aida.tax_recoverable_flag,
                aida.assets_tracking_flag,
                zrb.source_id,
                aila.line_group_number,
                decode(aila.line_type_lookup_code,
                       'ITEM',
                       aila.tax_classification_code,
                       aila.tax_rate_code),
                aila.tax_classification_code
      UNION ALL
      SELECT
      -- Acomptes
      -- 01/01/19 NBO Modification suite aux tests d'intégration
      --  Aida.Distribution_Line_Number
      -- RG7 : Montant au prorata
      -- Montant de la ligne = Montant restant a appliquer / Montant total de la facture * Montant de la ligne
      --, ROUND ( NVL(Ap_Invoices_Utility_PKG.get_prepay_amount_remaining (Aia.invoice_Id),0) * NVL(Aida.Amount,0) / NVL(Aia.Invoice_Amount,0) ,2) Amount
       SUM(round(nvl(ap_invoices_utility_pkg.get_prepay_amount_remaining(aia.invoice_id),
                     0) * nvl(aida.amount, 0) / nvl(aia.invoice_amount, 0),
                 2)) amount,
       aida.description,
       aida.amount_includes_tax_flag,
       aida.tax_code_id,
       aida.dist_code_combination_id,
       aida.attribute_category,
       aida.attribute1,
       aida.attribute2,
       aida.attribute3,
       aida.attribute4,
       aida.attribute5,
       aida.attribute6,
       aida.attribute7,
       aida.attribute8,
       aida.attribute9,
       aida.attribute10,
       aida.attribute11,
       aida.attribute12,
       aida.attribute13,
       aida.attribute14,
       aida.attribute15,
       aida.global_attribute_category,
       aida.global_attribute1,
       aida.global_attribute2,
       aida.global_attribute3,
       aida.global_attribute4,
       aida.global_attribute5,
       aida.global_attribute6,
       aida.global_attribute7,
       aida.global_attribute8,
       aida.global_attribute9,
       aida.global_attribute10,
       aida.global_attribute11,
       aida.global_attribute12,
       aida.global_attribute13,
       aida.global_attribute14,
       aida.global_attribute15,
       aida.global_attribute16,
       aida.global_attribute17,
       aida.global_attribute18,
       aida.global_attribute19,
       aida.global_attribute20,
       aida.tax_recovery_rate,
       aida.org_id,
       zrb.tax taxe_code_name
       --, Aida.Line_Type_Lookup_Code
      ,
       decode(aida.line_type_lookup_code,
              'NONREC_TAX',
              'TAX',
              'REC_TAX',
              'TAX',
              'IPV',
              'ITEM',
              aida.line_type_lookup_code) line_type_lookup_code,
       aida.type_1099,
       aia.invoice_type_lookup_code,
       aida.tax_recoverable_flag,
       aida.assets_tracking_flag,
       zrb.source_id,
       aila.line_group_number,
       decode(aila.line_type_lookup_code,
              'ITEM',
              aila.tax_classification_code,
              aila.tax_rate_code) tax_rate_code,
       aila.tax_classification_code
        FROM ap_invoice_distributions_all aida,
             ap_invoices_all              aia,
             zx_rates_b                   zrb,
             ap_invoice_lines_all         aila
       WHERE aida.invoice_id = pn_invoice_id_orig
         AND aida.accrual_posted_flag = 'Y'
            -- Debut Modif EMA du 14/10/2005
            --AND Aipa.Prepay_Id = Pn_Invoice_Id_Orig
            -- Fin Modif EMA du 14/10/2005
         AND aia.invoice_id = pn_invoice_id_orig
         AND zrb.source_id(+) = aida.tax_code_id
         AND aila.invoice_id = aida.invoice_id
         AND aila.line_number = aida.invoice_line_number
         AND aia.invoice_type_lookup_code = 'PREPAYMENT'
         AND aida.line_type_lookup_code <> 'NONREC_TAX'
         AND nvl(aila.tax_status_code, 'ITEM') <> 'OFFSET'
            -- 03/01/19 NBO Rejet des lignes abandonnees
         AND nvl(aila.DISCARDED_FLAG, 'N') = 'N'
       GROUP BY --  Aida.Distribution_Line_Number
                --, Aida.Amount
                --, Aia.Invoice_Amount
                 aida.description,
                aida.amount_includes_tax_flag,
                aida.tax_code_id,
                aida.dist_code_combination_id,
                aida.attribute_category,
                aida.attribute1,
                aida.attribute2,
                aida.attribute3,
                aida.attribute4,
                aida.attribute5,
                aida.attribute6,
                aida.attribute7,
                aida.attribute8,
                aida.attribute9,
                aida.attribute10,
                aida.attribute11,
                aida.attribute12,
                aida.attribute13,
                aida.attribute14,
                aida.attribute15,
                aida.global_attribute_category,
                aida.global_attribute1,
                aida.global_attribute2,
                aida.global_attribute3,
                aida.global_attribute4,
                aida.global_attribute5,
                aida.global_attribute6,
                aida.global_attribute7,
                aida.global_attribute8,
                aida.global_attribute9,
                aida.global_attribute10,
                aida.global_attribute11,
                aida.global_attribute12,
                aida.global_attribute13,
                aida.global_attribute14,
                aida.global_attribute15,
                aida.global_attribute16,
                aida.global_attribute17,
                aida.global_attribute18,
                aida.global_attribute19,
                aida.global_attribute20,
                aida.tax_recovery_rate,
                aida.org_id,
                zrb.tax
                --, Aida.Line_Type_Lookup_Code
               ,
                decode(aida.line_type_lookup_code,
                       'NONREC_TAX',
                       'TAX',
                       'REC_TAX',
                       'TAX',
                       'IPV',
                       'ITEM',
                       aida.line_type_lookup_code),
                aida.type_1099,
                aia.invoice_type_lookup_code,
                round(nvl(ap_invoices_utility_pkg.get_prepay_amount_remaining(aia.invoice_id),
                          0) * nvl(aida.amount, 0) /
                      nvl(aia.invoice_amount, 0),
                      2),
                aida.tax_recoverable_flag,
                aida.assets_tracking_flag,
                zrb.source_id,
                aila.line_group_number,
                decode(aila.line_type_lookup_code,
                       'ITEM',
                       aila.tax_classification_code,
                       aila.tax_rate_code),
                aila.tax_classification_code;
  
    dka_erreur_oracle VARCHAR2(80);
  
    rec_ap_inv_line_interface cur_ap_inv_line_interface%ROWTYPE;
    vn_invoice_line_id        ap_invoice_lines_interface.invoice_line_id%TYPE;
  
    -- Tax_Code_Id de la societe ansorbante
    vv_tax_code_absorbante ap.ap_invoice_lines_interface.tax_code%TYPE;
  
    vn_new_dist_ccid           gl_code_combinations.code_combination_id%TYPE;
    vv_tax_regime_code         zx_rates_b.tax_regime_code%TYPE;
    vv_tax                     zx_rates_b.tax%TYPE;
    vv_tax_jurisdiction_code   zx_rates_b.tax_jurisdiction_code%TYPE;
    vv_tax_status_code         zx_rates_b.tax_status_code%TYPE;
    vn_tax_rate_id             zx_rates_b.tax_rate_id%TYPE;
    vv_tax_rate_code           zx_rates_b.tax_rate_code%TYPE;
    vv_tax_classification_code zx_rates_b.tax_rate_code%TYPE;
    vv_prorate_across_flag     dka_fusion_ap_inv_lin_int.prorate_across_flag%TYPE;
    vv_line_group_number       ap_invoice_distributions_all.line_group_number%TYPE;
    vv_line_number             ap_invoice_distributions_all.distribution_line_number%TYPE := 0;
    vv_step                    VARCHAR2(50);
  
  BEGIN
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_AP_INVOICE_LINES_INT_F (' ||
                                               pn_invoice_id_orig || ',' ||
                                               pv_invoice_num_orig ||
                                               pv_societe_absorbee || ',' ||
                                               pv_societe_absorbante ||
                                               pn_new_invoice_id_absorbee || ',' ||
                                               pn_new_invoice_id_absorbante ||
                                               pv_cpt_local_generique || ',' ||
                                               pv_cpt_grpe_generique || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    FOR rec_ap_inv_line_interface IN cur_ap_inv_line_interface LOOP
      vv_line_number := vv_line_number + 1;
      IF NOT dka_print_debug_f(pv_position_debug => +1,
                               pv_marque         => '>'
                               --, Pv_Msg => 'Line '||Rec_Ap_Inv_Line_Interface.Distribution_Line_Number)
                              ,
                               pv_msg => 'Line ' || vv_line_number) THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      -- Societe absorbante
      -- Tax_Code de la societe absorbante
      /*
      IF Rec_Ap_Inv_Line_Interface.Tax_Code_Id IS NULL
      THEN
         Vv_Tax_Code_Absorbante := NULL ;
      ELSE
         IF NOT DKA_NEW_TAX_F ( Pv_Societe_Absorbee => Pv_Societe_Absorbee
                              , Pv_Societe_Absorbante => Pv_Societe_Absorbante
                              , Pn_Tax_Code_Id => Rec_Ap_Inv_Line_Interface.Tax_Code_Id
                              , Pv_Tax_Code  => Vv_Tax_Code_Absorbante )
         THEN
            RETURN FALSE;
         END IF;
      END IF; /* Rec_Ap_Inv_Line_Interface.Tax_Code_Id IS NULL */
    
      -- Recherche de DIST_CODE_COMBINATION_ID pour le societe absorbante
      vn_new_dist_ccid := dka_new_dist_ccid_f(pn_ccid_orig             => rec_ap_inv_line_interface.dist_code_combination_id,
                                              pv_line_type_lookup_code => rec_ap_inv_line_interface.line_type_lookup_code,
                                              pv_societe_absorbee      => pv_societe_absorbee,
                                              pv_societe_absorbante    => pv_societe_absorbante,
                                              pv_cpt_local_generique   => pv_cpt_local_generique,
                                              pv_cpt_grpe_generique    => pv_cpt_grpe_generique,
                                              pv_invoice_num           => pv_invoice_num_orig
                                              --, Pn_Distribution_Line_Number => Rec_Ap_Inv_Line_Interface.Distribution_Line_Number
                                             ,
                                              pn_distribution_line_number => vv_line_number,
                                              pv_invoice_type             => rec_ap_inv_line_interface.invoice_type_lookup_code
                                              -- Societe absorbante
                                             ,
                                              pn_type_ccid => 2);
      IF vn_new_dist_ccid = -1 THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      -- Récupération données taxes si ligne de type TAX
      IF rec_ap_inv_line_interface.line_type_lookup_code = 'TAX' THEN
        SELECT zrb.tax_regime_code,
               zrb.tax,
               zrb.tax_jurisdiction_code,
               zrb.tax_status_code,
               zrb.tax_rate_code
          INTO vv_tax_regime_code,
               vv_tax,
               vv_tax_jurisdiction_code,
               vv_tax_status_code,
               vv_tax_rate_code
          FROM zx_rates_b zrb
         WHERE zrb.source_id = rec_ap_inv_line_interface.source_id;
      ELSE
        vv_tax_regime_code       := NULL;
        vv_tax                   := NULL;
        vv_tax_jurisdiction_code := NULL;
        vv_tax_status_code       := NULL;
        vv_tax_rate_code         := NULL;
      END IF;
    
      -- Si ligne hors taxe
      vv_step := 'LIGNE_HT';
      IF rec_ap_inv_line_interface.amount_includes_tax_flag = 'N' THEN
        SELECT zrb.tax_rate_code
          INTO vv_tax_classification_code
          FROM zx_rates_b zrb
         WHERE zrb.source_id = rec_ap_inv_line_interface.source_id;
      ELSE
        vv_tax_classification_code := NULL;
      END IF;
    
      --
      vv_step := 'PRORATE_ACROSS_FLAG';
      IF rec_ap_inv_line_interface.line_type_lookup_code LIKE '%TAX%' THEN
        vv_prorate_across_flag := 'Y';
      ELSE
        vv_prorate_across_flag := 'N';
      END IF;
    
      SELECT ap_invoice_lines_interface_s.nextval
        INTO vn_invoice_line_id
        FROM dual;
    
      -- récupération du numéro de groupe
      vv_step := 'LINE_GROUP_NUMBER:' ||
                 rec_ap_inv_line_interface.line_group_number || ':' ||
                 rec_ap_inv_line_interface.tax_rate_code;
      IF rec_ap_inv_line_interface.line_group_number IS NULL AND
         rec_ap_inv_line_interface.tax_rate_code IS NOT NULL THEN
        SELECT num_group
          INTO vv_line_group_number
          FROM (SELECT tax_rate_code, rownum num_group
                  FROM zx_rates_b
                 WHERE SYSDATE BETWEEN effective_from AND
                       nvl(effective_to, SYSDATE)
                   AND active_flag = 'Y'
                 ORDER BY tax_rate_code) v
         WHERE tax_rate_code = rec_ap_inv_line_interface.tax_rate_code;
      ELSE
        vv_line_group_number := rec_ap_inv_line_interface.line_group_number;
      END IF;
    
      vv_step := 'INS_dka_ins_inv_dist_int_f';
      IF NOT
          dka_ins_inv_dist_int_f(pn_invoice_id => pn_new_invoice_id_absorbante
                                 --, Pn_Line_Number => Rec_Ap_Inv_Line_Interface.Distribution_Line_Number
                                ,
                                 pn_line_number               => vv_line_number,
                                 pn_invoice_line_id           => vn_invoice_line_id,
                                 pv_line_type_lookup_code     => rec_ap_inv_line_interface.line_type_lookup_code,
                                 pn_amount                    => rec_ap_inv_line_interface.amount,
                                 pv_description               => rec_ap_inv_line_interface.description,
                                 pv_amount_includes_tax_flag  => NULL,
                                 pv_tax_code                  => NULL,
                                 pn_dist_code_combination_id  => vn_new_dist_ccid,
                                 pv_attribute_category        => rec_ap_inv_line_interface.attribute_category,
                                 pv_attribute1                => NULL,
                                 pv_attribute2                => NULL,
                                 pv_attribute3                => NULL,
                                 pv_attribute4                => NULL,
                                 pv_attribute5                => NULL,
                                 pv_attribute6                => NULL,
                                 pv_attribute7                => NULL,
                                 pv_attribute8                => NULL,
                                 pv_attribute9                => NULL,
                                 pv_attribute10               => NULL,
                                 pv_attribute11               => NULL,
                                 pv_attribute12               => NULL,
                                 pv_attribute13               => NULL,
                                 pv_attribute14               => NULL,
                                 pv_attribute15               => NULL,
                                 pv_global_attribute_category => NULL,
                                 pv_global_attribute1         => NULL,
                                 pv_global_attribute2         => NULL,
                                 pv_global_attribute3         => NULL,
                                 pv_global_attribute4         => NULL,
                                 pv_global_attribute5         => NULL,
                                 pv_global_attribute6         => NULL,
                                 pv_global_attribute7         => NULL,
                                 pv_global_attribute8         => NULL,
                                 pv_global_attribute9         => NULL,
                                 pv_global_attribute10        => NULL,
                                 pv_global_attribute11        => NULL,
                                 pv_global_attribute12        => NULL,
                                 pv_global_attribute13        => NULL,
                                 pv_global_attribute14        => NULL,
                                 pv_global_attribute15        => NULL,
                                 pv_global_attribute16        => NULL,
                                 pv_global_attribute17        => NULL,
                                 pv_global_attribute18        => NULL,
                                 pv_global_attribute19        => NULL,
                                 pv_global_attribute20        => NULL,
                                 pn_tax_recovery_rate         => rec_ap_inv_line_interface.tax_recovery_rate,
                                 pn_org_id                    => pn_org_id_absorbante,
                                 pv_type_1099                 => rec_ap_inv_line_interface.type_1099,
                                 pv_tax_recoverable_flag      => rec_ap_inv_line_interface.tax_recoverable_flag,
                                 pn_line_group_number         => vv_line_group_number,
                                 pd_accounting_date           => pd_accounting_date,
                                 pv_prorate_across_flag       => vv_prorate_across_flag,
                                 pv_asset_tracking_flag       => rec_ap_inv_line_interface.assets_tracking_flag,
                                 pv_tax_regime_code           => vv_tax_regime_code,
                                 pv_tax                       => vv_tax,
                                 pv_tax_jurisdiction_code     => vv_tax_jurisdiction_code,
                                 pv_tax_status_code           => vv_tax_status_code,
                                 pn_tax_rate_id               => NULL,
                                 pv_tax_rate_code             => vv_tax_rate_code,
                                 pv_tax_classification_code   => vv_tax_classification_code) THEN
        RETURN FALSE;
      END IF;
    
      SELECT ap_invoice_lines_interface_s.nextval
        INTO vn_invoice_line_id
        FROM dual;
    
      -- Recherche de DIST_CODE_COMBINATION_ID pour le societe absorbante
      vn_new_dist_ccid := dka_new_dist_ccid_f(pn_ccid_orig             => rec_ap_inv_line_interface.dist_code_combination_id,
                                              pv_line_type_lookup_code => rec_ap_inv_line_interface.line_type_lookup_code,
                                              pv_societe_absorbee      => pv_societe_absorbee,
                                              pv_societe_absorbante    => pv_societe_absorbante,
                                              pv_cpt_local_generique   => pv_cpt_local_generique,
                                              pv_cpt_grpe_generique    => pv_cpt_grpe_generique,
                                              pv_invoice_num           => pv_invoice_num_orig
                                              --, Pn_Distribution_Line_Number => Rec_Ap_Inv_Line_Interface.Distribution_Line_Number
                                             ,
                                              pn_distribution_line_number => vv_line_number,
                                              pv_invoice_type             => rec_ap_inv_line_interface.invoice_type_lookup_code
                                              -- Societe absorbee
                                             ,
                                              pn_type_ccid => 1);
      IF vn_new_dist_ccid = -1 THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
      -- Societe absorbee
      IF NOT
          dka_ins_inv_dist_int_f(pn_invoice_id => pn_new_invoice_id_absorbee
                                 --, Pn_Line_Number => Rec_Ap_Inv_Line_Interface.Distribution_Line_Number
                                ,
                                 pn_line_number           => vv_line_number,
                                 pn_invoice_line_id       => vn_invoice_line_id,
                                 pv_line_type_lookup_code => rec_ap_inv_line_interface.line_type_lookup_code
                                 -- Montant inverse
                                ,
                                 pn_amount                    => - (rec_ap_inv_line_interface.amount),
                                 pv_description               => rec_ap_inv_line_interface.description,
                                 pv_amount_includes_tax_flag  => NULL,
                                 pv_tax_code                  => NULL,
                                 pn_dist_code_combination_id  => vn_new_dist_ccid,
                                 pv_attribute_category        => rec_ap_inv_line_interface.attribute_category,
                                 pv_attribute1                => NULL,
                                 pv_attribute2                => NULL,
                                 pv_attribute3                => NULL,
                                 pv_attribute4                => NULL,
                                 pv_attribute5                => NULL,
                                 pv_attribute6                => NULL,
                                 pv_attribute7                => NULL,
                                 pv_attribute8                => NULL,
                                 pv_attribute9                => NULL,
                                 pv_attribute10               => NULL,
                                 pv_attribute11               => NULL,
                                 pv_attribute12               => NULL,
                                 pv_attribute13               => NULL,
                                 pv_attribute14               => NULL,
                                 pv_attribute15               => NULL,
                                 pv_global_attribute_category => NULL,
                                 pv_global_attribute1         => NULL,
                                 pv_global_attribute2         => NULL,
                                 pv_global_attribute3         => NULL,
                                 pv_global_attribute4         => NULL,
                                 pv_global_attribute5         => NULL,
                                 pv_global_attribute6         => NULL,
                                 pv_global_attribute7         => NULL,
                                 pv_global_attribute8         => NULL,
                                 pv_global_attribute9         => NULL,
                                 pv_global_attribute10        => NULL,
                                 pv_global_attribute11        => NULL,
                                 pv_global_attribute12        => NULL,
                                 pv_global_attribute13        => NULL,
                                 pv_global_attribute14        => NULL,
                                 pv_global_attribute15        => NULL,
                                 pv_global_attribute16        => NULL,
                                 pv_global_attribute17        => NULL,
                                 pv_global_attribute18        => NULL,
                                 pv_global_attribute19        => NULL,
                                 pv_global_attribute20        => NULL,
                                 pn_tax_recovery_rate         => rec_ap_inv_line_interface.tax_recovery_rate,
                                 pn_org_id                    => pn_org_id_absorbee,
                                 pv_type_1099                 => rec_ap_inv_line_interface.type_1099,
                                 pv_tax_recoverable_flag      => rec_ap_inv_line_interface.tax_recoverable_flag,
                                 pn_line_group_number         => vv_line_group_number,
                                 pd_accounting_date           => pd_accounting_date,
                                 pv_prorate_across_flag       => vv_prorate_across_flag,
                                 pv_asset_tracking_flag       => rec_ap_inv_line_interface.assets_tracking_flag,
                                 pv_tax_regime_code           => vv_tax_regime_code,
                                 pv_tax                       => vv_tax,
                                 pv_tax_jurisdiction_code     => vv_tax_jurisdiction_code,
                                 pv_tax_status_code           => vv_tax_status_code,
                                 pn_tax_rate_id               => NULL,
                                 pv_tax_rate_code             => vv_tax_rate_code,
                                 pv_tax_classification_code   => vv_tax_classification_code) THEN
        RETURN FALSE;
      END IF;
    
      IF NOT dka_print_debug_f(pv_position_debug => -1,
                               pv_marque         => '<'
                               --, Pv_Msg => 'Line '||Rec_Ap_Inv_Line_Interface.Distribution_Line_Number)
                              ,
                               pv_msg => 'Line ' || vv_line_number) THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
    END LOOP;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_AP_INVOICE_LINES_INT_F (' ||
                                               pn_invoice_id_orig || ',' ||
                                               pv_invoice_num_orig ||
                                               pv_societe_absorbee || ',' ||
                                               pv_societe_absorbante ||
                                               pn_new_invoice_id_absorbee || ',' ||
                                               pn_new_invoice_id_absorbante ||
                                               pv_cpt_local_generique || ',' ||
                                               pv_cpt_grpe_generique || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  
  EXCEPTION
  
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_AP_INVOICE_LINES_INT_F (' ||
                                         pn_invoice_id_orig || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ') : ' ||
                                         vv_step);
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_ap_invoice_lines_int_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_DELETE_OLD_VALUES_F
  --  Description   : Suppression des donnees inserees du traitement precedent
  --
  --  PARAMETRES    : Aucun
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_delete_old_values_f RETURN BOOLEAN IS
  
    vv_step           VARCHAR2(30);
    dka_erreur_oracle VARCHAR2(80);
  
    vn_nbre_enr NUMBER;
  BEGIN
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_DELETE_OLD_VALUES_F()') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'DKA_FUSION_AP_INV_LIN_INT';
    DELETE dka_fusion_ap_inv_lin_int;
    vn_nbre_enr := SQL%ROWCOUNT;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => vn_nbre_enr ||
                                               ' record deleted in  DKA_FUSION_AP_INV_LIN_INT') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'DKA_FUSION_AP_INV_INT';
    DELETE dka_fusion_ap_inv_int;
    vn_nbre_enr := SQL%ROWCOUNT;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => vn_nbre_enr ||
                                               ' record deleted in DKA_FUSION_AP_INV_INT') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    vv_step := 'DKA_FUSION_AP_INVOICE';
    DELETE dka_fusion_ap_invoice;
    vn_nbre_enr := SQL%ROWCOUNT;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => vn_nbre_enr ||
                                               ' record deleted in DKA_FUSION_AP_INVOICE') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_DELETE_OLD_VALUES_F()') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_DELETE_OLD_VALUES_F - Step ' ||
                                         vv_step || ' ()');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : maj_blocages
  --  Description   : fonction qui met à jour les codes blocages
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_maj_blocage RETURN BOOLEAN IS
  
    CURSOR cur_factures IS
      SELECT aia.invoice_id, aia.invoice_num
        FROM ap_invoices_all      aia,
             po_vendors           pv,
             dka_stransco_headers dsh,
             dka_stransco_lines   dsl
       WHERE aia.pay_group_lookup_code LIKE dsl.return_value || '%'
         AND aia.vendor_id = pv.vendor_id
         AND pv.attribute2 = dsl.return_value
         AND aia.invoice_amount <> 0
         AND aia.amount_paid <> aia.invoice_amount
         AND dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsh.set_id = dsl.set_id;
  
    rec_factures        cur_factures%ROWTYPE;
    vc_description      ap_hold_codes.description%TYPE;
    vc_hold_lookup_code ap_hold_codes.hold_lookup_code%TYPE;
    vn_user_id          fnd_user.user_id%TYPE;
  
    dka_erreur_oracle VARCHAR2(80);
  
  BEGIN
  
    -- Dka_Tools_Pkg.put_outdebug_message ('procédure maj_blocages : début');
  
    vc_hold_lookup_code := 'En attente';
    SELECT ahc.description
      INTO vc_description
      FROM ap_hold_codes ahc
     WHERE ahc.hold_lookup_code = vc_hold_lookup_code;
  
    --Dka_Tools_Pkg.put_outdebug_message ('==> vc_description : ' || vc_description);
  
    SELECT fu.user_id
      INTO vn_user_id
      FROM fnd_user fu
     WHERE fu.user_name = 'APPSMGR';
  
    --Dka_Tools_Pkg.put_outdebug_message ('==> vn_user_id : ' || vn_user_id);
  
    OPEN cur_factures;
    LOOP
      FETCH cur_factures
        INTO rec_factures;
      EXIT WHEN cur_factures%NOTFOUND;
    
      INSERT INTO ap_holds_all
        (invoice_id,
         hold_lookup_code,
         last_update_date,
         last_updated_by,
         held_by,
         hold_date,
         hold_reason,
         creation_date,
         created_by,
         org_id)
      VALUES
        (rec_factures.invoice_id,
         vc_hold_lookup_code,
         SYSDATE,
         vn_user_id,
         vn_user_id,
         SYSDATE,
         vc_description,
         SYSDATE,
         vn_user_id,
         81);
    
      dka_tools_pkg.put_outdebug_message('==> blocage inséré pour la facture : ' ||
                                         rec_factures.invoice_num);
    
    END LOOP;
    CLOSE cur_factures;
  
    -- Dka_Tools_Pkg.put_outdebug_message ('procédure maj_blocages : fin');
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_MAJ_BLOCAGE');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_maj_blocage;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INS_DKA_FUSION_AP_INVOICE_F
  --  Description   : Insertion d'un enregistrement dans DKA_FUSION_AP_INVOICE
  --                  utilisee dans post-fusion pour reaffecter les blocages
  --
  --  PARAMETRES    : Liste des chaps a inserer
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ins_fusion_ap_invoice_f(pv_invoice_num_from VARCHAR2,
                                       pv_invoice_num_to   VARCHAR2,
                                       pn_org_id_from      NUMBER,
                                       pn_org_id_to        NUMBER,
                                       pn_vendor_id        NUMBER,
                                       pv_societe_absorbee VARCHAR2)
    RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
  BEGIN
    IF NOT dka_print_debug_f(pv_position_debug => +1,
                             pv_marque         => '>',
                             pv_msg            => 'DKA_INS_FUSION_AP_INVOICE_F(' ||
                                                  pv_invoice_num_from || ',' ||
                                                  pv_invoice_num_to || ',' ||
                                                  pn_org_id_from || ',' ||
                                                  pn_org_id_to || ',' ||
                                                  pn_vendor_id || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    INSERT INTO dka_fusion_ap_invoice
      (invoice_num_from,
       invoice_num_to,
       org_id_from,
       org_id_to,
       vendor_id,
       societe_absorbee)
    VALUES
      (pv_invoice_num_from,
       pv_invoice_num_to,
       pn_org_id_from,
       pn_org_id_to,
       pn_vendor_id,
       pv_societe_absorbee);
  
    IF NOT
        dka_print_debug_f(pv_position_debug => 0,
                          pv_marque         => '*',
                          pv_msg            => '1 row inserted in DKA_FUSION_AP_INVOICE') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => -1,
                             pv_marque         => '<',
                             pv_msg            => 'DKA_INS_FUSION_AP_INVOICE_F(' ||
                                                  pv_invoice_num_from || ',' ||
                                                  pv_invoice_num_to || ',' ||
                                                  pn_org_id_from || ',' ||
                                                  pn_org_id_to || ',' ||
                                                  pn_vendor_id || ')') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_INS_FUSION_AP_INVOICE_F (' ||
                                         pv_invoice_num_from || ',' ||
                                         pv_invoice_num_to || ',' ||
                                         pn_org_id_from || ',' ||
                                         pn_org_id_to || ',' ||
                                         pn_vendor_id || ')');
    
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_ins_fusion_ap_invoice_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_NEW_ASSET_CCID_F
  --  Description   : Nouveau Ccid de tresorerie (societre absorbante)
  --
  --  PARAMETRES    : CCID d'origine
  --                  societe absorbee
  --                  societe absorbante
  --                  Nom du compte bancaire
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_new_asset_ccid_f(pn_ccid_orig          NUMBER,
                                pv_societe_absorbee   VARCHAR2,
                                pv_societe_absorbante VARCHAR2,
                                pv_bank_account_name  VARCHAR2) RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle DIST_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000);
    vn_retcode NUMBER;
  
  BEGIN
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      RETURN - 1;
    ELSE
    
      -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
      IF NOT dka_value_valid_f(pv_value   => vv_segment1,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 3. Revalidation eventuelle des valeurs ( valeurs destination )
      IF NOT dka_value_valid_f(pv_value   => pv_societe_absorbante,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- 4. Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => pv_societe_absorbante,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 5. recherche du nouveau ccid
      dka_tools_pkg.get_code_combination_id(pv_segment1            => pv_societe_absorbante,
                                            pv_segment2            => vv_segment2,
                                            pv_segment3            => vv_segment3,
                                            pv_segment4            => vv_segment4,
                                            pv_segment5            => vv_segment5,
                                            pv_segment6            => vv_segment6,
                                            pv_segment7            => vv_segment7,
                                            pv_segment8            => vv_segment8,
                                            pv_segment9            => vv_segment9,
                                            pv_segment10           => vv_segment10,
                                            pv_segment11           => vv_segment11,
                                            pv_segment12           => vv_segment12,
                                            pn_code_combination_id => vn_new_ccid,
                                            pv_errbuf              => vv_errbuf,
                                            pn_retcode             => vn_retcode,
                                            pv_validation_flag     => 'Y');
    
      IF nvl(vn_new_ccid, 0) = 0 THEN
        -- Probleme lors de la recherche du noouveau CCID
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID de la cle tresorerie du Pv_Bank_Account_Name compte ' ||
                                           pv_bank_account_name);
        dka_tools_pkg.put_outdebug_message(vv_errbuf);
        -- Erreur lors d'un controle
        vb_erreur_ctr := TRUE;
      END IF;
    
      RETURN nvl(vn_new_ccid, -1);
    
    END IF; /* IF Vn_RetCode = 0 */
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_NEW_DIST_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN - 1;
  END dka_new_asset_ccid_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_NEW_FUTUR_PAY_CCID_F
  --  Description   : Nouveau Ccid de billet a ordre - Comptes bancaires (societe absorbante)
  --
  --  PARAMETRES    : CCID d'origine
  --                  societe absorbee
  --                  societe absorbante
  --                  Nom du compte bancaire
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_new_futur_pay_ccid_f(pn_ccid_orig          NUMBER,
                                    pv_societe_absorbee   VARCHAR2,
                                    pv_societe_absorbante VARCHAR2,
                                    pv_bank_account_name  VARCHAR2)
    RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle DIST_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000);
    vn_retcode NUMBER;
  
  BEGIN
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      RETURN - 1;
    ELSE
    
      -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
      IF NOT dka_value_valid_f(pv_value   => vv_segment1,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 3. Revalidation eventuelle des valeurs ( Valeurs destination )
      IF NOT dka_value_valid_f(pv_value   => pv_societe_absorbante,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- 4. Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => pv_societe_absorbante,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 5. recherche du nouveau ccid
      dka_tools_pkg.get_code_combination_id(pv_segment1            => pv_societe_absorbante,
                                            pv_segment2            => vv_segment2,
                                            pv_segment3            => vv_segment3,
                                            pv_segment4            => vv_segment4,
                                            pv_segment5            => vv_segment5,
                                            pv_segment6            => vv_segment6,
                                            pv_segment7            => vv_segment7,
                                            pv_segment8            => vv_segment8,
                                            pv_segment9            => vv_segment9,
                                            pv_segment10           => vv_segment10,
                                            pv_segment11           => vv_segment11,
                                            pv_segment12           => vv_segment12,
                                            pn_code_combination_id => vn_new_ccid,
                                            pv_errbuf              => vv_errbuf,
                                            pn_retcode             => vn_retcode,
                                            pv_validation_flag     => 'Y');
    
      IF nvl(vn_new_ccid, 0) = 0 THEN
        -- Probleme lors de la recherche du noouveau CCID
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID de billet a ordre du compte ' ||
                                           pv_bank_account_name);
        dka_tools_pkg.put_outdebug_message(vv_errbuf);
        -- Erreur lors d'un controle
        vb_erreur_ctr := TRUE;
      END IF;
    
      RETURN nvl(vn_new_ccid, -1);
    
    END IF; /* IF Vn_RetCode = 0 */
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_NEW_FUTUR_PAY_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN - 1;
  END dka_new_futur_pay_ccid_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_BANK_CHARGES_CCID_F
  --  Description   : Nouveau Ccid des frais bancaires (societe absorbante)
  --
  --  PARAMETRES    : CCID d'origine
  --                  societe absorbee
  --                  societe absorbante
  --                  Nom du compte bancaire (Message)
  --                  Nom du titre de paiement (Message)

  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_bank_charges_ccid_f(pn_ccid_orig          NUMBER,
                                   pv_societe_absorbee   VARCHAR2,
                                   pv_societe_absorbante VARCHAR2,
                                   pv_bank_account_name  VARCHAR2,
                                   pv_check_stock_name   VARCHAR2)
    RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle DIST_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000);
    vn_retcode NUMBER;
  
  BEGIN
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      RETURN - 1;
    ELSE
    
      -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
      IF NOT dka_value_valid_f(pv_value   => vv_segment1,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 3. Revalidation eventuelle des valeurs ( Valeurs destination )
      IF NOT dka_value_valid_f(pv_value   => pv_societe_absorbante,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- 4. Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => pv_societe_absorbante,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 5. recherche du nouveau ccid
      dka_tools_pkg.get_code_combination_id(pv_segment1            => pv_societe_absorbante,
                                            pv_segment2            => vv_segment2,
                                            pv_segment3            => vv_segment3,
                                            pv_segment4            => vv_segment4,
                                            pv_segment5            => vv_segment5,
                                            pv_segment6            => vv_segment6,
                                            pv_segment7            => vv_segment7,
                                            pv_segment8            => vv_segment8,
                                            pv_segment9            => vv_segment9,
                                            pv_segment10           => vv_segment10,
                                            pv_segment11           => vv_segment11,
                                            pv_segment12           => vv_segment12,
                                            pn_code_combination_id => vn_new_ccid,
                                            pv_errbuf              => vv_errbuf,
                                            pn_retcode             => vn_retcode,
                                            pv_validation_flag     => 'Y');
    
      IF nvl(vn_new_ccid, 0) = 0 THEN
        -- Probleme lors de la recherche du noouveau CCID
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID des frais bancaires du compte ' ||
                                           pv_bank_account_name ||
                                           ' - Document ' ||
                                           pv_check_stock_name);
        dka_tools_pkg.put_outdebug_message(vv_errbuf);
        -- Erreur lors d'un controle
        vb_erreur_ctr := TRUE;
      END IF;
    
      RETURN nvl(vn_new_ccid, -1);
    
    END IF; /* IF Vn_RetCode = 0 */
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_BANK_CHARGES_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN - 1;
  END dka_bank_charges_ccid_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_BANK_ERRORS_CCID_F
  --  Description   : Nouveau Ccid des erreurs bancaires (societe absorbante)
  --
  --  PARAMETRES    : CCID d'origine
  --                  societe absorbee
  --                  societe absorbante
  --                  Nom du compte bancaire (Message)
  --                  Nom du titre de paiement (Message)
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_bank_errors_ccid_f(pn_ccid_orig          NUMBER,
                                  pv_societe_absorbee   VARCHAR2,
                                  pv_societe_absorbante VARCHAR2,
                                  pv_bank_account_name  VARCHAR2,
                                  pv_check_stock_name   VARCHAR2)
    RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle DIST_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000);
    vn_retcode NUMBER;
  
  BEGIN
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      RETURN - 1;
    ELSE
    
      -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
      IF NOT dka_value_valid_f(pv_value   => vv_segment1,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 3. Revalidation eventuelle des valeurs ( Valeurs destination )
      IF NOT dka_value_valid_f(pv_value   => pv_societe_absorbante,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- 4. Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => pv_societe_absorbante,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 5. recherche du nouveau ccid
      dka_tools_pkg.get_code_combination_id(pv_segment1            => pv_societe_absorbante,
                                            pv_segment2            => vv_segment2,
                                            pv_segment3            => vv_segment3,
                                            pv_segment4            => vv_segment4,
                                            pv_segment5            => vv_segment5,
                                            pv_segment6            => vv_segment6,
                                            pv_segment7            => vv_segment7,
                                            pv_segment8            => vv_segment8,
                                            pv_segment9            => vv_segment9,
                                            pv_segment10           => vv_segment10,
                                            pv_segment11           => vv_segment11,
                                            pv_segment12           => vv_segment12,
                                            pn_code_combination_id => vn_new_ccid,
                                            pv_errbuf              => vv_errbuf,
                                            pn_retcode             => vn_retcode,
                                            pv_validation_flag     => 'Y');
    
      IF nvl(vn_new_ccid, 0) = 0 THEN
        -- Probleme lors de la recherche du noouveau CCID
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID des erreurs bancaires du compte ' ||
                                           pv_bank_account_name ||
                                           ' - Document ' ||
                                           pv_check_stock_name);
        dka_tools_pkg.put_outdebug_message(vv_errbuf);
        -- Erreur lors d'un controle
        vb_erreur_ctr := TRUE;
      END IF;
    
      RETURN nvl(vn_new_ccid, -1);
    
    END IF; /* IF Vn_RetCode = 0 */
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_BANK_ERRORS_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN - 1;
  END dka_bank_errors_ccid_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_BANK_CASH_CLEARING_CCID_F
  --  Description   : Nouveau Ccid des apurements règlements (societe absorbante)
  --
  --  PARAMETRES    : CCID d'origine
  --                  societe absorbee
  --                  societe absorbante
  --                  Nom du compte bancaire (Message)
  --                  Nom du titre de paiement (Message)
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_bank_cash_clearing_ccid_f(pn_ccid_orig          NUMBER,
                                         pv_societe_absorbee   VARCHAR2,
                                         pv_societe_absorbante VARCHAR2,
                                         pv_bank_account_name  VARCHAR2,
                                         pv_check_stock_name   VARCHAR2)
    RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle DIST_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000);
    vn_retcode NUMBER;
  
  BEGIN
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      RETURN - 1;
    ELSE
    
      -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
      IF NOT dka_value_valid_f(pv_value   => vv_segment1,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 3. Revalidation eventuelle des valeurs ( Valeurs destination )
      IF NOT dka_value_valid_f(pv_value   => pv_societe_absorbante,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- 4. Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => pv_societe_absorbante,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 5. recherche du nouveau ccid
      dka_tools_pkg.get_code_combination_id(pv_segment1            => pv_societe_absorbante,
                                            pv_segment2            => vv_segment2,
                                            pv_segment3            => vv_segment3,
                                            pv_segment4            => vv_segment4,
                                            pv_segment5            => vv_segment5,
                                            pv_segment6            => vv_segment6,
                                            pv_segment7            => vv_segment7,
                                            pv_segment8            => vv_segment8,
                                            pv_segment9            => vv_segment9,
                                            pv_segment10           => vv_segment10,
                                            pv_segment11           => vv_segment11,
                                            pv_segment12           => vv_segment12,
                                            pn_code_combination_id => vn_new_ccid,
                                            pv_errbuf              => vv_errbuf,
                                            pn_retcode             => vn_retcode,
                                            pv_validation_flag     => 'Y');
    
      IF nvl(vn_new_ccid, 0) = 0 THEN
        -- Probleme lors de la recherche du noouveau CCID
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID des apurements bancaires du compte ' ||
                                           pv_bank_account_name ||
                                           ' - Document ' ||
                                           pv_check_stock_name);
        dka_tools_pkg.put_outdebug_message(vv_errbuf);
        -- Erreur lors d'un controle
        vb_erreur_ctr := TRUE;
      END IF;
    
      RETURN nvl(vn_new_ccid, -1);
    
    END IF; /* IF Vn_RetCode = 0 */
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_BANK_CASH_CLEARING_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN - 1;
  END dka_bank_cash_clearing_ccid_f;

  --------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_FUTURE_PAY_CCID_F
  --  Description   : Nouveau Ccid des billets a ordre - Mode de paiement (societe absorbante)
  --
  --  PARAMETRES    : CCID d'origine
  --                  societe absorbee
  --                  societe absorbante
  --                  Nom du compte bancaire (Message)
  --                  Nom du titre de paiement (Message)
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          Autre nouveau Ccid
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_future_pay_ccid_f(pn_ccid_orig          NUMBER,
                                 pv_societe_absorbee   VARCHAR2,
                                 pv_societe_absorbante VARCHAR2,
                                 pv_bank_account_name  VARCHAR2,
                                 pv_check_stock_name   VARCHAR2)
    RETURN NUMBER IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    -- Segments de la cle GL
    vv_segment1  gl_code_combinations.segment1%TYPE;
    vv_segment2  gl_code_combinations.segment2%TYPE;
    vv_segment3  gl_code_combinations.segment3%TYPE;
    vv_segment4  gl_code_combinations.segment4%TYPE;
    vv_segment5  gl_code_combinations.segment5%TYPE;
    vv_segment6  gl_code_combinations.segment6%TYPE;
    vv_segment7  gl_code_combinations.segment7%TYPE;
    vv_segment8  gl_code_combinations.segment8%TYPE;
    vv_segment9  gl_code_combinations.segment9%TYPE;
    vv_segment10 gl_code_combinations.segment10%TYPE;
    vv_segment11 gl_code_combinations.segment11%TYPE;
    vv_segment12 gl_code_combinations.segment12%TYPE;
  
    -- Nouvelle DIST_CODE_COMBINATION_ID
    vn_new_ccid gl_code_combinations.code_combination_id%TYPE := 0;
  
    vv_errbuf  VARCHAR2(32000);
    vn_retcode NUMBER;
  
  BEGIN
    -- 1. recherche des segments du ccid d'origine
    get_all_segments(pn_ccid_orig,
                     seg1         => vv_segment1,
                     seg2         => vv_segment2,
                     seg3         => vv_segment3,
                     seg4         => vv_segment4,
                     seg5         => vv_segment5,
                     seg6         => vv_segment6,
                     seg7         => vv_segment7,
                     seg8         => vv_segment8,
                     seg9         => vv_segment9,
                     seg10        => vv_segment10,
                     seg11        => vv_segment11,
                     seg12        => vv_segment12,
                     errbuf       => vv_errbuf,
                     retcode      => vn_retcode);
  
    IF vn_retcode <> 0 THEN
      -- Probleme
      RETURN - 1;
    ELSE
    
      -- 2. Revalidation eventuelle des valeurs (Valeurs d'origine)
      IF NOT dka_value_valid_f(pv_value   => vv_segment1,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => vv_segment1,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 3. Revalidation eventuelle des valeurs ( Valeurs destination )
      IF NOT dka_value_valid_f(pv_value   => pv_societe_absorbante,
                               pv_segment => 'SEGMENT1') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment2,
                               pv_segment => 'SEGMENT2') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment3,
                               pv_segment => 'SEGMENT3') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment4,
                               pv_segment => 'SEGMENT4') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment5,
                               pv_segment => 'SEGMENT5') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment6,
                               pv_segment => 'SEGMENT6') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment7,
                               pv_segment => 'SEGMENT7') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment8,
                               pv_segment => 'SEGMENT8') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment9,
                               pv_segment => 'SEGMENT9') THEN
        RETURN - 1;
      END IF;
    
      IF NOT dka_value_valid_f(pv_value   => vv_segment10,
                               pv_segment => 'SEGMENT10') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment11,
                               pv_segment => 'SEGMENT11') THEN
        RETURN - 1;
      END IF;
      IF NOT dka_value_valid_f(pv_value   => vv_segment12,
                               pv_segment => 'SEGMENT12') THEN
        RETURN - 1;
      END IF;
    
      -- 4. Revalidation eventuelle du CCID
      IF NOT dka_ccid_valid_f(pv_segment1  => pv_societe_absorbante,
                              pv_segment2  => vv_segment2,
                              pv_segment3  => vv_segment3,
                              pv_segment4  => vv_segment4,
                              pv_segment5  => vv_segment5,
                              pv_segment6  => vv_segment6,
                              pv_segment7  => vv_segment7,
                              pv_segment8  => vv_segment8,
                              pv_segment9  => vv_segment9,
                              pv_segment10 => vv_segment10,
                              pv_segment11 => vv_segment11,
                              pv_segment12 => vv_segment12) THEN
        RETURN - 1;
      END IF;
    
      -- 5. recherche du nouveau ccid
      dka_tools_pkg.get_code_combination_id(pv_segment1            => pv_societe_absorbante,
                                            pv_segment2            => vv_segment2,
                                            pv_segment3            => vv_segment3,
                                            pv_segment4            => vv_segment4,
                                            pv_segment5            => vv_segment5,
                                            pv_segment6            => vv_segment6,
                                            pv_segment7            => vv_segment7,
                                            pv_segment8            => vv_segment8,
                                            pv_segment9            => vv_segment9,
                                            pv_segment10           => vv_segment10,
                                            pv_segment11           => vv_segment11,
                                            pv_segment12           => vv_segment12,
                                            pn_code_combination_id => vn_new_ccid,
                                            pv_errbuf              => vv_errbuf,
                                            pn_retcode             => vn_retcode,
                                            pv_validation_flag     => 'Y');
    
      IF nvl(vn_new_ccid, 0) = 0 THEN
        -- Probleme lors de la recherche du noouveau CCID
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche du CCID des billets a ordre du compte ' ||
                                           pv_bank_account_name ||
                                           ' - Document ' ||
                                           pv_check_stock_name);
        dka_tools_pkg.put_outdebug_message(vv_errbuf);
        -- Erreur lors d'un controle
        vb_erreur_ctr := TRUE;
      END IF;
    
      RETURN nvl(vn_new_ccid, -1);
    
    END IF; /* IF Vn_RetCode = 0 */
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_FUTURE_PAY_CCID_F (' ||
                                         pn_ccid_orig || ',' ||
                                         pv_societe_absorbee || ',' ||
                                         pv_societe_absorbante || ')');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN - 1;
  END dka_future_pay_ccid_f;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_UPD_CHECK_STOCKS_F
  --  Description   : Modification des CCIDs des titres de paiements du compte bancaire dont
  --                  l'id est passe en parametre
  --
  --  PARAMETRES    : Id du compte bancaire
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_upd_check_stocks_f(pn_bank_account_id    NUMBER,
                                  pv_societe_absorbee   VARCHAR2,
                                  pv_societe_absorbante VARCHAR2,
                                  pv_bank_account_name  VARCHAR2)
    RETURN BOOLEAN IS
  
    CURSOR cur_ap_check_stocks_01 IS
      SELECT acsa.bank_charges_ccid,
             acsa.bank_errors_ccid,
             acsa.cash_clearing_ccid,
             acsa.future_pay_code_combination_id,
             acsa.name,
             acsa.last_update_date,
             acsa.last_updated_by,
             acsa.last_update_login
        FROM ap_check_stocks_all acsa
       WHERE acsa.bank_account_id = pn_bank_account_id
         FOR UPDATE OF acsa.future_pay_code_combination_id, acsa.bank_charges_ccid, acsa.bank_errors_ccid, acsa.cash_clearing_ccid, acsa.last_update_date, acsa.last_updated_by, acsa.last_update_login;
  
    rec_ap_check_stocks_01 cur_ap_check_stocks_01%ROWTYPE;
  
    vn_new_bank_charges_ccid  gl_code_combinations.code_combination_id%TYPE;
    vn_new_bank_errors_ccid   gl_code_combinations.code_combination_id%TYPE;
    vn_new_cash_clearing_ccid gl_code_combinations.code_combination_id%TYPE;
    vn_new_future_pay_ccid    gl_code_combinations.code_combination_id%TYPE;
  
    vbn_nbre_bank_updated NUMBER := 0;
    vv_erreur_oracle      VARCHAR2(80);
  
  BEGIN
  
    FOR rec_ap_check_stocks_01 IN cur_ap_check_stocks_01 LOOP
      vn_new_bank_charges_ccid  := NULL;
      vn_new_bank_errors_ccid   := NULL;
      vn_new_cash_clearing_ccid := NULL;
      vn_new_future_pay_ccid    := NULL;
    
      IF rec_ap_check_stocks_01.bank_charges_ccid IS NOT NULL THEN
        -- Nouvelle combinaison
        vn_new_bank_charges_ccid := dka_bank_charges_ccid_f(pn_ccid_orig          => rec_ap_check_stocks_01.bank_charges_ccid,
                                                            pv_societe_absorbee   => pv_societe_absorbee,
                                                            pv_societe_absorbante => pv_societe_absorbante,
                                                            pv_bank_account_name  => pv_bank_account_name,
                                                            pv_check_stock_name   => rec_ap_check_stocks_01.name);
        IF nvl(vn_new_bank_charges_ccid, 0) = -1 THEN
          -- Probleme
          RETURN FALSE;
        END IF;
      
      END IF; /* Rec_Ap_Check_Stocks_01.Bank_Charges_Ccid  IS NOT NULL */
    
      IF rec_ap_check_stocks_01.bank_errors_ccid IS NOT NULL THEN
        -- Nouvelle combinaison
        vn_new_bank_errors_ccid := dka_bank_errors_ccid_f(pn_ccid_orig          => rec_ap_check_stocks_01.bank_errors_ccid,
                                                          pv_societe_absorbee   => pv_societe_absorbee,
                                                          pv_societe_absorbante => pv_societe_absorbante,
                                                          pv_bank_account_name  => pv_bank_account_name,
                                                          pv_check_stock_name   => rec_ap_check_stocks_01.name);
        IF nvl(vn_new_bank_errors_ccid, 0) = -1 THEN
          -- Probleme
          RETURN FALSE;
        END IF;
      
      END IF; /* Rec_Ap_Check_Stocks_01.Bank_Errors_Ccid  IS NOT NULL */
    
      IF rec_ap_check_stocks_01.cash_clearing_ccid IS NOT NULL THEN
        -- Nouvelle combinaison
        vn_new_cash_clearing_ccid := dka_bank_cash_clearing_ccid_f(pn_ccid_orig          => rec_ap_check_stocks_01.cash_clearing_ccid,
                                                                   pv_societe_absorbee   => pv_societe_absorbee,
                                                                   pv_societe_absorbante => pv_societe_absorbante,
                                                                   pv_bank_account_name  => pv_bank_account_name,
                                                                   pv_check_stock_name   => rec_ap_check_stocks_01.name);
        IF nvl(vn_new_cash_clearing_ccid, 0) = -1 THEN
          -- Probleme
          RETURN FALSE;
        END IF;
      
      END IF; /* Rec_Ap_Check_Stocks_01.Cash_Clearing_Ccid */
    
      IF rec_ap_check_stocks_01.future_pay_code_combination_id IS NOT NULL THEN
        -- Nouvelle combinaison
        vn_new_future_pay_ccid := dka_future_pay_ccid_f(pn_ccid_orig          => rec_ap_check_stocks_01.future_pay_code_combination_id,
                                                        pv_societe_absorbee   => pv_societe_absorbee,
                                                        pv_societe_absorbante => pv_societe_absorbante,
                                                        pv_bank_account_name  => pv_bank_account_name,
                                                        pv_check_stock_name   => rec_ap_check_stocks_01.name);
        IF nvl(vn_new_future_pay_ccid, 0) = -1 THEN
          -- Probleme
          RETURN FALSE;
        END IF;
      
      END IF; /* Rec_Ap_Check_Stocks_01.Bank_Errors_Ccid  IS NOT NULL */
    
      --Pas d'erreur lors d'un controle -> OK
      -- Sinon, inutile de mettre a jour puisque ROLLBACK en fin de traitement
      IF NOT vb_erreur_ctr THEN
        IF ((vn_new_bank_charges_ccid IS NOT NULL) OR
           (vn_new_bank_errors_ccid IS NOT NULL) OR
           (vn_new_cash_clearing_ccid IS NOT NULL) OR
           (vn_new_future_pay_ccid IS NOT NULL)) THEN
          -- Au moins une combinaison a modifier
          UPDATE ap_check_stocks_all acsa
             SET acsa.bank_charges_ccid              = decode(nvl(vn_new_bank_charges_ccid,
                                                                  0),
                                                              0,
                                                              NULL,
                                                              vn_new_bank_charges_ccid),
                 acsa.bank_errors_ccid               = decode(nvl(vn_new_bank_errors_ccid,
                                                                  0),
                                                              0,
                                                              NULL,
                                                              vn_new_bank_errors_ccid),
                 acsa.cash_clearing_ccid             = decode(nvl(vn_new_cash_clearing_ccid,
                                                                  0),
                                                              0,
                                                              NULL,
                                                              vn_new_cash_clearing_ccid),
                 acsa.future_pay_code_combination_id = decode(nvl(vn_new_future_pay_ccid,
                                                                  0),
                                                              0,
                                                              NULL,
                                                              vn_new_future_pay_ccid),
                 acsa.last_update_date               = SYSDATE,
                 acsa.last_updated_by                = fnd_profile.value('USER_ID'),
                 acsa.last_update_login              = fnd_profile.value('LOGIN_ID')
           WHERE CURRENT OF cur_ap_check_stocks_01;
          vbn_nbre_bank_updated := vbn_nbre_bank_updated + 1;
        END IF; /*  Vn_New_Bank_Charges_Ccid  IS NOT NULL ... */
      
      END IF; /* NOT Vb_Erreur_Ctr */
    
    END LOOP; /* Rec_Ap_Check_Stocks_01 IN Cur_Ap_Check_Stocks_01 */
  
    -- Pas d'erreur
    IF NOT vb_erreur_ctr THEN
      dka_tools_pkg.put_outdebug_message(vbn_nbre_bank_updated ||
                                         ' titres de paiement mis a jour pour le compte bancaire ' ||
                                         pv_bank_account_name);
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_UPD_CHECK_STOCKS_F ()');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      RETURN FALSE;
  END dka_upd_check_stocks_f;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_UPD_BANK_ACCOUNTS_F
  --  Description   : Modification des comptes bancaires : Non et CCIDs de tresorerie et billet a ordre +
  --                                                       CCIDs des modes de paiements attaches au compte en cours
  --                                                       de traitement
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_upd_bank_accounts_f RETURN BOOLEAN IS
  
    dka_erreur_oracle     VARCHAR2(80);
    vn_new_asset_ccid     gl_code_combinations.code_combination_id%TYPE;
    vn_new_futur_pay_ccid gl_code_combinations.code_combination_id%TYPE;
  
    CURSOR cur_ap_bank_accounts_01 IS
      SELECT abaa.bank_account_name,
             abaa.asset_code_combination_id,
             abaa.future_dated_payment_ccid,
             dsl.param1_value               societe_absorbee,
             dsl.return_value               societe_absorbante,
             abaa.bank_account_id,
             abaa.last_update_date,
             abaa.last_updated_by,
             abaa.last_update_login
        FROM dka_stransco_headers dsh,
             dka_stransco_lines   dsl,
             ap_bank_accounts_all abaa
       WHERE dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsl.set_id = dsh.set_id
         AND dsl.enable = 'Y'
         AND abaa.bank_account_name LIKE (dsl.param1_value || '%')
         AND nvl(abaa.account_type, 'NULL') = 'INTERNAL'
         FOR UPDATE OF abaa.bank_account_name, abaa.asset_code_combination_id, abaa.future_dated_payment_ccid, abaa.last_update_date, abaa.last_updated_by, abaa.last_update_login;
  
    rec_ap_bank_accounts_01 cur_ap_bank_accounts_01%ROWTYPE;
  
    vbn_nbre_bank_updated NUMBER := 0;
  BEGIN
  
    FOR rec_ap_bank_accounts_01 IN cur_ap_bank_accounts_01 LOOP
      vbn_nbre_bank_updated := vbn_nbre_bank_updated + 1;
      vn_new_asset_ccid     := NULL;
      vn_new_futur_pay_ccid := NULL;
    
      IF rec_ap_bank_accounts_01.asset_code_combination_id IS NOT NULL THEN
        -- Nouvelle combinaison
        vn_new_asset_ccid := dka_new_asset_ccid_f(pn_ccid_orig          => rec_ap_bank_accounts_01.asset_code_combination_id,
                                                  pv_societe_absorbee   => substr(rec_ap_bank_accounts_01.societe_absorbee,
                                                                                  4,
                                                                                  4),
                                                  pv_societe_absorbante => substr(rec_ap_bank_accounts_01.societe_absorbante,
                                                                                  4,
                                                                                  4),
                                                  pv_bank_account_name  => rec_ap_bank_accounts_01.bank_account_name);
        IF nvl(vn_new_asset_ccid, 0) = -1 THEN
          -- Probleme
          RETURN FALSE;
        END IF;
      
      END IF; /* Rec_Ap_Bank_Accounts_01.Asset_Code_Combination_Id IS NOT NULL */
    
      IF rec_ap_bank_accounts_01.future_dated_payment_ccid IS NOT NULL THEN
        -- Nouvelle combinaison
        vn_new_futur_pay_ccid := dka_new_futur_pay_ccid_f(pn_ccid_orig          => rec_ap_bank_accounts_01.future_dated_payment_ccid,
                                                          pv_societe_absorbee   => substr(rec_ap_bank_accounts_01.societe_absorbee,
                                                                                          4,
                                                                                          4),
                                                          pv_societe_absorbante => substr(rec_ap_bank_accounts_01.societe_absorbante,
                                                                                          4,
                                                                                          4),
                                                          pv_bank_account_name  => rec_ap_bank_accounts_01.bank_account_name);
        IF nvl(vn_new_futur_pay_ccid, 0) = -1 THEN
          -- Probleme
          RETURN FALSE;
        END IF;
      
      END IF; /* Rec_Ap_Bank_Accounts_01.Future_Dated_Payment_Ccid IS NOT NULL */
    
      --Pas d'erreur lors d'un controle -> OK
      -- Si non, inutile de mettre a jour puisque ROLLBACK en fin de traitement
      --JVI 160506 : on ne modifie pas tt de suite les cptes de trésorerie et de billet à ordre (à cause du lettrage à 0), cett action est faite dans main_Maj_Comptes
      IF NOT vb_erreur_ctr THEN
        UPDATE ap_bank_accounts_all abaa
           SET abaa.bank_account_name = substr(rec_ap_bank_accounts_01.societe_absorbante ||
                                               substr(abaa.bank_account_name,
                                                      5),
                                               1,
                                               80)
               --JVI, Abaa.Asset_Code_Combination_Id = DECODE (NVL(Vn_New_Asset_CCID,0),0,NULL,Vn_New_Asset_CCID)
               --JVI, Abaa.Future_Dated_Payment_Ccid = DECODE (NVL(Vn_New_Futur_Pay_CCID,0),0,NULL,Vn_New_Futur_Pay_CCID)
              ,
               abaa.last_update_date  = SYSDATE,
               abaa.last_updated_by   = fnd_profile.value('USER_ID'),
               abaa.last_update_login = fnd_profile.value('LOGIN_ID')
         WHERE CURRENT OF cur_ap_bank_accounts_01;
      END IF;
    
      -- Maj des comptes des modes de reglements associes au compte bancaire en cours de traitement
      IF NOT dka_upd_check_stocks_f(pn_bank_account_id    => rec_ap_bank_accounts_01.bank_account_id,
                                    pv_societe_absorbee   => substr(rec_ap_bank_accounts_01.societe_absorbee,
                                                                    4,
                                                                    4),
                                    pv_societe_absorbante => substr(rec_ap_bank_accounts_01.societe_absorbante,
                                                                    4,
                                                                    4),
                                    pv_bank_account_name  => substr(substr(rec_ap_bank_accounts_01.societe_absorbante,
                                                                           4,
                                                                           4) ||
                                                                    substr(rec_ap_bank_accounts_01.bank_account_name,
                                                                           5),
                                                                    1,
                                                                    80)) THEN
        -- Probleme
        RETURN FALSE;
      END IF;
    
    END LOOP; /* Rec_Ap_Bank_Accounts_01 IN Cur_Ap_Bank_Accounts_01 */
  
    -- Pas d'erreur
    IF NOT vb_erreur_ctr THEN
      dka_tools_pkg.put_outdebug_message(vbn_nbre_bank_updated ||
                                         ' comptes bancaires mis a jour');
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_UPD_BANK_ACCOUNTS_F ()');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_upd_bank_accounts_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_CPTES_GENERIQUES_F
  --  Description   : Recherche des deux comptes generiques pour les lignes de type ITEM
  --                  Valeurs contenues dans la transco FUSION_COMPTES_GEN
  --
  --  PARAMETRES    : OUT Valeurs genriques du cpte local et cpte groupe
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_cptes_generiques_f(pv_cpte_local  OUT VARCHAR2,
                                  pv_cpte_groupe OUT VARCHAR2) RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
    vv_cpte_local     VARCHAR2(30);
    vv_cpte_groupe    VARCHAR2(30);
  
  BEGIN
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_CPTES_GENERIQUES_F()') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    SELECT dsl_cpt_local.return_value, dsl_cpt_groupe.return_value
      INTO vv_cpte_local, vv_cpte_groupe
      FROM dka_stransco_headers dsh,
           dka_stransco_lines   dsl_cpt_local,
           dka_stransco_lines   dsl_cpt_groupe
     WHERE dsh.set_name = 'FUSION_COMPTES_GEN'
       AND dsl_cpt_local.set_id = dsh.set_id
       AND upper(dsl_cpt_local.param1_value) = 'AP'
       AND upper(dsl_cpt_local.param2_value) = 'COMPTE LOCAL'
       AND upper(dsl_cpt_groupe.param1_value) = 'AP'
       AND upper(dsl_cpt_groupe.param2_value) = 'COMPTE GROUPE';
  
    IF NOT dka_print_debug_f(pv_position_debug => 0,
                             pv_marque         => '*',
                             pv_msg            => 'compte local ' ||
                                                  vv_cpte_local) THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    IF NOT dka_print_debug_f(pv_position_debug => 0,
                             pv_marque         => '*',
                             pv_msg            => 'compte groupe ' ||
                                                  vv_cpte_groupe) THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    pv_cpte_local  := vv_cpte_local;
    pv_cpte_groupe := vv_cpte_groupe;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_CPTES_GENERIQUES_F()') THEN
      -- Probleme
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_CPTES_GENERIQUES_F ()');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_cptes_generiques_f;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Ctr
  --  Description   : procédure principale du controle
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_ctr(pv_errbuf  IN OUT VARCHAR2,
                     pn_retcode OUT NUMBER,
                     pv_debug   IN VARCHAR2) IS
    CURSOR cur_ap_invoice_01 IS
    
      SELECT /*+ ordered use_nl (Aida, Fdsc, Apsa, Pv, Ate, Pvsa, Dsl, Pv) */
       aia.invoice_num,
       aia.invoice_type_lookup_code,
       aia.payment_status_flag,
       aia.org_id,
       aia.invoice_id,
       aia.invoice_amount,
       dsl.return_value societe_absorbante,
       aida.tax_code_id,
       dsl.param1_value societe_absorbee,
       aida.dist_code_combination_id,
       aia.accts_pay_code_combination_id,
       to_char(dsl.start_date, 'YYYY') exercice,
       aia.doc_category_code,
       aia.pay_group_lookup_code,
       aida.line_type_lookup_code,
       aida.distribution_line_number,
       aia.doc_sequence_id,
       trunc(dsl.start_date) date_fusion,
       aspa.set_of_books_id,
       trunc(dsl.start_date) start_date,
       pvsa.pay_site_flag,
       pvsa.inactive_date,
       pvsa.vendor_site_code,
       pv.vendor_name,
       pv.segment1,
       pv.end_date_active,
       pvsa.vendor_site_id,
       pv.vendor_id,
       hou.name,
       aia.creation_date,
       aia.source,
       gld.LEDGER_ID ledger_id_absorbante
        FROM dka_stransco_headers         dsh,
             dka_stransco_lines           dsl,
             ap_invoices_all              aia,
             ap_invoice_distributions_all aida,
             fnd_doc_sequence_categories  fdsc,
             ap_system_parameters_all     aspa,
             po_vendor_sites_all          pvsa,
             po_vendors                   pv,
             hr_operating_units           hou,
             gl_ledgers                   gld
       WHERE dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsl.set_id = dsh.set_id
         AND dsl.enable = 'Y'
         AND fdsc.application_id = 200
         AND fdsc.code = aia.doc_category_code
         AND aida.invoice_id = aia.invoice_id
         AND aspa.org_id = aia.org_id
         AND pvsa.vendor_site_id = aia.vendor_site_id
         AND pv.vendor_id = pvsa.vendor_id
         AND hou.name = dsl.param1_value
         AND aia.org_id = hou.organization_id
         and nvl(aia.AMOUNT_PAID, 0) <> aia.invoice_amount
         and gld.SHORT_NAME = substr(dsl.RETURN_VALUE, 4, 4)
       ORDER BY aia.org_id, aia.invoice_id;
  
    CURSOR cur_ap_site_01 IS
      SELECT distinct pvsa.pay_site_flag,
                      pvsa.inactive_date,
                      pvsa.vendor_site_code,
                      pv.vendor_name,
                      pv.segment1,
                      pv.end_date_active,
                      pvsa.vendor_site_id,
                      pv.vendor_id,
                      hou.name,
                      dsl.return_value societe_absorbante
        FROM dka_stransco_headers         dsh,
             dka_stransco_lines           dsl,
             ap_invoices_all              aia,
             ap_invoice_distributions_all aida,
             fnd_doc_sequence_categories  fdsc,
             ap_system_parameters_all     aspa,
             po_vendor_sites_all          pvsa,
             po_vendors                   pv,
             hr_operating_units           hou,
             gl_ledgers                   gld
       WHERE dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsl.set_id = dsh.set_id
         AND dsl.enable = 'Y'
         AND fdsc.application_id = 200
         AND fdsc.code = aia.doc_category_code
         AND aida.invoice_id = aia.invoice_id
         AND aspa.org_id = aia.org_id
         AND pvsa.vendor_site_id = aia.vendor_site_id
         AND pv.vendor_id = pvsa.vendor_id
         AND hou.name = dsl.param1_value
         AND aia.org_id = hou.organization_id
         and nvl(aia.AMOUNT_PAID, 0) <> aia.invoice_amount
         and gld.SHORT_NAME = substr(dsl.RETURN_VALUE, 4, 4)
       order by pv.vendor_id;
  
    rec_ap_invoice_01 cur_ap_invoice_01%ROWTYPE;
    rec_ap_site_01    cur_ap_site_01%ROWTYPE;
    vv_erreur_oracle  VARCHAR2(80);
  
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
    vn_old_org_id      NUMBER := -1;
    vn_old_invoice_id  NUMBER := -1;
    vv_new_org_id      NUMBER := -1;
    vv_old_invoice_num ap_invoices_all.invoice_num%TYPE;
  
    vv_posting_status VARCHAR2(1);
    --Vv_Approval_Status VARCHAR2(30);
  
    -- Montants par type de facture
    TYPE vt_invoice_type_tab IS TABLE OF ap_invoices_all.invoice_type_lookup_code%TYPE INDEX BY BINARY_INTEGER;
    TYPE vt_invoice_amount_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    vt_invoice_type   vt_invoice_type_tab;
    vt_invoice_amount vt_invoice_amount_tab;
    vn_nbre_rangs     BINARY_INTEGER := 0;
  
    vn_rang_trouve NUMBER;
  
    --Vv_Tax_Code VARCHAR2(30);
  
    -- CCIDs (ligne et entete)
    --Vn_New_Dist_CCID Gl_Code_Combinations.Code_Combination_Id%TYPE;
    --Vn_Accts_Pay_CCID Gl_Code_Combinations.Code_Combination_Id%TYPE;
  
    -- Valeurs genriques des deux comptes generiques pour les
    -- lignes de distribution de type ITEM
    vv_cpt_local_generique VARCHAR2(30);
    vv_cpt_grpe_generique  VARCHAR2(30);
  
    vn_retour NUMBER; --JVI 12/05/2006
  
    -- Erreur lors d'un controle
    dka_erreur_ctr_e EXCEPTION;
  
    -- Id de la sequence destination (societe absorbante)
    vn_doc_seq_id fnd_document_sequences.doc_sequence_id%TYPE; --JVI 12/05/2006
  
    --Vc_Pay_Group_Lookup_Code VARCHAR2(100);
    vn_count_multi NUMBER;
    vn_param       NUMBER := 0;
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Ctr') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    /* vn_param := dka_verif_param;
    IF vn_param > 1 THEN
      dka_tools_pkg.put_outdebug_message('Plusieurs valeurs actives dans la table FUSION_SOCIETE_VERS_SOCIETE');
      RAISE dka_erreur_ctr_e;
    END IF;
    IF vn_param = 0 THEN
      dka_tools_pkg.put_outdebug_message('Aucune valeur active dans la table FUSION_SOCIETE_VERS_SOCIETE');
      RAISE dka_erreur_ctr_e;
    END IF;*/
  
    -- Recherche des comptes generiques pour les lignes de type ITEM
    IF NOT
        dka_cptes_generiques_f(pv_cpte_local  => vv_cpt_local_generique,
                               pv_cpte_groupe => vv_cpt_grpe_generique) THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
    -- RG4 Contrôle des factures en rejet dans l'open interface AP
    IF NOT dka_ctr_rejets THEN
      RAISE dka_erreur_e;
    END IF;
  
    FOR rec_ap_invoice_01 IN cur_ap_invoice_01 LOOP
    
      IF rec_ap_invoice_01.org_id <> vn_old_org_id THEN
      
        -- Positionnement sur l'organisation de la facture
        -- Normalement 1 seul ORG_ID pour l'ensemble des enregistrements
        fnd_client_info.set_org_context(rec_ap_invoice_01.org_id);
      END IF;
    
      IF vn_old_invoice_id <> rec_ap_invoice_01.invoice_id THEN
        -- On a change de facture -> On effectue les differents controles specifiques
        IF vn_old_invoice_id <> -1 THEN
          IF NOT
              dka_print_debug_f(pv_position_debug => -11,
                                pv_marque         => '<',
                                pv_msg            => 'Invoice: ' ||
                                                     vv_old_invoice_num ||
                                                     '(Id: ' ||
                                                     vn_old_invoice_id || ')') THEN
            -- Probleme
            RAISE dka_erreur_e;
          END IF;
        
        END IF; /* Vn_Old_Invoice_Id <> -1 */
      
        IF NOT
            dka_print_debug_f(pv_position_debug => +1,
                              pv_marque         => '>',
                              pv_msg            => 'Invoice: ' ||
                                                   rec_ap_invoice_01.invoice_num ||
                                                   '(Id: ' ||
                                                   rec_ap_invoice_01.invoice_id || ')') THEN
          -- Probleme
          RAISE dka_erreur_e;
        END IF;
      
        -- -------------
        -- RG5 Contrôle des factures et avoirs non ou partiellement comptabilisés
        -- -------------
        vv_posting_status := ap_invoices_utility_pkg.get_posting_status(l_invoice_id => rec_ap_invoice_01.invoice_id);
        IF nvl(vv_posting_status, 'N') <> 'Y' THEN
          dka_tools_pkg.put_outdebug_message('Facture ' ||
                                             rec_ap_invoice_01.invoice_num ||
                                             ' non comptabilisee');
          dka_tools_pkg.put_outdebug_message(rec_ap_invoice_01.invoice_num || '/' ||
                                             rec_ap_invoice_01.invoice_id || '/' ||
                                             rec_ap_invoice_01.name || '/' ||
                                             rec_ap_invoice_01.invoice_amount || '/' ||
                                             rec_ap_invoice_01.creation_date || '/' ||
                                             rec_ap_invoice_01.source);
          -- Erreur lors d'un controle
          vb_erreur_ctr := TRUE;
        END IF;
        /*
                 -- -------------
                 -- 4. Montant par type de facture
                 -- -------------
                 -- Recherche si le type de facture a deja ete traite
                 Vn_Rang_Trouve := 0;
                 FOR I IN 1..Vn_Nbre_Rangs
                 LOOP
                    IF VT_INVOICE_TYPE(I) = Rec_Ap_Invoice_01.Invoice_Type_Lookup_Code
                    THEN
                       Vn_Rang_Trouve := I;
                    END IF;
                 END LOOP;
        
                 IF Vn_Rang_Trouve <> 0
                 THEN
                    -- Type de facture deja traite -> Cumul
                    VT_INVOICE_AMOUNT (Vn_Rang_Trouve) := VT_INVOICE_AMOUNT (Vn_Rang_Trouve) + NVL(Rec_Ap_Invoice_01.Invoice_Amount,0);
                 ELSE
                    -- Nouveau type de facture -> Initalisation
                    Vn_Nbre_Rangs := Vn_Nbre_Rangs +1;
                    VT_INVOICE_AMOUNT (Vn_Nbre_Rangs) := NVL(Rec_Ap_Invoice_01.Invoice_Amount,0);
                    VT_INVOICE_TYPE(Vn_Nbre_Rangs) := Rec_Ap_Invoice_01.Invoice_Type_Lookup_Code;
                 END IF;
        */
        -- RG1 : Contrôle des séquences manquantes
        IF NOT
            dka_ctr_doc_sequence_f(pn_doc_seq_id_orig    => rec_ap_invoice_01.doc_sequence_id,
                                   pv_invoice_num        => rec_ap_invoice_01.invoice_num,
                                   pv_societe_absorbee   => substr(rec_ap_invoice_01.societe_absorbee,
                                                                   4,
                                                                   4),
                                   pv_societe_absorbante => substr(rec_ap_invoice_01.societe_absorbante,
                                                                   4,
                                                                   4),
                                   pv_source             => rec_ap_invoice_01.source,
                                   pn_soc_seq_id_dest    => vn_doc_seq_id) THEN
          -- Probleme
          RAISE dka_erreur_e;
        END IF;
      
        IF nvl(vn_doc_seq_id, 0) <> 0 AND
           rec_ap_invoice_01.source = 'SCAN_XGS' THEN
          -- RG2 : Contrôle des catégories de séquences manquantes dans la société aborbante
          IF NOT dka_ctr_doc_seq_ass_f(pn_doc_seq_id    => vn_doc_seq_id,
                                       pv_invoice_num   => rec_ap_invoice_01.invoice_num,
                                       pv_societe       => rec_ap_invoice_01.societe_absorbante,
                                       pn_sob_id        => rec_ap_invoice_01.ledger_id_absorbante,
                                       pd_date          => rec_ap_invoice_01.start_date,
                                       pv_category_code => REPLACE(substr(rec_ap_invoice_01.doc_category_code,
                                                                          1,
                                                                          4),
                                                                   substr(rec_ap_invoice_01.societe_absorbee,
                                                                          4,
                                                                          4),
                                                                   substr(rec_ap_invoice_01.societe_absorbante,
                                                                          4,
                                                                          4)) ||
                                                           substr(rec_ap_invoice_01.doc_category_code,
                                                                  5)) THEN
            -- Probleme
            RAISE dka_erreur_e;
          END IF;
        END IF;
      
        -- RG3 : Contrôle des affectations de séquence sur la société absorbante
        IF rec_ap_invoice_01.source <> 'SCAN_XGS' THEN
          IF NOT
              dka_ctr_doc_seq_ass_f(pn_doc_seq_id    => rec_ap_invoice_01.doc_sequence_id,
                                    pv_invoice_num   => rec_ap_invoice_01.invoice_num,
                                    pv_societe       => rec_ap_invoice_01.societe_absorbee,
                                    pn_sob_id        => rec_ap_invoice_01.ledger_id_absorbante,
                                    pd_date          => rec_ap_invoice_01.start_date,
                                    pv_category_code => rec_ap_invoice_01.doc_category_code) THEN
            -- Probleme
            RAISE dka_erreur_e;
          END IF;
        END IF;
        -- RG6 : Contrôle des factures multi-échéanciers
        vn_count_multi := 0;
        SELECT COUNT(*)
          INTO vn_count_multi
          FROM ap_payment_schedules_all
         WHERE invoice_id = rec_ap_invoice_01.invoice_id;
      
        IF vn_count_multi > 1 THEN
          dka_tools_pkg.put_outdebug_message('Facture multi-échéancier : ');
          dka_tools_pkg.put_outdebug_message(rec_ap_invoice_01.invoice_num || '/' ||
                                             rec_ap_invoice_01.invoice_id || '/' ||
                                             rec_ap_invoice_01.name || '/' ||
                                             rec_ap_invoice_01.invoice_amount || '/' ||
                                             rec_ap_invoice_01.creation_date || '/' ||
                                             rec_ap_invoice_01.source);
        END IF;
      
        -- -------------
        -- RG7 Contrôle des mouvements dont le fournisseur est l'une
        -- des sociétés absorbées
        --  ------------
        IF NOT dka_ctr_mvts(rec_ap_invoice_01.invoice_num,
                            rec_ap_invoice_01.accts_pay_code_combination_id,
                            substr(rec_ap_invoice_01.societe_absorbante, 4, 4),
                            rec_ap_invoice_01.invoice_id,
                            rec_ap_invoice_01.name,
                            rec_ap_invoice_01.invoice_amount,
                            rec_ap_invoice_01.creation_date,
                            rec_ap_invoice_01.source) THEN
          RAISE dka_erreur_e;
        END IF;
        -- -------------
        -- RG8 Contrôle compte fournisseur existant sur société absorbante
        --  ------------
        IF NOT dka_ctr_fournisseur(rec_ap_invoice_01.invoice_num,
                                   rec_ap_invoice_01.accts_pay_code_combination_id,
                                   substr(rec_ap_invoice_01.societe_absorbante,
                                          4,
                                          4),
                                   rec_ap_invoice_01.invoice_id,
                                   rec_ap_invoice_01.name,
                                   rec_ap_invoice_01.invoice_amount,
                                   rec_ap_invoice_01.creation_date,
                                   rec_ap_invoice_01.source) THEN
          RAISE dka_erreur_e;
        END IF;
      
      END IF;
    
      vn_old_org_id      := rec_ap_invoice_01.org_id;
      vn_old_invoice_id  := rec_ap_invoice_01.invoice_id;
      vv_old_invoice_num := rec_ap_invoice_01.invoice_num;
    
    END LOOP; /* Rec_Ap_Invoice_01 IN Cur_Ap_Invoice_01 */
  
    dka_tools_pkg.put_outdebug_message('****************************');
    dka_tools_pkg.put_outdebug_message('***Controle Site fournisseur manquant sur société absorbante***');
    dka_tools_pkg.put_outdebug_message('****************************');
  
    FOR rec_ap_site_01 IN cur_ap_site_01 LOOP
      SELECT hou.organization_id
        INTO vv_new_org_id
        FROM hr_operating_units hou
       WHERE hou.name = rec_ap_site_01.societe_absorbante;
    
      IF NOT dka_ctr_site_fournisseur(rec_ap_site_01.vendor_id,
                                      rec_ap_site_01.vendor_site_id,
                                      rec_ap_site_01.vendor_name,
                                      rec_ap_site_01.vendor_site_code,
                                      rec_ap_site_01.segment1,
                                      vv_new_org_id) THEN
        RAISE dka_erreur_e;
      END IF;
    
    END LOOP;
  
    IF vn_old_invoice_id <> -1 THEN
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'Invoice: ' ||
                                                 vv_old_invoice_num || '(Id: ' ||
                                                 vn_old_invoice_id || ')') THEN
        -- Probleme
        RAISE dka_erreur_e;
      END IF;
    END IF;
  
    -- Categories/sequences non crees
    /*   dka_tools_pkg.put_outdebug_message('****************************');
    dka_tools_pkg.put_outdebug_message('***CATEGORIE NON ASSIGNEE***');
    dka_tools_pkg.put_outdebug_message('****************************');
    
    FOR i IN 1 .. vn_nbre_rangs_category LOOP
      dka_tools_pkg.put_outdebug_message('Categorie ' ||
                                         vt_category_code(i));
    END LOOP;
    dka_tools_pkg.put_outdebug_message('**********************************');*/
  
    --JVI 12/05/2006
    --  dka_tools_pkg.put_outdebug_message('Mises à jour des affectations de catégorie à effectuer manuellement');
    /*
    
    -- Montants par type de facture
    Dka_Tools_Pkg.put_outdebug_message ('**********************************');
    Dka_Tools_Pkg.put_outdebug_message ('***MONTANTS PAR TYPE DE FACTURE***');
    Dka_Tools_Pkg.put_outdebug_message ('**********************************');
    
    FOR I IN 1..Vn_Nbre_Rangs
    LOOP
       Dka_Tools_Pkg.put_outdebug_message (VT_INVOICE_TYPE(I)||'-> Montant : '||VT_INVOICE_AMOUNT (I));
    END LOOP;
    
    */
  
    IF vb_erreur_ctr THEN
      -- Erreur lors d'un controle
      RAISE dka_erreur_ctr_e;
    END IF;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Ctr') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
    WHEN dka_erreur_ctr_e THEN
      dka_tools_pkg.put_outdebug_message('Erreur lors d''un controle');
      --     dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      COMMIT;
      pv_errbuf  := 'Erreur lors d''un controle';
      pn_retcode := 1;
    
    WHEN dka_erreur_e THEN
      --   Dka_Tools_Pkg.put_outdebug_message ('Annulation des modifications effectuees');
      COMMIT;
    
      pv_errbuf  := 'Erreur de controles';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur Main_Ctr');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
  END main_ctr;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Extract
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_extract(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         pv_debug   IN VARCHAR2) IS
    CURSOR cur_ap_invoice_01 IS
    
      SELECT /*+ ordered use_nl (Aida, Fdsc, Apsa, Pv, Ate, Pvsa, Dsl) */
      -- Factures
       dsl.return_value             societe_absorbante,
       dsl.param1_value             societe_absorbee,
       dsl.start_date               date_fusion,
       aia.invoice_num,
       aia.invoice_type_lookup_code,
       aia.invoice_date,
       aia.vendor_id,
       pv.vendor_name,
       aia.vendor_site_id
       -- RG4: Montant repris = valeur restante a regler
      ,
       round(nvl(SUM(apsa.amount_remaining), 0), 2) invoice_amount,
       aia.invoice_currency_code,
       aia.terms_id,
       aia.terms_date,
       ate.name terms_name,
       aia.description,
       aia.attribute_category,
       aia.attribute1,
       aia.attribute2,
       aia.attribute3,
       aia.attribute4,
       aia.attribute5
       --, Aia.Attribute6
      ,
       fnd_number.number_to_canonical(aia.invoice_amount) attribute6,
       aia.attribute7,
       aia.attribute8,
       aia.attribute9,
       aia.attribute10,
       aia.attribute11,
       aia.attribute12
       --, Aia.Attribute13
      ,
       (SELECT segment1
          FROM ap_invoice_lines_all aila, po_headers_all poh
         WHERE aila.invoice_id = aia.invoice_id
           AND aila.po_header_id IS NOT NULL
           AND aila.po_header_id = poh.po_header_id
           AND rownum = 1) attribute13,
       aia.attribute14,
       aia.attribute15,
       REPLACE(aia.global_attribute_category, 'APXINWKB', 'APXIISIM') new_glob_attribute_category,
       aia.global_attribute1,
       aia.global_attribute2,
       aia.global_attribute3,
       aia.global_attribute4,
       aia.global_attribute5,
       aia.global_attribute6,
       aia.global_attribute7,
       aia.global_attribute8,
       aia.global_attribute9,
       aia.global_attribute10,
       aia.global_attribute11,
       aia.global_attribute12,
       aia.global_attribute13,
       aia.global_attribute14,
       aia.global_attribute15,
       aia.global_attribute16,
       aia.global_attribute17,
       aia.global_attribute18,
       aia.global_attribute19,
       aia.global_attribute20,
       aia.payment_cross_rate_type,
       aia.payment_cross_rate_date,
       aia.payment_cross_rate,
       aia.payment_currency_code,
       aia.doc_category_code,
       aia.source,
       aia.payment_method_lookup_code,
       aia.pay_group_lookup_code,
       aia.invoice_id
       -- RG16: On inverse le type piece pour le societe absorbee
      ,
       decode(aia.invoice_type_lookup_code, 'CREDIT', 'STANDARD', 'CREDIT') type_inv_soc_abs,
       aia.accts_pay_code_combination_id,
       aia.org_id,
       aia.doc_sequence_id,
       aia.payment_method_code,
       pv.payment_priority,
       aia.external_bank_account_id,
       aia.remit_to_supplier_id,
       aia.remit_to_supplier_name,
       aia.remit_to_supplier_site,
       aia.remit_to_supplier_site_id
        FROM dka_stransco_headers        dsh,
             dka_stransco_lines          dsl,
             ap_invoices_all             aia,
             ap_payment_schedules_all    apsa,
             fnd_doc_sequence_categories fdsc,
             ap_terms                    ate,
             po_vendors                  pv,
             hr_operating_units          hou
       WHERE dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsl.set_id = dsh.set_id
         AND dsl.enable = 'Y'
            -- RG1: Type de la facture
         AND aia.invoice_type_lookup_code IN
             ('STANDARD', 'CREDIT', 'EXPENSE REPORT', 'DEBIT')
         AND fdsc.application_id = 200
            -- RG3: Mouvement doit appartenir a la societe absorbee
         AND fdsc.code = aia.doc_category_code
            --AND   Fdsc.Name LIKE (substr(Dsl.Param1_Value,4,4)||'%')
         AND hou.name = dsl.param1_value
         AND aia.org_id = hou.organization_id
         AND apsa.invoice_id = aia.invoice_id
         AND ate.term_id = aia.terms_id
         AND pv.vendor_id = aia.vendor_id
            -- RG1: Ensemble des lignes de la facture postees
         AND NOT EXISTS
       (SELECT 'x'
                FROM ap_invoice_distributions_all aida
               WHERE aida.invoice_id = aia.invoice_id
                 AND nvl(aida.accrual_posted_flag, 'N') <> 'Y')
       GROUP BY dsl.return_value,
                dsl.param1_value,
                dsl.start_date,
                aia.invoice_num,
                aia.invoice_type_lookup_code,
                aia.invoice_date,
                aia.vendor_id,
                pv.vendor_name,
                aia.vendor_site_id,
                aia.invoice_currency_code,
                aia.terms_id,
                aia.terms_date,
                ate.name,
                aia.description,
                aia.attribute_category,
                aia.attribute1,
                aia.attribute2,
                aia.attribute3,
                aia.attribute4,
                aia.attribute5,
                fnd_number.number_to_canonical(aia.invoice_amount),
                aia.attribute7,
                aia.attribute8,
                aia.attribute9,
                aia.attribute10,
                aia.attribute11,
                aia.attribute12,
                aia.attribute13,
                aia.attribute14,
                aia.attribute15,
                aia.global_attribute_category,
                aia.global_attribute1,
                aia.global_attribute2,
                aia.global_attribute3,
                aia.global_attribute4,
                aia.global_attribute5,
                aia.global_attribute6,
                aia.global_attribute7,
                aia.global_attribute8,
                aia.global_attribute9,
                aia.global_attribute10,
                aia.global_attribute11,
                aia.global_attribute12,
                aia.global_attribute13,
                aia.global_attribute14,
                aia.global_attribute15,
                aia.global_attribute16,
                aia.global_attribute17,
                aia.global_attribute18,
                aia.global_attribute19,
                aia.global_attribute20,
                aia.payment_cross_rate_type,
                aia.payment_cross_rate_date,
                aia.payment_cross_rate,
                aia.payment_currency_code,
                aia.doc_category_code,
                aia.source,
                aia.payment_method_lookup_code,
                dsl.param2_value,
                aia.pay_group_lookup_code,
                aia.invoice_id,
                aia.accts_pay_code_combination_id,
                aia.org_id,
                aia.doc_sequence_id,
                aia.payment_method_code,
                pv.payment_priority,
                aia.external_bank_account_id,
                aia.remit_to_supplier_id,
                aia.remit_to_supplier_name,
                aia.remit_to_supplier_site,
                aia.remit_to_supplier_site_id
      -- RG1: Champ Amount_Remaining <> 0
      HAVING nvl(SUM(apsa.amount_remaining), 0) <> 0
      UNION ALL
      -- Acomptes
      SELECT /*+ ordered use_nl (Aida, Fdsc, Aipa, Apsa, Pv, Ate, Pvsa, Dsl) */
       dsl.return_value             societe_absorbante,
       dsl.param1_value             societe_absorbee,
       dsl.start_date               date_fusion,
       aia.invoice_num,
       aia.invoice_type_lookup_code,
       aia.invoice_date,
       aia.vendor_id,
       pv.vendor_name,
       aia.vendor_site_id
       -- RG4: Montant repris = valeur restante a regler
      ,
       ap_invoices_utility_pkg.get_prepay_amount_remaining(aia.invoice_id) invoice_amount,
       aia.invoice_currency_code,
       aia.terms_id,
       aia.terms_date,
       ate.name terms_name,
       aia.description,
       aia.attribute_category,
       aia.attribute1,
       aia.attribute2,
       aia.attribute3,
       aia.attribute4,
       aia.attribute5
       --, Aia.Attribute6
      ,
       fnd_number.number_to_canonical(aia.invoice_amount) attribute6,
       aia.attribute7,
       aia.attribute8,
       aia.attribute9,
       aia.attribute10,
       aia.attribute11,
       aia.attribute12
       --, Aia.Attribute13
      ,
       (SELECT segment1
          FROM ap_invoice_lines_all aila, po_headers_all poh
         WHERE aila.invoice_id = aia.invoice_id
           AND aila.po_header_id IS NOT NULL
           AND aila.po_header_id = poh.po_header_id
           AND rownum = 1) attribute13,
       aia.attribute14,
       aia.attribute15,
       REPLACE(aia.global_attribute_category, 'APXINWKB', 'APXIISIM'),
       aia.global_attribute1,
       aia.global_attribute2,
       aia.global_attribute3,
       aia.global_attribute4,
       aia.global_attribute5,
       aia.global_attribute6,
       aia.global_attribute7,
       aia.global_attribute8,
       aia.global_attribute9,
       aia.global_attribute10,
       aia.global_attribute11,
       aia.global_attribute12,
       aia.global_attribute13,
       aia.global_attribute14,
       aia.global_attribute15,
       aia.global_attribute16,
       aia.global_attribute17,
       aia.global_attribute18,
       aia.global_attribute19,
       aia.global_attribute20,
       aia.payment_cross_rate_type,
       aia.payment_cross_rate_date,
       aia.payment_cross_rate,
       aia.payment_currency_code,
       aia.doc_category_code,
       aia.source
       --, Aia.Payment_Method_Lookup_Code
      ,
       'CHECK' payment_method_lookup_code,
       aia.pay_group_lookup_code,
       aia.invoice_id
       -- RG16: On inverse le type piece pour le societe absorbee
       -- Acompte -> Avoir
       -- Aia.invoice_type_lookup_code,
      ,
       'CREDIT' type_inv_soc_abs,
       aia.accts_pay_code_combination_id,
       aia.org_id,
       aia.doc_sequence_id,
       aia.payment_method_code,
       pv.payment_priority,
       aia.external_bank_account_id,
       aia.remit_to_supplier_id,
       aia.remit_to_supplier_name,
       aia.remit_to_supplier_site,
       aia.remit_to_supplier_site_id
        FROM dka_stransco_headers        dsh,
             dka_stransco_lines          dsl,
             ap_invoices_all             aia,
             fnd_doc_sequence_categories fdsc,
             ap_terms                    ate,
             po_vendors                  pv,
             hr_operating_units          hou
       WHERE dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsl.set_id = dsh.set_id
         AND dsl.enable = 'Y'
            -- RG2: Type de la facture
         AND aia.invoice_type_lookup_code = 'PREPAYMENT'
            -- RG2: Amount_Paid <> Invoice_Amount
         AND nvl(aia.invoice_amount, 0) = nvl(aia.amount_paid, 0)
         AND fdsc.application_id = 200
         AND fdsc.code = aia.doc_category_code
            -- RG3: Mouvement doit appartenir a la societe absorbee
            --AND   Fdsc.Name LIKE (substr(Dsl.Param1_Value,4,4)||'%')
         AND hou.name = dsl.param1_value
         AND aia.org_id = hou.organization_id
         AND ate.term_id = aia.terms_id
         AND pv.vendor_id = aia.vendor_id
            -- RG2: Ensemble des lignes de la facture postees
         AND NOT EXISTS
       (SELECT 'x'
                FROM ap_invoice_distributions_all aida
               WHERE aida.invoice_id = aia.invoice_id
                 AND nvl(aida.accrual_posted_flag, 'N') <> 'Y')
       GROUP BY dsl.return_value,
                dsl.param1_value,
                dsl.start_date,
                aia.invoice_num,
                aia.invoice_type_lookup_code,
                aia.invoice_date,
                aia.vendor_id,
                pv.vendor_name,
                aia.vendor_site_id,
                ap_invoices_utility_pkg.get_prepay_amount_remaining(aia.invoice_id),
                aia.invoice_currency_code,
                aia.terms_id,
                aia.terms_date,
                ate.name,
                aia.description,
                aia.attribute_category,
                aia.attribute1,
                aia.attribute2,
                aia.attribute3,
                aia.attribute4,
                aia.attribute5,
                fnd_number.number_to_canonical(aia.invoice_amount),
                aia.attribute7,
                aia.attribute8,
                aia.attribute9,
                aia.attribute10,
                aia.attribute11,
                aia.attribute12,
                aia.attribute13,
                aia.attribute14,
                aia.attribute15,
                aia.global_attribute_category,
                aia.global_attribute1,
                aia.global_attribute2,
                aia.global_attribute3,
                aia.global_attribute4,
                aia.global_attribute5,
                aia.global_attribute6,
                aia.global_attribute7,
                aia.global_attribute8,
                aia.global_attribute9,
                aia.global_attribute10,
                aia.global_attribute11,
                aia.global_attribute12,
                aia.global_attribute13,
                aia.global_attribute14,
                aia.global_attribute15,
                aia.global_attribute16,
                aia.global_attribute17,
                aia.global_attribute18,
                aia.global_attribute19,
                aia.global_attribute20,
                aia.payment_cross_rate_type,
                aia.payment_cross_rate_date,
                aia.payment_cross_rate,
                aia.payment_currency_code,
                aia.doc_category_code,
                aia.source,
                aia.payment_method_lookup_code,
                dsl.param2_value,
                aia.pay_group_lookup_code,
                aia.invoice_id,
                aia.accts_pay_code_combination_id,
                aia.org_id,
                aia.doc_sequence_id,
                aia.payment_method_code,
                pv.payment_priority,
                aia.external_bank_account_id,
                aia.remit_to_supplier_id,
                aia.remit_to_supplier_name,
                aia.remit_to_supplier_site,
                aia.remit_to_supplier_site_id
      -- Accompte non totalement rapproche et disponible
      HAVING ap_invoices_utility_pkg.get_prepay_amount_remaining(aia.invoice_id) <> 0;
  
    rec_ap_invoice_01 cur_ap_invoice_01%ROWTYPE;
  
    vn_retour        NUMBER;
    vv_erreur_oracle VARCHAR2(80);
  
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
    -- Nouveau Accounts_Pay_Ccid
    vn_new_pay_ccid gl_code_combinations.code_combination_id%TYPE;
  
    -- Id de la facture pour la societe absorbee
    -- Id de la facture pour la societe absorbante
    vn_invoice_id_absorbee   ap_invoices_all.invoice_id%TYPE;
    vn_invoice_id_absorbante ap_invoices_all.invoice_id%TYPE;
  
    -- Valeurs genriques des deux comptes generiques pour les
    -- lignes de distribution de type ITEM
    vv_cpt_local_generique VARCHAR2(30);
    vv_cpt_grpe_generique  VARCHAR2(30);
  
    -- Erreur lors d'un controle
    dka_erreur_ctr_e EXCEPTION;
  
    -- Id de la sequence destination (societe absorbante)
    vn_doc_seq_id fnd_document_sequences.doc_sequence_id%TYPE;
  
    vc_doc_category_code ap_invoices_all.doc_category_code%TYPE;
    -- Classe de règlements
    vc_pay_group_lookup_code ap_invoices_all.pay_group_lookup_code%TYPE;
  
    -- Type de la facture
    vv_new_invoice_type ap_invoices_all.invoice_type_lookup_code%TYPE;
    -- Org id
    vv_new_org_id                ap_invoices_all.org_id%TYPE;
    vn_vendor_site_id            ap_supplier_sites_all.vendor_site_id%TYPE;
    vn_party_site_id             ap_supplier_sites_all.party_site_id%TYPE;
    vn_external_bank_account_id  iby_ext_bank_accounts.ext_bank_account_id%TYPE;
    vn_param                     NUMBER := 0;
    vv_refactor_supplier         ap_suppliers.vendor_name%TYPE;
    vv_refactor_supplier_id      ap_suppliers.vendor_id%TYPE;
    vv_refactor_supplier_site    ap_supplier_sites_all.vendor_site_code%TYPE;
    vv_refactor_supplier_site_id ap_supplier_sites_all.vendor_site_id%TYPE;
  
    dka_erreur_oracle VARCHAR2(200);
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Extract') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    -- Vérifie si plusieurs valeurs de transco sont actives
    vn_param := dka_verif_param;
    IF vn_param > 1 THEN
      dka_tools_pkg.put_outdebug_message('Plusieurs valeurs actives dans la table FUSION_SOCIETE_VERS_SOCIETE');
      RAISE dka_erreur_ctr_e;
    END IF;
    IF vn_param = 0 THEN
      dka_tools_pkg.put_outdebug_message('Aucune valeur active dans la table FUSION_SOCIETE_VERS_SOCIETE');
      RAISE dka_erreur_ctr_e;
    END IF;
  
    -- Suppression des donnees du traitement precedent
    IF NOT dka_delete_old_values_f THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    -- Recherche des comptes generiques pour les lignes de type ITEM
    IF NOT
        dka_cptes_generiques_f(pv_cpte_local  => vv_cpt_local_generique,
                               pv_cpte_groupe => vv_cpt_grpe_generique) THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    FOR rec_ap_invoice_01 IN cur_ap_invoice_01 LOOP
      IF NOT
          dka_print_debug_f(pv_position_debug => +1,
                            pv_marque         => '>',
                            pv_msg            => 'Invoice: ' ||
                                                 rec_ap_invoice_01.invoice_num ||
                                                 '(Id: ' ||
                                                 rec_ap_invoice_01.invoice_id || ')') THEN
        -- Probleme
        RAISE dka_erreur_e;
      END IF;
    
      -- 3. Recherche du nouveau ACCOUNT_PAY_CCID ( Societe absorbante )
      vn_new_pay_ccid := dka_new_pay_ccid_f(pn_ccid_orig           => rec_ap_invoice_01.accts_pay_code_combination_id,
                                            pv_societe_absorbante  => substr(rec_ap_invoice_01.societe_absorbante,
                                                                             4,
                                                                             4),
                                            pv_invoice_num         => rec_ap_invoice_01.invoice_num,
                                            pv_invoice_type        => rec_ap_invoice_01.invoice_type_lookup_code,
                                            pv_cpt_local_generique => vv_cpt_local_generique,
                                            pv_cpt_grpe_generique  => vv_cpt_grpe_generique,
                                            pn_type_ccid           => 2);
    
      IF vn_new_pay_ccid = -1 THEN
        -- Probleme
        dka_tools_pkg.put_outdebug_message('Erreur recherche nouveau ACCOUNT_PAY_CCID pour la facture ' ||
                                           rec_ap_invoice_01.invoice_num);
      END IF;
    
      -- Insertion de l'entete de facture pour la societe absorbante
      SELECT ap_invoices_interface_s.nextval
        INTO vn_invoice_id_absorbante
        FROM dual;
    
      -- Modif EMA du 18/11/2005 : On modifie pour les acomptes la classe de règlements
      -- ( 'SocAbsorbante''CentreDeGestion''FUSION')
      IF rec_ap_invoice_01.invoice_type_lookup_code = 'PREPAYMENT' THEN
        vc_pay_group_lookup_code := REPLACE(substr(rec_ap_invoice_01.pay_group_lookup_code,
                                                   1,
                                                   4),
                                            rec_ap_invoice_01.societe_absorbee,
                                            rec_ap_invoice_01.societe_absorbante) ||
                                    substr(rec_ap_invoice_01.pay_group_lookup_code,
                                           5,
                                           3) || 'FUSION';
      ELSE
        vc_pay_group_lookup_code := REPLACE(substr(rec_ap_invoice_01.pay_group_lookup_code,
                                                   1,
                                                   4),
                                            rec_ap_invoice_01.societe_absorbee,
                                            rec_ap_invoice_01.societe_absorbante) ||
                                    substr(rec_ap_invoice_01.pay_group_lookup_code,
                                           5);
      END IF;
    
      -- Détermination de l'org id de la société absorbante
      SELECT hou.organization_id
        INTO vv_new_org_id
        FROM hr_operating_units hou
       WHERE hou.name = rec_ap_invoice_01.societe_absorbante;
    
      BEGIN
        --vendor site_id de la société absorbante
        SELECT vendor_site_id, party_site_id
          INTO vn_vendor_site_id, vn_party_site_id
          FROM ap_supplier_sites_all assa
         WHERE org_id = vv_new_org_id
           AND vendor_id = rec_ap_invoice_01.vendor_id
           and assa.PAY_SITE_FLAG = 'Y'
           and assa.INACTIVE_DATE is null
           AND location_id IN
               (SELECT location_id
                  FROM ap_supplier_sites_all
                 WHERE vendor_site_id = rec_ap_invoice_01.vendor_site_id);
      EXCEPTION
        WHEN no_data_found THEN
          vn_vendor_site_id := NULL;
        WHEN OTHERS THEN
          dka_erreur_oracle := substr(SQLERRM, 1, 80);
          dka_tools_pkg.put_debug_message('Erreur DKA_VERIF_PARAM ');
          dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      END;
    
      -- Récupération de l'external bank account id
      BEGIN
        SELECT ipi.instrument_id
          INTO vn_external_bank_account_id
          FROM hz_party_sites          hps,
               iby_external_payees_all iep,
               iby_pmt_instr_uses_all  ipi
         WHERE iep.payee_party_id = hps.party_id
           AND hps.party_site_id = nvl(vn_party_site_id, 0)
           AND iep.ext_payee_id = ipi.ext_pmt_party_id
           AND iep.supplier_site_id = vn_vendor_site_id
           AND order_of_preference = 1;
      EXCEPTION
        WHEN no_data_found THEN
          vn_external_bank_account_id := NULL;
        WHEN too_many_rows THEN
          vn_external_bank_account_id := NULL;
        WHEN OTHERS THEN
          dka_erreur_oracle := substr(SQLERRM, 1, 80);
          dka_tools_pkg.put_debug_message('Erreur DKA_VERIF_PARAM ');
          dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      END;
      -- Détermination de Vc_Doc_category_code
      IF rec_ap_invoice_01.source = 'SCAN_XGS' THEN
        vc_doc_category_code := REPLACE(substr(rec_ap_invoice_01.doc_category_code,
                                               1,
                                               4),
                                        substr(rec_ap_invoice_01.societe_absorbee,
                                               4,
                                               4),
                                        substr(rec_ap_invoice_01.societe_absorbante,
                                               4,
                                               4)) ||
                                substr(rec_ap_invoice_01.doc_category_code,
                                       5);
      ELSE
        vc_doc_category_code := rec_ap_invoice_01.doc_category_code;
      END IF;
    
      -- Récupération du refactor
      BEGIN
        SELECT hzp_rmt.party_name,
               aps.vendor_id,
               apsite_rmt.vendor_site_code,
               apsite_rmt.vendor_site_id
          INTO vv_refactor_supplier,
               vv_refactor_supplier_id,
               vv_refactor_supplier_site,
               vv_refactor_supplier_site_id
          FROM iby_ext_payee_relationships extrelationshipseo,
               hz_parties                  hzp_rmt,
               ap_supplier_sites_all       apsite_rmt,
               ap_suppliers                aps
         WHERE extrelationshipseo.supplier_site_id = vn_vendor_site_id
           AND extrelationshipseo.remit_party_id = hzp_rmt.party_id
           AND extrelationshipseo.remit_supplier_site_id =
               apsite_rmt.vendor_site_id
           AND aps.party_id = hzp_rmt.party_id
           AND rec_ap_invoice_01.invoice_date BETWEEN
               extrelationshipseo.from_date AND
               nvl(extrelationshipseo.to_date, SYSDATE);
      EXCEPTION
        WHEN no_data_found THEN
          vv_refactor_supplier         := NULL;
          vv_refactor_supplier_id      := NULL;
          vv_refactor_supplier_site    := NULL;
          vv_refactor_supplier_site_id := NULL;
        WHEN too_many_rows THEN
          vv_refactor_supplier         := NULL;
          vv_refactor_supplier_id      := NULL;
          vv_refactor_supplier_site    := NULL;
          vv_refactor_supplier_site_id := NULL;
        WHEN OTHERS THEN
          dka_erreur_oracle := substr(SQLERRM, 1, 80);
          dka_tools_pkg.put_debug_message('Erreur Refactor ');
          dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      END;
    
      IF NOT
          dka_ins_inv_interface_f(pn_invoice_id => vn_invoice_id_absorbante
                                  -- RG5: Numero de facture : societe absorbee + facture d'origine
                                 ,
                                  pv_invoice_num => substr(rec_ap_invoice_01.societe_absorbee || '_' ||
                                                           rec_ap_invoice_01.invoice_num,
                                                           1,
                                                           50)
                                  -- Si acompte -> Facture standard
                                  -- type de la facture mise a jour dans Main_Post_Fusion
                                 ,
                                  pv_invoice_type_lookup_code => rec_ap_invoice_01.invoice_type_lookup_code
                                  --                 REPLACE (Rec_Ap_Invoice_01.Invoice_Type_Lookup_Code,'PREPAYMENT','STANDARD')
                                 ,
                                  pd_invoice_date     => rec_ap_invoice_01.invoice_date,
                                  pn_vendor_id        => rec_ap_invoice_01.vendor_id,
                                  pv_vendor_name      => NULL,
                                  pn_vendor_site_id   => vn_vendor_site_id,
                                  pv_vendor_site_code => NULL
                                  -- RG7: Montant restant a payer / Montant restant a rapprocher pour la societe absorbante
                                 ,
                                  pn_invoice_amount             => rec_ap_invoice_01.invoice_amount,
                                  pv_invoice_currency_code      => rec_ap_invoice_01.invoice_currency_code,
                                  pn_terms_id                   => NULL,
                                  pn_terms_date                 => rec_ap_invoice_01.terms_date,
                                  pv_terms_name                 => rec_ap_invoice_01.terms_name,
                                  pv_description                => rec_ap_invoice_01.description,
                                  pv_attribute_category         => 'FUSION',
                                  pv_attribute1                 => rec_ap_invoice_01.attribute1,
                                  pv_attribute2                 => rec_ap_invoice_01.attribute2,
                                  pv_attribute3                 => rec_ap_invoice_01.attribute3,
                                  pv_attribute4                 => rec_ap_invoice_01.attribute4,
                                  pv_attribute5                 => rec_ap_invoice_01.attribute5,
                                  pv_attribute6                 => rec_ap_invoice_01.attribute6,
                                  pv_attribute7                 => rec_ap_invoice_01.attribute7,
                                  pv_attribute8                 => rec_ap_invoice_01.attribute8,
                                  pv_attribute9                 => rec_ap_invoice_01.attribute9,
                                  pv_attribute10                => rec_ap_invoice_01.attribute10,
                                  pv_attribute11                => rec_ap_invoice_01.attribute11,
                                  pv_attribute12                => rec_ap_invoice_01.attribute12,
                                  pv_attribute13                => rec_ap_invoice_01.attribute13,
                                  pv_attribute14                => rec_ap_invoice_01.attribute14,
                                  pv_attribute15                => rec_ap_invoice_01.attribute15,
                                  pv_global_attribute_category  => NULL,
                                  pv_global_attribute1          => NULL,
                                  pv_global_attribute2          => NULL,
                                  pv_global_attribute3          => NULL,
                                  pv_global_attribute4          => NULL,
                                  pv_global_attribute5          => NULL,
                                  pv_global_attribute6          => NULL,
                                  pv_global_attribute7          => NULL,
                                  pv_global_attribute8          => NULL,
                                  pv_global_attribute9          => NULL,
                                  pv_global_attribute10         => NULL,
                                  pv_global_attribute11         => NULL,
                                  pv_global_attribute12         => NULL,
                                  pv_global_attribute13         => NULL,
                                  pv_global_attribute14         => NULL,
                                  pv_global_attribute15         => NULL,
                                  pv_global_attribute16         => NULL,
                                  pv_global_attribute17         => NULL,
                                  pv_global_attribute18         => NULL,
                                  pv_global_attribute19         => NULL,
                                  pv_global_attribute20         => NULL,
                                  pv_status                     => NULL,
                                  pv_source                     => 'FUSION',
                                  pv_payment_cross_rate_type    => NULL,
                                  pv_payment_cross_rate_date    => NULL,
                                  pn_payment_cross_rate         => NULL,
                                  pv_payment_currency_code      => NULL,
                                  pv_doc_category_code          => vc_doc_category_code,
                                  pv_payment_method_lookup_code => NULL,
                                  pv_pay_group_lookup_code      => rec_ap_invoice_01.pay_group_lookup_code,
                                  pn_account_pay_ccid           => vn_new_pay_ccid,
                                  pn_org_id                     => vv_new_org_id,
                                  pd_gl_date                    => trunc(rec_ap_invoice_01.date_fusion),
                                  pv_operating_unit             => rec_ap_invoice_01.societe_absorbante,
                                  pv_payment_method_code        => rec_ap_invoice_01.payment_method_code,
                                  pn_payment_priority           => rec_ap_invoice_01.payment_priority,
                                  pn_external_bank_account_id   => vn_external_bank_account_id,
                                  --pv_remit_to_supplier_name     => rec_ap_invoice_01.remit_to_supplier_name,
                                  pv_remit_to_supplier_name => vv_refactor_supplier,
                                  --pn_remit_to_supplier_id       => rec_ap_invoice_01.remit_to_supplier_id,
                                  pn_remit_to_supplier_id => vv_refactor_supplier_id,
                                  --pv_remit_to_supplier_site     => rec_ap_invoice_01.remit_to_supplier_site,
                                  pv_remit_to_supplier_site => vv_refactor_supplier_site,
                                  --pn_remit_to_supplier_site_id  => rec_ap_invoice_01.remit_to_supplier_site_id,
                                  pn_remit_to_supplier_site_id => vv_refactor_supplier_site_id,
                                  pv_remit_to_supplier_num     => NULL) THEN
        -- Probleme
        RAISE dka_erreur_e;
      END IF;
    
      -- Memorisation de la concordance ancienne <> nouveau numero de facture
      -- pour la reaffectation des blocages post-fusion
      IF NOT dka_ins_fusion_ap_invoice_f(pv_invoice_num_from => rec_ap_invoice_01.invoice_num,
                                         pv_invoice_num_to   => substr(rec_ap_invoice_01.societe_absorbee || '_' ||
                                                                       rec_ap_invoice_01.invoice_num,
                                                                       1,
                                                                       50),
                                         pn_org_id_from      => rec_ap_invoice_01.org_id,
                                         pn_org_id_to        => vv_new_org_id,
                                         pn_vendor_id        => rec_ap_invoice_01.vendor_id,
                                         pv_societe_absorbee => 'N') THEN
        -- Probleme
        RAISE dka_erreur_e;
      END IF;
    
      -- Insertion de l'entete de facture pour la societe absorbee
      SELECT ap_invoices_interface_s.nextval
        INTO vn_invoice_id_absorbee
        FROM dual;
    
      -- Pour la société absorbée,
      -- si le champ d'origine est PREPAYMENT -> CREDIT
      -- si le champ d'origine est STANDARD -> CREDIT
      -- si le champ d'origine est CREDIT -> STANDARD
      IF rec_ap_invoice_01.invoice_type_lookup_code = 'PREPAYMENT' THEN
        vv_new_invoice_type := 'CREDIT';
      END IF;
      IF rec_ap_invoice_01.invoice_type_lookup_code = 'STANDARD' OR
         rec_ap_invoice_01.invoice_type_lookup_code = 'DEBIT' OR
         rec_ap_invoice_01.invoice_type_lookup_code = 'EXPENSE REPORT' THEN
        vv_new_invoice_type := 'CREDIT';
      END IF;
      IF rec_ap_invoice_01.invoice_type_lookup_code = 'CREDIT' THEN
        vv_new_invoice_type := 'STANDARD';
      END IF;
    
      -- Recherche du nouveau ACCOUNT_PAY_CCID ( Societe absorbee )
      vn_new_pay_ccid := dka_new_pay_ccid_f(pn_ccid_orig           => rec_ap_invoice_01.accts_pay_code_combination_id,
                                            pv_societe_absorbante  => substr(rec_ap_invoice_01.societe_absorbante,
                                                                             4,
                                                                             4),
                                            pv_invoice_num         => rec_ap_invoice_01.invoice_num,
                                            pv_invoice_type        => rec_ap_invoice_01.invoice_type_lookup_code,
                                            pv_cpt_local_generique => vv_cpt_local_generique,
                                            pv_cpt_grpe_generique  => vv_cpt_grpe_generique,
                                            pn_type_ccid           => 1);
    
      IF vn_new_pay_ccid = -1 THEN
        -- Probleme
        dka_tools_pkg.put_outdebug_message('Erreur recherche nouveau ACCOUNT_PAY_CCID pour la facture ' ||
                                           rec_ap_invoice_01.invoice_num);
      END IF;
    
      -- Détermination de Vc_Doc_category_code
      IF rec_ap_invoice_01.source != 'SCAN_XGS' THEN
        IF rec_ap_invoice_01.doc_category_code IN
           ('PREPAY INV', 'STD INV', 'EXP REP INV') THEN
          vc_doc_category_code := 'CRM INV';
        ELSIF rec_ap_invoice_01.doc_category_code IN ('CRM INV', 'DBM INV') THEN
          vc_doc_category_code := 'STD INV';
        ELSE
          vc_doc_category_code := rec_ap_invoice_01.doc_category_code;
        END IF;
      ELSE
        vc_doc_category_code := rec_ap_invoice_01.doc_category_code;
      END IF;
    
      -- Récupération du refactor
      BEGIN
        SELECT hzp_rmt.party_name,
               aps.vendor_id,
               apsite_rmt.vendor_site_code,
               apsite_rmt.vendor_site_id
          INTO vv_refactor_supplier,
               vv_refactor_supplier_id,
               vv_refactor_supplier_site,
               vv_refactor_supplier_site_id
          FROM iby_ext_payee_relationships extrelationshipseo,
               hz_parties                  hzp_rmt,
               ap_supplier_sites_all       apsite_rmt,
               ap_suppliers                aps
         WHERE extrelationshipseo.supplier_site_id =
               rec_ap_invoice_01.vendor_site_id
           AND extrelationshipseo.remit_party_id = hzp_rmt.party_id
           AND extrelationshipseo.remit_supplier_site_id =
               apsite_rmt.vendor_site_id
           AND aps.party_id = hzp_rmt.party_id
           AND rec_ap_invoice_01.invoice_date BETWEEN
               extrelationshipseo.from_date AND
               nvl(extrelationshipseo.to_date, SYSDATE);
      EXCEPTION
        WHEN no_data_found THEN
          vv_refactor_supplier         := NULL;
          vv_refactor_supplier_id      := NULL;
          vv_refactor_supplier_site    := NULL;
          vv_refactor_supplier_site_id := NULL;
        WHEN too_many_rows THEN
          vv_refactor_supplier         := NULL;
          vv_refactor_supplier_id      := NULL;
          vv_refactor_supplier_site    := NULL;
          vv_refactor_supplier_site_id := NULL;
        WHEN OTHERS THEN
          dka_erreur_oracle := substr(SQLERRM, 1, 80);
          dka_tools_pkg.put_debug_message('Erreur Refactor ');
          dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      END;
    
      IF NOT
          dka_ins_inv_interface_f(pn_invoice_id => vn_invoice_id_absorbee
                                  -- RG5: Numero de facture : societe absorbante + facture d'origine
                                 ,
                                  pv_invoice_num => substr(rec_ap_invoice_01.societe_absorbante || '_' ||
                                                           rec_ap_invoice_01.invoice_num,
                                                           1,
                                                           50)
                                  --                 , PV_INVOICE_TYPE_LOOKUP_CODE => REPLACE(Rec_Ap_Invoice_01.Type_Inv_Soc_Abs,'PREPAYMENT','STANDARD')
                                 ,
                                  pv_invoice_type_lookup_code => vv_new_invoice_type,
                                  pd_invoice_date             => rec_ap_invoice_01.invoice_date,
                                  pn_vendor_id                => rec_ap_invoice_01.vendor_id,
                                  pv_vendor_name              => NULL,
                                  pn_vendor_site_id           => rec_ap_invoice_01.vendor_site_id,
                                  pv_vendor_site_code         => NULL
                                  -- RG7: Inverse de Montant restant a payer / Montant restant a rapprocher pour la societe absorbee
                                 ,
                                  pn_invoice_amount            => - (rec_ap_invoice_01.invoice_amount),
                                  pv_invoice_currency_code     => rec_ap_invoice_01.invoice_currency_code,
                                  pn_terms_id                  => NULL,
                                  pn_terms_date                => rec_ap_invoice_01.terms_date,
                                  pv_terms_name                => rec_ap_invoice_01.terms_name,
                                  pv_description               => rec_ap_invoice_01.description,
                                  pv_attribute_category        => 'FUSION',
                                  pv_attribute1                => rec_ap_invoice_01.attribute1,
                                  pv_attribute2                => rec_ap_invoice_01.attribute2,
                                  pv_attribute3                => rec_ap_invoice_01.attribute3,
                                  pv_attribute4                => rec_ap_invoice_01.attribute4,
                                  pv_attribute5                => rec_ap_invoice_01.attribute5,
                                  pv_attribute6                => rec_ap_invoice_01.attribute6,
                                  pv_attribute7                => rec_ap_invoice_01.attribute7,
                                  pv_attribute8                => rec_ap_invoice_01.attribute8,
                                  pv_attribute9                => rec_ap_invoice_01.attribute9,
                                  pv_attribute10               => rec_ap_invoice_01.attribute10,
                                  pv_attribute11               => rec_ap_invoice_01.attribute11,
                                  pv_attribute12               => rec_ap_invoice_01.attribute12,
                                  pv_attribute13               => rec_ap_invoice_01.attribute13,
                                  pv_attribute14               => rec_ap_invoice_01.attribute14,
                                  pv_attribute15               => rec_ap_invoice_01.attribute15,
                                  pv_global_attribute_category => NULL,
                                  pv_global_attribute1         => NULL,
                                  pv_global_attribute2         => NULL,
                                  pv_global_attribute3         => NULL,
                                  pv_global_attribute4         => NULL,
                                  pv_global_attribute5         => NULL,
                                  pv_global_attribute6         => NULL,
                                  pv_global_attribute7         => NULL,
                                  pv_global_attribute8         => NULL,
                                  pv_global_attribute9         => NULL,
                                  pv_global_attribute10        => NULL,
                                  pv_global_attribute11        => NULL,
                                  pv_global_attribute12        => NULL,
                                  pv_global_attribute13        => NULL,
                                  pv_global_attribute14        => NULL,
                                  pv_global_attribute15        => NULL,
                                  pv_global_attribute16        => NULL,
                                  pv_global_attribute17        => NULL,
                                  pv_global_attribute18        => NULL,
                                  pv_global_attribute19        => NULL,
                                  pv_global_attribute20        => NULL,
                                  pv_status                    => NULL,
                                  pv_source                    => 'FUSION',
                                  pv_payment_cross_rate_type   => NULL,
                                  pv_payment_cross_rate_date   => NULL,
                                  pn_payment_cross_rate        => NULL,
                                  pv_payment_currency_code     => NULL
                                  --, PV_DOC_CATEGORY_CODE  => Rec_Ap_Invoice_01.Doc_Category_Code
                                 ,
                                  pv_doc_category_code          => vc_doc_category_code,
                                  pv_payment_method_lookup_code => NULL,
                                  pv_pay_group_lookup_code      => rec_ap_invoice_01.pay_group_lookup_code,
                                  pn_account_pay_ccid           => vn_new_pay_ccid,
                                  pn_org_id                     => rec_ap_invoice_01.org_id,
                                  pd_gl_date                    => trunc(rec_ap_invoice_01.date_fusion),
                                  pv_operating_unit             => rec_ap_invoice_01.societe_absorbee,
                                  pv_payment_method_code        => rec_ap_invoice_01.payment_method_code,
                                  pn_payment_priority           => rec_ap_invoice_01.payment_priority,
                                  pn_external_bank_account_id   => rec_ap_invoice_01.external_bank_account_id,
                                  --pv_remit_to_supplier_name     => rec_ap_invoice_01.remit_to_supplier_name,
                                  pv_remit_to_supplier_name => vv_refactor_supplier,
                                  --pn_remit_to_supplier_id       => rec_ap_invoice_01.remit_to_supplier_id,
                                  pn_remit_to_supplier_id => vv_refactor_supplier_id,
                                  --pv_remit_to_supplier_site     => rec_ap_invoice_01.remit_to_supplier_site,
                                  pv_remit_to_supplier_site => vv_refactor_supplier_site,
                                  --pn_remit_to_supplier_site_id  => rec_ap_invoice_01.remit_to_supplier_site_id,
                                  pn_remit_to_supplier_site_id => vv_refactor_supplier_site_id,
                                  pv_remit_to_supplier_num     => NULL) THEN
        -- Probleme
        RAISE dka_erreur_e;
      END IF;
    
      -- Insertion des lignes de destribution ( societe absorbante et absorbee )
      IF NOT
          dka_ap_invoice_lines_int_f(pn_invoice_id_orig           => rec_ap_invoice_01.invoice_id,
                                     pv_invoice_num_orig          => rec_ap_invoice_01.invoice_num,
                                     pv_societe_absorbee          => substr(rec_ap_invoice_01.societe_absorbee,
                                                                            4,
                                                                            4),
                                     pv_societe_absorbante        => substr(rec_ap_invoice_01.societe_absorbante,
                                                                            4,
                                                                            4),
                                     pn_new_invoice_id_absorbee   => vn_invoice_id_absorbee,
                                     pn_new_invoice_id_absorbante => vn_invoice_id_absorbante,
                                     pv_cpt_local_generique       => vv_cpt_local_generique,
                                     pv_cpt_grpe_generique        => vv_cpt_grpe_generique,
                                     pd_accounting_date           => trunc(rec_ap_invoice_01.date_fusion),
                                     pn_org_id_absorbee           => rec_ap_invoice_01.org_id,
                                     pn_org_id_absorbante         => vv_new_org_id) THEN
        -- Probleme
        RAISE dka_erreur_e;
      END IF;
    
      IF NOT
          dka_print_debug_f(pv_position_debug => -1,
                            pv_marque         => '<',
                            pv_msg            => 'Invoice: ' ||
                                                 rec_ap_invoice_01.invoice_num ||
                                                 '(Id: ' ||
                                                 rec_ap_invoice_01.invoice_id || ')') THEN
        -- Probleme
        RAISE dka_erreur_e;
      END IF;
    
    END LOOP;
  
    dka_tools_pkg.put_outdebug_message('**********************************');
    dka_tools_pkg.put_outdebug_message('Nbre total d''entetes de factures inserees: ' ||
                                       to_char(vn_nbre_entetes));
    dka_tools_pkg.put_outdebug_message('Nbre total de lignes de factures inserees: ' ||
                                       to_char(vn_nbre_lignes));
    dka_tools_pkg.put_outdebug_message('**********************************');
  
    IF vb_erreur_ctr THEN
      -- Erreur lors d'un controle
      RAISE dka_erreur_ctr_e;
    END IF;
  
    /*
       -- Maj des comptes bancaires
       IF NOT DKA_UPD_BANK_ACCOUNTS_F
       THEN
          -- Probleme
          RAISE DKA_Erreur_E;
       END IF;
    */
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Extract') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_ctr_e THEN
      dka_tools_pkg.put_outdebug_message('Erreur lors d''un controle');
      pv_errbuf  := 'Erreur lors d''un controle';
      pn_retcode := 1;
      COMMIT;
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur Main_Extract');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
  END main_extract;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Insert
  --  Description   : procédure principale de l'insertion dans les tables standard d'interface
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_insert(pv_errbuf  IN OUT VARCHAR2,
                        pn_retcode OUT NUMBER,
                        pv_debug   IN VARCHAR2) IS
  
    vv_step          VARCHAR2(30);
    vn_nbre_enr      NUMBER;
    vv_erreur_oracle VARCHAR2(80);
  
    dka_erreur_e EXCEPTION;
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Insert') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    vv_step := 'AP_INVOICES_INTERFACE';
    INSERT INTO ap_invoices_interface
      SELECT * FROM dka_fusion_ap_inv_int;
    vn_nbre_enr := SQL%ROWCOUNT;
    dka_tools_pkg.put_outdebug_message(vn_nbre_enr ||
                                       ' enregistrements inseres dans AP_INVOICES_INTERFACE');
  
    vv_step := 'AP_INVOICE_LINES_INTERFACE';
    INSERT INTO ap_invoice_lines_interface
      SELECT * FROM dka_fusion_ap_inv_lin_int;
    vn_nbre_enr := SQL%ROWCOUNT;
    dka_tools_pkg.put_outdebug_message(vn_nbre_enr ||
                                       ' enregistrements inseres dans AP_INVOICE_LINES_INTERFACE');
  
    IF NOT
        dka_print_debug_f(pv_position_debug => -1,
                          pv_marque         => '<',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Insert') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur Main_Insert - Step ' ||
                                         vv_step);
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des insertions effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
  END main_insert;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_REINIT_FFV_F
  --  Description   : Desactivation des valeurs reactivees lors du traitement et archivees
  --                  dans la table DKA_FUSION_AP_FFV  + Epuration de la table
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_reinit_ffv_f RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    CURSOR cur_fusion_ap_ffv_01 IS
      SELECT dfaf.flex_value_set_id,
             dfaf.flex_value,
             dfaf.end_date_active,
             dfaf.enabled_flag
        FROM dka_fusion_ap_ffv dfaf;
  
    rec_fusion_ap_ffv_01 cur_fusion_ap_ffv_01%ROWTYPE;
  
    vv_step VARCHAR2(30);
  
  BEGIN
    vv_step := 'UPDATE';
  
    FOR rec_fusion_ap_ffv_01 IN cur_fusion_ap_ffv_01 LOOP
      UPDATE fnd_flex_values ffv
         SET ffv.end_date_active = rec_fusion_ap_ffv_01.end_date_active,
             ffv.enabled_flag    = rec_fusion_ap_ffv_01.enabled_flag
       WHERE ffv.flex_value_set_id = rec_fusion_ap_ffv_01.flex_value_set_id
         AND ffv.flex_value = rec_fusion_ap_ffv_01.flex_value;
    END LOOP;
  
    vv_step := 'DELETE';
    DELETE dka_fusion_ap_ffv dfaf;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_REINIT_FFV_F - Step ' ||
                                         vv_step || ' ()');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_reinit_ffv_f;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_REINIT_CCID_F
  --  Description   : Desactivation des CCID reactivees lors du traitement et archivees
  --                  dans la table DKA_FUSION_AP_CCID + Epuratiion de la table
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_reinit_ccid_f RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    CURSOR cur_fusion_ap_ccid_01 IS
      SELECT dfac.ccid, dfac.end_date_active, dfac.enabled_flag
        FROM dka_fusion_ap_ccid dfac;
  
    rec_fusion_ap_ccid_01 cur_fusion_ap_ccid_01%ROWTYPE;
  
    vv_step VARCHAR2(30);
  
  BEGIN
    vv_step := 'UPDATE';
  
    FOR rec_fusion_ap_ccid_01 IN cur_fusion_ap_ccid_01 LOOP
      UPDATE gl_code_combinations gcc
         SET gcc.end_date_active = rec_fusion_ap_ccid_01.end_date_active,
             gcc.enabled_flag    = rec_fusion_ap_ccid_01.enabled_flag
       WHERE gcc.code_combination_id = rec_fusion_ap_ccid_01.ccid;
    END LOOP;
  
    vv_step := 'DELETE';
    DELETE dka_fusion_ap_ccid;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_REINIT_CCID_F - Step ' ||
                                         vv_step || ' ()');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_reinit_ccid_f;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_UPDATE_INV_DISTRIBUTIONS_F
  --  Description   : Mise à jour de la table Ap_Invoice_Distributions_All faisant le lien entre AP et PO.
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_update_inv_distributions_f RETURN BOOLEAN IS
  
    CURSOR cur_factures IS
      SELECT dfai.invoice_num_from, dfai.invoice_num_to, dfai.vendor_id
        FROM dka_fusion_ap_invoice dfai
       WHERE dfai.societe_absorbee = 'N';
  
    CURSOR cur_distributions(pn_invoice_id NUMBER) IS
      SELECT aida.po_distribution_id,
             aida.distribution_line_number,
             aida.amount,
             aida.description
        FROM ap_invoice_distributions_all aida
       WHERE aida.invoice_id = pn_invoice_id
         AND aida.po_distribution_id IS NOT NULL
       ORDER BY aida.distribution_line_number
         FOR UPDATE OF aida.po_distribution_id;
  
    CURSOR cur_new_distributions(pn_invoice_id  NUMBER,
                                 pn_amount      NUMBER,
                                 pv_description VARCHAR2) IS
      SELECT aida.po_distribution_id,
             aida.distribution_line_number,
             aida.amount,
             aida.description
        FROM ap_invoice_distributions_all aida
       WHERE aida.invoice_id = pn_invoice_id
         AND aida.amount = pn_amount
         AND aida.description = pv_description
         AND aida.po_distribution_id IS NULL
       ORDER BY aida.distribution_line_number
         FOR UPDATE OF aida.po_distribution_id;
  
    rec_factures                 cur_factures%ROWTYPE;
    rec_distributions            cur_distributions%ROWTYPE;
    rec_new_distributions        cur_new_distributions%ROWTYPE;
    vn_invoice_id_from           ap_invoices_all.invoice_id%TYPE;
    vn_invoice_id_to             ap_invoices_all.invoice_id%TYPE;
    vn_nb_factures_lus           NUMBER := 0;
    vn_nb_factures_maj           NUMBER := 0;
    vn_nb_distributions_lus      NUMBER := 0;
    vn_nb_distributions_maj_orig NUMBER := 0;
    vn_nb_distributions_maj_dest NUMBER := 0;
    vn_nb_erreurs                NUMBER := 0;
    vn_indice                    NUMBER := 0;
    vb_first                     BOOLEAN := FALSE;
  
    TYPE myrecord IS RECORD(
      invoice_id_from          ap_invoices_all.invoice_id%TYPE,
      invoice_num_from         ap_invoices_all.invoice_num%TYPE,
      invoice_id_to            ap_invoices_all.invoice_id%TYPE,
      invoice_num_to           ap_invoices_all.invoice_num%TYPE,
      distribution_line_number ap_invoice_distributions_all.distribution_line_number%TYPE);
  
    TYPE mytable IS TABLE OF myrecord INDEX BY BINARY_INTEGER;
  
    vt_error mytable;
  
    dka_erreur_oracle VARCHAR2(80);
  
    vv_step VARCHAR2(30);
  
  BEGIN
    vv_step := 'UPDATE';
  
    -- Boucle de lecture des factures créées
    OPEN cur_factures;
  
    LOOP
      FETCH cur_factures
        INTO rec_factures;
      EXIT WHEN cur_factures%NOTFOUND;
    
      vn_nb_factures_lus := vn_nb_factures_lus + 1;
    
      -- Recherche de l'invoice_id de la facture d'origine
      SELECT invoice_id
        INTO vn_invoice_id_from
        FROM ap_invoices_all aia
       WHERE aia.invoice_num = rec_factures.invoice_num_from
         AND aia.vendor_id = rec_factures.vendor_id;
    
      -- Recherche de l'invoice_id de la facture de destination
      SELECT invoice_id
        INTO vn_invoice_id_to
        FROM ap_invoices_all aia
       WHERE aia.invoice_num = rec_factures.invoice_num_to
         AND aia.vendor_id = rec_factures.vendor_id;
    
      vb_first := TRUE;
      OPEN cur_distributions(vn_invoice_id_from);
      LOOP
        FETCH cur_distributions
          INTO rec_distributions;
        EXIT WHEN cur_distributions%NOTFOUND;
      
        IF vb_first THEN
          vn_nb_factures_maj := vn_nb_factures_maj + 1;
          vb_first           := FALSE;
        END IF;
      
        vn_nb_distributions_lus := vn_nb_distributions_lus + 1;
      
        dka_tools_pkg.put_outdebug_message(rec_factures.invoice_num_from || ' (' ||
                                           vn_invoice_id_from || ') ' ||
                                           rec_factures.invoice_num_to || ' (' ||
                                           vn_invoice_id_to || ') : ' ||
                                           rec_distributions.po_distribution_id ||
                                           ' - ' ||
                                           rec_distributions.amount ||
                                           ' - ' || substr(rec_distributions.description,
                                                           1,
                                                           40));
      
        OPEN cur_new_distributions(vn_invoice_id_to,
                                   rec_distributions.amount,
                                   rec_distributions.description);
        FETCH cur_new_distributions
          INTO rec_new_distributions;
        IF cur_new_distributions%NOTFOUND THEN
          vn_nb_erreurs := vn_nb_erreurs + 1;
          vt_error(vn_nb_erreurs).invoice_id_from := vn_invoice_id_from;
          vt_error(vn_nb_erreurs).invoice_num_from := rec_factures.invoice_num_from;
          vt_error(vn_nb_erreurs).invoice_id_to := vn_invoice_id_to;
          vt_error(vn_nb_erreurs).invoice_num_to := rec_factures.invoice_num_to;
          vt_error(vn_nb_erreurs).distribution_line_number := rec_distributions.distribution_line_number;
        ELSE
          UPDATE ap_invoice_distributions_all aida
             SET aida.po_distribution_id = NULL
           WHERE CURRENT OF cur_distributions;
        
          vn_nb_distributions_maj_orig := vn_nb_distributions_maj_orig +
                                          SQL%ROWCOUNT;
        
          UPDATE ap_invoice_distributions_all aida
             SET aida.po_distribution_id = rec_distributions.po_distribution_id
           WHERE CURRENT OF cur_new_distributions;
        
          vn_nb_distributions_maj_dest := vn_nb_distributions_maj_dest +
                                          SQL%ROWCOUNT;
        END IF;
        CLOSE cur_new_distributions;
      
      END LOOP;
      CLOSE cur_distributions;
    
    END LOOP;
    CLOSE cur_factures;
  
    WHILE vn_indice < vn_nb_erreurs LOOP
      vn_indice := vn_indice + 1;
      IF vn_indice = 1 THEN
        dka_tools_pkg.put_outdebug_message('== LISTE DES FACTURES NON MISES A JOUR ==');
        dka_tools_pkg.put_outdebug_message('=========================================');
      END IF;
      dka_tools_pkg.put_outdebug_message('Facture : ' || vt_error(vn_indice).invoice_num_from || ' (' || vt_error(vn_indice).invoice_id_from || ')');
      dka_tools_pkg.put_outdebug_message('Facture : ' || vt_error(vn_indice).invoice_num_to || ' (' || vt_error(vn_indice).invoice_id_to || ')');
      dka_tools_pkg.put_outdebug_message('Ligne de distribution : ' || vt_error(vn_indice).distribution_line_number);
      dka_tools_pkg.put_outdebug_message('=========================================');
    END LOOP;
  
    dka_tools_pkg.put_outdebug_message('==> Nombre de factures lues                                   : ' ||
                                       vn_nb_factures_lus);
    dka_tools_pkg.put_outdebug_message('==> Nombre de factures mises à jour                           : ' ||
                                       vn_nb_factures_maj);
    dka_tools_pkg.put_outdebug_message('==> Nombre de lignes de distribution lues                     : ' ||
                                       vn_nb_distributions_lus);
    dka_tools_pkg.put_outdebug_message('==> Nombre de lignes de distribution origine mises à jour     : ' ||
                                       vn_nb_distributions_maj_orig);
    dka_tools_pkg.put_outdebug_message('==> Nombre de lignes de distribution destination mises à jour : ' ||
                                       vn_nb_distributions_maj_dest);
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_UPDATE_INVOICE_DISTRIBUTIONS_F - Step ' ||
                                         vv_step || ' ()');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_update_inv_distributions_f;
  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INSERT_HOLD_F
  --  Description   : Insertion des code blocages sur les factures crees
  --                  On se base sur les blocages non leves sur la facture d'origine
  --                  Lien facture orgine <> facture destination contenu dans Dka_Fusion_Ap_Invoice
  --
  --  PARAMETRES    : Type de Code blocage ( Permettant Oui ou non la centralisation)
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_insert_hold_f(pv_postable_flag IN VARCHAR2) RETURN BOOLEAN IS
  
    CURSOR cur_hold IS
      SELECT aia_to.invoice_id,
             aia_to.invoice_num           invoice_num_to,
             aia_from.invoice_num         invoice_num_from,
             aha_from.line_location_id,
             aha_from.hold_lookup_code,
             aha_from.held_by,
             aha_from.hold_date,
             aha_from.hold_reason,
             aha_from.release_lookup_code,
             aha_from.release_reason,
             aha_from.status_flag,
             aha_from.attribute_category,
             aha_from.attribute1,
             aha_from.attribute2,
             aha_from.attribute3,
             aha_from.attribute4,
             aha_from.attribute5,
             aha_from.attribute6,
             aha_from.attribute7,
             aha_from.attribute8,
             aha_from.attribute9,
             aha_from.attribute10,
             aha_from.attribute11,
             aha_from.attribute12,
             aha_from.attribute13,
             aha_from.attribute14,
             aha_from.attribute15,
             dfai.org_id_to,
             aha_from.responsibility_id,
             aha_from.rcv_transaction_id
        FROM dka_fusion_ap_invoice dfai,
             ap_invoices_all       aia_from,
             ap_holds_all          aha_from,
             ap_hold_codes         ahc_from,
             ap_invoices_all       aia_to
       WHERE aia_from.invoice_num = dfai.invoice_num_from
         AND aia_from.vendor_id = dfai.vendor_id
         AND aia_from.org_id = dfai.org_id_from
         AND aha_from.invoice_id = aia_from.invoice_id
         AND aha_from.release_lookup_code IS NULL
         AND aia_to.invoice_num = dfai.invoice_num_to
         AND aia_to.vendor_id = dfai.vendor_id
         AND aia_to.org_id = dfai.org_id_to
         AND ahc_from.hold_lookup_code = aha_from.hold_lookup_code
         AND ahc_from.postable_flag = pv_postable_flag;
  
    rec_hold          cur_hold%ROWTYPE;
    dka_erreur_oracle VARCHAR2(80);
    vn_nb_blocages    NUMBER := 0;
    vn_nbre_enr       NUMBER;
  
  BEGIN
    OPEN cur_hold;
    LOOP
      FETCH cur_hold
        INTO rec_hold;
      EXIT WHEN cur_hold%NOTFOUND;
    
      vn_nb_blocages := vn_nb_blocages + 1;
      INSERT INTO ap_holds_all
        (invoice_id,
         line_location_id,
         hold_lookup_code,
         last_update_date,
         last_updated_by,
         held_by,
         hold_date,
         hold_reason,
         release_lookup_code,
         release_reason,
         status_flag,
         last_update_login,
         creation_date,
         created_by,
         attribute_category,
         attribute1,
         attribute2,
         attribute3,
         attribute4,
         attribute5,
         attribute6,
         attribute7,
         attribute8,
         attribute9,
         attribute10,
         attribute11,
         attribute12,
         attribute13,
         attribute14,
         attribute15,
         org_id,
         responsibility_id,
         rcv_transaction_id,
         hold_id)
      VALUES
        (rec_hold.invoice_id,
         rec_hold.line_location_id,
         rec_hold.hold_lookup_code,
         SYSDATE,
         fnd_profile.value('USER_ID'),
         rec_hold.held_by,
         rec_hold.hold_date,
         rec_hold.hold_reason,
         rec_hold.release_lookup_code,
         rec_hold.release_reason,
         rec_hold.status_flag,
         fnd_profile.value('LOGIN_ID'),
         SYSDATE,
         fnd_profile.value('USER_ID'),
         rec_hold.attribute_category,
         rec_hold.attribute1,
         rec_hold.attribute2,
         rec_hold.attribute3,
         rec_hold.attribute4,
         rec_hold.attribute5,
         rec_hold.attribute6,
         rec_hold.attribute7,
         rec_hold.attribute8,
         rec_hold.attribute9,
         rec_hold.attribute10,
         rec_hold.attribute11,
         rec_hold.attribute12,
         rec_hold.attribute13,
         rec_hold.attribute14,
         rec_hold.attribute15,
         rec_hold.org_id_to,
         rec_hold.responsibility_id,
         rec_hold.rcv_transaction_id,
         ap_holds_s.nextval);
      dka_tools_pkg.put_outdebug_message('Blocage inséré de Invoice Num ' ||
                                         rec_hold.invoice_num_from ||
                                         ' vers Invoice Num ' ||
                                         rec_hold.invoice_num_to);
    END LOOP;
    CLOSE cur_hold;
  
    dka_tools_pkg.put_outdebug_message(vn_nb_blocages ||
                                       ' enregistrements inseres dans AP_HOLDS_ALL');
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_INSERT_HOLD_F (' ||
                                         pv_postable_flag || ')');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Post_Fusion
  --  Description   : procédure principale post-fusion
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_post_fusion(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER,
                             pv_debug   IN VARCHAR2) IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Post_Fusion') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    -- Insertion aux factures destinations des code blocages non leves sur les factures d'origine
    IF NOT dka_insert_hold_f(pv_postable_flag => 'Y') THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Desactivation des valeurs reactivees lors du traitement
    IF NOT dka_reinit_ffv_f THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Desactivation des CCIDs reactives lors du traitement
    IF NOT dka_reinit_ccid_f THEN
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur main_Post_Fusion');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
  END main_post_fusion;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Hold_No_Cent
  --  Description   : procédure principale d'insertion des code blocages
  --                  n'autorisant pas la centralisation
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_hold_no_cent(pv_errbuf  IN OUT VARCHAR2,
                              pn_retcode OUT NUMBER,
                              pv_debug   IN VARCHAR2) IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Hold_No_Cent') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    -- Insertion aux factures destinations des code blocages non leves sur les factures d'origine
    IF NOT dka_insert_hold_f(pv_postable_flag => 'N') THEN
      RAISE dka_erreur_e;
    END IF;
  
    --JVI 17/05/06
    IF NOT dka_maj_blocage THEN
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur main_Hold_No_Cent');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
  END main_hold_no_cent;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_EXTRACT_IMAGES
  --  Description   : Extraction des liens images existant pour les mouvements du périmètre de fusion
  --
  --
  --
  --  PARAMETRES    : Type de Code blocage ( Permettant Oui ou non la centralisation)
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_extract_images RETURN NUMBER IS
  
    dka_erreur_oracle VARCHAR2(80);
    vn_nbre_enr       NUMBER;
  BEGIN
    INSERT INTO dka_ap_invfus_attached_docs
      (org_name,
       org_id,
       invoice_num,
       invoice_id,
       vendor_id,
       vendor_num,
       vendor_name,
       vendor_site_id,
       vendor_site_code,
       invoice_type_lookup_code,
       pay_group_lookup_code,
       invoice_date,
       attached_document_id,
       seq_num,
       automatically_added_flag,
       status,
       document_id,
       datatype_id,
       category_id,
       security_type,
       security_id,
       publish_flag,
       image_type,
       storage_type,
       usage_type,
       start_date_active,
       end_date_active,
       description,
       file_name,
       media_id)
      SELECT haou.name                 AS org_name,
             aia.org_id,
             aia.invoice_num,
             aia.invoice_id,
             aia.vendor_id,
             pv.segment1               AS vendor_num,
             pv.vendor_name,
             aia.vendor_site_id,
             pvsa.vendor_site_code,
             invoice_type_lookup_code,
             aia.pay_group_lookup_code,
             invoice_date,
             fad.attached_document_id,
             seq_num,
             automatically_added_flag,
             fad.status,
             fd.document_id,
             fd.datatype_id,
             fd.category_id,
             security_type,
             security_id,
             publish_flag,
             image_type,
             storage_type,
             usage_type,
             fd.start_date_active,
             fd.end_date_active,
             fdt.description,
             fdt.file_name,
             fdt.media_id
        FROM ap_invoices_all aia
        JOIN hr_all_organization_units haou
          ON (aia.org_id = haou.organization_id)
        JOIN ap_supplier_sites_all pvsa
          ON (pvsa.vendor_site_id = aia.vendor_site_id)
        JOIN ap_suppliers pv
          ON (pv.vendor_id = pvsa.vendor_id)
        JOIN fnd_attached_documents fad
          ON (fad.entity_name = 'AP_INVOICES' AND
             aia.invoice_id = fad.pk1_value AND fad.pk2_value IS NULL AND
             fad.pk3_value IS NULL AND fad.pk4_value IS NULL)
        JOIN fnd_documents fd
          ON (fd.document_id = fad.document_id)
        JOIN fnd_documents_tl fdt
          ON (fdt.document_id = fd.document_id AND
             fdt.language = fdt.source_lang)
      -- RG1 le type de donnée doit être fichier
        JOIN fnd_document_datatypes fdd
          ON (fdd.datatype_id = fd.datatype_id AND fdd.name = 'FILE' AND
             fdd.language = 'F')
      -- RG1 Les pièces dont l'unité opérationnelle fait partie du jeu de transcodification
        JOIN dka_stransco_headers dsh
          ON (dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE')
        JOIN dka_stransco_lines dsl
          ON (dsl.set_id = dsh.set_id AND dsl.enable = 'Y' AND
             dsl.param1_value = haou.name)
      -- RG1 dont la pièce a été créée dans la société absorbante
        JOIN dka_fusion_ap_invoice dfai
          ON (dfai.org_id_from = aia.org_id AND
             dfai.vendor_id = aia.vendor_id AND
             dfai.invoice_num_from = aia.invoice_num AND
             dfai.societe_absorbee = 'N')
      
       WHERE 1 = 1;
    vn_nbre_enr := SQL%ROWCOUNT;
    dka_tools_pkg.put_outdebug_message(vn_nbre_enr ||
                                       ' enregistrements inseres dans DKA_AP_INVFUS_ATTACHED_DOCS');
  
    IF vn_nbre_enr = 0 THEN
      RETURN - 1;
    END IF;
    COMMIT;
    RETURN 1;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_EXTRACT_IMAGES ');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN 0;
  END;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_AJOUT_LIEN
  --  Description   : Ctrl que le code journal passe en parametre existe
  --
  --  PARAMETRES    : Numero de factuure (message)
  --                  Code journal
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Numerique
  --     Valeurs possibles : -1 Probleme
  --                          0 Pas trouve
  --                          1 Trouve
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_ajout_lien(pv_simulation IN VARCHAR2) RETURN BOOLEAN IS
    dka_erreur_oracle VARCHAR2(80);
    vn_nbre_enr       NUMBER := 0;
    CURSOR cur_images IS
      SELECT daiad.org_name,
             daiad.org_id,
             daiad.invoice_num,
             daiad.invoice_id,
             daiad.vendor_id,
             daiad.vendor_num,
             daiad.vendor_name,
             daiad.vendor_site_id,
             daiad.vendor_site_code,
             daiad.invoice_type_lookup_code,
             daiad.pay_group_lookup_code,
             daiad.invoice_date,
             daiad.attached_document_id,
             daiad.seq_num,
             daiad.automatically_added_flag,
             daiad.status,
             daiad.document_id,
             daiad.datatype_id,
             daiad.category_id,
             daiad.security_type,
             daiad.security_id,
             daiad.publish_flag,
             daiad.image_type,
             daiad.storage_type,
             daiad.usage_type,
             daiad.start_date_active,
             daiad.end_date_active,
             daiad.description,
             daiad.file_name,
             daiad.media_id,
             dfai.invoice_num_to            invoice_num_to,
             dfai.org_id_to                 org_id_to,
             --,   dfaii.invoice_id    new_invoice_id
             aia.invoice_id new_invoice_id
        FROM dka_ap_invfus_attached_docs daiad,
             dka_fusion_ap_invoice       dfai,
             dka_fusion_ap_inv_int       dfaii,
             ap_invoices_all             aia,
             ap_suppliers                aps
       WHERE daiad.org_id = dfai.org_id_from
         AND dfai.invoice_num_from = daiad.invoice_num
         AND dfai.invoice_num_to = dfaii.invoice_num
         AND daiad.org_id = dfai.org_id_from
         AND dfai.invoice_num_from = daiad.invoice_num
         AND dfai.invoice_num_to = dfaii.invoice_num
         AND aia.invoice_num = dfaii.invoice_num
         AND aps.vendor_id = aia.vendor_id
         AND aia.source = 'FUSION'
         AND aia.invoice_amount = dfaii.invoice_amount
         AND aia.org_id = dfaii.org_id
         AND aia.invoice_date = dfaii.invoice_date
         AND aps.segment1 = daiad.vendor_num;
  
    rec_images             cur_images%ROWTYPE;
    l_attached_document_id NUMBER;
  BEGIN
    FOR rec_images IN cur_images LOOP

         IF pv_simulation = 'N' THEN
        SELECT fnd_attached_documents_s.nextval
          INTO l_attached_document_id
          FROM dual;
        -- Rattachement à la société absorbante
        INSERT INTO fnd_attached_documents
          (attached_document_id,
           document_id,
           creation_date,
           created_by,
           last_update_date,
           last_updated_by,
           seq_num,
           entity_name,
           pk1_value,
           pk2_value,
           pk3_value,
           pk4_value,
           pk5_value,
           automatically_added_flag)
        VALUES
          (l_attached_document_id,
           rec_images.document_id,
           SYSDATE,
           fnd_profile.value('USER_ID'),
           SYSDATE,
           fnd_profile.value('USER_ID'),
           rec_images.seq_num,
           'AP_INVOICES',
           rec_images.new_invoice_id,
           NULL,
           NULL,
           NULL,
           NULL,
           rec_images.automatically_added_flag);
      
      END IF;
      dka_tools_pkg.put_outdebug_message('Document ' ||
                                         rec_images.file_name ||
                                         ' attaché sur la facture ' ||
                                         rec_images.invoice_num_to);
    END LOOP;
     
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur DKA_AJOUT_LIEN');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_ajout_lien;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Rattchmt_Images
  --  Description   : procédure principale de rattachement des images existantes sur
  --                  société aborbante
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_rattchmt_images(pv_errbuf     IN OUT VARCHAR2,
                                 pn_retcode    OUT NUMBER,
                                 pv_simulation IN VARCHAR2,
                                 pv_debug      IN VARCHAR2) IS
  
    vv_erreur_oracle VARCHAR2(80);
    vn_retour        NUMBER;
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Rattchmt_Images') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
    DELETE FROM dka_ap_invfus_attached_docs;
    -- Recensement des images disponibles sur les mouvements d'origines pour le périmètre de fusion
    vn_retour := dka_extract_images;
    IF vn_retour = -1 THEN
      -- Si pas d'enregistrements -> Warning
      pn_retcode := 1;
    ELSIF vn_retour = 0 THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Ajout du lien avec les images sur les factures crées sur la société absorbante
    IF NOT dka_ajout_lien(pv_simulation) THEN
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur main_Rattchmt_Images');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
  END main_rattchmt_images;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_LISTE_LETTRAGE
  --  Description   : Affichage de la somme des mouvements concernés par le lettrage à 0, le tout par vendor
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_liste_lettrage RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    --Vn_Nbre_Enr NUMBER;
  
    CURSOR cur_liste_lettrage IS
      SELECT pv.segment1, pvs.vendor_site_code, SUM(dfal.amount) amount
        FROM dka_fusion_ap_lettrage dfal,
             po_vendors             pv,
             po_vendor_sites_all    pvs
       WHERE dfal.vendor_id = pv.vendor_id
         AND dfal.vendor_site_id = pvs.vendor_site_id
       GROUP BY pv.segment1, pvs.vendor_site_code;
  
    rec_liste_lettrage cur_liste_lettrage%ROWTYPE;
  
  BEGIN
  
    dka_tools_pkg.put_outdebug_message('SOMME DES MOUVEMENTS CONCERNES PAR LE LETTRAGE A ZERO');
    dka_tools_pkg.put_outdebug_message('=====================================================');
    dka_tools_pkg.put_outdebug_message(chr(10));
    dka_tools_pkg.put_outdebug_message(rpad('Fournisseur', 30, ' ') ||
                                       ' | ' ||
                                       rpad('Site fournisseur', 16, ' ') ||
                                       ' | ' || 'Somme des mouvements');
    OPEN cur_liste_lettrage;
    LOOP
      FETCH cur_liste_lettrage
        INTO rec_liste_lettrage;
      EXIT WHEN cur_liste_lettrage%NOTFOUND;
    
      dka_tools_pkg.put_outdebug_message(rpad(rec_liste_lettrage.segment1,
                                              30,
                                              ' ') || ' | ' ||
                                         rpad(rec_liste_lettrage.vendor_site_code,
                                              16,
                                              ' ') || ' | ' ||
                                         to_char(rec_liste_lettrage.amount,
                                                 '999G999G999D99'));
    
    END LOOP;
    CLOSE cur_liste_lettrage;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_LISTE_LETTRAGE');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_liste_lettrage;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_INSERT_LETTRAGE
  --  Description   : Insert dans une table temporaire DKA_MVT_AP_LETTRAGE_0
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_insert_lettrage RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    vn_nbre_enr NUMBER;
  
  BEGIN
  
    INSERT INTO dka_fusion_ap_lettrage
      (invoice_type_lookup_code,
       vendor_id,
       vendor_site_id,
       invoice_num,
       invoice_id,
       amount)
      SELECT invoice_type_lookup_code,
             b.vendor_id,
             b.vendor_site_id,
             invoice_num,
             invoice_id,
             (invoice_amount - nvl(amount_paid, 0)) amount
        FROM ap_invoices_all          b,
             gl_code_combinations_kfv gcc,
             dka_stransco_headers     dsh,
             dka_stransco_lines       dsl,
             hr_operating_units       hou
       WHERE accts_pay_code_combination_id = gcc.code_combination_id
         AND nvl(invoice_amount, 0) != nvl(amount_paid, 0)
         AND invoice_type_lookup_code != 'PREPAYMENT'
         AND gcc.segment3 != '40110F' ---exclue avoir qui solde l'acompte
         AND dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsh.set_id = dsl.set_id
         AND dsl.enable = 'Y'
         AND hou.name = dsl.param1_value
         AND hou.organization_id = b.org_id;
  
    vn_nbre_enr := SQL%ROWCOUNT;
    dka_tools_pkg.put_outdebug_message(vn_nbre_enr ||
                                       ' enregistrements inseres dans DKA_FUSION_AP_LETTRAGE');
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_INSERT_LETTRAGE');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
  END dka_insert_lettrage;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Let_Rec
  --  Description   : procédure principale de recensement des mouvements à lettrer
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_let_rec(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         pv_debug   IN VARCHAR2) IS
  
    vv_erreur_oracle VARCHAR2(80);
    vn_nbre_enr      NUMBER;
  
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Let_Rec') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    DELETE dka_fusion_ap_lettrage;
    vn_nbre_enr := SQL%ROWCOUNT;
  
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => vn_nbre_enr ||
                                               ' record deleted in  DKA_FUSION_AP_LETTRAGE') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    -- Insertion dans la table DKA_FUSION_AP_LETTRAGE
    IF NOT dka_insert_lettrage THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Affichage de la somme des mouvements concernés par le lettrage à 0, regroupée par vendor
    IF NOT dka_liste_lettrage THEN
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      ROLLBACK;
    
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur main_Let_Rec');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
    
  END main_let_rec;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAJ_HOLDS_ALL
  --  Description   : Update des codes blocages pour lettrage à 0
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_maj_holds_all RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    vn_nbre_enr NUMBER;
  
  BEGIN
  
    UPDATE ap_holds_all
       SET release_lookup_code = 'APPROVED',
           release_reason      = 'Blocage approuvé'
     WHERE invoice_id IN (SELECT invoice_id FROM dka_fusion_ap_lettrage);
  
    vn_nbre_enr := SQL%ROWCOUNT;
    dka_tools_pkg.put_outdebug_message(vn_nbre_enr ||
                                       ' enregistrements mis à jour dans AP_HOLDS_ALL');
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_MAJ_HOLDS_ALL');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_maj_holds_all;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAJ_PAYMENT_SCHEDULES_ALL
  --  Description   : Update du mode de paiement pour lettrage à 0
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_maj_payment_schedules_all RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    vn_nbre_enr NUMBER;
  
  BEGIN
  
    UPDATE ap_payment_schedules_all
       SET payment_method_lookup_code = 'CHECK',
           payment_method_code        = 'CHECK',
           payment_priority           = 50,
           external_bank_account_id   = NULL
     WHERE invoice_id IN (SELECT invoice_id FROM dka_fusion_ap_lettrage);
  
    vn_nbre_enr := SQL%ROWCOUNT;
    dka_tools_pkg.put_outdebug_message(vn_nbre_enr ||
                                       ' enregistrements mis à jour dans AP_PAYMENT_SCHEDULES_ALL');
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_MAJ_PAYMENT_SCHEDULES_ALL');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_maj_payment_schedules_all;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_MAJ_STATUS_APPROB
  --  Description   : Update du status d'approbation
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_maj_status_approb RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    vn_nbre_enr NUMBER;
  
  BEGIN
  
    UPDATE ap_invoices_all
       SET WFAPPROVAL_STATUS = 'WFAPPROVED'
     WHERE invoice_id IN (SELECT invoice_id FROM dka_fusion_ap_lettrage);
  
    vn_nbre_enr := SQL%ROWCOUNT;
    dka_tools_pkg.put_outdebug_message(vn_nbre_enr ||
                                       ' enregistrements mis à jour dans AP_INVOICES_ALL');
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_MAJ_STATUS_APPROB');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_maj_status_approb;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_LISTE_MAJ_LETTRAGE
  --  Description   : Etat de contrôle des mise à jour des codes blocage et mode de paiement du lettrage
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_liste_maj_lettrage RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    --Vn_Nbre_Enr NUMBER;
  
    -- Controle des mise à jour
    CURSOR cur_liste_maj_lettrage IS
      SELECT DISTINCT dfal.invoice_id,
                      dfal.invoice_num,
                      dfal.amount,
                      pv.segment1,
                      pvsa.vendor_site_code,
                      'Presence d un blocage'
        FROM dka_fusion_ap_lettrage dfal,
             ap_holds_all           aha,
             po_vendor_sites_all    pvsa,
             po_vendors             pv
       WHERE dfal.invoice_id = aha.invoice_id
         AND pv.vendor_id = dfal.vendor_id
         AND pvsa.vendor_site_id = dfal.vendor_site_id
         AND (aha.hold_reason IS NOT NULL AND aha.release_reason IS NULL)
      UNION ALL
      SELECT dfal.invoice_id,
             dfal.invoice_num,
             dfal.amount,
             pv.segment1,
             pvsa.vendor_site_code,
             'méthode de paiement different de CHECK'
        FROM dka_fusion_ap_lettrage   dfal,
             ap_payment_schedules_all aps,
             po_vendor_sites_all      pvsa,
             po_vendors               pv
       WHERE dfal.invoice_id = aps.invoice_id
         AND pv.vendor_id = dfal.vendor_id
         AND pvsa.vendor_site_id = dfal.vendor_site_id
         AND aps.payment_method_lookup_code != 'CHECK';
  
    rec_liste_maj_lettrage cur_liste_maj_lettrage%ROWTYPE;
  
    ---- Liste les classe de reglements nécessaire pour lettrage à 0
  
    CURSOR cur_liste_clas_reg_lettrage IS
      SELECT pay_group_lookup_code, COUNT(*) nombre
        FROM dka_fusion_ap_lettrage a, ap_invoices_all b
       WHERE a.invoice_id = b.invoice_id
       GROUP BY pay_group_lookup_code;
  
    rec_liste_clas_reg_lettrage cur_liste_clas_reg_lettrage%ROWTYPE;
  
  BEGIN
  
    -- Controle des mise à jour
  
    dka_tools_pkg.put_outdebug_message('CODE DES BLOCAGES ET MODE DE PAIEMENT DU LETTRAGE A ZERO');
    dka_tools_pkg.put_outdebug_message('========================================================');
    dka_tools_pkg.put_outdebug_message(chr(10));
  
    OPEN cur_liste_maj_lettrage;
    LOOP
      FETCH cur_liste_maj_lettrage
        INTO rec_liste_maj_lettrage;
      EXIT WHEN cur_liste_maj_lettrage%NOTFOUND;
    
      dka_tools_pkg.put_outdebug_message(rpad(rec_liste_maj_lettrage.invoice_id,
                                              20,
                                              ' ') || ' | ' ||
                                         rpad(rec_liste_maj_lettrage.invoice_num,
                                              20,
                                              ' ') || ' | ' ||
                                         rpad(rec_liste_maj_lettrage.segment1,
                                              20,
                                              ' ') || ' | ' ||
                                         rpad(rec_liste_maj_lettrage.vendor_site_code,
                                              20,
                                              ' ') || ' | ' ||
                                         to_char(rec_liste_maj_lettrage.amount,
                                                 '999G999G999D99'));
    
    END LOOP;
    CLOSE cur_liste_maj_lettrage;
  
    ---- Liste les classes de reglements nécessaire pour lettrage à 0
  
    dka_tools_pkg.put_outdebug_message(chr(10));
    dka_tools_pkg.put_outdebug_message(chr(10));
    dka_tools_pkg.put_outdebug_message('CLASSES DE REGLEMENTS NECESSAIRES POUR LETTRAGE A ZERO');
    dka_tools_pkg.put_outdebug_message('======================================================');
    dka_tools_pkg.put_outdebug_message(chr(10));
  
    OPEN cur_liste_clas_reg_lettrage;
    LOOP
      FETCH cur_liste_clas_reg_lettrage
        INTO rec_liste_clas_reg_lettrage;
      EXIT WHEN cur_liste_clas_reg_lettrage%NOTFOUND;
    
      dka_tools_pkg.put_outdebug_message(rpad(rec_liste_clas_reg_lettrage.pay_group_lookup_code,
                                              20,
                                              ' ') || ' | ' ||
                                         to_char(rec_liste_clas_reg_lettrage.nombre,
                                                 '999G999G999'));
    
    END LOOP;
    CLOSE cur_liste_clas_reg_lettrage;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_LISTE_MAJ_LETTRAGE');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_liste_maj_lettrage;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Let_Maj
  --  Description   : procédure principale de mise à jour des mouvements à lettrer
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_let_maj(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         pv_debug   IN VARCHAR2) IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Let_Maj') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    -- Mise à jour des code blocage AP_HOLDS_ALL pour lettrage à 0
    IF NOT dka_maj_holds_all THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Mise à jour du mode de paiement pour lettrage à
    IF NOT dka_maj_payment_schedules_all THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Mise à jour du status d'approbation
    IF NOT dka_maj_status_approb THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Liste de controle de la mise à jour
    IF NOT dka_liste_maj_lettrage THEN
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur main_Let_Maj');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
    
  END main_let_maj;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_LISTE_MVT_LETTRAGE
  --  Description   : liste les factures non prise en compte pour le lettrage à 0
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_liste_mvt_lettrage RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    --Vn_Nbre_Enr NUMBER;
  
    -- Controle des mise à jour
    CURSOR cur_liste_mvt_lettrage IS
      SELECT aia.invoice_type_lookup_code invoice_type,
             pv.segment1 segment1,
             pvsa.vendor_site_code vendor_site_code,
             aia.invoice_num invoice_num,
             aia.invoice_id invoice_id,
             (aia.invoice_amount - nvl(aia.amount_paid, 0)) amount,
             decode(apsa.external_bank_account_id,
                    NULL,
                    'pas de banque sur la facture',
                    apsa.external_bank_account_id || ' - Id cpte bancaire') banque,
             decode(pvsa.hold_all_payments_flag,
                    'Y',
                    'Blocage reglement au niveau du site fournisseur',
                    pvsa.hold_all_payments_flag) blocage
        FROM ap_invoices_all          aia,
             ap_payment_schedules_all apsa,
             po_vendor_sites_all      pvsa,
             po_vendors               pv,
             dka_stransco_headers     dsh,
             dka_stransco_lines       dsl,
             hr_operating_units       hou
       WHERE aia.invoice_id = apsa.invoice_id
         AND pvsa.vendor_site_id = aia.vendor_site_id
         AND aia.vendor_id = pv.vendor_id
         AND nvl(aia.invoice_amount, 0) != nvl(aia.amount_paid, 0)
         AND aia.invoice_type_lookup_code != 'PREPAYMENT'
         AND dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsh.set_id = dsl.set_id
         AND dsl.enable = 'Y'
         AND hou.name = dsl.param1_value
         AND hou.organization_id = aia.org_id
      UNION ALL
      SELECT aiv.invoice_type,
             pv.segment1,
             pvsa.vendor_site_code,
             aiv.invoice_num,
             aiv.invoice_id,
             aiv.invoice_amount amount,
             decode(apsa.external_bank_account_id,
                    NULL,
                    'pas de bque sur la fact',
                    apsa.external_bank_account_id || ' - Id cpte bancaire') banque,
             decode(pvsa.hold_all_payments_flag,
                    'Y',
                    'Blocage reglement au niveau du site fournisseur',
                    pvsa.hold_all_payments_flag) blocage
        FROM ap_invoices_v            aiv,
             ap_payment_schedules_all apsa,
             po_vendor_sites_all      pvsa,
             po_vendors               pv,
             dka_stransco_headers     dsh,
             dka_stransco_lines       dsl,
             hr_operating_units       hou
       WHERE aiv.invoice_id = apsa.invoice_id
         AND aiv.vendor_site_id = pvsa.vendor_site_id
         AND aiv.vendor_id = pv.vendor_id
         AND aiv.payment_status_flag = 'Y'
         AND aiv.invoice_type_lookup_code = 'PREPAYMENT'
         AND aiv.approval_status_lookup_code != 'FULL'
         AND dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsh.set_id = dsl.set_id
         AND dsl.enable = 'Y'
         AND hou.name = dsl.param1_value
         AND hou.organization_id = aiv.org_id;
  
    rec_liste_mvt_lettrage cur_liste_mvt_lettrage%ROWTYPE;
  
  BEGIN
  
    -- recensement des pieces
  
    dka_tools_pkg.put_outdebug_message('FACTURES NON PRISE EN COMPTE POUR LE LETTRAGE A ZERO');
    dka_tools_pkg.put_outdebug_message('====================================================');
    dka_tools_pkg.put_outdebug_message(chr(10));
  
    OPEN cur_liste_mvt_lettrage;
    LOOP
      FETCH cur_liste_mvt_lettrage
        INTO rec_liste_mvt_lettrage;
      EXIT WHEN cur_liste_mvt_lettrage%NOTFOUND;
    
      dka_tools_pkg.put_outdebug_message(rpad(rec_liste_mvt_lettrage.invoice_type,
                                              25,
                                              ' ') || ' | ' ||
                                         rpad(rec_liste_mvt_lettrage.segment1,
                                              30,
                                              ' ') || ' | ' ||
                                         rpad(rec_liste_mvt_lettrage.vendor_site_code,
                                              5,
                                              ' ') || ' | ' ||
                                         rpad(rec_liste_mvt_lettrage.invoice_num,
                                              50,
                                              ' ') || ' | ' ||
                                         to_char(rec_liste_mvt_lettrage.invoice_id,
                                                 '999999999999999') ||
                                         ' | ' ||
                                         to_char(rec_liste_mvt_lettrage.amount,
                                                 '999G999G999D99') ||
                                         ' | ' || rpad(rec_liste_mvt_lettrage.banque,
                                                       30,
                                                       ' ') || ' | ' ||
                                         rpad(rec_liste_mvt_lettrage.blocage,
                                              50,
                                              ' '));
    
    END LOOP;
    CLOSE cur_liste_mvt_lettrage;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_LISTE_MVT_LETTRAGE');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_liste_mvt_lettrage;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Let_Mvt
  --  Description   : procédure principale d'affichage des mouvements non pris en compte et affectation blocage
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_let_mvt(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         pv_debug   IN VARCHAR2) IS
  
    vv_erreur_oracle VARCHAR2(80);
  
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Let_Mvt') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
  
    -- Lister les factures non prise en compte pour le lettrage à zéro
    IF NOT dka_liste_mvt_lettrage THEN
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur main_Let_Mvt');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
    
  END main_let_mvt;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_ANNULATION_WF
  --  Description   : Annulation des Workflows sur société absorbée
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_annulation_wf RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    vn_nbre_enr NUMBER;
  
    CURSOR cur_select_wf IS
      SELECT DISTINCT wias.item_type, wias.item_key
        FROM wf_item_activity_statuses   wias,
             ap_invoices_all             aia,
             dka_stransco_headers        dsh,
             dka_stransco_lines          dsl,
             hr_operating_units          hou,
             fnd_doc_sequence_categories fdsc
      
       WHERE wias.item_type = 'DKA_CSP'
         AND wias.item_key LIKE aia.invoice_id || '%'
         AND wias.activity_status != 'COMPLETE'
         AND aia.invoice_type_lookup_code IN
             ('STANDARD', 'CREDIT', 'EXPENSE REPORT', 'DEBIT')
         AND fdsc.application_id = 200
         AND fdsc.code = aia.doc_category_code
         AND fdsc.name LIKE (substr(dsl.param1_value, 4, 4) || '%')
         AND aia.invoice_type_lookup_code != 'PREPAYMENT'
         AND dsh.set_name = 'FUSION_SOCIETE_VERS_SOCIETE'
         AND dsh.set_id = dsl.set_id
         AND dsl.enable = 'Y'
         AND hou.name = dsl.param1_value
         AND hou.organization_id = aia.org_id;
  
    rec_select_wf cur_select_wf%ROWTYPE;
  
  BEGIN
  
    FOR rec_select_wf IN cur_select_wf LOOP
      BEGIN
        wf_engine.abortprocess(itemtype => rec_select_wf.item_type,
                               itemkey  => rec_select_wf.item_key);
        dka_tools_pkg.put_outdebug_message('Workflow ' ||
                                           rec_select_wf.item_key ||
                                           ' annulé');
      EXCEPTION
        WHEN OTHERS THEN
          dka_erreur_oracle := substr(SQLERRM, 1, 80);
          dka_tools_pkg.put_outdebug_message('Erreur annulation Workflow ' ||
                                             rec_select_wf.item_key);
          dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      END;
    END LOOP;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_ANNULATION_WF');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_annulation_wf;

  ----------------------------------------------------------------------------------------------------------------
  --  Nom           : DKA_NOTIFICATION
  --  Description   : Identification des notifications ouvertes sans moteur de workflow
  --
  --  PARAMETRES    : *NONE
  --
  --  VALEUR RETOURNEE :
  --     Description       : BOOLEAN
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION dka_notification RETURN BOOLEAN IS
  
    dka_erreur_oracle VARCHAR2(80);
  
    vn_nbre_enr NUMBER;
  
    CURSOR cur_select_notif IS
      SELECT DISTINCT wn.notification_id
        FROM wf_notifications wn
      
       WHERE wn.message_type = 'DKA_CSP'
         AND wn.status = 'OPEN'
         AND wn.callback = NULL;
  
    rec_select_notif cur_select_notif%ROWTYPE;
  
  BEGIN
  
    FOR rec_select_notif IN cur_select_notif LOOP
      BEGIN
        UPDATE wf_notifications
           SET status = 'CLOSED'
         WHERE notification_id = rec_select_notif.notification_id;
        dka_tools_pkg.put_outdebug_message('Notification ' ||
                                           rec_select_notif.notification_id ||
                                           ' fermée');
      EXCEPTION
        WHEN OTHERS THEN
          dka_erreur_oracle := substr(SQLERRM, 1, 80);
          dka_tools_pkg.put_outdebug_message('Erreur fermeture notification ' ||
                                             rec_select_notif.notification_id);
          dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      END;
    END LOOP;
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      dka_erreur_oracle := substr(SQLERRM, 1, 80);
    
      dka_tools_pkg.put_outdebug_message('Erreur DKA_NOTIFICATION');
      dka_tools_pkg.put_outdebug_message(dka_erreur_oracle);
      RETURN FALSE;
    
  END dka_notification;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Annul_workflow
  --  Description   : procédure principale d'annulation des workflow sur société absorbée
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_annul_workflow(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER,
                                pv_debug   IN VARCHAR2) IS
  
    vv_erreur_oracle VARCHAR2(80);
    vn_retour        NUMBER;
    --Erreur du programme
    dka_erreur_e EXCEPTION;
  
  BEGIN
    vv_debug_flag := pv_debug;
    IF NOT
        dka_print_debug_f(pv_position_debug => +1,
                          pv_marque         => '>',
                          pv_msg            => 'DKA_FUSION_AP_PKG.main_Annul_workflow') THEN
      -- Probleme
      RAISE dka_erreur_e;
    END IF;
    -- Annulation des workflow actifs pour toutes les factures de la société absorbée
    IF NOT dka_annulation_wf THEN
      RAISE dka_erreur_e;
    END IF;
  
    -- Identification des notifications restées ouvertes sans moteur de workflow
    IF NOT dka_notification THEN
      RAISE dka_erreur_e;
    END IF;
  
  EXCEPTION
  
    WHEN dka_erreur_e THEN
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur du traitement';
      pn_retcode := 2;
    
    WHEN OTHERS THEN
      vv_erreur_oracle := substr(SQLERRM, 1, 80);
      dka_tools_pkg.put_outdebug_message('Erreur main_Annul_workflow');
      dka_tools_pkg.put_outdebug_message(vv_erreur_oracle);
      dka_tools_pkg.put_outdebug_message('Annulation des modifications effectuees');
      ROLLBACK;
    
      pv_errbuf  := 'Erreur Main';
      pn_retcode := 2;
  END main_annul_workflow;

END dka_fusion_ap_pkg;

/
show err;
exit;
