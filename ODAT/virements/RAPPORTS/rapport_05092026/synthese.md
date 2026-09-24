# Synthèse du contrôle des virements

Ce document restitue, en langage métier, le résultat du contrôle automatique de la chaîne des virements sur la journée analysée. Il est destiné aux équipes fonctionnelles : chaque contrôle y est expliqué, et chaque écart est accompagné de sa signification concrète et de la suite à donner.

---

## Résultat global

> ### ✅ Conforme
>
> Aucune anomalie n'a été détectée. Tous les virements préparés ont été transmis à la banque, sans perte, sans doublon et sans écart de montant, à chacune des étapes du traitement. Aucune action n'est attendue.

> ℹ️ **Contrôle réalisé sur le dossier cible seul** : le dossier source (fichiers DK en euros) n'a pas été fourni. Les vérifications portent sur les fichiers préparés (DK_FIN01), les envois à la banque, le CSV Oracle et, le cas échéant, le retour de la trésorerie.

> 🟠 **2 point(s) à vérifier** ont toutefois été relevés (non bloquants) : voir la section « Points à vérifier » ci-dessous.

---

## 1. Ce que vérifie ce contrôle

Le contrôle suit chaque virement tout au long de son parcours et s'assure qu'à aucune étape un virement n'a été perdu, ajouté, ou modifié. Il se déroule en trois temps.

**Premier temps — les fichiers sont-ils tous présents ?** On vérifie que chaque fichier attendu dans la journée est bien présent, complet et lisible, à toutes les étapes : le fichier tel qu'il est produit à l'origine, le fichier transformé, le fichier effectivement transmis à la banque, et l'accusé de réception renvoyé par cette dernière.

