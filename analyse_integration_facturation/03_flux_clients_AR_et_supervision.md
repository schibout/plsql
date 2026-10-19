# Intégration des factures clients et supervision transversale

Analyse statique du corpus SQL/README au 17 octobre 2026. Aucun SQL, correctif, déploiement, envoi de mail ou appel Oracle n’a été exécuté. Les références `fichier:ligne` se rapportent aux sources du dépôt. Une preuve documentaire décrit le contenu disponible, sans attester son déploiement ni l’état actuel de la production.

## Chaîne fonctionnelle reconstituée

La facturation clients comprend deux chaînes complémentaires : l’alimentation du référentiel SIC/IFS vers AR et l’intégration des pièces de facturation. Le référentiel est un prérequis fonctionnel : sociétés/CDG, sites de facturation, profils et collecteurs doivent exister pour rendre les factures exploitables.

| Étape | Objets et règles attestés | Preuve |
|---|---|---|
| Réception référentiel | EAI alimente `DKA_ICLIENTIFS_INTERFACE` et `DKA_ICLIENTIFS_COLLECTORS` | `KDFI3357-Integration clients/README_IFS_AR.md:30` |
| Préparation/import/finalisation | `DKA_ICLIENTIFS_PKG.pre_oi`, `IN_OI`, `post_oi`; programmes `_1`, `_3`, `_2` dans cet ordre | `KDFI3357-Integration clients/README_IFS_AR.md:160`, `:181`, `:198` |
| Données clients | Payeurs/destinataires uniquement; duplication automatique des sites par société/CDG à partir des fichiers de facturation; fusions manuelles | `KDFI3357-Integration clients/README_IFS_AR.md:46`, `:85`, `:104` |
| Réception factures | Paire `*_SRC_FACTURESCLIENTS_*` / `*_CTL_FACTURESCLIENTS_*`, mêmes identifiants et séquences | `FichierControleFluxCoteUnix/README.md:5` |
| Contrôle amont | Par portefeuille, compter les lignes `411*` et sommer les montants en centimes après prise en compte du signe/sens; tolérance 0,005 | `FichierControleFluxCoteUnix/README.md:38`, `:54`, `:77` |
| Transformation/publication | `TARGET/FACTURESCLIENTS_FIN01.txt` cible `DKA_IARPAFAC_INTERFACE`; rapprochement SRC → cible → TS_OUT → rejets → Oracle | `FichierControleFluxCoteUnix/README.md:177` |
| Open interface AR | Suivi de `RA_INTERFACE_LINES_ALL`, erreurs `RA_INTERFACE_ERRORS_ALL`; rapprochement avec les factures reçues | `Projet_Dashboard/sql/07_fac_ar_recues.sql:10`, `08_fac_ar_rejets.sql:8` |
| Intégration finale | `RA_CUSTOMER_TRX_ALL` / `RA_CUSTOMER_TRX_LINES_ALL` rapprochés de l’interface spécifique | `FichierControleFluxCoteUnix/README.md:229` |
| Contrôle de flux | `DKA_SCTLFLUX_EAI_PKG.main` produit `DKA_SCTLFLUX_EAI`; suivi des pièces déjà prises via `DKA_SCTLFLUX_ARFLAG_EAI` et attributs de marquage | `KDFI-2198-ControleFlux/README.md:205`, `Reset_Et_Rejouer_SCTLFLUX_EAI.sql:17` |

Le contrôle SRC/CTL prouve la cohérence du fichier amont; une publication TS_OUT prouve une transmission; le rapprochement avec les tables définitives prouve une intégration métier. Ces preuves doivent être conservées séparément. Le README distingue explicitement cette cascade (`FichierControleFluxCoteUnix/README.md:179`). Le code des lanceurs, scripts Python, PowerShell et packages référencés n’appartient pas à ce sous-périmètre SQL/README : leurs comportements restent des déclarations documentaires ici.

## Identifiants, statuts et rapprochements

La clé métier d’une facture ne doit pas être réduite au numéro : l’origine, la société et le fichier sont présents dans l’interface spécifique. Dans l’interface standard, le mapping documenté est `INTERFACE_LINE_ATTRIBUTE1 = ORIGIN`, `2 = COMPANY_CODE`, `3 = INVOICE_NUMBER`, `4 = LINE_NUMBER`, `5 = période YYYYMM` (`Ligne_AR_En_Double/Detection_Doublons_RA_INTERFACE_LINES.sql:11`). Les diagnostics de doublons incluent aussi le contexte; les requêtes de dashboard, elles, rapprochent seulement `trx_number = invoice_number` (`Projet_Dashboard/sql/07_fac_ar_recues.sql:10`). **Risque inféré** : confusion entre deux factures de même numéro appartenant à des sociétés/origines différentes.

