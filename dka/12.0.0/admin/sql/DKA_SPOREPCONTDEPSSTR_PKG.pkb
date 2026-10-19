CREATE OR REPLACE PACKAGE BODY DKA_SPOREPCONTDEPSSTR_PKG AS
-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOREPCONTDEPSSTR_PKG.pkb
-- DESCRIPTION      : DKA_SPOREPCONTDEPSSTR_PKG Package Body
--
-- AUTEUR           : A.DELTOUR (Capgemini)
-- DATE DE CREATION : 28/08/2007
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 03/02/2009 CDE Evolution EID20090030 - gestion multi lieux de livraison
--                + champs description spécifique et ref fournisseur
-- 03/03/2009 CDE Prise en cpte alim "description_specifique_contrat" au lieu de
--                "comments" ds ctrl import du contrat + calcul Nbre apprv reel 
-- 02/03/2010 CDE Evolution EID20090323 - Changement de gestion du type de dépense
--                Evolution EID20090220 - Initialisation des nouveaux champs 
--                 + alimentation des tables d'archivage DKA
-- 18/10/2010 CDE EID20100185 - Adaptation pour déploiement sur VP
-- 17/10/2016 RBE Migration R12
-- 24/08/2017 NBO artf2212366 - SPE119 - Numérotation des contrats non conforme à la SFD
-- -----------------------------------------------------------------------------
--
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--
-- -----------------------------------------------------------------------------
-- Nom              : main
-- Description      : Procédure principale du traitement qui enchaîne l'ensemble
--                    des autres procédures.
--
-- PARAMETRES       : Pv_Errbuf         Sortie Message d'erreur
--                    Pn_Retcode        Sortie Code Retour de la procédure
--                                           '0' : Normal
--                                           '1' : Avertissement
--                                           '2' : Erreur
--
-- VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-- -----------------------------------------------------------------------------
PROCEDURE Main(Pv_Errbuf  OUT NOCOPY VARCHAR2,
               Pn_Retcode OUT NOCOPY NUMBER
              ) 
IS

Vn_count                            NUMBER         := 0;
Vn_total_rec                        NUMBER         := 0;
Vn_erreur_bis                       NUMBER         := 0;
Vn_rec_incomplet                    NUMBER         := 0;
Vn_rec_incomplet_bis                NUMBER         := 0;
Vn_rec_approved                     NUMBER         := 0;
Vn_new                              NUMBER         := 0;
Vn_total_contrat                    NUMBER         := 0;
i                                   INTEGER        := 0;
Vn_preparer_id                      Number         := 0;
--------------------------------------------
-- Curseur de lecture de la table temporaire 
--------------------------------------------
CURSOR C_TMP
IS  SELECT ref_contrat_depsttr, 
           description,
           ref_contrat_cadre,
           ref_contrat_cadre_desc, 
           num_fournisseur, 
           site_code, 
          -- CDE 030209 ship_to, 
           bill_to, 
           nature_prestation, 
           acheteur, 
           matricule, 
           debut_contrat, 
           fin_contrat, 
           montant_contrat, 
           reconduction_flag, 
           nbr_reconduction, 
           preavis_resiliation, 
           revision_flag, 
           revision_date, 
           nbr_intervention, 
           periodicite_int, 
           intervention_realise, 
          -- CDE 020310 type_depense, 
           variable_flag, 
           comments, 
           periodicite_fac,
           COUNT(*) nb_lignes 
    FROM   DKA_PO_CONTRAT_DEPSSTR_TMP tmp
    WHERE  ROW_STATUS = 'N'
    GROUP BY
           ref_contrat_depsttr, 
           description,
           ref_contrat_cadre,
           ref_contrat_cadre_desc, 
           num_fournisseur, 
           site_code, 
           -- CDE 030209 ship_to,
           bill_to, 
           nature_prestation, 
           acheteur, 
           matricule, 
           debut_contrat, 
           fin_contrat, 
           montant_contrat, 
           reconduction_flag, 
           nbr_reconduction, 
           preavis_resiliation, 
           revision_flag, 
           revision_date, 
           nbr_intervention, 
           periodicite_int, 
           intervention_realise, 
           type_depense, 
           variable_flag, 
           comments, 
           periodicite_fac     
    ORDER BY ref_contrat_depsttr ASC;    
    
--------------------------------------------
-- Curseur de lecture des lignes d'imputations 
--------------------------------------------
CURSOR C_TMP_2 ( p_ref_contrat_depsstr VARCHAR2 )
IS  SELECT ROWID,tmp.* 
    FROM   DKA_PO_CONTRAT_DEPSSTR_TMP tmp
    WHERE  ROW_STATUS = 'N'
    AND    tmp.ref_contrat_depsttr = p_ref_contrat_depsstr
    ORDER BY ref_contrat_depsttr, projet ASC;    
--------------------------------------------
-- Numérotation automatique des contrats
--------------------------------------------
CURSOR C_SEGMENT1
IS  SELECT to_char(current_max_unique_identifier + 1)
     FROM   po_unique_identifier_control
     WHERE  table_name = 'PO_HEADERS'
     FOR UPDATE OF current_max_unique_identifier;
     
rec_tmp_2 c_tmp_2%ROWTYPE;         

