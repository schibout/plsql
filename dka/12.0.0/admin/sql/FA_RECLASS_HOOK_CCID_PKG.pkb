create or replace package body FA_RECLASS_HOOK_CCID_PKG as
  ----------------------------------------------------------------------------------------------
  -- NOM               : FA_RECLASS_HOOK_CCID_PKG.pkb
  -- DESCRIPTION       : FA_RECLASS_HOOK_CCID_PKG package body : Pour lancer generator compte FA
  --                     Au niveau de l ecran des immobilisations
  ---
  --- AUTEUR           : RBELAYAC
  --- DATE DE CREATION : 22/05/2018
  --- DOC. ASSOCIEE    :
  ---
  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --  22/05/2018 RBE artf2413227: INC0193633 - FA erreur lors du changement de catégorie 
  ----------------------------------------------------------------------------------------------
  
  /* $Header: FARCLCIDB.pls 120.0.12020000.2 2013/02/28 13:57:41 rmandali noship $ */

  -- Private type declarations

  -- Private constant declarations

  -- Private variable declarations

  -- Function and procedure implementations
  FUNCTION GET_NEW_CCID(p_trans_rec          IN      FA_API_TYPES.trans_rec_type
                       ,p_asset_hdr_rec      IN      FA_API_TYPES.asset_hdr_rec_type
                       ,p_asset_cat_rec_new  IN      FA_API_TYPES.asset_cat_rec_type
                       ,p_dist_rec_old       IN      FA_API_TYPES.asset_dist_rec_type
                       ,p_dist_rec_new       IN      FA_API_TYPES.asset_dist_rec_type
                       ,p_expense_ccid       OUT     NOCOPY NUMBER
                       ,p_log_level_rec      IN      FA_API_TYPES.log_level_rec_type default null)  return boolean is

/*** Asset Level ***/
X_flex_account_type  varchar2(30) := 'DEPRN_EXP'; -- Dotation aux amortissements

X_book_type_code        varchar2(30) := p_asset_hdr_rec.book_type_code ;
X_distribution_id       number(15) := p_dist_rec_new.distribution_id ;

X_account_level         varchar2(30);

X_dist_ccid             number(15);
X_default_ccid          number(15);

X_dist_ccid_segts       varchar2 (240);
X_default_ccid_segts    varchar2 (240);

X_flex_num              number;
X_acct_segval           varchar2(30) := Null;
X_account_ccid          number       := Null;
X_return_ccid           number;
itemtype                varchar2(30) := 'FAFLEXWF';
itemKey                 varchar2(30);
h_concat_segs           varchar2(2000);
h_concat_ids            varchar2(2000);
h_concat_descrs         varchar2(2000);
h_errmsg                varchar2(2000);
h_encoded_msg           varchar2(4000);
result                  boolean;
h_return_ccid           number;
char_date               varchar2(27);

h_appl_short_name       varchar2(300);
h_message_name          varchar2(300);
h_num                   number;
h_string                varchar2(1000);

