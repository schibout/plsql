# Prompts Oracle E-Business Suite

Ce dossier contient des prompts personnalisés pour travailler avec Oracle EBS 12.2.13 via la connexion `oracleProd`.

## 📋 Liste des Prompts

### 1. `/oracle-ebs-query` - Exécution et Analyse de Requêtes

**Utilisation** : Exécuter des requêtes SQL et obtenir une analyse structurée des résultats.

**Cas d'usage** :
- Interroger les utilisateurs et responsabilités
- Extraire des données des modules financiers (AP, GL, PO, XLA, FA)
- Analyser des programmes concurrents
- Valider des données de production

**Exemples** :
```
/oracle-ebs-query Liste des utilisateurs actifs avec responsabilité AP
/oracle-ebs-query [sans argument, utilise la sélection SQL dans l'éditeur]
/oracle-ebs-query Provisions d'octobre 2025 pour société 348
```

**Outils utilisés** : SQLcl MCP server, bases Oracle EBS

---

### 2. `/analyse-incident-oracle` - Diagnostic d'Incidents

**Utilisation** : Investigation méthodique d'un problème de production avec rapport structuré.

**Cas d'usage** :
- Programmes concurrents lents ou bloqués
- Anomalies de données (montants incorrects, liens cassés)
- Écarts comptables ou provisions manquantes
- Erreurs de traitement récurrentes

**Exemples** :
```
/analyse-incident-oracle Programme DKA_SAPFRSDUPLI_MAJ prend 10h au lieu de 18s
/analyse-incident-oracle REQUEST_ID 46850719 en erreur
/analyse-incident-oracle Provisions NOV-25 manquantes pour Ecoliane
```

**Sortie** : Fichier Markdown `Analyse_[Module]_[Problème]_[Date].md` avec diagnostic complet

---

### 3. `/rapport-traitements-oracle` - Rapports de Traitements Batch

**Utilisation** : Génération de rapports d'analyse des traitements périodiques.

**Cas d'usage** :
- Analyse des traitements nocturnes (00h00-06h59)
- Contrôles du soir (19h00-23h59)
- Suivi mensuel des programmes concurrents
- Identification de problèmes de performance

**Exemples** :
```
/rapport-traitements-oracle Traitements nocturnes du 05/03/2026
/rapport-traitements-oracle Batch du soir semaine 10
/rapport-traitements-oracle Analyse mensuelle février 2026
```

**Sortie** : Fichier Markdown `Rapport_Traitements_[Type]_[Période]_Oracle_EBS.md` avec statistiques détaillées

---

## 🚀 Comment Utiliser

### Méthode 1 : Via le Chat

1. Ouvrez le chat Copilot (Ctrl+I ou Cmd+I)
2. Tapez `/` pour voir la liste des prompts disponibles
3. Sélectionnez le prompt désiré
4. Ajoutez votre argument (ou laissez vide pour utiliser la sélection)
5. Appuyez sur Entrée

### Méthode 2 : Via la Sélection de Code

1. Ouvrez un fichier `.sql`
2. Sélectionnez une requête SQL
3. Ouvrez le chat Copilot
4. Tapez `/oracle-ebs-query` (sans argument)
5. Le prompt utilisera automatiquement votre sélection

### Méthode 3 : Via la Palette de Commandes

1. Ctrl+Shift+P (ou Cmd+Shift+P)
2. Cherchez "Chat: Run Prompt..."
3. Sélectionnez le prompt désiré
4. Entrez votre argument dans le chat

---

## 🔧 Configuration Requise

### Connexion Database

Les prompts nécessitent :
- **MCP Server** : SQLcl configuré
- **Connexion** : `oracleProd` (Oracle EBS 12.2.13 Production)
- **Permissions** : Lecture sur les tables FND, AP, GL, PO, XLA, FA

### Vérification de la Connexion

Pour tester la connexion :
```sql
SELECT USER, SYSDATE FROM DUAL;
```

---

## 📚 Documentation de Référence

### Architecture Oracle EBS

Consultez [copilot-instructions.md](../../.github/copilot-instructions.md) pour :
- Flux de données Sub-Ledger → General Ledger
- Changement architectural NOV-25 (XLA APPLIED_TO_DIST_ID_NUM_1)
- Conventions de nommage des périodes
- Patterns de requêtes courants

