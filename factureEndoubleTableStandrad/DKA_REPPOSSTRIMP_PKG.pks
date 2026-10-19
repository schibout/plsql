CREATE OR REPLACE PACKAGE BODY DKA_CREATE_ACCOUNT_PKG IS
  /**************************************************************************
  * $HEADER : DKA_CREATE_ACCOUNT_PKG.sql  V1.1 2014/10/08 $
  *
  * FILENAME
  *  DKA_CREATE_ACCOUNT_PKG.sql
  *
  * DESCRIPTION
  *  XX : Création des comptes
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_err_buf         Renvoie les messages d'erreur
  * p_ret_code        Code retour
  * p_owner 
  *
  * HISTORY
  * =======
  *
  * VERSION DATE        AUTHOR(S)       DESCRIPTION
  * ------- ----------- --------------- ------------------------------------
  * 1.0     21-SEP-2016 LKI             Creation
  * 1.1     27/03/2017  Maxime EGOT     Refonte du traitement
  * 1.2     14/09/2017  N. BOUSSEKEYT   artf2223171 - Correction suite à la création de nouveaux comptes  
  *************************************************************************/

  -- Private Global Types
  --
  -- Private Global Constants
  --
  -- Private Global Variables
  --
  -- Private Global Cursors and Cursor Records
  --
  -- Private Program Units (forward references)
  --
  -- Private Global Exceptions
  --
  -- Public Program Units
  --

  /**************************************************************************
  * PROCEDURE NAME : main
  *
  * DESCRIPTION
  *  Procedure principale (= point d'entrée)
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_err_buf         Message d'erreur retour
  * p_ret_code        Code erreur retour (0=Normal,1=Avertissement,2=Erreur)
  * p_set_of_books_id SOB de l'entité à extraire
  * p_year            Annee à extraire
  *************************************************************************/
  l_DEBUG varchar2(1) := NVL(FND_PROFILE.value('CE_DEBUG'), 'N');

  PROCEDURE main(p_err_buf OUT VARCHAR2, p_ret_code OUT VARCHAR2, p_owner IN VARCHAR2) IS
    -- variables pour les appels à CE_BANK_PUB
    l_return_status          VARCHAR2(1);
    l_msg_count              NUMBER;
    l_msg_data               VARCHAR2(1000);
    l_acct_rec               BankAcct_rec_type;
    l_acct_id                number;
    l_bank_acct_use_rec      ce_bank_pub.BankAcct_use_rec_type;
    l_acct_use_id            number;
    l_account_name           ce_bank_accounts.bank_account_name%type;
    l_iban                   iby_ext_bank_accounts.iban%type;
    l_rate_var_gain          gl_code_combinations_kfv.concatenated_segments%type;
    l_rate_var_loss          gl_code_combinations_kfv.concatenated_segments%type;
    g_edisc_ar_trx_id        ar_receivables_trx_all.receivables_trx_id%type;
    g_unedisc_ar_trx_id      ar_receivables_trx_all.receivables_trx_id%type;
    v_org_id                 number;
    v_account_owner_org_id   number;
    v_account_owner_party_id number;
    v_name                   VARCHAR2(1000);
  
    CURSOR ligne_cur IS
      -- artf2223171 - Correction suite à la création de nouveaux comptes 
      SELECT int.*, int.rowid rid
        FROM DKA.DKA_COMPTE_BANC_INT int
       where 1 = 1 --NOM_PROPRIETAIRE = p_owner
         and INTITULE_COMPTE_BANCAIRE not in (select bank_account_name from CE_BANK_ACCOUNTS)
      ;
  
    ------------------------------------------------------------
    -- get_receivables_trx_id
    -- Description: recherche de l'identifiant AR du type d'évènement pour les escomptes
    ------------------------------------------------------------
    FUNCTION get_receivables_trx_id(p_org_id in hr_all_organization_units.organization_id%type,
                                    p_type   in ar_receivables_trx_all.type%type)
      return ar_receivables_trx_all.receivables_trx_id%type IS
      K_API_NAME CONSTANT VARCHAR2(30) := 'get_receivables_trx_id';
      l_result ar_receivables_trx_all.receivables_trx_id%type := null;
    
    BEGIN
    
      begin
        select receivables_trx_id
          into l_result
          from ar_receivables_trx_all
         where org_id = p_org_id
           and type = p_type
           and status = 'A';
      exception
        when no_data_found then
          --dbms_output.put_line('Il n''existe pas d''évènement d''escompte actif de type '||p_type||' pour l''ORG_ID '||p_org_id);
          Fnd_File.put_line(Fnd_File.LOG,
                            TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                            'Il n''existe pas d''évènement d''escompte actif de type ' || p_type || ' pour l''ORG_ID ' ||
                            p_org_id);
        when others then
          --dbms_output.put_line('Une erreur est survenue lors de la recherche du type d''évènement pour les escomptes');
          Fnd_File.put_line(Fnd_File.LOG,
                            TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                            'Une erreur est survenue lors de la recherche du type d''évènement pour les escomptes');
      end;
    
      return l_result;
    END get_receivables_trx_id;
  
    ------------------------------------------------------------
    -- get_ccid
    -- Description: recherche du ccid
    ------------------------------------------------------------
    FUNCTION get_ccid(p_value in varchar2) return number IS
      K_API_NAME CONSTANT VARCHAR2(30) := 'get_ccid';
      l_result number := null;
    BEGIN
    
      begin
        select code_combination_id
          into l_result
          from gl_code_combinations
         where segment1 || '.' || segment2 || '.' || segment3 || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' ||
               segment7 || '.' || segment8 || '.' || segment9 || '.' || segment10 || '.' || segment11 || '.' ||
               segment12 = p_value;
      exception
        when no_data_found then
          --dbms_output.put_line('Il n''existe pas de ccid pour  '||p_value);
          Fnd_File.put_line(Fnd_File.LOG,
                            TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Il n''existe pas de ccid pour  ' ||
                            p_value);
        when others then
          --dbms_output.put_line('Une erreur est survenue lors de la recherche du ccid');
          Fnd_File.put_line(Fnd_File.LOG,
                            TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                            'Une erreur est survenue lors de la recherche du ccid');
      end;
      return l_result;
    END get_ccid;
  
    /*=======================================================================+
    | PRIVATE PROCEDURE find_bank_info                                      |
    |                                                                       |
    | DESCRIPTION                                                           |
    |   Get the party_id and country of the bank given a bank_branch_id.    |
    |                                                                       |
    | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                |
    |                                                                       |
    | MODIFICATION HISTORY                                                  |
    |   08-SEP-2004    Xin Wang      Created.                               |
    +=======================================================================*/
    PROCEDURE find_bank_info(p_branch_id     IN NUMBER,
                             x_return_status IN OUT NOCOPY VARCHAR2,
                             x_bank_id       OUT NOCOPY NUMBER,
                             x_country_code  OUT NOCOPY VARCHAR2,
                             x_bank_name     OUT NOCOPY VARCHAR2,
                             x_bank_number   OUT NOCOPY VARCHAR2) IS
      CURSOR c_bank IS
        SELECT hz_bank.party_id AS bank_id,
               hz_bankorg.home_country,
               hz_bank.party_name,
               hz_bankorg.bank_or_branch_number
          FROM hz_parties               hz_bank,
               hz_organization_profiles hz_bankorg,
               hz_parties               hz_branch,
               hz_relationships         hz_rel,
               hz_code_assignments      hz_bankCA,
               hz_code_assignments      hz_branchCA
         WHERE hz_branchCA.owner_table_name = 'HZ_PARTIES'
           AND hz_branchCA.owner_table_id = hz_branch.party_id
           AND hz_branchCA.class_category = 'BANK_INSTITUTION_TYPE'
           AND hz_branchCA.class_code = 'BANK_BRANCH'
           AND NVL(hz_branchCA.STATUS, 'A') = 'A'
           AND hz_bankCA.CLASS_CATEGORY = 'BANK_INSTITUTION_TYPE'
           AND hz_bankCA.CLASS_CODE = 'BANK'
           AND hz_bankCA.OWNER_TABLE_NAME = 'HZ_PARTIES'
           AND hz_bankCA.OWNER_TABLE_ID = hz_bank.PARTY_ID
           AND NVL(hz_bankCA.STATUS, 'A') = 'A'
           AND hz_rel.OBJECT_ID = hz_bank.PARTY_ID
           And hz_branch.PARTY_ID = hz_rel.SUBJECT_ID
           And hz_rel.RELATIONSHIP_TYPE = 'BANK_AND_BRANCH'
           And hz_rel.RELATIONSHIP_CODE = 'BRANCH_OF'
           And hz_rel.STATUS = 'A'
           And hz_rel.SUBJECT_TABLE_NAME = 'HZ_PARTIES'
           And hz_rel.SUBJECT_TYPE = 'ORGANIZATION'
           And hz_rel.OBJECT_TABLE_NAME = 'HZ_PARTIES'
           And hz_rel.OBJECT_TYPE = 'ORGANIZATION'
           AND hz_bank.party_id = hz_bankorg.party_id
           AND SYSDATE between TRUNC(hz_bankorg.effective_start_date) and
               NVL(TRUNC(hz_bankorg.effective_end_date), SYSDATE + 1)
           AND hz_branch.party_id = p_branch_id;
    BEGIN
      -- initialize API return status to success.
      x_return_status := fnd_api.g_ret_sts_success;
    
      OPEN c_bank;
      FETCH c_bank
        INTO x_bank_id, x_country_code, x_bank_name, x_bank_number;
      IF c_bank%NOTFOUND THEN
        fnd_message.set_name('CE', 'CE_API_NO_BANK');
        fnd_msg_pub.add;
        x_return_status := fnd_api.g_ret_sts_error;
      END IF;
      CLOSE c_bank;
    
    END find_bank_info;
  
    /*=======================================================================+
    | PRIVATE FUNCTION check_mandatory_param                               |
    |   Check that value has been set for mandatory parameters             |
    |                                                                      |
    | DESCRIPTION                                                          |
    |   Get country of the bank given the bank party_id.                   |
    |                                                                      |
    | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                               |
    |                                                                      |
    | MODIFICATION HISTORY                                                 |
    |   18-May-2011   vnetan     Created.                                  |
    +======================================================================*/
    PROCEDURE check_mandatory_param(p_param_name IN VARCHAR2, p_param_value IN VARCHAR2) AS
    BEGIN
      IF (p_param_value IS NULL) THEN
        fnd_message.set_name('CE', 'CE_API_REQUIRED_PARAM');
        fnd_message.set_token('PARAM', p_param_name);
        fnd_msg_pub.add;
        IF l_DEBUG in ('Y', 'C') THEN
          cep_standard.debug(p_param_name || ' is a required parameter.');
        END IF;
        RAISE fnd_api.g_exc_error;
      
      END IF;
    END check_mandatory_param;
  
    /*=======================================================================+
    | PUBLIC PROCEDURE create_bank_acct                                     |
    |                                                                       |
    | DESCRIPTION                                                           |
    |   Create an internal or subsidiary bank account.                      |
    |                                                                       |
    | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                |
    |                                                                       |
    | ARGUMENTS                                                             |
    |   IN:                                                                 |
    |     p_init_msg_list      Initialize message stack if it is set to     |
    |                          FND_API.G_TRUE. Default is fnd_api.g_false   |
    |     p_acct_rec           Bank account record.                |
    |   IN/OUT:                                                             |
    |   OUT:                                                                |
    |     x_acct_id            Bank account ID.                             |
    |     x_return_status      Return status after the call. The status can |
    |                          be FND_API.G_RET_STS_SUCCESS (success),      |
    |                          fnd_api.g_ret_sts_error (error),             |
    |                          fnd_api.g_ret_sts_unexp_error (unexpected    |
    |                          error).                                      |
    |     x_msg_count          Number of messages in message stack.         |
    |     x_msg_data           Message text if x_msg_count is 1.            |
    | MODIFICATION HISTORY                                                  |
    |   25-AUG-2004    Xin Wang           Created.                          |
    +=======================================================================*/
    PROCEDURE create_bank_acct(p_init_msg_list IN VARCHAR2 := fnd_api.g_false,
                               p_acct_rec      IN BankAcct_rec_type,
                               x_acct_id       OUT NOCOPY NUMBER,
                               x_return_status OUT NOCOPY VARCHAR2,
                               x_msg_count     OUT NOCOPY NUMBER,
                               x_msg_data      OUT NOCOPY VARCHAR2,
                               p_new_xtr_acct  IN Boolean default true -- bug 18824937
                               ) IS
    
      CURSOR c_acct_id IS
        SELECT CE_BANK_ACCOUNTS_S.nextval FROM sys.dual;
      CURSOR c_acct_rowid IS
        SELECT rowid FROM CE_BANK_ACCOUNTS WHERE bank_account_id = x_acct_id;
      CURSOR c_branch IS
        SELECT bank_or_branch_number
          FROM hz_organization_profiles
         WHERE SYSDATE between TRUNC(effective_start_date) and NVL(TRUNC(effective_end_date), SYSDATE + 1)
           AND party_id = p_acct_rec.branch_id;
      /*
          CURSOR c_bank_id IS
            SELECT object_id
            FROM   hz_relationships
            WHERE  RELATIONSHIP_TYPE = 'BANK_AND_BRANCH'
            AND    RELATIONSHIP_CODE = 'BRANCH_OF'
            AND    subject_id = p_acct_rec.branch_id;
      */
      l_iban                VARCHAR2(50) := null;
      l_alc                 VARCHAR2(30) := null;
      l_country             VARCHAR2(60);
      l_bank_id             NUMBER(15) := null;
      l_acct_rowid          VARCHAR2(100);
      l_bank_name           VARCHAR2(360) := null;
      l_bank_number         VARCHAR2(30) := null;
      l_branch_number       VARCHAR2(30) := null;
      l_account_number      VARCHAR2(100) := null;
      X_ELECTRONIC_ACCT_NUM VARCHAR2(100) := null;
    
      -- Bug 14350260 Start
      l_party_code            xtr_parties_v.party_code%type;
      l_bank_code             xtr_party_info.party_code%type;
      l_city                  ce_bank_branches_v.city%type;
      l_address_line1         ce_bank_branches_v.ADDRESS_LINE1%type;
      l_eft_swift_code        ce_bank_branches_v.EFT_SWIFT_CODE%type;
      x_xtr_api_return_status VARCHAR2(10);
      x_xtr_api_msg_count     NUMBER;
      x_xtr_api_msg_data      VARCHAR2(10000);
    
      -- Bug 14350260 End
    
    BEGIN
      SAVEPOINT create_bank_acct;
    
      IF l_DEBUG in ('Y', 'C') THEN
        cep_standard.debug('>>CE_BANK_PUB.create_bank_acct.');
      END IF;
    
      -- initialize message list
      IF fnd_api.to_boolean(p_init_msg_list) THEN
        fnd_msg_pub.initialize;
      END IF;
    
      -- initialize API return status to success.
      x_return_status := fnd_api.g_ret_sts_success;
    
      -- first check all required params
      -- 12557352: Modified check by calling check_mandatory_param
      check_mandatory_param('p_acct_rec.branch_id', p_acct_rec.branch_id);
      check_mandatory_param('p_acct_rec.bank_account_name', p_acct_rec.bank_account_name);
      check_mandatory_param('p_acct_rec.bank_account_num', p_acct_rec.bank_account_num);
      check_mandatory_param('p_acct_rec.account_owner_org_id', p_acct_rec.account_owner_org_id);
      check_mandatory_param('p_acct_rec.account_classification', p_acct_rec.account_classification);
    
      -- validate currency
      IF p_acct_rec.currency IS NOT NULL THEN
        CE_BANK_AND_ACCOUNT_VALIDATION.validate_currency(p_acct_rec.currency, x_return_status);
      
        -- raise an exception if the validation is unsuccessful
        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE fnd_api.g_exc_error;
        END IF;
      END IF;
    
      -- Bug 10183698
      -- validate account name
      /* CE_BANK_AND_ACCOUNT_VALIDATION.validate_account_name(p_acct_rec.branch_id, p_acct_rec.bank_account_name,
                                                           null, x_return_status);
      
      -- raise an exception if the validation is unsuccessful
      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE fnd_api.g_exc_error;
      END IF;  */
    
      -- validate iban
      IF p_acct_rec.iban IS NOT NULL THEN
        CE_BANK_AND_ACCOUNT_VALIDATION.validate_IBAN(p_acct_rec.iban, l_iban, x_return_status);
      
        -- raise an exception if the validation is unsuccessful
        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE fnd_api.g_exc_error;
        END IF;
      END IF;
    
      -- validate agency_location_code
      IF p_acct_rec.agency_location_code IS NOT NULL THEN
        CE_BANK_AND_ACCOUNT_VALIDATION.validate_alc(p_acct_rec.agency_location_code,
                                                    FND_API.G_FALSE,
                                                    x_msg_count,
                                                    x_msg_data,
                                                    l_alc,
                                                    x_return_status);
      
        -- raise an exception if the validation is unsuccessful
        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE fnd_api.g_exc_error;
        END IF;
      END IF;
    
      -- find bank info
      IF p_acct_rec.branch_id IS NOT NULL THEN
        find_bank_info(p_acct_rec.branch_id, x_return_status, l_bank_id, l_country, l_bank_name, l_bank_number);
      
        -- raise an exception if bank is not found
        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE fnd_api.g_exc_error;
        END IF;
      
        -- find branch number
        OPEN c_branch;
        FETCH c_branch
          INTO l_branch_number;
        IF c_branch%NOTFOUND THEN
          fnd_message.set_name('CE', 'CE_API_NO_BRANCH');
          fnd_msg_pub.add;
          x_return_status := fnd_api.g_ret_sts_error;
          RAISE fnd_api.g_exc_error;
        END IF;
        CLOSE c_branch;
      END IF;
    
      -- country specific validation API call here.
      -- do not perform country specific validations for subsidiary accounts
      IF p_acct_rec.account_classification <> 'SUBSIDIARY' THEN
        ce_validate_bankinfo.ce_validate_cd(l_country,
                                            p_acct_rec.check_digits,
                                            l_bank_number,
                                            l_branch_number,
                                            p_acct_rec.bank_account_num,
                                            FND_API.G_FALSE,
                                            x_msg_count,
                                            x_msg_data,
                                            x_return_status,
                                            'INTERNAL');
      
        ce_validate_bankinfo.ce_validate_account(l_country,
                                                 l_bank_number,
                                                 l_branch_number,
                                                 p_acct_rec.bank_account_num,
                                                 l_bank_id,
                                                 p_acct_rec.branch_id,
                                                 null, -- account_id
                                                 p_acct_rec.currency,
                                                 p_acct_rec.acct_type,
                                                 p_acct_rec.acct_suffix,
                                                 p_acct_rec.secondary_account_reference,
                                                 p_acct_rec.bank_account_name,
                                                 FND_API.G_FALSE,
                                                 x_msg_count,
                                                 x_msg_data,
                                                 l_account_number,
                                                 x_return_status,
                                                 'INTERNAL',
                                                 p_acct_rec.check_digits,
                                                 X_ELECTRONIC_ACCT_NUM);
      
        -- raise an exception if the validation fails
        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE fnd_api.g_exc_error;
        END IF;
      ELSE
        -- set the account number for subsidiary accounts
        l_account_number := p_acct_rec.bank_account_num;
      END IF; -- subsidiary accounts
    
      -- insert data into ce_bank_accounts table
      OPEN c_acct_id;
      FETCH c_acct_id
        INTO x_acct_id;
      CLOSE c_acct_id;
    
      INSERT INTO CE_BANK_ACCOUNTS
        (BANK_ACCOUNT_ID,
         BANK_BRANCH_ID,
         BANK_ID,
         ACCOUNT_OWNER_PARTY_ID,
         ACCOUNT_OWNER_ORG_ID,
         ACCOUNT_CLASSIFICATION,
         BANK_ACCOUNT_NAME,
         BANK_ACCOUNT_NUM,
         CURRENCY_CODE,
         IBAN_NUMBER,
         CHECK_DIGITS,
         EFT_REQUESTER_IDENTIFIER,
         SECONDARY_ACCOUNT_REFERENCE,
         MULTI_CURRENCY_ALLOWED_FLAG,
         BANK_ACCOUNT_NAME_ALT,
         SHORT_ACCOUNT_NAME,
         BANK_ACCOUNT_TYPE,
         ACCOUNT_SUFFIX,
         DESCRIPTION_CODE1,
         DESCRIPTION_CODE2,
         DESCRIPTION,
         AGENCY_LOCATION_CODE,
         AP_USE_ALLOWED_FLAG,
         AR_USE_ALLOWED_FLAG,
         XTR_USE_ALLOWED_FLAG,
         PAY_USE_ALLOWED_FLAG,
         PAYMENT_MULTI_CURRENCY_FLAG,
         RECEIPT_MULTI_CURRENCY_FLAG,
         ZERO_AMOUNT_ALLOWED,
         MAX_OUTLAY,
         MAX_CHECK_AMOUNT,
         MIN_CHECK_AMOUNT,
         AP_AMOUNT_TOLERANCE,
         AR_AMOUNT_TOLERANCE,
         XTR_AMOUNT_TOLERANCE,
         PAY_AMOUNT_TOLERANCE,
         CE_AMOUNT_TOLERANCE,
         AP_PERCENT_TOLERANCE,
         AR_PERCENT_TOLERANCE,
         XTR_PERCENT_TOLERANCE,
         PAY_PERCENT_TOLERANCE,
         CE_PERCENT_TOLERANCE,
         START_DATE,
         END_DATE,
         ACCOUNT_HOLDER_NAME_ALT,
         ACCOUNT_HOLDER_NAME,
         CASHFLOW_DISPLAY_ORDER,
         POOLED_FLAG,
         MIN_TARGET_BALANCE,
         MAX_TARGET_BALANCE,
         EFT_USER_NUM,
         MASKED_ACCOUNT_NUM,
         MASKED_IBAN,
         INTEREST_SCHEDULE_ID,
         ASSET_CODE_COMBINATION_ID,
         CASH_CLEARING_CCID,
         BANK_CHARGES_CCID,
         BANK_ERRORS_CCID,
         CASHPOOL_MIN_PAYMENT_AMT,
         CASHPOOL_MIN_RECEIPT_AMT,
         CASHPOOL_ROUND_FACTOR,
         CASHPOOL_ROUND_RULE,
         ATTRIBUTE_CATEGORY,
         ATTRIBUTE1,
         ATTRIBUTE2,
         ATTRIBUTE3,
         ATTRIBUTE4,
         ATTRIBUTE5,
         ATTRIBUTE6,
         ATTRIBUTE7,
         ATTRIBUTE8,
         ATTRIBUTE9,
         ATTRIBUTE10,
         ATTRIBUTE11,
         ATTRIBUTE12,
         ATTRIBUTE13,
         ATTRIBUTE14,
         ATTRIBUTE15,
         LAST_UPDATE_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_LOGIN,
         CREATION_DATE,
         CREATED_BY,
         OBJECT_VERSION_NUMBER,
         xtr_bank_account_reference,
         netting_acct_flag, -- 22524647
         recon_enable_oi_flag, -- 22524647
         recon_foreign_bank_xrate_type, -- 22524647
         recon_for_bank_xrate_date_type, -- 22524647
         recon_oi_amount_tolerance, -- 22524647
         recon_oi_percent_tolerance, -- 22524647
         bank_account_num_electronic) -- 22524647
      VALUES
        (x_acct_id,
         p_acct_rec.branch_id,
         l_bank_id,
         p_acct_rec.account_owner_party_id,
         p_acct_rec.account_owner_org_id,
         p_acct_rec.account_classification,
         p_acct_rec.bank_account_name,
         l_account_number,
         p_acct_rec.currency,
         l_iban,
         p_acct_rec.check_digits,
         p_acct_rec.eft_requester_id,
         p_acct_rec.secondary_account_reference,
         p_acct_rec.multi_currency_allowed_flag,
         p_acct_rec.alternate_acct_name,
         p_acct_rec.short_account_name,
         p_acct_rec.acct_type,
         p_acct_rec.acct_suffix,
         p_acct_rec.description_code1,
         p_acct_rec.description_code2,
         p_acct_rec.description,
         l_alc,
         p_acct_rec.ap_use_allowed_flag,
         p_acct_rec.ar_use_allowed_flag,
         p_acct_rec.xtr_use_allowed_flag,
         p_acct_rec.pay_use_allowed_flag,
         p_acct_rec.payment_multi_currency_flag,
         p_acct_rec.receipt_multi_currency_flag,
         p_acct_rec.zero_amount_allowed,
         p_acct_rec.max_outlay,
         p_acct_rec.max_check_amount,
         p_acct_rec.min_check_amount,
         p_acct_rec.ap_amount_tolerance,
         p_acct_rec.ar_amount_tolerance,
         p_acct_rec.xtr_amount_tolerance,
         p_acct_rec.pay_amount_tolerance,
         p_acct_rec.ce_amount_tolerance,
         p_acct_rec.ap_percent_tolerance,
         p_acct_rec.ar_percent_tolerance,
         p_acct_rec.xtr_percent_tolerance,
         p_acct_rec.pay_percent_tolerance,
         p_acct_rec.ce_percent_tolerance,
         p_acct_rec.start_date,
         p_acct_rec.end_date,
         p_acct_rec.account_holder_name_alt,
         p_acct_rec.account_holder_name,
         p_acct_rec.cashflow_display_order,
         p_acct_rec.pooled_flag,
         p_acct_rec.min_target_balance,
         p_acct_rec.max_target_balance,
         p_acct_rec.eft_user_num,
         p_acct_rec.masked_account_num,
         p_acct_rec.masked_iban,
         p_acct_rec.interest_schedule_id,
         p_acct_rec.asset_code_combination_id,
         p_acct_rec.cash_clearing_ccid,
         p_acct_rec.bank_charges_ccid,
         p_acct_rec.bank_errors_ccid,
         p_acct_rec.cashpool_min_payment_amt,
         p_acct_rec.cashpool_min_receipt_amt,
         p_acct_rec.cashpool_round_factor,
         p_acct_rec.cashpool_round_rule,
         p_acct_rec.attribute_category,
         p_acct_rec.attribute1,
         p_acct_rec.attribute2,
         p_acct_rec.attribute3,
         p_acct_rec.attribute4,
         p_acct_rec.attribute5,
         p_acct_rec.attribute6,
         p_acct_rec.attribute7,
         p_acct_rec.attribute8,
         p_acct_rec.attribute9,
         p_acct_rec.attribute10,
         p_acct_rec.attribute11,
         p_acct_rec.attribute12,
         p_acct_rec.attribute13,
         p_acct_rec.attribute14,
         p_acct_rec.attribute15,
         sysdate,
         NVL(FND_GLOBAL.user_id, -1),
         NVL(FND_GLOBAL.login_id, -1),
         sysdate,
         NVL(FND_GLOBAL.user_id, -1),
         1,
         p_acct_rec.xtr_bank_account_reference,
         p_acct_rec.netting_acct_flag, -- 22524647
         p_acct_rec.recon_enable_oi_flag, -- 22524647
         p_acct_rec.recon_foreign_bank_xrate_type, -- 22524647
         p_acct_rec.recon_for_bank_xrate_date_type, -- 22524647
         p_acct_rec.recon_oi_amount_tolerance, -- 22524647
         p_acct_rec.recon_oi_percent_tolerance, -- 22524647
         X_ELECTRONIC_ACCT_NUM); -- 22524647
      OPEN c_acct_rowid;
      FETCH c_acct_rowid
        INTO l_acct_rowid;
      If (c_acct_rowid%NOTFOUND) then
        CLOSE c_acct_rowid;
        RAISE NO_DATA_FOUND;
      End If;
      CLOSE c_acct_rowid;
    
      -- Bug 14350260 Start
      -- Added a call to xtr API to insert XTR part of the data.
      cep_standard.debug('Starting XTR API Call...');
    
      cep_standard.debug('p_acct_rec.xtr_use_allowed_flag = ' || p_acct_rec.xtr_use_allowed_flag);
      if p_acct_rec.xtr_use_allowed_flag = 'Y' then
      
        cep_standard.debug('p_acct_rec.account_owner_org_id = ' || p_acct_rec.account_owner_org_id);
      
        select party_code
          into l_party_code
          from xtr_parties_v
         where legal_entity_id = p_acct_rec.account_owner_org_id
           and authorised = 'Y';
        cep_standard.debug('l_party_code = ' || l_party_code);
        cep_standard.debug('x_acct_id = ' || x_acct_id);
        cep_standard.debug('p_acct_rec.branch_id = ' || p_acct_rec.branch_id);
      
        select party_code into l_bank_code from xtr_party_info where ce_bank_branch_id = p_acct_rec.branch_id;
        cep_standard.debug('l_bank_code = ' || l_bank_code);
      
        select city, ADDRESS_LINE1, EFT_SWIFT_CODE
          into l_city, l_ADDRESS_LINE1, l_EFT_SWIFT_CODE
          from ce_bank_branches_v
         where BRANCH_PARTY_ID = p_acct_rec.branch_id;
        cep_standard.debug('l_city = ' || l_city);
        cep_standard.debug('l_ADDRESS_LINE1 = ' || l_ADDRESS_LINE1);
        cep_standard.debug('l_EFT_SWIFT_CODE = ' || l_EFT_SWIFT_CODE);
      
        if (p_new_xtr_acct = true) then
          -- bug 18824937
        
          XTR_REPLICATE_BANK_ACCOUNTS_P.REPLICATE_BANK_ACCOUNTS(l_account_number, -- p_account_number
                                                                NULL, -- p_authorised
                                                                l_party_code, --  p_party_code
                                                                'C', -- p_party_type
                                                                l_bank_code, -- p_bank_code
                                                                p_acct_rec.currency, -- p_currency
                                                                p_acct_rec.bank_account_name, -- p_bank_short_code
                                                                NULL, -- p_default_acct
                                                                NULL, -- p_eft_script_name
                                                                NULL, -- p_code_combination_id
                                                                NULL, -- p_intereste_calculation_basis
                                                                l_city, --  p_location
                                                                NULL, -- p_portfolio_code
                                                                NULL, -- p_primary_settlement_method
                                                                l_ADDRESS_LINE1, -- p_street
                                                                NULL, -- p_year_calc_type
                                                                l_EFT_SWIFT_CODE, -- p_swift_id
                                                                p_acct_rec.attribute_category, -- p_attribute_category
                                                                p_acct_rec.attribute1, -- p_attribute1
                                                                p_acct_rec.attribute2, -- p_attribute2
                                                                p_acct_rec.attribute3, -- p_attribute3
                                                                p_acct_rec.attribute4, -- p_attribute4
                                                                p_acct_rec.attribute5, -- p_attribute5
                                                                p_acct_rec.attribute6, -- p_attribute6
                                                                p_acct_rec.attribute7, -- p_attribute7
                                                                p_acct_rec.attribute8, -- p_attribute8
                                                                p_acct_rec.attribute9, -- p_attribute9
                                                                p_acct_rec.attribute10, -- p_attribute10
                                                                p_acct_rec.attribute11, -- p_attribute11
                                                                p_acct_rec.attribute12, -- p_attribute12
                                                                p_acct_rec.attribute13, -- p_attribute13
                                                                p_acct_rec.attribute14, -- p_attribute14
                                                                p_acct_rec.attribute15, -- p_attribute15
                                                                NULL, -- p_pricing_model
                                                                p_acct_rec.short_account_name, -- p_legal_account_name
                                                                x_acct_id, -- p_ce_bank_account_id
                                                                p_acct_rec.branch_id, -- p_bank_branch_id
                                                                NULL, -- p_bank_acct_use_id
                                                                'I', -- p_action_flag
                                                                x_xtr_api_return_status, -- x_return_status OUT
                                                                x_xtr_api_msg_count, -- x_msg_count OUT
                                                                x_xtr_api_msg_data, -- x_msg_data OUT
                                                                l_iban);
          cep_standard.debug('Call to XTR API XTR_REPLICATE_BANK_ACCOUNTS_P.REPLICATE_BANK_ACCOUNTS Sucessfully Completed...');
          if x_xtr_api_return_status <> FND_API.G_RET_STS_SUCCESS then
            cep_standard.debug('Call to XTR API XTR_REPLICATE_BANK_ACCOUNTS_P.REPLICATE_BANK_ACCOUNTS has failed...');
            RAISE fnd_api.g_exc_error;
          end if;
        end if; -- bug 18824937 ends
      end if;
      -- Bug 14350260 End
    
      -- get message count and if count is 1, get message info.
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false, p_count => x_msg_count, p_data => x_msg_data);
    
      IF l_DEBUG in ('Y', 'C') THEN
        cep_standard.debug('<<CE_BANK_PUB.create_bank_acct.');
      END IF;
    
    EXCEPTION
      WHEN fnd_api.g_exc_error THEN
        ROLLBACK TO create_bank_acct;
        x_return_status := fnd_api.g_ret_sts_error;
        fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false, p_count => x_msg_count, p_data => x_msg_data);
      
        IF l_DEBUG in ('Y', 'C') THEN
          cep_standard.debug_msg_stack(x_msg_count, x_msg_data);
        END IF;
      
      WHEN fnd_api.g_exc_unexpected_error THEN
        ROLLBACK TO create_bank_acct;
        x_return_status := fnd_api.g_ret_sts_unexp_error;
        fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false, p_count => x_msg_count, p_data => x_msg_data);
      
        IF l_DEBUG in ('Y', 'C') THEN
          cep_standard.debug_msg_stack(x_msg_count, x_msg_data);
        END IF;
      
      WHEN OTHERS THEN
        ROLLBACK TO create_bank_acct;
        x_return_status := fnd_api.g_ret_sts_unexp_error;
        fnd_message.set_name('CE', 'CE_API_OTHERS_EXCEP');
        fnd_message.set_token('ERROR', SQLERRM);
        fnd_msg_pub.add;
        fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false, p_count => x_msg_count, p_data => x_msg_data);
      
        IF l_DEBUG in ('Y', 'C') THEN
          cep_standard.debug_msg_stack(x_msg_count, x_msg_data);
        END IF;
      
    END create_bank_acct;
 





    ---------------------------------------------------------- 
    -- DEBUT DU PROGRAMME
    ---------------------------------------------------------- 
  BEGIN
  
    FOR ligne_rec IN ligne_cur LOOP
    
      SELECT xep.legal_entity_id, xep.party_id, xep.name
        INTO v_account_owner_org_id, v_account_owner_party_id, v_name
        FROM HR_ORGANIZATION_INFORMATION_V hoiv, xle_entity_profiles xep
       WHERE hoiv.org_information_context = 'Operating Unit Information'
         and org_information5 = ligne_rec.ORGANISATION
         and hoiv.org_information2 = xep.legal_entity_id;
    
      -- création du compte bancaire  
      l_acct_rec.branch_id                      := 7094; --p_branch_id;
      l_acct_rec.bank_id                        := 7093; --p_bank_id;
      l_acct_rec.account_owner_org_id           := v_account_owner_org_id; --p_legal_entity_id; -- xle_entity_profiles : legal_entity_id de l'entité légale  
      l_acct_rec.account_owner_party_id         := v_account_owner_party_id; --p_party_id;   -- hz_parties : party_id de l'entité légale (contrairement à ce que suggère le nom de colonne ou la documentation eTRM)
      l_acct_rec.account_classification         := 'INTERNAL';
      l_acct_rec.bank_account_name              := ligne_rec.INTITULE_COMPTE_BANCAIRE; --l_account_name;
      l_acct_rec.bank_account_num               := ligne_rec.NUMERO_CPT; --p_acct_number_out;
      l_acct_rec.currency                       := ligne_rec.DEVISE; --p_rec_bank_acct.currency_code;
      l_acct_rec.check_digits                   := null; --p_rec_bank_acct.check_digits;
      l_acct_rec.iban                           := null; --l_iban;
      l_acct_rec.masked_account_num             := ligne_rec.NUMERO_CPT; --p_acct_number_out;
      l_acct_rec.masked_iban                    := null; --l_acct_rec.iban;
      l_acct_rec.multi_currency_allowed_flag    := 'Y';
      l_acct_rec.alternate_acct_name            := null;
      l_acct_rec.short_account_name             := null;
      l_acct_rec.acct_type                      := null; --p_rec_bank_acct.bank_account_type;
      l_acct_rec.acct_suffix                    := null;
      l_acct_rec.description_code1              := null;
      l_acct_rec.description_code2              := null;
      l_acct_rec.description                    := null; --p_rec_bank_acct.description_1;
      l_acct_rec.ap_use_allowed_flag            := 'Y';
      l_acct_rec.ar_use_allowed_flag            := 'Y';
      l_acct_rec.xtr_use_allowed_flag           := null;
      l_acct_rec.pay_use_allowed_flag           := 'N';
      l_acct_rec.payment_multi_currency_flag    := 'Y';
      l_acct_rec.receipt_multi_currency_flag    := 'Y';
      l_acct_rec.zero_amount_allowed            := 'Y';
      l_acct_rec.max_outlay                     := null;
      l_acct_rec.max_check_amount               := null;
      l_acct_rec.min_check_amount               := null;
      l_acct_rec.ap_amount_tolerance            := 0;
      l_acct_rec.ar_amount_tolerance            := 0;
      l_acct_rec.xtr_amount_tolerance           := null;
      l_acct_rec.pay_amount_tolerance           := 0;
      l_acct_rec.ce_amount_tolerance            := 0;
      l_acct_rec.ap_percent_tolerance           := 0;
      l_acct_rec.ar_percent_tolerance           := 0;
      l_acct_rec.xtr_percent_tolerance          := null;
      l_acct_rec.pay_percent_tolerance          := null;
      l_acct_rec.ce_percent_tolerance           := 0;
      l_acct_rec.start_date                     := null;
      l_acct_rec.end_date                       := null;
      l_acct_rec.eft_user_num                   := null;
      l_acct_rec.asset_code_combination_id      := fnd_flex_ext.get_ccid('SQLGL',
                                                                         'GL#',
                                                                         101,
                                                                         SYSDATE,
                                                                         ligne_rec.TRESORERIE_UO);
      l_acct_rec.cash_clearing_ccid             := null;
      l_acct_rec.bank_charges_ccid              := null;
      l_acct_rec.bank_errors_ccid               := null;
      l_acct_rec.check_digits                   := ligne_rec.chiffre_de_controle;
      l_acct_rec.pooled_flag                    := 'N';
      l_acct_rec.netting_acct_flag              := 'N';
      l_acct_rec.recon_for_bank_xrate_date_type := 'SLD';
      l_acct_rec.recon_enable_oi_flag           := 'N';
      l_acct_rec.recon_oi_amount_tolerance      := 0;
      l_acct_rec.recon_oi_percent_tolerance     := 0;
      --l_acct_rec.created_by := 1180;
      --l_acct_rec.creation_date := sysdate;
      --l_acct_rec.last_update_date := sysdate;
      --l_acct_rec.last_updated_by := 1180;
    
      create_bank_acct(p_init_msg_list => FND_API.G_TRUE,
                       p_acct_rec      => l_acct_rec,
                       x_acct_id       => l_acct_id,
                       x_return_status => l_return_status,
                       x_msg_count     => l_msg_count,
                       x_msg_data      => l_msg_data,
                       p_new_xtr_acct  => false);
    
      if l_return_status <> FND_API.g_ret_sts_success or l_acct_id is null then
        --dbms_output.put_line('Erreur lors de la création du compte bancaire : ' || replace(l_msg_data, chr(0), '|'));
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                          'Erreur lors de la création du compte bancaire : ' || replace(l_msg_data, chr(0), '|'));
        -- artf2223171 - Correction suite à la création de nouveaux comptes 
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || ligne_rec.rid);                  
      else
        --dbms_output.put_line('Compte bancaire créé. acct_id=' || l_acct_id); 
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Compte bancaire créé. acct_id=' ||
                          l_acct_id);
      end if;
    
      select organization_id into v_org_id from hr_all_organization_units where name = ligne_rec.ORGANISATION;
    
      -- Récupération du type d'évènement pour les escomptes dûs
      g_edisc_ar_trx_id := get_receivables_trx_id(v_org_id, 'EDISC');
    
      -- Récupération du type d'évènement pour les escomptes non dûs
      g_unedisc_ar_trx_id := get_receivables_trx_id(v_org_id, 'UNEDISC');
    
      l_bank_acct_use_rec.bank_account_id            := l_acct_id;
      l_bank_acct_use_rec.org_type                   := 'OU';
      l_bank_acct_use_rec.primary_flag               := null;
      l_bank_acct_use_rec.org_id                     := v_org_id; --g_org_id; -- hr_all_organization_units
      l_bank_acct_use_rec.ap_use_enable_flag         := 'Y';
      l_bank_acct_use_rec.ar_use_enable_flag         := 'Y';
      l_bank_acct_use_rec.xtr_use_enable_flag        := null;
      l_bank_acct_use_rec.pay_use_enable_flag        := null;
      l_bank_acct_use_rec.edisc_receivables_trx_id   := g_edisc_ar_trx_id;
      l_bank_acct_use_rec.unedisc_receivables_trx_id := g_unedisc_ar_trx_id;
      l_bank_acct_use_rec.end_date                   := null;
      l_bank_acct_use_rec.legal_entity_id            := null; --p_legal_entity_id;
      l_bank_acct_use_rec.authorized_flag            := 'Y';
      l_bank_acct_use_rec.default_account_flag       := 'N';
    
      /*      l_bank_acct_use_rec.asset_code_combination_id := fnd_flex_ext.get_ccid('SQLGL',
                                                                             'GL#',
                                                                             101,
                                                                             SYSDATE,
                                                                             ligne_rec.TRESORERIE_UO);
      l_bank_acct_use_rec.ap_asset_ccid             := fnd_flex_ext.get_ccid('SQLGL',
                                                                             'GL#',
                                                                             101,
                                                                             SYSDATE,
                                                                             ligne_rec.TRESORERIE_UO);
      l_bank_acct_use_rec.ar_asset_ccid             := fnd_flex_ext.get_ccid('SQLGL',
                                                                             'GL#',
                                                                             101,
                                                                             SYSDATE,
                                                                             ligne_rec.TRESORERIE_UO);*/
    
      DECLARE
        pn_code_combination_id NUMBER;
        pv_errbuf              VARCHAR2(200);
        pn_retcode             NUMBER;
      
      BEGIN
      
        --
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(ligne_rec.TRESORERIE_UO,
                                                                               0,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1) - 1),
                                              pv_segment2            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 1) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 2) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 1) - 1),
                                              pv_segment3            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 2) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 3) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 2) - 1),
                                              pv_segment4            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 3) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 4) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 3) - 1),
                                              pv_segment5            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 4) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 5) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 4) - 1),
                                              pv_segment6            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 5) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 6) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 5) - 1),
                                              pv_segment7            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 6) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 7) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 6) - 1),
                                              pv_segment8            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 7) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 8) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 7) - 1),
                                              pv_segment9            => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 8) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 9) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 8) - 1),
                                              pv_segment10           => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 9) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 10) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 9) - 1),
                                              pv_segment11           => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 10) + 1,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 11) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 10) - 1),
                                              pv_segment12           => substr(ligne_rec.TRESORERIE_UO,
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 11) + 1,
                                                                               length(ligne_rec.TRESORERIE_UO) -
                                                                               instr(ligne_rec.TRESORERIE_UO, '.', 1, 11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');
      
        l_bank_acct_use_rec.asset_code_combination_id := pn_code_combination_id;
        l_bank_acct_use_rec.ap_asset_ccid             := pn_code_combination_id;
        l_bank_acct_use_rec.ar_asset_ccid             := pn_code_combination_id;
      
        Fnd_File.put_line(Fnd_File.LOG, pv_errbuf);
        pn_code_combination_id := NULL;
      
        --
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               0,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1) - 1),
                                              pv_segment2            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 1) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 2) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 1) - 1),
                                              pv_segment3            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 2) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 3) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 2) - 1),
                                              pv_segment4            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 3) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 4) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 3) - 1),
                                              pv_segment5            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 4) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 5) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 4) - 1),
                                              pv_segment6            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 5) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 6) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 5) - 1),
                                              pv_segment7            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 6) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 7) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 6) - 1),
                                              pv_segment8            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 7) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 8) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 7) - 1),
                                              pv_segment9            => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 8) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 9) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 8) - 1),
                                              pv_segment10           => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 9) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 10) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 9) - 1),
                                              pv_segment11           => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 10) + 1,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 11) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 10) - 1),
                                              pv_segment12           => substr(ligne_rec.GAIN_DE_CHANGE,
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 11) + 1,
                                                                               length(ligne_rec.GAIN_DE_CHANGE) -
                                                                               instr(ligne_rec.GAIN_DE_CHANGE, '.', 1, 11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');
      
        l_bank_acct_use_rec.gain_code_combination_id := pn_code_combination_id;
      
        Fnd_File.put_line(Fnd_File.LOG, pv_errbuf);
        pn_code_combination_id := NULL;
      
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               0,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1) - 1),
                                              pv_segment2            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 1) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 2) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 1) - 1),
                                              pv_segment3            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 2) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 3) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 2) - 1),
                                              pv_segment4            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 3) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 4) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 3) - 1),
                                              pv_segment5            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 4) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 5) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 4) - 1),
                                              pv_segment6            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 5) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 6) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 5) - 1),
                                              pv_segment7            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 6) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 7) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 6) - 1),
                                              pv_segment8            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 7) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 8) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 7) - 1),
                                              pv_segment9            => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 8) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 9) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 8) - 1),
                                              pv_segment10           => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 9) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE, '.', 1, 9) - 1),
                                              pv_segment11           => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) + 1,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) - instr(ligne_rec.PERTE_DE_CHANGE,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 10) - 1),
                                              pv_segment12           => substr(ligne_rec.PERTE_DE_CHANGE,
                                                                               instr(ligne_rec.PERTE_DE_CHANGE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) + 1,
                                                                               length(ligne_rec.PERTE_DE_CHANGE) -
                                                                               instr(ligne_rec.PERTE_DE_CHANGE,
                                                                                     '.',
                                                                                     1,
                                                                                     11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');
      
        l_bank_acct_use_rec.loss_code_combination_id := pn_code_combination_id;
      
        Fnd_File.put_line(Fnd_File.LOG, pv_errbuf);
        pn_code_combination_id := NULL;
      
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               0,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1) - 1),
                                              pv_segment2            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     1) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     2) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                1) - 1),
                                              pv_segment3            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     2) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     3) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                2) - 1),
                                              pv_segment4            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     3) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     4) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                3) - 1),
                                              pv_segment5            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     4) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     5) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                4) - 1),
                                              pv_segment6            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     5) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     6) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                5) - 1),
                                              pv_segment7            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     6) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     7) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                6) - 1),
                                              pv_segment8            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     7) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     8) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                7) - 1),
                                              pv_segment9            => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     8) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     9) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                '.',
                                                                                                1,
                                                                                                8) - 1),
                                              pv_segment10           => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     9) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 9) - 1),
                                              pv_segment11           => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) - instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 10) - 1),
                                              pv_segment12           => substr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) + 1,
                                                                               length(ligne_rec.ENCAISSEMENT_EN_COMPTE) -
                                                                               instr(ligne_rec.ENCAISSEMENT_EN_COMPTE,
                                                                                     '.',
                                                                                     1,
                                                                                     11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');
      
        l_bank_acct_use_rec.on_account_ccid := pn_code_combination_id;
        Fnd_File.put_line(Fnd_File.LOG, pv_errbuf);
        pn_code_combination_id := NULL;
      
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               0,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1) - 1),
                                              pv_segment2            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     1) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     2) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                1) - 1),
                                              pv_segment3            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     2) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     3) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                2) - 1),
                                              pv_segment4            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     3) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     4) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                3) - 1),
                                              pv_segment5            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     4) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     5) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                4) - 1),
                                              pv_segment6            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     5) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     6) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                5) - 1),
                                              pv_segment7            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     6) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     7) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                6) - 1),
                                              pv_segment8            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     7) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     8) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                7) - 1),
                                              pv_segment9            => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     8) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     9) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                '.',
                                                                                                1,
                                                                                                8) - 1),
                                              pv_segment10           => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     9) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 9) - 1),
                                              pv_segment11           => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) - instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 10) - 1),
                                              pv_segment12           => substr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) + 1,
                                                                               length(ligne_rec.ENCAISSEMENT_NON_LETTRE) -
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_LETTRE,
                                                                                     '.',
                                                                                     1,
                                                                                     11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');
      
        l_bank_acct_use_rec.unapplied_ccid := pn_code_combination_id;
      
        Fnd_File.put_line(Fnd_File.LOG, pv_errbuf);
        pn_code_combination_id := NULL;
      
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               0,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1) - 1),
                                              pv_segment2            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     1) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     2) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                1) - 1),
                                              pv_segment3            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     2) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     3) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                2) - 1),
                                              pv_segment4            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     3) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     4) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                3) - 1),
                                              pv_segment5            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     4) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     5) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                4) - 1),
                                              pv_segment6            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     5) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     6) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                5) - 1),
                                              pv_segment7            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     6) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     7) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                6) - 1),
                                              pv_segment8            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     7) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     8) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                7) - 1),
                                              pv_segment9            => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     8) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     9) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                '.',
                                                                                                1,
                                                                                                8) - 1),
                                              pv_segment10           => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     9) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 9) - 1),
                                              pv_segment11           => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     10) + 1,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) - instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                                 '.',
                                                                                                 1,
                                                                                                 10) - 1),
                                              pv_segment12           => substr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     11) + 1,
                                                                               length(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE) -
                                                                               instr(ligne_rec.ENCAISSEMENT_NON_IDENTIFIE,
                                                                                     '.',
                                                                                     1,
                                                                                     11)),
                                              pn_code_combination_id => pn_code_combination_id,
                                              pv_errbuf              => pv_errbuf,
                                              pn_retcode             => pn_retcode,
                                              pv_validation_flag     => 'Y');
      
        l_bank_acct_use_rec.unidentified_ccid := pn_code_combination_id;
      
        Fnd_File.put_line(Fnd_File.LOG, pv_errbuf);
        pn_code_combination_id := NULL;
      
      END;
    
      l_bank_acct_use_rec.xtr_asset_ccid     := null;
      l_bank_acct_use_rec.cash_clearing_ccid := null;
      l_bank_acct_use_rec.bank_charges_ccid  := null;
      l_bank_acct_use_rec.bank_errors_ccid   := null;
      /*      l_bank_acct_use_rec.gain_code_combination_id   := fnd_flex_ext.get_ccid('SQLGL',
      'GL#',
      101,
      SYSDATE,
      ligne_rec.GAIN_DE_CHANGE);*/
      /*      l_bank_acct_use_rec.loss_code_combination_id   := fnd_flex_ext.get_ccid('SQLGL',
      'GL#',
      101,
      SYSDATE,
      ligne_rec.PERTE_DE_CHANGE);*/
      /*      l_bank_acct_use_rec.on_account_ccid            := fnd_flex_ext.get_ccid('SQLGL',
      'GL#',
      101,
      SYSDATE,
      ligne_rec.ENCAISSEMENT_EN_COMPTE);*/
      /*      l_bank_acct_use_rec.unapplied_ccid             := fnd_flex_ext.get_ccid('SQLGL',
      'GL#',
      101,
      SYSDATE,
      ligne_rec.ENCAISSEMENT_NON_LETTRE);*/
      l_bank_acct_use_rec.unidentified_ccid          := fnd_flex_ext.get_ccid('SQLGL',
                                                                              'GL#',
                                                                              101,
                                                                              SYSDATE,
                                                                              ligne_rec.ENCAISSEMENT_NON_IDENTIFIE);
      l_bank_acct_use_rec.factor_ccid                := null;
      l_bank_acct_use_rec.receipt_clearing_ccid      := null;
      l_bank_acct_use_rec.remittance_ccid            := null;
      l_bank_acct_use_rec.ar_short_term_deposit_ccid := null;
      l_bank_acct_use_rec.br_short_term_deposit_ccid := null;
      l_bank_acct_use_rec.future_dated_payment_ccid  := null;
      l_bank_acct_use_rec.br_remittance_ccid         := null;
      l_bank_acct_use_rec.br_factor_ccid             := null;
      l_bank_acct_use_rec.bank_interest_expense_ccid := null;
      l_bank_acct_use_rec.bank_interest_income_ccid  := null;
      --l_bank_acct_use_rec.created_by := 1180;
      --l_bank_acct_use_rec.creation_date := sysdate;
      --l_bank_acct_use_rec.last_update_date := sysdate;
      --l_bank_acct_use_rec.last_updated_by := 1180;
    
      ce_bank_pub.create_bank_acct_use(p_init_msg_list => FND_API.G_TRUE,
                                       p_acct_use_rec  => l_bank_acct_use_rec,
                                       x_acct_use_id   => l_acct_use_id,
                                       x_return_status => l_return_status,
                                       x_msg_count     => l_msg_count,
                                       x_msg_data      => l_msg_data);
      if l_return_status <> FND_API.g_ret_sts_success or l_acct_id is null then
        --dbms_output.put_line('Erreur lors de la création de l''affectation du compte bancaire : ' || replace(l_msg_data, chr(0), '|'));
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                          'Erreur lors de la création de l''affectation du compte bancaire : ' ||
                          replace(l_msg_data, chr(0), '|'));
        -- artf2223171 - Correction suite à la création de nouveaux comptes 
         Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || ligne_rec.rid);
      else
        --dbms_output.put_line('Affectation de comtpe compte bancaire créée. acct_use_id=' || l_acct_use_id);
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                          'Affectation de comtpe compte bancaire créée. acct_use_id=' || l_acct_use_id);
      end if;
    
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQLERRM);
      p_ret_code := 2;
      --dbms_output.put_line(SQLERRM);
  
  END main;

END DKA_CREATE_ACCOUNT_PKG;
/
SHOW ERRORS;
EXIT
