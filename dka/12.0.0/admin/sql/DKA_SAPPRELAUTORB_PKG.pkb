CREATE OR REPLACE PACKAGE BODY APPS.dka_sapprelautorb_pkg IS
  --------------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SRBFACTURE_PKG.pkb
  -- Description      : DKA_SRBFACTURE_PKG package body
  -- Auteur           : S.HAHIOUI(Capgemini)
  -- Date de création : 21/10/2019
  -- Doc. associée    :
  -- Commentaire      : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Version Qui Description
  -- ---------- ------- --- --------------------------------------------------------------
  -- 07/05/2021 1.1   NBO Correction suite au retour recette
  -- 17/05/2021 1.1   SHA Correction suite au retour recette
  -- 26/12/2022 1.2   ARA EDB338 - 
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  g_request_id            NUMBER := fnd_global.conc_request_id;
  g_user_id               NUMBER := fnd_profile.value('USER_ID');
  g_lignes_rb_traitees         NUMBER := 0;
  g_lignes_non_mis_a_jour NUMBER := 0;
  g_lignes_mis_a_jour     NUMBER := 0;
  g_lignes_rg_traitees    NUMBER := 0;
  g_lignes_rg_crees       NUMBER := 0;
  g_lignes_rg_non_crees   NUMBER := 0;
  g_lignes_ref_traitees        NUMBER := 0;
  g_lignes_ref_effectuees      NUMBER := 0;
  g_lignes_ref_non_effectuees  NUMBER := 0;
  g_template_reg          VARCHAR2(100) := 'PREL_AUTO_FRN';

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Saloua HA
  -- Date              : 15/01/2021
  -- Remarques         :
  /*============================================================================*/
  PROCEDURE writeout(p_message IN VARCHAR2) IS
    l_procedure VARCHAR2(30) := 'writeout';
    v_etape     VARCHAR2(100);
  BEGIN

    fnd_file.put_line(fnd_file.output, p_message);

  EXCEPTION
    WHEN OTHERS THEN

      fnd_file.put_line(fnd_file.log,
                        '-------------------- ERREUR --------------------');
  END writeout;

  /*
   *************************************************************************
   * PROCEDURE NAME : Report_Bilan
   *
   * DESCRIPTION
   *  Procédure de génération du bilan du traitement d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */
  PROCEDURE Report_Bilan(p_Errbuf IN OUT VARCHAR2, p_retcode IN OUT NUMBER) IS
    vv_message varchar2(1000);
    CURSOR C_RB_NON_AJOUR IS
      select IDENTIFIANT_LIGNE_RB,
             UO_COMPTE_BANCAIRE,
             TYPE_LIGNE_RB,
             NUMERO_FACTURE_RB,
       NUMERO_CPT_FACTURATION_RB,--EDB338
             FOURNISSEUR_RB,
             ID_COMPTE_BANCAIRE,
             NUMERO_COMPTE_INTER,
             MONTANT_RB,
             CODE_DEVISE_RB,
             STATUT_REFERENCE,
             REFERENCE2,
             VENDOR_ID_RB,
             CAUSE_REJET_ALIMENTATION
        from DKA_PREL_AP_RB
       where STATUT_REFERENCE = 'P'
       group by IDENTIFIANT_LIGNE_RB,
                UO_COMPTE_BANCAIRE,
                TYPE_LIGNE_RB,
                NUMERO_FACTURE_RB,
        NUMERO_CPT_FACTURATION_RB,--EDB338
                FOURNISSEUR_RB,
                ID_COMPTE_BANCAIRE,
                NUMERO_COMPTE_INTER,
                MONTANT_RB,
                CODE_DEVISE_RB,
                STATUT_REFERENCE,
                REFERENCE2,
                VENDOR_ID_RB,
                CAUSE_REJET_ALIMENTATION
       order by UO_COMPTE_BANCAIRE, IDENTIFIANT_LIGNE_RB;

  /*CURSOR C_RB_NON_AJOUR_EDF IS
      select IDENTIFIANT_LIGNE_RB,
             UO_COMPTE_BANCAIRE,
             TYPE_LIGNE_RB,
             NUMERO_FACTURE_RB,
       NUMERO_CPT_FACTURATION_RB,--EDB338
             FOURNISSEUR_RB,
             ID_COMPTE_BANCAIRE,
             NUMERO_COMPTE_INTER,
             MONTANT_RB,
             CODE_DEVISE_RB,
             STATUT_REFERENCE,
             REFERENCE2,
             VENDOR_ID_RB,
             CAUSE_REJET_ALIMENTATION
        from DKA_PREL_AP_RB
       where STATUT_REFERENCE = 'P'
     AND NUMERO_CPT_FACTURATION_RB != 'Absence'
     and length(NUMERO_CPT_FACTURATION_RB) = 10
       group by IDENTIFIANT_LIGNE_RB,
                UO_COMPTE_BANCAIRE,
                TYPE_LIGNE_RB,
                NUMERO_FACTURE_RB,
        NUMERO_CPT_FACTURATION_RB,--EDB338
                FOURNISSEUR_RB,
                ID_COMPTE_BANCAIRE,
                NUMERO_COMPTE_INTER,
                MONTANT_RB,
                CODE_DEVISE_RB,
                STATUT_REFERENCE,
                REFERENCE2,
                VENDOR_ID_RB,
                CAUSE_REJET_ALIMENTATION
       order by UO_COMPTE_BANCAIRE, IDENTIFIANT_LIGNE_RB;*/


  CURSOR C_RB_AJOUR IS
      select IDENTIFIANT_LIGNE_RB,
             UO_COMPTE_BANCAIRE,
             TYPE_LIGNE_RB,
             NUMERO_FACTURE_RB,
       NUMERO_CPT_FACTURATION_RB,--EDB338
             FOURNISSEUR_RB,
             ID_COMPTE_BANCAIRE,
             NUMERO_COMPTE_INTER,
             MONTANT_RB,
             CODE_DEVISE_RB,
             STATUT_REFERENCE,
             REFERENCE2,
             VENDOR_ID_RB
        from DKA_PREL_AP_RB
       where STATUT_REFERENCE is NULL
       group by IDENTIFIANT_LIGNE_RB,
                UO_COMPTE_BANCAIRE,
                TYPE_LIGNE_RB,
                NUMERO_FACTURE_RB,
        NUMERO_CPT_FACTURATION_RB,--EDB338
                FOURNISSEUR_RB,
                ID_COMPTE_BANCAIRE,
                NUMERO_COMPTE_INTER,
                MONTANT_RB,
                CODE_DEVISE_RB,
                STATUT_REFERENCE,
                REFERENCE2,
                VENDOR_ID_RB
       order by UO_COMPTE_BANCAIRE, IDENTIFIANT_LIGNE_RB;

  /*CURSOR C_RB_AJOUR_EDF IS
      select IDENTIFIANT_LIGNE_RB,
             UO_COMPTE_BANCAIRE,
             TYPE_LIGNE_RB,
             NUMERO_FACTURE_RB,
       NUMERO_CPT_FACTURATION_RB,--EDB338
             FOURNISSEUR_RB,
             ID_COMPTE_BANCAIRE,
             NUMERO_COMPTE_INTER,
             MONTANT_RB,
             CODE_DEVISE_RB,
             STATUT_REFERENCE,
             REFERENCE2,
             VENDOR_ID_RB
        from DKA_PREL_AP_RB
       where STATUT_REFERENCE is NULL
     AND NUMERO_CPT_FACTURATION_RB != 'Absence'
     and length(NUMERO_CPT_FACTURATION_RB) = 10
       group by IDENTIFIANT_LIGNE_RB,
                UO_COMPTE_BANCAIRE,
                TYPE_LIGNE_RB,
                NUMERO_FACTURE_RB,
        NUMERO_CPT_FACTURATION_RB,--EDB338
                FOURNISSEUR_RB,
                ID_COMPTE_BANCAIRE,
                NUMERO_COMPTE_INTER,
                MONTANT_RB,
                CODE_DEVISE_RB,
                STATUT_REFERENCE,
                REFERENCE2,
                VENDOR_ID_RB
       order by UO_COMPTE_BANCAIRE, IDENTIFIANT_LIGNE_RB;*/
  BEGIN

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan');

    --------------------
    -- Initialisation --
    --------------------

    p_Errbuf  := NULL;
    p_retcode := 0;

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));

    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Total de lignes RB éligibles prises en compte (traitées)       :' ||
                      g_lignes_rb_traitees);
    Dka_Tools_Pkg.put_log_message('   . Total de lignes RB éligibles prises en compte (traitées) :       :' ||
                                  g_lignes_rb_traitees);
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Total de lignes RB éligibles mises à jour                      :' ||
                      g_lignes_mis_a_jour);
    Dka_Tools_Pkg.put_log_message('   . Total de lignes RB éligibles mises à jour                      :' ||
                                  g_lignes_mis_a_jour);
    Dka_Tools_Pkg.put_log_message(' Détail :');
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '--------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'Détail :');
    fnd_file.put_line(fnd_file.OUTPUT, ' ');
    writeout(RPAD('ID Ligne', 10) || RPAD('Type ligne', 10) ||
             RPAD('Num Fact', 15) || RPAD('Num Cpt Fact', 20) || --EDB338
       RPAD('Fournisseur', 20) ||
             RPAD('ID Fournisseur', 20) || RPAD('ID CPT Bancaire', 20) ||
             RPAD('UO', 10) || RPAD('Montant', 10) ||
             RPAD('Code DEVISE', 15) || RPAD('STATUT REFERENCE', 20) ||
             RPAD('Reference2', 10));
    writeout(RPAD('--------', 10) || RPAD('-------------', 10) ||
             RPAD('-----------', 15) || RPAD('-----------', 20) || --EDB338
       RPAD('-----------', 20) ||
             RPAD('-----------', 20) || RPAD('---------------', 20) ||
             RPAD('--', 10) || RPAD('-------', 10) || RPAD('-------', 15) ||
             RPAD('----------------', 20) || RPAD('----------', 10));

    FOR C_AJOUR IN C_RB_AJOUR LOOP
      Dka_Tools_Pkg.put_log_message(' - Identifiant de ligne RB  :' ||
                                    C_AJOUR.IDENTIFIANT_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - Type de ligne RB :' ||
                                    C_AJOUR.TYPE_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    C_AJOUR.NUMERO_FACTURE_RB);
    Dka_Tools_Pkg.put_log_message(' - les numéros de comptes de facturation de ces fournisseurs' ||
                                    C_AJOUR.NUMERO_CPT_FACTURATION_RB); --EDB338
      Dka_Tools_Pkg.put_log_message(' - les fournisseurs' ||
                                    C_AJOUR.FOURNISSEUR_RB);
      Dka_Tools_Pkg.put_log_message(' - vendor_id' || C_AJOUR.VENDOR_ID_RB);
      Dka_Tools_Pkg.put_log_message(' - ID compte bancaire' ||
                                    C_AJOUR.ID_COMPTE_BANCAIRE);
      Dka_Tools_Pkg.put_log_message(' - Numéro du compte bancaire interne' ||
                                    C_AJOUR.NUMERO_COMPTE_INTER);
      Dka_Tools_Pkg.put_log_message(' - le montant ' || C_AJOUR.MONTANT_RB);
      Dka_Tools_Pkg.put_log_message(' - Code devise ' ||
                                    C_AJOUR.CODE_DEVISE_RB);
      Dka_Tools_Pkg.put_log_message(' - Statut de référence ' ||
                                    C_AJOUR.STATUT_REFERENCE);
      Dka_Tools_Pkg.put_log_message(' - Reference2 ' || C_AJOUR.REFERENCE2);
      Dka_Tools_Pkg.put_log_message(' ----------------------------------- ');
      vv_message := RPAD(C_AJOUR.IDENTIFIANT_LIGNE_RB, 10) ||
                    RPAD(C_AJOUR.TYPE_LIGNE_RB, 10) ||
                    RPAD(NVL(C_AJOUR.NUMERO_FACTURE_RB, ' '), 15) ||
          RPAD(NVL(C_AJOUR.NUMERO_CPT_FACTURATION_RB, ' '), 20) || --EDB338
                    RPAD(C_AJOUR.FOURNISSEUR_RB, 20) ||
                    RPAD(NVL(C_AJOUR.VENDOR_ID_RB, 0), 20) ||
                    RPAD(C_AJOUR.ID_COMPTE_BANCAIRE, 20) ||
                    RPAD(C_AJOUR.UO_COMPTE_BANCAIRE, 10) ||
                    RPAD(C_AJOUR.MONTANT_RB, 10) ||
                    RPAD(C_AJOUR.CODE_DEVISE_RB, 15) ||
                    RPAD(NVL(C_AJOUR.STATUT_REFERENCE, ' '), 20) ||
                    RPAD(C_AJOUR.REFERENCE2, 10);
      writeout(vv_message);

    END LOOP;

  /*FOR C_AJOUR_EDF IN C_RB_AJOUR_EDF LOOP
      Dka_Tools_Pkg.put_log_message(' - Identifiant de ligne RB  :' ||
                                    C_AJOUR_EDF.IDENTIFIANT_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - Type de ligne RB :' ||
                                    C_AJOUR_EDF.TYPE_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    C_AJOUR_EDF.NUMERO_FACTURE_RB);
    Dka_Tools_Pkg.put_log_message(' - les numéros de comptes de facturation de ces fournisseurs' ||
                                    C_AJOUR_EDF.NUMERO_CPT_FACTURATION_RB); --EDB338
      Dka_Tools_Pkg.put_log_message(' - les fournisseurs' ||
                                    C_AJOUR_EDF.FOURNISSEUR_RB);
      Dka_Tools_Pkg.put_log_message(' - vendor_id' || C_AJOUR_EDF.VENDOR_ID_RB);
      Dka_Tools_Pkg.put_log_message(' - ID compte bancaire' ||
                                    C_AJOUR_EDF.ID_COMPTE_BANCAIRE);
      Dka_Tools_Pkg.put_log_message(' - Numéro du compte bancaire interne' ||
                                    C_AJOUR_EDF.NUMERO_COMPTE_INTER);
      Dka_Tools_Pkg.put_log_message(' - le montant ' || C_AJOUR_EDF.MONTANT_RB);
      Dka_Tools_Pkg.put_log_message(' - Code devise ' ||
                                    C_AJOUR_EDF.CODE_DEVISE_RB);
      Dka_Tools_Pkg.put_log_message(' - Statut de référence ' ||
                                    C_AJOUR_EDF.STATUT_REFERENCE);
      Dka_Tools_Pkg.put_log_message(' - Reference2 ' || C_AJOUR_EDF.REFERENCE2);
      Dka_Tools_Pkg.put_log_message(' ----------------------------------- ');
      vv_message := RPAD(C_AJOUR_EDF.IDENTIFIANT_LIGNE_RB, 10) ||
                    RPAD(C_AJOUR_EDF.TYPE_LIGNE_RB, 10) ||
                    RPAD(NVL(C_AJOUR_EDF.NUMERO_FACTURE_RB, ' '), 15) ||
          RPAD(NVL(C_AJOUR_EDF.NUMERO_CPT_FACTURATION_RB, ' '), 20) || --EDB338
                    RPAD(C_AJOUR_EDF.FOURNISSEUR_RB, 20) ||
                    RPAD(NVL(C_AJOUR_EDF.VENDOR_ID_RB, 0), 20) ||
                    RPAD(C_AJOUR_EDF.ID_COMPTE_BANCAIRE, 20) ||
                    RPAD(C_AJOUR_EDF.UO_COMPTE_BANCAIRE, 10) ||
                    RPAD(C_AJOUR_EDF.MONTANT_RB, 10) ||
                    RPAD(C_AJOUR_EDF.CODE_DEVISE_RB, 15) ||
                    RPAD(NVL(C_AJOUR_EDF.STATUT_REFERENCE, ' '), 20) ||
                    RPAD(C_AJOUR_EDF.REFERENCE2, 10);
      writeout(vv_message);

    END LOOP;*/

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));

    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Total de lignes RB éligibles non mises à jour                 :' ||
                      g_lignes_non_mis_a_jour);
    Dka_Tools_Pkg.put_log_message('   . Total de lignes RB éligibles non mises à jour  :' ||
                                  g_lignes_non_mis_a_jour);
    Dka_Tools_Pkg.put_log_message(' Détail :');
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '--------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'Détail :');
    fnd_file.put_line(fnd_file.OUTPUT, ' ');
    writeout(RPAD('ID Ligne', 10) || RPAD('Type ligne', 10) ||
             RPAD('Num Fact', 15) || RPAD('Num Cpt Fact', 20) || --EDB338
       RPAD('Fournisseur', 20) ||
             RPAD('ID Fournisseur', 20) || RPAD('ID CPT Bancaire', 20) ||
             RPAD('UO', 10) || RPAD('Montant', 10) ||
             RPAD('Code DEVISE', 15) || RPAD('STATUT REFERENCE', 20) ||
             RPAD('Reference2', 10) || RPAD('Cause rejet', 15));
    writeout(RPAD('--------', 10) || RPAD('-------------', 10) ||
             RPAD('-----------', 15) || RPAD('-----------', 20) || --EDB338
       RPAD('-----------', 20) ||
             RPAD('-----------', 20) || RPAD('---------------', 20) ||
             RPAD('--', 10) || RPAD('-------', 10) || RPAD('-------', 15) ||
             RPAD('----------------', 20) || RPAD('----------', 10) ||
             RPAD('----------', 15));

    FOR C_NON_AJOUR IN C_RB_NON_AJOUR LOOP
      Dka_Tools_Pkg.put_log_message(' - Identifiant de ligne RB  :' ||
                                    C_NON_AJOUR.IDENTIFIANT_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - Type de ligne RB :' ||
                                    C_NON_AJOUR.TYPE_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    C_NON_AJOUR.NUMERO_FACTURE_RB);
    Dka_Tools_Pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    C_NON_AJOUR.NUMERO_CPT_FACTURATION_RB); --EDB338
      Dka_Tools_Pkg.put_log_message(' - les fournisseurs' ||
                                    C_NON_AJOUR.FOURNISSEUR_RB);
      Dka_Tools_Pkg.put_log_message(' - vendor_id' ||
                                    C_NON_AJOUR.VENDOR_ID_RB);
      Dka_Tools_Pkg.put_log_message(' - ID compte bancaire' ||
                                    C_NON_AJOUR.ID_COMPTE_BANCAIRE);
      Dka_Tools_Pkg.put_log_message(' - Numéro du compte bancaire interne' ||
                                    C_NON_AJOUR.NUMERO_COMPTE_INTER);
      Dka_Tools_Pkg.put_log_message(' - le montant ' ||
                                    C_NON_AJOUR.MONTANT_RB);
      Dka_Tools_Pkg.put_log_message(' - Code devise ' ||
                                    C_NON_AJOUR.CODE_DEVISE_RB);
      Dka_Tools_Pkg.put_log_message(' - Statut de référence ' ||
                                    C_NON_AJOUR.STATUT_REFERENCE);
      Dka_Tools_Pkg.put_log_message(' - Reference2 ' ||
                                    C_NON_AJOUR.REFERENCE2);
      Dka_Tools_Pkg.put_log_message(' - Cause du rejet d¿alimentation ' ||
                                    C_NON_AJOUR.CAUSE_REJET_ALIMENTATION);
      Dka_Tools_Pkg.put_log_message(' ----------------------------------- ');
      vv_message := RPAD(C_NON_AJOUR.IDENTIFIANT_LIGNE_RB, 10) ||
                    RPAD(C_NON_AJOUR.TYPE_LIGNE_RB, 10) ||
                    RPAD(NVL(C_NON_AJOUR.NUMERO_FACTURE_RB, ' '), 15) ||
          RPAD(NVL(C_NON_AJOUR.NUMERO_CPT_FACTURATION_RB, ' '), 20) || --EDB338
                    RPAD(C_NON_AJOUR.FOURNISSEUR_RB, 20) ||
                    RPAD(NVL(C_NON_AJOUR.VENDOR_ID_RB, 0), 20) ||
                    RPAD(C_NON_AJOUR.ID_COMPTE_BANCAIRE, 20) ||
                    RPAD(C_NON_AJOUR.UO_COMPTE_BANCAIRE, 10) ||
                    RPAD(C_NON_AJOUR.MONTANT_RB, 10) ||
                    RPAD(C_NON_AJOUR.CODE_DEVISE_RB, 15) ||
                    RPAD(NVL(C_NON_AJOUR.STATUT_REFERENCE, ' '), 20) ||
                    RPAD(NVL(C_NON_AJOUR.REFERENCE2, ' '), 10) ||
                    RPAD(C_NON_AJOUR.CAUSE_REJET_ALIMENTATION, 50);
      writeout(vv_message);
      p_retcode := 1;
    END LOOP;

  /*FOR C_NON_AJOUR_EDF IN C_RB_NON_AJOUR_EDF LOOP
      Dka_Tools_Pkg.put_log_message(' - Identifiant de ligne RB  :' ||
                                    C_NON_AJOUR_EDF.IDENTIFIANT_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - Type de ligne RB :' ||
                                    C_NON_AJOUR_EDF.TYPE_LIGNE_RB);
      Dka_Tools_Pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    C_NON_AJOUR_EDF.NUMERO_FACTURE_RB);
    Dka_Tools_Pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    C_NON_AJOUR_EDF.NUMERO_CPT_FACTURATION_RB); --EDB338
      Dka_Tools_Pkg.put_log_message(' - les fournisseurs' ||
                                    C_NON_AJOUR_EDF.FOURNISSEUR_RB);
      Dka_Tools_Pkg.put_log_message(' - vendor_id' ||
                                    C_NON_AJOUR_EDF.VENDOR_ID_RB);
      Dka_Tools_Pkg.put_log_message(' - ID compte bancaire' ||
                                    C_NON_AJOUR_EDF.ID_COMPTE_BANCAIRE);
      Dka_Tools_Pkg.put_log_message(' - Numéro du compte bancaire interne' ||
                                    C_NON_AJOUR_EDF.NUMERO_COMPTE_INTER);
      Dka_Tools_Pkg.put_log_message(' - le montant ' ||
                                    C_NON_AJOUR_EDF.MONTANT_RB);
      Dka_Tools_Pkg.put_log_message(' - Code devise ' ||
                                    C_NON_AJOUR_EDF.CODE_DEVISE_RB);
      Dka_Tools_Pkg.put_log_message(' - Statut de référence ' ||
                                    C_NON_AJOUR_EDF.STATUT_REFERENCE);
      Dka_Tools_Pkg.put_log_message(' - Reference2 ' ||
                                    C_NON_AJOUR_EDF.REFERENCE2);
      Dka_Tools_Pkg.put_log_message(' - Cause du rejet d¿alimentation ' ||
                                    C_NON_AJOUR_EDF.CAUSE_REJET_ALIMENTATION);
      Dka_Tools_Pkg.put_log_message(' ----------------------------------- ');
      vv_message := RPAD(C_NON_AJOUR_EDF.IDENTIFIANT_LIGNE_RB, 10) ||
                    RPAD(C_NON_AJOUR_EDF.TYPE_LIGNE_RB, 10) ||
                    RPAD(NVL(C_NON_AJOUR_EDF.NUMERO_FACTURE_RB, ' '), 15) ||
          RPAD(NVL(C_NON_AJOUR_EDF.NUMERO_CPT_FACTURATION_RB, ' '), 20) || --EDB338
                    RPAD(C_NON_AJOUR_EDF.FOURNISSEUR_RB, 20) ||
                    RPAD(NVL(C_NON_AJOUR_EDF.VENDOR_ID_RB, 0), 20) ||
                    RPAD(C_NON_AJOUR_EDF.ID_COMPTE_BANCAIRE, 20) ||
                    RPAD(C_NON_AJOUR_EDF.UO_COMPTE_BANCAIRE, 10) ||
                    RPAD(C_NON_AJOUR_EDF.MONTANT_RB, 10) ||
                    RPAD(C_NON_AJOUR_EDF.CODE_DEVISE_RB, 15) ||
                    RPAD(NVL(C_NON_AJOUR_EDF.STATUT_REFERENCE, ' '), 20) ||
                    RPAD(NVL(C_NON_AJOUR_EDF.REFERENCE2, ' '), 10) ||
                    RPAD(C_NON_AJOUR_EDF.CAUSE_REJET_ALIMENTATION, 50);
      writeout(vv_message);
      p_retcode := 1;
    END LOOP;*/

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;

  /*
   *************************************************************************
   * PROCEDURE NAME : Report_Bilan2
   *
   * DESCRIPTION
   *  Procédure de génération du bilan du traitement d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */
  PROCEDURE report_bilan2(p_errbuf IN OUT VARCHAR2, p_retcode IN OUT NUMBER) IS
    vv_message VARCHAR2(2000);
    CURSOR c_rb_non_ajour IS
      SELECT identifiant_ligne_rb,
             type_ligne_rb,
             numero_facture_rb,
       NUMERO_CPT_FACTURATION_RB, --EDB338
             fournisseur_rb,
             id_compte_bancaire,
             numero_compte_inter,
             uo_compte_bancaire,
             montant_rb,
             code_devise_rb,
             statut_identification,
             statut_reference,
             reference2,
             vendor_id_rb,
             id_facture_ap,
             facture_ap,
             fournisseur_ap,
             vendor_id_ap,
             montant,
             uo_ap,
             id_modele_reglement,
             modele_reglement,
             causes_rejet_maj_echeancier,
             cause_rejet_alimentation
        FROM DKA_PREL_AP_RB
       WHERE statut_reference in ('R', 'P')
         AND g_lignes_non_mis_a_jour IS NOT NULL
       GROUP BY identifiant_ligne_rb,
                type_ligne_rb,
                numero_facture_rb,
        NUMERO_CPT_FACTURATION_RB, --EDB338
                fournisseur_rb,
                id_compte_bancaire,
                numero_compte_inter,
                uo_compte_bancaire,
                montant_rb,
                code_devise_rb,
                statut_identification,
                statut_reference,
                reference2,
                vendor_id_rb,
                id_facture_ap,
                facture_ap,
                fournisseur_ap,
                vendor_id_ap,
                montant,
                uo_ap,
                id_modele_reglement,
                modele_reglement,
                causes_rejet_maj_echeancier,
                cause_rejet_alimentation
        
        
       ORDER BY uo_compte_bancaire, identifiant_ligne_rb

      ;

    CURSOR c_rb_ajour IS
      SELECT identifiant_ligne_rb,
             type_ligne_rb,
             numero_facture_rb,
       NUMERO_CPT_FACTURATION_RB, --EDB338
             fournisseur_rb,
             id_compte_bancaire,
             numero_compte_inter,
             uo_compte_bancaire,
             montant_rb,
             code_devise_rb,
             statut_identification,
             statut_reference,
             reference2,
             vendor_id_rb,
             id_facture_ap,
             facture_ap,
             uo_ap,
             fournisseur_ap,
             vendor_id_ap,
             montant,
             id_modele_reglement,
             modele_reglement
        FROM DKA_PREL_AP_RB
       WHERE statut_reference = 'A'
         AND g_lignes_mis_a_jour IS NOT NULL
     AND STATUT_ETAPE = 'E2'
       GROUP BY identifiant_ligne_rb,
                type_ligne_rb,
                numero_facture_rb,
        NUMERO_CPT_FACTURATION_RB, --EDB338
                fournisseur_rb,
                id_compte_bancaire,
                numero_compte_inter,
                uo_compte_bancaire,
                montant_rb,
                code_devise_rb,
                statut_identification,
                statut_reference,
                reference2,
                vendor_id_rb,
                id_facture_ap,
                facture_ap,
                fournisseur_ap,
                vendor_id_ap,
                montant,
                uo_ap,
                id_modele_reglement,
                modele_reglement
       ORDER BY uo_compte_bancaire, identifiant_ligne_rb;
  BEGIN
    --g_lignes_non_mis_a_jour := g_lignes_rb_traitées - g_lignes_mis_a_jour ;
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan');

    --------------------
    -- Initialisation --
    --------------------

    fnd_file.put_line(fnd_file.output, chr(10));

    fnd_file.put_line(fnd_file.output,
                      '   . Total de lignes RB prises en compte (traitées) :' ||
                      g_lignes_rb_traitees);
    dka_tools_pkg.put_log_message('   . Total de lignes RB prises en compte (traitées)   :' ||
                                  g_lignes_rb_traitees);
    fnd_file.put_line(fnd_file.output,
                      '   . Total de lignes RB identifiées  :' ||
                      g_lignes_mis_a_jour);
    dka_tools_pkg.put_log_message('   . Total de lignes RB identifiées :' ||
                                  g_lignes_mis_a_jour);
    dka_tools_pkg.put_log_message(' Détail :');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      '--------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'Détail :');
    fnd_file.put_line(fnd_file.output, ' ');

    writeout(rpad('ID Ligne RB', 15) || rpad('Type ligne', 15) ||
             rpad('Num Fact', 15) || RPAD('Num Cpt Fact', 20) || --EDB338
       rpad('Fournisseur', 20) ||
             rpad('ID Fournisseur', 20) || rpad('ID CPT Bancaire', 20) ||
             rpad('NUM CPT Bancaire', 20) || rpad('UO RB', 10) ||
             rpad('Montant RB', 12) || rpad('Code DEVISE', 15) ||
             rpad('STATUT REFERENCE', 20) || rpad('ID FACTURE', 15) ||
             rpad('Num Fact AP', 15) || rpad('Fournisseur AP', 20) ||
             rpad('UO', 10) || rpad('Montant', 10) ||
             rpad('STATUT IDENTIFICATION', 22) ||
             rpad('MODELE REGLEMENT', 25) ||
             rpad('ID MODELE REGLEMENT', 20));
    writeout(rpad('-----------', 15) || rpad('----------', 15) ||
             rpad('--------', 15) || rpad('-----------', 20) || --EDB338
       rpad('-----------', 20) ||
             rpad('--------------', 20) || rpad('---------------', 20) ||
             rpad('----------------', 20) || rpad('-----', 10) ||
             rpad('----------', 12) || rpad('-----------', 15) ||
             rpad('----------------', 20) || rpad('----------', 15) ||
             rpad('-----------', 15) || rpad('--------------', 20) ||
             rpad('--', 10) || rpad('-------', 10) ||
             rpad('------------------', 22) ||
             rpad('----------------', 25) ||
             rpad('-------------------', 20));

    FOR c_ajour IN c_rb_ajour LOOP
      dka_tools_pkg.put_log_message(' - Identifiant de ligne RB  :' ||
                                    c_ajour.identifiant_ligne_rb);
      dka_tools_pkg.put_log_message(' - Type de ligne RB :' ||
                                    c_ajour.type_ligne_rb);
      dka_tools_pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    c_ajour.numero_facture_rb);
    dka_tools_pkg.put_log_message(' - les numéros de comptes de facturation de ces fournisseurs' ||
                                    c_ajour.NUMERO_CPT_FACTURATION_RB); --EDB338
      dka_tools_pkg.put_log_message(' - les fournisseurs' ||
                                    c_ajour.fournisseur_rb);
      dka_tools_pkg.put_log_message(' - vendor_id' || c_ajour.vendor_id_rb);
      dka_tools_pkg.put_log_message(' - ID compte bancaire' ||
                                    c_ajour.id_compte_bancaire);
      dka_tools_pkg.put_log_message(' - Numéro du compte bancaire interne' ||
                                    c_ajour.numero_compte_inter);
      dka_tools_pkg.put_log_message(' - le montant ' || c_ajour.montant_rb);
      dka_tools_pkg.put_log_message(' - Code devise ' ||
                                    c_ajour.code_devise_rb);
      dka_tools_pkg.put_log_message(' - ID Facture AP ' ||
                                    c_ajour.id_facture_ap);
      dka_tools_pkg.put_log_message(' - Reference2 ' || c_ajour.reference2);
      dka_tools_pkg.put_log_message(' - Numéro de facture AP ' ||
                                    c_ajour.facture_ap);
      dka_tools_pkg.put_log_message(' - fournisseur de facture AP ' ||
                                    c_ajour.fournisseur_ap);
      dka_tools_pkg.put_log_message(' - Vendor_id_ap ' ||
                                    c_ajour.vendor_id_ap);
      dka_tools_pkg.put_log_message(' - Montant  ' || c_ajour.montant);
      dka_tools_pkg.put_log_message(' - ID modèle de règlement ' ||
                                    c_ajour.id_modele_reglement);
      dka_tools_pkg.put_log_message(' - Modèle de règlement' ||
                                    c_ajour.modele_reglement);
      dka_tools_pkg.put_log_message(' - Statut d''identification ' ||
                                    c_ajour.statut_identification);
      dka_tools_pkg.put_log_message(' ----------------------------------- ');
      vv_message := rpad(c_ajour.identifiant_ligne_rb, 15) ||
                    rpad(c_ajour.type_ligne_rb, 15) ||
                    rpad(nvl(c_ajour.numero_facture_rb, ' '), 15) ||
          rpad(nvl(c_ajour.NUMERO_CPT_FACTURATION_RB, ' '), 20) || --EDB338
                    rpad(c_ajour.fournisseur_rb, 20) ||
                    rpad(nvl(c_ajour.vendor_id_rb, 0), 20) ||
                    rpad(c_ajour.id_compte_bancaire, 20) ||
                    rpad(c_ajour.numero_compte_inter, 20) ||
                    rpad(c_ajour.uo_compte_bancaire, 10) ||
                    rpad(c_ajour.montant_rb, 12) ||
                    rpad(c_ajour.code_devise_rb, 15) ||
                    rpad(nvl(c_ajour.statut_reference, ' '), 20) ||
                    rpad(c_ajour.id_facture_ap, 15) ||
                    rpad(nvl(c_ajour.facture_ap, ' '), 15) ||
                    rpad(c_ajour.fournisseur_ap, 20) ||
                    rpad(c_ajour.uo_ap, 10) || rpad(c_ajour.montant, 10) ||
                    rpad(nvl(c_ajour.statut_identification, ' '), 22) ||
                    rpad(c_ajour.modele_reglement, 25) ||
                    rpad(c_ajour.id_modele_reglement, 20);
      writeout(vv_message);

    END LOOP;

    fnd_file.put_line(fnd_file.output, chr(10));

    fnd_file.put_line(fnd_file.output,
                      '   . Total de lignes RB rejetées (sans identification de la facture)               :' ||
                      g_lignes_non_mis_a_jour);
    dka_tools_pkg.put_log_message('   . Total de lignes RB rejetées (sans identification de la facture)  :' ||
                                  g_lignes_non_mis_a_jour);
    dka_tools_pkg.put_log_message(' Détail :');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      '--------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'Détail :');

    fnd_file.put_line(fnd_file.output, ' ');
    writeout(rpad('ID Ligne RB', 15) || rpad('Type ligne', 15) ||
             rpad('Num Fact', 15) || RPAD('Num Cpt Fact', 20) || --EDB338
       rpad('Fournisseur', 20) ||
             rpad('ID Fournisseur', 20) || rpad('ID CPT Bancaire', 20) ||
             rpad('NUM CPT Bancaire', 20) || rpad('UO RB', 10) ||
             rpad('Montant RB', 12) || rpad('Code DEVISE', 15) ||
             rpad('STATUT REFERENCE', 20) || rpad('ID FACTURE', 15) ||
             rpad('Num Fact AP', 15) || rpad('Fournisseur AP', 20) ||
             rpad('UO', 10) || rpad('Montant', 10) ||
             rpad('STATUT IDENTIFICATION', 22) ||
             rpad('MODELE REGLEMENT', 25) ||
             rpad('ID MODELE REGLEMENT', 20) || rpad('Cause du rejet', 20));
    writeout(rpad('-----------', 15) || rpad('----------', 15) ||
             rpad('--------', 15) || rpad('-----------', 20) || --EDB338
       rpad('-----------', 20) ||
             rpad('--------------', 20) || rpad('---------------', 20) ||
             rpad('----------------', 20) || rpad('-----', 10) ||
             rpad('----------', 12) || rpad('-----------', 15) ||
             rpad('----------------', 20) || rpad('----------', 15) ||
             rpad('-----------', 15) || rpad('--------------', 20) ||
             rpad('--', 10) || rpad('-------', 10) ||
             rpad('-----------------', 22) || rpad('----------------', 25) ||
             rpad('-------------------', 20) || rpad('--------------', 20));

    FOR c_non_ajour IN c_rb_non_ajour LOOP

      dka_tools_pkg.put_log_message(' - Identifiant de ligne RB  :' ||
                                    c_non_ajour.identifiant_ligne_rb);
      dka_tools_pkg.put_log_message(' - Type de ligne RB :' ||
                                    c_non_ajour.type_ligne_rb);
      dka_tools_pkg.put_log_message(' - les numéros de factures de ces fournisseurs' ||
                                    c_non_ajour.numero_facture_rb);
    dka_tools_pkg.put_log_message(' - les numéros de comptes de facturation de ces fournisseurs' ||
                                    c_non_ajour.NUMERO_CPT_FACTURATION_RB); --EDB338
      dka_tools_pkg.put_log_message(' - les fournisseurs' ||
                                    c_non_ajour.fournisseur_rb);
      dka_tools_pkg.put_log_message(' - vendor_id' ||
                                    c_non_ajour.vendor_id_rb);
      dka_tools_pkg.put_log_message(' - ID compte bancaire' ||
                                    c_non_ajour.id_compte_bancaire);
      dka_tools_pkg.put_log_message(' - Numéro du compte bancaire interne' ||
                                    c_non_ajour.numero_compte_inter);
      dka_tools_pkg.put_log_message(' - le montant ' ||
                                    c_non_ajour.montant_rb);
      dka_tools_pkg.put_log_message(' - Code devise ' ||
                                    c_non_ajour.code_devise_rb);
      dka_tools_pkg.put_log_message(' - ID Facture AP ' ||
                                    c_non_ajour.id_facture_ap);
      dka_tools_pkg.put_log_message(' - Reference2 ' ||
                                    c_non_ajour.reference2);
      dka_tools_pkg.put_log_message(' - Numéro de facture AP ' ||
                                    c_non_ajour.facture_ap);
      dka_tools_pkg.put_log_message(' - fournisseur de facture AP ' ||
                                    c_non_ajour.fournisseur_ap);
      dka_tools_pkg.put_log_message(' - Vendor_id_ap ' ||
                                    c_non_ajour.vendor_id_ap);
      dka_tools_pkg.put_log_message(' - Montant  ' || c_non_ajour.montant);
      dka_tools_pkg.put_log_message(' - ID modèle de règlement ' ||
                                    c_non_ajour.id_modele_reglement);
      dka_tools_pkg.put_log_message(' - Modèle de règlement' ||
                                    c_non_ajour.modele_reglement);
      dka_tools_pkg.put_log_message(' - Statut d''identification ' ||
                                    c_non_ajour.statut_identification);
      dka_tools_pkg.put_log_message(' - Cause du rejet ' ||
                                    c_non_ajour.causes_rejet_maj_echeancier);
      dka_tools_pkg.put_log_message(' ----------------------------------- ');
      vv_message := rpad(c_non_ajour.identifiant_ligne_rb, 15) ||
                    rpad(c_non_ajour.type_ligne_rb, 15) ||
                    rpad(nvl(c_non_ajour.numero_facture_rb, ' '), 15) ||
          rpad(nvl(c_non_ajour.NUMERO_CPT_FACTURATION_RB, ' '), 20) || --EDB338
                    rpad(c_non_ajour.fournisseur_rb, 20) ||
                    rpad(nvl(c_non_ajour.vendor_id_rb, 0), 20) ||
                    rpad(c_non_ajour.id_compte_bancaire, 20) ||
                    rpad(c_non_ajour.numero_compte_inter, 20) ||
                    rpad(c_non_ajour.uo_compte_bancaire, 10) ||
                    rpad(c_non_ajour.montant_rb, 12) ||
                    rpad(c_non_ajour.code_devise_rb, 15) ||
                    rpad(nvl(c_non_ajour.statut_reference, ' '), 20) ||
                    rpad(nvl(c_non_ajour.id_facture_ap, 0), 15) ||
                    rpad(nvl(c_non_ajour.facture_ap, ' '), 15) ||
                    rpad(nvl(c_non_ajour.fournisseur_ap, ' '), 20) ||
                    rpad(nvl(c_non_ajour.uo_ap, ' '), 10) ||
                    rpad(nvl(c_non_ajour.montant, 0), 10) ||
                    rpad(nvl(c_non_ajour.statut_identification, ' '), 22) ||
                    rpad(nvl(c_non_ajour.modele_reglement, ' '), 25) ||
                    rpad(nvl(c_non_ajour.id_modele_reglement, 0), 20) ||
                    rpad(c_non_ajour.causes_rejet_maj_echeancier, 100);
      writeout(vv_message);
      p_retcode := 1;
    END LOOP;

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END report_bilan2;

  /*************************************************************************
  * PROCEDURE NAME : recuperer_facture
  *
  * DESCRIPTION
  *  Procédure pour récuperer la facuture en se basant sur la description longue du ligne RB
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  *
  *
  ************************************************************************
  */

  PROCEDURE recuperer_facture(p_long_description      in varchar2,
                              p_fournisseur           in varchar2,
                              p_mot_clef_de_recherche in varchar2,
                              p_position_num_facture  in varchar2,
                              p_taille_num_facture    in varchar2,
                              p_facture               out varchar2) IS
  BEGIN
    if p_mot_clef_de_recherche = '0' then
      BEGIN
        select trim(substr(p_long_description,
                           p_position_num_facture,
                           p_taille_num_facture))
          into p_facture
          from dual;
      EXCEPTION
        WHEN OTHERS THEN
          p_facture := null;
      END;
    else
      BEGIN
        select trim(substr(p_long_description,
                           instr(p_long_description, p_mot_clef_de_recherche) +
                           p_position_num_facture,
                           p_taille_num_facture))
          into p_facture
          from dual;

      EXCEPTION
        WHEN OTHERS THEN
          p_facture := null;
      end;
    end if;
  END;


    /*************************************************************************
  * PROCEDURE NAME : recuperer_facture_edf
  *
  * DESCRIPTION
  *  Procédure pour récuperer la facture edf en se basant sur la description longue du ligne RB
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  *
  *
  ************************************************************************
  */

  PROCEDURE recuperer_facture_edf(p_long_description      in varchar2,
                              p_fournisseur           in varchar2,
                              p_mot_clef_de_recherche in varchar2,
                              p_position_num_facture  in varchar2,
                              p_taille_num_facture    in varchar2,
                              p_facture               out varchar2) IS


  p_fact1 VARCHAR2(400);
  p_fact2 VARCHAR2(400);

  BEGIN

        /*select trim(substr(p_long_description,
                           instr(p_long_description, upper(p_mot_clef_de_recherche)) +
                           p_position_num_facture,
                           p_taille_num_facture))*/




    IF instr(p_long_description, upper(p_mot_clef_de_recherche)) <> 0 THEN

    BEGIN
      
   select substr(p_long_description,
                           instr(p_long_description, upper(p_mot_clef_de_recherche)) +
                           p_position_num_facture,
                           length(p_long_description))

    into p_fact1
    from dual;

  
  select substr (p_fact1,
  0,
  instr(p_fact1, ' ')-1)
  into p_fact2
  from dual ;
  
  p_facture := p_fact2;

    IF length(p_facture) != 10 THEN

    p_facture := null;

    END IF;

     

      EXCEPTION
      WHEN OTHERS THEN
        p_facture := null;
      end;

    ELSE

    p_facture := null;

    END IF;
  END;

  ------------------------------------------------------------------------------------
  -- Nom              : EXTRACT_DATA
  -- Description      : Procédure d'extraction des données dans une table spécifique
  --
  -- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
  --                    pn_retgcc     Sortie gcc Retour de la procédure
  --                                   '0' : Normal
  --                                   '1' : Avertissement
  --                                   '2' : Erreur
  --                  pv_type_fusion type de fusion
  --
  --
  -- VALEUR RETOURNEE :
  -- Description       :
  -- Valeurs possibles :
  ------------------------------------------------------------------------------------

  PROCEDURE EXTRACT_DATA(p_errbuf out varchar2, p_retcode out number) IS

    ----------------------------------------------------------------------
    -- curseur pour recuperer les lignes RB de type prélèvement
    ----------------------------------------------------------------------

    CURSOR C_LIGNE_RB IS

      SELECT distinct RLA.LINE_ID           IDENTIFIANT_LIGNE_RB,
                      RLA.LINE_TYPE         TYPE_LIGNE_RB,
                      pv.vendor_name        FOURNISSEUR,
                      pv.VENDOR_ID          VENDOR_ID,
                      aba.BANK_ACCOUNT_ID   ID_COMPTE_BANCAIRE,
                      aba.BANK_ACCOUNT_NUM  NUMERO_COMPTE_INTER,
                      aba.BANK_ACCOUNT_NAME COMPTE_BANCAIRE,
                      HOU.NAME              UO_COMPTE_BANCAIRE,
                      RLA.CURRENCY_CODE     CODE_DEVISE,
                      RLA.AMOUNT            MONTANT_RB,
                      RLA.LINE_ID           LIGNE_ID,
                      RLA.MATCHING_STATUS   MATCHING_STATUS,
                      RLA.line_type         LINE_TYPE,
                      RLA.LONG_DESCRIPTION  LONG_DESCRIPTION,
                      RLA.line_DATE         DATE_OPERATION,
                      RLA.bank_date         DATE_VALEUR,
                      RLA.TYPE              TYPE,
            RLA.bank_transaction_code OIB
        FROM CE_PAYMENT_DOCUMENTS  acs,
             CE_BANK_ACCOUNTS      aba,
             AP_SUPPLIERS          Pv,
             HR_OPERATING_UNITS    HOU,
             ce_bank_acct_uses_all bau,
             XXRB.RB_LINES_ALL     RLA,
             DKA_STRANSCO_LINES    DSTL,
             DKA_STRANSCO_HEADERS  DSTH,
             ce_ap_pm_doc_categories cadc
       WHERE 1 = 1
         AND acs.payment_document_name = 'PRLVT AUTO FOURNISSEUR'
         AND acs.INTERNAL_BANK_ACCOUNT_ID = aba.bank_account_id
         AND aba.bank_account_id = bau.bank_account_id
         AND hou.organization_id = bau.org_id
         AND rla.bank_account_id = aba.bank_account_id
         AND rla.bank_transaction_code = 'B1'
         AND RLA.line_type = 'B'
         AND RLA.Matching_status != 'Y'
         AND bau.bank_acct_use_id = cadc.bank_acct_use_id
         AND cadc.payment_method_code = 'WIRE'
         AND cadc.payment_doc_category = 'WIRE PAY'
         and RLA.LONG_DESCRIPTION like '%' || DSTL.RETURN_VALUE || '%'
         and DSTL.SET_ID = DSTH.SET_ID
         AND DSTH.SET_NAME = 'DKA_TRANSCO_FOURNISSEUR_AP_RB'
         AND DSTL.ENABLE = 'Y'
         AND NVL(DSTL.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
         and pv.vendor_id = DSTL.param3_value
         AND PV.vendor_name in
             (select DSTL2.param1_value
                from DKA_STRANSCO_LINES DSTL2, DKA_STRANSCO_HEADERS DSTH2
               where DSTL2.SET_ID = DSTH2.SET_ID
                 AND DSTH2.SET_NAME = 'DKA_TRANSCO_FACTUREAP_RB'
                 AND DSTL2.ENABLE = 'Y'
                 AND NVL(DSTL2.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE))

      ;

--EDB338

    CURSOR C_LIGNE_RB_EDF IS

 SELECT distinct RLA.LINE_ID           IDENTIFIANT_LIGNE_RB,
                      RLA.LINE_TYPE         TYPE_LIGNE_RB,
                      pv.vendor_name        FOURNISSEUR,
                      pv.VENDOR_ID          VENDOR_ID,
                      aba.BANK_ACCOUNT_ID   ID_COMPTE_BANCAIRE,
                      aba.BANK_ACCOUNT_NUM  NUMERO_COMPTE_INTER,
                      aba.BANK_ACCOUNT_NAME COMPTE_BANCAIRE,
                      HOU.NAME              UO_COMPTE_BANCAIRE,
                      RLA.CURRENCY_CODE     CODE_DEVISE,
                      RLA.AMOUNT            MONTANT_RB,
                      RLA.LINE_ID           LIGNE_ID,
                      RLA.MATCHING_STATUS   MATCHING_STATUS,
                      RLA.line_type         LINE_TYPE,
                      upper(RLA.LONG_DESCRIPTION)  LONG_DESCRIPTION,
                      RLA.line_DATE         DATE_OPERATION,
                      RLA.bank_date         DATE_VALEUR,
                      RLA.TYPE              TYPE,
            RLA.bank_transaction_code OIB
        FROM CE_PAYMENT_DOCUMENTS  acs,
             CE_BANK_ACCOUNTS      aba,
             AP_SUPPLIERS          Pv,
             HR_OPERATING_UNITS    HOU,
             ce_bank_acct_uses_all bau,
             XXRB.RB_LINES_ALL     RLA,
             DKA_STRANSCO_LINES    DSTL,
             DKA_STRANSCO_HEADERS  DSTH,
             ce_ap_pm_doc_categories cadc
       WHERE 1 = 1
         AND acs.payment_document_name = 'PRLVT AUTO FOURNISSEUR'
         AND acs.INTERNAL_BANK_ACCOUNT_ID = aba.bank_account_id
         AND aba.bank_account_id = bau.bank_account_id
         AND hou.organization_id = bau.org_id
         AND rla.bank_account_id = aba.bank_account_id
         AND rla.bank_transaction_code = 'B1'
         AND RLA.line_type = 'B'
         AND RLA.Matching_status != 'Y'
         AND bau.bank_acct_use_id = cadc.bank_acct_use_id
         AND cadc.payment_method_code = 'WIRE'
         AND cadc.payment_doc_category = 'WIRE PAY'
         and upper(RLA.LONG_DESCRIPTION) like '%' || upper(DSTL.RETURN_VALUE) || '%'
         and DSTL.SET_ID = DSTH.SET_ID
         AND DSTH.SET_NAME = 'DKA_TRANSCO_FRN_CPTFACAP_RB' --'DKA_TRANSCO_FOURNISSEUR_AP_RB'
         AND DSTL.ENABLE = 'Y'
         AND NVL(DSTL.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
         and pv.vendor_id = DSTL.param3_value
     --and rla.line_id = 1413526--
         --AND PV.vendor_id = '1567'
         /*AND PV.vendor_name in
             (select DSTL2.param1_value
                from DKA_STRANSCO_LINES DSTL2, DKA_STRANSCO_HEADERS DSTH2
               where DSTL2.SET_ID = DSTH2.SET_ID
                 AND DSTH2.SET_NAME = 'DKA_TRANSCO_CPTFACAP_RB'
                 AND DSTL2.ENABLE = 'Y'
                 AND NVL(DSTL2.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE))*/

         ;

    --end EDB338

    v_numero_facture           ap_invoices_all.invoice_num%type;
    v_fournisseur              DKA_STRANSCO_LINES.param1_value%type;
    v_mot_clef_de_recherche    DKA_STRANSCO_LINES.param2_value%type;
    v_position_num_facture     DKA_STRANSCO_LINES.param3_value%type;
    v_taille_num_facture       DKA_STRANSCO_LINES.RETURN_value%type;
    v_cause_rejet_alimentation VARCHAR2(250);
    v_statut_reference         VARCHAR2(1);

  --EDB338

  v_numero_facture_edf           ap_invoices_all.invoice_num%type;
    v_fournisseur_edf              DKA_STRANSCO_LINES.param1_value%type;
    v_mot_clef_de_recherche_edf    DKA_STRANSCO_LINES.param2_value%type;
    v_position_num_facture_edf     DKA_STRANSCO_LINES.param3_value%type;
    v_taille_num_facture_edf       DKA_STRANSCO_LINES.RETURN_value%type;
    v_cause_rejet_alimentation_edf VARCHAR2(250);
    v_statut_reference_edf         VARCHAR2(1);

  BEGIN
    p_errbuf  := NULL;
    p_retcode := 0;

    FOR C_RB IN C_LIGNE_RB LOOP
      v_cause_rejet_alimentation := null;
      g_lignes_rb_traitees       := g_lignes_rb_traitees + 1;
      BEGIN
        SELECT param1_value, param2_value, param3_value, return_value
          into v_fournisseur,
               v_mot_clef_de_recherche,
               v_position_num_facture,
               v_taille_num_facture

          FROM DKA_STRANSCO_LINES DSTL, DKA_STRANSCO_HEADERS DSTH
         WHERE DSTL.SET_ID = DSTH.SET_ID
           AND DSTH.SET_NAME LIKE 'DKA_TRANSCO_FACTUREAP_RB'
           AND DSTL.ENABLE = 'Y'
           and param1_value = C_RB.FOURNISSEUR
           AND NVL(DSTL.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE);
      EXCEPTION
        WHEN OTHERS THEN
          v_fournisseur           := null;
          v_mot_clef_de_recherche := null;
          v_position_num_facture  := null;
          v_taille_num_facture    := null;

      END;
      recuperer_facture(C_RB.LONG_DESCRIPTION,
                        v_fournisseur,
                        v_mot_clef_de_recherche,
                        v_position_num_facture,
                        v_taille_num_facture,
                        v_numero_facture);

      if v_numero_facture is null then
        v_statut_reference         := 'P';
        v_cause_rejet_alimentation := ' Absence de numéro de facture en description';
        g_lignes_non_mis_a_jour    := g_lignes_non_mis_a_jour + 1;
      else
        g_lignes_mis_a_jour := g_lignes_mis_a_jour + 1;
        v_statut_reference  := null;
        BEGIN
          update RB_LINES_ALL rb
             set reference2       = v_numero_facture,
                 last_update_date = sysdate,
                 last_updated_by  = g_user_id
           where rb.LINE_ID = C_RB.LIGNE_ID
             AND bank_account_id = C_RB.ID_COMPTE_BANCAIRE
             AND type = C_RB.TYPE
             AND line_type = C_RB.TYPE_LIGNE_RB;
        EXCEPTION
          WHEN OTHERS THEN
            v_cause_rejet_alimentation := substr('rejet au niveau de mise à jour de la table RB_LINES_ALL : ' ||
                                                 SQLERRM,
                                                 1,
                                                 250);

        END;

      end if;
      --COMMIT;
      BEGIN

        INSERT INTO dka_prel_ap_rb
          (CREATION_DATE,
           CREATED_BY,
           LAST_UPDATED_DATE_RB,
           UPDATED_BY_RB,
           IDENTIFIANT_LIGNE_RB,
           TYPE_LIGNE_RB,
           DATE_OPERATION,
           DATE_VALEUR,
           LIBELLE_LONG,
           MATCHING_STATUS_RB,
           NUMERO_FACTURE_RB,
           FOURNISSEUR_RB,
           ID_COMPTE_BANCAIRE,
           NUMERO_COMPTE_INTER,
           UO_COMPTE_BANCAIRE,
           REGION,
           NUMERO_SOCIETE,
           MONTANT_RB,
           CODE_DEVISE_RB,
           STATUT_REFERENCE,
           REFERENCE2,
           CAUSE_REJET_ALIMENTATION,
           LAST_UPDATED_DATE_AP,
           UPDATED_BY_AP,
           ID_FACTURE_AP,
           FACTURE_AP,
           FOURNISSEUR_AP,
           VENDOR_ID_AP,
           MONTANT,
           CODE_DEVISE_AP,
           ID_MODELE_REGLEMENT,
           MODELE_REGLEMENT,
           PRIORITE_ORIGINE,
           EXCLUSIVE_PAYMENT_FLAG_ORG,
           EXTERNAL_BANK_ACCOUNT_ID,
           STATUT_MAJ_ECHEANCIER,
           CAUSES_REJET_MAJ_ECHEANCIER,
           LAST_UPDATED_DATE_REGLEMENT,
           UPDATED_BY_REGLEMENT,
           ID_REGLEMENT,
           NUMERO_REGLEMENT,
           UO_REGLEMENT,
           MONTANT_REGLEMENT,
           CODE_DEVISE_REGLEMENT,
           NOM_MODELE,
           ID_DEMANDE_REGLEMENT,
           STATUT_ETAPE_REGLEMENT,
           MESSAGE_ERREUR,
           LAST_UPDATED_DATE_GL,
           UPDATED_BY_GL,
           STATUT_CENTRALISATION,
           MESSAGE_ERREUR_CENTRALISATION,
           STATUT_IMPUTATION,
           MESSAGE_ERREUR_IMPUTATION,
           ID_PIECE_GL,
           NUMERO_PIECE_GL,
           NUMERO_LIGNE_GL,
           ID_LIGNE_RB_GL,
           LIBELLE_LONG_GL,
           TYPE_LIGNE_RB_GL,
           REFERENCE2_GL,
           STATUT_ALIMENTATION_REF2,
           MESSAGE_ALIMENTATION_REF2,
           MATCHING_STATUS_RB_GL,
           RAPPROCHE_LE,
           COMPTE_BANCAIRE,
           VENDOR_ID_RB,
           BANK_ACCOUNT_NUM_ORG,
           UO_AP,
           STATUT_ETAPE,
           STATUT_IDENTIFICATION,
       NUM_FOURNISSEUR_AP,
       OIB

           )
        VALUES
          (sysdate,
           g_user_id,
           sysdate,
           g_user_id,
           C_RB.LIGNE_ID,
           C_RB.LINE_TYPE,
           C_RB.DATE_OPERATION,
           C_RB.DATE_VALEUR,
           C_RB.LONG_DESCRIPTION,
           C_RB.MATCHING_STATUS,
           v_numero_facture,
           C_RB.FOURNISSEUR,
           C_RB.ID_COMPTE_BANCAIRE,
           C_RB.NUMERO_COMPTE_INTER,
           C_RB.UO_COMPTE_BANCAIRE,
           substr(C_RB.UO_COMPTE_BANCAIRE, 1, 3),
           substr(C_RB.UO_COMPTE_BANCAIRE, 4, 7),
           C_RB.MONTANT_RB,
           C_RB.CODE_DEVISE,
           v_statut_reference,
           v_numero_facture,
           v_cause_rejet_alimentation,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           C_RB.COMPTE_BANCAIRE,
           C_RB.VENDOR_ID,
           null,
           null,
           'E1',
           null,
       null,
       C_RB.OIB);

      EXCEPTION

        WHEN OTHERS THEN
          p_retcode := 1;
          DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_PREL_AP_RB : ' ||
                                             SQLCODE || ' - ' || SQLERRM);

      END;
    END LOOP;

  --EDB338

    FOR C_RB_EDF IN C_LIGNE_RB_EDF LOOP
      v_cause_rejet_alimentation_edf := null;
      --g_lignes_rb_traitees       := g_lignes_rb_traitees + 1;
      BEGIN
        SELECT param1_value, param2_value, param3_value, return_value
          into v_fournisseur_edf,
               v_mot_clef_de_recherche_edf,
               v_position_num_facture_edf,
               v_taille_num_facture_edf

          FROM DKA_STRANSCO_LINES DSTL, DKA_STRANSCO_HEADERS DSTH
         WHERE DSTL.SET_ID = DSTH.SET_ID
           AND DSTH.SET_NAME LIKE 'DKA_TRANSCO_CPTFACAP_RB'
           AND DSTL.ENABLE = 'Y'
           and param1_value = C_RB_EDF.FOURNISSEUR
           AND NVL(DSTL.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE);
      EXCEPTION
        WHEN OTHERS THEN
          v_fournisseur_edf           := null;
          v_mot_clef_de_recherche_edf := null;
          v_position_num_facture_edf  := null;
          v_taille_num_facture_edf    := null;

      END;
      recuperer_facture_edf(C_RB_EDF.LONG_DESCRIPTION,
                        v_fournisseur_edf,
                        v_mot_clef_de_recherche_edf,
                        v_position_num_facture_edf,
                        v_taille_num_facture_edf,
                        v_numero_facture_edf);


      if v_numero_facture_edf is null then
        v_statut_reference_edf         := 'P';
        v_cause_rejet_alimentation_edf := ' Absence de numéro de compte de facturation en description';
        g_lignes_non_mis_a_jour    := g_lignes_non_mis_a_jour + 1;



    --elsif (instr(v_numero_facture_edf,' ') = 11 OR instr(v_numero_facture_edf,' ') <> 0) THEN --EDB338
    elsif (instr(v_numero_facture_edf,' ') = 0) THEN --EDB338

    g_lignes_rb_traitees       := g_lignes_rb_traitees + 1;

    v_numero_facture_edf := substr(v_numero_facture_edf,
                                                 1,
                                                 10);


        v_statut_reference_edf  := null;
        BEGIN
          update RB_LINES_ALL rb
             set reference2       = v_numero_facture_edf,
                 last_update_date = sysdate,
                 last_updated_by  = g_user_id
           where rb.LINE_ID = C_RB_EDF.LIGNE_ID
             AND bank_account_id = C_RB_EDF.ID_COMPTE_BANCAIRE
             AND type = C_RB_EDF.TYPE
             AND line_type = C_RB_EDF.TYPE_LIGNE_RB;
        EXCEPTION
          WHEN OTHERS THEN
            v_cause_rejet_alimentation := substr('rejet au niveau de mise à jour de la table RB_LINES_ALL : ' ||
                                                 SQLERRM,
                                                 1,
                                                 250);

        END;

    g_lignes_mis_a_jour := g_lignes_mis_a_jour + 1;

      --COMMIT;



      BEGIN



        INSERT INTO dka_prel_ap_rb
          (CREATION_DATE,
           CREATED_BY,
           LAST_UPDATED_DATE_RB,
           UPDATED_BY_RB,
           IDENTIFIANT_LIGNE_RB,
           TYPE_LIGNE_RB,
           DATE_OPERATION,
           DATE_VALEUR,
           LIBELLE_LONG,
           MATCHING_STATUS_RB,
           NUMERO_FACTURE_RB,
       NUMERO_CPT_FACTURATION_RB,--EDB338
           FOURNISSEUR_RB,
           ID_COMPTE_BANCAIRE,
           NUMERO_COMPTE_INTER,
           UO_COMPTE_BANCAIRE,
           REGION,
           NUMERO_SOCIETE,
           MONTANT_RB,
           CODE_DEVISE_RB,
           STATUT_REFERENCE,
           REFERENCE2,
           CAUSE_REJET_ALIMENTATION,
           LAST_UPDATED_DATE_AP,
           UPDATED_BY_AP,
           ID_FACTURE_AP,
           FACTURE_AP,
           FOURNISSEUR_AP,
           VENDOR_ID_AP,
           MONTANT,
           CODE_DEVISE_AP,
           ID_MODELE_REGLEMENT,
           MODELE_REGLEMENT,
           PRIORITE_ORIGINE,
           EXCLUSIVE_PAYMENT_FLAG_ORG,
           EXTERNAL_BANK_ACCOUNT_ID,
           STATUT_MAJ_ECHEANCIER,
           CAUSES_REJET_MAJ_ECHEANCIER,
           LAST_UPDATED_DATE_REGLEMENT,
           UPDATED_BY_REGLEMENT,
           ID_REGLEMENT,
           NUMERO_REGLEMENT,
           UO_REGLEMENT,
           MONTANT_REGLEMENT,
           CODE_DEVISE_REGLEMENT,
           NOM_MODELE,
           ID_DEMANDE_REGLEMENT,
           STATUT_ETAPE_REGLEMENT,
           MESSAGE_ERREUR,
           LAST_UPDATED_DATE_GL,
           UPDATED_BY_GL,
           STATUT_CENTRALISATION,
           MESSAGE_ERREUR_CENTRALISATION,
           STATUT_IMPUTATION,
           MESSAGE_ERREUR_IMPUTATION,
           ID_PIECE_GL,
           NUMERO_PIECE_GL,
           NUMERO_LIGNE_GL,
           ID_LIGNE_RB_GL,
           LIBELLE_LONG_GL,
           TYPE_LIGNE_RB_GL,
           REFERENCE2_GL,
           STATUT_ALIMENTATION_REF2,
           MESSAGE_ALIMENTATION_REF2,
           MATCHING_STATUS_RB_GL,
           RAPPROCHE_LE,
           COMPTE_BANCAIRE,
           VENDOR_ID_RB,
           BANK_ACCOUNT_NUM_ORG,
           UO_AP,
           STATUT_ETAPE,
           STATUT_IDENTIFICATION,
       NUM_FOURNISSEUR_AP,
       OIB

           )
        VALUES
          (sysdate,
           g_user_id,
           sysdate,
           g_user_id,
           C_RB_EDF.LIGNE_ID,
           C_RB_EDF.LINE_TYPE,
           C_RB_EDF.DATE_OPERATION,
           C_RB_EDF.DATE_VALEUR,
           C_RB_EDF.LONG_DESCRIPTION,
           C_RB_EDF.MATCHING_STATUS,
           null,--EDB338 --num de facture
       v_numero_facture_edf,--EDB338
           C_RB_EDF.FOURNISSEUR,
           C_RB_EDF.ID_COMPTE_BANCAIRE,
           C_RB_EDF.NUMERO_COMPTE_INTER,
           C_RB_EDF.UO_COMPTE_BANCAIRE,
           substr(C_RB_EDF.UO_COMPTE_BANCAIRE, 1, 3),
           substr(C_RB_EDF.UO_COMPTE_BANCAIRE, 4, 7),
           C_RB_EDF.MONTANT_RB,
           C_RB_EDF.CODE_DEVISE,
           v_statut_reference_edf,
           v_numero_facture_edf,
           v_cause_rejet_alimentation_edf,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           null,
           C_RB_EDF.COMPTE_BANCAIRE,
           C_RB_EDF.VENDOR_ID,
           null,
           null,
           'E1',
           null,
       null,
       C_RB_EDF.OIB);

      EXCEPTION

        WHEN OTHERS THEN
          p_retcode := 1;
          DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_PREL_AP_RB : ' ||
                                             SQLCODE || ' - ' || SQLERRM);


      END;

    END IF;


    END LOOP;



  --END EDB338

    COMMIT;
  END EXTRACT_DATA;

  /*
  *************************************************************************
  * PROCEDURE NAME : ARCHIVE_DATA
  *
  * DESCRIPTION
  *  Procédure pour Archiver les données extraites
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  *
  *
  *************************************************************************/

  PROCEDURE ARCHIVE_DATA(p_Errbuf IN OUT VARCHAR2, p_retcode IN OUT NUMBER) IS
    CURSOR CUR_ARCHIVE IS
      SELECT * FROM DKA_PREL_AP_RB;

  BEGIN

    FOR REC_ARCHIVE IN CUR_ARCHIVE LOOP
      BEGIN

     INSERT INTO DKA_PREL_AP_RB_HIST
           (CREATION_DATE,
           CREATED_BY,
           LAST_UPDATED_DATE_RB,
           UPDATED_BY_RB,
           IDENTIFIANT_LIGNE_RB,
           TYPE_LIGNE_RB,
           DATE_OPERATION,
           DATE_VALEUR,
           LIBELLE_LONG,
           MATCHING_STATUS_RB,
           NUMERO_FACTURE_RB,
           FOURNISSEUR_RB,
           ID_COMPTE_BANCAIRE,
           NUMERO_COMPTE_INTER,
           UO_COMPTE_BANCAIRE,
           REGION,
           NUMERO_SOCIETE,
           MONTANT_RB,
           CODE_DEVISE_RB,
           STATUT_REFERENCE,
           REFERENCE2,
           CAUSE_REJET_ALIMENTATION,
           LAST_UPDATED_DATE_AP,
           UPDATED_BY_AP,
           ID_FACTURE_AP,
           FACTURE_AP,
           FOURNISSEUR_AP,
           VENDOR_ID_AP,
           MONTANT,
           CODE_DEVISE_AP,
           ID_MODELE_REGLEMENT,
           MODELE_REGLEMENT,
           PRIORITE_ORIGINE,
           EXCLUSIVE_PAYMENT_FLAG_ORG,
           EXTERNAL_BANK_ACCOUNT_ID,
           STATUT_MAJ_ECHEANCIER,
           CAUSES_REJET_MAJ_ECHEANCIER,
           LAST_UPDATED_DATE_REGLEMENT,
           UPDATED_BY_REGLEMENT,
           ID_REGLEMENT,
           NUMERO_REGLEMENT,
           UO_REGLEMENT,
           MONTANT_REGLEMENT,
           CODE_DEVISE_REGLEMENT,
           NOM_MODELE,
           ID_DEMANDE_REGLEMENT,
           STATUT_ETAPE_REGLEMENT,
           MESSAGE_ERREUR,
           LAST_UPDATED_DATE_GL,
           UPDATED_BY_GL,
           STATUT_CENTRALISATION,
           MESSAGE_ERREUR_CENTRALISATION,
           STATUT_IMPUTATION,
           MESSAGE_ERREUR_IMPUTATION,
           ID_PIECE_GL,
           NUMERO_PIECE_GL,
           NUMERO_LIGNE_GL,
           LIBELLE_LONG_GL,
           TYPE_LIGNE_RB_GL,
           REFERENCE2_GL,
           STATUT_ALIMENTATION_REF2,
           MESSAGE_ALIMENTATION_REF2,
           MATCHING_STATUS_RB_GL,
           RAPPROCHE_LE,
           COMPTE_BANCAIRE,
           VENDOR_ID_RB,
           BANK_ACCOUNT_NUM_ORG,
           UO_AP,
           STATUT_ETAPE,
           statut_identification,
       NUM_FOURNISSEUR_AP,
       OIB)
        VALUES
          (sysdate,
           REC_ARCHIVE.CREATED_BY,
           sysdate,
           REC_ARCHIVE.UPDATED_BY_RB,
           REC_ARCHIVE.IDENTIFIANT_LIGNE_RB,
           REC_ARCHIVE.TYPE_LIGNE_RB,
           REC_ARCHIVE.DATE_OPERATION,
           REC_ARCHIVE.DATE_VALEUR,
           REC_ARCHIVE.LIBELLE_LONG,
           REC_ARCHIVE.MATCHING_STATUS_RB,
           REC_ARCHIVE.NUMERO_FACTURE_RB,
           REC_ARCHIVE.FOURNISSEUR_RB,
           REC_ARCHIVE.ID_COMPTE_BANCAIRE,
           REC_ARCHIVE.NUMERO_COMPTE_INTER,
           REC_ARCHIVE.UO_COMPTE_BANCAIRE,
           REC_ARCHIVE.REGION,
           REC_ARCHIVE.NUMERO_SOCIETE,
           REC_ARCHIVE.MONTANT_RB,
           REC_ARCHIVE.CODE_DEVISE_RB,
           REC_ARCHIVE.STATUT_REFERENCE,
           REC_ARCHIVE.REFERENCE2,
           REC_ARCHIVE.CAUSE_REJET_ALIMENTATION,
           REC_ARCHIVE.LAST_UPDATED_DATE_AP,
           REC_ARCHIVE.UPDATED_BY_AP,
           REC_ARCHIVE.ID_FACTURE_AP,
           REC_ARCHIVE.FACTURE_AP,
           REC_ARCHIVE.FOURNISSEUR_AP,
           REC_ARCHIVE.VENDOR_ID_AP,
           REC_ARCHIVE.MONTANT,
           REC_ARCHIVE.CODE_DEVISE_AP,
           REC_ARCHIVE.ID_MODELE_REGLEMENT,
           REC_ARCHIVE.MODELE_REGLEMENT,
           REC_ARCHIVE.PRIORITE_ORIGINE,
           REC_ARCHIVE.EXCLUSIVE_PAYMENT_FLAG_ORG,
           REC_ARCHIVE.EXTERNAL_BANK_ACCOUNT_ID,
           REC_ARCHIVE.STATUT_MAJ_ECHEANCIER,
           REC_ARCHIVE.CAUSES_REJET_MAJ_ECHEANCIER,
           REC_ARCHIVE.LAST_UPDATED_DATE_REGLEMENT,
           REC_ARCHIVE.UPDATED_BY_REGLEMENT,
           REC_ARCHIVE.ID_REGLEMENT,
           REC_ARCHIVE.NUMERO_REGLEMENT,
           REC_ARCHIVE.UO_REGLEMENT,
           REC_ARCHIVE.MONTANT_REGLEMENT,
           REC_ARCHIVE.CODE_DEVISE_REGLEMENT,
           REC_ARCHIVE.NOM_MODELE,
           REC_ARCHIVE.ID_DEMANDE_REGLEMENT,
           REC_ARCHIVE.STATUT_ETAPE_REGLEMENT,
           REC_ARCHIVE.MESSAGE_ERREUR,
           REC_ARCHIVE.LAST_UPDATED_DATE_GL,
           REC_ARCHIVE.UPDATED_BY_GL,
           REC_ARCHIVE.STATUT_CENTRALISATION,
           REC_ARCHIVE.MESSAGE_ERREUR_CENTRALISATION,
           REC_ARCHIVE.STATUT_IMPUTATION,
           REC_ARCHIVE.MESSAGE_ERREUR_IMPUTATION,
           REC_ARCHIVE.ID_PIECE_GL,
           REC_ARCHIVE.NUMERO_PIECE_GL,
           REC_ARCHIVE.NUMERO_LIGNE_GL,
           REC_ARCHIVE.LIBELLE_LONG_GL,
           REC_ARCHIVE.TYPE_LIGNE_RB_GL,
           REC_ARCHIVE.REFERENCE2_GL,
           REC_ARCHIVE.STATUT_ALIMENTATION_REF2,
           REC_ARCHIVE.MESSAGE_ALIMENTATION_REF2,
           REC_ARCHIVE.MATCHING_STATUS_RB_GL,
           REC_ARCHIVE.RAPPROCHE_LE,
           REC_ARCHIVE.COMPTE_BANCAIRE,
           REC_ARCHIVE.VENDOR_ID_RB,
           REC_ARCHIVE.BANK_ACCOUNT_NUM_ORG,
           REC_ARCHIVE.UO_AP,
           REC_ARCHIVE.STATUT_ETAPE,
           REC_ARCHIVE.statut_identification,
       REC_ARCHIVE.NUM_FOURNISSEUR_AP,
       REC_ARCHIVE.OIB

           );


      EXCEPTION
        WHEN OTHERS THEN
          p_retcode := 1;
          DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_PREL_AP_RB_hist : ' ||
                                             SQLCODE || ' - ' || SQLERRM);
      END;
    END LOOP;

    BEGIN
      DELETE from DKA_PREL_AP_RB
       where (statut_etape in ('E3', 'E4', 'E6') and
             IDENTIFIANT_LIGNE_RB in
             (select LINE_ID
                 from XXRB.RB_LINES_ALL
                where matching_status = 'Y'))
          or statut_etape in ('E1', 'E2', 'E7');
    EXCEPTION
      WHEN OTHERS THEN
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('problème de suppression de la table  DKA_PREL_AP_RB : ' ||
                                           SQLCODE || ' - ' || SQLERRM);

    END;
    COMMIT;
  END ARCHIVE_DATA;

  ------------------------------------------------------------------------------------
  -- Nom              : EXTRACT_DATA2
  -- Description      : Procédure d'extraction des données dans une table spécifique
  --
  -- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
  --                    pn_retgcc     Sortie gcc Retour de la procédure
  --                                   '0' : Normal
  --                                   '1' : Avertissement
  --                                   '2' : Erreur
  --                  pv_type_fusion type de fusion
  --
  --
  -- VALEUR RETOURNEE :
  -- Description       :
  -- Valeurs possibles :
  ------------------------------------------------------------------------------------

  PROCEDURE extract_data2(p_errbuf IN OUT VARCHAR2, p_retcode IN OUT NUMBER) IS

    ----------------------------------------------------------------------
    -- curseur pour recuperer les lignes RB de type prélèvement
    ----------------------------------------------------------------------

    CURSOR cur_prel_ap_rb IS
      SELECT DISTINCT external_bank_account_id
        FROM DKA_PREL_AP_RB
       WHERE statut_reference = 'A';
    CURSOR c_facture_rb IS
       SELECT rowid ,
              rb.*
       FROM DKA_PREL_AP_RB rb
       WHERE statut_reference IS NULL
         AND numero_facture_rb IS NOT NULL;

  --EDB338
  CURSOR c_facture_rb_edf IS--(p_date VARCHAR2) IS
  
  SELECT * FROM DKA_PREL_AP_RB_TMP_1;
  

    

     CURSOR c_fact_edf_ko
     IS
    
    select * from DKA_PREL_AP_RB_TMP_2;



    v_id_facture_ap               ap_invoices_all.invoice_id%type;
    v_facture_ap                  ap_invoices_all.invoice_num%type;
    v_payment_method_code         ap_invoices_all.payment_method_code%type;
    v_priorite_origine            ap_payment_schedules_all.payment_priority%type;
    v_code_devise_ap              ap_invoices_all.payment_currency_code%type;
    v_fournisseur_ap              ap_suppliers.vendor_name%type;
    v_vendor_id_ap                ap_suppliers.vendor_id%type;
  v_num_fournisseur_ap          ap_suppliers.segment1%type;
    v_uo_ap                       hr_operating_units.name%type;
    v_region                      VARCHAR2(50);
    v_uo                          VARCHAR2(50);
    v_montant                     ap_invoices_all.invoice_amount%type;
    v_payment_status_flag         VARCHAR2(50);
    v_invoice_type_lookup_code    ap_invoices_all.invoice_type_lookup_code%type;
    v_payment_priority            VARCHAR2(50);
    v_exclusive_payment_flag      ap_invoices_all.exclusive_payment_flag%type;
    v_bank_account_num            iby_ext_bank_accounts.bank_account_num%type;
    v_wfapproval_status           VARCHAR2(50);
    v_hold_flag                   VARCHAR2(50);
    v_due_date                    VARCHAR2(50);
    v_ext_bank_account            NUMBER;
    v_notfoundinvoice             BOOLEAN;
    v_multipleinvoice             BOOLEAN;
    v_causes_rejet_maj_echeancier VARCHAR2(1000);
    v_statut_reference            VARCHAR2(1);
    v_statut_maj_echeancier       VARCHAR2(1);
    v_modele_reglement            ap_payment_templates.template_name%TYPE;
    v_id_modele_reglement         ap_payment_templates.template_id%TYPE;
    v_flag_erreur                 BOOLEAN;
    v_blocage                     number;
  v_status                      varchar2(1);
  V_FOUNDINVOICE                BOOLEAN;

  --EDB338

  v_id_facture_ap_edf               ap_invoices_all.invoice_id%type;
    v_facture_ap_edf                  ap_invoices_all.invoice_num%type;
    v_payment_method_code_edf         ap_invoices_all.payment_method_code%type;
    v_priorite_origine_edf            ap_payment_schedules_all.payment_priority%type;
    v_code_devise_ap_edf              ap_invoices_all.payment_currency_code%type;
    v_fournisseur_ap_edf              ap_suppliers.vendor_name%type;
    v_vendor_id_ap_edf                ap_suppliers.vendor_id%type;
  v_num_fournisseur_ap_edf          ap_suppliers.segment1%type;
    v_uo_ap_edf                       hr_operating_units.name%type;
    v_region_edf                      VARCHAR2(50);
    v_uo_edf                          VARCHAR2(50);
    v_montant_edf                     ap_invoices_all.invoice_amount%type;
    v_payment_status_flag_edf         VARCHAR2(50);
    v_invoice_type_lookup_code_edf    ap_invoices_all.invoice_type_lookup_code%type;
    v_payment_priority_edf            VARCHAR2(50);
    v_exclusive_payment_flag_edf      ap_invoices_all.exclusive_payment_flag%type;
    v_bank_account_num_edf            iby_ext_bank_accounts.bank_account_num%type;
    v_wfapproval_status_edf           VARCHAR2(50);
    v_hold_flag_edf                   VARCHAR2(50);
    v_due_date_edf                    VARCHAR2(50);
    v_ext_bank_account_edf            NUMBER;
    v_notfoundinvoice_edf             BOOLEAN;
    v_multipleinvoice_edf             BOOLEAN;
    v_causes_rejet_maj_ech_edf VARCHAR2(1000);
    v_statut_reference_edf            VARCHAR2(1);
    v_statut_maj_echeancier_edf       VARCHAR2(1);
    v_modele_reglement_edf            ap_payment_templates.template_name%TYPE;
    v_id_modele_reglement_edf         ap_payment_templates.template_id%TYPE;
    v_flag_erreur_edf                 BOOLEAN;
    v_blocage_edf                     number;
  v_status_edf                      varchar2(1);
  V_FOUNDINVOICE_edf                BOOLEAN;
  VV_DATE_DEBUT varchar2(10);

  BEGIN

    FOR r_facture_rb IN c_facture_rb LOOP

    v_flag_erreur                 := FALSE;
      v_notfoundinvoice             := FALSE;
      v_multipleinvoice             := FALSE;
    v_foundinvoice                := FALSE;
    ---- SHA correction retour recette
      v_causes_rejet_maj_echeancier := NULL;
    v_id_facture_ap               := NULL;
      v_facture_ap                  := NULL;
      v_payment_method_code         := NULL;
      v_exclusive_payment_flag      := NULL;
      v_priorite_origine            := NULL;
      v_code_devise_ap              := NULL;
      v_fournisseur_ap              := NULL;
      v_vendor_id_ap                := NULL;
    v_num_fournisseur_ap          := NULL;
      v_uo_ap                       := NULL;
      v_region                      := NULL;
      v_uo                          := NULL;
      v_montant                     := NULL;
      v_payment_status_flag         := NULL;
      v_invoice_type_lookup_code    := NULL;
      v_wfapproval_status           := NULL;
      v_due_date                    := NULL;
      v_hold_flag                   := NULL;
    v_modele_reglement            := NULL;
    v_id_modele_reglement         := NULL;
    v_status                      := NULL;
      g_lignes_rb_traitees          := g_lignes_rb_traitees + 1;
      BEGIN
        SELECT DISTINCT aia.invoice_id ,
                        aia.invoice_num ,
                        aia.payment_method_code ,
                        aia.exclusive_payment_flag ,
                        apsa.payment_priority ,
                        aia.payment_currency_code ,
                        pv.vendor_name ,
                        pv.vendor_id ,
            pv.segment1 ,
                        hou.name uo_ap,
                        substr(hou.name, 1, 3) ,
                        substr(hou.name, 4) ,
                        aia.invoice_amount ,
                        aia.payment_status_flag ,
                        aia.invoice_type_lookup_code ,
                        aia.wfapproval_status ,
                        apsa.due_date ,
                        apsa.hold_flag
          INTO v_id_facture_ap,
               v_facture_ap,
               v_payment_method_code,
               v_exclusive_payment_flag,
               v_priorite_origine,
               v_code_devise_ap,
               v_fournisseur_ap,
               v_vendor_id_ap,
         v_num_fournisseur_ap,
               v_uo_ap,
               v_region,
               v_uo,
               v_montant,
               v_payment_status_flag,
               v_invoice_type_lookup_code,
               v_wfapproval_status,
               v_due_date,
               v_hold_flag
          FROM ap_invoices_all          aia,
               ap_payment_schedules_all apsa,
               ap_suppliers             pv,
               hr_operating_units       hou
         WHERE aia.invoice_id = apsa.invoice_id
           AND aia.vendor_id = pv.vendor_id
           AND hou.organization_id = aia.org_id
       --AND substr(hou.name ,4) = r_facture_rb.numero_societe
       AND hou.name  =  r_facture_rb.UO_COMPTE_BANCAIRE
           AND aia.invoice_num = r_facture_rb.numero_facture_rb
           AND aia.invoice_type_lookup_code = 'STANDARD';
      EXCEPTION

        WHEN TOO_MANY_ROWS THEN


    BEGIN
           SELECT DISTINCT aia.invoice_id ,
                        aia.invoice_num ,
                        aia.payment_method_code ,
                        aia.exclusive_payment_flag ,
                        apsa.payment_priority ,
                        aia.payment_currency_code ,
                        pv.vendor_name ,
                        pv.vendor_id ,
            pv.segment1 ,
                        hou.name uo_ap,
                        substr(hou.name, 1, 3) ,
                        substr(hou.name, 4) ,
                        aia.invoice_amount ,
                        aia.payment_status_flag ,
                        aia.invoice_type_lookup_code ,
                        aia.wfapproval_status ,
                        apsa.due_date ,
                        apsa.hold_flag
          INTO v_id_facture_ap,
               v_facture_ap,
               v_payment_method_code,
               v_exclusive_payment_flag,
               v_priorite_origine,
               v_code_devise_ap,
               v_fournisseur_ap,
               v_vendor_id_ap,
         v_num_fournisseur_ap,
               v_uo_ap,
               v_region,
               v_uo,
               v_montant,
               v_payment_status_flag,
               v_invoice_type_lookup_code,
               v_wfapproval_status,
               v_due_date,
               v_hold_flag
          FROM ap_invoices_all          aia,
               ap_payment_schedules_all apsa,
               ap_suppliers             pv,
               hr_operating_units       hou
         WHERE aia.invoice_id = apsa.invoice_id
           AND aia.vendor_id = pv.vendor_id
           AND hou.organization_id = aia.org_id
       --AND substr(hou.name ,4) = r_facture_rb.numero_societe
       AND hou.name  =  r_facture_rb.UO_COMPTE_BANCAIRE
           AND aia.invoice_num = r_facture_rb.numero_facture_rb
           AND aia.invoice_type_lookup_code = 'STANDARD'
       AND (-1 * aia.invoice_amount) = r_facture_rb.montant_rb
       and pv.vendor_name = r_facture_rb.fournisseur_rb
        ;
       EXCEPTION
         when others then
           v_multipleinvoice   := true;
      END;


    when others then


    BEGIN
      SELECT DISTINCT aia.invoice_id ,
              aia.invoice_num ,
              aia.payment_method_code ,
              aia.exclusive_payment_flag ,
              apsa.payment_priority ,
              aia.payment_currency_code ,
              pv.vendor_name ,
              pv.vendor_id ,
              pv.segment1 ,
              hou.name uo_ap,
              substr(hou.name, 1, 3) ,
              substr(hou.name, 4) ,
              aia.invoice_amount ,
              aia.payment_status_flag ,
              aia.invoice_type_lookup_code ,
              aia.wfapproval_status ,
              apsa.due_date ,
              apsa.hold_flag
        INTO v_id_facture_ap,
           v_facture_ap,
           v_payment_method_code,
           v_exclusive_payment_flag,
           v_priorite_origine,
           v_code_devise_ap,
           v_fournisseur_ap,
           v_vendor_id_ap,
           v_num_fournisseur_ap,
           v_uo_ap,
           v_region,
           v_uo,
           v_montant,
           v_payment_status_flag,
           v_invoice_type_lookup_code,
           v_wfapproval_status,
           v_due_date,
           v_hold_flag
        FROM ap_invoices_all          aia,
           ap_payment_schedules_all apsa,
           ap_suppliers             pv,
           hr_operating_units       hou
       WHERE aia.invoice_id = apsa.invoice_id
         AND aia.vendor_id = pv.vendor_id
         AND hou.organization_id = aia.org_id
         --AND substr(hou.name ,4) = r_facture_rb.numero_societe
         AND hou.name  <>  r_facture_rb.UO_COMPTE_BANCAIRE
         AND aia.invoice_num = r_facture_rb.numero_facture_rb
         AND aia.invoice_type_lookup_code = 'STANDARD';
         v_foundinvoice := true;
      EXCEPTION
            when no_data_found then
        v_notfoundinvoice   := true;
        WHEN  TOO_MANY_ROWS then
          v_multipleinvoice   := true;

      END;

      END;


      IF v_notfoundinvoice THEN
        v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                         ' - ' || 'Incohérence Facture';
        v_flag_erreur                 := true;
    v_status := 'P';

      ELSIF v_multipleinvoice THEN
        v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                         ' - ' || 'Plusieurs numéros factures trouvés';
        v_flag_erreur                 := true;

      ELSE
        BEGIN
          select COUNT(*)
            into v_blocage
            from ap_holds_all
           where invoice_id = v_id_facture_ap
             and release_lookup_code is null;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_blocage := 0;

        END;

    if v_foundinvoice then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Incohérence UO';
          v_flag_erreur                 := true;

        END IF;
        if v_fournisseur_ap != r_facture_rb.fournisseur_rb then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' ||
                                           'Incohérence Fournisseur';
          v_flag_erreur                 := true;
        END IF;



        if (-1 * v_MONTANT) != r_facture_rb.montant_rb then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Incohérence Montant';
          v_flag_erreur                 := true;
        END IF;
        IF (ap_invoices_pkg.get_approval_status(v_id_facture_ap,
                                                v_montant,
                                                v_payment_status_flag,
                                                v_invoice_type_lookup_code) !=
           'APPROVED') THEN
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Non validée';
          v_flag_erreur                 := true;

        END IF;
        IF (ap_invoices_pkg.get_posting_status(v_id_facture_ap) != 'Y') THEN
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Non Comptabilisée';
          v_flag_erreur                 := true;
        END IF;

        if v_payment_status_flag != 'N' then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Réglée';
          v_flag_erreur                 := true;
        END IF;

        if v_payment_method_code != 'WIRE' then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' ||
                                           'Mode de règlement différent';
          v_flag_erreur                 := true;
        END IF;

        if v_wfapproval_status != 'WFAPPROVED' then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' ||
                                           'Workflow non approuvé';
          v_flag_erreur                 := true;
        END IF;

        if v_due_date > sysdate then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Non échue';
          v_flag_erreur                 := true;
        END IF;

        if nvl(v_hold_flag, 'Y') != 'N'  then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Blocage échéancier';
          v_flag_erreur                 := true;
        END IF;
     if v_blocage != 0 then
          v_causes_rejet_maj_echeancier := v_causes_rejet_maj_echeancier ||
                                           ' - ' || 'Blocage ouvert';
          v_flag_erreur                 := true;
        END IF;

      END IF;
      if v_flag_erreur then
     if v_status = 'P'
      then
    v_statut_reference      := 'P';
    else
        v_statut_reference      := 'R';
     END IF ;
        v_statut_maj_echeancier := v_statut_maj_echeancier;
        g_lignes_non_mis_a_jour := g_lignes_non_mis_a_jour + 1;
        BEGIN
          UPDATE DKA_PREL_AP_RB
             SET last_updated_date_ap        = SYSDATE,
                 updated_by_ap               = g_user_id,
                 id_facture_ap               = v_id_facture_ap,
                 facture_ap                  = v_facture_ap,
                 fournisseur_ap              = v_fournisseur_ap,
                 vendor_id_ap                = v_vendor_id_ap,
                 montant                     = v_montant,
                 code_devise_ap              = v_code_devise_ap,
                 id_modele_reglement         = v_id_modele_reglement,
                 modele_reglement            = v_modele_reglement,
                 priorite_origine            = nvl(priorite_origine,
                                                   v_priorite_origine),
                 exclusive_payment_flag_org  = nvl(exclusive_payment_flag_org,
                                                   v_exclusive_payment_flag),
                 external_bank_account_id    = v_ext_bank_account,
                 statut_reference            = v_statut_reference,
                 causes_rejet_maj_echeancier = v_causes_rejet_maj_echeancier,
                 bank_account_num_org        = nvl(v_bank_account_num,
                                                   bank_account_num_org),
                 uo_ap                       = v_uo_ap,
         NUM_FOURNISSEUR_AP          = v_num_fournisseur_ap,
                 statut_maj_echeancier       = 'N',
                 STATUT_ETAPE                = 'E1',
                 statut_identification       = 'N'
           WHERE identifiant_ligne_rb = r_facture_rb.identifiant_ligne_rb
       and   rowid                = r_facture_rb.rowid;

        EXCEPTION

          WHEN OTHERS THEN
            p_retcode := 1;
            dka_tools_pkg.put_outdebug_message('problème d''UPDATE de la table  DKA_PREL_AP_RB :RB ' ||
                                               SQLCODE || ' - ' || SQLERRM);

        END;
      ELSE
        g_lignes_mis_a_jour     := g_lignes_mis_a_jour + 1;
        v_statut_reference      := 'A';
        v_statut_maj_echeancier := null;

        BEGIN
          SELECT eba.bank_account_num, ext_bank_account_id

            INTO v_bank_account_num, v_ext_bank_account
            FROM ap_suppliers            sup,
                 iby_external_payees_all epa,
                 iby_pmt_instr_uses_all  piu,
                 iby_ext_bank_accounts   eba,
                 ap_invoices_all         aia,
                 ap_supplier_sites_all   ss
           WHERE sup.vendor_id = ss.vendor_id
             AND ss.vendor_site_id = epa.supplier_site_id
             AND sup.party_id = epa.payee_party_id
             AND epa.ext_payee_id = piu.ext_pmt_party_id
             AND piu.instrument_id = eba.ext_bank_account_id
             AND aia.vendor_id = sup.vendor_id
                --AND aia.invoice_num = c_ap.facture_ap
             AND aia.invoice_id = v_id_facture_ap
             AND aia.org_id = epa.org_id
             AND epa.supplier_site_id = ss.vendor_site_id
             AND eba.bank_account_type = 'SUPPLIER'
             AND aia.vendor_site_id = ss.vendor_site_id
             and eba.bank_account_num is not null;
        EXCEPTION
          WHEN OTHERS THEN
            v_bank_account_num := NULL;

        END;
        BEGIN
          SELECT template_name, template_id
            INTO v_modele_reglement, v_id_modele_reglement
            FROM ap_payment_templates
           WHERE payment_method_code = v_payment_method_code
             AND template_name =
                 v_uo || '_' || v_region || '_' || g_template_reg;
        EXCEPTION
          WHEN OTHERS THEN
            dka_tools_pkg.put_outdebug_message('pas de modele : ' || v_uo || '_' ||
                                               v_region || '_' ||
                                               g_template_reg || ' et ' ||
                                               v_payment_method_code);
            v_modele_reglement    := NULL;
            v_id_modele_reglement := NULL;

        END;

        BEGIN

          UPDATE DKA_PREL_AP_RB
             SET last_updated_date_ap        = SYSDATE,
                 updated_by_ap               = g_user_id,
                 id_facture_ap               = v_id_facture_ap,
                 facture_ap                  = v_facture_ap,
                 fournisseur_ap              = v_fournisseur_ap,
                 vendor_id_ap                = v_vendor_id_ap,
                 montant                     = v_montant,
                 code_devise_ap              = v_code_devise_ap,
                 id_modele_reglement         = v_id_modele_reglement,
                 modele_reglement            = v_modele_reglement,
                 priorite_origine            = nvl(priorite_origine,
                                                   v_priorite_origine),
                 exclusive_payment_flag_org  = nvl(exclusive_payment_flag_org,
                                                   v_exclusive_payment_flag),
                 external_bank_account_id    = v_ext_bank_account,
                 statut_maj_echeancier       = v_statut_maj_echeancier,
                 statut_reference            = v_statut_reference,
                 causes_rejet_maj_echeancier = v_causes_rejet_maj_echeancier,
                 bank_account_num_org        = nvl(v_bank_account_num,
                                                   bank_account_num_org),
                 uo_ap                       = v_uo_ap,
         NUM_FOURNISSEUR_AP          = v_num_fournisseur_ap,
                 STATUT_ETAPE                = 'E2',
                 statut_identification       = 'Y'

            WHERE identifiant_ligne_rb = r_facture_rb.identifiant_ligne_rb
        and   rowid                = r_facture_rb.rowid;

        EXCEPTION

          WHEN OTHERS THEN
            p_retcode := 1;
            dka_tools_pkg.put_outdebug_message('problème d''update dans la table  DKA_PREL_AP_RB :RB ' ||
                                               SQLCODE || ' - ' || SQLERRM);

        END;

      END IF;

    END LOOP;
  


  --EDB338
  --Recuperation de la date de debut d''extraction depuis la table DKA_PARAMETERS
  SELECT
            VARCHAR2_VALUE
        INTO VV_DATE_DEBUT
        FROM
            DKA_PARAMETERS
        WHERE
            PARAMETER_NAME = 'DKA_SAPPRELAUTORB_DATE_EXT';
    
  --purge
  DELETE FROM DKA_PREL_AP_RB_TMP_1;
  DELETE FROM DKA_PREL_AP_RB_TMP_2;
  
  
   BEGIN
    
    INSERT INTO DKA_PREL_AP_RB_TMP_1
       SELECT DISTINCT AIA.INVOICE_ID id_fact_ap,
              AIA.INVOICE_NUM fact_ap,
              AIA.PAYMENT_METHOD_CODE payment_method_code,
              AIA.EXCLUSIVE_PAYMENT_FLAG exclusive_payment_flag,
              APSA.PAYMENT_PRIORITY priorite_origine_inv,
              AIA.PAYMENT_CURRENCY_CODE code_devise_inv,
              PV.VENDOR_NAME frs_ap,
              PV.VENDOR_ID frs_id_ap,
              PV.SEGMENT1 num_frs_ap,
              HOU.NAME UO_INV,
              SUBSTR(HOU.NAME, 1, 3) region_edf,
              SUBSTR(HOU.NAME, 4) uo_edf,
              AIA.INVOICE_AMOUNT montant_inv,
              AIA.PAYMENT_STATUS_FLAG PAYMENT_STATUS_FLAG,
              AIA.INVOICE_TYPE_LOOKUP_CODE INVOICE_TYPE_LOOKUP_CODE,
              AIA.WFAPPROVAL_STATUS WFAPPROVAL_STATUS,
              APSA.DUE_DATE DUE_DATE,
              APSA.HOLD_FLAG HOLD_FLAG,
              
              Rb.*,
              
              (select count(1) --distinct 1
               from ap_invoices_all ai,
         AP_PAYMENT_SCHEDULES_ALL aps
              where ai.VENDOR_ID = PV.VENDOR_ID
                and ai.INVOICE_ID != aia.INVOICE_ID
        
        AND AI.INVOICE_ID = aps.INVOICE_ID
        
                AND AI.CREATION_DATE >=
                  TO_date(VV_DATE_DEBUT, 'DD/MM/YYYY')
                AND INSTR(AI.ATTRIBUTE9, 'CE') > 0
                AND AI.SOURCE = 'AMONTS'
                AND INSTR(AI.DESCRIPTION, rb.NUMERO_CPT_FACTURATION_RB) > 0
                 --AND ai.invoice_amount = aia.invoice_amount
                AND (-1 * aia.invoice_amount) = Rb.montant_rb
                AND HOU.ORGANIZATION_ID = AI.ORG_ID
                --AND HOU.ORGANIZATION_ID = AIA.ORG_ID
                AND (-1 * ai.invoice_amount) = Rb.montant_rb
        AND ap_invoices_pkg.get_approval_status(ai.INVOICE_ID,ai.invoice_amount,AI.PAYMENT_STATUS_FLAG,AI.INVOICE_TYPE_LOOKUP_CODE) = 
            ap_invoices_pkg.get_approval_status(aia.INVOICE_ID,aia.invoice_amount,AIA.PAYMENT_STATUS_FLAG,AIA.INVOICE_TYPE_LOOKUP_CODE)
              AND ap_invoices_pkg.get_approval_status(ai.INVOICE_ID,ai.invoice_amount,AI.PAYMENT_STATUS_FLAG,AI.INVOICE_TYPE_LOOKUP_CODE) = 'APPROVED'
    
    AND ap_invoices_pkg.get_posting_status(ai.INVOICE_ID) = ap_invoices_pkg.get_posting_status(aia.INVOICE_ID)
        AND ap_invoices_pkg.get_posting_status(ai.INVOICE_ID) = 'Y'       
    
    AND AI.PAYMENT_STATUS_FLAG = AIA.PAYMENT_STATUS_FLAG 
        AND AI.PAYMENT_STATUS_FLAG = 'N'  
    
    AND AI.PAYMENT_METHOD_CODE = AIA.PAYMENT_METHOD_CODE
        AND AI.PAYMENT_METHOD_CODE = 'WIRE'
    
    AND AI.WFAPPROVAL_STATUS = AIA.WFAPPROVAL_STATUS
        AND AI.WFAPPROVAL_STATUS = 'WFAPPROVED'
    
        AND (
          select COUNT(*)
            from ap_holds_all
             where invoice_id = ai.INVOICE_ID
             and release_lookup_code is null
        ) = 0
    
    --- blocage
    AND (
      select COUNT(*)
            from ap_holds_all
           where invoice_id = ai.INVOICE_ID
             and release_lookup_code is null
    ) = (
      select COUNT(*)
            from ap_holds_all
           where invoice_id = aia.INVOICE_ID
             and release_lookup_code is null
    )
  ----
        
    and aps.DUE_DATE = APSA.DUE_DATE
        and aps.DUE_DATE <= sysdate
        
    and aps.HOLD_FLAG = APSA.HOLD_FLAG
        And aps.HOLD_FLAG = 'N'
        ) mult_line,
              
              (select count(1) --distinct 1
               from ap_invoices_all ai,
        AP_PAYMENT_SCHEDULES_ALL aps
              where ai.VENDOR_ID = PV.VENDOR_ID
                and ai.INVOICE_ID != aia.INVOICE_ID
        AND AI.INVOICE_ID = aps.INVOICE_ID
                AND AI.CREATION_DATE >=
                  TO_date(VV_DATE_DEBUT, 'DD/MM/YYYY')
                AND INSTR(AI.ATTRIBUTE9, 'CE') > 0
                AND AI.SOURCE = 'AMONTS'
                AND INSTR(AI.DESCRIPTION, rb.NUMERO_CPT_FACTURATION_RB) > 0
                 --AND ai.invoice_amount = aia.invoice_amount
                --AND (-1 * aia.invoice_amount) != Rb.montant_rb
                AND HOU.ORGANIZATION_ID != AI.ORG_ID
                --AND HOU.ORGANIZATION_ID != AIA.ORG_ID
                AND (-1 * ai.invoice_amount) != Rb.montant_rb
        AND ap_invoices_pkg.get_approval_status(ai.INVOICE_ID,ai.invoice_amount,AI.PAYMENT_STATUS_FLAG,AI.INVOICE_TYPE_LOOKUP_CODE) != 'APPROVED'
        AND ap_invoices_pkg.get_posting_status(ai.INVOICE_ID) != 'Y'
        AND AI.PAYMENT_STATUS_FLAG != 'N'        
        AND AI.PAYMENT_METHOD_CODE != 'WIRE'
        AND AI.WFAPPROVAL_STATUS != 'WFAPPROVED'
        AND (
          select COUNT(*)
            from ap_holds_all
             where invoice_id = ai.INVOICE_ID
             and release_lookup_code is null
        ) != 0
        
        and aps.DUE_DATE > sysdate
        
        and aps.HOLD_FLAG != 'N') mult_line_ko,
              ---
              hou.ORGANIZATION_ID org_id_rb,
              aia.org_id          org_id_inv,
              
              Rb.rowid row_id
      
      FROM AP_INVOICES_ALL          AIA,
         AP_PAYMENT_SCHEDULES_ALL APSA,
         AP_SUPPLIERS             PV,
         HR_OPERATING_UNITS       HOU,
         DKA_PREL_AP_RB           rb
       WHERE AIA.INVOICE_ID = APSA.INVOICE_ID
        
       AND AIA.VENDOR_ID = PV.VENDOR_ID
        
       AND PV.VENDOR_ID =
         (select dstl.param3_value
          from DKA_STRANSCO_LINES DSTL, DKA_STRANSCO_HEADERS DSTH
           where DSTL.SET_ID = DSTH.SET_ID
           AND DSTH.SET_NAME LIKE 'DKA_TRANSCO_FRN_CPTFACAP_RB'
           AND DSTL.ENABLE = 'Y'
           AND NVL(DSTL.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE))
        
       AND HOU.ORGANIZATION_ID = AIA.ORG_ID
       AND HOU.NAME = rb.UO_COMPTE_BANCAIRE
       and rb.statut_reference IS NULL
       AND rb.NUMERO_CPT_FACTURATION_RB IS NOT NULL
       AND INSTR(AIA.DESCRIPTION, rb.NUMERO_CPT_FACTURATION_RB) > 0
       AND AIA.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
       AND AIA.CREATION_DATE >= TO_date(VV_DATE_DEBUT, 'DD/MM/YYYY')
       AND INSTR(AIA.ATTRIBUTE9, 'CE') > 0
       AND AIA.SOURCE = 'AMONTS'
     
     union
      -- Récupérer les cas Incohérence UO
      SELECT DISTINCT AIA.INVOICE_ID id_fact_ap,
              AIA.INVOICE_NUM fact_ap,
              AIA.PAYMENT_METHOD_CODE payment_method_code,
              AIA.EXCLUSIVE_PAYMENT_FLAG exclusive_payment_flag,
              APSA.PAYMENT_PRIORITY priorite_origine_inv,
              AIA.PAYMENT_CURRENCY_CODE code_devise_inv,
              PV.VENDOR_NAME frs_ap,
              PV.VENDOR_ID frs_id_ap,
              PV.SEGMENT1 num_frs_ap,
              HOU.NAME UO_INV,
              SUBSTR(HOU.NAME, 1, 3) region_edf,
              SUBSTR(HOU.NAME, 4) uo_edf,
              AIA.INVOICE_AMOUNT montant_inv,
              AIA.PAYMENT_STATUS_FLAG PAYMENT_STATUS_FLAG,
              AIA.INVOICE_TYPE_LOOKUP_CODE INVOICE_TYPE_LOOKUP_CODE,
              AIA.WFAPPROVAL_STATUS WFAPPROVAL_STATUS,
              APSA.DUE_DATE DUE_DATE,
              APSA.HOLD_FLAG HOLD_FLAG,
              
              Rb.*,
              
              (select count(1) --distinct 1
               from ap_invoices_all ai,
         AP_PAYMENT_SCHEDULES_ALL aps
              where ai.VENDOR_ID = PV.VENDOR_ID
                and ai.INVOICE_ID != aia.INVOICE_ID
        
        AND AI.INVOICE_ID = aps.INVOICE_ID
        
                AND AI.CREATION_DATE >=
                  TO_date(VV_DATE_DEBUT, 'DD/MM/YYYY')
                AND INSTR(AI.ATTRIBUTE9, 'CE') > 0
                AND AI.SOURCE = 'AMONTS'
                AND INSTR(AI.DESCRIPTION, rb.NUMERO_CPT_FACTURATION_RB) > 0
                 --AND ai.invoice_amount = aia.invoice_amount
                AND (-1 * aia.invoice_amount) = Rb.montant_rb
                AND HOU.ORGANIZATION_ID = AI.ORG_ID
                --AND HOU.ORGANIZATION_ID = AIA.ORG_ID
                AND (-1 * ai.invoice_amount) = Rb.montant_rb
        AND ap_invoices_pkg.get_approval_status(ai.INVOICE_ID,ai.invoice_amount,AI.PAYMENT_STATUS_FLAG,AI.INVOICE_TYPE_LOOKUP_CODE) = 
            ap_invoices_pkg.get_approval_status(aia.INVOICE_ID,aia.invoice_amount,AIA.PAYMENT_STATUS_FLAG,AIA.INVOICE_TYPE_LOOKUP_CODE)
              AND ap_invoices_pkg.get_approval_status(ai.INVOICE_ID,ai.invoice_amount,AI.PAYMENT_STATUS_FLAG,AI.INVOICE_TYPE_LOOKUP_CODE) = 'APPROVED'
    
    AND ap_invoices_pkg.get_posting_status(ai.INVOICE_ID) = ap_invoices_pkg.get_posting_status(aia.INVOICE_ID)
        AND ap_invoices_pkg.get_posting_status(ai.INVOICE_ID) = 'Y'       
    
    AND AI.PAYMENT_STATUS_FLAG = AIA.PAYMENT_STATUS_FLAG 
        AND AI.PAYMENT_STATUS_FLAG = 'N'  
    
    AND AI.PAYMENT_METHOD_CODE = AIA.PAYMENT_METHOD_CODE
        AND AI.PAYMENT_METHOD_CODE = 'WIRE'
    
    AND AI.WFAPPROVAL_STATUS = AIA.WFAPPROVAL_STATUS
        AND AI.WFAPPROVAL_STATUS = 'WFAPPROVED'
    
        AND (
          select COUNT(*)
            from ap_holds_all
             where invoice_id = ai.INVOICE_ID
             and release_lookup_code is null
        ) = 0
    
    --- blocage
    AND (
      select COUNT(*)
            from ap_holds_all
           where invoice_id = ai.INVOICE_ID
             and release_lookup_code is null
    ) = (
      select COUNT(*)
            from ap_holds_all
           where invoice_id = aia.INVOICE_ID
             and release_lookup_code is null
    )
  ----
        
    and aps.DUE_DATE = APSA.DUE_DATE
        and aps.DUE_DATE <= sysdate
        
    and aps.HOLD_FLAG = APSA.HOLD_FLAG
        And aps.HOLD_FLAG = 'N'
    ) mult_line,
              
              (select count(1) --distinct 1
               from ap_invoices_all ai,
        AP_PAYMENT_SCHEDULES_ALL aps
              where ai.VENDOR_ID = PV.VENDOR_ID
                and ai.INVOICE_ID != aia.INVOICE_ID
        AND AI.INVOICE_ID = aps.INVOICE_ID
                AND AI.CREATION_DATE >=
                  TO_date(VV_DATE_DEBUT, 'DD/MM/YYYY')
                AND INSTR(AI.ATTRIBUTE9, 'CE') > 0
                AND AI.SOURCE = 'AMONTS'
                AND INSTR(AI.DESCRIPTION, rb.NUMERO_CPT_FACTURATION_RB) > 0
                 --AND ai.invoice_amount = aia.invoice_amount
                --AND (-1 * aia.invoice_amount) != Rb.montant_rb
                AND HOU.ORGANIZATION_ID != AI.ORG_ID
                --AND HOU.ORGANIZATION_ID != AIA.ORG_ID
                AND (-1 * ai.invoice_amount) != Rb.montant_rb
        AND ap_invoices_pkg.get_approval_status(ai.INVOICE_ID,ai.invoice_amount,AI.PAYMENT_STATUS_FLAG,AI.INVOICE_TYPE_LOOKUP_CODE) != 'APPROVED'
        AND ap_invoices_pkg.get_posting_status(ai.INVOICE_ID) != 'Y'
        AND AI.PAYMENT_STATUS_FLAG != 'N'        
        AND AI.PAYMENT_METHOD_CODE != 'WIRE'
        AND AI.WFAPPROVAL_STATUS != 'WFAPPROVED'
        AND (
          select COUNT(*)
            from ap_holds_all
             where invoice_id = ai.INVOICE_ID
             and release_lookup_code is null
        ) != 0
        
        and aps.DUE_DATE > sysdate
        
        and aps.HOLD_FLAG != 'N') mult_line_ko,
              ---
              hou.ORGANIZATION_ID org_id_rb,
              aia.org_id          org_id_inv,
              
              Rb.rowid row_id
      
      FROM AP_INVOICES_ALL          AIA,
         AP_PAYMENT_SCHEDULES_ALL APSA,
         AP_SUPPLIERS             PV,
         HR_OPERATING_UNITS       HOU,
         DKA_PREL_AP_RB           rb
       WHERE AIA.INVOICE_ID = APSA.INVOICE_ID
        
       AND AIA.VENDOR_ID = PV.VENDOR_ID
        
       AND PV.VENDOR_ID =
         (select dstl.param3_value
          from DKA_STRANSCO_LINES DSTL, DKA_STRANSCO_HEADERS DSTH
           where DSTL.SET_ID = DSTH.SET_ID
           AND DSTH.SET_NAME LIKE 'DKA_TRANSCO_FRN_CPTFACAP_RB'
           AND DSTL.ENABLE = 'Y'
           AND NVL(DSTL.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE))
        
        AND HOU.ORGANIZATION_ID = AIA.ORG_ID
        and HOU.NAME != rb.UO_COMPTE_BANCAIRE
       and rb.statut_reference IS NULL
       AND rb.NUMERO_CPT_FACTURATION_RB IS NOT NULL
       AND INSTR(AIA.DESCRIPTION, rb.NUMERO_CPT_FACTURATION_RB) > 0
       AND AIA.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
       AND AIA.CREATION_DATE >= TO_date(VV_DATE_DEBUT, 'DD/MM/YYYY')
       AND INSTR(AIA.ATTRIBUTE9, 'CE') > 0
       AND AIA.SOURCE = 'AMONTS'
     
      ;
    
    INSERT INTO DKA_PREL_AP_RB_TMP_2
    select rb.rowid row_id,
       rb.*
       from DKA_PREL_AP_RB rb
       ,AP_SUPPLIERS pv
    where vendor_id_rb = pv.vendor_id
    and pv.vendor_id = (
        select dstl.param3_value
    from 
     DKA_STRANSCO_LINES DSTL,
       DKA_STRANSCO_HEADERS DSTH
       where  DSTL.SET_ID = DSTH.SET_ID
     AND DSTH.SET_NAME LIKE 'DKA_TRANSCO_FRN_CPTFACAP_RB'
    AND DSTL.ENABLE = 'Y'
    AND NVL(DSTL.END_DATE, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
    )
     and rb.statut_reference IS NULL
     AND rb.NUMERO_CPT_FACTURATION_RB IS NOT NULL
    and not exists
    (
        select 1
        from AP_INVOICES_ALL aia
        where INSTR(AIA.DESCRIPTION,rb.NUMERO_CPT_FACTURATION_RB)>0
     AND AIA.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
     AND AIA.CREATION_DATE >=TO_date(VV_DATE_DEBUT, 'DD/MM/YYYY')
     AND INSTR(AIA.ATTRIBUTE9,'CE')>0
     AND AIA.SOURCE = 'AMONTS'
     AND AIA.VENDOR_ID = PV.VENDOR_ID
     );
      
    commit;
   
   END;

  
    FOR r_facture_rb_edf IN c_facture_rb_edf LOOP

    v_flag_erreur_edf                 := FALSE;
      v_notfoundinvoice_edf             := FALSE;
      v_multipleinvoice_edf             := FALSE;
    v_foundinvoice_edf                := FALSE;
      v_causes_rejet_maj_ech_edf := NULL;
    v_id_facture_ap_edf               := NULL;
      v_facture_ap_edf                  := NULL;
      v_payment_method_code_edf         := NULL;
      v_exclusive_payment_flag_edf      := NULL;
      v_priorite_origine_edf            := NULL;
      v_code_devise_ap_edf              := NULL;
      v_fournisseur_ap_edf              := NULL;
      v_vendor_id_ap_edf                := NULL;
    v_num_fournisseur_ap_edf          := NULL;
      v_uo_ap_edf                       := NULL;
      v_region_edf                      := NULL;
      v_uo_edf                          := NULL;
      v_montant_edf                     := NULL;
      v_payment_status_flag_edf         := NULL;
      v_invoice_type_lookup_code_edf    := NULL;
      v_wfapproval_status_edf           := NULL;
      v_due_date_edf                    := NULL;
      v_hold_flag_edf                   := NULL;
    v_modele_reglement_edf            := NULL;
    v_id_modele_reglement_edf         := NULL;
    v_status_edf                      := NULL;
      g_lignes_rb_traitees          := g_lignes_rb_traitees + 1;


    BEGIN


     v_id_facture_ap_edf := r_facture_rb_edf.id_fact_ap;
     v_facture_ap_edf := r_facture_rb_edf.fact_ap;
     v_payment_method_code_edf := r_facture_rb_edf.payment_method_code;
     v_exclusive_payment_flag_edf := r_facture_rb_edf.exclusive_payment_flag;
     v_priorite_origine_edf := r_facture_rb_edf.priorite_origine_inv;
     v_code_devise_ap_edf := r_facture_rb_edf.code_devise_inv;
     v_fournisseur_ap_edf := r_facture_rb_edf.frs_ap;
     v_vendor_id_ap_edf := r_facture_rb_edf.frs_id_ap;
     v_num_fournisseur_ap_edf := r_facture_rb_edf.num_frs_ap;
     v_uo_ap_edf := r_facture_rb_edf.UO_INV;
     v_region_edf := r_facture_rb_edf.region_edf;
     v_uo_edf := r_facture_rb_edf.uo_edf;
     v_montant_edf := r_facture_rb_edf.montant_inv;
     v_payment_status_flag_edf := r_facture_rb_edf.PAYMENT_STATUS_FLAG;
     v_invoice_type_lookup_code_edf := r_facture_rb_edf.INVOICE_TYPE_LOOKUP_CODE;
     v_wfapproval_status_edf := r_facture_rb_edf.WFAPPROVAL_STATUS;
     v_due_date_edf := r_facture_rb_edf.DUE_DATE;
     v_hold_flag_edf := r_facture_rb_edf.HOLD_FLAG;
   

    END;


      
    IF NVL(r_facture_rb_edf.mult_line_ko,0) > 0 OR NVL(r_facture_rb_edf.mult_line,0) > 0 THEN
    v_multipleinvoice_edf   := true;
    END IF;

      IF v_multipleinvoice_edf THEN
        v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                         ' - ' || 'Plusieurs factures pour le compte de facturation';
        v_flag_erreur_edf                 := true;

      ELSE
        BEGIN
          select COUNT(*)
            into v_blocage_edf
            from ap_holds_all
           where invoice_id = v_id_facture_ap_edf
             and release_lookup_code is null;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_blocage_edf := 0;

        END;


    if r_facture_rb_edf.UO_INV != r_facture_rb_edf.UO_COMPTE_BANCAIRE then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Incohérence Compte Facturation'; --'Incohérence UO';
          v_flag_erreur_edf                 := true;
        END IF;



        if v_fournisseur_ap_edf != r_facture_rb_edf.fournisseur_rb then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' ||
                                           'Incohérence Fournisseur';
          v_flag_erreur_edf                 := true;
        END IF;



        if (-1 * v_montant_edf) != r_facture_rb_edf.montant_rb then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Incohérence Montant';
          v_flag_erreur_edf                 := true;
        END IF;
        IF (ap_invoices_pkg.get_approval_status(v_id_facture_ap_edf,
                                                v_montant_edf,
                                                v_payment_status_flag_edf,
                                                v_invoice_type_lookup_code_edf) !=
           'APPROVED') THEN
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Non validée';
          v_flag_erreur_edf                 := true;

        END IF;
        IF (ap_invoices_pkg.get_posting_status(v_id_facture_ap_edf) != 'Y') THEN
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Non Comptabilisée';
          v_flag_erreur_edf                 := true;
        END IF;

        if v_payment_status_flag_edf != 'N' then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Réglée';
          v_flag_erreur_edf                 := true;
        END IF;

        if v_payment_method_code_edf != 'WIRE' then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' ||
                                           'Mode de règlement différent';
          v_flag_erreur_edf                 := true;
        END IF;

        if v_wfapproval_status_edf != 'WFAPPROVED' then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' ||
                                           'Workflow non approuvé';
          v_flag_erreur_edf                 := true;
        END IF;

        if v_due_date_edf > sysdate then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Non échue';
          v_flag_erreur_edf                 := true;
        END IF;

        if nvl(v_hold_flag_edf, 'Y') != 'N'  then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Blocage échéancier';
          v_flag_erreur_edf                 := true;
        END IF;
     if v_blocage_edf != 0 then
          v_causes_rejet_maj_ech_edf := v_causes_rejet_maj_ech_edf ||
                                           ' - ' || 'Blocage ouvert';
          v_flag_erreur_edf                 := true;
        END IF;

      END IF;
      if v_flag_erreur_edf then
     if v_status_edf = 'P'
      then
    v_statut_reference_edf      := 'P';
    else
        v_statut_reference_edf      := 'R';
     END IF ;
        v_statut_maj_echeancier_edf := v_statut_maj_echeancier_edf;
        g_lignes_non_mis_a_jour := g_lignes_non_mis_a_jour + 1;
        BEGIN
    
     
    
          UPDATE DKA_PREL_AP_RB_TMP_1--DKA_PREL_AP_RB
             SET last_updated_date_ap        = SYSDATE,
                 updated_by_ap               = g_user_id,
                 id_facture_ap               = v_id_facture_ap_edf,
                 facture_ap                  = v_facture_ap_edf,
                 fournisseur_ap              = v_fournisseur_ap_edf,
                 vendor_id_ap                = v_vendor_id_ap_edf,
                 montant                     = v_montant_edf,
                 code_devise_ap              = v_code_devise_ap_edf,
                 id_modele_reglement         = v_id_modele_reglement_edf,
                 modele_reglement            = v_modele_reglement_edf,
                 priorite_origine            = nvl(priorite_origine,
                                                   v_priorite_origine_edf),
                 exclusive_payment_flag_org  = nvl(exclusive_payment_flag_org,
                                                   v_exclusive_payment_flag_edf),
                 external_bank_account_id    = v_ext_bank_account_edf,
                 statut_reference            = v_statut_reference_edf,
                 causes_rejet_maj_echeancier = v_causes_rejet_maj_ech_edf,
                 bank_account_num_org        = nvl(v_bank_account_num_edf,
                                                   bank_account_num_org),
                 uo_ap                       = v_uo_ap_edf,
         NUM_FOURNISSEUR_AP          = v_num_fournisseur_ap_edf,
                 statut_maj_echeancier       = 'N',
                 STATUT_ETAPE                = 'E1',
                 statut_identification       = 'N'
           WHERE identifiant_ligne_rb = r_facture_rb_edf.identifiant_ligne_rb
           --and   row_id                = r_facture_rb_edf.row_id;
       and montant_inv = r_facture_rb_edf.montant_inv
       AND id_fact_ap = r_facture_rb_edf.id_fact_ap;

        EXCEPTION

          WHEN OTHERS THEN
            p_retcode := 1;
            dka_tools_pkg.put_outdebug_message('problème d''UPDATE de la table  DKA_PREL_AP_RB_TMP_1 :RB ' ||
                                               SQLCODE || ' - ' || SQLERRM);
      dka_tools_pkg.put_outdebug_message('rowid :  ' ||
                                               r_facture_rb_edf.row_id);
        END;
      ELSE
        g_lignes_mis_a_jour     := g_lignes_mis_a_jour + 1;
        v_statut_reference_edf      := 'A';
        v_statut_maj_echeancier_edf := null;

        BEGIN
          SELECT eba.bank_account_num, ext_bank_account_id

            INTO v_bank_account_num_edf, v_ext_bank_account_edf
            FROM ap_suppliers            sup,
                 iby_external_payees_all epa,
                 iby_pmt_instr_uses_all  piu,
                 iby_ext_bank_accounts   eba,
                 ap_invoices_all         aia,
                 ap_supplier_sites_all   ss
           WHERE sup.vendor_id = ss.vendor_id
             AND ss.vendor_site_id = epa.supplier_site_id
             AND sup.party_id = epa.payee_party_id
             AND epa.ext_payee_id = piu.ext_pmt_party_id
             AND piu.instrument_id = eba.ext_bank_account_id
             AND aia.vendor_id = sup.vendor_id
             AND aia.invoice_id = v_id_facture_ap_edf
             AND aia.org_id = epa.org_id
             AND epa.supplier_site_id = ss.vendor_site_id
             AND eba.bank_account_type = 'SUPPLIER'
             AND aia.vendor_site_id = ss.vendor_site_id
             and eba.bank_account_num is not null;
        EXCEPTION
          WHEN OTHERS THEN
            v_bank_account_num_edf := NULL;

        END;
        BEGIN
          SELECT template_name, template_id
            INTO v_modele_reglement_edf, v_id_modele_reglement_edf
            FROM ap_payment_templates
           WHERE payment_method_code = v_payment_method_code_edf
             AND template_name =
                 v_uo_edf || '_' || v_region_edf || '_' || g_template_reg;
        EXCEPTION
          WHEN OTHERS THEN
            dka_tools_pkg.put_outdebug_message('pas de modele : ' || v_uo_edf || '_' ||
                                               v_region_edf || '_' ||
                                               g_template_reg || ' et ' ||
                                               v_payment_method_code_edf);
            v_modele_reglement_edf    := NULL;
            v_id_modele_reglement_edf := NULL;

        END;

        BEGIN

            
    UPDATE DKA_PREL_AP_RB_TMP_1--DKA_PREL_AP_RB
         SET last_updated_date_ap        = SYSDATE,
           updated_by_ap               = g_user_id,
           id_facture_ap               = v_id_facture_ap_edf,
           facture_ap                  = v_facture_ap_edf,
           fournisseur_ap              = v_fournisseur_ap_edf,
           vendor_id_ap                = v_vendor_id_ap_edf,
           montant                     = v_montant_edf,
           code_devise_ap              = v_code_devise_ap_edf,
           id_modele_reglement         = v_id_modele_reglement_edf,
           modele_reglement            = v_modele_reglement_edf,
           priorite_origine            = nvl(priorite_origine,
                             v_priorite_origine_edf),
           exclusive_payment_flag_org  = nvl(exclusive_payment_flag_org,
                             v_exclusive_payment_flag_edf),
           external_bank_account_id    = v_ext_bank_account_edf,
           statut_maj_echeancier       = v_statut_maj_echeancier_edf,
           statut_reference            = v_statut_reference_edf,
           causes_rejet_maj_echeancier = v_causes_rejet_maj_ech_edf,
           bank_account_num_org        = nvl(v_bank_account_num_edf,
                             bank_account_num_org),
           uo_ap                       = v_uo_ap_edf,
       NUM_FOURNISSEUR_AP          = v_num_fournisseur_ap_edf,
           STATUT_ETAPE                = 'E2',
           statut_identification       = 'Y'
         WHERE identifiant_ligne_rb = r_facture_rb_edf.identifiant_ligne_rb
       and montant_inv = r_facture_rb_edf.montant_inv
       AND id_fact_ap = r_facture_rb_edf.id_fact_ap;
    
        EXCEPTION

          WHEN OTHERS THEN
            p_retcode := 1;
            dka_tools_pkg.put_outdebug_message('problème d''update dans la table  DKA_PREL_AP_RB_TMP_1 E2 :RB ' ||
                                               SQLCODE || ' - ' || SQLERRM);

        END;

      END IF;

    END LOOP;

  v_causes_rejet_maj_ech_edf := NULL;

  FOR r_fact_ko IN c_fact_edf_ko LOOP

        g_lignes_non_mis_a_jour := g_lignes_non_mis_a_jour + 1;
        BEGIN
      
    
          UPDATE DKA_PREL_AP_RB_TMP_2--DKA_PREL_AP_RB
             SET last_updated_date_ap        = SYSDATE,
                 updated_by_ap               = g_user_id,
                 id_facture_ap               = null,
                 facture_ap                  = null,
                 fournisseur_ap              = null,
                 vendor_id_ap                = null,
                 montant                     = null,
                 code_devise_ap              = null,
                 id_modele_reglement         = null,
                 modele_reglement            = null,
                 priorite_origine            = priorite_origine,
                 exclusive_payment_flag_org  = exclusive_payment_flag_org ,
                 external_bank_account_id    = null,
                 statut_reference            = 'P',
                 causes_rejet_maj_echeancier = ' - ' || 'Incohérence Compte Facturation',
                 bank_account_num_org        = bank_account_num_org,
                 uo_ap                       = null,
         NUM_FOURNISSEUR_AP          = null,
                 statut_maj_echeancier       = 'N',
                 STATUT_ETAPE                = 'E1',
                 statut_identification       = 'N'
         
           WHERE identifiant_ligne_rb = r_fact_ko.identifiant_ligne_rb
           and   row_id                = r_fact_ko.row_id;

        EXCEPTION

          WHEN OTHERS THEN
            p_retcode := 1;
            dka_tools_pkg.put_outdebug_message('problème d''UPDATE de la table  DKA_TSTT partie 2:RB ' ||
                                               SQLCODE || ' - ' || SQLERRM);

        END;

  END LOOP;
  
  BEGIN
    
    INSERT INTO DKA_PREL_AP_RB
      SELECT
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATED_DATE_RB,
      UPDATED_BY_RB,
      IDENTIFIANT_LIGNE_RB,
      TYPE_LIGNE_RB,
      DATE_OPERATION,
      DATE_VALEUR,
      LIBELLE_LONG,
      MATCHING_STATUS_RB,
      NUMERO_FACTURE_RB,
      FOURNISSEUR_RB,
      ID_COMPTE_BANCAIRE,
      NUMERO_COMPTE_INTER,
      UO_COMPTE_BANCAIRE,
      REGION,
      NUMERO_SOCIETE,
      MONTANT_RB,
      CODE_DEVISE_RB,
      STATUT_REFERENCE,
      REFERENCE2,
      CAUSE_REJET_ALIMENTATION,
      LAST_UPDATED_DATE_AP,
      UPDATED_BY_AP,
      ID_FACTURE_AP,
      FACTURE_AP,
      FOURNISSEUR_AP,
      VENDOR_ID_AP,
      MONTANT,
      CODE_DEVISE_AP,
      ID_MODELE_REGLEMENT,
      MODELE_REGLEMENT,
      PRIORITE_ORIGINE,
      EXCLUSIVE_PAYMENT_FLAG_ORG,
      EXTERNAL_BANK_ACCOUNT_ID,
      STATUT_MAJ_ECHEANCIER,
      CAUSES_REJET_MAJ_ECHEANCIER,
      LAST_UPDATED_DATE_REGLEMENT,
      UPDATED_BY_REGLEMENT,
      ID_REGLEMENT,
      NUMERO_REGLEMENT,
      UO_REGLEMENT,
      MONTANT_REGLEMENT,
      CODE_DEVISE_REGLEMENT,
      NOM_MODELE,
      ID_DEMANDE_REGLEMENT,
      STATUT_ETAPE_REGLEMENT,
      MESSAGE_ERREUR,
      LAST_UPDATED_DATE_GL,
      UPDATED_BY_GL,
      STATUT_CENTRALISATION,
      MESSAGE_ERREUR_CENTRALISATION,
      STATUT_IMPUTATION,
      MESSAGE_ERREUR_IMPUTATION,
      ID_PIECE_GL,
      NUMERO_PIECE_GL,
      NUMERO_LIGNE_GL,
      ID_LIGNE_RB_GL,
      LIBELLE_LONG_GL,
      TYPE_LIGNE_RB_GL,
      REFERENCE2_GL,
      STATUT_ALIMENTATION_REF2,
      MESSAGE_ALIMENTATION_REF2,
      MATCHING_STATUS_RB_GL,
      RAPPROCHE_LE,
      COMPTE_BANCAIRE,
      VENDOR_ID_RB,
      BANK_ACCOUNT_NUM_ORG,
      UO_AP,
      STATUT_ETAPE,
      STATUT_IDENTIFICATION,
      NUM_FOURNISSEUR_AP,
      OIB,
      NUMERO_CPT_FACTURATION_RB
      FROM DKA_PREL_AP_RB_TMP_1
      
      UNION
      
      SELECT
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATED_DATE_RB,
      UPDATED_BY_RB,
      IDENTIFIANT_LIGNE_RB,
      TYPE_LIGNE_RB,
      DATE_OPERATION,
      DATE_VALEUR,
      LIBELLE_LONG,
      MATCHING_STATUS_RB,
      NUMERO_FACTURE_RB,
      FOURNISSEUR_RB,
      ID_COMPTE_BANCAIRE,
      NUMERO_COMPTE_INTER,
      UO_COMPTE_BANCAIRE,
      REGION,
      NUMERO_SOCIETE,
      MONTANT_RB,
      CODE_DEVISE_RB,
      STATUT_REFERENCE,
      REFERENCE2,
      CAUSE_REJET_ALIMENTATION,
      LAST_UPDATED_DATE_AP,
      UPDATED_BY_AP,
      ID_FACTURE_AP,
      FACTURE_AP,
      FOURNISSEUR_AP,
      VENDOR_ID_AP,
      MONTANT,
      CODE_DEVISE_AP,
      ID_MODELE_REGLEMENT,
      MODELE_REGLEMENT,
      PRIORITE_ORIGINE,
      EXCLUSIVE_PAYMENT_FLAG_ORG,
      EXTERNAL_BANK_ACCOUNT_ID,
      STATUT_MAJ_ECHEANCIER,
      CAUSES_REJET_MAJ_ECHEANCIER,
      LAST_UPDATED_DATE_REGLEMENT,
      UPDATED_BY_REGLEMENT,
      ID_REGLEMENT,
      NUMERO_REGLEMENT,
      UO_REGLEMENT,
      MONTANT_REGLEMENT,
      CODE_DEVISE_REGLEMENT,
      NOM_MODELE,
      ID_DEMANDE_REGLEMENT,
      STATUT_ETAPE_REGLEMENT,
      MESSAGE_ERREUR,
      LAST_UPDATED_DATE_GL,
      UPDATED_BY_GL,
      STATUT_CENTRALISATION,
      MESSAGE_ERREUR_CENTRALISATION,
      STATUT_IMPUTATION,
      MESSAGE_ERREUR_IMPUTATION,
      ID_PIECE_GL,
      NUMERO_PIECE_GL,
      NUMERO_LIGNE_GL,
      ID_LIGNE_RB_GL,
      LIBELLE_LONG_GL,
      TYPE_LIGNE_RB_GL,
      REFERENCE2_GL,
      STATUT_ALIMENTATION_REF2,
      MESSAGE_ALIMENTATION_REF2,
      MATCHING_STATUS_RB_GL,
      RAPPROCHE_LE,
      COMPTE_BANCAIRE,
      VENDOR_ID_RB,
      BANK_ACCOUNT_NUM_ORG,
      UO_AP,
      STATUT_ETAPE,
      STATUT_IDENTIFICATION,
      NUM_FOURNISSEUR_AP,
      OIB,
      NUMERO_CPT_FACTURATION_RB
      FROM DKA_PREL_AP_RB_TMP_2;
    
    --COMMIT;
  
  END;
   
  BEGIN
     delete from DKA_PREL_AP_RB
     where statut_reference is null;
     
     commit;
  END;
   
  --end edb338

    COMMIT;
  END extract_data2;

  /*=====================================================================================*/
  /* PROCEDURE NAME : main
  /*
  /* DESCRIPTION
  /*  Procédure principale de l'interface d'import des fournisseurs
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/

  PROCEDURE MAIN(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    -- ========== VARIABLES ==========
    v_package        VARCHAR2(30) := 'DKA_SAPPRELAUTORB_PKG'; --'DKA_SRBFACTURE_AP_PKG'; --EDB338
    v_nom_traitement VARCHAR2(200) := 'DKA - Alimenter les références de facture AP dans RB ';
    v_sqlerrm        VARCHAR2(250) := NULL;
    v_nb_erreurs     NUMBER := 0;

    v_procedure VARCHAR2(30) := 'MAIN';
    v_message   VARCHAR2(500);

    v_errbuf  VARCHAR2(2500);
    v_retcode NUMBER;
    v_exeption EXCEPTION;
    v_resp_appl_id fnd_responsibility.application_id%TYPE;
    v_resp_id      fnd_responsibility.responsibility_id%TYPE;

  BEGIN

    -- Début du Programme --
    -- ========Initialisation des variables d'anomalies========
    p_retcode := 0;
    p_errbuf  := NULL;
    v_message := 'Début procédure MAIN';

    -- Initialization des journaux --
    Dka_Tools_Pkg.put_log_message('=======================================================================');
    Dka_Tools_Pkg.put_log_message(v_nom_traitement);
    Dka_Tools_Pkg.put_log_message('=======================================================================');
    Dka_Tools_Pkg.put_log_message('Date de lancement    : ' ||
                                  TO_CHAR(SYSDATE,
                                          'DD-MON-YYYY HH24:MI:SS'));
    -- Initialization de la sortie --

    Dka_Tools_Pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.put_outdebug_message(' COMPTE-RENDU DU TRAITEMENT << ' ||
                                       v_nom_traitement || ' >>');
    Dka_Tools_Pkg.put_outdebug_message(' Traitement n° ' ||
                                       TO_CHAR(g_request_id));
    Dka_Tools_Pkg.put_outdebug_message(' Le  : ' ||
                                       TO_CHAR(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.put_outdebug_message('                                                                ');
    -- Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
    -- Dka_Tools_Pkg.put_log_message('/*Historisation de donnée*/');
    -- Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');

    ARCHIVE_DATA(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE v_exeption;
    END IF;
    -- Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
    -- Dka_Tools_Pkg.put_log_message('/*Extraction de donnée*/');
    -- Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');

    EXTRACT_DATA(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      Dka_Tools_Pkg.put_outdebug_message('Chargement des fichiers en erreur');
      RAISE v_exeption;
    END IF;
    -- Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
    -- Dka_Tools_Pkg.put_log_message('/*Report bilan */');
    -- Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');

    Report_Bilan(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      Dka_Tools_Pkg.put_outdebug_message('Chargement des fichiers en erreur');
      RAISE v_exeption;
    END IF;
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
    ELSIF p_retcode = 1 THEN
      p_errbuf  := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      p_retcode := 1;
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
    END IF;

    COMMIT;

    Dka_Tools_Pkg.put_outdebug_message(CHR(10) || p_errbuf || CHR(10));
    Dka_Tools_Pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.put_outdebug_message('Programme terminé le : ' ||
                                       TO_CHAR(SYSDATE,
                                               'DD/MM/YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');

  EXCEPTION
    WHEN v_exeption THEN
      p_retcode := 2;
      p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
      Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      Dka_Tools_Pkg.put_outdebug_message('Package   : ' || v_package);
      Dka_Tools_Pkg.put_outdebug_message('Procédure : ' || v_procedure);
      Dka_Tools_Pkg.put_outdebug_message('Exception : OTHERS');
      Dka_Tools_Pkg.put_outdebug_message('Message   : ' || v_message);
      Dka_Tools_Pkg.put_log_message('Cause     : ' || p_errbuf);
      Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
      Dka_Tools_Pkg.put_outdebug_message(TO_CHAR(SYSDATE,
                                                 'DD/MM/YYYY HH24:MI:SS') ||
                                         ' - ' || 'Fin de la procédure ' ||
                                         v_procedure ||
                                         ' : EXCEPTION v_exeption ');
      Dka_Tools_Pkg.put_log_message('==> Fin de la procédure ' ||
                                    v_procedure ||
                                    ' : EXCEPTION v_exeption ');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      Dka_Tools_Pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      ROLLBACK;

    WHEN OTHERS THEN
      v_sqlerrm := SUBSTR(SQLERRM, 1, 200);
      p_retcode := 2;
      p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc ' ||
                   v_package || '.' || v_procedure;
      Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      Dka_Tools_Pkg.put_outdebug_message('Package   : ' || v_package);
      Dka_Tools_Pkg.put_outdebug_message('Procédure : ' || v_procedure);
      Dka_Tools_Pkg.put_outdebug_message('Exception : OTHERS');
      Dka_Tools_Pkg.put_outdebug_message('Message   : ' || v_message);
      Dka_Tools_Pkg.put_log_message(CHR(10) || p_errbuf);
      Dka_Tools_Pkg.put_outdebug_message('Cause     : ' || v_sqlerrm);
      Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      Dka_Tools_Pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      ROLLBACK;

  END main;

  /*=====================================================================================*/
  /* PROCEDURE NAME : main2
  /*
  /* DESCRIPTION
  /*  Procédure principale de l'interface d'import des fournisseurs
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/

  PROCEDURE main2(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    -- ========== VARIABLES ==========
    v_package        VARCHAR2(30) := 'DKA_SRBFACTURE_AP_PKG';
    v_nom_traitement VARCHAR2(200) := 'DKA - Identification des factures AP éligibles au rapprochement RB ';
    v_sqlerrm        VARCHAR2(250) := NULL;
    v_nb_erreurs     NUMBER := 0;

    v_procedure VARCHAR2(30) := 'MAIN';
    v_message   VARCHAR2(500);

    v_errbuf  VARCHAR2(2500);
    v_retcode NUMBER;
    v_exeption EXCEPTION;
    v_resp_appl_id fnd_responsibility.application_id%TYPE;
    v_resp_id      fnd_responsibility.responsibility_id%TYPE;

  BEGIN

    -- Début du Programme --
    -- ========Initialisation des variables d'anomalies========
    p_retcode := 0;
    p_errbuf  := NULL;
    v_message := 'Début procédure MAIN';

    -- Initialization des journaux --
    dka_tools_pkg.put_log_message('=======================================================================');
    dka_tools_pkg.put_log_message(v_nom_traitement);
    dka_tools_pkg.put_log_message('=======================================================================');
    dka_tools_pkg.put_log_message('Date de lancement    : ' ||
                                  to_char(SYSDATE,
                                          'DD-MON-YYYY HH24:MI:SS'));
    -- Initialization de la sortie --

    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message(' COMPTE-RENDU DU TRAITEMENT << ' ||
                                       v_nom_traitement || ' >>');
    dka_tools_pkg.put_outdebug_message(' Traitement n° ' ||
                                       to_char(g_request_id));
    dka_tools_pkg.put_outdebug_message(' Le  : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('                                                                ');

    extract_data2(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      dka_tools_pkg.put_outdebug_message('Chargement des fichiers en erreur');
      RAISE v_exeption;
    END IF;

    report_bilan2(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE v_exeption;
    END IF;
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
      UPDATE DKA_PREL_AP_RB
         SET last_updated_date_ap = SYSDATE,
             updated_by_ap        = g_user_id,
             statut_reference     = NULL
       WHERE statut_reference = 'R';

      UPDATE ap_payment_schedules_all
         SET payment_priority = '55',
             last_update_date = SYSDATE,
             last_updated_by  = g_user_id
       WHERE invoice_id IN (SELECT id_facture_ap
                              FROM DKA_PREL_AP_RB
                             WHERE statut_reference = 'A');

      UPDATE iby_ext_bank_accounts
         SET bank_account_num = NULL,
             last_update_date = SYSDATE,
             last_updated_by  = g_user_id
       WHERE ext_bank_account_id IN
             (SELECT external_bank_account_id
                FROM DKA_PREL_AP_RB
               WHERE statut_reference = 'A');

      UPDATE ap_invoices_all
         SET exclusive_payment_flag = 'Y',
             last_update_date       = SYSDATE,
             last_updated_by        = g_user_id
       WHERE invoice_id IN (SELECT id_facture_ap
                              FROM DKA_PREL_AP_RB
                             WHERE statut_reference = 'A');

    ELSIF p_retcode = 1 THEN
      p_errbuf  := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      p_retcode := 1;
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
    END IF;

    COMMIT;

    dka_tools_pkg.put_outdebug_message(chr(10) || p_errbuf || chr(10));
    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('Programme terminé le : ' ||
                                       to_char(SYSDATE,
                                               'DD/MM/YYYY HH24:MI:SS'));
    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');

  EXCEPTION
    WHEN v_exeption THEN
      --p_retcode := 2;
      --p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
      dka_tools_pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_outdebug_message('Package   : ' || v_package);
      dka_tools_pkg.put_outdebug_message('Procédure : ' || v_procedure);
      dka_tools_pkg.put_outdebug_message('Exception : OTHERS');
      dka_tools_pkg.put_outdebug_message('Message   : ' || v_message);
      dka_tools_pkg.put_log_message('Cause     : ' || p_errbuf);
      dka_tools_pkg.put_outdebug_message('------------------------------------------------');
      dka_tools_pkg.put_outdebug_message(to_char(SYSDATE,
                                                 'DD/MM/YYYY HH24:MI:SS') ||
                                         ' - ' || 'Fin de la procédure ' ||
                                         v_procedure ||
                                         ' : EXCEPTION v_exeption ');
      dka_tools_pkg.put_log_message('==> Fin de la procédure ' ||
                                    v_procedure ||
                                    ' : EXCEPTION v_exeption ');
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
      ROLLBACK;

    WHEN OTHERS THEN
      v_sqlerrm := substr(SQLERRM, 1, 200);
      p_retcode := 2;
      p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc ' ||
                   v_package || '.' || v_procedure;
      dka_tools_pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_outdebug_message('Package   : ' || v_package);
      dka_tools_pkg.put_outdebug_message('Procédure : ' || v_procedure);
      dka_tools_pkg.put_outdebug_message('Exception : OTHERS');
      dka_tools_pkg.put_outdebug_message('Message   : ' || v_message);
      dka_tools_pkg.put_log_message(chr(10) || p_errbuf);
      dka_tools_pkg.put_outdebug_message('Cause     : ' || v_sqlerrm);
      dka_tools_pkg.put_outdebug_message('------------------------------------------------');
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
      ROLLBACK;

  END main2;

  /*
   *************************************************************************
   * PROCEDURE NAME : Report_Bilan3
   *
   * DESCRIPTION
   *  Procédure de génération du bilan du traitement d'interface de l'étape 3
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */
  PROCEDURE report_bilan3(p_errbuf IN OUT VARCHAR2, p_retcode IN OUT NUMBER) IS

    vv_message VARCHAR2(2000);
    vv_header          VARCHAR2(500);

    CURSOR c_reg_cree IS
      SELECT id_facture_ap,
             facture_ap,
             id_compte_bancaire,
             numero_compte_inter,
             uo_ap,
             fournisseur_ap,
             montant,
             code_devise_ap,
             id_reglement,
             numero_reglement,
             uo_reglement,
             montant_reglement,
             id_modele_reglement,
             modele_reglement,
             id_demande_reglement,
             statut_etape_reglement
        FROM dka_prel_ap_rb
       WHERE statut_etape = 'E3'
       ORDER BY region, uo_ap, id_facture_ap;

    CURSOR c_reg_non_cree IS
      SELECT id_facture_ap,
             facture_ap,
             id_compte_bancaire,
             numero_compte_inter,
             uo_ap,
             fournisseur_ap,
             montant,
             code_devise_ap,
             statut_etape_reglement,
             message_erreur
        FROM dka_prel_ap_rb
       WHERE statut_etape = 'E2'
         AND statut_etape_reglement = 'N'
         AND message_erreur NOT LIKE 'Absence de configuration%'
       ORDER BY region, uo_ap, id_facture_ap;

    CURSOR c_reg_config IS
      SELECT id_compte_bancaire,
             numero_compte_inter,
             modele_reglement,
             message_erreur
        FROM dka_prel_ap_rb
       WHERE statut_etape = 'E2'
         AND statut_etape_reglement = 'N'
         AND message_erreur LIKE 'Absence de configuration%'
       ORDER BY region, uo_ap, id_compte_bancaire;

  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan3');

    --------------------
    -- Initialisation --
    --------------------

    fnd_file.put_line(fnd_file.output, chr(10));

    fnd_file.put_line(fnd_file.output,
                      '   . Total des lignes traitées : ' ||
                      g_lignes_rg_traitees);
    fnd_file.put_line(fnd_file.output,
                      '   . Total des règlements créés : ' ||
                      g_lignes_rg_crees);
    fnd_file.put_line(fnd_file.output,
                      '   . Total des règlements non créés : ' ||
                      g_lignes_rg_non_crees);
    fnd_file.put_line(fnd_file.output,
                      '   . Total de lignes éligibles avec échéancier de paiement mis à jour : ' ||
                      g_lignes_mis_a_jour);

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      '--------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'Détail des règlements créés :');
    fnd_file.put_line(fnd_file.output, ' ');


    vv_header := rpad('ID facture', 15) || ' | ' || rpad('Numéro facture', 20) || ' | ' ||
             rpad('ID Compte Bqe', 15) || ' | ' ||rpad('Numéro Compte Bqe', 20) || ' | ' ||
             rpad('UO', 8) || ' | ' ||
             rpad('Fournisseur', 20) || ' | ' || rpad('Montant', 10) || ' | ' ||
             rpad('DEVISE', 7) || ' | ' || rpad('ID REGLT', 10) || ' | ' ||
             rpad('Num REGLT', 12)  || ' | ' ||
             rpad('MODELE REGLEMENT', 25)  || ' | ' || rpad('ID DEMANDE REGLT', 16)  || ' | ' ||
             rpad('STATUT ETAPE', 12);

    writeout(vv_header);

    writeout(rpad('-', length(vv_header), '-'));

    dka_tools_pkg.put_log_message('debut reg_cree');
    FOR rec_reg IN c_reg_cree LOOP
      dka_tools_pkg.put_log_message('loop reg_cree');
      vv_message := rpad(rec_reg.id_facture_ap, 15)  || ' | ' ||
                    rpad(rec_reg.facture_ap, 20) || ' | ' ||
                    rpad(rec_reg.id_compte_bancaire, 15) || ' | ' ||
                    rpad(rec_reg.numero_compte_inter, 20) || ' | ' ||
                    rpad(rec_reg.uo_ap, 8) || ' | ' ||
                    rpad( rec_reg.fournisseur_ap, 20) || ' | ' ||
                    rpad(rec_reg.montant, 10) || ' | ' ||
                    rpad(rec_reg.code_devise_ap, 7) || ' | ' ||
                    rpad(rec_reg.id_reglement,  10) || ' | ' ||
                    rpad(rec_reg.numero_reglement,  12) || ' | ' ||
                    rpad(rec_reg.modele_reglement,  25) || ' | ' ||
                    rpad(rec_reg.id_demande_reglement, 16) || ' | ' ||
                    rpad(rec_reg.statut_etape_reglement, 12);
      writeout(vv_message);

    END LOOP;
    dka_tools_pkg.put_log_message('fin reg_cree');

    fnd_file.put_line(fnd_file.output, chr(10));

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      '--------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'Détail des règlements non créés :');

    fnd_file.put_line(fnd_file.output, ' ');

    vv_header := rpad('ID facture', 15) || ' | ' || rpad('Numéro de facture', 20) || ' | ' ||
             rpad('ID Compte Bqe', 15) || ' | ' || rpad('Numéro Compte Bqe', 20) || ' | ' ||
             rpad('UO', 8) || ' | ' || rpad('Fournisseur', 20) || ' | ' ||
             rpad('Montant', 10) || ' | ' || rpad('DEVISE', 7) || ' | ' ||
             rpad('STATUT ETAPE', 15) || ' | ' || rpad('Message Erreur', 50);

    writeout(vv_header);
    writeout(rpad('-', length(vv_header), '-'));

    dka_tools_pkg.put_log_message('debut reg_non_cree');
    FOR rec_reg IN c_reg_non_cree LOOP
      dka_tools_pkg.put_log_message('boucle reg_non_cree');

      vv_message := rpad(rec_reg.id_facture_ap, 15) || ' | ' ||
                    rpad(rec_reg.facture_ap, 20) || ' | ' ||
                    rpad(rec_reg.id_compte_bancaire, 15) || ' | ' ||
                    rpad(rec_reg.numero_compte_inter, 20) || ' | ' ||
                    rpad(rec_reg.uo_ap, 8) || ' | ' ||
                    rpad(rec_reg.fournisseur_ap, 20) || ' | ' ||
                    rpad(rec_reg.montant, 10) || ' | ' ||
                    rpad(rec_reg.code_devise_ap, 7) || ' | ' ||
                    rpad(rec_reg.statut_etape_reglement, 15) || ' | ' ||
                    rpad(rec_reg.message_erreur, 50);
      writeout(vv_message);

    END LOOP;

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      '--------------------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'Détail des manques de configuration :');

    fnd_file.put_line(fnd_file.output, ' ');

    vv_header := rpad('ID Compte Bqe', 15) || ' | ' ||
             rpad('Numéro Compte Bqe', 20) || ' | ' ||
             rpad('Modele REGLEMENT', 20) || ' | ' || rpad('Message Erreur', 50);
    writeout(vv_header);
    writeout(rpad('-', length(vv_header), '-'));

    dka_tools_pkg.put_log_message('debut reg_config');
    FOR rec_reg IN c_reg_config LOOP

      vv_message := rpad(rec_reg.id_compte_bancaire, 15) || ' | ' ||
                    rpad(rec_reg.numero_compte_inter, 20) || ' | ' ||
                    rpad(rec_reg.modele_reglement, 20) || ' | ' ||
                    rpad(rec_reg.message_erreur, 50);
      writeout(vv_message);

    END LOOP;

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan3');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN3 : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END report_bilan3;

  /*=====================================================================================*/
  /* PROCEDURE NAME : main_crea_reg
  /*
  /* DESCRIPTION
  /*  Procédure principale de création du règlement
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/

  PROCEDURE main_crea_reg(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    -- ========== VARIABLES ==========
    v_package        VARCHAR2(30) := 'DKA_SRBFACTURE_PKG';
    v_nom_traitement VARCHAR2(200) := 'DKA : Création des règlements pour la campagne de prélèvement AP - RB';
    v_sqlerrm        VARCHAR2(250) := NULL;
    v_nb_erreurs     NUMBER := 0;

    v_procedure VARCHAR2(30) := 'MAIN_CREA_REG';
    v_message   VARCHAR2(500);

    v_errbuf  VARCHAR2(2500);
    v_retcode NUMBER;
    v_exeption EXCEPTION;
    v_resp_appl_id fnd_responsibility.application_id%TYPE;
    v_resp_id      fnd_responsibility.responsibility_id%TYPE;

    v_request_id  fnd_concurrent_requests.request_id%TYPE;
    v_request_id2 fnd_concurrent_requests.request_id%TYPE;
    vv_printer    fnd_printer.printer_name%TYPE;

    v_checkrun_id   NUMBER;
    v_checkrun_name VARCHAR2(50);
    v_causes_rejet  VARCHAR2(100);
    v_statut_maj    VARCHAR2(1);

    v_phase         VARCHAR2(100);
    v_status        VARCHAR2(100);
    v_dev_phase     VARCHAR2(100);
    v_dev_status    VARCHAR2(100);
    l_pay_thru_days NUMBER;
    l_count         NUMBER;
    l_erreur_modele VARCHAR2(1);

    CURSOR cur_reg IS
      SELECT DISTINCT id_modele_reglement, modele_reglement
        FROM dka_prel_ap_rb dpar, ap_invoices_all aia
       WHERE dpar.statut_etape = 'E2'
         AND dpar.id_facture_ap = aia.invoice_id
         AND aia.invoice_type_lookup_code = 'STANDARD'
         AND ap_invoices_pkg.get_approval_status(aia.invoice_id,
                                                 aia.invoice_amount,
                                                 aia.payment_status_flag,
                                                 aia.invoice_type_lookup_code) =
             'APPROVED'
         AND ap_invoices_pkg.get_posting_status(aia.invoice_id) = 'Y'
         AND aia.payment_status_flag = 'N'
         AND aia.payment_method_code = 'WIRE'
         AND (SELECT MAX(apsa.due_date)
                FROM ap_payment_schedules_all apsa
               WHERE aia.invoice_id = apsa.invoice_id) <= SYSDATE
         AND (SELECT COUNT(*)
                FROM ap_holds_all
               WHERE invoice_id = aia.invoice_id
                 AND release_lookup_code IS NULL) = 0
         AND aia.wfapproval_status = 'WFAPPROVED';

    CURSOR cur_modele(p_modele_reg NUMBER) IS
      SELECT dpar.*, dpar.rowid rid
        FROM dka_prel_ap_rb dpar
      -- 07/05/2021 1.1   NBO Correction suite au retour recette
      WHERE dpar.statut_etape IN ('E2', 'E3')
         AND dpar.id_modele_reglement = p_modele_reg;

    g_tempo NUMBER := 20;

  BEGIN

    -- Début du Programme --
    -- ========Initialisation des variables d'anomalies========
    p_retcode := 0;
    p_errbuf  := NULL;
    v_message := 'Début procédure MAIN_CREA_REG';

    -- Initialization des journaux --
    dka_tools_pkg.put_log_message('=======================================================================');
    dka_tools_pkg.put_log_message(v_nom_traitement);
    dka_tools_pkg.put_log_message('=======================================================================');
    dka_tools_pkg.put_log_message('Date de lancement    : ' ||
                                  to_char(SYSDATE,
                                          'DD-MON-YYYY HH24:MI:SS'));
    -- Initialization de la sortie --

    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message(' COMPTE-RENDU DU TRAITEMENT << ' ||
                                       v_nom_traitement || ' >>');
    dka_tools_pkg.put_outdebug_message(' Traitement n° ' ||
                                       to_char(g_request_id));
    dka_tools_pkg.put_outdebug_message(' Le  : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('                                                                ');

    SELECT COUNT(1)
      INTO g_lignes_rg_traitees
      FROM dka_prel_ap_rb dpar
     WHERE dpar.statut_etape = 'E2';

    FOR rec_reg IN cur_reg LOOP
      l_erreur_modele := 'N';

      FOR rec_modele IN cur_modele(rec_reg.id_modele_reglement) LOOP

        SELECT COUNT(1)
          INTO l_count
          FROM iby_sys_pmt_profiles_vl
         WHERE system_profile_code = 'DKA_PREL_AUTO_FRN';

        IF l_count = 0 THEN
          UPDATE dka_prel_ap_rb dpar
             SET dpar.message_erreur         = dka_tools_pkg.get_message('DKA',
                                                                         'DKA_SAPPRELAUTORB_E001'),
                 dpar.statut_etape_reglement = 'N'
           WHERE dpar.rowid = rec_modele.rid;
          l_erreur_modele := 'Y';
        END IF;

        SELECT COUNT(1)
          INTO l_count
          FROM ap_payment_templates apt,
               ap_ou_group          aog,
               hr_operating_units   hou
         WHERE apt.template_id = aog.template_id
           AND apt.template_name = rec_modele.modele_reglement
           AND aog.org_id = hou.organization_id
           AND hou.name = rec_modele.uo_ap;

        IF l_count = 0 THEN
          UPDATE dka_prel_ap_rb dpar
             SET dpar.message_erreur         = dka_tools_pkg.get_message('DKA',
                                                                         'DKA_SAPPRELAUTORB_E002'),
                 dpar.statut_etape_reglement = 'N'
           WHERE dpar.rowid = rec_modele.rid;
          l_erreur_modele := 'Y';
        END IF;

        SELECT COUNT(1)
          INTO l_count
          FROM ce_bank_acct_uses_all cebau, ce_ap_pm_doc_categories cadc
         WHERE cebau.bank_account_id = rec_modele.id_compte_bancaire
           AND cebau.bank_acct_use_id = cadc.bank_acct_use_id
           AND cadc.payment_method_code = 'WIRE'
           AND cadc.payment_doc_category = 'WIRE PAY';

        IF l_count = 0 THEN
          UPDATE dka_prel_ap_rb dpar
             SET dpar.message_erreur         = dka_tools_pkg.get_message('DKA',
                                                                         'DKA_SAPPRELAUTORB_E003'),
                 dpar.statut_etape_reglement = 'N'
           WHERE dpar.rowid = rec_modele.rid;
          l_erreur_modele := 'Y';
        END IF;

        SELECT COUNT(1)
          INTO l_count
          FROM fnd_doc_sequence_categories  cat,
               fnd_doc_sequence_assignments asgn,
               hr_operating_units           hou
         WHERE cat.code = asgn.category_code
           AND cat.code = rec_modele.compte_bancaire
           AND hou.set_of_books_id = asgn.set_of_books_id
           AND hou.name = rec_modele.uo_ap;

        IF l_count = 0 THEN
          UPDATE dka_prel_ap_rb dpar
             SET dpar.message_erreur         = dka_tools_pkg.get_message('DKA',
                                                                         'DKA_SAPPRELAUTORB_E004'),
                 dpar.statut_etape_reglement = 'N'
           WHERE dpar.rowid = rec_modele.rid;
          l_erreur_modele := 'Y';
        END IF;

        SELECT COUNT(1)
          INTO l_count
          FROM ce_payment_documents
         WHERE payment_document_name = 'PRLVT AUTO FOURNISSEUR'
           AND internal_bank_account_id = rec_modele.id_compte_bancaire;

        IF l_count = 0 THEN
          UPDATE dka_prel_ap_rb dpar
             SET dpar.message_erreur         = dka_tools_pkg.get_message('DKA',
                                                                         'DKA_SAPPRELAUTORB_E005'),
                 dpar.statut_etape_reglement = 'N'
           WHERE dpar.rowid = rec_modele.rid;

          l_erreur_modele := 'Y';
        END IF;

        SELECT COUNT(1)
          INTO l_count
          FROM ap_payment_templates apt
         WHERE apt.template_name = rec_modele.modele_reglement
         AND inactive_date is not null
         AND nvl(inactive_date,sysdate) <= sysdate;

        IF l_count > 0 THEN
          UPDATE dka_prel_ap_rb dpar
             SET dpar.message_erreur         = dka_tools_pkg.get_message('DKA',
                                                                         'DKA_SAPPRELAUTORB_E006'),
                 dpar.statut_etape_reglement = 'N'
           WHERE dpar.rowid = rec_modele.rid;
          l_erreur_modele := 'Y';
        END IF;

        IF l_erreur_modele = 'N' THEN
          ---- Action
          BEGIN
            UPDATE ap_payment_schedules_all apsa
               SET payment_priority = '55',
                   last_update_date = SYSDATE,
                   last_updated_by  = g_user_id,
             -- 07/05/2021 1.1 NBO Correction suite au retour recette
                   apsa.attribute15 = apsa.external_bank_account_id,
                   apsa.external_bank_account_id = null
             WHERE invoice_id = rec_modele.id_facture_ap;
          EXCEPTION
            WHEN OTHERS THEN
              p_retcode := 2;
          END;

          -- 07/05/2021 1.1 NBO Correction suite au retour recette
          /*BEGIN

            UPDATE iby_ext_bank_accounts
               SET bank_account_num = NULL,
                   last_update_date = SYSDATE,
                   last_updated_by  = g_user_id
             WHERE ext_bank_account_id =
                   rec_modele.external_bank_account_id;
          EXCEPTION
            WHEN OTHERS THEN
              p_retcode := 2;

          END;*/

          BEGIN
            UPDATE ap_invoices_all
               SET exclusive_payment_flag = 'Y',
                   last_update_date       = SYSDATE,
                   last_updated_by        = g_user_id
             WHERE invoice_id = rec_modele.id_facture_ap;
          EXCEPTION
            WHEN OTHERS THEN
              p_retcode := 2;
          END;

          IF p_retcode = 2 THEN
            v_causes_rejet  := 'Erreur dans la mise à jour d''échéancier des règlements .';
            v_statut_maj    := 'N';
            l_erreur_modele := 'Y';

            UPDATE dka_prel_ap_rb dpar
               SET causes_rejet_maj_echeancier = v_causes_rejet,
                   statut_maj_echeancier       = 'N'
             WHERE dpar.rowid = rec_modele.rid;

          ELSE
            g_lignes_mis_a_jour := g_lignes_mis_a_jour + 1;
            v_statut_maj        := 'Y';

            UPDATE dka_prel_ap_rb dpar
               SET statut_maj_echeancier = 'Y'
             WHERE dpar.rowid = rec_modele.rid;
          END IF;
        END IF;
      END LOOP;

      IF l_erreur_modele = 'N' THEN

        v_request_id := fnd_request.submit_request(application => 'SQLAP',
                                                   program     => 'APXPBASL',
                                                   description => NULL,
                                                   start_time  => NULL,
                                                   sub_request => FALSE,
                                                   argument1   => NULL,
                                                   argument2   => rec_reg.id_modele_reglement,
                                                   argument3   => NULL,
                                                   argument4   => NULL,
                                                   argument5   => NULL);
        IF v_request_id = 0 THEN
          p_retcode := 2;
          fnd_file.put_line(fnd_file.log,
                            'ERREUR : Le Programme de demande de traitement des règlements' ||
                            chr(10) ||
                            'PROGRAMME  : Le Programme de demande de traitement des règlements');
          dka_tools_pkg.put_log_message('====> ERREUR : Le Programme de demande de traitement des règlements ');
          p_errbuf := ' ERREUR : Le Programme de demande de traitement des règlements ';
        ELSE
          COMMIT;

          fnd_file.put_line(fnd_file.log,
                            'Numéro du Programme de demande de traitement des règlements: ' ||
                            v_request_id);
          dka_tools_pkg.put_log_message('Numéro du Programme de demande de traitement des règlements: ' ||
                                        v_request_id);

          --********************************************
          -- Wait for the concurrent program to complete
          --********************************************
          IF NOT ( fnd_concurrent.wait_for_request(v_request_id,
                                                  60,
                                                  20,
                                                  v_phase,
                                                  v_status,
                                                  v_dev_phase,
                                                  v_dev_status,
                                                  v_message)) THEN

            p_errbuf  := v_message;
            p_retcode := 2;
            fnd_file.put_line(fnd_file.log,
                              'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' ||
                              chr(10) || 'MESSAGE : ' || v_message ||
                              chr(10));

          END IF;

          IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN

            fnd_file.put_line(fnd_file.log,
                              'COMPLETION= ' || v_dev_phase || '/' ||
                              v_dev_status);
            fnd_file.put_line(fnd_file.log,
                              'Statut de fin : ' || v_phase || '/' ||
                              v_status);

          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN

            fnd_file.put_line(fnd_file.log,
                              'Programme de demande de traitement des règlements en warning ' ||
                              v_request_id);
            v_message := 'ERREUR : Fin du traitement en warning: ' ||
                         v_message;
            p_retcode := 1;

          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN

            p_retcode := 2;
            v_message := 'ERREUR : Programme de demande de traitement des règlements : ' ||
                         v_message;

            fnd_file.put_line(fnd_file.log,
                              'ERREUR : Fin anormale du traitement ' ||
                              v_request_id || chr(10) || 'Phase/Statut : ' ||
                              v_dev_phase || '/' || v_dev_status || chr(10) ||
                              'MESSAGE : ' || v_message || chr(10));
            fnd_file.put_line(fnd_file.log,
                              '===> ERREUR : Fin anormale du traitement ' ||
                              v_request_id);

          END IF;
          p_errbuf := v_message;

          v_request_id2 := 0;

          WHILE v_request_id2 != -1 LOOP
            DBMS_LOCK.sleep(10);

            BEGIN
              SELECT MIN(fcr.request_id)
                INTO v_request_id2
                FROM fnd_concurrent_requests    fcr,
                     fnd_concurrent_programs_vl fcp
               WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
                 AND fcr.status_code IN ('R', 'P', 'I')
               START WITH fcr.request_id = v_request_id
              CONNECT BY PRIOR fcr.request_id = fcr.parent_request_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_request_id2 := -1;
            END;

            fnd_file.put_line(fnd_file.log,
                              v_request_id || '=>' || v_request_id2);

            IF v_request_id2 != -1 OR v_request_id2 IS NOT NULL THEN
              IF NOT (fnd_concurrent.wait_for_request(v_request_id2,
                                                      60,
                                                      30,
                                                      v_phase,
                                                      v_status,
                                                      v_dev_phase,
                                                      v_dev_status,
                                                      v_message)) THEN

                p_errbuf  := v_message;
                p_retcode := 2;
                fnd_file.put_line(fnd_file.log,
                                  'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' ||
                                  chr(10) || 'MESSAGE : ' || v_message ||
                                  chr(10));
              END IF;

              IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN

                fnd_file.put_line(fnd_file.log,
                                  'COMPLETION= ' || v_dev_phase || '/' ||
                                  v_dev_status);
                fnd_file.put_line(fnd_file.log,
                                  'Statut de fin : ' || v_phase || '/' ||
                                  v_status);

              ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN

                fnd_file.put_line(fnd_file.log,
                                  'Programme de demande de traitement des règlements en warning ' ||
                                  v_request_id);
                v_message := 'ERREUR : Fin du traitement en warning: ' ||
                             v_message;
                p_retcode := 1;

              ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN

                p_retcode := 2;
                v_message := 'ERREUR : Programme de demande de traitement des règlements : ' ||
                             v_message;

                fnd_file.put_line(fnd_file.log,
                                  'ERREUR : Fin anormale du traitement ' ||
                                  v_request_id || chr(10) ||
                                  'Phase/Statut : ' || v_dev_phase || '/' ||
                                  v_dev_status || chr(10) || 'MESSAGE : ' ||
                                  v_message || chr(10));
                fnd_file.put_line(fnd_file.log,
                                  '===> ERREUR : Fin anormale du traitement ' ||
                                  v_request_id);

              END IF;
            END IF;

          END LOOP;

          BEGIN
            SELECT checkrun_id, checkrun_name
              INTO v_checkrun_id, v_checkrun_name
              FROM ap_inv_selection_criteria_all
             WHERE (request_id = v_request_id OR
                   request_id IN
                   (SELECT request_id
                       FROM fnd_conc_req_summary_v
                      WHERE parent_request_id = v_request_id))
               AND rownum = 1;

          EXCEPTION
            WHEN OTHERS THEN
              v_checkrun_id   := NULL;
              v_checkrun_name := NULL;
          END;

          UPDATE dka_prel_ap_rb dpar
             SET id_demande_reglement        = v_checkrun_id,
                 statut_etape_reglement      = 'N',
                 last_updated_date_reglement = SYSDATE,
                 updated_by_reglement        = fnd_global.user_id,
                 message_erreur              = v_message
           WHERE statut_etape = 'E2'
             AND dpar.statut_etape_reglement IS NULL
             AND dpar.id_modele_reglement = rec_reg.id_modele_reglement
             AND message_erreur IS NULL;

          fnd_file.put_line(fnd_file.log,
                            'v_checkrun_id : ' || v_checkrun_id ||
                            ' v_checkrun_name : ' || v_checkrun_name);

          FOR rec_modele IN cur_modele(rec_reg.id_modele_reglement) LOOP
            BEGIN
              UPDATE dka_prel_ap_rb dpar
                 SET id_demande_reglement = v_checkrun_id,
                     (id_reglement,
                      numero_reglement,
                      uo_reglement,
                      montant_reglement,
                      code_devise_reglement) =
                     (SELECT aca.check_id,
                             aca.check_number,
                             hou.name,
                             aca.amount,
                             aca.currency_code
                        FROM ap_checks_all           aca,
                             ap_invoice_payments_all aipa,
                             ap_invoices_all         aia,
                             hr_operating_units      hou
                       WHERE aipa.invoice_id = aia.invoice_id
                         AND aipa.check_id = aca.check_id
                         AND aca.checkrun_id = v_checkrun_id
                         AND aia.org_id = hou.organization_id
                         AND aia.invoice_id = dpar.id_facture_ap),
                     nom_modele = rec_reg.modele_reglement,
                     statut_etape_reglement = 'Y',
                     statut_etape = 'E3',
                     last_updated_date_reglement = SYSDATE,
                     updated_by_reglement = fnd_global.user_id,
                     message_erreur = null
               WHERE statut_etape = 'E2'
                 AND dpar.rowid = rec_modele.rid
                 AND EXISTS
               (SELECT 'X'
                        FROM ap_checks_all           aca,
                             ap_invoice_payments_all aipa,
                             ap_invoices_all         aia
                       WHERE aipa.invoice_id = aia.invoice_id
                         AND aipa.check_id = aca.check_id
                         AND aca.checkrun_id = v_checkrun_id
                         AND aia.invoice_id = dpar.id_facture_ap);
            EXCEPTION
              WHEN OTHERS THEN
                p_retcode := 2;
                p_errbuf := SQLERRM;
              END;

            g_lignes_rg_crees := nvl(g_lignes_rg_crees, 0) + SQL%ROWCOUNT;
          END LOOP;

        END IF;

      END IF; -- l_erreur_modele = 'N'

      FOR rec_modele IN cur_modele(rec_reg.id_modele_reglement) LOOP

        ---- Action
        BEGIN
          UPDATE ap_payment_schedules_all apsa
             SET payment_priority = rec_modele.priorite_origine,
                 last_update_date = SYSDATE,
                 last_updated_by  = g_user_id,
               -- 07/05/2021 1.1 NBO Correction suite au retour recette
                 apsa.attribute15 = null,
                 apsa.external_bank_account_id = apsa.attribute15
           WHERE invoice_id = rec_modele.id_facture_ap;
        EXCEPTION
          WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf := SQLERRM;
        END;

        -- 07/05/2021 1.1 NBO Correction suite au retour recette
        /*BEGIN

          UPDATE iby_ext_bank_accounts
             SET bank_account_num = rec_modele.bank_account_num_org,
                 last_update_date = SYSDATE,
                 last_updated_by  = g_user_id
           WHERE ext_bank_account_id = rec_modele.external_bank_account_id;
        EXCEPTION
          WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf := SQLERRM;
        END;*/

        BEGIN
          UPDATE ap_invoices_all
             SET exclusive_payment_flag = rec_modele.exclusive_payment_flag_org,
                 last_update_date       = SYSDATE,
                 last_updated_by        = g_user_id
           WHERE invoice_id = rec_modele.id_facture_ap;
        EXCEPTION
          WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf := SQLERRM;
        END;
      END LOOP;

    END LOOP;

    -- 07/05/2021 1.1 NBO Correction suite au retour recette
    SELECT COUNT(DISTINCT id_modele_reglement)
      INTO g_lignes_rg_non_crees
      FROM dka_prel_ap_rb dpar
     WHERE dpar.statut_etape = 'E2';

    report_bilan3(p_errbuf, p_retcode);

  EXCEPTION
    WHEN v_exeption THEN
      dka_tools_pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_outdebug_message('Package   : ' || v_package);
      dka_tools_pkg.put_outdebug_message('Procédure : ' || v_procedure);
      dka_tools_pkg.put_outdebug_message('Exception : OTHERS');
      dka_tools_pkg.put_outdebug_message('Message   : ' || v_message);
      dka_tools_pkg.put_log_message('Cause     : ' || p_errbuf);
      dka_tools_pkg.put_outdebug_message('------------------------------------------------');
      dka_tools_pkg.put_outdebug_message(to_char(SYSDATE,
                                                 'DD/MM/YYYY HH24:MI:SS') ||
                                         ' - ' || 'Fin de la procédure ' ||
                                         v_procedure ||
                                         ' : EXCEPTION v_exeption ');
      dka_tools_pkg.put_log_message('==> Fin de la procédure ' ||
                                    v_procedure ||
                                    ' : EXCEPTION v_exeption ');
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
      ROLLBACK;

    WHEN OTHERS THEN
      v_sqlerrm := substr(SQLERRM, 1, 200);
      p_retcode := 2;
      p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc ' ||
                   v_package || '.' || v_procedure;
      dka_tools_pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_outdebug_message('Package   : ' || v_package);
      dka_tools_pkg.put_outdebug_message('Procédure : ' || v_procedure);
      dka_tools_pkg.put_outdebug_message('Exception : OTHERS');
      dka_tools_pkg.put_outdebug_message('Message   : ' || v_message);
      dka_tools_pkg.put_log_message(chr(10) || p_errbuf);
      dka_tools_pkg.put_outdebug_message('Cause     : ' || v_sqlerrm);
      dka_tools_pkg.put_outdebug_message('------------------------------------------------');
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
      ROLLBACK;
  END main_crea_reg;

  /*=====================================================================================
  * PROCEDURE NAME : syslog
  *
  * DESCRIPTION
  *  Affichage du message dans le journal du traitement
  *
  * PARAMETERS
  * ==========
  * NAME                DESCRIPTION
  * -----------------  ------------------------------------------------------
  * msg                Message à afficher
  *=====================================================================================*/
  PROCEDURE syslog(msg IN VARCHAR2) IS

  BEGIN

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || msg);

  END syslog;

  /*=====================================================================================
  * PROCEDURE NAME : CREER_COMPTABILISATION
  *
  * DESCRIPTION
  *  Procédure de lancement des traitements de comptabilisation
  *
  * PARAMETERS
  * ==========
  * NAME                DESCRIPTION
  * -----------------  ------------------------------------------------------
  * p_errbuf           Retour de message éventuel
  * p_retcode          Statut du traitement en sortie
  *=====================================================================================*/
  PROCEDURE CREER_COMPTABILISATION(pv_errbuf  OUT VARCHAR2,
                                   pn_retcode OUT NUMBER) IS
    vn_responsibility_id NUMBER;
    vn_application_id    NUMBER;
    vv_ap_responsibility VARCHAR2(100);
    rec_param            dka_parameters%ROWTYPE;
    vn_request_layout    BOOLEAN;
    vn_request_id        NUMBER;
    --vn_approval_org_id             NUMBER;
    vv_phase                       VARCHAR2(100);
    vv_status                      VARCHAR2(100);
    vv_dev_phase                   VARCHAR2(100);
    vv_dev_status                  VARCHAR2(100);
    va_request_ids                 pa_utils.IdTabTyp; ---Tableau
    vn_requests_cnt                NUMBER;
    vv_errbuf                      VARCHAR2(150);
    vv_parameter                   dka_parameters.parameter_name%TYPE;
    vn_prog_application_id         NUMBER;
    vv_prog_application_short_name VARCHAR2(50);
    vn_program_id                  NUMBER;

    --paramètres du traitement XLAACCPB
    n_application              number;
    n_source_application       number;
    n_ledger                   number;
    n_ledger_desc              varchar2(100);
    v_process_category         varchar2(10);
    v_dummy0                   varchar2(10);
    d_end_date                 date;
    v_create_accounting_flag   varchar2(10);
    v_dummy1                   varchar2(10);
    v_accounting_mode          varchar2(10);
    v_dummy2                   varchar2(10);
    v_errors_only_flag         varchar2(10);
    v_report                   varchar2(20);
    v_transfer_to_gl_flag      varchar2(10);
    v_dummy3                   varchar2(10);
    v_gl_batch_name            varchar2(10);
    v_mixed_currency_precision varchar2(10);
    v_post_to_gl               varchar2(30);
    v_include_zero             varchar2(10);
    v_include_zero_flag        varchar2(10);
    v_request_id               number;
    v_entity_id                varchar2(10);
    --n_source_application_name    varchar2(10);
    v_application_name           varchar2(10);
    v_ledger_name                varchar2(50);
    v_process_category_n         varchar2(10);
    v_create_accounting          varchar2(10);
    v_accounting_mode_name       varchar2(30);
    v_errors_only                varchar2(10);
    v_report_level               varchar2(30);
    v_transfer_to_gl             varchar2(30);
    v_post_in_gl                 varchar2(10);
    n_secu_id_int_1              number;
    n_secu_id_int_2              number;
    n_secu_id_int_3              number;
    v_security_id_char_1         varchar2(10);
    v_security_id_char_2         varchar2(10);
    v_security_id_char_3         varchar2(10);
    v_valuation_method           varchar2(10);
    v_p_include_user_trx_id_flag varchar2(10);
    v_p_include_user_trx_id      varchar2(10);
    v_p_debug_flag               varchar2(10);
    v_p_user_id                  varchar2(10);
    v_p_scalable_flag            varchar2(10);
    v_p_launch_balance_program   varchar2(10);
    v_p_launch_bal_program       varchar2(10);
    n_concurrent_request_id      number;
    v_source_application_name    varchar2(20);
    v_gl_date                    DATE; -- OBE artf2161941

    CURSOR select_ledgers IS
      SELECT distinct gl.LEDGER_ID, gl.SHORT_NAME, gl.NAME
        FROM dka_prel_ap_rb dpar, GL_LEDGERS gl
       WHERE dpar.ID_REGLEMENT IS NOT NULL
         AND NVL(dpar.STATUT_ETAPE_REGLEMENT, 'N') = 'Y' -- règlement créé
         AND NVL(dpar.STATUT_CENTRALISATION, 'N') = 'N' -- non compta/centralisé
         AND dpar.STATUT_ETAPE = 'E3'
         AND dpar.NUMERO_SOCIETE = gl.SHORT_NAME;

  BEGIN

    syslog('--> CREER_COMPTABILISATION' || CHR(10));

    pn_retcode   := 0;
    pv_errbuf    := NULL;
    vv_parameter := 'AP_RESPONSIBILITY_KEY';

    -- Récupération des parametres utilisés par le traitement
    dka_tools_pkg.get_parameter('SXLAACCPB',
                                vv_parameter,
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'Echec lors de la recuperation des parametres SXLAACCPB';
      RETURN;
    END IF;

    vn_requests_cnt := 0;
    dka_tools_pkg.put_debug_message('Recuperation des identifiants programme');

    -- Récupération de l'id de l'application et de son nom court
    SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
      INTO vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
      FROM fnd_concurrent_programs fcp, fnd_application fa
     WHERE fcp.concurrent_program_name = 'XLAACCPB'
       AND fa.application_id = fcp.application_id;

    FOR IC IN select_ledgers LOOP

      syslog('Creer comptabilisation ' || IC.NAME || '(' || IC.SHORT_NAME || ')');

      -- Ici on forme le nom de la responsabilité
      --vn_approval_org_id   := rec_approval.org_id;
      -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
      --vv_ap_responsibility := rec_approval.name || '_' ||
      vv_ap_responsibility := 'TOUT_' || rec_param.varchar2_value;

      --récupération des variables nécessaires au lancement du traitement
      SELECT fr.responsibility_id, fr.application_id
        INTO vn_responsibility_id, vn_application_id
        FROM fnd_responsibility fr
       WHERE fr.responsibility_key = vv_ap_responsibility;

      -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
      fnd_global.apps_initialize(fnd_global.user_id,
                                 vn_responsibility_id,
                                 vn_application_id);

      -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
      --fnd_request.set_org_id(rec_approval.org_id);

      dka_tools_pkg.put_debug_message('initialisation réussie sur la resp:' ||
                                      vv_ap_responsibility || '   ' ||
                                      fnd_global.user_id || '   ' ||
                                      vn_responsibility_id ||
                                      vn_application_id);

      SELECT concat(concat(concat(gl.NAME, ' ('), gl.short_name), ')') ledger_description
        INTO n_ledger_desc
        FROM gl_ledgers gl
       WHERE gl.ledger_id = ic.LEDGER_ID;
      -----------------------------------------------------------------------------------------------------------------------------------------------------
      -- Récupération des valeurs par défaut
      dka_tools_pkg.put_debug_message('Récupération des paramètres');

      SELECT lookup_code
        into v_accounting_mode
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
         AND XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = ic.LEDGER_ID;

      SELECT lookup_code
        into v_transfer_to_gl_flag
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
         AND XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = ic.LEDGER_ID;

      SELECT lookup_code
        into v_report
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
         AND XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = ic.LEDGER_ID;

      SELECT MEANING
        into v_report_level
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
         AND XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = ic.LEDGER_ID;

      SELECT MEANING
        into v_transfer_to_gl
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
         AND XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = ic.LEDGER_ID;

      SELECT meaning
        into v_accounting_mode_name
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
         AND XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = ic.LEDGER_ID;

      /*
        SELECT meaning into v_post_in_gl
          FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
          WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
          AND    XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
          AND   XSO.LEDGER_ID = p_set_of_books_id;

        SELECT lookup_code into v_post_to_gl
          FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
          WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
          AND    XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
          AND   XSO.LEDGER_ID = p_set_of_books_id;
      */

      SELECT meaning, LOOKUP_CODE
        into v_post_in_gl, v_post_to_gl
        FROM xla_lookups
       WHERE lookup_type = 'XLA_YES_NO'
         and lookup_code = 'Y';

      --v_report:=get_create_accounting_lookup(vn_application_id,p_set_of_books_id,'XLA_REPORT_LEVEL');
      --v_report:='N';
      -- v_post_to_gl:=get_create_accounting_lookup(vn_application_id,p_set_of_books_id,'XLA_YES_NO');

      SELECT MEANING
        into v_p_launch_bal_program
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'Y';

      SELECT lookup_code
        into v_create_accounting_flag
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'Y';

      SELECT 'Y'
        into v_dummy2
        FROM DUAL
       WHERE NVL(v_accounting_mode, 'F') = 'F';

      SELECT LOOKUP_CODE
        into v_errors_only_flag
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';

      SELECT meaning
        into v_p_include_user_trx_id
        FROM xla_lookups
       WHERE lookup_type = 'XLA_YES_NO'
         and lookup_code = 'N';

      SELECT application_name
        into v_source_application_name
        from fnd_application_tl
       where application_id = fnd_profile.value('resp_appl_id')
         and language = 'F';

      SELECT application_name
        into v_application_name
        from fnd_application_tl
       where application_id = fnd_profile.value('resp_appl_id')
         and language = 'F';

      --SELECT 'Y' into v_dummy3 FROM DUAL WHERE v_transfer_to_gl_flag = 'Y';
      SELECT lookup_code
        into v_include_zero_flag
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';

      SELECT name
        into v_ledger_name
        from gl_ledgers
       where ledger_id = ic.LEDGER_ID;

      SELECT MEANING
        into v_create_accounting
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'Y';

      SELECT MEANING
        into v_errors_only
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';

      SELECT MEANING
        into v_include_zero
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';

      SELECT EVENT_CLASS_GROUP_CODE, NAME
        INTO v_process_category, v_process_category_n
        FROM XLA_EVENT_CLASS_GRPS_VL
       WHERE application_id = 200
         AND EVENT_CLASS_GROUP_CODE = 'PAYMENTS';

      n_application        := fnd_profile.value('RESP_APPL_ID');
      n_source_application := fnd_profile.value('RESP_APPL_ID');
      n_ledger             := ic.LEDGER_ID;
      v_dummy0             := 'Y';
      d_end_date           := sysdate;
      --v_process_category       := null;
      v_dummy1                   := 'Y';
      v_dummy3                   := 'Y';
      v_mixed_currency_precision := null;
      v_gl_batch_name            := null;
      v_request_id               := null;
      v_entity_id                := null;
      --v_process_category_n     := null;
      v_p_include_user_trx_id_flag := 'N';
      v_p_debug_flag               := 'N';
      v_p_user_id                  := fnd_global.user_id;
      v_p_scalable_flag            := 'N';
      --v_p_launch_balance_program   := 'Y';
      n_secu_id_int_1            := null;
      n_secu_id_int_2            := null;
      n_secu_id_int_3            := null;
      v_security_id_char_1       := null;
      v_security_id_char_2       := null;
      v_security_id_char_3       := null;
      v_valuation_method         := null;
      v_p_launch_balance_program := 'Y';
      n_concurrent_request_id    := null;

      --< OBE artf2161941
      SELECT end_date
        INTO v_gl_date
        FROM gl_period_statuses
       WHERE 1 = 1
         AND TRUNC(sysdate) BETWEEN TRUNC(start_date) AND TRUNC(end_date)
         AND ledger_id = n_ledger
         AND application_id = 200;
      --> OBE artf2161941

      ------------------------------------------------------------------------------------------------------------------------------------------------------
      --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
      dka_tools_pkg.put_debug_message('Soumission du traitement appli = :' ||
                                      vv_prog_application_short_name ||
                                      ' short_name: ' || vn_program_id);

      -- Ajout du template
      vn_request_layout := FND_REQUEST.add_layout('XLA',
                                                  'XLAACCPB02',
                                                  'fr',
                                                  'FR',
                                                  'PDF');

      IF vn_request_layout THEN

        vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    'XLAACCPB', --SHORT_NAME du TRAITEMENT
                                                    n_ledger_desc, --DESCRIPTION
                                                    NULL, --START
                                                    FALSE, --SUB_REQUEST
                                                    n_application,
                                                    n_source_application,
                                                    v_dummy0,
                                                    n_ledger,
                                                    v_process_category, -- Process Category ,
                                                    TO_CHAR(v_gl_date,
                                                            'YYYY/MM/DD HH24:MI:SS'), --TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'), --ARGUMENT6 -- OBE artf2161941
                                                    v_create_accounting_flag,
                                                    v_dummy1,
                                                    v_accounting_mode,
                                                    v_dummy2,
                                                    v_errors_only_flag,
                                                    v_report,
                                                    v_transfer_to_gl_flag,
                                                    v_dummy3,
                                                    v_post_to_gl,
                                                    v_gl_batch_name, -- GL Batch Name,
                                                    v_mixed_currency_precision,
                                                    v_include_zero_flag,
                                                    v_request_id,
                                                    v_entity_id,
                                                    v_source_application_name,
                                                    v_application_name,
                                                    v_ledger_name,
                                                    v_process_category_n,
                                                    v_create_accounting,
                                                    v_accounting_mode_name,
                                                    v_errors_only,
                                                    v_report_level,
                                                    v_transfer_to_gl,
                                                    v_post_in_gl,
                                                    v_include_zero,
                                                    v_valuation_method,
                                                    v_security_id_char_1,
                                                    v_security_id_char_2,
                                                    v_security_id_char_3,
                                                    n_secu_id_int_1,
                                                    n_secu_id_int_2,
                                                    n_secu_id_int_3,
                                                    n_concurrent_request_id,
                                                    v_p_include_user_trx_id_flag,
                                                    v_p_include_user_trx_id,
                                                    v_p_debug_flag,
                                                    v_p_user_id,
                                                    v_p_scalable_flag,
                                                    v_p_launch_balance_program,
                                                    v_p_launch_bal_program);

        dka_tools_pkg.put_debug_message('Valeur de vn_request_id = ' ||
                                        vn_request_id);
        IF vn_request_id IS NULL THEN
          pn_retcode := 1;
          pv_errbuf  := 'Le traitement d''approbation n''a pas pu être lancé pour la société  ' ||
                        ic.NAME;
        ELSE
          pn_retcode := 0;
          pv_errbuf  := 'Traitement d''approbation : ' ||
                        TO_CHAR(vn_request_id) || ' lancé sur la société ' ||
                        IC.NAME;
          dka_tools_pkg.put_log_message(pv_errbuf);

          vn_requests_cnt := vn_requests_cnt + 1;
          va_request_ids(vn_requests_cnt) := vn_request_id;

        END IF;

        COMMIT;

      END IF;

    END LOOP;

    syslog('--> ATTENTE_FIN_COMPTA' || CHR(10));

    WHILE vn_requests_cnt > 0 LOOP
      IF NOT (fnd_concurrent.wait_for_request(va_request_ids(vn_requests_cnt),
                                              15,
                                              0,
                                              vv_phase,
                                              vv_status,
                                              vv_dev_phase,
                                              vv_dev_status,
                                              vv_errbuf)) THEN
        dka_tools_pkg.put_outdebug_message('Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                           ' trop long ou tombé en erreur');
      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
        dka_tools_pkg.put_log_message('Traitement numéro ' ||
                                      TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                      ' correctement exécuté');
      END IF;
      vn_requests_cnt := vn_requests_cnt - 1;

    END LOOP;

  END CREER_COMPTABILISATION;

  /*=====================================================================================*/
  /* PROCEDURE NAME : MAJ_TABLE_TRAVAIL
  /*
  /* DESCRIPTION
  /*  Procédure de mise à jour des informations des règlements comptabilisés / centralisés dans GL
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/
  PROCEDURE MAJ_TABLE_TRAVAIL(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    vn_event_id            NUMBER;
    vv_gl_trans_status     XLA_AE_HEADERS.GL_TRANSFER_STATUS_CODE%TYPE;
    vv_event_status_code   XLA_EVENTS.EVENT_STATUS_CODE%TYPE;
    vv_process_status_code XLA_EVENTS.PROCESS_STATUS_CODE%TYPE;
    vv_encoded_msg         XLA_ACCOUNTING_ERRORS.ENCODED_MSG%TYPE;
    vv_err_msg             VARCHAR2(500);

    vv_step VARCHAR2(50);

    vn_je_header_id        NUMBER;
    vv_jeh_name            VARCHAR2(200);
    vn_je_line_num         NUMBER;
    vd_gl_last_update_date DATE;
    vn_gl_last_updated_by  NUMBER;
    vv_posting_status      GL_JE_LINES.STATUS%TYPE;

    e_fin_curseur        EXCEPTION;
    e_err_centralisation EXCEPTION;
    e_err_imputation     EXCEPTION;

    CURSOR select_fact IS
      SELECT tmp.ID_FACTURE_AP, tmp.ID_REGLEMENT
        FROM dka_prel_ap_rb tmp
       WHERE tmp.ID_REGLEMENT IS NOT NULL
         AND NVL(tmp.STATUT_ETAPE_REGLEMENT, 'N') = 'Y' -- règlement créé
         AND NVL(tmp.STATUT_CENTRALISATION, 'N') = 'N' -- non compta/centralisé
         AND tmp.STATUT_ETAPE = 'E3';

  BEGIN

    syslog('--> MAJ_TABLE_TRAVAIL' || CHR(10));

    FOR curseur in select_fact LOOP

      syslog('      Facture ' || curseur.ID_FACTURE_AP || ' / Reglement ' ||
             curseur.ID_REGLEMENT);

      BEGIN

        vv_step := 'STEP01 : Recuperation EVENT_ID';

        -- Récupération EVENT_ID
        BEGIN
          SELECT aipa.ACCOUNTING_EVENT_ID
            INTO vn_event_id
            FROM AP_INVOICE_PAYMENTS_ALL aipa
           WHERE aipa.INVOICE_ID = curseur.ID_FACTURE_AP
             AND aipa.CHECK_ID = curseur.ID_REGLEMENT;

        EXCEPTION
          WHEN OTHERS THEN
            vv_err_msg := 'Impossible de recuperer un EVENT_ID ce reglement : ' ||
                          SQLERRM;
            raise e_err_centralisation;
        END;

        syslog('      Event_id  : ' || vn_event_id);

        -- Recuperation des statuts SLA et du message d'erreur
        vv_step := 'STEP02 : Recuperation statuts SLA';
        BEGIN
          SELECT xe.EVENT_STATUS_CODE,
                 xe.PROCESS_STATUS_CODE,
                 err.ENCODED_MSG
            INTO vv_event_status_code,
                 vv_process_status_code,
                 vv_encoded_msg
            FROM XLA_EVENTS xe, XLA_ACCOUNTING_ERRORS err
           WHERE xe.EVENT_ID = err.EVENT_ID(+)
             and xe.EVENT_ID = vn_event_id;
        EXCEPTION
          WHEN OTHERS THEN
            vv_err_msg := 'Impossible de recuperer les donnees dans XLA_EVENTS : ' ||
                          SQLERRM;
            raise e_err_centralisation;
        END;

        IF (vv_event_status_code != 'P' OR vv_process_status_code != 'P') THEN
          vv_err_msg := 'Evenement SLA en erreur : ' || vv_encoded_msg;
          raise e_err_centralisation;
        END IF;

        -- Verification du transfert SLA/GL
        vv_step := 'STEP03 : Verification transfert SLA/GL';
        SELECT GL_TRANSFER_STATUS_CODE
          INTO vv_gl_trans_status
          FROM XLA_AE_HEADERS xah /*, XLA_AE_LINES xal*/
         WHERE /*xah.AE_HEADER_ID = xal.AE_HEADER_ID
                                                                                                                                                                           AND*/
         xah.EVENT_ID = vn_event_id;

        IF (vv_gl_trans_status != 'Y') THEN
          vv_err_msg := 'Ecriture SLA non transferee dans GL';
          raise e_err_centralisation;
        END IF;

        -- Recherche de l'ecriture GL associee
        vv_step := 'STEP04 : Recherche ecriture GL';
        BEGIN

          SELECT gjl.JE_HEADER_ID,
                 gjh.NAME,
                 gjl.JE_LINE_NUM,
                 gjl.LAST_UPDATE_DATE,
                 gjl.LAST_UPDATED_BY,
                 gjl.STATUS
            INTO vn_je_header_id,
                 vv_jeh_name,
                 vn_je_line_num,
                 vd_gl_last_update_date,
                 vn_gl_last_updated_by,
                 vv_posting_status
            FROM XLA_AE_HEADERS           xah,
                 XLA_AE_LINES             xal,
                 GL_JE_HEADERS            gjh,
                 GL_JE_LINES              gjl,
                 GL_CODE_COMBINATIONS_KFV gcc
           WHERE xah.AE_HEADER_ID = xal.AE_HEADER_ID
             AND xah.EVENT_ID = vn_event_id
             AND gjh.JE_HEADER_ID = gjl.JE_HEADER_ID
             AND gjl.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID
             AND gcc.CODE_COMBINATION_ID = xal.CODE_COMBINATION_ID
             AND gjl.GL_SL_LINK_TABLE = xal.GL_SL_LINK_TABLE
             AND gjl.GL_SL_LINK_ID = xal.GL_SL_LINK_ID
                --  AND gjl.REFERENCE_6 = xah.EVENT_ID
                --  AND gjl.REFERENCE_7 = xah.AE_HEADER_ID
             AND xah.LEDGER_ID = gjl.LEDGER_ID
             AND gjh.CREATION_dATE >= xah.CREATION_DATE
             AND substr(gcc.segment3, 1, 3) in ('512', '513');

        EXCEPTION
          WHEN OTHERS THEN
            vv_err_msg := 'Impossible de recuperer les donnees dans GL : ' ||
                          SQLERRM;
            raise e_err_centralisation;
        END;

        vv_step := 'STEP05 : Mise a jour table de travail';

          UPDATE dka_prel_ap_rb
             SET STATUT_CENTRALISATION = 'Y',
                 STATUT_IMPUTATION     = 'Y',
                 ID_PIECE_GL           = vn_je_header_id,
                 NUMERO_PIECE_GL       = vv_jeh_name,
                 NUMERO_LIGNE_GL       = vn_je_line_num,
                 LAST_UPDATED_DATE_GL  = vd_gl_last_update_date,
                 UPDATED_BY_GL         = vn_gl_last_updated_by,
                 STATUT_ETAPE          = 'E4'
           WHERE ID_FACTURE_AP = curseur.ID_FACTURE_AP
             AND ID_REGLEMENT = curseur.ID_REGLEMENT;


      EXCEPTION
        WHEN e_err_centralisation THEN

          syslog('ERREUR CENTRALISATION - ' || vv_step || ' : ' ||
                 vv_err_msg);

          UPDATE dka_prel_ap_rb
             SET STATUT_CENTRALISATION         = 'N',
                 STATUT_IMPUTATION             = 'N',
                 MESSAGE_ERREUR_CENTRALISATION = vv_err_msg
           WHERE ID_FACTURE_AP = curseur.ID_FACTURE_AP
             AND ID_REGLEMENT = curseur.ID_REGLEMENT;


        WHEN OTHERS THEN
          p_errbuf := 'ERREUR GLOBALE - ' || vv_step || ' : ' || SQLERRM;
          p_retcode := 2;
          syslog(p_errbuf);
      END;

    END LOOP;

    COMMIT;

  END MAJ_TABLE_TRAVAIL;

  /*=====================================================================================*/
  /* PROCEDURE NAME : REPORT_BILAN4
  /*
  /* DESCRIPTION
  /*  Procédure d'edition de la sortie recapitulant les donnees traitees ainsi que leur statut
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/
  PROCEDURE REPORT_BILAN4(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    vn_lignes_traitees NUMBER;
    vn_compta_OK       NUMBER;
    vn_compta_KO       NUMBER;
    vv_header          VARCHAR2(500);
    vv_line            VARCHAR2(500);
    vv_interligne      VARCHAR2(500);

    vn_length_facture     NUMBER;
    vn_length_fournisseur NUMBER;
    vn_length_reglement   NUMBER;

    CURSOR lignes_compta IS
      SELECT UO_AP,
             ID_FACTURE_AP,
             FACTURE_AP,
             FOURNISSEUR_AP,
             MONTANT,
             NUMERO_REGLEMENT,
             MONTANT_REGLEMENT,
             STATUT_CENTRALISATION,
             STATUT_IMPUTATION,
             nvl(to_char(ID_PIECE_GL), ' ') ID_PIECE_GL,
             nvl(NUMERO_LIGNE_GL, ' ') NUMERO_LIGNE_GL
        FROM dka_prel_ap_rb
       WHERE NVL(STATUT_ETAPE_REGLEMENT, 'N') = 'Y'
         AND NVL(STATUT_CENTRALISATION, 'N') = 'Y'
         AND NVL(STATUT_IMPUTATION, 'N') = 'Y'
         AND STATUT_ETAPE = 'E4'
       ORDER BY UO_AP, FOURNISSEUR_AP, ID_FACTURE_AP;

    CURSOR lignes_non_compta IS
      SELECT UO_AP,
             ID_FACTURE_AP,
             FACTURE_AP,
             FOURNISSEUR_AP,
             MONTANT,
             NUMERO_REGLEMENT,
             MONTANT_REGLEMENT,
             STATUT_CENTRALISATION,
             'N' STATUT_IMPUTATION,
             nvl(to_char(ID_PIECE_GL), ' ') ID_PIECE_GL,
             nvl(NUMERO_LIGNE_GL, ' ') NUMERO_LIGNE_GL
        FROM dka_prel_ap_rb
       WHERE NVL(STATUT_ETAPE_REGLEMENT, 'N') = 'Y'
         AND (NVL(STATUT_CENTRALISATION, 'N') = 'N' OR
              NVL(STATUT_IMPUTATION, 'N') = 'N')
         AND STATUT_ETAPE = 'E3'
       ORDER BY UO_AP, FOURNISSEUR_AP, ID_FACTURE_AP;

  BEGIN

    syslog('--> EDITION_SORTIE' || CHR(10));

    SELECT COUNT(*)
      INTO vn_lignes_traitees
      FROM dka_prel_ap_rb
     WHERE NVL(STATUT_ETAPE_REGLEMENT, 'N') = 'Y';

    SELECT COUNT(*)
      INTO vn_compta_OK
      FROM dka_prel_ap_rb
     WHERE NVL(STATUT_ETAPE_REGLEMENT, 'N') = 'Y'
       AND NVL(STATUT_CENTRALISATION, 'N') = 'Y'
       AND NVL(STATUT_IMPUTATION, 'N') = 'Y';

    SELECT COUNT(*)
      INTO vn_compta_KO
      FROM dka_prel_ap_rb
     WHERE NVL(STATUT_ETAPE_REGLEMENT, 'N') = 'Y'
       AND (NVL(STATUT_CENTRALISATION, 'N') = 'N' OR
            NVL(STATUT_IMPUTATION, 'N') = 'N');

    SELECT max(length(FACTURE_AP)),
           max(length(FOURNISSEUR_AP)),
           max(length(nvl(NUMERO_REGLEMENT, 0)))
      INTO vn_length_facture, vn_length_fournisseur, vn_length_reglement
      FROM dka_prel_ap_rb;

    IF vn_length_facture < 15 THEN
      vn_length_facture := 15;
    END IF;

    IF vn_length_fournisseur < 15 THEN
      vn_length_fournisseur := 15;
    END IF;

    IF vn_length_reglement < 15 THEN
      vn_length_reglement := 15;
    END IF;

    writeout('Total des lignes traitées : ' || vn_lignes_traitees);
    writeout('-------------------------------------------------------------------------');
    writeout('Total des lignes comptabilisées : ' || vn_compta_OK);
    writeout('');

    vv_header := rpad('UO', 7, ' ') || ' | ' ||
                 rpad('NUM FACTURE', vn_length_facture, ' ') || ' | ' ||
                 rpad('FOURNISSEUR', vn_length_fournisseur, ' ') || ' | ' ||
                 'MONTANT FACT' || ' | ' ||
                 rpad('NUM REGLEMENT', vn_length_reglement, ' ') || ' | ' ||
                 'MONTANT RGLT' || ' | ' || 'CENTRALISATION' || ' | ' ||
                 rpad('IMPUTATION', 10, ' ') || ' | ' || 'JE_HEADER_ID' ||
                 ' | ' || 'JE_LINE_NUM';

    vv_interligne := rpad('-', length(vv_header), '-');

    IF (vn_compta_OK > 0) THEN
      writeout(vv_header);
      writeout(vv_interligne);

      -- Affichage des lignes comptabilisees
      FOR c_ok in lignes_compta LOOP

        vv_line := c_ok.UO_AP || ' | ' ||
                   rpad(c_ok.FACTURE_AP, vn_length_facture, ' ') || ' | ' ||
                   rpad(c_ok.FOURNISSEUR_AP, vn_length_fournisseur, ' ') ||
                   ' | ' || lpad(c_ok.MONTANT, 12, ' ') || ' | ' ||
                   rpad(c_ok.NUMERO_REGLEMENT, vn_length_reglement, ' ') ||
                   ' | ' || lpad(c_ok.MONTANT_REGLEMENT, 12, ' ') || ' | ' ||
                   rpad(c_ok.STATUT_CENTRALISATION, 14, ' ') || ' | ' ||
                   rpad(c_ok.STATUT_IMPUTATION, 10, ' ') || ' | ' ||
                   rpad(nvl(c_ok.ID_PIECE_GL, ' '), 12, ' ') || ' | ' ||
                   c_ok.NUMERO_LIGNE_GL;
        writeout(vv_line);

      END LOOP;

    END IF;

    writeout('' || CHR(10));
    writeout('Total des lignes non totalement comptabilisées : ' ||
             vn_compta_KO);
    writeout('');

    IF (vn_compta_KO > 0) THEN
      writeout(vv_header);
      writeout(vv_interligne);

      -- affichage des lignes non comptabilisees
      FOR c_ko in lignes_non_compta LOOP

        vv_line := c_ko.UO_AP || ' | ' ||
                   rpad(c_ko.FACTURE_AP, vn_length_facture, ' ') || ' | ' ||
                   rpad(c_ko.FOURNISSEUR_AP, vn_length_fournisseur, ' ') ||
                   ' | ' || lpad(c_ko.MONTANT, 12, ' ') || ' | ' ||
                   rpad(c_ko.NUMERO_REGLEMENT, vn_length_reglement, ' ') ||
                   ' | ' || lpad(c_ko.MONTANT_REGLEMENT, 12, ' ') || ' | ' ||
                   rpad(c_ko.STATUT_CENTRALISATION, 14, ' ') || ' | ' ||
                   rpad(c_ko.STATUT_IMPUTATION, 10, ' ') || ' | ' ||
                   rpad(c_ko.ID_PIECE_GL, 12, ' ') || ' | ' ||
                   c_ko.NUMERO_LIGNE_GL;
        writeout(vv_line);

      END LOOP;

    END IF;

  END REPORT_BILAN4;

  /*=====================================================================================*/
  /* PROCEDURE NAME : MAIN_COMPTA
  /*
  /* DESCRIPTION
  /*  Procédure principale de comptabilisation des règlements
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/
  PROCEDURE MAIN_COMPTA(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

  BEGIN

    CREER_COMPTABILISATION(p_errbuf, p_retcode);

    MAJ_TABLE_TRAVAIL(p_errbuf, p_retcode);

    REPORT_BILAN4(p_errbuf, p_retcode);

  END MAIN_COMPTA;

  /*
   *************************************************************************
   * PROCEDURE NAME : Report_Bilan6
   *
   * DESCRIPTION
   *  Procédure de génération du bilan du traitement d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */
  PROCEDURE report_bilan6(p_errbuf IN OUT VARCHAR2, p_retcode IN OUT NUMBER) IS
    vv_message VARCHAR2(2000);
    vv_header  VARCHAR2(500);
    CURSOR c_ref_maj IS
      SELECT id_reglement,
             numero_reglement,
             uo_reglement,
             montant_reglement,
             code_devise_reglement,
             statut_centralisation,
             statut_imputation,
             id_piece_gl,
             numero_ligne_gl,
             id_ligne_rb_gl,
             type_ligne_rb_gl,
       NUMERO_CPT_FACTURATION_RB,--EDB338
             reference2_gl,
             statut_alimentation_ref2
        FROM dka_prel_ap_rb
       WHERE statut_etape = 'E6'
       ORDER BY region, uo_ap, id_reglement;

    CURSOR c_ref_non_maj IS
            SELECT id_reglement,
             numero_reglement,
             uo_reglement,
             montant_reglement,
             code_devise_reglement,
             statut_centralisation,
             statut_imputation,
             id_piece_gl,
             numero_ligne_gl,
             id_ligne_rb_gl,
             type_ligne_rb_gl,
       NUMERO_CPT_FACTURATION_RB,--EDB338
             reference2_gl,
             statut_alimentation_ref2,
             message_alimentation_ref2
        FROM dka_prel_ap_rb
       WHERE statut_etape = 'E4'
       ORDER BY region, uo_ap, id_reglement;

  BEGIN
    --g_lignes_non_mis_a_jour := g_lignes_rb_traitées - g_lignes_mis_a_jour ;
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan');

    --------------------
    -- Initialisation --
    --------------------

    fnd_file.put_line(fnd_file.output, chr(10));

    fnd_file.put_line(fnd_file.output,
                      '   . Total lignes éligibles à l''alimentation et traitées :' ||
                      g_lignes_ref_traitees);
    fnd_file.put_line(fnd_file.output, '   . Total de lignes pour lesquelles l''alimentation a été effectuée  :' ||
                                  g_lignes_ref_effectuees);


    fnd_file.put_line(fnd_file.output,
                      '   . lignes pour lesquelles l''alimentation n''a pas été effectuée :' ||
                      g_lignes_ref_non_effectuees);

    dka_tools_pkg.put_log_message(' Détail :');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      '--------------------------------------------------------------------------------------------');

    vv_header := rpad('ID REGLT', 10) || ' | ' || rpad('Num REGLT', 12) || ' | ' ||
             rpad('UO REGLT', 10) || ' | ' || rpad('Montant', 10) || ' | ' ||
             rpad('DEVISE', 7) || ' | ' ||
             rpad('IMPUTATION', 11) || ' | ' || rpad('ID PIECE', 10) || ' | ' ||
             rpad('NUM LIGNE', 10) || ' | ' || rpad('ID LIGNE', 10) || ' | ' ||
             rpad('TYPE LIGNE', 11) || ' | '  || rpad('Num Cpt Facturation', 15) || ' | '  --EDB338
       || rpad('REF2', 15) || ' | ' ||
             rpad('STATUT ALIM', 12);

    writeout(vv_header);

    writeout(rpad('-', length(vv_header), '-'));

    FOR rec_ref_maj IN c_ref_maj LOOP
      vv_message := rpad(rec_ref_maj.id_reglement, 10) || ' | ' ||
                    rpad(rec_ref_maj.numero_reglement, 12) || ' | ' ||
             rpad(rec_ref_maj.uo_reglement, 10) || ' | ' ||
             rpad(rec_ref_maj.montant_reglement, 10) || ' | ' ||
             rpad(rec_ref_maj.code_devise_reglement, 7) || ' | ' ||
             rpad(rec_ref_maj.statut_imputation, 11) || ' | ' ||
             rpad(rec_ref_maj.id_piece_gl, 10) || ' | ' ||
             rpad(rec_ref_maj.numero_ligne_gl, 10) || ' | ' ||
             rpad(rec_ref_maj.id_ligne_rb_gl, 10) || ' | ' ||
             rpad(rec_ref_maj.type_ligne_rb_gl, 11) || ' | ' ||
       rpad(rec_ref_maj.NUMERO_CPT_FACTURATION_RB, 15) || ' | ' || --EDB338
             rpad(rec_ref_maj.reference2_gl, 15) || ' | ' ||
             rpad(rec_ref_maj.statut_alimentation_ref2, 12);

      writeout(vv_message);

    END LOOP;

    dka_tools_pkg.put_log_message(' Détail :');
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      '--------------------------------------------------------------------------------------------');

    vv_header :=   rpad('ID REGLT', 10) || ' | ' || rpad('Num REGLT', 12) || ' | ' ||
             rpad('UO REGLT', 10) || ' | ' || rpad('Montant', 10) || ' | ' ||
             rpad('DEVISE', 7) || ' | ' ||
             rpad('IMPUTATION', 11) || ' | ' || rpad('ID PIECE', 10) || ' | ' ||
             rpad('NUM LIGNE', 10) || ' | ' || rpad('ID LIGNE', 10) || ' | ' ||
             rpad('TYPE LIGNE', 11) || ' | ' || rpad('Num Cpt Facturation', 15) || ' | '  --EDB338
       || rpad('REF2', 15) || ' | ' ||
             rpad('STATUT ALIM', 12) || ' | ' || rpad('ERROR ALIM', 50);

    writeout(vv_header);

    writeout(rpad('-', length(vv_header), '-'));

    FOR rec_ref_non_maj IN c_ref_non_maj LOOP
      vv_message := rpad(rec_ref_non_maj.id_reglement, 10) || ' | ' ||
                    rpad(rec_ref_non_maj.numero_reglement, 12) || ' | ' ||
             rpad(rec_ref_non_maj.uo_reglement, 10) || ' | ' ||
             rpad(rec_ref_non_maj.montant_reglement, 10) || ' | ' ||
             rpad(rec_ref_non_maj.code_devise_reglement, 7) || ' | ' ||
             rpad(rec_ref_non_maj.statut_imputation, 11) || ' | ' ||
             rpad(rec_ref_non_maj.id_piece_gl, 10) || ' | ' ||
             rpad(rec_ref_non_maj.numero_ligne_gl, 10) || ' | ' ||
             rpad(rec_ref_non_maj.id_ligne_rb_gl, 10) || ' | ' ||
             rpad(rec_ref_non_maj.type_ligne_rb_gl, 11) || ' | ' ||
       rpad(rec_ref_non_maj.NUMERO_CPT_FACTURATION_RB, 15) || ' | ' || --EDB338
             rpad(rec_ref_non_maj.reference2_gl, 15) || ' | ' ||
             rpad(rec_ref_non_maj.statut_alimentation_ref2, 12)|| ' | ' ||
             rpad(rec_ref_non_maj.message_alimentation_ref2, 50);

      writeout(vv_message);

    END LOOP;

    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan6');

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN6 : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END report_bilan6;


 /*=====================================================================================*/
  /* PROCEDURE NAME : main6
  /*
  /* DESCRIPTION
  /*  Procédure principale de Alimentation de la référence 2 pour la ligne GL remontée dans RB
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/

  PROCEDURE main6(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

    -- ========== VARIABLES ==========
    v_package        VARCHAR2(30) := 'DKA_SRBFACTURE_PKG';
    v_nom_traitement VARCHAR2(200) := 'DKA : Alimentation de la référence pour la ligne GL dans RB';
    v_sqlerrm        VARCHAR2(250) := NULL;

    v_procedure VARCHAR2(30) := 'MAIN6';
    v_message   VARCHAR2(500);

    v_error  VARCHAR2(4000);


    CURSOR cur_ref IS
    SELECT rl.rowid               rid,
           dpar.rowid             rid2,
           dpar.facture_ap,
           rl.line_id,
           rl.type,
           gjl.description
      FROM rb_lines rl, dka_prel_ap_rb dpar, gl_je_lines gjl
     WHERE rl.je_header_id = dpar.id_piece_gl
       AND rl.je_line_num = dpar.numero_ligne_gl
       AND rl.line_type = 'A'
       AND rl.reference2 IS NULL
       AND dpar.statut_imputation = 'Y'
       AND dpar.id_piece_gl = gjl.je_header_id
       AND dpar.numero_ligne_gl = gjl.je_line_num
       AND dpar.statut_etape = 'E4'
     AND dpar.NUMERO_CPT_FACTURATION_RB IS NULL ; --EDB338


  --EDB338

  CURSOR cur_ref_edf IS
    SELECT rl.rowid               rid,
           dpar.rowid             rid2,
           dpar.facture_ap,
       dpar.NUMERO_CPT_FACTURATION_RB,
           rl.line_id,
           rl.type,
           gjl.description
      FROM rb_lines rl, dka_prel_ap_rb dpar, gl_je_lines gjl
     WHERE rl.je_header_id = dpar.id_piece_gl
       AND rl.je_line_num = dpar.numero_ligne_gl
       AND rl.line_type = 'A'
       AND rl.reference2 IS NULL
     AND dpar.NUMERO_CPT_FACTURATION_RB IS NOT NULL
       AND dpar.statut_imputation = 'Y'
       AND dpar.id_piece_gl = gjl.je_header_id
       AND dpar.numero_ligne_gl = gjl.je_line_num
       AND dpar.statut_etape = 'E4';

  -- END EDB338

    rec_ref cur_ref%ROWTYPE;

  BEGIN

    -- Début du Programme --
    -- ========Initialisation des variables d'anomalies========
    p_retcode := 0;
    p_errbuf  := NULL;
    v_message := 'Début procédure MAIN6';

    -- Initialization des journaux --
    dka_tools_pkg.put_log_message('=======================================================================');
    dka_tools_pkg.put_log_message(v_nom_traitement);
    dka_tools_pkg.put_log_message('=======================================================================');
    dka_tools_pkg.put_log_message('Date de lancement    : ' ||
                                  to_char(SYSDATE,
                                          'DD-MON-YYYY HH24:MI:SS'));
    -- Initialization de la sortie --

    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message(' COMPTE-RENDU DU TRAITEMENT << ' ||
                                       v_nom_traitement || ' >>');
    dka_tools_pkg.put_outdebug_message(' Traitement n° ' ||
                                       to_char(g_request_id));
    dka_tools_pkg.put_outdebug_message(' Le  : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    dka_tools_pkg.put_outdebug_message('--------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('                                                                ');

    SELECT COUNT(1) INTO g_lignes_ref_traitees FROM dka_prel_ap_rb dpar WHERE dpar.statut_etape = 'E4';

    FOR rec_ref IN cur_ref LOOP

       BEGIN

         UPDATE rb_lines rl
            SET reference2 = rec_ref.facture_ap,
                last_update_date = SYSDATE,
                last_updated_by  = g_user_id
          WHERE rl.ROWID = rec_ref.rid;

          BEGIN
             UPDATE dka_prel_ap_rb dpar
                SET reference2_gl            = rec_ref.facture_ap,
                    id_ligne_rb_gl           = rec_ref.line_id,
                    libelle_long_gl          = rec_ref.description,
                    type_ligne_rb_gl         = rec_ref.type,
                    statut_alimentation_ref2 = 'Y',
                    statut_etape = 'E6'
              WHERE ROWID = rec_ref.rid2;

             g_lignes_ref_effectuees := g_lignes_ref_effectuees + 1;

           EXCEPTION
             WHEN OTHERS THEN
               v_error := SQLERRM;

               UPDATE dka_prel_ap_rb dpar
                  SET statut_alimentation_ref2  = 'N',
                      message_alimentation_ref2 = v_error
                WHERE ROWID = rec_ref.rid2;
           END;

       EXCEPTION
         WHEN OTHERS THEN
           v_error := SQLERRM;

           UPDATE dka_prel_ap_rb dpar
              SET statut_alimentation_ref2  = 'N',
                  message_alimentation_ref2 = v_error
            WHERE ROWID = rec_ref.rid2;

       END;

   END LOOP;

    FOR rec_ref_edf IN cur_ref_edf LOOP

       BEGIN

      dka_tools_pkg.put_log_message('step 6 : rec_ref_edf.NUMERO_CPT_FACTURATION_RB : ' ||
                                               rec_ref_edf.NUMERO_CPT_FACTURATION_RB);

         UPDATE rb_lines rl
            SET reference2 = rec_ref_edf.NUMERO_CPT_FACTURATION_RB,
                last_update_date = SYSDATE,
                last_updated_by  = g_user_id
          WHERE rl.ROWID = rec_ref_edf.rid;



      dka_tools_pkg.put_log_message('step 6 : rec_ref_edf.rid : ' ||
                                               rec_ref_edf.rid);

          BEGIN
             UPDATE dka_prel_ap_rb dpar
                SET reference2_gl            = rec_ref_edf.NUMERO_CPT_FACTURATION_RB,
                    id_ligne_rb_gl           = rec_ref_edf.line_id,
                    libelle_long_gl          = rec_ref_edf.description,
                    type_ligne_rb_gl         = rec_ref_edf.type,
                    statut_alimentation_ref2 = 'Y',
                    statut_etape = 'E6'
              WHERE dpar.ROWID = rec_ref_edf.rid2;


      dka_tools_pkg.put_log_message('step 6 : rec_ref_edf.rid2 : ' ||
                                               rec_ref_edf.rid2);

             g_lignes_ref_effectuees := g_lignes_ref_effectuees + 1;

           EXCEPTION
             WHEN OTHERS THEN
               v_error := SQLERRM;

               UPDATE dka_prel_ap_rb dpar
                  SET statut_alimentation_ref2  = 'N',
                      message_alimentation_ref2 = v_error
                WHERE dpar.ROWID = rec_ref_edf.rid2;
           END;

       EXCEPTION
         WHEN OTHERS THEN
           v_error := SQLERRM;

           UPDATE dka_prel_ap_rb dpar
              SET statut_alimentation_ref2  = 'N',
                  message_alimentation_ref2 = v_error
            WHERE dpar.ROWID = rec_ref_edf.rid2;

       END;

   END LOOP;

   COMMIT;--


   SELECT COUNT(1) INTO g_lignes_ref_non_effectuees FROM dka_prel_ap_rb dpar WHERE dpar.statut_etape = 'E4';

   report_bilan6(p_errbuf, p_retcode);

  EXCEPTION
    WHEN OTHERS THEN
      v_sqlerrm := substr(SQLERRM, 1, 200);
      p_retcode := 2;
      p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc ' ||
                   v_package || '.' || v_procedure;
      dka_tools_pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_outdebug_message('Package   : ' || v_package);
      dka_tools_pkg.put_outdebug_message('Procédure : ' || v_procedure);
      dka_tools_pkg.put_outdebug_message('Exception : OTHERS');
      dka_tools_pkg.put_outdebug_message('Message   : ' || v_message);
      dka_tools_pkg.put_log_message(chr(10) || p_errbuf);
      dka_tools_pkg.put_outdebug_message('Cause     : ' || v_sqlerrm);
      dka_tools_pkg.put_outdebug_message('------------------------------------------------');
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
      ROLLBACK;
  END main6;

END dka_sapprelautorb_pkg;

/
SHOW ERRORS
EXIT;