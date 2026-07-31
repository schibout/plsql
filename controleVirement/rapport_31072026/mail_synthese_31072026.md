# Contrôle des virements – journée du 31 juillet 2026

**Objet du mail :** Contrôle des virements du 31/07/2026 – un point à valider avec la trésorerie

Bonjour,

Vous trouverez ci-dessous la synthèse du contrôle automatique des virements réalisé sur la journée du **31 juillet 2026**.

En résumé : **la chaîne de production des virements s'est déroulée sans aucune anomalie**. L'ensemble des virements préparés a bien été transmis à la banque, sans perte, sans doublon et sans écart de montant, à aucune étape.

Un seul point reste à valider : lors du rapprochement avec le retour de la trésorerie (Quartz), **un virement supplémentaire apparaît côté trésorerie alors qu'il ne fait pas partie des virements émis ce jour-là**. Notre analyse montre qu'il s'agit très probablement d'un virement du **29 juillet** repris avec un décalage, et non d'une anomalie de la journée. Nous avons besoin d'une confirmation de la trésorerie pour clôturer définitivement le contrôle.

Le détail est présenté ci-après.

---

## 1. Ce que le contrôle vérifie

Le contrôle suit un virement tout au long de son parcours, et vérifie à chaque étape que rien n'a été perdu, ajouté ou modifié. Concrètement, il se déroule en trois temps.

**Premier temps – les fichiers sont-ils tous là ?**
On vérifie que chaque fichier attendu dans la journée est bien présent, complet et lisible, à toutes les étapes du traitement : le fichier tel qu'il est produit à l'origine, le fichier transformé, puis le fichier effectivement transmis à la banque, ainsi que l'accusé de réception renvoyé par cette dernière.

**Deuxième temps – les montants et les virements sont-ils conservés ?**
On compare, fichier par fichier, le nombre de virements et le montant total à chaque étape. Un fichier qui contiendrait 40 virements pour 100 000 € au départ doit toujours contenir 40 virements pour 100 000 € à l'arrivée. Ce contrôle est fait à deux niveaux : d'abord sur les fichiers d'origine, ensuite sur les fichiers regroupés qui sont réellement envoyés à la banque (plusieurs fichiers d'origine sont souvent réunis en un seul envoi). Enfin, le contrôle descend au niveau du virement individuel : chaque bénéficiaire et chaque montant sont comparés un à un.

**Troisième temps – la trésorerie a-t-elle bien tout reçu ?**
On compare la liste des virements que nous avons envoyés avec la liste des virements que la trésorerie a importés dans son outil (Quartz) le même jour. C'est ce dernier rapprochement, et lui seul, qui fait ressortir un écart aujourd'hui.

---

## 2. Résultat de la journée

| Étape contrôlée | Volume concerné | Résultat |
|---|---|---|
| Présence et complétude des fichiers | 208 fichiers | **Conforme** – aucun fichier manquant ou incomplet |
| Montants et volumes sur les fichiers d'origine | 52 fichiers | **Conforme** – aucun écart |
| Montants et volumes sur les envois regroupés vers la banque | 43 envois | **Conforme** – aucun écart |
| Comparaison virement par virement (bénéficiaire et montant) | 322 virements | **Conforme** – aucun écart |
| Rapprochement avec le retour de la trésorerie | 323 reçus / 322 envoyés | **À valider** – 1 écart |

Ce qui a été envoyé à la banque le 31/07/2026 : **322 virements, pour un total de 2 105 846,52 €**.

Ce que la trésorerie a importé le 31/07/2026 : **323 virements, pour un total de 2 221 308,85 €**.

L'écart est donc de **un virement de plus** côté trésorerie, pour **115 462,33 €** — et cet écart s'explique intégralement par une seule ligne, décrite ci-dessous. Il n'y a pas d'autre différence : à l'exception de cette ligne, les deux listes se correspondent parfaitement.

---

## 3. Le virement concerné

