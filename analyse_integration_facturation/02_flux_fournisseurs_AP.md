# Intégration fournisseurs AP, images iValua et corrections Notilus

Analyse statique du 17 octobre 2026. Aucun SQL n'a été exécuté, aucune connexion Oracle n'a été ouverte. Les références `fichier:ligne` sont relatives à la racine du dépôt. **Preuve** désigne une instruction visible dans le code ; **documentation** une affirmation des README/commentaires ; **hypothèse/risque** une conséquence à vérifier en environnement.

## 1. Conclusion opérationnelle

La chaîne principale transforme les factures Xerox/XGS, ZCI et DSP/iValua en en-têtes et lignes de l'Open Interface AP, puis soumet le programme Oracle `APXIIMPT`. Le package porte les règles de rapprochement commande/réception, les avoirs, les taxes et les blocages. Le reporting custom mesure surtout la préparation de l'interface : son statut `OK` est enregistré et commité **avant** le lancement de l'import standard. Il faut donc rapprocher trois preuves distinctes : préparation custom, résultat APXIIMPT et facture effectivement créée dans AP.

Preuves : `DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG.sql:4652` (reporting OK), `:4674` (commit), `:4781` (soumission APXIIMPT). Le nom de fichier `_PROD` ne démontre pas le code actuellement installé en production.

## 2. Chaîne et responsabilités

| Étape | Objet et comportement établi | Référence |
|---|---|---|
| Chargement XGS | Jointure de deux types d'enregistrements de `DKA_IAPFACXGS_TMP` : en-tête `column1 <> 'FACTURE_SUIVI'`, suivi `column1 = 'FACTURE_SUIVI'`, liaison `e.column23 = s.column10` | `DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG.sql:5324` |
| Chargements ZCI/DSP | Procédures `populate_zci_tables` et `populate_dsp_tables`, tables temporaires propres, alimentation commune | même fichier `:5796`, `:5891`, `:6288` ; README `DKA  Intégration des factures XEROX/README.md:32` |
| Staging/historisation | Insertion `DKA_IAPFACXGS_INTERFACE`, `DKA_IAPFACXGS_REPORTING_ALL`, `DKA_IAPFACXGS_INT_HIST_LINES`, `DKA_IAPFACXGS_INT_HIST_HEADS` | package `:5466`, `:5548`, `:5653`, `:5685` |
| Orchestration | `import` détermine UO/livre, positionne l'organisation des requêtes, purge les lignes custom déjà traitées, contrôle les doublons, lance `child_import` | package `:4968`, `:5021`, `:5025`, `:5039` |
| Préparation AP | `insert_header` écrit `AP_INVOICES_INTERFACE` ; `insert_line` écrit `AP_INVOICE_LINES_INTERFACE` | package `:643`, `:674`, `:1162`, `:1207` |
| Taxes complémentaires | `DKA_AP_TOOLS_PKG.apply_fonction` appelé pour les origines XGS et DSP | package `:4719`, `:4739` |
| Import standard | `FND_REQUEST.SUBMIT_REQUEST('SQLAP','APXIIMPT', ...)`, paramètres UO, source, groupe, blocage ; attente de chaque requête | package `:4781`, `:4822` |
| Images iValua | Staging `DKA_JMETER_ST.EXTRACTION_FACTURE`, URL issue de `DKA_construct_download_url`, accès via `FND_LOB_ACCESS` | `exportImageVers Ivalua/Renvoi_Image_Facture_Ivalua.sql:123`, `:128`, `:159` |

Le filtre de sécurité UO `XLA_MO_SECURITY_PROFILE_LEVEL` figure dans la branche staging de l'union d'organisations ; la branche issue de `AP_INVOICES_INTERFACE` ne répète pas ce filtre. **Risque à qualifier** selon responsabilités et politiques EBS : périmètre de reprise plus large que la branche staging. Preuve : package `:4981` à `:4996`.

## 3. Mapping utile au dossier fonctionnel

Les références de cette section sont celles de `DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG.sql`.

