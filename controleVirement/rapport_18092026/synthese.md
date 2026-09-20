# Synthèse du contrôle des virements

Ce document restitue, en langage métier, le résultat du contrôle automatique de la chaîne des virements sur la journée analysée. Il est destiné aux équipes fonctionnelles : chaque contrôle y est expliqué, et chaque écart est accompagné de sa signification concrète et de la suite à donner.

---

## Résultat global

> ### ✅ Conforme
>
> Aucune anomalie n'a été détectée. Tous les virements préparés ont été transmis à la banque, sans perte, sans doublon et sans écart de montant, à chacune des étapes du traitement. Aucune action n'est attendue.

> 🟠 **1 point(s) à vérifier** ont toutefois été relevés (non bloquants) : voir la section « Points à vérifier » ci-dessous.

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
| Présence et complétude des fichiers | 236 fichiers | **Conforme** |
| Montants et volumes sur les fichiers d'origine | 59 fichiers | **Conforme** |
| Montants et volumes sur les envois regroupés vers la banque | 46 envois | **Conforme** |
| Comparaison virement par virement (bénéficiaire, montant, banque) | 205 virements | **Conforme** |
| Envois transmis plusieurs fois à la banque | 59 envois | **Conforme** |
| Envois se recouvrant partiellement | 59 envois | **Conforme** |
| Virements présents dans plusieurs envois du jour | 59 envois | **Conforme** |
| Virements en double au sein d'un même envoi | 59 envois | **Conforme** |
| Envois ou virements déjà transmis un jour précédent | 1 journée(s) comparée(s) | **Conforme** — 🟠 1 à vérifier |
| Fichiers d'origine rejoués | 59 envois | **Conforme** |
| Contrôles de forme sur les envois | 59 envois | **Conforme** |
| Rapprochement avec le retour de la trésorerie | — | *Non réalisé : l'export de la trésorerie n'a pas été fourni* |

Montant total transmis à la banque sur la journée : **2 667 877,07 EUR** pour **205 virements**.

---

## Points à vérifier (non bloquants)

Les constats ci-dessous ne sont pas des écarts avérés : ils correspondent à des situations qui peuvent être légitimes (paiement récurrent, deux factures de même montant) mais qui méritent un regard. Ils n'empêchent pas la clôture du contrôle.

### Envois ou virements déjà transmis un jour précédent

Les envois de la journée ont été comparés aux journées précédentes disponibles dans le dossier de contrôle. Un envoi identique (ou un fichier de même nom) déjà transmis est bloquant ; un virement isolé déjà payé peut être un paiement récurrent : à vérifier.

**1 constat(s) à vérifier** — détail dans `controle_doublons_historique.csv`.

| guid | fichier | type | date_precedente | fichier_precedent | nb_virements | montant_cts | detail |
|---|---|---|---|---|---|---|---|
| 3693b409347c4c89967976e0924428e1 | CDPG.NC4.IMPORT_ACK.DLK_VIR_17896890395209027.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | VIREMENT_DEJA_ENVOYE | 15092026 | CDPG.NC4.IMPORT_ACK.DLK_VIR_17894285694048294.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | 1 | 1 092,58 EUR | SCI CAJUS / FR7630003033370002005577087 deja paye le 15092026 |

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