| Domaine | Statuts/indicateurs documentés | Interprétation et réserve |
|---|---|---|
| Référentiel client IFS | `OA_STATUS` P/A/E/R | En attente / accepté / erreur technique / rejet métier; définition propre à cette interface (`KDFI3357-Integration clients/README.md:165`) |
| Facture spécifique | `NVL(OA_STATUS,'P') != 'A'` | Sélection non soldée dans l’extrait de contrôle (`KDFI-2198-ControleFlux/requ.sql:85`); ne pas généraliser automatiquement la nomenclature IFS |
| Résultat rapprochement | INTEGREE, EN INTERFACE, PARTIELLE, ABSENTE, ECART, puis REJETEE | Résultat calculé, distinct des statuts persistés (`FichierControleFluxCoteUnix/README.md:237`, `:249`) |
| Publication Talend | INTEGRE_COMPLET, INTEGRE_PARTIEL_REJETS, NON_PUBLIE, ECART_INEXPLIQUE, DEMI_FLUX2_ABSENT | Diagnostics de cascade; « complet » ici décrit le départ vers Oracle (`FichierControleFluxCoteUnix/README.md:198`) |
| Contrôle EAI | `TRAITE`, `N_TRAITEMENT`, `REQUEST_ID` | Marquage du contrôle; les exports ne doivent pas être assimilés sans contrôle aux factures intégrées (`TALEND/Monitoring_Jobs_Talend.sql:138`) |
| Traitements EBS | C, E, G, R, W | Comptés comme OK, erreur, warning, en cours, attente dans le dashboard (`Projet_Dashboard/sql/11_nuit_synthese.sql:5`); G avec texte « fin normale » est exclu du compteur warning (`00_kpi.sql:32`) |

Les comptages ont plusieurs grains : ligne comptable `411*`, numéro de facture distinct, ensemble origine/société/pièce et fichier. Le montant `SUM(fmt_amount)` de la vue AR reçue additionne toutes les lignes, sans restriction `411*` (`Projet_Dashboard/sql/07_fac_ar_recues.sql:7`). Il n’est donc pas directement comparable au TTC source défini sur les seuls comptes clients. Le total des erreurs est également un grain distinct du nombre de clients : un client peut avoir plusieurs adresses rejetées.

## Avoirs et intégrité des montants

La correction KDFI-2198 documente une double inversion : les avoirs déjà négatifs en AR deviennent positifs si le contrôle leur applique à nouveau `-1`. La règle finale annoncée est `SUM(NVL(MONTANT,0))` (`KDFI-2198-ControleFlux/README.md:96`). Les scripts de diagnostic comparent montants stockés, types de mouvement, comptes `411` et contreparties (`Test_diagnostic_CYC.sql:24`, `:92`, `:145`). La validation recherche notamment des avoirs encore positifs (`Verification_correction_avoirs.sql:147`, `:167`).

**Incohérence documentaire prouvée :** le même README conserve un exemple qui inverse les avoirs (`:177`), annonce un « ajout DECODE » en performance (`:135`) après avoir décrit sa suppression (`:105`), et présente des chiffres historiques non alignés entre symptôme (`:92`) et résultat (`:123`). Ces chiffres illustrent l’incident; ils ne constituent pas un jeu de recette cohérent. La mention « appliquée et validée » (`:7`) doit être vérifiée par version du package et résultats de recette, pas reprise comme état de production confirmé.

## Doublons, corrections et reprises

Deux classes de doublons coexistent. Les scripts à sept critères retiennent numéro, ligne, type de ligne, compte, société, origine et fichier; ils conservent le plus petit `IARPAFAC_ID` (`Ligne_AR_En_Double/Suppression_Doublons_DKA_IARPAFAC_INTERFACE_PRODUCTION.sql:15`, `:324`). Le montant n’appartient pas à cette clé. Les variantes à 40 colonnes incluent montant, statuts, request/group IDs et divers attributs (`Ligne_AR_En_Double/suppression_doublons_PRODUCTION.sql:11`, `:267`). Elles ne répondent pas au même besoin : doublon d’identité de ligne contre doublon de contenu.

