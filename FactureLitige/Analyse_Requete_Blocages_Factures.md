# Analyse de la Requête : Blocages de Factures (Litiges)

**Date de l'analyse** : 09/03/2026  
**Fichier analysé** : `original_query.sql`  
**Objectif** : Extraction des données de blocages de factures pour l'année en cours

---

## 1. SYNTHÈSE

Cette requête extrait les informations détaillées sur les **blocages de factures en litige** dans Oracle EBS, en intégrant des données provenant de trois sources principales :
- **Blocages AP** (`ap_holds_all`)
- **Historique d'approbation** (`ap_inv_aprvl_hist_all`)
- **Interface iValua** (`dka_iapfac_debloc_repor_interf`)

La requête identifie qui a mis une facture en litige, quand, pourquoi, et si elle a été débloquée.

---

## 2. STRUCTURE DE LA REQUÊTE

### 2.1 Tables Principales

| Alias | Table | Rôle |
|-------|-------|------|
| `aha` | `apps.ap_holds_all` | Table principale des blocages de factures |
| `a` | `ap_inv_aprvl_hist_all` | Historique d'approbation (workflow sans iValua) |
| `c` | `dka_iapfac_debloc_repor_interf` | Interface iValua pour les litiges traités via iValua |

### 2.2 Données Extraites (17 colonnes)

1. **Identification** : `invoice_id`, `hold_id`, `line_location_id`
2. **Blocage** : `code_blocage`, `raison_blocage`, `bloquee_par`, `date_blocage`
3. **Déblocage** : `code_deblocage`, `raison_deblocage`, `debloquee_par`, `Débloquée_le`
4. **Workflow** : `id_wkf_facture`, `a_traiter_ivalua`, `type_blocage_en_attente`
5. **Litige** : `Mise_en_litige_par`, `Matricule_Mise_en_litige`, `Mise_en_litige_le`, `Commentaire_litige`, `Poseur_litige`

---

## 3. LOGIQUE MÉTIER

### 3.1 Gestion de Deux Flux de Litiges

La requête gère deux scénarios d'origine de litige :

#### **Scenario A : Litige via Workflow Standard (sans iValua)**
- Condition : `c.hold_id IS NULL`
- Source : `ap_inv_aprvl_hist_all` (table `a`)
- Critère : `a.response = 'DKA_REFUS'`
- Les champs proviennent de la table d'historique d'approbation

#### **Scenario B : Litige via iValua**
- Condition : `c.hold_id IS NOT NULL`
- Source : `dka_iapfac_debloc_repor_interf` (table `c`)
- Critère : `c.response_code = 'DKA_REFUSE_IVALUA'`
- Les champs proviennent de l'interface iValua

### 3.2 Mapping des Types de Blocages

La jointure avec `ap_inv_aprvl_hist_all` utilise un mapping complexe :

```sql
DECODE(substr(a.approver_comments, 1, instr(a.approver_comments, '-')-2), 
       'Ecart de prix', 'En litige Prix', 
       'QTY_REC', 'En litige Quantité REC',
       'QTY_CDE', 'En litige Quantité CDE') = aha.hold_lookup_code
```

**Traduction** :
- Commentaire "Ecart de prix" → Code blocage "En litige Prix"
- Commentaire "QTY_REC" → Code blocage "En litige Quantité REC"
- Commentaire "QTY_CDE" → Code blocage "En litige Quantité CDE"

### 3.3 Filtre WHERE

```sql
EXISTS (SELECT 'X' FROM ap_holds_all aha2 
        WHERE aha2.invoice_id = aha.invoice_id
        AND aha2.hold_lookup_code LIKE 'En litige%')
```

**But** : Ne retenir que les factures ayant **au moins un blocage de type litige** (code commençant par "En litige").

---

## 4. PROBLÈMES IDENTIFIÉS

### 4.1 🔴 CRITIQUE : Problèmes de Performance

#### **Problème 1 : Sous-requêtes scalaires multiples**

La requête contient **5 sous-requêtes scalaires** exécutées pour chaque ligne :

```sql
-- Sous-requête 1 (ligne 8-9)
(SELECT fu.user_name FROM apps.fnd_user fu WHERE fu.user_id = aha.held_by)

-- Sous-requête 2 (ligne 17-18)
(SELECT DISTINCT ppf.employee_number FROM apps.per_people_f ppf WHERE ppf.person_id = aha.attribute6)

-- Sous-requête 3 (ligne 22-23)
(SELECT fu.user_name FROM apps.fnd_user fu WHERE fu.user_id = aha.last_updated_by)

-- Sous-requête 4 (lignes 27-30) - DANS un CASE
(SELECT d.full_name FROM per_people_f d WHERE ...)

-- Sous-requête 5 (lignes 34-36) - DANS un CASE
(SELECT DISTINCT ppf.employee_number FROM per_people_f ppf WHERE ...)
```

**Impact** : Si la requête retourne 10 000 lignes, chaque sous-requête scalaire est exécutée **10 000 fois** → **50 000 exécutions** de sous-requêtes au total.

