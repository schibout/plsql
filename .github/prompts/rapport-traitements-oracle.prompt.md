---
description: "Générer un rapport d'analyse de traitements batch Oracle EBS - Utiliser pour analyser traitements nocturnes, programmes concurrents récurrents, fenêtres de traitement"
name: "Rapport Traitements Oracle"
argument-hint: "Type de traitement (nuit/contrôle/batch) et période"
agent: "agent"
tools: ["sqlcl/*", "file_search", "read_file", "create_file"]
---

# Génération de Rapport de Traitements Oracle EBS

Vous êtes un expert en analyse de traitements batch Oracle E-Business Suite. Générez un rapport détaillé des traitements périodiques (nocturnes, contrôles, batch).

## Connexion

```
Établir connexion via mcp_sqlcl_-_sql_d_connect avec "oracleProd"
```

## Requête Standard pour Analyse de Traitements

```sql
SELECT 
    FCP.CONCURRENT_PROGRAM_NAME,
    FCPTL.USER_CONCURRENT_PROGRAM_NAME,
    FCR.REQUEST_ID,
    FCR.ACTUAL_START_DATE,
    FCR.ACTUAL_COMPLETION_DATE,
    ROUND((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60, 2) as DUREE_MINUTES,
    FCR.STATUS_CODE,
    FCR.PHASE_CODE,
    FU.USER_NAME as UTILISATEUR
FROM FND_CONCURRENT_REQUESTS FCR
JOIN FND_CONCURRENT_PROGRAMS FCP ON FCR.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
    AND FCR.PROGRAM_APPLICATION_ID = FCP.APPLICATION_ID
JOIN FND_CONCURRENT_PROGRAMS_TL FCPTL ON FCP.CONCURRENT_PROGRAM_ID = FCPTL.CONCURRENT_PROGRAM_ID
    AND FCP.APPLICATION_ID = FCPTL.APPLICATION_ID
    AND FCPTL.LANGUAGE = 'F'
LEFT JOIN FND_USER FU ON FCR.REQUESTED_BY = FU.USER_ID
WHERE FCR.ACTUAL_START_DATE BETWEEN TO_DATE('[date_debut]', 'DD/MM/YYYY HH24:MI:SS')
                                AND TO_DATE('[date_fin]', 'DD/MM/YYYY HH24:MI:SS')
ORDER BY FCR.ACTUAL_START_DATE;
```

**Adaptations selon le type** :
- **Traitements nocturnes** : 00h00-06h59
- **Contrôles du soir** : 19h00-23h59
- **Traitements du matin** : 07h00-12h00

## Structure du Rapport

Générer un fichier Markdown avec la structure suivante :