La détection standard mentionne explicitement des lignes de même numéro avec montants différents (`Ligne_AR_En_Double/Detection_Doublons_RA_INTERFACE_LINES.sql:194`). **Risque inféré élevé :** supprimer selon la clé courte peut effacer une variation métier légitime. À l’inverse, inclure des statuts techniques dans la clé peut masquer une réémission du même événement ayant changé de statut. Une clé d’idempotence et la règle métier de conservation doivent être validées avant de sélectionner un script.

Les versions de suppression ne sont pas de simples diagnostics : version test (`Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql:312`), versions production avec `DELETE` et `COMMIT` (`..._PRODUCTION.sql:324`, `:364`; `suppression_doublons_PRODUCTION.sql:262`, `:282`), réinsertion depuis sauvegarde (`insert_data_CORRIGE.sql:279`, `:422`). Certains scripts recréent une sauvegarde nommée de manière fixe et peuvent supprimer la précédente (`insert_data_CORRIGE.sql:40`; `suppression_doublons_PRODUCTION.sql:48`). Les commandes de restauration imprimées ne prouvent pas la conservation des contraintes, index, grants ou triggers.

**Défaut SQL certain :** dans `Ligne_AR_En_Double/Sauvegarde_et_Suppression_Doublons_PRODUCTION.sql:272`, `dii2.IARPAFAC_ID` est sélectionné sans agrégation et absent du `GROUP BY` des lignes 274–275. Cette requête est invalide en Oracle (erreur de regroupement attendue). Le défaut est dans le bloc contenant la suppression; le script ne constitue pas une procédure de reprise validée.

La remise à zéro du contrôle couvre AR, AP et GL : suppression des résultats et flags, remise à NULL d’`ATTRIBUTE8` AR, `ATTRIBUTE7` AP, `ATTRIBUTE5` GL, renommage optionnel du fichier et reset `OA_STATUS` (`KDFI-2198-ControleFlux/Reset_Et_Rejouer_SCTLFLUX_EAI.sql:86`, `:114`, `:140`, `:162`, `:189`). Le `COMMIT` est inconditionnel (`:212`). Les valeurs par défaut comprennent un request ID historique et un folio vide (`:33`, `:37`). **Risque inféré :** réinitialiser un périmètre trop large ou provoquer une nouvelle prise en compte en modifiant l’identité du fichier.

Le script de relance CYC initialise un contexte EBS et fabrique un `CONC_REQUEST_ID` horodaté (`KDFI-2198-ControleFlux/rerun_sctlflux_eai_CYC_2025-12-02.sql:21`), puis appelle directement le package (`:36`). Cet identifiant synthétique ne garantit pas l’existence d’une concurrent request correspondante. Un rapprochement avec FND peut donc rester vide. Les identifiants utilisateur/responsabilité sont des valeurs à remplacer (`:16`).

## Référentiel clients : causes bloquantes

Le dossier IFS répertorie des doublons de code ANAEL, erreurs de calcul de clés GL et collecteurs manquants (`KDFI3357-Integration clients/README.md:44`). Il expose un total historique de 5 649 erreurs, dont 319 erreurs de collecteurs, et 5 330 rejets clients (`:36`, `:48`, `:174`). Ces chiffres datent du diagnostic documenté; ce ne sont pas des volumes courants.

Les actions suivent la responsabilité de la donnée : correction SIC/IFS et réémission avec purge des lignes erronées, ou correction de paramétrage AR avec reprise au lancement suivant (`README_IFS_AR.md:239`). Les adresses destinataires peuvent avoir une fonction BILL_TO désactivée; un client à la fois payeur et destinataire doit conserver un site actif (`:94`). La désactivation de l’en-tête SIC doit désactiver les adresses AR, pas l’en-tête AR (`:210`). Les libellés RG ne sont pas harmonisés entre les deux README : le résumé appelle RG1 l’unicité ANAEL (`README.md:258`), la spécification appelle RG1 le filtre payeur/destinataire (`README_IFS_AR.md:206`). Utiliser le texte de règle et sa source, sans fusionner les numéros.

## Orchestration et surveillance

