# Proposition — Préparer ma nuit

## Objectif

Choisir une date, même future, ou une plage de plusieurs nuits et obtenir un
**plan de production prévisionnel expliqué** : quels traitements sont attendus,
à quelles heures, combien de temps ils prennent habituellement, lesquels
surveiller et pourquoi. Suivre ensuite la nuit à partir des dernières données
importées et, pour une nuit passée, comparer la prévision au réalisé.

**Toutes les nuits applicatives sont concernées, hors clôture comme en clôture.**
Le calendrier de clôture enrichit le contexte ; il n'est pas une condition
pour préparer ou suivre une nuit. Le socle couvre les traitements quotidiens,
hebdomadaires, de week-end et les passages cycliques observables.

Le plan reste une estimation issue de l'historique. Une programmation confirmée
par Control-M, si elle devient disponible, doit être identifiée séparément.
La page ne déclenche aucun traitement.

## 1. Ce que les données permettent déjà

Constat en lecture seule de la base locale le 19 septembre 2026, après import :

| Donnée | Couverture constatée |
|---|---|
| Photos Control-M | 701 |
| Dates ODAT distinctes | 205, entre le 26 janvier et le 19 septembre 2026 |
| Jobs FIN-FINANCE distincts | 542 |
| Groupes FIN-FINANCE distincts | 148 |
| Juin / juillet / août | 30 / 31 / 31 dates ODAT |
| Septembre | 19 dates ODAT |
| CSV déposés dans ODAT/Report_CTM | 622 |

Les dates présentes ne garantissent pas que tous les événements de chaque nuit
soient visibles : il faut mesurer aussi la couverture des photos et des jobs.
Plusieurs photos d'un même traitement ne constituent pas plusieurs exécutions.

L'application dispose déjà de SQLite, Streamlit, des historiques, des profils
par job, d'une frise Plotly et des rapprochements avec les demandes Oracle.
Le fichier `Arborescence_Finance_Details.html` apporte une référence visuelle
ECharts avec dépliage, zoom et infobulles, mais présente des données figées.

Le moteur `forecast.py` est un point de départ : sa prévision repose surtout sur
les jours de semaine observés et une heure médiane. La fréquence est déduite du
suffixe du nom du job. Il ne modélise pas encore un calendrier de clôture ni les
différents passages des jobs cycliques. Son indicateur « fiabilité » est un taux
de réussite historique, pas une mesure de confiance dans la date prévue.

## 2. Disposition proposée

Une nouvelle entrée « Préparer ma nuit » dans ODAT Watch, avec une présentation
pleine largeur. « Ce soir » et « Demain » pourront devenir des raccourcis vers
cette page lorsque la nouvelle prévision aura été validée.

```text
 PRÉPARER MA NUIT                         Données disponibles jusqu'au …
 [Date ODAT] [Début : date + heure] [Fin : date + heure] [Prévoir]
 [Ce soir] [Demain] [7 nuits] [Prochaine clôture] [Calendrier métier]
 [Préparer] [Suivre la nuit] [Bilan]   [Toutes / Hors clôture / Clôture / Inconnu]

 Contexte : jour ouvré · clôture J+1 · Europe/Paris · prévision historique
 [Jobs attendus] [Chaînes] [Sensibles] [Échéances à risque] [Couverture]

 [Recherche] [Domaine] [Fréquence] [Confiance] [Sensibles uniquement]
 ┌────────────────────┬─────────────────────────┬────────────────────────┐
 │ ARBRE DES CHAÎNES   │ FRISE DE LA NUIT         │ DÉTAIL DE LA SÉLECTION │
 │                    │                         │                        │
 │ − Finance          │ 19h  22h  00h  03h  07h │ Import factures        │
 │   + Facturation    │ Chaîne A ━━━━━          │ Début et fin estimés   │
 │   − Comptabilité   │ Chaîne B     ━━━━━      │ Durée habituelle       │
 │     + Import GL    │ Job B1       ━━━        │ Pourquoi attendu ?     │
 │     + Clôture      │ Job B2          ━━      │ Historique comparable  │
 │   + Trésorerie     │                         │ Sensibilité, échéance  │
 └────────────────────┴─────────────────────────┴────────────────────────┘
 [À surveiller] [Les plus longs] [Nuits comparables] [Prévu / réalisé]
 [Ouvrir l'Assistant de nuit : questions guidées / conversation]
 [Exporter CSV] [Exporter la synthèse HTML]
```

Les familles métier Facturation / Comptabilité / Trésorerie sont une proposition
de classement à valider. Sans correspondance validée, afficher Application →
Groupe Control-M → Job, sans inventer d'affectation métier.

Sur un écran étroit : frise et arbre dans deux vues alternables, fiche du job
en dessous. Garder une table consultable au clavier pour toutes les informations
disponibles sur le graphique.

## 3. Parcours et interactions

### Préparer et suivre toutes les nuits applicatives

Conserver une seule page et les mêmes filtres, arbre et frise pour trois modes :

