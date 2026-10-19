CREATE OR REPLACE PACKAGE BODY dka_iarrecsicm_men_pkg AS
  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : Projet Hélios
  -- NOM              : DKA_IARRECSICM_MEN_PKG
  -- DESCRIPTION      : DKA_IARRECSICM_MEN_PKG Package Body
  --
  -- AUTEUR           : M. TIABLIKOFF(Capgemini)
  -- DATE DE CREATION : 12/04/2016
  -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 08/09/2016 BDE Modification pour le projet Hélios /EX : Remplacement de la table ar_customers en AR_CUSTOMERS (changement de la R12)
  -- 19/12/2016 OBE Modification : Correctif artf2068255
  -- 12/01/2017 YWA artf2080350 : SPE171 - Corrections champs obligatoire - defect Flux_SI_Dalkia #264
  --            YWA artf2079730 : SPE171 - Modification du nom du fichier- defect Flux_SI_Dalkia #269
  -- 23/01/2017 MEG artf2087899 : SPE171 - Type de mouvement erroné
  -- 07/03/2017 NBO artf2098180 : SPE171 - Optimisation du traitement
  -- 22/03/2017 EFL artf2125432 : Optimisation + Corrections 
  -- 08/06/2017 OBE artf2171549 : SPE171 - erreur sélection de numéro de tache/projet - Defect Bout_En_Bout_Helios_Ref  
  -- 09/06/2017 MEG artf2169875 : SPE171 : En cours recouvrement clients vers SYRUS - Report du correctif réalisé en 11.5.9
  -- 02/10/2017 OBE artf2233613 : SPE171 - Analyse champ - Defect Beb #1103  
  -- 25/10/2017 OBE artf2250006 : SPE171 : En cours recouvrement clients vers SYRUS - Report d'un correctif réalisé en 11.5.9
  -- 31/01/2018 NBO artf2346244 : INC0185774 : Extraction en cours mouvements AR vers Syrus
  -- 05/03/2018 JJA artf2413242 : INC0197021 - SPE171 optimisation du traitement
  -- 19/08/2019 SFA artf07290465 : SPE171 - Changement nom de fichier pour les en-cours de recouvrement (TASK0089304)
  -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
  -- 03/02/2020 MTIA artf07319784 - TASK0096648 - Correctif ajout code chargé de recouvrement - Récupération du client destinataire
  -- 07/05/2020 MTIA artf07319784 - TASK0096648 - Correctif ajout code chargé de recouvrement - Récupération du client destinataire - Modif si plusieurs sites.
  -- 04/06/2020 MTIA artf07319784 - TASK0096648 - Correctif ajout code chargé de recouvrement - Récupération du client destinataire - Ne plus filtrer sur site actif.
  -- 08/02/2022 SHA  TASK0164048-Tâche de réalisation - Modification ou insertion de données par script 
  -- 21/02/2022 SHA  RITM0164478-Modifications des noms des clients  
  -- 23/03/2023 IBA  EDB360 - Export OA vers SYRUS - Modif RG pour déterminer le code région dans le cas d'un règlement
  -- 07/08/2023 IBA  Modification : Correctif  KDFI-1209 - Contrôles du matin - 27/07 - "DKA : Flux SI / CM - Extraction en cours recouvrement" en erreur
  -- 09/08/2023 IBA  artf07537003 EDB341 - Ajout nouvelles RG dans l'export journalier et mensuel vers SYRUS
  -- 13/10/2023 BNZ artf07537003  EDB341 - Ajout nouvelles RG dans l'export journalier et mensuel vers SYRUS : Modifications
  -- 22/12/2023 BNZ Modification : Correctif  KDFI-1560 - Compte client en colonne 13 erroné.
  -- -----------------------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- -----------------------------------------------------------------------------
  -- Nom              : Get_Lib_UO
  -- Description      : Fonction de recherche du libellé du centre de gestion
  --                    passé en parametre
  --
  -- PARAMETRES       : Pv_UO     Entrée         Centre de Gestion
  --                    Pv_Lib_UO        Sortie  Libellé Centre de Gestion
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  /*FUNCTION get_lib_uo(pv_uo IN VARCHAR2) RETURN VARCHAR2 IS
  
    pv_lib_uo fnd_flex_values_tl.description%TYPE;
  
  BEGIN
  
    ---------------------------------------
    -- Recherche du libellé de la région --
    ---------------------------------------
    --DAOPCCF UO
    BEGIN
      SELECT ffvt.description
        INTO pv_lib_uo
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv,
             fnd_flex_values_tl  ffvt
       WHERE ffvs.flex_value_set_name = 'DAOPCCF_UO'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         AND ffv.flex_value = pv_uo
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = userenv('LANG');
    
    EXCEPTION
      WHEN OTHERS THEN
        pv_lib_uo := NULL;
    END;
  
    RETURN(pv_lib_uo);
  
  END get_lib_uo;*/

  -- -----------------------------------------------------------------------------
  -- Nom              : Get_Classe_Client
  -- Description      : Fonction de recherche du libellé de la classe client
  --                    passée en parametre
  --
  -- PARAMETRES       : Pv_Classe_Client      Entrée         Classe Client
  --                    Pv_Lib_Classe_Client         Sortie  Libellé Classe Client
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  /*FUNCTION get_classe_client(pv_classe_client IN VARCHAR2) RETURN VARCHAR2 IS
  
    pv_lib_classe_client ar_lookups.meaning%TYPE;
  
  BEGIN
  
    -----------------------------------
    -- Recherche de la classe client --
    -----------------------------------
    BEGIN
      SELECT al.meaning
        INTO pv_lib_classe_client
        FROM ar_lookups al
       WHERE al.lookup_type = 'CUSTOMER CLASS'
         AND al.lookup_code = pv_classe_client;
    
    EXCEPTION
      WHEN OTHERS THEN
        pv_lib_classe_client := NULL;
    END;
  
    RETURN(pv_lib_classe_client);
  
  END get_classe_client;*/

  -- -----------------------------------------------------------------------------
  -- Nom              : Get_Categorie_Client
  -- Description      : Fonction de recherche du libellé de la catégorie client
  --                    passée en parametre
  --
  -- PARAMETRES       : Pv_Categorie_Client      Entrée         Catégorie Client
  --                    Pv_Lib_Categorie_Client         Sortie  Libellé Catégorie Client
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  /*FUNCTION get_categorie_client(pv_categorie_client IN VARCHAR2) RETURN VARCHAR2 IS
  
    pv_lib_categorie_client ar_lookups.meaning%TYPE;
  
  BEGIN
  
    --------------------------------------
    -- Recherche de la catégorie client --
    --------------------------------------
    BEGIN
      SELECT al.meaning
        INTO pv_lib_categorie_client
        FROM ar_lookups al
       WHERE al.lookup_type = 'CUSTOMER_CATEGORY'
         AND al.lookup_code = pv_categorie_client;
    
    EXCEPTION
      WHEN OTHERS THEN
        pv_lib_categorie_client := NULL;
    END;
  
    RETURN(pv_lib_categorie_client);
  
  END get_categorie_client;*/

  -- -----------------------------------------------------------------------------
  -- Nom              : Extraction_Encours
  -- Description      : Extraction des données pour la génération du fichier de
  --                    sortie justifiant l'encours
  --
  -- PARAMETRES       : Pv_Errbuf              Sortie Message d'erreur
  --                    Pn_Retcode             Sortie Code Retour de la procédure
  --                                                  '0' : Normal
  --                                                  '1' : Avertissement
  --                                                  '2' : Erreur
  --                    Pv_Debug_Mode Entrée          Mode debug
  --                    Pv_Region     Entrée          Centre de gestion
  --                    Pv_Periode    Entrée          Période
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE extraction_encours(pv_errbuf  OUT VARCHAR2,
                               pn_retcode OUT NUMBER,
                               pv_periode IN OUT VARCHAR2,
                               pv_region  IN VARCHAR2) IS
  
    e_file EXCEPTION;
    pv_fin_periode   VARCHAR2(15);
    pv_fin_periode_1 VARCHAR2(15);
    pv_mois          VARCHAR2(10);
    -----------------------------------------------------------------
    -- Curseur de lecture des factures a la date du jour --
    -----------------------------------------------------------------
    CURSOR cur_factures IS
      SELECT /*+ LEADING (Apsa) INDEX(Apsa,AR_PAYMENT_SCHEDULES_N9) USE_NL(Rcta,Rctta,Gcc,Rctlgda,Hcsua,Hcasa,Rc,Hp) */
       fnd_global.conc_request_id request_id,
       gcc.segment2 uo, -- Centre de Gestion
       rcta.org_id,
       ffvt.description lib_uo, --Libellé Centre de Gestion
       rc.account_number code_client, -- Code Client
       REPLACE(REPLACE (substrb(hp.party_name, 1, 50)  ,  chr(34), ' ') ,  chr(39), ' ') client, -- Client -- SHA RITM0164478
       apsa.trx_date date_mouvement, -- Date Mouvement
       apsa.due_date echeance, -- Echeance
       rctlgda.acctd_amount solde_du, -- Solde Du
       NULL charge_recouvrement, -- Chargé Recouvrement
       NULL numero_tache_projet, -- tache
       NULL centre_finance, -- Centre Finance
       rcta.attribute10 task_id,
       rcta.attribute11 project_id,
       NULL projet_majoritaire, -- Projet Majoritaire
       gcc.segment1 societe, -- Société
       rcta.trx_number num_piece, -- Num Piece
       -- 07/03/2017 NBO artf2098180 : SPE171 - Optimisation du traitement
       (SELECT flvv_class.meaning
          FROM fnd_lookup_values_vl flvv_class
         WHERE rctta.TYPE = flvv_class.lookup_code
           AND flvv_class.lookup_type = 'INV/CM') classe_piece, -- Classe Piece
       gcc.segment3 compte_client, -- Compte Client
       hcsua.location site_client, -- Site Client
       NULL num_client_destinataire, -- Num Client Destinataire
       NULL client_destinataire, -- Client Destinataire
       NULL adresse_1, -- Adresse_1 Client
       NULL adresse_2, -- Adresse_2 Client
       NULL adresse_3, -- Adresse_3 Client
       NULL adresse_4, -- Adresse_4 Client
       NULL code_postal, -- Code Postal
       NULL ville, -- Ville
       NULL pays, -- Pays
       -- 07/03/2017 NBO artf2098180 : SPE171 - Optimisation du traitement
       (SELECT flvv_status.meaning
          FROM fnd_lookup_values_vl flvv_status
         WHERE apsa.status = flvv_status.lookup_code
           AND flvv_status.lookup_type = 'PAYMENT_SCHEDULE_STATUS') statut, -- Statut
       rctta.NAME type_de_mouvement, -- Type de mouvement
       apsa.amount_in_dispute montant_en_litige, -- Montant en litige
       rcta.comments commentaire, -- Commantaire
       apsa.customer_site_use_id customer_site_use_id,
       apsa.customer_id customer_id,
       hcsua.cust_acct_site_id cust_acct_site_id,
       rcta.customer_trx_id customer_trx_id,
       rc.customer_class_code classe_client, -- Classe Client
       (SELECT al.meaning
          FROM ar_lookups al
         WHERE al.lookup_type = 'CUSTOMER CLASS'
           AND al.lookup_code = rc.customer_class_code) lib_classe_client,
       hp.category_code categorie_client, -- Catégorie Client
       (SELECT al.meaning
          FROM ar_lookups al
         WHERE al.lookup_type = 'CUSTOMER_CATEGORY'
           AND al.lookup_code = hp.category_code) lib_categorie_client,
       hcasa.attribute11 siret, -- Siret
       gcc.code_combination_id cle_comptable,
       rcta.purchase_order num_commande_alto, --num commande alto
       rcta.doc_sequence_id doc_sequence_id,
       rcta.doc_sequence_value doc_sequence_value,
       NULL code_adresse_payeur,
       rctlgda.gl_date date_gl,
       CASE nvl(apsa.attribute1, 'NULL')
         WHEN 'NULL' THEN
          'NON'
         ELSE
          'OUI'
       END AS piece_cede,
       to_char(to_date(substr(apsa.attribute1, 1, 10), 'YYYY/MM/DD'),
               'DD/MM/YYYY') date_cession,
       TRIM(REPLACE(apsa.attribute2, '.', ',')) montant_cede,
       NULL montant_p1,
       NULL montant_p2,
       NULL montant_p3,
       NULL montant_p4,
       NULL AS montant_p5,
       NULL AS montant_p6,
       NULL montant_autres,
       NULL montant_vide,
       NULL code_adresse_dest,
       NULL ad1_dest,
       NULL ad2_dest,
       NULL ad3_dest,
       NULL ad4_dest,
       NULL code_postal_dest,
       NULL ville_dest,
       NULL pays_dest,
      -- Libellé du Centre de gestion (Suite du Programme)
	  ---<Debut IBA EDB341
	   (select ARC.NAME from AR_RECEIPT_METHODS ARM ,AR_RECEIPT_CLASSES ARC where ARC.receipt_class_id = ARM.receipt_class_id
and RCTA.RECEIPT_METHOD_ID = ARM.RECEIPT_METHOD_ID 
) mode_reglement,
case when (select ARM.NAME from AR_RECEIPT_METHODS ARM ,AR_RECEIPT_CLASSES ARC where ARC.receipt_class_id = ARM.receipt_class_id
and RCTA.RECEIPT_METHOD_ID = ARM.RECEIPT_METHOD_ID ) = 'PRELEVT' then 
decode(rcta.attribute5,null,'OUI',rcta.attribute5)                                                                                                                                   
else
'NON' end  
 AUTORISE_PRELEV
	   ---IBA Fin >
        FROM ar_payment_schedules         apsa,
             ra_customer_trx_all          rcta,
             ra_cust_trx_types_all        rctta,
             ra_cust_trx_line_gl_dist_all rctlgda,
             gl_code_combinations         gcc,
             hz_cust_site_uses_all        hcsua,
             hz_cust_acct_sites_all       hcasa, -- 29/09/2011 Ajout pour SIRET
             hz_cust_accounts             rc, -- Ra_Customers                   Rc
             hz_parties                   hp,
             --artf2413242
             fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv,
             fnd_flex_values_tl  ffvt
       WHERE apsa.gl_date_closed > nvl(pv_fin_periode_1, SYSDATE) -- Date Butoire correspond a la date du jour
         AND apsa.CLASS <> 'PMT'
         AND apsa.customer_trx_id = rcta.customer_trx_id
         AND rcta.complete_flag = 'Y'
         AND rcta.cust_trx_type_id = rctta.cust_trx_type_id
         AND rcta.customer_trx_id = rctlgda.customer_trx_id
         AND rctlgda.account_class = 'REC'
         AND rctlgda.gl_date <= nvl(pv_fin_periode, SYSDATE) -- Date Butoire correspond a la date du jour.
         AND rctlgda.gl_posted_date IS NOT NULL
         AND rctlgda.code_combination_id = gcc.code_combination_id
            -- Vérifier que le centre de gestion fait partie des régions actifs (reprise du jeu de valeur [DKA_REGION_RECOUVREMENT])
         AND apsa.customer_site_use_id = hcsua.site_use_id
         AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id -- 29/09/2011 Jointure entre les tables Hz_Cust_Site_Uses et Hz_Cust_Acct_Sites
         AND apsa.customer_id = rc.cust_account_id
         AND hp.party_id = rc.party_id
         AND ('NULL' = nvl(pv_region, 'NULL') OR
             ('NULL' != nvl(pv_region, 'NULL') AND
             gcc.segment2 = pv_region))
            --artf2413242
         AND ffvs.flex_value_set_name = 'DAOPCCF_UO'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         AND ffv.flex_value = gcc.segment2
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffvt.LANGUAGE = userenv('LANG');
  
    rec_factures cur_factures%ROWTYPE;
    TYPE t_rec_factures IS TABLE OF cur_factures%ROWTYPE index by binary_integer;
    vt_rec_factures t_rec_factures;
    -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
    v_charge_recouvrement VARCHAR2(150);
  
    -------------------------------------------------------------------
    -- Curseur de lecture des reglements a la date de fin de période --
    -------------------------------------------------------------------
    CURSOR cur_reglements IS
      SELECT v.*,
             (SELECT flvv_class.meaning
                FROM fnd_lookup_values_vl flvv_class
               WHERE flvv_class.lookup_type = 'INV/CM'
                 AND flvv_class.lookup_code = v.CLASS) classe_piece, -- Classe Piece
             (SELECT al.meaning
                FROM ar_lookups al
               WHERE al.lookup_type = 'CUSTOMER CLASS'
                 AND al.lookup_code = v.classe_client) lib_classe_client,
             (SELECT al.meaning
                FROM ar_lookups al
               WHERE al.lookup_type = 'CUSTOMER_CATEGORY'
                 AND al.lookup_code = v.categorie_client) lib_categorie_client
        FROM (SELECT /*+ LEADING (Apsa) INDEX(Apsa AR_PAYMENT_SCHEDULES_N9) USE_NL(Acra,Acrha,Araa,Gcc) */
               fnd_global.conc_request_id request_id,
			   --< DEBUT IBA EDB360
               --gcc.segment2 uo, -- Centre de Gestion
			   substr(hou.name,1,3) uo, -- Centre de Gestion 
			   --FIN IBA EDB360>
               ffvt.description lib_uo, --Libellé Centre de Gestion
               rc.account_number code_client, -- Code Client
               REPLACE(REPLACE (substrb(hp.party_name, 1, 50)  ,  chr(34), ' ') ,  chr(39), ' ') client, -- Client -- SHA RITM0164478
               apsa.trx_date date_mouvement, -- Date Mouvement
               apsa.due_date echeance, -- Echeance
               SUM(decode(acrha.status,
                          'REVERSED',
                          -araa.amount_applied,
                          +araa.amount_applied)) solde_du, -- Solde du
               NULL charge_recouvrement, -- Charge Recouvrement
               'Pas de numero tache projet' numero_tache_projet, -- Centre Niv4
                ----<Debut IBA EDB341
                (select RETURN_VALUE from DKA_STRANSCO_HEADERS DSH, DKA_STRANSCO_LINES DSL
               where DSH.set_id = DSL.set_id
               and DSH.set_name = 'DKA_CF_REGION_AR'
               and gcc.segment2 = DSL.PARAMS_VALUE) centre_finance, -- Centre Finance
               ----IBA Fin> 
               NULL project_id,
               'Pas de projet' projet_majoritaire, -- Projet Majoritaire
               gcc.segment1 societe, -- Société
               acra.receipt_number num_piece, -- Num Piece
               apsa.CLASS,
               --'419000' compte_client, -- Compte Client
			   --< BNZ: KDFI-1560
               (select DISTINCT GCC1.segment3 
                       from gl_code_combinations gcc1 
                        where gcc1.CODE_COMBINATION_ID= araa.CODE_COMBINATION_ID) compte_client, --> Compte Client
               NULL site_client, -- Site Client
               NULL num_client_destinataire, -- Num Client Destinataire
               NULL client_destinataire, -- Client Destinataire
               NULL adresse_1, -- Adresse_1 Client
               NULL adresse_2, -- Adresse_2 Client
               NULL adresse_3, -- Adresse_3 Client
               NULL adresse_4, -- Adresse_4 Client
               NULL code_postal, -- Code Postal
               NULL ville, -- Ville
               NULL pays, -- Pays
               -- 07/03/2017 NBO artf2098180 : SPE171 - Optimisation du traitement
               (SELECT flvv_status.meaning
                  FROM fnd_lookup_values_vl flvv_status
                 WHERE apsa.status = flvv_status.lookup_code
                   AND flvv_status.lookup_type = 'PAYMENT_SCHEDULE_STATUS') statut, -- Statut
               'En compte' type_de_mouvement, -- Type de mouvement
               apsa.amount_in_dispute montant_en_litige, -- Montant en litige
               acra.comments commentaire, -- Commentaire
               -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                --apsa.customer_site_use_id customer_site_use_id,
                --apsa.customer_id customer_id,
                acra.customer_site_use_id customer_site_use_id,
                cas.cust_account_id       customer_id,
                rc.customer_class_code    classe_client, -- Classe Client
                hp.category_code          categorie_client, -- Catégorie Client
                NULL                      siret, -- Siret (Mis a null car il dépend Site Client qui est a null)
                -- Libellé du Centre de gestion (Suite du programme)
                NULL code_adresse_payeur,
                acrha.gl_date,
                NULL code_adresse_dest,
                NULL ad1_dest,
                NULL ad2_dest,
                NULL ad3_dest,
                NULL ad4_dest,
                NULL code_postal_dest,
                NULL ville_dest,
                NULL pays_dest,
                to_char(to_date(substr(apsa.attribute1, 1, 10), 'YYYY/MM/DD'),
                        'DD/MM/YYYY') date_cession, --YWA artf2080350
                apsa.org_id,
                hcsu.cust_acct_site_id cust_acct_site_id,
				----<Debut IBA EDB341
				apsa.cash_receipt_id   cash_receipt_id,
				(select ARC.NAME from AR_RECEIPT_METHODS ARM ,AR_RECEIPT_CLASSES ARC, AR_CASH_RECEIPTS_ALL ACRA where ARC.receipt_class_id = ARM.receipt_class_id
                and ACRA.RECEIPT_METHOD_ID = ARM.RECEIPT_METHOD_ID 
                and CASH_RECEIPT_ID =apsa.cash_receipt_id
                 ) mode_reglement
				----IBA Fin>
                 FROM ar_payment_schedules           apsa,
				      hr_operating_units             hou, --IBA EDB360
                      ar_cash_receipts_all           acra,
                      ar_cash_receipt_history_all    acrha,
                      ar_receivable_applications_all araa,
                      gl_code_combinations           gcc,
                      hz_cust_accounts               rc, -- Ra_Customers                   Rc
                      hz_parties                     hp,
                      --artf2413242
                      fnd_flex_value_sets ffvs,
                      fnd_flex_values     ffv,
                      fnd_flex_values_tl  ffvt,
                      -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                     hz_cust_site_uses_all  hcsu,
                     hz_cust_acct_sites_all cas
               WHERE apsa.gl_date_closed > nvl(pv_fin_periode_1, SYSDATE)
                 AND apsa.CLASS = 'PMT'
				 and acra.ORG_ID = hou.organization_id   --IBA EDB360
                 AND apsa.cash_receipt_id = acra.cash_receipt_id
                 AND acra.cash_receipt_id = araa.cash_receipt_id
                 AND araa.cash_receipt_id = acrha.cash_receipt_id
                 AND acrha.gl_posted_date IS NOT NULL
                 AND acrha.cash_receipt_history_id =
                     (SELECT MAX(acrh1.cash_receipt_history_id)
                        FROM ar_cash_receipt_history_all acrh1
                       WHERE acrh1.cash_receipt_id = acrha.cash_receipt_id
                         AND acrh1.gl_date <= nvl(pv_fin_periode, SYSDATE)
                         AND acrh1.gl_posted_date IS NOT NULL)
                 AND acrha.account_code_combination_id =
                     gcc.code_combination_id
                    -- Vérifier que le centre de gestion fait partie des régions actifs (reprise du jeu de valeur [DKA_REGION_RECOUVREMENT])
                 AND araa.status IN ('UNAPP', 'ACC')
                 AND araa.gl_date <= nvl(pv_fin_periode, SYSDATE)
                 AND araa.gl_posted_date IS NOT NULL
                    -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                     --AND apsa.customer_id = rc.cust_account_id
                  AND hcsu.site_use_id = acra.customer_site_use_id
                  AND hcsu.cust_acct_site_id = cas.CUST_ACCT_SITE_ID
                  AND cas.CUST_ACCOUNT_ID = rc.cust_account_id
                  AND hp.party_id = rc.party_id
                  AND nvl(araa.applied_customer_trx_id, -1) = -1
                  AND ('NULL' = nvl(pv_region, 'NULL') OR
                      ('NULL' != nvl(pv_region, 'NULL') AND
                      gcc.segment2 = pv_region))
                     --artf2413242
                  AND ffvs.flex_value_set_name = 'DAOPCCF_UO'
                  AND ffvs.flex_value_set_id = ffv.flex_value_set_id
				  ---<DEBUT IBA EDB360
               --   AND ffv.flex_value = gcc.segment2
				  AND ffv.flex_value = substr(hou.name,1,3)
				  ---FIN IBA EDB360>
                  AND ffv.flex_value_id = ffvt.flex_value_id
                  AND ffvt.LANGUAGE = userenv('LANG')
                GROUP BY gcc.segment2,
				         hou.name, --IBA EDB360
                         ffvt.description,
                         rc.account_number,
                         substrb(hp.party_name, 1, 50),
                         apsa.trx_date,
                         apsa.due_date,
                         gcc.segment1,
                         acra.receipt_number,
                         --gcc.segment3,
						 araa.CODE_COMBINATION_ID, --BNZ KDFI-1560
                         apsa.CLASS,
                         apsa.status,
                         apsa.amount_in_dispute,
                         acra.comments,
                         -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                        --apsa.customer_site_use_id,
                        --apsa.customer_id,
                        acra.customer_site_use_id,
                        cas.CUST_ACCOUNT_ID,
                        rc.customer_class_code,
                        hp.category_code,
                        acrha.gl_date,
                        apsa.attribute1,
                        apsa.org_id,
                        hcsu.cust_acct_site_id,
						apsa.cash_receipt_id  --IBA EDB341
						) v;
  
    rec_reglements cur_reglements%ROWTYPE;
    TYPE t_rec_reglements IS TABLE OF cur_reglements%ROWTYPE index by binary_integer;
    vt_rec_reglements t_rec_reglements;
  
    ------------------------------------------------------------------
    -- Curseur de lecture des lignes de la table DKA_IARRECSICM_ENCOURS_CLIENT --
    ------------------------------------------------------------------
    CURSOR cur_fichier IS
      SELECT
      /* 1*/
       DEC.code_client || ';' ||
       /* 2*/
       REPLACE( REPLACE(DEC.client ,  chr(34), ' '),  chr(39), ' ') || ';' || -- SHA RITM0164478
       /* 3*/
        to_char(DEC.date_mouvement, 'DD/MM/YYYY') || ';' ||
       /* 4*/
        to_char(DEC.echeance, 'DD/MM/YYYY') || ';' ||
       /* 5*/
        REPLACE(to_char(DEC.solde_du), '.', ',') || ';' ||
       /* 6*/
        DEC.charge_recouvrement || ';' ||
       /* 7*/
        DEC.centre_finance || ';' ||
       /* 8*/
        DEC.numero_tache_projet || ';' ||
       /* 9*/
        DEC.projet_majoritaire || ';' ||
       /*10*/
        DEC.societe || ';' ||
       /*11*/
        REPLACE(REPLACE(DEC.num_piece ,chr(10), ''),chr(13), '') || ';' || -- BNZ : EDB341
       /*12*/
        DEC.classe_piece || ';' ||
       /*13*/
        DEC.compte_client || ';' ||
       /*14*/
        decode(DEC.site_client,
               NULL,
               DEC.site_client,
               DEC.uo || '-' || DEC.site_client) || ';' || -- OBE
       /*15*/
        DEC.num_client_destinataire || ';' ||
       /*16*/
        DEC.client_destinataire || ';' ||
       /*17*/
        DEC.statut || ';' ||
       /*18*/
        DEC.type_de_mouvement || ';' ||
       /*19*/
        REPLACE(to_char(DEC.montant_en_litige), '.', ',') || ';' ligne1,
       /*20*/
       translate(DEC.commentaire,
                 '";' || chr(10) || chr(13) || chr(12) || chr(14) || chr(11) ||
                 chr(15) || chr(9),
                 ''',       ') ligne2,
       ';' ||
       /*21*/
        DEC.uo || ';' ||
       /*22*/
        DEC.lib_uo || ';' ||
       /*23*/
        DEC.classe_client || ';' ||
       /*24*/
        DEC.categorie_client || ';' ||
       /*25*/
        DEC.siret || ';' ||
       /*26*/
        DEC.adresse_1 || ';' ||
       /*27*/
        DEC.adresse_2 || ';' ||
       /*28*/
        DEC.adresse_3 || ';' ||
       /*29*/
        DEC.adresse_4 || ';' ||
       /*30*/
        DEC.code_postal || ';' ||
       /*31*/
        DEC.ville || ';' ||
       /*32*/
        DEC.pays || ';' ||
       /*33*/
        DEC.identifiant_oracle || ';' ||
       /*34*/
        REPLACE(to_char(DEC.montant_ttc), '.', ',') || ';' ||
       /*35*/
        REPLACE(to_char(DEC.montant_ht), '.', ',') || ';' ||
       /*36*/
        DEC.taux_de_tva || ';' ||
       /*37*/
        DEC.num_cmd_alto || ';' ||
       /*38*/
        DEC.code_adresse_payeur || ';' ||
       /*39*/
        to_char(DEC.date_gl, 'DD/MM/YYYY') || ';' ||
       /*40*/
        DEC.piece_cede || ';' ||
       /*41*/
        to_char(DEC.date_cession, 'DD/MM/YYYY') || ';' ||
       /*42*/
        REPLACE(to_char(DEC.montant_cede), '.', ',') || ';' ||
       /*43*/
        REPLACE(to_char(DEC.montant_p1), '.', ',') || ';' ||
       /*44*/
        REPLACE(to_char(DEC.montant_p2), '.', ',') || ';' ||
       /*45*/
        REPLACE(to_char(DEC.montant_p3), '.', ',') || ';' ||
       /*46*/
        REPLACE(to_char(DEC.montant_p4), '.', ',') || ';' ||
       /*47*/
        REPLACE(to_char(DEC.montant_p5), '.', ',') || ';' ||
       /*48*/
        REPLACE(to_char(DEC.montant_p6), '.', ',') || ';' ||
       /*49*/
        REPLACE(to_char(DEC.montant_autres), '.', ',') || ';' ||
       /*50*/
        REPLACE(to_char(DEC.montant_vide), '.', ',') || ';' ||
       /*51*/
        DEC.code_adresse_dest || ';' ||
       /*52*/
        DEC.ad1_dest || ';' ||
       /*53*/
        DEC.ad2_dest || ';' ||
       /*54*/
        DEC.ad3_dest || ';' ||
       /*55*/
        DEC.ad4_dest || ';' ||
       /*56*/
        DEC.code_postal_dest || ';' ||
       /*57*/
        DEC.ville_dest || ';' ||
       /*58*/
        DEC.pays_dest || ';' ||
		--<Debut IBA EDB341
	   /*59*/
	    DEC.mode_reglement || ';' ||
	   /*60*/
	    DEC.AUTORISE_PRELEV 	ligne3
		----IBA Fin>
        FROM dka_iarrecsicm_encours_client DEC
       WHERE DEC.request_id = fnd_global.conc_request_id;
  
    rec_fichier cur_fichier%ROWTYPE;
  
    cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';
    vv_buffer      VARCHAR2(4000);
    vn_buffer_size PLS_INTEGER;
  
    vn_nombre                    NUMBER := 0;
    vn_factures                  NUMBER := 0;
    vn_reglements                NUMBER := 0;
    vn_solde                     NUMBER;
    vn_montant1                  NUMBER;
    vn_montant2                  NUMBER;
    vn_montant3                  NUMBER;
    vn_montant4                  NUMBER;
    vn_montant_ht                NUMBER;
    vn_montant_ttc               NUMBER;
    vn_montant_tva               NUMBER;
    vv_type_mouvement            VARCHAR2(50);
    vv_code_adresse_destinataire VARCHAR(60);
    vv_segmentation_client       VARCHAR(60);
  
    vv_lib_uo           fnd_flex_values_tl.description%TYPE;
    vv_classe_client    ar_lookups.meaning%TYPE;
    vv_categorie_client ar_lookups.meaning%TYPE;
  
    vv_requested_by VARCHAR2(100);
    vn_org_id       NUMBER; -- OBE artf2233613
  
    -- Variable d'écriture du résultat dans le fichier FOACMAR_YYYYMMDD
    va_file_id utl_file.file_type;
  
    vv_filename VARCHAR2(80);
  
    vv_directory_name dba_directories.directory_path%TYPE;
    vv_period_name    VARCHAR2(60); --SFA  :  artf07290465 
    vv_end_date       VARCHAR2(10); --SFA  :  artf07290465
  BEGIN
  
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    dka_tools_pkg.put_debug_message('==> Début du traitement');
  
    --------------------------------------------------------------
    -- Suppression des données de tous les traitements terminés --
    --------------------------------------------------------------
    dka_tools_pkg.put_debug_message('Suppression des données des traitements précédents');
  
    DELETE FROM dka_iarrecsicm_encours_client DEC
     WHERE EXISTS
     (SELECT 'X'
              FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
             WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
               AND fcr.phase_code = 'C'
               AND fcp.concurrent_program_name =
                   'DKA_IAR_ENCOURS_REC_SICM_MEN'
               AND fcr.request_id = DEC.request_id);
  
    dka_tools_pkg.put_debug_message('==> ' || SQL%ROWCOUNT ||
                                    ' enregistrements supprimés');
  
    COMMIT;
  
    -------------------------------------------------------------------
    -- Recherche de la période en fonction de la date en entrée      --
    -------------------------------------------------------------------
    BEGIN
      pv_mois := substr(pv_periode, 1, 2);
      --< OBE artf2250006 
      /*
        If substr(Pv_Periode, 1, 1) = '0' THEN
          Pv_Mois := substr(Pv_Periode, 1, 2);
        ELSE
          Pv_Mois := substr(Pv_Periode, 2, 1);
        END IF;
      */
      --> OBE artf2250006 
      SELECT a.end_date, a.end_date + 1
        INTO pv_fin_periode, pv_fin_periode_1
        FROM gl_period_statuses a
       WHERE a.application_id = 222 --- AR
         AND a.period_year = substr(pv_periode, 4, 4) -- Année
         AND a.period_num = pv_mois
         AND rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        pv_periode := NULL;
    END;
    -----------------------------
    -- Traitement des factures --
    -----------------------------
    dka_tools_pkg.put_debug_message('Traitement des factures');
  
    -- Extraction des donnees
    OPEN cur_factures;
  
    LOOP
      FETCH cur_factures BULK COLLECT
        INTO vt_rec_factures LIMIT 100000;
    
      IF vt_rec_factures.COUNT > 0 THEN
        FOR i in vt_rec_factures.FIRST .. vt_rec_factures.LAST LOOP
        
          rec_factures := vt_rec_factures(i);
        
          vn_solde    := 0;
          vn_montant1 := nvl(rec_factures.solde_du, 0);
          vn_montant2 := 0;
          vn_montant3 := 0;
          vn_montant4 := 0;
        
          ----------------------------------------
          -- Recherche des reglements appliqués --
          ----------------------------------------
          BEGIN
            SELECT nvl(SUM(nvl(araa.acctd_amount_applied_to, 0)), 0)
              INTO vn_montant2
              FROM ar_receivable_applications_all araa
             WHERE araa.applied_customer_trx_id =
                   rec_factures.customer_trx_id
               AND araa.status = 'APP'
               AND araa.gl_date <= nvl(pv_fin_periode, SYSDATE)
               AND araa.gl_posted_date IS NOT NULL;
          END;
        
          ------------------------------------------------
          -- Cas du lettrage d'une facture par un avoir --
          ------------------------------------------------
          IF rec_factures.type_de_mouvement = 'Avoir' THEN
            BEGIN
              SELECT nvl(SUM(nvl(-araa.acctd_amount_applied_to, 0)), 0)
                INTO vn_montant3
                FROM ar_receivable_applications_all araa
               WHERE araa.customer_trx_id = rec_factures.customer_trx_id
                 AND araa.status = 'APP'
                 AND araa.gl_date <= nvl(pv_fin_periode, SYSDATE)
                 AND araa.gl_posted_date IS NOT NULL;
            END;
          END IF;
        
          -------------------------------
          -- Recherche des ajustements --
          -------------------------------
          BEGIN
            SELECT nvl(SUM(nvl(aaa.amount, 0)), 0)
              INTO vn_montant4
              FROM ar_adjustments_all aaa
             WHERE aaa.customer_trx_id = rec_factures.customer_trx_id
               AND aaa.status = 'A'
               AND aaa.gl_date <= nvl(pv_fin_periode, SYSDATE)
               AND aaa.gl_posted_date IS NOT NULL;
          END;
        
          ------------------------
          -- Calcul du solde du --
          ------------------------
          vn_solde := vn_montant1 - vn_montant2 - vn_montant3 + vn_montant4;
        
          ---------------------------------------------------------------------------------------------
          -- Si le solde du est différent de 0, on insere une ligne dans la table DKA_IARRECSICM_ENCOURS_CLIENT --
          ---------------------------------------------------------------------------------------------
          IF vn_solde <> 0 THEN
          
            -------------------------------------
            -- Recherche du Projet Majoritaire --
            -------------------------------------
            rec_factures.projet_majoritaire  := 'Pas de Projet';
            rec_factures.numero_tache_projet := 'Pas de Tache';
            rec_factures.centre_finance      := NULL;
          
            BEGIN
              IF rec_factures.task_id IS NOT NULL THEN
                SELECT ppa.segment1, pt.task_number, haou.NAME
                  INTO rec_factures.projet_majoritaire,
                       rec_factures.numero_tache_projet,
                       rec_factures.centre_finance
                  FROM pa_projects_all           ppa,
                       hr_all_organization_units /*Hr_Organization_Units*/ haou, -- OBE artf2171549
                       pa_tasks                  pt
                 WHERE ppa.project_id = to_number(rec_factures.project_id) -- OBE artf2171549
                   AND pt.task_id = to_number(rec_factures.task_id) -- OBE artf2171549
                   AND ppa.carrying_out_organization_id =
                       haou.organization_id;
              
              ELSE
                SELECT 'Pas de Projet', NULL, CASE gcc.segment6 when '0' then (select RETURN_VALUE                
                                                                 from DKA_STRANSCO_HEADERS DSH, DKA_STRANSCO_LINES DSL
                                                                 where DSH.set_id = DSL.set_id
                                                                 and DSH.set_name = 'DKA_CF_REGION_AR'
                                                                 and gcc.segment2 = DSL.PARAMS_VALUE)
                                                            ELSE gcc.segment6 END   -- BNZ : 341
                  INTO rec_factures.projet_majoritaire,
                       rec_factures.numero_tache_projet,
                       rec_factures.centre_finance
                  FROM ra_cust_trx_line_gl_dist_all rctlgda,
                       gl_code_combinations         gcc
                 WHERE rctlgda.cust_trx_line_gl_dist_id =
                       (SELECT MIN(cust_trx_line_gl_dist_id)
                          FROM ra_cust_trx_line_gl_dist_all rctlgda_1,
                               ra_customer_trx_lines_all    rctla_1
                         WHERE rctlgda_1.account_class = 'REV'
                           AND rctla_1.customer_trx_id =
                               rec_factures.customer_trx_id
                           AND rctlgda_1.customer_trx_line_id =
                               rctla_1.customer_trx_line_id
                           AND rctla_1.line_number = 1)
                   AND rctlgda.code_combination_id =
                       gcc.code_combination_id;
              
              END IF;
            
            EXCEPTION
              WHEN OTHERS THEN
                rec_factures.projet_majoritaire  := 'Pas de Projet';
                rec_factures.numero_tache_projet := 'Pas de Tache';
              --  rec_factures.centre_finance      := NULL;
			   --<Debut IBA EDB341
				select RETURN_VALUE
                into rec_factures.centre_finance 				
				from DKA_STRANSCO_HEADERS DSH, DKA_STRANSCO_LINES DSL
                where DSH.set_id = DSL.set_id
                and DSH.set_name = 'DKA_CF_REGION_AR'
               and rec_factures.uo = DSL.PARAMS_VALUE;
			   ------IBA Fin >
            END;
          
            ------------------------------------------------
            -- Recherche du nom du chargé de recouvrement --
            ------------------------------------------------
            BEGIN
              SELECT ac.NAME
              -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                INTO v_charge_recouvrement
                FROM hz_customer_profiles hcp, ar_collectors ac
               WHERE hcp.cust_account_id = rec_factures.customer_id
                 AND hcp.collector_id = ac.collector_id
                 AND hcp.site_use_id =
                     nvl(rec_factures.customer_site_use_id, hcp.site_use_id);
            
            EXCEPTION
              WHEN OTHERS THEN
                -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                v_charge_recouvrement := NULL;
            END;
          
            --------------------------------------
            -- Recherche des sous-montant       --
            --------------------------------------
            BEGIN
            
              -- 07/03/2017 NBO artf2098180 : SPE171 - Optimisation du traitement
              SELECT nvl(SUM(decode(dsl.return_value, 'P1', amount, 0)), 0) AS montant_p1,
                     nvl(SUM(decode(dsl.return_value, 'P2', amount, 0)), 0) AS montant_p2,
                     nvl(SUM(decode(dsl.return_value, 'P3', amount, 0)), 0) AS montant_p3,
                     nvl(SUM(decode(dsl.return_value, 'P4', amount, 0)), 0) AS montant_p4,
                     nvl(SUM(decode(dsl.return_value, 'P5', amount, 0)), 0) AS montant_p5,
                     nvl(SUM(decode(dsl.return_value, 'P6', amount, 0)), 0) AS montant_p6,
                     nvl(SUM(decode(dsl.return_value, 'Autre', amount, 0)),
                         0) AS montant_autres,
                     nvl(SUM(decode(dsl.return_value, '', amount, 0)), 0) AS montant_vide
                INTO rec_factures.montant_p1,
                     rec_factures.montant_p2,
                     rec_factures.montant_p3,
                     rec_factures.montant_p4,
                     rec_factures.montant_p5,
                     rec_factures.montant_p6,
                     rec_factures.montant_autres,
                     rec_factures.montant_vide
                FROM ra_cust_trx_line_gl_dist_all rct,
                     (SELECT dsl.return_value, dsl.param1_value
                        FROM dka_stransco_lines   dsl,
                             dka_stransco_headers dsh
                       WHERE dsh.set_id = dsl.set_id
                         AND dsh.set_name = 'DKA_TRANSCO_EVT_PRESTATIONS'
                         AND trunc(SYSDATE) BETWEEN
                             trunc(nvl(dsl.start_date, SYSDATE)) AND
                             trunc(nvl(dsl.end_date, SYSDATE))) dsl
               WHERE rct.customer_trx_id = rec_factures.customer_trx_id
                 AND rct.account_class = 'REV'
                 AND rct.attribute2 = dsl.param1_value(+);
            
            EXCEPTION
              WHEN OTHERS THEN
                rec_factures.montant_p1     := NULL;
                rec_factures.montant_p2     := NULL;
                rec_factures.montant_p3     := NULL;
                rec_factures.montant_p4     := NULL;
                rec_factures.montant_p5     := NULL;
                rec_factures.montant_p6     := NULL;
                rec_factures.montant_autres := NULL;
                rec_factures.montant_vide   := NULL;
            END;
          
            --------------------------------------
            -- Recherche du client destinataire --
            --------------------------------------
            BEGIN
              vv_segmentation_client       := NULL;
              vv_code_adresse_destinataire := NULL;
              vn_org_id                    := NULL; -- OBE artf2233613
              /*dka_tools_pkg.put_log_message('Récupération de l''adresse, etc du client avec les parametres Rec_Factures.Cust_Acct_Site_Id, Rec_Factures.code_client= '||
                                             Rec_Factures.Cust_Acct_Site_Id || '  '||Rec_Factures.code_client);
              
              dka_tools_pkg.put_log_message('-----Lancement de la requete 1 avec les parametres suivants : '||
                                            Rec_Factures.code_client||' ------');*/
            
              SELECT nvl(hzcustaccountsiteseoex.attribute1,
                         rec_factures.code_client),
                     REPLACE(replace (replace (ac.customer_name, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA RITM0164478 
                     REPLACE(replace (replace (lc.address1, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (replace (lc.address2, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (replace (lc.address3, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (replace (lc.address4, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(lc.postal_code, chr(59), ' '),
                     REPLACE(lc.city, chr(59), ' '),
                     REPLACE(territory_short_name, chr(59), ' '),
                     --replace(lc.attribute3, CHR(59), ' '),                    -- OBE artf2233613
                     REPLACE(hzcustaccountsiteseoex.attribute3,
                             chr(59),
                             ' '), -- OBE artf2233613
                     REPLACE(substr(ou.NAME, 0, 3), chr(59), ' '),
                     REPLACE(hzcustaccountsiteseoex.attribute2,
                             chr(59),
                             ' '),
                     hzcustaccountsiteseoex.org_id -- OBE artf2233613
                INTO rec_factures.num_client_destinataire,
                     rec_factures.client_destinataire,
                     rec_factures.adresse_1,
                     rec_factures.adresse_2,
                     rec_factures.adresse_3,
                     rec_factures.adresse_4,
                     rec_factures.code_postal,
                     rec_factures.ville,
                     rec_factures.pays,
                     rec_factures.code_adresse_payeur,
                     vv_segmentation_client,
                     vv_code_adresse_destinataire,
                     vn_org_id -- OBE artf2233613
                FROM hz_cust_accounts       h2,
                     hz_cust_acct_sites_all hzcustaccountsiteseoex,
                     hz_party_sites         ps,
                     hz_locations           lc,
                     fnd_territories_vl     terr,
                     hr_operating_units     ou,
                     ar_customers           ac
               WHERE hzcustaccountsiteseoex.cust_account_id =
                     h2.cust_account_id
                 AND hzcustaccountsiteseoex.party_site_id =
                     ps.party_site_id
                 AND ps.location_id = lc.location_id
                 AND terr.territory_code = lc.country
                 AND hzcustaccountsiteseoex.org_id = ou.organization_id
                 AND ac.customer_number = h2.account_number
                 AND h2.account_number = rec_factures.code_client
                 AND hzcustaccountsiteseoex.cust_acct_site_id =
                     rec_factures.cust_acct_site_id;
            
              --dka_tools_pkg.put_log_message('Résultat = Adresse_1:'|| Rec_Factures.adresse_1 ||' code_postal :'||Rec_Factures.code_postal);
            
            EXCEPTION
              WHEN OTHERS THEN
                rec_factures.num_client_destinataire := rec_factures.code_client;
                rec_factures.client_destinataire     := rec_factures.client;
                rec_factures.adresse_1               := NULL;
                rec_factures.adresse_2               := NULL;
                rec_factures.adresse_3               := NULL;
                rec_factures.adresse_4               := NULL;
                rec_factures.code_postal             := NULL;
                rec_factures.ville                   := NULL;
                rec_factures.pays                    := NULL;
                rec_factures.code_adresse_payeur     := NULL;
                vv_code_adresse_destinataire         := NULL;
                vv_segmentation_client               := NULL;
                vn_org_id                            := NULL; -- OBE artf2233613
            END;
          
            --------------------------------------
            -- Recherche du client payeur --
            --------------------------------------
            BEGIN
              -- 03/02/2020 MTIA artf07319784 - TASK0096648 - Correctif ajout code chargé de recouvrement - Récupération du client destinataire
              --< OBE artf2233613
              SELECT nvl(Rc_Dest.customer_number, rec_factures.code_client),
                     REPLACE(replace (replace (Rc_Dest.customer_name, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA RITM0164478 
                     REPLACE(replace (replace (lc.address1, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (replace (lc.address2, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (replace (lc.address3, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (replace (lc.address4, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(lc.postal_code, chr(59), ' '),
                     REPLACE(lc.city, chr(59), ' '),
                     REPLACE(territory_short_name, chr(59), ' '),
                     --replace(lc.attribute3, CHR(59), ' '),                    -- OBE artf2233613
                     REPLACE(hzcustaccountsiteseoex.attribute3,
                             chr(59),
                             ' '), -- OBE artf2233613
                     REPLACE(substr(ou.NAME, 0, 3), chr(59), ' '),
                     hzcustaccountsiteseoex.org_id
                INTO rec_factures.num_client_destinataire,
                     rec_factures.client_destinataire,
                     rec_factures.ad1_dest,
                     rec_factures.ad2_dest,
                     rec_factures.ad3_dest,
                     rec_factures.ad4_dest,
                     rec_factures.code_postal_dest,
                     rec_factures.ville_dest,
                     rec_factures.pays_dest,
                     rec_factures.code_adresse_dest,
                     vv_segmentation_client,
                     vn_org_id
                FROM hz_cust_acct_sites_all Ra,
                     hz_cust_acct_sites_all hzcustaccountsiteseoex,
                     ar_Customers           Rc_Dest,
                     hz_cust_site_uses_all  hcsua,
                     gl_code_combinations   gcc,
                     fnd_territories_vl     terr,
                     hz_party_sites         party_site,
                     hr_operating_units     ou,
                     hz_locations           lc
               WHERE Ra.CUST_ACCT_SITE_ID = rec_factures.cust_acct_site_id
                 AND Ra.Org_Id = rec_factures.org_id
                 and hzcustaccountsiteseoex.org_id = rec_factures.org_id
                 and hcsua.site_use_code = 'BILL_TO'
                 and hzcustaccountsiteseoex.STATUS = 'A'
                 AND Nvl(Ra.Attribute1, rec_factures.code_client) =
                     Rc_Dest.Customer_Number
                 and Rc_Dest.customer_id =
                     hzcustaccountsiteseoex.cust_account_id
                 and hcsua.CUST_ACCT_SITE_ID =
                     hzcustaccountsiteseoex.CUST_ACCT_SITE_ID
                 AND hcsua.gl_id_rec = gcc.code_combination_id
                 AND hzcustaccountsiteseoex.org_id = ou.organization_id
                 and hzcustaccountsiteseoex.party_site_id =
                     party_site.party_site_id
                 and party_site.LOCATION_ID = lc.LOCATION_ID
                 AND terr.territory_code = lc.country
                 AND hzcustaccountsiteseoex.attribute3 =
                     vv_code_adresse_destinataire
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN OTHERS THEN
                BEGIN
                  SELECT nvl(Rc_Dest.customer_number,
                             rec_factures.code_client),
                         REPLACE(replace (replace (Rc_Dest.customer_name, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA RITM0164478 
                         REPLACE(replace (replace (lc.address1, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                         REPLACE(replace (replace (lc.address2, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                         REPLACE(replace (replace (lc.address3, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                         REPLACE(replace (replace (lc.address4, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                         REPLACE(lc.postal_code, chr(59), ' '),
                         REPLACE(lc.city, chr(59), ' '),
                         REPLACE(territory_short_name, chr(59), ' '),
                         --replace(lc.attribute3, CHR(59), ' '),                    -- OBE artf2233613
                         REPLACE(hzcustaccountsiteseoex.attribute3,
                                 chr(59),
                                 ' '), -- OBE artf2233613
                         REPLACE(substr(ou.NAME, 0, 3), chr(59), ' '),
                         hzcustaccountsiteseoex.org_id
                    INTO rec_factures.num_client_destinataire,
                         rec_factures.client_destinataire,
                         rec_factures.ad1_dest,
                         rec_factures.ad2_dest,
                         rec_factures.ad3_dest,
                         rec_factures.ad4_dest,
                         rec_factures.code_postal_dest,
                         rec_factures.ville_dest,
                         rec_factures.pays_dest,
                         rec_factures.code_adresse_dest,
                         vv_segmentation_client,
                         vn_org_id
                    FROM hz_cust_acct_sites_all Ra,
                         hz_cust_acct_sites_all hzcustaccountsiteseoex,
                         ar_Customers           Rc_Dest,
                         hz_cust_site_uses_all  hcsua,
                         gl_code_combinations   gcc,
                         fnd_territories_vl     terr,
                         hz_party_sites         party_site,
                         hr_operating_units     ou,
                         hz_locations           lc
                   WHERE Ra.CUST_ACCT_SITE_ID =
                         rec_factures.cust_acct_site_id
                     AND Ra.Org_Id = rec_factures.org_id
                     and hzcustaccountsiteseoex.org_id =
                         rec_factures.org_id
                     and hcsua.site_use_code = 'BILL_TO'
                        --  and hzcustaccountsiteseoex.STATUS = 'A' MTIA 04/06/2020 ne plus filtrer sur site Actif
                     AND Nvl(Ra.Attribute1, rec_factures.code_client) =
                         Rc_Dest.Customer_Number
                     and Rc_Dest.customer_id =
                         hzcustaccountsiteseoex.cust_account_id
                     and hcsua.CUST_ACCT_SITE_ID =
                         hzcustaccountsiteseoex.CUST_ACCT_SITE_ID
                     AND hcsua.gl_id_rec = gcc.code_combination_id
                     AND hzcustaccountsiteseoex.org_id = ou.organization_id
                     and hzcustaccountsiteseoex.party_site_id =
                         party_site.party_site_id
                     and party_site.LOCATION_ID = lc.LOCATION_ID
                     AND terr.territory_code = lc.country
                     AND hzcustaccountsiteseoex.attribute3 =
                         vv_code_adresse_destinataire
                     AND ROWNUM = 1;
                EXCEPTION
                  WHEN OTHERS THEN
                    rec_factures.ad1_dest          := rec_factures.adresse_1;
                    rec_factures.ad2_dest          := rec_factures.adresse_2;
                    rec_factures.ad3_dest          := rec_factures.adresse_3;
                    rec_factures.ad4_dest          := rec_factures.adresse_4;
                    rec_factures.code_postal_dest  := rec_factures.code_postal;
                    rec_factures.ville_dest        := rec_factures.ville;
                    rec_factures.pays_dest         := rec_factures.pays;
                    rec_factures.code_adresse_dest := rec_factures.code_adresse_payeur;
                END;
            END;
            IF rec_factures.ad1_dest IS NULL AND
               vv_code_adresse_destinataire IS NULL THEN
              rec_factures.ad1_dest          := rec_factures.adresse_1;
              rec_factures.ad2_dest          := rec_factures.adresse_2;
              rec_factures.ad3_dest          := rec_factures.adresse_3;
              rec_factures.ad4_dest          := rec_factures.adresse_4;
              rec_factures.code_postal_dest  := rec_factures.code_postal;
              rec_factures.ville_dest        := rec_factures.ville;
              rec_factures.pays_dest         := rec_factures.pays;
              rec_factures.code_adresse_dest := rec_factures.code_adresse_payeur;
            
            END IF;
          
            vv_lib_uo           := NULL;
            vv_classe_client    := NULL;
            vv_categorie_client := NULL;
          
            -----------------------------------------------
            -- Recherche du libellé du centre de gestion --
            -----------------------------------------------
            vv_lib_uo := rec_factures.lib_uo;
          
            -----------------------------------
            -- Recherche de la classe client --
            -----------------------------------
            vv_classe_client := rec_factures.lib_classe_client;
          
            --------------------------------------
            -- Recherche de la catégorie client --
            --------------------------------------
            vv_categorie_client := rec_factures.lib_categorie_client;
          
            --------------------------------------
            -- Recherche du montant TTC         --
            --------------------------------------
            BEGIN
              SELECT rctlgda.amount
                INTO vn_montant_ttc
                FROM ra_cust_trx_line_gl_dist_all rctlgda,
                     ra_customer_trx_all          rcta
               WHERE rcta.customer_trx_id = rctlgda.customer_trx_id + 0
                 AND rcta.trx_number = rec_factures.num_piece
                 AND rctlgda.account_class = 'REC'
                 AND rctlgda.code_combination_id =
                     rec_factures.cle_comptable
                 AND rctlgda.customer_trx_id = rec_factures.customer_trx_id;
            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf  := SQLCODE || ' - ' || substr(SQLERRM, 1, 80);
                pn_retcode := 1;
                dka_tools_pkg.put_debug_message(pv_errbuf);
            END;
          
            --------------------------------------
            -- Recherche du montant HT         --
            --------------------------------------
            SELECT SUM(amount)
              INTO vn_montant_ht
              FROM ra_cust_trx_line_gl_dist_all rctlgda,
                   ra_customer_trx_all          rcta
             WHERE rcta.customer_trx_id = rctlgda.customer_trx_id + 0
               AND rctlgda.account_class = 'REV'
               AND rcta.trx_number = rec_factures.num_piece
               AND rctlgda.customer_trx_id = rec_factures.customer_trx_id;
          
            ------------------------------------------------
            -- Recherche du type de mouvement             --
            ------------------------------------------------
            BEGIN
              SELECT NAME
                INTO vv_type_mouvement
                FROM fnd_document_sequences fdc
               WHERE fdc.application_id = 222
                 AND fdc.doc_sequence_id = rec_factures.doc_sequence_id;
              --dka_tools_pkg.put_log_message('doc_sequence_id : '|| Rec_factures.doc_sequence_id||'Type de mouvement = ' ||vv_type_mouvement);
            
              IF (instr(translate(vv_type_mouvement,
                                  '0123456789',
                                  '          '),
                        ' _') != 0) THEN
                vv_type_mouvement := substr(vv_type_mouvement,
                                            instr(translate(vv_type_mouvement,
                                                            '0123456789',
                                                            '          '),
                                                  ' _') + 2);
              END IF;
              IF (instr(translate(vv_type_mouvement,
                                  '0123456789',
                                  '          '),
                        '_ ') != 0) THEN
                vv_type_mouvement := substr(vv_type_mouvement,
                                            0,
                                            instr(translate(vv_type_mouvement,
                                                            '0123456789',
                                                            '          '),
                                                  '_ ') - 1);
              END IF;
            
            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf  := SQLCODE || ' - ' || substr(SQLERRM, 1, 80);
                pn_retcode := 1;
                dka_tools_pkg.put_debug_message(pv_errbuf);
                vv_type_mouvement := NULL;
            END;
            --dka_tools_pkg.put_log_message('Le type de mouvement est : --'|| vv_type_mouvement||'---');
            vv_type_mouvement := dka_stransco_pkg.etl_get_value_f('DKA_TYPE_MVT_AR',
                                                                  SYSDATE,
                                                                  vv_type_mouvement);
            IF vv_type_mouvement IS NULL THEN
              pv_errbuf := 'Erreur lors de la récupération du type de mouvement pour la piece numéro : ' ||
                           rec_factures.num_piece;
              dka_tools_pkg.put_debug_message(pv_errbuf);
              pn_retcode := 1;
            ELSE
            
              ------------------------------------------------
              -- Recherche du type du montant TVA           --
              ------------------------------------------------
              SELECT MAX(zl.tax_rate)
                INTO vn_montant_tva
                FROM zx_lines zl, ra_customer_trx_all rcta
               WHERE zl.application_id = 222
                 AND zl.entity_code = 'TRANSACTIONS'
                 AND zl.event_class_code = 'INVOICE'
                 AND zl.trx_id = rec_factures.customer_trx_id
                 AND rcta.customer_trx_id = zl.trx_id + 0;
            
              --dka_tools_pkg.put_log_message('Taux de TVA récupéré :'|| vn_montant_tva);
            
              dka_tools_pkg.put_debug_message('insertion facture : ' ||
                                              rec_factures.num_piece);
              ------------------------------------------------
              -- Insertion dans la table DKA_IARRECSICM_ENCOURS_CLIENT --
              ------------------------------------------------
              INSERT INTO dka_iarrecsicm_encours_client
                (request_id,
                 code_client,
                 client,
                 date_mouvement,
                 echeance,
                 solde_du,
                 charge_recouvrement,
                 numero_tache_projet,
                 centre_finance,
                 projet_majoritaire,
                 societe,
                 num_piece,
                 classe_piece,
                 compte_client,
                 site_client,
                 num_client_destinataire,
                 client_destinataire,
                 statut,
                 type_de_mouvement,
                 montant_en_litige,
                 commentaire,
                 uo,
                 lib_uo,
                 classe_client,
                 categorie_client,
                 siret,
                 adresse_1,
                 adresse_2,
                 adresse_3,
                 adresse_4,
                 code_postal,
                 ville,
                 pays,
                 creation_date,
                 created_by,
                 identifiant_oracle,
                 montant_ttc,
                 montant_ht,
                 taux_de_tva,
                 num_cmd_alto,
                 code_adresse_payeur,
                 date_gl,
                 piece_cede,
                 date_cession,
                 montant_cede,
                 montant_p1,
                 montant_p2,
                 montant_p3,
                 montant_p4,
                 montant_p5,
                 montant_p6,
                 montant_autres,
                 montant_vide,
                 code_adresse_dest,
                 ad1_dest,
                 ad2_dest,
                 ad3_dest,
                 ad4_dest,
                 code_postal_dest,
                 ville_dest,
                 pays_dest,
				 --<Debut IBA EBD341
				 MODE_REGLEMENT,
				 AUTORISE_PRELEV
				 --IBA Fin >
				 )
              VALUES
                (rec_factures.request_id,
                 rec_factures.code_client,
                 rec_factures.client,
                 rec_factures.date_mouvement,
                 rec_factures.echeance,
                 vn_solde,
                 -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                 v_charge_recouvrement,
                 rec_factures.numero_tache_projet,
                 rec_factures.centre_finance,
                 rec_factures.projet_majoritaire,
                 rec_factures.societe,
                 rec_factures.num_piece,
                 rec_factures.classe_piece,
                 rec_factures.compte_client,
                 rec_factures.site_client,
                 rec_factures.num_client_destinataire,
                 rec_factures.client_destinataire,
                 rec_factures.statut,
                 rec_factures.type_de_mouvement,
                 nvl(rec_factures.montant_en_litige, 0), --YWA artf2080350
                 rec_factures.commentaire,
                 rec_factures.uo,
                 vv_lib_uo,
                 vv_classe_client,
                 vv_categorie_client,
                 rec_factures.siret,
                 rec_factures.adresse_1,
                 rec_factures.adresse_2,
                 rec_factures.adresse_3,
                 rec_factures.adresse_4,
                 rec_factures.code_postal,
                 rec_factures.ville,
                 rec_factures.pays,
                 SYSDATE,
                 fnd_global.user_id,
                 rec_factures.societe || '_' || vv_type_mouvement || '_' ||
                 rec_factures.doc_sequence_value,
                 vn_montant_ttc,
                 vn_montant_ht,
                 vn_montant_tva,
                 rec_factures.num_commande_alto,
                 rec_factures.code_adresse_payeur,
                 rec_factures.date_gl,
                 CASE nvl(rec_factures.date_cession, 'NULL') WHEN 'NULL' THEN
                 'NON' ELSE 'OUI' END,
                 to_date(rec_factures.date_cession, 'DD/MM/YYYY'),
                 rec_factures.montant_cede,
                 rec_factures.montant_p1,
                 rec_factures.montant_p2,
                 rec_factures.montant_p3,
                 rec_factures.montant_p4,
                 rec_factures.montant_p5,
                 rec_factures.montant_p6,
                 rec_factures.montant_autres,
                 rec_factures.montant_vide,
                 rec_factures.code_adresse_dest,
                 rec_factures.ad1_dest,
                 rec_factures.ad2_dest,
                 rec_factures.ad3_dest,
                 rec_factures.ad4_dest,
                 rec_factures.code_postal_dest,
                 rec_factures.ville_dest,
                 rec_factures.pays_dest,
				 --<Debut IBA EDB341
				 rec_factures.MODE_REGLEMENT,
				 rec_factures.AUTORISE_PRELEV
				 --IBA FIN >
				 );
            
              vn_nombre   := vn_nombre + 1;
              vn_factures := vn_factures + 1;
              --dka_tools_pkg.put_log_message('Nombre : '||vn_nombre||' nb_factures : ' ||vn_factures);
            END IF;
          END IF;
        
        END LOOP; --vt_rec_factures
      
      END IF; --vt_rec_factures.COUNT
    
      EXIT WHEN cur_factures%NOTFOUND;
    
    END LOOP;
    CLOSE cur_factures;
  
    dka_tools_pkg.put_debug_message(vn_factures ||
                                    ' factures insérées dans la table DKA_IARRECSICM_ENCOURS_CLIENT');
  
    -------------------------------
    -- Traitement des reglements --
    -------------------------------
    dka_tools_pkg.put_debug_message('Traitement des reglements');
  
    -- Extraction des donnees
    OPEN cur_reglements;
  
    LOOP
      FETCH cur_reglements BULK COLLECT
        INTO vt_rec_reglements LIMIT 100000;
    
      IF vt_rec_reglements.COUNT > 0 THEN
        FOR i in vt_rec_reglements.FIRST .. vt_rec_reglements.LAST LOOP
        
          rec_reglements := vt_rec_reglements(i);
        
          ------------------------
          -- Calcul du solde du --
          ------------------------
          vn_solde := -nvl(rec_reglements.solde_du, 0);
        
          ---------------------------------------------------------------------------------------------
          -- Si le solde du est différent de 0, on insere une ligne dans la table DKA_IARRECSICM_ENCOURS_CLIENT --
          ---------------------------------------------------------------------------------------------
          IF vn_solde <> 0 THEN
          
            ------------------------------------------------
            -- Recherche du nom du chargé de recouvrement --
            ------------------------------------------------
            dka_tools_pkg.put_debug_message('rec_reglements.customer_id=' ||
                                            rec_reglements.customer_id);
            dka_tools_pkg.put_debug_message('rec_reglements.customer_site_use_id=' ||
                                            rec_reglements.customer_site_use_id);
            BEGIN
              -- 07/03/2017 NBO artf2098180 : SPE171 - Optimisation du traitement
              SELECT ac.NAME
              -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                INTO v_charge_recouvrement
                FROM hz_cust_accounts     hca,
                     hz_customer_profiles hcp,
                     ar_collectors        ac
               WHERE hca.cust_account_id = hcp.cust_account_id
                    -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                 AND hcp.cust_account_id = rec_reglements.customer_id
                 AND hcp.collector_id = ac.collector_id
                 AND hcp.party_id = hca.party_id
                    -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                 AND (hcp.site_use_id = rec_reglements.customer_site_use_id OR
                     rec_reglements.customer_site_use_id IS NULL);
            
            EXCEPTION
              WHEN OTHERS THEN
                -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
                v_charge_recouvrement := NULL;
            END;
          
            --------------------------------------
            -- Recherche du client destinataire --
            --------------------------------------
            BEGIN
              vv_segmentation_client       := NULL;
              vv_code_adresse_destinataire := NULL;
              -----------------------------------------------------
              -- Le reglement est passé sur un site avec adresse --
              -----------------------------------------------------
            
              IF rec_reglements.customer_site_use_id IS NOT NULL THEN
                --dka_tools_pkg.put_log_message('-----Lancement de la requete avec les parametres suivants : '|| Rec_Reglements.code_client||' ------'|| Rec_Reglements.Customer_site_use_id);
                SELECT nvl(REPLACE(hzcustaccountsiteseoex.attribute1,
                                   chr(59),
                                   ' '),
                           rec_reglements.code_client), -- YWA artf2080350
                       REPLACE(replace (replace (ac.customer_name, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA RITM0164478 
                       REPLACE(hcsua.location, chr(59), ' '),
                       REPLACE(replace (replace (lc.address1, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                       REPLACE(replace (replace (lc.address2, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                       REPLACE(replace (replace (lc.address3, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                       REPLACE(replace (replace (lc.address4, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                       REPLACE(lc.postal_code, chr(59), ' '),
                       REPLACE(lc.city, chr(59), ' '),
                       REPLACE(territory_short_name, chr(59), ' '),
                       --replace(lc.attribute3, CHR(59), ' '),                     -- OBE artf2233613
                       REPLACE(hzcustaccountsiteseoex.attribute3,
                               chr(59),
                               ' '), -- OBE artf2233613
                       REPLACE(substr(ou.NAME, 0, 3), chr(59), ' '),
                       REPLACE(hzcustaccountsiteseoex.attribute2,
                               chr(59),
                               ' ')
                  INTO rec_reglements.num_client_destinataire,
                       rec_reglements.client_destinataire,
                       rec_reglements.site_client,
                       rec_reglements.adresse_1,
                       rec_reglements.adresse_2,
                       rec_reglements.adresse_3,
                       rec_reglements.adresse_4,
                       rec_reglements.code_postal,
                       rec_reglements.ville,
                       rec_reglements.pays,
                       rec_reglements.code_adresse_payeur,
                       vv_segmentation_client,
                       vv_code_adresse_destinataire
                  FROM hz_cust_accounts       h2,
                       hz_cust_acct_sites_all hzcustaccountsiteseoex,
                       hz_party_sites         ps,
                       hz_locations           lc,
                       fnd_territories_vl     terr,
                       hr_operating_units     ou,
                       ar_customers           ac,
                       hz_cust_site_uses_all  hcsua
                 WHERE hzcustaccountsiteseoex.cust_account_id =
                       h2.cust_account_id
                   AND hzcustaccountsiteseoex.party_site_id =
                       ps.party_site_id
                   AND ps.location_id = lc.location_id
                   AND terr.territory_code = lc.country
                   AND hzcustaccountsiteseoex.org_id = ou.organization_id
                   AND ac.customer_number = h2.account_number
                   AND h2.account_number = rec_reglements.code_client
                   AND hzcustaccountsiteseoex.cust_acct_site_id =
                       hcsua.cust_acct_site_id
                   AND hcsua.site_use_id =
                       rec_reglements.customer_site_use_id;
              
              ELSE
                -----------------------------------------------------
                -- Le reglement est passé sur un site sans adresse --
                -----------------------------------------------------
                --< OBE artf2233613
              
                SELECT nvl(REPLACE(hzcustaccountsiteseoex.attribute1,
                                   chr(59),
                                   ' '),
                           rec_reglements.code_client),
                       REPLACE(hcsua.location, chr(59), ' '),
                       REPLACE(replace (replace (lc.address1, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                       REPLACE(replace (replace (lc.address2, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                       REPLACE(replace (replace (lc.address3, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                       REPLACE(replace (replace (lc.address4, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048
                       REPLACE(lc.postal_code, chr(59), ' '),
                       REPLACE(lc.city, chr(59), ' '),
                       REPLACE(territory_short_name, chr(59), ' '),
                       REPLACE(lc.attribute3, chr(59), ' '),
                       REPLACE(substr(ou.NAME, 0, 3), chr(59), ' '),
                       REPLACE(hzcustaccountsiteseoex.attribute2,
                               chr(59),
                               ' ')
                  INTO rec_reglements.num_client_destinataire,
                       rec_reglements.site_client,
                       rec_reglements.adresse_1,
                       rec_reglements.adresse_2,
                       rec_reglements.adresse_3,
                       rec_reglements.adresse_4,
                       rec_reglements.code_postal,
                       rec_reglements.ville,
                       rec_reglements.pays,
                       rec_reglements.code_adresse_payeur,
                       vv_segmentation_client,
                       vv_code_adresse_destinataire
                  FROM hz_cust_accounts_all   h2,
                       hz_cust_acct_sites_all hzcustaccountsiteseoex,
                       hz_party_sites         ps,
                       hz_locations           lc,
                       fnd_territories_vl     terr,
                       hr_operating_units     ou,
                       ar_customers           ac,
                       hz_cust_site_uses_all  hcsua
                 WHERE hzcustaccountsiteseoex.cust_account_id =
                       h2.cust_account_id
                   AND hzcustaccountsiteseoex.party_site_id =
                       ps.party_site_id
                   AND ps.location_id = lc.location_id
                   AND terr.territory_code = lc.country
                   AND hzcustaccountsiteseoex.org_id = ou.organization_id
                   AND ou.organization_id = rec_reglements.org_id
                   AND ac.customer_number = h2.account_number
                   AND h2.account_number = rec_reglements.code_client
                   AND hzcustaccountsiteseoex.cust_acct_site_id =
                       hcsua.cust_acct_site_id;
                --> OBE artf2233613
              END IF;
              /*dka_tools_pkg.put_log_message('Valeurs récupérées : ' ||Rec_Reglements.Num_Client_Destinataire || ' '||
              Rec_Reglements.Client_Destinataire|| ' '||
              Rec_Reglements.Site_Client|| ' '||
              Rec_Reglements.Adresse_1);*/
            EXCEPTION
              WHEN OTHERS THEN
                --dka_tools_pkg.put_log_message('Exception rencontrée'|| SUBSTR(SQLERRM, 1, 400));
                rec_reglements.num_client_destinataire := rec_reglements.code_client;
                rec_reglements.client_destinataire     := rec_reglements.client;
                rec_reglements.site_client             := NULL;
                rec_reglements.adresse_1               := NULL;
                rec_reglements.adresse_2               := NULL;
                rec_reglements.adresse_3               := NULL;
                rec_reglements.adresse_4               := NULL;
                rec_reglements.code_postal             := NULL;
                rec_reglements.ville                   := NULL;
                rec_reglements.pays                    := NULL;
                rec_reglements.code_adresse_payeur     := NULL;
                vv_code_adresse_destinataire           := NULL;
                vv_segmentation_client                 := NULL;
            END;
          
            -------------------------------------------------------------------
            -- Recherche des informations clients destinataire sur le reglement
            --------------------------------------------------------------------
            BEGIN
            
              --dka_tools_pkg.put_log_message(Vv_code_adresse_destinataire||'   '||Rec_Reglements.customer_site_use_id||'   '||Rec_Reglements.code_client);
              --< OBE artf2233613
            
              SELECT nvl(REPLACE(Rc_Dest.customer_number, chr(59), ' '),
                         rec_reglements.code_client),
                     REPLACE(REPLACE (REPLACE (Rc_Dest.customer_name, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA RITM0164478 
                     REPLACE(replace (REPLACE (lc.address1, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (REPLACE (lc.address2, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (REPLACE (lc.address3, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                     REPLACE(replace (REPLACE (lc.address4, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048
                     REPLACE(lc.postal_code, chr(59), ' '),
                     REPLACE(lc.city, chr(59), ' '),
                     REPLACE(territory_short_name, chr(59), ' '),
                     REPLACE(ra.attribute2, chr(59), ' ')
                INTO rec_reglements.num_client_destinataire,
                     rec_reglements.client_destinataire,
                     rec_reglements.ad1_dest,
                     rec_reglements.ad2_dest,
                     rec_reglements.ad3_dest,
                     rec_reglements.ad4_dest,
                     rec_reglements.code_postal_dest,
                     rec_reglements.ville_dest,
                     rec_reglements.pays_dest,
                     rec_reglements.code_adresse_dest
                FROM hz_cust_acct_sites_all Ra,
                     hz_cust_acct_sites_all hzcustaccountsiteseoex,
                     ar_Customers           Rc_Dest,
                     hz_cust_site_uses_all  hcsua,
                     gl_code_combinations   gcc,
                     fnd_territories_vl     terr,
                     hz_party_sites         party_site,
                     hr_operating_units     ou,
                     hz_locations           lc
               WHERE Ra.CUST_ACCT_SITE_ID =
                     rec_reglements.cust_acct_site_id
                 AND Ra.Org_Id = rec_reglements.org_id
                 and hzcustaccountsiteseoex.org_id = rec_reglements.org_id
                 and hcsua.site_use_code = 'BILL_TO'
                 and hzcustaccountsiteseoex.STATUS = 'A'
                 AND Nvl(Ra.Attribute1, rec_reglements.code_client) =
                     Rc_Dest.Customer_Number
                 and Rc_Dest.customer_id =
                     hzcustaccountsiteseoex.cust_account_id
                 and hcsua.CUST_ACCT_SITE_ID =
                     hzcustaccountsiteseoex.CUST_ACCT_SITE_ID
                 AND hcsua.gl_id_rec = gcc.code_combination_id
                 AND hzcustaccountsiteseoex.org_id = ou.organization_id
                 and hzcustaccountsiteseoex.party_site_id =
                     party_site.party_site_id
                 and party_site.LOCATION_ID = lc.LOCATION_ID
                 AND terr.territory_code = lc.country
                 AND hzcustaccountsiteseoex.attribute3 =
                     vv_code_adresse_destinataire
                 AND ROWNUM = 1;
            
            EXCEPTION
              WHEN OTHERS THEN
                BEGIN
                  SELECT nvl(REPLACE(Rc_Dest.customer_number, chr(59), ' '),
                             rec_reglements.code_client),
                         REPLACE(REPLACE (REPLACE (Rc_Dest.customer_name, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA RITM0164478 
                         REPLACE(replace (REPLACE (lc.address1, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                         REPLACE(replace (REPLACE (lc.address2, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                         REPLACE(replace (REPLACE (lc.address3, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048 
                         REPLACE(replace (REPLACE (lc.address4, chr(34), ' '), chr(39), ' '), chr(59), ' '),-- SHA TASK0164048
                         REPLACE(lc.postal_code, chr(59), ' '),
                         REPLACE(lc.city, chr(59), ' '),
                         REPLACE(territory_short_name, chr(59), ' '),
                         REPLACE(ra.attribute2, chr(59), ' ')
                    INTO rec_reglements.num_client_destinataire,
                         rec_reglements.client_destinataire,
                         rec_reglements.ad1_dest,
                         rec_reglements.ad2_dest,
                         rec_reglements.ad3_dest,
                         rec_reglements.ad4_dest,
                         rec_reglements.code_postal_dest,
                         rec_reglements.ville_dest,
                         rec_reglements.pays_dest,
                         rec_reglements.code_adresse_dest
                    FROM hz_cust_acct_sites_all Ra,
                         hz_cust_acct_sites_all hzcustaccountsiteseoex,
                         ar_Customers           Rc_Dest,
                         hz_cust_site_uses_all  hcsua,
                         gl_code_combinations   gcc,
                         fnd_territories_vl     terr,
                         hz_party_sites         party_site,
                         hr_operating_units     ou,
                         hz_locations           lc
                   WHERE Ra.CUST_ACCT_SITE_ID =
                         rec_reglements.cust_acct_site_id
                     AND Ra.Org_Id = rec_reglements.org_id
                     and hzcustaccountsiteseoex.org_id =
                         rec_reglements.org_id
                     and hcsua.site_use_code = 'BILL_TO'
                        --and hzcustaccountsiteseoex.STATUS = 'A' --MTIA 04/06/2020 ne plus filtrer sur site Actif
                     AND Nvl(Ra.Attribute1, rec_reglements.code_client) =
                         Rc_Dest.Customer_Number
                     and Rc_Dest.customer_id =
                         hzcustaccountsiteseoex.cust_account_id
                     and hcsua.CUST_ACCT_SITE_ID =
                         hzcustaccountsiteseoex.CUST_ACCT_SITE_ID
                     AND hcsua.gl_id_rec = gcc.code_combination_id
                     AND hzcustaccountsiteseoex.org_id = ou.organization_id
                     and hzcustaccountsiteseoex.party_site_id =
                         party_site.party_site_id
                     and party_site.LOCATION_ID = lc.LOCATION_ID
                     AND terr.territory_code = lc.country
                     AND hzcustaccountsiteseoex.attribute3 =
                         vv_code_adresse_destinataire
                     AND ROWNUM = 1;
                EXCEPTION
                  WHEN OTHERS THEN
                    --dka_tools_pkg.put_log_message('Exception rencontrée'|| SUBSTR(SQLERRM, 1, 400));
                    rec_reglements.num_client_destinataire := rec_reglements.code_client;
                    rec_reglements.client_destinataire     := rec_reglements.client;
                    rec_reglements.ad1_dest                := rec_reglements.adresse_1;
                    rec_reglements.ad2_dest                := rec_reglements.adresse_2;
                    rec_reglements.ad3_dest                := rec_reglements.adresse_3;
                    rec_reglements.ad4_dest                := rec_reglements.adresse_4;
                    rec_reglements.code_postal_dest        := rec_reglements.code_postal;
                    rec_reglements.ville_dest              := rec_reglements.ville;
                    rec_reglements.pays_dest               := rec_reglements.pays;
                    rec_reglements.code_adresse_dest       := rec_reglements.code_adresse_payeur;
                END;
            END;
            vv_lib_uo           := NULL;
            vv_classe_client    := NULL;
            vv_categorie_client := NULL;
          
            -----------------------------------------------
            -- Recherche du libellé du centre de gestion --
            -----------------------------------------------
            vv_lib_uo := rec_reglements.lib_uo;
          
            -----------------------------------
            -- Recherche de la classe client --
            -----------------------------------
            vv_classe_client := rec_factures.lib_classe_client;
          
            --------------------------------------
            -- Recherche de la catégorie client --
            --------------------------------------
            vv_categorie_client := rec_factures.lib_categorie_client;
          
            ------------------------------------------------
            -- Insertion dans la table DKA_IARRECSICM_ENCOURS_CLIENT --
            ------------------------------------------------
            INSERT INTO dka_iarrecsicm_encours_client
              (request_id,
               code_client,
               client,
               date_mouvement,
               echeance,
               solde_du,
               charge_recouvrement,
               numero_tache_projet,
               centre_finance,
               projet_majoritaire,
               societe,
               num_piece,
               classe_piece,
               compte_client,
               site_client,
               num_client_destinataire,
               client_destinataire,
               statut,
               type_de_mouvement,
               montant_en_litige,
               commentaire,
               uo,
               lib_uo,
               classe_client,
               categorie_client,
               siret,
               adresse_1,
               adresse_2,
               adresse_3,
               adresse_4,
               code_postal,
               ville,
               pays,
               creation_date,
               created_by,
			   --<Debut IBA EDB341
			   identifiant_oracle,
			   -----IBA FIN>
               code_adresse_payeur,
               code_adresse_dest,
               ad1_dest,
               ad2_dest,
               ad3_dest,
               ad4_dest,
               code_postal_dest,
               ville_dest,
               pays_dest,
               date_gl,
               piece_cede, --YWA artf2080350
			   MODE_REGLEMENT --IBA EDB341
               )
            VALUES
              (rec_reglements.request_id,
               rec_reglements.code_client,
               rec_reglements.client,
               rec_reglements.date_mouvement,
               rec_reglements.echeance,
               vn_solde,
               -- 25/10/2019 NBO artf07319354 : INCXXXX - Dans le fichier quotidien ENCOURS_RECOUVREMENT, les pièces de type Règlement n'ont pas de Code Chargé de recouvrement renseigné  
               v_charge_recouvrement,
               rec_reglements.numero_tache_projet,
               rec_reglements.centre_finance,
               rec_reglements.projet_majoritaire,
               rec_reglements.societe,
               rec_reglements.num_piece,
               rec_reglements.classe_piece,
               rec_reglements.compte_client,
               rec_reglements.site_client,
               rec_reglements.num_client_destinataire,
               rec_reglements.client_destinataire,
               rec_reglements.statut,
               rec_reglements.type_de_mouvement,
               nvl(rec_reglements.montant_en_litige, 0), --YWA artf2080350
               rec_reglements.commentaire,
               rec_reglements.uo,
               vv_lib_uo,
               vv_classe_client,
               vv_categorie_client,
               rec_reglements.siret,
               rec_reglements.adresse_1,
               rec_reglements.adresse_2,
               rec_reglements.adresse_3,
               rec_reglements.adresse_4,
               rec_reglements.code_postal,
               rec_reglements.ville,
               rec_reglements.pays,
               SYSDATE,
               fnd_global.user_id,
			    --<Debut IBA EDB341
			   rec_reglements.societe || '_RGT_' ||rec_reglements.cash_receipt_id,
			   ---iba Fin >
               rec_reglements.code_adresse_payeur,
               rec_reglements.code_adresse_dest,
               rec_reglements.ad1_dest,
               rec_reglements.ad2_dest,
               rec_reglements.ad3_dest,
               rec_reglements.ad4_dest,
               rec_reglements.code_postal_dest,
               rec_reglements.ville_dest,
               rec_reglements.pays_dest,
               rec_reglements.gl_date,
               CASE nvl(rec_reglements.date_cession, 'NULL') WHEN 'NULL' THEN
               'NON' ELSE 'OUI' END, --YWA artf2080350
			   rec_reglements.MODE_REGLEMENT --IBA EDB341
               );
          
            vn_nombre     := vn_nombre + 1;
            vn_reglements := vn_reglements + 1;
          
          END IF;
        
        END LOOP; --vt_rec_reglements
      
      END IF; --vt_rec_reglements.COUNT
    
      EXIT WHEN cur_reglements%NOTFOUND;
    
    END LOOP;
    CLOSE cur_reglements;
  
    dka_tools_pkg.put_debug_message(vn_reglements ||
                                    ' reglements insérés dans la table DKA_IARRECSICM_ENCOURS_CLIENT');
  
    COMMIT;
  
    BEGIN
    
      dka_tools_pkg.put_debug_message('Recuperation du demandeur :');
      dka_tools_pkg.put_debug_message('Requested_By : ' ||
                                      fnd_profile.VALUE('USER_ID'));
    
      SELECT user_name
        INTO vv_requested_by
        FROM fnd_user
       WHERE user_id = fnd_profile.VALUE('USER_ID');
    
      dka_tools_pkg.put_debug_message('Requested_By : ' || vv_requested_by);
    
    EXCEPTION
      WHEN no_data_found THEN
        dka_tools_pkg.put_debug_message('PROBLEME RECUPERATION REQUESTED BY');
        vv_requested_by := 'EXPLOITATION';
      
    END;
  
    --<! SFA  :  artf07290465
  
    SELECT period_name, to_char(end_date, 'YYYYMM')
      INTO vv_period_name, vv_end_date
      FROM gl_periods
     WHERE END_date =
           (SELECT min(start_date) - 1
              FROM PER_SECURITY_PROFILES_V      pspv,
                   PER_SECURITY_ORGANIZATIONS_V psov,
                   hr_operating_units           hou,
                   gl_ledgers                   gl,
                   gl_period_statuses           gls
             WHERE pspv.security_profile_id =
                   fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL')
               AND pspv.security_profile_id = psov.security_profile_id
               AND hou.organization_id = psov.organization_id
               AND hou.set_of_books_id = gl.ledger_id
               AND gls.application_id = 222
               AND gls.closing_status = 'O'
               AND gls.set_of_books_id = gl.ledger_id)
       AND period_set_name = 'GROUPE';
  
    --fin modification SFA  :   artf07290465 -->--
  
    IF (vv_requested_by = 'EXPLOITATION') THEN
      ------------------------
      -- Edition du fichier --
      ------------------------
      dka_tools_pkg.put_debug_message('Edition du fichier');
    
      vv_filename := 'ENCOURS_RECOUVREMENT_MEN_'; --YWA artf2079730
      -----------------------------------------
      -- Recherche du fichier de destination --
      -----------------------------------------
      IF nvl(pv_periode, 'NULL') != 'NULL' AND
         nvl(pv_region, 'NULL') != 'NULL' THEN
        vv_filename := vv_filename ||
                       to_char(to_date(pv_periode, 'MM/YYYY'), 'YYYYMM') || '_' ||
                       pv_region || '_' || to_char(SYSDATE, 'YYYYMMDD') ||
                       '.csv';
      ELSIF nvl(pv_periode, 'NULL') != 'NULL' AND
            nvl(pv_region, 'NULL') = 'NULL' THEN
        vv_filename := vv_filename ||
                       to_char(to_date(pv_periode, 'MM/YYYY'), 'YYYYMM') || '_' ||
                       to_char(SYSDATE, 'YYYYMMDD') || '.csv';
      ELSIF nvl(pv_periode, 'NULL') = 'NULL' AND
            nvl(pv_region, 'NULL') != 'NULL' THEN
        vv_filename := vv_filename || pv_region || '_' ||
                       to_char(SYSDATE, 'YYYYMMDD') || '.csv';
      ELSE
        --<! SFA  :  artf07290465
        /*vv_filename := vv_filename || to_char(SYSDATE,
        'YYYYMMDD') || '.csv';*/
        vv_filename := vv_filename || vv_end_date || '.csv';		 
        --fin modification SFA  :  artf07290465 -->--                          
      END IF;
    
      --------------------------------------------------------
      -- Recherche du répertoire de destination du fichier. --
      --------------------------------------------------------
      SELECT dd.directory_path
        INTO vv_directory_name
        FROM dba_directories dd
       WHERE dd.directory_name = 'DKA_OUT_DIR';
    
      ---------------------------------------------------
      -- Vérifie que le fichier n'est pas déja ouvert. --
      ---------------------------------------------------
      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fermeture du fichier pour l''extraction RA.');
        --------------------------
        -- fermeture du fichier --
        --------------------------
        utl_file.fclose(va_file_id);
        dka_tools_pkg.put_log_message('  fichier fermé');
      END IF;
    
      -------------------------------------------
      -- Ouverture du fichier en Mode Ecriture --
      -------------------------------------------
      va_file_id := utl_file.fopen(cv_directory, vv_filename, 'w',5000); -- IBA  KDFI-1209
    
      ------------------------------------------------------------
      -- Vérifie que l'on a bien ouvert le fichier en écriture. --
      ------------------------------------------------------------
      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fichier ' || vv_directory_name || '/' ||
                                      vv_filename || ' ouvert en écriture');
      ELSE
        RAISE e_file;
      END IF;
    
      ---------------------------------------------------------------------
      -- Parcours du curseur contenant les différentes lignes a insérer. --
      ---------------------------------------------------------------------
      FOR rec_fichier IN cur_fichier LOOP
      
        --dka_tools_pkg.put_log_message('ligne :' || Rec_Fichier.Ligne1);
      
        vv_buffer      := rec_fichier.ligne1 || rec_fichier.ligne2 ||
                          rec_fichier.ligne3;
        vn_buffer_size := length(vv_buffer);
      
        IF vn_buffer_size > 1023 THEN
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          vv_buffer := rec_fichier.ligne1 ||
                       substr(rec_fichier.ligne2,
                              0,
                              length(rec_fichier.ligne2) -
                              (length(vv_buffer) - 1023)) ||
                       rec_fichier.ligne3;
        
          utl_file.put_line(va_file_id, vv_buffer);
        
          --dka_tools_pkg.put_log_message('Ancienne taille de la chaine :' || vn_buffer_size);
          --dka_tools_pkg.put_log_message('Nouvelle taille de la chaine :' || length(vv_buffer));
        
        ELSE
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans le fichier --
          ------------------------------------------------------
          utl_file.put_line(va_file_id, vv_buffer);
        END IF;
      END LOOP;
    
      ---------------------------------------
      -- Fermeture du fichier en écriture. --
      ---------------------------------------
      utl_file.fclose(va_file_id);
    
    ELSE
    
      ---------------------------------------------------------------------
      -- Parcours du curseur contenant les différentes lignes a insérer. --
      ---------------------------------------------------------------------
      FOR rec_fichier IN cur_fichier LOOP
      
        --dka_tools_pkg.put_log_message('ligne :' || Rec_Fichier.Ligne1);
        vv_buffer      := rec_fichier.ligne1 || rec_fichier.ligne2 ||
                          rec_fichier.ligne3;
        vn_buffer_size := length(vv_buffer);
      
        IF vn_buffer_size > 1023 THEN
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans la sortie  --
          ------------------------------------------------------
          vv_buffer := rec_fichier.ligne1 ||
                       substr(rec_fichier.ligne2,
                              0,
                              length(rec_fichier.ligne2) -
                              (length(vv_buffer) - 1023)) ||
                       rec_fichier.ligne3;
        
          fnd_file.put_line(fnd_file.output, vv_buffer);
        
          --dka_tools_pkg.put_log_message('Ancienne taille de la chaine :' || vn_buffer_size);
          --dka_tools_pkg.put_log_message('Nouvelle taille de la chaine :' || length(vv_buffer));
        
        ELSE
          ------------------------------------------------------
          -- Insertion de la ligne du curseur dans la sortie  --
          ------------------------------------------------------
          fnd_file.put_line(fnd_file.output, vv_buffer);
        END IF;
      END LOOP;
    
    END IF;
  
    -------------------------------------------
    -- Suppression des données du traitement --
    -------------------------------------------
    /*Dka_Tools_Pkg.Put_Debug_Message('Suppression des données du traitement');
    DELETE FROM DKA_IARRECSICM_ENCOURS_CLIENT Dec
     WHERE Dec.Request_Id = Fnd_Global.Conc_Request_Id;
    
    Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT ||
                                    ' enregistrements supprimés');
    
    COMMIT;
    */
  
    dka_tools_pkg.put_debug_message('==> Fin du traitement');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLCODE || ' - ' || substr(SQLERRM, 1, 80);
      pn_retcode := 2;
    
  END extraction_encours;

END dka_iarrecsicm_men_pkg;
/
SHOW ERRORS
EXIT