Les requêtes Control-M reconstruisent les programmes EBS, exécutables, paramètres SRS, jeux de traitement, durées et fréquences (`ChaineControleM/Requete_Programme_ControlM.sql:23`, `:64`; `Inventaire_Complet_Chaines_ControlM.sql:276`). Elles observent EBS; elles ne donnent pas un export de l’ordonnanceur Control-M. L’affirmation que les programmes custom sont « typiquement » lancés via concsub est une hypothèse du commentaire (`Inventaire_Complet_Chaines_ControlM.sql:19`). Le nombre d’exécutions observées ne permet pas, à lui seul, de prouver qu’une chaîne attendue a été lancée.

La requête faible fréquence rattache les démarrages avant 7 h au soir précédent et filtre les programmes ayant au plus quatre exécutions par mois actif (`controlMnonLance/Requete_Traitements_Faible_Frequence_Mensuelle.sql:24`, `:97`). Elle ne construit pas les mois sans exécution. Son commentaire annonce six mois complets, mais le filtre n’a pas de borne supérieure excluant le mois en cours (`:40`). **Limite prouvée :** ce résultat mesure les mois présents, pas les absences attendues.

La supervision Talend lit des tables métier de contrôle : volumes et équilibre débit/crédit dans `DKA_SCTLFLUX_EAI`, compteurs iValua, flags AR et liens FND (`TALEND/Monitoring_Jobs_Talend.sql:20`, `:83`, `:153`). Ce script ne montre pas de lecture d’un journal natif de chaque exécution Talend. Les dates de début/fin d’extraction ne doivent pas être interprétées sans validation comme durée réelle d’un job. Le taux de rejet iValua divise les rejets par les « processed » (`:89`); le dénominateur doit être confirmé si cet indicateur est présenté comme taux sur le total reçu.

Le contrôle du matin et sa version nuit regroupent flux DSP, notes de frais, factures, GL, traitements nocturnes et imports bancaires. Le dashboard réutilise des requêtes du contrôle générique et publie les CSV toutes les heures vers Drive/Apps Script (`Projet_Dashboard/README.md:3`). Il rafraîchit l’écran toutes les quinze minutes, mais conserve l’ancien CSV si une requête échoue; le seuil de péremption annoncé est trois heures (`:61`). Un écran accessible n’atteste donc pas que ses données sont récentes.

## Anomalies et limites de la supervision

| Priorité | Constat statique et effet | Source |
|---|---|---|
| Haute | Virgule absente après `AS PROGRAMME`, avant `COUNT(*)` : requête invalide, export de la section impossible | `Projet_Dashboard/sql/12_nuit_erreurs_programme.sql:5` |
| Haute | `NB_AUTRE` ajoute 2 par ligne au lieu de 1; les statuts NULL ne sont pas comptés par `NOT IN` | `Projet_Dashboard/sql/19_demat_par_jour.sql:9` |
| Haute | Rapprochement/rejets AR par seul numéro; `MAX(message_text)` ne conserve qu’un message et le titre « rejetées » inclut l’attente sans erreur | `Projet_Dashboard/sql/08_fac_ar_rejets.sql:8`, `:11`, `:13` |
| Haute | Le fichier nommé `D2_interface_statuts.sql` est un manifeste CSV de requêtes et non du SQL | `ScriptsLanceurCentrale/D2_interface_statuts.sql:1` |
| Moyenne | Noms D1/D3/D4/D5 décalés : D1 analyse région, D3 source/folio, D4 synthèse journalière, D5 statuts interface | fichiers correspondants, ligne 1 |
| Moyenne | Plusieurs jointures FND ne portent que sur `CONCURRENT_PROGRAM_ID`; la requête 12 ajoute explicitement `PROGRAM_APPLICATION_ID` contrairement aux 13–16 | `Projet_Dashboard/sql/12_nuit_erreurs_programme.sql:13`, `13_nuit_erreurs_detail.sql:13` |
| Moyenne | Les warnings G sont exclus des tuiles si texte « fin normale », mais restent WARNING dans la synthèse brute | `Projet_Dashboard/sql/00_kpi.sql:32`, `11_nuit_synthese.sql:9` |
| Moyenne | Fenêtres différentes : AR glissant 24 h, nuit J-1 19 h à J 7 h, GL stock sans borne et KPI GL depuis J-1 | `07_fac_ar_recues.sql:13`, `11_nuit_synthese.sql:16`, `09_gl_interface.sql:5`, `00_kpi.sql:28` |
| Moyenne | KPI « GL interface > 0 = OK » mesure de l’activité; ce statut ne prouve pas absence de blocage | `Projet_Dashboard/sql/00_kpi.sql:68` |
| Moyenne | La lecture des rejets du second demi-flux peut échouer silencieusement, perdant l’explication métier d’un ABSENT | `FichierControleFluxCoteUnix/README.md:257` |
| Moyenne | Le log SQL fournisseurs compare les rejets de lignes avec `parent_id = invoice_id` au lieu de l’identifiant de ligne; le contrôle peut manquer des rejets ligne | `FichierControleFluxCoteUnix/Logs/requetes_fac02_frs_25082026_162844.sql:84` |
| Moyenne | Le lanceur central reconnaît qu’une écriture Excel peut échouer sans propager l’erreur et être comptée OK | `ScriptsLanceurCentrale/README_LOCAL.md:281` |

