# Intégrations DKA : flux, interfaces et reprises

## Portée et méthode

Revue statique des sources `dka/12.0.0`, sans exécution des SQL, des jobs Unix, des imports FNDLOAD ni connexion Oracle. Ce document couvre les familles d'intégration, les packages `DKA_I*`, `DKA_OPEN_INTERFACE*`, `XXEAI*` et les traitements de fusion `DKA_FUS*`. Les autres traitements spécifiques et workflows sont documentés dans les chapitres voisins. Le catalogue final de ce chapitre recense chaque corps de package de ce périmètre avec preuves de routines et de tables écrites. Cette couverture est exhaustive au niveau inventaire ; la lecture fonctionnelle des grands corps est ciblée sur leurs entrées, transformations et sorties, et ne constitue pas une validation de chaque branche.

Les références `chemin:ligne` sont relatives à la racine du dépôt. Dans les fiches, `admin/sql/X` désigne `dka/12.0.0/admin/sql/X`. Une table d'interface alimentée ne prouve pas que l'objet métier final a été créé : il faut contrôler la demande concurrente et les rejets standard.

## 1. Carte des flux

| Domaine | Entrant / traitement | Interface ou sortie | Consommateur / étape suivante |
|---|---|---|---|
| AP factures | XGS/Xerox, ZCI et DSP | `DKA_IAPFACXGS_INTERFACE`, puis `AP_INVOICES_INTERFACE` et `AP_INVOICE_LINES_INTERFACE` | Import AP standard ; factures et distributions finales à rapprocher |
| AP EAI | Factures `AMONTS` déjà déposées en interface standard | Contrôle période, doublon et groupes dans `DKA_OPEN_INTERFACE_AP_EAI` | `SQLAP/APXIIMPT` |
| AP Ivalua | Export des factures/images Oracle vers Ivalua | Fichiers et supervision `DKA_IAPFAC_IVALUA` | Lanceur de transfert ; succès aval non démontré par le seul export |
| AR facturation projets | `DKA_IARPAFAC_INTERFACE` | `RA_INTERFACE_LINES_ALL` et `RA_INTERFACE_DISTRIBUTIONS_ALL` | `AR/RAXMTR` et recyclage |
| AR clients | Clients IFS / staging spécifique | Interfaces clients et profils AR | `AR/RACUSTMA`, puis post-traitements |
| GL EAI | `GL_INTERFACE`, utilisateur EAI | Groupes et `GL_INTERFACE_CONTROL` | `SQLGL/GLLEZL` |
| PO commandes Ivalua | Fichiers en-têtes/lignes et staging | Interfaces PO ; branches de modification et annulation | `PO/POXPOPDOI`, contrôle des retours |
| PO réceptions | Ivalua / staging réception | `RCV_HEADERS_INTERFACE`, `RCV_TRANSACTIONS_INTERFACE` | `PO/RVCTP` |
| PO contrats sous-traitance | Ivalua | `DKA_SPO_CONTRAT_SSTR_IVALUA` ; tables de reporting/historique | Traitements et workflow spécifiques PO |
| PA / organisations | `DKA_EAI_ORGANISATION`, `DKA_EAI_PROJET`, `DKA_EAI_TACHE` | Organisations, projets, tâches, flexfields, historique | APIs / traitements PA, `PA/PAPMPRPB` |
| RH | `XXEAI_HR_*_INT` | Employés, affectations, tiers fournisseurs et informations bancaires | APIs Oracle et mises à jour quotidiennes |
| INV référentiels | Fichier articles | Interfaces articles/catégories et jeux de valeurs | `INV/INCOIN`, `INV_ITEM_CAT_ASSIGN_OI` |
| FA / CE / restitutions | Immobilisations, banques, événements AR | CSV/fichiers DTR, Hyperion, Hercules, CRM, fiscalité | Applications aval / exploitation fichiers |
| Fusion sociétés | Extraction, contrôles, transcodification | Tables temporaires, interfaces et modifications métiers | Imports standards et étapes post-fusion |

## 2. AP : factures, images, déblocage et contrôles

### 2.1 XGS, ZCI et DSP

Le même moteur `DKA_IAPFACXGS_PKG` contient les procédures `populate_xgs_tables`, `populate_zci_tables` et `populate_dsp_tables`. Elles alimentent le staging commun, le reporting et les historiques d'en-têtes/lignes. Il faut donc documenter trois origines distinctes mais une logique d'intégration partagée : `admin/sql/DKA_IAPFACXGS_PKG.pkb:5187`, `:5677`, `:6169`. Les fichiers `.ctl` propres à chaque origine définissent le contrat de chargement ; les jobs et scripts SQL constituent les points de lancement.

Le moteur calcule le type de transaction, cherche les réceptions et lignes de commande, détermine la TVA et gère les codes de rejet, puis écrit les en-têtes et lignes AP (`admin/sql/DKA_IAPFACXGS_PKG.pkb:141`, `:188`, `:312`, `:345`, `:524`, `:1043`). Les erreurs sont reportées dans le staging et les rejets standard (`:476`, `:4743`). Les procédures `control_double` et `delete_processed_lines` montrent que doublons et purge font partie du cycle ; elles ne garantissent pas à elles seules qu'une relance de tout fichier est idempotente (`:457`, `:4988`).

Le job `dka/12.0.0/bin/DKA_IAPFACXGS_JOB.sh:45` appelle SQL*Plus puis `DKA_IAPFACXGS.sql`. Les chemins réels, droits des répertoires, position des fichiers, bad/discard SQL*Loader et archivage doivent être confirmés en exploitation. Aucun de ces jobs n'a été lancé pendant l'analyse.

### 2.2 Open Interface AP EAI

`DKA_OPEN_INTERFACE_AP_EAI_PKG.main` prend l'organisation en paramètre et sélectionne les factures de source `AMONTS`, créées par l'utilisateur EAI, non encore `PROCESSED`, pour cette organisation (`admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb:259`, `:270`). Il contrôle la période comptable : une facture hors période ouverte passe à `WAITING` (`:584`). Le contrôle de doublon peut forcer `vendor_site_id = -999` et compléter le numéro fournisseur avec `DOUBLON`, puis créer un rejet `DUPLICATE INVOICE NUMBER` (`:575`, `:679`). Ce marquage modifie les données de l'interface : une correction doit tenir compte de ces valeurs, pas seulement de la cause métier initiale.

Avant l'import, il appelle `DKA_AP_TOOLS_PKG.apply_fonction` avec une clé `OI_` concaténée à l'origine (`:604`). La logique dépend donc aussi du paramétrage d'extensions par origine. Il lance `SQLAP/APXIIMPT` par source/groupe, organisation et code de blocage, avec purge désactivée et point de validation de 1000 (`:128`). Les demandes sont persistées dans `DKA_OPEN_INTERFACE_AP_EAI` (`:616`). L'attente est globale : boucle sur les demandes non terminées, pause de 30 secondes, sans borne visible dans cette boucle (`:642`). Le statut concurrent est ensuite rapatrié (`:664`).

**Reprise :** réouvrir/corriger la période ou les référentiels, qualifier les doublons, rapprocher facture originale, staging, interface et demande AP. Contrôler la fin des sous-demandes ; le retour de soumission seul ne suffit pas. Attention également à la mise à jour des notes de débit dans `AP_INVOICES_ALL`, située avant l'attente globale (`:629`).

### 2.3 Exports Ivalua et traitements complémentaires

`DKA_IAPFAC_IVALUA_PKG` est un export : génération des fichiers et suivi `DKA_IAPFAC_IVALUA`, extraction des BLOB/images, lancement de transfert et supervision (`admin/sql/DKA_IAPFAC_IVALUA_PKG.pkb:347`, `:1074`, `:1241`, `:1322`, `:1417`, `:1651`). Son nom ne doit pas être interprété comme un import AP entrant. `MAIN` met aussi à jour les documents attachés (`:1784`, `:1824`). Un test bout en bout doit comparer fichier produit, pièces jointes, dépôt aval et accusé de prise en compte.

Le déblocage DSP dispose d'un package et de tables d'interface, historique et reporting (`DKA_IAPFAC_DEBLOC_INTERFACE_PKG`, `.tab` et `.ctl`). Les contrôles de flux Xerox et Ivalua ont chacun leur package/reporting ; ils constituent une supervision distincte de la création effective des factures. `DKA_IAPFACTTDS_PKG` calcule les statuts, archive et fabrique un fichier (`admin/sql/DKA_IAPFACTTDS_PKG.pkb:43`, `:545`, `:671`). `DKA_IAPEMPLNOT_PKG` alimente une interface à une date de situation (`admin/sql/DKA_IAPEMPLNOT_PKG.pkb:44`, `:261`). Le catalogue ci-dessous permet de retrouver chaque routine et ses preuves.

## 3. AR : facturation, clients et recouvrement

### 3.1 Factures projets

