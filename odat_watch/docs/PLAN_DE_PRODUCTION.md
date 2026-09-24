# Plan de production : guide de lecture

Onglet **Control-M › 📋 Plan de production** d'ODAT Watch.

Ce guide explique d'où viennent les données, comment lire chaque couleur et chaque chiffre, et ce que fait
le bouton **Synchroniser avec ODAT**. Il s'adresse à l'équipe qui suit les chaînes Control-M FIN-FINANCE
pendant et après les clôtures.

---

## 1. Le principe en trois phrases

1. **Le point de départ est la bible de Lionel** (`docs/Plan de Production.xlsx`, juin 2025). Elle a été chargée
   **une seule fois**, automatiquement, à la première ouverture de l'onglet.
2. **Ensuite, ce sont les photos ODAT qui font foi.** Le bouton « Synchroniser avec ODAT » ajoute les chaînes
   nouvelles, retire celles qui ont disparu et recale les planifications sur ce qui tourne vraiment.
3. **On raisonne toujours autour de la clôture**, de J-7 à J+16, et jamais en dates seules.

---

## 2. Le calendrier : J, L et D

| Notion | Règle |
|---|---|
| **J** | Dernier jour **ouvré** du mois (clôture comptable). |
| **J-n / J+n** | Compté en **jours ouvrés** : samedis, dimanches et fériés français ne comptent pas. |
| **Fenêtre affichée** | De **J-7** à **J+16**. Les week-ends et fériés sont affichés, mais sans label J. |
| **Calendrier Control-M** | Rappel entre parenthèses ou en colonne : **J-n = L(n+1)**, **J+n = Dn**. |

Correspondances utiles :

| Métier | Control-M |
|---|---|
| J-7 | L8 |
| J-6 | L7 |
| J-1 | L2 |
| J | L1 |
| J+1 | D1 |
| J+16 | D16 |

Les fériés pris en compte sont les fériés nationaux : 1er janvier, lundi de Pâques, 1er mai, 8 mai, Ascension,
lundi de Pentecôte, 14 juillet, 15 août, 1er et 11 novembre, 25 décembre. Il n'y a pas de fériés régionaux.

Un jour ouvré quelconque a toujours un seul label. Il est **J-n du mois en cours** s'il est à 7 jours ouvrés ou
moins de J, sinon **J+n du mois précédent**. Exemple : le lundi 21/09/2026 est J-7 de septembre, et non J+15 d'août.

---

## 3. D'où viennent les données : les photos ODAT

Control-M produit **5 photos par odate** :

| Photo | Moment |
|---|---|
| 1 | 13h46, le jour même |
| 2 | 16h46, le jour même |
| 3 | 7h07, le lendemain |
| 4 | 7h37, le lendemain |
| 5 | 8h07, le lendemain |

Une même exécution (job + odate + order id) apparaît donc jusqu'à 5 fois. Elle passe typiquement de
« Wait for Event » à « Executing », puis à « Ended OK ».

**ODAT Watch fusionne ces photos** et ne garde que **le dernier état connu de chaque exécution** :

- **Une attente est remplacée** dès qu'une photo suivante montre l'exécution partie. Un mensuel n'apparaît
  donc qu'une fois par mois.
- **Une relance reste visible.** Un échec à 23h00 puis une reprise OK à 7h20 font deux lignes, car chaque
  tentative a son heure de début.
- **« Non lancé »** : le job était encore en attente à la dernière photo d'un odate terminé. Il n'a jamais tourné
  pour cet odate. C'est le cas par exemple du flux B des relevés quand aucun fichier n'arrive.
- **Un job cyclique** resté « entre deux cycles » sur un odate terminé est compté **Ended OK**, car son dernier
  cycle s'est terminé normalement.

La base `odat.db` n'est jamais modifiée par cette fusion : elle se fait à l'affichage. Les onglets Jobs CtrlM,
Profils, Historique et Plan de production l'utilisent tous.

---

## 4. L'écran, de haut en bas

### 4.1 Bouton « 🔄 Synchroniser avec ODAT »

Voir la section 6. À côté du bouton, une ligne indique :