| Mode | Utilité | Informations principales |
|---|---|---|
| Préparer | Anticiper une nuit ordinaire ou de clôture | Occurrences attendues, horaires estimés, traitements longs ou sensibles et motifs |
| Suivre la nuit | Voir où en est la nuit sélectionnée selon les données disponibles | Derniers statuts observés, prévu/réalisé, erreurs, relances, retards possibles et fraîcheur |
| Bilan | Examiner une nuit passée, même hors clôture | Réussites/erreurs observées, écarts horaires, occurrences attendues non observées et couverture |

Le filtre de contexte vaut « Toutes » par défaut. « Hors clôture » sélectionne
les nuits sans jalon ni fenêtre de clôture applicable dans un calendrier validé
couvrant la période et le périmètre. Si cette couverture manque, afficher
« Contexte inconnu », et non « Hors clôture ». Les nuits de contexte inconnu
restent consultables et prévisibles avec les rythmes ordinaires ; aucune
obligation d'importer un calendrier Excel pour utiliser la page.

Pour les nuits ordinaires, comparer les mêmes jours de semaine et les types
de jours pertinents (ouvré, week-end, férié lorsque renseigné). Séparer les
observations de clôture identifiées pour ne pas attribuer leurs jobs spécifiques
à toutes les nuits. Le contexte de clôture s'applique par périmètre : une
clôture finance ne requalifie pas automatiquement les autres applications.

### Suivi de nuit et fraîcheur des données

- Afficher la date ODAT, les bornes de la nuit, l'heure de la dernière photo
  source et celle de son import. Un bouton « Actualiser » relit les données
  importées ; il ne signifie pas qu'une nouvelle interrogation Control-M a eu lieu.
- Indiquer « Suivi sur exports » : avec des photos espacées, ce n'est pas une
  supervision temps réel. Si aucune nouvelle photo ne couvre la période,
  signaler les données anciennes ou insuffisantes, sans prolonger un statut
  « En cours » comme s'il venait d'être confirmé.
- Afficher les compteurs attendus, terminés OK, en erreur, en cours et attendus
  non observés. Les statuts correspondent au dernier état connu de chaque
  occurrence ; les relances restent consultables. Les exécutions observées
  mais non prévues restent visibles dans une catégorie distincte.
- Superposer prévu et réalisé sur la frise. Une absence de trace est
  « Non observé », jamais automatiquement « Non exécuté ». Un retard potentiel
  nécessite une fenêtre attendue dépassée et des observations assez récentes ;
  sinon afficher « À vérifier — données insuffisantes ».
- Pour les durées anormalement longues, comparer au profil du même contexte
  et préciser l'instant de dernière observation. Conserver la distinction
  entre dérive de durée, erreur constatée et dépassement d'une échéance métier.
- Conserver une version datée du plan de référence choisi avant la nuit.
  Une prévision recalculée après réception des résultats ne remplace pas ce
  plan pour mesurer les écarts. Sans référence conservée, afficher
  « Analyse rétrospective », pas une évaluation d'une prévision faite à l'avance.

Le bilan conserve les inconnues tant que les exports ne permettent pas de
conclure ; l'heure de fin théorique de la nuit ne suffit pas à déclarer tous
les traitements terminés. Les listes « À surveiller » et « Les plus longs »
fonctionnent dans les trois modes, indépendamment des clôtures.

### Choisir une période

- Une date future quelconque est acceptée ; afficher la distance à la dernière
  observation, qui limite la pertinence des habitudes apprises.
- La « nuit du 30 septembre » affiche explicitement ses bornes, par exemple
  30/09 19:00 → 01/10 07:00. L'heure de bascule de l'ODAT est configurable et
  doit suivre l'exploitation ; une date ODAT n'est pas automatiquement la date civile.
- Les champs début/fin restent libres : un créneau de deux heures, une nuit ou
  plusieurs jours. Pour plusieurs nuits, afficher une synthèse par nuit, puis
  ouvrir une nuit dans l'explorateur détaillé.
- Le filtre inclut les jobs dont l'exécution estimée chevauche la période,
  même s'ils démarrent avant celle-ci. Signaler les horaires inconnus à part.
- Un changement de dates recalcule sur demande ; le dépliage d'un nœud ne
  relance pas l'apprentissage des profils.

### Explorer l'arbre et la frise ensemble

- Bouton `+` : déplier les sous-nœuds ; clic sur le libellé : sélectionner.
- Sélection d'une chaîne : filtrer la frise sur ses jobs et ouvrir sa synthèse.
- Sélection d'un job : mettre sa barre en évidence et ouvrir sa fiche.
- Sélection d'un créneau sur la frise : mettre en évidence les nœuds concernés.
- Préserver les nœuds ouverts et la sélection lors des changements de filtres.
- Boutons « Tout replier », « Recentrer », « Afficher les sensibles » et
  « Afficher les prévisions incertaines ».
