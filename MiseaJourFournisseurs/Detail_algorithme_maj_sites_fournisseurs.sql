-- ============================================================================
-- DÉTAIL COMPLET DU TRAITEMENT
-- Programme : DKA : Mise à jour quotidienne des sites fournisseurs dupliqués
-- Package : DKA_SAPFRSDUPLI_MAJ_PKG.MAIN
-- ============================================================================

/*
OBJECTIF DU TRAITEMENT :
-----------------------
Synchroniser les sites fournisseurs dupliqués sur toutes les entités (UO) 
avec les informations de la référence centrale REF9999.

PRINCIPE :
----------
1. La référence REF9999 contient les données "maîtres" des fournisseurs
2. Chaque entité (0458, 0483, 0329, etc.) a des sites fournisseurs "dupliqués"
3. Le traitement met à jour automatiquement les sites dupliqués avec les 
   données de la référence quand celle-ci est modifiée

EXEMPLE :
---------
Fournisseur : VEOLIA
- Site REF9999 : VEOLIA_PARIS (référence, coordonnées bancaires IBAN: FR76...)
- Site 0458.DCW : VEOLIA_PARIS (dupliqué, doit avoir le même IBAN)
- Site 0483.DEW : VEOLIA_PARIS (dupliqué, doit avoir le même IBAN)

Si l'IBAN change dans REF9999 → Mise à jour automatique dans 0458 et 0483
*/

-- ============================================================================
-- ALGORITHME DÉTAILLÉ
-- ============================================================================

/*
┌─────────────────────────────────────────────────────────────────┐
│                    ÉTAPE 1 : INITIALISATION                      │
└─────────────────────────────────────────────────────────────────┘

1.1 Récupération de la DATE DE DERNIÈRE MAJ depuis DKA_PARAMETERS
    → Cette date sert de point de repère pour identifier les modifications
    
1.2 Initialisation de l'environnement Oracle EBS
    → Responsabilité : TOUT_AP_ADMINISTRATEUR
    → Permet d'exécuter les API Oracle en mode administrateur
    
1.3 Affichage de l'entête dans le fichier .OUT
*/

BEGIN
  -- Variables globales
  v_date_maj := récupération depuis DKA_PARAMETERS;
  v_resp_id := récupération responsabilité AP;
  APPS.FND_GLOBAL.APPS_INITIALIZE(...);
  entete_de_sortie();  -- Affiche le compte-rendu
END;

/*
┌─────────────────────────────────────────────────────────────────┐
│              ÉTAPE 2 : IDENTIFICATION DES SITES À TRAITER        │
└─────────────────────────────────────────────────────────────────┘

Le curseur SITE_A_MAJ sélectionne TOUS les sites fournisseurs de REF9999
qui ont été modifiés depuis la dernière exécution.

TABLES INTERROGÉES :
*/

-- 2.1 Structure du curseur SITE_A_MAJ
CURSOR SITE_A_MAJ (p_date_maj DATE) IS
  SELECT DISTINCT 
         assa.vendor_site_id,        -- ID du site dans REF9999
         assa.vendor_site_code,      -- Code du site (ex: VEOLIA_PARIS)
         ass.vendor_name             -- Nom du fournisseur (ex: VEOLIA)
  FROM   ap_supplier_sites_all assa      -- Sites fournisseurs
  ,      ap_suppliers ass                -- Fournisseurs
  ,      hr_operating_units hou          -- Unités opérationnelles
  ,      iby_ext_bank_accounts ieb       -- Comptes bancaires (IBAN, BIC, etc.)
  ,      iby_pmt_instr_uses_all ipi      -- Instruments de paiement (dates validité)
  ,      iby_external_payees_all iep     -- Payeurs externes (lien site<->compte)
  ,      iby_ext_party_pmt_mthds ieppm   -- Méthodes de paiement
  WHERE  assa.vendor_id = ass.vendor_id
  AND    hou.organization_id = assa.org_id
  AND    hou.name = 'REF9999'            -- ⚠️ UNIQUEMENT LA RÉFÉRENCE !
  AND    iep.ext_payee_id = ieppm.ext_pmt_party_id
  AND    iep.supplier_site_id(+) = assa.vendor_site_id
  AND    iep.ext_payee_id = ipi.ext_pmt_party_id(+)
  AND    ipi.instrument_id = ieb.ext_bank_account_id(+)
  AND    ipi.payment_function(+) = 'PAYABLES_DISB'  -- Paiements fournisseurs
  -- ⚠️ CONDITION CRITIQUE : Sites modifiés depuis dernière MAJ
  AND    (ieppm.last_update_date > p_date_maj 
       OR assa.last_update_date > p_date_maj 
       OR ipi.LAST_UPDATE_DATE > p_date_maj 
       OR iep.LAST_UPDATE_DATE > p_date_maj);

