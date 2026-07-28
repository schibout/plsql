# Analyse Erreur ORA-01403 - Application Règlement AR

**Date** : 13/01/2026  
**Incident** : Règlement non créé pour SDC RESIDENCE LE FONTENAY  
**Erreur** : ORA-01403: aucune donnée trouvée dans AR_RECEIPT_API_PUB.Apply

---

## 1. Contexte de l'Erreur

### Données du Règlement Échoué

| Élément | Valeur |
|---------|--------|
| **Numéro règlement traité** | VT SYND LE FONTENAY 30/12 |
| **UO du règlement** | DEW0001 |
| **Numéro règlement créé** | PC017401 (non créé) |
| **Client** | SDC RESIDENCE LE FONTENAY |
| **Montant** | 7 716,29 € |
| **Mode de règlement** | 0605_DSW_PC_DEW0001_452000 |

### Trace d'Erreur Complète

```
ORA-01403: aucune donnée trouvée
ORA-06512: à "APPS.AR_RECEIPT_LIB_PVT", ligne 3633
ORA-06512: à "APPS.AR_RECEIPT_LIB_PVT", ligne 3500
ORA-06512: à "APPS.AR_RECEIPT_LIB_PVT", ligne 5294
```

---

## 2. Analyse du Code Source

### Pile d'Appels (de bas en haut)

```
AR_RECEIPT_API_PUB.Apply
    └── AR_RECEIPT_LIB_PVT.Default_application_info (ligne 5294)
        └── AR_RECEIPT_LIB_PVT.Default_disc_and_amt_applied
            └── SELECT INTO (ligne 3500) ← ❌ NO_DATA_FOUND
                └── EXCEPTION RAISE (ligne 3633)
```

### Code Source Incriminé (Ligne 3500-3509)

```sql
-- AR_RECEIPT_LIB_PVT.Default_disc_and_amt_applied
-- Bug fix 3450317 : See if discounts are allowed for this customer
SELECT NVL(NVL(site.discount_terms, cust.discount_terms),'Y')
INTO   l_allow_discount
FROM   hz_customer_profiles  cust
     , hz_customer_profiles  site
WHERE  cust.cust_account_id = p_customer_id      -- ⚠️ Client passé en paramètre
AND    cust.site_use_id     IS NULL              -- ⚠️ Profil au niveau COMPTE
AND    site.cust_account_id (+) = cust.cust_account_id
AND    site.site_use_id (+)     = p_bill_to_site_use_id;
```

### Condition d'Échec

Cette requête échoue (**NO_DATA_FOUND**) lorsque :
1. `p_customer_id` est NULL ou invalide, **OU**
2. Le client n'a **pas de profil au niveau compte** (hz_customer_profiles.site_use_id IS NULL)

---

## 3. Cause Racine Identifiée

### Vérification du Client

| Vérification | Résultat |
|--------------|----------|
| Client existe dans HZ_CUST_ACCOUNTS | ✅ CUST_ACCOUNT_ID = 3055203 |
| Client a un profil compte | ✅ PROFILE_CLASS_ID = 1041 (PRIVE) |
| Client a des sites BILL_TO | ✅ 64 sites dans diverses UO **DSW** |

### Le Problème

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  ⚠️ INCOHÉRENCE DÉTECTÉE                                                        │
│                                                                                 │
│  Le règlement est créé dans l'UO : DEW0001 (org_id = 86)                       │
│  Le client n'a AUCUN site BILL_TO dans DEW0001                                 │
│  Le client a des sites uniquement dans des UO DSW                              │
│                                                                                 │
│  → Le customer_id passé à AR_RECEIPT_API_PUB.Apply est probablement           │
│    NULL ou incohérent avec l'OU du règlement                                   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Preuves

**Sites BILL_TO du client** (extrait) :
| Site Use ID | Org ID | Operating Unit |
|-------------|--------|----------------|
| 13753344 | 91 | DSW0001 |
| 13753410 | 357 | **DSW0605** |
| ... | ... | autres DSW |

**Aucun site dans DEW0001 (org_id = 86)** !

**Factures du client** :
| Org ID | Operating Unit | Nb Factures |
|--------|----------------|-------------|
| 357 | **DSW0605** | 6 |

Le client a une facture ouverte **0605S26010034** de **7 192,15 €** dans **DSW0605**.

---

## 4. Mode de Règlement - Analyse

Le mode de règlement `0605_DSW_PC_DEW0001_452000` suggère :
- `0605` : Référence à DSW0605
- `DSW` : Type Dalkia Services & Works
- `PC` : Prélèvement Client ?
- `DEW0001` : ⚠️ **UO de destination du règlement**
- `452000` : Compte comptable

**Il y a une incohérence entre l'UO source (DSW0605) et l'UO cible (DEW0001).**

---

## 5. Cause Technique Détaillée

Lors de l'appel à `AR_RECEIPT_API_PUB.Apply`, le flux est le suivant :

1. **Création du règlement** dans DEW0001 → OK (règlement PC017401 partiellement créé)