- Au niveau groupe : nombre de jobs distincts, occurrences attendues, fenêtre
  de début/fin, nombre de sensibles et nombre de prévisions peu documentées.

Avec 148 groupes, commencer par l'arbre replié ; ne pas afficher les 542 jobs
simultanément. Les labels métier lisibles passent avant les noms techniques,
qui restent visibles dans la fiche et la recherche.

### Lire une fiche utile

Exemple fictif de présentation, non calculé sur les données actuelles :

> Import factures fournisseurs — job sélectionné
>
> Attendu vers 22:15 ; démarrages généralement observés entre 22:05 et 22:30.
> Durée médiane : 18 min ; 90 % des durées observées ne dépassent pas 31 min.
> Observé lors de 15 nuits comparables sur 16 suffisamment documentées.
> Confiance : élevée pour ce contexte. Échéance métier : 06:00, renseignée.

La fiche contient :

1. Horaire et durée estimés, plage d'incertitude et fin estimée.
2. Motif d'inclusion : quotidien ouvré, mardi, fin de mois, clôture J+1, règle manuelle…
3. Nombre de nuits comparables, dates et fraîcheur des observations.
4. Dernières exécutions, graphique des durées, erreurs et relances observées.
5. Sensibilité métier, échéance, responsable et consigne si renseignés.
6. Lien vers les demandes Oracle et leurs logs lorsque le rapprochement existe.
7. Prévisions « peu documentées » ou « non retenues », avec la raison consultable.

### Comprendre les couleurs

Pour le futur : bleu = attendu, violet = contexte de clôture, orange = risque
estimé de dépassement, gris/pointillé = prévision peu documentée.
Afficher la sensibilité avec un badge et un libellé indépendants.

Pour le réalisé : reprendre les statuts OK / erreur / en cours / attente.
Ne jamais afficher « OK » pour une exécution future. Les couleurs sont toujours
accompagnées de texte ou d'icônes ; la légende s'adapte au mode consulté.

## 4. Les quatre questions de pilotage

| Question | Réponse proposée |
|---|---|
| Qu'est-ce qui va tourner ? | Jobs et occurrences attendus, plage horaire, fréquence, motif et confiance |
| Qu'est-ce qui prend du temps ? | Durées médianes, durées hautes observées, dérive récente et étendue des chaînes |
| Qu'est-ce qui est urgent ? | Jobs proches d'une échéance renseignée, marge restante estimée et risque de dépassement |
| Qu'est-ce qui est sensible ? | Jobs qualifiés par le métier : paiements, clôture, alimentation aval, engagement de service… |

Une longue durée ne suffit pas à définir l'urgence ou la sensibilité. Sans
échéance ou qualification métier, afficher « À qualifier ». L'historique peut
signaler des candidats à examiner, mais ne crée pas seul une criticité métier.

Le bas de page propose des listes courtes cliquables : durées les plus longues,
plus fortes variations, erreurs récurrentes, jobs rares attendus et échéances
potentiellement dépassées. Chaque élément ouvre la même fiche détaillée.

L'étendue d'une chaîne va du premier début à la dernière fin ; ce n'est pas la
somme des durées, car les jobs peuvent tourner en parallèle. Le nombre de jobs
simultanés mesure la concurrence estimée, pas la consommation CPU.

## 5. Construire des prévisions explicables

### Préparer les exécutions observées

- Consolider les photos pour retrouver les vraies exécutions, en validant la
  clé serveur Control-M / application / job / ODAT / order_id / passage.
  Conserver les relances et ne pas compter plusieurs fois une même exécution.
- Séparer les jobs non démarrés, les exécutions incomplètes, les suppressions,
  les tâches techniques de type Dummy et les durées invalides.
- Identifier les jobs cycliques et leurs créneaux récurrents ; une seule heure
  médiane par job masquerait plusieurs passages distincts.
- Calculer une couverture par nuit et contexte : absence de photo ou de trace
  ne veut pas dire qu'un job n'était pas programmé.
- Conserver les dates civiles, l'ODAT et le fuseau Europe/Paris ; tester le
  passage à minuit et les changements d'heure.

### Identifier les rythmes

Comparer des règles simples et lisibles : tous les jours, jours ouvrés, jours
de semaine précis, jour du mois, dernier jour ouvré, début/fin de mois et jours
relatifs à une clôture. Les suffixes `_Q`, `_H`, `_M` restent des indices à
confronter aux observations.

Choisir les contextes sur lesquels une règle dispose d'assez d'exemples,
favoriser les observations récentes et signaler les changements de comportement.
Afficher les jobs irréguliers dans « À confirmer » plutôt que les faire
disparaître du résultat.

La fréquence observée, le taux de succès passé et la confiance de prévision
sont trois champs distincts. Pour commencer, utiliser des niveaux de confiance
avec leur justification ; ne pas présenter un score comme une probabilité
calibrée avant validation sur des nuits mises de côté.

### Prendre en compte les clôtures