### Incidents Passés

Exemples d'analyses dans le workspace :
- `Rapport_detaille_incident_maj_sites_fournisseurs.md` : Performance PL/SQL
- `DTR-BO/CONCLUSION_Analyse_provisions_NOV25.md` : Problèmes de provisions
- `Rapport_Traitements_Nuit_Oracle_EBS.md` : Baseline des traitements nocturnes
- `controleNuit.md` : Analyse des contrôles du soir

### Requêtes SQL de Référence

Dossiers avec exemples :
- `DTR-BO/` : Provisions et receipt accruals
- `MiseaJourFournisseurs/` : Gestion fournisseurs
- `cloture2026/` : Clôtures comptables
- `Ajout_de_responsabilite/` : Gestion des utilisateurs

---

## 🎯 Workflows Recommandés

### Workflow 1 : Analyse d'Incident

1. **Détection** : Utilisateur signale un problème
2. **Investigation** : `/analyse-incident-oracle [description du problème]`
3. **Validation** : Le prompt génère un rapport complet
4. **Correction** : Appliquer les recommandations
5. **Vérification** : `/oracle-ebs-query [requête de validation]`

### Workflow 2 : Développement de Requête

1. **Draft** : Écrire une requête SQL brouillon dans un fichier `.sql`
2. **Test** : Sélectionner la requête et lancer `/oracle-ebs-query`
3. **Analyse** : Examiner les résultats et l'analyse
4. **Raffinement** : Corriger la requête selon les retours
5. **Documentation** : Ajouter les commentaires standards

### Workflow 3 : Rapport Mensuel

1. **Extraction** : `/rapport-traitements-oracle Traitements nocturnes [mois]`
2. **Revue** : Examiner le rapport généré
3. **Comparaison** : Comparer avec le mois précédent
4. **Escalade** : Identifier les anomalies pour investigation
5. **Archivage** : Sauvegarder le rapport pour référence

---

## ⚙️ Personnalisation

### Modifier un Prompt

Les fichiers `.prompt.md` peuvent être édités :
- **Frontmatter YAML** : Configuration (description, outils, agent)
- **Corps Markdown** : Instructions pour l'agent

### Ajouter un Nouveau Prompt

1. Créer un fichier `[nom].prompt.md` dans ce dossier
2. Ajouter le frontmatter YAML avec `description`
3. Écrire les instructions en Markdown
4. Tester via `/` dans le chat

### Base de Connaissances

Les prompts référencent automatiquement :
- `copilot-instructions.md` : Contexte Oracle EBS global
- Fichiers du workspace : Exemples et patterns
- Mémoire utilisateur : Préférences (si configurée)

---

## 🐛 Dépannage

### Prompt Non Visible dans la Liste

**Cause** : Frontmatter YAML invalide ou `description` manquante  
**Solution** : Vérifier la syntaxe YAML et ajouter une `description`

### Erreur de Connexion oracleProd

**Cause** : MCP SQLcl non configuré ou connexion inactive  
**Solution** : 
1. Vérifier la configuration MCP dans VS Code
2. Tester la connexion manuellement
3. Redémarrer VS Code si nécessaire

### Résultats Partiels ou Tronqués

**Cause** : Requête retourne trop de données (>60KB)  
**Solution** : 
1. Ajouter `ROWNUM <= 1000` à la requête
2. Filtrer par période/société
3. Utiliser des agrégations (COUNT, SUM, GROUP BY)

### Prompt N'utilise Pas la Sélection

**Cause** : Argument fourni explicitement  
**Solution** : Lancer `/oracle-ebs-query` sans argument pour utiliser la sélection

---

## 📞 Support

Pour les questions ou améliorations :
1. Consulter [copilot-instructions.md](../../.github/copilot-instructions.md)
2. Examiner les rapports d'analyse existants dans le workspace
3. Modifier les prompts selon vos besoins spécifiques

---

**Version** : 1.0  
**Date** : Mars 2026  
**Environnement** : Oracle EBS 12.2.13 Production (19.25.0.0.0)