| Donnée entrante | Transformation / cible | Preuve |
|---|---|---|
| `CODE_REGION || CODE_SOCIETE` | Nom d'organisation, puis `ORG_ID`, livre de l'UO | `:1973`, `:4971` |
| `CODE_FRS`, `SITE_FRS`, UO | `AP_SUPPLIERS.SEGMENT1`, `AP_SUPPLIER_SITES_ALL.VENDOR_SITE_CODE`, `ORG_ID` ; récupération compte collectif et groupe de paiement | `:2326` à `:2350` |
| Colonnes du fichier | `ec1..ec27` → données facture, `sc1..sc11` → suivi et images ; correspondance positionnelle, non par nom | `:5466` à `:5545` |
| `NUM_FACT` | Suppression des espaces à l'insertion AP | `:2810` |
| `TYPE_PIECE='0001'` | `STANDARD`, montant `round(abs(MTTC_DEVISE)/100,2)` | `:2501` |
| Autres `TYPE_PIECE` | `CREDIT`, montant négatif, condition Comptant | `:2505` à `:2511` |
| `DATE_PIECE` | Date facture `TO_DATE(...,'YYYYMMDD')` | `:2812` |
| Période courante AP du livre | Date GL initialisée à la fin de période courante, contrôle `CLOSING_STATUS='O'` | `:2411` à `:2441` |
| `BATCHNO LIKE '%DSP%'` | `ATTRIBUTE9='DSP'`, sinon `XGS` | `:2444` |
| Source AP | Constante `SCAN_XGS`, y compris DSP et ZCI dans la version de base | `:957` |
| `REFERENCE_LAD` | `ATTRIBUTE3` et `ATTRIBUTE10` à travers les paramètres d'`insert_header` | `:655` à `:660`, `:2838` à `:2841` |
| Commande | `ATTRIBUTE13` ; tentative de rapprochement selon vue de commandes valides | `:2470`, `:2605` |
| Sans commande/rejet de classe 1 | Blocage `Imputation en attente`, groupe UO suffixé ; `ATTRIBUTE14='En attente'` sous conditions | `:2478` à `:2523` |
| Rejet de classe 2 | Blocage `Multi-commandes` | `:2489` |
| Type TVA `EN` | Régime global `CRE/M`, sinon `DEB/M` | `:2860` |
| Commande rapprochée | IDs commande, ligne, localisation, distribution dans les lignes AP | `:3749` à `:3760`, `:4035` à `:4069` |

Le contrôle de paiement contient `SYSDATE >= NVL(IEPPM.inactive_date,SYSDATE)` (`:2395`). **Point à confirmer** : la borne semble sélectionner une date d'inactivation passée, contrairement à un contrôle classique de validité ; aucun correctif n'est proposé sans règles du référentiel IBY.

## 4. Rapprochement, TVA et blocages

**Preuves, package de base :**

- Une commande éligible exige notamment cohérence UO, dates de fermeture projet/tâche compatibles et société du projet identique à la facture, ou type de transaction reconnu `REFAC` (`:2605` à `:2635`). `transaction_type` délègue à `DKA_SARREFAC_PKG.is_transaction_type_refac` (`:262`).
- Les commandes identifiées sous-traitance par le motif de numéro passent en `0003_SSTRT` (`:2647`). Si le HT entrant correspond au total commande, type `0003_ALLCDE` (`:2686`). Si le BL correspond après `lower(trim())`, `0003_BL` (`:2706`, `:2715`). Le cas général dépend du paramètre `NB_LIGNES_112_BLOCAGE` ; sinon retour à l'imputation en attente (`:2739` à `:2771`).
- La TVA dépend du type EN/DE/EX/IC, du caractère fournisseur de services, du type de tâche GY et des taux ZX actifs. Les paramètres `ECART_ENERGIE_MAX` et `ECART_ENERGIE_MIN` encadrent le cas 2A (`:3439`, `:3453`, `:3467`). Le seuil est signé ; il ne s'agit pas simplement d'une comparaison à une valeur absolue.
- Les cas IC 1, 2, 2A, 3 à 9 sont distingués ; le cas 1 exige commande approuvée, taux nul, montant égal et numéro IC fournisseur présent (`:3408`). Le cas 9 reprend l'égalité sans numéro IC (`:3534`). Les cas 2/3/6/8 imposent le groupe d'imputation en attente (`:4101`). La condition globale d'autorisation du rapprochement est visible `:3674`.
- La répartition SSTRT utilise un prorata du total commande et des montants déjà rapprochés (`:3715` à `:3723`). Une protection explicite existe pour un prix unitaire nul (`:3732`) ; **risque à tester** pour un total commande nul au dénominateur `po_total`, qui est un autre dénominateur.

