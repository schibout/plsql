CREATE OR REPLACE PACKAGE BODY APPS.dka_sapfrs_history_pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : dka_sapfrs_history_pkg.pkb
-- DESCRIPTION       : dka_sapfrs_history_pkg package body :
---
--- AUTEUR           : Saloua HAHIOUI
--- DATE DE CREATION : 23/12/2021
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- ---------- --- -------------------------------------------------------------------------



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----------------------------------------------------------------
 -- NOM         : get_vendor_party
 -- DESCRIPTION : Procédure qui ramène le vendor_id et vendor_site_id
 -----------------------------------------------------------------
PROCEDURE get_vendor_party (pn_party_site_id  IN   NUMBER,
                pn_vendor_id      OUT  NUMBER,
              pn_vendor_site_id OUT  NUMBER) IS
BEGIN
    Select
  vendor_id ,
  vendor_site_id
    into
  pn_vendor_id ,
  pn_vendor_site_id
    from ap_supplier_sites_all asaa
where asaa.party_site_id = pn_party_site_id;
EXCEPTION
       WHEN OTHERS THEN NULL;
END get_vendor_party;
-----------------------------------------------------------------
 -- NOM         : get_vendor_id
 -- DESCRIPTION : Procédure qui ramène le vendor_id
 -----------------------------------------------------------------
PROCEDURE get_vendor_id (pn_supplier_site_id  IN   NUMBER,
                pn_vendor_id      OUT  NUMBER
              ) IS
BEGIN

    SELECT
    ss.vendor_id
  into
  pn_vendor_id

FROM

    ap_supplier_sites_all ss
WHERE
    ss.vendor_site_id = pn_supplier_site_id;


EXCEPTION
       WHEN OTHERS THEN NULL;
END get_vendor_id;
-----------------------------------------------------------------
 -- NOM         : get_vendor_name
 -- DESCRIPTION : Procédure qui ramène le vendor_name
 -----------------------------------------------------------------
PROCEDURE get_vendor_name (pn_supplier_site_id  IN   NUMBER,
              pn_vendor_name    out varchar2,
              pn_vendor_site_code out varchar2
              ) IS
BEGIN
/*    SELECT
    ss.vendor_id
  into
  pn_vendor_id

FROM

    ap_supplier_sites_all ss
WHERE
    ss.vendor_site_id = pn_supplier_site_id;
*/
select sit.vendor_site_code , sup.VENDOR_NAME
  into pn_vendor_site_code, pn_vendor_name
  from AP_SUPPLIERS sup,
       AP_SUPPLIER_SITES_ALL sit
      where sit.vendor_id=sup.VENDOR_ID
      and sit.vendor_site_id = pn_supplier_site_id;



EXCEPTION
       WHEN OTHERS THEN NULL;
END get_vendor_name;
-------------------------------------------------------------
 -- NOM         : get_vendor_site_id
 -- DESCRIPTION : Procédure qui ramène  vendor_site_id
 -------------------------------------------------------------
PROCEDURE get_vendor_site_id (pn_ext_pmt_party_id  IN   NUMBER,
                pn_vendor_site_id    OUT  NUMBER) IS
BEGIN


      select distinct  supplier_site_id
    into
        pn_vendor_site_id
       from
       iby_external_payees_all epa
        where
         epa.ext_payee_id = pn_ext_pmt_party_id;


    EXCEPTION
       WHEN OTHERS THEN NULL;
END get_vendor_site_id;

-------------------------------------------------------------
 -- NOM         : get_payement_method
 -- DESCRIPTION : Procédure qui ramène  PAYMENT_METHOD_CODE
 -------------------------------------------------------------
PROCEDURE get_payement_method (pn_vendor_site_id  IN   NUMBER,
                              pn_ext_party_pmt_mthd_id  IN   NUMBER,
                               pn_primary_flag    IN   VARCHAR2,
                 pn_payment_method_code    OUT  VARCHAR2) IS
BEGIN
  select distinct  paym.payment_method_code
  into
    pn_payment_method_code
FROM

    iby_external_payees_all payee,
    iby_ext_party_pmt_mthds paym
