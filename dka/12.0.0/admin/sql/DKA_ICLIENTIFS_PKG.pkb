CREATE OR REPLACE PACKAGE BODY dka_iclientifs_pkg AS
  -------------------------------------------------------------------------------
  -- CAP GEMINI ERNST AND YOUNG
  -- Projet          : DALKIA Oracle Applications
  -- Auteur        : Bertrand RENAUDIN
  -- Date Création    :
  -- Version livrables : V01
  --------------------------------------------------------------------------------
  -- NOM            : dka_ICLIENTIFS_PKG.sql
  -- DESCRIPTION       : Package
  --------------------------------------------------------------------------------

  --------------------------- M O D I F I C A T I O N S -------------------------
  -- Date                : 28/10/2021
  -- Auteur              : Saloua HAHIOUI 
  -- Description         : SHA - artf07468996 - EDB305 - DPE20210028 - INT005 - DESACTIVER LES ADRESSES D’UN ETABLISSEMENT DESACTIVE
  -------------------------------------------------------------------------
  -- Date                : 05/11/2019
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf07233449 - EDB242 - DGE20190012 - OracleR12_Finance_AR_Import factures client_Duplication automatique site client  
  --
  -------------------------------------------------------------------------
  -- Date                : 29/10/2019
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf07319790  - TASK0096649 - Correction sites sans profil suite transfert région 
  --
  -------------------------------------------------------------------------
  -- Date                : 12/09/2019
  -- Auteur              : Jerome WYCKAERT
  -- Description         : artf07306014 - INC0344864 - correction en cas de doublons chargé recouvrement / cdg
  --
  -------------------------------------------------------------------------
  -- Date                : 01/04/2019
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf07234729 - INC0225987 - chargé de recouvrement du client ne remonte pas
  --
  -------------------------------------------------------------------------
  -- Date                : 26/09/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf3034049 : INC0250675 - Une correction de la table des rejets (AR) est nécessaire afin de supprimer les lignes qui sont rejouées afin que les rejets ne soient pas bloqués après correction en amont (action à réaliser dans la foulée de l'état des lieux)
  --
  -------------------------------------------------------------------------
  -- Date                : 16/07/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2876887 - TASK0061020 - Faire évoluer l'interface SIC pour utiliser le nom1 au lieu de customer_name.
  --
  -------------------------------------------------------------------------
  -- Date                : 27/04/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
  --
  -------------------------------------------------------------------------
  -- Date                : 25/04/2018
  -- Auteur              : Maxime EGOT
  -- Description         : Optimisation
  --
  -------------------------------------------------------------------------
  -- Date                : 24/04/2018
  -- Auteur              : Oussama BENHAYOUN
  -- Description         : artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
  --
  -------------------------------------------------------------------------
  -- Date                : 19/04/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2546656 : INC0211379 - Le traitement "DKA : Import des clients : Pre Open Interface" de la nuit applicative du 18/04/2018 s'est terminé en erreur (request id = 3231777)
  --
  -------------------------------------------------------------------------
  -- Date                : 11/04/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2356814 : INC0187177 : Demande assistance nettoyage table client
  --
  -------------------------------------------------------------------------
  -- Date                : 27/03/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2459074 : INC0202251 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
  --
  -------------------------------------------------------------------------
  -- Date                : 13/03/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
  --
  -------------------------------------------------------------------------
  -- Date                : 21/02/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2390981 - INC0192034 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE ACHAT
  --
  -------------------------------------------------------------------------
  -- Date                : 25/01/2018
  -- Auteur              : Nicolas BOUSSEKEYT
  -- Description         : artf2310607 - INC0180336 :  erreurs à l'import des clients.
  --
  -------------------------------------------------------------------------
  -- Date                : 25/05/2017
  -- Auteur              : Younes WARID
  -- Description         : YWA artf2184345 : INT005 - Contrôle d'organisation active - defect Bout_enBout_Helios_Ref #850
  --
  -------------------------------------------------------------------------
  -- Date                : 25/05/2017
  -- Auteur              : Younes WARID
  -- Description         : YWA artf2154954,artf2158785
  --
  -------------------------------------------------------------------------
  -- Date                : 04/05/2017
  -- Auteur              : Younes WARID
  -- Description         : YWA artf2149045
  --
  -------------------------------------------------------------------------
  -- Date                : 28/04/2017
  -- Auteur              : Younes WARID
  -- Description         : YWA artf2147025
  --
  -------------------------------------------------------------------------
  -- Date                : 31/03/2017
  -- Auteur              : eflass
  -- Description         : artf2110194 (Suite): Performance - Modification de la procedure post_OI
  --
  -------------------------------------------------------------------------
  -- Date                : 20/03/2017
  -- Auteur              : eflass
  -- Description         : artf2110194: Soumission du traitement RACUST pour tous les orgs
  --
  -------------------------------------------------------------------------
  -- Date                : 15/02/2017
  -- Auteur              : Redouane BELAYACHI
  -- Description         : Evolution EDB046 artf2100712 et Correctif artf2102500
  --
  -------------------------------------------------------------------------
  -- Date                : 16/11/2016
  -- Auteur              : Oussama BENHAYOUN
  -- Description         : Correctif artf2045644
  --
  -------------------------------------------------------------------------
  -- Date                : 09/05/2016
  -- Auteur              : Younes WARID
  -- Description         : Migration R12
  --
  -------------------------------------------------------------------------
  -- Date                : 09/02/2011
  -- Auteur              : Franck MICHEL
  -- Description         : DPE20105002 :Modif interface SIC/AR
  --                       Ajout du siret dans AR.
  --                       On met à jour le champ Attribute11 avec le num_siret de la table dka_iclientifs_interface
  --                       recherche modif DPE20105002
  -------------------------------------------------------------------------
  -- Date                : 17/12/2007
  -- Auteur              : J.VIEVILLE
  -- Description         : EARS00007844264 : gestion des relations payeurs-destinataires
  --                       On met à jour les relations pour tous les clients interfacés
  -------------------------------------------------------------------------
  -- Date                : 24/10/2007
  -- Auteur              : J.VIEVILLE
  -- Description         : Evolution DQM : ajout du statut 'M'(Merge)
  --                       et gestion de 2 nouvelles infos (num et adresse fusionnant)
  -------------------------------------------------------------------------
  -- Date                : 29/03/2007
  -- Auteur              : J.VIEVILLE
  -- Description         : EARS00007368651 : Modification du calcul de l'id de l'adresse destinataire
  --                       Quand le cdg n'existe pas sur le destinataire on prend l'id de l'adresse la plus ancienne
  -------------------------------------------------------------------------
  -- Date                : 02/03/2007
  -- Auteur              : J.VIEVILLE
  -- Description         : EARS00007354065 : Modification de la gestion de changement de destinataire
  --                       quand passage d'un destinataire à pas de destinataire
  --                       => désactivation de la relation avec l'ancien
  -------------------------------------------------------------------------
  -- Date                : 05/10/2006
  -- Auteur              : J.VIEVILLE
  -- Description         : Propagation des infos sur les sites déjà existants
  -------------------------------------------------------------------------
  -- Date                : 07/02/2006
  -- Auteur              : E.BLONDEEL
  -- Description         : Ajout d'un controle dans GLOBAL_CONTROL
  -------------------------------------------------------------------------
  -- Date                : 27/09/2005
  -- Auteur              : J.VIEVILLE
  -- Description         : Adaptation de l'interface pour ne plus utiliser la duplication client
  --       Création dans CRM d'un chargé de recouvrement par centre de gestion devant être dupliqué
  --       Modification : curseur cur_ifs, alim_OI, pré_OI
  -------------------------------------------------------------------------
  -- Date                : 05/07/2005
  -- Auteur              : J.VIEVILLE
  -- Description         : Projet PHENIX : modification de l'appel à la fonction address_exists (avec paramètre CDG-Ref Anael)
  --                     comme on insert maintenant le couple CDG-Ref Anael, on regarde si ce dernier existe
  -------------------------------------------------------------------------
  -- Date                : 04/07/2005
  -- Auteur              : SOPRA
  -- Description         : Projet PHENIX : Migration
  --                       Impacts sur: alim_oi, address_exists, post_oi, update_gl_id, pre_oi
  -------------------------------------------------------------------------
  -- Date                : 15/03/2005
  -- Auteur              : J.VIEVILLE
  -- Description         : Modification procédure get_collector_from_cust_cdg
  --       ajout d'un chargé de recouvrement par défaut par région
  -------------------------------------------------------------------------
  -- Date                : 23/02/2005
  -- Auteur              : E.MATUSZEWSKI
  -- Description         : Prise en compte du paramètre supplémentaire p_debug_flag dans la procédure compile_hierarchy
  --                       suite au passage du patch 3582622
  --------------------------------------------------------------------------
  -- Date                : 17-06-2004
  -- Auteur              : SFE
  -- Description         : Projet PHENIX 2004: Migration
  --                       Impacts sur: global_control, get_gl_id, init, duplicate_addr, post_OI.
  --------------------------------------------------------------------------
  -- Date                : 08/07/2004
  -- Auteur              : J.VIEVILLE
  -- Description         : (PHENIX 2004)Dans Pre_OI : ajout d'un distinct dans la requête de gestion client payeur/destinataire.
  --------------------------------------------------------------------------
  -- Date                : 04/06/2004
  -- Auteur              : J.VIEVILLE
  -- Description         : (PHENIX 2004)Dans Pre_OI : ne pas supprimer les lignes dka_iclientifs_collectors
  --                       afin de permettre la propagation des chargés de recouvrement lors de
  --                       duplication client.
  --------------------------------------------------------------------------
  -- Date                : 19/02/2004
  -- Auteur              : J.VIEVILLE
  -- Description         : Pre_OI Suppression des clients Gerrico dans dka_iclientifs_collectors
  --                       Pre_OI Suppression des lignes dka_iclientifs_collectors avec un oa_status = 'A'
  --                       Post_OI Suppression des lignes dka_iclientifs_interface
  --                       avec oa_status = 'P'
  ---------------------------------------------------------------------------
  -- Date                : 01/12/2003
  -- Auteur              : J.VIEVILLE
  -- Description         : Modif de la procédure PRE OI
  --                          --> Gestion du lien entre un client payeur et son destinataire
  ---------------------------------------------------------------------------
  -- Date                : 20-10-2003
  -- Auteur              : J.VIEVILLE
  -- Description         : Modif des procédures PRE OI et POST OI
  --                          --> Stockage du status du client(Payeur, destinataire) dans la proc PRE_OI
  --         pour une mise à jour dans POST_OI
  ---------------------------------------------------------------------------
  -- Date                : 27-03-2003
  -- Auteur              : E. BLONDEEL
  -- Description         : Modif de la procedure duplicate_addr
  --                          --> Ajout d'initialisations pour lancer la procedure en manuel
  ---------------------------------------------------------------------------

  -- Date                : 18-02-2003
  -- Auteur              : E. Flass
  -- Description         : Modif IFS pour probleme du NOM (Action 85)
  --                          --> Modif de l'alimentation du champ CUSTOMER_NAME et CUSTOMER_KEY
  ---------------------------------------------------------------------------
  -- Date                : 12-02-2003
  -- Auteur              : E. Flass
  -- Description         : Modif IFS pour probleme du NOM (Action 85)
  --                           --> Modif de l'alimentation des champs adresses, nom et customer_key
  --                               dans la table RA_CUSTOMERS_INTERFACE_ALL
  --                           --> Modif du CUSTOMER_NAME passe a la procedure insert_client_gl
  ---------------------------------------------------------------------------
  -- Date                : 24-10-2002
  -- Auteur              : BER
  -- Description         : duplicate_addr : correction bug de violation contrainte unique
  ---------------------------------------------------------------------------
  -- Date                : 16-10-2002
  -- Auteur              : BER
  -- Description         : Post_oi : Ajout de la coche de la case "Fact." dans l'onglet Relations du panneau client
  ------------------------------------------------------------------------------
  -- Date                : 15-10-2019
  -- Auteur              : NBO
  -- Description         : artf07315378 - INC0354606 - Problème de clé comptable dans l'import des clients
  ------------------------------------------------------------------------------
  -- Date                : 08-01-2020
  -- Auteur              : JWY
  -- Description         : artf07432057 - INC0499580 - Problème alimentation du champ LOCATION dans le cadre de mises à jour
  ------------------------------------------------------------------------------

  -- Variables Globales
  gv_buf        VARCHAR2(2000); --buffer d erreur
  gn_ret        NUMBER; --code retour erreur
    gn_request_id NUMBER :=Fnd_Global.conc_request_id; --request_id du traitement courant
  erreur EXCEPTION; --Erreur fatale du programme

  gv_segment4_client_partner  VARCHAR2(40); --Compte groupe client avec code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....
  gv_segment4_client          VARCHAR2(40); --Compte groupe client sans code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....
  gv_segment4_produit_partner VARCHAR2(40); --Compte groupe produit avec code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....
  gv_segment4_produit         VARCHAR2(40); --Compte groupe produit sans code partenaire -- PHENIX 2004:  gv_segment2... -> gv_segment4....

  gv_segment3_client_partner  VARCHAR2(40); --Compte local client avec code partenaire
  gv_segment3_client          VARCHAR2(40); --Compte local client sans code partenaire
  gv_segment3_produit_partner VARCHAR2(40); --Compte local produit avec code partenaire
  gv_segment3_produit         VARCHAR2(40); --Compte local produit sans code partenaire

  --gv_default_society      VARCHAR2(40); --Code de la societe par defaut sur laquelle est lancee l open interface --R12 migration YWA
  gv_default_cdg       VARCHAR2(40); --Code du centre de gestion par defaut
  gv_default_collector VARCHAR2(40); --Code du charge de recouvrement par defaut
  --gn_default_invoice_copy NUMBER; --Nombre d exemplaire de facture par defaut --R12 migration YWA

  gv_type_org_soc            VARCHAR2(40); --Type de l organisation correspondant a la liste des code societe
  gv_dunning_letter_set_name VARCHAR2(30); --Nom du jeu de lettre de relance
  gv_grouping_rule_name      VARCHAR2(40); --Nom de la regle de regroupement
  --gv_profile_class_group     VARCHAR2(40); --Nom de la classe de profil groupe -- YWA R12
  gv_gerrico_category VARCHAR2(40); --Code de la categorie de client Gerrico */--YWA

  gn_flex_set_id_soc NUMBER; --Identifiant du segment1 de la clef flexible -- PHENIX 2004: gn_flex_set_id_cg_soc -> gn_flex_set_id_soc.
  gn_flex_set_id_cdg NUMBER; --Identifiant du segment2 de la clef flexible  -- PHENIX 2004: Ajout.

  gv_code_destinataire VARCHAR(8); --variable contenant  l'ancien code destinataire à mettre à jour
  gv_attribute7        NUMBER; --JVI 29/03/2007EARS00007368651

  g_org_id NUMBER; --YWA

  -- Curseurs
  --Boucle sur les enregistrements clients corrects
  --JV 26/09/2005 : la duplication client ayant été retiré :
  --le curseur recupère toutes les cdg dans la table des collectors
  CURSOR cur_ifs IS
    SELECT dii.*,
           decode(dic.customer_number, NULL, gv_default_cdg, dic.cdg) cdg_cdr --ceux n'étant pas dans la tables des collectors on le cdg par défaut
    FROM   DKA_ICLIENTIFS_INTERFACE  dii,
           DKA_ICLIENTIFS_COLLECTORS dic
     WHERE dii.oa_status = 'P'
       AND decode(dic.customer_number, NULL, gv_default_cdg, dic.cdg) IN
           (SELECT flex_value
              FROM fnd_flex_values
             WHERE flex_value_set_id = gn_flex_set_id_cdg) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
       AND dic.customer_number(+) = dii.customer_number
    UNION
    SELECT dii.*,
           gv_default_cdg cdg_cdr
    --mettre le cdg par défaut pour ceux dont le cdg de la table collector n'existe pas dans le jeu de valeur
    FROM   DKA_ICLIENTIFS_INTERFACE  dii,
           DKA_ICLIENTIFS_COLLECTORS dic
     WHERE dii.oa_status = 'P'
       AND decode(dic.customer_number, NULL, gv_default_cdg, dic.cdg) NOT IN
           (SELECT flex_value
              FROM fnd_flex_values
             WHERE flex_value_set_id = gn_flex_set_id_cdg)
       AND dic.customer_number(+) = dii.customer_number;


  --Boucle sur les enregistrements clients en rejet
  CURSOR cur_ifs_reject IS
    SELECT *
    FROM   DKA_ICLIENTIFS_INTERFACE
    WHERE  oa_status = 'R';

  --Boucle sur les enregistrements de charge de recouvrement en rejet
  CURSOR cur_ifs_collector_reject IS
    SELECT *
    FROM   dka_ICLIENTIFS_COLLECTORS
    WHERE  OA_status = 'R';

  --Liste les reference Anael qui ont ete traitees
  -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
  CURSOR cur_anael_ref IS
    SELECT ref_address,
           (SELECT organization_id
              FROM hr_operating_units
             WHERE NAME = cdg || soc
            AND sysdate  between date_from and nvl(date_to,sysdate) --YWA artf2184345
            ) org_id,
           t.cust_acct_site_id
    FROM   dka_iclientifs_interface dii,
           hz_cust_acct_sites_all t
     WHERE dii.oa_status = 'P'
       AND t.orig_system_reference = dii.ref_address --selection des sites de cette reference ANAEL
      AND  t.org_id = (select organization_id
              FROM hr_operating_units
             WHERE NAME = cdg || soc
            AND sysdate  between date_from and nvl(date_to,sysdate) --YWA artf2184345
            )
    UNION
    -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
    SELECT DISTINCT cas.attribute3 ref_address,
                    cas.org_id,
                    cas.cust_acct_site_id
      FROM dka_iclientifs_collectors dic,
           hz_cust_acct_sites_all    cas,
           hz_cust_accounts_all      ca
     WHERE dic.oa_request_id = gn_request_id
       AND dic.customer_number = ca.account_number
       AND ca.cust_account_id = cas.cust_account_id;

  -----------------------------------------------------------------------------
  --        PROCEDURES ET FONCTIONS PRIVEES
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  --  Nom           : alim_OI
  --  Description   : alimente les tables d open interface client
  --                   RA_CUSTOMERS_INTERFACE_ALL
  --                   RA_CUSTOMER_PROFILES_INTERFACE
  --
  --  PARAMETRES    :
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------
  PROCEDURE alim_oi IS
  BEGIN
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('Debut Alimentation Open Interface...');
  
    -- Alimentation des tables d' Open Interface Standard.
  
    --Insertion des informations d entete et d adresses
    dka_tools_pkg.put_outdebug_message('Insertion des informations d entete et d adresses');
  
    -- 26/09/2018 - Nicolas BOUSSEKEYT - artf3034049 : INC0250675 - Une correction de la table des rejets (AR) est nécessaire afin de supprimer les lignes qui sont rejouées afin que les rejets ne soient pas bloqués après correction en amont (action à réaliser dans la foulée de l'état des lieux)
    DELETE FROM ra_customers_interface_all
     WHERE customer_number IN (SELECT customer_number
                                 FROM dka_iclientifs_interface
                                WHERE oa_status = 'P'
                                  AND insert_update_flag IS NOT NULL
                                  AND cdg IS NOT NULL);
  
        Dka_Tools_Pkg.put_debug_message('Nombre de lignes supprimés : ' || SQL%ROWCOUNT);
  
    INSERT INTO ra_customers_interface_all
      (address_attribute1,
       address_attribute2,
       address_attribute3, --reference ancien systeme
       --ADDRESS_ATTRIBUTE4, --nb exemplaire fact --R12 migration YWA
       --ADDRESS_ATTRIBUTE5, --euribor --R12 migration YWA
       address1,
       address2,
       address3,
       address4,
       city,
       country,
       created_by,
       creation_date,
       cust_tax_reference, --num intracom
       address_attribute8, -- code partenaire --YWA MIGRATION R12
       customer_category_code,
       customer_class_code,
       customer_key, --customer_name en maj
       customer_name,
       customer_number,
       customer_status, -- A actif
       customer_type, -- I interne / R externe
       gl_id_rec,
       gl_id_rev,
       insert_update_flag,
       last_updated_by,
       last_update_date,
       location, -- CdG + ref ANAEL ou address_identity ==> migration R12 ref ANAEL ou address_identity --YWA
       org_id,
       orig_system_address_ref,
       orig_system_customer_ref,
       orig_system_parent_ref, -- client lié ?
       postal_code,
       primary_site_use_flag,
       site_use_code)
      SELECT code_client_destinataire,
             adresse_client_destinataire,
             ref_address,
             --NVL(invoice_copy, TO_CHAR(gn_default_invoice_copy)),--R12 migration YWA
             --euribor,--R12 migration YWA
             nom1,
             nom2,
             address1,
             address2,
             city,
             country,
             fnd_global.user_id,
             SYSDATE,
             intracom_number,
             partner_code,
             customer_category,
             customer_class,
-- 16/07/2018 - NBO - artf2876887 - TASK0061020 - Faire évoluer l'interface SIC pour utiliser le nom1 au lieu de customer_name.
             --UPPER(CUSTOMER_NAME),
             upper(nom1),
             --CUSTOMER_NAME,
             nom1,
             customer_number,
             'A', --SHA EDB305
			 --decode(customer_status, 'M', 'I', customer_status), --JVI 24/10/2007
             decode(customer_class, 'GROUPE_INTERNE', 'I', 'R'), --Si groupe => interne , sinon => externe
             gl_id_rec,
             gl_id_rev,
			 -- 05/11/2019 - NBO - artf07233449 - EDB242 - DGE20190012 - OracleR12_Finance_AR_Import factures client_Duplication automatique site client  
             -- 29/10/2019 - NBO - artf07319790  - TASK0096649 - Correction sites sans profil suite transfert région 
             (SELECT decode(COUNT(1), 0, 'I', NULL, 'I', 'U')
                FROM hz_customer_profiles   hcp,
                     hz_cust_accounts       hcu,
                     hz_cust_acct_sites_all cas,
                     hz_cust_site_uses_all  csu
               WHERE hcu.account_number = customer_number
                 AND hcu.cust_account_id = hcp.cust_account_id
                 AND hcp.site_use_id = csu.site_use_id
                 AND cas.attribute3 = ref_address
                 AND cas.org_id = (SELECT organization_id
                                     FROM hr_operating_units
                                    WHERE NAME = cdg || soc
                                      AND SYSDATE BETWEEN date_from AND
                                          nvl(date_to, SYSDATE) --YWA artf2184345
                                   )
                 AND csu.cust_acct_site_id = cas.cust_acct_site_id
                 AND csu.site_use_code = 'BILL_TO'
                 AND hcu.cust_account_id = cas.cust_account_id) insert_update_flag,
             fnd_global.user_id,
             SYSDATE,
			 -- 05/11/2019 - NBO - artf07233449 - EDB242 - DGE20190012 - OracleR12_Finance_AR_Import factures client_Duplication automatique site client  
             --decode(insert_update_flag, 'I', ref_address, NULL), --location PHENIX 2004
       -- 08-01-2020 - JWY - artf07432057 - INC0499580 - Problème alimentation du champ LOCATION dans le cadre de mises à jour                   
             --(SELECT decode(COUNT(1), 0, ref_address, NULL, ref_address, ref_address)
             (SELECT decode(COUNT(1), 0, ref_address, NULL, ref_address, NULL)
                FROM hz_customer_profiles   hcp,
                     hz_cust_accounts       hcu,
                     hz_cust_acct_sites_all cas,
                     hz_cust_site_uses_all  csu
               WHERE hcu.account_number = customer_number
                 AND hcu.cust_account_id = hcp.cust_account_id
                 AND hcp.site_use_id = csu.site_use_id
                 AND cas.attribute3 = ref_address
                 -- < 08-01-2020 - JWY - artf07432057 - INC0499580 - Problème alimentation du champ LOCATION dans le cadre de mises à jour            
                  AND cas.org_id = (SELECT organization_id
                                     FROM hr_operating_units
                                    WHERE NAME = cdg || soc
                                      AND SYSDATE BETWEEN date_from AND
                                          nvl(date_to, SYSDATE)
                                   )
                  -- 08-01-2020 - JWY - artf07432057 - INC0499580 - Problème alimentation du champ LOCATION dans le cadre de mises à jour  />                          
                 AND csu.cust_acct_site_id = cas.cust_acct_site_id
                 AND csu.site_use_code = 'BILL_TO'
                 AND hcu.cust_account_id = cas.cust_account_id), -- location
             (SELECT organization_id
                FROM hr_operating_units
               WHERE NAME = cdg || soc
                 AND SYSDATE BETWEEN date_from AND nvl(date_to, SYSDATE) --YWA artf2184345
              ),
			 -- 05/11/2019 - NBO - artf07233449 - EDB242 - DGE20190012 - OracleR12_Finance_AR_Import factures client_Duplication automatique site client  
             -- NBO 25/01/18 - artf2310607 - INC0180336 :  erreurs à l'import des clients.
             --ref_address, --JV 05/07/2005 : insertion CDG CODE ANAEL ==> migration R12 CODE ANAEL ou address_identity --YWA
             nvl((SELECT orig_system_reference
                   FROM hz_cust_acct_sites_all hcasa
                  WHERE attribute3 = ref_address
                    AND org_id = (SELECT organization_id
                FROM hr_operating_units
               WHERE NAME = cdg || soc
                 AND SYSDATE BETWEEN date_from AND nvl(date_to, SYSDATE)
              )                    AND rownum = 1),
                 ref_address),
             customer_number,
             code_client_destinataire, -- a voir pour liaison clients parent,
             postal_code,
			 -- 05/11/2019 - NBO - artf07233449 - EDB242 - DGE20190012 - OracleR12_Finance_AR_Import factures client_Duplication automatique site client  
             --decode(insert_update_flag, 'I', 'N', NULL),
             (SELECT decode(COUNT(1), 0, 'N', NULL, 'N', NULL)
                FROM hz_customer_profiles   hcp,
                     hz_cust_accounts       hcu,
                     hz_cust_acct_sites_all cas,
                     hz_cust_site_uses_all  csu
               WHERE hcu.account_number = customer_number
                 AND hcu.cust_account_id = hcp.cust_account_id
                 AND hcp.site_use_id = csu.site_use_id
                 AND cas.attribute3 = ref_address
                 AND cas.org_id = (SELECT organization_id
                                     FROM hr_operating_units
                                    WHERE NAME = cdg || soc
                                      AND SYSDATE BETWEEN date_from AND
                                          nvl(date_to, SYSDATE) --YWA artf2184345
                                   )
                 AND csu.cust_acct_site_id = cas.cust_acct_site_id
                 AND csu.site_use_code = 'BILL_TO'
                 AND hcu.cust_account_id = cas.cust_account_id), -- primary_site_use_flag
             --decode(insert_update_flag, 'I', 'BILL_TO', NULL)
             (SELECT decode(COUNT(1), 0, 'BILL_TO', NULL, 'BILL_TO', NULL)
                FROM hz_customer_profiles   hcp,
                     hz_cust_accounts       hcu,
                     hz_cust_acct_sites_all cas,
                     hz_cust_site_uses_all  csu
               WHERE hcu.account_number = customer_number
                 AND hcu.cust_account_id = hcp.cust_account_id
                 AND hcp.site_use_id = csu.site_use_id
                 AND cas.attribute3 = ref_address
                 AND cas.org_id = (SELECT organization_id
                                     FROM hr_operating_units
                                    WHERE NAME = cdg || soc
                                      AND SYSDATE BETWEEN date_from AND
                                          nvl(date_to, SYSDATE)
                                   )
                 AND csu.cust_acct_site_id = cas.cust_acct_site_id
                 AND csu.site_use_code = 'BILL_TO'
                 AND hcu.cust_account_id = cas.cust_account_id) -- site_use_code            
        FROM dka_iclientifs_interface
       WHERE oa_status = 'P'
         AND insert_update_flag IS NOT NULL
         AND cdg IS NOT NULL;
  
    -- Insertion du profil de l adresse client
    dka_tools_pkg.put_outdebug_message('Insertion du profil de l adresse client');
  
    -- 26/09/2018 - Nicolas BOUSSEKEYT - artf3034049 : INC0250675 - Une correction de la table des rejets (AR) est nécessaire afin de supprimer les lignes qui sont rejouées afin que les rejets ne soient pas bloqués après correction en amont (action à réaliser dans la foulée de l'état des lieux)
    DELETE FROM ra_customer_profiles_int_all
         WHERE ORIG_SYSTEM_CUSTOMER_REF IN (SELECT customer_number
              FROM dka_iclientifs_interface
             WHERE oa_status = 'P'
               AND insert_update_flag IS NOT NULL
               AND cdg IS NOT NULL);
  
        Dka_Tools_Pkg.put_debug_message('Nombre de lignes supprimés : ' || SQL%ROWCOUNT);
  
    INSERT INTO ra_customer_profiles_int_all
      (collector_name,
       created_by,
       creation_date,
       credit_balance_statements,
       credit_hold,
       customer_profile_class_name,
       dunning_letters,
       dunning_letter_set_name,
       grouping_rule_name,
       insert_update_flag,
       interest_charges,
       last_update_date,
       last_updated_by,
       org_id,
       orig_system_address_ref,
       orig_system_customer_ref, --OVERRIDE_TERMS, STANDARD_TERM_NAME,
       statements,
       tolerance)
      SELECT
      --collector,
       NULL,
       fnd_global.user_id,
       SYSDATE,
       'N',
       'N',
       profil_class,
       'Y',
       gv_dunning_letter_set_name,
       gv_grouping_rule_name,
       -- 29/10/2019 - NBO - artf07319790  - TASK0096649 - Correction sites sans profil suite transfert région 
       --INSERT_UPDATE_FLAG,
       (SELECT decode(COUNT(1), 0, 'I', NULL, 'I', 'U')
          FROM hz_customer_profiles   hcp,
               hz_cust_accounts       hcu,
               hz_cust_acct_sites_all cas,
               hz_cust_site_uses_all  csu
         WHERE hcu.account_number = customer_number
           AND hcu.cust_account_id = hcp.cust_account_id
           AND hcp.site_use_id = csu.site_use_id
           AND cas.attribute3 = ref_address
           AND cas.org_id =
               (SELECT organization_id
                  FROM hr_operating_units
                 WHERE NAME = cdg || soc
                   AND SYSDATE BETWEEN date_from AND nvl(date_to, SYSDATE) --YWA artf2184345
                )
           AND csu.cust_acct_site_id = cas.cust_acct_site_id
           AND csu.site_use_code = 'BILL_TO'
           AND hcu.cust_account_id = cas.cust_account_id) insert_update_flag,
       'N',
       SYSDATE,
       fnd_global.user_id,
       (SELECT organization_id
          FROM hr_operating_units
         WHERE NAME = cdg || soc
                AND sysdate  between date_from and nvl(date_to,sysdate) --YWA artf2184345
        ),
       -- 29/10/2019 - NBO - artf07319790  - TASK0096649 - Correction sites sans profil suite transfert région 
       --ref_address, --address_num,--JV 05/07/2005 : insertion CDG CODE ANAEL
       nvl((SELECT orig_system_reference
             FROM hz_cust_acct_sites_all hcasa
            WHERE (orig_system_reference = ref_address OR
                  orig_system_reference = cdg || '-' || ref_address)
              AND rownum = 1),
           ref_address),
       customer_number,
       'N',
       0
        FROM dka_iclientifs_interface
       WHERE oa_status = 'P'
         AND insert_update_flag IS NOT NULL
         AND cdg IS NOT NULL;
  
    -- Insertion du profil de l entete client (une ligne par client)
    dka_tools_pkg.put_outdebug_message('Insertion du profil de l entete client (une ligne par client)');
    INSERT INTO ra_customer_profiles_int_all
      (collector_name,
       created_by,
       creation_date,
       credit_balance_statements,
       credit_hold,
       customer_profile_class_name,
       dunning_letters,
       dunning_letter_set_name,
       grouping_rule_name,
       insert_update_flag,
       interest_charges,
       last_update_date,
       last_updated_by,
       org_id,
       orig_system_address_ref,
       orig_system_customer_ref,
       statements,
       tolerance)
      SELECT
      --collector,
       NULL, --gv_default_collector, pour le moment en attente d'information YWA
       fnd_global.user_id,
       SYSDATE,
       'N',
       'N',
       MIN(profil_class), --fonction de groupe obligatoire ,meme valeur pour toutes les adresses d un meme client
       'Y',
       gv_dunning_letter_set_name,
       gv_grouping_rule_name,
       decode(customer_exists(customer_number), 0, 'U', 'I'), --si le client existait deja, c est un update
       'N',
       SYSDATE,
       fnd_global.user_id,
       MIN((SELECT organization_id
             FROM hr_operating_units
            WHERE NAME = cdg || soc
                AND sysdate  between date_from and nvl(date_to,sysdate) --YWA artf2184345
           )),
       NULL, --address_ref null => profil niveau entete
       customer_number,
       'N',
       0
        FROM dka_iclientifs_interface
       WHERE oa_status = 'P'
         AND insert_update_flag IS NOT NULL
         AND cdg IS NOT NULL
       GROUP BY customer_number;
    --  cdg || soc; --une seule ligne par client
  
    -- Insertion d une ligne par client pour l update des informations de niveau entete
    --  les min() sont des fonctions de groupe obligatoires pour le group by
    dka_tools_pkg.put_outdebug_message('Insertion d une ligne par client pour l update des informations de niveau entete');
    INSERT INTO ra_customers_interface_all
      (created_by,
       creation_date,
       cust_tax_reference, --num intracom
       address_attribute8, -- code partenaire -- YWA R12
       customer_category_code,
       customer_class_code,
       customer_key, --customer_name en maj
       customer_name,
       customer_number,
       customer_status, -- A actif
       customer_type, -- I interne / R externe
       insert_update_flag,
       last_updated_by,
       last_update_date,
       org_id,
       orig_system_customer_ref,
       orig_system_parent_ref -- client lié ?
       )
      SELECT fnd_global.user_id,
             SYSDATE,
             MIN(intracom_number),
             MIN(partner_code),
             MIN(customer_category),
             MIN(customer_class),
-- 16/07/2018 - NBO - artf2876887 - TASK0061020 - Faire évoluer l'interface SIC pour utiliser le nom1 au lieu de customer_name.
             --UPPER(CUSTOMER_NAME),
             upper(nom1),
             --CUSTOMER_NAME,
             nom1,
             customer_number,
             'A',--SHA EDB305
			 ---MIN(decode(customer_status, 'M', 'I', customer_status)), --JVI 24/10/2007
             decode(MIN(customer_class), 'GROUPE_INTERNE', 'I', 'R'), --Si groupe => interne , sinon => externe
             'U',
             fnd_global.user_id,
             SYSDATE,
             (SELECT organization_id
                FROM hr_operating_units
               WHERE NAME = cdg || soc
                AND sysdate  between date_from and nvl(date_to,sysdate) --YWA artf2184345
              ),
             customer_number,
             MIN(code_client_destinataire) -- a voir pour liaison clients parent,
        FROM dka_iclientifs_interface
       WHERE oa_status = 'P'
         AND customer_exists(customer_number) = 0 -- insertion si le client existe
         AND insert_update_flag IS NOT NULL
         AND cdg IS NOT NULL
       GROUP BY customer_number,
-- 16/07/2018 - NBO - artf2876887 - TASK0061020 - Faire évoluer l'interface SIC pour utiliser le nom1 au lieu de customer_name.
                --CUSTOMER_NAME,
                nom1,
                cdg || soc; -- une ligne par client
  
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('Fin Alimentation Open Interface.');
  
  END alim_oi;

  -------------------------------------------------------------------------------------
  --  Nom           : GLOBAL_CONTROL
  --  Description   : Effectue une serie de controles sur les donnees des tables
  --      DKA_ICLIENTIFS_INTERFACE et dka_ICLIENTIFS_COLLECTORS
  --        Met a jour les OA_status et error_message
  --      pour affichage ulterieur.
  --
  ------------------------------------------------------------------------------------
  -- PHENIX 2004: Procedure modifiee.
  PROCEDURE global_control IS
  BEGIN
  
    dka_tools_pkg.put_debug_message('Début de Global_Control');
  
    dka_tools_pkg.put_debug_message(' Update 1');
    UPDATE dka_iclientifs_interface
       SET error_message = NULL,
           oa_status     = 'P',
           oa_request_id = gn_request_id;
    --WHERE  ETL_status = 'A'; YWA
  
    dka_tools_pkg.put_debug_message(' Update 2');
  
    UPDATE dka_iclientifs_collectors
       SET error_message = NULL,
           oa_status     = 'P',
           oa_request_id = gn_request_id
     WHERE --ETL_status = 'A' YWA
     (oa_status IS NULL OR oa_status != 'A');
  
    dka_tools_pkg.put_debug_message(' Update 4');
  
    UPDATE dka_iclientifs_interface
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'customer_status invalide'),
                                  1,
                                  200)
     WHERE customer_status NOT IN ('A', 'I', 'M'); --JVI 24/10/2007
  
    dka_tools_pkg.put_debug_message(' Update 5');
  
    UPDATE dka_iclientifs_interface
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'customer_category inconnue'),
                                  1,
                                  200)
     WHERE customer_category NOT IN
           (SELECT lookup_code
              FROM ar_lookups
             WHERE lookup_type = 'CUSTOMER_CATEGORY'
               AND enabled_flag = 'Y'
               AND SYSDATE BETWEEN nvl(start_date_active, SYSDATE) AND
                   nvl(end_date_active, SYSDATE + 1));
  
    dka_tools_pkg.put_debug_message(' Update 12');
  
    UPDATE dka_iclientifs_interface
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Numero ANAEL invalide'),
                                  1,
                                  200)
     WHERE (length(ref_address) != 8);
    --OR ( )  --Test de coherence => Algorithme?
  
    dka_tools_pkg.put_debug_message(' Update 13');
  
    UPDATE dka_iclientifs_interface
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Numero de client absent'),
                                  1,
                                  200)
     WHERE customer_number IS NULL
        OR customer_number = '';
  
    dka_tools_pkg.put_debug_message(' Update 15');
  
    UPDATE dka_iclientifs_interface t
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Code client destinataire inconnu'),
                                  1,
                                  200)
     WHERE NOT EXISTS (SELECT customer_number
              FROM dka_iclientifs_interface
             WHERE oa_status = 'P'
               AND customer_number = t.code_client_destinataire)
       AND NOT EXISTS
     (SELECT account_number
              FROM hz_cust_accounts
             WHERE account_number = t.code_client_destinataire)
       AND code_client_destinataire IS NOT NULL;
  
    dka_tools_pkg.put_debug_message(' Update 16');
  
    UPDATE dka_iclientifs_interface t
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Adresse client destinataire inconnu'),
                                  1,
                                  200)
     WHERE NOT EXISTS (SELECT customer_number
              FROM dka_iclientifs_interface
             WHERE oa_status = 'P'
               AND ref_address = t.adresse_client_destinataire)
        AND    NOT EXISTS
         (SELECT orig_system_reference --YWA attribute3 ==> orig_system_reference
              FROM hz_cust_acct_sites_all
                WHERE  attribute3 /*attribute2*/ = T.Adresse_client_destinataire) --YWA attribute3 ==> attribute2 -- OBE artf2562676
       AND adresse_client_destinataire IS NOT NULL;
  
    dka_tools_pkg.put_debug_message(' Update 17');
  
    -- controles sur la table des collectors
    UPDATE dka_iclientifs_collectors
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Collector inconnu ou inactif'),
                                  1,
                                  200)
        WHERE  collector NOT IN (SELECT name
                                 FROM   ar_collectors
                                 WHERE  status = 'A');
  
    dka_tools_pkg.put_debug_message(' Update 18');
  
    UPDATE dka_iclientifs_collectors
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Centre de gestion inconnu'),
                                  1,
                                  200)
     WHERE cdg NOT IN
           (SELECT flex_value
              FROM fnd_flex_values
             WHERE flex_value_set_id = gn_flex_set_id_cdg) -- PHENIX 2004: gn_flex_set_id_cg_soc -> gn_flex_set_id_cdg.
        OR length(cdg) != 3;
  
    dka_tools_pkg.put_debug_message(' Update 19');
  
    UPDATE dka_iclientifs_collectors t
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Numero de client inconnu'),
                                  1,
                                  200)
     WHERE NOT EXISTS (SELECT customer_number
              FROM dka_iclientifs_interface
             WHERE oa_status = 'P'
               AND customer_number = t.customer_number)
       AND NOT EXISTS
     (SELECT account_number
              FROM hz_cust_accounts
             WHERE account_number = t.customer_number);
  
    -- Modif EB 2006/02/07
    dka_tools_pkg.put_debug_message(' Update 20');
  
    UPDATE dka_iclientifs_interface
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Code ANAEL présent sur un autre client. Verifier le lien établissement de'),
                                  1,
                                  200)
     WHERE customer_number IN
           (SELECT dii.customer_number
              FROM dka_iclientifs_interface dii,
                       (SELECT hcasa.orig_system_reference,
                               ac.customer_number
                        from   hz_cust_acct_sites_all hcasa,
                               ar_customers           ac
                     WHERE ac.customer_id = hcasa.cust_account_id) a --YWA
            -- NBO 25/01/18 - artf2310607 - INC0180336 :  erreurs à l'import des clients.
            --where  dii.ref_address = a.orig_system_reference
                where  (substr(a.orig_system_reference,5) = dii.ref_address or a.orig_system_reference = dii.ref_address)
               AND dii.customer_number != a.customer_number);
  
    -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
    dka_tools_pkg.put_debug_message(' Update 21');
  
    UPDATE dka_iclientifs_interface
       SET oa_status     = 'R',
           error_message = substr((error_message || ',' ||
                                  'Il n''a pas de collectors pour ce client'),
                                  1,
                                  200)
     WHERE customer_number NOT IN
           (SELECT customer_number FROM dka_iclientifs_collectors);
  -- 26/10/2021 - SHA - artf07468996 -EDB 305 - INT005 - DESACTIVER LES ADRESSES D’UN ETABLISSEMENT DESACTIVE
    dka_tools_pkg.put_debug_message('Modification suite à la désactivation des adresses d'' un etablissement désactivé ');
	UPDATE dka_iclientifs_interface
       SET CUSTOMER_STATUS     = 'A',
	       ADDRESS_STATUS      = 'I'     
     WHERE CUSTOMER_STATUS     = 'I'
	 AND SOC is null 
	 and cdg is null;
	
    -- FIN MODIF EB 2006/02/07
  
    COMMIT; -- OBE artf2562676
  
    dka_tools_pkg.put_debug_message(' Fin de Global_Control');
  
  END global_control;

  -------------------------------------------------------------------------------------
  --  Nom           : GET_GL_ID
  --  Description   : Calcule et retourne les cles comptables client et produit
  --      qu il faudra par la suite inserer dans la fonction
  --      economique de facturation
  --
  --  PARAMETRES    : Code Centre de Gestion
  --        Code Societe
  --        Code Partenaire
  --  OUT      ID de la cle client
  --  OUT      ID de la cle produit
  --
  ------------------------------------------------------------------------------------
  -- PHENIX 2004: Procedure modifiee.
  PROCEDURE get_gl_id(p_set_of_books_id IN NUMBER,
                      pv_cdg            IN VARCHAR2,
                      pv_soc            IN VARCHAR2,
                      pv_partner_code   IN VARCHAR2 DEFAULT NULL,
                      gl_id_rec         OUT NUMBER,
                      gl_id_rev         OUT NUMBER) IS
  
    v_segment3_client VARCHAR2(40);
  
  BEGIN
  
    dka_tools_pkg.put_debug_message('pv_partner_code' || pv_partner_code);
          v_segment3_client :=gv_segment3_client;
  
          IF pv_partner_code IS NOT NULL THEN -- YWA artf2147025
      -- code partenaire renseigne
            v_segment3_client :=gv_segment3_client_partner;
    END IF;
  
    BEGIN
      SELECT gcc.code_combination_id
        INTO gl_id_rec
            FROM   gl_ledgers     gl,
                   gl_code_combinations gcc
       WHERE gl.ledger_id = p_set_of_books_id
         AND gcc.chart_of_accounts_id = gl.chart_of_accounts_id
         AND gcc.segment1 = pv_soc -- PHENIX 2004: pv_cdg||pv_soc -> pv_soc.
         AND gcc.segment2 = pv_cdg -- PHENIX 2004: gv_segment2_client_partner -> pv_cdg.
            AND    gcc.segment3 = v_segment3_client-- YWA  artf2147025
         AND gcc.segment4 = gv_segment4_client_partner -- PHENIX 2004: pv_partner_code -> gv_segment4_client_partner.
            AND    gcc.segment5 = nvl(pv_partner_code,'0') -- PHENIX 2004: '0' -> pv_partner_code.
         AND gcc.segment6 = '0'
         AND gcc.segment7 = '0'
         AND gcc.segment8 = '0'
         AND gcc.segment9 = '0' -- PHENIX 2004: Ajout.
         AND gcc.segment10 = '0'; -- PHENIX 2004: Ajout.
    EXCEPTION
      WHEN OTHERS THEN
        dka_tools_pkg.get_code_combination_id(pv_soc,
                                              pv_cdg,
                                                    v_segment3_client,-- YWA artf2147025
                                              gv_segment4_client_partner,
                                                    nvl(pv_partner_code,'0'),
                                              '0',
                                              '0',
                                              '0',
                                              '0',
                                              '0',
                                              '0',
                                              '0',
                                              gl_id_rec,
                                              gv_buf,
                                              gn_ret); -- PHENIX 2004: --pv_cdg||pv_soc,gv_segment2_client_partner,gv_segment3_client_partner,pv_partner_code,'0','0','0','0' -> pv_soc,pv_cdg, gv_segment3_client_partner,gv_segment4_client_partner,pv_partner_code,'0','0','0','0','0'.
        IF gn_ret != 0 THEN
          dka_tools_pkg.put_outdebug_message('get_gl_id :' || gv_buf);
          --RAISE erreur;--YWA artf2154954
        END IF;
    END;
  
    --< OBE
    BEGIN
      SELECT gcc.code_combination_id
        INTO gl_id_rev
        FROM gl_ledgers gl,
             --gl_sets_of_books     gsob,
             gl_code_combinations gcc
       WHERE gl.ledger_id = p_set_of_books_id --gsob.set_of_books_id = Fnd_Profile.VALUE('GL_SET_OF_BKS_ID')
         AND gcc.chart_of_accounts_id = gl.chart_of_accounts_id
         AND gcc.segment1 = pv_soc -- PHENIX 2004: pv_cdg||pv_soc -> pv_soc.
         AND gcc.segment2 = pv_cdg -- PHENIX 2004: gv_segment2_produit_partner -> pv_cdg.
         AND gcc.segment3 = gv_segment3_produit_partner
         AND gcc.segment4 = gv_segment4_produit_partner -- PHENIX 2004: pv_partner_code -> gv_segment4_produit_partner.
            AND    gcc.segment5 = nvl(pv_partner_code,'0')-- PHENIX 2004: gv_segment5_produit -> pv_partner_code.
         AND gcc.segment6 = '0' -- PHENIX 2004: '0' -> gv_segment6_produit. --YWA R12 DAAG==> 0
         AND gcc.segment7 = '0'
         AND gcc.segment8 = '0'
         AND gcc.segment9 = '0' -- PHENIX 2004: Ajout.
         AND gcc.segment10 = '0'; -- PHENIX 2004:  Ajout.
    EXCEPTION
      WHEN OTHERS THEN
        dka_tools_pkg.get_code_combination_id(pv_soc,
                                              pv_cdg,
                                              gv_segment3_produit_partner,
                                              gv_segment4_produit_partner,
                                                    nvl(pv_partner_code,'0'),
                                                    '0',--YWA R12 DAAG==> 0
                                              '0',
                                              '0',
                                              '0',
                                              '0',
                                              '0',
                                              '0',
                                              gl_id_rev,
                                              gv_buf,
                                              gn_ret); -- PHENIX 2004: pv_cdg||pv_soc,gv_segment2_produit_partner,gv_segment3_produit_partner,pv_partner_code,gv_segment5_produit,'0','0','0' -> pv_soc,pv_cdg, gv_segment3_produit_partner,gv_segment4_produit_partner,pv_partner_code,gv_segment6_produit,'0','0','0','0'.
        IF gn_ret != 0 THEN
          dka_tools_pkg.put_outdebug_message('get_gl_id :' || gv_buf);
          --RAISE erreur;--YWA artf2154954
        END IF;
    END;
    --> OBE
  

  END get_gl_id;

  -------------------------------------------------------------------------------------
  --  Nom           : UPDATE_COLLECTORS
  --  Description   : Parcourt tous les sites d une adresse , sur un certain CdG
  --      Recalcule et met a jour le code du charge de recouvrement
  --      pour ce site/CdG
  --
  --  PARAMETRES    : Reference ANAEL
  --        Code Centre de Gestion
  --
  ------------------------------------------------------------------------------------
  PROCEDURE update_collectors IS
    CURSOR cur_csu IS
      SELECT hcp.cust_account_profile_id,
             ca.account_number,
             hou.organization_id,
             hou.set_of_books_id,
             dki.cdg,
             dki.soc,
             cas.attribute8 partner_code,
             csu.site_use_id,
             csu.gl_id_rec,
             -- 27/03/2018 - NBO - artf2459074 : INC0202251 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
             csu.gl_id_rev,
             -- 01/04/2019 - NBO - artf07234729 - INC0225987 - chargé de recouvrement du client ne remonte pas
             dki.rowid rid,
             hcp.rowid rid2,
             -- 15/10/2019 - NBO - artf07315378 - INC0354606 - Problème de clé comptable dans l'import des clients
             csu.rowid rid3
        FROM dka_iclientifs_interface dki,
             hr_operating_units       hou,
             hz_cust_acct_sites_all   cas,
             hz_cust_site_uses_all    csu,
             hz_cust_accounts         ca,
             hz_customer_profiles     hcp
       WHERE dki.oa_status = 'P'
         AND dki.soc IS NOT NULL
         AND dki.cdg IS NOT NULL
         AND EXISTS (SELECT 'x'
                FROM fnd_flex_values
               WHERE flex_value_set_id = gn_flex_set_id_cdg
                 AND flex_value = dki.cdg) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
         AND hou.name = dki.cdg || dki.soc --region+societe
            --
         AND dki.ref_address = cas.attribute3
         AND cas.org_id = hou.organization_id
            --
         AND cas.cust_acct_site_id = csu.cust_acct_site_id
         AND csu.site_use_code = 'BILL_TO'
            --
         AND ca.cust_account_id = cas.cust_account_id
            --
            -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
            --AND    hcp.cust_account_id = ca.cust_account_id + 0
            --AND    hcp.site_use_id = csu.site_use_id + 0
            --AND    hcp.party_id = ca.party_id  + 0
         AND hcp.cust_account_id = ca.cust_account_id
         AND hcp.site_use_id = csu.site_use_id
         AND hcp.party_id = ca.party_id
       FOR UPDATE OF
       hcp.collector_id,
       hcp.last_update_date,
       csu.gl_id_rec,
       csu.gl_id_rev,
       csu.last_update_date
       ;
    rec_site cur_csu%ROWTYPE;
  
    vn_id_rec          NUMBER;
    vn_id_rev          NUMBER;
    vn_old_site_use_id NUMBER := -1;
  
  BEGIN
  
    FOR rec_site IN cur_csu
    LOOP
      IF vn_old_site_use_id <> rec_site.site_use_id
      THEN
        -- procedure update_site_gl_id
        vn_id_rec := NULL;
        vn_id_rev := NULL;
      
        get_gl_id(rec_site.set_of_books_id,
                  rec_site.cdg,
                  rec_site.soc,
                  rec_site.partner_code,
                  vn_id_rec,
                  vn_id_rev);
      
        -- 27/03/2018 - NBO - artf2459074 : INC0202251 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
        IF vn_id_rec IS NULL OR vn_id_rev IS NULL THEN
          -- Affectation des champs calcules au record
          UPDATE dka_iclientifs_interface
             SET gl_id_rec     = vn_id_rec,
                 gl_id_rev     = vn_id_rev,
                 oa_status     = 'R', --YWA
                 error_message = substr((error_message || ',' ||
                                        'Calcul des cles comptables impossible GET_GL_ID'),
                                        1,
                                        200)
           WHERE ROWID = rec_site.rid;
        ELSE
          UPDATE hz_cust_site_uses_all
             SET gl_id_rec        = vn_id_rec,
                 gl_id_rev        = vn_id_rev,
                 last_update_date = SYSDATE --JV 26/09/2005
          -- 15/10/2019 - NBO - artf07315378 - INC0354606 - Problème de clé comptable dans l'import des clients
           WHERE ROWID = rec_site.rid3; --CURRENT OF cur_csu;
        END IF;
      

        vn_old_site_use_id := rec_site.site_use_id;
      
      END IF;
    
      UPDATE hz_customer_profiles
         SET collector_id     = get_collector_from_cust_cdg(rec_site.account_number,
                                                            rec_site.organization_id),
             last_update_date = SYSDATE --JV 26/09/2005
      -- 01/04/2019 - NBO - artf07234729 - INC0225987 - chargé de recouvrement du client ne remonte pas
      --WHERE  CURRENT OF cur_csu ;
       WHERE ROWID = rec_site.rid2;
    
    END LOOP;
  
  END update_collectors;

  -------------------------------------------------------------------------------------
  --  Nom           : UPDATE_SITE_GL_ID
  --  Description   : Parcourt tous les sites d une adresse et recalcule les cles
  --      comptables des fonctions economiques de facturation
  --
  --  PARAMETRES    : Reference ANAEL
  --
  ------------------------------------------------------------------------------------
  PROCEDURE update_site_gl_id(pv_anael_ref IN VARCHAR2,
                              p_org_id     IN NUMBER) IS
    CURSOR cur_csu(refer    VARCHAR2,
                   p_org_id NUMBER) IS
      SELECT /*+ ordered */
       csu.site_use_id,
       (SELECT substrb(NAME, 0, 3)
          FROM hr_operating_units
         WHERE organization_id = p_org_id) cdg,
       (SELECT substrb(NAME, 4)
          FROM hr_operating_units
         WHERE organization_id = p_org_id) soc, -- PHENIX 2004 : SUBSTR(csu.location,4,4)
       (SELECT set_of_books_id
          FROM hr_operating_units
         WHERE organization_id = p_org_id) set_of_books_id,
       cas.attribute8 partner_code
      FROM   hz_cust_acct_sites_all cas,
             hz_cust_site_uses_all  csu
      --hz_cust_accounts_all       ca
       WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
            --AND    ca.cust_account_id = cas.cust_account_id
         AND csu.site_use_code = 'BILL_TO'
         AND cas.attribute3 = refer
         AND cas.org_id = p_org_id
         AND cas.org_id = csu.org_id;
  
    rec_site  cur_csu%ROWTYPE;
    vn_id_rec NUMBER;
    vn_id_rev NUMBER;
  
  BEGIN
  
    FOR rec_site IN cur_csu(pv_anael_ref, p_org_id)
    LOOP
      -- recalcul des cles associees a ce site
      -- PHENIX 2004 : pas de société pour le client
      get_gl_id(rec_site.set_of_books_id,
                rec_site.cdg,
                rec_site.soc,
                rec_site.partner_code,
                vn_id_rec,
                vn_id_rev);
    
      -- 27/03/2018 - NBO - artf2459074 : INC0202251 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
      IF vn_id_rec IS NULL OR vn_id_rev IS NULL THEN
        -- Affectation des champs calcules au record
        UPDATE dka_iclientifs_interface
           SET gl_id_rec     = vn_id_rec,
               gl_id_rev     = vn_id_rev,
               oa_status     = 'R', --YWA
               error_message = substr((error_message || ',' ||
                                      'Calcul des cles comptables impossible GET_GL_ID'),
                                      1,
                                      200)
         WHERE customer_number = pv_anael_ref
             AND cdg||soc IN (select name from hr_operating_units where organization_id = p_org_id);
      
      ELSE
        UPDATE hz_cust_site_uses_all
           SET gl_id_rec        = vn_id_rec,
               gl_id_rev        = vn_id_rev,
               last_update_date = SYSDATE --JV 26/09/2005
         WHERE site_use_id = rec_site.site_use_id
           AND org_id = p_org_id;
      END IF;
    
    END LOOP;
  
  END update_site_gl_id;

  -----------------------------------------------------------------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : Initialisation
  --  VALEUR RETOURNEE :
  --     Description       : Initialisation des variables globales par dka_parameter et autres
  ----------------------------------------------------------------------------------------------------------------------
  -- PHENIX 2004: Procedure modifiee.
  PROCEDURE init(pv_errbuf  OUT VARCHAR2,
                 pn_retcode OUT NUMBER) IS
  
    rec_param dka_parameters%ROWTYPE;
    --vn_org_id NUMBER;
    --vv_soc    VARCHAR2(10);
  BEGIN
  

    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    dka_tools_pkg.put_debug_message('Lancement des initialisations');
  
    -- Appel à la procédure commune d'initialisation de l'état de sortie
    --Dka_Tools_Pkg.put_out_header;
  
    -- Récupération des variables de la table des paramètres
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG4_CUST_PARTNER',
                                rec_param,
                                pn_retcode,
                                pv_errbuf); -- PHENIX 2004: SEG2_CUST_PARTNER -> SEG4_CUST_PARTNER.
    gv_segment4_client_partner := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_client_partner -> gv_segment4_client_partner.
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG4_CUST_PARTNER - ' || pv_errbuf; -- PHENIX 2004: SEG2_CUST_PARTNER -> SEG4_CUST_PARTNER.
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG4_CUST',
                                rec_param,
                                pn_retcode,
                                pv_errbuf); -- PHENIX 2004: SEG2_CUST -> SEG4_CUST.
    gv_segment4_client := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_client -> gv_segment4_client.
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG4_CUST - ' || pv_errbuf; -- PHENIX 2004: SEG2_CUST -> SEG4_CUST.
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG4_REV_PARTNER',
                                rec_param,
                                pn_retcode,
                                pv_errbuf); -- PHENIX 2004: SEG2_REV_PARTNER -> SEG4_REV_PARTNER.
    gv_segment4_produit_partner := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_produit_partner -> gv_segment4_produit_partner.
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG4_REV_PARTNER - ' || pv_errbuf; -- PHENIX 2004: SEG2_REV_PARTNER -> SEG4_REV_PARTNER.
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG4_REV',
                                rec_param,
                                pn_retcode,
                                pv_errbuf); -- PHENIX 2004: SEG2_REV -> SEG4_REV.
    gv_segment4_produit := rec_param.varchar2_value; -- PHENIX 2004: gv_segment2_produit -> gv_segment4_produit.
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG4_REV - ' || pv_errbuf; -- PHENIX 2004: SEG2_REV -> SEG4_REV.
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG3_CUST_PARTNER',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_segment3_client_partner := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG3_CUST_PARTNER - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG3_CUST',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_segment3_client := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG3_CUST - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG3_REV_PARTNER',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_segment3_produit_partner := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG3_REV_PARTNER - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'SEG3_REV',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_segment3_produit := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : SEG3_REV - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'DEFAULT_CDG',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_default_cdg := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : DEFAULT_CDG - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'DEFAULT_COLLECTOR',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_default_collector := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : DEFAULT_COLLECTOR - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'ORG_TYPE_SOC',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_type_org_soc := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : ORG_TYPE_SOC - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'DUNNING_LETTER_SET_NAME',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_dunning_letter_set_name := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : DUNNING_LETTER_SET_NAME - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'GROUPING_RULE_NAME',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_grouping_rule_name := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : GROUPING_RULE_NAME - ' || pv_errbuf;
      RETURN;
    END IF;
  
    dka_tools_pkg.get_parameter('ICLIENTIFS',
                                'GERRICO_CATEGORY',
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    gv_gerrico_category := rec_param.varchar2_value;
    IF pn_retcode != 0 THEN
      pv_errbuf := 'init : GERRICO_CATEGORY - ' || pv_errbuf;
      RETURN;
    END IF;
  

    --Autres Initialisations
    --recherche du segment1 de la CCF
    DECLARE
      vv_flex_value_set_name VARCHAR2(200);
    BEGIN
      dka_tools_pkg.get_flex_key_seg_value_set(pv_errbuf              => pv_errbuf,
                                               pn_retcode             => pn_retcode,
                                               pv_legal_flex_key_flag => 'N',
                                               pn_segment_num         => 1,
                                               pn_flex_value_set_id   => gn_flex_set_id_soc, -- PHENIX 2004: gn_flex_set_id_cg_soc -> gn_flex_set_id_soc.
                                               pv_flex_value_set_name => vv_flex_value_set_name);
      IF pn_retcode != 0 THEN
        pv_errbuf := 'init : Parametre GN_FLEX_SET_ID_CG_SOC non-trouve : ' ||
                     pv_errbuf;
        RETURN;
      END IF;
    END;
  
    --recherche du segment2 de la CCF                                        -- PHENIX 2004: Ajout.
    DECLARE
      -- PHENIX 2004: Ajout.
      vv_flex_value_set_name VARCHAR2(200); -- PHENIX 2004: Ajout.
    BEGIN
      -- PHENIX 2004: Ajout.
      dka_tools_pkg.get_flex_key_seg_value_set( -- PHENIX 2004: Ajout.
                                               pv_errbuf              => pv_errbuf -- PHENIX 2004: Ajout.
                                              ,
                                               pn_retcode             => pn_retcode -- PHENIX 2004: Ajout.
                                              ,
                                               pv_legal_flex_key_flag => 'N' -- PHENIX 2004: Ajout.
                                              ,
                                               pn_segment_num         => 2 -- PHENIX 2004: Ajout.
                                              ,
                                               pn_flex_value_set_id   => gn_flex_set_id_cdg -- PHENIX 2004: Ajout.
                                              ,
                                               pv_flex_value_set_name => vv_flex_value_set_name -- PHENIX 2004: Ajout.
                                               ); -- PHENIX 2004: Ajout.
      IF pn_retcode != 0 THEN
        -- PHENIX 2004: Ajout.
        pv_errbuf := 'init : Parametre GN_FLEX_SET_ID_CG_SOC non-trouve : ' ||
                     pv_errbuf; -- PHENIX 2004: Ajout.
        RETURN; -- PHENIX 2004: Ajout.
      END IF; -- PHENIX 2004: Ajout.
    END; -- PHENIX 2004: Ajout.
  
    ---- initialisation de GN_REQUEST_ID pour recuperer l'ID du traitement courant
    gn_request_id := fnd_global.conc_request_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
  END init;

  --RBE artf2100712
  --------------------------------------------------------------------------------------
  --  Nom           : delete_duplicate_data
  --  Description   : Nettoyage tables de travail : laisser les derniers enregistrements
  --------------------------------------------------------------------------------------
  PROCEDURE delete_duplicate_data (pv_errbuf  OUT VARCHAR2,
                                  pn_retcode OUT NUMBER) IS
  BEGIN
  
    -- Nettoyage tables de travail : laisser les derniers enregistrements
    DELETE dka_iclientifs_interface dii1
     WHERE TIMESTAMP != (SELECT MAX(TIMESTAMP)
                           FROM dka_iclientifs_interface dii2
                          WHERE dii1.customer_number = dii2.customer_number
                               -- 11/04/2018 / NBO / artf2356814 : INC0187177 : Demande assistance nettoyage table client
                            AND dii1.ref_address = dii2.ref_address
                         -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
                         --AND NVL(dii1.cdg,'XYZ') = NVL(dii2.cdg,'XYZ')  -- OBE artf2562676
                         --AND NVL(dii1.soc,'XYZ') = NVL(dii2.soc,'XYZ') -- OBE artf2562676
                         );
  
    Dka_Tools_Pkg.put_debug_message('Nbre lignes supprimées CLIENTS : '||TO_CHAR(SQL%ROWCOUNT));
  
    DELETE dka_iclientifs_collectors dic1
    WHERE timestamp != (SELECT MAX(timestamp)
              FROM dka_iclientifs_collectors dic2
             WHERE dic1.customer_number = dic2.customer_number
                  -- 11/04/2018 / NBO / artf2356814 : INC0187177 : Demande assistance nettoyage table client
                        AND NVL(dic1.cdg,'XYZ') = NVL(dic2.cdg,'XYZ')
                       );
  
    Dka_Tools_Pkg.put_debug_message('Nbre lignes supprimées COLLECTOR : '||TO_CHAR(SQL%ROWCOUNT));
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
  END delete_duplicate_data;
  -------------------------------------------------------------------------------------
  --  Nom           : SHOW_REJECTED_RECORDS
  --  Description   : Affiche les enregistrements rejetes (clients + charge de rec.)
  ------------------------------------------------------------------------------------
  PROCEDURE show_rejected_records IS
  BEGIN
    dka_tools_pkg.put_outdebug_message('Rejets du fichier Clients ');
    dka_tools_pkg.put_outdebug_message(rpad('Customer Number', 20) ||
                                       rpad('Ref ANAEL', 20) ||
                                       rpad('Error Message', 200));
    dka_tools_pkg.put_outdebug_message('---------------------------------------------------------------- ');
  
    FOR rec_reject IN cur_IFS_reject
    LOOP
    
      dka_tools_pkg.put_outdebug_message(rpad(rec_reject.customer_number,
                                              20) ||
                                         rpad(rec_reject.ref_address, 20) ||
                                         rpad(rec_reject.error_message,
                                              200));
    
      dka_tools_pkg.ins_prog_message(pn_request_id   => gn_request_id,
                                     pv_prog_name    => 'ICLIENTIFS',
                                     pv_source       => 'OA',
                                     pv_table_name   => 'DKA_ICLIENTIFS_INTERFACE',
                                     pv_table_id     => rec_reject.ref_address,
                                     pv_column_name  => NULL,
                                     pv_column_value => NULL,
                                     pv_message_type => 'E',
                                     pv_message_text => rec_reject.error_message);
    
    END LOOP;
  
    dka_tools_pkg.put_outdebug_message(' ');
    dka_tools_pkg.put_outdebug_message(' ');
  
    dka_tools_pkg.put_outdebug_message('Rejets du fichier Collectors ');
    dka_tools_pkg.put_outdebug_message(rpad('Customer Number', 20) ||
                                       rpad('CDG', 5) ||
                                       rpad('Collector', 15) ||
                                       rpad('Error Message', 200));
    dka_tools_pkg.put_outdebug_message('---------------------------------------------------------------- ');
  
    FOR rec_reject IN cur_IFS_collector_reject
    LOOP
    
      dka_tools_pkg.put_outdebug_message(rpad(rec_reject.customer_number,
                                              20) ||
                                         rpad(rec_reject.cdg, 5) ||
                                         rpad(rec_reject.collector, 15) ||
                                         rpad(rec_reject.error_message,
                                              200));
    
      dka_tools_pkg.ins_prog_message(pn_request_id   => gn_request_id,
                                     pv_prog_name    => 'ICLIENTIFS',
                                     pv_source       => 'OA',
                                     pv_table_name   => 'DKA_ICLIENTIFS_COLLECTORS',
                                     pv_table_id     => rec_reject.customer_number || '-' ||
                                                        rec_reject.cdg || '-' ||
                                                        rec_reject.collector,
                                     pv_column_name  => NULL,
                                     pv_column_value => NULL,
                                     pv_message_type => 'E',
                                     pv_message_text => rec_reject.error_message);
    
    END LOOP;
  
  END show_rejected_records;

  -------------------------------------------------------------------------------------
  --  Nom           : GET_COLLECTOR_FROM_CUST_CDG
  --  Description   : Retourne un charge de recouvrement pour ce client
  --      et ce centre de gestion
  --        Se base sur la table DKA_ICLIENTIFS_COLLECTORS sinon retourne
  --      un charge de recouvrement par defaut
  --  PARAMETRES    : Reference ANAEL de l adresse
  --        Code Centre de Gestion
  --  VALEUR RETOURNEE :
  --     Description       : identifiant du charge de recouvrement (collector_id)
  ------------------------------------------------------------------------------------
  FUNCTION get_collector_from_cust_cdg(pv_customer_number IN VARCHAR2,
                                       p_org_id           IN NUMBER)
    RETURN NUMBER IS
    vv_collector NUMBER;
    v_cdg        VARCHAR2(5);
  BEGIN
  
    SELECT substrb(NAME, 0, 3)
      INTO v_cdg
      FROM hr_operating_units
     WHERE organization_id = p_org_id;
  
    SELECT DISTINCT ac.collector_id -- JWYC artf07306014
      INTO vv_collector
    FROM   dka_iclientifs_collectors dic,
           ar_collectors             ac
     WHERE dic.customer_number = pv_customer_number
       AND dic.cdg = v_cdg
       AND nvl(dic.oa_status, 'R') != 'R'
       AND dic.collector = ac.name
       AND rownum = 1; -- JWYC artf07306014
  
    RETURN vv_collector;
  
  EXCEPTION
    WHEN no_data_found THEN
      BEGIN
        SELECT ac.collector_id
          INTO vv_collector
          FROM ar_collectors ac
         WHERE ac.name = v_cdg || 'Def' --JV 15/03/05 Chargé de recouvrement par défaut pour la région pv_cdg
        ;
        RETURN vv_collector;
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
      END;
    
    --Faut il ajouter une valeur par defaut par CDG  ??
  END get_collector_from_cust_cdg;

  -------------------------------------------------------------------------------------
  --  Nom           : REJECTED_LINES_EXIST
  --  Description   : Teste l existence de lignes rejetees dans les tables d interface
  --      specifiques
  --
  --  VALEUR RETOURNEE :
  --     Description       : Vrai : Il y a des rejets
  ------------------------------------------------------------------------------------
  FUNCTION rejected_lines_exist RETURN BOOLEAN IS
    nb_line NUMBER;
  BEGIN
  
    SELECT COUNT(1)
      INTO nb_line
      FROM dka_iclientifs_interface
     WHERE oa_status = 'R';
  
    IF nb_line > 0 THEN
      RETURN TRUE;
    END IF;
  
    SELECT COUNT(1)
      INTO nb_line
      FROM dka_iclientifs_collectors
     WHERE oa_status = 'R';
  
    IF nb_line > 0 THEN
      RETURN TRUE;
    END IF;
  
    RETURN FALSE;
  END rejected_lines_exist;

  -------------------------------------------------------------------------------------
  --  Nom           : CUSTOMER_EXISTS
  --  Description   : Teste l existence de ce client
  --
  --  PARAMETRES    : Numero de client
  --
  --  VALEUR RETOURNEE :
  --     Description       : 0 si le client existe, 1 sinon
  ------------------------------------------------------------------------------------
  FUNCTION customer_exists(pv_orig_ref IN VARCHAR2) RETURN NUMBER IS
    v_tmp NUMBER;
    v_ret NUMBER := 0;
  BEGIN
  
    BEGIN
      SELECT MIN(account_number)
        INTO v_tmp
        FROM hz_cust_accounts
       WHERE account_number = pv_orig_ref;
    EXCEPTION
      WHEN OTHERS THEN
        v_ret := 1;
    END;
    IF v_tmp IS NULL THEN
      v_ret := 1;
    END IF;
    RETURN v_ret;
  END customer_exists;

  -------------------------------------------------------------------------------------
  --  Nom           : ADDRESS_EXISTS
  --  Description   : Teste l existence de cette adresse dans une societe et un CDG
  --
  --  PARAMETRES    : Reference ANAEL de l adresse
  --        Code Centre de Gestion
  --        Code Societe
  --  VALEUR RETOURNEE :
  --     Description       : booleen
  ------------------------------------------------------------------------------------
  FUNCTION address_exists(pv_orig_ref IN VARCHAR2,
                          p_org_id    IN NUMBER /*, pv_soc IN VARCHAR2*/) --YWA
   RETURN BOOLEAN IS
    -- PHENIX 2004
    v_tmp NUMBER;
    v_ret BOOLEAN := TRUE;
  BEGIN
  
    BEGIN
      SELECT MIN(site_use_id)
        INTO v_tmp
        FROM hz_cust_site_uses_all
       WHERE location = pv_orig_ref
         AND org_id = p_org_id; -- PHENIX 2004
    EXCEPTION
      WHEN OTHERS THEN
        v_ret := FALSE;
    END;
  
    IF v_tmp IS NULL THEN
      v_ret := FALSE;
    END IF;
  
    RETURN v_ret;
  END address_exists;

  /*=========================================================================*/
  /* PROCEDURE NAME :   Launch_OI
  /*
  /* DESCRIPTION      :  Traitement standard d'import des clients AR
  /*
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /*
  /*
  /*=========================================================================*/
  PROCEDURE Launch_OI(p_errbuf  OUT VARCHAR2,
                      p_retcode OUT NUMBER) IS
  
    v_phase             VARCHAR2(100);
    v_status            VARCHAR2(100);
    v_dev_phase         VARCHAR2(100);
    v_dev_status        VARCHAR2(100);
    v_message           VARCHAR2(100);
    g_import_request_id NUMBER;
    v_msg               VARCHAR2(100);
  
  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Launch_OI');
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de l''interface client : ');
  
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output,
                      'LANCEMENT DE L''INTERFACE CLIENT :');
    fnd_file.put_line(fnd_file.output, '----------------------');
    ---------------------------------------------------
    -- Lancement du traitement de l'interface client --
    ---------------------------------------------------
  
    -- Lancement du traitement
    g_import_request_id := fnd_request.submit_request('AR' -- APPL
                                                     ,
                                                      --'RACUST' -- PROG
                                                      -- NBO 25/01/18 - artf2310607 - INC0180336 :  erreurs à l'import des clients.
                                                      'RACUSTMA' -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                     ,
                                                      'N',
                                                      NULL);
  
    IF g_import_request_id = 0 THEN
      p_retcode := 2;
      v_msg := SUBSTR(Fnd_Message.get,1,100);
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement de l''interface client a échoué' ||
                        chr(10) || 'PROGRAMME  : RACUST' || chr(10));
      fnd_file.put_line(fnd_file.LOG,v_msg);
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR : Le traitement de l''interface client a échoué');
    ELSE
      COMMIT;
      fnd_file.put_line(fnd_file.log,
                        '=> REQUEST ID= ' || g_import_request_id);
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement de l''interface client : ' ||
                        g_import_request_id);
    
      -- Attente de la fin du traitement
      IF NOT (fnd_concurrent.wait_for_request(g_import_request_id,
                                              20,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_message;
        fnd_file.put_line(fnd_file.log,
                          'ERREUR : Attente de la fin du programme de l''interface client : Fin du traitement' ||
                          chr(10) || 'MESSAGE : ' || v_message || chr(10));
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        fnd_file.put_line(fnd_file.log,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        fnd_file.put_line(fnd_file.output,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        fnd_file.put_line(fnd_file.log,
                          'Fin du traitement de l''interface client en warning ' ||
                          g_import_request_id);
        p_retcode := 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 2;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface client : ' ||
                     v_message;
      
        fnd_file.put_line(fnd_file.log,
                          'ERREUR : Fin anormale du traitement de l''interface client ' ||
                          g_import_request_id || chr(10) ||
                          'Phase/Statut : ' || v_dev_phase || '/' ||
                          v_dev_status || chr(10) || 'MESSAGE : ' ||
                          v_message || chr(10));
        fnd_file.put_line(fnd_file.output,
                          '===> ERREUR : Fin anormale du traitement de l''interface client ' ||
                          g_import_request_id);
      END IF;
    
    END IF;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Launch_OI');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'Launch_OI : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Launch_OI : EXCEPTION OTHERS ');
  END launch_oi;

  -------------------------------------------------------------------------------------
  --  Nom           : pre_OI
  --  Description   : Traitement execute AVANT l Open Interface
  --                   -initialisation des parametres
  --         -controle des donnees
  --         -affichage des donnees en rejet
  --                   -chargement des tables standard d Open Interface
  ------------------------------------------------------------------------------------
  PROCEDURE pre_oi(pv_errbuf  IN OUT VARCHAR2,
                   pn_retcode OUT NUMBER) IS
  
    rec_ifs               cur_ifs%ROWTYPE;
    vn_soc                VARCHAR2(50);
    vn_cdg                VARCHAR2(50);
    vn_ccid_cpt_client    gl_code_combinations.code_combination_id%TYPE;
    vn_ccid_cpt_produit   gl_code_combinations.code_combination_id%TYPE;
    vn_insert_update_flag VARCHAR2(1);
  
  vn_cpt_client              NUMBER :=0; -- OBE artf2562676
  
  BEGIN
  
    pn_retcode := 0;
  
    init(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      dka_tools_pkg.put_outdebug_message(pv_errbuf);
      RETURN;
    END IF;
  


    dka_tools_pkg.put_debug_message(' Avant Global_Controls');
    /*--JV Supprimer les lignes dans dka_iclientifs_collectors avec un oa_status = 'A'
    DELETE DKA_ICLIENTIFS_COLLECTORS
    WHERE oa_status = 'A';*/
  
    -- YWA artf2158785
    -- purger l'ensemble des messages précédent de la table dka_program_messages.
    DELETE dka_program_messages WHERE prog_name = 'ICLIENTIFS';
  
    -- RBE artf2100712
    -- Nettoyage tables de travail
    delete_duplicate_data(pv_errbuf, pn_retcode);
    --controles globaux
    global_control;
    dka_tools_pkg.put_debug_message(' Après Global_Controls');
  

    -- Traitement des champs a calculer
    FOR rec_ifs IN cur_ifs
    LOOP
    
      -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
      vn_cpt_client := vn_cpt_client + 1; -- OBE artf2562676
    
      dka_tools_pkg.put_debug_message('Traitement du client : ' ||
                                      rec_ifs.customer_number ||
                                      ' - ref Anael : ' ||
                                      rec_ifs.ref_address);
    
      dka_tools_pkg.put_debug_message('Region : ' || rec_ifs.cdg_cdr);
    
      vn_cdg := rec_ifs.cdg_cdr;
    
      FOR societe IN (SELECT organization_id org_id,
                             NAME,
                             set_of_books_id,
                             default_legal_context_id
                        FROM hr_operating_units
                       WHERE NAME LIKE rec_ifs.cdg_cdr || '%'
                      AND sysdate  between date_from and nvl(date_to,sysdate) --YWA artf2184345
                      )
      LOOP

      
        g_org_id   := societe.org_id;
        pn_retcode := 0;
        --init_environement(pv_errbuf, pn_retcode); --YWA --RBE artf2102500
        IF pn_retcode != 0 THEN
          dka_tools_pkg.put_outdebug_message(pv_errbuf);
          raise_application_error(-20001, '');
        END IF;
      
        -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
        /*pn_retcode := 0;
        init(pv_errbuf, pn_retcode);
        
        IF pn_retcode != 0 THEN
          Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
          raise_application_error(-20001, '');
        END IF;*/
      
        vn_soc := substr(societe.name, 4);
        dka_tools_pkg.put_debug_message('societe : ' || vn_soc);
        dka_tools_pkg.put_debug_message('debut d''insert DKA_ICLIENTIFS_INTERFACE');
        Dka_Tools_Pkg.put_debug_message(vn_soc||'/'||substr(nvl(rec_ifs.PARTNER_CODE,'XXXX0'),4));
      
        -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
        -- 19/04/2018 NBO / artf2546656 : INC0211379 - Le traitement "DKA : Import des clients : Pre Open Interface" de la nuit applicative du 18/04/2018 s'est terminé en erreur (request id = 3231777)
       IF vn_soc != substr(nvl(rec_ifs.PARTNER_CODE,'XXX0'),4) THEN
          INSERT INTO dka_iclientifs_interface
          VALUES
            (rec_ifs.customer_name,
             rec_ifs.customer_number,
             rec_ifs.intracom_number,
             --rec_ifs.INVOICE_COPY,--R12 migration YWA
             --rec_ifs.euribor,--R12 migration YWA
             decode(rec_ifs.customer_status,
                    'M',
                    'I',
                    rec_ifs.customer_status), --JVI 24/10/2007
             rec_ifs.customer_category,
             rec_ifs.customer_class,
             rec_ifs.nom1,
             rec_ifs.nom2,
             rec_ifs.address1,
             rec_ifs.address2,
             rec_ifs.city,
             rec_ifs.postal_code,
             rec_ifs.country,
             DECODE(rec_ifs.ADDRESS_STATUS, 'M', 'I', rec_ifs.ADDRESS_STATUS), --JVI 24/10/2007
             rec_ifs.profil_class,
             rec_ifs.partner_code,
             rec_ifs.code_client_destinataire,
             rec_ifs.adresse_client_destinataire,
             rec_ifs.recipient_only_flag,
             rec_ifs.ref_address,
             --rec_ifs.SOCIETY,--R12 migration YWA
             rec_ifs.gl_id_rec,
             rec_ifs.gl_id_rev,
             rec_ifs.insert_update_flag,
             rec_ifs.cdg_cdr,
             vn_soc,
             rec_ifs.oa_status,
             --rec_ifs.ETL_STATUS,--R12 migration YWA
             rec_ifs.oa_request_id,
             --rec_ifs.ETL_REQUEST_ID,--R12 migration YWA
             rec_ifs.error_message,
             --rec_ifs.NUM_FUS, --JVI 24/10/2007 --R12 migration YWA
             --rec_ifs.ADD_FUS, --JVI 24/10/2007 --R12 migration YWA
             rec_ifs.num_siret, --DPE20105002 - FRAMICHE - 15/02/2011
             rec_ifs.receipt_method,
             NULL,
             current_timestamp -- RBE artf2100712
             );
        
          --rec_ifs.society := societe.name;
          dka_tools_pkg.put_debug_message('Calcul des cles comptables');
          --Calcul des cles comptables -- a revoir YWA get_gl_id
         get_gl_id( societe.set_of_books_id,
                    vn_cdg,
                    vn_soc,
                    rec_ifs.partner_code,
                    vn_ccid_cpt_client,
                    vn_ccid_cpt_produit); --YWA ccf
        
        END IF;
      
        --JV 05/07/2005 : comme on insert maintenant le couple CDG-Code Anael dans la table standard, on regarde
        --si le couple CDG-Code Anael, avant on regardait par code anaël seulement
        --YWA migration R12 utilisation de org_id a la place de cdg
        dka_tools_pkg.put_debug_message('address_exists');
        IF address_exists(rec_ifs.ref_address, societe.org_id) THEN
          vn_insert_update_flag := 'U';
        
        ELSE
          vn_insert_update_flag := 'I';
        
        END IF;
      
        --YWA artf2154954
        IF vn_ccid_cpt_client IS NULL OR vn_ccid_cpt_produit IS NULL THEN
          -- Affectation des champs calcules au record
          UPDATE dka_iclientifs_interface
             SET gl_id_rec          = vn_ccid_cpt_client,
                 gl_id_rev          = vn_ccid_cpt_produit,
                 insert_update_flag = vn_insert_update_flag,
                 cdg                = vn_cdg,
                 soc                = vn_soc,
                 oa_status          = 'R', --YWA
                 error_message      = substr((error_message || ',' ||
                                             'Calcul des cles comptables impossible GET_GL_ID'),
                                             1,
                                             200)
           WHERE ref_address = rec_ifs.ref_address
             AND cdg = rec_ifs.cdg_cdr
             AND soc = vn_soc;
        
        ELSE
          -- Affectation des champs calcules au record
          UPDATE dka_iclientifs_interface
             SET gl_id_rec          = vn_ccid_cpt_client,
                 gl_id_rev          = vn_ccid_cpt_produit,
                 insert_update_flag = vn_insert_update_flag,
                 cdg                = vn_cdg,
                 soc                = vn_soc
           WHERE ref_address = rec_ifs.ref_address
             AND cdg = rec_ifs.cdg_cdr
             AND soc = vn_soc; --JV 26/09/2005
        END IF;--YWA artf2154954
      
        dka_tools_pkg.put_debug_message('update de DKA_ICLIENTIFS_INTERFACE, insert_update_flag :' ||
                                        vn_insert_update_flag ||
                                        ' pour : ' ||
                                        rec_ifs.customer_number);
      
        -- Gestion du lien entre un client payeur et un client destinaire
        --Enregistrer l'ancien code destinataire pour pouvoir le mettre à jour ensuite (Ajout JV 01/12/2003)
        --JVI 02/03/2007 : EARS00007354065 si il existe un ancien destinataire et que l'on supprime le destinataire
        --                 => suppression de la relation avec l'ancien destinataire
        IF vn_insert_update_flag = 'U' THEN
        
          --      IF rec_ifs.code_client_destinataire IS NOT NULL THEN
          BEGIN
            --YWA migration R12 RA_ADDRESSES_ALL==>hz_cust_acct_sites_all
            SELECT DISTINCT attribute1
              INTO gv_code_destinataire
              FROM hz_cust_acct_sites_all
             WHERE cust_account_id IN
                   (SELECT customer_id
                      FROM ar_customers
                     WHERE customer_number = rec_ifs.customer_number)
                  --AND orig_system_reference = rec_ifs.ref_address;--TESTJV 05/07/2005
               AND attribute3 = rec_ifs.ref_address
                  -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
               AND org_id = societe.org_id
                  -- 19/04/2018 NBO / artf2546656 : INC0211379 - Le traitement "DKA : Import des clients : Pre Open Interface" de la nuit applicative du 18/04/2018 s'est terminé en erreur (request id = 3231777)
            AND (orig_system_reference = rec_ifs.ref_address OR  orig_system_reference = vn_cdg || '-' || rec_ifs.ref_address)
            AND attribute1 IS NOT NULL;--YWA artf2149045
          
            dka_tools_pkg.put_debug_message('Code Client Destinataire: ' ||
                                            gv_code_destinataire);
          
          EXCEPTION
            --WHEN NO_DATA_FOUND THEN -- OBE artf2562676
      WHEN OTHERS THEN          -- OBE artf2562676
              dka_tools_pkg.put_debug_message('Pb dans la détermination de l''ancien destinataire');
          END;
        
          --      END IF;
        
          --vérifier si le code destinataire a changé
          --si oui, désactiver la ligne concernée dans la liste des relations de l'ancien code destinataire
        
          IF nvl(rec_ifs.code_client_destinataire, 0) !=
             gv_code_destinataire THEN
            UPDATE hz_cust_acct_relate_all
            SET    status           = 'I',
                   last_update_date = SYSDATE --JV 26/09/2005
             WHERE related_cust_account_id IN
                   (SELECT customer_id
                      FROM ar_customers
                     WHERE customer_number = rec_ifs.customer_number)
               AND cust_account_id IN
                   (SELECT customer_id
                      FROM ar_customers
                     WHERE customer_number = gv_code_destinataire);
          
            dka_tools_pkg.put_debug_message('Désactivation du client ' ||
                                            rec_ifs.customer_number ||
                                            ' dans la liste des payeurs de l ancien code partenaire ' ||
                                            gv_code_destinataire);
          
            UPDATE hz_cust_acct_relate_all
            SET    status           = 'A',
                   last_update_date = SYSDATE --JV 26/09/2005
             WHERE related_cust_account_id IN
                   (SELECT customer_id
                      FROM ar_customers
                     WHERE customer_number = rec_ifs.customer_number)
               AND cust_account_id IN
                   (SELECT customer_id
                      FROM ar_customers
                     WHERE customer_number =
                           rec_ifs.code_client_destinataire);
          
            dka_tools_pkg.put_debug_message('Activation du client ' ||
                                            rec_ifs.customer_number ||
                                            ' dans la liste du nouveau code partenaire ' ||
                                            rec_ifs.code_client_destinataire);
          END IF;
        END IF;
      
      END LOOP;
    
      --< OBE artf2562676
      --Reactivation des site_use eventuellement desactivees precedemment
      --Ceci afin d eviter une erreur dans l open interface standard survenant dans ce cas
      UPDATE hz_cust_site_uses_all a
         SET status           = 'A',
             attribute16      = status --JV Modif du 20/10/03
            ,
             last_update_date = SYSDATE --JV 26/09/2005
      -- NBO 25/01/18 - artf2310607 - INC0180336 :  erreurs à l'import des clients.
       WHERE --site_use_id IN
      -- (SELECT csu.site_use_id
           (site_use_id, cust_acct_site_id) IN (SELECT csu.site_use_id, csu.cust_acct_site_id
          FROM hz_cust_acct_sites_all cas,
               hz_cust_site_uses_all  csu,
               hz_cust_accounts       ca
         WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
           AND csu.site_use_code = 'BILL_TO'
           AND cas.cust_account_id = ca.cust_account_id
           AND ca.account_number = rec_ifs.customer_number --in (select distinct customer_number from dka_iclientifs_interface)
           AND a.attribute3 = rec_ifs.ref_address
        -- 19/04/2018 NBO / artf2546656 : INC0211379 - Le traitement "DKA : Import des clients : Pre Open Interface" de la nuit applicative du 18/04/2018 s'est terminé en erreur (request id = 3231777)
      ) AND status <> 'A';
    
      --Dka_Tools_Pkg.put_debug_message('update de hz_cust_site_uses_all, status =A pour : ' ||
      --rec_ifs.customer_number);
    
      -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
      --< OBE artf2562676
      IF vn_cpt_client = 100 THEN
        COMMIT;
        vn_cpt_client := 0;
      END IF;
      --> OBE artf2562676
    --> OBE artf2562676
    
    END LOOP;
  

    -- Affichage des lignes rejetees
    show_rejected_records;
  
    -- JV Supprimer les clients Gerrico dans DKA_ICLIENTIFS_COLLECTORS et dans DKA_ICLIENTIFS_INTERFACE
    DELETE FROM dka_iclientifs_collectors
     WHERE customer_number IN
           (SELECT customer_number
              FROM dka_iclientifs_interface
             WHERE customer_category = gv_gerrico_category
               AND oa_status != 'R');
  
    DELETE FROM dka_iclientifs_interface
     WHERE customer_category = gv_gerrico_category
       AND oa_status != 'R'; --YWA
  
    -- Alimentation des tables d Open Interface Standard.
    alim_oi;
  
    -- S il y a des rejets , le traitement se termine en status "Warning"
    IF rejected_lines_exist THEN
      pn_retcode := 1;
      pv_errbuf  := 'Les lignes rejetees ne seront pas traitees.';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := SQLCODE;
      pv_errbuf  := SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf || gv_buf);
      raise_application_error(-20001, '');
  END pre_oi;

  /*=========================================================================*/
  /* PROCEDURE NAME :   IN_OI
  /*
  /* DESCRIPTION      :  Traitement standard d'import des clients
  /*
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /*
  /*
   /*=========================================================================*/
  PROCEDURE IN_OI(p_errbuf  IN OUT VARCHAR2,
                  p_retcode OUT NUMBER) IS
  
    v_errbuf  VARCHAR2(200);
    v_retcode NUMBER;
  BEGIN
  
      Fnd_File.put_line(Fnd_File.LOG,'--------------------------------------------------------------------------------------------------');
      Fnd_File.put_line(Fnd_File.LOG,'début lancement traitement standard d''import des clients (toutes organisations)');
  
    launch_oi(v_errbuf, v_retcode);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      raise_application_error(-20001, p_errbuf);
    END IF;
  END in_oi;

  -------------------------------------------------------------------------------------
  --  Nom           : post_OI
  --  Description   : Traitement execute APRES l Open Interface
  --                   -initialisation des parametres
  --         -duplication des sites,fonctions economiques,profiles,relations
  --      par appel a duplicate_addr
  --         -propagation des updates sur les sites dupliques
  ------------------------------------------------------------------------------------
  -- PHENIX 2004: Procedure modifiee.
  PROCEDURE post_OI(pv_errbuf  IN OUT VARCHAR2,
                    pn_retcode OUT NUMBER) IS
  
  BEGIN
  
    pn_retcode := 0;
  
    init(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      dka_tools_pkg.put_outdebug_message(pv_errbuf);
      RETURN;
    END IF;
  
    dka_tools_pkg.put_outdebug_message('post_oi: Duplication des updates niveau adresse');
  


-------------NEW
    --site_use inactif si client uniquement destinataire
    UPDATE hz_cust_site_uses_all
       SET status           = 'I', --site_use inactif si client uniquement destinataire
           attribute16      = 'I', --JV Modif 20/10/03
           last_update_date = SYSDATE --JV 26/09/2005
     WHERE site_use_id IN
           (SELECT csu.site_use_id
              FROM dka_iclientifs_interface dii,
                   hr_operating_units       hou,
                   hz_cust_acct_sites_all   cas,
                   hz_cust_site_uses_all    csu,
                   hz_cust_accounts_all     ca
             WHERE dii.oa_status = 'P'
               AND dii.soc IS NOT NULL
                  AND  Dii.cdg in (SELECT ffv.flex_value
                      FROM fnd_flex_values ffv
                     WHERE flex_value_set_id = gn_flex_set_id_cdg
                       AND ffv.enabled_flag = 'Y'
                                   AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ffv.START_DATE_ACTIVE,SYSDATE)) AND TRUNC(NVL(ffv.END_DATE_ACTIVE,SYSDATE))
                                  ) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
                  --
               AND hou.name = dii.cdg || dii.soc --region+societe
                  --
               AND cas.attribute3 = dii.ref_address --JV Modif 20/10/03
               AND cas.org_id = hou.organization_id
                  --
               AND csu.cust_acct_site_id = cas.cust_acct_site_id
               AND csu.site_use_code = 'BILL_TO'
                  --
               AND ca.cust_account_id = cas.cust_account_id
                  -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
               AND ca.account_number = dii.customer_number)
       AND status != 'I';
  
    --site actif si client payeur
    UPDATE hz_cust_site_uses_all
       SET status           = 'A', --site actif si client payeur
           attribute16      = 'A', --JV Modif 20/10/03
           last_update_date = SYSDATE --JV 26/09/2005
     WHERE site_use_id IN
           (SELECT csu.site_use_id
              FROM dka_iclientifs_interface dii,
                   hr_operating_units       hou,
                   hz_cust_acct_sites_all   cas,
                   hz_cust_site_uses_all    csu,
                   hz_cust_accounts_all     ca
             WHERE dii.oa_status = 'P'
               AND dii.soc IS NOT NULL
                  AND  Dii.cdg in (SELECT ffv.flex_value
                      FROM fnd_flex_values ffv
                     WHERE flex_value_set_id = gn_flex_set_id_cdg
                       AND ffv.enabled_flag = 'Y'
                                   AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ffv.START_DATE_ACTIVE,SYSDATE)) AND TRUNC(NVL(ffv.END_DATE_ACTIVE,SYSDATE))
                                  ) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
                  AND  NVL(Dii.recipient_only_flag,'N') != 'Y' --site actif si client payeur
                  --
               AND hou.name = dii.cdg || dii.soc --region+societe
                  --
               AND cas.attribute3 = dii.ref_address --JV Modif 20/10/03
               AND cas.org_id = hou.organization_id
                  --
               AND csu.cust_acct_site_id = cas.cust_acct_site_id
               AND csu.site_use_code = 'BILL_TO'
                  --
               AND ca.cust_account_id = cas.cust_account_id
                  -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
               AND ca.account_number = dii.customer_number)
       AND status != 'A';
  
    --JV Ajout du 20/10/2003
    UPDATE hz_cust_site_uses_all
    SET    status           = NVL(attribute16, 'A'),
           last_update_date = SYSDATE--JV 26/09/2005
     WHERE site_use_id IN
           (SELECT csu.site_use_id
              FROM dka_iclientifs_interface dii,
                   hz_cust_acct_sites_all   cas,
                   hz_cust_site_uses_all    csu,
                   hz_cust_accounts_all     ca
             WHERE dii.oa_status = 'P'
               AND dii.soc IS NOT NULL
                  AND  Dii.cdg in (SELECT ffv.flex_value
                      FROM fnd_flex_values ffv
                     WHERE flex_value_set_id = gn_flex_set_id_cdg
                       AND ffv.enabled_flag = 'Y'
                                   AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ffv.START_DATE_ACTIVE,SYSDATE)) AND TRUNC(NVL(ffv.END_DATE_ACTIVE,SYSDATE))
                                  ) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
                  --
               AND csu.cust_acct_site_id = cas.cust_acct_site_id
               AND csu.site_use_code = 'BILL_TO'
                  --
               AND ca.cust_account_id = cas.cust_account_id
                  -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
               AND ca.account_number = dii.customer_number)
       AND status != nvl(attribute16, 'A');
  
    -- Il faut propager les updates dans les sites dupliques
    UPDATE hz_cust_acct_sites_all hcasa
    SET ( attribute1,attribute2,status,attribute11,last_update_date) =
       ( SELECT Dki.Code_client_destinataire,
                   dki.adresse_client_destinataire,
                DECODE(Dki.address_status,
                       'M',
                       'I',
                        Dki.address_status), --JVI 24/10/2007
                   dki.num_siret, --DPE20105002 - FRAMICHE - 09/02/2011
                   SYSDATE
         FROM DKA_ICLIENTIFS_INTERFACE Dki,
              hr_operating_units Hou
             WHERE hou.organization_id = hcasa.org_id
               AND dki.ref_address = hcasa.attribute3
               AND hou.name = dki.cdg || dki.soc --region+societe
         AND ROWNUM = 1 )
    WHERE ( Hcasa.Attribute3, Hcasa.Org_Id ) IN
    (  SELECT Dki.REF_ADDRESS, Hou.Organization_Id
       FROM   DKA_ICLIENTIFS_INTERFACE Dki,
              hr_operating_units Hou
             WHERE dki.oa_status = 'P'
               AND dki.soc IS NOT NULL
       AND    Dki.cdg in (SELECT ffv.flex_value
                      FROM fnd_flex_values ffv
                     WHERE flex_value_set_id = gn_flex_set_id_cdg
                       AND ffv.enabled_flag = 'Y'
                          AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ffv.START_DATE_ACTIVE,SYSDATE)) AND TRUNC(NVL(ffv.END_DATE_ACTIVE,SYSDATE))
                         ) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
               AND hou.name = dki.cdg || dki.soc --region+societe
       AND EXISTS ( SELECT 'X'
                      FROM hz_cust_site_uses_all hcsua
                     WHERE hcsua.location = dki.ref_address
                 and    Hcsua.Org_Id = Hou.Organization_Id  ) );
  
    --JVI 05/10/2006 : EARS00006370220
    UPDATE hz_locations hl
    SET (Hl.ADDRESS1,Hl.ADDRESS2,Hl.ADDRESS3,Hl.ADDRESS4,HL.CITY,HL.POSTAL_CODE,HL.COUNTRY) =
        (SELECT Dki.NOM1,Dki.NOM2,Dki.ADDRESS1,Dki.ADDRESS2,Dki.CITY,Dki.POSTAL_CODE,Dki.COUNTRY
              FROM dka_iclientifs_interface dki
             WHERE dki.ref_address = hl.attribute3
         AND   ROWNUM = 1 )
    WHERE  EXISTS (
       SELECT 'X'
       FROM   DKA_ICLIENTIFS_INTERFACE Dki,
              hr_operating_units Hou
             WHERE dki.oa_status = 'P'
               AND dki.soc IS NOT NULL
       AND    Dki.cdg in (SELECT ffv.flex_value
                      FROM fnd_flex_values ffv
                     WHERE flex_value_set_id = gn_flex_set_id_cdg
                       AND ffv.enabled_flag = 'Y'
                          AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ffv.START_DATE_ACTIVE,SYSDATE)) AND TRUNC(NVL(ffv.END_DATE_ACTIVE,SYSDATE))
                         ) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
               AND dki.ref_address = hl.attribute3
               AND hou.name = dki.cdg || dki.soc --region+societe
       AND EXISTS ( SELECT 'X'
                      FROM hz_cust_site_uses_all hcsua
                     WHERE hcsua.location = dki.ref_address
                 AND    Hcsua.Org_Id = Hou.Organization_Id ) );
  
    -- FOR rec_collector IN cur_IFS_collector(rec_IFS.customer_number)
    UPDATE dka_iclientifs_collectors
       SET oa_status = 'A'
    WHERE (customer_number, cdg) IN ( SELECT Dki.customer_number, Dic.Cdg
              FROM dka_iclientifs_interface  dki,
                   hr_operating_units        hou,
                   dka_iclientifs_collectors dic
             WHERE dki.insert_update_flag = 'I'
               AND dki.oa_status = 'P'
               AND dki.soc IS NOT NULL
                                       AND    Dki.cdg in (SELECT ffv.flex_value
                      FROM fnd_flex_values ffv
                     WHERE flex_value_set_id = gn_flex_set_id_cdg
                       AND ffv.enabled_flag = 'Y'
                                                          AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ffv.START_DATE_ACTIVE,SYSDATE)) AND TRUNC(NVL(ffv.END_DATE_ACTIVE,SYSDATE))
                                                         ) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
               AND hou.name = dki.cdg || dki.soc --region+societe
               AND dic.customer_number = dki.customer_number
               AND nvl(dic.oa_status, 'R') != 'R' -- JWYC artf07306014
                                       AND NOT EXISTS ( SELECT 'X'
                      FROM hz_cust_site_uses_all hcsua
                     WHERE hcsua.location = dki.ref_address
                                                        AND   Hcsua.Org_id = Hou.Organization_Id ) );
  
    --Affectation du collector dans le cas d un insert sur le centre de gestion par defaut, inoperant sinon
    --+gestion de l'update des comptes du site dans le cas d un update du code partenaire (sur centre de gestion par defaut)
    update_collectors;
  
    -- 27/04/2018 - NBO - artf2562676 : INC0212650 - INT005 - Optimisation du programme de Pré-OI de l'interface clients
    --Il faut que la case "Fact." dans l'onglet Relations du panneau client soit cochée
    UPDATE hz_cust_acct_relate_all hcara
      SET    BILL_TO_FLAG     = 'Y',
             last_update_date = SYSDATE --JV 26/09/2005
      WHERE  EXISTS ( SELECT 'X'
              FROM hz_cust_accounts         hca,
                   dka_iclientifs_interface dki,
                   hr_operating_units       hou,
                   hz_cust_acct_relate_all  hcara2
             WHERE hca.orig_system_reference = dki.customer_number
               AND dki.oa_status = 'P'
                      AND  Dki.cdg in (SELECT ffv.flex_value
                      FROM fnd_flex_values ffv
                     WHERE flex_value_set_id = gn_flex_set_id_cdg
                       AND ffv.enabled_flag = 'Y'
                                       AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(ffv.START_DATE_ACTIVE,SYSDATE)) AND TRUNC(NVL(ffv.END_DATE_ACTIVE,SYSDATE))
                                       ) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
               AND dki.soc IS NOT NULL
               AND hou.name = dki.cdg || dki.soc --region+societe
               AND hou.organization_id = hcara.org_id
                  --AND   Hca.CUST_ACCOUNT_ID IN (Hcara.CUST_ACCOUNT_ID,Hcara.RELATED_CUST_ACCOUNT_ID));
               AND hcara.cust_acct_relate_id = hcara2.cust_acct_relate_id
                      AND   Hca.CUST_ACCOUNT_ID IN (Hcara2.CUST_ACCOUNT_ID, Hcara2.RELATED_CUST_ACCOUNT_ID)
                      );

  