Les calendriers T1, T2 et T3 2026 ont été fournis et examinés en lecture seule
le 19 septembre 2026. Ils couvrent les clôtures de janvier à septembre, avec
des opérations débordant sur le mois suivant. Ils ne sont pas encore importés
dans l'application. Les dates ci-dessous sont les valeurs enregistrées dans
les classeurs ; les formules ont été inspectées, sans recalcul Excel.

#### Sources et jalons disponibles

| Clôture | Fermeture FA | J : provisoire GL, définitives AP/AR/PO* | Définitive GL |
|---|---|---|---|
| Janvier | 23/01/2026 | 30/01/2026 | 03/02/2026 |
| Février | 20/02/2026 | 27/02/2026 | 03/03/2026 |
| Mars | 24/03/2026 | 31/03/2026 | 02/04/2026 |
| Avril | 23/04/2026 | 30/04/2026 | 05/05/2026 |
| Mai | 21/05/2026 | 29/05/2026 | 02/06/2026 |
| Juin | 23/06/2026 | 30/06/2026 | 02/07/2026 |
| Juillet | 24/07/2026 | 31/07/2026 | 04/08/2026 |
| Août | 24/08/2026 | 31/08/2026 | 02/09/2026 |
| Septembre | 23/09/2026 | 30/09/2026 | 02/10/2026 |

*Au T1, le libellé indique aussi SSP/PO. Sources dans `docs/` :

- `Planning Clôtures T1-2026.xlsx` : feuilles JANVIER / FEVRIER / MARS 2026,
  lignes 8, 44 et 56, colonnes A à G.
- `Planning Clôtures T2-2026.xlsx` : feuilles AVRIL / MAI / JUIN 2026,
  lignes 8, 48 et 62, colonnes A à G.
- `Planning Clôtures T3-2026.xlsx` : feuilles JUILLET / AOUT 2026,
  lignes 10, 53 et 69 ; SEPTEMBRE 2026, lignes 12, 56 et 71,
  colonnes A à G.

Les feuilles détaillées distinguent ARRETE, TRAITEMENT et RESTITUTION (A/B/C),
la référence J (D), la date de l'opération (E), le moment ou l'heure (F) et
le décalage J±N (G). Les formules `WORKDAY` utilisent les jours fériés de
`Feuil1!D2:D14` : **J+2 signifie deux jours ouvrés, pas deux jours civils**.
Ainsi, pour avril, J est le 30/04 et J+2 le 05/05.

Conserver chaque opération, et pas seulement trois dates par mois : passages
successifs de refacturation, abonnements GL, PIRENE, CELERIS, extournes,
restitutions et campagnes de virements enrichissent le contexte d'une nuit.
Une ligne métier ne correspond pas nécessairement à un job automatique.

#### Utilisation dans la page

Ajouter un bandeau de jalons cliquables au-dessus de la frise :
« FA J−5 → Provisoire J → Définitive GL J+2 → Restitutions J+3 ».
Chaque jalon ouvre sa date et affiche les opérations métier, les jobs liés
et les opérations dont le rapprochement reste à valider.

Exemple concret : en sélectionnant le **30/09/2026**, afficher
« Clôture de septembre — J — fermeture application / provisoire GL ».
Rechercher les exécutions des précédentes nuits J suffisamment documentées,
en distinguant le contexte trimestriel, plutôt que tous les mercredis.
Les heures de début/fin et durées restent estimées à partir de l'historique.
Le calendrier confirme une intention métier, pas la programmation Control-M.

Le bouton « Prochaine clôture » propose les prochains jalons avec leur nature
(FA, provisoire, définitive), pour éviter de confondre fermeture FA le 23/09
et clôture provisoire le 30/09. La fiche indique la source et sa validation.

#### Import et rapprochements à prévoir

1. Lire les trois feuilles mensuelles de chaque fichier trimestriel d'après
   leurs noms et en-têtes, sans dépendre de leur ordre ni des numéros de lignes,
   différents entre trimestres. Exclure les feuilles de synthèse des opérations ;
   utiliser la feuille technique des jours fériés uniquement pour les calculs.
   Conserver séparément les textes A/B/C lorsqu'une ligne contient plusieurs informations.
2. Prévisualiser les opérations : période comptable, date J, date civile,
   décalage ouvré, moment (`Matin`, `Soir`, `Nuit`, `Journée`) ou heure précise,
   libellés, périmètre, fichier/feuille/cellules sources et version.
3. Contrôler valeurs mémorisées et formules, jours fériés, erreurs, doublons
   et conflits. Toute correction reste une décision explicite et traçable.
   Réimporter le même fichier ne doit pas dupliquer ses opérations ; une
   nouvelle version doit présenter ses différences avant activation.
4. Relier les opérations aux groupes/jobs via une table de correspondance
   validée : une opération peut avoir plusieurs jobs et inversement.
   Les descriptions et noms servent à suggérer, jamais à confirmer seuls.
