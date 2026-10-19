CREATE OR REPLACE PACKAGE BODY APPS.DKA_SARLETTZERO_PKG IS
  --------------------------------------------------------------------------------
  -- $Id: DKA_SARLETTZERO.pkb
  -- Capgemini
  -- Projet           :
  -- Nom              : DKA_SARLETTZERO_PKG.pkb (DKA : campagne de lettrage A  zero)
  -- Description      : Corps du package DKA_SARLETTZERO_PKG
  -- Auteur           : Zakaria BEN DAOUD
  -- Date de creation : 05/12/2024
  -- Commentaires     :
  --------------------------------------------------------------------------------

  g_package       VARCHAR2(30) := 'DKA_SARLETTZERO_PKG';
  g_sqlerrm       VARCHAR2(500) := NULL;
  g_retproc       NUMBER := 0;
  cv_error_message   CONSTANT VARCHAR2(100) := ' (voir le fichier journal pour ' || 'plus d''informations)';
  g_request_id    NUMBER := fnd_global.CONC_REQUEST_ID;
  vn_user_id      NUMBER := fnd_global.user_id;
  l_fichier_avoir utl_file.file_type;
  l_line_count    NUMBER;
  g_avoir_file    VARCHAR2(240);
  g_date          DATE := SYSDATE;

  g_cdir       VARCHAR2(30) := 'DKA_OUT_DIR';
  g_separateur VARCHAR2(1) := ';'; 


  gv_conn VARCHAR2(30);

  v_test varchar2(240);

  -- Message d'information.
  g_step    VARCHAR2(500);
  rec_param dka_parameters%ROWTYPE;
  -- Variable contenant l'entete et le corps du mail.
  gv_objet VARCHAR2(4000);
  gv_corps VARCHAR2(4000);

  K_DIRECTORY CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';

  TYPE liste_destinataires IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  erreur_programme EXCEPTION;
  erreur_mail      EXCEPTION;

  pv_errbuf VARCHAR2(2500);
  pn_retcode NUMBER;
  v_errbuf   VARCHAR2(2500);

  

  vv_adresses VARCHAR2(32000);

  vt_adr_to liste_destinataires;
  vn_cpt    NUMBER;

  PROCEDURE log_msg(p_message IN VARCHAR2) IS
    l_message VARCHAR2(1000);
  BEGIN
    l_message := substr(p_message, 1, 1000);
    IF (l_message IS NULL) THEN
      l_message := to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS');
    END IF;
  
    fnd_file.put_line(fnd_file.log, l_message);
  END log_msg;

  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Zakaria BEN DAOUD
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    L_procedure VARCHAR2(30) := 'writeout';
    v_etape     VARCHAR2(100);
  BEGIN
  
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);
  
  EXCEPTION
    WHEN OTHERS THEN
      G_retproc := 1;
      G_sqlerrm := SUBSTR(SQLERRM, 1, 200);
      Fnd_File.put_line(Fnd_File.LOG,
                        '-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || G_package);
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || L_procedure);
      Fnd_File.put_line(Fnd_File.LOG, 'Exception : OTHERS');
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || v_etape);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || G_sqlerrm);
  END writeout;

  /*============================================================================*/
  /* Fonction          : sortie_traitement                                      */
  /* Description       : affiche les statistiques dans la sortie de traitement  */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE sortie_traitement IS
  
  BEGIN
    fnd_file.put_line(fnd_file.output,
                      '                                                                           ');
  
    fnd_file.put_line(fnd_file.output,
                      '                                                                           ');
    fnd_file.put_line(fnd_file.output,
                      'Liste des factures avec somme differente de zero :');
    fnd_file.put_line(fnd_file.output,
                      '                                                                           ');
  
  END sortie_traitement;
  /*============================================================================*/
  /* Fonction          : entete_de_sortie                                      */
  /* Description       : entete de la sortie                 */
  /*                                                                            */
  /* Parametres entree : nom de fichier                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE entete_de_sortie IS
  
    
   
  
  BEGIN
  
    writeout('+-------------------------------------------------------------------------+');
    writeout('TRAITEMENT < DKA : campagne de lettrage a zero  >');
    writeout('Traitement n° : ' || g_request_id);
    writeout('Programme lance le : ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('                                                                           ');
  END entete_de_sortie;
  /*============================================================================*/
  /* Fonction          : fin_de_sortie                                      */
  /* Description       : fin de la sortie                 */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE fin_de_sortie IS
  
  BEGIN
    writeout('');
    writeout('');
  
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('Programme termine le : ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    writeout('                                                                           ');
    writeout('+-------------------------------------------------------------------------+');
  END fin_de_sortie;

  /*============================================================================*/
  /* Procedure         : reglement_lettrage                                      */
  /* Description       :                */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE reglement_lettrage(pv_errbuf  IN OUT VARCHAR2,
                               pn_retcode OUT NUMBER) IS
  
    l_return_status     VARCHAR2(1);
    l_msg_count         NUMBER;
    l_msg_data          VARCHAR2(240);
    l_cash_receipt_id   NUMBER;
    p_count             number := 0;
    v_receipt_number    VARCHAR2(240);
    v_account_id    	Number;
    vn_organization_id  number;
    V_RECEIPT_METHOD_ID number;
    V_NAME              varchar2(50);
    v_param1            varchar2(50);
    v_param2            number;
    v_param3            varchar2(50);
    vn_user_id          VARCHAR2(240);
    vn_appl_id          NUMBER;
    vn_resp_id          NUMBER;
    vn_org_id           NUMBER;
    seq_number          number;
    Vn_count            NUMBER := 0;
 
    cursor C1 is
       SELECT 
	   hca.cust_account_id ,
	   hca.ACCOUNT_NUMBER,
             ps.ATTRIBUTE6,
             hou.name,
             substr(hou.name, 1, 3) UO,
             hp.PARTY_NAME,
             HOU.organization_id,
              ps.customer_site_use_id,
             hcsua.LOCATION,
       ps.customer_id,
             SUM(ps.amount_due_remaining) as summ
        from hz_cust_accounts         hca,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all ps,
             hr_operating_units       hou,
             HZ_PARTIES               hp,
             hz_cust_site_uses_all    hcsua
      -----------------------------
       where 1 = 1
         AND ps.customer_id = hca.cust_account_id
         AND hca.cust_account_id = rcta.BILL_TO_CUSTOMER_ID
         AND hp.PARTY_ID = hca.PARTY_ID
         AND rcta.ORG_ID = hou.organization_id
         and ps.ORG_ID = hou.organization_id
         AND ps.CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
         AND hcsua.site_use_id = rcta.bill_to_site_use_id
         AND PS.CLASS in ('CM', 'INV')
		 AND ps.status = 'OP'
         AND PS.ATTRIBUTE6 = 'OUI'
         AND PS.ATTRIBUTE7 IS NOT NULL
       group BY 
	   hca.cust_account_id ,
	   hca.ACCOUNT_NUMBER,
                hou.name,
                HOU.organization_id,
                hou.name,
                hp.PARTY_NAME,
				ps.customer_id,
				ps.customer_site_use_id,
                hcsua.LOCATION,
                ps.ATTRIBUTE6;

    -- having SUM(ps.amount_due_remaining) = 0;
  
    cursor C2(v_account_id   in varchar2,
              vn_organization_id in number,
              v_adresse_anael    in varchar2) is
    
      SELECT ps.trx_number,
             hca.ACCOUNT_NUMBER,
             hca.CUST_ACCOUNT_ID,
             rcta.CUSTOMER_TRX_ID,
             hou.name,
             substr(name, 1, 3) UO,
             HOU.organization_id,
             PS.ATTRIBUTE6,
             ps.GL_DATE,
             ps.due_date,
             ps.INVOICE_CURRENCY_CODE,
             ps.customer_id,
             ps.customer_site_use_id,
             hcasa.attribute3
        from hz_cust_accounts         hca,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all ps,
             hr_operating_units       hou,
             HZ_PARTIES               hp,
             hz_party_sites           hps,
             hz_locations             hl,
             hz_cust_site_uses_all    hcsua,
             hz_cust_acct_sites_all   hcasa
      -----------------------------
       where 1 = 1
         AND ps.customer_id = hca.cust_account_id
         AND hca.cust_account_id = rcta.BILL_TO_CUSTOMER_ID
         AND hp.PARTY_ID = hca.PARTY_ID
         AND hp.PARTY_ID = hps.PARTY_ID
         AND hcasa.party_site_id = hps.party_site_id
         AND hcasa.cust_account_id = hca.cust_account_id
         AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
         AND hou.organization_id = hcsua.org_id
         and hcasa.ORG_ID = hcsua.org_id
         and hps.location_id = hl.location_id
         AND rcta.ORG_ID = hou.organization_id
         and ps.ORG_ID = hou.organization_id
         AND ps.CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
         AND hcsua.site_use_id = rcta.bill_to_site_use_id
         AND hca.cust_account_id  = v_account_id
         --AND hcasa.attribute3 = v_adresse_anael
		 AND hcsua.LOCATION = v_adresse_anael
         AND hou.organization_id = vn_organization_id
         AND ps.status = 'OP'
            -- AND ps.due_date < sysdate
         AND PS.CLASS in ('CM', 'INV')
         AND PS.ATTRIBUTE6 = 'OUI'
         AND PS.ATTRIBUTE7 IS NOT NULL;
  
  begin
  
    For cur_reg in C1 loop
    
      -- 1) Set the applications context
      SELECT DISTINCT frv.application_id,
                      frv.responsibility_id,
                      fpov.profile_option_value
        INTO vn_appl_id, vn_resp_id, vn_org_id
        FROM apps.fnd_profile_options_vl    fpo,
             apps.fnd_responsibility_vl     frv,
             apps.fnd_profile_option_values fpov,
             apps.hr_organization_units     hou
       WHERE hou.name = cur_reg.name
         AND fpov.profile_option_value = to_char(hou.organization_id)
         AND fpo.profile_option_id = fpov.profile_option_id
         AND frv.responsibility_id = fpov.level_value
         AND frv.responsibility_name = cur_reg.name || '_AR_ADMINISTRATEUR'
       ORDER BY frv.responsibility_name;
     -- dka_tools_pkg.put_log_message('vn_appl_id : ' || vn_appl_id);
    --  dka_tools_pkg.put_log_message('vn_resp_id : ' || vn_resp_id);
      dka_tools_pkg.put_log_message('vn_org_id : ' || vn_org_id);
      mo_global.init('AR');
      mo_global.set_policy_context('S', cur_reg.organization_id);
      fnd_global.apps_initialize(vn_user_id, vn_resp_id, vn_appl_id, 0);
    
      v_param1 := cur_reg.cust_account_id;
      v_param2 := cur_reg.organization_id;
      v_param3 := cur_reg.LOCATION;
    
      begin
      
      
        if (cur_reg.summ = 0) then
        
          v_test := 'select DKA_SARLETTZERO_' || cur_reg.UO ||
                    '_SEQ.NEXTVAL from dual';
        
          execute immediate v_test
            into seq_number;
          --select  v_test.NEXTVAL into seq_number from dual;
          DKA_TOOLS_PKG.put_log_message('seq_number : ' || seq_number);
        
          v_receipt_number := cur_reg.UO || '_LETTRAGE_ZERO_' || seq_number;
          DKA_TOOLS_PKG.put_log_message('receipt_number : ' ||
                                        v_receipt_number);
        
          select RECEIPT_METHOD_ID, NAME
            into V_RECEIPT_METHOD_ID, V_NAME
            from AR_RECEIPT_METHODS
           where NAME = substr(cur_reg.name, 4, 5) || '_' ||
                 substr(cur_reg.name, 1, 3) || '_VI_585000';
          DKA_TOOLS_PKG.put_log_message('----------------- NEW REG ---------------- ');
        
          DKA_TOOLS_PKG.put_log_message('Message ' || V_RECEIPT_METHOD_ID ||
                                        ' --- ' || V_NAME);
          -- 2) Call the API
          AR_RECEIPT_API_PUB.CREATE_CASH(p_api_version       => 1.0,
                                         p_init_msg_list     => FND_API.G_TRUE,
                                         p_commit            => FND_API.G_TRUE,
                                         p_validation_level  => FND_API.G_VALID_LEVEL_FULL,
                                         x_return_status     => l_return_status,
                                         x_msg_count         => l_msg_count,
                                         x_msg_data          => l_msg_data,
                                         p_currency_code     => 'EUR',
                                         p_amount            => 0,
                                         p_receipt_number    => v_receipt_number,
										 
                                         p_receipt_date      => sysdate, --reg_api.due_date,
                                         p_gl_date           => sysdate,
										 p_customer_id		 => cur_reg.customer_id , --new
                                        -- p_customer_number   => cur_reg.account_number,
										 p_default_site_use  =>	'N'	,--new
										 p_location			 => cur_reg.LOCATION, --new
										 p_customer_site_use_id => 	cur_reg.customer_site_use_id, --new
                                         p_receipt_method_id => V_RECEIPT_METHOD_ID,
										
                                         p_org_id            => cur_reg.organization_id,
                                         p_cr_id             => l_cash_receipt_id);
         -- commit;
          -- 3) Review the API output
          DKA_TOOLS_PKG.put_log_message('Status ' || l_return_status);
          DKA_TOOLS_PKG.put_log_message('Cash Receipt id ' ||
                                        l_cash_receipt_id);
          DKA_TOOLS_PKG.put_log_message('Message count ' || l_msg_count);
        
          if l_msg_count = 1 Then
            DKA_TOOLS_PKG.put_log_message('l_msg_data ' || l_msg_data);
          elsif l_msg_count > 1 Then
            loop
              p_count    := p_count + 1;
              l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,
                                            FND_API.G_FALSE);
              if l_msg_data is NULL then
                exit;
              end if;
              DKA_TOOLS_PKG.put_log_message('Message ' || p_count || '. ' ||
                                            l_msg_data);
            end loop;
          end if;
        
          DKA_TOOLS_PKG.put_log_message('CASH RECEIPT ID :  ' ||
                                        l_cash_receipt_id);
          -- end loop;
        
          if l_return_status = 'S' then
            For reg_api in C2(v_param1, v_param2, v_param3) loop
              DKA_TOOLS_PKG.put_log_message(' 2) Call the API APPLY--------- ');
              -- 2) Call the API ---------------------------------------------------------------------------------------
              AR_RECEIPT_API_PUB.APPLY(p_api_version          => 1.0,
                                       p_init_msg_list        => FND_API.G_TRUE,
                                       p_commit               => FND_API.G_TRUE,
                                       p_validation_level     => FND_API.G_VALID_LEVEL_FULL,
                                       p_cash_receipt_id      => l_cash_receipt_id,
                                       p_customer_trx_id      => reg_api.CUSTOMER_TRX_ID,
                                      -- p_show_closed_invoices => 'Y', -- facture ferme
                                       p_org_id               => reg_api.organization_id,
                                       x_return_status        => l_return_status,
                                       x_msg_count            => l_msg_count,
                                       x_msg_data             => l_msg_data);
           --   commit;
              -- 3) Review the API output
              DKA_TOOLS_PKG.put_log_message('Status ' || l_return_status);
        
        
              DKA_TOOLS_PKG.put_log_message('Message count ' ||
                                            l_msg_count);
            
              if l_msg_count = 1 Then
                DKA_TOOLS_PKG.put_log_message('l_msg_data ' || l_msg_data);
              elsif l_msg_count > 1 Then
                loop
                  p_count    := p_count + 1;
                  l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,
                                                FND_API.G_FALSE);
                  if l_msg_data is NULL Then
                    exit;
                  end if;
                  DKA_TOOLS_PKG.put_log_message('Message ' || p_count || '. ' ||
                                                l_msg_data);
       
                end loop;
              end if;
               if l_return_status != 'S' then 
               raise erreur_programme;
                end if;
            end loop;
          end if;
          ------------------------------------------------------------------------------------------
        end if ;
        if (cur_reg.summ != 0) then
          Vn_count := Vn_count + 1;
        
          fnd_file.put_line(fnd_file.output,
                            'Avertissement : La somme des mouvements sur le lieu ' ||
                            cur_reg.LOCATION || ' de la region ' ||
                            cur_reg.name || ' du client ' ||
                            cur_reg.ACCOUNT_NUMBER || ' ( ' ||
                            cur_reg.PARTY_NAME ||
                            ') n''est pas égale à Zéro  - Montant  ' ||
                            cur_reg.summ);
        
        END if;
        
  EXCEPTION  
    WHEN erreur_programme THEN

      fnd_file.put_line(fnd_file.log, 'API APPLY ');
      fnd_file.put_line(fnd_file.log,  ' Voir Message ');   
 
