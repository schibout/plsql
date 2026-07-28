# Analyse de l'Erreur - Traitement KO de l'image Tradeshift

**Date** : 09/03/2026  
**Incident** : Le traitement de rattachement des images de factures échoue en ETI1.  
**Exemple** : `Traitement KO de l'image L56VFRTDSPAR356970520260415-091802-809.TIF de la facture N° 861024`  
**Package concerné** : `dka_iapfacxgs_pkg`

---

## 1. Résumé Exécutif

L'erreur provient d'une **modification récente du package `dka_iapfacxgs_pkg` en ETI1**. Une nouvelle logique a été introduite pour identifier dynamiquement la source des factures (`Xerox`, `Ivalua`, `Demat`) en se basant sur le préfixe du nom de fichier.

**Le flux Tradeshift (préfixe `L56`) a été oublié dans cette nouvelle logique**, ce qui cause une mauvaise classification de la facture et un rejet de l'image lors du traitement de rattachement.

---

## 2. Analyse de la Cause Racine

### Comparaison PROD vs ETI1

- **Version PROD** : Le package est moins strict. Il ne se base pas sur le nom du fichier image pour déterminer la source. Il traite la plupart des flux comme du `SCAN_XGS` (Xerox) par défaut. Cela fonctionnait "par chance" pour les images Tradeshift.

- **Version ETI1** : Le package a été modifié pour supporter de nouveaux flux de dématérialisation (`OCR`, `DMT`). Pour cela, **trois nouvelles fonctions** ont été ajoutées pour analyser le nom du fichier (`NOM_FICHIER`) :
  - `get_prefix_from_filename`
  - `get_source_from_filename`
  - `get_folio_from_filename`

### Le Point de Rupture : La Logique de Parsing en ETI1

La nouvelle logique en ETI1 présente deux défauts majeurs qui provoquent l'erreur avec les fichiers Tradeshift.

#### A. L'expression régulière (Regex) est inadaptée

La fonction `get_prefix_from_filename` utilise la regex suivante pour extraire le préfixe :
```sql
vv_prefix := REGEXP_SUBSTR(upper(trim(pv_nom_fichier)), '^[^_\.]+');
```
Cette regex signifie : "Prendre tous les caractères depuis le début jusqu'au premier `_` ou `.`".

- Pour un fichier Xerox `VE1_DAL...TIF`, elle extrait correctement **`VE1`**.
- Pour le fichier Tradeshift `L56VFRTDSPAR...809.TIF`, **il n'y a pas de `_`**. La regex capture donc toute la chaîne jusqu'au point : **`L56VFRTDSPAR...809`**.

Le préfixe extrait est donc incorrect et beaucoup trop long.

#### B. Le préfixe `L56` est inconnu

Même si le préfixe était correctement extrait en `L56`, la fonction `get_source_from_filename` ne le connaît pas :

```sql
CASE vv_prefix
  WHEN 'VE1' THEN RETURN 'SCAN_XGS';
  WHEN 'DSP' THEN RETURN 'SCAN_XGS';
  WHEN 'ZCI' THEN RETURN 'SCAN_XGS';
  WHEN 'OCR' THEN RETURN 'DEMAT';
  WHEN 'DMT' THEN RETURN 'DEMAT';
  ELSE RETURN 'SCAN_XGS'; -- Le L56... tombe ici
END CASE;
```
Le flux Tradeshift est donc incorrectement classifié comme `SCAN_XGS`.

### Conséquence

1.  Lors de l'intégration, la facture est insérée dans les tables d'interface avec la source `SCAN_XGS` et le folio `XGS`.
2.  Le programme de rattachement d'images, qui est devenu plus strict en ETI1, prend le relais.
3.  Il voit une facture qui se prétend être "Xerox" mais constate que le fichier image associé est `L56...TIF` et non `VE1...TIF`.
4.  **Cette incohérence provoque le rejet de l'image et l'erreur "Traitement KO"**.

---

## 3. Solution Recommandée