BEGIN
  Dka_Tools_Pkg.Put_Debug_Message('Start - Main (+)');  
  
  ----------------------------------
  -- initialisation des variables --
  ---------------------------------- 
            
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Execution du traitement d''import et d''approbation des contrats dépendant et de SSTR');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  BEGIN
    SELECT fu.employee_id
    INTO   Vn_preparer_id
    FROM   FND_USER fu
    WHERE  fu.user_id = FND_PROFILE.value('USER_ID'); --'SOFTAPACK'; --RBE MigR12
  EXCEPTION WHEN NO_DATA_FOUND THEN
    Dka_Tools_Pkg.Put_Debug_Message('=> Init: L''approbateur n''est pas défini. Aucune donnée ne peut être traitée');
    Pn_Retcode := 2;
    RETURN;
  END;   
  ---------------------------------------------------------------------------------
  -- Phase 1 : Identification des contrats cadres de sous-traitance en doublons  --
  -- Principe:                                                                   --
  ---------------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Debug_Message(' ');
  Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Debug_Message('=> Phase 1 : Identification des doublons');
  
  UPDATE dka_po_contrat_depsstr_tmp t
  SET    t.ROW_STATUS = 'R'
  WHERE (t.REF_CONTRAT_DEPSTTR) IN (SELECT tmp.ref_contrat_depsttr
                                   FROM ( SELECT REF_CONTRAT_DEPSTTR,SHIP_TO,PROJET, COUNT(1)
                                          FROM dka_po_contrat_depsstr_tmp
                                          GROUP BY REF_CONTRAT_DEPSTTR,SHIP_TO,PROJET
                                          HAVING COUNT(1) > 1
                                         )tmp
                                  );
  IF SQL%ROWCOUNT != 0 THEN
    Dka_Tools_Pkg.Put_Debug_Message('Présence de contrats dépendant/Sstr en doublon.');
  END IF;
  COMMIT;    
  Dka_Tools_Pkg.Put_Debug_Message('=> Statut OK');
  
  FOR REC_TMP IN C_TMP
  LOOP
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('Contrat - référence = ' || rec_tmp.ref_contrat_depsttr);
        
    gt_imputation_tab.DELETE;
    i := 0;       
    
    DECLARE
      Vb_is_null                          BOOLEAN                           := FALSE;
      Vv_column_name                      VARCHAR2(4000)                    := NULL;     
      Vb_date                             BOOLEAN                           := FALSE;
      Vb_no_data_found                    BOOLEAN                           := FALSE;
      Vb_error                            BOOLEAN                           := FALSE;
      Vb_reject                           BOOLEAN                           := FALSE;
      Vn_vendor_id                        PO_VENDORS.VENDOR_ID%TYPE         := NULL;
      Vn_vendor_site_id                   PO_VENDOR_SITES_ALL.VENDOR_SITE_ID%TYPE := NULL;
      Vn_ship_to_location_id              HR_LOCATIONS_ALL.LOCATION_ID%TYPE := NULL;
      Vn_head_ship_to_location_id         HR_LOCATIONS_ALL.LOCATION_ID%TYPE := NULL; -- CDE 030209
      Vn_bill_to_location_id              HR_LOCATIONS_ALL.LOCATION_ID%TYPE := NULL;
      Vn_category_id                      MTL_CATEGORIES_B.CATEGORY_ID%TYPE := NULL;
      Vn_agent_id                         PO_HEADERS_ALL.AGENT_ID%TYPE      := NULL;
      Vv_item_key                         PO_HEADERS_ALL.WF_ITEM_KEY%TYPE   := NULL;
      Vv_item_type                        PO_HEADERS_ALL.WF_ITEM_TYPE%TYPE  := NULL;
      Vv_Workflow_Process                 PO_DOCUMENT_TYPES_ALL.WF_APPROVAL_PROCESS%TYPE;
      Vv_segment1                         PO_HEADERS_ALL.SEGMENT1%TYPE      := NULL;
      Vv_rowid                            VARCHAR2(100)                     := NULL;
      Vn_header_id                        PO_HEADERS_ALL.PO_HEADER_ID%TYPE  := NULL;
      Vn_terms_id                         PO_VENDOR_SITES_ALL.Terms_Id%TYPE := NULL;
      Vv_periodicite_int                  FND_FLEX_values.Flex_Value%TYPE   := NULL;
      Vv_expenditure_type                 Pa_Expenditure_Types.Expenditure_Type%TYPE := NULL;
      Vv_status                           PA_PROJECTS_ALL.PROJECT_STATUS_CODE%TYPE := NULL;
      Vv_type_contrat                     FND_FLEX_VALUES.FLEX_VALUE%TYPE   := NULL;
      Vn_po_header_id                     PO_HEADERS_ALL.PO_HEADER_ID%TYPE  := NULL;
      Vd_start_date                       PO_HEADERS_ALL.Start_Date%TYPE    := NULL;                      
      Vd_end_date                         PO_HEADERS_ALL.End_Date%TYPE      := NULL;
      Vn_project_id                       PA_PROJECTS_ALL.PROJECT_ID%TYPE   := NULL;
      Vn_task_id                          PA_TASKS.TASK_ID%TYPE             := NULL; --RBE
      Vn_contrat_imputation_id            DKA_CONTRAT_SSTR_IMPUTATION.CONTRAT_IMPUTATION_ID%TYPE := NULL;
      Vn_nbr_entete                       NUMBER                            := 0;
      Vn_exist                            NUMBER                            := NULL;
      E_check_failed                      EXCEPTION;
      E_not_inserted                      EXCEPTION;
            
    BEGIN
      
      SAVEPOINT SV1;
      ------------------------------------------------------------------------   
      -- Verification que toutes les informations destinées à l'entête du   -- 
      -- contrat sont identiques                                            --
      -- sur chaque lignes d'imputation                                     --
      ------------------------------------------------------------------------
      IF rec_tmp.ref_contrat_depsttr IS NOT NULL THEN
        SELECT COUNT(t.ref_contrat_depsttr)
        INTO   Vn_nbr_entete
        FROM   DKA_PO_CONTRAT_DEPSSTR_TMP t
        WHERE  t.ref_contrat_depsttr = rec_tmp.ref_contrat_depsttr
        GROUP BY t.ref_contrat_depsttr;
      ELSE
        Dka_Tools_Pkg.Put_Debug_Message('=> ERREUR : La référence du contrat n''est pas renseignée');
        RAISE E_not_inserted;
      END IF;
      
      IF rec_tmp.nb_lignes != Vn_nbr_entete THEN
        Dka_Tools_Pkg.Put_Debug_Message('=> Vérifier les informations d''entête/lignes (' || Vn_nbr_entete || '/' || rec_tmp.nb_lignes || ')' );        
        RAISE E_not_inserted;
      ELSE
        Dka_Tools_Pkg.Put_Debug_Message('=> Entêtes du contrat correctes (' || Vn_nbr_entete || '/' || rec_tmp.nb_lignes || ')' );
        
        --
        -- On vérifie que le contrat cadre n' a pas déja été importé.
        --
        SELECT COUNT(1)
        INTO   Vn_exist
        FROM   PO_HEADERS_ALL pha
               ,dka.DKA_CONTRAT_SSTR dcs 
        WHERE  dcs.po_header_id = pha.po_header_id
        -- CDE 030309 AND    pha.comments = rec_tmp.ref_contrat_depsttr || '-' || rec_tmp.description
        AND    dcs.description_specifique_contrat = rec_tmp.ref_contrat_depsttr || '-' || rec_tmp.description
        AND    pha.type_lookup_code = 'CONTRACT'
        AND    pha.attribute4 IN ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
        AND    pha.org_id = gn_org_id
        AND    dcs.org_id = gn_org_id;
      
        IF Vn_exist > 0
        THEN
          Dka_Tools_Pkg.Put_Debug_Message('Le contrat ' || rec_tmp.ref_contrat_depsttr || '-' ||  rec_tmp.description || ' a déjà été importé.');
          RAISE E_not_inserted;
        END IF;        
                
        -- Traitement des lignes       
        OPEN C_TMP_2(rec_tmp.ref_contrat_depsttr);
        LOOP
          FETCH C_TMP_2 INTO rec_tmp_2;
          EXIT WHEN C_TMP_2%NOTFOUND;         
          
          -- Réinitialisation des variables
          Vb_is_null                 := FALSE;          
          Vb_date                    := FALSE;
          Vb_no_data_found           := FALSE;
          Vb_error                   := FALSE;  
          
          ---------------------------------------------------------------------------------
          -- Phase 2 : Contrôle des colonnes obligatoires                                --
          -- Colonnes : Ref.contrat dependant ou de sous-traitance                       --
          --            Num oracle fournisseur                                           --
          --            Code site fournisseur                                            --
          --            Lieu de livraison                                                --
          --            Lieu de facturation                                              --
          --            Nature de prestation                                             --
          --            Nom du signataire                                                --
          --            Date de debut de contrat                                         --
          --            Date de fin de contrat                                           --
          --            Montant contrat                                                  --
          --            Tacite reconduction                                              --
          --            Nombre de reconduction                                           --
          --            Preavis de résialitaion                                          --
          --            Flag revision                                                    --
          --            Date révision                                                    --
          --            Type de dépense                                                  --
          --            Varaible de facturation                                          --
          --            Periodicité de facturation                                       --
          --            Projet                                                           --
          ---------------------------------------------------------------------------------             
          Dka_Tools_Pkg.Put_Debug_Message('=> Phase 2 : Vérification des champs obligatoires');     
          
          IF rec_tmp_2.ref_contrat_depsttr IS NULL THEN
            vv_column_name := 'Ref.contrat dependant ou de sous-traitance';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.num_fournisseur IS NULL THEN
            vv_column_name :=  vv_column_name || CHR(10) ||'Num oracle fournisseur';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.site_code IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Code site fournisseur';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.ship_to  IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Lieu de livraison';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.bill_to  IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Lieu de facturation';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.nature_prestation  IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Nature de prestation';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.acheteur IS NULL OR rec_tmp_2.matricule IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Nom du signataire / Matricule';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.debut_contrat IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Date de debut de contrat';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.fin_contrat IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Date de fin de contrat';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.montant_contrat IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Montant du contrat';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.RECONDUCTION_FLAG IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Tacite reconduction';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.NBR_RECONDUCTION IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Nombre de reconduction';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.PREAVIS_RESILIATION IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Préavis de résiliation';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.REVISION_FLAG IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Flag révision';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.REVISION_DATE IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Date de révision';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.TYPE_DEPENSE IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Type de dépense';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.VARIABLE_FLAG IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Flag variable facturation';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.PERIODICITE_FAC IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Periodicite facturation';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.PROJET IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Projet d''imputation';
            vb_is_null := TRUE;
          END IF;
          
          IF vb_is_null THEN
            Dka_Tools_Pkg.Put_Debug_Message('Statut : Valeur NULL sur zone obligatoire détectée.' );
            Dka_Tools_Pkg.Put_Debug_Message('Les champs concernés sont:' || CHR(10) || vv_column_name);                
          ELSE      
            Dka_Tools_Pkg.Put_Debug_Message('=> Statut OK');
          END IF;
                
          ---------------------------------------------------------------------------------
          -- Phase 3 : Contrôle référentiel                                              --
          -- Colonnes : Num oracle fournisseur                                           --
          --            Code site fournisseur                                            --
          --            Lieu de livraison                                                --
          --            Lieu de facturation                                              --
          --            Nature de prestation                                             --
          --            Matricule                                                        --          
          ---------------------------------------------------------------------------------             
          Dka_Tools_Pkg.Put_Debug_Message('=> Phase 3 : Contrôle référentiel');
          -- Fournisseur       
          BEGIN
            IF rec_tmp_2.num_fournisseur IS NOT NULL THEN
              SELECT pv.VENDOR_ID
              INTO   Vn_vendor_id
              FROM   PO_VENDORS pv
              WHERE  pv.segment1 = rec_tmp_2.num_fournisseur;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.1): Aucun fournisseur trouvé pour le numéro ' || rec_tmp_2.num_fournisseur);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.1) : ' || SQLERRM);
          END;
          -- site fournisseur
          BEGIN
            IF rec_tmp_2.site_code IS NOT NULL AND Vn_vendor_id IS NOT NULL THEN
              SELECT pvsa.vendor_site_id,
                     pvsa.terms_id 
              INTO   Vn_vendor_site_id,
                     Vn_terms_id
              FROM   PO_VENDOR_SITES_ALL pvsa
              WHERE  pvsa.vendor_id  = Vn_vendor_id
              AND    pvsa.vendor_site_code = rec_tmp_2.site_code
              AND    NVL(pvsa.inactive_date,TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
              AND    pvsa.org_id = gn_org_id;
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.2): Aucun site fournisseur trouvé pour le numéro fournisseur ' || rec_tmp_2.num_fournisseur || ' et le code site ' || rec_tmp_2.site_code );
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.2) : ' || SQLERRM);
          END;
          -- Lieu de livraison
          BEGIN
            IF rec_tmp_2.ship_to IS NOT NULL THEN
              SELECT hl.location_id
              INTO   Vn_ship_to_location_id
              FROM   hr_locations hl
              WHERE  hl.ship_to_site_flag = 'Y'
              AND    hl.location_code = rec_tmp_2.ship_to
              ;          
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.3): Aucun lieu de livraison trouvé pour le lieu ' || rec_tmp_2.ship_to);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.3) : ' || SQLERRM);
          END;
          -- Lieu de facturation     
          BEGIN
            IF rec_tmp_2.bill_to IS NOT NULL THEN
              SELECT hl.location_id
              INTO   Vn_bill_to_location_id
              FROM   hr_locations hl
              WHERE  hl.bill_to_site_flag  = 'Y'
              AND    hl.location_code = rec_tmp_2.bill_to
              ;          
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.4): Aucun lieu de facturation trouvé pour le lieu ' || rec_tmp_2.bill_to);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.4) : ' || SQLERRM);
          END;
          -- Nature de prestation    
          BEGIN
            IF rec_tmp_2.nature_prestation IS NOT NULL THEN
              SELECT mc.category_id
              INTO   Vn_category_id
              FROM   mtl_categories_kfv mc
              WHERE  mc.concatenated_segments = rec_tmp_2.nature_prestation
              AND    mc.structure_id = 201
              -- CDE 181010 AND    mc.segment2 = 'SSTR'
              -- CDE 181010 AND    mc.segment5 = 'GZ'
              AND    mc.attribute1 = 'OUI';        
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.5): Aucune catégorie trouvée pour les segments ' || rec_tmp_2.nature_prestation);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.5) : ' || SQLERRM);
          END;                                    
          -- Matricule  
          BEGIN
            IF rec_tmp_2.matricule IS NOT NULL THEN
              SELECT fu.employee_id
              INTO   Vn_agent_id
              FROM   FND_USER fu
              WHERE  fu.user_name = rec_tmp_2.matricule;       
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.6): Aucun acheteur trouvé pour le matricule ' || rec_tmp_2.matricule);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.6) : ' || SQLERRM);
          END;       
          -- Periodicité d'intervention
          BEGIN
            IF rec_tmp_2.PERIODICITE_INT IS NOT NULL THEN
              SELECT fvv.flex_VALUE
              INTO   Vv_periodicite_int 
              FROM   fnd_flex_value_sets fvs,
                     fnd_flex_values_vl fvv 
              WHERE  fvs.flex_value_set_id = fvv.FLEX_VALUE_SET_ID 
              AND    fvs.flex_value_set_name = 'DKA_PERIODICITE_INTERVENTION'
              AND    fvv.FLEX_VALUE = rec_tmp_2.PERIODICITE_INT;       
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.7): Périodicité d''intervention invalide ' || rec_tmp_2.PERIODICITE_INT);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.7) : ' || SQLERRM);
          END; 
          -- Type de dépense
          BEGIN
            IF rec_tmp_2.TYPE_DEPENSE IS NOT NULL THEN
              SELECT expenditure_type
              INTO   Vv_expenditure_type 
              FROM   pa_expenditure_types pet
              WHERE  NVL(pet.attribute5,'N') = 'Y'
              AND    NVL(pet.attribute3,'N') = 'Y'
              AND    pet.expenditure_type = rec_tmp_2.TYPE_DEPENSE;      
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.8): Type de dépense invalide ' || rec_tmp_2.TYPE_DEPENSE);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.8) : ' || SQLERRM);
          END; 
          -- Projet
          BEGIN
            IF rec_tmp_2.PROJET IS NOT NULL THEN
                SELECT ppa.project_status_code,
                       ppa.project_id
                INTO   Vv_status,
                       Vn_project_id 
                FROM   pa_projects_all ppa
                WHERE  ppa.segment1 = rec_tmp_2.projet
                AND    ppa.org_id = gn_org_id;
                
                IF Vv_status = 'CLOSED' THEN
                  Vb_error := TRUE;
                  Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.9): Le projet ' || rec_tmp_2.PROJET || 'est fermé.');
                END IF;
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.9): Projet invalide ' || rec_tmp_2.PROJET);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.9) : ' || SQLERRM);
          END;
          -- Tache
          BEGIN
            IF rec_tmp_2.TACHE IS NOT NULL THEN

                SELECT pt.task_id
                INTO vn_task_id
                FROM pa_projects_all pp, pa_tasks pt
                WHERE pt.project_id  = pp.project_id 
                AND   pt.task_number = rec_tmp_2.tache 
                AND   pp.project_id  = Vn_project_id
                AND   pp.org_id      = gn_org_id;
    
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.10): Tâche invalide ' || rec_tmp_2.TACHE);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.10) : ' || SQLERRM);
          END;
          -- Détermination du type de contrat                                 --
          -- Si le type est dépendant, alors il doit exister un contrat cadre.--
          -- Les dates du contrat cadre doivent être cohérente avec celles du --
          -- contrat dépendant                                                --
          ----------------------------------------------------------------------      
          /* --RBE Migration R12
          IF rec_tmp_2.ref_contrat_cadre IS NOT NULL THEN
            Vv_type_contrat := 'CONTRAT DEPENDANT'; 
            BEGIN
              SELECT pha.po_header_id,
                     pha.start_date,
                     pha.end_date
              INTO   Vn_po_header_id,
                     Vd_start_date,
                     Vd_end_date
              FROM   po_headers_all pha
              WHERE  pha.comments = rec_tmp_2.ref_contrat_cadre || '-' || rec_tmp_2.REF_CONTRAT_CADRE_DESC
              AND    pha.attribute4 = 'CONTRAT CADRE'
              AND    pha.type_lookup_code = 'CONTRACT'
              AND    pha.org_id = gn_org_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                Vb_no_data_found := TRUE;
                Dka_Tools_Pkg.Put_Debug_Message('=> Référence du contrat cadre introuvable' || rec_tmp_2.ref_contrat_cadre);
              WHEN OTHERS THEN
                Vb_error := TRUE;
                Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.10) : ' || SQLERRM);
            END;                     
          ELSE */
          Vv_type_contrat := 'CONTRAT SOUS-TRAITANCE';
          Vn_po_header_id := NULL;                 
          --END IF;  --RBE Migration R12             
          ---------------------------------------------------------------------------------
          -- Contrôle de cohérence des dates                                             --
          -- Colonnes : Date de debut de contrat                                         --
          --            Date de fin de contrat                                           --      
          ---------------------------------------------------------------------------------                         
          IF rec_tmp_2.debut_contrat >= rec_tmp_2.fin_contrat THEN
            Vb_date := TRUE;
            Dka_Tools_Pkg.Put_Debug_Message('Statut (3.11) : Dates incohérentes.' );
            Dka_Tools_Pkg.Put_Debug_Message('Date début: ' || rec_tmp_2.debut_contrat || ', Fin contrat: ' || rec_tmp_2.fin_contrat);      
          END IF;   
          
          IF rec_tmp_2.debut_contrat IS NOT NULL AND rec_tmp_2.debut_contrat < NVL(Vd_start_date,rec_tmp_2.debut_contrat-1) THEN
            Vb_date := TRUE;
            Dka_Tools_Pkg.Put_Debug_Message('Statut (3.12): Dates incohérentes.' );
            Dka_Tools_Pkg.Put_Debug_Message('Date début contrat cadre : ' || Vd_start_date || ', Date de début du contrat dép/Sstr: ' || rec_tmp_2.debut_contrat);    
          END IF;
          
          IF rec_tmp_2.fin_contrat IS NOT NULL AND rec_tmp_2.fin_contrat > NVL(Vd_end_date,rec_tmp_2.fin_contrat+1) THEN
            Vb_date := TRUE;
            Dka_Tools_Pkg.Put_Debug_Message('Statut (3.13): Dates incohérentes.' );
            Dka_Tools_Pkg.Put_Debug_Message('Date fin contrat cadre : ' || Vd_end_date || ', Date de début du contrat dép/Sstr: ' || rec_tmp_2.fin_contrat);    
          END IF;
          
          IF NOT vb_is_null AND 
             NOT Vb_date AND 
             NOT Vb_no_data_found AND
             NOT Vb_error THEN
            i := i + 1;
            SELECT dka_contrat_sstr_imputation_s.NEXTVAL
            INTO   Vn_contrat_imputation_id 
            FROM DUAL;
            gt_imputation_tab(i).CONTRAT_IMPUTATION_ID := Vn_contrat_imputation_id;
            gt_imputation_tab(i).PO_HEADER_ID := NULL;
            gt_imputation_tab(i).PROJECT_ID := Vn_project_id;
            gt_imputation_tab(i).TASK_ID    := Vn_task_id; --RBE MigR12
            gt_imputation_tab(i).UNITE_OEUVRE := rec_tmp_2.unite;
            gt_imputation_tab(i).INSTALLATION_CODE := NULL;
            gt_imputation_tab(i).LOCATION_ID := Vn_ship_to_location_id;
            gt_imputation_tab(i).EXPENDITURE_TYPE := Vv_expenditure_type;
            
                 -- CDE 030209 Récup du lieu de livraison de la ligne 1
                 IF i=1 THEN
                 Vn_head_ship_to_location_id := Vn_ship_to_location_id;
                 END IF;
            
            Dka_Tools_Pkg.Put_Debug_Message('=> Statut OK');
            
          ELSE
            -- Mise à jour du statut du contrat      
            UPDATE DKA_PO_CONTRAT_DEPSSTR_TMP
            SET    ROW_STATUS = 'R'
            WHERE  ROWID = rec_tmp_2.ROWID;              
            Vb_reject := TRUE;  
          END IF;
        
        END LOOP;
        CLOSE C_TMP_2;
              
        IF NOT Vb_reject THEN            
          
          ---------------------------------------------------------------------------------
          -- Phase 4 : Insertion des contrats                                            --
          ---------------------------------------------------------------------------------        
          Dka_Tools_Pkg.Put_Debug_Message('=> Phase 4 : Insertion du contrat');    
          -- 24-AOU-17  NBO       artf2212366 - SPE119 - Numérotation des contrats non conforme à la SFD          
           -- Attribution du numéro de contrat        
          /*OPEN C_SEGMENT1;
          FETCH C_SEGMENT1 into vv_segment1;
          UPDATE po_unique_identifier_control
          SET    current_max_unique_identifier = current_max_unique_identifier + 1
          WHERE  CURRENT of C_SEGMENT1;
          CLOSE C_SEGMENT1;*/
          select DKA.DKA_CONTRAT_SSTR_NUM.nextval into vv_segment1 from dual;
          
          --RBE
          Vv_segment1 := Vv_segment1||'SSTR1';
          
          Dka_Tools_Pkg.Put_Debug_Message('=> Numéro de contrat = ' || Vv_segment1);
          
          po_headers_sv11.insert_po(X_Rowid => Vv_rowid, 
                                 X_Po_Header_Id => Vn_header_id, 
                                 X_Agent_Id => Vn_agent_id,                   
                                 X_Type_Lookup_Code  => 'CONTRACT' ,            
                                 X_Last_Update_Date => SYSDATE,              
                                 X_Last_Updated_By  => gn_userid,            
                                 X_Segment1 => Vv_segment1,
                                 X_Summary_Flag  => 'N',                 
                                 X_Enabled_Flag  => 'Y',  
                                 p_org_id => gn_org_id, --FND_PROFILE.value('ORG_ID'),   --RBE Migration R12      
                                 X_Segment2  => '' ,                    
                                 X_Segment3  => '' ,                    
                                 X_Segment4  => '' ,                    
                                 X_Segment5  => '' ,                    
                                 X_Start_Date_Active => '' ,              
                                 X_End_Date_Active => '' ,               
                                 X_Last_Update_Login => gn_login_id,             
                                 X_Creation_Date => SYSDATE,                  
                                 X_Created_By  => gn_userid,                    
                                 X_Vendor_Id => Vn_vendor_id,                     
                                 X_Vendor_Site_Id => Vn_vendor_site_id,                
                                 X_Vendor_Contact_Id  => '' ,           
                                 -- CDE 030209 X_Ship_To_Location_Id  => Vn_ship_to_location_id,  
                                 X_Ship_To_Location_Id  => Vn_head_ship_to_location_id,       
                                 X_Bill_To_Location_Id  => Vn_bill_to_location_id,          
                                 X_Terms_Id  => Vn_terms_id,                     
                                 X_Ship_Via_Lookup_Code => '',          
                                 X_Fob_Lookup_Code => '',               
                                 X_Pay_On_Code => '',                    
                                 X_Freight_Terms_Lookup_Code  => '',    
                                 X_Status_Lookup_Code => '',            
                                 X_Currency_Code => 'EUR',                 
                                 X_Rate_Type => '',                     
                                 X_Rate_Date => SYSDATE,                     
                                 X_Rate => '',                          
                                 X_From_Header_Id  => '',               
                                 X_From_Type_Lookup_Code => '',         
                                 X_Start_Date => rec_tmp.debut_contrat,                     
                                 X_End_Date => rec_tmp.fin_contrat,                      
                                 X_Blanket_Total_Amount => rec_tmp.montant_contrat,           
                                 X_Authorization_Status => '',           
                                 X_Revision_Num  => 0,                
                                 X_Revised_Date => '',                  
                                 X_Approved_Flag => '',                  
                                 X_Approved_Date  => '',                 
                                 X_Amount_Limit => '',                  
                                 X_Min_Release_Amount => '',             
                                 X_Note_To_Authorizer => '',              
                                 X_Note_To_Vendor => '',                  
                                 X_Note_To_Receiver  => '',               
                                 X_Print_Count => 0,                     
                                 X_Printed_Date => '',                     
                                 X_Vendor_Order_Num  => '',               
                                 X_Confirming_Order_Flag => 'N' ,         
                                --CDE 030209 X_Comments => rec_tmp.ref_contrat_depsttr ||'-'||rec_tmp.description,    
                                 X_Comments => '',                   
                                 X_Reply_Date   => '',                    
                                 X_Reply_Method_Lookup_Code   => '',      
                                 X_Rfq_Close_Date    => '',               
                                 X_Quote_Type_Lookup_Code  => '' ,        
                                 X_Quotation_Class_Code  => '' ,          
                                 X_Quote_Warning_Delay_Unit   => '',      
                                 X_Quote_Warning_Delay  => '',            
                                 X_Quote_Vendor_Quote_Number   => '',    
                                 X_Acceptance_Required_Flag => 'N',      
                                 X_Acceptance_Due_Date   => '' ,          
                                 X_Closed_Date => '',                     
                                 X_User_Hold_Flag   => '',                
                                 X_Approval_Required_Flag     => '',      
                                 X_Cancel_Flag  => 'N',                    
                                 X_Firm_Status_Lookup_Code  => 'N',     
                                 X_Firm_Date  => '',                      
                                 X_Frozen_Flag => 'N',
                                 X_Supply_Agreement_Flag => 'N',	
                                 X_Global_Agreement_Flag => '', 
                                 X_Attribute_Category => '' ,          
                                 X_Attribute1 => '',                      
                                 X_Attribute2 => '',                      
                                 X_Attribute3 => '',                      
                                 X_Attribute4 => Vv_type_contrat,                      
                                 X_Attribute5 => rec_tmp.nature_prestation,                      
                                 X_Attribute6 => '',                      
                                 X_Attribute7 => '',                      
                                 X_Attribute8 => '',                      
                                 X_Attribute9 => '',                      
                                 X_Attribute10 => '',                      
                                 X_Attribute11 => '',                     
                                 X_Attribute12 => '',                     
                                 X_Attribute13 => '',                     
                                 X_Attribute14 => '',                     
                                 X_Attribute15 => '',                     
                                 X_Closed_Code => '',                     
                                 X_Ussgl_Transaction_Code => '',           
                                 X_Government_Context => '',              
                                 X_Global_Attribute_Category => '',  	
                                 X_Global_Attribute1 => '',  		
                                 X_Global_Attribute2 => '',  		
                                 X_Global_Attribute3 => '',  		
                                 X_Global_Attribute4 => '',  		
                                 X_Global_Attribute5 => '',  		
                                 X_Global_Attribute6 => '',  		
                                 X_Global_Attribute7	=> '',  	
                                 X_Global_Attribute8 => '',  		
                                 X_Global_Attribute9 => '',  		
                                 X_Global_Attribute10	=> '',  
                                 X_Global_Attribute11	=> '',  
                                 X_Global_Attribute12	=> '',  
                                 X_Global_Attribute13 => '',  
                                 X_Global_Attribute14	=> '',  	
                                 X_Global_Attribute15	=> '',  	
                                 X_Global_Attribute16	=> '',  	
                                 X_Global_Attribute17	=> '',  	
                                 X_Global_Attribute18	=> '',  	
                                 X_Global_Attribute19	=> '',  	
                                 X_Global_Attribute20	=> '',  	
                                 X_Manual  => TRUE,                         
                                 X_Price_Update_Tolerance => ''  );
                                 
          IF NVL(Vn_header_id,0) != 0 THEN
            Dka_Tools_Pkg.Put_Debug_Message('=> Po_header_id = ' || Vn_header_id);         
            
            INSERT INTO Dka_Contrat_Sstr dcs
            ( po_header_id, 
              cadre_po_header_id, 
              flag_tacite_reconduction, 
              nb_reconduction, 
              preavis_resiliation, 
              flag_revision, 
              date_revision, 
              nb_intervention, 
              periodicite_intervention, 
              nb_intervention_realise, 
              -- CDE 020310 expenditure_type, 
              flag_facturation, 
              commentaire_facturation, 
              periodicite_facturation, 
              signataire_contrat, 
              created_by, 
              creation_date, 
              last_updated_by, 
              last_update_date, 
              org_id, 
              last_update_login,
              description_specifique_contrat,   -- CDE 030209
              ref_contrat_fournisseur,   -- CDE 030209
              revision_num,    -- CDE 020310
              reconduction_num) -- CDE 020310
            VALUES
            ( Vn_header_id,
              Vn_po_header_id,
              DECODE(rec_tmp.reconduction_flag,'OUI','Y','NON','N',NULL),
              rec_tmp.nbr_reconduction,
              rec_tmp.preavis_resiliation,
              DECODE(rec_tmp.revision_flag,'OUI','Y','NON','N',NULL),
              rec_tmp.revision_date,
              rec_tmp.nbr_intervention,
              rec_tmp.periodicite_int,
              rec_tmp.intervention_realise,
              -- CDE 020310 rec_tmp.type_depense,
              DECODE(rec_tmp.variable_flag,'OUI','Y','NON','N',NULL),
              rec_tmp.comments,   
              rec_tmp.periodicite_fac,
              Vn_agent_id,
              gn_userid,
              SYSDATE,
              gn_userid,
              SYSDATE,
              gn_org_id,   
              gn_login_id,
              rec_tmp.ref_contrat_depsttr ||'-'||rec_tmp.description, -- CDE 030209
              rec_tmp.ref_contrat_depsttr,   -- CDE 030209
              0, -- CDE 020310
              0);   -- CDE 020310

            FOR k IN gt_imputation_tab.FIRST..gt_imputation_tab.LAST
            LOOP
              INSERT INTO 
              DKA_CONTRAT_SSTR_IMPUTATION 
              ( contrat_imputation_id, 
                po_header_id, 
                project_id,
                task_id, --RBE MigR12 
                unite_oeuvre, 
                installation_code, 
                created_by, 
                creation_date, 
                last_updated_by, 
                last_update_date, 
                org_id, 
                last_update_login,
                location_id,
                expenditure_type, -- CDE 020310
                revision_num) -- CDE 020310
              VALUES 
              ( gt_imputation_tab(k).contrat_imputation_id,
                Vn_header_id,              
                gt_imputation_tab(k).project_id,
                gt_imputation_tab(k).task_id, --RBE MigR12
                gt_imputation_tab(k).unite_oeuvre,
                gt_imputation_tab(k).installation_code,
                gn_userid,
                SYSDATE,
                gn_userid,
                SYSDATE,
                gn_org_id,
                gn_login_id,
                gt_imputation_tab(k).location_id,
                gt_imputation_tab(k).expenditure_type, -- CDE 020310
                0    -- CDE 020310            
              );
            END LOOP;

            -- Mise à jour du statut du contrat
            UPDATE DKA_PO_CONTRAT_DEPSSTR_TMP
            SET    ROW_STATUS = 'I',
                   PO_HEADER_ID = Vn_header_id
            WHERE  ref_contrat_depsttr = rec_tmp.ref_contrat_depsttr;

            -- Excéution du worflow d'approbation POAPPRV           
            PO_REQAPPROVAL_INIT1.Start_WF_Process(ItemType              => Vv_item_type,
  					                                      ItemKey               => Vv_item_key,
  					                                      WorkflowProcess       => Vv_Workflow_Process,
  					                                      ActionOriginatedFrom  => 'Approval',
  					                                      DocumentID            => Vn_header_id,
  					                                      DocumentNumber        => Vv_segment1,
  					                                      preparerid            => Vn_preparer_id,
  					                                      DocumentTypeCode      => 'PA',
  	  				                                    DocumentSubtype       => 'CONTRACT',
  	  				                                    SubmitterAction       => 'APPROVE',
  	  				                                    forwardToID           => '',
  	  				                                    forwardFromID         => '',
                         			  				          DefaultApprovalPathID => '',
                           							          Note                  => '',
                           							          printFlag             => 'N',
                           							          p_sourcing_inv_org_id => gn_org_id); --RBE
                           							          

            Dka_Tools_Pkg.Put_Debug_Message('=> Exécution du workflow d''approbation ' );
          ELSE
            Dka_Tools_Pkg.Put_Debug_Message('=> Statut : po_headers_sv11.insert_po - contrat non inséré');
            RAISE E_not_Inserted;                                                      
          END IF;
          -- Mise à jour du statut du contrat
          UPDATE DKA_PO_CONTRAT_DEPSSTR_TMP
          SET    ROW_STATUS = 'A'               
          WHERE  ref_contrat_depsttr = rec_tmp.ref_contrat_depsttr;
          Dka_Tools_Pkg.Put_Debug_Message('=> Statut : OK');     
                      
        ELSE
          -- Passage au contrat suivant
          RAISE E_check_failed;
        END IF;      
      END IF;
    EXCEPTION    
    WHEN E_check_failed THEN
      Dka_Tools_Pkg.Put_Debug_Message('~ ERREUR : Passage au contrat suivant' );
      Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');      
      --vn_erreur := vn_erreur + 1;
    WHEN E_not_inserted THEN
      Dka_Tools_Pkg.Put_Debug_Message('~ ERREUR : Passage au contrat suivant' );
      Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      --vn_erreur := vn_erreur + 1;
      ROLLBACK TO SV1;
      UPDATE DKA_PO_CONTRAT_DEPSSTR_TMP
      SET    ROW_STATUS = 'R'
      WHERE  ref_contrat_depsttr = rec_tmp.ref_contrat_depsttr;   
    WHEN OTHERS THEN
      Dka_Tools_Pkg.Put_Debug_Message('~ ERREUR NON DEFINIE - ' || SQLERRM );
      Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      --vn_erreur := vn_erreur + 1;
      ROLLBACK TO SV1;
      UPDATE DKA_PO_CONTRAT_DEPSSTR_TMP
      SET    ROW_STATUS = 'R'
      WHERE  ref_contrat_depsttr = rec_tmp.ref_contrat_depsttr;
    END;
        
    vn_count := vn_count + 1;
     
  END LOOP;
  --CLOSE C_TMP;
  -----------------------------------------
  -- Alimentation des tables d'archivage DKA 
  -- pour les contrats qui ont été approuvés
  ------------------------------------------
  
  INSERT INTO DKA_CONTRAT_SSTR_ARCHI
  (SELECT distinct dcs.*
   FROM DKA_CONTRAT_SSTR dcs
        , DKA_PO_CONTRAT_DEPSSTR_TMP tmp
        , PO_HEADERS_ALL pha
   WHERE tmp.po_header_id = dcs.po_header_id
   AND pha.po_header_id = dcs.po_header_id
   AND tmp.row_status = 'A'
   AND pha.authorization_status = 'APPROVED'
   );
        
  INSERT INTO DKA_CONTRAT_SSTR_IMPUT_ARCHI
  (SELECT distinct dcsi.*
   FROM DKA_CONTRAT_SSTR_IMPUTATION dcsi
        , DKA_PO_CONTRAT_DEPSSTR_TMP tmp
        , PO_HEADERS_ALL pha
   WHERE tmp.po_header_id = dcsi.po_header_id
   AND pha.po_header_id = dcsi.po_header_id
   AND tmp.row_status = 'A'
   AND pha.authorization_status = 'APPROVED'
   );


  ------------------------------------------
  -- Reporting
  ------------------------------------------
  -- Nombre total d'enregistrements
  SELECT (SELECT COUNT(*) FROM DKA_PO_CONTRAT_DEPSSTR_TMP ),
         (SELECT COUNT(DISTINCT ref_contrat_depsttr) FROM DKA_PO_CONTRAT_DEPSSTR_TMP),
         (SELECT COUNT(*) FROM DKA_PO_CONTRAT_DEPSSTR_TMP WHERE ROW_STATUS = 'R'),
         (SELECT COUNT(*) FROM DKA_PO_CONTRAT_DEPSSTR_TMP WHERE ROW_STATUS = 'I'),
         (SELECT COUNT(DISTINCT ref_contrat_depsttr) FROM DKA_PO_CONTRAT_DEPSSTR_TMP WHERE ROW_STATUS = 'A' ),
         (SELECT COUNT(*) FROM DKA_PO_CONTRAT_DEPSSTR_TMP WHERE ROW_STATUS = 'N')
  INTO   Vn_total_rec,
         Vn_total_contrat,
         Vn_erreur_bis,
         Vn_rec_incomplet,
         Vn_rec_approved,
         Vn_new 
  FROM DUAL; 
  
  -- Nombre d'enregistrements approuvés
  SELECT COUNT(DISTINCT pha.po_header_id)
  INTO   Vn_rec_incomplet_bis
  FROM   PO_HEADERS_ALL pha,
         DKA_PO_CONTRAT_depsstr_TMP tmp,
         DKA_CONTRAT_SSTR dcs
  WHERE  -- CDE 030309 pha.comments = tmp.ref_contrat_depsttr || '-' || tmp.description
         dcs.description_specifique_contrat = tmp.ref_contrat_depsttr || '-' || tmp.description
  AND    dcs.po_header_id = pha.po_header_id    
  AND    pha.po_header_id = tmp.po_header_id
  AND    pha.authorization_status = 'APPROVED'
  AND    pha.approved_flag = 'Y'
  AND    TRUNC(pha.approved_date) = TRUNC(SYSDATE)
  AND    dcs.org_id = gn_org_id;  
           
  ------------------------------------------
  -- Resultat d'import
  ------------------------------------------
  Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total d''enregistrements...........................: ' ||  Vn_total_rec);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de contrat...................................: ' ||  Vn_total_contrat);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de contrat lu................................: ' ||  Vn_count);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de lignes en erreur..........................: ' ||  Vn_erreur_bis);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de lignes insérées mais non approuvées.......: ' ||  Vn_rec_incomplet);
  IF Vn_rec_incomplet_bis = Vn_rec_approved THEN
    Dka_Tools_Pkg.put_outdebug_message('Nombre Total d''enregistrements approuvés...................: ' ||  Vn_rec_approved);
  ELSE  
    Dka_Tools_Pkg.put_outdebug_message('Nombre Total d''enregistrements approuvés théoriques........: ' || Vn_rec_approved);
    Dka_Tools_Pkg.put_outdebug_message('Nombre Total d''enregistrements approuvés réels.............: ' || Vn_rec_incomplet_bis);
  END IF;
  
  IF Vn_new != 0 THEN
    Dka_Tools_Pkg.put_outdebug_message('Nombre Total d''enregistrements non traités.................: ' || Vn_new);
  END IF;
  
  Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> FIN DE PROGRAMME');
  Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');      
    
  Dka_Tools_Pkg.Put_Debug_Message('End - Main (-)');

EXCEPTION      
  WHEN OTHERS THEN    
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Pv_Errbuf  := 'Erreur dans la procécure Main : ' || SQLERRM;
    Pn_Retcode := 2;
    Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
    Dka_Tools_Pkg.Put_Debug_Message('End - Main (-)');
END Main;

END DKA_SPOREPCONTDEPSSTR_PKG;
/
SHOW ERROR PACKAGE BODY DKA_SPOREPCONTDEPSSTR_PKG
EXIT
