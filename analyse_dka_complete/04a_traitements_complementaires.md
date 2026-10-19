# Composants complémentaires : intégrations et traitements particuliers

Cette note complète les familles du document 04 par 22 composants situés dans `dka/12.0.0/admin/sql`. Chaque fiche repose sur une lecture ciblée du corps, de ses points d'entrée, de ses sélections et effets. Les références `L` désignent les lignes du fichier lié dans la fiche. Une absence de commit dans une routine ne garantit pas l'absence de validation dans ses appels ou son appelant. L'installation, les fréquences, les destinataires réels et les données de paramétrage restent à confirmer. Aucun SQL ni shell du corpus exécuté.

## DKA_AMOR_FISC_PKG

[Source](../dka/12.0.0/admin/sql/DKA_AMOR_FISC_PKG.pkb). `Insert_Data` reçoit société, centre de gestion, périodes de début/fin, livre, utilisateur et demande concurrente (L80). Il lit les immobilisations, livres, périodes et amortissements FA (L206, L226, L303, L350), puis alimente `Dka_Amor_Fisc` avec amortissement initial, réévaluation, dotations et diminution (L441). Il s'agit d'une préparation de données d'état d'amortissement, malgré un commentaire d'en-tête générique.

Sorties : table de travail et code/message d'erreur. `Insert_Data` valide à L480 ; `Delete_Data` supprime des données puis valide à L509/L515. Reprise : conserver livre, périodes et request ID ; rapprocher les montants FA avant de supprimer/régénérer la sortie. Les transcodifications sont aussi consultées (L256).

## DKA_APFRSEXP_PKG

[Source](../dka/12.0.0/admin/sql/DKA_APFRSEXP_PKG.pkb). Deux entrées, `Export_journalier` (L43) et `Export_mensuel` (L1252), exportent les fournisseurs et contacts dans des fichiers ouverts en écriture (L183/L187 et L1340/L1344). Les sélections incluent les relations de paiement fournisseur `PAYABLES_DISB` (L339).

Le journalier modifie aussi `ap_supplier_contacts`, `ap_supplier_sites_all`, `iby_ext_payee_relationships` et `ap_suppliers` (L489–506). Ce n'est donc pas une extraction sans effets en base. Commits L1158/L1668, rollbacks L1238/L1747 : les fichiers déjà écrits ne sont pas annulés par rollback. Tester la livraison incomplète, la relance et les marques d'export ; confirmer les noms/répertoires paramétrés et la fréquence réelle des deux modes.

## DKA_CGA_AUTO_PKG

[Source](../dka/12.0.0/admin/sql/DKA_CGA_AUTO_PKG.pkb). `AUTO_CGA` reçoit un `P_ORG_ID` (L19), sélectionne les langues F/US pour l'organisation sans annexe existante (L33), recherche les deux documents « CONDITIONS GENERALES ACHATS » (L80/L88), puis inscrit leurs références dans `DKA_SPOBON_ANNEXE` (L101/L118).

Dépendances : unité opérationnelle, utilisateur `EXPLOITATION`, catégorie d'annexe, type `LONG_TEXT` et documents FND (L44–91). Commit L140 ; en exception, code 1 et message SQL (L142). Le test d'existence porte sur l'organisation : vérifier une organisation partiellement équipée avant relance, car elle peut être considérée déjà traitée sans réparer la partie manquante.

## DKA_CONTROLE_REFAC_PKG

[Source](../dka/12.0.0/admin/sql/DKA_CONTROLE_REFAC_PKG.pkb). Le pilote `Main` (L2667) orchestre plusieurs étapes : détermination des clients de sociétés du groupe (L30/L43), contrôle des mouvements non refacturés (L140/L154) et identification des sites fournisseurs/clients manquants (L745/L759). Les requêtes rapprochent dépenses PA, projets et types de mouvements, notamment les classes `VI`/`ER` (L221/L316).

