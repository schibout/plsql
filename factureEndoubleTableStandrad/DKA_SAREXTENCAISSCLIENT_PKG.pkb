CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAPEXTDATAFACT_PKG AS
  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : Projet Hélios
  -- NOM              : DKA_SAPEXTDATAFACT_PKG
  -- DESCRIPTION      : DKA_SAPEXTDATAFACT_PKG Package Body
  --
  -- AUTEUR           : IKRAME BALKHITY(Capgemini)
  -- DATE DE CREATION : 05/09/2023
  -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- -----------------------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  /*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (1000);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '+-----------------------------------------------------------------------------------------------------------------+';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????????????????????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line );
    Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Extraction de données Factures Fournisseurs pour le Datalake »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END output_header;

/*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '---------------------------------------------------------------------------';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;


  -- -----------------------------------------------------------------------------
  -- Nom              : Extraction_Encours
  -- Description      : Extraction des données pour la génération du fichier de
  --                    sortie justifiant l'encours
  --
  -- PARAMETRES       : Pv_Errbuf              Sortie Message d'erreur
  --                    Pn_Retcode             Sortie Code Retour de la procédure
  --                                                  '0' : Normal
  --                                                  '1' : Avertissement
  --                                                  '2' : Erreur
  --                    Pv_Debug_Mode Entrée          Mode debug
  --                    Pv_Region     Entrée          Centre de gestion
  --                    Pv_Periode    Entrée          Période
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE extraction_datalake(pv_errbuf  OUT VARCHAR2,
                               pn_retcode OUT NUMBER,
                 p_file_entete OUT VARCHAR2,
                 p_file_line OUT VARCHAR2,
                 p_file_reg OUT VARCHAR2) IS

    e_file EXCEPTION;
    pv_fin_periode   VARCHAR2(15);
    pv_fin_periode_1 VARCHAR2(15);
    pv_mois          VARCHAR2(10);
    l_message        VARCHAR2(4000);
    vn_date_pivot      VARCHAR2(20);
    vn_date_pivot_fin  VARCHAR2(20);

  is_found_rec boolean := false;

    -----------------------------------------------------------------
    -- Curseur de lecture des factures a la date du jour --
    -----------------------------------------------------------------
    CURSOR cur_factures_entete IS
    select aia.INVOICE_ID ID_FACTURE,
       aia.INVOICE_NUM NUMERO_FACTURE,
       aia.org_id UNITE_OPERATIONNELLE,
       aia.INVOICE_TYPE_LOOKUP_CODE TYPE_DOCUMENT,
       aia.INVOICE_CURRENCY_CODE DEVISE,
       aia.INVOICE_AMOUNT MONTANT_FACTURE_TTC,
       aia.TOTAL_TAX_AMOUNT MONTANT_FACTURE_TAX,
       aia.INVOICE_DATE in_DATE,
       aia.PAYMENT_METHOD_CODE MODE_REGLEMENT,
       aia.AMOUNT_PAID MONTANT_PAYE,
       aia.SOURCE SOURCE,
       replace(replace(replace(replace(aia.DESCRIPTION,CHR(13),' '),CHR(10),' '),';',' ') ,'"','')  DESCRIPTION,
       aia.REMIT_TO_SUPPLIER_ID IDENTIFIANT_EN_TETE_FACTOR,
       aia.REMIT_TO_SUPPLIER_NAME NOM_FACTOR,
       aia.REMIT_TO_SUPPLIER_SITE SITE_FACTOR,
       aia.REMIT_TO_SUPPLIER_SITE_ID ID_SITE_FACTOR,
       aia.EXTERNAL_BANK_ACCOUNT_ID ID_COMPTE_BANCAIRE,
       aia.WFAPPROVAL_STATUS STATUT_APPROBATION,
       aia.CANCELLED_AMOUNT MONTANT_ANNULE,
       aia.CANCELLED_BY ID_TECHNIQUE,
       aia.CANCELLED_DATE DATE_ANNULATION,
       aia.PAYMENT_CURRENCY_CODE DEVISE_PAIEMENT,
       aia.PAY_GROUP_LOOKUP_CODE CLASSE_REGLEMENT,
       aia.VENDOR_ID ID_ENTETE_FOURNISSEUR,
       aia.VENDOR_SITE_ID ID_SITE_FOURNISSEUR,
       aia.ACCTS_PAY_CODE_COMBINATION_ID ID_COMPTABLE,
       aia.ATTRIBUTE9 FOLIO,
       aia.GL_DATE DATE_GL,
       aia.SET_OF_BOOKS_ID ID_GL,
       aia.DOC_SEQUENCE_VALUE NUMERO_CHRONO,
       hou.name UO_FACTURE,
       aia.CREATION_DATE DATE_CREATION,
       aia.GL_DATE DATE_COMPTABILISATION,
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(aia.INVOICE_ID,
                                           aia.INVOICE_AMOUNT,
                                           aia.PAYMENT_STATUS_FLAG,
                                           aia.INVOICE_TYPE_LOOKUP_CODE) STATUT_VALIDATION,
       aia.ATTRIBUTE3 NOM_NUMERISATION_FACTURE,
     (SELECT apt.name
          FROM ap_terms_tl apt
         WHERE apt.term_id = aia.terms_id AND apt.language = 'F') TERMS_NAME,

       --aia.payment_method_code TERMS_NAME,

       DECODE(aia.attribute9, 'DSP', 'Y', 'N') DSP_PO_FLIP,
       DECODE(aia.attribute9,
              'DSP',
              decode(instr(aia.attribute10, 'INV'),
                     0,
                     decode(instr(aia.attribute10, 'CRE'),
                            0,
                            '',
                            substr(aia.attribute10,
                                   instr(aia.attribute10, 'CRE'),
                                   9)),
                     substr(aia.attribute10, instr(aia.attribute10, 'INV'), 9)),
              '') ID_FACTURE_IVALUA,
       DECODE(aia.PAY_GROUP_LOOKUP_CODE, 'PMTDIR', 'Y', 'N') PAIEMENT_DIRECT,
       aia.TERMS_ID TERMS_ID,
       --apt.name PAYMENT_TERMS_NAME,
       /*DECODE(apps.ap_invoices_pkg.get_approval_status(aia.invoice_id,
                                                       aia.invoice_amount,
                                                       aia.payment_status_flag,
                                                       aia.invoice_type_lookup_code),
              'FULL',
              'entièrement appliqué',
              'UNAPPROVED',
              'non validé',
              'NEEDS REAPPROVAL',
              'Nécessite une revalidation',
              'APPROVED',
              'Validé',
              'NEVER APPROVED',
              'Jamais validé',
              'CANCELLED',
              'Annulé',
              'UNPAID',
              'Non payé',
              'AVAILABLE',
              'Disponible') STATUT_VALIDATION_FACTURE,*/
       decode(aia.Payment_Status_Flag,
              'Y',
              'Fully paid',
              'P',
              'Partially Paid',
              'N',
              'Unpaid') STATUT_REGLEMENT_FACTURE,
       aia.last_update_date DERNIERE_MODIF_FACTURE
  from AP_INVOICES_ALL aia, ap_terms apt, hr_organization_units hou
 where aia.ORG_ID = hou.organization_id
   and apt.term_id = aia.TERMS_ID
   and aia.INVOICE_TYPE_LOOKUP_CODE <> 'EXPENSE REPORT'
   and (((aia.creation_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS') or  aia.last_update_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS')) and vn_date_pivot_fin is null)
   OR (aia.creation_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS') and vn_date_pivot_fin is not null and aia.creation_date <= to_date(vn_date_pivot_fin , 'DD/MM/YYYY HH24:MI:SS')));
   --and (aia.creation_date >= to_date(vn_date_pivot,'DD/MM/YYYY') or aia.last_update_date >= to_date(vn_date_pivot,'DD/MM/YYYY'));


    ------------------------------------------------------------------
    -- Curseur de lecture des lignes de la table  --
    ------------------------------------------------------------------
    CURSOR cur_fichier_entete IS
      SELECT
     /* 1*/
    DEC.ID_FACTURE                                                || ';' ||
     /* 2*/
      '"'||DEC.NUMERO_FACTURE||'"'                                           || ';' ||
     /* 3*/
      '"'||DEC.UNITE_OPERATIONNELLE||'"'                                     || ';' ||
     /* 4*/
      '"'||DEC.TYPE_DOCUMENT||'"'                                             || ';' ||
     /* 5*/
      '"'||DEC.DEVISE||'"'                                                   || ';' ||
     /* 6*/
      REPLACE(to_char(DEC.MONTANT_FACTURE_TTC), '.', ',')            || ';' ||
    /* 7*/
    REPLACE(to_char(DEC.MONTANT_FACTURE_TAX), '.', ',')            || ';' ||
     /* 8*/
     TO_CHAR(DEC.in_DATE, 'DD/MM/YYYY')                                            || ';' ||
     /* 9*/
      '"'||DEC.MODE_REGLEMENT||'"'                                            || ';' ||
     /* 10*/
      REPLACE(to_char(DEC.MONTANT_PAYE), '.', ',')                  || ';' ||
     /* 11*/
      '"'||DEC.SOURCE||'"'                                                   || ';' ||
     /* 12*/
      '"'||DEC.DESCRIPTION||'"'                                              || ';' ligne1,
     /* 13*/
      DEC.IDENTIFIANT_EN_TETE_FACTOR                                || ';' ||
     /* 14*/
      '"'||DEC.NOM_FACTOR||'"'                                                || ';' ||
     /* 15*/
      '"'||DEC.SITE_FACTOR||'"'                                               || ';' ||
     /* 16*/
      DEC.ID_SITE_FACTOR                                            || ';' ||
     /* 17*/
      DEC.ID_COMPTE_BANCAIRE                                        || ';' ||
     /* 18*/
      '"'||DEC.STATUT_APPROBATION||'"'                                       || ';' ||
     /* 19*/
      REPLACE(to_char(DEC.MONTANT_ANNULE), '.', ',')                || ';' ||
     /* 20*/
      DEC.ID_TECHNIQUE                                              || ';' ||
     /* 21*/
      TO_CHAR(DEC.DATE_ANNULATION, 'DD/MM/YYYY')                             || ';' ||
     /* 22*/
      '"'||DEC.DEVISE_PAIEMENT||'"'                                           || ';' ||
     /* 23*/
      '"'||DEC.CLASSE_REGLEMENT||'"'                                          || ';' ||
     /* 24*/
      DEC.ID_ENTETE_FOURNISSEUR                                     || ';'ligne2,
     /* 25*/
      DEC.ID_SITE_FOURNISSEUR                                       || ';' ||
     /* 26*/
      DEC.ID_COMPTABLE                                              || ';' ||
     /* 27*/
      '"'||DEC.FOLIO||'"'                                                    || ';' ||
     /* 28*/
      TO_CHAR(DEC.DATE_GL, 'DD/MM/YYYY')                            || ';' ||
     /* 29*/
      DEC.ID_GL                                                     || ';' ||
     /* 30*/
      DEC.NUMERO_CHRONO                                             || ';' ||
    /* 31*/
    '"'||DEC.UO_FACTURE||'"'                                                  || ';' ||
    /* 32*/
      TO_CHAR(DEC.DATE_CREATION , 'DD/MM/YYYY HH24:MI:SS')                                     || ';' ||
    /* 32*/
      TO_CHAR(DEC.DATE_COMPTABILISATION , 'DD/MM/YYYY')                || ';' ||
    /* 33*/
      '"'||DEC.STATUT_VALIDATION||'"'                                            || ';' ||
    /* 34*/
      '"'||DEC.NOM_NUMERISATION_FACTURE||'"'                                    || ';' ||
    /* 35*/
      '"'||DEC.TERMS_ID||'"'                                                     || ';' ||
    /* 36*/
      '"'||DEC.TERMS_NAME||'"'                                                  || ';' ||
    /* 37*/
      '"'||DEC.DSP_PO_FLIP||'"'                                                  || ';' ||
    /* 38*/
      '"'||DEC.ID_FACTURE_IVALUA||'"'                                            || ';' ||
    /* 39*/
      '"'||DEC.PAIEMENT_DIRECT||'"'                                              || ';' ||
    /* 40*/
      --'"'||DEC.PAYMENT_TERMS_NAME||'"'                                          || ';' ||
    /* 41*/
     -- '"'||DEC.STATUT_VALIDATION_FACTURE||'"'                                   || ';' ||
    /* 42*/
      '"'||DEC.STATUT_REGLEMENT_FACTURE||'"'                                     || ';' ||
    /* 43*/
      TO_CHAR(DEC.DERNIERE_MODIF_FACTURE, 'DD/MM/YYYY HH24:MI:SS')        ligne3
        FROM dka_sextfacture_entete DEC
       WHERE DEC.request_id = fnd_global.conc_request_id;

    rec_fichier_entete cur_fichier_entete%ROWTYPE;

     CURSOR cur_fichier_ligne IS

   select
       /* 1*/
     DEC.NUMERO_LIGNE                         || ';' ||
     /* 2*/
       DEC.ID_FACTURE                           || ';' ||
     /* 3*/
       '"'||DEC.TYPE_LIGNE||'"'                           || ';' ||
     /* 4*/
       DEC.MONTANT_LIGNE                        || ';' ||
     /* 5*/
       DEC.QUANTITE_LIGNE_FACTURE               || ';' ||
     /* 6*/
     replace(ROUND(DEC.PRIX_UNITAIRE , 2), ',', '.')                       || ';' ||
     /* 7*/
       '"'||DEC.CODE_TX_TVA||'"'                          || ';' ||
     /* 8*/
       '"'||DEC.DESCRIPTION_LIGNE||'"'                    || ';' ||
     /* 9*/
       DEC.ID_LIGNE_DITRIBUTION_COMMANDE        || ';' ||
     /* 10*/
       DEC.ID_ENTETE_COMMANDE                   || ';' ||
     /* 11*/
       DEC.ID_LIGNE_COMMANDE                    || ';' ligne1,
     /* 12*/
       DEC.ID_LIGNE_LOCATION_COMMANDE           || ';' ||
     /* 13*/
       '"'||DEC.ID_PROJET_REFAC||'"'                      || ';' ||
     /* 14*/
       '"'||DEC.ID_TACHE_REFAC||'"'                       || ';' ||
     /* 15*/
       --'"'||DEC.LIGNE_ANNULEE||'"'                        || ';' ||
     /* 16*/
       '"'||DEC.LIGNE_ABANDONNEE||'"'                    || ';' ||
     /* 17*/
       TO_CHAR(DEC.DATE_DEPENSE, 'DD/MM/YYYY')                        || ';' ||
     /* 18*/
       '"'||DEC.TYPE_DEPENSE||'"'                         || ';' ||
     /* 19*/
       '"'||DEC.UO||'"'                                   || ';' ||
     /* 20*/
       TO_CHAR(DEC.DATE_GL, 'DD/MM/YYYY')                              || ';' ||
     /* 21*/
       DEC.ID_PF                                || ';' ||
     /* 22*/
       DEC.ID_TF                               || ';' ligne2,
     /* 23*/
       DEC.TAUX_TVA                             || ';' ||
     /* 24*/
     --  ||'"'||DEC.TF_DIST_REFAC||'"'||                        || ';' ||
     /* 25*/
       '"'||DEC.COMPTE_LOCAL||'"'                         || ';' ||
     /* 26*/
       '"'||DEC.DESC_COMPTE_LOCAL||'"'                    || ';' ||
     /* 27*/
       TO_CHAR(DEC.DERNIERE_MODIF_LIGNE_F, 'DD/MM/YYYY HH24:MI:SS')               || ';' ||
     /* 28*/
       '"'||DEC.STATUT_ANN_LIGNE_FACTURE||'"'             || ';' ||
     /* 29*/
       '"'||DEC.COMPTE_ANALYTIQUE||'"'                    || ';' ||
   /* 30*/
       '"'||DEC.DESC_COMPTE_ANALYTIQUE||'"'                    || ';' ||
     /* 31*/
       '"'||DEC.TAXE_JURIDICTION||'"'                     || ';' ||
     /* 32*/
       '"'||DEC.TAXE_REGIME||'"'                         || ';' ||
     /* 33*/
       DEC.ID_LIGNE_ACCOMPTE                    || ';' ||
     /* 34*/
       DEC.LIGNE_ACOMPTE                        ligne3
    FROM dka_sextfacture_ligne DEC
       WHERE DEC.request_id = fnd_global.conc_request_id;


    rec_fichier_ligne cur_fichier_ligne%ROWTYPE;

     CURSOR cur_fichier_regl IS

     select
     /* 1*/
     DEC.ID_FACTURE               || ';' ||
     /* 2*/
       DEC.ID_REGLEMENT            || ';' ||
     /* 3*/
       DEC.ID_COMPTE               || ';' ||
     /* 4*/
      '"'||DEC.NOM_COMPTE||'"'              || ';' ||
     /* 5*/
       '"'||DEC.NUMERO_COMPTE||'"'           || ';' ||
     /* 6*/
       '"'||DEC.CHECKRUN_NAME||'"'           || ';'ligne1,
     /* 7*/
       TO_CHAR(DEC.DATE_REGLEMENT, 'DD/MM/YYYY')          || ';' ||
     /* 8*/
       DEC.NUMERO_REGLEMENT        || ';' ||
     /* 9*/
       '"'||DEC.IBAN||'"'                    || ';' ||
     /* 10*/
       '"'||DEC.UO||'"'                      || ';' ||
     /* 11*/
       '"'||DEC.MODE_REGLEMENT||'"'          || ';' ||
   /* 11*/
       '"'||DEC.MONTANT_REGLEMENT||'"'          || ';' ||
   /* 11*/
       '"'||TO_CHAR(DEC.DATE_CREATION_REGLEMENT, 'DD/MM/YYYY HH24:MI:SS')||'"'          || ';' ||
     /* 12*/
       '"'||DEC.ID_ENTETE_FACTOR||'"'        || ';'ligne2,
     /* 13*/
       '"'||DEC.NOM_FACTOR||'"'              || ';' ||
     /* 14*/
       '"'||DEC.NOM_SITE_FACTOR||'"'         || ';' ||
     /* 15*/
       DEC.ID_SITE_FACTOR          || ';' ||
     /* 16*/
       DEC.ID_ENTETE_FOURNISSEUR   || ';' ||
     /* 17*/
       '"'||DEC.ID_SITE_FOURNISSEUR||'"'     || ';' ||
     /* 18*/
       TO_CHAR(DEC.DATE_ANNULATION, 'DD/MM/YYYY')       ligne3
     FROM dka_sextreglement DEC
       WHERE DEC.request_id = fnd_global.conc_request_id;


    rec_fichier_regl cur_fichier_regl%ROWTYPE;

    cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';
    vv_buffer      VARCHAR2(4000);
    vn_buffer_size PLS_INTEGER;

  vv_buffer_L      VARCHAR2(4000);
    vn_buffer_size_L PLS_INTEGER;

  vv_buffer_R      VARCHAR2(4000);
    vn_buffer_size_R PLS_INTEGER;

    vv_requested_by VARCHAR2(100);
    vn_org_id       NUMBER;


    va_file_id utl_file.file_type;

    vv_filename VARCHAR2(80);

   va_file_id_L utl_file.file_type;

    vv_filename_L VARCHAR2(80);

   va_file_id_R utl_file.file_type;

    vv_filename_R VARCHAR2(80);

    vv_directory_name dba_directories.directory_path%TYPE;
    vv_period_name    VARCHAR2(60);
    vv_end_date       VARCHAR2(10);
  BEGIN

    pv_errbuf  := NULL;
    pn_retcode := 0;

    dka_tools_pkg.put_debug_message('==> Début du traitement');
       BEGIN
    select  varchar2_value
      into vn_date_pivot
      from dka_parameters
         WHERE program_code = 'DKA_SAPEXTDATAFACT'
           AND parameter_name = 'Last_ExtFact_Date';

  select  varchar2_value
    into vn_date_pivot_fin
    from dka_parameters
   WHERE program_code = 'DKA_SAPEXTDATAFACT'
     AND parameter_name = 'Last_ExtFact_Date_Fin';

    EXCEPTION
      WHEN OTHERS THEN
        l_message  := 'erreur lors de la recuperation de parametre de derniere mise a jour';
        pn_retcode := 2;

    END;
    --------------------------------------------------------------
    -- Suppression des données de tous les traitements terminés --
    --------------------------------------------------------------
    dka_tools_pkg.put_debug_message('Suppression des données des traitements précédents');

    DELETE FROM dka_sextfacture_entete DEC
     WHERE EXISTS
     (SELECT 'X'
              FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
             WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
               AND fcr.phase_code = 'C'
               AND fcp.concurrent_program_name =
                   'DKA_SAPEXTDATAFACT'
               AND fcr.request_id = DEC.request_id);

    dka_tools_pkg.put_debug_message('==> ' || SQL%ROWCOUNT ||
                                    ' enregistrements supprimés');

    COMMIT;

  DELETE FROM dka_sextfacture_ligne DEC
     WHERE EXISTS
     (SELECT 'X'
              FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
             WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
               AND fcr.phase_code = 'C'
               AND fcp.concurrent_program_name =
                   'DKA_SAPEXTDATAFACT'
               AND fcr.request_id = DEC.request_id);

    dka_tools_pkg.put_debug_message('==> ' || SQL%ROWCOUNT ||
                                    ' enregistrements supprimés');

    COMMIT;

  DELETE FROM dka_sextreglement DEC
     WHERE EXISTS
     (SELECT 'X'
              FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
             WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
               AND fcr.phase_code = 'C'
               AND fcp.concurrent_program_name =
                   'DKA_SAPEXTDATAFACT'
               AND fcr.request_id = DEC.request_id);

    dka_tools_pkg.put_debug_message('==> ' || SQL%ROWCOUNT ||
                                    ' enregistrements supprimés');

    COMMIT;

    -------------------------------------------------------------------
    -- Recherche de la période en fonction de la date en entrée      --
    -------------------------------------------------------------------


    -----------------------------
    -- Traitement des factures --
    -----------------------------
    dka_tools_pkg.put_debug_message('Traitement des factures');

    -- Extraction des donnees


    for rec_factures in  cur_factures_entete   loop

        is_found_rec := true;

              dka_tools_pkg.put_log_message('insertion facture : ' ||
                                              rec_factures.NUMERO_FACTURE);
              ------------------------------------------------
              -- Insertion dans la table dka_sextfacture_entete --
              ------------------------------------------------
        BEGIN


              INSERT INTO dka_sextfacture_entete
                (request_id                       ,
                 ID_FACTURE                       ,
                 NUMERO_FACTURE                   ,
                 UNITE_OPERATIONNELLE             ,
                 TYPE_DOCUMENT                    ,
                 DEVISE                           ,
                 MONTANT_FACTURE_TTC              ,
                 MONTANT_FACTURE_TAX              ,
                 in_DATE                          ,
                 MODE_REGLEMENT                   ,
                 MONTANT_PAYE                     ,
                 SOURCE                           ,
                 DESCRIPTION                      ,
                 IDENTIFIANT_EN_TETE_FACTOR       ,
                 NOM_FACTOR                       ,
                 SITE_FACTOR                      ,
                 ID_SITE_FACTOR                   ,
                 ID_COMPTE_BANCAIRE               ,
                 STATUT_APPROBATION               ,
                 MONTANT_ANNULE                   ,
                 ID_TECHNIQUE                     ,
                 DATE_ANNULATION                  ,
                 DEVISE_PAIEMENT                  ,
                 CLASSE_REGLEMENT                 ,
                 ID_ENTETE_FOURNISSEUR            ,
                 ID_SITE_FOURNISSEUR              ,
                 ID_COMPTABLE                     ,
                 FOLIO                            ,
                 DATE_GL                          ,
                 ID_GL                            ,
                 NUMERO_CHRONO                    ,
                 UO_FACTURE                       ,
                 DATE_CREATION                    ,
                 DATE_COMPTABILISATION            ,
                 STATUT_VALIDATION                ,
                 NOM_NUMERISATION_FACTURE         ,
                 TERMS_ID                         ,
                 TERMS_NAME                       ,
                 DSP_PO_FLIP                      ,
                 ID_FACTURE_IVALUA                ,
                 PAIEMENT_DIRECT                  ,
                 --PAYMENT_TERMS_NAME               ,
                 --STATUT_VALIDATION_FACTURE        ,
                 STATUT_REGLEMENT_FACTURE         ,
                 DERNIERE_MODIF_FACTURE

         )
              VALUES
                (fnd_global.conc_request_id,
         rec_factures.ID_FACTURE                       ,
                 rec_factures.NUMERO_FACTURE                   ,
                 rec_factures.UNITE_OPERATIONNELLE             ,
                 rec_factures.TYPE_DOCUMENT                    ,
                 rec_factures.DEVISE                           ,
                 rec_factures.MONTANT_FACTURE_TTC              ,
                 rec_factures.MONTANT_FACTURE_TAX              ,
                 rec_factures.in_DATE                          ,
                 rec_factures.MODE_REGLEMENT                   ,
                 rec_factures.MONTANT_PAYE                     ,
                 rec_factures.SOURCE                           ,
                 rec_factures.DESCRIPTION                      ,
                 rec_factures.IDENTIFIANT_EN_TETE_FACTOR       ,
                 rec_factures.NOM_FACTOR                       ,
                 rec_factures.SITE_FACTOR                      ,
                 rec_factures.ID_SITE_FACTOR                   ,
                 rec_factures.ID_COMPTE_BANCAIRE               ,
                 rec_factures.STATUT_APPROBATION               ,
                 rec_factures.MONTANT_ANNULE                   ,
                 rec_factures.ID_TECHNIQUE                     ,
                 rec_factures.DATE_ANNULATION                  ,
                 rec_factures.DEVISE_PAIEMENT                  ,
                 rec_factures.CLASSE_REGLEMENT                 ,
                 rec_factures.ID_ENTETE_FOURNISSEUR            ,
                 rec_factures.ID_SITE_FOURNISSEUR              ,
                 rec_factures.ID_COMPTABLE                     ,
                 rec_factures.FOLIO                            ,
                 rec_factures.DATE_GL                          ,
                 rec_factures.ID_GL                            ,
                 rec_factures.NUMERO_CHRONO                    ,
                 rec_factures.UO_FACTURE                       ,
                 rec_factures.DATE_CREATION                    ,
                 rec_factures.DATE_COMPTABILISATION            ,
                 rec_factures.STATUT_VALIDATION                ,
                 rec_factures.NOM_NUMERISATION_FACTURE         ,
                 rec_factures.TERMS_ID                         ,
                 rec_factures.TERMS_NAME                       ,
                 rec_factures.DSP_PO_FLIP                      ,
                 rec_factures.ID_FACTURE_IVALUA                ,
                 rec_factures.PAIEMENT_DIRECT                  ,
                 --rec_factures.PAYMENT_TERMS_NAME               ,
                 --rec_factures.STATUT_VALIDATION_FACTURE        ,
                 rec_factures.STATUT_REGLEMENT_FACTURE         ,
                 rec_factures.DERNIERE_MODIF_FACTURE


         );
     EXCEPTION
         WHEN OTHERS THEN
       pv_errbuf  := 'Erreur dans insert dans dka_sextfacture_entete : ' || SQLERRM;
           dka_tools_pkg.put_log_message(pv_errbuf);
       pn_retcode := 2;
         END;
           commit;

     BEGIN

     dka_tools_pkg.put_log_message('ID_FACTURE : ' || rec_factures.ID_FACTURE);

     INSERT INTO dka_sextfacture_ligne
     (  request_id               ,
    NUMERO_LIGNE                   ,
    ID_FACTURE                     ,
    TYPE_LIGNE                     ,
    MONTANT_LIGNE                  ,
    QUANTITE_LIGNE_FACTURE         ,
    PRIX_UNITAIRE                  ,
    CODE_TX_TVA                    ,
    DESCRIPTION_LIGNE              ,
    ID_LIGNE_DITRIBUTION_COMMANDE  ,
    ID_ENTETE_COMMANDE             ,
    ID_LIGNE_COMMANDE              ,
    ID_LIGNE_LOCATION_COMMANDE     ,
    ID_PROJET_REFAC                ,
    ID_TACHE_REFAC                 ,
    LIGNE_ABANDONNEE               ,
    DATE_DEPENSE                   ,
    TYPE_DEPENSE                   ,
    UO                             ,
    DATE_GL                        ,
    ID_PF                          ,
    ID_TF                          ,
    TAUX_TVA                       ,
    COMPTE_LOCAL                   ,
    DESC_COMPTE_LOCAL              ,
    DERNIERE_MODIF_LIGNE_F         ,
    STATUT_ANN_LIGNE_FACTURE       ,
    COMPTE_ANALYTIQUE              ,
    DESC_COMPTE_ANALYTIQUE         ,
    TAXE_JURIDICTION               ,
    TAXE_REGIME                    ,
    ID_LIGNE_ACCOMPTE              ,
    LIGNE_ACOMPTE
          )
     select   distinct  fnd_global.conc_request_id request_id,
                aila.LINE_NUMBER NUMERO_LIGNE,
                aila.INVOICE_ID ID_FACTURE,
                aila.LINE_TYPE_LOOKUP_CODE TYPE_LIGNE,
                aila.AMOUNT MONTANT_LIGNE,
                aila.QUANTITY_INVOICED QUANTITE_LIGNE_FACTURE,
                aila.UNIT_PRICE PRIX_UNITAIRE,
                aila.TAX_RATE_CODE CODE_TX_TVA,
        replace(replace(replace(replace(aila.DESCRIPTION,CHR(13),' '),CHR(10),' '),';',' ') ,'"','')  DESCRIPTION_LIGNE,
        aila.PO_DISTRIBUTION_ID ID_LIGNE_DITRIBUTION_COMMANDE,
                aila.PO_HEADER_ID ID_ENTETE_COMMANDE,
                aila.PO_LINE_ID ID_LIGNE_COMMANDE,
                aila.PO_LINE_LOCATION_ID ID_LIGNE_LOCATION_COMMANDE,
        (
        select segment1
        from pa_projects_all
        where project_id = aila.ATTRIBUTE1
        ) ID_PROJET_REFAC,
        (
        select task_number
        from pa_tasks
        where task_id = aila.ATTRIBUTE7
        ) ID_TACHE_REFAC,
                --aila.ATTRIBUTE1 ID_PROJET_REFAC,
                --aila.ATTRIBUTE7 ID_TACHE_REFAC,
                aila.DISCARDED_FLAG LIGNE_ABANDONNEE,
                aila.EXPENDITURE_ITEM_DATE DATE_DEPENSE,
                aila.EXPENDITURE_TYPE TYPE_DEPENSE,
                aila.org_id UO,
                aila.ACCOUNTING_DATE DATE_GL,
                (
        select segment1
        from pa_projects_all
        where project_id = aila.PROJECT_ID
        ) ID_PF,
        (
        select task_number
        from pa_tasks
        where task_id = aila.TASK_ID
        ) ID_TF,
        --aila.PROJECT_ID ID_PF,
                --aila.TASK_ID ID_TF,
                aila.TAX_RATE TAUX_TVA,
                gcc.segment3 COMPTE_LOCAL,
                /*DECODE(GCC.SEGMENT3,
                       NULL,
                       '',
                       SUBSTR(APPS.GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL(GCC.CHART_OF_ACCOUNTS_ID,
                                                                         3,
                                                                         GCC.SEGMENT3),
                              1,
                              40)) DESC_COMPTE_LOCAL,*/
        (SELECT ffvv.description
          FROM fnd_flex_value_sets  ffvs
             JOIN fnd_flex_values_vl ffvv
               ON     ffvs.flex_value_set_id = ffvv.flex_value_set_id
                AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
         WHERE 1 = 1 AND ffvv.flex_value = gcc.segment3) DESC_COMPTE_LOCAL,

                aila.last_update_date DERNIERE_MODIF_LIGNE_F,
                decode(NVL(aila.CANCELLED_FLAG,'N'),
                       'N',
                       'Non annulé',
                       'Y',
                       'Annulé') STATUT_ANN_LIGNE_FACTURE,
                gcc.segment4 COMPTE_ANALYTIQUE,

        (SELECT ffvv.description
          FROM fnd_flex_value_sets  ffvs
             JOIN fnd_flex_values_vl ffvv
               ON     ffvs.flex_value_set_id = ffvv.flex_value_set_id
                AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
         WHERE 1 = 1 AND ffvv.flex_value = gcc.segment4) DESC_COMPTE_ANALYTIQUE,


                aila.TAX_JURISDICTION_CODE TAXE_JURIDICTION,
                aila.TAX_REGIME_CODE TAXE_REGIME,
                aila.PREPAY_INVOICE_ID ID_LIGNE_ACCOMPTE,
                aila.PREPAY_LINE_NUMBER LIGNE_ACOMPTE
      from AP_INVOICE_LINES_ALL         aila,
             hr_organization_units        hou,
             gl_code_combinations         gcc,
             AP_INVOICE_DISTRIBUTIONS_all aida
       where aila.ORG_ID = hou.organization_id
         and aida.INVOICE_ID = aila.INVOICE_ID
         and AIDA.DIST_CODE_COMBINATION_ID = gcc.code_combination_id
         and aida.invoice_line_number = aila.LINE_NUMBER
         --and aida.amount = aila.amount
     and NVL(aila.description, 'A') = NVL(aida.description, 'A')
         and NVL(aila.project_id,0) = NVL(aida.project_id,0)
         and NVL(aila.task_id,0) = NVL(aida.task_id,0)
     and (((aila.creation_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS') or  aila.last_update_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS')) and vn_date_pivot_fin is null)
     OR (aila.creation_date >= to_date(vn_date_pivot , 'DD/MM/YYYY HH24:MI:SS') and vn_date_pivot_fin is not null and aila.creation_date <= to_date(vn_date_pivot_fin , 'DD/MM/YYYY HH24:MI:SS')))
         --and (aila.creation_date >= to_date(vn_date_pivot, 'DD/MM/YYYY') or aila.last_update_date >= to_date(vn_date_pivot, 'DD/MM/YYYY'))
         and aila.invoice_id = rec_factures.ID_FACTURE;
   --AND ROWNUM <=2;
   EXCEPTION
         WHEN NO_DATA_FOUND THEN
            pn_retcode := 1;
         WHEN OTHERS THEN
      pv_errbuf  := 'Erreur dans insert dans dka_sextfacture_ligne : ' || SQLERRM;
           dka_tools_pkg.put_log_message(pv_errbuf);
       pn_retcode := 2;
         END;
     commit;

   BEGIN

     INSERT INTO dka_sextreglement
     (request_id      ,
ID_FACTURE            ,
ID_REGLEMENT          ,
ID_COMPTE             ,
NOM_COMPTE            ,
NUMERO_COMPTE         ,
CHECKRUN_NAME         ,
DATE_REGLEMENT        ,
NUMERO_REGLEMENT      ,
IBAN                  ,
UO                    ,
MODE_REGLEMENT        ,
MONTANT_REGLEMENT     ,
DATE_CREATION_REGLEMENT  ,
ID_ENTETE_FACTOR      ,
NOM_FACTOR            ,
NOM_SITE_FACTOR       ,
ID_SITE_FACTOR        ,
ID_ENTETE_FOURNISSEUR ,
ID_SITE_FOURNISSEUR   ,
DATE_ANNULATION
          )
     select fnd_global.conc_request_id,
         aipa.INVOICE_ID  ID_FACTURE         ,
         aca.CHECK_ID      ID_REGLEMENT                        ,
         aca.BANK_ACCOUNT_ID ID_COMPTE                           ,
         aca.BANK_ACCOUNT_NAME NOM_COMPTE                          ,
         aca.BANK_ACCOUNT_NUM NUMERO_COMPTE                       ,
         aca.CHECKRUN_NAME           ,
         aca.CHECK_DATE DATE_REGLEMENT                      ,
         aca.CHECK_NUMBER NUMERO_REGLEMENT                    ,
         aca.IBAN_NUMBER IBAN                                ,
         aca.org_id UO,--hou.name UO                                  ,
         aca.PAYMENT_METHOD_CODE MODE_REGLEMENT                      ,
     aca.AMOUNT MONTANT_REGLEMENT ,
     aca.CREATION_DATE DATE_CREATION_REGLEMENT ,
         aca.REMIT_TO_SUPPLIER_ID ID_ENTETE_FACTOR                    ,
         aca.REMIT_TO_SUPPLIER_NAME NOM_FACTOR                          ,
         aca.REMIT_TO_SUPPLIER_SITE NOM_SITE_FACTOR                     ,
         aca.REMIT_TO_SUPPLIER_SITE_ID ID_SITE_FACTOR                      ,
         aca.VENDOR_ID ID_ENTETE_FOURNISSEUR               ,
         aca.VENDOR_SITE_ID ID_SITE_FOURNISSEUR                 ,
         aca.VOID_DATE DATE_ANNULATION
         from AP_CHECKS_ALL aca,AP_INVOICE_PAYMENTS_ALL aipa, hr_organization_units hou
         where aca.check_id = aipa.check_id
         and  hou.organization_id = aca.org_id
     and aipa.INVOICE_ID = rec_factures.ID_FACTURE;
     --AND ROWNUM <=2;

   EXCEPTION
          WHEN NO_DATA_FOUND THEN
            pn_retcode := 1;
         WHEN OTHERS THEN
       pv_errbuf  := 'Erreur dans insert dans dka_sextreglement : ' || SQLERRM;
           dka_tools_pkg.put_log_message(pv_errbuf);
       pn_retcode := 2;
         END;

     commit;





    END LOOP;

   BEGIN
    DELETE FROM dka_sextfacture_ligne
    WHERE TYPE_LIGNE = 'TAX'
    AND COMPTE_LOCAL NOT LIKE '4%';
    EXCEPTION
    WHEN OTHERS THEN
      null;
   END;

    COMMIT;

     IF NOT is_found_rec THEN
       pn_retcode:= 1;
       dka_tools_pkg.put_debug_message('Lines non existants ');
   ELSE
     dka_tools_pkg.put_debug_message(' factures insérées dans les trois tables');
   END IF;




    -- Extraction des donnees


      ------------------------
      -- Edition du fichier --
      ------------------------
      dka_tools_pkg.put_debug_message('Edition du fichier');

      vv_filename := 'DKA_EXP_FACTURE_ENTETE_'||TO_CHAR(SYSDATE,'DDMMYYYY-HH24MISS')||'.csv';
      -----------------------------------------
      -- Recherche du fichier de destination --
      -----------------------------------------

    p_file_entete := vv_filename;

      --------------------------------------------------------
      -- Recherche du répertoire de destination du fichier. --
      --------------------------------------------------------
      SELECT dd.directory_path
        INTO vv_directory_name
        FROM dba_directories dd
       WHERE dd.directory_name = 'DKA_OUT_DIR';

      ---------------------------------------------------
      -- Vérifie que le fichier n'est pas déja ouvert. --
      ---------------------------------------------------
      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fermeture du fichier pour l''extraction RA.');
        --------------------------
        -- fermeture du fichier --
        --------------------------
        utl_file.fclose(va_file_id);
        dka_tools_pkg.put_log_message('  fichier fermé');
      END IF;

      -------------------------------------------
      -- Ouverture du fichier en Mode Ecriture --
      -------------------------------------------
      va_file_id := utl_file.fopen(cv_directory, vv_filename, 'w',5000);

      ------------------------------------------------------------
      -- Vérifie que l'on a bien ouvert le fichier en écriture. --
      ------------------------------------------------------------
      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fichier ' || vv_directory_name || '/' ||
                                      vv_filename || ' ouvert en écriture');
      ELSE
        RAISE e_file;
      END IF;

      utl_file.put_line(va_file_id, 'ID_FACTURE;NUMERO_FACTURE;UNITE_OPERATIONNELLE;TYPE_DOCUMENT;DEVISE;MONTANT_FACTURE_TTC;MONTANT_FACTURE_TAX;DATE;MODE_REGLEMENT;MONTANT_PAYE;SOURCE;DESCRIPTION;IDENTIFIANT_EN_TETE_FACTOR;NOM_FACTOR;SITE_FACTOR;ID_SITE_FACTOR;ID_COMPTE_BANCAIRE;STATUT_APPROBATION;MONTANT_ANNULE;ID_TECHNIQUE;DATE_ANNULATION;DEVISE_PAIEMENT;CLASSE_REGLEMENT;ID_ENTETE_FOURNISSEUR;ID_SITE_FOURNISSEUR;ID_COMPTABLE;FOLIO;DATE_GL;ID_GL;NUMERO_CHRONO;UO_FACTURE;DATE_CREATION;DATE_COMPTABILISATION;STATUT_VALIDATION;NOM_NUMERISATION_FACTURE;TERMS_ID;TERMS_NAME;DSP_PO_FLIP;ID_FACTURE_IVALUA;PAIEMENT_DIRECT;STATUT_REGLEMENT_FACTURE;DERNIERE_MODIF_FACTURE;');


      ---------------------------------------------------------------------
      -- Parcours du curseur contenant les différentes lignes a insérer. --
      ---------------------------------------------------------------------
      FOR rec_fichier_entete IN cur_fichier_entete LOOP



        vv_buffer      := rec_fichier_entete.ligne1 || rec_fichier_entete.ligne2 ||
                          rec_fichier_entete.ligne3;


        vn_buffer_size := length(vv_buffer);

        IF vn_buffer_size > 1023 THEN
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          vv_buffer := rec_fichier_entete.ligne1 ||
                       substr(rec_fichier_entete.ligne2,
                              0,
                              length(rec_fichier_entete.ligne2) -
                              (length(vv_buffer) - 1023)) ||
                       rec_fichier_entete.ligne3;

          utl_file.put_line(va_file_id, vv_buffer);


        ELSE
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          utl_file.put_line(va_file_id, vv_buffer);
        END IF;
      END LOOP;

      ---------------------------------------
      -- Fermeture du fichier en écriture. --
      ---------------------------------------
      utl_file.fclose(va_file_id);

    ------------------------------------------------ligne

      ------------------------
      -- Edition du fichier --
      ------------------------
      dka_tools_pkg.put_debug_message('Edition du fichier');

      vv_filename_L := 'DKA_EXP_FACTURE_LIGNE_'||TO_CHAR(SYSDATE,'DDMMYYYY-HH24MISS')||'.csv';


    p_file_line := vv_filename_L;

      -----------------------------------------
      -- Recherche du fichier de destination --
      -----------------------------------------


      --------------------------------------------------------
      -- Recherche du répertoire de destination du fichier. --
      --------------------------------------------------------
      SELECT dd.directory_path
        INTO vv_directory_name
        FROM dba_directories dd
       WHERE dd.directory_name = 'DKA_OUT_DIR';

      ---------------------------------------------------
      -- Vérifie que le fichier n'est pas déja ouvert. --
      ---------------------------------------------------
      IF utl_file.is_open(va_file_id_L) THEN
        dka_tools_pkg.put_log_message('  fermeture du fichier pour l''extraction RA.');
        --------------------------
        -- fermeture du fichier --
        --------------------------
        utl_file.fclose(va_file_id_L);
        dka_tools_pkg.put_log_message('  fichier fermé');
      END IF;

      -------------------------------------------
      -- Ouverture du fichier en Mode Ecriture --
      -------------------------------------------
      va_file_id_L := utl_file.fopen(cv_directory, vv_filename_L, 'w',5000);

      ------------------------------------------------------------
      -- Vérifie que l'on a bien ouvert le fichier en écriture. --
      ------------------------------------------------------------
      IF utl_file.is_open(va_file_id_L) THEN
        dka_tools_pkg.put_log_message('  fichier ' || vv_directory_name || '/' ||
                                      vv_filename_L || ' ouvert en écriture');
      ELSE
        RAISE e_file;
      END IF;

      ---------------------------------------------------------------------
      -- Parcours du curseur contenant les différentes lignes a insérer. --
      ---------------------------------------------------------------------

    utl_file.put_line(va_file_id_L, 'NUMERO_LIGNE;ID_FACTURE;TYPE_LIGNE;MONTANT_LIGNE;QUANTITE_LIGNE_FACTURE;PRIX_UNITAIRE;CODE_TX_TVA;DESCRIPTION_LIGNE;ID_LIGNE_DITRIBUTION_COMMANDE;ID_ENTETE_COMMANDE;ID_LIGNE_COMMANDE;ID_LIGNE_LOCATION_COMMANDE;ID_PROJET_REFAC;ID_TACHE_REFAC;LIGNE_ABANDONNEE;DATE_DEPENSE;TYPE_DEPENSE;UO;DATE_GL;ID_PF;ID_TF;TAUX_TVA;COMPTE_LOCAL;DESC_COMPTE_LOCAL;DERNIERE_MODIF_LIGNE_F;STATUT_ANN_LIGNE_FACTURE;COMPTE_ANALYTIQUE;DESC_COMPTE_ANALYTIQUE;TAXE_JURIDICTION;TAXE_REGIME;ID_LIGNE_ACCOMPTE;LIGNE_ACOMPTE;');


      FOR rec_fichier_ligne IN cur_fichier_ligne LOOP



        vv_buffer_L      := rec_fichier_ligne.ligne1 || rec_fichier_ligne.ligne2 ||
                          rec_fichier_ligne.ligne3;
        vn_buffer_size_L := length(vv_buffer_L);

        IF vn_buffer_size_L > 1023 THEN
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          vv_buffer_L := rec_fichier_ligne.ligne1 ||
                       substr(rec_fichier_ligne.ligne2,
                              0,
                              length(rec_fichier_ligne.ligne2) -
                              (length(vv_buffer_L) - 1023)) ||
                       rec_fichier_ligne.ligne3;

          utl_file.put_line(va_file_id_L, vv_buffer_L);


        ELSE
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          utl_file.put_line(va_file_id_L, vv_buffer_L);
        END IF;
      END LOOP;

      ---------------------------------------
      -- Fermeture du fichier en écriture. --
      ---------------------------------------
      utl_file.fclose(va_file_id_L);




  ----------------------------------------------------

  ----------------------------------------------------reglement


      ------------------------
      -- Edition du fichier --
      ------------------------
      dka_tools_pkg.put_debug_message('Edition du fichier');

      vv_filename_R := 'DKA_EXP_REGLEMENT_'||TO_CHAR(SYSDATE,'DDMMYYYY-HH24MISS')||'.csv';

    p_file_reg := vv_filename_R;

      -----------------------------------------
      -- Recherche du fichier de destination --
      -----------------------------------------


      --------------------------------------------------------
      -- Recherche du répertoire de destination du fichier. --
      --------------------------------------------------------
      SELECT dd.directory_path
        INTO vv_directory_name
        FROM dba_directories dd
       WHERE dd.directory_name = 'DKA_OUT_DIR';

      ---------------------------------------------------
      -- Vérifie que le fichier n'est pas déja ouvert. --
      ---------------------------------------------------
      IF utl_file.is_open(va_file_id_R) THEN
        dka_tools_pkg.put_log_message('  fermeture du fichier pour l''extraction RA.');
        --------------------------
        -- fermeture du fichier --
        --------------------------
        utl_file.fclose(va_file_id_R);
        dka_tools_pkg.put_log_message('  fichier fermé');
      END IF;

      -------------------------------------------
      -- Ouverture du fichier en Mode Ecriture --
      -------------------------------------------
      va_file_id_R := utl_file.fopen(cv_directory, vv_filename_R, 'w',5000);

      ------------------------------------------------------------
      -- Vérifie que l'on a bien ouvert le fichier en écriture. --
      ------------------------------------------------------------
      IF utl_file.is_open(va_file_id_R) THEN
        dka_tools_pkg.put_log_message('  fichier ' || vv_directory_name || '/' ||
                                      vv_filename_R || ' ouvert en écriture');
      ELSE
        RAISE e_file;
      END IF;

      ---------------------------------------------------------------------
      -- Parcours du curseur contenant les différentes lignes a insérer. --
      ---------------------------------------------------------------------

    utl_file.put_line(va_file_id_R, 'ID_FACTURE;ID_REGLEMENT;ID_COMPTE;NOM_COMPTE;NUMERO_COMPTE;CHECKRUN_NAME;DATE_REGLEMENT;NUMERO_REGLEMENT;IBAN;UO;MODE_REGLEMENT;MONTANT_REGLEMENT;DATE_CREATION_REGLEMENT;ID_ENTETE_FACTOR;NOM_FACTOR;NOM_SITE_FACTOR;ID_SITE_FACTOR;ID_ENTETE_FOURNISSEUR;ID_SITE_FOURNISSEUR;DATE_ANNULATION;');

      FOR rec_fichier_regl IN cur_fichier_regl LOOP



        vv_buffer_R      := rec_fichier_regl.ligne1 || rec_fichier_regl.ligne2 ||
                          rec_fichier_regl.ligne3;
        vn_buffer_size_R := length(vv_buffer_R);

        IF vn_buffer_size_R > 1023 THEN
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          vv_buffer_R := rec_fichier_regl.ligne1 ||
                       substr(rec_fichier_regl.ligne2,
                              0,
                              length(rec_fichier_regl.ligne2) -
                              (length(vv_buffer_R) - 1023)) ||
                       rec_fichier_regl.ligne3;

          utl_file.put_line(va_file_id_R, vv_buffer_R);


        ELSE
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          utl_file.put_line(va_file_id_R, vv_buffer_R);
        END IF;
      END LOOP;

      ---------------------------------------
      -- Fermeture du fichier en écriture. --
      ---------------------------------------
      utl_file.fclose(va_file_id_R);


  ----------------------------------------------------------
  dka_tools_pkg.put_debug_message('==> Mise à jour du paramètre Last_ExtFact_Date dans la table dka_parameters');
  -- Mise à jour du paramètre Last_ExtFact_Date dans la table dka_parameters
         UPDATE dka_parameters
         SET varchar2_value = to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')
         WHERE program_code = 'DKA_SAPEXTDATAFACT'
           AND parameter_name = 'Last_ExtFact_Date';

     UPDATE dka_parameters
         SET varchar2_value = null
         WHERE program_code = 'DKA_SAPEXTDATAFACT'
           AND parameter_name = 'Last_ExtFact_Date_Fin';

    commit;
    dka_tools_pkg.put_debug_message('==> Fin du traitement');

  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLCODE || ' - ' || substr(SQLERRM, 1, 80);
      pn_retcode := 2;

  END extraction_datalake;

