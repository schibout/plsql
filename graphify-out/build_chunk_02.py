import json,re,pathlib,hashlib,collections
root=pathlib.Path('C:/Projects/plsql'); files=json.loads((root/'graphify-out/perimetre_2.json').read_text(encoding='utf-8-sig'))
def norm(x): return re.sub('[^a-z0-9]+','_',x.lower()).strip('_')
nodes=[];edges=[]; inv=[]
for f in files:
 p=root/f; txt=p.read_text(encoding='utf-8-sig',errors='replace'); lines=txt.splitlines(); stem=norm((p.parent.name+'_' if '/' in f else '')+p.stem); fid=stem+'_fichier'
 nodes.append(dict(id=fid,label=f,file_type='code' if p.suffix.lower()=='.sql' else 'document',source_file=f,source_location='1',source_url=None,captured_at=None,author=None,contributor=None))
 refs={}; inblock=False
 for n,line in enumerate(lines,1):
  code=line
  if inblock:
   if '*/' not in code: continue
   code=code.split('*/',1)[1];inblock=False
  while '/*' in code:
   a,b=code.split('/*',1)
   if '*/' in b: code=a+' '+b.split('*/',1)[1]
   else: code=a;inblock=True;break
  code=code.split('--',1)[0]
  # Pure lexical SQL object references. CTEs may also appear; graph is explicitly documentary.
  for m in re.finditer(r'\b(?:FROM|JOIN|UPDATE|INSERT\s+INTO|DELETE\s+FROM)\s+([A-Za-z][A-Za-z0-9_$#]*(?:\.[A-Za-z][A-Za-z0-9_$#]*)?)',code,re.I):
   obj=m.group(1).upper()
   if obj in ('DUAL','SELECT','SET','TABLE','THE','A','ALL','DATE','NO','GL_DATE'):continue
   refs.setdefault(obj,n)
 for obj,n in refs.items():
  oid=stem+'_'+norm(obj)
  nodes.append(dict(id=oid,label=obj,file_type='concept',source_file=f,source_location=str(n),source_url=None,captured_at=None,author=None,contributor=None))
  edges.append(dict(source=fid,target=oid,relation='references',confidence='EXTRACTED',confidence_score=1.0,source_file=f,source_location=str(n),weight=1.0))
 s=f.lower()
 if any(x in s for x in ['datefin','ajout_de','verification_user','responable_hierachique']):cat='RH / habilitations / workflow (connexe pour BAP)'
 elif any(x in s for x in ['facturelitige','csp_onglet']):cat='Litiges / référentiel / pièces'
 elif any(x in s for x in ['dtr-bo','cloture_cap','sstr','jira','cloture2026']):cat='Clôture / provisions / cut-off'
 elif any(x in s for x in ['fournisseur','fermeture','annuler']):cat='Référentiel fournisseur / commandes'
 elif any(x in s for x in ['prelev','virement','releve']):cat='Paiements / banque / collecte de rapports'
 elif any(x in s for x in ['pytest','github','odat','ctm','control','appinit','index_contrainte','get_','categories','refresh']):cat='Support technique / orchestration / autre domaine'
 else:cat='Facturation / GL-PA / diagnostic à contextualiser'
 inv.append(dict(fichier=f,lignes=len(lines),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),classement=cat,objets=[{'objet':o,'ligne':n} for o,n in refs.items()]))
