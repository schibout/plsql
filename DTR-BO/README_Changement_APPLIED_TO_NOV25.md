# RÉSUMÉ : Changement APPLIED_TO_DIST_ID_NUM_1 en NOV-25

## 🔴 PROBLÈME

Votre requête retournait des données en OCT-25 mais plus rien en NOV-25.

## ✅ CAUSE IDENTIFIÉE

**Oracle a changé son comportement depuis NOV-25** :

| Champ | OCT-25 | NOV-25 | Impact |
|-------|--------|--------|--------|
| `XLA_DISTRIBUTION_LINKS.APPLIED_TO_DIST_ID_NUM_1` | ✅ Alimenté (62,852 lignes) | ❌ NULL (0 ligne) | **Requête cassée** |

## 📊 STATISTIQUES

```
OCT-25 : 131,435 lignes de provisions
├─ 62,852 avec APPLIED_TO_DIST_ID_NUM_1 (47.8%)
└─ 68,583 sans APPLIED_TO_DIST_ID_NUM_1 (52.2%)

NOV-25 : 126,921 lignes de provisions
├─ 0 avec APPLIED_TO_DIST_ID_NUM_1 (0%) ❌
└─ 126,921 sans APPLIED_TO_DIST_ID_NUM_1 (100%)
```

## 🔧 SOLUTION

### Ancienne Requête (cassée en NOV-25)
```sql
LEFT OUTER JOIN po.po_distributions_all pda
    ON PDA.po_distribution_id = XDL.APPLIED_TO_DIST_ID_NUM_1
WHERE pda.PO_DISTRIBUTION_ID IS NOT NULL  -- ❌ Retourne 0 ligne en NOV-25
```

### Nouvelle Requête (fonctionne OCT et NOV)
```sql
-- Ajouter cette jointure :
LEFT OUTER JOIN PO.RCV_TRANSACTIONS RT
    ON RT.TRANSACTION_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
    AND XDL.SOURCE_DISTRIBUTION_TYPE = 'RCV_RECEIVING_SUB_LEDGER'

-- Modifier la jointure PO :
LEFT OUTER JOIN PO.PO_DISTRIBUTIONS_ALL PDA
    ON PDA.PO_DISTRIBUTION_ID = COALESCE(
           XDL.APPLIED_TO_DIST_ID_NUM_1,  -- OCT-25
           RT.PO_DISTRIBUTION_ID          -- NOV-25
       )

-- Modifier le filtre :
WHERE RT.TRANSACTION_ID IS NOT NULL  -- ✅ Au lieu de PDA.PO_DISTRIBUTION_ID
```

## 📁 FICHIERS CRÉÉS

1. **Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql**
   - Requête complète corrigée et commentée
   - Fonctionne pour OCT-25 ET NOV-25

2. **Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md**
   - Analyse technique détaillée
   - Comparaison OCT-25 vs NOV-25
   - Explications et recommandations

## ⚡ RÉSULTATS ATTENDUS

Avec la nouvelle requête :

| Période | Ancienne Requête | Nouvelle Requête | Amélioration |
|---------|-----------------|------------------|--------------|
| OCT-25 | 62,852 lignes | ~119,931 lignes | +91% |
| NOV-25 | **0 ligne** ❌ | **~116,975 lignes** ✅ | ∞ |

## 🎯 ACTION IMMÉDIATE

1. ✅ Utiliser **Requete_provisions_CORRIGEE_compatible_OCT_NOV.sql**
2. ⏳ Identifier les autres requêtes utilisant `APPLIED_TO_DIST_ID_NUM_1`
3. ⏳ Modifier toutes les requêtes avec le nouveau pattern

## 📞 SUPPORT

Si vous avez des questions, consultez :
- **Analyse_APPLIED_TO_DIST_ID_NUM_1_OCT_vs_NOV.md** (analyse complète)
- **CONCLUSION_Analyse_provisions_NOV25.md** (contexte général)

---

**Date :** 01/12/2025  
**Statut :** ✅ RÉSOLU  
**Impact :** Critique - Toutes les requêtes sur provisions NOV-25 affectées