2. **Application du règlement** sur la facture client :
   - Le système cherche le `customer_id` associé au règlement
   - Le `bill_to_site_use_id` est récupéré depuis la facture/client
   - Appel à `Default_disc_and_amt_applied` avec ces paramètres

3. **Échec** dans la requête ligne 3500 :
   - Si le `customer_id` passé est celui du client SDC RESIDENCE LE FONTENAY (3055203)
   - Mais le contexte de l'OU est DEW0001
   - Le système ne trouve pas de correspondance valide

**Hypothèse principale** : Le `p_customer_id` passé est NULL car le client n'existe pas dans l'OU DEW0001 du règlement.

---

## 6. Solutions

### Solution A : Correction du Flux Source (RECOMMANDÉE)

Le règlement doit être créé dans la **même OU que la facture cliente**.

| Actuel (Erreur) | Corrigé |
|-----------------|---------|
| Règlement dans DEW0001 | Règlement dans **DSW0605** |
| Facture dans DSW0605 | Facture dans DSW0605 |

**Action** : Modifier le paramétrage du mode de règlement ou du flux d'encaissement pour cibler l'UO correcte.

### Solution B : Création du Site Client dans DEW0001

Si le client doit avoir des transactions dans DEW0001 :
1. Créer un site BILL_TO pour ce client dans l'OU DEW0001
2. Créer le profil client associé à ce site

```sql
-- Vérifier l'absence de site
SELECT * FROM hz_cust_site_uses_all 
WHERE cust_acct_site_id IN (
    SELECT cust_acct_site_id FROM hz_cust_acct_sites_all 
    WHERE cust_account_id = 3055203
)
AND org_id = 86;  -- DEW0001
-- Résultat : aucune ligne
```

### Solution C : Validation dans le Package DKA

Ajouter une validation avant l'appel à `AR_RECEIPT_API_PUB.Apply` :

```sql
-- Vérifier que le client a un site BILL_TO dans l'OU du règlement
SELECT COUNT(*) INTO l_site_count
FROM hz_cust_site_uses_all hcsu
JOIN hz_cust_acct_sites_all hcas ON hcas.cust_acct_site_id = hcsu.cust_acct_site_id
WHERE hcas.cust_account_id = p_customer_id
AND hcsu.site_use_code = 'BILL_TO'
AND hcsu.org_id = p_org_id
AND hcsu.status = 'A';

IF l_site_count = 0 THEN
   -- Erreur : Client sans site BILL_TO dans cette OU
   RAISE_APPLICATION_ERROR(-20001, 
       'Client ' || p_customer_id || ' n''a pas de site BILL_TO dans l''OU ' || p_org_id);
END IF;
```

---

## 7. Actions Immédiates

### Pour ce Règlement Spécifique

1. **Annuler** la tentative de règlement dans DEW0001
2. **Recréer** le règlement dans l'OU **DSW0605** (où se trouve la facture)
3. **Appliquer** le règlement sur la facture **0605S26010034**

### Requête de Vérification

```sql
-- Trouver la facture à régler
SELECT customer_trx_id, trx_number, org_id,
       (SELECT name FROM hr_operating_units WHERE organization_id = org_id) as ou_name,
       (SELECT SUM(amount_due_remaining) 
        FROM ar_payment_schedules_all 
        WHERE customer_trx_id = rcta.customer_trx_id) as solde_restant
FROM ra_customer_trx_all rcta
WHERE bill_to_customer_id = 3055203
AND EXISTS (
    SELECT 1 FROM ar_payment_schedules_all ps
    WHERE ps.customer_trx_id = rcta.customer_trx_id
    AND ps.amount_due_remaining > 0
);
```

---

## 8. Résumé

| Élément | Détail |
|---------|--------|
| **Erreur** | ORA-01403 dans AR_RECEIPT_LIB_PVT.Default_disc_and_amt_applied |
| **Cause** | Incohérence OU : règlement dans DEW0001, client/facture dans DSW0605 |
| **Impact** | Règlement PC017401 non créé |
| **Solution** | Créer le règlement dans l'OU de la facture (DSW0605) |
| **Responsable** | Équipe fonctionnelle AR / Paramétrage des flux |

---

## 9. Annexes

### A. Données Client

```
CUST_ACCOUNT_ID  : 3055203
ACCOUNT_NUMBER   : 01465564
PARTY_NAME       : SDC RESIDENCE LE FONTENAY
PROFILE_CLASS    : PRIVE (1041)
Sites BILL_TO    : 64 (uniquement dans UO DSW)
```

### B. Facture en Attente

```
TRX_NUMBER       : 0605S26010034
CUSTOMER_TRX_ID  : 12184923
ORG_ID           : 357 (DSW0605)
AMOUNT_REMAINING : 7 192,15 €
```

### C. Références Code Source

- [AR_RECEIPT_LIB_PVT](AR_RECEIPT_LIB_PVT) - Package Oracle Standard
  - Ligne 3500-3509 : Requête de vérification discount_terms
  - Ligne 3633 : RAISE dans bloc EXCEPTION
  - Ligne 5294 : Appel à Default_disc_and_amt_applied
