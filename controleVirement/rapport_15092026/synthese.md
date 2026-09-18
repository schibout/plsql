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
| Présence et complétude des fichiers | 1551 fichiers | **À examiner** (15) |
| Montants et volumes sur les fichiers d'origine | 384 fichiers | **À examiner** (1) |
| Montants et volumes sur les envois regroupés vers la banque | 320 envois | **À examiner** (2) |
| Comparaison virement par virement (bénéficiaire, montant, banque) | 3360 virements | **Conforme** |
| Rapprochement avec le retour de la trésorerie | 4229 repris / 3360 envoyés | **À examiner** (973) |

Montant total transmis à la banque sur la journée : **172 517 516,21 EUR** pour **3360 virements**.

Montant total repris par la trésorerie : **172 695 688,30 EUR** pour **4229 virements**.

Différence entre les deux : **+869 virement(s)** et **178 172,09 EUR** de plus côté trésorerie. Cette différence est détaillée dans la section correspondante ci-dessous.

---

## 3. Points d'attention

### Fichiers manquants ou incomplets

Les fichiers ci-dessous étaient attendus dans la journée mais n'ont pas été trouvés, ou n'ont pas pu être exploités. Tant que ce point n'est pas levé, une partie des virements de la journée n'est pas contrôlée : il faut vérifier avec l'exploitation que le traitement s'est bien déroulé jusqu'au bout.

| Fichier | Étape concernée | Constat |
|---|---|---|
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033758415.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033858416.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033938417.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033968418.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033988419.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315033998420.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034008421.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034018422.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034028423.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034048424.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034058425.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034068426.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034078427.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034088428.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |
| `CDPG.NC4.IMPORT_ACK.DLK_VIR_17894315034098429.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL` | ACK | ORPHELIN — present mais non reference par Oracle |

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

### Écarts avec le retour de la trésorerie

Les virements ci-dessous n'ont pas pu être appariés entre ce que nous avons transmis à la banque et ce que la trésorerie a importé sur la même journée.