- le nombre de chaînes **actives** du référentiel ;
- la date du chargement unique de la bible ;
- la date de la **dernière synchronisation ODAT**.

### 4.2 Mois comptable

La liste affiche par exemple « Août 2026 · J = lun 31/08 ».

- **Par défaut**, c'est la dernière clôture passée, c'est-à-dire le dernier mois dont le J est couvert par les photos.
- **Le dernier mois de la liste** est entièrement à venir. Il sert à **préparer** la prochaine clôture.

### 4.3 Bandeau du calendrier

Il y a une colonne par jour de la fenêtre. Chaque en-tête donne le label J et la date, par exemple « J-2 27/08 »,
ou le jour et la date pour un week-end, par exemple « sam 29/08 ».

| Ligne | Contenu |
|---|---|
| **Control-M** | Label L ou D du jour. Vide pour un week-end ou un férié. |
| **jour** | Jour de la semaine. « (férié) » apparaît quand un jour de semaine est férié. |
| **jalons clôture** | Nombre d'opérations du **Planning Clôtures** importé (onglet 📥 Clôtures) ce jour-là. |

L'encart **« Jalons du calendrier de clôture sur la fenêtre »** détaille ces opérations : date, J, décalage,
moment et libellé.

### 4.4 Les 5 tuiles chiffrées

| Tuile | Couleur du liseré | Ce qu'elle compte |
|---|---|---|
| **Chaînes au référentiel** | gris | Chaînes du référentiel qui ne sont pas au statut « supprimée ». |
| **Chaînes observées sur le mois** | bleu | Chaînes qui ont **réellement tourné** au moins une fois dans la fenêtre du mois. Le « Non lancé » ne compte pas. |
| **Nouvelles, à qualifier** | jaune | Chaînes vues dans les photos mais **absentes du référentiel**. |
| **Absentes des photos** | rouge | Chaînes du référentiel « Jamais vue » ou « Plus vue depuis… ». |
| **Écarts de planification** | jaune | Chaînes dont les jours réels diffèrent de la planification du référentiel. |

### 4.5 Filtres

| Filtre | Effet |
|---|---|
| **Recherche** | Cherche dans le code chaîne, la description, **les noms des jobs** de la chaîne et **leurs programmes Oracle**. |
| **Catégorie** | Référentiel, Quotidienne, Périodique, Clôture, Campagne, À qualifier… |
| **Origine** | Voir la section 4.7. « Plus vue » regroupe toutes les dates. |
| **Écarts uniquement** | Ne garde que les chaînes qui ont au moins un écart. |
| **Masquer supprimées** | Coché par défaut. |

La ligne sous les filtres rappelle le nombre de chaînes affichées et la légende des symboles.

### 4.6 La grille : colonnes fixes

| Colonne | Signification |
|---|---|
| **chaîne** | Code Control-M de la chaîne (group name). |
| **description** | Description du référentiel. À défaut, celle du job homonyme ou la plus fréquente dans les photos. |
| **catégorie** | Catégorie du référentiel. « À qualifier » pour une chaîne nouvelle. |
| **planification** | Planification **de référence** : jours de semaine ou J±n. Voir la section 5. |
| **Control-M** | La même planification en labels L/D, par exemple « L3, L1, D4 ». Vide pour des jours de semaine. |
| **observée (ODAT)** | Planification **déduite de tout l'historique des photos**. Voir la section 6.3. |
| **origine** | D'où vient la chaîne et si elle tourne encore. Voir la section 4.7. |
| **écarts** | Différences entre planification et réalité sur le mois. Voir la section 4.9. |

### 4.7 Origine d'une chaîne

| Origine | Signification |
|---|---|
| **Référentiel** | Chaîne de la bible, toujours vue dans les photos. |
| **Ajoutée** | Chaîne ajoutée au référentiel depuis les ODAT, par le bouton ou la synchronisation. |
| **Nouvelle** | Chaîne vue dans les photos mais **pas encore au référentiel**. |
| **Jamais vue** | Chaîne du référentiel qui n'apparaît dans **aucune** photo. |
| **Plus vue depuis JJ/MM/AAAA** | Chaîne du référentiel absente depuis plus de **40 jours** avant la dernière photo. |
| **Supprimée** | Statut « supprimée » dans le référentiel. Ligne masquée par défaut. |