/*
EXPLICATION DES JOINTURES :

┌──────────────────────┐
│ ap_supplier_sites_all│
│ (SITE REF9999)       │
│ vendor_site_id       │
└──────────┬───────────┘
           │
           ├─────────────────────┐
           │                     │
           ▼                     ▼
┌──────────────────┐   ┌─────────────────────┐
│ ap_suppliers     │   │ iby_external_payees │
│ (FOURNISSEUR)    │   │ (LIEN SITE→COMPTE)  │
│ vendor_name      │   │ ext_payee_id        │
└──────────────────┘   └──────────┬──────────┘
                                  │
                                  ▼
                       ┌──────────────────────┐
                       │ iby_pmt_instr_uses   │
                       │ (INSTRUMENT PAIEMENT)│
                       │ dates validité       │
                       └──────────┬───────────┘
                                  │
                                  ▼
                       ┌──────────────────────┐
                       │ iby_ext_bank_accounts│
                       │ (COMPTE BANCAIRE)    │
                       │ IBAN, BIC, etc.      │
                       └──────────────────────┘

POURQUOI CES JOINTURES ?
→ Pour récupérer TOUTES les infos : site + fournisseur + compte bancaire + dates
→ Si un de ces éléments change → le site doit être re-synchronisé
*/

/*
┌─────────────────────────────────────────────────────────────────┐
│          ÉTAPE 3 : BOUCLE DE TRAITEMENT (POUR CHAQUE SITE)       │
└─────────────────────────────────────────────────────────────────┘

Pour chaque site REF9999 trouvé par le curseur :
*/