`DKA_IARPAFAC_PKG` regroupe les lignes de `DKA_IARPAFAC_INTERFACE` par société, origine, année, région et organisation. Il sélectionne les lignes non acceptées de la demande courante ; les lignes `CLIENT` structurent le regroupement (`admin/sql/DKA_IARPAFAC_PKG.pkb:4462`). Les lignes sont ensuite ordonnées pour traiter les montants clients puis les composantes HT/TVA (`:4504`). Les contrôles couvrent date GL, TVA, type de mouvement, comptes TTC/HT/TVA/surtaxe, client et projet (`:1999`, `:2165`, `:2283`, `:2391`, `:2977`, `:3501`, `:3769`).

Les écritures cibles sont les interfaces AutoInvoice (`:1521`, `:1674`). L'import et le recyclage utilisent `AR/RAXMTR` dans deux procédures distinctes (`:4073`, `:4139`, `:4227`, `:4249`). Des traitements propres au prélèvement existent, dont création d'instrument et mise à jour de facture (`:789`, `:4313`). **Reprise :** corriger le staging et les référentiels, conserver le lien groupe/demande/facture, analyser les rejets AutoInvoice et éviter de reconstruire les lignes déjà acceptées.

### 3.2 Clients et extractions AR

`DKA_ICLIENTIFS_PKG` alimente `RA_CUSTOMERS_INTERFACE_ALL` et `RA_CUSTOMER_PROFILES_INT_ALL`, contrôle les données, lance l'import, puis applique les post-traitements (`admin/sql/DKA_ICLIENTIFS_PKG.pkb:391`, `:796`, `:1822`, `:2339`). La version présente lance `RACUSTMA` ; `RACUST` figure dans un commentaire ancien (`:1850`). Ne pas déduire le programme réellement utilisé d'un commentaire historique. Des contrôles de doublons, lignes rejetées et existence de clients/adresses sont visibles (`:1557`, `:1594`, `:1753`, `:1783`).

`DKA_IARRECSICM_PKG` et sa variante mensuelle extraient les encours pour SICM ; `DKA_IAR_EVENEMENTS_DTR_PKG` extrait les événements AR avec dates de dernière exécution et d'observation (`admin/sql/DKA_IARRECSICM_PKG.pkb:186`, `:1283` ; `admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb:117`, `:968`). Ce sont des sorties métier, à distinguer de l'import de factures.

## 4. GL, fiscalité et restitutions financières

`DKA_IGL_INTERFACE_EAI_PKG` travaille sur `GL_INTERFACE`, pour les lignes de l'utilisateur EAI, sans groupe, aux statuts `NEW` ou `P` (`admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb:352`). Il construit `GL_INTERFACE_CONTROL` (`:98`, `:134`) et le suivi `DKA_IGL_INTERFACE_EAI`, puis appelle `SQLGL/GLLEZL` avec identifiant d'exécution et livre comptable (`:178`, `:198`). **Reprise :** rapprocher groupe, interface_run_id, demande, statuts GL et journaux créés ; une nouvelle sélection sans groupe ne reprend pas forcément un ancien groupe en échec.

Les sorties GL comprennent Hyperion montants et quantités (`admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:333`, `:501`, `:730`, `:818`), les valeurs/attributs flexfields et codes de consolidation `IEOGLVEC01` (`admin/sql/DKA_IEOGLVEC01_PKG.pkb:668`, `:1089`, `:1858`, `:2077`), et l'extraction fiscale Altaven `IEOGLETF01` (`admin/sql/DKA_IEOGLETF01_PKG.pkb:236`). Les données de fiscalité AP/AR/GL sont réunies dans `DKA_EXTRACT_FISCAL`, avec factures, règlements, divers, ajustements, autres GL et reports à nouveau (`admin/sql/DKA_IAPARGLCTRLFISCAL_PKG.pkb:787`, `:980`, `:1136`, `:1326`, `:1514`, `:1670`, `:1829`, `:1985`). La production des fichiers de données et paramètres est séparée (`:2542`, `:2701`).

## 5. PO : achats Ivalua, fournisseurs, contrats et réceptions

### 5.1 Commandes

`DKA_IPOCDE_IVALUA_PKG` orchestre chargement, purge des données traitées, préparation, détermination d'action, validation, import et contrôle du retour (`admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:610`, `:738`, `:828`, `:1026`, `:1352`, `:5902`). Il alimente les trois interfaces PO d'en-têtes, lignes et distributions (`:3540`, `:3617`, `:3683`), mais comporte aussi des branches de mise à jour et d'annulation d'en-tête/ligne (`:4352`, `:4681`, `:5027`). Documenter uniquement une création de commande serait donc incomplet.

L'import standard est `PO/POXPOPDOI` (`:5383`), suivi d'un contrôle d'import (`:5482`). Les pièces jointes des bons de commande sont construites dans les tables FND documents (`:5602`). Les lanceurs de chargement et de recyclage sont distincts dans `sql/DKA_IPOCDE_CHARG.sql` et `sql/DKA_IPOCDE_RECYCL.sql`. La reprise doit identifier l'action d'origine, l'état du document standard, les identifiants d'interface et les pièces jointes déjà créées avant toute relance.

### 5.2 Fournisseurs et contrats

`DKA_IPOFRS_IVALUA_PKG` gère statut, suppression des données obsolètes, loader, validation et import (`admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb:138`, `:190`, `:582`, `:743`, `:2466`). Le format d'entrée distingue en-têtes, lignes et homologations dans les fichiers `.ctl` de `bin/`. `DKA_IPOFRS_REP_IVALUA_PKG` dispose d'un flux de reprise du référentiel avec contrôle puis mise à jour (`admin/sql/DKA_IPOFRS_REP_IVALUA_PKG.pkb:370`, `:703`). Ne pas assimiler cette reprise au chargement quotidien sans examen des paramètres.

Les contrats de sous-traitance Ivalua passent par `DKA_IPO_SSTR_IVALUA_PKG` : chargement, préparation, détermination d'action, validation, insertion dans `DKA_SPO_CONTRAT_SSTR_IVALUA`, compteurs, reporting et historique (`admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:201`, `:249`, `:309`, `:587`, `:642`, `:887`, `:934`). Le moteur `DKA_IPOGENCOM_PKG` génère des commandes depuis les contrats et possède une entrée workflow `modification_commande(itemtype, ...)` ; il écrit également certaines localisations et distributions dans les tables finales (`admin/sql/DKA_IPOGENCOM_PKG.pkb:496`, `:833`, `:1286`, `:1442`). Ce flux combine donc interfaces et opérations spécifiques sur documents existants.

### 5.3 Réceptions

`DKA_IPORECEPTION_IVALUA_PKG` valide par groupe et globalement, alimente les interfaces réception, soumet `PO/RVCTP`, répercute les résultats et produit un bilan (`admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:605`, `:2638`, `:2932`, `:3661`, `:3914`, `:4232`). Les rejets spécifiques sont conservés dans `DKA_IPOREC_REJECT` et des copies historique/reporting sont présentes (`:1386`, `:4130`, `:4155`). Plusieurs appels RVCTP existent : il ne faut pas supposer une seule sous-demande par fichier (`:3712`, `:3759`, `:3805`).

`DKA_IMPTRECPO_PKG` fournit un autre import réception avec validation, interface, RVCTP, mode reprise et réinitialisation des statuts (`admin/sql/DKA_IMPTRECPO_PKG.PKB:591`, `:1165`, `:1631`, `:2002`, `:2037`). `DKA_IPORECVTOTAL_PKG` contient des corrections déclenchables depuis le workflow et des compléments de réception (`admin/sql/DKA_IPORECVTOTAL_PKG.pkb:238`, `:654`, `:824`). Le rapprochement commande/livraison/réception et quantités est indispensable avant rejouer un groupe.

### 5.4 Sorties achats

Les achats disposent de sorties distinctes : commandes `DKA_IPOEXTRACTCDE_PKG`, engagements Hercules `DKA_IPOEXTENGHERC_PKG`, soldes Hercules `DKA_IPOEXTSOLDHERC_PKG`, et Hyperion/ détail sous-traitance `DKA_IPOHYPERION_PKG`. Les sorties Hercules comprennent bilan et compression (`admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:147`, `:491`, `:773`, `:934`, `:1314` ; `admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:526`, `:644`, `:937`). Hyperion comprend aussi un envoi SMTP avec pièce jointe (`admin/sql/DKA_IPOHYPERION_PKG.pkb:1256`, `:1600`). Le contenu financier généré et la livraison du fichier doivent être vérifiés séparément.

## 6. PA, RH et référentiels

### 6.1 Organisations, centres de finance, projets et tâches

`DKA_ICODEPROJET_PKG` traite les centres de finance, les classifications et hiérarchies organisationnelles, les projets et tâches, leurs classes, budgets et contrôles de transactions (`admin/sql/DKA_ICODEPROJET_PKG.pkb:307`, `:544`, `:645`, `:741`, `:1473`, `:1800`, `:1963`, `:2045`, `:2367`, `:3743`). Le staging `DKA_EAI_ORGANISATION/PROJET/TACHE` est historisé (`:4314`). L'appel `PA/PAPMPRPB` est visible (`:4698`). Des routines propres aux fermetures et mises à jour mensuelles complètent le flux (`:5134`, `:5206`, `:5395`, `:5672`).