Les requêtes d’encours AP exposent des informations de validation, blocages, échéances, banque et images; elles décrivent l’état aval des factures fournisseurs et non la seule réception d’un fichier (`ScriptsLanceurCentrale/ENCOURAP_OPTIMISE.sql:3`, `:32`, `:168`). Les versions Q2/Q3 doivent être comparées sur leur grain avant d’additionner les TTC : une facture peut posséder plusieurs échéances et jointures associées. L’optimisation annonce préagrégations et calculs mutualisés; sa performance réelle n’a pas été mesurée ici.

Le correctif GL Dacar illustre une dépendance référentielle tâche/UO via `HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12`; l’UPDATE et le COMMIT sont commentés (`diversAnalyses/CORRECTION_GL_Dacar_GK1596490T.sql:146`). Il ne faut pas présenter la correction proposée comme appliquée.

## Compléments attendus pour un dossier d’intégration exploitable

1. Définir une identité de bout en bout : instance/flux/fichier/séquence, origine, société, pièce et ligne; conserver l’identité initiale pendant les reprises.
2. Établir les invariants à chaque étage : reçus = publiés + rejetés + non publiés, puis publiés = intégrés + en interface + anomalies expliquées, sur un même périmètre temporel et une même unité.
3. Fixer les règles des avoirs par étage, les monnaies/arrondis, les types de ligne et le traitement des factures à zéro; constituer un jeu de recette versionné.
4. Ajouter la preuve du calendrier attendu et des dépendances Control-M, puis rapprocher les exécutions attendues/réelles; observer uniquement l’historique FND ne détecte pas tous les non-lancements.
5. Qualifier les reprises : simulation de périmètre, sauvegarde indépendante, contrôle avant/après par compte et pièce, arrêt sur erreur, et absence de nouvelle facturation indue.
6. Corriger les anomalies de reporting et rendre visibles date du dernier export réussi, périmètre filtré, erreurs techniques et contrôles indisponibles.

## Couverture et limites

Le sous-périmètre correspond aux 66 entrées de `graphify-out/perimetre_1.json`. Tous les fichiers ont été inventoriés et soumis à lecture/recherche statique; les constats ci-dessus ont été vérifiés sur les lignes citées. Les grandes sorties de lecture regroupée ont été tronquées par l’outil : cette analyse ne revendique donc pas une revue humaine exhaustive de chaque ligne ni une validation syntaxique complète des 66 fichiers. Les noms et commentaires sont traités comme indices; le comportement SQL cité prévaut. Le fichier `.pytest_cache/README.md` est une documentation technique de cache, sans règle de facturation. Les logs SQL générés sont des instantanés historiques. Les liens externes, outils Google, librairie `gdrive`, configurations de connexion et environnement Oracle n’ont pas été interrogés.