FOR rec_site_a_maj IN SITE_A_MAJ (v_date_maj) LOOP
  
  g_nbr_site := g_nbr_site + 1;  -- Compteur de sites traités
  
  /*
  3.1 Appel à la procédure de mise à jour
      Package : DKA_SAPFRSDUPLI_PKG (package séparé)
      Procédure : MAJ_SITE_FOURNISSEUR
  */
  
  DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR(
      p_vendor_site_id_ref => rec_site_a_maj.vendor_site_id,  -- ID site REF9999
      p_result_maj         => v_result_maj,                   -- OUT: OK/KO
      p_nbr_maj_succes     => v_nbr_maj_succes,               -- OUT: Nb sites OK
      p_nbr_maj_echec      => v_nbr_maj_echec,                -- OUT: Nb sites KO
      p_maj_code_echec     => v_maj_code_echec,               -- OUT: Code erreur
      p_id_liste_erreur    => v_id_liste_erreur               -- OUT: ID dans table erreurs
  );
  
  /*
  ⚠️ CE QUE FAIT MAJ_SITE_FOURNISSEUR (dans le package DKA_SAPFRSDUPLI_PKG) :
  
  A) Recherche de tous les sites DUPLIQUÉS du site REF9999
     → Sites avec même vendor_id et vendor_site_code mais dans d'autres UO
     
     Exemple :
     - Site REF9999 : vendor_site_id=123, code=VEOLIA_PARIS, org_id=9999
     - Sites dupliqués trouvés :
       * vendor_site_id=456, code=VEOLIA_PARIS, org_id=0458 (entité DCW)
       * vendor_site_id=789, code=VEOLIA_PARIS, org_id=0483 (entité DEW)
       * vendor_site_id=1011, code=VEOLIA_PARIS, org_id=0329 (entité DOS)
  
  B) Pour chaque site dupliqué, mise à jour de :
     ✓ Coordonnées bancaires (IBAN, BIC, nom banque)
     ✓ Clés comptables (compte fournisseur, compte de charge, etc.)
     ✓ Dates de validité des instruments de paiement
     ✓ Ordre de préférence des comptes bancaires
     ✓ Autres attributs du site fournisseur
  
  C) Utilisation des API Oracle standard :
     - AP_VENDOR_PUB_PKG.Update_Vendor_Site  → Mise à jour site fournisseur
     - IBY_EXT_BANKACCT_PUB.Update_Ext_Bank  → Mise à jour compte bancaire
     - GL_ACCOUNT_API.Validate_Account       → Validation clés comptables
  
  D) Gestion des erreurs :
     - Si erreur → Insertion dans DKA_SAPFRSDUPLI_ERROR_TMP
     - Chaque erreur contient : site_id, message, code erreur
     - Pas de ROLLBACK → Le traitement continue pour les autres sites
  */
  
  /*
  3.2 Si des erreurs sont survenues, les récupérer pour le rapport
  */
  
  IF v_nbr_maj_echec != 0 THEN
    
    FOR rec_erreur_maj IN (
      SELECT * 
      FROM DKA_SAPFRSDUPLI_ERROR_TMP
      WHERE ACTION_ID = v_id_liste_erreur  -- Erreurs de ce traitement
    ) LOOP
      
      g_site_a_maj := g_site_a_maj + 1;
      
      -- Stockage de l'erreur dans un tableau pour le rapport final
      g_tab_sites_maj(g_site_a_maj).NOM_FOURNISSEUR := rec_site_a_maj.VENDOR_NAME;
      g_tab_sites_maj(g_site_a_maj).CODE_SITE       := rec_site_a_maj.vendor_site_code;
      g_tab_sites_maj(g_site_a_maj).LISTE_MSG       := rec_erreur_maj.error_message;
      
      -- Récupération du nom de l'UO du site en erreur
      BEGIN
        SELECT hou.name
        INTO   V_UO_SITE_DUP
        FROM   ap_supplier_sites_all ass, hr_operating_units hou
        WHERE  vendor_site_id = rec_erreur_maj.VENDOR_SITE_ID_REF
        AND    hou.organization_id = ass.org_id;
      EXCEPTION WHEN OTHERS THEN
        V_UO_SITE_DUP := null;
      END;
      
      g_tab_sites_maj(g_site_a_maj).UO_SITE := V_UO_SITE_DUP;
      
    END LOOP;
    
  END IF;
  
  -- Mise à jour des compteurs globaux
  g_site_maj_ok := g_site_maj_ok + v_nbr_maj_succes;
  g_site_maj_ko := g_site_maj_ko + v_nbr_maj_echec;

  -- ⚠️ PAS DE COMMIT ICI → Problème de performance !
  
END LOOP;  -- Fin de la boucle sur les sites à traiter

/*
┌─────────────────────────────────────────────────────────────────┐
│              ÉTAPE 4 : MISE À JOUR DATE DERNIÈRE MAJ             │
└─────────────────────────────────────────────────────────────────┘

Une fois tous les sites traités, mise à jour de la date de référence
pour la prochaine exécution.
*/

UPDATE DKA_PARAMETERS
SET    date_value = (
         SELECT requested_start_date 
         FROM fnd_concurrent_requests 
         WHERE request_id = g_request_id
       )
WHERE  program_code = 'DKA_SAPFRSDUPLI_MAJ'
AND    parameter_name = 'DATE_DERNIERE_MAJ';

-- ⚠️ Date mise à jour = Date de LANCEMENT du traitement (pas date de fin)
-- Pourquoi ? Pour ne pas manquer les modifications faites pendant l'exécution

/*
┌─────────────────────────────────────────────────────────────────┐
│              ÉTAPE 5 : GÉNÉRATION DU RAPPORT                     │
└─────────────────────────────────────────────────────────────────┘

Affichage des statistiques et des erreurs dans le fichier .OUT
*/

sortie_traitement();  -- Affiche BILAN et LISTE DES ERREURS