Les paramètres et données ZX/PO/PA ne sont pas présents sous forme d'extraction de base : les valeurs effectives des seuils, le comportement des packages externes et l'exhaustivité des cas métiers restent à confirmer. Le README fournit un résumé, pas une spécification exhaustive (`DKA  Intégration des factures XEROX/README.md:43`).

## 5. Statuts et erreurs : contrat à formaliser

| Niveau | Signification démontrée | Référence |
|---|---|---|
| Custom `FLAG_TRT=1` | Marquage après préparation des interfaces ; purge au passage suivant | package de base `:4622`, `:578` |
| Custom `STATUT_INTERFACE='OK'` | Préparation custom validée avant APXIIMPT, pas preuve de facture définitive | `:4652`, `:4781` |
| `DESCRIPTION_ANO_INTERFACE` | Message tronqué à 260 caractères ; procédure autonome | `:595` à `:625` |
| Custom `KO` | Affectation commentée dans `reporte_erreur` ; ne pas supposer qu'une erreur passe automatiquement à KO | `:603` |
| Standard AP `NULL`, `REJECTED`, `PROCESSED` | Curseurs de reprise des non traitées et rejetées | `:2089`, `:4682` |
| Rejet doublon | Site forcé à `-999`, numéro fournisseur suffixé `DOUBLON` ; création d'un rejet `DUPLICATE INVOICE NUMBER` | `:4597`, `:4862` |
| Concurrent COMPLETE/NORMAL | Fin technique du programme standard ; à compléter par un contrôle des rejets et des factures | `:4836` |

**Doublons.** `control_double` compare numéro/fournisseur/site et date ou montant différents ; renomme les faux doublons avec suffixe `_' || substr(date_piece,1,6)` dans staging, reporting et historique, avec trois commits séparés (`:5172`, `:5210`, `:5226`, `:5241`). La condition d'UO a été retirée (`:5178`, `:5261`). Les doublons avec même date/montant et site différent reçoivent `.98` (`:5258` à `:5276`). La jointure des sites se fait via fournisseur, sans `api.vendor_site_id=pvs.vendor_site_id` dans ces requêtes : **risque** de classification trop large à éprouver sur fournisseurs multi-sites ; ce n'est pas une preuve de doublon réellement constaté.

## 6. Versions Xerox : comparaison matérielle

Comparaison des contenus complets : `DKA_IAPFACXGS_PKG.sql` et `DKA_IAPFACXGS_PKG_PROD.sql` sont identiques ligne à ligne (6 763 lignes). `DKA_IAPFACXGS_PKG_ETI1.sql` en contient 6 899. Cela établit des variantes du dépôt, pas leur déploiement.

| Sujet | Base / PROD | ETI1 et preuve |
|---|---|---|
| Reconnaissance origine | `BATCHNO LIKE '%DSP%'`, sinon XGS | Préfixe extrait de `NOM_FICHIER` par REGEXP ; `get_prefix_from_filename` `:191`, appel `:2522` |
| Source | `SCAN_XGS` fixe | VE1/DSP/ZCI → SCAN_XGS ; OCR/DMT → DEMAT ; défaut SCAN_XGS (`:209` à `:229`) |
| Folio | DSP ou XGS | VE1/ZCI → XGS ; DSP → DSP ; OCR/DMT conservés (`:236` à `:256`) |
| En-tête | Source constante | Nouveau paramètre `pv_source` et passage `vv_source` (`:732`, `:1031`, `:2932`) |
| Séquence documentaire | société_SCAN_XGS ou société_IVALUA | Ajout société_DEMAT pour OCR/DMT (`:2649`) |
| Groupes de traitement | clé group_id | clé `source || '|' || group_id` (`:2876`, `:4784`), puis découpage à l'appel APXIIMPT (`:4914`) |
| Recyclage | source SCAN_XGS | Curseurs élargis SCAN_XGS/DEMAT (`:2136`, `:2163`, `:2311`, `:4779`, `:5130`) |
| Autoliquidation | Appels XGS et DSP | Branche DEMAT avec origines OCR et DMT (`:4815` à `:4854`) |

**Risques à vérifier avant adoption d'ETI1 :** préfixe inconnu ou vide classé silencieusement XGS ; dépendance au nom de fichier réel ; présence des séquences société_DEMAT, sources et règles d'autoliquidation ; compatibilité des tableaux de groupes avec la longueur de clé. Les trois procédures de peuplement continuent à construire des noms VE1/ZCI/DSP : l'entrée réelle des fichiers OCR/DMT n'est pas démontrée par ces seules procédures. Plusieurs chaînes présentent des dégradations d'encodage ; conserver les identifiants et données brutes lors d'un futur déploiement.