Sorties : états de contrôle et alimentation de `Dka_Controle_Refac` (insertion active L1200, commit L1449). L'insertion L902 est commentée et ne doit pas être prise pour une seconde opération active. Recetter clients/projets/sites absents et volumes détaillés ; le contrôle ne prouve pas, à lui seul, qu'une facture de refacturation a été créée. La sémantique des étapes 4 à 8 demande un rapprochement métier complémentaire.

## DKA_CREATE_ACCOUNT_PKG

[Source](../dka/12.0.0/admin/sql/DKA_CREATE_ACCOUNT_PKG.pkb). `main` reçoit le propriétaire et retourne code/message (L61). Le curseur lit `DKA.DKA_COMPTE_BANC_INT` et exclut les intitulés déjà présents dans `CE_BANK_ACCOUNTS` (L84/L86). Il recherche événements AR, combinaisons GL et banque/agence HZ (L93/L129/L167), crée le compte puis son usage via `ce_bank_pub.create_bank_acct_use` (L866/L1607).

Effet majeur : la routine locale `create_bank_acct` contient une insertion directe dans `CE_BANK_ACCOUNTS` (L464), complétée par des contrôles de statut API et messages FND (L874/L1613). Le contrôle de doublon par nom doit être validé pour les comptes homonymes. La revue ciblée n'établit pas une frontière transactionnelle globale : contrôler appelant et contrat CE avant reprise, puis rapprocher compte créé et usage organisationnel.

## DKA_EMPJOBSIMP_PKG

[Source](../dka/12.0.0/admin/sql/DKA_EMPJOBSIMP_PKG.pkb). Chaîne de chargement d'emplois salariés : soumission d'un chargeur concurrent (L246/L271), validation de `DKA_EMPLOYEE_JOBS_TMP` et transcodification via `DKA_REP_TRANSCO_LINES` (L353/L364/L368), puis mise à jour d'affectation via `HR_ASSIGNMENT_API.update_emp_asg_criteria` à la date système (L533/L553).

Sorties : affectations RH, statuts de lignes temporaires (L575/L582/L591) et bilan (L631). Le package purge la table temporaire (L690/L697), valide la demande du chargeur (L287) et le traitement principal (L825). Sauvegarder le fichier et les rejets avant purge ; tester les dates d'effet et salariés sans affectation, car la reprise ultérieure peut viser une autre date système.

## DKA_ETA081_PKG

[Source](../dka/12.0.0/admin/sql/DKA_ETA081_PKG.pkb). `INSERT_TABLE_P` reçoit nom de table et données facture/TVA : société, compte, taux, bases, dû et demande concurrente (L19–36). Il insère ces valeurs liées par variables dans une table du schéma DKA dont le nom est concaténé au SQL dynamique (L41–54).

Sortie : ligne de travail pour l'état ETA081. Aucun commit explicite dans cette routine courte ; journalisation des paramètres et réémission de l'exception à L55–63. Le nom de table n'est pas une variable liée : vérifier la liste autorisée chez les appelants. Rapprocher le nombre de lignes et le request ID pour éviter un état mélangeant plusieurs exécutions.

## DKA_EXPCDE_IVALUA_PKG

[Source](../dka/12.0.0/admin/sql/DKA_EXPCDE_IVALUA_PKG.pkb). Le pilote `main` (L1222) valide et extrait l'historique des transferts de fournisseurs de commandes `DKA_SPOCDE_TRANSFRS_HIST` (L968/L993/L1044). Il écrit un fichier séparé par `|` contenant numéro PO, nouveau fournisseur/site et ancien fournisseur/site (L1112/L1128/L1141), et conserve sa référence dans `DKA_EXPCDE_IVALUA_FILE` (L1164).

Dépendances : répertoires Oracle contrôlés (L912), transcodifications d'adresses (L513) et SMTP (L342). Les statuts et le registre fichier sont validés en plusieurs points (L1006/L1174/L1188) ; `send_mail` supprime une référence fichier et valide (L761/L763). Tester l'échec après fichier mais avant courriel : la réussite d'extraction ne prouve pas la réception par Ivalua.

## DKA_EXTR_DA_PKG

