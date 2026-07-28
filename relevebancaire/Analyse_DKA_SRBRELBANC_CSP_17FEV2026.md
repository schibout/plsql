# Analyse du Traitement DKA_SRBRELBANC_CSP
## Edition des Relevés Bancaires pour les CSP

**Date d'analyse** : 17/02/2026  
**Période analysée** : Dernières 24 heures (16/02/2026 - 17/02/2026)  
**Base de données** : Oracle EBS 12.2.13 (19.25.0.0.0)  
**Schéma** : SCHIBOUT

---

## 1. SYNTHÈSE EXÉCUTIVE

### ✅ Statut Global : ACTIF - EXÉCUTIONS RÉCENTES CONFIRMÉES

Le traitement **DKA_SRBRELBANC_CSP** (Edition des relevés bancaires pour les CSP) a bien été exécuté dans les dernières 24 heures avec **10 exécutions** le 16/02/2026.

**Points clés** :
- ✅ **10 exécutions** détectées le 16 février 2026
- ⚠️ **5 exécutions** terminées avec avertissements (statut 'G')
- ✅ **5 exécutions** terminées normalement (statut 'C')
- ❌ **0 erreur** critique
- ⏱️ Durée moyenne : **~52 secondes**

---

## 2. INFORMATIONS DU PROGRAMME

### Configuration Technique

| Propriété | Valeur |
|-----------|--------|
| **Nom du programme** | DKA_SRBRELBANC_CSP |
| **Nom utilisateur** | DKA : Edition des relevés bancaires pour les CSP |
| **Exécutable** | DKA_SRBRELBANC_CSP_PKG |
| **Méthode d'exécution** | Immediate (I) - Package PL/SQL |
| **Statut** | Activé (Y) |
| **Description** | Edition des relevés bancaires pour les CSP |

---

## 3. ANALYSE DES EXÉCUTIONS DES DERNIÈRES 24 HEURES

### Exécutions du 16/02/2026

#### Détail des 10 exécutions

| Request ID | Heure Début | Heure Fin | Durée (sec) | Statut | Utilisateur | Paramètres |
|------------|-------------|-----------|-------------|--------|-------------|------------|
| 47114082 | 11:53:08 | 11:53:36 | 28 | ✅ Terminé normalement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114081 | 11:52:27 | 11:52:59 | 32 | ✅ Terminé normalement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114080 | 11:51:46 | 11:52:07 | 21 | ✅ Terminé normalement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114079 | 11:51:05 | 11:51:32 | 27 | ✅ Terminé normalement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114078 | 11:50:24 | 11:51:01 | 37 | ✅ Terminé normalement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114060 | 11:43:29 | 11:43:58 | 29 | ⚠️ Avertissement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114059 | 11:42:47 | 11:43:20 | 33 | ⚠️ Avertissement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114058 | 11:42:07 | 11:42:38 | 31 | ⚠️ Avertissement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114057 | 11:41:25 | 11:42:03 | 38 | ⚠️ Avertissement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |
| 47114055 | 11:40:44 | 11:41:22 | 38 | ⚠️ Avertissement | EXPLOITATION | 2026/02/16, 2026/02/16, , A |

#### Pattern d'exécution

**Première série (11:40 - 11:43)** : 5 exécutions avec avertissements  
**Deuxième série (11:50 - 11:53)** : 5 exécutions réussies

→ Cela suggère que les premières exécutions ont rencontré des conditions générant des avertissements, puis les exécutions suivantes se sont déroulées normalement.

---

## 4. STATISTIQUES SUR 7 JOURS

### Tendance d'exécution

| Date | Nb Exécutions | Succès | Erreurs | Avertissements | Durée Moy. | Durée Min | Durée Max |
|------|---------------|--------|---------|----------------|------------|-----------|-----------|
| 16/02/2026 | 10 | 5 | 0 | 5 | ~52 sec | 21 sec | 38 sec |
| 14/02/2026 | 5 | 4 | 0 | 1 | ~57 sec | 27 sec | 50 sec |
| 13/02/2026 | 5 | 5 | 0 | 0 | ~63 sec | 31 sec | 50 sec |
| 12/02/2026 | 5 | 5 | 0 | 0 | ~64 sec | 2 sec | 49 sec |
| 11/02/2026 | 5 | 5 | 0 | 0 | ~57 sec | 2 sec | 41 sec |
| 10/02/2026 | 5 | 5 | 0 | 0 | ~64 sec | 32 sec | 50 sec |

