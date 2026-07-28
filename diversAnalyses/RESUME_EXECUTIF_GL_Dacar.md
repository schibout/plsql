# Résumé Exécutif - Rejet GL Dacar : GET_UO_DALKIA_FROM_TACHE

## 🔴 Problème

**Date** : 24/12/2025 à 05:00:02  
**Système** : Interface GL Dacar → Oracle EBS  
**Erreur** : `VHC02_SRC_ECRITURESGL_241225-050002|GET_UO_DALKIA_FROM_TACHE|ASSURANCE202512-0001`  
**Impact** : Deux pièces GL bloquées, comptabilité Dacar en attente

## 🔍 Cause Racine

Le système Oracle EBS utilise une table de liaison (`HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12`) pour retrouver l'Operating Unit à partir d'une tâche projet.

**Données identifiées** :
- **Tâche utilisée par le flux** : GK1596490T (TF TRAVAUX DTGP MIDI)
- **Projet** : FB0092005B-DNA_0001PF ORG TRAV
- **Operating Unit** : DNA0001 (Org ID 89)
- **Problème** : ATTRIBUTE12 contient `GK0001338W` au lieu de `GK1596490T`

**Flux technique** :
```
Flux GL → Tâche GK1596490T → Recherche dans HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12
                           → Aucune correspondance trouvée
                           → ERREUR : GET_UO_DALKIA_FROM_TACHE
```

## ✅ Solution Recommandée

**Mise à jour du champ ATTRIBUTE12** de l'Operating Unit DNA0001 :

```sql
UPDATE APPS.HR_ALL_ORGANIZATION_UNITS
SET ATTRIBUTE12 = 'GK1596490T'
WHERE ORGANIZATION_ID = 89 AND NAME = 'DNA0001';
```

**Durée d'intervention** : 5 minutes (+ tests)  
**Risque** : Faible (si validation fonctionnelle préalable)  
**Réversibilité** : Oui (sauvegarde de l'ancienne valeur)

## 📋 Actions Requises

### Avant Correction
1. ✅ **Validation fonctionnelle** : Confirmer que GK1596490T est la bonne tâche pour DNA0001
2. ✅ **Vérifier impact** : S'assurer que l'ancienne tâche GK0001338W n'est plus utilisée

### Correction (DBA)
3. ⏳ **Exécuter le script** : `CORRECTION_GL_Dacar_GK1596490T.sql`
4. ⏳ **Valider la mise à jour** : Vérifier que ATTRIBUTE12 = 'GK1596490T'

### Après Correction
5. ⏳ **Retraiter les pièces GL** : Relancer le batch VHC02_SRC_ECRITURESGL
6. ⏳ **Vérifier l'intégration** : Confirmer que les pièces passent en statut SUCCESS

## 📊 Prévention

### Court Terme
- Documenter la correspondance Projet → Tâche → UO pour Dacar
- Ajouter un monitoring sur les rejets GL avec erreur "GET_UO_DALKIA_FROM_TACHE"

### Moyen Terme
- Améliorer la fonction `get_task_number` pour rechercher l'UO via le projet (plus robuste)
- Créer une alerte automatique lors de changement de tâche dans les projets actifs

### Long Terme
- Automatiser la synchronisation entre PA_TASKS et HR_ALL_ORGANIZATION_UNITS.ATTRIBUTE12
- Implémenter un contrôle de cohérence mensuel

## 📎 Documents Associés

- **Analyse détaillée** : `Analyse_Erreur_GL_Dacar_GET_UO_DALKIA_FROM_TACHE.md`
- **Script de correction** : `CORRECTION_GL_Dacar_GK1596490T.sql`
- **Package concerné** : XXEAI.XXEAI_INTERFACE_TOOLS_PKG (lignes 234-251, 1143-1151)

## 👥 Contacts

- **DBA** : Exécution du script de correction
- **Équipe Fonctionnelle Dacar** : Validation de la tâche GK1596490T
- **Support EBS** : Retraitement des pièces GL après correction

---

**Date d'analyse** : 29/12/2025  
**Analyste** : GitHub Copilot  
**Statut** : ⏳ En attente de validation fonctionnelle