Les orchestrateurs `DKA_IIPRJOPA01.sql` et `DKA_IIPRJOPA01_MONTHLY.sql` ciblent respectivement `DKA_IPROJECT` et `DKA_ICODEPROJET_2` (`dka/12.0.0/sql/DKA_IIPRJOPA01.sql:24` ; `dka/12.0.0/sql/DKA_IIPRJOPA01_MONTHLY.sql:23`). `DKA_IPAPROJETHRM.sql` lance un ensemble de demandes homonyme (`:23`, `:70`). La définition de l'ensemble, ses étapes et paramètres doivent être lues avec ces scripts : les appels sont en partie pilotés par métadonnées FND.

### 6.2 Employés

Les variantes `DKA_IHREMP_PKG` et `DKA_IHREMP_GXP_PKG` consomment les structures XXEAI employés/affectations/banques et gèrent recherche d'employé, emploi, fournisseur, site et données bancaires. Elles contiennent terminaison, réactivation, création, modification et mise à jour quotidienne (`admin/sql/DKA_IHREMP_PKG.pkb:1467`, `:1602`, `:1702`, `:3549`, `:7178` ; variante GXP `:1258`, `:1383`, `:1440`, `:3070`, `:5549`).

Dans la version principale, `main` enchaîne initialisation, purge des tables de travail, création, mise à jour, traitement quotidien et édition, en vérifiant les retours (`admin/sql/DKA_IHREMP_PKG.pkb:8655`, `:8673`, `:8693`, `:8712`, `:8750`, `:8768`). La branche commentée de mise à jour des seules banques ne doit pas être considérée active (`:8720`). Les erreurs ont une procédure dédiée et une table `XXEAI_HR_INT_ERRORS_ALL` ; les indicateurs traité pilotent la reprise (`:493`, `:592`). Attention aux dates d'effet et à l'état fournisseur/employé déjà appliqué avant relance.

### 6.3 Articles et services EAI

`DKA_IEOMTL_CODARTINT_PKG` charge un fichier d'articles dans une table temporaire, contrôle format, unicité et référentiels, crée des erreurs, alimente les jeux de valeurs et les interfaces articles/catégories (`admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:121`, `:944`, `:1257`, `:3829`, `:4824`, `:3263`). Il lance `INV/INCOIN` et `INV/INV_ITEM_CAT_ASSIGN_OI`, puis vérifie leurs retours (`:3746`, `:5373`, `:5568`, `:5673`). Il inclut aussi des écritures directes de valeurs FND : contrôler les effets partiels avant reprise. `DKA_IEOMTL_PURGRECH_PKG` fournit une purge séparée de recherche catalogue (`admin/sql/DKA_IEOMTL_PURGRECH_PKG.pkb:42`).

`XXEAI_INTERFACE_TOOLS_PKG` expose les services de contrôle/consultation EAI : projets/tâches, période ouverte, monnaie, flexfields, TVA, banque, folios AP/GL, société/projet, clé comptable CUF, facture et numéro/type de ligne AR. Des variantes liste opèrent sur les types SQL XXEAI (`admin/sql/XXEAI_INTERFACE_TOOLS_PKG.pkb:139`, `:194`, `:404`, `:446`, `:581`, `:953`, `:1718`, `:1861`, `:1926`, `:2180`, `:2501`). Ce package est une dépendance de transformation et de validation, pas un import autonome de toutes ces entités. Les `.sql` de types, grants et synonymes font partie du contrat d'exposition ; le catalogue global les recense.

## 7. FA, CE, CRM et autres sorties

`DKA_IFA_FLUXCM_PKG` exporte `IMMOBILISATIONS_YYYYMMDD.csv` dans `DKA_IEOARCRM01_DIR`, avec période début/fin, livre, catégorie, compte, immobilisation, projet, montants d'amortissement et tâche (`admin/sql/DKA_IFA_FLUXCM_PKG.pkb:565`, `:570`, `:603`). Le périmètre dépend des profils région et sécurité ; il adapte la lecture aux immobilisations provenant d'une fusion (`:593`, `:597`, `:644`). C'est une extraction patrimoniale, sans import FA démontré dans ce package.

`DKA_ICE_BANKBRANCHES_DTR_PKG` extrait les agences bancaires pour DTR selon dernière exécution et date d'observation (`admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb:115`, `:322`). `DKA_IAPBANK_PKG` traite un référentiel établissements/guichets avec tables temporaires, historique, contrôles de cohérence et simulation (`admin/sql/DKA_IAPBANK_PKG.pkb:44`, `:235`, `:702`, `:1214`, `:1841`).

`DKA_IEOARCRM01_PKG` produit plusieurs CSV : fournisseurs, règlements, factures payées/non payées et commandes (`admin/sql/DKA_IEOARCRM01_PKG.pkb:304`, `:371`, `:449`, `:534`, `:771`). Son préfixe AR ne reflète donc pas toute sa couverture. `DKA_IEOAPSAT01_APIMP_PKG` crée un fichier AP_IMPORT et des tables en-têtes/lignes (`admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pkb:453`, `:1515`, `:1706`). `DKA_IDECLIC_PKG` calcule les soldes, coûts et événements dans `DKA_I00RC` et `DKA_I00EH` (`admin/sql/DKA_IDECLIC_PKG.pkb:52`, `:828`, `:986`, `:1021`, `:1095`).

## 8. Fusions de sociétés : chaîne transverse à maîtriser séparément

Ces traitements sont présents dans le dépôt et relèvent d'opérations métier de fusion ; leur nom ne prouve pas une migration vers le produit Oracle Fusion Cloud.

| Famille | Chaîne et conséquences | Sources probantes |
|---|---|---|
| AP | Contrôle → extraction vers interfaces spécifiques → insertion interfaces AP → post-fusion → blocages, pièces jointes, lettrages et annulation workflows | `admin/sql/DKA_FUSION_AP_PKG.pkb:6231`, `:6705`, `:7723`, `:8247`, `:8629`, `:8817`, `:9136`, `:9343`, `:9527` |
| AR | Contrôles banque/sites/TVA/combinaisons → interfaces AutoInvoice → règlements, annulation, post-fusion et lettrage | `admin/sql/DKA_FUSION_AR_PKG.pkb:3598`, `:4015`, `:4550`, `:4735`, `:5125`, `:5498`, `:5777` |
| GL | Extraction → validation/transcodification → import → archivage | `admin/sql/DKA_FUSGLFUEXT_PKG.pkb:41`, `:942`, `:1432`, `:2534`, `:2597` |
| PA | Sauvegarde/purge interfaces → suffixage projets → rattachement historique → restauration → fermeture projets/tâches → correction organisations et indicateurs | `admin/sql/DKA_FUSION_PA_PKG.pkb:438`, `:655`, `:1053`, `:1474`, `:1673`, `:1907`, `:2151` |
| PO commandes | Extraction en-têtes/lignes/distributions temporaires → validation → interfaces PO → POXPOPDOI → post-import et reprise | `admin/sql/DKA_FUSPOCMDEXP_PKG.pkb:829`, `:1010`, `:1214` ; `admin/sql/DKA_FUSPOIMP_PKG.pkb:589`, `:1529`, `:2026`, `:2261`, `:2880` |
| PO contrats | Extraction spécifique → validation → import avec écritures finales et archives PO/contrats → bilan/reprise | `admin/sql/DKA_FUSPOEXPCTRSSTR_PKG.pkb:485` ; `admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:454`, `:1400`, `:1510`, `:1687`, `:2030`, `:2133` |
| PO annexes | Réception totale, génération images, mise à jour prix et orchestration maître | `admin/sql/DKA_FUSPORECVTOTAL_PKG.pkb:115`, `:216`, `:291` ; `admin/sql/DKA_FUSPOGENIMG_PKG.pkb:147` ; `admin/sql/DKA_FUSPOMAJPFTF_PKG.pkb:33` ; `admin/sql/DKA_FUSPOMAJPFTF_Maitre_PKG.pkb:33` |

Des modifications de tables finales sont présentes : blocages AP, documents joints, distributions PA, contrats et en-têtes PO. Une reprise de fusion exige l'état exact de chaque étape, les sauvegardes, le mapping absorbée/absorbante, les contrôles comptables et le détail des objets déjà créés ; une relance globale n'est pas une procédure de récupération démontrée.

## 9. Paramètres, lanceurs et exploitation

