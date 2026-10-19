# Inventaire exhaustif des SQL et README

État du dépôt au 17 octobre 2026. 193 fichiers : 159 SQL et 34 README, y compris cinq README techniques de cache. Les objets sont des candidats extraits lexicalement : les commentaires et CTE peuvent produire des faux positifs. La revue fonctionnelle détaillée est décrite dans chaque note.

| Fichier | Lignes | Lot de revue |
|---|---:|---|
| [.github/prompts/README.md](../.github/prompts/README.md) | 236 | Comptabilité / référentiels / autres |
| [.pytest_cache/README.md](../.pytest_cache/README.md) | 8 | Comptabilité / référentiels / autres |
| [Ajout_de_responsabilite/pbAjoutRespon/Fix_WF_Synchro_H00036238E.sql](../Ajout_de_responsabilite/pbAjoutRespon/Fix_WF_Synchro_H00036238E.sql) | 63 | Comptabilité / référentiels / autres |
| [Ajout_de_responsabilite/Utilisateurs ayant une certaine responsabilité.sql](../Ajout_de_responsabilite/Utilisateurs%20ayant%20une%20certaine%20responsabilit%C3%A9.sql) | 26 | Comptabilité / référentiels / autres |
| [AppsScript/cloture/README.md](../AppsScript/cloture/README.md) | 42 | Comptabilité / référentiels / autres |
| [AppsScript/controlePrelevement/README.md](../AppsScript/controlePrelevement/README.md) | 145 | Comptabilité / référentiels / autres |
| [AppsScript/odat/README.md](../AppsScript/odat/README.md) | 124 | Comptabilité / référentiels / autres |
| [ChaineControleM/Inventaire_Complet_Chaines_ControlM.sql](../ChaineControleM/Inventaire_Complet_Chaines_ControlM.sql) | 450 | AR / flux / supervision |
| [ChaineControleM/Inventaire_Jobs_FINFIN.sql](../ChaineControleM/Inventaire_Jobs_FINFIN.sql) | 255 | Comptabilité / référentiels / autres |
| [ChaineControleM/Requete_Programme_ControlM.sql](../ChaineControleM/Requete_Programme_ControlM.sql) | 140 | AR / flux / supervision |
| [cloture2026/Controle_Cloture_Quotidien.sql](../cloture2026/Controle_Cloture_Quotidien.sql) | 475 | Comptabilité / référentiels / autres |
| [cloture2026/Dalkia_Traitements.sql](../cloture2026/Dalkia_Traitements.sql) | 465 | Comptabilité / référentiels / autres |
| [cloture2026/Fev2026/Controle_Cloture_Quotidien.sql](../cloture2026/Fev2026/Controle_Cloture_Quotidien.sql) | 475 | Comptabilité / référentiels / autres |
| [cloture2026/Fev2026/Recherche_La_Crau_Energies_Vertes.sql](../cloture2026/Fev2026/Recherche_La_Crau_Energies_Vertes.sql) | 410 | Comptabilité / référentiels / autres |
| [cloture2026/Fev2026/Responsabilites_ORG_ID_86.sql](../cloture2026/Fev2026/Responsabilites_ORG_ID_86.sql) | 299 | Comptabilité / référentiels / autres |
| [cloture_Cap/CAP_COMMANDES_REJ.sql](../cloture_Cap/CAP_COMMANDES_REJ.sql) | 30 | Comptabilité / référentiels / autres |
| [cloture_Cap/CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql](../cloture_Cap/CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql) | 72 | Comptabilité / référentiels / autres |
| [cloture_Cap/CAP_OD_Cut_Off_SSTR_factures_V3.sql](../cloture_Cap/CAP_OD_Cut_Off_SSTR_factures_V3.sql) | 339 | Comptabilité / référentiels / autres |
| [cloture_Cap/SQL_Provision_OCT-25.sql](../cloture_Cap/SQL_Provision_OCT-25.sql) | 478 | Comptabilité / référentiels / autres |
| [cloturePeriode/sql_J-7.sql](../cloturePeriode/sql_J-7.sql) | 23 | Comptabilité / référentiels / autres |
| [ControleFolioRose/README.md](../ControleFolioRose/README.md) | 163 | AR / flux / supervision |
| [ControleMatinGenerique/Controle_Quotidien_Complet.sql](../ControleMatinGenerique/Controle_Quotidien_Complet.sql) | 826 | AR / flux / supervision |
| [ControleMatinGenerique/README.md](../ControleMatinGenerique/README.md) | 161 | AR / flux / supervision |
| [controleNuit/Controle_Quotidien_Complet.sql](../controleNuit/Controle_Quotidien_Complet.sql) | 605 | AR / flux / supervision |
| [controleNuit/ControleMatin-21012026/Diagnostic_Traitement_AR_46850719.sql](../controleNuit/ControleMatin-21012026/Diagnostic_Traitement_AR_46850719.sql) | 135 | AR / flux / supervision |
| [controleNuit/Q - Verifications qutidiennes.sql](../controleNuit/Q%20-%20Verifications%20qutidiennes.sql) | 289 | AR / flux / supervision |
| [controleNuit/ReadMe.md](../controleNuit/ReadMe.md) | 55 | AR / flux / supervision |
| [controlePaye/XXEAI_CLE_COMPTABLE_CUF_OBJ.sql](../controlePaye/XXEAI_CLE_COMPTABLE_CUF_OBJ.sql) | 38 | AP / fournisseurs / images |
| [controlePaye/XXEAI_INTERFACE_TOOLS_PKG.sql](../controlePaye/XXEAI_INTERFACE_TOOLS_PKG.sql) | 2685 | AP / fournisseurs / images |
| [ControleReleveBancaire/Analyse_Verification_Import_Releves_Bancaires.sql](../ControleReleveBancaire/Analyse_Verification_Import_Releves_Bancaires.sql) | 301 | Comptabilité / référentiels / autres |
| [ControleReleveBancaire/DKA_SRBCTRLRB_PKG.sql](../ControleReleveBancaire/DKA_SRBCTRLRB_PKG.sql) | 645 | Comptabilité / référentiels / autres |
| [ControleReleveBancaire/README.md](../ControleReleveBancaire/README.md) | 190 | Comptabilité / référentiels / autres |
| [controleVirement/.pytest_cache/README.md](../controleVirement/.pytest_cache/README.md) | 8 | Comptabilité / référentiels / autres |
| [controlMnonLance/Requete_Traitements_Faible_Frequence_Mensuelle.sql](../controlMnonLance/Requete_Traitements_Faible_Frequence_Mensuelle.sql) | 115 | AR / flux / supervision |
| [CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/.pytest_cache/README.md](../CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/.pytest_cache/README.md) | 8 | Comptabilité / référentiels / autres |
| [CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/docs/README_ecart_589_20260914.md](../CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/docs/README_ecart_589_20260914.md) | 114 | Comptabilité / référentiels / autres |
| [dateFinEmploye/body.sql](../dateFinEmploye/body.sql) | 8915 | Comptabilité / référentiels / autres |
| [dateFinEmploye/export/xxeai_hr_assignment_int.sql](../dateFinEmploye/export/xxeai_hr_assignment_int.sql) | 297 | Comptabilité / référentiels / autres |
| [dateFinEmploye/export/xxeai_hr_bank_int_all.sql](../dateFinEmploye/export/xxeai_hr_bank_int_all.sql) | 297 | Comptabilité / référentiels / autres |
| [dateFinEmploye/export/XXEAI_HR_PEOPLE_INT.sql](../dateFinEmploye/export/XXEAI_HR_PEOPLE_INT.sql) | 264 | Comptabilité / référentiels / autres |
| [dateFinEmploye/reverse_termination.sql](../dateFinEmploye/reverse_termination.sql) | 62 | Comptabilité / référentiels / autres |
| [dateFinUser/desactivation_users.sql](../dateFinUser/desactivation_users.sql) | 382 | Comptabilité / référentiels / autres |
| [DiagnosticWebadi/README.md](../DiagnosticWebadi/README.md) | 114 | AP / fournisseurs / images |
| [diversAnalyses/ControleFolioRose.sql](../diversAnalyses/ControleFolioRose.sql) | 47 | AR / flux / supervision |
| [diversAnalyses/CORRECTION_GL_Dacar_GK1596490T.sql](../diversAnalyses/CORRECTION_GL_Dacar_GK1596490T.sql) | 236 | AR / flux / supervision |
| [diversAnalyses/get_ebs_info.sql](../diversAnalyses/get_ebs_info.sql) | 3 | Comptabilité / référentiels / autres |
| [diversAnalyses/get_main_programs.sql](../diversAnalyses/get_main_programs.sql) | 28 | Comptabilité / référentiels / autres |
| [diversAnalyses/get_ou_info.sql](../diversAnalyses/get_ou_info.sql) | 13 | Comptabilité / référentiels / autres |
| [diversAnalyses/Open AP Invoices.sql](../diversAnalyses/Open%20AP%20Invoices.sql) | 49 | Comptabilité / référentiels / autres |
| [diversAnalyses/oracleProd.sql](../diversAnalyses/oracleProd.sql) | 33 | Comptabilité / référentiels / autres |
| [diversAnalyses/Recherche_Fournisseur_Groupe_Services_France.sql](../diversAnalyses/Recherche_Fournisseur_Groupe_Services_France.sql) | 325 | Comptabilité / référentiels / autres |
| [diversAnalyses/Requete_Suppression_Doublons_IARPAFAC_CORRIGEE.sql](../diversAnalyses/Requete_Suppression_Doublons_IARPAFAC_CORRIGEE.sql) | 230 | AR / flux / supervision |
| [diversAnalyses/Requête statut des factures AP.sql](../diversAnalyses/Requ%C3%AAte%20statut%20des%20factures%20AP.sql) | 154 | Comptabilité / référentiels / autres |
| [diversAnalyses/run_direct.sql](../diversAnalyses/run_direct.sql) | 9 | Comptabilité / référentiels / autres |
| [diversAnalyses/temp_oracleProd_20260605_141040.sql](../diversAnalyses/temp_oracleProd_20260605_141040.sql) | 50 | Comptabilité / référentiels / autres |
| [diversAnalyses/temp_test.sql](../diversAnalyses/temp_test.sql) | 614 | Comptabilité / référentiels / autres |
| [diversAnalyses/Traitement_longue_duree_27nov.sql](../diversAnalyses/Traitement_longue_duree_27nov.sql) | 67 | Comptabilité / référentiels / autres |
| [diversAnalyses/Utilisateurs ayant une certaine responsabilité.sql](../diversAnalyses/Utilisateurs%20ayant%20une%20certaine%20responsabilit%C3%A9.sql) | 26 | Comptabilité / référentiels / autres |
| [DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG.sql](../DKA%20%20Int%C3%A9gration%20des%20factures%20XEROX/DKA_IAPFACXGS_PKG.sql) | 6763 | AP / fournisseurs / images |
| [DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG_ETI1.sql](../DKA%20%20Int%C3%A9gration%20des%20factures%20XEROX/DKA_IAPFACXGS_PKG_ETI1.sql) | 6899 | AP / fournisseurs / images |
| [DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG_PROD.sql](../DKA%20%20Int%C3%A9gration%20des%20factures%20XEROX/DKA_IAPFACXGS_PKG_PROD.sql) | 6763 | AP / fournisseurs / images |
| [DKA  Intégration des factures XEROX/README.md](../DKA%20%20Int%C3%A9gration%20des%20factures%20XEROX/README.md) | 58 | AP / fournisseurs / images |
| [DTR-BO/Analyse_requete_provisions_NOV25.sql](../DTR-BO/Analyse_requete_provisions_NOV25.sql) | 313 | Comptabilité / référentiels / autres |
| [DTR-BO/ancienneReq.sql](../DTR-BO/ancienneReq.sql) | 80 | Comptabilité / référentiels / autres |
| [DTR-BO/README_Changement_APPLIED_TO_NOV25.md](../DTR-BO/README_Changement_APPLIED_TO_NOV25.md) | 90 | Comptabilité / référentiels / autres |
| [DTR-BO/requete.sql](../DTR-BO/requete.sql) | 82 | Comptabilité / référentiels / autres |
| [DTR-BO/Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql](../DTR-BO/Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql) | 197 | Comptabilité / référentiels / autres |
| [DTR-BO/Requete_provisions_NOV25_CORRIGEE.sql](../DTR-BO/Requete_provisions_NOV25_CORRIGEE.sql) | 214 | Comptabilité / référentiels / autres |
| [DTR-BO/requeteDiag.sql](../DTR-BO/requeteDiag.sql) | 38 | Comptabilité / référentiels / autres |
| [DTR-BO/requeteNVetAn.sql](../DTR-BO/requeteNVetAn.sql) | 187 | Comptabilité / référentiels / autres |
| [exportImageVers Ivalua/README.md](../exportImageVers%20Ivalua/README.md) | 331 | AP / fournisseurs / images |
| [exportImageVers Ivalua/Renvoi_Image_Facture_Ivalua.sql](../exportImageVers%20Ivalua/Renvoi_Image_Facture_Ivalua.sql) | 374 | AP / fournisseurs / images |
| [factureEndoubleTableStandrad/Detection_Doublons_IARPAFAC_V1.sql](../factureEndoubleTableStandrad/Detection_Doublons_IARPAFAC_V1.sql) | 304 | AR / flux / supervision |
| [factureEndoubleTableStandrad/Detection_Doublons_IARPAFAC_V3_avec_table.sql](../factureEndoubleTableStandrad/Detection_Doublons_IARPAFAC_V3_avec_table.sql) | 219 | AR / flux / supervision |
| [factureEndoubleTableStandrad/Extraction_Depenses_GS0211082R_Soc348.sql](../factureEndoubleTableStandrad/Extraction_Depenses_GS0211082R_Soc348.sql) | 180 | Comptabilité / référentiels / autres |
| [factureEndoubleTableStandrad/Rapport_Doublons_OpenInterface_AR.sql](../factureEndoubleTableStandrad/Rapport_Doublons_OpenInterface_AR.sql) | 240 | Comptabilité / référentiels / autres |
| [factureEndoubleTableStandrad/Suppression_Doublons_Execution.sql](../factureEndoubleTableStandrad/Suppression_Doublons_Execution.sql) | 192 | Comptabilité / référentiels / autres |
| [factureEndoubleTableStandrad/Suppression_Doublons_OpenInterface_AR.sql](../factureEndoubleTableStandrad/Suppression_Doublons_OpenInterface_AR.sql) | 319 | Comptabilité / référentiels / autres |
| [FactureLitige/DKA_GENERATE_URL_IMAGE_BDC_OPTIMISEE.sql](../FactureLitige/DKA_GENERATE_URL_IMAGE_BDC_OPTIMISEE.sql) | 261 | Comptabilité / référentiels / autres |
| [FactureLitige/DKA_GENERATE_URL_IMAGE_FACTURE_SOURCE.sql](../FactureLitige/DKA_GENERATE_URL_IMAGE_FACTURE_SOURCE.sql) | 178 | Comptabilité / référentiels / autres |
| [FactureLitige/optimized_query.sql](../FactureLitige/optimized_query.sql) | 147 | Comptabilité / référentiels / autres |
| [FactureLitige/original_query.sql](../FactureLitige/original_query.sql) | 73 | Comptabilité / référentiels / autres |
| [FactureLitige/README_Optimisation_SQL_Export_Gestion_Litiges.md](../FactureLitige/README_Optimisation_SQL_Export_Gestion_Litiges.md) | 227 | Comptabilité / référentiels / autres |
| [FactureLitige/Referentiel_Fournisseur.sql](../FactureLitige/Referentiel_Fournisseur.sql) | 169 | Comptabilité / référentiels / autres |
| [FactureLitige/Referentiel_Fournisseur_OPTIMISEE.sql](../FactureLitige/Referentiel_Fournisseur_OPTIMISEE.sql) | 199 | Comptabilité / référentiels / autres |
| [FactureLitige/Script_Generation_BDC_2026_Mensuel.sql](../FactureLitige/Script_Generation_BDC_2026_Mensuel.sql) | 258 | Comptabilité / référentiels / autres |
| [FactureLitige/SQL_Export_Gestion_Litiges.sql](../FactureLitige/SQL_Export_Gestion_Litiges.sql) | 158 | Comptabilité / référentiels / autres |
| [FactureLitige/SQL_Export_Gestion_Litiges_OPTIMISEE.sql](../FactureLitige/SQL_Export_Gestion_Litiges_OPTIMISEE.sql) | 272 | Comptabilité / référentiels / autres |
| [fermetureCommandesPO/archive/fermeture_commandes_04122025.sql](../fermetureCommandesPO/archive/fermeture_commandes_04122025.sql) | 223 | Comptabilité / référentiels / autres |
| [fermetureCommandesPO/archive/fermeture_commandes_23122025.sql](../fermetureCommandesPO/archive/fermeture_commandes_23122025.sql) | 201 | Comptabilité / référentiels / autres |
| [fermetureCommandesPO/archive/fermeture_commandes_24122025.sql](../fermetureCommandesPO/archive/fermeture_commandes_24122025.sql) | 204 | Comptabilité / référentiels / autres |
| [fermetureCommandesPO/archive/fermeture_commandes_26012026.sql](../fermetureCommandesPO/archive/fermeture_commandes_26012026.sql) | 186 | Comptabilité / référentiels / autres |
| [fermetureCommandesPO/archive/fermeture_commandes_30012026.sql](../fermetureCommandesPO/archive/fermeture_commandes_30012026.sql) | 207 | Comptabilité / référentiels / autres |
| [fermetureCommandesPO/archive/hindFermeture.sql](../fermetureCommandesPO/archive/hindFermeture.sql) | 162 | Comptabilité / référentiels / autres |
| [fermetureCommandesPO/archive/hindFermetureEhanced.sql](../fermetureCommandesPO/archive/hindFermetureEhanced.sql) | 296 | Comptabilité / référentiels / autres |
| [FichierControleFluxCoteUnix/.pytest_cache/README.md](../FichierControleFluxCoteUnix/.pytest_cache/README.md) | 8 | AR / flux / supervision |
| [FichierControleFluxCoteUnix/Logs/requetes_fac02_frs_25082026_162844.sql](../FichierControleFluxCoteUnix/Logs/requetes_fac02_frs_25082026_162844.sql) | 92 | AR / flux / supervision |
| [FichierControleFluxCoteUnix/README.md](../FichierControleFluxCoteUnix/README.md) | 268 | AR / flux / supervision |
| [FichierPaie22012026/extract_package.sql](../FichierPaie22012026/extract_package.sql) | 51 | Comptabilité / référentiels / autres |
| [FichierPaie22012026/README_Package_Extraction.md](../FichierPaie22012026/README_Package_Extraction.md) | 35 | Comptabilité / référentiels / autres |
| [INtegrationDesNoteDeFrais/Correction_Dates_Notilus.sql](../INtegrationDesNoteDeFrais/Correction_Dates_Notilus.sql) | 401 | AP / fournisseurs / images |
| [INtegrationDesNoteDeFrais/MOA - modif période dans O.I. pour Notilus_V2.sql](../INtegrationDesNoteDeFrais/MOA%20-%20modif%20p%C3%A9riode%20dans%20O.I.%20pour%20Notilus_V2.sql) | 185 | AP / fournisseurs / images |
| [INtegrationDesNoteDeFrais/ReadMe.md](../INtegrationDesNoteDeFrais/ReadMe.md) | 91 | AP / fournisseurs / images |
| [Ivalua/Vérification chargmt depuis iValua (1).sql](../Ivalua/V%C3%A9rification%20chargmt%20depuis%20iValua%20%281%29.sql) | 29 | AP / fournisseurs / images |
| [Ivalua/Vérification chargmt depuis iValua.sql](../Ivalua/V%C3%A9rification%20chargmt%20depuis%20iValua.sql) | 29 | AP / fournisseurs / images |
| [JiraKDFI3809/CAP_OD_Cut_Off_SSTR_factures_V3.sql](../JiraKDFI3809/CAP_OD_Cut_Off_SSTR_factures_V3.sql) | 339 | Comptabilité / référentiels / autres |
| [JiraKDFI3809/SSTR_Od_Cut_Off_détail_factures_V4.sql](../JiraKDFI3809/SSTR_Od_Cut_Off_d%C3%A9tail_factures_V4.sql) | 127 | Comptabilité / référentiels / autres |
| [KDFI-2198-ControleFlux/deploiement_correction_avoirs.sql](../KDFI-2198-ControleFlux/deploiement_correction_avoirs.sql) | 166 | AR / flux / supervision |
| [KDFI-2198-ControleFlux/README.md](../KDFI-2198-ControleFlux/README.md) | 249 | AR / flux / supervision |
| [KDFI-2198-ControleFlux/requ.sql](../KDFI-2198-ControleFlux/requ.sql) | 279 | AR / flux / supervision |
| [KDFI-2198-ControleFlux/rerun_sctlflux_eai_CYC_2025-12-02.sql](../KDFI-2198-ControleFlux/rerun_sctlflux_eai_CYC_2025-12-02.sql) | 68 | AR / flux / supervision |
| [KDFI-2198-ControleFlux/Reset_Et_Rejouer_SCTLFLUX_EAI.sql](../KDFI-2198-ControleFlux/Reset_Et_Rejouer_SCTLFLUX_EAI.sql) | 221 | AR / flux / supervision |
| [KDFI-2198-ControleFlux/Test_diagnostic_CYC.sql](../KDFI-2198-ControleFlux/Test_diagnostic_CYC.sql) | 290 | AR / flux / supervision |
| [KDFI-2198-ControleFlux/Validation_correction_CYC.sql](../KDFI-2198-ControleFlux/Validation_correction_CYC.sql) | 151 | AR / flux / supervision |
| [KDFI-2198-ControleFlux/Verification_correction_avoirs.sql](../KDFI-2198-ControleFlux/Verification_correction_avoirs.sql) | 223 | AR / flux / supervision |
| [KDFI-3422/maj_last_update_date_categories.sql](../KDFI-3422/maj_last_update_date_categories.sql) | 157 | Comptabilité / référentiels / autres |
| [KDFI-3426AnnulerBonDecommande/annulation_PO_4736744ST2501.sql](../KDFI-3426AnnulerBonDecommande/annulation_PO_4736744ST2501.sql) | 336 | Comptabilité / référentiels / autres |
| [KDFI-3825-CUT OFF SSTR/SSTR_Od_Cut_Off_détail_factures_V4.sql](../KDFI-3825-CUT%20OFF%20SSTR/SSTR_Od_Cut_Off_d%C3%A9tail_factures_V4.sql) | 127 | Comptabilité / référentiels / autres |
| [KDFI3357-Integration clients/README.md](../KDFI3357-Integration%20clients/README.md) | 348 | AR / flux / supervision |
| [KDFI3357-Integration clients/README_IFS_AR.md](../KDFI3357-Integration%20clients/README_IFS_AR.md) | 271 | AR / flux / supervision |
| [lanceurCentrale/Analyse_Erreur_Control_Fournisseur/Control_Fournisseur_CORRIGEE.sql](../lanceurCentrale/Analyse_Erreur_Control_Fournisseur/Control_Fournisseur_CORRIGEE.sql) | 586 | Comptabilité / référentiels / autres |
| [Ligne_AR_En_Double/Detection_Doublons_RA_INTERFACE_LINES.sql](../Ligne_AR_En_Double/Detection_Doublons_RA_INTERFACE_LINES.sql) | 285 | AR / flux / supervision |
| [Ligne_AR_En_Double/insert_data.sql](../Ligne_AR_En_Double/insert_data.sql) | 664 | AR / flux / supervision |
| [Ligne_AR_En_Double/insert_data_CORRIGE.sql](../Ligne_AR_En_Double/insert_data_CORRIGE.sql) | 538 | AR / flux / supervision |
| [Ligne_AR_En_Double/Sauvegarde_et_Suppression_Doublons_PRODUCTION.sql](../Ligne_AR_En_Double/Sauvegarde_et_Suppression_Doublons_PRODUCTION.sql) | 380 | AR / flux / supervision |
| [Ligne_AR_En_Double/Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql](../Ligne_AR_En_Double/Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql) | 530 | AR / flux / supervision |
| [Ligne_AR_En_Double/Suppression_Doublons_DKA_IARPAFAC_INTERFACE_PRODUCTION.sql](../Ligne_AR_En_Double/Suppression_Doublons_DKA_IARPAFAC_INTERFACE_PRODUCTION.sql) | 527 | AR / flux / supervision |
| [Ligne_AR_En_Double/suppression_doublons_PRODUCTION.sql](../Ligne_AR_En_Double/suppression_doublons_PRODUCTION.sql) | 351 | AR / flux / supervision |
| [lionelDtr/XXEAI.sql](../lionelDtr/XXEAI.sql) | 3102 | Comptabilité / référentiels / autres |
| [MiseaJourFournisseurs/Definition_programme_maj_sites_fournisseurs.sql](../MiseaJourFournisseurs/Definition_programme_maj_sites_fournisseurs.sql) | 133 | Comptabilité / référentiels / autres |
| [MiseaJourFournisseurs/Detail_algorithme_maj_sites_fournisseurs.sql](../MiseaJourFournisseurs/Detail_algorithme_maj_sites_fournisseurs.sql) | 653 | Comptabilité / référentiels / autres |
| [miseAjourGL/Update_GL_JE_LINES_ATTRIBUTE13_MO_HORS_THO.sql](../miseAjourGL/Update_GL_JE_LINES_ATTRIBUTE13_MO_HORS_THO.sql) | 190 | Comptabilité / référentiels / autres |
| [odat_watch/.pytest_cache/README.md](../odat_watch/.pytest_cache/README.md) | 8 | Comptabilité / référentiels / autres |
| [odat_watch/README.md](../odat_watch/README.md) | 305 | Comptabilité / référentiels / autres |
| [OptimisationRequete/FACTURES_EN_COURS_V3_Q1.sql](../OptimisationRequete/FACTURES_EN_COURS_V3_Q1.sql) | 258 | Comptabilité / référentiels / autres |
| [Projet_CTM/README.md](../Projet_CTM/README.md) | 91 | Comptabilité / référentiels / autres |
| [Projet_Dashboard/README.md](../Projet_Dashboard/README.md) | 65 | AR / flux / supervision |
| [Projet_Dashboard/sql/00_kpi.sql](../Projet_Dashboard/sql/00_kpi.sql) | 77 | AR / flux / supervision |
| [Projet_Dashboard/sql/01_dsp_flux.sql](../Projet_Dashboard/sql/01_dsp_flux.sql) | 47 | AR / flux / supervision |
| [Projet_Dashboard/sql/02_dsp_synthese.sql](../Projet_Dashboard/sql/02_dsp_synthese.sql) | 44 | AR / flux / supervision |
| [Projet_Dashboard/sql/03_ndf_notilus.sql](../Projet_Dashboard/sql/03_ndf_notilus.sql) | 14 | AP / fournisseurs / images |
| [Projet_Dashboard/sql/04_factures_source.sql](../Projet_Dashboard/sql/04_factures_source.sql) | 12 | AR / flux / supervision |
| [Projet_Dashboard/sql/05_xerox_sans_image.sql](../Projet_Dashboard/sql/05_xerox_sans_image.sql) | 29 | AP / fournisseurs / images |
| [Projet_Dashboard/sql/06_xerox_avec_image.sql](../Projet_Dashboard/sql/06_xerox_avec_image.sql) | 15 | AP / fournisseurs / images |
| [Projet_Dashboard/sql/07_fac_ar_recues.sql](../Projet_Dashboard/sql/07_fac_ar_recues.sql) | 15 | AR / flux / supervision |
| [Projet_Dashboard/sql/08_fac_ar_rejets.sql](../Projet_Dashboard/sql/08_fac_ar_rejets.sql) | 16 | AR / flux / supervision |
| [Projet_Dashboard/sql/09_gl_interface.sql](../Projet_Dashboard/sql/09_gl_interface.sql) | 19 | AR / flux / supervision |
| [Projet_Dashboard/sql/10_gl_lignes.sql](../Projet_Dashboard/sql/10_gl_lignes.sql) | 13 | AR / flux / supervision |
| [Projet_Dashboard/sql/11_nuit_synthese.sql](../Projet_Dashboard/sql/11_nuit_synthese.sql) | 27 | AR / flux / supervision |
| [Projet_Dashboard/sql/12_nuit_erreurs_programme.sql](../Projet_Dashboard/sql/12_nuit_erreurs_programme.sql) | 25 | AR / flux / supervision |
| [Projet_Dashboard/sql/13_nuit_erreurs_detail.sql](../Projet_Dashboard/sql/13_nuit_erreurs_detail.sql) | 20 | AR / flux / supervision |
| [Projet_Dashboard/sql/14_nuit_warnings.sql](../Projet_Dashboard/sql/14_nuit_warnings.sql) | 19 | AR / flux / supervision |
| [Projet_Dashboard/sql/15_nuit_longs.sql](../Projet_Dashboard/sql/15_nuit_longs.sql) | 17 | AR / flux / supervision |
| [Projet_Dashboard/sql/16_nuit_en_cours.sql](../Projet_Dashboard/sql/16_nuit_en_cours.sql) | 15 | AR / flux / supervision |
| [Projet_Dashboard/sql/17_rb_imports.sql](../Projet_Dashboard/sql/17_rb_imports.sql) | 12 | AR / flux / supervision |
| [Projet_Dashboard/sql/18_demat_statut.sql](../Projet_Dashboard/sql/18_demat_statut.sql) | 9 | AR / flux / supervision |
| [Projet_Dashboard/sql/19_demat_par_jour.sql](../Projet_Dashboard/sql/19_demat_par_jour.sql) | 14 | AR / flux / supervision |
| [Projet_Dashboard/sql/20_demat_en_attente.sql](../Projet_Dashboard/sql/20_demat_en_attente.sql) | 6 | AR / flux / supervision |
| [Projet_Virements/README.md](../Projet_Virements/README.md) | 219 | Comptabilité / référentiels / autres |
| [README.md](../README.md) | 100 | Comptabilité / référentiels / autres |
| [Recherche_Facture_11633263.sql](../Recherche_Facture_11633263.sql) | 139 | AP / fournisseurs / images |
| [repousseGL/repouusse.sql](../repousseGL/repouusse.sql) | 184 | Comptabilité / référentiels / autres |
| [responable_hierachique/DKA_SAPWFCSP_PKG.sql](../responable_hierachique/DKA_SAPWFCSP_PKG.sql) | 14200 | Comptabilité / référentiels / autres |
| [responable_hierachique/Requetes_Diagnostic_Routage_BAP_0380.sql](../responable_hierachique/Requetes_Diagnostic_Routage_BAP_0380.sql) | 206 | Comptabilité / référentiels / autres |
| [robot/CA_global_concat_CORRIGE.sql](../robot/CA_global_concat_CORRIGE.sql) | 196 | Comptabilité / référentiels / autres |
| [ScriptsLanceurCentrale/D1_folios_fichiers_ap.sql](../ScriptsLanceurCentrale/D1_folios_fichiers_ap.sql) | 31 | AR / flux / supervision |
| [ScriptsLanceurCentrale/D2_interface_statuts.sql](../ScriptsLanceurCentrale/D2_interface_statuts.sql) | 12 | AR / flux / supervision |
| [ScriptsLanceurCentrale/D3_motifs_rejet.sql](../ScriptsLanceurCentrale/D3_motifs_rejet.sql) | 21 | AR / flux / supervision |
| [ScriptsLanceurCentrale/D4_region_source.sql](../ScriptsLanceurCentrale/D4_region_source.sql) | 33 | AR / flux / supervision |
| [ScriptsLanceurCentrale/D5_folio_vs_batchprefix.sql](../ScriptsLanceurCentrale/D5_folio_vs_batchprefix.sql) | 23 | AR / flux / supervision |
| [ScriptsLanceurCentrale/ENCOURAP_OPTIMISE.sql](../ScriptsLanceurCentrale/ENCOURAP_OPTIMISE.sql) | 313 | AR / flux / supervision |
| [ScriptsLanceurCentrale/FACTURES_EN_COURS_V2_Q2.sql](../ScriptsLanceurCentrale/FACTURES_EN_COURS_V2_Q2.sql) | 287 | AR / flux / supervision |
| [ScriptsLanceurCentrale/FACTURES_EN_COURS_V2_Q3.sql](../ScriptsLanceurCentrale/FACTURES_EN_COURS_V2_Q3.sql) | 283 | AR / flux / supervision |
| [ScriptsLanceurCentrale/README_GDRIVE_TOKEN.md](../ScriptsLanceurCentrale/README_GDRIVE_TOKEN.md) | 65 | AR / flux / supervision |
| [ScriptsLanceurCentrale/README_LOCAL.md](../ScriptsLanceurCentrale/README_LOCAL.md) | 282 | AR / flux / supervision |
| [ScriptsLanceurCentrale/README_UN_SQL.md](../ScriptsLanceurCentrale/README_UN_SQL.md) | 103 | AR / flux / supervision |
| [sql/appinit.sql](../sql/appinit.sql) | 3 | Comptabilité / référentiels / autres |
| [sql/CSP_Onglet_Litige.sql](../sql/CSP_Onglet_Litige.sql) | 192 | Comptabilité / référentiels / autres |
| [sql/oracleProd4.sql](../sql/oracleProd4.sql) | 3 | Comptabilité / référentiels / autres |
| [sql/oracleProd~2.sql](../sql/oracleProd~2.sql) | 73 | Comptabilité / référentiels / autres |
| [sql/oracleProd~3.sql](../sql/oracleProd~3.sql) | 27 | Comptabilité / référentiels / autres |
| [SSTR/README_Optimisation_SQL_Provision.md](../SSTR/README_Optimisation_SQL_Provision.md) | 104 | Comptabilité / référentiels / autres |
| [SSTR/SQL_Provision_OCT-25.sql](../SSTR/SQL_Provision_OCT-25.sql) | 466 | Comptabilité / référentiels / autres |
| [synchroDackShop/update.sql](../synchroDackShop/update.sql) | 137 | AP / fournisseurs / images |
| [synchroDackShop/updateAp_invoices_all/Update_AP_Invoices_Date_Jour.sql](../synchroDackShop/updateAp_invoices_all/Update_AP_Invoices_Date_Jour.sql) | 126 | AP / fournisseurs / images |
| [TACHE_FRONTAL_FINANCE/REFRESH_MV_20h00.sql](../TACHE_FRONTAL_FINANCE/REFRESH_MV_20h00.sql) | 79 | Comptabilité / référentiels / autres |
| [TALEND/Monitoring_Jobs_Talend.sql](../TALEND/Monitoring_Jobs_Talend.sql) | 276 | AR / flux / supervision |
| [TP12011976/requete_index_contrainte.sql](../TP12011976/requete_index_contrainte.sql) | 54 | Comptabilité / référentiels / autres |
| [UpdateApInvoice-DacShop/update_invoice_3850521294.sql](../UpdateApInvoice-DacShop/update_invoice_3850521294.sql) | 146 | AP / fournisseurs / images |
| [verification_user/verification_user.sql](../verification_user/verification_user.sql) | 65 | Comptabilité / référentiels / autres |
| [webadi/package.sql](../webadi/package.sql) | 196 | AP / fournisseurs / images |
| [webadi/packagebody.sql](../webadi/packagebody.sql) | 2308 | AP / fournisseurs / images |
| [XXEAI_INTERFACE_TOOLS_PKG/XXEAI_INTERFACE_TOOLS_PKG.sql](../XXEAI_INTERFACE_TOOLS_PKG/XXEAI_INTERFACE_TOOLS_PKG.sql) | 3079 | AP / fournisseurs / images |

## Copies strictement identiques

Égalité des octets uniquement : elle ne prouve pas quelle version est déployée.

- `.pytest_cache/README.md` ; `controleVirement/.pytest_cache/README.md` ; `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS/.pytest_cache/README.md` ; `FichierControleFluxCoteUnix/.pytest_cache/README.md` ; `odat_watch/.pytest_cache/README.md`
- `Ajout_de_responsabilite/Utilisateurs ayant une certaine responsabilité.sql` ; `diversAnalyses/Utilisateurs ayant une certaine responsabilité.sql`
- `DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG.sql` ; `DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG_PROD.sql`
- `Ivalua/Vérification chargmt depuis iValua (1).sql` ; `Ivalua/Vérification chargmt depuis iValua.sql`
- `JiraKDFI3809/SSTR_Od_Cut_Off_détail_factures_V4.sql` ; `KDFI-3825-CUT OFF SSTR/SSTR_Od_Cut_Off_détail_factures_V4.sql`