5. Valider le rattachement de « Nuit » à l'ODAT et ses bornes. Ne pas inventer
   19:00 pour toutes les lignes « Nuit », ni considérer toute heure explicite
   comme une échéance SLA : préciser si c'est un lancement ou une limite.

Le calendrier reste éditable/importable, avec exceptions et périmètres par
domaine ou entité. Conserver période comptable et date réelle séparément :
le 02/10 appartient ici à la clôture de septembre. Aucun calendrier de clôture
T4 n'a été fourni : les opérations d'octobre issues du T3 ne le remplacent pas.
Hors couverture, afficher « Calendrier métier non renseigné » ; les rythmes
ordinaires restent prévisibles, mais une clôture extrapolée reste une simulation.

#### Points de vigilance identifiés dans les sources

- **Synthèse T3 incohérente, exclue de l'import** : `Feuil2!B2:G8` porte un titre « Juillet »,
  des dates textuelles en août et une date Excel au 02/09 en B7. Ne pas
  fusionner cette synthèse avec les feuilles mensuelles. Son exclusion ne
  bloque pas l'import de feuilles mensuelles valides ; ne pas corriger le classeur source.
- **Les règles évoluent** : « Alimentation de la Garantie Totale » est à J+3
  au T2 (`JUIN 2026!B64:G64`), mais à J+2 au T3
  (`SEPTEMBRE 2026!B73:G73`). Versionner les règles par période, plutôt que
  figer un décalage unique ou laisser une moyenne masquer le changement.
- **Périmètre trimestriel à confirmer** : la surtaxe communale figure aussi
  dans les feuilles janvier/février du T1, ligne 63, avec un libellé trimestriel.
  Ne pas déduire de ces seules lignes une récurrence mensuelle automatique.
- Les mentions d'astreinte et de cockpit des synthèses sont des informations
  d'organisation ; elles ne suffisent pas à définir la criticité de chaque job.

Pour chaque job : comparer les nuits de clôture et les nuits ordinaires,
repérer les passages propres à J-1/J/J+1 et les allongements de durée.
Toujours montrer le nombre de clôtures comparables réellement observées.
Quatre mois ne permettent pas à eux seuls de valider une règle annuelle ou de
généraliser à toutes les clôtures trimestrielles.

Une option « Comparer nuit ordinaire / clôture » présente les jobs ajoutés,
retirés et les durées différentes. Un contexte imposé par l'utilisateur porte
la mention « Simulation », sans modifier le calendrier réel.

### Encadrer les horaires

Estimer début et durée par contexte, avec médiane et quantiles si l'échantillon
est suffisant. Pour la fin estimée, exploiter les fins observées ou les couples
début/durée ; additionner deux quantiles ne produit pas automatiquement un
quantile de fin valide.

Pour un job cyclique, distinguer jobs uniques et occurrences attendues. Si les
photos ne permettent pas de reconstruire tous les passages, afficher une plage
de fréquence et sa limite d'observation.

## 6. Arborescence et dépendances

L'arbre reprend les groupes Control-M et les jobs. Un lien parent/enfant signifie
« appartient à », pas « doit finir avant ».

Le schéma SQLite actuel n'enregistre pas les conditions amont/aval de Control-M.
Une vraie vue des dépendances et un chemin critique demandent un export des
définitions/conditions ou une qualification manuelle. Les successions horaires
observées peuvent être proposées à validation, pas déclarées comme dépendances.

La première version doit donc annoncer la fin estimée d'une chaîne sans
prétendre calculer une propagation certaine des retards.

## 7. Page « Calendriers de clôture » — charger les fichiers Excel

Prévoir une page dédiée dans la navigation d'ODAT Watch, distincte de
« Préparer ma nuit » et accessible également depuis son bouton
« Calendrier métier ». Elle permet de charger les fichiers sans les copier
manuellement dans le dossier du projet. Les deux pages utilisent le même
calendrier validé, enregistré durablement dans la base.

### Parcours d'import

1. **Déposer les fichiers** : sélection ou glisser-déposer d'un ou plusieurs
   fichiers `.xlsx`, un fichier par trimestre, trois feuilles métier par fichier,
   une par mois. Ce parcours doit fonctionner aussi pour les futurs trimestres
   et années, sans noms de fichiers T1–T3 2026 codés en dur.
2. **Vérifier les mois reconnus** : afficher fichier, trimestre/année détectés,
   trois mois, nombre d'opérations et état des contrôles. Montrer à part les
   feuilles annexes ignorées et la source des jours fériés. Un mois absent,
   dupliqué ou incompatible avec le trimestre bloque la validation du fichier.
3. **Prévisualiser par mois** : trois onglets mensuels avec date, J±N,
   moment/heure, arrêté, traitement et restitution ; filtres « Nuit » et
   « Anomalies ». Afficher les cellules sources pour retrouver une erreur
   dans Excel et conserver les opérations débordant sur le mois suivant.