WHERE
      payee.ext_payee_id = paym.ext_pmt_party_id
    AND    paym.ext_pmt_party_id = pn_vendor_site_id
  and  rownum < 2
    and paym.primary_flag = 'N' order by paym.last_update_date;
  --AND    paym.ext_party_pmt_mthd_id = pn_ext_party_pmt_mthd_id;


    EXCEPTION
       WHEN OTHERS THEN NULL;
END get_payement_method;
 -----------------------------------------------------------------
 -- NOM         : get_user_name
 -- DESCRIPTION : Procédure qui ramène le non d'utilisateur
 -----------------------------------------------------------------
    PROCEDURE get_user_name (pn_user_id IN NUMBER,
                 pn_user_name OUT VARCHAR2)
    IS

      BEGIN

        select fu.USER_NAME
        INTO pn_user_name
        FROM fnd_user fu
        where fu.user_id = pn_user_id;

    EXCEPTION
       WHEN OTHERS THEN NULL;
    END get_user_name;
  -----------------------------------------------------------------
 -- NOM         : get_term_name
 -- DESCRIPTION : Procédure qui ramène le nom du condition de règlement
 -----------------------------------------------------------------
    PROCEDURE get_term_name (pn_term_id IN NUMBER,
                 pn_term_name OUT VARCHAR2)
    IS

      BEGIN

        select at.NAME
        INTO pn_term_name
        FROM ap_terms at
        where at.term_id = pn_term_id;

    EXCEPTION
       WHEN OTHERS THEN NULL;
    END get_term_name;
    
 /*     -----------------------------------------------------------------
 -- NOM         : get_supplier_bank
 -- DESCRIPTION : Procédure qui ramène le nom du condition de règlement
 -----------------------------------------------------------------
    PROCEDURE get_supplier_bank (pn_last_update_date IN date,
                 pn_ext_bank_account IN NUMBER ,
                 pn_vendor_id OUT NUMBER,
                 pn_vendor_site_id OUT NUMBER)
    IS

      BEGIN
        
select distinct epa.supplier_site_id
into pn_vendor_site_id
  from IBY_PMT_INSTR_USES_ALL ipiua, iby_external_payees_all epa, ap_supplier_sites_all assa ,iby_ext_bank_accounts eba
 where ipiua.EXT_PMT_PARTY_ID = epa.ext_payee_id
 and assa.VENDOR_SITE_ID = epa.supplier_site_id
 and eba.ext_bank_account_id = instrument_id
 and eba.ext_bank_account_id = pn_ext_bank_account;
 
 
   SELECT                    
             assa.vendor_id
             into pn_vendor_id
            
FROM          ap_supplier_sites_all              assa
                 
WHERE        assa.vendor_site_id         =  pn_vendor_site_id    

;

    EXCEPTION
       WHEN OTHERS THEN NULL;
    END get_supplier_bank; */
-----------------------------------------------------------------
-- NOM         : insert_supplier_history
-- DESCRIPTION : Procédure qui ajoute un ou plusieurs enregistrements
--               dans la table DKA_SAPFRS_MAJ_HEADERS et DKA_SAPFRS_MAJ_HEADERS_HIST
-----------------------------------------------------------------

    PROCEDURE insert_supplier_history (pv_dml_type               IN VARCHAR2,
                                     pn_vendor_id              IN NUMBER,
                                     pd_last_update_date       IN DATE,
                                     pn_last_updated_by        IN NUMBER,
                                     pt_field_names            IN dka_typ_fields,
                                     pt_field_old_values       IN dka_typ_fields,
                                     pt_field_new_values       IN dka_typ_fields
                                   )
    IS

    i NUMBER;
    vn_seq_id               NUMBER(15);
    vn_seq_hist_id               NUMBER(15);
    BEGIN

                  -- Récupération de l'id de la ligne
         SELECT DKA_SAPFRS_MAJ_HEADERS_S.nextval
         INTO vn_seq_id
         FROM DUAL;

         SELECT DKA_SAPFRS_MAJ_HEADERS_HIST_S.nextval
         INTO vn_seq_hist_id
         FROM DUAL;

         IF pv_dml_type = 'CREATION'
         THEN