### 4.8 La grille : une colonne par jour, couleurs et symboles

Chaque cellule résume **toute la chaîne pour cet odate**. Le chiffre est le **nombre de jobs** de la chaîne
vus ce jour-là. Quand les jobs n'ont pas tous le même état, c'est le **pire état** qui s'affiche, dans cet ordre :
✖, puis ▶, puis ⏸, puis ✔, puis ⊘.

| Cellule | Couleur | Signification |
|---|---|---|
| **✔ 5** | fond vert clair, texte vert | Tous les jobs de la chaîne sont **terminés OK**. |
| **✖ 5** | fond rouge clair, texte rouge | Au moins un job **en erreur** (Ended Not OK). |
| **▶ 5** | fond bleu clair, texte bleu | Au moins un job **en cours** à la dernière photo. |
| **⏸ 5** | fond jaune clair, texte brun | Au moins un job **en attente** : odate en cours, ce n'est pas encore fini. |
| **⊘ 5** | fond mauve clair, texte mauve | Chaîne **ordonnancée mais jamais partie** pour cet odate (Non lancé). |
| **✔ 5+** | texte **violet gras** | La chaîne a tourné un jour **hors de sa planification**. Le « + » s'ajoute à n'importe quel état. |
| **○** | fond gris | **Prévu mais absent** : la chaîne devait tourner, il y a des photos ce jour-là, elle n'y est pas. |
| **·** | fond gris très clair | **Prévu, à venir** : jour postérieur à la dernière photo. |
| **?** | fond gris très clair | **Prévu, aucune photo** ce jour-là : impossible de savoir. |
| *(vide)* | aucun | Pas prévu et rien observé. |

À retenir :

- **○ ne veut pas dire « pas exécuté ».** La chaîne n'apparaît pas dans les photos de ce jour, c'est tout.
  C'est un point à vérifier.
- **Un ⊘ n'est pas un succès.** La chaîne ne compte pas comme « tournée ». Si elle était prévue ce jour-là,
  cela crée un écart « − ».

### 4.9 La colonne « écarts »

Elle compare les jours **réellement tournés** aux jours **prévus** par la planification, sur la fenêtre du mois.

| Notation | Signification |
|---|---|
| **+J+3** | La chaîne a tourné à J+3 alors que ce n'était **pas prévu**. |
| **−J-1** | La chaîne était **prévue** à J-1 et n'a **pas tourné**. Ce n'est compté que si des photos existent ce jour-là. |
| **+dim 23/08** | Même chose pour un jour sans label J (week-end ou férié). |

La colonne reste vide quand tout correspond, quand la chaîne n'a pas de planification, ou quand elle est
supprimée.

### 4.10 « ✏️ Qualifier et enrichir le référentiel »

| Action | Effet |
|---|---|
| **Ajouter les N chaîne(s) nouvelle(s)** | Les chaînes « Nouvelle » du mois entrent au référentiel : statut « nouvelle », catégorie « À qualifier », planification observée. |
| **Adopter la planification observée pour…** | Remplace la planification de référence par l'observée pour les chaînes choisies. |
| **Tableau éditable + Enregistrer** | Modifie la description, la catégorie, la planification, le statut ou le commentaire. |

Colonnes du tableau en lecture seule :

- **règle écrite (bible)** : la colonne C de la bible, par exemple « L6, L5, L4, L3, L2 ».
- **jours cochés (bible)** : les jours où la chaîne était cochée en juin 2025.
- **source**
- **maj_le** : date de la dernière modification.

**Une planification saisie à la main est protégée** : la synchronisation ne la modifie plus. Pour rendre la main
aux ODAT, **videz la case** et enregistrez.

### 4.11 Fiche chaîne

Choisissez une chaîne en bas de page. La fiche affiche :

- **une ligne de synthèse** : description, catégorie, planification avec son rappel Control-M, planification
  observée et origine ;