| Lancement identifié | Paramètres ou clé de traitement | Preuve |
|---|---|---|
| AP EAI | Organisation, source, groupe, code blocage ; `APXIIMPT`, purge `N`, point validation 1000 | `admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb:111`, `:128`, `:259` |
| GL EAI | Interface_run_id et livre comptable | `admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb:178`, `:198` |
| Facturation AR | Demande, groupe, société, origine, année/région ; `RAXMTR` import/recyclage | `admin/sql/DKA_IARPAFAC_PKG.pkb:4139`, `:4249`, `:4462` |
| PO | Création de commandes standard `POXPOPDOI` ; réceptions `RVCTP` | `admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:5383` ; `admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:3712` |
| RH | Drapeau debug et contexte FND ; données de staging à dates d'effet | `admin/sql/DKA_IHREMP_PKG.pkb:8624` |
| FA | Période début et période fin ; région/sécurité dans profils | `admin/sql/DKA_IFA_FLUXCM_PKG.pkb:565`, `:593` |
| DTR CE et AR | Dernière exécution et date d'observation | `admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb:322` ; `admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb:968` |
| Ensembles FND | `DKA_ICLIENTIFS`, `DKA_IPAPROJETHRM` | `dka/12.0.0/sql/DKA_IISIGORA01.sql:25`, `:72` ; `dka/12.0.0/sql/DKA_IPAPROJETHRM.sql:23`, `:70` |

Les `.prt`, `.ldt`, `.pst` et `.dpt` sous `admin/import` apportent programmes, exécutables, ensembles et paramètres. Les scripts `DKA_II*` récupèrent parfois les paramètres via `DKA_TOOLS_PKG.get_request_set_params` : les valeurs opérationnelles et horaires ne sont donc pas entièrement déductibles du code. Les fichiers `.ctl` sont le contrat des champs d'entrée ; le catalogue ci-dessous les associe par préfixe quand le lien est explicite dans les noms, sans prétendre résoudre automatiquement tous les appels dynamiques.

Pour chaque exécution, conserver : origine/fichier et empreinte, demande parent et demandes enfants, organisation/livre, groupe et identifiants d'interface, comptages reçus/validés/rejetés/intégrés, objets finaux, historique et dépôt aval. Les durées, volumes, planifications, propriétaire d'exploitation, SLA, habilitations et rétention ne sont pas établis par cette revue ; ils doivent être complétés avec le paramétrage déployé.

## 10. Vérifications prioritaires

1. Tester le cas période fermée puis réouverte AP/GL et contrôler la reprise des statuts/groupe, sans réimporter des objets acceptés.
2. Tester le doublon AP sur un autre site fournisseur : marquage de l'interface, rejet, correction et nouvelle soumission.
3. Tester les rejets partiels AutoInvoice, PO et réception ; comparer compteurs spécifiques aux objets finaux.
4. Tester la livraison des exports et images avec erreur de répertoire ou transfert ; distinguer fichier généré et fichier consommé.
5. Vérifier les appels dynamiques et ensembles FND dans l'environnement cible, notamment extensions par origine AP.
6. Pour RH, tester création, changement à date d'effet, sortie et réactivation ; rapprocher employé, fournisseur et banque.
7. Pour les fusions, réaliser un exercice de reprise sur une copie de données avec contrôle de chaque étape et rapprochement comptable.



## 11. Catalogue des corps de packages d?int?gration et fusion
**56 corps de packages** du p?rim?tre de pr?fixes d?fini en introduction. Les ?l?ments ci-dessous sont extraits du contenu ; les noms de routines et cibles sont des indices techniques, ? lire avec les fiches fonctionnelles pr?c?dentes. Les appels peuvent ?tre comment?s ou dynamiques : cette extraction ne constitue pas un graphe d?ex?cution valid?. Une absence de cible INSERT ne signifie pas absence de modification (UPDATE, API ou SQL dynamique possibles).
### DKA_FUSGLCTRLPR_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_FUSGLCTRLPR_PKG.pkb:53`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSGLCTRLPR.prt`.

### DKA_FUSGLFUEXT_PKG

Points d?entr?e / ?tapes : `EXTRACT_DATA` (`dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb:41`); `VALIDATE_DATA` (`dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb:942`); `IMPORT_DATA` (`dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb:1432`); `MAIN` (`dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb:2597`).

Cibles INSERT rep?r?es : `DKA_SGLFUSION_TMP` (`dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb:541`); `DKA_STRANSCO_LINES_HIST` (`dka/12.0.0/admin/sql/DKA_FUSGLFUEXT_PKG.pkb:2552`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSGLFUEXT.prt`.

### DKA_FUSION_AP_PKG

Points d?entr?e / ?tapes : `dka_value_valid_f` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:1202`); `dka_ccid_valid_f` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:1379`); `dka_bank_charges_ccid_f` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:4803`); `main_ctr` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:6231`); `main_extract` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:6705`); `main_insert` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:7723`); `main_post_fusion` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8247`); `main_hold_no_cent` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8312`); `dka_extract_images` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8371`); `main_rattchmt_images` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8629`); `main_let_rec` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8817`); `main_let_maj` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:9136`).

Cibles INSERT rep?r?es : `dka_fusion_ap_ffv` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:1283`); `dka_fusion_ap_ccid` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:1474`); `dka_fusion_ap_inv_int` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:2205`); `dka_fusion_ap_inv_lin_int` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:3124`); `ap_holds_all` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:4141`); `dka_fusion_ap_invoice` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:4216`); `ap_invoices_interface` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:7743`); `ap_invoice_lines_interface` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:7750`); `dka_ap_invfus_attached_docs` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8376`); `fnd_attached_documents` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8570`); `dka_fusion_ap_lettrage` (`dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb:8764`).

### DKA_FUSION_AR_PKG

Points d?entr?e / ?tapes : `extraction` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:1076`); `valeur_valide` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:2288`); `MAIN` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:6100`).

Cibles INSERT rep?r?es : `DKA_AR_FUSION_INV_CTRL_TEMP` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:357`); `DKA_AR_FUSION_REC_CTRL_TEMP` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:720`); `dka_ar_fusion_ffv_temp` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:2333`); `dka_ar_fusion_gcc_temp` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:2447`); `ra_interface_lines_all` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:4015`); `RA_INTERFACE_DISTRIBUTIONS_ALL` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:4550`); `DKA_AR_FUSION_MVT_LETTRAGE_0` (`dka/12.0.0/admin/sql/DKA_FUSION_AR_PKG.pkb:5644`).

### DKA_FUSION_PA_PKG

Points d?entr?e / ?tapes : `BILAN_ET01` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:328`); `MAIN_SAUV_PURGE` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:438`); `MAIN_SUFFIX_PROJET` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:655`); `MAIN_REC_HIST` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1053`); `BILAN_ET07` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1396`); `MAIN_REST_TAB_INT` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1474`); `BILAN_ET08` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1648`); `MAIN_FERM_PROJET` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1673`); `MAIN_CORREC_PROJET` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1907`); `MAIN_REPRISE_INDIC` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:2151`); `MAIN_MAJ_PR_TEC_PCA` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:2535`); `MAIN_MAJ_PR_CCA` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:2921`).

Cibles INSERT rep?r?es : `DKA_EAI_ORG_SAUV_FUSION` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:246`); `DKA_EAI_PROJET_SAUV_FUSION` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:262`); `DKA_EAI_TACHE_SAUV_FUSION` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:278`); `PA.PA_COST_DIST_OVERRIDES` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:963`); `DKA_EAI_ORGANISATION` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1199`); `DKA_EAI_PROJET` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1216`); `DKA_EAI_TACHE` (`dka/12.0.0/admin/sql/DKA_FUSION_PA_PKG.pkb:1293`).

### DKA_FUSPOCMDEXP_PKG

Points d?entr?e / ?tapes : `Main` (`dka/12.0.0/admin/sql/DKA_FUSPOCMDEXP_PKG.pkb:37`).

Cibles INSERT rep?r?es : `DKA_SPOFUSION_HEADERS_TMP` (`dka/12.0.0/admin/sql/DKA_FUSPOCMDEXP_PKG.pkb:829`); `DKA_SPOFUSION_LINES_TMP` (`dka/12.0.0/admin/sql/DKA_FUSPOCMDEXP_PKG.pkb:1010`); `DKA_SPOFUSION_DISTRIBS_TMP` (`dka/12.0.0/admin/sql/DKA_FUSPOCMDEXP_PKG.pkb:1214`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPOCMDEXP.prt`.

### DKA_FUSPOEXPCTRSSTR_PKG

Points d?entr?e / ?tapes : `Main` (`dka/12.0.0/admin/sql/DKA_FUSPOEXPCTRSSTR_PKG.pkb:44`).

Cibles INSERT rep?r?es : `DKA_SPOFUSION_SSTR_HEADERS_TMP` (`dka/12.0.0/admin/sql/DKA_FUSPOEXPCTRSSTR_PKG.pkb:485`); `DKA_SPOFUSION_SSTR_DETAIL_TMP` (`dka/12.0.0/admin/sql/DKA_FUSPOEXPCTRSSTR_PKG.pkb:626`); `DKA_SPOFUSION_SSTR_IMPUT_TMP` (`dka/12.0.0/admin/sql/DKA_FUSPOEXPCTRSSTR_PKG.pkb:750`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPOEXPCTRSSTR.prt`.

### DKA_FUSPOGENIMG_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_FUSPOGENIMG_PKG.pkb:147`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPOGENIMG.prt`.

### DKA_FUSPOIMP_PKG

Points d?entr?e / ?tapes : `validate_data` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:589`); `import_data` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:1529`); `Launch_OI` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:2026`); `update_post_import` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:2261`); `Report_Bilan` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:2665`); `set_recovery_mode` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:2880`); `post_OI` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:3142`); `main` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:3539`).

