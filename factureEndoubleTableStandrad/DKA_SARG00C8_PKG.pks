CREATE OR REPLACE PACKAGE BODY DKA_AR_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_AR_TOOLS_PKG.pkb
-- DESCRIPTION       : DKA_AR_TOOLS_PKG package body : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  10/01/2016 MEG Modification dans le cadre de l'artf2077959 
--  11/08/2017 NBO artf2211142 - Fonction commune de détermination d'un compte de surtaxe
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

---------------------------------------------------------------------------------------
--  Nom           : get_customer_partner
--  Description   : Procédure permettant d'obtenir les identifiants du client, addresse client,
--                  et lieu de facturation correspondant a la société passée en parametre
--                  et définis dans le centre de gestion et l'organisation passés en entrée
--
--  PARAMETRES :
--          pv_orgname              Entrée
--          pn_org_id               Entrée
--          pn_customer_id                 Sortie
--          pv_customer_number             Sortie
--          pn_customer_site_id            Sortie
--          pn_bill_to_site_use_id         Sortie
--          pv_interco                     Sortie
--          pv_errbuf              Entrée  Sortie
--          pn_retcode                     Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_customer_partner (
        pv_orgname               IN       VARCHAR2,
        pn_org_id                IN       NUMBER,
        pn_customer_id              OUT   NUMBER,
        pv_customer_number          OUT   VARCHAR2,
        pn_customer_site_id         OUT   NUMBER,
        pn_bill_to_site_use_id      OUT   NUMBER,
        pv_interco                  OUT   VARCHAR2,
        pv_errbuf                IN OUT   VARCHAR2,
        pn_retcode                  OUT   NUMBER
    )
    IS
        CURSOR cur_customer (
            pv_orgname   IN   VARCHAR2,
            pn_org       IN   NUMBER
        )
        IS
            SELECT   hca.cust_account_id,
                     hca.account_number,
                     hcas.cust_acct_site_id,
                     hcsu.site_use_id,
                     hcas.attribute8
            FROM     gl_code_combinations gcc, 
                     hz_cust_site_uses_all hcsu,
                     hz_cust_acct_sites_all hcas,
                     hz_cust_accounts hca
            WHERE        hcsu.gl_id_rec = gcc.code_combination_id
                     AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcsu.org_id = hcas.org_id
                     AND hca.cust_account_id = hcas.cust_account_id
                     AND hcsu.site_use_code = 'BILL_TO'
                     AND hcsu.status = 'A'
                     AND hcas.status = 'A'
                     AND hcas.attribute8 = pv_orgname
                     AND hcas.org_id = pn_org
            ORDER BY hcsu.primary_flag DESC,
                     hcas.creation_date ASC; -- le site principal sera le premier cree

        rec_customer       cur_customer%ROWTYPE;
        e_customer_error   EXCEPTION;
    BEGIN
        -- Recuperation des informations liees au client
        OPEN cur_customer (pv_orgname, pn_org_id);
        FETCH cur_customer INTO rec_customer;

        IF cur_customer%NOTFOUND
        THEN
          
          BEGIN
            SELECT * 
              INTO pn_customer_id,
                   pv_customer_number,
                   pn_customer_site_id,
                   pn_bill_to_site_use_id,
                   pv_interco
            FROM (  
              SELECT hca.cust_account_id,
                     hca.account_number,
                     hcas.cust_acct_site_id,
                     hcsu.site_use_id,
                     hcas.attribute8
                FROM gl_code_combinations gcc, 
                     hz_cust_site_uses_all hcsu,
                     hz_cust_acct_sites_all hcas,
                     hz_cust_accounts hca
               WHERE hcsu.gl_id_rec = gcc.code_combination_id
                 AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                 AND hcsu.org_id = hcas.org_id
                 AND hca.cust_account_id = hcas.cust_account_id
                 AND hcsu.site_use_code = 'BILL_TO'
                 AND hcsu.status = 'A'
                 AND hcas.status = 'A'
                 AND hcas.attribute8 = 'XXX' || substr(pv_orgname, -4)
                 AND hcas.org_id = pn_org_id
            ORDER BY hcsu.primary_flag DESC,
                     hcas.creation_date ASC
               )
            WHERE ROWNUM = 1;
               
          EXCEPTION
            WHEN OTHERS THEN
                 RAISE e_customer_error;
          END;
          
        ELSE
            pn_customer_id            := rec_customer.cust_account_id;
            pv_customer_number        := rec_customer.account_number;
            pn_customer_site_id       := rec_customer.cust_acct_site_id;
            pn_bill_to_site_use_id    := rec_customer.site_use_id;
            pv_interco                := rec_customer.attribute8;
        END IF; --rec_customer%NOTFOUND

        CLOSE cur_customer;
    EXCEPTION
        WHEN e_customer_error
        THEN
            pv_errbuf     := 'get_customer_partner : pas de client partenaire';
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'Erreur get_customer_partner : WHEN_OTHERS  ' || SQLERRM;
            pn_retcode    := 2;
    END get_customer_partner;
    
