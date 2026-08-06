# Synthèse du contrôle des virements

Ce document restitue, en langage métier, le résultat du contrôle automatique de la chaîne des virements sur la journée analysée. Il est destiné aux équipes fonctionnelles : chaque contrôle y est expliqué, et chaque écart est accompagné de sa signification concrète et de la suite à donner.

---

## Résultat global

> ### ⚠️ Points d'attention détectés
>
> Le contrôle a relevé au moins un écart. Le détail figure dans les sections « Points d'attention » ci-dessous, avec pour chacun son explication et la vérification à mener.

---

## 1. Ce que vérifie ce contrôle

Le contrôle suit chaque virement tout au long de son parcours et s'assure qu'à aucune étape un virement n'a été perdu, ajouté, ou modifié. Il se déroule en trois temps.

**Premier temps — les fichiers sont-ils tous présents ?** On vérifie que chaque fichier attendu dans la journée est bien présent, complet et lisible, à toutes les étapes : le fichier tel qu'il est produit à l'origine, le fichier transformé, le fichier effectivement transmis à la banque, et l'accusé de réception renvoyé par cette dernière.

**Deuxième temps — les montants et les volumes sont-ils conservés ?** On compare, fichier par fichier, le nombre de virements et le montant total à chaque étape : un fichier contenant 40 virements pour 100 000 € au départ doit toujours contenir 40 virements pour 100 000 € à l'arrivée. La vérification est faite sur les fichiers d'origine, puis sur les envois regroupés réellement transmis à la banque (plusieurs fichiers d'origine sont souvent réunis en un seul envoi). Le contrôle descend enfin au niveau du virement individuel : chaque bénéficiaire, chaque montant et chaque coordonnée bancaire sont comparés un à un.

**Troisième temps — la trésorerie a-t-elle bien tout reçu ?** On compare la liste des virements transmis à la banque avec la liste des virements que la trésorerie a importés dans son outil (Quartz) le même jour.

---

## 2. Résultat détaillé

| Étape contrôlée | Volume concerné | Résultat |
|---|---|---|
| Présence et complétude des fichiers | 208 fichiers | **Conforme** |
| Montants et volumes sur les fichiers d'origine | 52 fichiers | **Conforme** |
| Montants et volumes sur les envois regroupés vers la banque | 43 envois | **Conforme** |
| Comparaison virement par virement (bénéficiaire, montant, banque) | 322 virements | **Conforme** |
| Rapprochement avec le retour de la trésorerie | 323 repris / 322 envoyés | **À examiner** (1) |

Montant total transmis à la banque sur la journée : **2 105 846,52 EUR** pour **322 virements**.

Montant total repris par la trésorerie : **2 221 308,85 EUR** pour **323 virements**.

Différence entre les deux : **+1 virement(s)** et **115 462,33 EUR** de plus côté trésorerie. Cette différence est détaillée dans la section correspondante ci-dessous.

---

## 3. Points d'attention

### Écarts avec le retour de la trésorerie

Les virements ci-dessous n'ont pas pu être appariés entre ce que nous avons transmis à la banque et ce que la trésorerie a importé sur la même journée.

| Nature de l'écart | Montant | Détail |
|---|---|---|
| Virement repris par la trésorerie sans envoi correspondant du jour | 115 462,33 EUR | importe par Quartz ('SDC BAT 51 A 151') mais non envoye |

---

## 4. Comprendre les écarts relevés

Pour chaque nature d'écart apparaissant ci-dessus, voici ce que cela signifie concrètement et l'impact potentiel.

**Virement repris par la trésorerie sans envoi correspondant du jour**

La trésorerie a importé un virement qui ne fait pas partie des virements émis sur la journée contrôlée. Il s'agit le plus souvent d'un virement d'une journée précédente repris avec du retard, à confirmer avec la trésorerie.

---

## 5. Suite à donner

Les écarts listés ci-dessus doivent être qualifiés avant de pouvoir clôturer le contrôle de la journée. Deux issues sont possibles pour chacun d'eux.

**L'écart est expliqué** — par exemple un virement d'une journée précédente repris avec du retard par la trésorerie, ou un décalage de reprise connu. Dans ce cas aucune correction n'est nécessaire : le contrôle peut être clôturé en « écart expliqué », en conservant la trace de la justification.

**L'écart n'est pas expliqué** — un virement reste introuvable, ou un montant ne se justifie pas. Il faut alors ouvrir une analyse avec l'exploitation et, selon le cas, avec la trésorerie ou la banque, avant toute nouvelle émission.

---

## Annexe — documents détaillés du dossier

Les fichiers ci-dessous accompagnent cette synthèse et contiennent le détail complet de chaque vérification. Ils s'ouvrent dans Excel.

- **`controle_fichiers.csv`** — la liste de tous les fichiers vérifiés dans la journée, avec pour chacun son statut.
- **`controle_totaux_source.csv`** — pour chaque fichier d'origine, le nombre de virements et le montant total constatés à chaque étape de la préparation.
- **`controle_totaux_edf.csv`** — pour chaque envoi regroupé vers la banque, le nombre de virements et le montant total, comparés à l'accusé de réception bancaire.
- **`controle_lignes_ecarts.csv`** — les différences relevées virement par virement lors de la préparation. **Un fichier vide signifie qu'aucun écart n'a été détecté**, et constitue donc un bon résultat.
- **`controle_quartz_ecarts.csv`** — les virements qui n'ont pas pu être appariés avec le retour de la trésorerie. **Un fichier vide signifie que le rapprochement est parfait**.