**Deuxième temps — les montants et les volumes sont-ils conservés ?** On compare, fichier par fichier, le nombre de virements et le montant total à chaque étape : un fichier contenant 40 virements pour 100 000 € au départ doit toujours contenir 40 virements pour 100 000 € à l'arrivée. La vérification est faite sur les fichiers d'origine, puis sur les envois regroupés réellement transmis à la banque (plusieurs fichiers d'origine sont souvent réunis en un seul envoi). Le contrôle descend enfin au niveau du virement individuel : chaque bénéficiaire, chaque montant et chaque coordonnée bancaire sont comparés un à un.

**Troisième temps — la trésorerie a-t-elle bien tout reçu ?** On compare la liste des virements transmis à la banque avec la liste des virements que la trésorerie a importés dans son outil (Quartz) le même jour.

**En parallèle — un même envoi a-t-il été transmis plusieurs fois ?** Tous les fichiers transmis à la banque sur la journée sont comparés entre eux : deux envois portant le même compte payeur et exactement les mêmes virements sont signalés comme un doublon, car les bénéficiaires seraient alors payés deux fois. La recherche de doublons est complétée par : les envois qui se recouvrent partiellement, les virements présents dans plusieurs envois du jour, les virements répétés dans un même envoi, les envois déjà transmis un jour précédent, et les fichiers d'origine rejoués. Des contrôles de forme (signature, compte payeur, IBAN, montants) complètent l'ensemble.

---

## 2. Résultat détaillé

| Étape contrôlée | Volume concerné | Résultat |
|---|---|---|
| Présence et complétude des fichiers | 114 fichiers | **Conforme** |
| Montants et volumes sur les fichiers d'origine | 57 fichiers | **Conforme** |
| Montants et volumes sur les envois regroupés vers la banque | 45 envois | **Conforme** |
| Comparaison virement par virement (bénéficiaire, montant, banque) | 262 virements | **Conforme** |
| Envois transmis plusieurs fois à la banque | 57 envois | **Conforme** |
| Envois se recouvrant partiellement | 57 envois | **Conforme** |
| Virements présents dans plusieurs envois du jour | 57 envois | **Conforme** |
| Virements en double au sein d'un même envoi | 57 envois | **Conforme** |
| Envois ou virements déjà transmis un jour précédent | 3 journée(s) comparée(s) | **Conforme** — 🟠 2 à vérifier |
| Fichiers d'origine rejoués | 57 envois | **Conforme** |
| Contrôles de forme sur les envois | 57 envois | **Conforme** |
| Rapprochement avec le retour de la trésorerie | — | *Non réalisé : l'export de la trésorerie n'a pas été fourni* |

Montant total transmis à la banque sur la journée : **4 740 238,82 EUR** pour **262 virements**.

---

## Points à vérifier (non bloquants)

Les constats ci-dessous ne sont pas des écarts avérés : ils correspondent à des situations qui peuvent être légitimes (paiement récurrent, deux factures de même montant) mais qui méritent un regard. Ils n'empêchent pas la clôture du contrôle.

### Envois ou virements déjà transmis un jour précédent

Les envois de la journée ont été comparés aux journées précédentes disponibles dans le dossier de contrôle. Un envoi identique (ou un fichier de même nom) déjà transmis est bloquant ; un virement isolé déjà payé peut être un paiement récurrent : à vérifier.

**2 constat(s) à vérifier** — détail dans `controle_doublons_historique.csv`.

| guid | fichier | type | date_precedente | fichier_precedent | nb_virements | montant_cts | detail |
|---|---|---|---|---|---|---|---|
| 0e0c86f1016e4fd59dc4305967a4b691 | CDPG.NC4.IMPORT_ACK.DLK_VIR_17885660970907302.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | VIREMENT_DEJA_ENVOYE | 02092026 | CDPG.NC4.IMPORT_ACK.DLK_VIR_17883113155457055.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | 1 | 72,00 EUR | OFFICE - ALLIANCE / FR7630004008240001012087537 deja paye le 02092026 |
| 0e0c86f1016e4fd59dc4305967a4b691 | CDPG.NC4.IMPORT_ACK.DLK_VIR_17885660970907302.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | VIREMENT_DEJA_ENVOYE | 02092026 | CDPG.NC4.IMPORT_ACK.DLK_VIR_17883113155457055.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | 1 | 307,92 EUR | ONET SERVICES / FR1230002029350000060261S04 deja paye le 02092026 |

---

## Annexe — documents détaillés du dossier

Les fichiers ci-dessous accompagnent cette synthèse et contiennent le détail complet de chaque vérification. Ils s'ouvrent dans Excel.

- **`controle_fichiers.csv`** — la liste de tous les fichiers vérifiés dans la journée, avec pour chacun son statut.
- **`controle_totaux_source.csv`** — pour chaque fichier d'origine, le nombre de virements et le montant total constatés à chaque étape de la préparation.
- **`controle_totaux_edf.csv`** — pour chaque envoi regroupé vers la banque, le nombre de virements et le montant total, comparés à l'accusé de réception bancaire.
- **`controle_lignes_ecarts.csv`** — les différences relevées virement par virement lors de la préparation. **Un fichier vide signifie qu'aucun écart n'a été détecté**, et constitue donc un bon résultat.
- **`controle_quartz_ecarts.csv`** — les virements qui n'ont pas pu être appariés avec le retour de la trésorerie. **Un fichier vide signifie que le rapprochement est parfait**.
- **`controle_doublons_ack.csv`** — les envois vers la banque dont le contenu est identique à un envoi déjà transmis sur la journée. **Un fichier vide signifie qu'aucun envoi n'a été transmis en double**.
- **`controle_doublons_virements.csv`** — le détail, virement par virement (bénéficiaire, IBAN, BIC, montant), des envois transmis en double : la liste à communiquer à la banque pour les demandes de retour de fonds.
- **`controle_doublons_croises.csv`** — envois se recouvrant partiellement. **Un fichier vide est un bon résultat.**
- **`controle_doublons_virements_jour.csv`** — virements présents dans plusieurs envois du jour. **Un fichier vide est un bon résultat.**
- **`controle_doublons_intra_envoi.csv`** — virements en double au sein d'un même envoi. **Un fichier vide est un bon résultat.**
- **`controle_doublons_historique.csv`** — envois ou virements déjà transmis un jour précédent. **Un fichier vide est un bon résultat.**
- **`controle_doublons_sources.csv`** — fichiers d'origine rejoués. **Un fichier vide est un bon résultat.**
- **`controle_sanite.csv`** — contrôles de forme sur les envois. **Un fichier vide est un bon résultat.**