| Nature de l'écart | Montant | Détail |
|---|---|---|
| Virement repris par la trésorerie sans envoi correspondant du jour | 1,70 EUR | importe par Quartz ('QUIDOR DIT PASQUET NICOL') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 2,50 EUR | importe par Quartz ('CHENEVOY NOE 77396L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 3,60 EUR | importe par Quartz ('DEBARD SANDRA 75190J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 4,20 EUR | importe par Quartz ('BOCCO KOMIVI BOGA 77892P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 4,30 EUR | importe par Quartz ('MATHIEU JEAN-YVES 74216C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 4,80 EUR | importe par Quartz ('DAUTRICHE REMY 74994B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 5,10 EUR | importe par Quartz ('HONDE LAETITIA 73957L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 5,22 EUR | importe par Quartz ('DUBOIS CLEMENT 77846D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 5,60 EUR | importe par Quartz ('DARTHUY ELIETTE 61776J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 6,00 EUR | importe par Quartz ('BERGERET MANON 75474H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 6,10 EUR | importe par Quartz ('CHARRETON YANNICK 70306H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 6,42 EUR | importe par Quartz ('FADEL NABIL 69805Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 6,93 EUR | importe par Quartz ('TIETTO JOSEPH 72213S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 7,99 EUR | importe par Quartz ('BLANLOEIL JOEL 38373R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 8,80 EUR | importe par Quartz ('SY OUMAR 77614Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 9,00 EUR | importe par Quartz ('CHEVALIER ALEXANDRE 6582') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 9,59 EUR | importe par Quartz ('SZYMKOWSKI YVAN 65385H') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 10,00 EUR | cible='LAROUM MAHIEDDINE 45454H' quartz='JEROME JOHANN 68373P' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 10,00 EUR | importe par Quartz ('LAROUM MAHIEDDINE 45454H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 10,00 EUR | importe par Quartz ('LAROUM MAHIEDDINE 45454H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 10,40 EUR | importe par Quartz ('PERLIN RONAN 68727E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 10,50 EUR | importe par Quartz ('KOUASSI BEDJRAN MARTIAL') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 10,60 EUR | importe par Quartz ('BONTHOUX ERIC 71271C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 11,08 EUR | importe par Quartz ('AVRIL ALEXANDRE 49296N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 11,20 EUR | importe par Quartz ('LARTIGUE DIDIER 21134H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 11,46 EUR | importe par Quartz ('MANSION JULIEN 73929A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 11,60 EUR | importe par Quartz ('POL GREGORY 60787H') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 12,00 EUR | cible='MINET CORENTIN 73677T' quartz='FRANCOMME THOMAS 42564E' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 12,00 EUR | importe par Quartz ('MINET CORENTIN 73677T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 12,00 EUR | importe par Quartz ('MINET CORENTIN 73677T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 12,40 EUR | importe par Quartz ('CHEVEE FABIEN 75217W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 12,68 EUR | importe par Quartz ('MANSION EMILIE 65619R') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 12,90 EUR | cible='MARCUS BENJAMIN 66859Y' quartz='BOUCHEUR GILLES 71558E' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 12,90 EUR | importe par Quartz ('MARCUS BENJAMIN 66859Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 12,90 EUR | importe par Quartz ('MARCUS BENJAMIN 66859Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 13,12 EUR | importe par Quartz ('CANDIDO JEAN-PHILIPPE 77') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 13,20 EUR | importe par Quartz ('LAZARE CAMILLE 76133A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 13,30 EUR | importe par Quartz ('GONAN GEORGES 56961Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 13,50 EUR | importe par Quartz ('BALLET CYRILLE 76224W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 13,66 EUR | importe par Quartz ('GARCIA-MENDEZ LIONEL 475') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,00 EUR | importe par Quartz ('MAJERI SABRI 73562S') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 14,20 EUR | cible='TABET ELYESS 68756T' quartz='EZZAIDI MOHAMED 78052A' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,20 EUR | importe par Quartz ('TABET ELYESS 68756T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,20 EUR | importe par Quartz ('TABET ELYESS 68756T') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 14,40 EUR | cible='DA SILVA MARTINS PAULO 5' quartz='BURBAN FLORIAN 72988L' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,40 EUR | importe par Quartz ('DA SILVA MARTINS PAULO 5') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,40 EUR | importe par Quartz ('DA SILVA MARTINS PAULO 5') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,50 EUR | importe par Quartz ('FURLANO ANTONIO 76157F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,70 EUR | importe par Quartz ('VIVIER BENOIT 43094C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 14,84 EUR | importe par Quartz ('AMRI YOUCEF 72656A') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 15,00 EUR | cible='FANTIN XAVIER 74257F' quartz='CHAUVAUX JEAN CYRIL 2124' |
| Nom du bénéficiaire différent d'une étape à l'autre | 15,00 EUR | cible='RODA CHARLIE 64456K' quartz='FANTIN XAVIER 74257F' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 15,00 EUR | importe par Quartz ('FANTIN XAVIER 74257F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 15,00 EUR | importe par Quartz ('RODA CHARLIE 64456K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 15,00 EUR | importe par Quartz ('RODA CHARLIE 64456K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 15,50 EUR | importe par Quartz ('BELINGARD DENIS 55983L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 15,55 EUR | importe par Quartz ('DELENCLOS LOIS 71891T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 15,95 EUR | importe par Quartz ('SERSERI NATHALIE 53609N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,20 EUR | importe par Quartz ('MECHARA RAMZI 50671Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,41 EUR | importe par Quartz ('MARCHAL FREDERIC 51820J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,43 EUR | importe par Quartz ('FORTIN VINCENT 71533Y') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 16,50 EUR | cible='DOGAN ENZO 74988T' quartz='CHABLE AXEL 74956B' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,50 EUR | importe par Quartz ('DOGAN ENZO 74988T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,50 EUR | importe par Quartz ('DOGAN ENZO 74988T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,80 EUR | importe par Quartz ('THAYAHARAN THANUJAN 6579') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 16,90 EUR | cible='DHONDT BENOIT 76006H' quartz='BRESO CELIA 75024R' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,90 EUR | importe par Quartz ('DHONDT BENOIT 76006H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,90 EUR | importe par Quartz ('DHONDT BENOIT 76006H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 16,98 EUR | importe par Quartz ('DE FARIA ALOIS 73485R') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 17,00 EUR | cible='NOUSSIBOUE PAUL 65144R' quartz='HOUDEMONT RICHARD 70276T' |
| Nom du bénéficiaire différent d'une étape à l'autre | 17,00 EUR | cible='SOUFFLET MICHAEL 75399J' quartz='NOUSSIBOUE PAUL 65144R' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 17,00 EUR | importe par Quartz ('NOUSSIBOUE PAUL 65144R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 17,00 EUR | importe par Quartz ('SOUFFLET MICHAEL 75399J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 17,00 EUR | importe par Quartz ('SOUFFLET MICHAEL 75399J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 17,10 EUR | importe par Quartz ('CADET DAVID 74298K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 18,40 EUR | importe par Quartz ('LEBRETON PIERRE 61269S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 19,40 EUR | importe par Quartz ('DELSART GAUTIER 72739J') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 19,50 EUR | cible='VAUCOULEUR JIMMY 44028F' quartz='L'HOMEL CORALIE 76450S' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 19,50 EUR | importe par Quartz ('VAUCOULEUR JIMMY 44028F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 19,50 EUR | importe par Quartz ('VAUCOULEUR JIMMY 44028F') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 19,90 EUR | cible='OLIVIER JEAN-LUC 74313E' quartz='AFKIR AZEDDINE 76402D' |
| Nom du bénéficiaire différent d'une étape à l'autre | 19,90 EUR | cible='SIMOES JEREMY 65588A' quartz='OLIVIER JEAN-LUC 74313E' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 19,90 EUR | importe par Quartz ('OLIVIER JEAN-LUC 74313E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 19,90 EUR | importe par Quartz ('SIMOES JEREMY 65588A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 19,90 EUR | importe par Quartz ('SIMOES JEREMY 65588A') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 20,00 EUR | cible='DUFRANNE JULIE 68973D' quartz='BARROQUEIRO PASCAL 70220' |
| Nom du bénéficiaire différent d'une étape à l'autre | 20,00 EUR | cible='GARITEY FRANCK 73193F' quartz='DUFRANNE JULIE 68973D' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,00 EUR | importe par Quartz ('DUFRANNE JULIE 68973D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,00 EUR | importe par Quartz ('GARITEY FRANCK 73193F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,00 EUR | importe par Quartz ('GARITEY FRANCK 73193F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,13 EUR | importe par Quartz ('CHOMONT JULIEN 65489W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,40 EUR | importe par Quartz ('DOUARD JULIE 75968H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,69 EUR | importe par Quartz ('MARTY PASCAL 35690K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,85 EUR | importe par Quartz ('LE ROCHAIS GUILLAUME 693') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 20,90 EUR | cible='LEGRAND ARNAUD 67451B' quartz='EL MOUQUADDEM BENZALOUH' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,90 EUR | importe par Quartz ('LEGRAND ARNAUD 67451B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 20,90 EUR | importe par Quartz ('LEGRAND ARNAUD 67451B') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 21,00 EUR | cible='ISOLA PIERRE 69704R' quartz='BESSEGHIER ABDELAZIZ 705' |
| Nom du bénéficiaire différent d'une étape à l'autre | 21,00 EUR | cible='MALLET - LEPRETRE SERRUR' quartz='ISOLA PIERRE 69704R' |
| Nom du bénéficiaire différent d'une étape à l'autre | 21,00 EUR | cible='RATOUIT LINDSAY 76963S' quartz='ISOLA PIERRE 69704R' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,00 EUR | importe par Quartz ('MALLET - LEPRETRE SERRUR') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,00 EUR | importe par Quartz ('RATOUIT LINDSAY 76963S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,00 EUR | importe par Quartz ('RATOUIT LINDSAY 76963S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,32 EUR | importe par Quartz ('DOMENECH LOZANO JOHANN 4') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,37 EUR | importe par Quartz ('VERNIER LAURENT 57546T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,50 EUR | importe par Quartz ('CHAUVEL SYLVAIN 66752F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,58 EUR | importe par Quartz ('PERRAUDIN MICKAEL 74603L') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 21,70 EUR | cible='MAHIEU DYLAN 64143Z' quartz='FERRAND JIMMY 73510Z' |
| Nom du bénéficiaire différent d'une étape à l'autre | 21,70 EUR | cible='MEZERGUES ROMAIN 71499C' quartz='MAHIEU DYLAN 64143Z' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,70 EUR | importe par Quartz ('MAHIEU DYLAN 64143Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,70 EUR | importe par Quartz ('MEZERGUES ROMAIN 71499C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 21,70 EUR | importe par Quartz ('MEZERGUES ROMAIN 71499C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,30 EUR | importe par Quartz ('VILLEMINOT JEROME 77163E') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 22,50 EUR | cible='TAILLANDIER MICKAEL 5798' quartz='LIZEAU ARTHUR 76783E' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,50 EUR | importe par Quartz ('TAILLANDIER MICKAEL 5798') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,50 EUR | importe par Quartz ('TAILLANDIER MICKAEL 5798') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,60 EUR | importe par Quartz ('SAADA FABRICE 63703W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,65 EUR | importe par Quartz ('TARTAGLIA XAVIER 60902J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,80 EUR | importe par Quartz ('POIZAT FABRICE 36941F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,90 EUR | importe par Quartz ('SERRE DORIAN 72622E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 22,94 EUR | importe par Quartz ('GUELENNOC DOMINIQUE 6732') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 23,00 EUR | cible='MENAGE HERVE 39777N' quartz='DEVULDER BRUNO 07808Z' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,00 EUR | importe par Quartz ('MENAGE HERVE 39777N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,00 EUR | importe par Quartz ('MENAGE HERVE 39777N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,21 EUR | importe par Quartz ('OLLIVIER SEBASTIEN 73031') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,30 EUR | importe par Quartz ('PERRIN GUILLAUME 51676W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,35 EUR | importe par Quartz ('DAUPHIN QUENTIN 53293Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,50 EUR | importe par Quartz ('CASTRO VICTOR 42803W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,60 EUR | importe par Quartz ('M BOUP MAODO 74552W') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 23,70 EUR | cible='BEN REGUIGA ABDELKADER 6' quartz='BAILLANCOURT JEAN PIERRE' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,70 EUR | importe par Quartz ('BEN REGUIGA ABDELKADER 6') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,70 EUR | importe par Quartz ('BEN REGUIGA ABDELKADER 6') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 23,80 EUR | cible='LECOUTURIER SEBASTIEN 61' quartz='DE MONTARD ETIENNE 64827' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,80 EUR | importe par Quartz ('LECOUTURIER SEBASTIEN 61') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,80 EUR | importe par Quartz ('LECOUTURIER SEBASTIEN 61') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,82 EUR | importe par Quartz ('ESTHER GUILLAUME 75320E') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 23,90 EUR | cible='DIALLO ALSENY 67295X' quartz='BENADEL KHALIL 67833D' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,90 EUR | importe par Quartz ('DIALLO ALSENY 67295X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 23,90 EUR | importe par Quartz ('DIALLO ALSENY 67295X') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 24,00 EUR | cible='MASSAMBA KISOKA 56752Z' quartz='AISSAOUI MOHAMED 69530L' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,00 EUR | importe par Quartz ('MASSAMBA KISOKA 56752Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,00 EUR | importe par Quartz ('MASSAMBA KISOKA 56752Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,26 EUR | importe par Quartz ('SULIN ERIC 63193Z') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 24,30 EUR | cible='ROUSSEY REMY 43345H' quartz='MURANO THIBAUT 75821P' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,30 EUR | importe par Quartz ('ROUSSEY REMY 43345H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,30 EUR | importe par Quartz ('ROUSSEY REMY 43345H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,60 EUR | importe par Quartz ('RIOU FAUSTIN 78041K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,78 EUR | importe par Quartz ('NGUYEN VAN HUU OLIVIER 6') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 24,90 EUR | importe par Quartz ('BONNIN NICOLAS 55872R') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 25,00 EUR | cible='CALLAC RONAN 72777J' quartz='BOYER JEAN MICHEL 61043W' |
| Nom du bénéficiaire différent d'une étape à l'autre | 25,00 EUR | cible='HUGUET FREDERIC 72949K' quartz='CALLAC RONAN 72777J' |
| Nom du bénéficiaire différent d'une étape à l'autre | 25,00 EUR | cible='MACIA SAM 72200A' quartz='CALLAC RONAN 72777J' |
| Nom du bénéficiaire différent d'une étape à l'autre | 25,00 EUR | cible='PEREIRA FREDERIC 72906D' quartz='HUGUET FREDERIC 72949K' |
| Nom du bénéficiaire différent d'une étape à l'autre | 25,00 EUR | cible='VILLENEUVE PIERRE 72473J' quartz='HUGUET FREDERIC 72949K' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,00 EUR | importe par Quartz ('MACIA SAM 72200A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,00 EUR | importe par Quartz ('MACIA SAM 72200A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,00 EUR | importe par Quartz ('PEREIRA FREDERIC 72906D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,00 EUR | importe par Quartz ('PEREIRA FREDERIC 72906D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,00 EUR | importe par Quartz ('VILLENEUVE PIERRE 72473J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,00 EUR | importe par Quartz ('VILLENEUVE PIERRE 72473J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,16 EUR | importe par Quartz ('ZAOUANE WOIELLE 77305S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,20 EUR | importe par Quartz ('ROY CHRISTIAN 67837J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,23 EUR | importe par Quartz ('LOUIS STEPHEN 75760J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,40 EUR | importe par Quartz ('ABED HAKIM 55732F') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 25,50 EUR | cible='NOU STEVEN 57716S' quartz='LARTAUD MICKAEL 65580P' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,50 EUR | importe par Quartz ('NOU STEVEN 57716S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 25,50 EUR | importe par Quartz ('NOU STEVEN 57716S') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 26,00 EUR | cible='VIALARET DANIEL 75930H' quartz='CORNET NICOLAS 31259E' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,00 EUR | importe par Quartz ('VIALARET DANIEL 75930H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,00 EUR | importe par Quartz ('VIALARET DANIEL 75930H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,10 EUR | importe par Quartz ('ERPELDING PAUL 70998T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,30 EUR | importe par Quartz ('REBUFFEL PATRICK 58812J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,52 EUR | importe par Quartz ('AOUANE BORIS 68229A') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 26,70 EUR | cible='DELAVIE JEAN-CLAUDE 7807' quartz='ANDRE LUDOVIC 25791K' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,70 EUR | importe par Quartz ('DELAVIE JEAN-CLAUDE 7807') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,70 EUR | importe par Quartz ('DELAVIE JEAN-CLAUDE 7807') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,80 EUR | importe par Quartz ('DESORT CEDRIC 74457W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,90 EUR | importe par Quartz ('GARRYYEVA JEREN 77745X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 26,95 EUR | importe par Quartz ('LAURENT GUILLAUME 63787E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 27,30 EUR | importe par Quartz ('HOHN JASON 76445K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 27,40 EUR | importe par Quartz ('DALIBEY CHERIF 51760E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 27,60 EUR | importe par Quartz ('MAINE PHILIPPE 41422C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 27,72 EUR | importe par Quartz ('ARMELIN BENOIT 50116S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 27,78 EUR | importe par Quartz ('MOIGNEAU CYRILLE 34816K') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 27,88 EUR | cible='THUDEROZ FLORIAN 46866R' quartz='COULIBEUF FREDERIC 33614' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 27,88 EUR | importe par Quartz ('THUDEROZ FLORIAN 46866R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 27,88 EUR | importe par Quartz ('THUDEROZ FLORIAN 46866R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 28,30 EUR | importe par Quartz ('BARTHELEMI PI AMANDINE 7') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 28,40 EUR | importe par Quartz ('HENRY SEBASTIEN 44561H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 28,50 EUR | importe par Quartz ('DUSSART MATHIEU 47711C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 29,20 EUR | importe par Quartz ('EL OUARDI HIMADE 73293N') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 29,40 EUR | cible='RICHE FRANCK 58433K' quartz='BURELLI CHRISTOPHE 62610' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 29,40 EUR | importe par Quartz ('RICHE FRANCK 58433K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 29,40 EUR | importe par Quartz ('RICHE FRANCK 58433K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 29,44 EUR | importe par Quartz ('HAMMOUCHE BOUGHERRA 6533') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 29,70 EUR | importe par Quartz ('GRZEGOROWSKI THIERRY 635') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 30,00 EUR | cible='KUHNI JOHANN 65083K' quartz='GILLES SEBASTIEN 76408L' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 30,00 EUR | importe par Quartz ('KUHNI JOHANN 65083K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 30,00 EUR | importe par Quartz ('KUHNI JOHANN 65083K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 30,20 EUR | importe par Quartz ('BRETIN GUILLAUME 75636X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 30,50 EUR | importe par Quartz ('SERVANTE FLORIAN 70557N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 30,90 EUR | importe par Quartz ('DECEES ALAIN 64921Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,17 EUR | importe par Quartz ('LEBARBIER ANTOINE 77335F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,30 EUR | importe par Quartz ('AIT HADDA HASANE 66253A') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 31,60 EUR | cible='RIZZATO PATRICK 63766C' quartz='BILY BRUNO 71249Z' |
| Nom du bénéficiaire différent d'une étape à l'autre | 31,60 EUR | cible='ZERBONE CHRISTOPHE 63659' quartz='RIZZATO PATRICK 63766C' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,60 EUR | importe par Quartz ('RIZZATO PATRICK 63766C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,60 EUR | importe par Quartz ('ZERBONE CHRISTOPHE 63659') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,60 EUR | importe par Quartz ('ZERBONE CHRISTOPHE 63659') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,70 EUR | importe par Quartz ('DURAND GABRIEL 73906W') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 31,80 EUR | cible='TELLIER NICOLE 16668F' quartz='GARCIA ALAIN 56423R' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,80 EUR | importe par Quartz ('TELLIER NICOLE 16668F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,80 EUR | importe par Quartz ('TELLIER NICOLE 16668F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 31,94 EUR | importe par Quartz ('MAURER-PHILIPPE AGATHE 7') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 32,00 EUR | importe par Quartz ('VINCENTI CHRISTIAN 64809') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 32,40 EUR | importe par Quartz ('MILLET ALEXANDRE 52295J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 32,58 EUR | importe par Quartz ('LECLERE GEOFFREY 61644K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 32,65 EUR | importe par Quartz ('CASTERMANT JENNIFER 7607') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 32,90 EUR | importe par Quartz ('HUTTE WILFRID 57652H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 32,99 EUR | importe par Quartz ('TURPIN CHRISTIAN 78065S') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 33,00 EUR | cible='DE BASTARD PHILIPPE 4754' quartz='BOREL ROMAIN 50057P' |
| Nom du bénéficiaire différent d'une étape à l'autre | 33,00 EUR | cible='HANOTTE FREDERIC 70902S' quartz='DE BASTARD PHILIPPE 4754' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 33,00 EUR | importe par Quartz ('DE BASTARD PHILIPPE 4754') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 33,00 EUR | importe par Quartz ('HANOTTE FREDERIC 70902S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 33,00 EUR | importe par Quartz ('HANOTTE FREDERIC 70902S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 33,05 EUR | importe par Quartz ('KEITA MAMBY 63424C') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 33,60 EUR | cible='COULOT SANDRINE 69772E' quartz='CHERPION LOIC 60202N' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 33,60 EUR | importe par Quartz ('COULOT SANDRINE 69772E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 33,60 EUR | importe par Quartz ('COULOT SANDRINE 69772E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 33,70 EUR | importe par Quartz ('BAVEREL HUGO 74702S') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 34,00 EUR | cible='RIGAL MATHIEU 68078B' quartz='MERCADIER CHARLELIE 7483' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 34,00 EUR | importe par Quartz ('RIGAL MATHIEU 68078B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 34,00 EUR | importe par Quartz ('RIGAL MATHIEU 68078B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 35,10 EUR | importe par Quartz ('AHACHE DIDIER 41730H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 35,20 EUR | importe par Quartz ('FORESTIER GAETAN 72694A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 35,30 EUR | importe par Quartz ('GUILLOUX CORENTIN 75429Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 35,88 EUR | importe par Quartz ('FAUTRAS MATEO 62582W') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 36,60 EUR | cible='LEMAIRE JULIEN 45748W' quartz='BACHTOU BRICE 56994S' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 36,60 EUR | importe par Quartz ('LEMAIRE JULIEN 45748W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 36,60 EUR | importe par Quartz ('LEMAIRE JULIEN 45748W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 37,15 EUR | importe par Quartz ('LEGRAND NICOLAS 68098C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 37,88 EUR | importe par Quartz ('DAVID MARDOCHEE 75191K') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 38,00 EUR | cible='BOEDEC ANGELIQUE 60269B' quartz='BOCQUET DAMIEN 77336H' |
| Nom du bénéficiaire différent d'une étape à l'autre | 38,00 EUR | cible='ROCHET WILFRID 60728E' quartz='BOEDEC ANGELIQUE 60269B' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 38,00 EUR | importe par Quartz ('BOEDEC ANGELIQUE 60269B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 38,00 EUR | importe par Quartz ('ROCHET WILFRID 60728E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 38,00 EUR | importe par Quartz ('ROCHET WILFRID 60728E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 38,17 EUR | importe par Quartz ('DJANI SAMIR 76197J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 38,33 EUR | importe par Quartz ('FORQUIN BENOIT 52807H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 38,40 EUR | importe par Quartz ('REMY FABIEN 63769F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 38,95 EUR | importe par Quartz ('DUBUC TEO 61844Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 39,00 EUR | importe par Quartz ('MEHENNI SELIM 77515T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 39,25 EUR | importe par Quartz ('MONFLIER YOHAN 41748F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 39,90 EUR | importe par Quartz ('PONTIFICE MIKAEL 72227K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 39,99 EUR | importe par Quartz ('BARACHE CHERIF 76475A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,00 EUR | importe par Quartz ('CAPDORDY ALEXANDRE 49233') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,01 EUR | importe par Quartz ('DEBERGH EMMANUEL 63834S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,02 EUR | importe par Quartz ('LARONCHE SIMON 77190R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,30 EUR | importe par Quartz ('COMTE SEBASTIEN 77294C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,50 EUR | importe par Quartz ('GOUANZROU ISMAIN 77506F') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 40,70 EUR | cible='SCHOTT FREDERIC 42294A' quartz='SANQUER YANNICK 72806Y' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,70 EUR | importe par Quartz ('SCHOTT FREDERIC 42294A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,70 EUR | importe par Quartz ('SCHOTT FREDERIC 42294A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 40,80 EUR | importe par Quartz ('BEN ABDESSATAR NEJOUM 54') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 41,25 EUR | importe par Quartz ('COULM PAULINE 73164T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 41,50 EUR | importe par Quartz ('ARDHUISE JENNIFER 38022D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 41,60 EUR | importe par Quartz ('SION ERIC 08565W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 41,61 EUR | importe par Quartz ('PLOU BRYAN 58985L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 41,90 EUR | importe par Quartz ('FOUSSADIER THOMAS 55575A') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 42,00 EUR | cible='MOULIN DAVID 55389E' quartz='GRUNDRICK SYLVAIN 63136Z' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 42,00 EUR | importe par Quartz ('MOULIN DAVID 55389E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 42,00 EUR | importe par Quartz ('MOULIN DAVID 55389E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 42,05 EUR | importe par Quartz ('MAHE FABRICE 54705E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 42,80 EUR | importe par Quartz ('FERREIRA CHRISTIAN 74359') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 42,90 EUR | importe par Quartz ('LIZAMBERT GUILLAUME 4329') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 43,21 EUR | importe par Quartz ('LEBARILLIER JOSEPH 63590') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 43,49 EUR | importe par Quartz ('BOUSSEMART LAURENT- 1270') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 44,41 EUR | importe par Quartz ('MAYET STEPHEN 65150Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 44,50 EUR | importe par Quartz ('JAN SEBASTIEN 39585K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 44,75 EUR | importe par Quartz ('VIALETTE FRANCOIS 68232D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 44,99 EUR | importe par Quartz ('VASSELET CLEMENT 73284B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 45,40 EUR | importe par Quartz ('FRAVAL MICKAEL 75369W') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 46,50 EUR | cible='VIEULES MICKAEL 47326X' quartz='PASSARD TITOUAN 66289Y' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 46,50 EUR | importe par Quartz ('VIEULES MICKAEL 47326X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 46,50 EUR | importe par Quartz ('VIEULES MICKAEL 47326X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 46,80 EUR | importe par Quartz ('VIDAL OLIVIER 41971A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 47,00 EUR | importe par Quartz ('POLUS EMNA 75041N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 47,55 EUR | importe par Quartz ('GOUZAOUIT LAHOUCINE 5617') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 48,05 EUR | importe par Quartz ('PERDEREAU EMMANUEL 23362') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 48,48 EUR | importe par Quartz ('MACHADO PATRICIA 72238A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 48,50 EUR | importe par Quartz ('MALLARD LUDOVIC 48795D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 48,64 EUR | importe par Quartz ('DA SILVA MOTA CARLOS 716') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 48,77 EUR | importe par Quartz ('SEREMES SEBASTIEN 76023E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 48,95 EUR | importe par Quartz ('ALLOUCHE JULIEN 69818R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 49,10 EUR | importe par Quartz ('RIOU NOLAN 76430R') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 49,50 EUR | cible='WINTERSTEIN JEAN-LUC 386' quartz='SUCHET DONOVAN 62640X' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 49,50 EUR | importe par Quartz ('WINTERSTEIN JEAN-LUC 386') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 49,50 EUR | importe par Quartz ('WINTERSTEIN JEAN-LUC 386') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 49,65 EUR | importe par Quartz ('GERARD VIVIEN 74132S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 49,79 EUR | importe par Quartz ('VIGNERON PASCAL 60446J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 49,80 EUR | importe par Quartz ('NIESS ISABELLE 71233C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 49,99 EUR | importe par Quartz ('BLACHERE FABRICE 63650A') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 50,00 EUR | cible='DIALLO BOUBACAR 46116D' quartz='BOUSSAGEON PATRICIA 1369' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 50,00 EUR | importe par Quartz ('DIALLO BOUBACAR 46116D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 50,00 EUR | importe par Quartz ('DIALLO BOUBACAR 46116D') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 50,05 EUR | cible='RENAUDIE FRANCOIS 71151W' quartz='CROUZIER CLEMENT 74503E' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 50,05 EUR | importe par Quartz ('RENAUDIE FRANCOIS 71151W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 50,05 EUR | importe par Quartz ('RENAUDIE FRANCOIS 71151W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 50,30 EUR | importe par Quartz ('KOMBO FABRICE 65098E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 50,45 EUR | importe par Quartz ('MANISSADJIAN KATHERINE 4') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 51,00 EUR | importe par Quartz ('SANTORO BRUNO 63284T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 51,10 EUR | importe par Quartz ('THERON MIKAEL 47381T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 51,54 EUR | importe par Quartz ('MARTY XAVIER 47786B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 51,68 EUR | importe par Quartz ('LEFFY ETIENNE 77724T') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 52,20 EUR | cible='SARL IDEC' quartz='BEN HADDOU ABDERRAHIM 74' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 52,20 EUR | importe par Quartz ('SARL IDEC') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 52,50 EUR | importe par Quartz ('LAGRANGE STEPHANE 46985Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 52,59 EUR | importe par Quartz ('YVETOT MARC 37311T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 52,82 EUR | importe par Quartz ('SELLES JEROME 54906W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 52,97 EUR | importe par Quartz ('JOUENNE ANTOINE 73781E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 53,20 EUR | importe par Quartz ('ALVES JUVENTINO 56156P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 53,45 EUR | importe par Quartz ('LOUNAS HAMID 77685S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 53,60 EUR | importe par Quartz ('VILLIER KILIAN 73266C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 53,93 EUR | importe par Quartz ('DELAIRE ANAELLE 72843X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 54,00 EUR | importe par Quartz ('ROTH ERIC 77923E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 54,24 EUR | importe par Quartz ('ZAGAJSKI DIDIER 56302F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 54,35 EUR | importe par Quartz ('AQUILINA HERVE 75174N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 54,85 EUR | importe par Quartz ('BRAHIMI EDDIE 76416Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 54,90 EUR | importe par Quartz ('VINCENT THIERRY 43973J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 55,00 EUR | importe par Quartz ('MABIZA TUTONDA JOEL 6078') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 55,35 EUR | importe par Quartz ('HSAINI MOUNIR 48495J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 55,50 EUR | importe par Quartz ('BEN HOSSEM SEBASTIEN 626') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 55,60 EUR | importe par Quartz ('BOJKO JEROME 63509P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 56,20 EUR | importe par Quartz ('GERVASUTTI JOHAN 73245A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 56,28 EUR | importe par Quartz ('NUMERUS JEAN 72435J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 56,30 EUR | importe par Quartz ('FLECK FRANCINE 10978W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 56,49 EUR | importe par Quartz ('LAVAUVRE EMILIEN 61525D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 57,80 EUR | importe par Quartz ('SERRANO CLAUDE 63175A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 57,95 EUR | importe par Quartz ('GARZIA GABRIEL 68271E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 58,20 EUR | importe par Quartz ('SOULIMANI ABDEL-HAMED 77') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 58,66 EUR | importe par Quartz ('GIROUD-SUISSE SEBASTIEN') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 58,73 EUR | importe par Quartz ('COURT FLORENT 42366W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 58,90 EUR | importe par Quartz ('VOISARD RAPHAEL 63084E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 59,03 EUR | importe par Quartz ('GONZALVEZ STEPHANE 69430') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 59,18 EUR | importe par Quartz ('MARZOUK FAYCAL 61240D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 59,19 EUR | importe par Quartz ('BROCHAND PHILIPPE 62084P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 59,50 EUR | importe par Quartz ('RUMEAU JEROME 72244H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 60,00 EUR | importe par Quartz ('FERRY ETIENNE 50800S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 60,25 EUR | importe par Quartz ('TABAREAU ADRIEN 69154S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 60,70 EUR | importe par Quartz ('TAFANI JEROME 47372F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 61,00 EUR | importe par Quartz ('MONNEL ROBERTO 55852P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 61,50 EUR | importe par Quartz ('ZAMBON ERIC 38067N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 61,90 EUR | importe par Quartz ('REINHARD ERIC 53231R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 62,72 EUR | importe par Quartz ('CABOZ CANENA JOAQUIM MAN') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 62,85 EUR | importe par Quartz ('MERLE CHRISTOPHE 61494N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 63,60 EUR | importe par Quartz ('PIAT KEVIN 71842D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 64,00 EUR | importe par Quartz ('TOUMI CHAHID 76400B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 64,94 EUR | importe par Quartz ('PITTAU NOEMIE 76116C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 64,99 EUR | importe par Quartz ('SAURA DOMINIQUE 77783X') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 65,60 EUR | cible='DURAND MAXIME 66791H' quartz='BERTOMEU JOSE 75955R' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 65,60 EUR | importe par Quartz ('DURAND MAXIME 66791H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 65,60 EUR | importe par Quartz ('DURAND MAXIME 66791H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 65,90 EUR | importe par Quartz ('LEGRAIN ADRIEN 60873X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 65,95 EUR | importe par Quartz ('ROSA DO CARMO CHARLENE 4') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 66,00 EUR | cible='JAVEGNY JAMES 26069B' quartz='CHOUASNE DIDIER 77256C' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 66,00 EUR | importe par Quartz ('JAVEGNY JAMES 26069B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 66,00 EUR | importe par Quartz ('JAVEGNY JAMES 26069B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 66,09 EUR | importe par Quartz ('CELCE MARIANNE 63255E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 66,25 EUR | importe par Quartz ('MINACORI MATTHIAS 53267N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 66,45 EUR | importe par Quartz ('LYAN FREDERIC 66692C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 67,00 EUR | importe par Quartz ('REY TINAT VINCENT 55945L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 67,22 EUR | importe par Quartz ('AKROUT MOHAMED 69504C') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 67,50 EUR | cible='TAMIZON CEDRIC 77474P' quartz='DYEN THOMAS 76070S' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 67,50 EUR | importe par Quartz ('TAMIZON CEDRIC 77474P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 67,50 EUR | importe par Quartz ('TAMIZON CEDRIC 77474P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 67,70 EUR | importe par Quartz ('BELLIARD JEAN MARIE 3730') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 67,85 EUR | importe par Quartz ('TROUVE ROMAIN 66065C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 68,10 EUR | importe par Quartz ('BENYAGOUB NASR EDDINE 22') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 68,30 EUR | importe par Quartz ('MOURET AURELIEN 68033S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 68,50 EUR | importe par Quartz ('MONNIN MARIANNE 21597S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 68,86 EUR | importe par Quartz ('PIERRE MARINE 74602K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 69,10 EUR | importe par Quartz ('SCHENKER REMI 50392E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 69,50 EUR | importe par Quartz ('MAROTTE GREGOIRE 70607D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 69,80 EUR | importe par Quartz ('RASOLOFOMANDRANTO HUGUES') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 69,92 EUR | importe par Quartz ('DUDKO OLEKSII 77610T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 69,93 EUR | importe par Quartz ('FATOUX THIBAUD 75201Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 70,20 EUR | importe par Quartz ('LARDET DAMIEN 65033W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 70,40 EUR | importe par Quartz ('DAL MORO MAXIME 65114B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 70,61 EUR | importe par Quartz ('CANTOBION MATHURIN 45242') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 70,84 EUR | importe par Quartz ('TOMAZ DELPHINE 73856D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 71,00 EUR | importe par Quartz ('THOMAS EMMANUEL 18648L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 71,50 EUR | importe par Quartz ('BUCQUOY OLIVIER 41672F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 72,01 EUR | importe par Quartz ('LAURET THOMAS 66311B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 72,40 EUR | importe par Quartz ('DELBOE GREGORY 57250D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 72,50 EUR | importe par Quartz ('SOUSA DA COSTA FARIA FER') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 73,10 EUR | importe par Quartz ('JATEOUA RACHID 67214P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 73,70 EUR | importe par Quartz ('CURTET VINCENT 69593W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 73,99 EUR | importe par Quartz ('VALBONESI ANNIE 52314J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 74,40 EUR | importe par Quartz ('HOOGHORDEL RONALD 14592A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 75,45 EUR | importe par Quartz ('MASSACRIER BENJAMIN 7163') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 76,00 EUR | importe par Quartz ('LEFEVRE HUGO 75337C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 76,10 EUR | importe par Quartz ('GUERD BILEL 73310K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 76,15 EUR | importe par Quartz ('MIETTON CHARLY 75179W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 76,40 EUR | importe par Quartz ('FORGET ROMAIN 62485S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 77,38 EUR | importe par Quartz ('NASSEYS JACQUES 40943Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 77,61 EUR | importe par Quartz ('DEVEDEUX CHARLY 64083W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 77,85 EUR | importe par Quartz ('COLSON SEBASTIEN 38154C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 78,07 EUR | importe par Quartz ('GARDES DAVID 53472H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 78,28 EUR | importe par Quartz ('ZAOUALI MEHDI 76179K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 78,69 EUR | importe par Quartz ('MARTIN ERIC 56719E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 78,90 EUR | importe par Quartz ('CHAARI WAJDI 72439P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 79,30 EUR | importe par Quartz ('CURTET BENJAMIN 69946J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 79,35 EUR | importe par Quartz ('CHARRIER LOIC 58052J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 79,70 EUR | importe par Quartz ('ENGELAERE JEAN-SEBASTIEN') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,00 EUR | importe par Quartz ('AMAMI AMAR 35680Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,06 EUR | importe par Quartz ('VERSELE FLORENT 77882B') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 80,10 EUR | cible='ROSSI JEAN PHILIPPE 5200' quartz='LOUVET CYRIL 26606H' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,10 EUR | importe par Quartz ('ROSSI JEAN PHILIPPE 5200') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,10 EUR | importe par Quartz ('ROSSI JEAN PHILIPPE 5200') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,17 EUR | importe par Quartz ('CHRISTINE JEAN-AUGUSTE 4') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 80,60 EUR | cible='BAVOUX ANTOINE 58193W' quartz='ALLOUCHE DAVID 59946B' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,60 EUR | importe par Quartz ('BAVOUX ANTOINE 58193W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,60 EUR | importe par Quartz ('BAVOUX ANTOINE 58193W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 80,71 EUR | importe par Quartz ('CLEMENSON DAVID 41419Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 81,27 EUR | importe par Quartz ('DELLIER VICTOR 62569C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 81,55 EUR | importe par Quartz ('DECLAUQUEMENT MATTHIEU 7') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 82,00 EUR | importe par Quartz ('TANTARO UGO 62666E') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 82,50 EUR | cible='MADERN PIERRE 50760P' quartz='LOUIS JULES 76466N' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 82,50 EUR | importe par Quartz ('MADERN PIERRE 50760P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 82,50 EUR | importe par Quartz ('MADERN PIERRE 50760P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 82,65 EUR | importe par Quartz ('ROSSEL NICOLAS 41219K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 82,68 EUR | importe par Quartz ('MARLIN ALEXANDRA 34545D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 82,70 EUR | importe par Quartz ('ROUX SIBILON DENIS 22991') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 83,08 EUR | importe par Quartz ('CARVALHO CARLOS 51260Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 83,30 EUR | importe par Quartz ('FLEURY KEVIN 70509A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 83,60 EUR | importe par Quartz ('LABRUYERE JOHANN 42298E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 84,02 EUR | importe par Quartz ('GUIGARD DOMINIQUE 38812T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 86,01 EUR | importe par Quartz ('VERDIERE THOMAS 74556A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 86,30 EUR | importe par Quartz ('EL KHABCHI NOURDDINE 760') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 86,40 EUR | importe par Quartz ('LOPEZ MARIA 36074R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 86,96 EUR | importe par Quartz ('TAZAOUI JADE 75300D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 87,10 EUR | importe par Quartz ('HONG ANTHONY 34100T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 88,29 EUR | importe par Quartz ('GASTALDI OLIVIER 55127K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 88,90 EUR | importe par Quartz ('GAUME SOPHIE 63352H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 89,48 EUR | importe par Quartz ('KIEFFERT JEAN NOEL 34884') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 89,70 EUR | importe par Quartz ('PAPET CHRISTOPHE 44034P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 90,10 EUR | importe par Quartz ('LAUGA DANIEL 38473Y') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 90,70 EUR | cible='JAMAIN CATHERINE 37663F' quartz='CARON MATTHEO 76458C' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 90,70 EUR | importe par Quartz ('JAMAIN CATHERINE 37663F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 90,70 EUR | importe par Quartz ('JAMAIN CATHERINE 37663F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 90,80 EUR | importe par Quartz ('LALOUETTE GREGORY 47979E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 91,30 EUR | importe par Quartz ('CAVANNE AURELIEN 64037J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 91,60 EUR | importe par Quartz ('PIRLOT FRANCK 63848K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 91,96 EUR | importe par Quartz ('CHARLES CEDRIC 67873F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 92,70 EUR | importe par Quartz ('FACHE FABRICE 18106Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 92,88 EUR | importe par Quartz ('DE FREITAS SAMUEL 58067D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 92,90 EUR | importe par Quartz ('CARBONNIERE FLORIAN 6454') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 94,20 EUR | importe par Quartz ('RAVIER SEBASTIEN 50018N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 94,30 EUR | importe par Quartz ('GODART LOIC 75044S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 94,40 EUR | importe par Quartz ('FONDELOT CEDRIC 48066W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 94,80 EUR | importe par Quartz ('CABRAL LAURENT 47002W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 94,82 EUR | importe par Quartz ('MAQUART DIDIER 39483B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 94,92 EUR | importe par Quartz ('LAPALUS SEBASTIEN 59004L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 95,18 EUR | importe par Quartz ('JUBLIN BERTRAND 39394J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 95,34 EUR | importe par Quartz ('AVIER PETER 71544L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 95,70 EUR | importe par Quartz ('BEAUVAIS TONY 64270R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 95,76 EUR | importe par Quartz ('UWIZEYE RICHARD 70567B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 95,81 EUR | importe par Quartz ('FRANCART OLIVIER 34509F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 96,00 EUR | importe par Quartz ('MOURET STEFAN 23385W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 96,10 EUR | importe par Quartz ('GONCALVES DINIS DAVID 68') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 96,70 EUR | importe par Quartz ('AYED MOHAMED-ALI 72802S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 96,83 EUR | importe par Quartz ('BRULARD VINCENT 47394K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 97,30 EUR | importe par Quartz ('POSTERARO FRANCOIS 72395') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 97,50 EUR | importe par Quartz ('FRENNE EMILIE 60183N') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 98,30 EUR | cible='GUILBERT GUILLAUME 45790' quartz='BONNET AURELIEN 75420L' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 98,30 EUR | importe par Quartz ('GUILBERT GUILLAUME 45790') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 98,30 EUR | importe par Quartz ('GUILBERT GUILLAUME 45790') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 99,28 EUR | importe par Quartz ('BINET LAURENT 06386C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 99,37 EUR | importe par Quartz ('CUVILLIEZ MICHAEL 37523Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 99,85 EUR | importe par Quartz ('BALOUZAT DIDIER 71386D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 99,89 EUR | importe par Quartz ('THOMAS GREGORY 77865D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 100,00 EUR | importe par Quartz ('COMTE MARC 22888R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 100,01 EUR | importe par Quartz ('MAUMY LAURENT 77496T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 100,08 EUR | importe par Quartz ('PRIM DANIEL 48063R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 102,00 EUR | importe par Quartz ('KOTOMSKI ENZO 77652Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 102,50 EUR | importe par Quartz ('LEVEZAC GAUTHIER 68180K') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 103,00 EUR | cible='WEIGEL ALEX 75508C' quartz='MASSOUTIER CHRISTIAN 229' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 103,00 EUR | importe par Quartz ('WEIGEL ALEX 75508C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 103,00 EUR | importe par Quartz ('WEIGEL ALEX 75508C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 103,30 EUR | importe par Quartz ('PELLETIER JEAN PHILIPPE') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 103,40 EUR | importe par Quartz ('AKAMWIKA CHRISTIAN 68414') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 103,70 EUR | importe par Quartz ('PAUL ANTHONY 75428Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 103,75 EUR | importe par Quartz ('BROUCQSAULT SEBASTIEN 53') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 103,80 EUR | importe par Quartz ('THONNAT CEDRIC 55356L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 104,00 EUR | importe par Quartz ('WEBER XAVIER 46524R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 104,30 EUR | importe par Quartz ('BOURCIAT JEAN DENIS 5322') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 104,35 EUR | importe par Quartz ('BOUZRED AMAR 75958W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 104,55 EUR | importe par Quartz ('EZ-ZEKRI KAMEL 47473P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 104,80 EUR | importe par Quartz ('LEPAUMIER ARNAUD 77253Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 105,10 EUR | importe par Quartz ('LE BARAZER TITOUAN 68824') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 105,37 EUR | importe par Quartz ('MARTIN MAXIME 76230C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 106,10 EUR | importe par Quartz ('VERHAEGHE AMADEUS 57130X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 106,11 EUR | importe par Quartz ('WRAZIDLO MATHIEU 52088L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 106,20 EUR | importe par Quartz ('KONATE SILAMARA 77374H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 106,50 EUR | importe par Quartz ('CONSIGNY LIONEL 40616S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 106,90 EUR | importe par Quartz ('PEYRON FREDERIC 53479S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 107,00 EUR | importe par Quartz ('BARON FABRICE 47237D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 107,12 EUR | importe par Quartz ('DESCHAMPS SEBASTIEN 4521') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 107,90 EUR | importe par Quartz ('RAIMBAULT PATRICE 53879T') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 108,00 EUR | cible='OFFICE - ALLIANCE' quartz='LEPLUS FABIEN 64094J' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 108,00 EUR | importe par Quartz ('OFFICE - ALLIANCE') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 108,20 EUR | importe par Quartz ('GUILBOT PASCAL 56806W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 109,24 EUR | importe par Quartz ('RAS SEBASTIEN 73917J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 109,54 EUR | importe par Quartz ('TOFFANO VALENTIN 76464K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 109,90 EUR | importe par Quartz ('LEONARD SANDRINE 75813D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 109,93 EUR | importe par Quartz ('NTWARI EDYNA 77187L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 110,59 EUR | importe par Quartz ('CHEVALIER MARINE 73840H') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 111,10 EUR | cible='CORNELOUP SAMUEL 74580F' quartz='BERTUCCI PHILIPPE 75631P' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 111,10 EUR | importe par Quartz ('CORNELOUP SAMUEL 74580F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 111,10 EUR | importe par Quartz ('CORNELOUP SAMUEL 74580F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 111,30 EUR | importe par Quartz ('LEFEVRE ANTHONY 58035L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 111,70 EUR | importe par Quartz ('FRANCOIS ERIC 15259C') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 112,95 EUR | cible='CASTEL CEDRIC 69442X' quartz='BLOT TITOUAN 70687J' |
| Nom du bénéficiaire différent d'une étape à l'autre | 112,95 EUR | cible='PERRUSSEL XAVIER 75724L' quartz='CASTEL CEDRIC 69442X' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 112,95 EUR | importe par Quartz ('CASTEL CEDRIC 69442X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 112,95 EUR | importe par Quartz ('PERRUSSEL XAVIER 75724L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 112,95 EUR | importe par Quartz ('PERRUSSEL XAVIER 75724L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 113,00 EUR | importe par Quartz ('DUCA THOMAS 66484D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 113,98 EUR | importe par Quartz ('AFRI SABRI 71257J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 114,04 EUR | importe par Quartz ('LAURENT JEROME NICOLAS 5') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 114,35 EUR | importe par Quartz ('LIOTARD LAURENT 22960K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 114,60 EUR | importe par Quartz ('ROCH-DUPLAND MATTHIEU 65') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 114,96 EUR | importe par Quartz ('BOUZEKRI DJAMEL 73187Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 115,20 EUR | importe par Quartz ('ROCHE BENOIT 71255F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 115,30 EUR | importe par Quartz ('BOURDELIN PASCAL 42297D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 115,40 EUR | importe par Quartz ('POTHIER CHRISTOPHE 52250') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 115,50 EUR | importe par Quartz ('MEJAN KEVIN 74135X') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 115,60 EUR | cible='SOCIETE DE DEVELOPPEMENT' quartz='LEPENANT STEPHANE 18445W' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 115,60 EUR | importe par Quartz ('SOCIETE DE DEVELOPPEMENT') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 115,70 EUR | importe par Quartz ('CASTEL EMMANUEL 63759T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 115,81 EUR | importe par Quartz ('DURSUN EMIR 76813W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 116,29 EUR | importe par Quartz ('SARMIS ALI 69318H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 116,38 EUR | importe par Quartz ('PRZYGODZKI DAVID 76973E') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 117,40 EUR | cible='WACHAJA JORDAN 74274D' quartz='TOUATI MOHAMED AMINE 763' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 117,40 EUR | importe par Quartz ('WACHAJA JORDAN 74274D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 117,40 EUR | importe par Quartz ('WACHAJA JORDAN 74274D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 117,75 EUR | importe par Quartz ('MOUTERDE SIMON 68367F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 118,21 EUR | importe par Quartz ('TASSERY ARNAUD 36382X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 118,80 EUR | importe par Quartz ('LEIBUNDGUTH ALEXANDRE 57') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 119,10 EUR | importe par Quartz ('RASOLOFONIRINA KIADY 727') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 119,21 EUR | importe par Quartz ('DA SILVA GOMES VICTOR 15') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 120,30 EUR | importe par Quartz ('MONTEIRO GEORGES 42637B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 120,80 EUR | importe par Quartz ('VERDIERE FABRICE 50231T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 121,12 EUR | importe par Quartz ('CHALAL SAMIR 42348X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 121,47 EUR | importe par Quartz ('BLANDINIERES CHRISTOPHE') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 121,60 EUR | importe par Quartz ('SINORA JOHN 64222C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 122,70 EUR | importe par Quartz ('VERSTRAETEN NICOLAS 4160') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 123,43 EUR | importe par Quartz ('BOUDY JESSY 73313P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 123,46 EUR | importe par Quartz ('MELLIES BRICE 30352L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 124,20 EUR | importe par Quartz ('LIEBAUT AXEL 77578B') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 124,40 EUR | cible='MARCHE ALEXANDRE 75803R' quartz='FILLOL AURELIEN 74183J' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 124,40 EUR | importe par Quartz ('MARCHE ALEXANDRE 75803R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 124,40 EUR | importe par Quartz ('MARCHE ALEXANDRE 75803R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 124,49 EUR | importe par Quartz ('N DAO HABIBOU 63967S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 124,60 EUR | importe par Quartz ('WATREMEZ THEO 70717Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 125,41 EUR | importe par Quartz ('SEMAIL QUENTIN 75792B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 126,35 EUR | importe par Quartz ('DONATACCI CEDRIC 51815C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 126,93 EUR | importe par Quartz ('BODENES ANTOINE 62494D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 127,90 EUR | importe par Quartz ('ORTEGA MAXENCE 74083C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 128,12 EUR | importe par Quartz ('HOUISE JEROME 26018J') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 128,40 EUR | cible='VIESSMANN INDUSTRIE FRAN' quartz='CROZE PASCAL 77345W' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 128,40 EUR | importe par Quartz ('VIESSMANN INDUSTRIE FRAN') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 129,40 EUR | importe par Quartz ('GREMONT HERVE 64167E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 130,30 EUR | importe par Quartz ('MORALES AXEL 67525Z') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 131,90 EUR | cible='PHILIP SEBASTIEN 60322X' quartz='HANSCOTTE KEVIN 72401P' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 131,90 EUR | importe par Quartz ('PHILIP SEBASTIEN 60322X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 131,90 EUR | importe par Quartz ('PHILIP SEBASTIEN 60322X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 132,67 EUR | importe par Quartz ('FORTE GREGORY 57914C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 132,80 EUR | importe par Quartz ('BLASQUEZ FLORENT 77026A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 132,90 EUR | importe par Quartz ('BOUDOUAIA SAMIR 54806N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 133,77 EUR | importe par Quartz ('DEPASSE MAXIME 60574C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 136,50 EUR | importe par Quartz ('SARFATI BRUNO 43851Z') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 138,10 EUR | cible='PAUCOD SYLVAIN 63718P' quartz='DANICAN RUDDY 58355H' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 138,10 EUR | importe par Quartz ('PAUCOD SYLVAIN 63718P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 138,10 EUR | importe par Quartz ('PAUCOD SYLVAIN 63718P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 139,50 EUR | importe par Quartz ('DE GRIEVE VINCENT 77185J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 139,98 EUR | importe par Quartz ('RISSER DAMIEN 74558C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 140,20 EUR | importe par Quartz ('DJELAL FOUAD 42779N') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 141,29 EUR | cible='GRISON JEREMY 43958P' quartz='BESANCON EMMANUEL 77325T' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 141,29 EUR | importe par Quartz ('GRISON JEREMY 43958P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 141,29 EUR | importe par Quartz ('GRISON JEREMY 43958P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 143,08 EUR | importe par Quartz ('RECURT ALAIN 22976F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 143,13 EUR | importe par Quartz ('VEYRON CORENTIN 62197N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 143,90 EUR | importe par Quartz ('LUBRANO-LAVADERA FREDERI') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 144,00 EUR | importe par Quartz ('SCHILIS FABRICE 42751B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 144,66 EUR | importe par Quartz ('GILLIER LAURENT 18052C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 144,86 EUR | importe par Quartz ('BORDET BERTRAND 59203Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 145,45 EUR | importe par Quartz ('KAMERER JEAN PHILIPPE 50') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 146,05 EUR | importe par Quartz ('PANTIN ALAN 60917D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 146,68 EUR | importe par Quartz ('TAHMISSIAN VIRGINIE 7272') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 147,10 EUR | importe par Quartz ('RENARD PHILIPPE 63551W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 147,30 EUR | importe par Quartz ('BARBIER JEROME 43647E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 148,50 EUR | importe par Quartz ('JAMAIN JOHN 72424W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 149,80 EUR | importe par Quartz ('LAMESTA ANDY 68796X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 149,97 EUR | importe par Quartz ('BISSUEL DAVID 49138E') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 150,00 EUR | cible='LECLERE JOHANN 45146C' quartz='FERRERO ERIC 55022Y' |
| Nom du bénéficiaire différent d'une étape à l'autre | 150,00 EUR | cible='R.L.M.' quartz='LECLERE JOHANN 45146C' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 150,00 EUR | importe par Quartz ('LECLERE JOHANN 45146C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 150,00 EUR | importe par Quartz ('R.L.M.') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 150,56 EUR | importe par Quartz ('PETIT-JEAN SYLVAIN 68043') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 153,30 EUR | importe par Quartz ('MARILLER DENIS 72801R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 153,95 EUR | importe par Quartz ('DAHHOU WALID 67903X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 154,70 EUR | importe par Quartz ('CHAZERAY MAXIME 53349X') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 155,00 EUR | cible='BUNDULA MAKUIKA YVES 718' quartz='BUFFET FREDERIC 35574H' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 155,00 EUR | importe par Quartz ('BUNDULA MAKUIKA YVES 718') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 155,00 EUR | importe par Quartz ('BUNDULA MAKUIKA YVES 718') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 155,29 EUR | importe par Quartz ('BARDESSA REMI 76263X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 155,70 EUR | importe par Quartz ('JEAN MATTEO 77383W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 156,33 EUR | importe par Quartz ('VANDEWALLE THEO 67400J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 156,37 EUR | importe par Quartz ('FLEURY THOMAS 62136H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 156,67 EUR | importe par Quartz ('CARADEC BERTRAND 16047P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 156,75 EUR | importe par Quartz ('BOCQUET CLAIRE 76756W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 157,20 EUR | importe par Quartz ('BOURVIEUX BENJAMIN 55616') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 157,51 EUR | importe par Quartz ('SALAM MEHDI 71998J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 157,60 EUR | importe par Quartz ('DEVASSON GUILLAUME 76512') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 157,74 EUR | importe par Quartz ('SUDRE ARNAUD 49229A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 158,16 EUR | importe par Quartz ('SANCHEZ MATHIEU 76758Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 160,61 EUR | importe par Quartz ('ALEGRE VINCENT 51070Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 163,62 EUR | importe par Quartz ('ODIN THIERRY 72704N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 164,57 EUR | importe par Quartz ('LE DEVIC BERTRAND 52873W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 165,08 EUR | importe par Quartz ('MARECHAL VINCENT 51987D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 165,78 EUR | importe par Quartz ('COUIX STEPHANE 73646C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 166,50 EUR | importe par Quartz ('JAMET GAETAN 44117Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 166,80 EUR | importe par Quartz ('SCHEPPER STANISLAS 66545') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 167,20 EUR | importe par Quartz ('SANCHOU PATRICE 71620L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 168,20 EUR | importe par Quartz ('GAVALDA ANTHONY 71300R') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 168,50 EUR | cible='SAVARIN FABRICE 15835K' quartz='MARTINS BENOIT 66554X' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 168,50 EUR | importe par Quartz ('SAVARIN FABRICE 15835K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 168,50 EUR | importe par Quartz ('SAVARIN FABRICE 15835K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 169,31 EUR | importe par Quartz ('NAHOUM DAVID 76141K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 169,42 EUR | importe par Quartz ('LOPES JEAN MARIE 18446X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 169,50 EUR | importe par Quartz ('WOIRIN CYRIL 08343C') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 170,50 EUR | cible='ROUSSEL ROMAIN 69033H' quartz='FORGET CYRILLE 70895H' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 170,50 EUR | importe par Quartz ('ROUSSEL ROMAIN 69033H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 170,50 EUR | importe par Quartz ('ROUSSEL ROMAIN 69033H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 171,04 EUR | importe par Quartz ('DESCLEVES BENOIT 46233H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 171,22 EUR | importe par Quartz ('BECK PATRICE 39975Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 171,35 EUR | importe par Quartz ('CHEBILI LORIS 74581H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 172,50 EUR | importe par Quartz ('DAOUDI MOHAMMED 77328Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 173,20 EUR | importe par Quartz ('CARRERE FREDERIC 23372C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 173,40 EUR | importe par Quartz ('ROCHETEAU BAPTISTE 76332') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 173,70 EUR | importe par Quartz ('SANTOS MAXIME 64423S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 174,25 EUR | importe par Quartz ('CHEVAL MAXIME 75409Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 174,85 EUR | importe par Quartz ('MUNIER QUENTIN 68348F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 175,55 EUR | importe par Quartz ('GRAND CLAIRE 58617C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 175,70 EUR | importe par Quartz ('JAUNEAU CHRISTOPHE 57618') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 176,95 EUR | importe par Quartz ('M'KABEYA-PULULU JEAN 422') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 178,65 EUR | importe par Quartz ('CABANNE JULIEN 67499P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 180,00 EUR | importe par Quartz ('DESPRETZ DAVID 45294Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 181,40 EUR | importe par Quartz ('REINARD JIMMY 74857X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 182,63 EUR | importe par Quartz ('JELLAD OIHID 72706R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 183,07 EUR | importe par Quartz ('FOSSO MAURIZIO 66681N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 184,70 EUR | importe par Quartz ('LOGEAIS GUILLAUME 76587Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 185,26 EUR | importe par Quartz ('DECROLIER BENOIT 55349C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 186,08 EUR | importe par Quartz ('DUPREY FREDERIC 63156A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 186,19 EUR | importe par Quartz ('BAIGNEAU CLAIRE 75664H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 186,59 EUR | importe par Quartz ('MARKIEWICZ MICHEL 77826C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 187,00 EUR | importe par Quartz ('PILLOT SEBASTIEN 52177D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 187,20 EUR | importe par Quartz ('VIBOUD VINCENT 74008D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 188,40 EUR | importe par Quartz ('BENABDELMOUMENE SOFIAN 4') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 189,00 EUR | importe par Quartz ('SANNIER ERIC 21090A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 189,81 EUR | importe par Quartz ('DIKO VINCENT 54364F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 190,62 EUR | importe par Quartz ('CHAPAS BENOIT 68443F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 190,68 EUR | importe par Quartz ('PONCHEL LAURENT 38058B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 192,00 EUR | importe par Quartz ('AZIBI NADIR 65802F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 192,20 EUR | importe par Quartz ('ESNAULT GILLES 64368W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 193,09 EUR | importe par Quartz ('DELORAINE CELINE 71543K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 193,36 EUR | importe par Quartz ('BACQUET ARNAUD 50431F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 194,30 EUR | importe par Quartz ('MICHEL ANNE 74006B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 195,30 EUR | importe par Quartz ('CHAMBEAU AURELIEN 43860K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 195,75 EUR | importe par Quartz ('HERVE JULIEN 63649Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 197,67 EUR | importe par Quartz ('BETHUNE JEAN-PIERRE 4688') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 197,82 EUR | importe par Quartz ('PIZZETTA ERIK 73946Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 199,08 EUR | importe par Quartz ('JEULIN AURELIEN 51221X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 199,50 EUR | importe par Quartz ('CLEMENT FRANCINE 73423J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 200,30 EUR | importe par Quartz ('VIVES JOEL 75612P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 203,15 EUR | importe par Quartz ('COWEN MATTHIEU 65896E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 204,01 EUR | importe par Quartz ('ENRIQUE NICOLAS 75019J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 204,20 EUR | importe par Quartz ('BLANCHARD MARC 63252B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 205,30 EUR | importe par Quartz ('TUFFELLI VIVIEN 45821R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 205,38 EUR | importe par Quartz ('MAIGNANT JEAN-LUC 51593K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 207,61 EUR | importe par Quartz ('YILMAZ DENIS 73828S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 210,00 EUR | importe par Quartz ('MARCONNOT EVAN 70667H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 210,54 EUR | importe par Quartz ('CHAABIT SAID 73351P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 210,70 EUR | importe par Quartz ('SCHREINER ERNEST 34486B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 212,05 EUR | importe par Quartz ('PRISER ERIC 11526R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 212,69 EUR | importe par Quartz ('MARIN BENJAMIN 49049N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 215,54 EUR | importe par Quartz ('HARCHY THOMAS 77566K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 216,02 EUR | importe par Quartz ('BISCHOFF GERALD 56650P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 217,80 EUR | importe par Quartz ('BATISTA MARC 76228A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 218,47 EUR | importe par Quartz ('BLERVAQUE CHRISTOPHE 602') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 220,16 EUR | importe par Quartz ('CHARLES VIRGINIE 48271P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 222,15 EUR | importe par Quartz ('LEFEBVRE MARC 42815K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 222,22 EUR | importe par Quartz ('ELY MARIUS STEPHANE 4918') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 222,26 EUR | importe par Quartz ('TOURNIER JEROME 51293R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 222,95 EUR | importe par Quartz ('EL MESTRI OMAR 71783B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 225,77 EUR | importe par Quartz ('ZERBINO CHRISTIAN 46078D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 227,30 EUR | importe par Quartz ('LEMIRE MICKAEL 30300T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 227,36 EUR | importe par Quartz ('HENNECENT KEVIN 63503F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 228,86 EUR | importe par Quartz ('BRUYAS PASCAL 75925B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 230,10 EUR | importe par Quartz ('LAMOURE GUILLAUME 48481R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 230,31 EUR | importe par Quartz ('PERRET FRANCIS 43250H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 231,88 EUR | importe par Quartz ('TRAPY LUDOVIC 65604X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 233,54 EUR | importe par Quartz ('LERCH CORENTIN 70997S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 234,34 EUR | importe par Quartz ('SERBES ALAIN 22874Y') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 235,20 EUR | cible='MWPI' quartz='FERNANDES MACIEL SERGIO' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 235,20 EUR | importe par Quartz ('MWPI') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 235,70 EUR | importe par Quartz ('PERRIN JULIA 76254J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 235,94 EUR | importe par Quartz ('FARGERES CORENTIN 55860A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 236,35 EUR | importe par Quartz ('STEINER CHRISTOPHER 4763') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 237,30 EUR | importe par Quartz ('LEFEVRE ARNAUD 35456C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 237,84 EUR | importe par Quartz ('DUCOTE FLORIAN 77236B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 239,26 EUR | importe par Quartz ('GAUDILLOT VALERE 61340K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 239,40 EUR | importe par Quartz ('BAUDET-GAGNEUR THOMAS 73') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 240,00 EUR | cible='SCIERS TEDDY 75572L' quartz='CALVIER EMMA 77779R' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 240,00 EUR | importe par Quartz ('SCIERS TEDDY 75572L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 240,00 EUR | importe par Quartz ('SCIERS TEDDY 75572L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 240,10 EUR | importe par Quartz ('CHARPENTIER FABRICE 5365') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 240,59 EUR | importe par Quartz ('LIVERTOUT STEPHANE 26506') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 241,02 EUR | importe par Quartz ('DUDOGNON STEPHANE 74887K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 241,96 EUR | importe par Quartz ('DUBOIS LUDOVIC 50369A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 242,87 EUR | importe par Quartz ('MARTIN PIERRE-DANIEL 698') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 242,95 EUR | importe par Quartz ('IMBERT ALEXANDRA 65806L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 244,50 EUR | importe par Quartz ('PARENTI ALICE 72866B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 245,49 EUR | importe par Quartz ('NOBLET CYRIL 38388K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 249,20 EUR | importe par Quartz ('SERIEYS GUILLAUME 44055S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 251,02 EUR | importe par Quartz ('NAYET YOHANN 64172L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 251,40 EUR | importe par Quartz ('BODEVEIX ALEXANDRE 72356') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 251,50 EUR | importe par Quartz ('BARTOLO TEDDY 57309F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 252,48 EUR | importe par Quartz ('PRIME STEPHANE 18463T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 254,40 EUR | importe par Quartz ('DUVIVIER LAURENT 63593A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 255,50 EUR | importe par Quartz ('MAUREL FREDERIC 53475L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 255,85 EUR | importe par Quartz ('MERCET SYLVAIN 52418X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 256,00 EUR | importe par Quartz ('KERHOAS SYLVIE 65020C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 256,10 EUR | importe par Quartz ('CILIO GILLES 76350K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 257,75 EUR | importe par Quartz ('LAMARRE STEPHY 65463K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 258,00 EUR | importe par Quartz ('DUBREUIL BENOIT 77432J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 260,98 EUR | importe par Quartz ('BERGE JULIEN 53741L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 266,65 EUR | importe par Quartz ('AVIX CHRISTIAN 73750P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 266,85 EUR | importe par Quartz ('DUCROIZE FABRICE 40449Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 267,55 EUR | importe par Quartz ('SYLA FLAMUR 77979D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 269,38 EUR | importe par Quartz ('BASSET GREGORY 74260K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 270,43 EUR | importe par Quartz ('LEGRAND ERIC 73566Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 271,60 EUR | importe par Quartz ('CULLET JEROME 37167D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 272,56 EUR | importe par Quartz ('BEAUDOUX STEPHANE 23026Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 274,40 EUR | importe par Quartz ('TRAN-QUY BENJAMIN 39205K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 275,30 EUR | importe par Quartz ('DELCOURT SYLVAIN 52902H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 275,40 EUR | importe par Quartz ('DIABY MALIK 54614K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 276,52 EUR | importe par Quartz ('ESTEVE PIERRE 40140R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 277,90 EUR | importe par Quartz ('NAUDIN PIERRE 63662R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 278,65 EUR | importe par Quartz ('LEFEBVRE THIBAULT 74512S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 280,30 EUR | importe par Quartz ('STEPHAN GREGORY 65462J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 281,18 EUR | importe par Quartz ('DIAFI SABRI 68155C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 281,85 EUR | importe par Quartz ('ZITO EMILIO 73343D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 282,10 EUR | importe par Quartz ('MERCIER SAMIR-JOHN 74413') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 284,20 EUR | importe par Quartz ('ONIDA MAURICE 33263S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 285,00 EUR | importe par Quartz ('NAWROT SIMON 73934F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 287,54 EUR | importe par Quartz ('GRAND JEROME 76897E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 287,60 EUR | importe par Quartz ('CUVELIER MANUEL 46448R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 287,78 EUR | importe par Quartz ('POINTEAU FREDERICK 52082') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 289,05 EUR | importe par Quartz ('MOUHAMED YASSINE 64537S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 289,38 EUR | importe par Quartz ('DA SILVEIRA AKO KOFFI 77') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 292,33 EUR | importe par Quartz ('HUBERT TONY 72598Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 292,58 EUR | importe par Quartz ('TRONCHI JULIEN 74521D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 298,75 EUR | importe par Quartz ('RAGOT VIRGIL 71841C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 299,26 EUR | importe par Quartz ('FRIESS ROMAIN 71281R') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 300,00 EUR | cible='ENNAJARI AYMEN 78352W' quartz='DOCHTERMANN JEROME 64165' |
| Nom du bénéficiaire différent d'une étape à l'autre | 300,00 EUR | cible='FLERS AGGLO' quartz='ENNAJARI AYMEN 78352W' |
| Nom du bénéficiaire différent d'une étape à l'autre | 300,00 EUR | cible='JEHIN STEVE 77428D' quartz='ENNAJARI AYMEN 78352W' |
| Nom du bénéficiaire différent d'une étape à l'autre | 300,00 EUR | cible='VIALLON GREGORY 73558L' quartz='FLERS AGGLO' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 300,00 EUR | importe par Quartz ('JEHIN STEVE 77428D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 300,00 EUR | importe par Quartz ('JEHIN STEVE 77428D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 300,00 EUR | importe par Quartz ('VIALLON GREGORY 73558L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 300,00 EUR | importe par Quartz ('VIALLON GREGORY 73558L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 303,85 EUR | importe par Quartz ('PELLERIN ERWAN 57346E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 303,90 EUR | importe par Quartz ('GERY MICKAEL 60209Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 305,50 EUR | importe par Quartz ('PETEL NICOLAS 77838T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 305,83 EUR | importe par Quartz ('VAILLANT DAMIEN 47459X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 307,43 EUR | importe par Quartz ('HASSAINI HOCINE 60281S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 309,90 EUR | importe par Quartz ('BELLET CHRISTOPHE 46832X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 313,01 EUR | importe par Quartz ('ABOU GUILLAUME 71536B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 315,84 EUR | importe par Quartz ('BARREAU THOMAS 71483F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 316,00 EUR | importe par Quartz ('POTEAU GUILLAUME 68328E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 316,34 EUR | importe par Quartz ('POITAU LUCA 76091W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 318,49 EUR | importe par Quartz ('SELOSSE LAETITIA 36587R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 320,75 EUR | importe par Quartz ('GUEGAN CYRIL 72498S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 322,75 EUR | importe par Quartz ('LOVERDE BRICE 63745A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 323,00 EUR | importe par Quartz ('TRIQUET ANTHONY 74466F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 323,43 EUR | importe par Quartz ('MURCIA GEOFFREY 47279J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 324,51 EUR | importe par Quartz ('MAZEYRAT LAURENT 67379F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 327,10 EUR | importe par Quartz ('LAGRANGE ALIX 55971X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 327,60 EUR | importe par Quartz ('OGIER DE BAULNY THOMAS 5') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 328,63 EUR | importe par Quartz ('GHERIB KARIM 50914S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 329,85 EUR | importe par Quartz ('LAROCHE SIMON 57795X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 330,40 EUR | importe par Quartz ('DEGRYSE SEBASTIEN 44217E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 332,82 EUR | importe par Quartz ('CANOVA ANTOINE 75504Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 333,80 EUR | importe par Quartz ('EUDELINE FRANCK 14726B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 334,50 EUR | importe par Quartz ('MOUS ANIS 72916S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 338,00 EUR | importe par Quartz ('CAMARA IBA 56082S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 338,76 EUR | importe par Quartz ('ROSAIRE THIBAUT 62428S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 339,90 EUR | importe par Quartz ('EL MIRI ABDELILLAH 77825') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 340,51 EUR | importe par Quartz ('PERRIN BENOIT 64843W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 341,66 EUR | importe par Quartz ('FOUCAL WILLIAM 73777A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 342,30 EUR | importe par Quartz ('KOLES CHRISTIAN 50421T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 348,80 EUR | importe par Quartz ('BESLE MATHIEU 71857Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 350,00 EUR | importe par Quartz ('MINELLI VERONIQUE 21556N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 350,06 EUR | importe par Quartz ('GUILBAUT JEROME 41437Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 350,79 EUR | importe par Quartz ('CARRERE DIDIER 23712A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 352,41 EUR | importe par Quartz ('POLICAND JOACHIM 49293J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 352,79 EUR | importe par Quartz ('DUVIGNAUD GUILLAUME 6812') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 354,13 EUR | importe par Quartz ('FERVEUR ANTOINE 68996J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 354,41 EUR | importe par Quartz ('ABDOUN MUSTAPHA 46043H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 356,00 EUR | importe par Quartz ('PELTIER JONATHAN 72703L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 357,28 EUR | importe par Quartz ('BADER JEREMY 62059F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 357,65 EUR | importe par Quartz ('DEBAUDRINGHIEN BERTRAND') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 358,44 EUR | importe par Quartz ('EL GHAMARTI REDOUANE 521') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 358,60 EUR | importe par Quartz ('DOGLIO MICHEL 50303N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 360,34 EUR | importe par Quartz ('MALBRANT SYLVAIN 69919Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 364,10 EUR | importe par Quartz ('GARAU ISABELLE 66618E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 365,94 EUR | importe par Quartz ('NEMONT STEPHANE 23723P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 366,84 EUR | importe par Quartz ('FARGUES CHRISTOPHE 17349') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 367,95 EUR | importe par Quartz ('DOURLEN JULIEN 66963J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 369,42 EUR | importe par Quartz ('TRIAU ANGEL 70797D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 369,60 EUR | importe par Quartz ('CHERAD OMAR 58064A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 372,33 EUR | importe par Quartz ('BRICHE MATTHEO 73132B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 374,10 EUR | importe par Quartz ('GANDAR ERIC 62712R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 375,56 EUR | importe par Quartz ('RIBES LIONEL 43070X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 378,83 EUR | importe par Quartz ('DUMETS BAPTISTE 68938H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 381,90 EUR | importe par Quartz ('PFEIFFER MARIE HELENE 65') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 383,25 EUR | importe par Quartz ('MOUCHE STEPHANE 21337A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 383,60 EUR | importe par Quartz ('CORRE THOMAS 72289S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 387,61 EUR | importe par Quartz ('COBO PIERRE 62210E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 391,10 EUR | importe par Quartz ('BROUX KEVIN 58169N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 398,93 EUR | importe par Quartz ('BOUVET FLORIAN 69700K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 398,94 EUR | importe par Quartz ('DEBUCQUET MAERIC 72839R') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 400,00 EUR | cible='MJ THERM' quartz='AGATHE SEBASTIEN 39040T' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 400,00 EUR | importe par Quartz ('MJ THERM') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 403,65 EUR | importe par Quartz ('VIEILLEFOSSE JULIEN 5336') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 412,10 EUR | importe par Quartz ('ANTUNES DURO NICOLAS 581') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 413,34 EUR | importe par Quartz ('ROEHRIG REMI 46513B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 418,61 EUR | importe par Quartz ('ROGER BRICE 65729K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 418,75 EUR | importe par Quartz ('THEIS ALEXIS 66074P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 419,54 EUR | importe par Quartz ('GHENNAM EL MEHDI 75936R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 419,70 EUR | importe par Quartz ('ARRIGONI LUCAS 73974J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 427,35 EUR | importe par Quartz ('MARSAL THIBAUD 75133J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 434,12 EUR | importe par Quartz ('BADEANU COSMIN 75741J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 440,78 EUR | importe par Quartz ('LALANCE PHILIPPE 38147T') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 450,00 EUR | cible='DIEHL METERING SAS' quartz='BOURGES Guillaume 77674C' |
| Nom du bénéficiaire différent d'une étape à l'autre | 450,00 EUR | cible='LE FROID FRANCILIEN' quartz='DIEHL METERING SAS' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 450,00 EUR | importe par Quartz ('LE FROID FRANCILIEN') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 451,04 EUR | importe par Quartz ('BRIEU VINCENT 39961E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 451,78 EUR | importe par Quartz ('HAMELIN CLEMENT 52643S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 452,58 EUR | importe par Quartz ('LOGRE JONAS 78039H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 454,58 EUR | importe par Quartz ('RENAUD ANTOINE 46771R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 455,30 EUR | importe par Quartz ('GHERRAT SEBASTIEN 53335C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 456,80 EUR | importe par Quartz ('DAVIGNON CELINE 43589D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 460,20 EUR | importe par Quartz ('RAMBEAUD FABIEN 50348Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 460,50 EUR | importe par Quartz ('CANAL FABIEN 59343H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 465,28 EUR | importe par Quartz ('AMIENS NATHAN 77567L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 469,15 EUR | importe par Quartz ('LAMY BERNARD 33955C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 479,52 EUR | importe par Quartz ('LEMAITRE CHRISTOPHE 3107') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 500,00 EUR | cible='MLF' quartz='FLORY GREGORY 77647S' |
| Nom du bénéficiaire différent d'une étape à l'autre | 500,00 EUR | cible='MOUNIB LYESSE 64632S' quartz='MLF' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 500,00 EUR | importe par Quartz ('MOUNIB LYESSE 64632S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 500,00 EUR | importe par Quartz ('MOUNIB LYESSE 64632S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 501,30 EUR | importe par Quartz ('LABADIOLE AURELIE 61132L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 506,94 EUR | importe par Quartz ('ROUSSEL MAURICE 63283S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 507,30 EUR | importe par Quartz ('LEFEBVRE OLIVIER 50032F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 514,04 EUR | importe par Quartz ('JARRY RODOLPHE 64855K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 521,37 EUR | importe par Quartz ('NEJJAR SOUFIANE 69843Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 522,04 EUR | importe par Quartz ('JIMENEZ ENZO 65743D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 525,14 EUR | importe par Quartz ('PICARELLI DIDIER 63868L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 529,36 EUR | importe par Quartz ('LAMLOUMI ZIED 61731A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 531,34 EUR | importe par Quartz ('DELAMASURE AURELIEN 6920') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 532,70 EUR | importe par Quartz ('MOUCHON CHRISTOPHE 52454') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 533,40 EUR | importe par Quartz ('VERDIER YANNICK 73950C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 535,04 EUR | importe par Quartz ('TAVERNIER XAVIER 76200N') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 540,00 EUR | cible='SAMSON REGULATION' quartz='ODO MATHIAS 75011Z' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 540,00 EUR | importe par Quartz ('SAMSON REGULATION') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 541,40 EUR | importe par Quartz ('BALDONI ALAIN 51558P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 548,45 EUR | importe par Quartz ('VITRY LUC 64218Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 548,95 EUR | importe par Quartz ('RICHARD EDOUARD 55006B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 549,63 EUR | importe par Quartz ('RELTIENNE MAXIME 47450J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 551,87 EUR | importe par Quartz ('CAPGRAS PIERRE 75028X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 552,40 EUR | importe par Quartz ('FRANCOIS PHILIPPE JEAN P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 557,50 EUR | importe par Quartz ('CAUJOLLE BASTIEN 53407Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 562,62 EUR | importe par Quartz ('MAURIN PATRICK 60924N') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 566,11 EUR | importe par Quartz ('COURSIA JEREMY 55778S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 571,38 EUR | importe par Quartz ('MICHAUT MICHAEL 56097L') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 572,70 EUR | importe par Quartz ('BERGHE GREGORY 44198E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 576,45 EUR | importe par Quartz ('QUILLIEN STEPHANE 61523B') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 600,00 EUR | cible='BOIS ENERGIE FRANCE' quartz='BAR VALERIE 55241K' |
| Nom du bénéficiaire différent d'une étape à l'autre | 600,00 EUR | cible='ESLC SERVICES' quartz='BOIS ENERGIE FRANCE' |
| Nom du bénéficiaire différent d'une étape à l'autre | 600,00 EUR | cible='KEEMIA' quartz='ESLC SERVICES' |
| Nom du bénéficiaire différent d'une étape à l'autre | 600,00 EUR | cible='LUXCORD' quartz='KEEMIA' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 600,00 EUR | importe par Quartz ('LUXCORD') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 621,92 EUR | importe par Quartz ('MASSENZIO ALBERT 69977A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 624,68 EUR | importe par Quartz ('QUERTINIER CYRIL 72327S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 629,05 EUR | importe par Quartz ('BLOUET CHANTAL 41090R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 642,08 EUR | importe par Quartz ('WAETERLOOS MAXIME 41376S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 650,00 EUR | importe par Quartz ('TRAVERS HUGO 74218E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 674,33 EUR | importe par Quartz ('MIRIBEL CARLA 73933E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 681,02 EUR | importe par Quartz ('BOUDET CHRISTOPHE 70340C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 690,94 EUR | importe par Quartz ('MALLIARD CLEMENT 76203S') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 700,00 EUR | cible='VILLIERE FABRICE' quartz='BARBAN HUGO 74779T' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 700,00 EUR | importe par Quartz ('VILLIERE FABRICE') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 702,66 EUR | importe par Quartz ('MONCHANIN ROMAIN 75000J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 706,68 EUR | importe par Quartz ('SORLIN EDOUARD 66403Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 718,51 EUR | importe par Quartz ('NICOLAS YOURI 54089W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 723,80 EUR | importe par Quartz ('JACQUES BERNARD 65164S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 724,71 EUR | importe par Quartz ('CHEVALLIER QUENTIN 63776') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 730,44 EUR | importe par Quartz ('ANFRIANI SEBASTIEN 61818') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 745,70 EUR | importe par Quartz ('MADAMOUR JULIEN 47161D') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 754,26 EUR | importe par Quartz ('MERY JEAN-LUC 54664B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 755,54 EUR | importe par Quartz ('ZERGAOUI STEPHANE 55468J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 774,80 EUR | importe par Quartz ('CHAMBRAULT NICOLAS 63926') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 792,85 EUR | importe par Quartz ('PEREZ ARNAUD 33417W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 805,13 EUR | importe par Quartz ('DUFAYET JULIEN 54461J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 807,25 EUR | importe par Quartz ('LICZBINSKI MICKAEL 68139') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 808,20 EUR | importe par Quartz ('PETIT GABRIEL 70810X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 812,11 EUR | importe par Quartz ('HAMELET MAXIME 75298B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 826,80 EUR | importe par Quartz ('BELLONCLE NOAN 76673K') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 839,22 EUR | importe par Quartz ('SIMEON OLIVIER 37228J') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 852,51 EUR | importe par Quartz ('BARGE EMILIE 60305Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 874,02 EUR | importe par Quartz ('REYNAUD LILIAN 63143H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 881,81 EUR | importe par Quartz ('RAYMONDAUD NICOLAS 46255') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 882,55 EUR | importe par Quartz ('ROBIN MORGANE 73002E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 906,50 EUR | importe par Quartz ('DELESALLE THOMAS 51843P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 918,30 EUR | importe par Quartz ('FONTAINE MICHAEL 42843Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 927,98 EUR | importe par Quartz ('GINDENSPERGER VINCENT 56') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 929,58 EUR | importe par Quartz ('ZOBNINE EVGUENI 65099F') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 934,37 EUR | importe par Quartz ('BOULACHEB KAMEL 38517E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 950,40 EUR | importe par Quartz ('RICHARD MICHAEL 72411C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 955,30 EUR | importe par Quartz ('FOLIN CELINE 74807E') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 978,25 EUR | importe par Quartz ('DUBREUIL FREDERIC 23049C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 996,90 EUR | importe par Quartz ('ROUILLIER FREDERIC 39691') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 1 000,00 EUR | cible='BAIGUE ISABELLE 75481S' quartz='AKTAS YUNUS 75564B' |
| Nom du bénéficiaire différent d'une étape à l'autre | 1 000,00 EUR | cible='FERNANDEZ EMMANUEL 61508' quartz='BAIGUE ISABELLE 75481S' |
| Nom du bénéficiaire différent d'une étape à l'autre | 1 000,00 EUR | cible='FORBAT' quartz='BAIGUE ISABELLE 75481S' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 000,00 EUR | importe par Quartz ('FERNANDEZ EMMANUEL 61508') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 000,00 EUR | importe par Quartz ('FERNANDEZ EMMANUEL 61508') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 000,00 EUR | importe par Quartz ('FORBAT') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 034,69 EUR | importe par Quartz ('DAMIN ERIC 40371W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 056,06 EUR | importe par Quartz ('AGUESSE JEROME 26692X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 067,83 EUR | importe par Quartz ('POULAIN GALLUCCIO VERONI') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 116,32 EUR | importe par Quartz ('DANO OLIVIER 77213X') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 140,65 EUR | importe par Quartz ('GANEY LOIC 78262B') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 204,60 EUR | importe par Quartz ('NARME MARC 21140R') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 273,14 EUR | importe par Quartz ('LACROIX LOIS 77786A') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 295,72 EUR | importe par Quartz ('GRANIER GILLES 38127S') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 304,67 EUR | importe par Quartz ('MOUSSAOUI HAMOU 61365T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 380,50 EUR | importe par Quartz ('MONTEIRO LUCILIA 48689P') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 476,81 EUR | importe par Quartz ('KOCH THIBAUT 62892C') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 508,65 EUR | importe par Quartz ('LOUBSENS BENOIT 47943H') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 959,99 EUR | importe par Quartz ('VEYRET OLIVIER 43357Z') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 967,85 EUR | importe par Quartz ('VOLTZ NICOLAS 13162T') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 1 988,21 EUR | importe par Quartz ('MOREAU FABIEN 65141L') mais non envoye |
| Nom du bénéficiaire différent d'une étape à l'autre | 2 000,00 EUR | cible='SARL KAMBOH' quartz='BALCON JEREMY 65037A' |
| Nom du bénéficiaire différent d'une étape à l'autre | 2 000,00 EUR | cible='THIERRY OLIVIER 76414W' quartz='SARL KAMBOH' |
| Virement repris par la trésorerie sans envoi correspondant du jour | 2 000,00 EUR | importe par Quartz ('THIERRY OLIVIER 76414W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 2 000,00 EUR | importe par Quartz ('THIERRY OLIVIER 76414W') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 2 215,00 EUR | importe par Quartz ('BESNARD DIMITRI 68113Y') mais non envoye |
| Virement repris par la trésorerie sans envoi correspondant du jour | 2 310,22 EUR | importe par Quartz ('EMEREAU ANTHONY 77354F') mais non envoye |

---

## 4. Comprendre les écarts relevés

Pour chaque nature d'écart apparaissant ci-dessus, voici ce que cela signifie concrètement et l'impact potentiel.

**Virement repris par la trésorerie sans envoi correspondant du jour**

La trésorerie a importé un virement qui ne fait pas partie des virements émis sur la journée contrôlée. Il s'agit le plus souvent d'un virement d'une journée précédente repris avec du retard, à confirmer avec la trésorerie.

**Nom du bénéficiaire différent d'une étape à l'autre**

Le montant correspond bien, mais le nom du bénéficiaire n'est pas identique entre les deux étapes comparées. Le paiement peut être rejeté par la banque ou versé au mauvais destinataire.

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