Il est impératif de corriger le package `dka_iapfacxgs_pkg` en ETI1 pour qu'il reconnaisse et gère correctement le flux Tradeshift.

### Action de Correction

Modifier les fonctions `get_source_from_filename` et `get_folio_from_filename` pour :
1.  Forcer la lecture sur les 3 premiers caractères du préfixe.
2.  Ajouter le cas `L56`.

**Exemple de correction pour `get_source_from_filename` :**
```sql
FUNCTION get_source_from_filename(pv_nom_fichier IN VARCHAR2)
  RETURN ap_invoices_interface.source%TYPE IS
  vv_prefix VARCHAR2(30);
BEGIN
  vv_prefix := get_prefix_from_filename(pv_nom_fichier);

  -- CORRECTION : Forcer la lecture sur 3 caractères et ajouter le cas L56
  CASE substr(vv_prefix, 1, 3) 
    WHEN 'VE1' THEN RETURN 'SCAN_XGS';
    WHEN 'DSP' THEN RETURN 'SCAN_XGS';
    WHEN 'ZCI' THEN RETURN 'SCAN_XGS';
    WHEN 'L56' THEN RETURN 'SCAN_XGS'; -- <-- AJOUTER CETTE LIGNE
    WHEN 'OCR' THEN RETURN 'DEMAT';
    WHEN 'DMT' THEN RETURN 'DEMAT';
    ELSE RETURN 'SCAN_XGS';
  END CASE;
END get_source_from_filename;
```
La même logique doit être appliquée à la fonction `get_folio_from_filename` pour retourner le folio `XGS` (ou un folio dédié si nécessaire).

### Contournement Temporaire (pour test)

Pour valider ce diagnostic en ETI1 sans modifier le code, il suffit de renommer le fichier image :
- **Nom original** : `L56VFRTDSPAR356970520260415-091802-809.TIF`
- **Nom pour test** : `VE1_DAL_L56VFRTDSPAR356970520260415-091802-809.TIF`

Avec ce renommage, le traitement de rattachement devrait fonctionner, confirmant que le problème vient bien du parsing du nom de fichier.

---

## 4. Proposition de mise à jour JIRA

**Titre** : [ETI1] Rejet rattachement images Tradeshift (L56) suite à l'évolution Demat

**Description** :
**Symptôme** : Rejet systématique des images Tradeshift (`L56*.TIF`) lors du traitement de rattachement en environnement ETI1 (identifié lors des tests Pacha). Le flux fonctionne correctement en PROD.

**Cause Racine** : L'évolution récente du package `dka_iapfacxgs_pkg` livrée en ETI1 (ajout des flux OCR/DMT) a introduit une identification stricte basée sur le nom de fichier via `get_prefix_from_filename`. Le préfixe Tradeshift (`L56`) a été omis du routage. La facture est classifiée par erreur en flux Xerox (`SCAN_XGS`), ce qui provoque un rejet lors de l'étape de rattachement car l'image `L56...` ne correspond pas au modèle attendu pour Xerox. De plus, la Regex d'extraction du préfixe dysfonctionne sur le format Tradeshift (absence d'underscore `_`).

**Solution Technique à implémenter (Dev)** :
Dans le body du package `dka_iapfacxgs_pkg` :
1. Modifier les fonctions `get_source_from_filename` et `get_folio_from_filename` pour sécuriser l'évaluation du préfixe sur ses 3 premiers caractères : `CASE substr(vv_prefix, 1, 3)` au lieu de `CASE vv_prefix`.
2. Ajouter la gestion explicite du Tradeshift dans le `CASE` :
   `WHEN 'L56' THEN RETURN 'SCAN_XGS';`

**Contournement temporaire QA** : 
Pour poursuivre les tests d'intégration dans `image_in` en attendant la livraison de la correction, renommer temporairement le fichier en ajoutant un préfixe factice Xerox : 
*Exemple : Renommer `L56VFRT...TIF` en `VE1_DAL_L56VFRT...TIF`.*