- **la liste des jobs de la chaîne**, dans l'ordre de passage habituel. Pour chaque job :
  - le **programme Oracle** lancé et le script ;
  - l'**heure habituelle** (médiane), avec « (J+1) » s'il tourne après minuit ;
  - la **durée médiane** et la **fiabilité**, c'est-à-dire la part des exécutions terminées OK ;
  - la **fréquence**, déduite du suffixe du nom : _Q quotidien, _H hebdo, _M mensuel ;
  - les **jours** où il tourne et le nombre d'**exécutions** observées ;
- **la grille job × jours** du mois, avec les mêmes couleurs que la grille principale.

---

## 5. Écrire une planification

| Forme | Exemple | Utilisée pour |
|---|---|---|
| **Jours de semaine** | `lun mar mer jeu ven` | Chaînes quotidiennes ou hebdomadaires |
| **Labels J** | `J-2, J, J+4` | Chaînes de clôture, périodiques, campagnes |
| **Labels Control-M** | `L3, L1, D4` | Accepté en saisie, converti en J (L3 = J-2, D4 = J+4) |

On peut mélanger les formes, par exemple « `sam J+2` ».

---

## 6. La synchronisation avec ODAT

### 6.1 Ce que fait le bouton

Un clic ajuste le référentiel sur les photos ODAT, puis affiche le **journal** des changements : code,
changement, avant, après.

| Changement | Règle |
|---|---|
| **ajoutée** | Chaîne vue dans les photos des **40 derniers jours** et absente du référentiel. Elle entre avec le statut « nouvelle », la catégorie « À qualifier » et sa planification observée. |
| **supprimée** | Chaîne du référentiel **absente des photos depuis plus de 40 jours**, ou jamais vue. Elle passe au statut « supprimée ». |
| **réactivée** | Chaîne « supprimée » **revue** dans les 40 derniers jours. Elle reprend son statut d'origine. |
| **planification** | La planification observée diffère de celle du référentiel. Elle la remplace, **sauf** si la planification a été saisie à la main, si l'observée est vide ou « variable », ou si la chaîne n'est plus vue. |

Les 40 jours se comptent depuis la date de la dernière photo chargée, pas depuis aujourd'hui.

Autres points :

- **La synchronisation est idempotente** : relancée tout de suite, elle ne change plus rien et affiche
  « le plan de production était déjà à jour ».
- **Pensez à importer les derniers fichiers ODAT** dans la barre latérale **avant** de synchroniser.
- **La bible n'est plus relue.** Le rechargement de la bible a été retiré de l'écran.

### 6.2 Quand la lancer

- après chaque import de nouvelles photos ODAT, ou au moins une fois par semaine ;
- systématiquement après une clôture, vers J+16.

### 6.3 Comment la planification est déduite des photos

Seules les exécutions **réellement parties** comptent. Les « Non lancé » sont exclus. On regarde toute la
période où la chaîne apparaît et on teste trois cas, dans cet ordre :

1. **Quotidienne** : la chaîne tourne au moins **60 %** des jours qui ont des photos. Elle est décrite par les
   jours de semaine où elle tourne au moins une fois sur deux, par exemple `lun mar mer jeu ven`.
2. **Hebdomadaire** : un jour de semaine revient au moins **une semaine sur deux**. Exemple : `ven`.
3. **Clôture ou périodique** : les labels J±n qui reviennent au moins **un mois sur deux**. Il faut au moins
   deux mois d'historique. Exemple : `J-5, J-4, J-3`.

Si aucun des trois ne marche, la planification observée vaut **variable** et la synchronisation n'y touche pas.

Réglages, en tête de `plan_prod.py` :

| Constante | Valeur | Rôle |
|---|---|---|
| `SEUIL_QUOTIDIEN` | 0,6 | Part des jours avec photo pour être quotidienne |
| `SEUIL_RECURRENT` | 0,5 | Part des semaines ou des mois où un jour ou un J±n doit revenir |
| `OUBLI_JOURS` | 40 | Absence au-delà de laquelle une chaîne est « plus vue » ou « supprimée » |
| `AVANT`, `APRES` | 7, 16 | Fenêtre J-7 … J+16 |

---

## 7. Onglet Jobs CtrlM : ce qui a changé

