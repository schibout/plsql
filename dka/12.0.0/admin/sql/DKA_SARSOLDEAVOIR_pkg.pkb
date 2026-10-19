CREATE OR REPLACE PACKAGE BODY APPS.DKA_SARSOLDEAVOIR_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SARSOLDEAVOIR_PKG
  -- Nom              : Le package DKA_SARSOLDEAVOIR_PKG viendra créer le reglement d'un avoirs avec la demande de remboursement dans AP.
  -- Description      : Body du package DKA_SARSOLDEAVOIR_PKG
  -- Auteur           : IKRAME BALKHITY  
  -- Date de création : 29/05/2023
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------

  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  gn_user_id    fnd_user.user_id%TYPE;
  gn_login_id   fnd_logins.login_id%TYPE;
  gn_org_id     hr_all_organization_units.organization_id%TYPE;
  gn_request_id fnd_concurrent_requests.request_id%TYPE;

  -----------------------------------------------------------------
  --  Nom           : solde_avoirs_creat_remb
  --  Description   : Procédure pour creer un règlement par avoir à rembourser et alimenter l¿attribute9 de l¿avoir avec le motif de rejet.
  --
  --  PARAMETRES :
  --   p_message      texte a imprimer dans le log
  --
  -----------------------------------------------------------------

  PROCEDURE solde_avoirs_creat_remb(pv_errbuf     IN OUT VARCHAR2,
                                    pn_retcode    IN OUT NUMBER) IS
  
    l_return_status                VARCHAR2(1);
    l_msg_count                    NUMBER;
    l_msg_data                     VARCHAR2(240);
    l_count                        NUMBER;
    l_cash_receipt_id              NUMBER;
    l_msg_data_out                 VARCHAR2(240);
    l_mesg                         VARCHAR2(240);
    p_count                        NUMBER;
    vn_user_id                     VARCHAR2(240);
    vn_appl_id                     NUMBER;
    vn_resp_id                     NUMBER;
    vn_org_id                      NUMBER;
    v_return_status                VARCHAR2(30);
    v_return_status_1                VARCHAR2(30);
    vn_receipt_method              NUMBER;
    v_msg_count                    NUMBER;
    v_msg_data                     VARCHAR2(2000);
    v_attribute_rec                ar_receipt_api_pub.attribute_rec_type;
    v_cr_id                        NUMBER;
    v_commit                       VARCHAR2(1);
    l_message_api                  VARCHAR2(240);
    l_index                        NUMBER := 0;
    v_comments                     VARCHAR2(1900);
    vn_date_gl                     VARCHAR2(240);
    vv_new_num_reg                 VARCHAR2(240);
    vv_receipt_method_name         VARCHAR2(240);
    vv_party_id                    NUMBER;
    vv_party_site_id               NUMBER;
    vv_receivables_trx_id          NUMBER;
    vv_customer_trx_id             NUMBER;
    vv_cash_receipt_id             NUMBER;
    v_receipt_id                   ar_receivable_applications_all.cash_receipt_id%TYPE;
    v_receipt_number               ar_cash_receipts_all.receipt_number%TYPE;
    v_applied_payment_schedule_id  ar_receivable_applications_all.applied_payment_schedule_id%TYPE;
    v_msg_index_out                NUMBER(10);
    v_application_ref_type         ar_receivable_applications.application_ref_type%TYPE;
    v_application_ref_id           ar_receivable_applications.application_ref_id%TYPE;
    v_application_ref_num          ar_receivable_applications.application_ref_num%TYPE;
    v_secondary_application_ref_id ar_receivable_applications.secondary_application_ref_id%TYPE;
    v_receivable_application_id    ar_receivable_applications.receivable_application_id%TYPE;
    v_receivables_trx_id           ar_receivables_trx_all.receivables_trx_id%TYPE;
    vn_date                        VARCHAR2(24);
    vn_cptt                        NUMBER;
    pn_bank_account_num            VARCHAR2(240);
    pn_EXT_BANK_ACCOUNT_ID         NUMBER;
    vn_receipt_number              VARCHAR2(240);
    vn_amount                      number;
  
  vv_receipt_method_id           ar_receipt_methods.receipt_method_id%TYPE;
  vv_customer_id             ar_payment_schedules_all.customer_id%TYPE; 
  vv_customer_site_use_id      ar_payment_schedules_all.customer_site_use_id%TYPE;
  vv_org_id                  hr_operating_units.organization_id%TYPE;
  vv_gl_date                 DATE ;--ar_payment_schedules_all.gl_date%TYPE;
  vv_due_date              DATE;--ar_payment_schedules_all.due_date%TYPE;
  
  vn_tempo                         NUMBER         := 20;
    vn_request_id                    NUMBER (15);
  vn_request_id_1                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
  vv_applied_avoir                 VARCHAR2(5);
  v_amount                         ar_payment_schedules_all.amount_due_remaining%TYPE;
  
   lv_req_return_status BOOLEAN;
  
  
    CURSOR c1 IS
      SELECT * FROM dka_ar_remboursement_avoirs;
    
  CURSOR cur_remb IS
      SELECT distinct dar.UO, organization_id org_id
    FROM dka_ar_remboursement_avoirs dar , DKA_ARREMB_REPORTING dr , hr_operating_units hou
    WHERE dar.num_avoir = dr.num_avoir
    AND dar.uo = dr.uo
    AND hou.name = dar.uo
    AND dr.apply_flag = 'Y';
  
  BEGIN
  
  BEGIN
    
  DELETE FROM DKA_ARREMB_REPORTING;
  
  INSERT INTO DKA_ARREMB_REPORTING
  SELECT request_id , num_avoir, null ,null, null , uo 
  from dka_ar_remboursement_avoirs;
  
  COMMIT;
  
  END;
  
  
    FOR iapi IN c1 LOOP
      vn_user_id := fnd_global.user_id;
    vv_applied_avoir := 'N';
      dka_tools_pkg.put_log_message('++++++++++++++++++++ ');
      dka_tools_pkg.put_log_message('vn_user_id : ' || vn_user_id);
      dka_tools_pkg.put_log_message('Unité opérationnelle  : ' || iapi.uo);
      dka_tools_pkg.put_log_message('Num_avoir  : ' || iapi.num_avoir);
      dka_tools_pkg.put_log_message('IBAN : ' || iapi.IBAN);
      dka_tools_pkg.put_log_message('remb : ' || iapi.remb);
      begin
        
     
     --ARA optimisation
     
     vv_customer_trx_id := null;
     
     SELECT rcta.customer_trx_id
         INTO vv_customer_trx_id
         FROM ra_customer_trx_all       rcta,
               ar_payment_schedules_all  ps,
               ra_cust_trx_types_all   rctta
         WHERE rcta.cust_trx_type_id = rctta.cust_trx_type_id
         AND rcta.cust_trx_type_id = rctta.cust_trx_type_id
         AND ps.customer_trx_id = rcta.customer_trx_id
         AND ps.class = 'CM'
         AND rctta.name in ('MAN_AVOIR', 'SI_AMONT_AVOIR')
         AND rcta.attribute6 = 'OUI'
         and rcta.trx_number = iapi.num_avoir;
         
        
      EXCEPTION
        WHEN OTHERS THEN
          pv_errbuf := 'erreur lors de la recuperation de la valeur du champ customer_trx_id ' || SQLERRM;
          dka_tools_pkg.put_log_message(pv_errbuf);
      end;
    
    dka_tools_pkg.put_log_message('vv_customer_trx_id : ' || vv_customer_trx_id);
  
  
  
      IF iapi.remb = 'Y' THEN
        IF iapi.iban IS NOT NULL THEN
        
        --Initialisation
        vn_org_id := null;
        vn_appl_id := null;
        vn_resp_id := null;
        
          SELECT DISTINCT frv.application_id,
                          frv.responsibility_id,
                          fpov.profile_option_value
            INTO vn_appl_id, vn_resp_id, vn_org_id
            FROM apps.fnd_profile_options_vl    fpo,
                 apps.fnd_responsibility_vl     frv,
                 apps.fnd_profile_option_values fpov,
                 apps.hr_organization_units     hou
           WHERE hou.name = iapi.uo
             AND fpov.profile_option_value = to_char(hou.organization_id)
             AND fpo.profile_option_id = fpov.profile_option_id
             AND frv.responsibility_id = fpov.level_value
             AND frv.responsibility_name = iapi.uo || '_AR_ADMINISTRATEUR'
           ORDER BY frv.responsibility_name;
          dka_tools_pkg.put_log_message('vn_appl_id : ' || vn_appl_id);
          dka_tools_pkg.put_log_message('vn_resp_id : ' || vn_resp_id);
          dka_tools_pkg.put_log_message('vn_org_id : ' || vn_org_id);
          mo_global.init('AR');
          mo_global.set_policy_context('S', vn_org_id);
          fnd_global.apps_initialize(vn_user_id, vn_resp_id, vn_appl_id, 0);
         
     vv_new_num_reg := 'RBT_AVOIR_' || iapi.num_avoir;
          dka_tools_pkg.put_log_message('vv_new_num_reg : ' ||
                                        vv_new_num_reg);
          
          vn_receipt_number := null;
          vv_cash_receipt_id := null;
          
          begin
            SELECT receipt_number, CASH_RECEIPT_ID
              into vn_receipt_number, vv_cash_receipt_id
              FROM ar_cash_receipts_all
             WHERE status <> 'REV'
       and receipt_number = vv_new_num_reg;
          EXCEPTION
            WHEN no_data_found THEN
              vn_receipt_number := null;
          end;
          dka_tools_pkg.put_log_message('vn_receipt_number : ' ||
                                        vn_receipt_number);
        
          dka_tools_pkg.put_log_message('vv_cash_receipt_id : ' ||
                                        vv_cash_receipt_id);
                    
     
      vv_customer_id := null;
        vv_customer_site_use_id := null;
        vv_gl_date := null;
        vv_due_date := null;
        
                 
    BEGIN
    select customer_id, customer_site_use_id, gl_date,due_date
      INTO vv_customer_id, vv_customer_site_use_id , vv_gl_date, vv_due_date
      from ar_payment_schedules_all arp,
       ra_customer_trx_all      rct,
       hr_operating_units       hou
     where rct.customer_trx_id = arp.customer_trx_id
       and rct.customer_trx_id = vv_customer_trx_id
       and rct.org_id = hou.organization_id;
       EXCEPTION
       WHEN OTHERS THEN
       dka_tools_pkg.put_log_message('erreur requete1  : ' || SQLERRM);
         
        END;
        
        vv_receipt_method_id := null;
        vv_receipt_method_name := null;
        
        
    select RECEIPT_METHOD_ID,NAME
      INTO vv_receipt_method_id,vv_receipt_method_name
      from AR_RECEIPT_METHODS 
      where NAME = substr(iapi.uo, 4, 5) || '_' || substr(iapi.uo, 1, 3) ||
           '_VI_585000';

      dka_tools_pkg.put_log_message('vv_receipt_method_id : ' ||
                                        vv_receipt_method_id);              
                    
    dka_tools_pkg.put_log_message('VV_receipt_method_name : ' ||
                                        vv_receipt_method_name);
                                    
                    
                    
          vn_date := to_char(sysdate, 'DD/MM/YYYY');
          dka_tools_pkg.put_log_message('vn_date : ' || vn_date);
     
  
  v_amount := null;
  
  BEGIN
  SELECT ps.amount_due_remaining
    INTO v_amount
    FROM dka_ar_remboursement_avoirs   rcta,
            ar_payment_schedules_all    ps
    WHERE ps.customer_trx_id = rcta.id_avoir
      AND ps.class = 'CM'
      AND rcta.id_avoir = iapi.id_avoir;
    EXCEPTION
      WHEN OTHERS THEN
        dka_tools_pkg.put_log_message('Erreur récupération montant');
  END;

    IF iapi.AMT_NON_SLD != v_amount THEN
    vv_applied_avoir := 'Y';
    dka_tools_pkg.put_log_message('L''avoir ' || iapi.num_avoir || ' est déjà lettré partiellement après sélection');
  END IF;
    
          BEGIN
            if vn_receipt_number is null and vv_applied_avoir != 'Y' then
              dka_tools_pkg.put_log_message('Début ++++++++++ API : ar_receipt_api_pub.Create_cash ++++++++++ ');
              ar_receipt_api_pub.create_cash(p_api_version                  => 1.0,
                                             p_init_msg_list                => fnd_api.g_true,
                                             p_commit                       => fnd_api.g_true,
                                             p_validation_level             => fnd_api.g_valid_level_full,
                                             x_return_status                => v_return_status,
                                             x_msg_count                    => v_msg_count,
                                             x_msg_data                     => v_msg_data,
                                             p_usr_currency_code            => NULL,
                                             p_currency_code                => 'EUR',
                                             p_usr_exchange_rate_type       => NULL,
                                             p_exchange_rate_type           => NULL,
                                             p_exchange_rate                => NULL,
                                             p_exchange_rate_date           => NULL,
                                             p_amount                       => 0, --iapi.amt_avoir - iapi.amt_non_sld, 
                                             p_receipt_number               => vv_new_num_reg,
                       p_receipt_date               => sysdate,--iapi.date_avoir,
                       p_gl_date                    => sysdate,--vv_gl_date,
                       p_maturity_date              => sysdate,--vv_due_date,
                                            -- p_customer_number              => iapi.code_oracle,
                                             --p_customer_name                => null, ---iapi.nom_client, 
                                             p_location                     => iapi.code_anael,
                       p_customer_id                => vv_customer_id,
                       p_customer_site_use_id       => vv_customer_site_use_id,
                                             p_customer_bank_account_num    => NULL,
                                             p_customer_bank_account_name   => NULL,
                                             p_override_remit_account_flag  => NULL,
                                             p_remittance_bank_account_num  => NULL,
                                             p_remittance_bank_account_name => NULL,
                                             p_receipt_method_id            => vv_receipt_method_id,
                                             --p_receipt_method_name          => null,
                                             p_org_id                       => vn_org_id,
                                             p_called_from                  => 'pl/sql Script',
                                             p_attribute_rec                => v_attribute_rec,
                                             p_cr_id                        => v_cr_id);
                       
            
        dka_tools_pkg.put_log_message('v_return_status (API : ar_receipt_api_pub.Create_cash) : ' ||
                                              v_return_status);
              IF v_return_status != 'S' THEN
                dka_tools_pkg.put_log_message('v_return_status (API : ar_receipt_api_pub.Create_cash) : ' ||
                                              v_return_status);
                dka_tools_pkg.put_log_message('v_msg_count (API : ar_receipt_api_pub.Create_cash) : ' ||
                                              v_msg_count);
                dka_tools_pkg.put_log_message('v_msg_data (API : ar_receipt_api_pub.Create_cash) : ' ||
                                              v_msg_data);
                        
        IF v_msg_count = 1 Then
        dka_tools_pkg.put_log_message('v_msg_data (API : ar_receipt_api_pub.Create_cash) : '||v_msg_data);
        ELSIF v_msg_count > 1 Then
        FOR tst in 1..v_msg_count LOOP
        --p_count := p_count+1;
        v_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
        dka_tools_pkg.put_log_message('v_msg_data (API : message number ' || tst || ' ) : '||v_msg_data);
        
        
        END LOOP;
        END IF;
        dka_tools_pkg.put_log_message('Message de retour (API : ar_receipt_api_pub.Create_cash) : '||v_msg_data);
        
        BEGIN
          UPDATE DKA_ARREMB_REPORTING
          SET reg_flag = 'N'
          WHERE num_avoir = iapi.num_avoir
          AND uo = iapi.uo;
          
          COMMIT;
          
          EXCEPTION
          WHEN OTHERS THEN
          dka_tools_pkg.put_log_message('ERROR UPDATE activity_flag : ' || iapi.num_avoir );
          dka_tools_pkg.put_log_message('Erreur  : ' || SQLERRM);
        END;
        
        
        
              ELSE
                
                        
        BEGIN
          UPDATE DKA_ARREMB_REPORTING
          SET reg_flag = 'Y'
          WHERE num_avoir = iapi.num_avoir
          AND uo = iapi.uo;
          
         -- COMMIT;
          
          EXCEPTION
          WHEN OTHERS THEN
          dka_tools_pkg.put_log_message('ERROR UPDATE activity_flag : ' || iapi.num_avoir );
          dka_tools_pkg.put_log_message('Erreur  : ' || SQLERRM);
        END;
        
        
                COMMIT;
              end if;
              dka_tools_pkg.put_log_message('Fin ++++++++++ API : ar_receipt_api_pub.Create_cash ++++++++++ ');
            end if;
            begin
      
      --ARA 
      BEGIN
      SELECT CASH_RECEIPT_ID
              into vv_cash_receipt_id
              FROM ar_cash_receipts_all
             WHERE status <> 'REV'
       and receipt_number = vv_new_num_reg;
       
       EXCEPTION
         WHEN OTHERS THEN
           vv_cash_receipt_id := null;
           dka_tools_pkg.put_log_message('Erreur recuperation vv_cash_receipt_id');
       END;
              
                dka_tools_pkg.put_log_message('vv_cash_receipt_id : ' ||
                                              vv_cash_receipt_id);
            --
            
             
              SELECT acra.RECEIPT_NUMBER, sum(ARAA.AMOUNT_APPLIED)
                INTO vn_receipt_number, vn_amount
                FROM AR_CASH_RECEIPTS_ALL           acra,
                     AR_CASH_RECEIPT_HISTORY_ALL    acrha,
                     AR_RECEIVABLE_APPLICATIONS_ALL araa,
                     RA_CUSTOMER_TRX_ALL            rcta,
                     HZ_CUST_SITE_USES_ALL          HCSUA,
                     CE_BANK_ACCOUNTS               CBA,
                     CE_BANK_ACCT_USES_OU           REMIT_BANK,
                     CE_BANK_BRANCHES_V             BB
               WHERE acrha.CASH_RECEIPT_ID = acra.CASH_RECEIPT_ID
                 AND acrha.CASH_RECEIPT_HISTORY_ID =
                     araa.CASH_RECEIPT_HISTORY_ID(+)
                 AND acrha.CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID(+)
                 AND araa.display = 'Y'
                 AND rcta.CUSTOMER_TRX_ID(+) = araa.APPLIED_CUSTOMER_TRX_ID
                 AND rcta.BILL_TO_SITE_USE_ID = HCSUA.SITE_USE_ID(+)
                 AND REMIT_BANK.BANK_ACCT_USE_ID(+) =
                     acra.REMIT_BANK_ACCT_USE_ID
                 AND REMIT_BANK.ORG_ID(+) = acra.ORG_ID
                 AND remit_bank.bank_account_id = CBA.bank_account_id(+)
                 AND BB.BRANCH_PARTY_ID(+) = CBA.BANK_BRANCH_ID
                 AND acra.CASH_RECEIPT_ID = vv_cash_receipt_id
               GROUP BY acra.RECEIPT_NUMBER;
            EXCEPTION
              WHEN OTHERS THEN
                vn_amount := -1;
                vn_receipt_number := null;
                dka_tools_pkg.put_log_message('Erreur récuperation v_amount et vn_receipt_number : ' || SQLERRM);
            end;
            dka_tools_pkg.put_log_message('vn_amount : ' || vn_amount);
      
      dka_tools_pkg.put_log_message('vn_receipt_number : ' || vn_receipt_number);--ARA
      
      dka_tools_pkg.put_log_message('v_return_status : ' || v_return_status);--ARA
          
            IF (vn_receipt_number is not null and vn_amount < 0) OR
               v_return_status = 'S' then
            
              BEGIN
                dka_tools_pkg.put_log_message('Début ++++++++++ API : Ar_receipt_api_pub.apply ++++++++++ ');
                ar_receipt_api_pub.apply(p_api_version      => 1.0,
                                         p_init_msg_list    => fnd_api.g_true,
                                         p_validation_level => fnd_api.g_valid_level_full,
                                         x_return_status    => v_return_status_1,
                                         x_msg_count        => v_msg_count,
                                         x_msg_data         => v_msg_data,
                                         p_cash_receipt_id  => v_cr_id, --receipt_id du règlement à  0
                                         --p_receipt_number   => vv_new_num_reg,
                                         --p_trx_number       => iapi.num_avoir,
                                         p_customer_trx_id  => vv_customer_trx_id,
                                         p_org_id           => vn_org_id,
                                         p_commit           => v_commit,
                                         p_comments         => null);
              
                dka_tools_pkg.put_log_message(' ok ');
                dka_tools_pkg.put_log_message('Status (API : Ar_receipt_api_pub.apply) : ' ||
                                              v_return_status_1);
                dka_tools_pkg.put_log_message('v_msg_count (API : Ar_receipt_api_pub.apply) : ' ||
                                              v_msg_count);
                dka_tools_pkg.put_log_message('Message count  (API : Ar_receipt_api_pub.apply) : ' ||
                                              v_msg_count);
                dka_tools_pkg.put_log_message('l_msg_data (API : Ar_receipt_api_pub.apply) : ' ||
                                              v_msg_data);
              
                COMMIT;
        
        -- Gestion du code retour
          IF (v_return_status_1 != 'S') THEN
          dka_tools_pkg.put_log_message( 'Erreur Création lettrage à  0 sur : ' || iapi.num_avoir);
          IF v_msg_count = 1 then
            dka_tools_pkg.put_log_message('Message de retour (API : ar_receipt_api_pub.Create_cash) : '||v_msg_data);
          ELSE
            for i in 1 .. v_msg_count LOOP
            fnd_msg_pub.get(p_msg_index     => i,
                    p_encoded       => 'F',
                    p_data          => l_message_api,
                    p_msg_index_out => l_index);
            
            END loop;
          dka_tools_pkg.put_log_message('Message de retour (API : ar_receipt_api_pub.Create_cash) : '||l_message_api);
          end if;
          
          BEGIN
            UPDATE DKA_ARREMB_REPORTING
            SET apply_flag = 'N'
            WHERE num_avoir = iapi.num_avoir
            AND uo = iapi.uo;
            
            EXCEPTION
            WHEN OTHERS THEN
            dka_tools_pkg.put_log_message('ERROR UPDATE activity_flag : ' || iapi.num_avoir );
            dka_tools_pkg.put_log_message('Erreur  : ' || SQLERRM);
            END;
          
        ELSIF (v_return_status_1 = 'S') THEN
          dka_tools_pkg.put_log_message( 'Création lettrage avec succès pour : ' || iapi.num_avoir);
          
          
          BEGIN
            UPDATE DKA_ARREMB_REPORTING
            SET apply_flag = 'Y'
            WHERE num_avoir = iapi.num_avoir
            AND uo = iapi.uo;
                        
            EXCEPTION
            WHEN OTHERS THEN
            dka_tools_pkg.put_log_message('ERROR UPDATE activity_flag : ' || iapi.num_avoir );
            dka_tools_pkg.put_log_message('Erreur  : ' || SQLERRM);
          END;
        
        END IF;
        
        COMMIT;
              
                dka_tools_pkg.put_log_message('Fin ++++++++++ API : Ar_receipt_api_pub.apply ++++++++++ ');
        
        
              END;
            end if;
          
          END;
        
        END IF;
      ELSE
        dka_tools_pkg.put_log_message('                                                     ');
        dka_tools_pkg.put_log_message('++++++++++ Alimenter l''attribute9 du cuf ++++++++++ ');
        dka_tools_pkg.put_log_message('Numero de l''avoir : ' ||
                                      iapi.num_avoir);
        UPDATE ra_customer_trx_all
           SET attribute9 = iapi.motif_rejet
         WHERE customer_trx_id = vv_customer_trx_id;
      
        COMMIT;
      END IF;
    
    END LOOP;
  
  
  FOR rec_remb in cur_remb
    
  LOOP
  
  dka_tools_pkg.put_log_message ('Soumission du traitement de remboursement pour l''UO : ' || rec_remb.uo);
  
    vn_request_id := fnd_request.submit_request(application => 'DKA',
                                                program     => 'DKA_SLAUNCHER',
                                                description => NULL,
                                                start_time  => NULL,
                                                sub_request => FALSE,
                                                Argument1   => 'DKA_SARREMB_API_JOB.sh',
                                                Argument2   => rec_remb.org_id,
                                                Argument3   => rec_remb.uo);
    COMMIT;

    IF vn_request_id = 0 THEN
       dka_tools_pkg.put_log_message ('Erreur Soumission du traitement de remboursement pour l''UO : ' || rec_remb.uo);
    END IF;
  
    dka_tools_pkg.put_log_message ('Traitement remboursement lancé avec numéro : ' || TO_CHAR (vn_request_id));
   
    IF NOT fnd_concurrent.wait_for_request (request_id      => vn_request_id
                                            ,INTERVAL        => 5 --interval Number of seconds to wait between checks
                                            ,max_wait        => 120 --Maximum number of seconds to wait for the request completion
                                             -- out arguments
                                            ,phase           => vv_rphase
                                            ,STATUS          => vv_rstatus
                                            ,dev_phase       => vv_dphase
                                            ,dev_status      => vv_dstatus
                                            ,message         => vv_message
                                            )


    THEN
       Dka_Tools_Pkg.put_log_message( '==> Warning : Le Programme de remboursement des règlements est terminé en avertissemernt ');
    ELSE
       IF vv_dstatus = 'WARNING' THEN
      Dka_Tools_Pkg.put_log_message( '==> Le Programme de remboursement des règlements est terminé en avertissemernt ');

       ELSIF vv_dstatus != 'NORMAL' THEN
      Dka_Tools_Pkg.put_log_message( '==> Le Programme de remboursement des règlements est terminé en erreur ');

       END IF;
    END IF;

  Dka_Tools_Pkg.put_log_message( '==> Le Programme de remboursement des règlements est terminé avec succès ');
  
  
  END LOOP;
  
  
  --ARA EDB295LOT1A
  BEGIN
  
  UPDATE dka_parameters
  SET VARCHAR2_VALUE = 'N'
  WHERE PROGRAM_CODE = 'DKA_SAPAUTORGT'
  AND PARAMETER_NAME = 'FLAG_CAMPAGNE';

  COMMIT;
  
  END;
  
  
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := 'aucune donnée traitée';
      dka_tools_pkg.put_log_message(pv_errbuf);
      --pn_retcode := 1;
  END solde_avoirs_creat_remb;

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : pp_errbuf         Sortie Message d'erreur
  --                    pp_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------

  PROCEDURE main(p_errbuf IN OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    vv_ligne      VARCHAR2(4000);
    vv_phase      VARCHAR2(100);
    vv_status     VARCHAR2(100);
    vv_dev_phase  VARCHAR2(100);
    vv_filename   VARCHAR2(80);
    vv_dev_status VARCHAR2(100);
    vv_message    VARCHAR2(100);
    pv_errbuf     VARCHAR2(2500);
    nom_program   VARCHAR2(2500);
    vvn_retcode   NUMBER;
    pn_retcode    NUMBER;
    v_errbuf      VARCHAR2(2500);
    v_retcode     NUMBER;
    erreur_programme EXCEPTION;
    erreur_mail      EXCEPTION;
    cv_line                VARCHAR2(100);
    v_current_program_unit VARCHAR2(30);
    vn_nb_line             NUMBER;
    vv_file_name           VARCHAR2(70);
    p_count_traite         NUMBER;
    p_count_remb           NUMBER := 0;
    p_count_rows           NUMBER := 0;
    p_iban_remb            NUMBER := 0;
    p_msg_data             VARCHAR2(4000);
    p_status               VARCHAR2(10);
    pn_status              VARCHAR2(10);
    pn_tab                 tab_numavoir;
    ppn_retcode            number := 0;
    p_avoir_non_valid      number;
  
  p_err_apply           NUMBER := 0;
  p_err_event           NUMBER := 0;
  
  
  BEGIN
    gn_request_id := fnd_global.conc_request_id;
    dka_tools_pkg.put_log_message('==>');
    pn_retcode := 0;
    solde_avoirs_creat_remb(p_errbuf,
                            ppn_retcode);
    
  --ARA
  SELECT COUNT(*)
  INTO p_count_remb
  FROM DKA_ARREMB_REPORTING
  WHERE reg_flag = 'Y';
  
  SELECT COUNT(*)
  INTO p_err_apply
  FROM DKA_ARREMB_REPORTING
  WHERE apply_flag = 'N';
  
  SELECT COUNT(*)
  INTO p_err_event
  FROM DKA_ARREMB_REPORTING
  WHERE activity_flag = 'E';
  
    SELECT COUNT(*)
      INTO p_iban_remb
      FROM dka_ar_remboursement_avoirs
     WHERE iban IS NULL
       AND REMB = 'Y';
  
    SELECT COUNT(*)
      INTO p_count_traite
      FROM dka_ar_remboursement_avoirs
     WHERE remb = 'Y';
  
    BEGIN
    
      SELECT 1
        INTO p_count_rows
        FROM dka_ar_remboursement_avoirs
       WHERE ROWNUM = 1
         and remb = 'Y';
    EXCEPTION
      WHEN no_data_found THEN
        pv_errbuf := 'aucune donnée traitée';
        dka_tools_pkg.put_log_message(pv_errbuf);
        pn_retcode := 1;
    END;
  
    SELECT COUNT(*)
      INTO p_avoir_non_valid
      FROM dka_ar_remboursement_avoirs
    --ARA
    WHERE nvl(remb, 'N') = 'N';
  
    dka_tools_pkg.put_log_message('Pn_Retcode : ' || pn_retcode);
    fnd_file.put_line(fnd_file.output,
                      'COMPTE-RENDU DU TRAITEMENT "DKA : Solde des avoirs et création des remboursements"');
    fnd_file.put_line(fnd_file.output, 'Traitement n° : ' || gn_request_id);
    fnd_file.put_line(fnd_file.output,
                      '                                                                           ');
    fnd_file.put_line(fnd_file.output,
                      '---------------------------------------------------------');
    fnd_file.put_line(fnd_file.output,
                      '                                                                           ');
    fnd_file.put_line(fnd_file.output,
                      'Nombre d''avoirs à rembourser : ' || p_count_traite);
    fnd_file.put_line(fnd_file.output,
                      '                                                                           ');
    fnd_file.put_line(fnd_file.output,
                      'Nombre de règlements créés dans AR : ' ||
                      p_count_remb);
  
    IF p_count_traite <> p_count_remb THEN
      pn_retcode := 1;
      fnd_file.put_line(fnd_file.output,
                        '---------------------------------------------------------');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        'Le nombre d''avoirs à rembourser est différent du nombre de règlements créés dans AR');
      ppn_retcode := pn_retcode;
    END IF;
  
    IF p_count_rows IS NULL and pn_retcode = 1 THEN
      pn_retcode := 1;
      fnd_file.put_line(fnd_file.output,
                        '---------------------------------------------------------');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output, 'Aucun avoir à rembourser');
      ppn_retcode := pn_retcode;
    END IF;
  
    IF p_iban_remb <> 0 THEN
      pn_retcode := 1;
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '---------------------------------------------------------');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        'Liste des avoirs à rembourser non sélectionnés pour IBAN manquant :');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '' || rpad('UO', 9) || rpad('-', 10) ||
                        rpad('NUM FACTURE', 30) || rpad('-', 10) ||
                        rpad('NOM CLIENT', 40) || rpad('-', 10) ||
                        rpad('SOLDE DU', 30) || rpad('-', 10) ||
                        rpad('MOTIF REJET', 150));
    
      FOR cur_rem_reg IN (SELECT *
                            FROM dka_ar_remboursement_avoirs
                           WHERE iban IS NULL
                             and REMB = 'Y') LOOP
        fnd_file.put_line(fnd_file.output,
                          '' || rpad(cur_rem_reg.uo, 9) || rpad('-', 10) ||
                          rpad(cur_rem_reg.num_avoir, 30) || rpad('-', 10) ||
                          rpad(cur_rem_reg.nom_client, 40) || rpad('-', 10) ||
                          rpad(cur_rem_reg.amt_avoir, 30) || rpad('-', 10) ||
                          rpad(cur_rem_reg.motif_rejet, 150));
      END LOOP;
      ppn_retcode := pn_retcode;
    END IF;
  
    IF p_err_apply > 0 THEN
      --pn_retcode := 1;
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '---------------------------------------------------------');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        'Liste des règlements dont le lettrage est incomplet  :');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '' || rpad('UO', 9) || rpad('-', 10) ||
                        rpad('NUM FACTURE', 30) || rpad('-', 10) ||
                        rpad('NOM CLIENT', 40) || rpad('-', 10) ||
                        rpad('SOLDE DU', 30));
    
      FOR i IN pn_tab.first .. pn_tab.last LOOP
        FOR cur_rem_reg IN (SELECT ra.*
                              FROM dka_ar_remboursement_avoirs ra, DKA_ARREMB_REPORTING rem
                             WHERE ra.num_avoir = rem.num_avoir
               AND ra.uo = rem.uo
               AND rem.apply_flag = 'N'
              ) LOOP
          fnd_file.put_line(fnd_file.output,
                            '' || rpad(cur_rem_reg.uo, 9) || rpad('-', 10) ||
                            rpad(cur_rem_reg.num_avoir, 30) ||
                            rpad('-', 10) ||
                            rpad(cur_rem_reg.nom_client, 40) ||
                            rpad('-', 10) ||
                            rpad(cur_rem_reg.amt_avoir, 30));
        END LOOP;
      END LOOP;
      ppn_retcode := 1;
    END IF;
  
    IF p_err_event > 0 THEN
      pn_retcode := 1;
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '---------------------------------------------------------');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        'Type d''évènement de Remboursement non paramétré ou inactif :');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '' || rpad('XXXX_YYY_Remboursement client', 30));
    
      FOR cur_rem_reg IN (
               SELECT arta.name
               FROM ar_receivables_trx_all      arta,
                 ra_customer_trx_all         rcta,
                 DKA_ARREMB_REPORTING dara
               WHERE 1 = 1
               AND rcta.org_id = arta.org_id
               AND arta.type = 'CM_REFUND'
               AND dara.activity_flag = 'E'
               AND rcta.trx_number = dara.num_avoir
             )
    LOOP
        fnd_file.put_line(fnd_file.output,
                          '' || rpad(cur_rem_reg.name, 30));
      END LOOP;
      ppn_retcode := pn_retcode;
    END IF;
  
    if p_avoir_non_valid <> 0 then
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '---------------------------------------------------------');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        'Liste des avoirs non validés pour remboursement :');
      fnd_file.put_line(fnd_file.output,
                        '                                                                           ');
      fnd_file.put_line(fnd_file.output,
                        '' || rpad('UO', 9) || rpad('-', 10) ||
                        rpad('NUM FACTURE', 30) || rpad('-', 10) ||
                        rpad('NOM CLIENT', 40) || rpad('-', 10) ||
                        rpad('SOLDE DU', 30) || rpad('-', 10) ||
                        rpad('MOTIF REJET', 150));
    
      FOR cur_rem_reg IN (SELECT *
                            FROM dka_ar_remboursement_avoirs
                           WHERE nvl(remb, 'N') = 'N') LOOP
        fnd_file.put_line(fnd_file.output,
                          '' || rpad(cur_rem_reg.uo, 9) || rpad('-', 10) ||
                          rpad(cur_rem_reg.num_avoir, 30) || rpad('-', 10) ||
                          rpad(cur_rem_reg.nom_client, 40) || rpad('-', 10) ||
                          rpad(cur_rem_reg.amt_avoir, 30) || rpad('-', 10) ||
                          rpad(cur_rem_reg.motif_rejet, 150));
      END LOOP;
    end if;
  
  
  
    IF ppn_retcode = 0 THEN
      dka_tools_pkg.put_log_message('Le traitement DKA_SARSOLDEAVOIR est terminé avec succès');
      p_retcode := 0;
    ELSIF ppn_retcode = 1 THEN
      ROLLBACK;
      p_errbuf  := 'aucune donnée traitée';
      p_retcode := 1;
    END IF;
  
  EXCEPTION
  WHEN OTHERS THEN
  dka_tools_pkg.put_log_message('Le traitement DKA_SARSOLDEAVOIR est terminé en erreur : ' || SQLERRM);
  
  END main;

END DKA_SARSOLDEAVOIR_PKG;

/
SHOW ERRORS;
EXIT;