## 7. Transactions, concurrence et reprise

**Preuves et conséquences à traiter :**

1. La préparation de lignes peut commiter dès la gestion `DKA_IAPFACXGS_MTDISP` (`package de base:3854` à `:3888`), puis à la fin des insertions (`:4251`). Un rollback final ne peut plus annuler ces lots. Le commentaire « on commite quand on a vraiment tout insere » ne décrit donc pas une atomicité complète.
2. Le marquage staging, le reporting et la soumission de chaque requête sont commités séparément (`:4631`, `:4674`, `:4810`). Une panne intermédiaire peut laisser des niveaux incohérents ; la reprise doit inventorier les interfaces AP avant tout rechargement du CSV.
3. `reporte_erreur` est autonome (`:596`) : la trace peut survivre au rollback métier. **Risque** de conflit de verrou si le parent a modifié les mêmes lignes reporting ; le scénario doit être testé, pas considéré comme incident constaté.
4. `DKA_IAPFACXGS_MTDISP` est vidée sans filtre UO/request (`:5044`). **Hypothèse de concurrence** : interférence si plusieurs sessions utilisent cette table partagée. Le DDL et les incompatibilités de programmes concurrents sont requis pour savoir si elle est temporaire ou si les exécutions sont sérialisées.
5. Le curseur facture de `child_import` ne filtre pas `FLAG_TRT` (`:1973` à `:1975`) et ne porte pas de verrou de réservation. La purge précède l'appel (`:5025`) ; l'idempotence dépend de l'enchaînement complet et des contrôles de doublon.

**Reprise proposée, à faire valider comme procédure d'exploitation, sans exécution ici :** identifier UO/source/fichier/batch et conserver comptes/IDs ; comparer staging, historique, interface AP, rejets et factures définitives ; retrouver les request_id et leur résultat ; corriger la cause (référentiel, période, taxe, document), puis retraiter le niveau déjà atteint. Ne pas recharger une facture déjà présente dans l'interface ou AP. Après reprise, réconcilier quantités et sommes HT/TVA/TTC par UO/source/devise, puis vérifier blocages et image. Les règles de rapprochement de facture doivent inclure fournisseur et UO, au-delà du seul numéro.

## 8. Images et synchronisation iValua

Le SQL de renvoi prouve une extraction par pièce jointe `AP_INVOICES`, catégorie `MISC`, langue `F`, description `IMAGE FACTURE`, type `FILE`, avec sélection du media_id le plus récent et de l'accès le plus récent (`exportImageVers Ivalua/Renvoi_Image_Facture_Ivalua.sql:123` à `:156`). Il remplace la ligne de staging ciblée, renouvelle `FND_LOB_ACCESS.TIMESTAMP` au 01/01/2050 et commite (`:159` à `:168`). **Risque** : conserver longtemps la validité des liens, choix du document le plus récent à valider métier, et perte d'une ancienne entrée si la requête d'insertion ne trouve aucune image.

Le README est contradictoire : architecture générique avec `DKA_IAPFAC_IMAGES_URL` (`exportImageVers Ivalua/README.md:43`, `:130`), puis contrat précis `DKA_JMETER_ST.EXTRACTION_FACTURE`, filtre `LAST_UPDATE_DATE` et vidage global (`:255` à `:259`). Le SQL fourni appuie la seconde table ; le corps du générateur et du concurrent d'export ne figure pas parmi ces 24 fichiers. Les horaires, statistiques, volumes et l'enchaînement automatique données → images sont **documentaires**, pas vérifiés sur Control-M/EBS (`README.md:59`, `:139` ; SQL `:225`). Le diagnostic contient `aia.amount` (`SQL:67`) alors que les autres requêtes utilisent `invoice_amount` : **compatibilité à vérifier sur le dictionnaire**, avant usage.

Les scripts `synchroDackShop/update.sql:92`, `synchroDackShop/updateAp_invoices_all/Update_AP_Invoices_Date_Jour.sql:84` et `UpdateApInvoice-DacShop/update_invoice_3850521294.sql:44` touchent les champs d'audit d'AP, puis commitent. Ce sont des actions de réémission/synchronisation, pas des imports de nouvelles factures. Les identifiants de session sont codés en dur dans les deux premiers. Le deuxième contrôle après mise à jour filtre par numéro alors que l'UPDATE filtre par ID (`:90`, `:120`) : contrôler le même ID avant/après. Le troisième est limité simultanément par numéro et ID (`:50`).