/*
Format du rapport :

BILAN :
-------
. Nombre de sites de la référence sélectionnés pour la mise à jour : 27164
. Nombre de sites dupliqués mis à jour avec succès : 25055
. Nombre de sites dupliqués pour lesquels la mise à jour a échoué : 2109

LISTE DES ERREURS EN MISE A JOUR :
---------------------------------------------
Nom du fournisseur          Code site         UO Maj    Message erreur
------------------          ---------         ------    --------------
VEOLIA                      VEOLIA_PARIS      0458.DCW  La clé comptable 0458...
SUEZ                        SUEZ_LYON         0483.DEW  Fourchettes de temps...
...
*/

/*
┌─────────────────────────────────────────────────────────────────┐
│                    ÉTAPE 6 : FINALISATION                        │
└─────────────────────────────────────────────────────────────────┘

Détermination du statut de sortie du traitement
*/

IF pn_retcode = 2 THEN
  pv_errbuf := 'ATTENTION : Erreur bloquante : '||pv_errbuf;
  
ELSIF (pn_retcode = 1 OR g_tab_sites_maj.count > 0) THEN
  pv_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
  pn_retcode := 1;  -- WARNING
  
ELSE
  pv_errbuf := 'Fin normale du traitement - Aucun rejet.';
  pn_retcode := 0;  -- SUCCESS
  
END IF;

writeout(pv_errbuf);
fin_de_sortie();  -- Affiche date de fin

-- ============================================================================
-- SCHÉMA DE FLUX DU TRAITEMENT
-- ============================================================================