---- OLD
  
/*    FOR rec_IFS IN cur_IFS_post
        LOOP
          BEGIN
    
            SELECT organization_id
            INTO   v_org_id
            FROM   hr_operating_units
            WHERE  name = rec_ifs.cdg || rec_ifs.soc; --region+societe
          END;
    
          --gestion des clients uniquement destinataires.
          IF rec_IFS.recipient_only_flag = 'Y' THEN
            --site_use inactif si client uniquement destinataire
            Dka_Tools_Pkg.PUT_DEBUG_MESSAGE('Desactivation de la fonction de facturation de la ref ANAEL ' ||
                                            rec_IFS.ref_address);
    
        SELECT *
        FROM   DKA_ICLIENTIFS_INTERFACE
        WHERE  oa_status = 'P'
        and    cdg is not null
        and    soc is not null
        AND    cdg in (SELECT flex_value
                       FROM   fnd_flex_values
                       WHERE  flex_value_set_id = gn_flex_set_id_cdg); --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
    
    
    
            UPDATE hz_cust_site_uses_all
            SET    status           = 'I',
                   attribute16      = 'I', --JV Modif 20/10/03
                   last_update_date = SYSDATE --JV 26/09/2005
            WHERE  site_use_id IN
                   (SELECT csu.site_use_id
                    FROM   DKA_ICLIENTIFS_INTERFACE Dii,
                           hr_operating_units Hou,
                           hz_cust_acct_sites_all cas,
                           hz_cust_site_uses_all  csu,
                           hz_cust_accounts_all   ca
                    WHERE  Dii.oa_status = 'P'
                      AND  Dii.cdg is not null
                      AND  Dii.soc is not null
                      AND  Dii.cdg in (SELECT flex_value
                                       FROM   fnd_flex_values
                                       WHERE  flex_value_set_id = gn_flex_set_id_cdg) --ne prendre que les cdg de la table collectors qui existent dans le jeu de valeur
                      AND  Dii.recipient_only_flag = 'Y'
                       --
                      AND  Hou.name = Dii.cdg || Dii.soc --region+societe
                       --
                      AND  cas.attribute3 = Dii.ref_address --JV Modif 20/10/03
                      AND  cas.org_id = Hou.Organization_Id
                       --
                      AND  csu.cust_acct_site_id = cas.cust_acct_site_id
                      AND  csu.site_use_code = 'BILL_TO'
                       --
                      AND  ca.cust_account_id = cas.cust_account_id
                      AND  ca.account_number = Dii.customer_number);
    
    
    
            --JV Ajout du 21/11/2003
          ELSE
    
            UPDATE hz_cust_site_uses_all --site actif si client payeur
            SET    status           = 'A',
                   attribute16      = 'A',
                   last_update_date = SYSDATE --JV 26/09/2005
            WHERE  site_use_id IN
                   (SELECT csu.site_use_id
                    FROM   hz_cust_acct_sites_all cas,
                           hz_cust_site_uses_all  csu,
                           hz_cust_accounts_all   ca
                    WHERE  cas.cust_acct_site_id = csu.cust_acct_site_id
                    AND    csu.site_use_code = 'BILL_TO'
                    AND    cas.cust_account_id = ca.cust_account_id
                    AND    ca.account_number = rec_IFS.customer_number
                    AND    cas.attribute3 = rec_ifs.ref_address
                    AND    cas.org_id = v_org_id
                    AND    csu.org_id = cas.org_id) --migration R12 YWA
            AND    org_id = v_org_id; --migration R12 YWA
    
          END IF;
    
          --JV Ajout du 20/10/2003
          UPDATE hz_cust_site_uses_all
          SET    status           = NVL(attribute16, 'A'),
                 last_update_date = SYSDATE --JV 26/09/2005
          WHERE  site_use_id IN
                 (SELECT csu.site_use_id
                  FROM   hz_cust_acct_sites_all cas,
                         hz_cust_site_uses_all  csu,
                         hz_cust_accounts_all   ca
                  WHERE  cas.cust_acct_site_id = csu.cust_acct_site_id
                  AND    csu.site_use_code = 'BILL_TO'
                  AND    cas.cust_account_id = ca.cust_account_id
                  AND    ca.account_number = rec_IFS.customer_number
                  AND    cas.org_id = v_org_id
                  AND    csu.org_id = cas.org_id) --migration R12 YWA)
          AND    org_id = v_org_id; --migration R12 YWA
    
          --JVI 05/10/2006 : on fait la propagation des infos sur les autres sites de l'adresse si elle existe déjà
    
          IF address_exists(rec_ifs.ref_address, v_org_id) THEN
            --JVI 05/10/2006
    
    
            -- Il faut propager les updates dans les sites dupliques
    
            Dka_Tools_Pkg.PUT_DEBUG_MESSAGE('Propagation des updates de la ref ANAEL ' ||
                                            rec_IFS.ref_address);
    
            UPDATE HZ_CUST_ACCT_SITES_ALL
            SET    attribute1 = rec_IFS.Code_client_destinataire,
                   attribute2 = rec_IFS.Adresse_client_destinataire,
                   status           = DECODE(rec_IFS.address_status,
                                             'M',
                                             'I',
                                             rec_IFS.address_status) --JVI 24/10/2007
                  ,
                   attribute11      = rec_IFS.num_siret --DPE20105002 - FRAMICHE - 09/02/2011
                  ,
                   last_update_date = SYSDATE
            --customer_category_code ??
            WHERE
                   attribute3 = rec_IFS.ref_address
            AND    org_id = v_org_id;
    
            --JVI 05/10/2006 : EARS00006370220
            UPDATE HZ_LOCATIONS L
            SET    L.ADDRESS1    = rec_IFS.NOM1,
                   L.ADDRESS2    = rec_IFS.NOM2,
                   L.ADDRESS3    = rec_IFS.ADDRESS1,
                   L.ADDRESS4    = rec_IFS.ADDRESS2,
                   L.CITY        = rec_IFS.CITY,
                   L.POSTAL_CODE = rec_IFS.POSTAL_CODE,
                   L.COUNTRY     = rec_IFS.COUNTRY
            WHERE  ATTRIBUTE3 = rec_IFS.ref_address;
            --fin JVI 05/10/2006
    
          ELSIF (rec_IFS.insert_update_flag = 'I') THEN
            Dka_Tools_Pkg.PUT_OUTDEBUG_MESSAGE('insert_update_flag = I pour : ' ||
                                               rec_IFS.customer_number);
    
            DECLARE
              --duplication CDG
              vb_no_cdg BOOLEAN := TRUE;
            BEGIN
              FOR rec_collector IN cur_IFS_collector(rec_IFS.customer_number)
              LOOP
    
                Dka_Tools_Pkg.PUT_DEBUG_MESSAGE('Duplication de la ref ANAEL ' ||
                                                rec_IFS.ref_address ||
                                                ' dans le couple Cdg-Soc : ' ||
                                                rec_collector.cdg ||
                                                rec_ifs.soc);
                UPDATE dka_iclientifs_collectors
                SET    OA_status = 'A'
                WHERE  customer_number = rec_IFS.customer_number
                AND    cdg = rec_collector.cdg;
                vb_no_cdg := FALSE;
              END LOOP;
    
            END; --duplication CDG
          END IF;
    
          --Affectation du collector dans le cas d un insert sur le centre de gestion par defaut, inoperant sinon
          update_collectors(rec_IFS.ref_address, v_org_id);
    
          --gestion de l'update des comptes du site dans le cas d un update du code partenaire (sur centre de gestion par defaut)
         update_site_gl_id(rec_IFS.ref_address, v_org_id); --YWA migration R12 ccf
          --> Integre dans  update_collectors
    
          --Il faut que la case "Fact." dans l'onglet Relations du panneau client soit cochée
          UPDATE HZ_CUST_ACCT_RELATE_ALL
          SET    BILL_TO_FLAG     = 'Y',
                 last_update_date = SYSDATE --JV 26/09/2005
          WHERE  CUST_ACCOUNT_ID =
                 (SELECT cust_account_id
                  FROM   hz_cust_accounts_all
                  WHERE  orig_system_reference = rec_IFS.customer_number)
          OR     RELATED_CUST_ACCOUNT_ID =
                 (SELECT cust_account_id
                   FROM   hz_cust_accounts_all
                   WHERE  orig_system_reference = rec_IFS.customer_number)
          and    org_id = v_org_id;
        END LOOP;
*/
  