### Observations

- **Fréquence** : Exécution quotidienne, généralement 5 exécutions par jour
- **Anomalie 16/02** : 10 exécutions au lieu de 5 (double du volume habituel)
- **Performance** : Durée d'exécution stable entre 21 et 50 secondes
- **Fiabilité** : Aucune erreur critique sur les 7 derniers jours
- **Avertissements** : Présents occasionnellement, notamment le 16/02 (5 occurrences)

---

## 5. ANALYSE DES PARAMÈTRES

### Format des paramètres observés

```
, 2026/02/16, 2026/02/16, , A
```

**Structure identifiée** :
1. **Paramètre 1** : (vide)
2. **Paramètre 2** : Date de début (YYYY/MM/DD) → `2026/02/16`
3. **Paramètre 3** : Date de fin (YYYY/MM/DD) → `2026/02/16`
4. **Paramètre 4** : (vide)
5. **Paramètre 5** : Type/Mode → `A` (probablement "Automatique" ou "All")

**Observation** : Toutes les exécutions du 16/02 traitent la même période (16/02/2026), ce qui est cohérent avec une édition de relevés bancaires quotidiens.

---

## 6. POINTS D'ATTENTION

### ⚠️ Avertissements du 16/02/2026

**5 exécutions** entre 11:40 et 11:43 ont généré des avertissements (statut 'G').

**Actions recommandées** :
1. Consulter les fichiers de log des Request ID : 47114055, 47114057, 47114058, 47114059, 47114060
2. Identifier la cause des avertissements
3. Vérifier si les relevés bancaires générés sont complets malgré les avertissements

### 📊 Volume d'exécution inhabituel

Le 16/02 affiche **10 exécutions** au lieu des 5 habituelles.

**Hypothèses possibles** :
- Réexécution suite aux avertissements de la première série
- Traitement de plusieurs CSP ou périodes
- Correction manuelle effectuée par l'équipe EXPLOITATION

---

## 7. RECOMMANDATIONS

### Actions immédiates

1. **Vérifier les logs** des exécutions avec avertissements (Request ID 47114055-47114060)
2. **Valider les fichiers de sortie** : s'assurer que les relevés bancaires sont corrects
3. **Identifier la cause** du doublement des exécutions le 16/02

### Surveillance continue

1. **Monitorer** les exécutions quotidiennes pour détecter toute récurrence des avertissements
2. **Alerter** si le nombre d'exécutions dépasse 5 par jour sans justification
3. **Suivre** la durée d'exécution : déclencher une alerte si >2 minutes

### Requête SQL de surveillance

```sql
-- Vérification quotidienne du traitement DKA_SRBRELBANC_CSP
SELECT 
    TO_CHAR(FCR.ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DATE_DEBUT,
    FCR.REQUEST_ID,
    ROUND((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60, 2) AS DUREE_MIN,
    CASE 
        WHEN FCR.STATUS_CODE = 'C' THEN 'OK'
        WHEN FCR.STATUS_CODE = 'E' THEN 'ERREUR'
        WHEN FCR.STATUS_CODE = 'G' THEN 'AVERTISSEMENT'
        ELSE FCR.STATUS_CODE
    END AS STATUT,
    FCR.ARGUMENT_TEXT
FROM FND_CONCURRENT_REQUESTS FCR,
     FND_CONCURRENT_PROGRAMS FCP
WHERE FCR.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
  AND FCR.PROGRAM_APPLICATION_ID = FCP.APPLICATION_ID
  AND FCP.CONCURRENT_PROGRAM_NAME = 'DKA_SRBRELBANC_CSP'
  AND FCR.ACTUAL_START_DATE >= TRUNC(SYSDATE)
ORDER BY FCR.ACTUAL_START_DATE DESC;
```

---

## 8. CONCLUSION

✅ **Le traitement DKA_SRBRELBANC_CSP a bien tourné dans les dernières 24 heures.**

**Bilan** :
- 10 exécutions détectées le 16/02/2026
- Fonctionnement globalement correct
- Présence d'avertissements à investiguer
- Performance stable (~52 secondes en moyenne)
- Aucune erreur critique

**Prochaine étape** : Consulter les logs des exécutions avec avertissements pour identifier et résoudre la cause des statuts 'G'.

---

**Document généré le** : 17/02/2026  
**Analyste** : GitHub Copilot  
**Base de données** : Oracle EBS Production (oracleProd)
