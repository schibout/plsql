requete;execution;date_expiration;fichier_sortie;description
D1_folios_fichiers_ap.sql;oui;31/10/2026;D1_folios_fichiers_ap.csv;Folios (attribute9) et fichiers (attribute10) dans AP_INVOICES_ALL, 30 j ; fichier repete sur plusieurs jours ?
D2_interface_statuts.sql;oui;31/10/2026;D2_interface_statuts.csv;AP_INVOICES_INTERFACE : statuts conserves (purge des PROCESSED ?), rejets entete / ligne
D3_motifs_rejet.sql;oui;31/10/2026;D3_motifs_rejet.csv;Codes de rejet AP_INTERFACE_REJECTIONS par folio, entete et lignes
D4_region_source.sql;oui;31/10/2026;D4_region_source.csv;Region : rapprochement AP -> DKA_IAPFACXGS_REPORTING_ALL et operating units
D5_folio_vs_batchprefix.sql;oui;31/10/2026;D5_folio_vs_batchprefix.csv;Folio AP contre batchprefix DKA ; validation des codes VE1 / L56 / DSP
D6_fichiers_par_jour.sql;oui;31/10/2026;D6_fichiers_par_jour.csv;Apercu : fichiers recus / integrees / rejetees / en attente par jour et folio
../Projet_Dashboard/sql/00_kpi.sql;oui;31/10/2026;00_kpi.csv;Tuiles KPI avec les 3 nouvelles tuiles fichiers (brouillon, a valider)
../Projet_Dashboard/sql/18_fac_fichiers_jour.sql;oui;31/10/2026;18_fac_fichiers_jour.csv;Fichiers factures par jour (brouillon, a valider)
../Projet_Dashboard/sql/19_fac_fichiers_detail.sql;oui;31/10/2026;19_fac_fichiers_detail.csv;Fichiers factures par fichier et folio (brouillon, a valider)
../Projet_Dashboard/sql/20_fac_region.sql;oui;31/10/2026;20_fac_region.csv;Fichiers factures par region (brouillon, a valider)
../Projet_Dashboard/sql/21_fac_rejets_detail.sql;oui;31/10/2026;21_fac_rejets_detail.csv;Rejets AP des fichiers, detail avec motifs (brouillon, a valider)
