CREATE OR REPLACE PACKAGE DKA_CREATE_ACCOUNT_PKG IS

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
  *************************************************************************/

  -- Public Global Types
  --
  -- Public Global Constants
  --
  -- Public Global Variables
  --
  -- Public Program Units
  --

  TYPE BankAcct_rec_type IS RECORD(
    bank_account_id                NUMBER(15), -- required for update
    branch_id                      NUMBER(15), -- required for create
    bank_id                        NUMBER(15),
    account_owner_party_id         NUMBER(15),
    account_owner_org_id           NUMBER(15), -- required for create (cannot be updated)
    account_classification         VARCHAR2(30), -- required
    bank_account_name              VARCHAR2(80), -- required
    bank_account_num               VARCHAR2(100), -- required
    currency                       VARCHAR2(15),
    iban                           VARCHAR2(50),
    check_digits                   VARCHAR2(30),
    eft_requester_id               VARCHAR2(25),
    secondary_account_reference    VARCHAR2(30),
    multi_currency_allowed_flag    VARCHAR2(1),
    alternate_acct_name            VARCHAR2(320),
    short_account_name             VARCHAR2(30),
    acct_type                      VARCHAR2(25),
    acct_suffix                    VARCHAR2(30),
    description_code1              VARCHAR2(60),
    description_code2              VARCHAR2(60),
    description                    VARCHAR2(240),
    agency_location_code           VARCHAR2(30),
    ap_use_allowed_flag            VARCHAR2(1),
    ar_use_allowed_flag            VARCHAR2(1),
    xtr_use_allowed_flag           VARCHAR2(1),
    pay_use_allowed_flag           VARCHAR2(1),
    payment_multi_currency_flag    VARCHAR2(1),
    receipt_multi_currency_flag    VARCHAR2(1),
    zero_amount_allowed            VARCHAR2(1),
    max_outlay                     NUMBER(15),
    max_check_amount               NUMBER(15),
    min_check_amount               NUMBER, -- Bug 9665618
    ap_amount_tolerance            NUMBER(15),
    ar_amount_tolerance            NUMBER(15),
    xtr_amount_tolerance           NUMBER(15),
    pay_amount_tolerance           NUMBER(15),
    ce_amount_tolerance            NUMBER(15),
    ap_percent_tolerance           NUMBER(15),
    ar_percent_tolerance           NUMBER(15),
    xtr_percent_tolerance          NUMBER(15),
    pay_percent_tolerance          NUMBER(15),
    ce_percent_tolerance           NUMBER(15),
    start_date                     DATE,
    end_date                       DATE,
    account_holder_name_alt        VARCHAR2(150),
    account_holder_name            VARCHAR2(240),
    cashflow_display_order         NUMBER(15),
    pooled_flag                    VARCHAR2(1),
    min_target_balance             NUMBER(15),
    max_target_balance             NUMBER(15),
    eft_user_num                   VARCHAR2(30),
    masked_account_num             VARCHAR2(100),
    masked_iban                    VARCHAR2(50),
    interest_schedule_id           NUMBER(15),
    asset_code_combination_id      NUMBER(15),
    cash_clearing_ccid             NUMBER(15),
    bank_charges_ccid              NUMBER(15),
    bank_errors_ccid               NUMBER(15),
    cashpool_min_payment_amt       NUMBER,
    cashpool_min_receipt_amt       NUMBER,
    cashpool_round_factor          NUMBER(15),
    cashpool_round_rule            VARCHAR2(4),
    attribute_category             VARCHAR2(150),
    attribute1                     VARCHAR2(150),
    attribute2                     VARCHAR2(150),
    attribute3                     VARCHAR2(150),
    attribute4                     VARCHAR2(150),
    attribute5                     VARCHAR2(150),
    attribute6                     VARCHAR2(150),
    attribute7                     VARCHAR2(150),
    attribute8                     VARCHAR2(150),
    attribute9                     VARCHAR2(150),
    attribute10                    VARCHAR2(150),
    attribute11                    VARCHAR2(150),
    attribute12                    VARCHAR2(150),
    attribute13                    VARCHAR2(150),
    attribute14                    VARCHAR2(150),
    attribute15                    VARCHAR2(150),
    xtr_bank_account_reference     VARCHAR2(20),
    netting_acct_flag              VARCHAR2(1), -- 22524647
    recon_enable_oi_flag           VARCHAR2(1), -- 22524647
    recon_foreign_bank_xrate_type  VARCHAR2(30), -- 22524647
    recon_for_bank_xrate_date_type VARCHAR2(10), -- 22524647
    recon_oi_amount_tolerance      NUMBER, -- 22524647
    recon_oi_percent_tolerance     NUMBER -- 22524647
    );

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
  * p_owner
  *************************************************************************/

  PROCEDURE main(p_err_buf OUT VARCHAR2, p_ret_code OUT VARCHAR2, p_owner IN VARCHAR2);

END DKA_CREATE_ACCOUNT_PKG;
/
SHOW ERRORS PACKAGE DKA_REPAPFRSIMP_PKG;
EXIT