-- insert into  test_edb297 select 2,2 from dual ;
             -- On crée autant d'enregistrements qu'il y a de champs à tracer
            FOR i IN pt_field_names.FIRST .. pt_field_names.LAST
             LOOP
-- insert into  test_edb297 select 3,3 from dual ;

                 INSERT INTO DKA_SAPFRS_MAJ_HEADERS
                 (seq_id,
                  vendor_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
                  TO_CHAR(pd_last_update_date, 'DD/MM/YYYY HH24:MI'),
                  pn_last_updated_by,
                  pv_dml_type,
                  pt_field_names(i),
                  NULL,
                  pt_field_new_values(i)
                 );
-- insert into  test_edb297 select 4,4 from dual ;
             END LOOP;

         ELSIF pv_dml_type = 'MODIFICATION'
         THEN
             -- On crée autant de lignes qu'il y a de valeurs différentes entre les anciennes et les nouvelles
             FOR i IN pt_field_names.FIRST .. pt_field_names.LAST
             LOOP
                 IF NVL(pt_field_new_values(i), '$$$') <> NVL(pt_field_old_values(i), '$$$')
                 THEN
                     INSERT INTO DKA_SAPFRS_MAJ_HEADERS
                     (seq_id,
                      vendor_id,
                      last_update_date,
                      last_updated_by,
                      action_type,
                      item,
                      old_item_value,
                      new_item_value
                     )
                     VALUES
                     (vn_seq_id,
                      pn_vendor_id,
                      pd_last_update_date,
                      pn_last_updated_by,
                      pv_dml_type,
                      pt_field_names(i),
                      pt_field_old_values(i),
                      pt_field_new_values(i)
                     );
                 END IF;
             END LOOP;
        ELSIF pv_dml_type = 'SUPPRESSION'
        THEN

                     INSERT INTO DKA_SAPFRS_MAJ_HEADERS
                     (seq_id,
                      vendor_id,
                      last_update_date,
                      last_updated_by,
                      action_type,
                      item,
                      old_item_value,
                      new_item_value
                     )
                     VALUES
                     (vn_seq_id,
                      pn_vendor_id,
                      pd_last_update_date,
                      pn_last_updated_by,
                      pv_dml_type,
                      pt_field_names(i),
                      pt_field_old_values(i),
                      pt_field_new_values(i)
                     );
         END IF;
--delete from test_edb297;
         COMMIT;

    EXCEPTION
        WHEN OTHERS
        THEN null;

    END insert_supplier_history;