[Source](../dka/12.0.0/admin/sql/DKA_EXTR_DA_PKG.pkb). `MAIN` reçoit de nombreux filtres de demandes d'achat : région/UO, type, rédacteur/demandeur, tâche, statut, dates, numéros et fournisseur/site (L61–77). Les sélections associent entêtes/lignes/distributions PO, catégories INV, tâches PA et personnes RH (L121–186).

Sortie : document XML construit par `DBMS_XMLDOM`, avec unité, établissement, société, numéro/ligne/date DA, fournisseur et classification achat (L330–355). Traitement d'extraction ; la lecture ciblée n'a pas établi de modification métier ni de commit. Vérifier les filtres nulls, les droits multi-organisations et les caractères XML ; l'état n'est pas une interface de création de DA.

## DKA_FUPOCTRLSF_PKG

[Source](../dka/12.0.0/admin/sql/DKA_FUPOCTRLSF_PKG.pkb). `Main` reçoit UO absorbée et UO absorbante (L30–34). Il rapproche commandes et sites fournisseurs, avec des transcodifications d'organisations (L54/L71/L82/L128), puis produit les listes des sites manquants et existants sur l'absorbante.

Sorties explicites : `DKA_SITES_FOURNISSEURS_MQTS.csv` et `DKA_SITES_FOURNISSEURS_EXTS.csv` dans `DKA_OUT_DIR`, ouverts en mode `W` (L719–729), avec indications de duplication/action (L731–741). Cette fiche établit un contrôle de préparation de fusion, pas une duplication effective. Les noms fixes impliquent un écrasement possible entre exécutions ; conserver les fichiers par couple d'UO et vérifier les paramètres bancaires/termes comparés (L807/L894).

## DKA_GENPOIMGCMD_PKG

[Source](../dka/12.0.0/admin/sql/DKA_GENPOIMGCMD_PKG.pkb). `main` reçoit une région (L153–156), sélectionne les commandes et pièces jointes de catégorie `BON DE COMMANDE` (L186–203), puis soumet le jeu `DKA_GENBDCRPCMD` (L275). Une phase configure l'organisation et lance `DKA_SPOBON_STOCIMG` pour stocker l'image (L318–329).

Sorties : demandes concurrentes et images de commande produites par les programmes enfants. Commit après soumission du jeu (L330), rollbacks L412/L429. Une relance ne doit pas se baser uniquement sur le statut du parent : contrôler les enfants et les pièces jointes déjà créées. Le code interprète région `T` ou nulle comme absence de restriction (L263–266).

## DKA_GLPARV_PKG

[Source](../dka/12.0.0/admin/sql/DKA_GLPARV_PKG.pkb). Le point d'entrée `main` pilote la contrepassation GL (L9/L52). Il modifie `GL_JE_SOURCES`, des statuts de périodes, soumet une requête concurrente, puis restaure/modifie à nouveau les paramètres (L91/L128/L168/L228/L263).

Commits L94/L192/L266 : les changements de configuration et la soumission ne constituent pas une transaction atomique. Tester échec du programme enfant, concurrence et restauration des paramètres ; rapprocher les journaux contrepassés avec le lot initial. La mise à blanc des attributs projet évoquée dans l'historique apparaît commentée à L143 et ne doit pas être présentée comme active.

## DKA_MAIL_PKG

[Source](../dka/12.0.0/admin/sql/DKA_MAIL_PKG.pkb). Utilitaire d'envoi avec pièces jointes : `envoi_avec_fichier` (L201) lit les sorties concurrentes et leurs types MIME (L222), ainsi que `dka.dka_mail_param` (L272), et ouvre une connexion SMTP sur port 25 (L328). `envoi_mail` est le point d'entrée du traitement d'envoi des fichiers de contrôle de préclôture (L584/L595).

Sortie externe : courriel MIME ; dépendances réseau SMTP, annuaire de répertoires Oracle (L98), fichiers et paramètres par demande. Aucun commit explicite relevé ; une transaction SQL ne peut pas annuler un courriel déjà accepté. Conserver une preuve par demande/pièce jointe et tester les fichiers absents, les erreurs SMTP et le risque de renvoi en double.

## DKA_RAPCTRLPRLVT_PKG