END;
    
    end loop;
  
    if Vn_count != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'il y a des sommes differentes de zero ';
    end if;
  
  
  EXCEPTION  
     
  WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('ERREUR [exception dans reglement_lettrage() ' ||
                                    'non catchee]');
  dka_Tools_Pkg.put_log_message('Erreur ' || SQLERRM );
    
      pn_retcode := 2;
      pv_errbuf  := 'Erreur ' || SQLERRM || cv_error_message;
      dka_Tools_Pkg.put_log_message('# ' || SQLERRM);
  
  END;

  --END reglement_lettrage;

  /*============================================================================*/
  -- Procedure         : extraction_reglement
  -- Description       : extraction des avoirs non solde et remborse
  -- Parametres entree : p_region IN VARCHAR2 : Region
  --
  -- Parametres sortie : AUCUN
  -- Auteur            : ZAKARIA BEN DAOUD
  -- Date              : 08/08/2024
  -- Remarques         :
  /*============================================================================*/

  PROCEDURE extraction_reglement(pv_errbuf   IN OUT VARCHAR2,
                                 pn_retcode  IN OUT NUMBER,
                                 p_region    IN VARCHAR2,
                                 vv_filename OUT VARCHAR2) IS
  
  
    l_avoirs_lignes VARCHAR2(2000);
    vv_step         VARCHAR2(500);
   
    my_exeception EXCEPTION;
    l_message_entete VARCHAR2(2000);
  
    CURSOR rec_reg(p_region IN VARCHAR2) IS
    -----------------------------------
    
      select hou.name,
             hca.ACCOUNT_NUMBER,
             hp.PARTY_NAME,
             ps.TRX_NUMBER,
             hcsua.LOCATION adresse_anael,
             PS.INVOICE_CURRENCY_CODE DEVISE,
             ARPT_SQL_FUNC_UTIL.get_lookup_meaning('INV/CM', PS.CLASS) mod_reg,
             PS.ATTRIBUTE6,
             PS.ATTRIBUTE7 Matricule,
             (select distinct DESCRIPTION
                from fnd_user
               where user_name = PS.ATTRIBUTE7) libelle,
             SUM(ps.amount_due_remaining) as summ
      
        from hz_cust_accounts         hca,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all ps,
             hr_operating_units       hou,
             HZ_PARTIES               hp,
             hz_cust_site_uses_all    hcsua
      -----------------------------
       where 1 = 1
         AND ps.customer_id = hca.cust_account_id
         AND hca.cust_account_id = rcta.BILL_TO_CUSTOMER_ID
         AND hp.PARTY_ID = hca.PARTY_ID
         AND rcta.ORG_ID = hou.organization_id
         and ps.ORG_ID = hou.organization_id
         AND ps.CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
         AND hcsua.site_use_id = rcta.bill_to_site_use_id
         AND PS.CLASS in ('CM', 'INV')
         AND PS.ATTRIBUTE6 = 'OUI'
         AND PS.ATTRIBUTE7 IS NOT NULL
         And substr(hou.name, 1, 3) = p_region
       group BY hp.PARTY_NAME,
                hou.name,
                PS.CLASS,
                hca.ACCOUNT_NUMBER,
                hcsua.LOCATION,
                PS.ATTRIBUTE7,
                PS.INVOICE_CURRENCY_CODE,
                PS.ATTRIBUTE6,
                ps.TRX_NUMBER
      having SUM(ps.amount_due_remaining) != 0
	  Order by hou.name ,hca.ACCOUNT_NUMBER, hcsua.LOCATION;
  
  BEGIN
    dka_tools_pkg.put_debug_message('==> Debut d''extraction');
  
   
  
  
    IF utl_file.is_open(l_fichier_avoir) THEN
      utl_file.fclose(l_fichier_avoir);
    END IF;
    
    l_line_count := 0;
    g_avoir_file := p_region || '_lettrage_a_zero_' || g_request_id || '_' ||
                    to_char(g_date, 'YYYYMMDDHH24MISS') || '.csv';
  
    vv_filename := g_avoir_file;
    vv_step     := '003 : Ouverture du fichier : ' || vv_filename;
    dka_tools_pkg.put_log_message(vv_step);
    l_fichier_avoir := utl_file.fopen(g_cdir, vv_filename, 'w', 32767);
    l_avoirs_lignes := 'UO' || g_separateur ||
						'CODE_CLIENT' || g_separateur ||
						'CLIENT' || g_separateur ||
                       'ADRESSE_ANAEL' || g_separateur ||
                      
					   'TYPE DE MOUVEMENT' || g_separateur ||
					   'MOUVEMENT' || g_separateur ||
					   'MONTANT' || g_separateur ||
                       'DEVISE' || g_separateur ||
					   
					   'MATRICULE' || g_separateur ||
                       'LIBELLE';
  
    utl_file.put_line(l_fichier_avoir, l_avoirs_lignes);
  
    dka_tools_pkg.put_log_message(vv_step);
    FOR cur_rec IN rec_reg(p_region) LOOP
    
      --dka_tools_pkg.put_log_message('TEST ok ');
    
      l_message_entete := cur_rec.name || g_separateur ||
						cur_rec.ACCOUNT_NUMBER || g_separateur ||
                          cur_rec.PARTY_NAME || g_separateur ||
                          cur_rec.ADRESSE_ANAEL || g_separateur ||
                          
						  cur_rec.mod_reg || g_separateur ||
                          cur_rec.TRX_NUMBER || g_separateur ||
                          cur_rec.summ || g_separateur ||
						  cur_rec.DEVISE || g_separateur ||
						  
                          cur_rec.matricule || g_separateur ||
                          cur_rec.libelle;
    
      l_line_count := l_line_count + 1;
      dka_tools_pkg.put_log_message(vv_step);
      utl_file.put_line(l_fichier_avoir, l_message_entete);
      ------------------------------------------------
    
    END LOOP;
    dka_tools_pkg.put_log_message(' count line : ' || l_line_count);
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_fichier_avoir);
  
   EXCEPTION WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('ERREUR [exception dans extraction_reglement() ' ||
                                    'non catchee]');

      pn_retcode := 2;
      pv_errbuf  := 'Erreur ' || SQLERRM || cv_error_message;
      dka_Tools_Pkg.put_log_message('# ' || SQLERRM);
  
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : SEND_MSG
  --  Description   : Envoi du message avec fichier.
  --
  --  PARAMETRES    :
  --  Pv_Errbuf      IN OUT       Message d'avertissement
  --  Pn_Retcode  IN OUT     Code erreur
  --  P_REGION     IN Region
  --------------------------------------------------------------------------------------
  PROCEDURE SEND_MSG(p_tab_to  liste_destinataires,
                     p_from    IN VARCHAR2,
                     p_subject IN VARCHAR2,
                     -- P_period           IN VARCHAR2,
                     P_region      IN VARCHAR2,
                     p_text_msg    IN VARCHAR2 DEFAULT NULL,
                     p_attach_name IN VARCHAR2 DEFAULT NULL,
                     p_attach_mime IN VARCHAR2 DEFAULT NULL,
                     p_smtp_host   IN VARCHAR2,
                     p_smtp_port   IN NUMBER DEFAULT 25) AS
    l_mail_conn UTL_SMTP.connection;
    l_boundary  VARCHAR2(50) := '----=*#abc1234321cba#*=';
  
    fil             BFILE;
    v_length        integer := 0;
    k               integer := 1;
    v_raw           raw(57);
    v_buffer_size   integer := 57;
    
    p_to            VARCHAR2(30000);
  
  BEGIN
  
    l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
    UTL_SMTP.helo(l_mail_conn, p_smtp_host);
    UTL_SMTP.mail(l_mail_conn, p_from);
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'YYYY/DD/MM HH24:MI:SS') ||
                      '     > Mail : Chargement des destinataires directs ');
  
    -- Ajout des destinataires directs
    FOR i in p_tab_to.FIRST .. p_tab_to.LAST LOOP
      UTL_SMTP.rcpt(l_mail_conn, p_tab_to(i));
      IF (i = 1) THEN
        p_to := p_tab_to(i);
      ELSE
        p_to := p_to || ';' || p_tab_to(i);
      END IF;
    
    END LOOP;
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Chargement des destinataires en copie');
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Alimentation du mail');
  
    UTL_SMTP.open_data(l_mail_conn);
  
    UTL_SMTP.write_data(l_mail_conn,
                        'Date: ' ||
                        TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') ||
                        UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
  
    UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Subject: ' || REPLACE(utl_encode.MIMEHEADER_ENCODE(p_subject,
                                                                            'utf8'),
                                               CHR(13) || CHR(10),
                                               '') || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Reply-To: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn,
                        'Content-Type: multipart/mixed; boundary="' ||
                        l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
  
    IF p_text_msg IS NOT NULL THEN
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: text/plain; charset="iso-8859-1"' ||
                          UTL_TCP.crlf || UTL_TCP.crlf);
    
      utl_smtp.write_raw_data(l_mail_conn, utl_raw.cast_to_raw(p_text_msg));
      UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
    END IF;
  
    fnd_file.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                      '     > Mail : Alimentation de la piece jointe');
  
    IF p_attach_name IS NOT NULL THEN
      --IF p_attach_name = 1 THEN -- test
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Type: ' || p_attach_mime || '; name="' ||
                          P_REGION || '_lettrage_a_zero_' || g_request_id||'_'||
                          TO_CHAR(g_date, 'YYYYDDMMHH24MISS') || '.csv' || '"' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Transfer-Encoding: base64' ||
                          UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn,
                          'Content-Disposition: attachment; filename="' ||
                          P_REGION || '_lettrage_a_zero_' || g_request_id ||'_'||
                          TO_CHAR(g_date, 'YYYYDDMMHH24MISS') || '.csv' || '"' ||
                          UTL_TCP.crlf || UTL_TCP.crlf);
    
      BEGIN
        fil := bfilename(p_attach_mime, p_attach_name);
        dbms_lob.fileopen(fil, dbms_lob.file_readonly);
      EXCEPTION
        WHEN OTHERS THEN
          null;
      END;
      v_length := dbms_lob.getlength(fil);
    
      while k < v_length loop
        dbms_lob.read(fil, v_buffer_size, k, v_raw);
        UTL_SMTP.write_data(l_mail_conn,
                            UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(v_raw)));
        utl_smtp.write_data(l_mail_conn, utl_tcp.crlf);
        k := k + v_buffer_size;
      end loop;
    
      dbms_lob.fileclose(fil);
    
    END IF;
  
    UTL_SMTP.write_data(l_mail_conn,
                        '--' || l_boundary || '--' || UTL_TCP.crlf);
    UTL_SMTP.close_data(l_mail_conn);
  
    UTL_SMTP.quit(l_mail_conn);
  
     EXCEPTION WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('ERREUR [exception dans SEND_MSG() ' ||
                                    'non catchee]');

      pn_retcode := 2;
      pv_errbuf  := 'Erreur ' || SQLERRM || cv_error_message;
      dka_Tools_Pkg.put_log_message('# ' || SQLERRM);
  END SEND_MSG;

  /*============================================================================*/
  -- Procedure         : ENVOI_MAIL
  -- Description       : envoi du mail
  -- Parametres entree : p_region IN VARCHAR2 : Region
  -- vv_filename in VARCHAR2 : nom de fichier
  -- Parametres sortie : AUCUN
  -- Auteur            : ZAKARIA BEN DAOUD
  -- Date              : 08/08/2024
  -- Remarques         :
  /*============================================================================*/

  PROCEDURE ENVOI_MAIL(pv_errbuf   IN OUT VARCHAR2,
                       pn_retcode  IN OUT NUMBER,
                       p_region    IN VARCHAR2,
                       vv_filename in VARCHAR2) IS

  
    CURSOR c_liste_destinataire(p_region IN VARCHAR2) IS
      WITH CTE AS
       (SELECT ffv.attribute1 adresse
          FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
         WHERE ffvs.flex_value_set_name = 'DKA_SARLETT_ENVOI_MAIL'
           AND ffv.flex_value_set_id = ffvs.flex_value_set_id
           AND ffv.flex_value = nvl(p_region, ffv.flex_value)
           AND ffv.enabled_flag = 'Y'
           AND sysdate BETWEEN nvl(ffv.start_date_active, sysdate) AND
               nvl(ffv.end_date_active, sysdate)
        
        )
      SELECT TRIM(REGEXP_SUBSTR(adresse, '[^;]+', 1, LEVEL)) adresse
        FROM CTE
      CONNECT BY LEVEL < LENGTH(REGEXP_REPLACE(adresse, '[^;]+')) + 1;
  
  BEGIN
    dka_tools_pkg.put_log_message('le mail a ete envoye');
  
    log_msg('Nom Fichier : ' || vv_filename);
  
    -- dka_tools_pkg.get_parameter('SARREFAC', 'EXPEDITEUR', rec_param, pv_errbuf, pn_retcode);
    dka_tools_pkg.get_parameter('SPOCDE_CITY',
                                'SMTP_CONNECTION',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
  
    gv_conn := rec_param.varchar2_value;
    IF gv_conn IS NULL THEN
      fnd_file.put_line(fnd_file.log,
                        chr(10) ||
                        'ECHEC : erreur concernant la connexion SMTP.');
      RAISE erreur_mail;
    END IF;
  
    g_step := 'ENVOI_AVEC_FICHIER 000 : DEBUT';
    log_msg(g_step);
    g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
    log_msg(g_step);
    gv_objet := 'Compte-rendu de la campagne de lettrage à zéro du ' ||
                to_char(g_date, 'DD' || '/' || 'MM' || '/' || 'YYYY');
  
    IF gv_objet IS NULL THEN
      fnd_file.put_line(fnd_file.log,
                        chr(10) || 'ECHEC : Pas d''objet du mail.');
      RAISE erreur_mail;
    END IF;
  
    g_step := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
    log_msg(g_step);
    gv_corps := 'Bonjour,' || chr(13) || chr(10) || chr(10) ||
                'Suite à la dernière Campagne de lettrage à zéro, vous trouverez en pièce jointe l’état des mouvements dont le total n''est pas égal à zéro pour la région ' ||
                p_region || ' .' || chr(13) || chr(10) || chr(10) ||
                'Cordialement,' || chr(13) || chr(10);
  
    IF gv_corps IS NULL THEN
      fnd_file.put_line(fnd_file.log,
                        chr(10) || 'ECHEC : Pas de corps du mail.');
      RAISE erreur_mail;
    END IF;
  
    vn_cpt := 0;
    vt_adr_to.delete;
    vt_adr_to(1) := 'INIT';
    vv_adresses := NULL;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(sysdate, 'DD/MM/YYYY') || ' - ' ||
                      'Recuperation des destinataires directs');
    -- Alimentation du tableau des destinataires directs
  
    FOR cur_adr_to IN c_liste_destinataire(p_region) LOOP
      vn_cpt := vn_cpt + 1;
      vt_adr_to(vn_cpt) := cur_adr_to.adresse;
      vv_adresses := vv_adresses || cur_adr_to.adresse || ';';
    
    END LOOP;
    fnd_file.put_line(fnd_file.log,
                      chr(10) || 'adresse1 : ' || vv_adresses);
  
    IF vv_adresses IS NULL THEN
      fnd_file.put_line(fnd_file.log,
                        chr(10) ||
                        'Aucune valeur n''est active dans le jeu de valeurs DKA_SARLETT_ENVOI_MAIL');
      RAISE erreur_mail;
    ELSE
    
      SEND_MSG(p_tab_to => vt_adr_to,
               p_from    => 'no-reply@dalkia.fr',
               p_subject => gv_objet,
               P_region      => P_region,
               p_text_msg    => gv_corps,
               p_attach_name => vv_filename,
               p_attach_mime => K_DIRECTORY,
               p_smtp_host   => gv_conn);
    
      log_msg('adresses : ' || vv_adresses);
    
    END IF;
  
  EXCEPTION
    WHEN erreur_mail THEN
      pn_retcode := 1;
      fnd_file.put_line(fnd_file.output,
                        'ECHEC : Le mail n''a pas pu etre envoye.');
      fnd_file.put_line(fnd_file.output,
                        chr(10) ||
                        'Voir le journal du traitement pour avoir plus de detail sur l''anomalie rencontree.');
    
    WHEN erreur_programme THEN
      pn_retcode := 2;
      pv_errbuf  := v_errbuf;
      fnd_file.put_line(fnd_file.log, pv_errbuf);
      fnd_file.put_line(fnd_file.log, chr(10) || pv_errbuf);
  END;

  /*======================================================================================================*/
  --  Nom           : main
  --  Description   : procedure principale du traitement qui enchainera l'ensemble
  --                  des autres procedures.
  --  PARAMETRES    : pv_errbuf           Entree/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 18/08/2023
  /*=========================================================================================================*/
  PROCEDURE MAIN(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    v_etape     VARCHAR2(100);
    
    vv_errbuf   VARCHAR2(500);
    vn_retcode  NUMBER;
    vv_filename VARCHAR2(200);
  
  
  BEGIN
  
   
    entete_de_sortie;
    v_etape := 'Sortie de traitement';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    sortie_traitement;
    
  
    v_etape := ' lettrage Reglement';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    reglement_lettrage(vv_errbuf, vn_retcode);
  
    
    fin_de_sortie;
  
    IF (vn_retcode != 0) THEN
      pv_errbuf  := vv_errbuf;
      pn_retcode := vn_retcode;
      if vn_retcode = 2 then
    dka_Tools_Pkg.put_log_message('# reglement_lettrage ' || SQLERRM);
    end if;
    END IF;
  
  v_etape := 'Extraction des donnees';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    FOR cur_region IN (SELECT distinct substr(name, 1, 3) user_name
                         FROM hr_operating_units
                        where substr(name, 1, 3) <> 'REF') LOOP
      dka_tools_pkg.put_debug_message('EXTRACTION FICHIER');
     
    
      -- Extraction des donnees
      extraction_reglement(vv_errbuf, vn_retcode,
                           cur_region.user_name,
                           vv_filename);
      IF (vn_retcode != 0) THEN
      pv_errbuf  := vv_errbuf;
      pn_retcode := vn_retcode;
       IF (vn_retcode = 2) THEN
    dka_Tools_Pkg.put_log_message('# extraction_reglement ' || SQLERRM);
     END IF; 
   END IF;        
      dka_tools_pkg.put_log_message('region : ' || cur_region.user_name);
      dka_tools_pkg.put_log_message('File : ' || vv_filename);
      ENVOI_MAIL(vv_errbuf, vn_retcode, cur_region.user_name, vv_filename);
    IF (vn_retcode != 0) THEN
      pv_errbuf  := vv_errbuf;
      pn_retcode := vn_retcode;
       IF (vn_retcode = 2) THEN
    dka_Tools_Pkg.put_log_message('# ENVOI_MAIL ' || SQLERRM);
        END IF;                             
    END IF;
    END LOOP;
  
  
    IF pn_retcode = 2 THEN
      pv_errbuf := 'ATTENTION : Erreur bloquante : ' || pv_errbuf;
    ELSIF pn_retcode = 1 THEN
      pv_errbuf  := 'ATTENTION : Il y a des cas d''avertissement : ' ||
                    pv_errbuf;
      pn_retcode := 1;
    ELSE
      pv_errbuf  := 'Fin normale du traitement.';
      pn_retcode := 0;
    END IF;
  
    writeout(pv_errbuf);
    fin_de_sortie;
   EXCEPTION WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('ERREUR [exception dans MAIN() ' ||
                                    'non catchee]');

      pn_retcode := 2;
      pv_errbuf  := 'Erreur ' || SQLERRM || cv_error_message;
      dka_Tools_Pkg.put_log_message('# MAIN ERREUR : ' || SQLERRM);
  
  
  
  END;

END DKA_SARLETTZERO_PKG;
/
 
SHOW ERRORS ;
EXIT 