-----------------------------------------------------------------
-- NOM         : insert_supplier_sites_his
-- DESCRIPTION : Procédure qui ajoute un ou plusieurs enregistrements
--               dans la table DKA_SAPFRS_MAJ_SITES  et DKA_SAPFRS_MAJ_SITES _HIST
-----------------------------------------------------------------
 PROCEDURE insert_supplier_sites_history (pv_dml_type       IN VARCHAR2,
                                     pn_vendor_id              IN NUMBER,
                                     pn_vendor_site_id         IN NUMBER,
                                     pd_last_update_date       IN DATE,
                                     pn_last_updated_by        IN NUMBER,
                                     pt_field_names            IN dka_typ_fields,
                                     pt_field_old_values       IN dka_typ_fields,
                                     pt_field_new_values       IN dka_typ_fields
                                   )
    IS

    i NUMBER;
    vn_seq_id                    NUMBER(15);
    vn_seq_hist_id               NUMBER(15);
    vv_user_name                 VARCHAR2(50);
    BEGIN
   -- i :=1;
    dka_sapfrs_history_pkg.get_user_name(pn_last_updated_by, vv_user_name);

  IF vv_user_name <> 'EXPLOITATION' then
        -- Récupération de l'id de la ligne
         SELECT DKA_SAPFRS_MAJ_SITES_S.nextval
         INTO vn_seq_id
         FROM DUAL;

         SELECT DKA_SAPFRS_MAJ_SITES_HIST_S.nextval
         INTO vn_seq_hist_id
         FROM DUAL;


         IF pv_dml_type = 'CREATION'
         THEN
             -- On crée autant d'enregistrements qu'il y a de champs à tracer



            FOR i IN pt_field_new_values.FIRST .. pt_field_new_values.LAST
             LOOP

                 INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
            vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
            pn_vendor_site_id,
                  pd_last_update_date,
                  pn_last_updated_by,
                  pv_dml_type,
                  pt_field_names(i),
                  null,
                  pt_field_new_values(i)
                 );
             END LOOP;

         ELSIF pv_dml_type = 'MODIFICATION'
         THEN


             -- On crée autant de lignes qu'il y a de valeurs différentes entre les anciennes et les nouvelles
           FOR i IN pt_field_new_values.FIRST .. pt_field_new_values.LAST
       --  for i in 1..pt_field_names.count
             LOOP



                 IF NVL(pt_field_new_values(i), '$$$') <> NVL(pt_field_old_values(i), '$$$')
                 THEN

                      INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
          vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
          pn_vendor_site_id,
                  pd_last_update_date,
                  pn_last_updated_by,
                  pv_dml_type,
                  pt_field_names(i),
                  pt_field_old_values(i),
                  pt_field_new_values(i)
                 );
                 END IF;
        --     i:=i+1;


             END LOOP;

        ELSIF pv_dml_type = 'SUPPRESSION'
        THEN
             INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
            vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
            pn_vendor_site_id,
                  pd_last_update_date,
                  pn_last_updated_by,
                  pv_dml_type,
                  pt_field_names(i),
                  pt_field_old_values(i),
                  null
                 );
         END IF;
    END IF ;
     update DKA_SAPFRS_MAJ_SITES
        set vendor_id=pn_vendor_id
          , vendor_site_id =pn_vendor_site_id
      where vendor_id= vendor_site_id
        and action_type = 'CREATION';



    delete from  DKA_SAPFRS_MAJ_SITES bb
      where (item in (
              'Nom du site',
              'Adresse (Ligne 1)',
              'Adresse (Ligne 2)',
              'Adresse (Ligne 3)',
              'Adresse (Ligne 4)',
              'Ville',
              'Code postal',
              'Calcul de la TVA (Oui/Non)',
              'Conditions de règlements',
              'Site de règlements (Oui/Non)',
              'Site d''achat (Oui/Non)',
              'Unité opérationnelle',
              'Adresse mail avis virement',
              'Mode de paiement',
              'Statut (Date de désactivation)',
              'Bloquer le règlement/Factures non validées (Oui/Non)',
              'Bloquer le règlement/Factures non rapprochée (Oui/Non)',
              'Bloquer le règlement/Toutes les factures (Oui/Non)',
              'Autoriser la Tva Intracommunautaire (Oui/Non)'
              )
         and bb.seq_id >  (select min(aa.seq_id)
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.seq_id <> bb.seq_id
                                and aa.vendor_id = bb.vendor_id
                and exists ( select 1 from  ap_supplier_sites_all pvs,  ap_supplier_sites_all pvs_abs
                                              where pvs_abs.location_id=pvs.location_id
                                              and pvs.vendor_site_id = bb.vendor_site_id
                                              and pvs_abs.vendor_site_id =aa.vendor_site_id )

                              -- and aa.vendor_site_id  = bb.vendor_site_id
                and aa.last_updated_by = bb.last_updated_by
               -- and aa.action_type = bb.action_type
                and aa.item = bb.item
                and nvl(aa.old_item_value,'a#') = nvl(bb.old_item_value,'a#')
                and nvl(aa.new_item_value,'a#') = nvl(bb.new_item_value,'a#')
                and aa.action_type = 'CREATION'))
        or
        (bb.action_type = 'CREATION'
             and bb.item in (
                    'Adresse (Ligne 2)',
                    'Adresse (Ligne 3)',
                    'Adresse (Ligne 4)',
                    'Ville',
                    'Code postal')
             and nvl(bb.OLD_item_value,'#|') = '#|'
             and nvl(bb.new_item_value ,'#|') = '#|'
                       and  bb.seq_id <> (select max(aa.seq_id)
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.vendor_id = bb.vendor_id
                and aa.vendor_site_id  = bb.vendor_site_id
                and aa.last_updated_by = bb.last_updated_by
                and aa.action_type = 'MODIFICATION'
                and aa.item = bb.item));


     update DKA_SAPFRS_MAJ_SITES
        set new_item_value= ( select name
                  from hr_organization_units
                  where organization_id = new_item_value),
        old_item_value= ( select name
                  from hr_organization_units
                  where organization_id = old_item_value)
      where item= 'Unité opérationnelle'
        and action_type = 'CREATION'
        and ((trim(TRANSLATE(nvl(new_item_value,0), '0123456789-,.', ' ')) is null) and (trim(TRANSLATE(nvl(old_item_value,0), '0123456789-,.', ' ')) is null));




     update DKA_SAPFRS_MAJ_SITES bb
       set bb.action_type = 'CREATION'
      where (item in (
              'Adresse (Ligne 1)',
              'Adresse (Ligne 2)',
              'Adresse (Ligne 3)',
              'Adresse (Ligne 4)',
              'Ville',
              'Code postal'
              )
             and bb.action_type = 'MODIFICATION'
         and bb.seq_id >  (select min(aa.seq_id)
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.vendor_id = bb.vendor_id
                and aa.vendor_site_id  = bb.vendor_site_id
                and aa.last_updated_by = bb.last_updated_by
                and aa.action_type = 'CREATION'
                and aa.item = 'Unité opérationnelle'
                )
             and not exists (select 1
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.vendor_id = bb.vendor_id
                and aa.vendor_site_id  = bb.vendor_site_id
                and aa.last_updated_by = bb.last_updated_by
                and aa.action_type = 'CREATION'
                and aa.item = bb.item
                              and (old_item_value is not null or new_item_value is not null )
                ));