[Source](../dka/12.0.0/admin/sql/DKA_RAPCTRLPRLVT_PKG.pkb). `main` lit `dka_prel_ap_rb` pour construire le rapport de contrôle des prélèvements (L38/L83/L102/L142). Il récupère une sortie temporaire `x<request_id>.tmp` dans `DKA_OUT_DIR` (L854). `send_mail` recherche demandes et paramètres de destinataires (L898/L902/L908).

La diffusion remplace des lignes de `dka_mail_param`, soumet une demande d'envoi et valide (L973/L975/L994/L1000) ; rollback d'erreur à L1046. Les fichiers, les résultats de prélèvement et la demande de diffusion doivent être rapprochés ensemble. Un rapport produit ou un enfant soumis ne prouve pas la livraison du courriel.

## DKA_RGLEXPORT89_PKG

[Source](../dka/12.0.0/admin/sql/DKA_RGLEXPORT89_PKG.pkb). `main` reçoit société et année (L664–667). Il initialise les paramètres puis extrait les écritures GL et les soldes (L384/L408/L500). Le titre produit précise « Liste des pièces GL avec comptes comptable 8 ou 9 » (L622), ce qui établit la fonction de l'export.

Sorties : état/fichier de sortie du traitement via outils de journalisation/édition (L610–636), avec nettoyage/transcodification du texte (L93). Dépendances GL, sociétés, valeurs flexfield et livres (L208/L272/L327). Un rollback apparaît dans la gestion d'erreur (L591) ; aucune chaîne d'import métier n'est établie ici. Tester soldes/ouverture, année et filtres de comptes, et confirmer le format exact attendu par le destinataire.

## DKA_RJETVADEDUC_PKG

[Source](../dka/12.0.0/admin/sql/DKA_RJETVADEDUC_PKG.pkb). Deux procédures calculent les données de TVA déductible : `calcul_tva_cre` et `calcul_tva_deb`, alimentant respectivement `DKA_RJETVADEDUC_CRE` et `DKA_RJETVADEDUC_DEB` (L51/L790 et L848/L1300). Une fonction vérifie un code TVA (L1360).

Les procédures suppriment préalablement des données et valident cette suppression (L77/L87, L874/L884). La reprise après échec de calcul peut donc laisser un périmètre vidé : contrôler les prédicats de suppression, request IDs et filtres de calcul avant relance. Le code établit une préparation d'état fiscal, pas le dépôt d'une déclaration auprès de l'administration.

## DKA_TVA_COLLECTEE_PKG

[Source](../dka/12.0.0/admin/sql/DKA_TVA_COLLECTEE_PKG.pkb). `insert_data` alimente `dka_tva_collectee` pour l'édition (L50/L70/L106/L192/L319). Des routines mettent ensuite à jour totaux facture/règlement, montants HT/TVA à déclarer et montant réglé (L495/L520/L598/L610/L666/L700).

Commits multiples dans l'alimentation (L431/L441/L452/L462), rollbacks d'erreur (L466/L473), puis purge spécifique `delete_data` avec commit (L748/L765/L775). Vérifier l'ordre des routines chez l'appelant et rapprocher base, TVA et règlements ; une régénération isolée de l'une des mises à jour peut produire un état incohérent.

## DKA_XLA_AP_CUSTOM_SOURCES_PKG

[Source](../dka/12.0.0/admin/sql/DKA_XLA_AP_CUSTOM_SOURCES_PKG.pkb). Fournit des valeurs à la comptabilité auxiliaire SLA : identification d'une ligne immobilisable, code taxe et compte de dette (L206/L351/L439). Les fonctions rapprochent distributions/lignes AP et comptes GL, y compris taxes autoliquidées (`ap_self_assessed_tax_dist_all`, L253–270 et L384–395), et utilisent catégories FA/taux ZX (L291/L307).

Entrées : identifiants et paramètres des fonctions SLA ; sorties : valeurs de sources comptables, pas import de factures. Pas de commit explicite relevé. Les erreurs sont transmises par `xla_exceptions_pkg.raise_message` (L334). Recetter dans un événement comptable réel, avec distributions absentes, taxe autoliquidée et compte de dette ; la présence des fonctions ne prouve pas leur association à une règle SLA installée.