------------------WAIT
    --Calcul des CUF attribute6 et 7 pour specifique de relance
    --JVI 29/03/2007 : EARS00007368651  : quand le cdg n'existe pas sur le destinataire on prend l'id le plus ancien
    dka_tools_pkg.put_outdebug_message('Calcul des CUF pour le specifique de relance...');
    FOR rec_anael IN cur_ANAEL_ref
    LOOP
      --balayage de toutes les references ANAEL crees ou modifiees
      dka_tools_pkg.put_debug_message('  Calcul des CUF de la reference ANAEL : ' ||
                                      rec_anael.ref_address ||
                                      'dans l''org_id :' ||
                                      rec_anael.org_id); --YWA
    
      UPDATE /*+ index (t DKA_HZ_CUST_ACCT_SITES_ALL_U1) */ hz_cust_acct_sites_all t --alias "t" sur la table updatee
         SET attribute6      =
             (SELECT ca.cust_account_id --determination de l ID du client destinataire
                FROM hz_cust_accounts_all ca --a partir du CUF contenant le code client destinataire
              WHERE  ca.account_number = t.attribute1) ,
             last_update_date = SYSDATE --JV 26/09/2005
      -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
      WHERE  1=1
         AND t.cust_acct_site_id = rec_anael.cust_acct_site_id
         AND t.org_id = rec_anael.org_id
            --t.orig_system_reference = rec_anael.ref_address  --selection des sites de cette reference ANAEL
            --AND    t.org_id = rec_anael.org_id
         AND t.attribute1 IS NOT NULL
         AND t.attribute6 IS NULL; --YWA
    
      -- 27/03/2018 - NBO - artf2459074 : INC0202251 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
      Dka_Tools_Pkg.PUT_OUTDEBUG_MESSAGE(SQL%ROWCOUNT || ' lignes mise à jour.');
    
      -- NBO 25/01/18 - artf2310607 - INC0180336 :  erreurs à l'import des clients.
      -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
      /*UPDATE  hz_cust_acct_sites_all t --alias "t" sur la table updatee
      SET    attribute6 =
             (SELECT ca.cust_account_id --determination de l ID du client destinataire
              FROM   hz_cust_accounts_all ca --a partir du CUF contenant le code client destinataire
              WHERE  ca.account_number = t.attribute1) ,
             last_update_date = SYSDATE --JV 26/09/2005
      -- NBO 21/02/18 - artf2390981 - INC0192034 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE ACHAT
      -- NBO 15/02/18 - artf2310607 - INC0180336 :  erreurs à l'import des clients.
      --WHERE substr(t.orig_system_reference,5) = rec_anael.ref_address
      WHERE t.orig_system_reference LIKE '%' || rec_anael.ref_address
      AND    t.org_id = rec_anael.org_id; --YWA*/
    
      --JVI 29/03/2007 : EARS00007368651
      -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
      /*DECLARE
        CURSOR cur IS
          SELECT t.cust_acct_site_id -- ID du site client destinataire dans le meme CDG/Soc que la ligne updatee de la table "t"
          FROM   hz_cust_acct_sites_all t
          -- NBO 21/02/18 - artf2390981 - INC0192034 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE ACHAT
          -- NBO 25/01/18 - artf2310607 - INC0180336 :  erreurs à l'import des clients.
          --WHERE  t.orig_system_reference = rec_anael.ref_address
          --WHERE (substr(t.orig_system_reference,5) = rec_anael.ref_address or t.orig_system_reference = rec_anael.ref_address)
          WHERE  (t.orig_system_reference LIKE '%'||rec_anael.ref_address or t.orig_system_reference = rec_anael.ref_address)
          AND    t.org_id = rec_anael.org_id;
      
      BEGIN*/
    
      -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
      --FOR rec IN cur
      --LOOP
    
      BEGIN
      
        SELECT cas.cust_acct_site_id -- ID du site client destinataire dans le meme CDG/Soc que la ligne updatee de la table "t"
          INTO gv_attribute7
          FROM hz_cust_acct_sites_all cas,
               hz_cust_site_uses_all  csu, --site use correspondant a la table "cas"
               hz_cust_site_uses_all  csu_t, --site use correspondant a la table updatee "t"
               hz_cust_acct_sites_all t
         WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
           AND cas.attribute3 = t.attribute2 --determination de l ensemble des sites de l adresse destinataire a partir du CUF de la ligne updatee
           AND csu_t.cust_acct_site_id = t.cust_acct_site_id --recherche du site use de la table updatee "t"
           AND csu_t.site_use_code = 'BILL_TO'
           AND csu_t.location = csu.location -- dans le meme CDG --YWA
           AND cas.org_id = t.org_id
              -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
              --AND    t.cust_acct_site_id = rec.cust_acct_site_id;
           AND t.cust_acct_site_id = rec_anael.cust_acct_site_id;
      
      EXCEPTION
        WHEN no_data_found THEN
        
          SELECT MIN(cas.cust_acct_site_id)
            INTO gv_attribute7
            FROM hz_cust_acct_sites_all cas,
                 hz_cust_site_uses_all  csu, --site use correspondant a la table "cas"
                 hz_cust_acct_sites_all t
           WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
             AND cas.attribute3 = t.attribute2 --determination de l ensemble des sites de l adresse destinataire a partir du CUF de la ligne updatee
             AND cas.org_id = t.org_id
                -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
                --AND    t.cust_acct_site_id = rec.cust_acct_site_id;
             AND t.cust_acct_site_id = rec_anael.cust_acct_site_id;
      END;
    
      UPDATE /*+ index (t DKA_HZ_CUST_ACCT_SITES_ALL_U1) */ hz_cust_acct_sites_all t --alias "t" sur la table updatee
         SET attribute7 = gv_attribute7
      -- 13/03/2018 NBO artf2432434 : INC0199851 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE
      --WHERE  t.cust_acct_site_id = rec.cust_acct_site_id; --selection des sites de cette reference ANAEL
       WHERE t.cust_acct_site_id = rec_anael.cust_acct_site_id;
      -- END LOOP;
      --END;
    
      dka_tools_pkg.put_debug_message('     ...' || SQL%ROWCOUNT ||
                                      ' lignes modifiees.');
    END LOOP;
  
    dka_tools_pkg.put_outdebug_message('Post_oi: Désactivation des relations payeurs/destinataires non valides...');
    --JVI 17/12/2007 : On désactive les relations payeurs/destinataires non valides
    UPDATE hz_cust_acct_relate_all r
    SET    STATUS           = 'I',
           LAST_UPDATE_DATE = SYSDATE
     WHERE EXISTS
     (SELECT 1
              FROM hz_cust_acct_relate_all  hca,
                   ar_customers             dest,
                   ar_customers             payeur,
                   dka_iclientifs_interface dii
             WHERE dest.customer_id = hca.cust_account_id
               AND payeur.customer_id = hca.related_cust_account_id
               AND dii.customer_number = payeur.customer_number
               AND dest.customer_number !=
                   nvl(dii.code_client_destinataire, 1)
               AND NOT EXISTS
             (SELECT 1 --YWA MIGRATION R12
                      FROM hz_cust_acct_sites_all hcasa
                     WHERE hcasa.cust_account_id = payeur.customer_id
                       AND hcasa.attribute3 != dii.ref_address
                       AND hcasa.attribute1 = dest.customer_number)
               AND NOT EXISTS
             (SELECT 1
                      FROM dka_iclientifs_interface di
                     WHERE di.customer_number = dii.customer_number
                       AND di.code_client_destinataire = dest.customer_number)
               AND hca.status != 'I'
               AND hca.related_cust_account_id = r.related_cust_account_id
               AND hca.cust_account_id = r.cust_account_id);
    dka_tools_pkg.put_debug_message('     ...' || SQL%ROWCOUNT ||
                                    ' relations désactivées');
  
    --Purge de la table d interface client
    --On laisse les lignes rejetees
    dka_tools_pkg.put_outdebug_message('Post_oi: purge des lignes d interface traitees...');
    DELETE DKA_ICLIENTIFS_INTERFACE
    WHERE  oa_status = 'P';
    dka_tools_pkg.put_outdebug_message(SQL%ROWCOUNT || ' lignes purgees.');
  
  END post_oi;

  -- 05/11/2019 - NBO - artf07233449 - EDB242 - DGE20190012 - OracleR12_Finance_AR_Import factures client_Duplication automatique site client  
  -------------------------------------------------------------------------------------
  --  Nom           : pre_import_client
  --  Description   : Duplication des sites non existant liés aux factures client
  ------------------------------------------------------------------------------------
  PROCEDURE pre_import_client(pv_errbuf  IN OUT VARCHAR2,
                              pn_retcode OUT NUMBER) IS
    CURSOR cur_site_client IS
      SELECT DISTINCT region, company_code, sub_account
        FROM dka_iarpafac_interface dii
       WHERE sub_account IS NOT NULL
         AND NOT EXISTS
       (SELECT 'x'
                FROM hz_cust_acct_sites_all hcasa,
                     hz_cust_accounts       hca,
                     hz_cust_site_uses_all  hcsua,
                     hr_operating_units     hou
               WHERE hca.cust_account_id = hcasa.cust_account_id
                 AND hcasa.attribute3 = dii.sub_account
                 AND hcasa.org_id = hou.organization_id
                 AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
                 AND hou.name = dii.region || dii.company_code)
         AND EXISTS
       (SELECT 'x'
                FROM hz_cust_acct_sites_all hcasa,
                     hz_cust_accounts       hca,
                     hz_cust_site_uses_all  hcsua
               WHERE hca.cust_account_id = hcasa.cust_account_id
                 AND hcasa.attribute3 = dii.sub_account
                 AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id);
    l_count  NUMBER;
    l_count2 NUMBER;
  
    lv_account_number       VARCHAR2(30);
    lv_customer_name        VARCHAR2(100);
    lv_category_code        VARCHAR2(50);
    ln_cust_acct_site_id    NUMBER;
    lv_attribute3           VARCHAR2(100);
    ln_cust_account_id      NUMBER;
    lv_customer_class_code  VARCHAR2(100);
    ln_party_id             NUMBER;
    lv_intracom_number      VARCHAR2(150);
    lv_destinataire         VARCHAR2(150);
    lv_adresse_destinataire VARCHAR2(150);
    lv_reference_anael      VARCHAR2(150);
    lv_partenaire_interco   VARCHAR2(150);
    lv_siret                VARCHAR2(150);
    lv_nom1                 VARCHAR2(150);
    lv_nom2                 VARCHAR2(150);
    lv_address3             VARCHAR2(150);
    lv_address4             VARCHAR2(150);
    lv_city                 VARCHAR2(100);
    lv_postal_code          VARCHAR2(50);
    lv_country              VARCHAR2(50);
    lv_collector            VARCHAR2(50);
    lv_profile_class_name   VARCHAR2(50);
    ln_org_id               NUMBER;
    lv_org_name             VARCHAR2(50);
    
    lv_step VARCHAR2(200);
  
  BEGIN
    pn_retcode := 0;
    
    lv_step := 'BEGIN';
  
    /*
    
    En plus de la duplication du client pour l¿ensemble des sociétés du centre de gestion, le traitement devra vérifier les clients des factures présents dans 
    la table spécifique des mouvements AR (dka_iarpafac_interface). Cette vérification sera effectuée juste avant de lancer le traitement standard d¿import des clients.
    
    Si aucun site client n¿existe pour la même référence d¿adresse : 
    -  Aucune action n¿est à réaliser.
    
    Si la référence de l¿adresse existe mais pour une autre UO que celle de la facture :
    
    -  Les tables d¿open interface des clients seront alimentées à partir des informations récupérer de l¿adresse existant dans Oracle sur la société 0001. La duplication sera effectuée même si le site est sur une région différente de la facture.
    
    Une vérification sera effectuée afin de ne pas réinsérer le site client s¿il existe déjà dans la table d¿open interface des clients.
    
    
    */
    FOR rec_site_client IN cur_site_client LOOP
      
    lv_step := 'LOOP rec_site_client';
    
      SELECT COUNT(1)
        INTO l_count
        FROM dka_iclientifs_interface
       WHERE ref_address = rec_site_client.sub_account
         AND cdg = rec_site_client.region;
       --  AND soc = rec_site_client.company_code;
    
      SELECT COUNT(1)
        INTO l_count2
        FROM ra_customers_interface_all rci, hr_operating_units hou
       WHERE rci.org_id = hou.organization_id
         AND hou.name =
             rec_site_client.region || rec_site_client.company_code
         AND address_attribute3 = rec_site_client.sub_account;
    
      IF l_count = 0 AND l_count2 = 0 THEN
        lv_step := 'PREMIER IF :' || rec_site_client.sub_account || '/'|| rec_site_client.region || '/'||
                              rec_site_client.company_code;
      
        BEGIN
          SELECT hca.account_number,
                 ac.customer_name,
                 pty.category_code,
                 hcasa.cust_acct_site_id,
                 hca.cust_account_id,
                 hca.customer_class_code,
                 pty.party_id,
                 org.tax_reference       intracom_number,
                 hcasa.attribute1        destinataire,
                 hcasa.attribute2        adresse_destinataire,
                 hcasa.attribute3        reference_anael,
                 hcasa.attribute8        partenaire_interco,
                 hcasa.attribute11       siret,
                 hl.address1             nom1,
                 hl.address2             nom2,
                 hl.address3,
                 hl.address4,
                 hl.city,
                 hl.postal_code,
                 hl.country,
                 ac.name                 collector,
                 hcpc.name               profile_class_name,
                 hcasa.org_id,
                 hou.name                org_name
            INTO lv_account_number,
                 lv_customer_name,
                 lv_category_code,
                 ln_cust_acct_site_id,
                 ln_cust_account_id,
                 lv_customer_class_code,
                 ln_party_id,
                 lv_intracom_number,
                 lv_destinataire,
                 lv_adresse_destinataire,
                 lv_reference_anael,
                 lv_partenaire_interco,
                 lv_siret,
                 lv_nom1,
                 lv_nom2,
                 lv_address3,
                 lv_address4,
                 lv_city,
                 lv_postal_code,
                 lv_country,
                 lv_collector,
                 lv_profile_class_name,
                 ln_org_id,
                 lv_org_name
            FROM hz_cust_acct_sites_all   hcasa,
                 hz_cust_accounts         hca,
                 ar_customers             ac,
                 hz_cust_site_uses_all    hcsua,
                 hr_operating_units       hou,
                 hz_parties               pty,
                 hz_organization_profiles org,
                 hz_party_sites           hps,
                 hz_locations             hl,
                 hz_customer_profiles     hcp,
                 hz_cust_profile_classes  hcpc,
                 ar_collectors            ac
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND ac.customer_id = hca.cust_account_id
             AND hcasa.attribute3 = rec_site_client.sub_account
             AND hcasa.org_id = hou.organization_id
             AND org.party_id = pty.party_id
             AND org.effective_end_date IS NULL
             AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
             --AND hou.name LIKE '%001'
             AND hou.name = rec_site_client.region || '0001'
             AND hca.party_id = pty.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hl.location_id = hps.location_id
             AND hcp.cust_account_id = hcasa.cust_account_id
             AND hcp.site_use_id = hcsua.site_use_id
             AND hcp.collector_id = ac.collector_id
             AND hcp.profile_class_id = hcpc.profile_class_id
             AND rownum = 1;
        EXCEPTION
          WHEN no_data_found THEN
            BEGIN
              lv_step := 'DEUXIEME SELECT';
              SELECT hca.account_number,
                   ac.customer_name,
                   pty.category_code,
                   hcasa.cust_acct_site_id,
                   hca.cust_account_id,
                   hca.customer_class_code,
                   pty.party_id,
                   org.tax_reference       intracom_number,
                   hcasa.attribute1        destinataire,
                   hcasa.attribute2        adresse_destinataire,
                   hcasa.attribute3        reference_anael,
                   hcasa.attribute8        partenaire_interco,
                   hcasa.attribute11       siret,
                   hl.address1             nom1,
                   hl.address2             nom2,
                   hl.address3,
                   hl.address4,
                   hl.city,
                   hl.postal_code,
                   hl.country,
                   hcpc.name               profile_class_name,
                   hcasa.org_id,
                   hou.name                org_name
              INTO lv_account_number,
                   lv_customer_name,
                   lv_category_code,
                   ln_cust_acct_site_id,
                   ln_cust_account_id,
                   lv_customer_class_code,
                   ln_party_id,
                   lv_intracom_number,
                   lv_destinataire,
                   lv_adresse_destinataire,
                   lv_reference_anael,
                   lv_partenaire_interco,
                   lv_siret,
                   lv_nom1,
                   lv_nom2,
                   lv_address3,
                   lv_address4,
                   lv_city,
                   lv_postal_code,
                   lv_country,
                   lv_profile_class_name,
                   ln_org_id,
                   lv_org_name
              FROM hz_cust_acct_sites_all   hcasa,
                   hz_cust_accounts         hca,
                   ar_customers             ac,
                   hz_cust_site_uses_all    hcsua,
                   hr_operating_units       hou,
                   hz_parties               pty,
                   hz_organization_profiles org,
                   hz_party_sites           hps,
                   hz_locations             hl,
                   hz_customer_profiles     hcp,
                   hz_cust_profile_classes  hcpc
             WHERE hca.cust_account_id = hcasa.cust_account_id
               AND ac.customer_id = hca.cust_account_id
               AND hcasa.attribute3 = rec_site_client.sub_account
               AND hcasa.org_id = hou.organization_id
               AND org.party_id = pty.party_id
               AND org.effective_end_date IS NULL
               AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
               AND hou.name LIKE '%0001'
               AND hca.party_id = pty.party_id
               AND hcasa.party_site_id = hps.party_site_id
               AND hl.location_id = hps.location_id
               AND hcp.cust_account_id = hcasa.cust_account_id
               AND hcp.site_use_id = hcsua.site_use_id
               AND hcp.profile_class_id = hcpc.profile_class_id
               AND rownum = 1;
               
            lv_collector := rec_site_client.region || '000';
          EXCEPTION
            WHEN no_data_found THEN
              ln_cust_acct_site_id := NULL;
              ln_cust_account_id   := NULL;
          END;
            
        END;
        
        lv_step := 'INSERT';
      
        IF ln_cust_account_id IS NOT NULL THEN
        
          INSERT INTO dka.dka_iclientifs_interface
            (customer_name,
             customer_number,
             intracom_number,
             customer_status,
             customer_category,
             customer_class,
             nom1,
             nom2,
             address1,
             address2,
             city,
             postal_code,
             country,
             address_status,
             profil_class,
             partner_code,
             code_client_destinataire,
             adresse_client_destinataire,
             recipient_only_flag,
             ref_address,
             insert_update_flag,
             --cdg,
             --soc,
             oa_status,
             num_siret,
             TIMESTAMP)
          VALUES
            (lv_customer_name,
             lv_account_number,
             lv_intracom_number,
             'A',
             lv_category_code,
             lv_customer_class_code,
             lv_nom1,
             lv_nom2,
             lv_address3,
             lv_address4,
             lv_city,
             lv_postal_code,
             lv_country,
             'A',
             lv_profile_class_name,
             lv_partenaire_interco,
             lv_destinataire,
             lv_adresse_destinataire,
             'N',
             lv_reference_anael,
             'I',
             --rec_site_client.region,
             --rec_site_client.company_code,
             NULL,
             lv_siret,
             SYSDATE);
        
          INSERT INTO dka_iclientifs_collectors
            (customer_number, cdg, collector, oa_status, TIMESTAMP)
          VALUES
            (lv_account_number,
             rec_site_client.region,
             lv_collector,
             'N',
             SYSDATE);
             
          dka_tools_pkg.put_log_message('Le site client ''' ||
                              rec_site_client.sub_account ||
                              ''' du client '||lv_account_number||' n''existe pas dans le referentiel sur l''organisation ' ||
                              rec_site_client.region ||
                              rec_site_client.company_code);
       END IF;
      
      ELSE
          dka_tools_pkg.put_log_message('Le site client ''' ||
                              rec_site_client.sub_account ||
                              ''' existe dans OI sur l''organisation ' ||
                              rec_site_client.region ||
                              rec_site_client.company_code);        
      END IF;
    
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      dka_tools_pkg.put_log_message(lv_step || '=> ' || pv_errbuf);
  END pre_import_client;

END dka_iclientifs_pkg;
/
SHOW ERRORS;
EXIT