- **Une ligne par exécution** à son dernier état, au lieu d'une ligne par photo. Sur FIN-FINANCE, on passe
  d'environ 149 000 lignes à environ 44 000 exécutions.
- **Nouveau statut ⊘ « Non lancé »**, masqué par défaut. Cochez **« Afficher les non lancés »** pour le voir,
  ou choisissez-le dans le filtre Statut.
- **« Non OK uniquement »** n'affiche pas les non lancés.
- **Le « Wait for Event »** n'apparaît plus que pour l'odate en cours.

---

## 8. Exemples commentés

Données de la base au 21/09/2026.

### 8.1 FINEXT_J17GEN_06_M : campagne de règlements TIERS EXPRESS

**Ce que fait la chaîne.** Chaque soir de semaine, elle sélectionne les factures fournisseurs TIERS EXPRESS
à payer. Elle alimente AP Import, produit le fichier de virement, le pousse vers le NAS, puis envoie les avis
de virement par mail. Les jobs s'enchaînent dans cet ordre :

| Heure habituelle | Job | Rôle | Programme Oracle | Durée |
|---|---|---|---|---|
| 23h57 | `FINEXT_J17GEN_06_M` | Conteneur de la chaîne | | ~1h40 |
| 23h57 | `FINEXT_J17GEN_06_WRK01_M` | Règlements automatiques | DKA : Règlements automatiques toutes sociétés des factures fournisseurs | ~1h30 |
| 01h29 (J+1) | `FINEXT_J17GEN_06_WRK02_M` | Alimentation AP Import | DKA : Campagne de règlements - Alimentation des tables AP Import | ~2 min |
| 01h31 (J+1) | `FINEXT_J17GEN_06_EXP01_M` | Création du fichier APIMPORT | DKA : Campagne de règlements - Création du fichier APIMPORT | ~2 min |
| 01h33 (J+1) | `FINEXT_J17GEN_06_MOV01_M` | Dépôt `DK*EXP*.txt` sur le NAS (`MOV_OUT_Generique_DKA.ksh`) | | quelques secondes |
| 01h33 (J+1) | `FINEXT_J17GEN_06_WRK03_M` | Calcul du poids | DKA : Calcul du poids | ~2 min |
| 01h35 (J+1) | `FINEXT_J17GEN_06_MEL01_M` | Avis de virement par mail | DKA_SAPVIRMAIL | ~6 min |

Le **WRK01** porte presque toute la durée : c'est lui qu'il faut surveiller. Si WRK01 échoue, les jobs suivants
ne partent pas.

**Référentiel.** Catégorie Campagne, planification `lun mar mer jeu ven`. La planification observée dans les
ODAT est identique. La règle écrite par Lionel était « Quotidien - Sauf L7, L6, L2, D3, D4 ».
L'ancien plan de production de juin 2025 disait « Quotidien sauf D3, D4, L7, L5 et L1 ».

**Août 2026, jour par jour.**

| Cellule | Jours | Lecture |
|---|---|---|
| ✔ 7 | presque tous les jours de J-7 à J+15 | Les 7 jobs ont tourné et sont terminés OK. |
| ✖ 7 | J-5 (24/08) | WRK01 en erreur à 23h04. Les 5 jobs suivants sont restés Non lancé : **pas de virement TIERS EXPRESS ce soir-là**. |
| ✖ 7 | J-2 (27/08) | Le conteneur et le dépôt NAS (MOV01) en erreur. Les règlements et le fichier ont été produits, mais le fichier n'a peut-être pas atteint le NAS. |
| ○ | J (31/08) | Prévu par `lun…ven`, absent des photos : la chaîne **ne tourne jamais le jour de la clôture**. |
| · | J+16 (22/09) | À venir, après la dernière photo. |

La colonne écarts affiche **−J**.

**Ce que disent les autres mois.**

| Mois | Jours ouvrés sans la chaîne | Incidents |
|---|---|---|
| Mars 2026 | J-5, J-4, J, J+12 | |
| Mai 2026 | J-5, J-4, J | |
| Juin 2026 | J-5, J-4, J | WRK01 en erreur à J-3 et J-2 : deux soirs sans virement. Le 14/07 est férié. |
| Juillet 2026 | J | J+16 (24/08) : c'est le même incident que J-5 d'août. |
| Août 2026 | J | J-5 et J-2 (voir ci-dessus) |