Les contrôles dashboard utilisent une fenêtre AP/documents de 30 jours et un fichier reçu hier (`Projet_Dashboard/sql/05_xerox_sans_image.sql:20` à `:27`, `06_xerox_avec_image.sql:10` à `:15`). Leur jointure reporting ↔ AP utilise seulement `INVOICE_NUM` : **risque** de collisions fournisseurs/UO, faux rapprochement ou agrégation de factures distinctes. `COUNT(DISTINCT num_fact)` est un compteur de numéros, pas nécessairement de factures. Les contrôles iValua amont lisent les historiques commandes, fournisseurs et réceptions, sans prouver l'intégration AP (`Ivalua/Vérification chargmt depuis iValua.sql:8`, `:16`, `:26`). Les deux copies de cette requête sont identiques octet pour octet.

## 9. Notes de frais Notilus

Le flux est identifié par `ATTRIBUTE9='NOT'`, fichier en `ATTRIBUTE10` ; le README annonce un retraitement nocturne AP/GL (`INtegrationDesNoteDeFrais/ReadMe.md:8`, `:21`, `:72`). Le script fourni est une correction de dates dans l'Open Interface, pas le chargeur initial ni le batch nocturne.

`Correction_Dates_Notilus.sql:34` à `:38` configure une date cible, filtre REJECTED, fichier facultatif et SIMULATION par défaut. En mise à jour : lignes non TAX **dont EXPENDITURE_ITEM_DATE est renseignée**, changement comptable et date de dépense (`:247` à `:258`) ; lignes TAX, date comptable seulement (`:285`) ; en-têtes, date GL (`:316`). Le statut n'est pas modifié. Commit et rollback sont commentés (`:357`).

**Limites à vérifier :** les lignes non TAX à date de dépense NULL gardent leur date comptable ; aucun contrôle explicite de période ouverte n'est réalisé dans ce script ; absence de filtre UO si fichier NULL ; masques `DD/MM/YY` avec une valeur paramétrée sur quatre chiffres (`:34`, `:206`) à normaliser/tester. Les compteurs postérieurs comptent les lignes rattachées à des en-têtes à la date cible, pas exclusivement celles modifiées par le run (`:373` à `:397`). L'historique `MOA - modif période dans O.I. pour Notilus_V2.sql` a ses UPDATE dans un commentaire bloc (`:89` à `:137`) mais conserve un `COMMIT` actif (`:139`). La condition historique `status <> 'PROCESSED'` exclut aussi les valeurs NULL ; elle diffère du filtre REJECTED explicite du nouveau script. Le dashboard Notilus (`Projet_Dashboard/sql/03_ndf_notilus.sql:10`) observe les créations AP sur dix jours ; il ne mesure pas le stock de rejets.

## 10. Services EAI et WebADI : dépendances adjacentes

Le corps `controlePaye/XXEAI_INTERFACE_TOOLS_PKG.sql` est identique ligne à ligne au corps à partir de la ligne 395 de `XXEAI_INTERFACE_TOOLS_PKG/XXEAI_INTERFACE_TOOLS_PKG.sql` (spécification ajoutée en préfixe, décalage +394). Éviter de compter ces copies comme deux versions fonctionnelles différentes.

Le service génère les IDs ENTETE/LIGNE via séquences AP (`controlePaye/XXEAI_INTERFACE_TOOLS_PKG.sql:1873`), récupère fournisseur/site/UO (`:1926`), paramètre source/devise/folio via flex values (`:2122`), détermine lignes MISCELLANEOUS/TAX/ITEM et données PA/refacturation (`:2214` à `:2293`), construit le code taxe (`:2298`). `Get_Cle_Comptable_CUF` retourne segments 1 à 12 et contexte ; ses types d'entrée/sortie sont explicités dans `controlePaye/XXEAI_CLE_COMPTABLE_CUF_OBJ.sql:1` et `:26`. L'appel direct de ces services par Xerox n'est pas établi : dépendance fonctionnelle adjacente, pas arc d'appel inventé.