| Élément | Valeur |
|---|---|
| Bénéficiaire | SDC BAT 51 A 151 |
| Montant | 115 462,33 € |
| Compte à débiter | 0577IF513118 – SARCELLES ENERGIE – Société Générale – EUR |
| Site concerné | Site SARCELLES |
| Référence du virement | 4VSEP000451DALKDAL4861553100 |
| Banque | Société Générale |
| Date portée par le virement | **29 juillet 2026** |
| Date d'import par la trésorerie | 31 juillet 2026 |

---

## 4. Notre analyse

Ce virement **n'existe nulle part dans les fichiers de la journée du 31 juillet**. Nous avons recherché aussi bien le montant (115 462,33 €) que le nom du bénéficiaire (« SDC BAT 51 A 151 ») dans la totalité des fichiers de la journée, à toutes les étapes du traitement : aucune correspondance. Ce n'est donc ni un virement du jour qui aurait été compté deux fois, ni un virement mal regroupé lors de la préparation de l'envoi.

L'élément déterminant est la **date portée par le virement lui-même**. Chaque virement conserve la trace de la journée de production dont il est issu. Sur les 323 virements importés par la trésorerie le 31 juillet :

- 137 proviennent de la production du **31 juillet** ;
- 185 proviennent de la production du **30 juillet** — ce qui est le fonctionnement normal, la trésorerie reprenant couramment les virements de la veille ;
- **1 seul provient de la production du 29 juillet** : c'est exactement notre ligne en écart.

Autrement dit, ce virement a été émis deux jours plus tôt et n'a été repris par la trésorerie que le 31 juillet. Comme le contrôle du 31 juillet ne compare le retour de la trésorerie qu'aux virements émis ce jour-là, cette ligne apparaît mécaniquement « en trop », sans qu'il y ait pour autant d'anomalie dans notre chaîne de production.

**En clair : il s'agit très probablement d'un simple décalage de reprise côté trésorerie, et non d'un problème sur la production des virements.**

Nous formulons cette conclusion comme une hypothèse forte, et non comme une certitude : pour la confirmer, il faut vérifier que ce virement figure bien dans les envois du 29 juillet, ce qui sort du périmètre du contrôle de cette journée.

---

## 5. Ce que nous vous demandons

**Une vérification auprès de la trésorerie**, portant sur le virement référencé `4VSEP000451DALKDAL4861553100` (SDC BAT 51 A 151, 115 462,33 €) :

**Si ce virement figure bien dans les envois du 29 juillet** et n'avait pas été importé à cette date, l'écart est expliqué et justifié. Aucune correction n'est nécessaire, et le contrôle du 31 juillet peut être clôturé en « écart expliqué ». Il conviendra simplement de garder à l'esprit que ce virement a été traité avec deux jours de décalage.

**Si ce virement ne figure dans aucun de nos envois**, la situation change de nature : cela signifierait qu'un virement a été importé par la trésorerie sans avoir été émis de notre côté. Il faudrait alors ouvrir une analyse spécifique avec la trésorerie et la banque, car le montant en jeu est significatif.

Nous restons à votre disposition pour tout complément d'information.

Bien cordialement,

---

## Annexe – documents disponibles

Le dossier `rapport_31072026` contient l'ensemble des éléments détaillés qui appuient cette synthèse :

- **`synthese.md`** – la synthèse chiffrée du contrôle
- **`controle_fichiers.csv`** – le détail des 208 fichiers vérifiés, avec leur statut
- **`controle_totaux_source.csv`** – les volumes et montants contrôlés sur chacun des 52 fichiers d'origine
- **`controle_totaux_edf.csv`** – les volumes et montants contrôlés sur chacun des 43 envois regroupés vers la banque
- **`controle_lignes_ecarts.csv`** – les écarts constatés virement par virement lors de la préparation : **ce fichier est vide, ce qui signifie qu'aucun écart n'a été détecté**
- **`controle_quartz_ecarts.csv`** – l'écart avec le retour de la trésorerie, c'est-à-dire l'unique ligne décrite dans ce mail