4. **Examiner les contrôles et différences** : distinguer erreurs bloquantes
   et avertissements explicables. Signaler notamment date illisible, formule
   sans valeur exploitable, référence J incohérente ou doublon. Si le mois
   existe déjà, comparer opérations ajoutées, modifiées et retirées ; aucune
   ancienne donnée ne doit disparaître silencieusement.
5. **Valider et activer** : bouton explicite « Enregistrer et activer » après
   contrôle des trois mois et confirmation des éventuels remplacements.
   Un dépôt, une prévisualisation ou une annulation ne change pas le calendrier
   actif. Enregistrer chaque fichier de façon atomique : ses trois mois sont
   enregistrés ensemble, ou aucun en cas d'échec. Pour plusieurs fichiers,
   afficher un résultat distinct par fichier et détecter leurs conflits avant activation.
6. **Ouvrir le résultat** : confirmation des mois activés, nombre d'opérations
   et lien « Préparer une nuit de cette clôture ». Invalider les prévisions
   en cache concernées pour utiliser la nouvelle version validée.

Un fichier déjà importé à l'identique est signalé « Déjà chargé », sans doublon.
Une version corrigée est enregistrée comme une nouvelle version, en conservant
l'ancienne et la possibilité de la réactiver avec confirmation. Une opération
sans correspondance Control-M peut être importée : elle reste « Jobs à associer »
et ne doit pas se transformer automatiquement en prévision de job.

### Consultation et historique

En haut de page, afficher l'année et les douze mois avec leur état textuel :
« Non chargé », « Actif » ou « À vérifier ». Distinguer les tentatives d'import
en erreur du calendrier actif : un nouvel essai invalide ne désactive pas une
version précédemment validée.

Sous cette vue, présenter les imports : fichier, date de chargement, période,
version, état, nombre d'opérations et accès au détail des contrôles. Conserver
la provenance et l'empreinte du fichier ; les corrections des Excel se font
dans le fichier source puis par réimport, sans édition libre de la grille
dans cette première version.

### Contrôles de sécurité et critères de recette

- Limiter la taille et le nombre de fichiers par dépôt ; rejeter les formats
  non pris en charge, fichiers corrompus ou protégés non lisibles. Ne pas
  exécuter de macros ni actualiser de liens externes du classeur.
- Tester un trimestre valide : trois mois et leurs opérations sont chargés,
  les feuilles de synthèse ne créent aucun événement.
- Tester les feuilles dans un ordre différent, un mois manquant, les jours
  fériés et les opérations du mois suivant sans changer leur période comptable.
- Tester un dépôt identique, une version corrigée avec retrait d'opérations,
  deux fichiers couvrant le même mois, une annulation et un échec d'enregistrement.
- Vérifier que le calendrier actif survit au redémarrage de l'application,
  que l'ancienne version reste consultable et que « Préparer ma nuit » affiche
  bien les jalons de la version activée.

## 8. Assistant de nuit — poser des questions sur le futur

Principe validé : une conversation reliée à l'arbre et à la frise, utilisable
pour toutes les nuits applicatives, en clôture comme hors clôture. L'assistant
explique les résultats du moteur de prévision ; il ne constitue pas un second
moteur qui invente ses propres horaires ou probabilités.

### Présentation et interactions

Un panneau escamotable à droite de « Préparer ma nuit » accueille la conversation.
Pour préserver la largeur des graphiques, ce panneau et la fiche de détail
partagent l'espace latéral, avec bascule entre les deux. Sur écran étroit,
la conversation devient une vue alternable avec les graphiques.

Afficher en permanence le contexte actif : dates et heures exactes, ODAT,
fuseau Europe/Paris, application/groupe/job sélectionné, filtres et version
du plan consulté. Proposer les raccourcis « Demain », « Les plus longs »,
« À surveiller », « Prochaine clôture », « Comparer » et « Pourquoi ce job ? ».

Exemple de parcours, sans résultat chiffré inventé :

1. « Prépare-moi la nuit du 30 septembre » : résoudre et afficher l'année et
   les bornes de nuit, le contexte métier et les traitements attendus.
2. « Seulement ceux qui prennent plus de 30 minutes » : filtrer par durée
   médiane estimée, annoncer ce critère et synchroniser l'arbre et la frise.
3. « Et lesquels sont sensibles ? » : appliquer la qualification métier validée ;
   signaler les jobs non qualifiés, sans les déclarer non sensibles.
4. « Compare avec la clôture précédente » : conserver le périmètre et comparer
   des jalons de même nature. Préciser si la comparaison oppose une prévision
   au réalisé ou deux prévisions ; demander le jalon si le contexte est ambigu.
5. Après clic sur un job : « Pourquoi celui-là est attendu ? » ouvre les
   observations comparables et la règle ayant motivé son inclusion.

La conversation conserve les filtres dans la session et suit les changements
effectués dans l'interface. Un bouton « Réinitialiser le contexte » permet de
repartir d'une sélection claire. Les réponses anciennes gardent leurs dates,
filtres et références : elles ne deviennent pas des réponses sur la nouvelle sélection.

### Réponses attendues et limites