**Anomalie candidate de contrat d'erreur :** `Get_Info_Invoice_Header` initialise `vv_code_erreur='OAE000'` (`:1929`) et son `WHEN OTHERS` renvoie le même code avec tous les champs NULL (`:2097`). Une exception inattendue peut donc retourner un code de succès ; à reproduire et corriger dans une tâche distincte. `Get_Info_Invoice_Line`, lui, renvoie `OAE999` en exception inattendue (`:2340`). Les commits de `Get_Infos_Banque` (`:513`, `:545`) sont à connaître si ces utilitaires sont composés dans une transaction métier.

`webadi/package.sql:8` et `webadi/packagebody.sql:1213` concernent `WEBADI.DKA_SPACUTOFFGL_PKG`, contrôle GL/PA et CUF, sans chaîne d'import AP démontrée. Le SQL dynamique `tab_select` concatène requête et valeurs et ouvre un curseur sans fermeture visible (`packagebody.sql:2274` à `:2304`) : risque de robustesse et de contrôle des entrées à examiner séparément. `DiagnosticWebadi/README.md:7` décrit le diagnostic poste, réseau et Excel ; les affirmations de compatibilité Office sont documentaires et n'établissent aucune contrainte fonctionnelle de l'interface AP.

`Recherche_Facture_11633263.sql:14` à `:139` documente une investigation ciblée fournisseur/site, facture, distributions et paiements ; la suspicion d'un ID iValua en attribut de site (`:71`) reste expressément une hypothèse.

## 11. Couverture et limites de preuve

Périmètre : 24 fichiers, 30 949 lignes, chargé intégralement par l'extraction statique ; revue sémantique approfondie des passages de flux, mappings, transactions et erreurs cités ci-dessus, comparaison complète des variantes. Les longs INSERT de colonnes Oracle et les utilitaires GL ne font pas l'objet ici d'une spécification champ par champ exhaustive. La lecture automatique intégrale ne constitue pas une validation exhaustive de chaque branche PL/SQL. Inventaire, empreintes et lignes dans `graphify-out/couverture_chunk_00.json` ; fragment explicite dans `graphify-out/.graphify_chunk_00.json`. L'extracteur masque commentaires et littéraux pour les références statiques ; il n'est pas un parseur Oracle complet et ne résout ni synonymes ni SQL dynamique. Les appels listés dans le fragment sont vérifiés manuellement ; des tables qualifiées/non qualifiées peuvent représenter le même objet.

Fichiers couverts :

- `controlePaye/XXEAI_CLE_COMPTABLE_CUF_OBJ.sql` ; `controlePaye/XXEAI_INTERFACE_TOOLS_PKG.sql`.
- `DiagnosticWebadi/README.md`.
- `DKA  Intégration des factures XEROX/DKA_IAPFACXGS_PKG.sql` ; `DKA_IAPFACXGS_PKG_ETI1.sql` ; `DKA_IAPFACXGS_PKG_PROD.sql` ; `README.md` du même dossier.
- `exportImageVers Ivalua/README.md` ; `exportImageVers Ivalua/Renvoi_Image_Facture_Ivalua.sql`.
- `INtegrationDesNoteDeFrais/Correction_Dates_Notilus.sql` ; `MOA - modif période dans O.I. pour Notilus_V2.sql` ; `ReadMe.md` du même dossier.
- `Ivalua/Vérification chargmt depuis iValua (1).sql` ; `Ivalua/Vérification chargmt depuis iValua.sql`.
- `Projet_Dashboard/sql/03_ndf_notilus.sql` ; `Projet_Dashboard/sql/05_xerox_sans_image.sql` ; `Projet_Dashboard/sql/06_xerox_avec_image.sql`.
- `Recherche_Facture_11633263.sql` ; `synchroDackShop/update.sql` ; `synchroDackShop/updateAp_invoices_all/Update_AP_Invoices_Date_Jour.sql` ; `UpdateApInvoice-DacShop/update_invoice_3850521294.sql`.
- `webadi/package.sql` ; `webadi/packagebody.sql` ; `XXEAI_INTERFACE_TOOLS_PKG/XXEAI_INTERFACE_TOOLS_PKG.sql`.

À obtenir pour conclure sur l'intégration en exploitation : DDL/index/contraintes des tables custom, vues de commandes valides et synonymes, corps des packages externes, chargeurs/fichiers de contrôle, configuration des sources/folios/taxes/seuils, paramétrage concurrent et Control-M, logs et comptages réels par UO/source. Les identifiants et dates dans les scripts sont des exemples ou interventions historiques, pas l'état actuel de production.