delete from  DKA_SAPFRS_MAJ_SITES bb
      where (item in (
              'Nom du site',
              'Adresse (Ligne 1)',
              'Adresse (Ligne 2)',
              'Adresse (Ligne 3)',
              'Adresse (Ligne 4)',
              'Ville',
              'Code postal',
              'Calcul de la TVA (Oui/Non)',
              'Conditions de règlements',
              --'Site de règlements (Oui/Non)',
             -- 'Site d''achat (Oui/Non)',
              'Unité opérationnelle',
              'Adresse mail avis virement',
              'Mode de paiement',
              --'Statut (Date de désactivation)',
              'Bloquer le règlement/Factures non validées (Oui/Non)',
              'Bloquer le règlement/Factures non rapprochée (Oui/Non)',
              'Bloquer le règlement/Toutes les factures (Oui/Non)',
              'Autoriser la Tva Intracommunautaire (Oui/Non)'
              )
         and   exists (select 1
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.seq_id <> bb.seq_id
                                and  aa.vendor_id = bb.vendor_id
                and exists ( select 1 from  ap_supplier_sites_all pvs,  ap_supplier_sites_all pvs_abs
                                              where pvs_abs.location_id=pvs.location_id
                                              and pvs.vendor_site_id = bb.vendor_site_id
                                              and pvs_abs.vendor_site_id =aa.vendor_site_id )

                              -- and aa.vendor_site_id  = bb.vendor_site_id
                and aa.last_updated_by = bb.last_updated_by
               -- and aa.action_type = bb.action_type
                and aa.item = bb.item
                and nvl(aa.old_item_value,'a#') = nvl(bb.old_item_value,'a#')
                and nvl(aa.new_item_value,'a#') = nvl(bb.new_item_value,'a#')))
        ;

 delete from  DKA_SAPFRS_MAJ_SITES bb
      where (item in (
              'Nom du site',
              'Adresse (Ligne 1)',
              'Adresse (Ligne 2)',
              'Adresse (Ligne 3)',
              'Adresse (Ligne 4)',
              'Ville',
              'Code postal',
              'Calcul de la TVA (Oui/Non)',
              'Conditions de règlements',
              --'Site de règlements (Oui/Non)',
             -- 'Site d''achat (Oui/Non)',
              'Unité opérationnelle',
              'Adresse mail avis virement',
              'Mode de paiement',
              --'Statut (Date de désactivation)',
              'Bloquer le règlement/Factures non validées (Oui/Non)',
              'Bloquer le règlement/Factures non rapprochée (Oui/Non)',
              'Bloquer le règlement/Toutes les factures (Oui/Non)',
              'Autoriser la Tva Intracommunautaire (Oui/Non)'
              )
         and  seq_id > (select min(aa.seq_id)
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.vendor_id = bb.vendor_id
                and exists ( select 1 from  ap_supplier_sites_all pvs,  ap_supplier_sites_all pvs_abs
                                              where pvs_abs.location_id=pvs.location_id
                                              and pvs.vendor_site_id = bb.vendor_site_id
                                              and pvs_abs.vendor_site_id =aa.vendor_site_id )
and aa.last_updated_by = bb.last_updated_by
               and aa.action_type = bb.action_type
                and aa.item = bb.item
                and nvl(aa.old_item_value,'a#') = nvl(bb.old_item_value,'a#')
                and nvl(aa.new_item_value,'a#') = nvl(bb.new_item_value,'a#')))
             and bb.action_type = 'MODIFICATION'         ;

 COMMIT;
 
 update DKA_SAPFRS_MAJ_SITES aa