/*
 *************************************************************************
 * PROCEDURE NAME : main
 *
 * DESCRIPTION
 *  Procédure générale du traitement
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   )
IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  cv_line                     VARCHAR2 (100);
  v_file_entete           VARCHAR2(100);
  v_file_line             VARCHAR2(100);
  v_file_reg            VARCHAR2(100);

BEGIN

      Output_Header;

    extraction_datalake(v_errbuf,v_retcode,v_file_entete,v_file_line,v_file_reg);

    IF v_retcode = 2
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
          RAISE Erreur_Programme;
    ELSIF v_retcode = 1
    THEN
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Il y''a aucune donnée à traiter.');
      Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
    ELSIF v_retcode = 0
    THEN
        Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Date de dernière exécution de l''export : ' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Nom du fichier ENTETES généré : ' || v_file_entete);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Nom du fichier LIGNES généré : ' || v_file_line);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Nom du fichier REGLEMENT généré : ' || v_file_reg);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Fin normale du traitement.');
          Pn_Retcode := v_retcode;
      END IF;

      output_end;

  EXCEPTION
        WHEN Erreur_Programme THEN
            Pn_Retcode   := 2;
            Pv_Errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||' extraction_datalake '||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.LOG, '==> Fin de la procédure '||' extraction_datalake '||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
       WHEN OTHERS
       THEN
           fnd_concurrent.af_rollback;
           Pn_Retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SAPEXTDATAFACT_PKG.' || ' extraction_datalake '||CHR(10)||' A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           Pv_Errbuf := SQLERRM;
END main;

END DKA_SAPEXTDATAFACT_PKG;

/

SHOW ERRORS

EXIT