Cibles INSERT rep?r?es : `dka_program_messages` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:240`); `PO_HEADERS_INTERFACE` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:1566`); `PO_LINES_INTERFACE` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:1723`); `PO_DISTRIBUTIONS_INTERFACE` (`dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb:1873`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPOIMP.prt`.

### DKA_FUSPOIMPCTRSSTR_PKG

Points d?entr?e / ?tapes : `validate_data` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:454`); `import_data` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:1400`); `Report_Bilan` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:2030`); `set_recovery_mode` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:2133`); `main` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:2334`).

Cibles INSERT rep?r?es : `PO_HEADERS_ALL` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:1510`); `PO_HEADERS_ARCHIVE_ALL` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:1597`); `DKA_CONTRAT_SSTR` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:1687`); `DKA_CONTRAT_SSTR_ARCHI` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:1758`); `DKA_CONTRAT_SSTR_IMPUTATION` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:1844`); `DKA_CONTRAT_SSTR_IMPUT_ARCHI` (`dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb:1890`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPOIMPCTRSSTR.prt`.

### DKA_FUSPOMAJPFTF_Maitre_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_FUSPOMAJPFTF_Maitre_PKG.pkb:33`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPOMAJPFTF_MAITRE.prt`.

### DKA_FUSPOMAJPFTF_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_FUSPOMAJPFTF_PKG.pkb:33`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPOMAJPFTF.prt`.

### DKA_FUSPORECVTOTAL_PKG

Points d?entr?e / ?tapes : `Launch_OI` (`dka/12.0.0/admin/sql/DKA_FUSPORECVTOTAL_PKG.pkb:73`); `main` (`dka/12.0.0/admin/sql/DKA_FUSPORECVTOTAL_PKG.pkb:426`).

Cibles INSERT rep?r?es : `rcv_headers_interface` (`dka/12.0.0/admin/sql/DKA_FUSPORECVTOTAL_PKG.pkb:216`); `rcv_transactions_interface` (`dka/12.0.0/admin/sql/DKA_FUSPORECVTOTAL_PKG.pkb:291`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_FUSPORECVTOTAL.prt`.

### DKA_IAPARGLCTRLFISCAL_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IAPARGLCTRLFISCAL_PKG.pkb:2897`); `main_auto` (`dka/12.0.0/admin/sql/DKA_IAPARGLCTRLFISCAL_PKG.pkb:3248`).

Cibles INSERT rep?r?es : `dka_param_extract_fiscal` (`dka/12.0.0/admin/sql/DKA_IAPARGLCTRLFISCAL_PKG.pkb:222`); `DKA_EXTRACT_FISCAL` (`dka/12.0.0/admin/sql/DKA_IAPARGLCTRLFISCAL_PKG.pkb:806`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IAPARGLCTRLFISCAL_JOB.sh`, `dka/12.0.0/sql/DKA_IAPARGLCTRLFISCAL.sql`, `dka/12.0.0/admin/import/DKA_IAPARGLCTRLFISCAL.prt`.

### DKA_IAPBANK_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb:2474`).

Cibles INSERT rep?r?es : `DKA_IAPBANK_GUI_TMP_HIST` (`dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb:66`); `DKA_IAPBANK_ETAB_TMP_HIST` (`dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb:162`); `DKA_IAPBANK_GUI_TMP` (`dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb:607`); `DKA_IAPBANK_ETAB_TMP` (`dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb:1059`); `DKA_IAPBANK_ERROR` (`dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb:1332`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IAPBANK.mnt`.

### DKA_IAPCTRFLUX_IVALUA_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_IVALUA_PKG.pkb:60`).

Cibles INSERT rep?r?es : `dka.dka_iapctrflux_ivalua` (`dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_IVALUA_PKG.pkb:501`).

### DKA_IAPCTRFLUX_XEROX_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_XEROX_PKG.pkb:64`).

Cibles INSERT rep?r?es : `dka.dka_iapctrflux_xerox` (`dka/12.0.0/admin/sql/DKA_IAPCTRFLUX_XEROX_PKG.pkb:517`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IAPCTRFLUX_XEROX.dpt`, `dka/12.0.0/admin/import/DKA_IAPCTRFLUX_XEROX.mst`, `dka/12.0.0/admin/import/DKA_IAPCTRFLUX_XEROX.prt`.

### DKA_IAPEMPLNOT_PKG

Points d?entr?e / ?tapes : `Main` (`dka/12.0.0/admin/sql/DKA_IAPEMPLNOT_PKG.pkb:72`).

Cibles INSERT rep?r?es : `DKA_IAPEMPLNOT_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IAPEMPLNOT_PKG.pkb:261`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IAPEMPLNOT_JOB.sh`, `dka/12.0.0/sql/DKA_IAPEMPLNOT.sql`, `dka/12.0.0/admin/import/DKA_IAPEMPLNOT.prt`.

### DKA_IAPFAC_DEBLOC_INTERFACE_PKG

Points d?entr?e / ?tapes : `validate_data_group` (`dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB:488`); `validate_data` (`dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB:1238`); `Report_Bilan` (`dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB:2421`); `main` (`dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB:2691`).

Cibles INSERT rep?r?es : `DKA_IAPFAC_DEBLOC_HIST_INTERF` (`dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB:2311`); `DKA_IAPFAC_DEBLOC_REPOR_INTERF` (`dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB:2341`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IAPFAC_DEBLOC_INTERFACE.ctl`, `dka/12.0.0/admin/import/DKA_IAPFAC_DEBLOC_INTERFACE.prt`, `dka/12.0.0/admin/import/DKA_IAPFAC_DEBLOC_INTERFACE_LOADER.prt`.

### DKA_IAPFAC_IVALUA_PKG

Points d?entr?e / ?tapes : `MAIN` (`dka/12.0.0/admin/sql/DKA_IAPFAC_IVALUA_PKG.pkb:1824`).

Cibles INSERT rep?r?es : `dka_iapfac_ivalua_img_maj` (`dka/12.0.0/admin/sql/DKA_IAPFAC_IVALUA_PKG.pkb:963`); `DKA_IAPFAC_IVALUA` (`dka/12.0.0/admin/sql/DKA_IAPFAC_IVALUA_PKG.pkb:1074`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IAPFAC_IVALUA.dpt`.

### DKA_IAPFACTTDS_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IAPFACTTDS_PKG.pkb:747`).

Cibles INSERT rep?r?es : `DKA_IAPFACTTDS_TAB` (`dka/12.0.0/admin/sql/DKA_IAPFACTTDS_PKG.pkb:468`); `DKA_IAPFACTTDS_HIST` (`dka/12.0.0/admin/sql/DKA_IAPFACTTDS_PKG.pkb:554`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IAPFACTTDS_JOB.sh`, `dka/12.0.0/sql/DKA_IAPFACTTDS.sql`.

### DKA_IAPFACXGS_PKG

Points d?entr?e / ?tapes : `child_import` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:1811`); `import` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:4821`).

Cibles INSERT rep?r?es : `ap_invoices_interface` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:555`); `ap_invoice_lines_interface` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:1088`); `DKA_IAPFACXGS_MTDISP` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:3735`); `ap_interface_rejections` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:4743`); `DKA_IAPFACXGS_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:5347`); `DKA_IAPFACXGS_REPORTING_ALL` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:5429`); `DKA_IAPFACXGS_INT_HIST_LINES` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:5534`); `DKA_IAPFACXGS_INT_HIST_HEADS` (`dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb:5566`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IAPFACXGS.ctl`, `dka/12.0.0/bin/DKA_IAPFACXGS_JOB.sh`, `dka/12.0.0/sql/DKA_IAPFACXGS.sql`, `dka/12.0.0/admin/import/DKA_IAPFACXGS.dpt`, `dka/12.0.0/admin/import/DKA_IAPFACXGS.prt`.

### DKA_IAPLOADIMG_XEROX_PKG

Points d?entr?e / ?tapes : `chargement_image` (`dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb:166`); `main` (`dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb:783`).