## DKA_XLA_AR_CUSTOM_SOURCES_PKG

[Source](../dka/12.0.0/admin/sql/DKA_XLA_AR_CUSTOM_SOURCES_PKG.pkb). Enrichit les sources SLA avec informations client d'encaissement (L132, lecture AR/HZ L166–173), attribut 8 de site (L209/L242/L253), classe de profil client (L288/L320) et code taxe d'une ligne de transaction (L357/L386/L398).

Sorties : valeurs dérivées retournées au moteur comptable ; pas de commit explicite relevé. Gestion d'erreur par `app_exception.raise_exception` (L192/L272/L339). Attention : la recherche effective d'attribut 8 utilise `party_site_id` avec `rownum = 1` (L253) ; tester les sites multiples et confirmer le contrat du paramètre. Vérifier la configuration SLA consommatrice, absente de cette seule fiche.

## DKA_XLA_FA_CUSTOM_SOURCES_PKG

[Source](../dka/12.0.0/admin/sql/DKA_XLA_FA_CUSTOM_SOURCES_PKG.pkb). Dérive des sources SLA FA : livre fiscal, catégorie IFRS, comptes IFRS/social, projet/tâche, provisions et reclassements (entrées fonctionnelles L198/L258/L362/L612/L689/L756/L1010/L1075/L1535/L1688). Les fonctions lisent livres/catégories FA, combinaisons GL et transcodifications DKA (L226/L286/L408/L472/L567).

Sorties : valeurs/segments comptables et indicateurs consommés par SLA ; pas de commit explicite relevé. Les erreurs sont relayées via `app_exception.raise_exception` (L242/L309). Les fonctions de provision, annulation et sortie d'actif doivent être testées séparément ; leurs noms ne suffisent pas à établir les montants ou règles métier. Vérifier couverture IFRS/social et règles SLA effectivement associées.

## DKA_XX_LOADER_UTILS_PKG

[Source](../dka/12.0.0/admin/sql/DKA_XX_LOADER_UTILS_PKG.pkb). Utilitaires FNDXLOAD (L10) : création de jeux de valeurs (L325), accès aux groupes de demandes (L173), traitements de lookups (L2062), traductions de profils (L2171), messages FND (L2194) et paramètres DKA (L2260).

Entrées : métadonnées de configuration, noms, traductions et paramètres ; sorties : configuration applicative, avec mises à jour de `fnd_profile_options_tl`, `fnd_new_messages` et `dka_parameters` (L2179/L2209/L2320), et insertions de messages/paramètres (L2217/L2334). C'est un composant de déploiement/administration, à distinguer des imports fonctionnels. La frontière transactionnelle dépend des APIs et de l'appelant ; sauvegarder les valeurs existantes, vérifier langue et propriétaires avant réapplication.

## IBY_ASSIGNEXT_PUB

[Source](../dka/12.0.0/admin/sql/IBY_ASSIGNEXT_PUB.pkb). Hook Oracle personnalisé, appelé sur la liste de documents encore sans affectation de compte/profil (contrat L52–64, entrée `IN OUT` L77). Il recherche une campagne concurrente de prélèvement et son compte bancaire via `argument6` (L110–138), puis le profil `DKA_PRELEVEMENT` (L153–156).

Pour chaque document, il recherche dans `dka_prel_ap_rb` la facture à l'étape `E2`, choisit `DKA_PREL_AUTO_FRN`, et modifie en mémoire `int_bank_acct_id`/`pay_profile_id` de la liste (L170–193). En absence de ligne, il utilise les valeurs de campagne (L195–197). Pas de commit explicite dans le hook : le moteur IBY applique ces affectations. Cas critique : plusieurs lignes de prélèvement mettent le compte à NULL dans le gestionnaire `TOO_MANY_ROWS`, puis poursuivent (L175–180/L192). Tester absence, doublon, plusieurs campagnes et profils manquants ; valider le compte réellement utilisé avant émission bancaire.