/*
┌─────────────────────────────────────────────────────────────────────┐
│                                                                       │
│  ╔══════════════════════════════════════════════════════════════╗   │
│  ║              DÉBUT DU TRAITEMENT                             ║   │
│  ╚══════════════════════════════════════════════════════════════╝   │
│                               │                                       │
│                               ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ 1. Récupération date dernière MAJ depuis DKA_PARAMETERS    │     │
│  │    → Exemple : 27/11/2025 12:10:09                         │     │
│  └────────────────────┬───────────────────────────────────────┘     │
│                       │                                              │
│                       ▼                                              │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ 2. Initialisation environnement Oracle EBS                 │     │
│  │    → Responsabilité : TOUT_AP_ADMINISTRATEUR               │     │
│  └────────────────────┬───────────────────────────────────────┘     │
│                       │                                              │
│                       ▼                                              │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ 3. Ouverture curseur SITE_A_MAJ                            │     │
│  │    → SELECT sites REF9999 modifiés depuis dernière MAJ     │     │
│  │    → Résultat : 27,164 sites trouvés (incident 28/11)     │     │
│  └────────────────────┬───────────────────────────────────────┘     │
│                       │                                              │
│                       ▼                                              │
│  ╔════════════════════════════════════════════════════════════╗     │
│  ║         DÉBUT BOUCLE FOR (pour chaque site)               ║     │
│  ╚════════════════════════════════════════════════════════════╝     │
│                       │                                              │
│         ┌─────────────┴─────────────┐                               │
│         │                           │                               │
│         ▼                           │                               │
│  ┌──────────────────────────┐      │                               │
│  │ Site n°1 : VEOLIA_PARIS  │      │                               │
│  │ vendor_site_id = 123456  │      │                               │
│  └──────────┬───────────────┘      │                               │
│             │                       │                               │
│             ▼                       │                               │
│  ┌─────────────────────────────────────────────────┐               │
│  │ 4. Appel DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR │             │
│  └──────────┬──────────────────────────────────────┘               │
│             │                                                        │
│             ▼                                                        │
│  ┌──────────────────────────────────────────────────────┐          │
│  │ 4.1 Recherche sites dupliqués de VEOLIA_PARIS       │          │
│  │     → SELECT ap_supplier_sites_all                   │          │
│  │       WHERE vendor_site_code = 'VEOLIA_PARIS'        │          │
│  │       AND org_id != 9999 (pas REF9999)               │          │
│  │                                                       │          │
│  │     Résultats :                                      │          │
│  │     ✓ Site 0458.DCW : vendor_site_id=456789         │          │
│  │     ✓ Site 0483.DEW : vendor_site_id=789012         │          │
│  │     ✓ Site 0329.DOS : vendor_site_id=101112         │          │
│  └──────────┬───────────────────────────────────────────┘          │
│             │                                                        │
│             ▼                                                        │
│  ┌──────────────────────────────────────────────────────┐          │
│  │ 4.2 Pour chaque site dupliqué :                     │          │
│  │                                                       │          │
│  │  A) Lecture données REF9999 :                        │          │
│  │     - IBAN : FR7630004000031234567890143            │          │
│  │     - BIC : BNPAFRPP                                │          │
│  │     - Clé compta : 0458.DCW.401100.25020...         │          │
│  │     - Date validité : 01/01/2024 → 31/12/2099      │          │
│  │                                                       │          │
│  │  B) Validation clé comptable (API GL) :             │          │
│  │     ✓ 0458.DCW.401100.25020... → VALIDE            │          │
│  │     ✗ 0458.DCW.409100.14300... → DÉSACTIVÉE ❌     │          │
│  │                                                       │          │
│  │  C) Si validation OK → Mise à jour site dupliqué :  │          │
│  │     UPDATE ap_supplier_sites_all                     │          │
│  │     UPDATE iby_ext_bank_accounts                     │          │
│  │     UPDATE iby_pmt_instr_uses_all                    │          │
│  │                                                       │          │
│  │  D) Si validation KO → Insertion erreur :           │          │
│  │     INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP           │          │
│  │     (vendor_site_id, error_message, ...)            │          │
│  └──────────┬───────────────────────────────────────────┘          │
│             │                                                        │
│             ▼                                                        │
│  ┌──────────────────────────────────────────────────────┐          │
│  │ 5. Récupération du résultat :                        │          │
│  │    v_nbr_maj_succes = 2  (0458, 0483 OK)            │          │
│  │    v_nbr_maj_echec = 1   (0329 KO)                  │          │
│  └──────────┬───────────────────────────────────────────┘          │
│             │                                                        │
│             ▼                                                        │
│  ┌──────────────────────────────────────────────────────┐          │
│  │ 6. Si erreurs, boucle sur DKA_SAPFRSDUPLI_ERROR_TMP │          │
│  │    → Récupération détails erreurs pour rapport       │          │
│  └──────────┬───────────────────────────────────────────┘          │
│             │                                                        │
│             │  ⚠️ PAS DE COMMIT ! Transaction continue              │
│             │                                                        │
│             ▼                                                        │
│         Site suivant...                                              │
│             │                                                        │
│         ◄───┘ (boucle sur 27,164 sites)                             │
│                                                                       │
│  ╔════════════════════════════════════════════════════════════╗     │
│  ║              FIN BOUCLE FOR                                ║     │
│  ╚════════════════════════════════════════════════════════════╝     │
│                               │                                       │
│                               ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ 7. Mise à jour DKA_PARAMETERS                              │     │
│  │    date_value = 28/11/2025 07:00:07 (date lancement)      │     │
│  └────────────────────┬───────────────────────────────────────┘     │
│                       │                                              │
│                       ▼                                              │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ 8. Génération rapport dans fichier .OUT                    │     │
│  │    - BILAN : 25055 succès, 2109 erreurs                   │     │
│  │    - LISTE DES ERREURS (détail par site)                  │     │
│  └────────────────────┬───────────────────────────────────────┘     │
│                       │                                              │
│                       ▼                                              │
│  ╔══════════════════════════════════════════════════════════════╗   │
│  ║              FIN DU TRAITEMENT                               ║   │
│  ║   Statut : WARNING (des erreurs sont survenues)             ║   │
│  ╚══════════════════════════════════════════════════════════════╝   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
*/

-- ============================================================================
-- TABLES UTILISÉES
-- ============================================================================