---------------------------------------------------------------------------------------------------------------
  --  Nom           : alim_corresp_operations
  --  Description   :  procédure alimentant l'ecran Configuration /type de pieces 
  --                       dans resp DKA RB RESPONSABLE RAPPROCHEMENT
  --
  --  PARAMETRES    :
  --                     pv_type_operation  EFFETS ou PRELEVEMENT
  --
  --  VALEUR RETOURNEE :
  --     Description       : pn_retcode  
  --     Valeurs possibles :      0 succes, 1 erreur
---------------------------------------------------------------------------------------------------------------
  PROCEDURE alim_corresp_operations (pv_type_operation IN VARCHAR2, 
                                     pn_retcode        OUT number, 
                                     pv_err_buffer     OUT varchar2)
      
  IS 
    cn_remise_effets_encaissement number := 35;
    cn_prelevement_emis           number := 25;        
    vn_transaction_code           number;
    vv_methode                    AR_RECEIPT_METHODS.name%type;
      
  BEGIN
  
    pn_retcode :=0;
    --constantes pour 'Remise d'effet à l'encaissement'   35
    --                'Prélèvement émis'                  25 
  
    IF pv_type_operation = 'EFFETS' THEN
      vn_transaction_code := cn_remise_effets_encaissement;
      vv_methode := 'EFFET_DE_COMMERCE';
    ELSIF pv_type_operation = 'PRELEVEMENTS' THEN
      vn_transaction_code := cn_prelevement_emis;       
      vv_methode := 'PRELEVEMENT';
    ELSE 
      pn_retcode := 1;
      pv_err_buffer := 'alim_correspondances_operations::Valeur ' || pv_type_operation || ' innattendue pour pv_type_operation';
      return;
    END IF;
    
    begin
      insert into RB_BANK_TRANSACTION_CODES_LNK(BANK_TRANSACTION_CODE,
                                                CHECK_FORMAT_ID,
                                                RECEIPT_METHOD_ID,
                                                JE_CATEGORY_NAME,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATE_DATE,
                                                LAST_UPDATE_LOGIN)
                  select  vn_transaction_code, 
                          null, 
                          arm.RECEIPT_METHOD_ID, 
                          null, 
                          fnd_profile.value('USER_ID'), 
                          sysdate, 
                          fnd_profile.value('USER_ID'), 
                          sysdate, 
                          fnd_profile.value('LOGIN_ID') 
                  from AR_RECEIPT_CLASSES	arc
                  join AR_RECEIPT_METHODS	arm on(arm.receipt_class_id = arc.receipt_class_id)
                  where 1 = 1
                    and arc.name = vv_methode
                    and not exists (select 1 
                                    from RB_BANK_TRANSACTION_CODES_LNK
                                    where receipt_method_id = arm.RECEIPT_METHOD_ID);
      commit;

    exception
      when others then
        pn_retcode := 1;
        pv_err_buffer := 'alim_correspondances_operations::Erreur innatendue ' || SQLERRM;
    end;
    
  END alim_corresp_operations;
  
--  11/08/2017 NBO artf2211142 - Fonction commune de détermination d'un compte de surtaxe
  ----------------------------------------------------------------------------
  --  Nom           : isSurtaxeAccount
  --  Description   : Valide si un compte local est de type surtaxe
  -- PARAMETRES     :
  --  pv_localaccount    Compte local à valider
  --
  -- VALEUR RETOURNEE :
  --  VARCHAR2    TRUE Si il est de type local. 
  ----------------------------------------------------------------------------
  FUNCTION issurtaxeaccount(pv_localaccount fnd_flex_values.flex_value%TYPE)
    RETURN VARCHAR2 IS
    vn_count NUMBER;
  BEGIN

    SELECT COUNT(1)
      INTO vn_count
      FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
     WHERE ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
       AND ffv.enabled_flag = 'Y'
       AND ffv.attribute10 = 'Y'
       AND ffv.flex_value = pv_localaccount;

    IF vn_count = 1 THEN
      RETURN 'TRUE';
    ELSE
      RETURN 'FALSE';
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'FALSE';
  END issurtaxeaccount;
    
END DKA_AR_TOOLS_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;