**Conclusions :**
- **La chaîne ne tourne jamais à J (L1).** C'est voulu : l'exclusion « sauf L1 » figurait déjà dans l'ancien plan.
  L'écart −J est donc normal chaque mois.
- **Jusqu'en juin, elle sautait aussi J-5 et J-4 (L6 et L5).** Depuis juillet, elle tourne ces jours-là.
  La règle Control-M a changé entre juin et juillet 2026 : à confirmer avec l'équipe Control-M.
- **Sur tout l'historique**, 130 odates observés, WRK01 est OK dans 98 % des cas, les autres jobs dans 99 à 100 %.
  Les erreurs sont concentrées à l'approche de la clôture, de J-5 à J-2. C'est le moment où la campagne traite
  le plus de factures.
- **Un ✖ sur WRK01 veut dire qu'il n'y a pas eu de virement ce soir-là.** Il faut vérifier la reprise le
  lendemain matin.

### 8.2 FINDTR_J11GEN_06_Q : extraction Datapump pour DTR

**Référentiel.** Catégorie Quotidienne, planification `lun mar mer jeu ven`, 7 jobs. En août 2026, la colonne
écarts affiche **−J-2 −J −J+1 −J+2 −J+9**.

| Jours | Ce que disent les photos |
|---|---|
| J+1, J+2 | La chaîne n'est **pas ordonnancée**, et c'est pareil en mai, juin et juillet. C'est une suspension voulue pendant la clôture. |
| J-2, J, J+9 | La chaîne est ordonnancée mais ses 7 jobs sont restés **⊘ Non lancé**. `FINDTR_J11TEC_04_Q` (2 jobs) n'est pas partie non plus ces jours-là. Elle est probablement en amont et a bloqué l'extraction. C'est à investiguer. |

Ces deux exemples montrent qu'**un écart n'est pas toujours un incident**. Un écart qui revient chaque mois
(−J pour TIERS EXPRESS, −J+1 −J+2 pour DTR) est une règle d'ordonnancement. Notez-la dans la colonne
commentaire du référentiel. Un écart isolé est un incident à expliquer.

---

## 9. Questions fréquentes

**Une chaîne est ○ alors qu'elle a tourné.**
Vérifiez qu'une photo de 7h07 ou 8h07 du lendemain a bien été importée. Tant que seules les photos de 13h46 ou
16h46 sont là, l'exécution de la nuit n'est pas visible.

**Beaucoup de « Plus vue » ou de « Jamais vue » juste après l'installation.**
C'est normal : la bible date de juin 2025. Lancez la synchronisation, elle passera ces chaînes en « supprimée ».

**La synchronisation a modifié une planification que je voulais garder.**
Saisissez-la à la main dans le tableau éditable, puis enregistrez. Elle sera protégée.

**Une chaîne tourne des deux côtés d'un week-end, le samedi une fois et le dimanche la fois suivante.**
La planification observée suit ce que montrent les photos : l'odate Control-M peut être le samedi ou le
dimanche. Corrigez à la main si besoin.

**Les chiffres ne bougent pas après un import.**
Relancez l'application (`run.bat`) : le cache garde l'état précédent tant qu'elle reste ouverte.

---

## 10. Où est le code

| Fichier | Rôle |
|---|---|
| `plan_prod.py` | Calendrier J/L/D, lecture de la bible, grille, synthèse, planification observée, synchronisation |
| `ui_plan_prod.py` | L'écran décrit ici |
| `forecast.py` › `consolider` | Fusion des photos ODAT : une ligne par exécution, « Non lancé », cycliques |
| `ui_jobs_controlm.py` | Onglet Jobs CtrlM |
| Table `pdp_chaines` (`odat.db`) | Le référentiel du plan de production |
| Paramètre `pdp.synchro` (table `parametres`) | Date de la dernière synchronisation |
| `tests/test_plan_prod.py`, `tests/test_ui_plan_prod.py`, `tests/test_consolider.py` | Tests |