set aa.vendor_id = ( Select vendor_id
    from ap_supplier_sites_all asaa
where asaa.party_site_id = aa.vendor_site_id 
and rownum<2),
    aa.vendor_site_id = (Select vendor_site_id
    from ap_supplier_sites_all asaa
where asaa.party_site_id = aa.vendor_site_id
and rownum<2)
 WHERE ACTION_TYPE ='CREATION'
AND  aa.item IN ('Statut', 'Nom de l''adresse')
and aa.last_update_date not in (select max(aa.last_update_date)
                       from DKA_SAPFRS_MAJ_SITES aa
                      where aa.item in('Statut', 'Nom de l''adresse')
                        and aa.action_type = 'CREATION');
 
 commit; 
    EXCEPTION
        WHEN OTHERS
        THEN null;

    END insert_supplier_sites_history;

-----------------------------------------------------------------
-- NOM         : insert_supplier_mode_p
-- DESCRIPTION : Procédure qui ajoute un ou plusieurs enregistrements
--               dans la table DKA_SAPFRS_MAJ_SITES  et DKA_SAPFRS_MAJ_SITES _HIST
-----------------------------------------------------------------
 PROCEDURE insert_supplier_mode_p (pv_dml_type       IN VARCHAR2,
                                     pn_vendor_id              IN NUMBER,
                                     pn_vendor_site_id         IN NUMBER,
                                     pd_last_update_date       IN DATE,
                                     pn_last_updated_by        IN NUMBER,
                                     pt_field_names            IN dka_typ_fields,
                                     pt_field_old_values       IN dka_typ_fields,
                                     pt_field_new_values       IN dka_typ_fields
                                   )
    IS
    p_date                      date;
    i NUMBER;
    vn_seq_id                    NUMBER(15);
    vn_seq_hist_id               NUMBER(15);
    vv_user_name                 VARCHAR2(50);
    BEGIN
    dka_sapfrs_history_pkg.get_user_name(pn_last_updated_by, vv_user_name);

  IF vv_user_name <> 'EXPLOITATION' then
        -- Récupération de l'id de la ligne
         SELECT DKA_SAPFRS_MAJ_SITES_S.nextval
         INTO vn_seq_id
         FROM DUAL;

         SELECT DKA_SAPFRS_MAJ_SITES_HIST_S.nextval
         INTO vn_seq_hist_id
         FROM DUAL;

         IF pv_dml_type = 'CREATION'
         THEN
             -- On crée autant d'enregistrements qu'il y a de champs à tracer
        FOR i IN pt_field_names.FIRST .. pt_field_names.LAST
             LOOP
            update  DKA_SAPFRS_MAJ_SITES
      set     new_item_value = pt_field_new_values(i)
      where last_update_date = (select max(last_update_date) from DKA_SAPFRS_MAJ_SITES)
      and  vendor_site_id = pn_vendor_site_id
      and   item = 'Mode de paiement';
      end loop;
         ELSIF pv_dml_type = 'MODIFICATION'
         THEN
        select max(last_update_date) into p_date from DKA_SAPFRS_MAJ_SITES;

      if p_date = pd_last_update_date then
         -- On crée autant d'enregistrements qu'il y a de champs à tracer
       FOR i IN pt_field_names.FIRST .. pt_field_names.LAST
             LOOP
        update  DKA_SAPFRS_MAJ_SITES
        set     new_item_value = pt_field_new_values(i)
        where last_update_date = (select max(last_update_date) from DKA_SAPFRS_MAJ_SITES)
        and  vendor_site_id = pn_vendor_site_id
        and   item = 'Mode de paiement';
             end loop;
       else
             -- On crée autant de lignes qu'il y a de valeurs différentes entre les anciennes et les nouvelles
             FOR i IN pt_field_names.FIRST .. pt_field_names.LAST
             LOOP
                 IF NVL(pt_field_new_values(i), '$$$') <> NVL(pt_field_old_values(i), '$$$')
                 THEN
                      INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
          vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
          pn_vendor_site_id,
                  pd_last_update_date,
                  pn_last_updated_by,
                  pv_dml_type,
                  pt_field_names(i),
                  pt_field_new_values(i),
                  pt_field_old_values(i)--pt_field_new_values(i)
                 );
                 END IF;
             END LOOP;
        end if ;
        ELSIF pv_dml_type = 'SUPPRESSION'
        THEN
             INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
            vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
            pn_vendor_site_id,
                  pd_last_update_date,
                  pn_last_updated_by,
                  pv_dml_type,
                  pt_field_names(i),
                  pt_field_old_values(i),
                  null
                 );
         END IF;
    END IF ;
    COMMIT;

    EXCEPTION
        WHEN OTHERS
        THEN null;

    END insert_supplier_mode_p;