/*
┌─────────────────────────────────────────────────────────────────────┐
│                         TABLES PRINCIPALES                           │
└─────────────────────────────────────────────────────────────────────┘

1. AP_SUPPLIER_SITES_ALL (Accounts Payable)
   ┌────────────────────┬──────────────────────────────────────────┐
   │ Colonne            │ Description                              │
   ├────────────────────┼──────────────────────────────────────────┤
   │ vendor_site_id     │ PK - ID unique du site                   │
   │ vendor_id          │ FK → ap_suppliers (fournisseur)          │
   │ vendor_site_code   │ Code du site (ex: VEOLIA_PARIS)          │
   │ org_id             │ FK → hr_operating_units (UO)             │
   │ last_update_date   │ Date dernière modification               │
   │ last_updated_by    │ User ID qui a modifié                    │
   │ accts_pay_ccid     │ Clé comptable compte fournisseur         │
   │ prepay_ccid        │ Clé comptable acomptes                   │
   │ future_dated_pmt   │ Paiements futurs (Y/N)                   │
   │ ...                │                                          │
   └────────────────────┴──────────────────────────────────────────┘

2. AP_SUPPLIERS
   ┌────────────────────┬──────────────────────────────────────────┐
   │ vendor_id          │ PK - ID unique du fournisseur            │
   │ vendor_name        │ Nom du fournisseur (ex: VEOLIA)          │
   │ vendor_type        │ Type (PURCHASE, EXPENSE, etc.)           │
   │ enabled_flag       │ Actif (Y/N)                             │
   └────────────────────┴──────────────────────────────────────────┘

3. HR_OPERATING_UNITS
   ┌────────────────────┬──────────────────────────────────────────┐
   │ organization_id    │ PK - ID de l'UO                          │
   │ name               │ Nom de l'UO (REF9999, 0458.DCW, etc.)    │
   │ short_code         │ Code court                               │
   └────────────────────┴──────────────────────────────────────────┘

4. IBY_EXT_BANK_ACCOUNTS (Internet Banking)
   ┌────────────────────┬──────────────────────────────────────────┐
   │ ext_bank_account_id│ PK - ID du compte bancaire               │
   │ bank_account_num   │ Numéro de compte                         │
   │ iban               │ IBAN (ex: FR76...)                       │
   │ bank_account_name  │ Nom du compte                            │
   │ branch_id          │ FK → Agence bancaire                     │
   │ last_update_date   │ Date dernière modification               │
   └────────────────────┴──────────────────────────────────────────┘

5. IBY_PMT_INSTR_USES_ALL (Payment Instruments Uses)
   ┌────────────────────┬──────────────────────────────────────────┐
   │ instrument_payment_│ PK - ID de l'usage de l'instrument       │
   │ use_id             │                                          │
   │ instrument_id      │ FK → iby_ext_bank_accounts               │
   │ ext_pmt_party_id   │ FK → iby_external_payees_all             │
   │ payment_function   │ Fonction (PAYABLES_DISB, etc.)           │
   │ start_date         │ Date début validité                      │
   │ end_date           │ Date fin validité                        │
   │ order_of_preference│ Ordre de préférence (1, 2, 3...)        │
   │ last_update_date   │ Date dernière modification               │
   └────────────────────┴──────────────────────────────────────────┘

6. IBY_EXTERNAL_PAYEES_ALL
   ┌────────────────────┬──────────────────────────────────────────┐
   │ ext_payee_id       │ PK - ID du payeur externe                │
   │ supplier_site_id   │ FK → ap_supplier_sites_all               │
   │ payment_function   │ Fonction de paiement                     │
   │ last_update_date   │ Date dernière modification               │
   └────────────────────┴──────────────────────────────────────────┘

7. IBY_EXT_PARTY_PMT_MTHDS (Payment Methods)
   ┌────────────────────┬──────────────────────────────────────────┐
   │ ext_pmt_party_id   │ PK/FK - ID de la partie payée            │
   │ payment_method_code│ Code méthode (CHECK, EFT, etc.)          │
   │ last_update_date   │ Date dernière modification               │
   └────────────────────┴──────────────────────────────────────────┘

8. DKA_PARAMETERS (Table custom Dalkia)
   ┌────────────────────┬──────────────────────────────────────────┐
   │ program_code       │ PK - Code du programme                   │
   │ parameter_name     │ PK - Nom du paramètre                    │
   │ date_value         │ Valeur date du paramètre                 │
   │ ...                │                                          │
   └────────────────────┴──────────────────────────────────────────┘

9. DKA_SAPFRSDUPLI_ERROR_TMP (Table temporaire erreurs)
   ┌────────────────────┬──────────────────────────────────────────┐
   │ action_id          │ PK - ID de l'action                      │
   │ vendor_site_id_ref │ ID du site en erreur                     │
   │ error_message      │ Message d'erreur                         │
   │ error_code         │ Code d'erreur                            │
   │ creation_date      │ Date de l'erreur                         │
   └────────────────────┴──────────────────────────────────────────┘
*/