**Complexité** : Les sous-requêtes 4 et 5 dans les CASE sont particulièrement problématiques car elles incluent :
- Parsing de chaîne avec `SUBSTR` et `INSTR`
- Recherche dans `per_people_f` par email en UPPER
- `ROWNUM = 1` pour gérer les doublons

#### **Problème 2 : EXISTS avec sous-requête corrélée**

```sql
EXISTS (SELECT 'X' FROM ap_holds_all aha2 
        WHERE aha2.invoice_id = aha.invoice_id
        AND aha2.hold_lookup_code LIKE 'En litige%')
```

**Impact** : Cette sous-requête corrélée est exécutée pour chaque ligne de `ap_holds_all`, entraînant un **balayage répété** de la table.

#### **Problème 3 : Parsing de chaînes complexe**

```sql
DECODE(substr(a.approver_comments, 1, instr(a.approver_comments, '-')-2), ...)
```

Le parsing de commentaires avec `SUBSTR` et `INSTR` dans la condition de jointure peut empêcher l'utilisation d'index.

### 4.2 ⚠️ MAJEUR : Problèmes de Logique

#### **Problème 1 : Ambiguïté de la condition dans CASE**

Lignes 28-30 :
```sql
WHERE c.response_code ='DKA_REFUSE_IVALUA' and c.invoice_id = aha.invoice_id
```

**Problème** : Cette condition répète celle déjà présente dans la jointure (ligne 68-69). Si `c` est NULL (litige standard), cette sous-requête retournera NULL car la condition `c.invoice_id = aha.invoice_id` sera toujours fausse.

#### **Problème 2 : DISTINCT sans ORDER BY avec ROWNUM = 1**

Lignes 35-37 et 40-42 :
```sql
(SELECT DISTINCT ppf.employee_number FROM per_people_f ppf 
 WHERE ppf.full_name = a.approver_name AND ROWNUM = 1)
```

**Problème** : `DISTINCT` + `ROWNUM = 1` sans `ORDER BY` donne un résultat **non déterministe** si plusieurs lignes correspondent.

**Cause** : `per_people_f` est une table **date-effective** (peut avoir plusieurs lignes pour la même personne à différentes dates).

#### **Problème 3 : Utilisation de SELECT DISTINCT au niveau principal**

```sql
SELECT DISTINCT ...
```

**Problème** : Le `DISTINCT` masque potentiellement un problème de cardinalité dans les jointures. Si plusieurs lignes identiques apparaissent, cela peut indiquer :
- Une jointure incorrecte générant des cartésiens partiels
- Des données dupliquées dans les tables de référence

### 4.3 ⚠️ MINEUR : Problèmes de Maintenabilité

#### **Problème 1 : Utilisation excessive d'attributes flexfields**

```sql
aha.attribute2, aha.attribute4, aha.attribute5, aha.attribute6, aha.attribute9
```

**Problème** : Les colonnes `attributeN` ne sont pas auto-documentantes. Sans documentation, il est difficile de comprendre leur signification.

**Exemple** :
- `attribute2` = ID workflow facture (OK avec alias)
- `attribute4` = Flag "à traiter iValua" (Y/N)
- `attribute6` = Person ID (?)
- `attribute9` = Poseur litige (?)

#### **Problème 2 : Incohérence de formatage**

- Indentation variable (tabulations vs espaces)
- Casse mixte (`apps.` parfois, pas toujours)
- Alignement des alias non uniforme

---

## 5. RECOMMANDATIONS D'OPTIMISATION

### 5.1 Optimisation Critique : Remplacer les sous-requêtes scalaires par des jointures

**AVANT** (sous-requête scalaire) :
```sql
(SELECT fu.user_name FROM apps.fnd_user fu WHERE fu.user_id = aha.held_by) bloquee_par
```

**APRÈS** (jointure) :
```sql
LEFT JOIN apps.fnd_user fu_held ON fu_held.user_id = aha.held_by
-- Dans le SELECT : fu_held.user_name AS bloquee_par
```

**Gain estimé** : Réduction de 80-90% du temps d'exécution sur gros volumes.

### 5.2 Optimisation Majeure : Remplacer EXISTS par jointure ou filtre direct

**Option A : Ajouter un filtre direct**
```sql
WHERE aha.hold_lookup_code LIKE 'En litige%'
```

**Option B : Si plusieurs blocages par facture, utiliser une CTE**
```sql
WITH factures_en_litige AS (
    SELECT DISTINCT invoice_id 
    FROM ap_holds_all 
    WHERE hold_lookup_code LIKE 'En litige%'
)
...
INNER JOIN factures_en_litige fel ON fel.invoice_id = aha.invoice_id
```

### 5.3 Optimisation : Gérer les dates effectives de per_people_f

**AVANT** :
```sql
SELECT DISTINCT ppf.employee_number FROM per_people_f ppf 
WHERE ppf.person_id = aha.attribute6 AND ROWNUM = 1
```

