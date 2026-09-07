# Note fonctionnelle — Interface Employés (Cador → Oracle HRMS)
## Correction de la gestion des annulations de date de fin de contrat

**Objet :** INT076 / package `DKA_IHREMP_PKG` — traitement d'un flux correctif envoyant une date de fin vide.
**Destinataires :** équipe fonctionnelle RH / Finance, recette.
**Statut :** développement réalisé, en attente de validation fonctionnelle et de recette.

---

## 1. Le besoin métier

Cador transmet quotidiennement à Oracle les données des employés, dont la **date de fin de contrat**.

Il arrive qu'une date de fin soit transmise **par erreur** (saisie erronée, contrat finalement non rompu). Cador corrige alors l'erreur en renvoyant le même employé avec une **date de fin vide**.

Attendu métier : *l'employé doit redevenir actif exactement comme s'il n'était jamais sorti* — même contrat, même ancienneté, même historique.

---

## 2. Le problème constaté

Aujourd'hui, Oracle ne fait pas la différence entre :

| Situation métier | Ce que reçoit Oracle | Ce qu'Oracle devrait faire |
|---|---|---|
| **Réembauche** — l'employé était bien parti, il revient | Employé sorti + une nouvelle date de début | Créer une nouvelle période de contrat |
| **Annulation de sortie** — la date de fin était une erreur | Employé sorti + date de fin vide | Supprimer la sortie, restaurer le contrat d'origine |

Dans les deux cas, le programme traitait l'employé comme une **réembauche**.

**Conséquences sur le dossier RH :**
- création d'une **deuxième période de contrat** alors que l'employé n'a jamais quitté l'entreprise ;
- **rupture d'ancienneté** : le compteur repart à la date de « réembauche » ;
- **doublon de contrat** dans l'historique de l'employé ;
- risques en aval : calculs de paie, droits liés à l'ancienneté, éditions et reportings RH, éventuels impacts sur le fournisseur associé à l'employé.

Ces dossiers doivent aujourd'hui être corrigés manuellement par les gestionnaires RH.

---

## 3. La correction apportée

Le programme distingue désormais les deux situations et applique le traitement Oracle adapté.

**Nouvelle règle de gestion :**

> Si l'employé est **déjà sorti** dans Oracle **et** que le flux Cador transmet une **date de fin vide**,
> alors il s'agit d'une **annulation de sortie** : la sortie est supprimée et la période de contrat initiale est restaurée.

Concrètement, après traitement :
- l'employé redevient **actif** ;
- sa **date de fin de contrat est effacée** ;
- sa **période de contrat d'origine est conservée** — pas de nouvelle période, **ancienneté préservée** ;
- les **informations de départ** associées à la sortie (motif, etc.) sont également effacées ;
- **aucun doublon** n'est créé dans l'historique.

Le cas de la **vraie réembauche reste inchangé** : si le flux transmet une nouvelle date de début sur un employé sorti, le comportement actuel (création d'une nouvelle période) s'applique toujours.

---

## 4. Ce qui ne change pas

- La **sortie d'un employé** (date de fin transmise sur un employé actif) : comportement identique.
- La **réembauche** d'un employé réellement parti : comportement identique.
- Les autres mises à jour du flux (affectations, organisation, données bancaires, fournisseur) : inchangées.
- Le **suivi des erreurs** : si l'annulation échoue, l'employé est rejeté en erreur d'interface avec le message « Erreur dans l'annulation de la sortie de l'employé » et devra être retraité — le dossier RH n'est pas modifié à moitié.

---

## 5. Scénarios de recette à valider

| # | Scénario | Données en entrée | Résultat attendu |
|---|---|---|---|
| 1 | Sortie erronée puis correction | Flux 1 : date de fin 15/05/2024 → Flux 2 : date de fin vide | Employé actif, date de fin vide, **une seule** période de contrat, date de début d'origine inchangée |
| 2 | Vraie réembauche | Employé sorti au 31/01/2024 → flux avec nouvelle date de début 01/09/2024 | **Deux** périodes de contrat (comportement actuel conservé) |
| 3 | Sortie normale | Employé actif → flux avec date de fin | Employé sorti (comportement actuel conservé) |
| 4 | Flux sans effet | Employé **actif**, flux avec date de fin vide | Aucun changement, aucune erreur |
| 5 | Double correction | Le flux correctif (date de fin vide) est rejoué une seconde fois | Aucun changement, aucune erreur |
| 6 | Ancienneté | Après scénario 1 | Vérifier la date d'ancienneté et les éléments de paie de l'employé |

---

## 6. Points à confirmer par le fonctionnel

1. **Périmètre de l'annulation** : la correction annule **la dernière sortie enregistrée**. Confirmez-vous que c'est bien l'attendu pour un employé ayant plusieurs périodes de contrat successives (plusieurs sorties dans son historique) ?
2. **Effacement des informations de départ** : le motif de départ et les informations associées à la sortie sont supprimés. Confirmez-vous, ou faut-il en conserver une trace (commentaire, historique) ?
3. **Délai de correction** : y a-t-il une limite au-delà de laquelle une sortie ne doit plus être annulée automatiquement (ex. sortie de plus de X mois, période de paie déjà close) ? Le développement actuel n'impose aucune limite.
4. **Éléments liés à la sortie** : des traitements ont-ils pu être déclenchés entre la sortie erronée et sa correction (solde de tout compte, désactivation du fournisseur, clôture d'accès) ? Faut-il prévoir une reprise manuelle sur ces éléments ?
5. **Reprise de l'existant** : faut-il identifier et corriger les dossiers déjà pollués par des réembauches injustifiées, ou la correction ne s'applique-t-elle qu'aux flux à venir ?

---

## 7. Prérequis technique avant recette

La procédure standard Oracle utilisée pour l'annulation doit être validée sur l'instance cible avant livraison (contrôle technique, sans impact fonctionnel). Voir `prompt.md` et `reverse_termination.sql` pour le détail technique.
