# Proposition de Correctif - Rattachement Images Tradeshift (L56)

**Date** : 09/03/2026  
**Package** : `dka_iapfacxgs_pkg` (Body)  
**Environnement** : ETI1

---

## 1. Contexte

L'analyse de l'incident "Traitement KO de l'image Tradeshift" a révélé que la nouvelle logique de parsing des noms de fichiers dans `dka_iapfacxgs_pkg` est la cause du rejet des images `L56*.TIF`.

Ce document propose un correctif en deux étapes pour fiabiliser le traitement.

---

## 2. Solution Technique (Améliorée)

La solution consiste à modifier trois fonctions du package pour assurer une identification correcte et pérenne des flux.

### Étape 1 : Fiabiliser l'extraction du préfixe

La fonction `get_prefix_from_filename` utilise une expression régulière inadaptée. Il est plus simple et robuste de la remplacer par une extraction des 3 premiers caractères, puisque tous les préfixes connus (`VE1`, `DSP`, `ZCI`, `OCR`, `DMT`, et le `L56` manquant) ont cette longueur.

**Modification dans `get_prefix_from_filename` :**
```sql
FUNCTION get_prefix_from_filename(pv_nom_fichier IN VARCHAR2)
  RETURN VARCHAR2 IS
BEGIN
  -- AVANT :
  -- RETURN REGEXP_SUBSTR(upper(trim(pv_nom_fichier)), '^[^_\.]+');

  -- APRÈS (plus robuste) :
  RETURN SUBSTR(UPPER(TRIM(pv_nom_fichier)), 1, 3);
END get_prefix_from_filename;
```

### Étape 2 : Intégrer le flux Tradeshift (L56)

Maintenant que le préfixe est correctement extrait, il faut l'ajouter à la logique de routage dans les fonctions `get_source_from_filename` et `get_folio_from_filename`.

**Modification dans `get_source_from_filename` :**
```sql
-- Le CASE peut maintenant s'appuyer sur un préfixe fiable de 3 caractères.
CASE vv_prefix
  WHEN 'VE1' THEN RETURN 'SCAN_XGS';
  WHEN 'DSP' THEN RETURN 'SCAN_XGS';
  WHEN 'ZCI' THEN RETURN 'SCAN_XGS';
  WHEN 'L56' THEN RETURN 'SCAN_XGS'; -- <-- AJOUT
  WHEN 'OCR' THEN RETURN 'DEMAT';
  WHEN 'DMT' THEN RETURN 'DEMAT';
  ELSE RETURN 'SCAN_XGS';
END CASE;
```

**Modification dans `get_folio_from_filename` :**
```sql
CASE vv_prefix
  WHEN 'VE1' THEN RETURN 'XGS';
  WHEN 'DSP' THEN RETURN 'DSP';
  WHEN 'ZCI' THEN RETURN 'XGS';
  WHEN 'L56' THEN RETURN 'XGS'; -- <-- AJOUT (folio XGS comme pour VE1/ZCI)
  WHEN 'OCR' THEN RETURN 'OCR';
  WHEN 'DMT' THEN RETURN 'DMT';
  ELSE RETURN 'XGS';
END CASE;
```

---

## 3. Avantages de cette approche

- **Robustesse** : La correction à la source dans `get_prefix_from_filename` évite les contournements et rend le code plus lisible et maintenable.
- **Pérennité** : Le code est désormais prêt à intégrer d'autres flux futurs basés sur un préfixe de 3 caractères sans nécessiter de nouvelle adaptation de la logique d'extraction.