Cibles INSERT rep?r?es : `fnd_lobs` (`dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb:197`); `fnd_documents_tl` (`dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb:275`); `fnd_documents` (`dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb:298`); `fnd_attached_documents` (`dka/12.0.0/admin/sql/DKA_IAPLOADIMG_XEROX_PKG.pkb:327`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IAPLOADIMG_XEROX_JOB.sh`, `dka/12.0.0/sql/DKA_IAPLOADIMG_XEROX.sql`, `dka/12.0.0/admin/import/DKA_IAPLOADIMG_XEROX.dpt`, `dka/12.0.0/admin/import/DKA_IAPLOADIMG_XEROX.grp`, `dka/12.0.0/admin/import/DKA_IAPLOADIMG_XEROX.prt`.

### DKA_IAR_EVENEMENTS_DTR_PKG

Points d?entr?e / ?tapes : `p_validate` (`dka/12.0.0/admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb:60`); `p_extract_data` (`dka/12.0.0/admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb:117`); `p_bilan` (`dka/12.0.0/admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb:933`); `main` (`dka/12.0.0/admin/sql/DKA_IAR_EVENEMENTS_DTR_PKG.pkb:968`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IAR_EVENEMENTS_DTR_JOB.sh`, `dka/12.0.0/sql/DKA_IAR_EVENEMENTS_DTR.sql`, `dka/12.0.0/admin/import/DKA_IAR_EVENEMENTS_DTR.prt`.

### DKA_IARPAFAC_PKG

Points d?entr?e / ?tapes : `run_import` (`dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb:4073`); `run_recyclage_rejections` (`dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb:4227`); `main` (`dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb:4405`).

Cibles INSERT rep?r?es : `ra_interface_distributions_all` (`dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb:645`); `dka_iarpafac_prelev_tmp` (`dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb:1478`); `ra_interface_lines_all` (`dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb:1521`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IARPAFAC.ldt`, `dka/12.0.0/admin/import/DKA_IARPAFAC.prt`.

### DKA_IARRECSICM_MEN_PKG

Points d?entr?e / ?tapes : `extraction_encours` (`dka/12.0.0/admin/sql/DKA_IARRECSICM_MEN_PKG.pkb:188`).

Cibles INSERT rep?r?es : `dka_iarrecsicm_encours_client` (`dka/12.0.0/admin/sql/DKA_IARRECSICM_MEN_PKG.pkb:1313`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IARRECSICM_MEN_JOB.sh`, `dka/12.0.0/sql/DKA_IARRECSICM_MEN.sql`.

### DKA_IARRECSICM_PKG

Points d?entr?e / ?tapes : `extraction_encours` (`dka/12.0.0/admin/sql/DKA_IARRECSICM_PKG.pkb:186`).

Cibles INSERT rep?r?es : `dka_iarrecsicm_encours_client` (`dka/12.0.0/admin/sql/DKA_IARRECSICM_PKG.pkb:1283`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IARRECSICM_JOB.sh`, `dka/12.0.0/sql/DKA_IARRECSICM.sql`.

### DKA_ICE_BANKBRANCHES_DTR_PKG

Points d?entr?e / ?tapes : `p_validate` (`dka/12.0.0/admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb:58`); `p_extract_data` (`dka/12.0.0/admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb:115`); `p_bilan` (`dka/12.0.0/admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb:285`); `main` (`dka/12.0.0/admin/sql/DKA_ICE_BANKBRANCHES_DTR_PKG.pkb:322`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_ICE_BANKBRANCHES_DTR_JOB.sh`, `dka/12.0.0/sql/DKA_ICE_BANKBRANCHES_DTR.sql`, `dka/12.0.0/admin/import/DKA_ICE_BANKBRANCHES_DTR.prt`.

### DKA_ICLIENTIFS_PKG

Points d?entr?e / ?tapes : `Launch_OI` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:1822`); `post_OI` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:2339`); `pre_import_client` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:2914`).

Cibles INSERT rep?r?es : `ra_customers_interface_all` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:411`); `ra_customer_profiles_int_all` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:598`); `dka_iclientifs_interface` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:2044`); `dka.dka_iclientifs_interface` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:3182`); `dka_iclientifs_collectors` (`dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb:3237`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_ICLIENTIFS.dpt`, `dka/12.0.0/admin/import/DKA_ICLIENTIFS.ldt`.

### DKA_ICODEPROJET_PKG

Points d?entr?e / ?tapes : `validate_centre_finance` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:307`); `bilan_cf` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:1199`); `validate_project` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:1473`); `bilan_projet` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:4477`); `main2` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:5672`).

Cibles INSERT rep?r?es : `pa_class_codes` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:1588`); `pa_transaction_controls` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:1978`); `dka_eai_organisation_hist` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:4321`); `dka_eai_tache_hist` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:4353`); `dka_eai_projet_hist` (`dka/12.0.0/admin/sql/DKA_ICODEPROJET_PKG.pkb:4403`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_ICODEPROJET.dpt`.

### DKA_IDECLIC_PKG

Points d?entr?e / ?tapes : `extract_i00rc` (`dka/12.0.0/admin/sql/DKA_IDECLIC_PKG.pkb:309`); `main` (`dka/12.0.0/admin/sql/DKA_IDECLIC_PKG.pkb:1135`).

Cibles INSERT rep?r?es : `dka_i00rc` (`dka/12.0.0/admin/sql/DKA_IDECLIC_PKG.pkb:828`); `dka_i00eh` (`dka/12.0.0/admin/sql/DKA_IDECLIC_PKG.pkb:1095`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IDECLIC_JOB.sh`, `dka/12.0.0/sql/DKA_IDECLIC.sql`, `dka/12.0.0/admin/import/DKA_IDECLIC.prt`.

### DKA_IEOAPSAT01_APIMP_PKG

Points d?entr?e / ?tapes : `create_ap_import_file` (`dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pkb:453`); `main` (`dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pkb:751`).

Cibles INSERT rep?r?es : `DKA_IEOAPSAT01_APIMP_HDR` (`dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pkb:1515`); `DKA_IEOAPSAT01_APIMP_LINE` (`dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pkb:1706`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IEOAPSAT01_APIMP_JOB.sh`, `dka/12.0.0/sql/DKA_IEOAPSAT01_APIMP.sql`, `dka/12.0.0/admin/import/DKA_IEOAPSAT01_APIMP.prt`.

### DKA_IEOARCRM01_PKG

Points d?entr?e / ?tapes : `validate` (`dka/12.0.0/admin/sql/DKA_IEOARCRM01_PKG.pkb:54`); `Extract_CSV` (`dka/12.0.0/admin/sql/DKA_IEOARCRM01_PKG.pkb:272`); `main` (`dka/12.0.0/admin/sql/DKA_IEOARCRM01_PKG.pkb:880`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IEOARCRM01_JOB.sh`, `dka/12.0.0/sql/DKA_IEOARCRM01.sql`, `dka/12.0.0/admin/import/DKA_IEOARCRM01.dpt`, `dka/12.0.0/admin/import/DKA_IEOARCRM01.prt`.

### DKA_IEOGLETF01_PKG

Points d?entr?e / ?tapes : `extraction_altaven` (`dka/12.0.0/admin/sql/DKA_IEOGLETF01_PKG.pkb:236`); `main` (`dka/12.0.0/admin/sql/DKA_IEOGLETF01_PKG.pkb:318`).

Cibles INSERT rep?r?es : `dka_ieogletf01_int` (`dka/12.0.0/admin/sql/DKA_IEOGLETF01_PKG.pkb:245`).

### DKA_IEOGLVEC01_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IEOGLVEC01_PKG.pkb:2077`).

Cibles INSERT rep?r?es : `dka_ieoglvec01_int` (`dka/12.0.0/admin/sql/DKA_IEOGLVEC01_PKG.pkb:1147`).

### DKA_IEOMTL_CODARTINT_PKG

Points d?entr?e / ?tapes : `MAIN` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:5776`); `bilan` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:6109`).

Cibles INSERT rep?r?es : `dka_ieomtl_system_items_tmp` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:643`); `dka_ieomtl_error` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:1341`); `mtl_item_categories_interface` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:3395`); `fnd_flex_values` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:3979`); `fnd_flex_values_tl` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:4008`); `fnd_flex_value_norm_hierarchy` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:4319`); `dka_ieomtl_compl_tech` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:4725`); `mtl_system_items_interface` (`dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb:4928`).

### DKA_IEOMTL_PURGRECH_PKG

Points d?entr?e / ?tapes : `MAIN` (`dka/12.0.0/admin/sql/DKA_IEOMTL_PURGRECH_PKG.pkb:95`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

### DKA_IFA_FLUXCM_PKG

Points d?entr?e / ?tapes : `Main` (`dka/12.0.0/admin/sql/DKA_IFA_FLUXCM_PKG.pkb:565`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IFA_FLUXCM_JOB.sh`, `dka/12.0.0/sql/DKA_IFA_FLUXCM.sql`, `dka/12.0.0/admin/import/DKA_IFA_FLUXCM.prt`.

### DKA_IGL_INTERFACE_EAI_PKG

Points d?entr?e / ?tapes : `run_import` (`dka/12.0.0/admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb:178`); `main` (`dka/12.0.0/admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb:336`).