(root/'graphify-out/.graphify_chunk_02.json').write_text(json.dumps(dict(nodes=nodes,edges=edges,hyperedges=[],input_tokens=0,output_tokens=0),ensure_ascii=False,indent=2),encoding='utf-8')
(root/'graphify-out/couverture_02.json').write_text(json.dumps(inv,ensure_ascii=False,indent=2),encoding='utf-8')
header='''# Comptabilité, référentiels et périmètre connexe de la facturation

## Portée et niveau de preuve

Analyse statique des 103 SQL et README énumérés dans `graphify-out/perimetre_2.json`. Tous les contenus ont été lus par un traitement intégral (inventaire, lignes, empreinte, références lexicales) ; revue sémantique approfondie des flux pertinents, revue de classement des scripts connexes. Les très grands packages RH et workflow ne font pas l'objet d'une certification exhaustive de leur comportement. Le détail par fichier figure ci-dessous et dans `graphify-out/couverture_02.json`. Aucun SQL exécuté, aucune base consultée, aucun correctif appliqué.

**Preuve** désigne ici une instruction ou une déclaration présente dans le dépôt, pas un résultat constaté en production. Les résultats, performances et causes annoncés dans les README restent des déclarations documentaires. **Hypothèse / à confirmer** signale une interprétation ou une vérification restant nécessaire. Les variantes et archives ne constituent pas autant de flux distincts ni une preuve de déploiement.

## Chaîne comptable et analytique observée

La facture fournisseur s'articule autour de `AP_INVOICES_ALL` (en-tête), `AP_INVOICE_LINES_ALL` (ligne), `AP_INVOICE_DISTRIBUTIONS_ALL` (imputation), puis `AP_PAYMENT_SCHEDULES_ALL` (échéance). Fournisseur et site relèvent de `AP_SUPPLIERS` et `AP_SUPPLIER_SITES_ALL` ; l'unité opérationnelle est portée par `ORG_ID`. La documentation racine décrit distributions, codes comptables, règlements et annulations de paiement (`README.md:34`, `README.md:57`, `README.md:64`). Elle renvoie à un script précis ; cette description ne suffit pas à valider toutes les requêtes du dépôt.

Les requêtes de provisions matérialisent le chemin GL → XLA → réception → distribution PO : journal/en-tête/lot (`GL_JE_LINES`, `GL_JE_HEADERS`, `GL_JE_BATCHES`), `XLA_AE_LINES` reliées par `GL_SL_LINK_ID`, puis `XLA_DISTRIBUTION_LINKS`. Quand le lien GL est absent, `GL_IMPORT_REFERENCES` fournit l'étape intermédiaire. Les deux branches sont séparées par `GL_SL_LINK_ID IS [NOT] NULL` : `cloture_Cap/CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql:8`, `:30`, `:46`, `:67`.

Dans CAP V4, la référence source XLA rejoint `RCV_RECEIVING_SUB_LEDGER.RCV_SUB_LEDGER_ID` sous `APPLICATION_ID=707` et type `RCV_RECEIVING_SUB_LEDGER`, puis `REFERENCE3` rejoint `PO_DISTRIBUTIONS_ALL.PO_DISTRIBUTION_ID` (`cloture_Cap/CAP_DTR_PROVISIONS_GL_PO_HELIOS_V4.sql:21`). Le rattachement projet/tâche s'effectue ensuite depuis la distribution PO vers `PA_PROJECTS_ALL` et `PA_TASKS` (`SSTR/SQL_Provision_OCT-25.sql:168`, `:178`). La liste des commandes rejetées relie explicitement `DKA_SPOCHARGE_ERRORS` à la distribution, la tâche, la commande et le fournisseur (`cloture_Cap/CAP_COMMANDES_REJ.sql:24`). C'est un point de rapprochement charge/provision/facture, pas une preuve d'intégration réussie.

### Divergence critique sur les clés de réception

Le README DTR-BO déclare la disparition de `APPLIED_TO_DIST_ID_NUM_1` en NOV-25 et propose une jonction directe de `SOURCE_DISTRIBUTION_ID_NUM_1` à `RCV_TRANSACTIONS.TRANSACTION_ID` (`DTR-BO/README_Changement_APPLIED_TO_NOV25.md:13`, `:39`). La requête « compatible » reproduit ce chemin et impose une transaction de réception non nulle (`DTR-BO/Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql:58`, `:78`). Le chemin CAP V4 décrit plus haut utilise une clé de sous-livre de réception distincte. Le dépôt comporte donc des interprétations concurrentes de la même référence source.

**À confirmer avant réutilisation :** type réel de distribution, clé source, correspondance sous-livre/transaction, taux de rattachement PO et sommes débit/crédit par période. Le filtre `RT.TRANSACTION_ID IS NOT NULL` peut exclure un ancien enregistrement dont seul `APPLIED_TO_DIST_ID_NUM_1` est renseigné malgré le `COALESCE`. Le libellé « compatible » n'est donc pas une garantie. L'attribution documentaire à un patch Oracle (`...compatible_OCT_NOV.sql:184`) ne démontre pas la cause générale ; aucun accès production n'a été réalisé.

## Cut-off SSTR, factures et granularité

La variante V4 construit `INVOICE_DETAILS` à la granularité distribution PO + numéro/date de facture, avec sommes séparées sur `POSTED_FLAG`, et exclusion de `PREPAY`, `REC_TAX`, `NONREC_TAX` (`JiraKDFI3809/SSTR_Od_Cut_Off_détail_factures_V4.sql:2`). Le lien final porte sur `PO_DISTRIBUTION_ID` (`:120`). C'est plus traçable qu'un seul numéro de commande, mais une distribution portant plusieurs factures produit plusieurs lignes : sommer ensuite le montant GL répété sur ces lignes gonflerait le cut-off. Un contrôle distinct du montant provisionné et des montants facturés est nécessaire.

Cette extraction sélectionne le ledger primaire, une période codée en dur `JUN-26`, la source `Purchasing` et des noms d'OD à contrepassation définis par expression régulière (`...V4.sql:121`). Les V3 et V4 sont des variantes locales de reporting ; ne pas cumuler leurs résultats. Les contrats proviennent notamment de `DKA_CONTRAT_SSTR_ARCHI`, `DKA_SPO_CONTRAT_SSTR_IVALUA` et `DKA_CONTRAT_SSTR` (`cloture_Cap/CAP_OD_Cut_Off_SSTR_factures_V3.sql:27`, `:64`, `:280`). Leurs versions et dates de validité doivent entrer dans le dossier de mapping.

## Référentiel fournisseur et paiement

Le référentiel joint fournisseur/site à `HZ_PARTIES`, `HZ_PARTY_SITES`, aux structures d'organisation et aux objets IBY. La variante optimisée reste une extraction, pas le mécanisme maître de synchronisation (`FactureLitige/Referentiel_Fournisseur_OPTIMISEE.sql:154`). Le fichier `MiseaJourFournisseurs/Detail_algorithme_maj_sites_fournisseurs.sql` est principalement une **description d'algorithme**, avec exemples et propositions : il déclare un traitement incrémental par `LAST_UPDATE_DATE`, un watermark `DKA_PARAMETERS`, et un appel `DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR` (`:39`, `:69`, `:150`). Il cite les API de mise à jour du site et du compte bancaire (`:180`), ainsi que la table d'erreurs `DKA_SAPFRSDUPLI_ERROR_TMP` (`:185`). Ces déclarations nécessitent confirmation dans le package exécuté.

Le watermark est décrit comme la date de lancement, issue de `FND_CONCURRENT_REQUESTS.REQUESTED_START_DATE` (`...Detail_algorithme...sql:243`). **Risque à instruire :** avance du watermark alors que certains sites sont en erreur, changements simultanés pendant le traitement, multiplicité des instruments bancaires, et cohérence entre transactions et table d'erreurs. Ajouter des commits intermédiaires sur la seule foi d'une recommandation documentaire changerait l'atomicité du flux ; le dossier doit d'abord préciser l'unité de reprise.

L'identité de rapprochement doit conserver `VENDOR_ID`, `VENDOR_SITE_ID`, `ORG_ID`, bénéficiaire IBY, instrument et périodes de validité. Un numéro de fournisseur ou un code de site seul ne prouve pas l'unicité multi-organisation. Les fiches bancaires et données personnelles vues dans le dépôt ne sont pas recopiées dans l'analyse.

## Litiges, BAP et images

Le point d'entrée des exports de litiges est `AP_HOLDS_ALL`, filtré sur blocage non levé et code contenant `itige` ; les refus Ivalua proviennent de `AP_INV_APRVL_HIST_ALL`, réponse `DKA_REFUSE_IVALUA`, avec classement par date (`FactureLitige/SQL_Export_Gestion_Litiges_OPTIMISEE.sql:28`). Les échéances, fournisseurs, unité et compte GL enrichissent le résultat (`:253`). Le README précise qu'une facture avec plusieurs holds actifs conserve plusieurs lignes (`FactureLitige/README_Optimisation_SQL_Export_Gestion_Litiges.md:221`). **À confirmer :** granularité attendue facture/hold/échéance, sensibilité à la casse des codes, départage des événements à date égale et traitement des bénéficiaires globaux `ORG_ID IS NULL` (`:217`).

Le calcul documentaire du « solde fournisseur » agrège par `VENDOR_ID` (`...README_Optimisation...md:175`) : ce montant peut regrouper plusieurs organisations et devises. Il ne constitue pas un solde comptable exploitable sans préciser les axes et la conversion. Le flag « comptabilisé » fondé sur l'absence de distribution `POSTED_FLAG='N'` peut également masquer les cas sans distribution ou avec valeur nulle ; à rapprocher des statuts XLA/GL.

Les pièces jointes passent par `FND_ATTACHED_DOCUMENTS`, `FND_DOCUMENTS` et `FND_LOB_ACCESS`. Les générateurs d'URL produisent des données d'extraction ; ce ne sont pas de simples SELECT. Le générateur facture commence par supprimer le contenu d'`EXTRACTION_FACTURE` puis valider (`FactureLitige/DKA_GENERATE_URL_IMAGE_FACTURE_SOURCE.sql:25`). Il faut conserver le lien de pièce, sa durée de validité et les contrôles d'accès dans le contrat d'intégration. Le package `responable_hierachique/DKA_SAPWFCSP_PKG.sql` définit notamment initialisation OI/AP, poses de blocage et transfert OI → AP (`:295`, `:311`, `:379`, `:430`). Son lien avec la facturation est explicite ; son périmètre de 14 200 lignes exige une revue dédiée avant changement de routage.

## Reprises, corrections et clôture

`repousseGL/repouusse.sql` met à jour les dates comptables des lignes d'interface, la `GL_DATE` et le statut de l'en-tête, puis fait un `COMMIT` (`:88`, `:114`, `:137`). Une telle reprise modifie le rattachement de période : exiger périmètre source/lot, état avant/après, accord comptable et preuve de non-duplication avant toute exécution.

Les archives de fermeture PO réalisent des UPDATE directs d'en-têtes, lignes et échéanciers, parfois des distributions, avec commits (`fermetureCommandesPO/archive/fermeture_commandes_04122025.sql:77`, `:106`, `:114`). Les versions ne touchent pas toutes les mêmes niveaux ; elles ne constituent pas un mode opératoire générique de fermeture. Le script d'annulation ciblée, les contrôles de réceptions et factures doivent être réévalués pour chaque commande.

La correction GL `miseAjourGL/Update_GL_JE_LINES_ATTRIBUTE13_MO_HORS_THO.sql` annonce une simulation avec rollback, contrôle les absents et le nombre modifié avant validation conditionnelle (`:28`, `:158`). Conserver le mode effectivement activé dans toute fiche de reprise. Le groupe AR « doublons OpenInterface » comporte rapport et scripts de suppression enfants → erreurs → lignes avec possibilité de commit (`factureEndoubleTableStandrad/Suppression_Doublons_Execution.sql:113`, `:130`, `:156`) ; une erreur d'interface ne suffit pas à prouver un doublon métier. Ce volet relève de la facturation client, à séparer du circuit AP.

Les contrôles de clôture interrogent les requêtes concurrentes (`cloture2026/Controle_Cloture_Quotidien.sql:92`) ; ils donnent une visibilité de traitement, pas un contrôle de totalisation des factures. Les programmes, request IDs, paramètres, période, UO et sommes intégrées/rejetées doivent être reliés au même lot de factures.

## Banque, supervision et frontières du dossier

Les README de virements/prélèvements décrivent principalement collecte de mails et pièces vers Drive, idempotence et contrôle de rapports (`Projet_Virements/README.md:179`, `AppsScript/controlePrelevement/README.md:17`). Ils ne démontrent ni génération de paiement EBS ni exécution bancaire. L'incident relevés bancaires décrit une concurrence des chaînes Control-M 05/06 sur le même zip et un plan de reprise séquencé (`ControleReleveBancaire/README.md:12`, `:122`, `:159`). La causalité est celle du rapport fourni ; elle n'a pas été reproduite. Un défaut de relevé ne doit pas être interprété directement comme une facture non payée.

RH (`dateFinEmploye`, exports d'affectation/banque/personnes), désactivation utilisateurs, ajout de responsabilités et vérification de comptes relèvent de domaines connexes. Ils peuvent conditionner l'approbation ou le fournisseur salarié, mais leur inclusion complète dans l'intégration de facturation est une **hypothèse** à faire valider. Paie, catégories d'immobilisations, cache pytest, prompts, inventaire scheduler et rafraîchissement de vues restent du support ou d'autres domaines ; ne pas les convertir artificiellement en étapes de facturation. `lionelDtr/XXEAI.sql` expose des recherches de projets/tâches (`:536`, `:558`), utiles au mapping analytique, sans preuve qu'un flux de facture précis appelle ces routines.

## Éléments à reprendre dans le dossier d'intégration

1. Définir les contrats séparés AP, AR, PO/réception, GL/XLA, PA, référentiel et paiement : clés, cardinalités, organisation, devise, dates et sources maîtres.
2. Tracer un lot depuis le fichier et le contrôle EAI jusqu'à l'interface, la facture, les distributions, les rejets, la request concurrente et le journal comptable.
3. Arbitrer les chemins XLA/réception sur échantillons de périodes antérieures et récentes ; mesurer les non-rattachés et réconcilier les montants avant de choisir une variante SQL.
4. Définir la reprise par lot/transaction, ses statuts, son idempotence et son watermark ; distinguer simulation, correction validée, purge et réimport.
5. Tester les cardinalités avec plusieurs échéances, plusieurs holds, historique RH, plusieurs bénéficiaires IBY et plusieurs factures par distribution PO. Conserver des contrôles à la granularité des montants pour éviter les doubles sommes.
6. Documenter les interfaces réellement déployées et les preuves d'exploitation : README, SQL locaux et archives ne remplacent pas inventaire applicatif, package en production, logs et recette métier.

## Couverture fichier par fichier

Inventaire documentaire : références lexicales détectées, incluant potentiellement CTE ou exemples. Les classes ci-dessous servent au tri et ne certifient pas l'appartenance à un flux exécuté. Les empreintes et toutes les références/numéros de lignes sont dans `graphify-out/couverture_02.json`. Le fragment de graphe encode seulement « le fichier référence l'objet », sans déduire automatiquement appel, propriété ou flux réel.

| Fichier | Lignes | Classement | Premiers objets repérés |
|---|---:|---|---|
'''
rows=[]
for x in inv:
 refs=' ; '.join(o['objet']+':'+str(o['ligne']) for o in x['objets'][:4]) or 'Documentation / aucune référence SQL isolée'
 rows.append('| `'+x['fichier']+'` | '+str(x['lignes'])+' | '+x['classement']+' | '+refs+' |')
out=root/'analyse_integration_facturation/04_comptabilite_referentiels_et_perimetre.md';out.parent.mkdir(exist_ok=True);out.write_text(header+'\n'.join(rows)+'\n',encoding='utf-8')
print(json.dumps({'files':len(files),'lines':sum(x['lignes'] for x in inv),'nodes':len(nodes),'edges':len(edges),'report':str(out)},ensure_ascii=False))
