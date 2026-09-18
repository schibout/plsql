# Synthèse du contrôle des virements

Ce document restitue, en langage métier, le résultat du contrôle automatique de la chaîne des virements sur la journée analysée. Il est destiné aux équipes fonctionnelles : chaque contrôle y est expliqué, et chaque écart est accompagné de sa signification concrète et de la suite à donner.

---

## Résultat global

> ### ✅ Conforme
>
> Aucune anomalie n'a été détectée. Tous les virements préparés ont été transmis à la banque, sans perte, sans doublon et sans écart de montant, à chacune des étapes du traitement. Aucune action n'est attendue.

---

## 1. Ce que vérifie ce contrôle

Le contrôle suit chaque virement tout au long de son parcours et s'assure qu'à aucune étape un virement n'a été perdu, ajouté, ou modifié. Il se déroule en trois temps.

**Premier temps — les fichiers sont-ils tous présents ?** On vérifie que chaque fichier attendu dans la journée est bien présent, complet et lisible, à toutes les étapes : le fichier tel qu'il est produit à l'origine, le fichier transformé, le fichier effectivement transmis à la banque, et l'accusé de réception renvoyé par cette dernière.

**Deuxième temps — les montants et les volumes sont-ils conservés ?** On compare, fichier par fichier, le nombre de virements et le montant total à chaque étape : un fichier contenant 40 virements pour 100 000 € au départ doit toujours contenir 40 virements pour 100 000 € à l'arrivée. La vérification est faite sur les fichiers d'origine, puis sur les envois regroupés réellement transmis à la banque (plusieurs fichiers d'origine sont souvent réunis en un seul envoi). Le contrôle descend enfin au niveau du virement individuel : chaque bénéficiaire, chaque montant et chaque coordonnée bancaire sont comparés un à un.

**Troisième temps — la trésorerie a-t-elle bien tout reçu ?** On compare la liste des virements transmis à la banque avec la liste des virements que la trésorerie a importés dans son outil (Quartz) le même jour.

**En parallèle — un même envoi a-t-il été transmis plusieurs fois ?** Tous les fichiers transmis à la banque sur la journée sont comparés entre eux : deux envois portant le même compte payeur et exactement les mêmes virements sont signalés comme un doublon, car les bénéficiaires seraient alors payés deux fois.

---

## 2. Résultat détaillé

| Étape contrôlée | Volume concerné | Résultat |
|---|---|---|
| Présence et complétude des fichiers | 236 fichiers | **Conforme** |
| Montants et volumes sur les fichiers d'origine | 59 fichiers | **Conforme** |
| Montants et volumes sur les envois regroupés vers la banque | 46 envois | **Conforme** |
| Comparaison virement par virement (bénéficiaire, montant, banque) | 205 virements | **Conforme** |
| Envois transmis plusieurs fois à la banque | 59 envois | **Conforme** |
| Rapprochement avec le retour de la trésorerie | — | *Non réalisé : l'export de la trésorerie n'a pas été fourni* |

Montant total transmis à la banque sur la journée : **2 667 877,07 EUR** pour **205 virements**.

---

## Annexe — documents détaillés du dossier

Les fichiers ci-dessous accompagnent cette synthèse et contiennent le détail complet de chaque vérification. Ils s'ouvrent dans Excel.

- **`controle_fichiers.csv`** — la liste de tous les fichiers vérifiés dans la journée, avec pour chacun son statut.
- **`controle_totaux_source.csv`** — pour chaque fichier d'origine, le nombre de virements et le montant total constatés à chaque étape de la préparation.
- **`controle_totaux_edf.csv`** — pour chaque envoi regroupé vers la banque, le nombre de virements et le montant total, comparés à l'accusé de réception bancaire.
- **`controle_lignes_ecarts.csv`** — les différences relevées virement par virement lors de la préparation. **Un fichier vide signifie qu'aucun écart n'a été détecté**, et constitue donc un bon résultat.
- **`controle_quartz_ecarts.csv`** — les virements qui n'ont pas pu être appariés avec le retour de la trésorerie. **Un fichier vide signifie que le rapprochement est parfait**.
- **`controle_doublons_ack.csv`** — les envois vers la banque dont le contenu est identique à un envoi déjà transmis sur la journée. **Un fichier vide signifie qu'aucun envoi n'a été transmis en double**.