Chaque réponse contient une synthèse courte, les résultats calculés consultables,
le motif, le niveau de confiance justifié, le nombre de nuits comparables,
la fraîcheur des données et les références des exécutions ou cellules du
calendrier utilisées. Les boutons « Voir sur la frise », « Ouvrir le job »,
« Voir les sources », « Comparer » et « Exporter » réutilisent la sélection.

Pour « Quelle nuit sera la plus chargée ? », annoncer la mesure choisie :
nombre d'occurrences attendues, somme des durées ou pic de simultanéité estimé.
Ne pas assimiler cette mesure à une charge CPU ni à la durée totale de la nuit.
Pour une échéance ou une criticité inconnue, répondre « À qualifier ».

Une date éloignée reste interrogeable, mais les données insuffisantes, le
calendrier manquant et les règles peu documentées doivent être visibles.
Distinguer prévision historique, événement du calendrier métier, programmation
Control-M confirmée si disponible et résultat réellement observé. L'assistant
peut répondre « Je ne peux pas conclure avec les données disponibles ».
Il ne prédit pas une panne certaine et ne déduit pas de dépendances causales
à partir de la seule succession des horaires. Aucun traitement n'est lancé,
arrêté ou reprogrammé depuis la conversation.

### Deux étapes de réalisation

- **Questions guidées** : boutons et paramètres structurés exécutant des
  fonctions de lecture et de prévision connues, avec réponses explicatives
  déterministes. Cette version fonctionne sans service d'IA externe ; elle
  n'est pas présentée comme comprenant n'importe quelle question libre.
- **Questions libres en français** : un modèle autorisé par Dalkia traduit
  la question en intention et paramètres validés, puis explique le résultat
  calculé. Le choix du modèle et de son hébergement reste à valider avant
  activation. En son absence ou en cas d'erreur, conserver les questions guidées.

Les fonctions accessibles à l'assistant sont limitées à la consultation du
plan, aux filtres, aux comparaisons et aux explications. Aucun SQL arbitraire
produit par le modèle n'est exécuté. Valider les dates, périmètres et limites
des requêtes ; traiter les descriptions de jobs et les textes des classeurs
comme des données, jamais comme des instructions.

Aucun transfert vers un service externe par défaut. Avant toute activation,
valider les données transmissibles et la politique de conservation ; ne pas
envoyer de secrets, de configuration sensible ni la base complète. La conversation
reste limitée à la session dans la première version, sans archivage automatique.

### Recette de l'assistant

Vérifier qu'une même demande via les filtres, les boutons guidés et la question
libre produit les mêmes jobs, occurrences et chiffres. Tester les questions
successives, la sélection d'un job, le changement de date hors conversation,
les formulations ambiguës, les résultats vides et les données manquantes.
Contrôler la concordance des sources, les frontières de nuit, les clôtures et
les nuits ordinaires ; tester aussi une indisponibilité du modèle et un texte
source contenant de fausses instructions. Aucune réponse chiffrée ne doit être
affichée comme établie sans résultat calculé correspondant.

## 9. Plan de réalisation

| Lot | Livrable | Critère de sortie |
|---|---|---|
| 1 — Données et modèle de nuit | Exécutions consolidées, couverture, ODAT, occurrences et lecture des calendriers trimestriels | Une exécution vue dans cinq photos est comptée une fois ; les anomalies de calendrier sont isolées |
| 1 bis — Page Calendriers de clôture | Dépôt Excel, aperçu des trois mois, contrôles, activation et historique des versions | Import atomique par fichier, aucun doublon au réimport ; la version active alimente les prévisions |
| 2 — Page exploratoire | Dates libres, jalons validés, arbre, frise, fiche, filtres et export | Une sélection de nœud et une sélection horaire donnent les mêmes jobs ; passage à minuit correct |
| 3 — Prévisions de base | Rythmes quotidiens/hebdomadaires, horaires et explications | Chaque prévision cite ses nuits comparables ; les données insuffisantes sont identifiables |
| 3 bis — Suivi de toutes les nuits | Modes suivi/bilan, derniers statuts, prévu/réalisé et fraîcheur des exports | Fonctionne sans calendrier de clôture ; distingue non observé, erreur, retard potentiel et données insuffisantes |
| 4 — Clôtures et priorités | Correspondances opérations/jobs validées, prévisions par jalon, sensibilité et échéances | Différence nuit ordinaire/clôture expliquée ; règles versionnées et urgence justifiée par une échéance |
| 5 — Validation et suivi | Rejeu historique, comparaison prévu/réalisé, dérive | Qualité mesurée sur des nuits non utilisées pour apprendre, par type de rythme |
| 6 — Assistant guidé | Panneau de questions, contexte partagé, réponses sourcées et actions sur les graphiques | Mêmes résultats que les filtres manuels, sans modèle externe ; fonctionne hors clôture |
| 7 — Conversation libre | Interprétation en français via un modèle autorisé, fonctions de lecture contrôlées et repli guidé | Sources vérifiables, ambiguïtés traitées et aucun transfert externe sans validation |