BEGIN
    /*
       Points to remember :
         1. implement desired logic to do segment overlay including you custom initial character match to cost center.
         2. raise an exception if the ccid generation fails (causing the transaction to fail).
         3. insure raised the exception, pop a message on the stack (using FA's message stack) so as to explain to the user what happened
         4. Code logic to populate p_expense_ccid
    */
 BEGIN
    --
    --Pour prendre en compte la nouvelle categorie
    --
    update fa_additions_b 
    set asset_category_id = p_asset_cat_rec_new.category_id
    where asset_id = p_asset_hdr_rec.asset_id;
      
    --
    -- Initialisation des variables
    --
    Select fdh.code_combination_id,
           gcc.concatenated_segments
    Into X_dist_ccid,
         X_dist_ccid_segts
    From fa_distribution_history fdh,
         gl_code_combinations_kfv gcc
    Where fdh.distribution_id = X_distribution_id
      And gcc.code_combination_id = fdh.code_combination_id;
    
    Dbms_Output.Put_line ('X_dist_ccid : ' || To_Char (X_dist_ccid));
    Dbms_Output.Put_line (X_dist_ccid_segts);
    Dbms_Output.Put_line ('');

    Select fbc.flexbuilder_defaults_ccid,
           gcc.concatenated_segments
    Into X_default_ccid,
         X_default_ccid_segts
    From fa_book_controls fbc,
         gl_code_combinations_kfv gcc
    Where fbc.book_type_code = X_book_type_code
      And gcc.code_combination_id = fbc.flexbuilder_defaults_ccid;

    Dbms_Output.Put_line ('X_default_ccid : ' || To_Char (X_default_ccid));
    Dbms_Output.Put_line (X_default_ccid_segts);
    Dbms_Output.Put_line ('');
    
    If X_flex_account_type In ('DEPRN_EXP')
    Then
        X_account_level := 'Asset Level';
    End If;

    --
    -- Fin initialisation variables
    --
     fnd_flex_workflow.debug_on;

     /* added for BUG# 1735689 to be consistent with 11.0 */
     select accounting_flex_structure,
            flexbuilder_defaults_ccid
      into  X_flex_num,
            X_default_ccid
      from  fa_book_controls
     where  book_Type_code=X_book_type_code;

     itemkey := FND_FLEX_WORKFLOW.INITIALIZE
                ('SQLGL',
                   'GL#',
                  X_flex_num,
                      'FAFLEXWF'
                 );
      /* Initialize the workflow item attributes  */

      wf_engine.SetItemAttrText(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    =>'BOOK_TYPE_CODE',
                                avalue   =>X_book_type_code);

      wf_engine.SetItemAttrText(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    =>'ACCOUNT_TYPE',
                                avalue   =>X_flex_account_type);
      wf_engine.SetItemAttrNumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    =>'CHART_OF_ACCOUNTS_ID',
                                avalue   =>X_flex_num);

      wf_engine.SetItemAttrNumber(itemtype => itemtype,
                                   itemkey => itemkey,
                                   aname   => 'DISTRIBUTION_CCID',
                                   avalue  =>  X_dist_ccid );

      wf_engine.SetItemAttrText(itemtype => itemtype,
                                   itemkey => itemkey,
                                   aname   => 'ACCT_SEG_VAL',
                                   avalue  =>  X_acct_segval);
      wf_engine.SetItemAttrNumber(itemtype => itemtype,
                                   itemkey => itemkey,
                                   aname   => 'DEFAULT_CCID',
                                   avalue  =>  X_default_ccid);
      wf_engine.SetItemAttrNumber(itemtype => itemtype,
                                   itemkey => itemkey,
                                   aname   => 'ACCOUNT_CCID',
                                   avalue  =>  X_account_ccid);
      wf_engine.SetItemAttrNumber(itemtype => itemtype,
                                   itemkey => itemkey,
                                   aname   => 'DISTRIBUTION_ID',
                                   avalue  =>  X_distribution_id);
                                   

      result := FND_FLEX_WORKFLOW.GENERATE('FAFLEXWF',
                    itemkey,
                    h_return_ccid,
                    h_concat_segs,
                    h_concat_ids,
                    h_concat_descrs,
                    h_errmsg);
      IF (not result) THEN
        dbms_output.put_line('Failed to Generate CCID');
        dbms_output.put_line('Segments   : ' || h_concat_segs);

      /* BUG# 1504839
       *  enhancing the messaging here for fagda and for form level
       *  transactions.  Now dump the concatonated segs and the FND
       *  error returned in encoded format from Workflow
       *    -- bridgway 04/12/01
       */

      FND_MESSAGE.PARSE_ENCODED
                         (ENCODED_MESSAGE   => h_errmsg, --h_encoded_msg,
                          APP_SHORT_NAME    => h_appl_short_name,
                          MESSAGE_NAME      => h_message_name);
  
      dbms_output.put_line('Error Message: ' || h_message_name);

      if (h_message_name = 'FLEX-EXCLUDED BY XVAL RULE' or
          h_message_name = 'FLEX-EXCLUDED BY SEC. RULE') then
  
          h_num    := INSTR(h_errmsg, 'MESSAGE', 1);
          h_num    := h_num + 8;
          h_string := substr(h_errmsg, h_num);
          h_string := ltrim(rtrim(h_string));
  
          dbms_output.put_line('XVAL Message: ' || h_string);
  
      elsif (h_message_name = 'FLEX-VALUE IS DISABLED') then
  
          h_num    := INSTR(h_errmsg, 'VALUE', 16);
          h_num    := h_num + 6;
          h_string := substr(h_errmsg, h_num);
          h_string := ltrim(rtrim(h_string));
  
           dbms_output.put_line('Value: ' || h_string);
  
      else
          null;
      end if;

      /* end BUG# 1504839 */
    END IF;
 
    if (h_return_ccid = -1) then
       select to_char(sysdate,'DD-MON-YYYY')
       into char_date
       from dual;
       h_return_ccid := FND_FLEX_EXT.get_ccid(
                   'SQLGL',
                   'GL#',
                    X_flex_num,
                    char_date,
                       h_concat_segs);
          if (h_return_ccid = 0 ) then
           dbms_output.put_line('Failed to generate CCID');
             FND_MESSAGE.SET_ENCODED(h_errmsg);
             h_encoded_msg := FND_MESSAGE.GET_ENCODED;
             FA_SRVR_MSG.ADD_MESSAGE
          (CALLING_FN=>'FAFLEX_PKG_WF.START_PROCESS',
               NAME=>h_encoded_msg);
             --return;
          END IF;
    END IF; /* if h_return_ccid = -1  */
  
    --
    --Retourner le code ccid generé
    --
    p_expense_ccid := h_return_ccid;
    
    dbms_output.put_line('Success');
    dbms_output.put_line('CCID is :' || to_char(h_return_ccid));
    dbms_output.put_line('Segments   : ' || h_concat_segs);

    exception
      when others then
      ROLLBACK;
      wf_core.context('FA_FLEX_PKG','StartProcess',X_book_type_code,X_dist_ccid,X_default_ccid,'FAFLEXWF');
      raise;
                
    END ; 

    RETURN (TRUE);

  EXCEPTION
     WHEN OTHERS THEN
        ROLLBACK;
        fa_srvr_msg.add_sql_error(
             calling_fn => 'FA_RECLASS_HOOK_CCID_PKG.GET_NEW_CCID', p_log_level_rec => p_log_level_rec);
         RETURN (FALSE);

  END;

END FA_RECLASS_HOOK_CCID_PKG;
/
SHOW ERRORS
EXIT;