```markdown
# Rapport des Traitements [Type] Oracle EBS - [Période]

**Date d'analyse** : [Date]  
**Période couverte** : [Dates]  
**Fenêtre horaire** : [Plage]  
**Base de données** : Oracle EBS 12.2.13 (oracleProd)

---

## 1. Résumé Exécutif

### Vue d'Ensemble

- **Nombre total d'exécutions** : [X] programmes
- **Durée totale** : [Y] heures
- **Plage horaire** : [HH:MM] - [HH:MM]
- **Taux de succès** : [Z]%

### Faits Saillants

- [Observation principale 1]
- [Observation principale 2]
- [Problèmes critiques si présents]

---

## 2. Analyse Temporelle

### 2.1 Distribution par Période

| Plage Horaire | Nb Exécutions | Durée Totale (min) | % du Total |
|---------------|---------------|---------------------|------------|
| [HH:MM-HH:MM] | X | Y | Z% |
| ... | ... | ... | ... |

### 2.2 Fenêtre de Pic d'Activité

**Pic principal** : [HH:MM] - [HH:MM]  
**Nombre d'exécutions** : [X]  
**Programmes concernés** : [Top 3]

[Graphique textuel ou description]

---

## 3. Top Programmes

### 3.1 Par Fréquence d'Exécution

| Rang | Programme | Nom Utilisateur | Nb Exécutions | Fréquence |
|------|-----------|-----------------|---------------|-----------|
| 1 | [PROGRAM_NAME] | [USER_NAME] | X | Y par heure |
| 2 | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

### 3.2 Par Durée Totale

| Rang | Programme | Nom Utilisateur | Durée Totale (h) | Durée Moyenne (min) |
|------|-----------|-----------------|------------------|---------------------|
| 1 | [PROGRAM_NAME] | [USER_NAME] | X.XX | Y.Y |
| 2 | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

### 3.3 Par Durée Unitaire

| Rang | Programme | REQUEST_ID | Durée (min) | Date Exécution |
|------|-----------|------------|-------------|----------------|
| 1 | [PROGRAM_NAME] | [ID] | X.X | [DATE] |
| 2 | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

---

## 4. Analyse par Module

### Module [AP/GL/PO/XLA/FA/etc.]

**Nombre d'exécutions** : [X]  
**Durée totale** : [Y] heures  
**Programmes principaux** :
- `[PROGRAM_1]` : [X] exécutions, [Y] min total
- `[PROGRAM_2]` : [X] exécutions, [Y] min total

[Répéter pour chaque module significatif]

---

## 5. État des Exécutions

### 5.1 Statuts

| Statut | Nombre | Pourcentage |
|--------|--------|-------------|
| Completed (C) | X | Y% |
| Error (E) | X | Y% |
| Warning (W) | X | Y% |
| Running (R) | X | Y% |

### 5.2 Erreurs et Avertissements

[Si COUNT > 0 pour erreurs/warnings]

**Programmes en erreur** :

| Programme | REQUEST_ID | Date | Message |
|-----------|------------|------|---------|
| [PROGRAM] | [ID] | [DATE] | [Si disponible] |

**Action recommandée** : [Investigation requise / Contact support / etc.]

---

## 6. Comparaison Historique

[Si des données de référence existent]

### Évolution vs Période Précédente

| Métrique | [Période N-1] | [Période N] | Évolution |
|----------|---------------|-------------|-----------|
| Nb exécutions | X | Y | +Z% |
| Durée totale | X h | Y h | +Z% |
| Taux erreur | X% | Y% | +Z pp |

### Anomalies Détectées

- [Augmentation inhabituelle de X]
- [Nouvelle apparition de Y]
- [Disparition de Z]

---

## 7. Programmes Critiques

### Définition

Programmes identifiés comme critiques pour le processus métier :
- Durée > [seuil] minutes
- Fréquence > [seuil] exécutions/heure
- Impact métier élevé

### Liste des Programmes Critiques

#### 1. [Nom Programme]

- **ID Concurrent** : [CONCURRENT_PROGRAM_ID]
- **Nombre d'exécutions** : [X]
- **Durée moyenne** : [Y] min
- **Durée max observée** : [Z] min ([REQUEST_ID])
- **Module** : [AP/GL/etc.]
- **Impact métier** : [Description]
- **Dépendances** : [Autres programmes dépendants]

[Répéter pour chaque programme critique]

---

## 8. Patterns Identifiés

### 8.1 Chaînes de Traitement

**Chaîne 1 : [Nom de la chaîne]**
- `Programme A` ([HH:MM]) → `Programme B` ([HH:MM]) → `Programme C` ([HH:MM])
- Durée totale : [X] min
- Fréquence : [Y] fois/jour

### 8.2 Programmes Récurrents

| Programme | Intervalle | Fenêtre | Régularité |
|-----------|------------|---------|------------|
| [PROGRAM] | [X] min | [HH:MM-HH:MM] | [Toutes les X min] |

---

## 9. Recommandations

### 9.1 Optimisations Suggérées

1. **[Programme X]** : [Recommandation précise]
   - Cause : [Description]
   - Gain estimé : [X] min/exécution
   - Priorité : [Haute/Moyenne/Basse]

2. **[Programme Y]** : [Recommandation précise]
   - ...

### 9.2 Surveillance Renforcée

Programmes nécessitant une surveillance accrue :
- `[PROGRAM_1]` : [Raison]
- `[PROGRAM_2]` : [Raison]

### 9.3 Fenêtre de Traitement

**Capacité actuelle** : [X] exécutions sur fenêtre de [Y] heures  
**Utilisation** : [Z]% de la capacité  
**Marge disponible** : [Calcul]

**Recommandation** : [Maintenir/Optimiser/Étendre fenêtre]

---

## 10. Requêtes SQL Utilisées

### Requête Principale

\`\`\`sql
-- Extraction complète des traitements
[Code SQL complet utilisé]
\`\`\`

### Requêtes Complémentaires

[Autres requêtes SQL exécutées pour l'analyse]

---

## 11. Annexes

### A. Méthodologie

- **Période d'analyse** : [X] jours
- **Source des données** : `FND_CONCURRENT_REQUESTS`, `FND_CONCURRENT_PROGRAMS`
- **Critères de filtrage** : [Description]
- **Exclusions** : [Si applicable]

### B. Définitions

- **Durée** : `(ACTUAL_COMPLETION_DATE - ACTUAL_START_DATE) * 24 * 60` (minutes)
- **Taux de succès** : `(Completed / Total) * 100`
- **Fenêtre critique** : 00h00-06h59 (traitements nocturnes)

### C. Références

- [Rapports précédents similaires]
- [Documentation Oracle]
- [Procédures internes]

---

**Date de génération** : [Timestamp]  
**Généré par** : GitHub Copilot avec connexion oracleProd
```