**APRÈS** :
```sql
SELECT ppf.employee_number FROM per_people_f ppf 
WHERE ppf.person_id = aha.attribute6
  AND SYSDATE BETWEEN ppf.effective_start_date AND ppf.effective_end_date
```

**Alternative** : Si la date du blocage est connue :
```sql
AND aha.hold_date BETWEEN ppf.effective_start_date AND ppf.effective_end_date
```

### 5.4 Optimisation : Simplifier le parsing d'email

Le parsing d'email dans les sous-requêtes (lignes 30 et 42) est complexe :

```sql
UPPER(d.email_address) = SUBSTR(c.commentaire, 
    INSTR(c.commentaire, ':') + 1, 
    INSTR(c.commentaire,'/') - INSTR(c.commentaire, ':') - 1)
```

**Recommandation** : Stocker l'email extrait dans une colonne calculée ou une CTE :

```sql
WITH commentaires_parsed AS (
    SELECT 
        hold_id,
        UPPER(SUBSTR(commentaire, 
            INSTR(commentaire, ':') + 1, 
            INSTR(commentaire, '/') - INSTR(commentaire, ':') - 1)) AS email_extrait
    FROM dka_iapfac_debloc_repor_interf
    WHERE response_code = 'DKA_REFUSE_IVALUA'
)
```

### 5.5 Amélioration : Supprimer DISTINCT et analyser la cardinalité

**Action** :
1. Retirer `SELECT DISTINCT`
2. Exécuter la requête sur un échantillon
3. Identifier les doublons éventuels
4. Corriger les jointures à la source du problème

---

## 6. IMPACT ET ESTIMATION

### 6.1 Scénarios de Volume

| Volume de factures en litige | Temps estimé AVANT | Temps estimé APRÈS |
|------------------------------|-------------------|-------------------|
| 1 000 factures | 5-10 secondes | < 1 seconde |
| 10 000 factures | 30-60 secondes | 2-3 secondes |
| 100 000 factures | 5-10 minutes | 10-15 secondes |

**Hypothèses** :
- Base de données correctement indexée
- Statistiques à jour (ANALYZE)
- Optimisations appliquées (jointures au lieu de sous-requêtes scalaires)

### 6.2 Index Recommandés

```sql
-- Pour ap_holds_all
CREATE INDEX ap_holds_all_n1 ON ap_holds_all (invoice_id, hold_lookup_code);

-- Pour ap_inv_aprvl_hist_all
CREATE INDEX ap_inv_aprvl_hist_n1 ON ap_inv_aprvl_hist_all (invoice_id, response);

-- Pour dka_iapfac_debloc_repor_interf
CREATE INDEX dka_iapfac_debloc_n1 ON dka_iapfac_debloc_repor_interf (invoice_id, response_code);

-- Pour per_people_f (dates effectives)
CREATE INDEX per_people_f_n2 ON per_people_f (person_id, effective_start_date, effective_end_date);
CREATE INDEX per_people_f_n3 ON per_people_f (UPPER(email_address));
```

---

## 7. PLAN D'ACTION RECOMMANDÉ

### Phase 1 : Optimisations Rapides (Impact Immédiat)
1. ✅ Remplacer les 3 premières sous-requêtes scalaires par des LEFT JOIN sur `fnd_user` et `per_people_f`
2. ✅ Ajouter filtres date-effective pour `per_people_f`
3. ✅ Vérifier les index existants et créer ceux manquants

**Gain attendu** : 70-80% de réduction du temps d'exécution

### Phase 2 : Refactoring Logique (Impact Moyen Terme)
4. ✅ Créer des CTE pour parser et préparer les données iValua
5. ✅ Remplacer EXISTS par filtre direct ou jointure
6. ✅ Supprimer DISTINCT et corriger les jointures génératrices de doublons

**Gain attendu** : Architecture plus claire, +10-15% de performance supplémentaire

### Phase 3 : Amélioration Continue
7. ✅ Documenter les attributeN dans un fichier README ou commentaires SQL
8. ✅ Standardiser le formatage et l'indentation
9. ✅ Créer une vue matérialisée si la requête est exécutée fréquemment

---

## 8. CONCLUSION

### Points Forts
✅ Requête fonctionnelle qui couvre les deux flux (workflow standard + iValua)  
✅ Logique métier claire malgré la complexité  
✅ Gestion des états déblocage/blocage complète

### Points d'Attention
🔴 **Performance critique** : Sous-requêtes scalaires multiples  
⚠️ **Logique fragile** : Parsing de chaînes complexe, dépendance aux formats de commentaires  
⚠️ **Maintenabilité** : Code difficile à lire et maintenir sans documentation

### Prochaine Étape
👉 **Créer une version optimisée** de la requête en appliquant les recommandations de la Phase 1 pour validation sur environnement de test.

---

**Analyste** : GitHub Copilot  
**Référence** : Documentation Oracle EBS 12.2.13 - Module AP (Accounts Payable)