-- ============================================================================
-- PROBLÈMES DE PERFORMANCE IDENTIFIÉS
-- ============================================================================

/*
1. ⚠️ PAS DE COMMIT INTERMÉDIAIRE
   -------------------------------
   Le traitement fait UNE SEULE TRANSACTION pour tous les sites.
   
   Conséquence avec 27,164 sites :
   → Transaction de 9 heures
   → UNDO tablespace saturé
   → Impossible de reprendre en cas d'erreur
   → Ralentissement progressif

2. ⚠️ CURSEUR AVEC 7 JOINTURES
   ----------------------------
   Le curseur joint 7 tables dont 3 en OUTER JOIN.
   
   Avec 27,164 sites, le plan d'exécution peut être inefficace :
   → NESTED LOOPS au lieu de HASH JOIN
   → Index mal utilisés
   → Statistiques obsolètes

3. ⚠️ TRAITEMENT UNITAIRE
   ----------------------
   Chaque site est traité un par un (pas de BULK COLLECT).
   
   Pour 27,164 sites :
   → 27,164 appels à DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR
   → Chaque appel fait potentiellement 3-5 UPDATE
   → Total : ~100,000+ opérations SQL

4. ⚠️ SELECT DANS LA BOUCLE
   -------------------------
   Pour chaque erreur, un SELECT est fait pour récupérer le nom de l'UO.
   
   Avec 2,109 erreurs :
   → 2,109 SELECT supplémentaires
   → Pourrait être fait en un seul JOIN

5. ⚠️ PAS DE LIMITE DE VOLUME
   ---------------------------
   Le traitement n'a aucune limite sur le nombre de sites à traiter.
   
   → Si 50,000 sites sont modifiés, tous seront traités
   → Pas de pagination
   → Pas de possibilité de reprendre
*/

-- ============================================================================
-- AMÉLIORATIONS RECOMMANDÉES
-- ============================================================================

/*
1. AJOUTER COMMIT TOUS LES 100 SITES
   ----------------------------------
   FOR rec_site_a_maj IN SITE_A_MAJ LOOP
     -- Traitement...
     
     IF MOD(g_nbr_site, 100) = 0 THEN
       COMMIT;
       -- Éventuellement : INSERT log progression
     END IF;
   END LOOP;

2. UTILISER BULK COLLECT
   ----------------------
   DECLARE
     TYPE t_site_ids IS TABLE OF NUMBER;
     l_site_ids t_site_ids;
   BEGIN
     OPEN SITE_A_MAJ;
     LOOP
       FETCH SITE_A_MAJ BULK COLLECT INTO l_site_ids LIMIT 1000;
       EXIT WHEN l_site_ids.COUNT = 0;
       
       -- Traiter le batch de 1000 sites
       FOR i IN 1..l_site_ids.COUNT LOOP
         -- Traitement...
       END LOOP;
       
       COMMIT;
     END LOOP;
   END;

3. AJOUTER LIMITE DE VOLUME
   -------------------------
   CURSOR SITE_A_MAJ IS
     SELECT ...
     FROM ...
     WHERE ...
     AND ROWNUM <= 5000;  -- Max 5000 sites par exécution

4. IMPLÉMENTER GESTION DE REPRISE
   -------------------------------
   -- Nouvelle table de progression
   CREATE TABLE DKA_SAPFRSDUPLI_PROGRESS (
     request_id NUMBER,
     last_vendor_site_id NUMBER,
     nb_traites NUMBER,
     nb_erreurs NUMBER
   );
   
   -- Dans le curseur
   WHERE vendor_site_id > NVL(last_treated_site_id, 0)
   ORDER BY vendor_site_id
   FETCH FIRST 1000 ROWS ONLY;

5. PARALLÉLISER LE TRAITEMENT
   ---------------------------
   -- Lancer plusieurs jobs en parallèle sur des plages différentes
   -- Job 1 : sites 1-10000
   -- Job 2 : sites 10001-20000
   -- etc.
*/

-- ============================================================================
-- FIN DU DOCUMENT
-- ============================================================================