## Requêtes SQL Complémentaires Utiles

### Top 20 Programmes par Fréquence

```sql
SELECT 
    FCP.CONCURRENT_PROGRAM_NAME,
    FCPTL.USER_CONCURRENT_PROGRAM_NAME,
    COUNT(*) as NB_EXECUTIONS,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) as DUREE_MOY_MIN
FROM FND_CONCURRENT_REQUESTS FCR
JOIN FND_CONCURRENT_PROGRAMS FCP ON FCR.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
JOIN FND_CONCURRENT_PROGRAMS_TL FCPTL ON FCP.CONCURRENT_PROGRAM_ID = FCPTL.CONCURRENT_PROGRAM_ID
WHERE FCR.ACTUAL_START_DATE BETWEEN [date_debut] AND [date_fin]
  AND FCR.STATUS_CODE = 'C'
GROUP BY FCP.CONCURRENT_PROGRAM_NAME, FCPTL.USER_CONCURRENT_PROGRAM_NAME
ORDER BY NB_EXECUTIONS DESC
FETCH FIRST 20 ROWS ONLY;
```

### Distribution Horaire

```sql
SELECT 
    TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24') as HEURE,
    COUNT(*) as NB_EXECUTIONS,
    ROUND(SUM((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) as DUREE_TOTALE_MIN
FROM FND_CONCURRENT_REQUESTS FCR
WHERE FCR.ACTUAL_START_DATE BETWEEN [date_debut] AND [date_fin]
GROUP BY TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')
ORDER BY HEURE;
```

### Programmes en Erreur

```sql
SELECT 
    FCP.CONCURRENT_PROGRAM_NAME,
    FCR.REQUEST_ID,
    FCR.ACTUAL_START_DATE,
    FCR.STATUS_CODE,
    FCR.PHASE_CODE
FROM FND_CONCURRENT_REQUESTS FCR
JOIN FND_CONCURRENT_PROGRAMS FCP ON FCR.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
WHERE FCR.ACTUAL_START_DATE BETWEEN [date_debut] AND [date_fin]
  AND FCR.STATUS_CODE IN ('E', 'X')
ORDER BY FCR.ACTUAL_START_DATE DESC;
```

## Types de Rapports Spécialisés

### 1. Rapport Traitements Nocturnes

**Fenêtre** : 00h00-06h59  
**Focus** : Programmes critiques (GL, AP, FA accounting)  
**Références** : `Rapport_Traitements_Nuit_Oracle_EBS.md`, `controleNuit.md`

### 2. Rapport Contrôles du Soir

**Fenêtre** : 19h00-23h59  
**Focus** : Post-business processing (XLA Create Accounting)  
**Références** : `controleNuit.md`

### 3. Rapport Flux Quotidiens

**Fenêtre** : 24h  
**Focus** : Intégrations (iValua, Hercule, ControlM)  
**Références** : `Rapport_Traitements_Flux_DKA_SCTLFLUX_EAI.md`

## Convention de Nommage

**Format** : `Rapport_Traitements_[Type]_[Période]_Oracle_EBS.md`

**Exemples** :
- `Rapport_Traitements_Nuit_Jan26_Oracle_EBS.md`
- `Rapport_Traitements_Soir_Semaine_S03_2026_Oracle_EBS.md`
- `Rapport_Batch_Mensuel_Fev26_Oracle_EBS.md`

## Checklist Avant Publication

- [ ] Connexion oracleProd établie et testée
- [ ] Période d'analyse claire et validée
- [ ] Au moins 3 requêtes SQL exécutées
- [ ] Top 20 programmes identifiés
- [ ] Distribution temporelle analysée
- [ ] Erreurs et warnings listés
- [ ] Recommandations actionables fournies
- [ ] Comparaison historique (si données disponibles)
- [ ] Format Markdown validé
- [ ] Fichier sauvegardé dans le workspace racine

## Tone

- **Professionnel et structuré** : Rapport destiné aux équipes techniques et métier
- **Français** : Tout le rapport en français, SQL en anglais
- **Quantitatif** : Privilégier les données chiffrées et tableaux
- **Actionnable** : Recommandations concrètes et priorisées