La liste complète de couverture est ajoutée ci-dessous pour rendre le périmètre vérifiable.
- `ChaineControleM/Inventaire_Complet_Chaines_ControlM.sql`
- `ChaineControleM/Requete_Programme_ControlM.sql`
- `ControleFolioRose/README.md`
- `ControleMatinGenerique/Controle_Quotidien_Complet.sql`
- `ControleMatinGenerique/README.md`
- `controleNuit/Controle_Quotidien_Complet.sql`
- `controleNuit/ControleMatin-21012026/Diagnostic_Traitement_AR_46850719.sql`
- `controleNuit/Q - Verifications qutidiennes.sql`
- `controleNuit/ReadMe.md`
- `controlMnonLance/Requete_Traitements_Faible_Frequence_Mensuelle.sql`
- `diversAnalyses/ControleFolioRose.sql`
- `diversAnalyses/CORRECTION_GL_Dacar_GK1596490T.sql`
- `diversAnalyses/Requete_Suppression_Doublons_IARPAFAC_CORRIGEE.sql`
- `factureEndoubleTableStandrad/Detection_Doublons_IARPAFAC_V1.sql`
- `factureEndoubleTableStandrad/Detection_Doublons_IARPAFAC_V3_avec_table.sql`
- `FichierControleFluxCoteUnix/.pytest_cache/README.md`
- `FichierControleFluxCoteUnix/Logs/requetes_fac02_frs_25082026_162844.sql`
- `FichierControleFluxCoteUnix/README.md`
- `KDFI-2198-ControleFlux/deploiement_correction_avoirs.sql`
- `KDFI-2198-ControleFlux/README.md`
- `KDFI-2198-ControleFlux/requ.sql`
- `KDFI-2198-ControleFlux/rerun_sctlflux_eai_CYC_2025-12-02.sql`
- `KDFI-2198-ControleFlux/Reset_Et_Rejouer_SCTLFLUX_EAI.sql`
- `KDFI-2198-ControleFlux/Test_diagnostic_CYC.sql`
- `KDFI-2198-ControleFlux/Validation_correction_CYC.sql`
- `KDFI-2198-ControleFlux/Verification_correction_avoirs.sql`
- `KDFI3357-Integration clients/README.md`
- `KDFI3357-Integration clients/README_IFS_AR.md`
- `Ligne_AR_En_Double/Detection_Doublons_RA_INTERFACE_LINES.sql`
- `Ligne_AR_En_Double/insert_data.sql`
- `Ligne_AR_En_Double/insert_data_CORRIGE.sql`
- `Ligne_AR_En_Double/Sauvegarde_et_Suppression_Doublons_PRODUCTION.sql`
- `Ligne_AR_En_Double/Suppression_Doublons_DKA_IARPAFAC_INTERFACE.sql`
- `Ligne_AR_En_Double/Suppression_Doublons_DKA_IARPAFAC_INTERFACE_PRODUCTION.sql`
- `Ligne_AR_En_Double/suppression_doublons_PRODUCTION.sql`
- `Projet_Dashboard/README.md`
- `Projet_Dashboard/sql/00_kpi.sql`
- `Projet_Dashboard/sql/01_dsp_flux.sql`
- `Projet_Dashboard/sql/02_dsp_synthese.sql`
- `Projet_Dashboard/sql/04_factures_source.sql`
- `Projet_Dashboard/sql/07_fac_ar_recues.sql`
- `Projet_Dashboard/sql/08_fac_ar_rejets.sql`
- `Projet_Dashboard/sql/09_gl_interface.sql`
- `Projet_Dashboard/sql/10_gl_lignes.sql`
- `Projet_Dashboard/sql/11_nuit_synthese.sql`
- `Projet_Dashboard/sql/12_nuit_erreurs_programme.sql`
- `Projet_Dashboard/sql/13_nuit_erreurs_detail.sql`
- `Projet_Dashboard/sql/14_nuit_warnings.sql`
- `Projet_Dashboard/sql/15_nuit_longs.sql`
- `Projet_Dashboard/sql/16_nuit_en_cours.sql`
- `Projet_Dashboard/sql/17_rb_imports.sql`
- `Projet_Dashboard/sql/18_demat_statut.sql`
- `Projet_Dashboard/sql/19_demat_par_jour.sql`
- `Projet_Dashboard/sql/20_demat_en_attente.sql`
- `ScriptsLanceurCentrale/D1_folios_fichiers_ap.sql`
- `ScriptsLanceurCentrale/D2_interface_statuts.sql`
- `ScriptsLanceurCentrale/D3_motifs_rejet.sql`
- `ScriptsLanceurCentrale/D4_region_source.sql`
- `ScriptsLanceurCentrale/D5_folio_vs_batchprefix.sql`
- `ScriptsLanceurCentrale/ENCOURAP_OPTIMISE.sql`
- `ScriptsLanceurCentrale/FACTURES_EN_COURS_V2_Q2.sql`
- `ScriptsLanceurCentrale/FACTURES_EN_COURS_V2_Q3.sql`
- `ScriptsLanceurCentrale/README_GDRIVE_TOKEN.md`
- `ScriptsLanceurCentrale/README_LOCAL.md`
- `ScriptsLanceurCentrale/README_UN_SQL.md`
- `TALEND/Monitoring_Jobs_Talend.sql`