Les tests de chaque lot sont réalisés au fil du développement ; le lot 5
consolide la validation métier. Pour rejouer une date passée, n'utiliser que les
photos disponibles avant l'heure de prévision simulée, y compris pour choisir
les règles. Une photo postérieure peut révéler une fin que l'on ne connaissait
pas encore à cet instant.

Versionner aussi les calendriers et les correspondances. Si la version connue
à une date passée n'est pas disponible, présenter le test comme une analyse
rétrospective avec calendrier actuel, pas comme une prévision historique stricte.

Mesurer les traitements oubliés, les traitements annoncés à tort, les erreurs
d'heure de début/fin, la couverture des intervalles et les dépassements
d'échéance. Comparer au moteur actuel et à une référence simple « même jour de
la semaine précédente ». Évaluer séparément les clôtures, jobs rares et cycliques.

Les seuils d'acceptation métier seront fixés après cette mesure, en privilégiant
la visibilité des traitements sensibles susceptibles d'être oubliés.

Recette du suivi hors clôture : tester une nuit ordinaire en semaine, une nuit
de week-end, un job cyclique, une nuit sans calendrier métier et une nuit sans
photo récente. Vérifier aussi un passage à minuit, une erreur suivie d'une
relance réussie, un job observé non prévu et un attendu absent des exports.
Le suivi ordinaire doit être livrable sans attendre les rapprochements métier
du lot clôtures. La page « Calendriers de clôture » reste un complément indépendant.

## 10. Organisation technique proposée

- `app.py` : navigation vers « Préparer ma nuit » et « Calendriers de clôture »,
  avec leurs raccourcis.
- `ui_preproduction.py` : modes préparation/suivi/bilan, filtres, synthèse,
  frise prévu/réalisé, fraîcheur des sources et panneau de détail.
- `ui_calendriers.py` : dépôt Excel, aperçu mensuel, contrôles, comparaison
  des versions, confirmation d'activation et historique des imports.
- `ui_assistant_nuit.py` : panneau de conversation, questions guidées,
  contexte de session et liens vers l'arbre, la frise et les sources.
- `assistant_nuit.py` : intentions autorisées, validation des paramètres,
  appels aux fonctions métier existantes et réponses structurées sourcées.
  L'adaptateur de modèle pour les questions libres est optionnel et désactivé
  tant que le modèle et les conditions d'utilisation ne sont pas validés.
- `production_plan.py` : assemblage d'un plan sur une plage libre, explications.
- `night_monitoring.py` : rapprochement des occurrences attendues/observées,
  derniers états, écarts et suivi des relances ; réutiliser la consolidation
  des exécutions et les sources existantes sans créer un second import Control-M.
- `forecast.py` : profils enrichis et règles évaluées par contexte.
- `business_calendar.py` : clôtures, jours ouvrés, exceptions et simulations.
- `calendar_import.py` : lecture des trois feuilles mensuelles des classeurs trimestriels, prévisualisation,
  provenance et contrôles avant validation ; aucun import silencieux.
- `db.py` : migrations additives pour calendrier, qualification métier et
  résultats de prévision datés ; conserver les observations sources, les
  versions de calendrier et l'historique des imports ; activation transactionnelle.
- Composant d'arbre ECharts inspiré du HTML existant : données dynamiques,
  événements de sélection reliés à Streamlit et conservation de l'état.
  Vérifier la compatibilité avec la version installée lors du prototype ;
  intégrer les ressources localement pour ne pas dépendre du CDN sur Dalkia.
- Tests dédiés aux fréquences, doublons, cycles, couverture, clôtures,
  limites temporelles, filtres synchronisés et rejouage sans fuite du futur.

L'arbre, la frise, les fiches, l'assistant et les exports consomment le même
résultat calculé, identifié par une version et un contexte explicites.
Le cache est invalidé à l'import de données ou à la modification du calendrier
et des règles. Les données Oracle simulées, lorsqu'elles sont utilisées pour
une démonstration, ne doivent pas alimenter les statistiques de production.

## Première version recommandée

Livrer d'abord une page couvrant une date libre ou plusieurs nuits, avec arbre
repliable, frise synchronisée, fiche historique, traitements longs, confiance
expliquée et visibilité des cas incertains. La préparation, le suivi sur exports
et le bilan doivent fonctionner pour les nuits ordinaires, même sans calendrier
de clôture chargé. Les calendriers étant disponibles,
intégrer la page de chargement Excel « Calendriers de clôture » et ses jalons
validés dès ce socle, avec les champs sensibilité et échéance. Activer ensuite les prévisions par clôture
après validation des correspondances opérations/jobs et comparaison au réel.
Brancher ensuite les questions guidées sur ces mêmes calculs, puis activer
la conversation libre après validation du modèle et de la confidentialité.
C'est cette combinaison qui transforme l'arborescence actuelle en outil de
préparation opérationnelle.
