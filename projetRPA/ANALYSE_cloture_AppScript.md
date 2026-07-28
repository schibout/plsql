# Analyse du Script Google Apps Script - cloture.gs

## 📋 Vue d'ensemble

Ce script Google Apps Script automatise le remplacement de période comptable en effectuant une recherche et remplacement sur des fichiers SQL stockés dans Google Drive.

---

## 🔧 Détail du Code

### **Fonction : `UpdateCloture()`**

```javascript
function UpdateCloture() {
```
- Fonction principale qui ne prend pas de paramètres
- Sera exécutée via Google Sheets/Drive (déclenchement manuel ou automatisé)

---

### **Étape 1 : Recherche des fichiers SQL**

```javascript
var files = DriveApp.searchFiles('parents in "1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl" and mimeType contains "SQL"');
```

**Analyse :**
- **`DriveApp.searchFiles()`** : Recherche les fichiers dans Google Drive
- **`parents in "1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl"`** : Cible un dossier spécifique (ID : `1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl`)
- **`mimeType contains "SQL"`** : Filtre uniquement les fichiers contenant "SQL" dans le type MIME
- **Résultat** : Iterator de fichiers correspondant aux critères

---

### **Étape 2 : Itération sur les fichiers**

```javascript
while (files.hasNext()) {
  var file = files.next();
```
- Boucle sur chaque fichier trouvé
- **`files.next()`** : Récupère le fichier suivant

---

### **Étape 3 : Récupération du contenu**

```javascript
  var file_blob = file.getBlob();
  var text = file_blob.getDataAsString();
```

**Analyse :**
- **`getBlob()`** : Récupère le fichier sous forme d'objet binaire (Blob)
- **`getDataAsString()`** : Convertit le contenu en chaîne de caractères texte
- **Résultat** : `text` contient le code SQL complet du fichier

---

### **Étape 4 : Affichage et Remplacement**

```javascript
  console.log(file.getName());
  text = text.split('DEC-25').join('JAN-26')
```

**Analyse :**
- **`console.log(file.getName())`** : Affiche le nom du fichier dans la console
- **`split('DEC-25').join('JAN-26')`** : 
  - Découpe la chaîne par `'DEC-25'` (période décembre 2025)
  - Rejoint les parties avec `'JAN-26'` (période janvier 2026)
  - Effectue un remplacement global de toutes les occurrences

---

## ⚠️ Problèmes Identifiés

### **1. Fichier modifié mais pas sauvegardé**
- Le contenu est modifié dans la variable `text`
- **Aucune instruction pour sauvegarder** le fichier modifié
- **Action requise** : Ajouter `.setContent()` ou créer un nouveau fichier

### **2. Variable inutilisée**
```javascript
var file_to_create  // Déclarée mais jamais utilisée
```
- Ligne à supprimer ou à implémenter pour créer un fichier d'output

### **3. Aucune gestion d'erreur**
- Pas de try/catch
- Pas de vérification si le dossier existe
- Risque de crash silencieux

---

## 🎯 Objectif du Script

**Mise à jour automatique de clôture comptable** :
- Cherche tous les fichiers SQL dans un dossier Drive
- Remplace les références de période de `DEC-25` → `JAN-26`
- Prépare les requêtes SQL pour le mois suivant

---

## 📊 Flux d'Exécution

```
1. Rechercher fichiers SQL dans Drive
   ↓
2. Pour chaque fichier trouvé:
   ├─ Récupérer le contenu
   ├─ Remplacer DEC-25 par JAN-26
   ├─ Afficher le nom (logs)
   └─ [MANQUANT] Sauvegarder les modifications
```

---

## 💡 Recommandations d'Amélioration

### **Version Corrigée Proposée**

```javascript
function UpdateCloture() {
  try {
    var files = DriveApp.searchFiles('parents in "1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl" and mimeType contains "SQL"');
    var updated_count = 0;
    
    while (files.hasNext()) {
      var file = files.next();
      var file_blob = file.getBlob();
      var text = file_blob.getDataAsString();
      
      // Vérifier si la période existe
      if (text.includes('DEC-25')) {
        var updated_text = text.split('DEC-25').join('JAN-26');
        
        // Sauvegarder le fichier modifié
        file.setContent(updated_text);
        
        Logger.log('✓ Mis à jour : ' + file.getName());
        updated_count++;
      } else {
        Logger.log('⚠ Aucune référence DEC-25 : ' + file.getName());
      }
    }
    
    Logger.log('Résumé: ' + updated_count + ' fichier(s) mis à jour');
    
  } catch (error) {
    Logger.log('ERREUR : ' + error.toString());
  }
}
```

### **Modifications**
✅ Ajout de `setContent()` pour sauvegarder  
✅ Vérification `includes()` avant remplacement  
✅ Gestion d'erreur avec try/catch  
✅ Comptage et résumé des fichiers traités  
✅ Messages détaillés en console

---

## 📌 Utilisation

**Pour exécuter ce script :**
1. Ouvrir Google Sheets/Drive
2. Accéder aux Apps Script (Extensions → Apps Script)
3. Coller le code
4. Lancer la fonction `UpdateCloture()`
5. Vérifier les logs (Affichage → Logs)

---

## 🔐 Sécurité

- ⚠️ L'ID du dossier est en dur dans le code → à paramétrer
- ⚠️ Aucune vérification de validation
- ✅ Les fichiers ne sont que lus/modifiés dans Drive (pas de suppression)

---

## 📝 Résumé

| Aspect | Description |
|--------|-------------|
| **Objectif** | Mettre à jour les périodes comptables dans les fichiers SQL |
| **Entrée** | Fichiers SQL dans Google Drive |
| **Traitement** | Remplacement `DEC-25` → `JAN-26` |
| **Sortie** | Fichiers SQL modifiés dans Drive |
| **Fréquence** | Exécution manuelle ou déclenchée |
| **État** | 🔴 Incomplet - pas de sauvegarde implémentée |

