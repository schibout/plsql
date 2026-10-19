create or replace PACKAGE BODY DKA_APFRSEXP_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_APFRSEXP_PKG.sql                                    -
    -- Version : 1.0                                                     -
    -- AUTEUR  : Y.Warid / SOCIETE : CAPGEMINI                           -
    -- DATE    : 26/05/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : DKA : Export des fournisseurs                        -
    -- FONCTION   : INT001                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :     1.1                                    -
    -- PROGRAMME MODIFIE LE :     16/01/2017                             -
    -- PAR                  :     Maxime EGOT                            -
    -- NUM_ANOMALIE         :                                            -
    -- OBJET                :     Evolution EDB38                        -
    --                                                                   -
    ----------------------------------------------------------------------
    --- HISTORIQUE DES MODIFICATIONS
    --- Date       Qui Description
    --- 31/01/2017 YWA artf2090773 
    --- 06/02/2017 OBE Modification - artf2096185
    --- 20/02/2017 RBE Correction artf2104094 
    --- 08/03/2017 YWA artf2115232 + suppression des tabulations dans toutes les lignes écrites dans les fichiers
    --- 19/04/2017 OBE artf2141490 : INT001 - Méthode de règlement sur site fournisseur - Bout_en_Bout_Helios_Ref #572
    --- 03/05/2017 RBE artf2147539 : INT001 - Filtre sur les fournisseurs de type EMPLOYEE - EDB052
    --- 06/07/2017 RBE artf2191673 : INT001 - Extraction fournisseur sans type renseigné - defect BeB #572
    --- 31/01/2018 RBE artf2338800 : DPE20180004 - Evolution - Export des fournisseurs
    --- 04/08/2020 AAM EDB006      : Exclusion des sites de l’UO de référence
	--- 02/12/2020 SELO artf07424252 : INC0485323 - INT001 Prise en compte modifications relation factor  
    ----------------------------------------------------------------------
    
    /*=====================================================================================*/
    /* Procedure         : Export_journalier                                               */
    /* Description       : Procedure principale qui extrait les donnees eligibles          */ 
    /*                     et qui respecte les regles de gestion puis ecrit le fichier     */     
    /* Parametres entree : p_errbuff  IN OUT VARCHAR2 :                                    */
    /*                   : p_retcode  IN OUT NUMBER   :                                    */
    /* Parametres sortie : AUCUN                                                           */
    /* Remarques         :                                                                 */
    /*=====================================================================================*/     
    PROCEDURE Export_journalier( p_errbuff                IN OUT VARCHAR2,
                                 p_retcode                IN OUT NUMBER
                    )
    IS
    
        -- ========== VARIABLES ==========
        v_package            VARCHAR2(30)  := 'DKA_APFRSEXP_PKG';
        v_nom_traitement     VARCHAR2(200) := 'Export des fournisseurs journalier';
        v_sqlerrm            VARCHAR2(250) := NULL;

        v_nom_chemin         VARCHAR2(250) := 'DKA_OUT_DIR';-- temporaire a remplacer par 'REP_DATA_OUT';
        v_fichier_courant    VARCHAR2(100);

        v_procedure          VARCHAR2(30)    := 'Export_journalier';
        v_message            VARCHAR2(500);

        
        v_cur_vide           BOOLEAN := TRUE;
        v_cur_site_vide      BOOLEAN := TRUE;
        
        v_non_fi_fournisseurs  VARCHAR2(50)    := 'FOURNISSEURS_DELTA_';
        v_non_fi_contact       VARCHAR2(50)    := 'FOURNISSEURS_CONTACTS_DELTA_';

        v_ext   VARCHAR2(30)    := '.dat';
        --v_prefix VARCHAR2(30)    := 'DKA_REP_';
        v_f                    utl_file.file_type;
        v_csf                  utl_file.file_type;

        
        v_f_count     NUMBER := 0;
        v_csf_count   NUMBER := 0;

        -- curseur sur fournisseur avec les champs a extraire selon les regles elligibilite sur les sites fournisseurs pour l'export journalier
        CURSOR cur_fournisseur
        IS
            SELECT  pv.vendor_id ,
                    pv.segment1 code_fournisseur,
                    pv.vendor_name nom_fournisseur_long,--YWA artf2115232 
                    SUBSTR(pv.vendor_name,0,35) nom_fournisseur_court,
                    pv.attribute2 code_partenaire,
                    DECODE(upper(pv.vendor_type_lookup_code), 'EMPLOYEE', papf.national_identifier, DECODE(pv.organization_type_lookup_code, 'INDIVIDUAL',pv.individual_1099, 'FOREIGN INDIVIDUAL',pv.individual_1099, hp.jgzz_fiscal_code)) num_siren ,
                    hp.tax_reference num_tva ,
                    pv.vat_registration_num num_tva_1,
                    pv.vendor_type_lookup_code type_fournisseur,
                    pv.standard_industry_class num_ape ,
                    NVL(pv.attribute1,'N') fournisseur_service,
                    NVL(pv.attribute3,'N') fournisseur_combustible,
                    TO_CHAR(pv.last_update_date,'YYYYMMDD') date_maj_entete,
                    TO_CHAR(pv.creation_date,'YYYYMMDD') creation_fournisseur,
                    TO_CHAR(pv.end_date_active,'YYYYMMDD')  fin_activite_fournisseur,
                    pv.attribute4 code_accord,
                    pv.federal_reportable_flag,
                    pv.attribute8 classification_achat,
                    pv.party_id,
                    --decode(sign(NVL(TO_DATE(pv.attribute12,'YYYY/MM/DD HH24:MI:SS'),pv.last_update_date-1) - pv.last_update_date),-1, 'ENTETE', 0, null,'SITE') type_modif
                    CASE WHEN 
                      NVL(TO_DATE(pv.attribute12,'YYYY/MM/DD HH24:MI:SS'),pv.last_update_date-1) < pv.last_update_date
                      THEN 'ENTETE' 
                     WHEN EXISTS(SELECT 1
                        FROM ap_supplier_sites_all assa
                        WHERE assa.vendor_id                                                    =pv.vendor_id
                        AND NVL(TO_DATE(assa.attribute12,'YYYY/MM/DD HH24:MI:SS'),assa.last_update_date-1) < assa.last_update_date) then 'SITE'
                    --	SELO - DEBUT : artf07424252
					 WHEN EXISTS 
					    (SELECT distinct 1
						   FROM IBY_EXT_PAYEE_RELATIONSHIPS ExtRelationshipsEO,
						        ap_supplier_sites_all apsite_inv,
								hr_operating_units hou 
						  WHERE ExtRelationshipsEO.supplier_site_id = apsite_inv.vendor_site_id 
						    AND apsite_inv.vendor_id  =pv.vendor_id
                            AND apsite_inv.org_id  =hou.organization_id
                            AND hou.name !='REF9999'
							AND NVL(TO_DATE(ExtRelationshipsEO.attribute12,'YYYY/MM/DD HH24:MI:SS'),ExtRelationshipsEO.last_update_date-1) < ExtRelationshipsEO.last_update_date
						) THEN 'SITE'
					--	SELO - FIN : artf07424252
					
                  /* when exists(SELECT 1
                        FROM po_vendor_contacts pvc
                        WHERE pvc.vendor_id                                                    =pv.vendor_id
                        AND NVL(TO_DATE(pvc.attribute12,'YYYY/MM/DD HH24:MI:SS'),pvc.last_update_date-1) < pvc.last_update_date)then 'CONTACT' end as type_modif*/
                   ELSE  'CONTACT'  end as type_modif
            FROM    po_vendors pv,
                    hz_parties hp ,
                    per_all_people_f papf
            WHERE   pv.party_id                                                     = hp.party_id
            AND     NVL(PV.VENDOR_TYPE_LOOKUP_CODE,'N/A') <> 'EMPLOYEE'  -- RBE artf2147539, artf2191673
            AND     pv.employee_id                                                  = papf.person_id (+)
            AND     NVL(papf.effective_end_date,SYSDATE)                           >= SYSDATE
            AND     (NVL(TO_DATE(pv.attribute12,'YYYY/MM/DD HH24:MI:SS'),pv.last_update_date-1) < pv.last_update_date
                    OR EXISTS
                        (SELECT 1
                        FROM ap_supplier_sites_all assa
                        ,    hr_operating_units hou --AAM
                        WHERE assa.vendor_id                                                    =pv.vendor_id
                        AND   assa.org_id                                                       =hou.organization_id --AAM
                        AND   hou.name                                                          !='REF9999'          --AAM
                        AND NVL(TO_DATE(assa.attribute12,'YYYY/MM/DD HH24:MI:SS'),assa.last_update_date-1) < assa.last_update_date
                        )
                    OR EXISTS
                        (SELECT 1
                        FROM po_vendor_contacts pvc
                        WHERE pvc.vendor_id                                                    =pv.vendor_id
                        AND NVL(TO_DATE(pvc.attribute12,'YYYY/MM/DD HH24:MI:SS'),pvc.last_update_date-1) < pvc.last_update_date
                        )
					--	SELO - DEBUT : artf07424252
					OR EXISTS
					    (SELECT distinct 1
						   FROM IBY_EXT_PAYEE_RELATIONSHIPS ExtRelationshipsEO,
						        ap_supplier_sites_all apsite_inv,
								hr_operating_units hou 
						  WHERE ExtRelationshipsEO.supplier_site_id = apsite_inv.vendor_site_id 
						    AND apsite_inv.vendor_id  =pv.vendor_id
                            AND apsite_inv.org_id  =hou.organization_id
                            AND hou.name !='REF9999'
							AND NVL(TO_DATE(ExtRelationshipsEO.attribute12,'YYYY/MM/DD HH24:MI:SS'),ExtRelationshipsEO.last_update_date-1) < ExtRelationshipsEO.last_update_date
						)
					--	SELO - FIN : artf07424252
					);

    BEGIN

        -- Initialization des journaux --
        Dka_Tools_Pkg.Put_Outdebug_Message('================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('Extraction fourniseur DKA_APFRSEXP_PKG');
        Dka_Tools_Pkg.Put_Outdebug_Message('================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Dka_Tools_Pkg.Put_Outdebug_Message('Numero de traitement : ' || TO_CHAR(FND_GLOBAL.CONC_REQUEST_ID));
        Dka_Tools_Pkg.Put_Outdebug_Message('================================================');

        -- Initialisation des variables d'anomalies
        p_retcode   := 0;
        p_errbuff   := NULL;
        v_message   := 'Debut procedure MAIN';

        -- Ouverture des fichiers
        v_message   := 'Ouverture des fichiers';
        Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
        
        v_non_fi_fournisseurs   := v_non_fi_fournisseurs||TO_CHAR(SYSDATE,'YYYYMMDD')||v_ext;
        v_fichier_courant       := v_non_fi_fournisseurs;
        v_f:=utl_file.fopen(v_nom_chemin,v_non_fi_fournisseurs,'W',32754);
        
        v_non_fi_contact   := v_non_fi_contact||TO_CHAR(SYSDATE,'YYYYMMDD')||v_ext;
        v_fichier_courant  := v_non_fi_contact;
        v_csf := utl_file.fopen(v_nom_chemin,v_non_fi_contact,'W',32754);

        ----premiere ligne detaillant le contenu des champs du fichier founisseurs
        --utl_file.put_line(v_f,);

        ---boucle sur le curseur des fournisseurs eligibles
        v_message   := 'Ouverture du curseur des fournisseurs';
        Dka_Tools_Pkg.put_log_message(v_message);
        
        FOR fourniseur IN cur_fournisseur LOOP
            
            --variable si curseur vide
            v_cur_vide       := FALSE;
            v_cur_site_vide  := TRUE;
           
            --ecriture dans le fichier fournisseur
            --v_message   := 'Ecriture dans le fichier fournisseur';
            --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
           
            IF fourniseur.nom_fournisseur_court IS NULL THEN
                v_message   := 'Le founisseur '||fourniseur.code_fournisseur||' ne sera pas extrait';
                Dka_Tools_Pkg.put_log_message(v_message);
                CONTINUE;
            END IF;
            
            --RBE artf2338800
            IF fourniseur.num_siren IS NULL THEN
                fourniseur.num_siren := 'PROVISOIRE';
                v_message   := 'Fournisseur ('||fourniseur.nom_fournisseur_court||') : Le champ SIREN est vide, il a été remplacé par la valeur PROVISOIRE';
                Dka_Tools_Pkg.put_log_message(v_message);
            END IF;
            
            IF fourniseur.type_modif = 'ENTETE' THEN
            
                v_message   := '(Type : ENTETE) Extraction du site pour le fournisseur '||fourniseur.code_fournisseur;
                Dka_Tools_Pkg.put_log_message(v_message);
                
                FOR site_fourniseur IN (SELECT assa.vendor_site_id,
                                               assa.party_site_id,
                                               assa.attribute1 complement_siret,
                                               fourniseur.num_siren ||NVL(assa.attribute1,'PROVI') code_rcs, --RBE artf2338800
                                               assa.vendor_site_code code_site_fournisseur,
                                               assa.address_line1 adresse1,
                                               assa.address_line2 adresse2,
                                               assa.address_line3 adresse3,
                                               assa.address_line4 adresse4,
                                               assa.city ville,
                                               assa.zip code_postal,
                                               assa.country pays,
                                               hcp1.phone_number telephone,
                                               hcp2.phone_number fax,
                                               TO_CHAR(assa.creation_date,'YYYYMMDD') date_creation_site,
                                               TO_CHAR(assa.inactive_date,'YYYYMMDD') date_fin_site,
                                               shiploc.location_id ship_location_id,
                                               shiploc.location_code ship_location_code,
                                               shiploc.address_line_1||' '||shiploc.address_line_2||' '||shiploc.address_line_3 adresse_livraison,
                                               billloc.location_id bill_location_id,
                                               billloc.location_code bill_location_code,
                                               billloc.address_line_1||' '||billloc.address_line_2||' '||billloc.address_line_3 adresse_facturation,
                                               (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                               FROM gl_code_combinations WHERE code_combination_id=assa.accts_pay_code_combination_id) compte_fournisseur,
                                               (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                               FROM gl_code_combinations WHERE code_combination_id=assa.prepay_code_combination_id) compte_acompte,
                                               assa.accts_pay_code_combination_id,
                                               assa.prepay_code_combination_id,
                                               TO_CHAR(assa.last_update_date,'YYYYMMDD') date_maj_site,
                                               assa.province province,
                                               NVL(assa.purchasing_site_flag,'N')  site_achat,
                                               NVL(assa.pay_site_flag,'N') site_paiement,
                                               --DECODE (fourniseur.type_fournisseur,'FACTOR',assa.attribute5,null) affacturage,
                                               CASE WHEN EXISTS (SELECT 1 from iby_ext_payee_relationships where supplier_site_id=assa.vendor_site_id 
                                               AND party_id=fourniseur.party_id  AND primary_flag= 'Y' 
                                               AND (sysdate BETWEEN from_date AND NVL(TO_DATE,sysdate))) THEN 'Y'
                                               ELSE  NULL  END AS affacturage,
                                               (SELECT name FROM hr_operating_units WHERE organization_id=assa.org_id )  code_uo,
                                               assa.offset_tax_flag flag_intracommunautaire,
                                               hcp3.email_address,
                                               DECODE(pm.payment_method_code,'WIRE',1,0)f_treglement
                                        FROM   ap_supplier_sites_all assa,
                                               hr_operating_units hou, --AAM
                                               hz_party_sites        hps,
                                               hz_contact_points     hcp1,
                                               hz_contact_points     hcp2,
                                               hz_contact_points     hcp3,
                                               hr_locations_all      shiploc,
                                               hr_locations_all      billloc,
                                               iby_external_payees_all payee,
                                               iby_ext_party_pmt_mthds pm
                                        WHERE  vendor_id = fourniseur.vendor_id
                                        AND    assa.org_id = hou.organization_id --AAM
                                        AND    hou.name    !='REF9999'           --AAM
                                        AND    hps.party_site_id(+) = assa.party_site_id
                                        AND    hcp1.owner_table_id(+) = hps.party_site_id
                                        AND    hcp1.contact_point_type(+) = 'PHONE'
                                        AND    hcp1.phone_line_type(+) = 'GEN'
                                        AND    hcp1.status(+) = 'A'
                                        AND    hcp1.owner_table_name(+) = 'HZ_PARTY_SITES'
                                        AND    hcp1.primary_flag(+) = 'Y'
                                        --< OBE
                                        AND   (hcp1.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp1.owner_table_id
                                                                            AND   contact_point_type = 'PHONE'
                                                                            AND   phone_line_type    = 'GEN'
                                                                            AND   status             = 'A'
                                                                            AND   primary_flag       = 'Y'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp1.contact_point_id,NULL,1,2)    
                                                )                                        
                                        --> OBE
                                        AND    hcp2.owner_table_id(+) = hps.party_site_id
                                        AND    hcp2.contact_point_type(+) = 'PHONE'
                                        AND    hcp2.phone_line_type(+) = 'FAX'
                                        AND    hcp2.status(+) = 'A'
                                        AND    hcp2.owner_table_name(+) = 'HZ_PARTY_SITES'
                                        --< OBE
                                        AND   (hcp2.contact_point_id    = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp2.owner_table_id
                                                                            AND   contact_point_type = 'PHONE'
                                                                            AND   phone_line_type    = 'FAX'
                                                                            AND   status             = 'A'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp2.contact_point_id,NULL,1,2)    
                                                )                                        
                                        --> OBE
                                        AND    shiploc.ship_to_site_flag(+) = 'Y'
                                        AND    hcp3.contact_point_type(+) = 'EMAIL' 
                                        AND    hcp3.owner_table_id(+) = hps.party_site_id
                                        AND    hcp3.status(+) = 'A' 
                                        AND    hcp3.owner_table_name(+) = 'HZ_PARTY_SITES' 
                                        AND    hcp3.primary_flag(+) = 'Y' 
                                        --< OBE
                                        AND   (hcp3.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp3.owner_table_id
                                                                            AND   contact_point_type = 'EMAIL'
                                                                            AND   status             = 'A'
                                                                            AND   primary_flag       = 'Y'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp3.contact_point_id,NULL,1,2)    
                                                )                                                
                                        --> OBE
                                        AND    sysdate < NVL(TRUNC(shiploc.inactive_date), sysdate + 1)
                                        AND    shiploc.location_id(+) = assa.ship_to_location_id
                                        AND    billloc.ship_to_site_flag(+) = 'Y'
                                        AND    sysdate < NVL(TRUNC(billloc.inactive_date), sysdate + 1)
                                        AND    billloc.location_id(+) = assa.bill_to_location_id
                                        --AND    payee.payee_party_id = hps.party_id
                                        AND    payee.payment_function = 'PAYABLES_DISB'
                                        --AND    payee.party_site_id = assa.party_site_id
                                        AND    payee.supplier_site_id = assa.vendor_site_id
                                        AND    payee.org_id = assa.org_id
                                        AND    payee.org_type = 'OPERATING_UNIT'
                                        AND    payee.ext_payee_id = pm.ext_pmt_party_id (+)
                                        --< OBE artf2141490 
                                        --AND    pm.primary_flag  = 'Y'
                                        AND NVL(pm.primary_flag,'Y')  = 'Y' 
                                        AND payee.party_site_id IS NOT NULL
                                        --> OBE artf2141490
                                        --AND   NVL(TO_DATE(assa.attribute12,'YYYY/MM/DD HH24:MI:SS'),assa.last_update_date-1) < assa.last_update_date
                           )
    
                LOOP
                    
                    v_cur_site_vide     := FALSE;
                    
                    --v_message   := 'Ecriture des informations des sites fournisseurs pour chaque fournisseur';
                    --Dka_Tools_Pkg.Put_Outdebug_Message('Ecriture des informations du site fournisseur '||site_fourniseur.code_site_fournisseur||' eligibles pour le fournisseur '|| fourniseur.code_fournisseur);
                    --RBE artf2338800
                    IF LENGTH(site_fourniseur.telephone) > 15 THEN
                        site_fourniseur.telephone := REPLACE (site_fourniseur.telephone,' ','');
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        IF LENGTH(site_fourniseur.telephone) > 15 THEN
                            site_fourniseur.telephone :=  SUBSTR(site_fourniseur.telephone,1,15);
                            v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                            Dka_Tools_Pkg.put_log_message(v_message);
                        END IF;
                    END IF;

                    --RBE artf2338800
                    IF LENGTH(site_fourniseur.FAX) > 15 THEN
                        site_fourniseur.FAX := REPLACE (site_fourniseur.FAX,' ','');
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, les espaces sont supprimés';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        IF LENGTH(site_fourniseur.FAX) > 15 THEN
                            site_fourniseur.FAX :=  SUBSTR(site_fourniseur.FAX,1,15);
                            v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, le champ a été tronqué ';
                            Dka_Tools_Pkg.put_log_message(v_message);
                        END IF;
                    END IF;
                    
                    --RBE artf2338800
                    IF site_fourniseur.complement_siret IS NULL THEN
                        site_fourniseur.complement_siret := 'PROVI';
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : Le champ complément SIRET est vide, il a été remplacé par la valeur PROVI';
                        Dka_Tools_Pkg.put_log_message(v_message);
                    END IF;
                    
                    v_fichier_courant := v_non_fi_fournisseurs;
                    utl_file.put_line(v_f, REPLACE(fourniseur.code_fournisseur            ||';'||                
                                            REPLACE(fourniseur.nom_fournisseur_long,';',' ')        ||';'||                
                                            fourniseur.nom_fournisseur_court      ||';'||                
                                            fourniseur.code_partenaire            ||';'||                
                                            fourniseur.num_siren                  ||';'||                
                                            site_fourniseur.complement_siret      ||';'||  
                                            site_fourniseur.code_rcs              ||';'||                                
                                            fourniseur.num_tva                    ||';'||                
                                            fourniseur.type_fournisseur           ||';'||                
                                            fourniseur.num_ape                    ||';'||                
                                            site_fourniseur.code_site_fournisseur ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse1,';',''),'"','')              ||';'||   --artf2090773                               
                                            REPLACE(REPLACE(site_fourniseur.adresse2,';',''),'"','')              ||';'||   --artf2090773                              
                                            REPLACE(REPLACE(site_fourniseur.adresse3,';',''),'"','')              ||';'||   --artf2090773                              
                                            REPLACE(REPLACE(site_fourniseur.adresse4,';',''),'"','')              ||';'||   --artf2090773                              
                                            site_fourniseur.ville                 ||';'||                                
                                            site_fourniseur.code_postal           ||';'||
                                            site_fourniseur.pays                  ||';'||
                                            site_fourniseur.telephone             ||';'||
                                            site_fourniseur.fax                   ||';'||
                                            site_fourniseur.date_creation_site    ||';'||
                                            site_fourniseur.date_fin_site         ||';'||
                                            site_fourniseur.adresse_livraison     ||';'||
                                            site_fourniseur.adresse_facturation   ||';'||
                                            site_fourniseur.compte_fournisseur    ||';'||
                                            site_fourniseur.compte_acompte        ||';'||
                                            fourniseur.fournisseur_service        ||';'||
                                            fourniseur.fournisseur_combustible    ||';'||
                                            fourniseur.date_maj_entete            ||';'||
                                            site_fourniseur.date_maj_site         ||';'||
                                            fourniseur.creation_fournisseur       ||';'||
                                            fourniseur.fin_activite_fournisseur   ||';'||
                                            site_fourniseur.province              ||';'||
                                            fourniseur.code_accord                ||';'||
                                            site_fourniseur.site_achat            ||';'||
                                            site_fourniseur.site_paiement         ||';'||
                                            site_fourniseur.affacturage           ||';'||
                                            fourniseur.federal_reportable_flag    ||';'||
                                            site_fourniseur.code_uo               ||';'||
                                            fourniseur.classification_achat       ||';'||
                                            site_fourniseur.flag_intracommunautaire  ||';'||  
                                            REPLACE(site_fourniseur.email_address,';','')            ||';'|| --artf2090773 
                                            site_fourniseur.vendor_site_id           ||';'|| 
                                            site_fourniseur.f_treglement ,chr(9),''));  --YWA artf2115232
                    
                    
                    FOR contact_fourniseur IN (SELECT  vendor_contact_id,
                                                    vendor_id,
                                                    vendor_site_id,
                                                    last_name nom_contact,    -- RBE artf2104094 
                                                    first_name prenom_contact,-- RBE artf2104094 
                                                    title fonction,
                                                    phone telephone,
                                                    email_address mail,
                                                    last_update_date,
                                                    attribute12 
                                            FROM    po_vendor_contacts
                                            WHERE   vendor_id=fourniseur.vendor_id
                                            AND     vendor_site_id =site_fourniseur.vendor_site_id
                                        ) 
                    LOOP
                        
                        --v_message   := 'Ecriture des informations des contact site fournisseurs eligibles pour chaque fournisseur';
                        --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                        v_fichier_courant := v_non_fi_contact;
                        
                        IF contact_fourniseur.nom_contact IS NULL OR INSTR(contact_fourniseur.nom_contact,';') > 0 THEN --RBE artf2338800
                            --v_message   := 'Le contact (ID: '||contact_fourniseur.vendor_contact_id||') ne sera pas extrait';
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : le champ nom du contact est vide ou il contient ";", il a été remplacé par la valeur CONTACTDEF';
                            Dka_Tools_Pkg.put_log_message(v_message);
                            --CONTINUE;
                            contact_fourniseur.nom_contact := 'CONTACTDEF';
                        END IF;
                        
                        --RBE artf2338800
                        IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                            contact_fourniseur.telephone := REPLACE (contact_fourniseur.telephone,' ','');
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                            Dka_Tools_Pkg.put_log_message(v_message);
                            IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                                contact_fourniseur.telephone :=  SUBSTR(contact_fourniseur.telephone,1,15);
                                v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                                Dka_Tools_Pkg.put_log_message(v_message);
                            END IF;
                        END IF;
                        
                        utl_file.put_line(v_csf,REPLACE(fourniseur.code_fournisseur                    ||';'||
                                                site_fourniseur.code_site_fournisseur          ||';'||
                                                site_fourniseur.code_uo                        ||';'||
                                                site_fourniseur.vendor_site_id                 ||';'||
                                                contact_fourniseur.nom_contact                 ||';'||
                                                contact_fourniseur.prenom_contact              ||';'||
                                                contact_fourniseur.fonction                    ||';'||
                                                contact_fourniseur.telephone                   ||';'||
                                                REPLACE(contact_fourniseur.mail,';','') ,chr(9),'')                           
                                            );
                        

                        UPDATE  ap_supplier_contacts
                        SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                        WHERE  vendor_contact_id = contact_fourniseur.vendor_contact_id;
                        
                        v_csf_count:=v_csf_count+1;
                        
                    END LOOP;              
                    
                    UPDATE  ap_supplier_sites_all
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE vendor_site_id = site_fourniseur.vendor_site_id;
                    --	SELO - DEBUT : artf07424252
                    UPDATE  iby_ext_payee_relationships
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE supplier_site_id = site_fourniseur.vendor_site_id;					
                    --	SELO - FIN : artf07424252
					
                    UPDATE  ap_suppliers
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE vendor_id =fourniseur.vendor_id;
                    
                    v_f_count:=v_f_count+1;
                    
                    
                        
                END LOOP;
            
            ELSIF fourniseur.type_modif = 'SITE' THEN
                
                v_message   := '(Type : SITE) Extraction du site pour le fournisseur '||fourniseur.code_fournisseur;
                Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                
                --v_message   := 'Boucle des sites fournisseurs eligibles pour le fournisseur '|| fourniseur.code_fournisseur;
                --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                
                --boucle qui contient les sites fournisseurs eligibles pour chaque fournisseur avec vendor_id
                FOR site_fourniseur IN (SELECT assa.vendor_site_id,
                                               assa.party_site_id,
                                               assa.attribute1 complement_siret,
                                               fourniseur.num_siren ||NVL(assa.attribute1,'PROVI') code_rcs, --RBE artf2338800
                                               assa.vendor_site_code code_site_fournisseur,
                                               assa.address_line1 adresse1,
                                               assa.address_line2 adresse2,
                                               assa.address_line3 adresse3,
                                               assa.address_line4 adresse4,
                                               assa.city ville,
                                               assa.zip code_postal,
                                               assa.country pays,
                                               hcp1.phone_number telephone,
                                               hcp2.phone_number fax,
                                               TO_CHAR(assa.creation_date,'YYYYMMDD') date_creation_site,
                                               TO_CHAR(assa.inactive_date,'YYYYMMDD') date_fin_site,
                                               shiploc.location_id ship_location_id,
                                               shiploc.location_code ship_location_code,
                                               shiploc.address_line_1||' '||shiploc.address_line_2||' '||shiploc.address_line_3 adresse_livraison,
                                               billloc.location_id bill_location_id,
                                               billloc.location_code bill_location_code,
                                               billloc.address_line_1||' '||billloc.address_line_2||' '||billloc.address_line_3 adresse_facturation,
                                               (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                               FROM gl_code_combinations WHERE code_combination_id=assa.accts_pay_code_combination_id) compte_fournisseur,
                                               (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                               FROM gl_code_combinations WHERE code_combination_id=assa.prepay_code_combination_id) compte_acompte,
                                               assa.accts_pay_code_combination_id,
                                               assa.prepay_code_combination_id,
                                               TO_CHAR(assa.last_update_date,'YYYYMMDD') date_maj_site,
                                               assa.province province,
                                               NVL(assa.purchasing_site_flag,'N')  site_achat,
                                               NVL(assa.pay_site_flag,'N') site_paiement,
                                               --DECODE (fourniseur.type_fournisseur,'FACTOR',assa.attribute5,null) affacturage,
                                               CASE WHEN EXISTS (SELECT 1 from iby_ext_payee_relationships where supplier_site_id=assa.vendor_site_id 
                                               AND party_id=fourniseur.party_id  AND primary_flag= 'Y' 
                                               AND (sysdate BETWEEN from_date AND NVL(TO_DATE,sysdate))) THEN 'Y'
                                               ELSE  NULL  END AS affacturage,
                                               (SELECT name FROM hr_operating_units WHERE organization_id=assa.org_id )  code_uo,
                                               assa.offset_tax_flag flag_intracommunautaire,
                                               hcp3.email_address,
                                               DECODE(pm.payment_method_code,'WIRE',1,0)f_treglement
                                        FROM   ap_supplier_sites_all assa,
                                               hr_operating_units hou, --AAM
                                               hz_party_sites        hps,
                                               hz_contact_points     hcp1,
                                               hz_contact_points     hcp2,
                                               hz_contact_points     hcp3,
                                               hr_locations_all      shiploc,
                                               hr_locations_all      billloc,
                                               iby_external_payees_all payee,
                                               iby_ext_party_pmt_mthds pm
                                        WHERE  vendor_id = fourniseur.vendor_id
                                        AND    assa.org_id = hou.organization_id --AAM
                                        AND    hou.name    !='REF9999'           --AAM
                                        AND    hps.party_site_id(+) = assa.party_site_id
                                        AND    hcp1.owner_table_id(+) = hps.party_site_id
                                        AND    hcp1.contact_point_type(+) = 'PHONE'
                                        AND    hcp1.phone_line_type(+) = 'GEN'
                                        AND    hcp1.status(+) = 'A'
                                        AND    hcp1.owner_table_name(+) = 'HZ_PARTY_SITES'
                                        AND    hcp1.primary_flag(+) = 'Y'
                                        --< OBE
                                        AND   (hcp1.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp1.owner_table_id
                                                                            AND   contact_point_type = 'PHONE'
                                                                            AND   phone_line_type    = 'GEN'
                                                                            AND   status             = 'A'
                                                                            AND   primary_flag       = 'Y'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp1.contact_point_id,NULL,1,2)    
                                                )                                        
                                        --> OBE                                        
                                        AND    hcp2.owner_table_id(+) = hps.party_site_id
                                        AND    hcp2.contact_point_type(+) = 'PHONE'
                                        AND    hcp2.phone_line_type(+) = 'FAX'
                                        AND    hcp2.status(+) = 'A'
                                        AND    hcp2.owner_table_name(+) = 'HZ_PARTY_SITES'
                                        --< OBE
                                        AND   (hcp2.contact_point_id    = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp2.owner_table_id
                                                                            AND   contact_point_type = 'PHONE'
                                                                            AND   phone_line_type    = 'FAX'
                                                                            AND   status             = 'A'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp2.contact_point_id,NULL,1,2)    
                                                )                                        
                                        --> OBE                                        
                                        AND    shiploc.ship_to_site_flag(+) = 'Y'
                                        AND    hcp3.contact_point_type(+) = 'EMAIL' 
                                        AND    hcp3.owner_table_id(+) = hps.party_site_id
                                        AND    hcp3.status(+) = 'A' 
                                        AND    hcp3.owner_table_name(+) = 'HZ_PARTY_SITES' 
                                        AND    hcp3.primary_flag(+) = 'Y' 
                                        --< OBE
                                        AND   (hcp3.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp3.owner_table_id
                                                                            AND   contact_point_type = 'EMAIL'
                                                                            AND   status             = 'A'
                                                                            AND   primary_flag       = 'Y'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp3.contact_point_id,NULL,1,2)    
                                                )                                                
                                        --> OBE                                        
                                        AND    sysdate < NVL(TRUNC(shiploc.inactive_date), sysdate + 1)
                                        AND    shiploc.location_id(+) = assa.ship_to_location_id
                                        AND    billloc.ship_to_site_flag(+) = 'Y'
                                        AND    sysdate < NVL(TRUNC(billloc.inactive_date), sysdate + 1)
                                        AND    billloc.location_id(+) = assa.bill_to_location_id
                                        AND   ( NVL(TO_DATE(assa.attribute12,'YYYY/MM/DD HH24:MI:SS'),assa.last_update_date-1) < assa.last_update_date
										      --	SELO - DEBUT : artf07424252
											  OR
											    exists (
												 SELECT distinct 1
												   FROM IBY_EXT_PAYEE_RELATIONSHIPS ExtRelationshipsEO,
													--	ap_supplier_sites_all apsite_inv,
														hr_operating_units hou 
												  WHERE ExtRelationshipsEO.supplier_site_id = assa.vendor_site_id 
													AND assa.vendor_id  =fourniseur.vendor_id
													AND assa.org_id  =hou.organization_id
													AND hou.name !='REF9999'
													AND NVL(TO_DATE(ExtRelationshipsEO.attribute12,'YYYY/MM/DD HH24:MI:SS'),ExtRelationshipsEO.last_update_date-1) < ExtRelationshipsEO.last_update_date
												)
											--	SELO - FIN : artf07424252
											  )
                                        --AND    payee.payee_party_id = hps.party_id
                                        AND    payee.payment_function = 'PAYABLES_DISB'
                                        --AND    payee.party_site_id = assa.party_site_id
                                        AND    payee.supplier_site_id = assa.vendor_site_id
                                        AND    payee.org_id = assa.org_id
                                        AND    payee.org_type = 'OPERATING_UNIT'
                                        AND    payee.ext_payee_id = pm.ext_pmt_party_id (+)
                                        --< OBE artf2141490 
                                        --AND    pm.primary_flag  = 'Y'
                                        AND NVL(pm.primary_flag,'Y')  = 'Y' 
                                        AND payee.party_site_id IS NOT NULL
                                        --> OBE artf2141490                                        
                                    )
                    
                LOOP
                    v_cur_site_vide     := FALSE;
                    
                    --v_message   := 'Ecriture des informations des sites fournisseurs eligibles pour chaque fournisseur';
                    --Dka_Tools_Pkg.Put_Outdebug_Message(v_message || ' '||site_fourniseur.code_site_fournisseur||' eligibles pour le fournisseur '|| fourniseur.code_fournisseur);
                    --RBE artf2338800
                    IF LENGTH(site_fourniseur.telephone) > 15 THEN
                        site_fourniseur.telephone := REPLACE (site_fourniseur.telephone,' ','');
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        IF LENGTH(site_fourniseur.telephone) > 15 THEN
                            site_fourniseur.telephone :=  SUBSTR(site_fourniseur.telephone,1,15);
                            v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                            Dka_Tools_Pkg.put_log_message(v_message);
                        END IF;
                    END IF;

                    --RBE artf2338800
                    IF LENGTH(site_fourniseur.FAX) > 15 THEN
                        site_fourniseur.FAX := REPLACE (site_fourniseur.FAX,' ','');
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, les espaces sont supprimés';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        IF LENGTH(site_fourniseur.FAX) > 15 THEN
                            site_fourniseur.FAX :=  SUBSTR(site_fourniseur.FAX,1,15);
                            v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, le champ a été tronqué ';
                            Dka_Tools_Pkg.put_log_message(v_message);
                        END IF;
                    END IF;
                    
                    --RBE artf2338800
                    IF site_fourniseur.complement_siret IS NULL THEN
                        site_fourniseur.complement_siret := 'PROVI';
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : Le champ complément SIRET est vide, il a été remplacé par la valeur PROVI';
                        Dka_Tools_Pkg.put_log_message(v_message);
                    END IF;
                    
                    v_fichier_courant := v_non_fi_fournisseurs;
                    utl_file.put_line(v_f, REPLACE(fourniseur.code_fournisseur            ||';'||                
                                            REPLACE(fourniseur.nom_fournisseur_long,';',' ')       ||';'||                
                                            fourniseur.nom_fournisseur_court      ||';'||                
                                            fourniseur.code_partenaire            ||';'||                
                                            fourniseur.num_siren                  ||';'||                
                                            site_fourniseur.complement_siret      ||';'||    
                                            site_fourniseur.code_rcs              ||';'||                                
                                            fourniseur.num_tva                    ||';'||                
                                            fourniseur.type_fournisseur           ||';'||                
                                            fourniseur.num_ape                    ||';'||                
                                            site_fourniseur.code_site_fournisseur ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse1,';',''),'"','')              ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse2,';',''),'"','')              ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse3,';',''),'"','')              ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse4,';',''),'"','')              ||';'||                                
                                            site_fourniseur.ville                 ||';'||                                
                                            site_fourniseur.code_postal           ||';'||
                                            site_fourniseur.pays                  ||';'||
                                            site_fourniseur.telephone             ||';'||
                                            site_fourniseur.fax                   ||';'||
                                            site_fourniseur.date_creation_site    ||';'||
                                            site_fourniseur.date_fin_site         ||';'||
                                            site_fourniseur.adresse_livraison     ||';'||
                                            site_fourniseur.adresse_facturation   ||';'||
                                            site_fourniseur.compte_fournisseur    ||';'||
                                            site_fourniseur.compte_acompte        ||';'||
                                            fourniseur.fournisseur_service        ||';'||
                                            fourniseur.fournisseur_combustible    ||';'||
                                            fourniseur.date_maj_entete            ||';'||
                                            site_fourniseur.date_maj_site         ||';'||
                                            fourniseur.creation_fournisseur       ||';'||
                                            fourniseur.fin_activite_fournisseur   ||';'||
                                            site_fourniseur.province              ||';'||
                                            fourniseur.code_accord                ||';'||
                                            site_fourniseur.site_achat            ||';'||
                                            site_fourniseur.site_paiement         ||';'||
                                            site_fourniseur.affacturage           ||';'||
                                            fourniseur.federal_reportable_flag    ||';'||
                                            site_fourniseur.code_uo               ||';'||
                                            fourniseur.classification_achat       ||';'||
                                            site_fourniseur.flag_intracommunautaire  ||';'||  
                                            REPLACE(site_fourniseur.email_address,';','')            ||';'||
                                            site_fourniseur.vendor_site_id           ||';'|| 
                                            site_fourniseur.f_treglement ,chr(9),''));  
                    
                    UPDATE  ap_supplier_sites_all
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE vendor_site_id = site_fourniseur.vendor_site_id;
                    --	SELO - DEBUT : artf07424252
					 UPDATE  iby_ext_payee_relationships
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE supplier_site_id = site_fourniseur.vendor_site_id;	
					--	SELO - FIN : artf07424252
                    UPDATE  ap_suppliers
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE vendor_id =fourniseur.vendor_id;
                    
                    v_f_count:=v_f_count+1;
                    FOR contact_fourniseur IN (SELECT  vendor_contact_id,
                                                    vendor_id,
                                                    vendor_site_id,
                                                    last_name  nom_contact,   -- RBE artf2104094 
                                                    first_name prenom_contact,-- RBE artf2104094 
                                                    title fonction,
                                                    phone telephone,
                                                    email_address mail,
                                                    last_update_date,
                                                    attribute12 
                                            FROM    po_vendor_contacts
                                            WHERE   vendor_id=fourniseur.vendor_id
                                            AND     vendor_site_id =site_fourniseur.vendor_site_id
                                        ) 
                    LOOP
                        
                        --v_message   := 'Ecriture des informations des contacts fournisseurs eligibles pour chaque fournisseur';
                        --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                        
                        v_fichier_courant := v_non_fi_contact;
                        
                        IF contact_fourniseur.nom_contact IS NULL OR INSTR(contact_fourniseur.nom_contact,';') > 0 THEN --RBE artf2338800
                            --v_message   := 'Le contact (ID: '||contact_fourniseur.vendor_contact_id||') ne sera pas extrait';
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : le champ nom du contact est vide ou il contient ";", il a été remplacé par la valeur CONTACTDEF';
                            Dka_Tools_Pkg.put_log_message(v_message);
                            --CONTINUE;
                            contact_fourniseur.nom_contact := 'CONTACTDEF';
                        END IF;
                        
                        --RBE artf2338800
                        IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                            contact_fourniseur.telephone := REPLACE (contact_fourniseur.telephone,' ','');
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                            Dka_Tools_Pkg.put_log_message(v_message);
                            IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                                contact_fourniseur.telephone :=  SUBSTR(contact_fourniseur.telephone,1,15);
                                v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                                Dka_Tools_Pkg.put_log_message(v_message);
                            END IF;
                        END IF;
                        
                        utl_file.put_line(v_csf,REPLACE(fourniseur.code_fournisseur                    ||';'||
                                                site_fourniseur.code_site_fournisseur          ||';'||
                                                site_fourniseur.code_uo                        ||';'||
                                                site_fourniseur.vendor_site_id                 ||';'||
                                                contact_fourniseur.nom_contact                 ||';'||
                                                contact_fourniseur.prenom_contact              ||';'||
                                                contact_fourniseur.fonction                    ||';'||
                                                contact_fourniseur.telephone                   ||';'||
                                                REPLACE(contact_fourniseur.mail,';','') ,chr(9),'')                           
                                            );
                        

                        UPDATE  ap_supplier_contacts
                        SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                        WHERE  vendor_contact_id = contact_fourniseur.vendor_contact_id;
                        
                        v_csf_count:=v_csf_count+1;
                        
                    END LOOP;  
                        
                END LOOP;

            ELSE 
            
                --v_message   := 'Extraction de l''en-tête et du site MAJ et du contact MAJ';
                --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                --v_message   := 'boucle des sites fournisseurs eligibles pour le fournisseur '|| fourniseur.code_fournisseur;
                --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                
                --boucle qui contient les sites fournisseurs eligibles pour chaque fournisseur avec vendor_id
                v_message   := 'Ouverture du curseur des sites fournisseurs pour le fournisseur ' || fourniseur.code_fournisseur;
                Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                    
                FOR site_fourniseur IN (SELECT assa.vendor_site_id,
                                               assa.party_site_id,
                                               assa.attribute1 complement_siret,
                                               fourniseur.num_siren ||NVL(assa.attribute1,'PROVI') code_rcs, --RBE artf2338800
                                               assa.vendor_site_code code_site_fournisseur,
                                               assa.address_line1 adresse1,
                                               assa.address_line2 adresse2,
                                               assa.address_line3 adresse3,
                                               assa.address_line4 adresse4,
                                               assa.city ville,
                                               assa.zip code_postal,
                                               assa.country pays,
                                               hcp1.phone_number telephone,
                                               hcp2.phone_number fax,
                                               TO_CHAR(assa.creation_date,'YYYYMMDD') date_creation_site,
                                               TO_CHAR(assa.inactive_date,'YYYYMMDD') date_fin_site,
                                               shiploc.location_id ship_location_id,
                                               shiploc.location_code ship_location_code,
                                               shiploc.address_line_1||' '||shiploc.address_line_2||' '||shiploc.address_line_3 adresse_livraison,
                                               billloc.location_id bill_location_id,
                                               billloc.location_code bill_location_code,
                                               billloc.address_line_1||' '||billloc.address_line_2||' '||billloc.address_line_3 adresse_facturation,
                                               (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                               FROM gl_code_combinations WHERE code_combination_id=assa.accts_pay_code_combination_id) compte_fournisseur,
                                               (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                               FROM gl_code_combinations WHERE code_combination_id=assa.prepay_code_combination_id) compte_acompte,
                                               assa.accts_pay_code_combination_id,
                                               assa.prepay_code_combination_id,
                                               TO_CHAR(assa.last_update_date,'YYYYMMDD') date_maj_site,
                                               assa.province province,
                                               NVL(assa.purchasing_site_flag,'N')  site_achat,
                                               NVL(assa.pay_site_flag,'N') site_paiement,
                                               --DECODE (fourniseur.type_fournisseur,'FACTOR',assa.attribute5,null) affacturage, 
                                               CASE WHEN EXISTS (SELECT 1 from iby_ext_payee_relationships where supplier_site_id=assa.vendor_site_id 
                                               AND party_id=fourniseur.party_id  AND primary_flag= 'Y' 
                                               AND (sysdate BETWEEN from_date AND NVL(TO_DATE,sysdate))) THEN 'Y'
                                               ELSE  NULL  END AS affacturage,
                                               (SELECT name FROM hr_operating_units WHERE organization_id=assa.org_id )  code_uo,
                                               assa.offset_tax_flag flag_intracommunautaire,
                                               hcp3.email_address,
                                                DECODE(pm.payment_method_code,'WIRE',1,0)f_treglement
                                        FROM   ap_supplier_sites_all assa,
                                               hr_operating_units hou, --AAM
                                               hz_party_sites        hps,
                                               hz_contact_points     hcp1,
                                               hz_contact_points     hcp2,
                                               hz_contact_points     hcp3,
                                               hr_locations_all      shiploc,
                                               hr_locations_all      billloc,
                                               iby_external_payees_all payee,
                                               iby_ext_party_pmt_mthds pm
                                        WHERE  assa.vendor_id = fourniseur.vendor_id
                                        AND    assa.org_id = hou.organization_id --AAM
                                        AND    hou.name    != 'REF9999'          --AAM
                                        AND    hps.party_site_id(+) = assa.party_site_id
                                        AND    hcp1.owner_table_id(+) = hps.party_site_id
                                        AND    hcp1.contact_point_type(+) = 'PHONE'
                                        AND    hcp1.phone_line_type(+) = 'GEN'
                                        AND    hcp1.status(+) = 'A'
                                        AND    hcp1.owner_table_name(+) = 'HZ_PARTY_SITES'
                                        AND    hcp1.primary_flag(+) = 'Y'
                                        --< OBE
                                        AND   (hcp1.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp1.owner_table_id
                                                                            AND   contact_point_type = 'PHONE'
                                                                            AND   phone_line_type    = 'GEN'
                                                                            AND   status             = 'A'
                                                                            AND   primary_flag       = 'Y'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp1.contact_point_id,NULL,1,2)    
                                                )                                        
                                        --> OBE                                        
                                        AND    hcp2.owner_table_id(+) = hps.party_site_id
                                        AND    hcp2.contact_point_type(+) = 'PHONE'
                                        AND    hcp2.phone_line_type(+) = 'FAX'
                                        AND    hcp2.status(+) = 'A'
                                        AND    hcp2.owner_table_name(+) = 'HZ_PARTY_SITES'
                                        --< OBE
                                        AND   (hcp2.contact_point_id    = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp2.owner_table_id
                                                                            AND   contact_point_type = 'PHONE'
                                                                            AND   phone_line_type    = 'FAX'
                                                                            AND   status             = 'A'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp2.contact_point_id,NULL,1,2)    
                                                )                                        
                                        --> OBE
                                        AND    hcp3.contact_point_type(+) = 'EMAIL' 
                                        AND    hcp3.owner_table_id(+) = hps.party_site_id
                                        AND    hcp3.status(+) = 'A' 
                                        AND    hcp3.owner_table_name(+) = 'HZ_PARTY_SITES' 
                                        AND    hcp3.primary_flag(+) = 'Y' 
                                        --< OBE
                                        AND   (hcp3.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                            FROM hz_contact_points
                                                                            WHERE owner_table_id     = hcp3.owner_table_id
                                                                            AND   contact_point_type = 'EMAIL'
                                                                            AND   status             = 'A'
                                                                            AND   primary_flag       = 'Y'
                                                                            AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                            )   
                                                OR 1 = DECODE(hcp3.contact_point_id,NULL,1,2)    
                                                )                                                
                                        --> OBE
                                        AND    shiploc.ship_to_site_flag(+) = 'Y'
                                        AND    sysdate < NVL(TRUNC(shiploc.inactive_date), sysdate + 1)
                                        AND    shiploc.location_id(+) = assa.ship_to_location_id
                                        AND    billloc.ship_to_site_flag(+) = 'Y'
                                        AND    sysdate < NVL(TRUNC(billloc.inactive_date), sysdate + 1)
                                        AND    billloc.location_id(+) = assa.bill_to_location_id
                                        --AND    payee.payee_party_id = hps.party_id
                                        AND    payee.payment_function = 'PAYABLES_DISB'
                                        --AND    payee.party_site_id = assa.party_site_id
                                        AND    payee.supplier_site_id = assa.vendor_site_id
                                        AND    payee.org_id = assa.org_id
                                        AND    payee.org_type = 'OPERATING_UNIT'
                                        AND    payee.ext_payee_id = pm.ext_pmt_party_id (+)
                                        --< OBE artf2141490 
                                        --AND    pm.primary_flag  = 'Y'
                                        AND NVL(pm.primary_flag,'Y')  = 'Y' 
                                        AND payee.party_site_id IS NOT NULL
                                        --> OBE artf2141490
                                        AND  EXISTS
                                            (SELECT 1
                                            FROM po_vendor_contacts pvc
                                            WHERE pvc.vendor_id                                                    =assa.vendor_id
                                            AND pvc.vendor_site_id  =assa.vendor_site_id
                                            AND NVL(TO_DATE(pvc.attribute12,'YYYY/MM/DD HH24:MI:SS'),pvc.last_update_date-1) < pvc.last_update_date
                                            )
                                    )
                    
                LOOP
                    
                    v_cur_site_vide     := FALSE;
                    
                    --RBE artf2338800
                    IF LENGTH(site_fourniseur.telephone) > 15 THEN
                        site_fourniseur.telephone := REPLACE (site_fourniseur.telephone,' ','');
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        IF LENGTH(site_fourniseur.telephone) > 15 THEN
                            site_fourniseur.telephone :=  SUBSTR(site_fourniseur.telephone,1,15);
                            v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                            Dka_Tools_Pkg.put_log_message(v_message);
                        END IF;
                    END IF;

                    --RBE artf2338800
                    IF LENGTH(site_fourniseur.FAX) > 15 THEN
                        site_fourniseur.FAX := REPLACE (site_fourniseur.FAX,' ','');
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, les espaces sont supprimés';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        IF LENGTH(site_fourniseur.FAX) > 15 THEN
                            site_fourniseur.FAX :=  SUBSTR(site_fourniseur.FAX,1,15);
                            v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, le champ a été tronqué ';
                            Dka_Tools_Pkg.put_log_message(v_message);
                        END IF;
                    END IF;
                    --RBE artf2338800
                    IF site_fourniseur.complement_siret IS NULL THEN
                        site_fourniseur.complement_siret := 'PROVI';
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : Le champ complément SIRET est vide, il a été remplacé par la valeur PROVI';
                        Dka_Tools_Pkg.put_log_message(v_message);
                    END IF;
                    
                    v_fichier_courant := v_non_fi_fournisseurs;
                    utl_file.put_line(v_f, REPLACE(fourniseur.code_fournisseur            ||';'||                
                                            REPLACE(fourniseur.nom_fournisseur_long,';',' ')        ||';'||                
                                            fourniseur.nom_fournisseur_court      ||';'||                
                                            fourniseur.code_partenaire            ||';'||                
                                            fourniseur.num_siren                  ||';'||                
                                            site_fourniseur.complement_siret      ||';'||   
                                            site_fourniseur.code_rcs              ||';'||                                
                                            fourniseur.num_tva                    ||';'||                
                                            fourniseur.type_fournisseur           ||';'||                
                                            fourniseur.num_ape                    ||';'||                
                                            site_fourniseur.code_site_fournisseur ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse1,';',''),'"','')              ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse2,';',''),'"','')              ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse3,';',''),'"','')              ||';'||                                
                                            REPLACE(REPLACE(site_fourniseur.adresse4,';',''),'"','')              ||';'||                               
                                            site_fourniseur.ville                 ||';'||                                
                                            site_fourniseur.code_postal           ||';'||
                                            site_fourniseur.pays                  ||';'||
                                            site_fourniseur.telephone             ||';'||
                                            site_fourniseur.fax                   ||';'||
                                            site_fourniseur.date_creation_site    ||';'||
                                            site_fourniseur.date_fin_site         ||';'||
                                            site_fourniseur.adresse_livraison     ||';'||
                                            site_fourniseur.adresse_facturation   ||';'||
                                            site_fourniseur.compte_fournisseur    ||';'||
                                            site_fourniseur.compte_acompte        ||';'||
                                            fourniseur.fournisseur_service        ||';'||
                                            fourniseur.fournisseur_combustible    ||';'||
                                            fourniseur.date_maj_entete            ||';'||
                                            site_fourniseur.date_maj_site         ||';'||
                                            fourniseur.creation_fournisseur       ||';'||
                                            fourniseur.fin_activite_fournisseur   ||';'||
                                            site_fourniseur.province              ||';'||
                                            fourniseur.code_accord                ||';'||
                                            site_fourniseur.site_achat            ||';'||
                                            site_fourniseur.site_paiement         ||';'||
                                            site_fourniseur.affacturage           ||';'||
                                            fourniseur.federal_reportable_flag    ||';'||
                                            site_fourniseur.code_uo               ||';'||
                                            fourniseur.classification_achat       ||';'||
                                            site_fourniseur.flag_intracommunautaire  ||';'||  
                                            REPLACE(site_fourniseur.email_address,';','')            ||';'||
                                            site_fourniseur.vendor_site_id           ||';'|| 
                                            site_fourniseur.f_treglement ,chr(9),'')); 
                    
                    UPDATE  ap_supplier_sites_all
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE vendor_site_id = site_fourniseur.vendor_site_id;
                    --	SELO - DEBUT : artf07424252
                    UPDATE  iby_ext_payee_relationships
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE supplier_site_id = site_fourniseur.vendor_site_id;						
                    --	SELO - FIN : artf07424252
                    UPDATE  ap_suppliers
                    SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                    WHERE vendor_id =fourniseur.vendor_id;
                    
                    v_f_count:=v_f_count+1;
                    FOR contact_fourniseur IN (SELECT  vendor_contact_id,
                                                    vendor_id,
                                                    vendor_site_id,
                                                    last_name  nom_contact,   -- RBE artf2104094 
                                                    first_name prenom_contact,-- RBE artf2104094 
                                                    title fonction,
                                                    phone telephone,
                                                    email_address mail,
                                                    last_update_date,
                                                    attribute12 
                                            FROM    po_vendor_contacts
                                            WHERE   vendor_id=fourniseur.vendor_id
                                            AND     vendor_site_id =site_fourniseur.vendor_site_id
                                            AND     NVL(TO_DATE(attribute12,'YYYY/MM/DD HH24:MI:SS'),last_update_date-1) < last_update_date        
                                        ) 
                    LOOP
                        
                        --v_message   := 'Ecriture des informations des contacts eligibles du site fournisseur '||fourniseur.code_fournisseur||' pour le fournisseur '||site_fourniseur.code_site_fournisseur  ;
                        --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                        v_fichier_courant := v_non_fi_contact;
                        
                        IF contact_fourniseur.nom_contact IS NULL OR INSTR(contact_fourniseur.nom_contact,';') > 0 THEN --RBE artf2338800
                            --v_message   := 'Le contact (ID: '||contact_fourniseur.vendor_contact_id||') ne sera pas extrait';
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : le champ nom du contact est vide ou il contient ";", il a été remplacé par la valeur CONTACTDEF';
                            Dka_Tools_Pkg.put_log_message(v_message);
                            --CONTINUE;
                            contact_fourniseur.nom_contact := 'CONTACTDEF';
                        END IF;
                        
                        --RBE artf2338800
                        IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                            contact_fourniseur.telephone := REPLACE (contact_fourniseur.telephone,' ','');
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                            Dka_Tools_Pkg.put_log_message(v_message);
                            IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                                contact_fourniseur.telephone :=  SUBSTR(contact_fourniseur.telephone,1,15);
                                v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                                Dka_Tools_Pkg.put_log_message(v_message);
                            END IF;
                        END IF;
                        
                        --RBE artf2338800
                        IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                            contact_fourniseur.telephone := REPLACE (contact_fourniseur.telephone,' ','');
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                            Dka_Tools_Pkg.put_log_message(v_message);
                            IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                                contact_fourniseur.telephone :=  SUBSTR(contact_fourniseur.telephone,1,15);
                                v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                                Dka_Tools_Pkg.put_log_message(v_message);
                            END IF;
                        END IF;
                        
                        utl_file.put_line(v_csf,REPLACE(fourniseur.code_fournisseur                    ||';'||
                                                site_fourniseur.code_site_fournisseur          ||';'||
                                                site_fourniseur.code_uo                        ||';'||
                                                site_fourniseur.vendor_site_id                 ||';'||
                                                contact_fourniseur.nom_contact                 ||';'||
                                                contact_fourniseur.prenom_contact              ||';'||
                                                contact_fourniseur.fonction                    ||';'||
                                                contact_fourniseur.telephone                   ||';'||
                                                REPLACE(contact_fourniseur.mail,';','')  ,chr(9),'')                          
                                            );

                        UPDATE  ap_supplier_contacts
                        SET     attribute12 = to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                        WHERE  vendor_contact_id = contact_fourniseur.vendor_contact_id;
                        
                        v_csf_count:=v_csf_count+1;
                        
                    END LOOP;  
                END LOOP;
           
            END IF;
            
            IF v_cur_site_vide THEN 
                p_errbuff:= 'Aucun site n''a pu etre recupere pour ce fournisseur '||fourniseur.code_fournisseur ;
                Dka_Tools_Pkg.put_log_message(p_errbuff);
            END IF;
                
        END LOOP;
        
   
        IF NOT v_cur_vide THEN   
            p_errbuff:= '=========================================================================';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            p_errbuff:= 'Des founisseurs ont bien été extraits dans le fichier';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
           
            utl_file.fclose(v_f);
            utl_file.fclose(v_csf);
            
            COMMIT;    
            
        ELSE
            v_message   := 'Aucun fournisseur n''a ete identifie comme eligible';
             
            IF UTL_FILE.IS_OPEN(v_f) THEN
                UTL_FILE.FREMOVE(v_nom_chemin,v_non_fi_fournisseurs);
            END IF;
            IF UTL_FILE.IS_OPEN(v_csf) THEN
                UTL_FILE.FREMOVE(v_nom_chemin,v_non_fi_contact);
            END IF;

            p_retcode := 0;
            p_errbuff:= v_message;
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        END IF;
          
        ---------------
        -- Statistiques
        ---------------
        p_errbuff:= '=========================================================================';
        Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);

        p_errbuff:= 'Nombre d''enregistrements extraits dans le fichier FOURNISSEURS: ' ||TO_CHAR(v_f_count);
        Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
        p_errbuff:= 'Nombre d''enregistrements extraits dans le fichier FOURNISSEURS_CONTACTS: ' ||TO_CHAR(v_csf_count);
        Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);


    EXCEPTION
        WHEN utl_file.invalid_operation THEN             
            p_retcode := 2;
            p_errbuff:= 'Erreur : Operation invalide sur le fichier ' ||v_fichier_courant ||'au niveau du directory '||v_nom_chemin;
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.invalid_path THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur : Repertoire invalide. Veuillez renseigner le directory ' ||v_nom_chemin ||' dans DBA_DIRECTORIES et s¿assurer que ce repertoire existe bien sur la machine';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.invalid_mode THEN
            p_retcode := 2;
            p_errbuff:= 'Mode invalide';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.invalid_filehandle THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur :Descripteur de fichier '||v_fichier_courant ||' non valide ';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.read_error THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur de lecture';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.internal_error THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur interne';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.delete_failed THEN
            p_retcode := 2;
            p_errbuff:= 'Impossible de supprimer les fichiers';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
        WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            p_errbuff  := 'ERREUR dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            
            Dka_Tools_Pkg.put_debug_message('-------------------- ERREUR --------------------');
            Dka_Tools_Pkg.put_debug_message('Package   : '||v_package);
            Dka_Tools_Pkg.put_debug_message('Procedure : '||v_procedure);
            Dka_Tools_Pkg.put_debug_message('Exception : OTHERS');
            Dka_Tools_Pkg.put_debug_message('Message   : '||v_message);
            Dka_Tools_Pkg.put_debug_message('Cause     : '||v_sqlerrm);
            Dka_Tools_Pkg.put_debug_message('------------------------------------------------');
            Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================================');
            Dka_Tools_Pkg.Put_Outdebug_Message('Traitement '||v_nom_traitement||' termine en erreur         ');
            Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================================');
            ROLLBACK;

    END Export_journalier;    

    
        /*=====================================================================================*/
    /* Procedure         : Export_mensuel                                                           */
    /* Description       : Procedure principale qui extrait les donnees eligibles          */ 
    /*                     et qui respecte les regles de gestion puis ecrit le fichier   */     
    /* Parametres entree : p_errbuff  IN OUT VARCHAR2 :                                    */
    /*                   : p_retcode  IN OUT NUMBER   :                                    */
    /* Parametres sortie : AUCUN                                                           */
    /* Remarques         :                                                                 */
    /*=====================================================================================*/     
    PROCEDURE Export_mensuel( p_errbuff                IN OUT VARCHAR2,
                              p_retcode                IN OUT NUMBER,
                              p_site_paiement          IN     VARCHAR2
                    )
    IS
    
        -- ========== VARIABLES ==========
        v_package            VARCHAR2(30)  := 'DKA_APFRSEXP_PKG';
        v_nom_traitement     VARCHAR2(200) := 'Export des fournisseurs mensuel';
        v_sqlerrm            VARCHAR2(250) := NULL;

        v_nom_chemin         VARCHAR2(250) := 'DKA_OUT_DIR';-- temporaire a remplacer par 'REP_DATA_OUT';
        v_fichier_courant    VARCHAR2(100);

        v_procedure          VARCHAR2(30)    := 'Export_mensuel';
        v_message            VARCHAR2(500);

        v_cur_vide           BOOLEAN := TRUE;
        v_cur_site_vide      BOOLEAN := TRUE;
        
        v_non_fi_fournisseurs VARCHAR2(50)    := 'FOURNISSEURS_FULL_';
        v_non_fi_contact      VARCHAR2(50)    := 'FOURNISSEURS_CONTACTS_FULL_';

        v_ext   VARCHAR2(30)    := '.dat';
        --v_prefix VARCHAR2(30)    := 'DKA_REP_';
        v_f                        utl_file.file_type;
        v_csf                      utl_file.file_type;
 
        v_f_count     NUMBER := 0;
        v_csf_count   NUMBER := 0;

        -- curseur sur fournisseur avec les champs a extraire selon les regles elligibilite sur les sites fournisseurs pour l'export mensuel
        CURSOR cur_fournisseur
        IS
            SELECT  pv.vendor_id ,
                    pv.segment1 code_fournisseur,
                    pv.vendor_name nom_fournisseur_long,--YWA artf2115232 
                    SUBSTR(pv.vendor_name,0,35) nom_fournisseur_court,
                    pv.attribute2 code_partenaire,
                    DECODE(upper(pv.vendor_type_lookup_code), 'EMPLOYEE', papf.national_identifier, DECODE(pv.organization_type_lookup_code, 'INDIVIDUAL',pv.individual_1099, 'FOREIGN INDIVIDUAL',pv.individual_1099, hp.jgzz_fiscal_code)) num_siren ,
                    hp.tax_reference num_tva ,
                    pv.vat_registration_num num_tva_1,
                    pv.vendor_type_lookup_code type_fournisseur,
                    pv.standard_industry_class num_ape ,
                    NVL(pv.attribute1,'N') fournisseur_service,
                    NVL(pv.attribute3,'N') fournisseur_combustible,
                    TO_CHAR(pv.last_update_date,'YYYYMMDD') date_maj_entete,
                    TO_CHAR(pv.creation_date,'YYYYMMDD') creation_fournisseur,
                    TO_CHAR(pv.end_date_active,'YYYYMMDD')  fin_activite_fournisseur,
                    pv.attribute4 code_accord,
                    pv.federal_reportable_flag,
                    pv.attribute8 classification_achat,
                    pv.party_id
            FROM    po_vendors pv,
                    hz_parties hp ,
                    per_all_people_f papf
            WHERE   pv.party_id                                                     = hp.party_id
            AND     NVL(PV.VENDOR_TYPE_LOOKUP_CODE,'N/A') <> 'EMPLOYEE'  -- RBE artf2147539,artf2191673
            AND     pv.employee_id                                                  = papf.person_id (+)
            AND     NVL(papf.effective_end_date,SYSDATE)                           >= SYSDATE;

        BEGIN

        -- Debut du Programme --

        -- Initialization des journaux --
        Dka_Tools_Pkg.Put_Outdebug_Message('================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('Extraction fourniseur DKA_APFRSEXP_PKG');
        Dka_Tools_Pkg.Put_Outdebug_Message('================================================');
        Dka_Tools_Pkg.Put_Outdebug_Message('Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Dka_Tools_Pkg.Put_Outdebug_Message('Numero de traitement : ' || TO_CHAR(FND_GLOBAL.CONC_REQUEST_ID));
        Dka_Tools_Pkg.Put_Outdebug_Message('Paramètre(s):');
        Dka_Tools_Pkg.Put_Outdebug_Message('1) Site de paiement: '||NVL(p_site_paiement,'N/A'));
        Dka_Tools_Pkg.Put_Outdebug_Message('================================================');

        -- Initialisation des variables d'anomalies --
        p_retcode   := 0;
        p_errbuff   := NULL;
        v_message   := 'Debut procedure MAIN';
  
        /*============================================================================================*/
        /*ouverture des fichiers*/
        /*============================================================================================*/
        v_message   := 'Ouverture des fichiers';
        Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
        
        v_non_fi_fournisseurs   := v_non_fi_fournisseurs||TO_CHAR(SYSDATE,'YYYYMMDD')||v_ext;
        v_fichier_courant       := v_non_fi_fournisseurs;
        v_f:=utl_file.fopen(v_nom_chemin,v_non_fi_fournisseurs,'W',32754);
        
        v_non_fi_contact   := v_non_fi_contact||TO_CHAR(SYSDATE,'YYYYMMDD')||v_ext;
        v_fichier_courant  := v_non_fi_contact;
        v_csf := utl_file.fopen(v_nom_chemin,v_non_fi_contact,'W',32754);

        ----premiere ligne detaillant le contenu des champs du fichier founisseurs
        --utl_file.put_line(v_f,);

        ---boucle sur le curseur des fournisseurs eligibles
        v_message   := 'Ouverture du curseur des fournisseurs';
        Dka_Tools_Pkg.put_log_message(v_message);
        
        FOR fourniseur IN cur_fournisseur LOOP

            --variable si curseur vide
            v_cur_vide := FALSE;
           
            --ecriture dans le fichier fournisseur
            --v_message   := 'Ecriture dans le fichier fournisseur';
            --Dka_Tools_Pkg.put_outdebug_message(v_message);
           
            IF fourniseur.nom_fournisseur_court IS NULL THEN
                v_message   := 'Le founisseur '||fourniseur.code_fournisseur||' ne sera pas extrait';
                Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                CONTINUE;
            END IF;
            --RBE artf2338800
            IF fourniseur.num_siren IS NULL THEN
                fourniseur.num_siren := 'PROVISOIRE';
                v_message   := 'Fournisseur ('||fourniseur.nom_fournisseur_court||') : Le champ SIREN est vide, il a été remplacé par la valeur PROVISOIRE';
                Dka_Tools_Pkg.put_log_message(v_message);
            END IF;
            
            v_cur_site_vide := TRUE;
            --v_message   := 'Extraction de l''en-tête et de tous les sites et contacts associés au fournisseur '||fourniseur.code_fournisseur;
            --Dka_Tools_Pkg.put_log_message(v_message);

            v_message   := 'Ouverture du curseur des sites fournisseurs pour le fournisseur ' || fourniseur.code_fournisseur;
            Dka_Tools_Pkg.Put_Outdebug_Message(v_message);

            FOR site_fourniseur IN (SELECT assa.vendor_site_id,
                                           assa.party_site_id,
                                           assa.attribute1 complement_siret,
                                           fourniseur.num_siren ||NVL(assa.attribute1,'PROVI') code_rcs, --RBE artf2338800
                                           assa.vendor_site_code code_site_fournisseur,
                                           assa.address_line1 adresse1,
                                           assa.address_line2 adresse2,
                                           assa.address_line3 adresse3,
                                           assa.address_line4 adresse4,
                                           assa.city ville,
                                           assa.zip code_postal,
                                           assa.country pays,
                                           hcp1.phone_number telephone,
                                           hcp2.phone_number fax,
                                           TO_CHAR(assa.creation_date,'YYYYMMDD') date_creation_site,
                                           TO_CHAR(assa.inactive_date,'YYYYMMDD') date_fin_site,
                                           shiploc.location_id ship_location_id,
                                           shiploc.location_code ship_location_code,
                                           shiploc.address_line_1||' '||shiploc.address_line_2||' '||shiploc.address_line_3 adresse_livraison,
                                           billloc.location_id bill_location_id,
                                           billloc.location_code bill_location_code,
                                           billloc.address_line_1||' '||billloc.address_line_2||' '||billloc.address_line_3 adresse_facturation,
                                           (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                           FROM gl_code_combinations WHERE code_combination_id=assa.accts_pay_code_combination_id) compte_fournisseur,
                                           (select segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||'.'||segment8||'.'||segment9||'.'||segment10||'.'||segment11||'.'||segment12
                                           FROM gl_code_combinations WHERE code_combination_id=assa.prepay_code_combination_id) compte_acompte,
                                           assa.accts_pay_code_combination_id,
                                           assa.prepay_code_combination_id,
                                           TO_CHAR(assa.last_update_date,'YYYYMMDD') date_maj_site,
                                           assa.province province,
                                           NVL(assa.purchasing_site_flag,'N')  site_achat,
                                           NVL(assa.pay_site_flag,'N') site_paiement,
                                           --DECODE (fourniseur.type_fournisseur,'FACTOR',assa.attribute5,null) affacturage,
                                           CASE WHEN EXISTS (SELECT 1 from iby_ext_payee_relationships where supplier_site_id=assa.vendor_site_id 
                                           AND party_id=fourniseur.party_id  AND primary_flag= 'Y' 
                                           AND (sysdate BETWEEN from_date AND NVL(TO_DATE,sysdate))) THEN 'Y'
                                           ELSE  NULL  END AS affacturage,
                                           (SELECT name FROM hr_operating_units WHERE organization_id=assa.org_id )  code_uo,
                                           assa.offset_tax_flag flag_intracommunautaire,
                                           hcp3.email_address,
                                           DECODE(pm.payment_method_code,'WIRE',1,0)f_treglement
                                    FROM   ap_supplier_sites_all assa,
                                           hr_operating_units hou, --AAM
                                           hz_party_sites        hps,
                                           hz_contact_points     hcp1,
                                           hz_contact_points     hcp2,
                                           hz_contact_points     hcp3,
                                           hr_locations_all      shiploc,
                                           hr_locations_all      billloc,
                                           iby_external_payees_all payee,
                                           iby_ext_party_pmt_mthds pm
                                    WHERE  vendor_id = fourniseur.vendor_id
                                    AND   assa.org_id = hou.organization_id --AAM
                                    AND   hou.name    != 'REF9999'          --AAM
                                    AND    hps.party_site_id(+) = assa.party_site_id
                                    AND    hcp1.owner_table_id(+) = hps.party_site_id
                                    AND    hcp1.contact_point_type(+) = 'PHONE'
                                    AND    hcp1.phone_line_type(+) = 'GEN'
                                    AND    hcp1.status(+) = 'A'
                                    AND    hcp1.owner_table_name(+) = 'HZ_PARTY_SITES'
                                    AND    hcp1.primary_flag(+) = 'Y'
                                    --< OBE
                                    AND   (hcp1.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                        FROM hz_contact_points
                                                                        WHERE owner_table_id     = hcp1.owner_table_id
                                                                        AND   contact_point_type = 'PHONE'
                                                                        AND   phone_line_type    = 'GEN'
                                                                        AND   status             = 'A'
                                                                        AND   primary_flag       = 'Y'
                                                                        AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                        )   
                                            OR 1 = DECODE(hcp1.contact_point_id,NULL,1,2)    
                                            )                                        
                                    --> OBE                                    
                                    AND    hcp2.owner_table_id(+) = hps.party_site_id
                                    AND    hcp2.contact_point_type(+) = 'PHONE'
                                    AND    hcp2.phone_line_type(+) = 'FAX'
                                    AND    hcp2.status(+) = 'A'
                                    AND    hcp2.owner_table_name(+) = 'HZ_PARTY_SITES'
                                    --< OBE
                                    AND   (hcp2.contact_point_id    = (SELECT MAX(contact_point_id)
                                                                        FROM hz_contact_points
                                                                        WHERE owner_table_id     = hcp2.owner_table_id
                                                                        AND   contact_point_type = 'PHONE'
                                                                        AND   phone_line_type    = 'FAX'
                                                                        AND   status             = 'A'
                                                                        AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                        )   
                                            OR 1 = DECODE(hcp2.contact_point_id,NULL,1,2)    
                                            )                                        
                                    --> OBE                                    
                                    AND    shiploc.ship_to_site_flag(+) = 'Y'
                                    AND    hcp3.contact_point_type(+) = 'EMAIL' 
                                    AND    hcp3.owner_table_id(+) = hps.party_site_id
                                    AND    hcp3.status(+) = 'A' 
                                    AND    hcp3.owner_table_name(+) = 'HZ_PARTY_SITES' 
                                    AND    hcp3.primary_flag(+) = 'Y' 
                                    --< OBE
                                    AND   (hcp3.contact_point_id   = (SELECT MAX(contact_point_id)
                                                                        FROM hz_contact_points
                                                                        WHERE owner_table_id     = hcp3.owner_table_id
                                                                        AND   contact_point_type = 'EMAIL'
                                                                        AND   status             = 'A'
                                                                        AND   primary_flag       = 'Y'
                                                                        AND   owner_table_name   = 'HZ_PARTY_SITES'
                                                                        )   
                                            OR 1 = DECODE(hcp3.contact_point_id,NULL,1,2)    
                                            )                                                
                                    --> OBE                                    
                                    AND    sysdate < NVL(TRUNC(shiploc.inactive_date), sysdate + 1)
                                    AND    shiploc.location_id(+) = assa.ship_to_location_id
                                    AND    billloc.ship_to_site_flag(+) = 'Y'
                                    AND    sysdate < NVL(TRUNC(billloc.inactive_date), sysdate + 1)
                                    AND    billloc.location_id(+) = assa.bill_to_location_id
                                    --AND    payee.payee_party_id = hps.party_id
                                    AND    payee.payment_function = 'PAYABLES_DISB'
                                    --AND    payee.party_site_id = assa.party_site_id
                                    AND    payee.supplier_site_id = assa.vendor_site_id
                                    AND    payee.org_id = assa.org_id
                                    AND    payee.org_type = 'OPERATING_UNIT'
                                    AND    payee.ext_payee_id = pm.ext_pmt_party_id (+)
                                    --< OBE artf2141490 
                                    --AND    pm.primary_flag  = 'Y'
                                    AND NVL(pm.primary_flag,'Y')  = 'Y' 
                                    AND payee.party_site_id IS NOT NULL
                                    --> OBE artf2141490
                                    AND    assa.pay_site_flag = NVL(p_site_paiement, assa.pay_site_flag)
                                )

            LOOP
            
                v_cur_site_vide := FALSE;
                
                --v_message   := 'Ecriture des informations des sites fournisseurs pour chaque fournisseur';
                --Dka_Tools_Pkg.Put_Outdebug_Message('Ecriture des informations du site fournisseur '||site_fourniseur.code_site_fournisseur||' eligibles pour le fournisseur '|| fourniseur.code_fournisseur);
                --RBE artf2338800
                IF LENGTH(site_fourniseur.telephone) > 15 THEN
                    site_fourniseur.telephone := REPLACE (site_fourniseur.telephone,' ','');
                    v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                    Dka_Tools_Pkg.put_log_message(v_message);
                    IF LENGTH(site_fourniseur.telephone) > 15 THEN
                        site_fourniseur.telephone :=  SUBSTR(site_fourniseur.telephone,1,15);
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                        Dka_Tools_Pkg.put_log_message(v_message);
                    END IF;
                END IF;

                --RBE artf2338800
                IF LENGTH(site_fourniseur.FAX) > 15 THEN
                    site_fourniseur.FAX := REPLACE (site_fourniseur.FAX,' ','');
                    v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, les espaces sont supprimés';
                    Dka_Tools_Pkg.put_log_message(v_message);
                    IF LENGTH(site_fourniseur.FAX) > 15 THEN
                        site_fourniseur.FAX :=  SUBSTR(site_fourniseur.FAX,1,15);
                        v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : la taille du champ FAX dépasse 15 caractères, le champ a été tronqué ';
                        Dka_Tools_Pkg.put_log_message(v_message);
                    END IF;
                END IF;
                --RBE artf2338800
                IF site_fourniseur.complement_siret IS NULL THEN
                    site_fourniseur.complement_siret := 'PROVI';
                    v_message   := 'Site (ID: '||site_fourniseur.vendor_site_id||') : Le champ complément SIRET est vide, il a été remplacé par la valeur PROVI';
                    Dka_Tools_Pkg.put_log_message(v_message);
                END IF;
                    
                v_fichier_courant := v_non_fi_fournisseurs;
                utl_file.put_line(v_f, REPLACE(fourniseur.code_fournisseur            ||';'||                
                                        REPLACE(fourniseur.nom_fournisseur_long,';',' ')        ||';'||                
                                        fourniseur.nom_fournisseur_court      ||';'||                
                                        fourniseur.code_partenaire            ||';'||                
                                        fourniseur.num_siren                  ||';'||                
                                        site_fourniseur.complement_siret      ||';'||  
                                        site_fourniseur.code_rcs              ||';'||                                
                                        fourniseur.num_tva                    ||';'||                
                                        fourniseur.type_fournisseur           ||';'||                
                                        fourniseur.num_ape                    ||';'||                
                                        site_fourniseur.code_site_fournisseur ||';'||                                
                                        REPLACE(REPLACE(site_fourniseur.adresse1,';',''),'"','')              ||';'||                                
                                        REPLACE(REPLACE(site_fourniseur.adresse2,';',''),'"','')              ||';'||                                
                                        REPLACE(REPLACE(site_fourniseur.adresse3,';',''),'"','')              ||';'||                                
                                        REPLACE(REPLACE(site_fourniseur.adresse4,';',''),'"','')              ||';'||                               
                                        site_fourniseur.ville                 ||';'||                      
                                        site_fourniseur.code_postal           ||';'||
                                        site_fourniseur.pays                  ||';'||
                                        site_fourniseur.telephone             ||';'||
                                        site_fourniseur.fax                   ||';'||
                                        site_fourniseur.date_creation_site    ||';'||
                                        site_fourniseur.date_fin_site         ||';'||
                                        site_fourniseur.adresse_livraison     ||';'||
                                        site_fourniseur.adresse_facturation   ||';'||
                                        site_fourniseur.compte_fournisseur    ||';'||
                                        site_fourniseur.compte_acompte        ||';'||
                                        fourniseur.fournisseur_service        ||';'||
                                        fourniseur.fournisseur_combustible    ||';'||
                                        fourniseur.date_maj_entete            ||';'||
                                        site_fourniseur.date_maj_site         ||';'||
                                        fourniseur.creation_fournisseur       ||';'||
                                        fourniseur.fin_activite_fournisseur   ||';'||
                                        site_fourniseur.province              ||';'||
                                        fourniseur.code_accord                ||';'||
                                        site_fourniseur.site_achat            ||';'||
                                        site_fourniseur.site_paiement         ||';'||
                                        site_fourniseur.affacturage           ||';'||
                                        fourniseur.federal_reportable_flag    ||';'||
                                        site_fourniseur.code_uo               ||';'||
                                        fourniseur.classification_achat       ||';'||
                                        site_fourniseur.flag_intracommunautaire  ||';'||  
                                        REPLACE(site_fourniseur.email_address,';','')            ||';'||
                                        site_fourniseur.vendor_site_id           ||';'|| 
                                        site_fourniseur.f_treglement,chr(9),'') );  
                
                
                FOR contact_fourniseur IN (SELECT  vendor_contact_id,
                                                vendor_id,
                                                vendor_site_id,
                                                last_name  nom_contact,   -- RBE artf2104094 
                                                first_name prenom_contact,-- RBE artf2104094 
                                                title fonction,
                                                phone telephone,
                                                email_address mail,
                                                last_update_date,
                                                attribute12 
                                        FROM    po_vendor_contacts
                                        WHERE   vendor_id=fourniseur.vendor_id
                                        AND     vendor_site_id =site_fourniseur.vendor_site_id
                                    ) 
                LOOP
                
                    --v_message   := 'Ecriture des informations des contact site fournisseurs eligibles pour chaque fournisseur';
                    --Dka_Tools_Pkg.Put_Outdebug_Message(v_message);
                    v_fichier_courant := v_non_fi_contact;
                    
                    IF contact_fourniseur.nom_contact IS NULL OR INSTR(contact_fourniseur.nom_contact,';') > 0 THEN --RBE artf2338800
                        --v_message   := 'Le contact (ID: '||contact_fourniseur.vendor_contact_id||') ne sera pas extrait';
                        v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : le champ nom du contact est vide ou il contient ";", il a été remplacé par la valeur CONTACTDEF';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        --CONTINUE;
                        contact_fourniseur.nom_contact := 'CONTACTDEF';
                    END IF;
                    
                    --RBE artf2338800
                    IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                        contact_fourniseur.telephone := REPLACE (contact_fourniseur.telephone,' ','');
                        v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, les espaces sont supprimés';
                        Dka_Tools_Pkg.put_log_message(v_message);
                        IF LENGTH(contact_fourniseur.telephone) > 15 THEN
                            contact_fourniseur.telephone :=  SUBSTR(contact_fourniseur.telephone,1,15);
                            v_message   := 'Contact (ID: '||contact_fourniseur.vendor_contact_id||') : la taille du champ Telephone dépasse 15 caractères, le champ a été tronqué ';
                            Dka_Tools_Pkg.put_log_message(v_message);
                        END IF;
                    END IF;
                    
                    utl_file.put_line(v_csf,REPLACE(fourniseur.code_fournisseur                    ||';'||
                                            site_fourniseur.code_site_fournisseur          ||';'||
                                            site_fourniseur.code_uo                        ||';'||
                                            site_fourniseur.vendor_site_id                 ||';'||
                                            contact_fourniseur.nom_contact                 ||';'||
                                            contact_fourniseur.prenom_contact              ||';'||
                                            contact_fourniseur.fonction                    ||';'||
                                            contact_fourniseur.telephone                   ||';'||
                                            REPLACE(contact_fourniseur.mail,';',''),chr(9),'')                         
                                        );
                    
                    v_csf_count:=v_csf_count+1;
                    
                END LOOP;              

                v_f_count:=v_f_count+1;
                    
            END LOOP;
            
            IF  v_cur_site_vide THEN 
                p_errbuff:= 'Aucun site n''a  pu etre recuperé pour ce fournisseur '||fourniseur.code_fournisseur ;
                Dka_Tools_Pkg.put_log_message(p_errbuff);
            END IF;
        
        END LOOP;
        
        IF NOT v_cur_vide THEN   
            p_errbuff:= '=========================================================================';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            p_errbuff:= 'Des founisseurs ont bien été extraits dans le fichier';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
           
            utl_file.fclose(v_f);
            utl_file.fclose(v_csf);

            COMMIT;

        ELSE
            v_message   := 'Aucun fournisseur n''a ete identifie comme eligible';
             
            IF UTL_FILE.IS_OPEN(v_f) THEN
                UTL_FILE.FREMOVE(v_nom_chemin,v_non_fi_fournisseurs);
            END IF;
            IF UTL_FILE.IS_OPEN(v_csf) THEN
                UTL_FILE.FREMOVE(v_nom_chemin,v_non_fi_contact);
            END IF;

            p_retcode := 0;
            p_errbuff:= v_message;
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        END IF;
          
        ---------------
        -- Statistiques
        ---------------
        p_errbuff:= '=========================================================================';
        Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
        
        p_errbuff:= 'Nombre d''enregistrements extraits dans le fichier FOURNISSEURS: ' ||TO_CHAR(v_f_count);
        Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
        p_errbuff:= 'Nombre d''enregistrements extraits dans le fichier FOURNISSEURS_CONTACTS: ' ||TO_CHAR(v_csf_count);
        Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);


    EXCEPTION
        WHEN utl_file.invalid_operation THEN             
            p_retcode := 2;
            p_errbuff:= 'Erreur : Operation invalide sur le fichier ' ||v_fichier_courant ||'au niveau du directory '||v_nom_chemin;
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.invalid_path THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur : Repertoire invalide. Veuillez renseigner le directory ' ||v_nom_chemin ||' dans DBA_DIRECTORIES et s¿assurer que ce repertoire existe bien sur la machine';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.invalid_mode THEN
            p_retcode := 2;
            p_errbuff:= 'Mode invalide';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.invalid_filehandle THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur :Descripteur de fichier '||v_fichier_courant ||' non valide ';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.read_error THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur de lecture';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.internal_error THEN
            p_retcode := 2;
            p_errbuff:= 'Erreur interne';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
            
        WHEN utl_file.delete_failed THEN
            p_retcode := 2;
            p_errbuff:= 'Impossible de supprimer les fichiers';
            Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuff);
        WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            p_errbuff  := 'ERREUR dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Dka_Tools_Pkg.put_debug_message('-------------------- ERREUR --------------------');
            Dka_Tools_Pkg.put_debug_message('Package   : '||v_package);
            Dka_Tools_Pkg.put_debug_message('Procedure : '||v_procedure);
            Dka_Tools_Pkg.put_debug_message('Exception : OTHERS');
            Dka_Tools_Pkg.put_debug_message('Message   : '||v_message);
            Dka_Tools_Pkg.put_debug_message('Cause     : '||v_sqlerrm);
            Dka_Tools_Pkg.put_debug_message('------------------------------------------------');
            Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================================');
            Dka_Tools_Pkg.Put_Outdebug_Message('Traitement '||v_nom_traitement||' termine en erreur         ');
            Dka_Tools_Pkg.Put_Outdebug_Message('=========================================================================');
            ROLLBACK;

    END Export_mensuel; 
        
        
END DKA_APFRSEXP_PKG;
/
SHOW ERRORS PACKAGE DKA_APFRSEXP_PKG;
EXIT
