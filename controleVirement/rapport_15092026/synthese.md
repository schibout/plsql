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

**En parallèle — un même envoi a-t-il été transmis plusieurs fois ?** Tous les fichiers transmis à la banque sur la journée sont comparés entre eux : deux envois portant le même compte payeur et exactement les mêmes virements sont signalés comme un doublon, car les bénéficiaires seraient alors payés deux fois.

---

## 2. Résultat détaillé

| Étape contrôlée | Volume concerné | Résultat |
|---|---|---|
| Présence et complétude des fichiers | 1551 fichiers | **Conforme** |
| Montants et volumes sur les fichiers d'origine | 384 fichiers | **À examiner** (1) |
| Montants et volumes sur les envois regroupés vers la banque | 320 envois | **À examiner** (2) |
| Comparaison virement par virement (bénéficiaire, montant, banque) | 3360 virements | **Conforme** |
| Envois transmis plusieurs fois à la banque | 399 envois | **À examiner** (15) |
| Rapprochement avec le retour de la trésorerie | 4229 repris / 4229 envoyés | **Conforme** |

Montant total transmis à la banque sur la journée : **172 517 516,21 EUR** pour **3360 virements**, auxquels s'ajoutent **869 virements** pour **178 172,09 EUR** transmis en double (voir ci-dessous).

Montant total repris par la trésorerie : **172 695 688,30 EUR** pour **4229 virements**.

Les deux listes correspondent exactement, en nombre de virements comme en montant.

---

## 3. Points d'attention

### Envois transmis en double à la banque

**15 envoi(s)** ont été transmis à la banque alors qu'un envoi strictement identique (même compte payeur, mêmes bénéficiaires, mêmes montants) avait déjà été transmis sur la journée. Cela représente **869 virements** pour **178 172,09 EUR** susceptibles d'avoir été payés deux fois. Il faut vérifier sans délai avec la banque si le second envoi a été exécuté et, le cas échéant, engager les demandes de retour de fonds.

| Envoi en double | Identique à l'envoi | Nombre de virements | Montant |
|---|---|---|---|
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033758415.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039548279.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 702 | 141 950,36 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033858416.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039588280.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 9 | 2 873,66 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033938417.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039588281.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 6 | 1 289,70 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033968418.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039618282.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 3 | 344,85 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033988419.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039628283.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 54 | 6 711,09 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033998420.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039738284.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 3 | 512,43 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034008421.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039768285.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 3 | 915,41 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034018422.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039778286.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 6 | 1 111,37 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034028423.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039788287.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 2 | 1 300,00 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034048424.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039798288.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 65 | 19 067,08 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034058425.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039798289.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 1 | 239,26 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034068426.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039808290.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 4 | 432,55 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034078427.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039818291.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 2 | 121,10 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034088428.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039828292.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 1 | 266,65 EUR |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034098429.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315039828293.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | 8 | 1 036,58 EUR |

### Écarts de totaux sur les fichiers d'origine

Pour les fichiers ci-dessous, le nombre de virements ou le montant total ne se retrouve pas à l'identique d'une étape à l'autre de la préparation. Cela signifie qu'un virement a pu être perdu, dupliqué, ou que son montant a été modifié lors de la transformation du fichier.

| Fichier d'origine | Nombre de virements | Montant total |
|---|---|---|
| DK_FIN01_30004-0688DOSGPE-20260915-49040622_20260915-050221.txt | cohérent | **écart** |

### Écarts de totaux sur les envois regroupés vers la banque

Plusieurs fichiers d'origine sont réunis en un seul envoi vers la banque. Pour les envois ci-dessous, le total de l'envoi ne correspond pas à la somme des fichiers qui le composent, ou ne correspond pas à l'accusé de réception de la banque. Le montant réellement débité peut donc différer du montant attendu.

| Envoi vers la banque | Nombre de virements | Montant total |
|---|---|---|
| CDPG.NC4.IMPORT_ACK.DLK_VIR_17894415426818589.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | cohérent | **écart** |
| CDPG.NC4.IMPORT_ACK.DLK_VIR_17894415427218660.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL | cohérent | **écart** |

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
- **`controle_doublons_ack.csv`** — les envois vers la banque dont le contenu est identique à un envoi déjà transmis sur la journée. **Un fichier vide signifie qu'aucun envoi n'a été transmis en double**.