Cibles INSERT rep?r?es : `gl_interface_control` (`dka/12.0.0/admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb:134`); `DKA_IGL_INTERFACE_EAI` (`dka/12.0.0/admin/sql/DKA_IGL_INTERFACE_EAI_PKG.pkb:462`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IGL_INTERFACE_EAI_JOB.sh`, `dka/12.0.0/sql/DKA_IGL_INTERFACE_EAI.sql`, `dka/12.0.0/admin/import/DKA_IGL_INTERFACE_EAI.dpt`, `dka/12.0.0/admin/import/DKA_IGL_INTERFACE_EAI.prt`.

### DKA_IGLHYPERIONDR_PKG

Points d?entr?e / ?tapes : `p_validate` (`dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:67`); `f_get_period_to_extract` (`dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:204`); `p_extract_data` (`dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:333`); `p_extract_data_qte` (`dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:501`); `p_bilan` (`dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:679`); `main` (`dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:730`); `main_qte` (`dka/12.0.0/admin/sql/DKA_IGLHYPERIONDR_PKG.pkb:818`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IGLHYPERIONDR_JOB.sh`, `dka/12.0.0/sql/DKA_IGLHYPERIONDR.sql`.

### DKA_IHREMP_GXP_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IHREMP_GXP_PKG.pkb:6965`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IHREMP_GXP_JOB.sh`, `dka/12.0.0/sql/DKA_IHREMP_GXP.sql`, `dka/12.0.0/admin/import/DKA_IHREMP_GXP.prt`.

### DKA_IHREMP_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IHREMP_PKG.pkb:8624`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IHREMP_JOB.sh`, `dka/12.0.0/sql/DKA_IHREMP.sql`, `dka/12.0.0/admin/import/DKA_IHREMP.dpt`, `dka/12.0.0/admin/import/DKA_IHREMP.prt`.

### DKA_IMPTRECPO_PKG

Points d?entr?e / ?tapes : `validate_data` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:591`); `import_data` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:1165`); `Launch_OI` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:1631`); `Report_Bilan` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:1934`); `set_recovery_mode` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:2002`); `main` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:2211`).

Cibles INSERT rep?r?es : `dka_program_messages` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:293`); `rcv_headers_interface` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:1238`); `rcv_transactions_interface` (`dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB:1298`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IMPTRECPO.dpt`, `dka/12.0.0/admin/import/DKA_IMPTRECPO.prt`.

### DKA_IPO_SSTR_IVALUA_PKG

Points d?entr?e / ?tapes : `LANCE_CHARGEMENT_FICHIER` (`dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:309`); `VALIDATION_DONNEES` (`dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:642`); `IMPORT_DONNEES` (`dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:887`); `MAIN` (`dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:1127`).

Cibles INSERT rep?r?es : `DKA_IPOCTR_SSTR_IVALUA_REPORT` (`dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:201`); `DKA_IPOCTR_SSTR_IVALUA_HIST` (`dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:249`); `DKA_SPO_CONTRAT_SSTR_IVALUA` (`dka/12.0.0/admin/sql/DKA_IPO_SSTR_IVALUA_PKG.pkb:934`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IPO_SSTR_IVALUA.prt`.

### DKA_IPOCDE_IVALUA_PKG

Points d?entr?e / ?tapes : `LANCE_CHARGEMENT_FICHIER` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:610`); `VALIDATION_DONNEES` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:1352`); `IMPORT_DONNEES` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:3460`); `CONTROLE_IMPORT_CMD` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:5482`); `MAIN` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:5902`).

Cibles INSERT rep?r?es : `PO_HEADERS_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:3540`); `PO_LINES_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:3617`); `PO_DISTRIBUTIONS_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:3683`); `po_action_history` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:4951`); `fnd_documents_tl` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:5638`); `fnd_documents` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:5660`); `fnd_attached_documents` (`dka/12.0.0/admin/sql/DKA_IPOCDE_IVALUA_PKG.pkb:5690`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IPOCDE_IVALUA.prt`, `dka/12.0.0/admin/import/DKA_IPOCDE_IVALUA_LOADER.prt`.

### DKA_IPOEXTENGHERC_PKG

Points d?entr?e / ?tapes : `p_validate` (`dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:80`); `p_extract_data_cmd` (`dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:147`); `p_extract_data_inv` (`dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:491`); `p_extract_data_maind` (`dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:773`); `p_extract_data_refac` (`dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:934`); `main` (`dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:1161`); `bilan` (`dka/12.0.0/admin/sql/DKA_IPOEXTENGHERC_PKG.pkb:1244`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IPOEXTENGHERC_JOB.sh`, `dka/12.0.0/sql/DKA_IPOEXTENGHERC.sql`, `dka/12.0.0/admin/import/DKA_IPOEXTENGHERC.dpt`.

### DKA_IPOEXTRACTCDE_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IPOEXTRACTCDE_PKG.pkb:254`).

Cibles INSERT rep?r?es : `DKA_IPOEXTRACTCDE_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IPOEXTRACTCDE_PKG.pkb:278`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IPOEXTRACTCDE_JOB.sh`, `dka/12.0.0/sql/DKA_IPOEXTRACTCDE.sql`, `dka/12.0.0/admin/import/DKA_IPOEXTRACTCDE.prt`.

### DKA_IPOEXTSOLDHERC_PKG

Points d?entr?e / ?tapes : `p_validate` (`dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:74`); `p_extract_data` (`dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:137`); `p_extract_data_type_p3` (`dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:526`); `p_extract_data_type_p6` (`dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:644`); `main` (`dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:818`); `bilan` (`dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:890`).

Cibles INSERT rep?r?es : `DKA_IPOEXTSOLDHERC` (`dka/12.0.0/admin/sql/DKA_IPOEXTSOLDHERC_PKG.pkb:278`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IPOEXTSOLDHERC_JOB.sh`, `dka/12.0.0/sql/DKA_IPOEXTSOLDHERC.sql`.

### DKA_IPOFRS_IVALUA_PKG

Points d?entr?e / ?tapes : `Report_Bilan` (`dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb:370`); `validate_data` (`dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb:743`); `import_data` (`dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb:2466`); `MAIN` (`dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb:3995`).

Cibles INSERT rep?r?es : `dka_program_messages` (`dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb:698`); `DKA_SAPFRSDUPLI_MASSE_TMP` (`dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb:3880`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IPOFRS_IVALUA.prt`, `dka/12.0.0/admin/import/DKA_IPOFRS_IVALUA_LOADER.prt`.

### DKA_IPOFRS_REP_IVALUA_PKG

Points d?entr?e / ?tapes : `LANCE_CHARGEMENT_FICHIER` (`dka/12.0.0/admin/sql/DKA_IPOFRS_REP_IVALUA_PKG.pkb:223`); `BILAN` (`dka/12.0.0/admin/sql/DKA_IPOFRS_REP_IVALUA_PKG.pkb:756`); `MAIN` (`dka/12.0.0/admin/sql/DKA_IPOFRS_REP_IVALUA_PKG.pkb:940`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

### DKA_IPOGENCOM_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb:1770`).

Cibles INSERT rep?r?es : `po_headers_interface` (`dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb:550`); `po_lines_interface` (`dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb:672`); `po_distributions_interface` (`dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb:766`); `po_line_locations_all` (`dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb:1333`); `po_distributions_all` (`dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb:1567`); `PO_ACTION_HISTORY` (`dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb:1706`).

### DKA_IPOHYPERION_PKG

Points d?entr?e / ?tapes : `p_validate` (`dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb:104`); `p_extract_data` (`dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb:212`); `p_extract_detail_sstr` (`dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb:645`); `p_bilan` (`dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb:1667`); `p_bilan_detail_sstr` (`dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb:1717`); `main` (`dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb:1754`); `main_detail_sstr` (`dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb:1852`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_IPOHYPERION_JOB.sh`, `dka/12.0.0/sql/DKA_IPOHYPERION.sql`, `dka/12.0.0/admin/import/DKA_IPOHYPERION.prt`.

### DKA_IPORECEPTION_IVALUA_PKG

Points d?entr?e / ?tapes : `validate_data_group` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:605`); `validate_data` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:2638`); `import_data` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:2932`); `Launch_OI` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:3661`); `Report_Bilan` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:4232`); `main` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:4845`).

Cibles INSERT rep?r?es : `dka_program_messages` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:302`); `DKA.DKA_IPOREC_REJECT` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:1386`); `rcv_headers_interface` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:3120`); `rcv_transactions_interface` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:3176`); `DKA_IPOREC_HIST_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:4130`); `DKA_IPOREC_REPORTING_INTERFACE` (`dka/12.0.0/admin/sql/DKA_IPORECEPTION_IVALUA_PKG.PKB:4155`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/admin/import/DKA_IPORECEPTION_IVALUA.prt`, `dka/12.0.0/admin/import/DKA_IPORECEPTION_IVALUA_LOADER.prt`.

### DKA_IPORECVTOTAL_PKG

Points d?entr?e / ?tapes : `main` (`dka/12.0.0/admin/sql/DKA_IPORECVTOTAL_PKG.pkb:1239`).

Cibles INSERT rep?r?es : `rcv_headers_interface` (`dka/12.0.0/admin/sql/DKA_IPORECVTOTAL_PKG.pkb:87`); `rcv_transactions_interface` (`dka/12.0.0/admin/sql/DKA_IPORECVTOTAL_PKG.pkb:160`).

### DKA_OPEN_INTERFACE_AP_EAI_PKG