-----------------------------------------------------------------
-- NOM         : INSERT_CUSTOMER_HISTORY
-- DESCRIPTION : Procédure qui ajoute un ou plusieurs enregistrements
--               dans la table DKA_SAPFRS_MAJ_SITES  et DKA_SAPFRS_MAJ_SITES _HIST
-----------------------------------------------------------------

PROCEDURE INSERT_CUSTOMER_HISTORY (  pv_dml_type             IN VARCHAR2,
                                     pn_ext_bank_account_id    IN NUMBER,
                                     pd_last_update_date       IN DATE,
                                     pn_last_updated_by        IN NUMBER,
                                     pt_field_names            IN dka_typ_fields,
                                     pt_field_old_values       IN dka_typ_fields,
                                     pt_field_new_values       IN dka_typ_fields
                                    )IS
     CURSOR cur_site_fournisseur IS
     select distinct   ext_pmt_party_id

       from
        iby_pmt_instr_uses_all  piu
        where
        piu.instrument_id  = pn_ext_bank_account_id
        and rownum<2
  ;
 v_vendor_site_id number;
 v_vendor_id number;


BEGIN




for rec_site_fournisseur  IN  cur_site_fournisseur LOOP

get_vendor_site_id (rec_site_fournisseur.ext_pmt_party_id  ,
                v_vendor_site_id );


get_vendor_id (v_vendor_site_id ,
                v_vendor_id );


insert_supplier_sites_history(pv_dml_type,                  -- Type de l'opération DML
                               v_vendor_id,              --
                               v_vendor_site_id,         -- --
                               pd_last_update_date,       -- -- -- valeurs permanentes
                               pn_last_updated_by,        -- --
                               pt_field_names,              -- Chaine contenant la liste des champs tracés
                               pt_field_old_values,         -- Anciennes valeurs -> NULL
                               pt_field_new_values          -- Nouvelles valeurs
                                );


end loop;
commit;

END INSERT_CUSTOMER_HISTORY;

END dka_sapfrs_history_pkg;
/
SHOW ERRORS
EXIT