Points d?entr?e / ?tapes : `run_import` (`dka/12.0.0/admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb:111`); `main` (`dka/12.0.0/admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb:259`).

Cibles INSERT rep?r?es : `DKA_OPEN_INTERFACE_AP_EAI` (`dka/12.0.0/admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb:463`); `ap_interface_rejections` (`dka/12.0.0/admin/sql/DKA_OPEN_INTERFACE_AP_EAI_PKG.pkb:679`).

Artefacts associ?s par pr?fixe (? confirmer avec les appels) : `dka/12.0.0/bin/DKA_OPEN_INTERFACE_AP_EAI_JOB.sh`, `dka/12.0.0/sql/DKA_OPEN_INTERFACE_AP_EAI.sql`, `dka/12.0.0/admin/import/DKA_OPEN_INTERFACE_AP_EAI.prt`.

### XXEAI_INTERFACE_TOOLS_PKG

Points d?entr?e / ?tapes : `validate` (`dka/12.0.0/admin/sql/XXEAI_INTERFACE_TOOLS_PKG.pkb:121`).

Cibles INSERT rep?r?es : aucune cible simple rep?r?e ; examiner les curseurs, UPDATE et appels API.

## 12. Contrats de chargement et orchestrateurs compl?mentaires

Les fichiers ci-dessous appartiennent au m?me p?rim?tre par pr?fixe. Ils sont inventori?s m?me lorsqu?ils ne correspondent pas directement ? un nom de package ; leur contenu doit ?tre pris en compte pour le d?ploiement.

| Artefact | Contrat / appel rep?r? dans le contenu |
|---|---|
| `DKA_IAPFAC_DEBLOC_INTERFACE.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IAPFAC_DEBLOC_INTERFACE.ctl:19`) ; `INTO TABLE DKA_IAPFAC_DEBLOC_INTERFACE FIELDS TERMINATED BY '/'    TRAILING NULLCOLS(` (`dka/12.0.0/bin/DKA_IAPFAC_DEBLOC_INTERFACE.ctl:20`) |
| `DKA_IAPFACDSP.ctl` | `TRUNCATE` (`dka/12.0.0/bin/DKA_IAPFACDSP.ctl:23`) ; `INTO TABLE DKA.DKA_IAPFACDSP_TMP` (`dka/12.0.0/bin/DKA_IAPFACDSP.ctl:24`) ; `fields terminated by ";"` (`dka/12.0.0/bin/DKA_IAPFACDSP.ctl:25`) |
| `DKA_IAPFACXGS.ctl` | `TRUNCATE` (`dka/12.0.0/bin/DKA_IAPFACXGS.ctl:23`) ; `INTO TABLE DKA.DKA_IAPFACXGS_TMP` (`dka/12.0.0/bin/DKA_IAPFACXGS.ctl:24`) ; `fields terminated by ";"` (`dka/12.0.0/bin/DKA_IAPFACXGS.ctl:25`) |
| `DKA_IAPFACZCI.ctl` | `TRUNCATE` (`dka/12.0.0/bin/DKA_IAPFACZCI.ctl:23`) ; `INTO TABLE DKA.DKA_IAPFACZCI_TMP` (`dka/12.0.0/bin/DKA_IAPFACZCI.ctl:24`) ; `fields terminated by ";"` (`dka/12.0.0/bin/DKA_IAPFACZCI.ctl:25`) |
| `DKA_IEOGLVEC01_LOAD_FLEX_ATTR.ctl` | `INTO TABLE DKA_IEOGLVEC01_LOAD_FLEX_ATTR` (`dka/12.0.0/bin/DKA_IEOGLVEC01_LOAD_FLEX_ATTR.ctl:3`) ; `fields terminated by ";"` (`dka/12.0.0/bin/DKA_IEOGLVEC01_LOAD_FLEX_ATTR.ctl:4`) |
| `DKA_IEOGLVEC01_LOAD_FLEX_VALUE.ctl` | `INTO TABLE dka_ieoglvec01_load_flex_value` (`dka/12.0.0/bin/DKA_IEOGLVEC01_LOAD_FLEX_VALUE.ctl:3`) ; `fields terminated by ";"` (`dka/12.0.0/bin/DKA_IEOGLVEC01_LOAD_FLEX_VALUE.ctl:4`) |
| `DKA_IPOCDE_IVALUA_LOADER_HEAD.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_HEAD.ctl:23`) ; `INTO TABLE DKA_IPOCDE_HEADERS` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_HEAD.ctl:24`) ; `FIELDS TERMINATED BY '/'` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_HEAD.ctl:25`) ; `INTO TABLE DKA_IPOCDE_REPORTING_HEADERS` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_HEAD.ctl:52`) ; `FIELDS TERMINATED BY '/'` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_HEAD.ctl:53`) |
| `DKA_IPOCDE_IVALUA_LOADER_LINES.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_LINES.ctl:23`) ; `INTO TABLE DKA_IPOCDE_LINES` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_LINES.ctl:24`) ; `FIELDS TERMINATED BY '/'` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_LINES.ctl:25`) ; `INTO TABLE DKA_IPOCDE_HIST_LINES` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_LINES.ctl:59`) ; `FIELDS TERMINATED BY '/'` (`dka/12.0.0/bin/DKA_IPOCDE_IVALUA_LOADER_LINES.ctl:60`) |
| `DKA_IPOCTR_SSTR_IVALUA_LOADER.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOCTR_SSTR_IVALUA_LOADER.ctl:23`) ; `INTO TABLE DKA_IPOCTR_SSTR_IVALUA` (`dka/12.0.0/bin/DKA_IPOCTR_SSTR_IVALUA_LOADER.ctl:24`) ; `FIELDS TERMINATED BY '/'` (`dka/12.0.0/bin/DKA_IPOCTR_SSTR_IVALUA_LOADER.ctl:25`) |
| `DKA_IPOFRS_ENETETES.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOFRS_ENETETES.ctl:20`) ; `INTO TABLE DKA_IPOFRS_ENTETES` (`dka/12.0.0/bin/DKA_IPOFRS_ENETETES.ctl:21`) ; `FIELDS TERMINATED BY "/"` (`dka/12.0.0/bin/DKA_IPOFRS_ENETETES.ctl:22`) ; `INTO TABLE DKA_IPOFRS_REPORTING_ENTETES` (`dka/12.0.0/bin/DKA_IPOFRS_ENETETES.ctl:54`) ; `FIELDS TERMINATED BY '/'` (`dka/12.0.0/bin/DKA_IPOFRS_ENETETES.ctl:55`) |
| `DKA_IPOFRS_HOMOLOGATIONS.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOFRS_HOMOLOGATIONS.ctl:20`) ; `INTO TABLE DKA_IPOFRS_HOMOLOGATIONS` (`dka/12.0.0/bin/DKA_IPOFRS_HOMOLOGATIONS.ctl:21`) ; `FIELDS TERMINATED BY "/"` (`dka/12.0.0/bin/DKA_IPOFRS_HOMOLOGATIONS.ctl:22`) ; `INTO TABLE DKA_IPOFRS_REPORTING_HOMOLOG` (`dka/12.0.0/bin/DKA_IPOFRS_HOMOLOGATIONS.ctl:41`) ; `FIELDS TERMINATED BY "/"` (`dka/12.0.0/bin/DKA_IPOFRS_HOMOLOGATIONS.ctl:42`) |
| `DKA_IPOFRS_LIGNES.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOFRS_LIGNES.ctl:20`) ; `INTO TABLE DKA_IPOFRS_LIGNES` (`dka/12.0.0/bin/DKA_IPOFRS_LIGNES.ctl:21`) ; `FIELDS TERMINATED BY "/"` (`dka/12.0.0/bin/DKA_IPOFRS_LIGNES.ctl:22`) ; `INTO TABLE DKA_IPOFRS_REPORTING_LIGNES` (`dka/12.0.0/bin/DKA_IPOFRS_LIGNES.ctl:59`) ; `FIELDS TERMINATED BY "/"` (`dka/12.0.0/bin/DKA_IPOFRS_LIGNES.ctl:60`) |
| `DKA_IPOFRS_REP_IVALUA_LOADER_TAB.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOFRS_REP_IVALUA_LOADER_TAB.ctl:23`) ; `INTO TABLE DKA_IPOFRS_MAJ_SITES_REPRIS` (`dka/12.0.0/bin/DKA_IPOFRS_REP_IVALUA_LOADER_TAB.ctl:24`) ; `FIELDS TERMINATED BY '/'` (`dka/12.0.0/bin/DKA_IPOFRS_REP_IVALUA_LOADER_TAB.ctl:25`) |
| `DKA_IPOREC_INTERFACE.ctl` | `APPEND` (`dka/12.0.0/bin/DKA_IPOREC_INTERFACE.ctl:19`) ; `INTO TABLE DKA_IPOREC_INTERFACE FIELDS TERMINATED BY '/'    TRAILING NULLCOLS(` (`dka/12.0.0/bin/DKA_IPOREC_INTERFACE.ctl:20`) |
