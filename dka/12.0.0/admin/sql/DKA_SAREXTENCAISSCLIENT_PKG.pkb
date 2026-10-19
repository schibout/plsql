CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAREXTENCAISSCLIENT_PKG AS
  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : Projet Hèlios
  -- NOM              : DKA_SAREXTENCAISSCLIENT_PKG
  -- DESCRIPTION      : DKA_SAREXTENCAISSCLIENT_PKG Package Body
  --
  -- AUTEUR           : Saloua HA(Capgemini)
  -- DATE DE CREATION : 24/10/2023
  -- COMMENTAIRES     : A exècuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- -----------------------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  /*
*************************************************************************
* PROCEDURE NAME : Output_Header
*
* DESCRIPTION
*  Procèdure pour insèrer une en-tète dans le fichier de sortie
*
* PARAMETERS
* ==========
* NAME              DESCRIPTION
* ----------------- ------------------------------------------------------
*
*
************************************************************************
*/



  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (1000);
         BEGIN

        cv_line    := '+-----------------------------------------------------------------------------------------------------------------+';




        Fnd_File.put_line (Fnd_File.output, cv_line );
        Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT : DKA : Extraction des encaissements clients');
        Fnd_File.put_line (Fnd_File.output, 'Traitement : '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END output_header;

/*
*************************************************************************
* PROCEDURE NAME : Output_End
*
* DESCRIPTION
*  Procèdure pour insèrer une fin dans le fichier de sortie
*
* PARAMETERS
* ==========
* NAME              DESCRIPTION
* ----------------- ------------------------------------------------------
*
*
************************************************************************
*/

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '---------------------------------------------------------------------------';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;



  -- -----------------------------------------------------------------------------
  -- Nom              : Extraction_encaissements_clients
  -- Description      : Extraction des encaissements clients pour la gènèration du fichier de
  --                    sortie
  --
  -- PARAMETRES       : Pv_Errbuf              Sortie Message d'erreur
  --                    Pn_Retcode             Sortie Code Retour de la procèdure
  --                                                  '0' : Normal
  --                                                  '1' : Avertissement
  --                                                  '2' : Erreur
  --                    Pv_Debug_Mode Entrèe          Mode debug
  --                    Pv_Region     Entrèe          Centre de gestion
  --                    Pv_Periode    Entrèe          Pèriode
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Extraction_encaissements_clients
            (pv_errbuf  OUT VARCHAR2,
             pn_retcode OUT NUMBER,
             pn_date_pivot IN OUT VARCHAR2,
             pn_nb_lignes_ec    IN OUT NUMBER
            ) IS

    e_file EXCEPTION;

    ------------------------------------------------------------------
    -- Curseur d'extraction  --
    ------------------------------------------------------------------

    CURSOR cur_extract_encaissement  IS


SELECT DISTINCT
  substr(hou.name, 4, 4) ||'_'||substr(hou.name, 1, 3)||'_'||acr.cash_receipt_id ||'_'|| acrh.cash_receipt_history_id IDENTIFIANT_AR
--,ps.AMOUNT_DUE_REMAINING
--,ps.AMOUNT_APPLIED
  ,acr.cash_receipt_id CASH_RECEIPT_ID
  ,acrh.cash_receipt_history_id CASH_RECEIPT_HISTORY_ID
  ,gl.name NOM_SOCIETE
  ,substr(hou.name, 4, 4) CODE_SOCIETE
  ,substr(hou.name, 1, 3) REGION
  ,hou.name UO
  ,arcs.NAME CLASSE_DE_REGLEMENT
  ,decode (acr.type ,'CASH', 'Standard','MISC', 'Divers') TYPE_REGLEMENT
  ,rcrm.name MODE_DE_REGLEMENT
--rcrm.RECEIPT_CREATION_RULE_CODE ,
-- arcs.CREATION_METHOD_CODE ,
  ,banque_info.BANK_ACCOUNT_NUM COMPTE_BANCAIRE
  ,banque_info.bank_name BANQUE_REMISE
  ,banque_info.BANK_BRANCH_NAME AGENCE_REMISE
  ,CUST.ACCOUNT_NUMBER   NUM_CLIENT
  ,RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' ')) NOM_CLIENT
  ,SITE_USES.LOCATION CODE_ADRESSE_CLIENT
  , 'CREATION'
        TYPE_ACTION
  ,acr.RECEIPT_NUMBER NUMERO_REGLEMENT
  , acr.AMOUNT MONTANT_REGLEMENT
  ,acr.CURRENCY_CODE DEVISE
  ,acr.COMMENTS COMMENTAIRES_REGLEMENTS
  ,' '  TYPE_MAJ
  , DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.MEANING) MOTIF_ANNULATION
  ,acr.REVERSAL_COMMENTS  COMMENTAIRES_ANNULATION
  ,acr.DOC_SEQUENCE_VALUE NUM_DOCUMENT
  ,trunc(acr.CREATION_DATE) DATE_CREATION_REGLEMENT
  ,acr.RECEIPT_DATE DATE_REGLEMENT
  ,ps.DUE_DATE DATE_EXIGIBILITE
  , case

  when arcs.NAME = 'PRELEVEMENT' then
    to_char(to_date(acr.ATTRIBUTE4,'DD-MON-YY'), 'DD/MM/YYYY')
    else null end DATE_PRELEVEMENT
  , acr.REVERSAL_DATE DATE_ANNULATION_REGLEMENT
  ,  APP.APPLY_DATE DATE_LETTRAGE
  , null DATE_DELETTRAGE
  ,fu.user_name REGLEMENT_CREE_PAR
  ,piece.trx_number NUMERO_PIECE_AR
  ,substr(hou.name, 4, 4)||'_'||piece.return_value||'_'||piece.doc_sequence_value IDENTIFIANT_PIECE_SYRUS
  ,case when folio.concaten_Fact ='OUI'
  then substr(hou.name, 4, 4)||' '|| substr(hou.name, 2, 1)||' '|| piece.trx_number
   else piece.trx_number
     end
   NUM_PIECE_AMONT
  --,ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh.STATUS)
  ,folio.code_folio CODE_FOLIO
  ,folio.description LIBELLE_FOLIO
  ,DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) TYPE_PIECE_AR
  --, app.AMOUNT_APPLIED_FROM MONTANT_PIECE_AR
   ,ps_inv.AMOUNT_DUE_ORIGINAL
    MONTANT_PIECE_AR
--  ,APP.AMOUNT_APPLIED_FROM

  , DECODE (DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING),'Facture',ABS(piece.MONTANT_PIECE_AR),
     'Avoir',piece.MONTANT_PIECE_AR,ABS(piece.MONTANT_PIECE_AR))
   MONTANT_LETTRE
   , 0
    MONTANT_DELETTRE
   , acr.STATUS STATE_DSP
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al.MEANING)
  ,acr.REVERSAL_REASON_CODE REVERSAL_REASON_CODE
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.DESCRIPTION) REVERSAL_REASON_DESCRIPTION
  ,banque_info.bank_account_id
--,app.status

FROM

   ar_cash_receipts_all acr
   ,HZ_CUST_ACCOUNTS CUST
   ,ar_cash_receipt_history_all acrh
   ,ar_cash_receipt_history_all acrh1
   ,hr_operating_units hou
   ,HZ_PARTIES PARTY
   ,gl_ledgers gl
   ,ar_receipt_methods rcrm
   ,AR_RECEIPT_CLASSES arcs
   ,fnd_user             fu
   ,(    SELECT DISTINCT ffvt.description description ,
           ffv.ATTRIBUTE2 concaten_Fact ,
       ffv.flex_value code_folio,
       CTL.customer_trx_id 
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv,
             RA_CUSTOMER_TRX_LINES_all CTL,
             fnd_flex_values_tl  ffvt
       WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         and NVL(CTL.ATTRIBUTE9,'Y') = NVL(ffv.flex_value,'Y')
          AND ffv.enabled_flag = 'Y'
         AND ffv.flex_value_id = ffvt.flex_value_id
           )folio
   ,(
  SELECT  distinct return_value,
    rcta.doc_sequence_value,
    rcta.trx_number,
    araa.CASH_RECEIPT_ID,
    APPLIED_PAYMENT_SCHEDULE_ID,
    --CTL.ATTRIBUTE9 code_folio,
    RCTA.customer_trx_id,
    NVL(araa.AMOUNT_APPLIED_FROM, araa.AMOUNT_APPLIED)MONTANT_PIECE_AR
    , araa.APPLY_DATE
  FROM DKA_STRANSCO_LINES    DSTL,
       DKA_STRANSCO_HEADERS  DSTH,
       AR_CASH_RECEIPTS_ALL            acra,
       AR_RECEIVABLE_APPLICATIONS_ALL  araa,
       RA_CUSTOMER_TRX_ALL             rcta,
       --RA_CUSTOMER_TRX_LINES_all CTL,
       RA_BATCH_SOURCES_all BS

 WHERE  DSTL.SET_ID = DSTH.SET_ID
        and acra.CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID(+)
        --AND araa.display = 'Y'
        AND araa.display = CASE  WHEN acra.status='APP' THEN 'Y' ELSE araa.display END

        AND rcta.CUSTOMER_TRX_ID(+) = araa.APPLIED_CUSTOMER_TRX_ID
       -- AND RCTA.customer_trx_id         = CTL.customer_trx_id(+)
      --  AND CTL.LINE_TYPE              ='LINE'
        AND BS.BATCH_SOURCE_ID  = rcta.BATCH_SOURCE_ID
        and  bs.name like '%'|| DSTL.PARAMS_VALUE ||'%'
        AND DSTH.SET_NAME = 'DKA_TYPE_MVT_AR'
        AND DSTL.ENABLE = 'Y'
    )
   piece
   ,( SELECT        CEA.BANK_ACCOUNT_NUM ,
                    CBB.bank_name ,
                    CBB.BANK_BRANCH_NAME ,
                    acr1.cash_receipt_id,
                    arma.org_id,
                    cea.bank_account_id

                  FROM
                     AR_RECEIPT_METHODS arm1
                    ,ar_cash_receipts_all acr1
                    ,ar_receipt_method_accounts_all arma
                    ,CE_BANK_ACCT_USES_ALL cbaua
                    ,CE_BANK_ACCOUNTS CEA
                    ,ce_bank_branches_v CBB
                   WHERE
                    acr1.receipt_method_id = arma.receipt_method_id
                   AND ARM1.receipt_method_id = ARMA.receipt_method_id
                   AND arma.primary_flag = 'Y'
                   AND arma.REMIT_BANK_ACCT_USE_ID(+) = cbaua.BANK_ACCT_USE_ID
                   AND cbaua.BANK_ACCOUNT_ID = CEA.bank_account_id
                   AND cbb.bank_party_id = cea.bank_id
                   AND cbb.branch_party_id = cea.bank_branch_id
    ) banque_info

   ,HZ_CUST_SITE_USES_ALL SITE_USES
   ,AR_PAYMENT_SCHEDULES_all ps_inv
   ,AR_PAYMENT_SCHEDULES_all ps
  -- ,RA_CUSTOMER_TRX CT
   --RA_CUST_TRX_TYPES CTT ,
   ,AR_LOOKUPS al
   ,AR_LOOKUPS al1
   ,AR_RECEIVABLE_APPLICATIONS_all APP
  WHERE
      acr.cash_receipt_id = acrh.cash_receipt_id
  and acr.cash_receipt_id = acrh1.cash_receipt_id
  AND acr.PAY_FROM_CUSTOMER = CUST.CUST_ACCOUNT_ID (+)
  AND acr.CUSTOMER_SITE_USE_ID = SITE_USES.SITE_USE_ID (+)
-- AND acrh.CASH_RECEIPT_HISTORY_ID = app.CASH_RECEIPT_HISTORY_ID(+)
  AND acr.ORG_ID = SITE_USES.ORG_ID (+)
  and fu.user_id= acr.created_by
  AND app.cash_receipt_id = acr.cash_receipt_id
  and piece.cash_receipt_id =acr.cash_receipt_id
   AND piece.customer_trx_id         = folio.customer_trx_id(+)
 -- and NVL(piece.code_folio,'Y') = NVL(folio.code_folio,'Y')
  and  APP.APPLIED_PAYMENT_SCHEDULE_ID = piece.APPLIED_PAYMENT_SCHEDULE_ID
  AND AL1.LOOKUP_TYPE (+) = 'CKAJST_REASON'
  AND AL1.LOOKUP_CODE (+) = ACR.REVERSAL_REASON_CODE
  --AND PS_INV.ORG_ID(+) = acr.ORG_ID
  --AND CT.CUSTOMER_TRX_ID(+) = PS_INV.CUSTOMER_TRX_ID
  --AND CTT.CUST_TRX_TYPE_ID(+) = PS_INV.CUST_TRX_TYPE_ID
  AND CUST.CUST_ACCOUNT_ID(+) = PS_INV.CUSTOMER_ID
  AND PS.CASH_RECEIPT_ID(+) = acr.CASH_RECEIPT_ID
  AND PS.ORG_ID(+) = acr.ORG_ID
  AND APP.APPLIED_PAYMENT_SCHEDULE_ID = PS_INV.PAYMENT_SCHEDULE_ID
  AND acr.org_id = hou.organization_id
  AND hou.SET_OF_BOOKS_ID =  gl.LEDGER_ID
  AND acr.receipt_method_id = rcrm.receipt_method_id
  AND rcrm.RECEIPT_CLASS_ID = arcs.RECEIPT_CLASS_ID
  AND hou.organization_id = banque_info.org_id(+)
  AND banque_info.cash_receipt_id = acr.cash_receipt_id
  AND CUST.PARTY_ID = PARTY.PARTY_ID(+)
  AND  PS_INV.class = al.LOOKUP_CODE
  AND al.LOOKUP_TYPE = 'INV/CM'
  and acrh.CURRENT_RECORD_FLAG ='Y'
  AND acrh.ORG_ID = acr.ORG_ID
  AND acrh1.ORG_ID = acr.ORG_ID
-- AND acrh1.ORG_ID = acr.ORG_ID
  ------ debut ne pas extraire
  --  Les règlements non identifiès
  and CUST.ACCOUNT_NUMBER  is not null
  and RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' '))  is not null
  --  Les règlements crèès et annulès le mème jour
  AND to_char(acr.CREATION_DATE,'DD/MM/YYYY')!= NVL(acr.REVERSAL_DATE, to_date('01/01/1901','DD/MM/YYYY'))
  --  Les règlements de type DIVERS
  AND acr.type != 'MISC'
  --  Crèation dèun règlement non lettrè quand le montant du règlement = montant non lettrè
  AND ( acr.status !='UNAPP' or acr.AMOUNT != DECODE (acr.status, 'UNAPP', NVL (ps.amount_applied, 0), 0))
  --  Les factures mise en litige
  and not exists (select CTT.NAME  from AR_ADJUSTMENTS_all ADJ ,AR_PAYMENT_SCHEDULES_all PS,RA_CUSTOMER_TRX_all CT, RA_CUST_TRX_TYPES_all CTT,AR_LOOKUPS REASON  
 where PS.CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
  AND CT.REASON_CODE = REASON.LOOKUP_CODE (+)
  AND REASON.LOOKUP_TYPE (+) = 'ADJUST_REASON'
 AND REASON.ENABLED_FLAG (+) = 'Y'
 AND CTT.CUST_TRX_TYPE_ID = CT.CUST_TRX_TYPE_ID
 and ADJ.CHARGEBACK_CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
 AND adj.PAYMENT_SCHEDULE_ID = ps_inv.PAYMENT_SCHEDULE_ID
 and CTT.NAME ='DOUTEUX')
  
  ---Extraire les encaissement client avec mode VIREMENT , CHEQUE ,POUR COMPTE crèè et lettrè le mème jour
 AND 
    arcs.NAME IN ('VIREMENT','POUR_COMPTE','CHEQUE')
    AND trunc(acr.CREATION_DATE) = trunc(app.CREATION_DATE)

    and ( trunc(acr.CREATION_DATE) =  trunc(acr.LAST_UPDATE_DATE)
        or( trunc(acr.CREATION_DATE) <  trunc(acr.LAST_UPDATE_DATE)
            and to_char(app.creation_date ,'YYYYMMDD') =  to_char(acr.CREATION_DATE ,'YYYYMMDD')
    and not exists (select  MATCHING_DATE
     from rb_lines rla
   where rla.bank_account_id            = banque_info.bank_account_id
       and rla.amount                   = acr.amount
     and check_number                 = acr.RECEIPT_NUMBER
       AND RLA.line_type                = 'A'
       and matching_date is not null
       and rla.MATCHING_STATUS = 'Y'
       AND exists (select line_type from rb_lines rla1
                  where  rla.bank_account_id            = rla1.bank_account_id
                         and rla.amount                 = rla1.amount
                         and rla.MATCHING_REF           = rla1.MATCHING_REF
                         and RLA1.line_type                = 'B')



     )
     AND ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) != 'Annulé'
   )
   )
   
  and acr.CREATION_DATE >= to_date(pn_date_pivot , 'DD/MM/YYYY HH24:MI:SS')


union all 



SELECT DISTINCT
--acr.creation_date ,
--app.CREATION_DATE,
--app.APPLY_DATE,
--acrh1.CREATION_DATE,
--acrh1.LAST_UPDATE_DATE,
  substr(hou.name, 4, 4) ||'_'||substr(hou.name, 1, 3)||'_'||acr.cash_receipt_id ||'_'|| acrh.cash_receipt_history_id IDENTIFIANT_AR
--,ps.AMOUNT_DUE_REMAINING
--,ps.AMOUNT_APPLIED
  ,acr.cash_receipt_id CASH_RECEIPT_ID
  ,acrh.cash_receipt_history_id CASH_RECEIPT_HISTORY_ID
  ,gl.name NOM_SOCIETE
  ,substr(hou.name, 4, 4) CODE_SOCIETE
  ,substr(hou.name, 1, 3) REGION
  ,hou.name UO
  ,arcs.NAME CLASSE_DE_REGLEMENT
  ,decode (acr.type ,'CASH', 'Standard','MISC', 'Divers') TYPE_REGLEMENT
  ,rcrm.name MODE_DE_REGLEMENT
--rcrm.RECEIPT_CREATION_RULE_CODE ,
-- arcs.CREATION_METHOD_CODE ,
  ,banque_info.BANK_ACCOUNT_NUM COMPTE_BANCAIRE
  ,banque_info.bank_name BANQUE_REMISE
  ,banque_info.BANK_BRANCH_NAME AGENCE_REMISE
  ,CUST.ACCOUNT_NUMBER   NUM_CLIENT
  ,RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' ')) NOM_CLIENT
  ,SITE_USES.LOCATION CODE_ADRESSE_CLIENT
  , 'CREATION'
        TYPE_ACTION
  ,acr.RECEIPT_NUMBER NUMERO_REGLEMENT
  , acr.AMOUNT MONTANT_REGLEMENT
  ,acr.CURRENCY_CODE DEVISE
  ,acr.COMMENTS COMMENTAIRES_REGLEMENTS
  ,' '  TYPE_MAJ
  , DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.MEANING) MOTIF_ANNULATION
  ,acr.REVERSAL_COMMENTS  COMMENTAIRES_ANNULATION
  ,acr.DOC_SEQUENCE_VALUE NUM_DOCUMENT
  ,trunc(acr.CREATION_DATE) DATE_CREATION_REGLEMENT
  ,acr.RECEIPT_DATE DATE_REGLEMENT
  ,ps.DUE_DATE DATE_EXIGIBILITE
  , case

  when arcs.NAME = 'PRELEVEMENT' then
    to_char(to_date(acr.ATTRIBUTE4,'DD-MON-YY'), 'DD/MM/YYYY')
    else null end DATE_PRELEVEMENT
  , acr.REVERSAL_DATE DATE_ANNULATION_REGLEMENT
  ,  APP.APPLY_DATE DATE_LETTRAGE
  , null DATE_DELETTRAGE
  ,fu.user_name REGLEMENT_CREE_PAR
  ,piece.trx_number NUMERO_PIECE_AR
  ,substr(hou.name, 4, 4)||'_'||piece.return_value||'_'||piece.doc_sequence_value IDENTIFIANT_PIECE_SYRUS
  ,case when folio.concaten_Fact ='OUI'
  then substr(hou.name, 4, 4)||' '|| substr(hou.name, 2, 1)||' '|| piece.trx_number
   else piece.trx_number
     end
   NUM_PIECE_AMONT
  --,ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh.STATUS)
  ,folio.code_folio CODE_FOLIO
  ,folio.description LIBELLE_FOLIO
  ,DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) TYPE_PIECE_AR
  --, app.AMOUNT_APPLIED_FROM MONTANT_PIECE_AR
   ,ps_inv.AMOUNT_DUE_ORIGINAL
    MONTANT_PIECE_AR
--  ,APP.AMOUNT_APPLIED_FROM

  , DECODE (DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING),'Facture',ABS(piece.MONTANT_PIECE_AR),
     'Avoir',piece.MONTANT_PIECE_AR,ABS(piece.MONTANT_PIECE_AR))
   MONTANT_LETTRE
   , 0
    MONTANT_DELETTRE
   , acr.STATUS STATE_DSP
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al.MEANING)
  ,acr.REVERSAL_REASON_CODE REVERSAL_REASON_CODE
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.DESCRIPTION) REVERSAL_REASON_DESCRIPTION
  ,banque_info.bank_account_id
--,app.status

FROM

   ar_cash_receipts_all acr
   ,HZ_CUST_ACCOUNTS CUST
   ,ar_cash_receipt_history_all acrh
   ,ar_cash_receipt_history_all acrh1
   ,hr_operating_units hou
   ,HZ_PARTIES PARTY
   ,gl_ledgers gl
   ,ar_receipt_methods rcrm
   ,AR_RECEIPT_CLASSES arcs
   ,fnd_user             fu
   ,(    SELECT DISTINCT ffvt.description description ,
           ffv.ATTRIBUTE2 concaten_Fact ,
       ffv.flex_value code_folio,
       CTL.customer_trx_id 
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv,
             RA_CUSTOMER_TRX_LINES_all CTL,
             fnd_flex_values_tl  ffvt
       WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         and NVL(CTL.ATTRIBUTE9,'Y') = NVL(ffv.flex_value,'Y')
          AND ffv.enabled_flag = 'Y'
         AND ffv.flex_value_id = ffvt.flex_value_id
           )folio
   ,(
  SELECT  distinct return_value,
    rcta.doc_sequence_value,
    rcta.trx_number,
    araa.CASH_RECEIPT_ID,
    APPLIED_PAYMENT_SCHEDULE_ID,
    --CTL.ATTRIBUTE9 code_folio,
    RCTA.customer_trx_id,
    NVL(araa.AMOUNT_APPLIED_FROM, araa.AMOUNT_APPLIED)MONTANT_PIECE_AR
    , araa.APPLY_DATE
  FROM DKA_STRANSCO_LINES    DSTL,
       DKA_STRANSCO_HEADERS  DSTH,
       AR_CASH_RECEIPTS_ALL            acra,
       AR_RECEIVABLE_APPLICATIONS_ALL  araa,
       RA_CUSTOMER_TRX_ALL             rcta,
       --RA_CUSTOMER_TRX_LINES_all CTL,
       RA_BATCH_SOURCES_all BS

 WHERE  DSTL.SET_ID = DSTH.SET_ID
        and acra.CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID(+)
        --AND araa.display = 'Y'
        AND araa.display = CASE  WHEN acra.status='APP' THEN 'Y' ELSE araa.display END

        AND rcta.CUSTOMER_TRX_ID(+) = araa.APPLIED_CUSTOMER_TRX_ID
       -- AND RCTA.customer_trx_id         = CTL.customer_trx_id(+)
      --  AND CTL.LINE_TYPE              ='LINE'
        AND BS.BATCH_SOURCE_ID  = rcta.BATCH_SOURCE_ID
        and  bs.name like '%'|| DSTL.PARAMS_VALUE ||'%'
        AND DSTH.SET_NAME = 'DKA_TYPE_MVT_AR'
        AND DSTL.ENABLE = 'Y'
    )
   piece
   ,( SELECT        CEA.BANK_ACCOUNT_NUM ,
                    CBB.bank_name ,
                    CBB.BANK_BRANCH_NAME ,
                    acr1.cash_receipt_id,
                    arma.org_id,
                    cea.bank_account_id

                  FROM
                     AR_RECEIPT_METHODS arm1
                    ,ar_cash_receipts_all acr1
                    ,ar_receipt_method_accounts_all arma
                    ,CE_BANK_ACCT_USES_ALL cbaua
                    ,CE_BANK_ACCOUNTS CEA
                    ,ce_bank_branches_v CBB
                   WHERE
                    acr1.receipt_method_id = arma.receipt_method_id
                   AND ARM1.receipt_method_id = ARMA.receipt_method_id
                   AND arma.primary_flag = 'Y'
                   AND arma.REMIT_BANK_ACCT_USE_ID(+) = cbaua.BANK_ACCT_USE_ID
                   AND cbaua.BANK_ACCOUNT_ID = CEA.bank_account_id
                   AND cbb.bank_party_id = cea.bank_id
                   AND cbb.branch_party_id = cea.bank_branch_id
    ) banque_info

   ,HZ_CUST_SITE_USES_ALL SITE_USES
   ,AR_PAYMENT_SCHEDULES_all ps_inv
   ,AR_PAYMENT_SCHEDULES_all ps
  -- ,RA_CUSTOMER_TRX CT
   --RA_CUST_TRX_TYPES CTT ,
   ,AR_LOOKUPS al
   ,AR_LOOKUPS al1
   ,AR_RECEIVABLE_APPLICATIONS_all APP
  WHERE
      acr.cash_receipt_id = acrh.cash_receipt_id
  and acr.cash_receipt_id = acrh1.cash_receipt_id
  AND acr.PAY_FROM_CUSTOMER = CUST.CUST_ACCOUNT_ID (+)
  AND acr.CUSTOMER_SITE_USE_ID = SITE_USES.SITE_USE_ID (+)
-- AND acrh.CASH_RECEIPT_HISTORY_ID = app.CASH_RECEIPT_HISTORY_ID(+)
  AND acr.ORG_ID = SITE_USES.ORG_ID (+)
  and fu.user_id= acr.created_by
  AND app.cash_receipt_id = acr.cash_receipt_id
  and piece.cash_receipt_id =acr.cash_receipt_id
   AND piece.customer_trx_id         = folio.customer_trx_id(+)
 -- and NVL(piece.code_folio,'Y') = NVL(folio.code_folio,'Y')
  and  APP.APPLIED_PAYMENT_SCHEDULE_ID = piece.APPLIED_PAYMENT_SCHEDULE_ID
  AND AL1.LOOKUP_TYPE (+) = 'CKAJST_REASON'
  AND AL1.LOOKUP_CODE (+) = ACR.REVERSAL_REASON_CODE
  --AND PS_INV.ORG_ID(+) = acr.ORG_ID
  --AND CT.CUSTOMER_TRX_ID(+) = PS_INV.CUSTOMER_TRX_ID
  --AND CTT.CUST_TRX_TYPE_ID(+) = PS_INV.CUST_TRX_TYPE_ID
  AND CUST.CUST_ACCOUNT_ID(+) = PS_INV.CUSTOMER_ID
  AND PS.CASH_RECEIPT_ID(+) = acr.CASH_RECEIPT_ID
  AND PS.ORG_ID(+) = acr.ORG_ID
  AND APP.APPLIED_PAYMENT_SCHEDULE_ID = PS_INV.PAYMENT_SCHEDULE_ID
  AND acr.org_id = hou.organization_id
  AND hou.SET_OF_BOOKS_ID =  gl.LEDGER_ID
  AND acr.receipt_method_id = rcrm.receipt_method_id
  AND rcrm.RECEIPT_CLASS_ID = arcs.RECEIPT_CLASS_ID
  AND hou.organization_id = banque_info.org_id(+)
  AND banque_info.cash_receipt_id = acr.cash_receipt_id
  AND CUST.PARTY_ID = PARTY.PARTY_ID(+)
  AND  PS_INV.class = al.LOOKUP_CODE
  AND al.LOOKUP_TYPE = 'INV/CM'
  and acrh.CURRENT_RECORD_FLAG ='Y'
  AND acrh.ORG_ID = acr.ORG_ID
  AND acrh1.ORG_ID = acr.ORG_ID
-- AND acrh1.ORG_ID = acr.ORG_ID
  ------ debut ne pas extraire
  --  Les règlements non identifiès
  and CUST.ACCOUNT_NUMBER  is not null
  and RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' '))  is not null
  --  Les règlements crèès et annulès le mème jour
  AND to_char(acr.CREATION_DATE,'DD/MM/YYYY')!= NVL(acr.REVERSAL_DATE, to_date('01/01/1901','DD/MM/YYYY'))
  --  Les règlements de type DIVERS
  AND acr.type != 'MISC'
  --  Crèation dèun règlement non lettrè quand le montant du règlement = montant non lettrè
  AND ( acr.status !='UNAPP' or acr.AMOUNT != DECODE (acr.status, 'UNAPP', NVL (ps.amount_applied, 0), 0))
  --  Les factures mise en litige
  and not exists (select CTT.NAME  from AR_ADJUSTMENTS_all ADJ ,AR_PAYMENT_SCHEDULES_all PS,RA_CUSTOMER_TRX_all CT, RA_CUST_TRX_TYPES_all CTT,AR_LOOKUPS REASON  
 where PS.CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
  AND CT.REASON_CODE = REASON.LOOKUP_CODE (+)
  AND REASON.LOOKUP_TYPE (+) = 'ADJUST_REASON'
 AND REASON.ENABLED_FLAG (+) = 'Y'
 AND CTT.CUST_TRX_TYPE_ID = CT.CUST_TRX_TYPE_ID
 and ADJ.CHARGEBACK_CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
 AND adj.PAYMENT_SCHEDULE_ID = ps_inv.PAYMENT_SCHEDULE_ID
 and CTT.NAME ='DOUTEUX')
  
  ---Extraire les encaissement client avec mode VIREMENT , CHEQUE ,POUR COMPTE crèè et lettrè le mème jour
 AND 
    ( arcs.NAME IN ('PRELEVEMENT') and ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Remis en banque' )
    AND trunc(acr.CREATION_DATE) = trunc(app.CREATION_DATE)

    and ( trunc(acr.CREATION_DATE) =  trunc(acr.LAST_UPDATE_DATE)
        or( trunc(acr.CREATION_DATE) <  trunc(acr.LAST_UPDATE_DATE)
            and to_char(app.creation_date ,'YYYYMMDD') =  to_char(acr.CREATION_DATE ,'YYYYMMDD')
    and not exists (select  MATCHING_DATE
     from rb_lines rla
   where rla.bank_account_id            = banque_info.bank_account_id
       and rla.amount                   = acr.amount
     and check_number                 = acr.RECEIPT_NUMBER
       AND RLA.line_type                = 'A'
       and matching_date is not null
       and rla.MATCHING_STATUS = 'Y'
       AND exists (select line_type from rb_lines rla1
                  where  rla.bank_account_id            = rla1.bank_account_id
                         and rla.amount                 = rla1.amount
                         and rla.MATCHING_REF           = rla1.MATCHING_REF
                         and RLA1.line_type                = 'B')



     )
     AND ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) != 'Annulé'
   )
   )
   
  and acrh1.CREATION_DATE >= to_date(pn_date_pivot , 'DD/MM/YYYY HH24:MI:SS')
  
  union all 
SELECT DISTINCT
  substr(hou.name, 4, 4) ||'_'||substr(hou.name, 1, 3)||'_'||acr.cash_receipt_id ||'_'|| acrh.cash_receipt_history_id IDENTIFIANT_AR
--,ps.AMOUNT_DUE_REMAINING
--,ps.AMOUNT_APPLIED
  ,acr.cash_receipt_id CASH_RECEIPT_ID
  ,acrh.cash_receipt_history_id CASH_RECEIPT_HISTORY_ID
  ,gl.name NOM_SOCIETE
  ,substr(hou.name, 4, 4) CODE_SOCIETE
  ,substr(hou.name, 1, 3) REGION
  ,hou.name UO
  ,arcs.NAME CLASSE_DE_REGLEMENT
  ,decode (acr.type ,'CASH', 'Standard','MISC', 'Divers') TYPE_REGLEMENT
  ,rcrm.name MODE_DE_REGLEMENT
--rcrm.RECEIPT_CREATION_RULE_CODE ,
-- arcs.CREATION_METHOD_CODE ,
  ,banque_info.BANK_ACCOUNT_NUM COMPTE_BANCAIRE
  ,banque_info.bank_name BANQUE_REMISE
  ,banque_info.BANK_BRANCH_NAME AGENCE_REMISE
  ,CUST.ACCOUNT_NUMBER   NUM_CLIENT
  ,RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' ')) NOM_CLIENT
  ,SITE_USES.LOCATION CODE_ADRESSE_CLIENT
  ,case when not exists (select  MATCHING_DATE
     from rb_lines rla
   where rla.bank_account_id            = banque_info.bank_account_id
       and rla.amount                   = acr.amount
     and check_number                 = acr.RECEIPT_NUMBER
       AND RLA.line_type                = 'A'
       and matching_date is not null
       and rla.MATCHING_STATUS = 'Y'
       AND exists (select line_type from rb_lines rla1
                  where  rla.bank_account_id            = rla1.bank_account_id
                         and rla.amount                 = rla1.amount
                         and rla.MATCHING_REF           = rla1.MATCHING_REF
                         and RLA1.line_type                = 'B'))
     then 'CREATION'
       else
         'MAJ' end  TYPE_ACTION
  ,acr.RECEIPT_NUMBER NUMERO_REGLEMENT
  , acr.AMOUNT MONTANT_REGLEMENT
  ,acr.CURRENCY_CODE DEVISE
  ,acr.COMMENTS COMMENTAIRES_REGLEMENTS
  ,case when not exists (select  MATCHING_DATE
     from rb_lines rla
   where rla.bank_account_id            = banque_info.bank_account_id
       and rla.amount                   = acr.amount
     and check_number                 = acr.RECEIPT_NUMBER
       AND RLA.line_type                = 'A'
       and matching_date is not null
       and rla.MATCHING_STATUS = 'Y'
       AND exists (select line_type from rb_lines rla1
                  where  rla.bank_account_id            = rla1.bank_account_id
                         and rla.amount                 = rla1.amount
                         and rla.MATCHING_REF           = rla1.MATCHING_REF
                         and RLA1.line_type                = 'B')
     )
     then ' '
       else
         'RAPPROCHEMENT BANCAIRE'
         END  TYPE_MAJ
  , DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.MEANING) MOTIF_ANNULATION
  ,acr.REVERSAL_COMMENTS  COMMENTAIRES_ANNULATION
  ,acr.DOC_SEQUENCE_VALUE NUM_DOCUMENT
  ,trunc(acr.CREATION_DATE) DATE_CREATION_REGLEMENT
  ,acr.RECEIPT_DATE DATE_REGLEMENT
  ,ps.DUE_DATE DATE_EXIGIBILITE
  , case

  when arcs.NAME = 'PRELEVEMENT' then
    to_char(to_date(acr.ATTRIBUTE4,'DD-MON-YY'), 'DD/MM/YYYY')
    else null end DATE_PRELEVEMENT
  , acr.REVERSAL_DATE DATE_ANNULATION_REGLEMENT
  ,  APP.APPLY_DATE DATE_LETTRAGE
  ,null DATE_DELETTRAGE
  ,fu.user_name REGLEMENT_CREE_PAR
  ,piece.trx_number NUMERO_PIECE_AR
  ,substr(hou.name, 4, 4)||'_'||piece.return_value||'_'||piece.doc_sequence_value IDENTIFIANT_PIECE_SYRUS
  ,case when folio.concaten_Fact ='OUI'
  then substr(hou.name, 4, 4)||' '|| substr(hou.name, 2, 1)||' '|| piece.trx_number
   else piece.trx_number
     end
   NUM_PIECE_AMONT
  --,ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh.STATUS)
  ,folio.code_folio CODE_FOLIO
  ,folio.description LIBELLE_FOLIO
  ,DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) TYPE_PIECE_AR
  --, app.AMOUNT_APPLIED_FROM MONTANT_PIECE_AR
   ,ps_inv.AMOUNT_DUE_ORIGINAL
    MONTANT_PIECE_AR
--  ,APP.AMOUNT_APPLIED_FROM

  ,DECODE (DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING),'Facture',ABS(piece.MONTANT_PIECE_AR),
     'Avoir',piece.MONTANT_PIECE_AR,ABS(piece.MONTANT_PIECE_AR))
   MONTANT_LETTRE
   , 0 MONTANT_DELETTRE
   , acr.STATUS STATE_DSP
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al.MEANING)
  ,acr.REVERSAL_REASON_CODE REVERSAL_REASON_CODE
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.DESCRIPTION) REVERSAL_REASON_DESCRIPTION
  ,banque_info.bank_account_id

FROM

   ar_cash_receipts_all acr
   ,HZ_CUST_ACCOUNTS CUST
   ,ar_cash_receipt_history_all acrh
   ,ar_cash_receipt_history_all acrh1
   ,hr_operating_units hou
   ,HZ_PARTIES PARTY
   ,gl_ledgers gl
   ,ar_receipt_methods rcrm
   ,AR_RECEIPT_CLASSES arcs
   ,fnd_user             fu
   ,DKA_RB_LINES T
   ,(    SELECT DISTINCT ffvt.description description ,
           ffv.ATTRIBUTE2 concaten_Fact ,
       ffv.flex_value code_folio,
       CTL.customer_trx_id 
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv,
             RA_CUSTOMER_TRX_LINES_all CTL,
             fnd_flex_values_tl  ffvt
       WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         and NVL(CTL.ATTRIBUTE9,'Y') = NVL(ffv.flex_value,'Y')
          AND ffv.enabled_flag = 'Y'
         AND ffv.flex_value_id = ffvt.flex_value_id
           )folio
   ,(
  SELECT  distinct return_value,
    rcta.doc_sequence_value,
    rcta.trx_number,
    araa.CASH_RECEIPT_ID,
    APPLIED_PAYMENT_SCHEDULE_ID,
    --CTL.ATTRIBUTE9 code_folio,
    RCTA.customer_trx_id,
    NVL(araa.AMOUNT_APPLIED_FROM, araa.AMOUNT_APPLIED)MONTANT_PIECE_AR
    , araa.APPLY_DATE
  FROM DKA_STRANSCO_LINES    DSTL,
       DKA_STRANSCO_HEADERS  DSTH,
       AR_CASH_RECEIPTS_ALL            acra,
       AR_RECEIVABLE_APPLICATIONS_ALL  araa,
       RA_CUSTOMER_TRX_ALL             rcta,
       --RA_CUSTOMER_TRX_LINES_all CTL,
       RA_BATCH_SOURCES_all BS

 WHERE  DSTL.SET_ID = DSTH.SET_ID
        and acra.CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID(+)
        --AND araa.display = 'Y'
        AND araa.display = CASE  WHEN acra.status='APP' THEN 'Y' ELSE araa.display END

        AND rcta.CUSTOMER_TRX_ID(+) = araa.APPLIED_CUSTOMER_TRX_ID
       -- AND RCTA.customer_trx_id         = CTL.customer_trx_id(+)
      --  AND CTL.LINE_TYPE              ='LINE'
        AND BS.BATCH_SOURCE_ID  = rcta.BATCH_SOURCE_ID
        and  bs.name like '%'|| DSTL.PARAMS_VALUE ||'%'
        AND DSTH.SET_NAME = 'DKA_TYPE_MVT_AR'
        AND DSTL.ENABLE = 'Y'
    )
   piece
   ,( SELECT        CEA.BANK_ACCOUNT_NUM ,
                    CBB.bank_name ,
                    CBB.BANK_BRANCH_NAME ,
                    acr1.cash_receipt_id,
                    arma.org_id,
                    cea.bank_account_id

                  FROM
                     AR_RECEIPT_METHODS arm1
                    ,ar_cash_receipts_all acr1
                    ,ar_receipt_method_accounts_all arma
                    ,CE_BANK_ACCT_USES_ALL cbaua
                    ,CE_BANK_ACCOUNTS CEA
                    ,ce_bank_branches_v CBB
                   WHERE
                    acr1.receipt_method_id = arma.receipt_method_id
                   AND ARM1.receipt_method_id = ARMA.receipt_method_id
                   AND arma.primary_flag = 'Y'
                   AND arma.REMIT_BANK_ACCT_USE_ID(+) = cbaua.BANK_ACCT_USE_ID
                   AND cbaua.BANK_ACCOUNT_ID = CEA.bank_account_id
                   AND cbb.bank_party_id = cea.bank_id
                   AND cbb.branch_party_id = cea.bank_branch_id
    ) banque_info

   ,HZ_CUST_SITE_USES_ALL SITE_USES
   ,AR_PAYMENT_SCHEDULES_all ps_inv
   ,AR_PAYMENT_SCHEDULES_all ps
  -- ,RA_CUSTOMER_TRX CT
   --RA_CUST_TRX_TYPES CTT ,
   ,AR_LOOKUPS al
   ,AR_LOOKUPS al1
   ,AR_RECEIVABLE_APPLICATIONS_all APP
  WHERE
      acr.cash_receipt_id = acrh.cash_receipt_id
  and acr.cash_receipt_id = acrh1.cash_receipt_id
  AND acr.PAY_FROM_CUSTOMER = CUST.CUST_ACCOUNT_ID (+)
  AND acr.CUSTOMER_SITE_USE_ID = SITE_USES.SITE_USE_ID (+)
-- AND acrh.CASH_RECEIPT_HISTORY_ID = app.CASH_RECEIPT_HISTORY_ID(+)
  AND acr.ORG_ID = SITE_USES.ORG_ID (+)
  and fu.user_id= acr.created_by
  AND app.cash_receipt_id = acr.cash_receipt_id
  and piece.cash_receipt_id =acr.cash_receipt_id
   AND piece.customer_trx_id         = folio.customer_trx_id(+)
 -- and NVL(piece.code_folio,'Y') = NVL(folio.code_folio,'Y')
  and  APP.APPLIED_PAYMENT_SCHEDULE_ID = piece.APPLIED_PAYMENT_SCHEDULE_ID
  AND AL1.LOOKUP_TYPE (+) = 'CKAJST_REASON'
  AND AL1.LOOKUP_CODE (+) = ACR.REVERSAL_REASON_CODE
  --AND PS_INV.ORG_ID(+) = acr.ORG_ID
  --AND CT.CUSTOMER_TRX_ID(+) = PS_INV.CUSTOMER_TRX_ID
  --AND CTT.CUST_TRX_TYPE_ID(+) = PS_INV.CUST_TRX_TYPE_ID
  AND CUST.CUST_ACCOUNT_ID(+) = PS_INV.CUSTOMER_ID
  AND PS.CASH_RECEIPT_ID(+) = acr.CASH_RECEIPT_ID
  AND PS.ORG_ID(+) = acr.ORG_ID
  AND APP.APPLIED_PAYMENT_SCHEDULE_ID = PS_INV.PAYMENT_SCHEDULE_ID
  AND acr.org_id = hou.organization_id
  AND hou.SET_OF_BOOKS_ID =  gl.LEDGER_ID
  AND acr.receipt_method_id = rcrm.receipt_method_id
  AND rcrm.RECEIPT_CLASS_ID = arcs.RECEIPT_CLASS_ID
  AND hou.organization_id = banque_info.org_id(+)
  AND banque_info.cash_receipt_id = acr.cash_receipt_id
  AND CUST.PARTY_ID = PARTY.PARTY_ID(+)
  AND  PS_INV.class = al.LOOKUP_CODE
  AND al.LOOKUP_TYPE = 'INV/CM'
  and acrh.CURRENT_RECORD_FLAG ='Y'
  AND acrh.ORG_ID = acr.ORG_ID
  AND acrh1.ORG_ID = acr.ORG_ID
-- AND acrh1.ORG_ID = acr.ORG_ID
  ------ debut ne pas extraire
  --  Les règlements non identifiès
  and CUST.ACCOUNT_NUMBER  is not null
  and RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' '))  is not null
  --  Les règlements crèès et annulès le mème jour
  AND to_char(acr.CREATION_DATE,'DD/MM/YYYY')!= NVL(acr.REVERSAL_DATE, to_date('01/01/1901','DD/MM/YYYY'))
  --  Les règlements de type DIVERS
  AND acr.type != 'MISC'
  --  Crèation dèun règlement non lettrè quand le montant du règlement = montant non lettré
 AND ( acr.status !='UNAPP' or acr.AMOUNT != DECODE (acr.status, 'UNAPP', NVL (ps.amount_applied, 0), 0))
  --  Les factures mise en litige
  and not exists (select CTT.NAME  from AR_ADJUSTMENTS_all ADJ ,AR_PAYMENT_SCHEDULES_all PS,RA_CUSTOMER_TRX_all CT, RA_CUST_TRX_TYPES_all CTT,AR_LOOKUPS REASON  
 where PS.CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
  AND CT.REASON_CODE = REASON.LOOKUP_CODE (+)
  AND REASON.LOOKUP_TYPE (+) = 'ADJUST_REASON'
 AND REASON.ENABLED_FLAG (+) = 'Y'
 AND CTT.CUST_TRX_TYPE_ID = CT.CUST_TRX_TYPE_ID
 and ADJ.CHARGEBACK_CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
 AND adj.PAYMENT_SCHEDULE_ID = ps_inv.PAYMENT_SCHEDULE_ID
 and CTT.NAME ='DOUTEUX')
  
  ---Extraire les encaissement client avec mode VIREMENT , CHEQUE ,POUR COMPTE crèè et lettrè le mème jour
  AND((arcs.NAME IN ('VIREMENT','POUR_COMPTE','CHEQUE')--PRELEVEMENT
   AND trunc(acr.CREATION_DATE) = trunc(app.CREATION_DATE)

)

   OR   
    ( 
    (arcs.NAME IN ('PRELEVEMENT') and ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Remis en banque' )
    AND trunc(acr.CREATION_DATE) = trunc(app.CREATION_DATE)

  ))
  and trunc(acr.CREATION_DATE) =  trunc(t.matching_sysdate)
  and T.bank_account_id          = banque_info.bank_account_id
  and T.amount                   = acr.amount
  and T.check_number             = acr.RECEIPT_NUMBER
  
  UNION ALL
-- MAJ
-- MAJ
SELECT DISTINCT
  substr(hou.name, 4, 4) ||'_'||substr(hou.name, 1, 3)||'_'||acr.cash_receipt_id ||'_'|| acrh.cash_receipt_history_id IDENTIFIANT_AR
--,ps.AMOUNT_DUE_REMAINING
--,ps.AMOUNT_APPLIED
  ,acr.cash_receipt_id CASH_RECEIPT_ID
  ,acrh.cash_receipt_history_id CASH_RECEIPT_HISTORY_ID
  ,gl.name NOM_SOCIETE
  ,substr(hou.name, 4, 4) CODE_SOCIETE
  ,substr(hou.name, 1, 3) REGION
  ,hou.name UO
  ,arcs.NAME CLASSE_DE_REGLEMENT
  ,decode (acr.type ,'CASH', 'Standard','MISC', 'Divers') TYPE_REGLEMENT
  ,rcrm.name MODE_DE_REGLEMENT
--rcrm.RECEIPT_CREATION_RULE_CODE ,
-- arcs.CREATION_METHOD_CODE ,
  ,banque_info.BANK_ACCOUNT_NUM COMPTE_BANCAIRE
  ,banque_info.bank_name BANQUE_REMISE
  ,banque_info.BANK_BRANCH_NAME AGENCE_REMISE
  ,CUST.ACCOUNT_NUMBER   NUM_CLIENT
  ,RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' ')) NOM_CLIENT
  ,SITE_USES.LOCATION CODE_ADRESSE_CLIENT
  ,'MAJ' TYPE_ACTION
  ,acr.RECEIPT_NUMBER NUMERO_REGLEMENT
  , acr.AMOUNT MONTANT_REGLEMENT
  ,acr.CURRENCY_CODE DEVISE
  ,acr.COMMENTS COMMENTAIRES_REGLEMENTS
  ,  CASE 
    when piece.total  = 0 AND  ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Annulé'
  then 'ANNULATION REGLEMENT'
    
   when piece.type_maj = 'LETTRAGE MANUEL'
 THEN 'LETTRAGE MANUEL'
    
   WHEN piece.type_maj = 'DELETTRAGE MANUEL'
  then 'DELETTRAGE MANUEL'
    
    else ' ' end TYPE_MAJ
  , DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.MEANING) MOTIF_ANNULATION
  ,acr.REVERSAL_COMMENTS  COMMENTAIRES_ANNULATION
  ,acr.DOC_SEQUENCE_VALUE NUM_DOCUMENT
  ,trunc(acr.CREATION_DATE) DATE_CREATION_REGLEMENT
  ,acr.RECEIPT_DATE DATE_REGLEMENT
  ,ps.DUE_DATE DATE_EXIGIBILITE
  , case

  when arcs.NAME = 'PRELEVEMENT' then
    to_char(to_date(acr.ATTRIBUTE4,'DD-MON-YY'), 'DD/MM/YYYY')
    else null end DATE_PRELEVEMENT
  , acr.REVERSAL_DATE DATE_ANNULATION_REGLEMENT
  ,   CASE  
  
   WHEN piece.type_maj = 'LETTRAGE MANUEL' 
   
 THEN trunc(APP.APPLY_DATE)
  
    
    else null END  DATE_LETTRAGE
  ,CASE  WHEN  piece.type_maj = 'DELETTRAGE MANUEL'
   
  then trunc(ps_inv.LAST_UPDATE_DATE)
   when piece.total  = 0 AND  ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Annulé'
      then trunc(ps_inv.LAST_UPDATE_DATE)
       else null
      END DATE_DELETTRAGE
  ,fu.user_name REGLEMENT_CREE_PAR
  ,piece.trx_number NUMERO_PIECE_AR
  ,substr(hou.name, 4, 4)||'_'||return_value||'_'||piece.doc_sequence_value IDENTIFIANT_PIECE_SYRUS
  ,case when folio.concaten_Fact ='OUI'
  then substr(hou.name, 4, 4)||' '|| substr(hou.name, 2, 1)||' '|| piece.trx_number
   else piece.trx_number
     end
   NUM_PIECE_AMONT
  --,ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh.STATUS)
  , folio.code_folio CODE_FOLIO
  ,folio.description LIBELLE_FOLIO
  ,DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) TYPE_PIECE_AR
  --, app.AMOUNT_APPLIED_FROM MONTANT_PIECE_AR
   ,ps_inv.AMOUNT_DUE_ORIGINAL
    MONTANT_PIECE_AR

  ,case
  WHEN piece.type_maj = 'LETTRAGE MANUEL'  and ps_inv.AMOUNT_DUE_ORIGINAL >=0 
   then ABS(piece.MONTANT_PIECE_AR)
   when  piece.type_maj = 'LETTRAGE MANUEL' and ps_inv.AMOUNT_DUE_ORIGINAL <0
    then  piece.MONTANT_PIECE_AR
     
     when piece.total  <0 then 
        piece.MONTANT_PIECE_AR
        
      when ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Annulé' then 0
   else
        0
    end
   MONTANT_LETTRE
   ,case  
    WHEN  piece.total  = 0 and piece.type_maj = 'DELETTRAGE MANUEL' and ps_inv.AMOUNT_DUE_ORIGINAL >=0 then 
   ABS(piece.MONTANT_PIECE_AR)
   
   WHEN  piece.total  = 0 and piece.type_maj = 'DELETTRAGE MANUEL'  and ps_inv.AMOUNT_DUE_ORIGINAL <0 then 
    -1 * piece.MONTANT_PIECE_AR
     
     when piece.total  <0 and piece.type_maj = 'DELETTRAGE MANUEL'and ps_inv.AMOUNT_DUE_ORIGINAL >=0 then 
     ABS(piece.total) 
     
     when piece.total  <0 and piece.type_maj = 'DELETTRAGE MANUEL'and ps_inv.AMOUNT_DUE_ORIGINAL <0 then 
     piece.total
    
       
     when ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Annulé'
    THEN ps_inv.AMOUNT_DUE_ORIGINAL
    else 0
   end
    MONTANT_DELETTRE
   -- ,piece.MONTANT_PIECE_AR
   --,piece.total
   , acr.STATUS STATE_DSP
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al.MEANING)
  ,acr.REVERSAL_REASON_CODE REVERSAL_REASON_CODE
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.DESCRIPTION) REVERSAL_REASON_DESCRIPTION
  ,banque_info.bank_account_id

FROM

   ar_cash_receipts_all acr
   ,HZ_CUST_ACCOUNTS CUST
   ,ar_cash_receipt_history_all acrh
   ,ar_cash_receipt_history_all acrh1
   ,hr_operating_units hou
   ,HZ_PARTIES PARTY
   ,gl_ledgers gl
   ,ar_receipt_methods rcrm
   ,AR_RECEIPT_CLASSES arcs
   ,fnd_user             fu
   ,DKA_STRANSCO_LINES    DSTL
   ,DKA_STRANSCO_HEADERS  DSTH
   ,(    SELECT DISTINCT ffvt.description description ,
           ffv.ATTRIBUTE2 concaten_Fact ,
       ffv.flex_value code_folio,
       CTL.customer_trx_id 
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv,
             RA_CUSTOMER_TRX_LINES_all CTL,
             fnd_flex_values_tl  ffvt
       WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         and NVL(CTL.ATTRIBUTE9,'Y') = NVL(ffv.flex_value,'Y')
          AND ffv.enabled_flag = 'Y'
         AND ffv.flex_value_id = ffvt.flex_value_id
           )folio
   ,(
 select  app.AMOUNT_APPLIED,
 app.AMOUNT_APPLIED,
 bs.name,
 rcta.doc_sequence_value,
    DECODE(SIGN(app.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) type,
    rcta.trx_number,
    app.CASH_RECEIPT_ID,
    app.APPLIED_PAYMENT_SCHEDULE_ID,
    --CTL.ATTRIBUTE9 code_folio,
    RCTA.customer_trx_id,
    app.RECEIVABLE_APPLICATION_ID,
     apsa.AMOUNT_DUE_ORIGINAL,
    NVL(app.AMOUNT_APPLIED_FROM, app.AMOUNT_APPLIED)MONTANT_PIECE_AR,
  
abs( app.amount_applied )total ,

 'LETTRAGE MANUEL' type_maj
  
  
from ar_receivable_applications_all app,
    -- ar_receivable_applications_all araa,
 RA_CUSTOMER_TRX_ALL             rcta,
   AR_CASH_RECEIPTS_ALL            acra
 ,AR_PAYMENT_SCHEDULES_all  apsa
 , RA_BATCH_SOURCES_all BS
        ,AR_LOOKUPS al
  
where  apsa.class = al.LOOKUP_CODE
 AND al.LOOKUP_TYPE = 'INV/CM'
  AND BS.BATCH_SOURCE_ID  = rcta.BATCH_SOURCE_ID
and app.CASH_RECEIPT_ID = acra.CASH_RECEIPT_ID
AND rcta.CUSTOMER_TRX_ID = app.APPLIED_CUSTOMER_TRX_ID
AND app.APPLIED_PAYMENT_SCHEDULE_ID = apsa.PAYMENT_SCHEDULE_ID
AND trunc(app.last_update_date) = trunc(acra.last_update_date)
 and app.status = 'APP' 
 and not exists ( select distinct 1
                   from ar_receivable_applications_all t
                   where t.cash_receipt_id =app.cash_receipt_id 
                   and t.status = 'APP' 
                   and t.PAYMENT_SCHEDULE_ID = app.PAYMENT_SCHEDULE_ID
                   and t.APPLIED_CUSTOMER_TRX_ID = app.APPLIED_CUSTOMER_TRX_ID
                   and T.amount_applied != app.amount_applied
                   and T.RECEIVABLE_APPLICATION_ID != app.RECEIVABLE_APPLICATION_ID
                  )
                   
                   
 union all
 
 select distinct
 araa.AMOUNT_APPLIED,
 app.AMOUNT_APPLIED,
 bs.name,
 rcta.doc_sequence_value,
    DECODE(SIGN(araa.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) type,
    rcta.trx_number,
    araa.CASH_RECEIPT_ID,
    araa.APPLIED_PAYMENT_SCHEDULE_ID,
    --CTL.ATTRIBUTE9 code_folio,
    RCTA.customer_trx_id,
    araa.RECEIVABLE_APPLICATION_ID,
     apsa.AMOUNT_DUE_ORIGINAL,
    NVL(araa.AMOUNT_APPLIED_FROM, araa.AMOUNT_APPLIED)MONTANT_PIECE_AR,
  
abs (ARAA.amount_applied)  - abs(APP.amount_applied) total ,
CASE WHEN abs(ARAA.amount_applied) < abs(APP.amount_applied)
  then 'DELETTRAGE MANUEL'
   WHEN abs(ARAA.amount_applied) > abs(APP.amount_applied) 
 THEN 'LETTRAGE MANUEL'
   when ARAA.amount_applied =-1*APP.amount_applied 
     then 'DELETTRAGE MANUEL'
    end type_maj
from AR_CASH_RECEIPTS_ALL            acra,
ar_receivable_applications_all app,
     ar_receivable_applications_all araa,
  RA_CUSTOMER_TRX_ALL             rcta,
  AR_PAYMENT_SCHEDULES_all  apsa , RA_BATCH_SOURCES_all BS
        ,AR_LOOKUPS al
  
where  acra.CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID
 and apsa.class = al.LOOKUP_CODE
 AND al.LOOKUP_TYPE = 'INV/CM'
 AND rcta.CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
  AND araa.APPLIED_PAYMENT_SCHEDULE_ID = apsa.PAYMENT_SCHEDULE_ID
    and app.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
 and app.status = 'APP' 
 AND trunc(araa.creation_date) = trunc(acra.last_update_date)
 AND (ABS(app.amount_applied) != ABS(araa.AMOUNT_APPLIED) or 
 (araa.RECEIVABLE_APPLICATION_ID = (select max(T.RECEIVABLE_APPLICATION_ID)
                                           from ar_receivable_applications_all t
                                       where t.cash_receipt_id =araa.cash_receipt_id  and t.status = 'APP'
                                      and t.PAYMENT_SCHEDULE_ID = araa.PAYMENT_SCHEDULE_ID
                                      and t.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
                                       )))
    AND BS.BATCH_SOURCE_ID  = rcta.BATCH_SOURCE_ID
  and app.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID(+)
  and app.cash_receipt_id =araa.cash_receipt_id(+)
   and araa.status = 'APP' 
  and app.PAYMENT_SCHEDULE_ID = araa.PAYMENT_SCHEDULE_ID(+)
  and app.RECEIVABLE_APPLICATION_ID < ARAA.RECEIVABLE_APPLICATION_ID
 
  
  and ARAA.RECEIVABLE_APPLICATION_ID = ( select min(T.RECEIVABLE_APPLICATION_ID)
                                           from ar_receivable_applications_all t
                                       where t.cash_receipt_id =araa.cash_receipt_id  and t.status = 'APP'
                                      and t.PAYMENT_SCHEDULE_ID = araa.PAYMENT_SCHEDULE_ID
                                       and t.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
                                       and T.RECEIVABLE_APPLICATION_ID > app.RECEIVABLE_APPLICATION_ID) 
       
    )
   piece
   ,( SELECT        CEA.BANK_ACCOUNT_NUM ,
                    CBB.bank_name ,
                    CBB.BANK_BRANCH_NAME ,
                    acr1.cash_receipt_id,
                    arma.org_id,
                    cea.bank_account_id

                  FROM
                     AR_RECEIPT_METHODS arm1
                    ,ar_cash_receipts_all acr1
                    ,ar_receipt_method_accounts_all arma
                    ,CE_BANK_ACCT_USES_ALL cbaua
                    ,CE_BANK_ACCOUNTS CEA
                    ,ce_bank_branches_v CBB
                   WHERE
                    acr1.receipt_method_id = arma.receipt_method_id
                   AND ARM1.receipt_method_id = ARMA.receipt_method_id
                   AND arma.primary_flag = 'Y'
                   AND arma.REMIT_BANK_ACCT_USE_ID(+) = cbaua.BANK_ACCT_USE_ID
                   AND cbaua.BANK_ACCOUNT_ID = CEA.bank_account_id
                   AND cbb.bank_party_id = cea.bank_id
                   AND cbb.branch_party_id = cea.bank_branch_id
    ) banque_info

   ,HZ_CUST_SITE_USES_ALL SITE_USES
   ,AR_PAYMENT_SCHEDULES_all ps_inv
   ,AR_PAYMENT_SCHEDULES_all ps
  -- ,RA_CUSTOMER_TRX CT
   --RA_CUST_TRX_TYPES CTT ,
   ,AR_LOOKUPS al
   ,AR_LOOKUPS al1
   ,AR_RECEIVABLE_APPLICATIONS_all APP
  WHERE
     
      acr.cash_receipt_id = acrh.cash_receipt_id
  and acr.cash_receipt_id = acrh1.cash_receipt_id
  AND acr.PAY_FROM_CUSTOMER = CUST.CUST_ACCOUNT_ID (+)
  AND acr.CUSTOMER_SITE_USE_ID = SITE_USES.SITE_USE_ID (+)
--AND acrh.CASH_RECEIPT_HISTORY_ID = app.CASH_RECEIPT_HISTORY_ID(+)
  AND acr.ORG_ID = SITE_USES.ORG_ID (+)
  and fu.user_id= acr.created_by
  AND app.cash_receipt_id = acr.cash_receipt_id
  and piece.cash_receipt_id =acr.cash_receipt_id
   AND piece.customer_trx_id         = folio.customer_trx_id(+)
 -- and NVL(piece.code_folio,'Y') = NVL(folio.code_folio,'Y')
 and app.RECEIVABLE_APPLICATION_ID = piece.RECEIVABLE_APPLICATION_ID
  and  APP.APPLIED_PAYMENT_SCHEDULE_ID = piece.APPLIED_PAYMENT_SCHEDULE_ID
  AND AL1.LOOKUP_TYPE (+) = 'CKAJST_REASON'
  AND AL1.LOOKUP_CODE (+) = ACR.REVERSAL_REASON_CODE
  --AND PS_INV.ORG_ID(+) = acr.ORG_ID
  --AND CT.CUSTOMER_TRX_ID(+) = PS_INV.CUSTOMER_TRX_ID
  --AND CTT.CUST_TRX_TYPE_ID(+) = PS_INV.CUST_TRX_TYPE_ID
  AND CUST.CUST_ACCOUNT_ID(+) = PS_INV.CUSTOMER_ID
  AND PS.CASH_RECEIPT_ID(+) = acr.CASH_RECEIPT_ID
  AND PS.ORG_ID(+) = acr.ORG_ID
  AND APP.APPLIED_PAYMENT_SCHEDULE_ID = PS_INV.PAYMENT_SCHEDULE_ID
  AND acr.org_id = hou.organization_id
  AND hou.SET_OF_BOOKS_ID =  gl.LEDGER_ID
  AND acr.receipt_method_id = rcrm.receipt_method_id
  AND rcrm.RECEIPT_CLASS_ID = arcs.RECEIPT_CLASS_ID
  AND hou.organization_id = banque_info.org_id(+)
  AND banque_info.cash_receipt_id = acr.cash_receipt_id
  AND CUST.PARTY_ID = PARTY.PARTY_ID(+)
  AND  PS_INV.class = al.LOOKUP_CODE
  AND al.LOOKUP_TYPE = 'INV/CM'
  and acrh.CURRENT_RECORD_FLAG ='Y'
  and acrh1.CURRENT_RECORD_FLAG ='Y'
  AND acrh.ORG_ID = acr.ORG_ID
  AND acrh1.ORG_ID = acr.ORG_ID
  and DSTL.SET_ID = DSTH.SET_ID
  and   piece.name  like '%'|| DSTL.PARAMS_VALUE||'%'
  AND DSTH.SET_NAME = 'DKA_TYPE_MVT_AR'
  AND DSTL.ENABLE = 'Y'

-- AND acrh1.ORG_ID = acr.ORG_ID
  ------ debut ne pas extraire
  --  Les règlements non identifiès
  and CUST.ACCOUNT_NUMBER  is not null
  and RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' '))  is not null
  --  Les règlements crèès et annulès le mème jour
  AND to_char(acr.CREATION_DATE,'DD/MM/YYYY')!= NVL(acr.REVERSAL_DATE, to_date('01/01/1901','DD/MM/YYYY'))
  --  Les règlements de type DIVERS
  AND acr.type != 'MISC'
  --  Crèation dèun règlement non lettrè quand le montant du règlement = montant non lettrè
AND ( acr.status !='UNAPP' or acr.AMOUNT != DECODE (acr.status, 'UNAPP', NVL (ps.amount_applied, 0), 0))
  --  Les factures mise en litige
  and not exists (select CTT.NAME  from AR_ADJUSTMENTS_all ADJ ,AR_PAYMENT_SCHEDULES_all PS,RA_CUSTOMER_TRX_all CT, RA_CUST_TRX_TYPES_all CTT,AR_LOOKUPS REASON  
 where PS.CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
  AND CT.REASON_CODE = REASON.LOOKUP_CODE (+)
  AND REASON.LOOKUP_TYPE (+) = 'ADJUST_REASON'
 AND REASON.ENABLED_FLAG (+) = 'Y'
 AND CTT.CUST_TRX_TYPE_ID = CT.CUST_TRX_TYPE_ID
 and ADJ.CHARGEBACK_CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
 AND adj.PAYMENT_SCHEDULE_ID = ps_inv.PAYMENT_SCHEDULE_ID
 and CTT.NAME ='DOUTEUX')
  
    ------Extraction PRELEVEMENT Remis en banque
and (exists ( select hist.STATUS from ar_cash_receipt_history_all hist where hist.CASH_RECEIPT_ID =  acr.cash_receipt_id
  and STATUS = 'REMITTED' and arcs.name = 'PRELEVEMENT')or arcs.name !='PRELEVEMENT') 
  and trunc(acr.CREATION_DATE) <  trunc(acr.LAST_UPDATE_DATE)

 and acr.last_update_date >= to_date(pn_date_pivot, 'DD/MM/YYYY HH24:MI:SS')
 
UNION ALL
-- MAJ 



SELECT DISTINCT
  substr(hou.name, 4, 4) ||'_'||substr(hou.name, 1, 3)||'_'||acr.cash_receipt_id ||'_'|| acrh.cash_receipt_history_id IDENTIFIANT_AR
--,ps.AMOUNT_DUE_REMAINING
--,ps.AMOUNT_APPLIED
  ,acr.cash_receipt_id CASH_RECEIPT_ID
  ,acrh.cash_receipt_history_id CASH_RECEIPT_HISTORY_ID
  ,gl.name NOM_SOCIETE
  ,substr(hou.name, 4, 4) CODE_SOCIETE
  ,substr(hou.name, 1, 3) REGION
  ,hou.name UO
  ,arcs.NAME CLASSE_DE_REGLEMENT
  ,decode (acr.type ,'CASH', 'Standard','MISC', 'Divers') TYPE_REGLEMENT
  ,rcrm.name MODE_DE_REGLEMENT
--rcrm.RECEIPT_CREATION_RULE_CODE ,
-- arcs.CREATION_METHOD_CODE ,
  ,banque_info.BANK_ACCOUNT_NUM COMPTE_BANCAIRE
  ,banque_info.bank_name BANQUE_REMISE
  ,banque_info.BANK_BRANCH_NAME AGENCE_REMISE
  ,CUST.ACCOUNT_NUMBER   NUM_CLIENT
  ,RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' ')) NOM_CLIENT
  ,SITE_USES.LOCATION CODE_ADRESSE_CLIENT
  ,'MAJ' TYPE_ACTION
  ,acr.RECEIPT_NUMBER NUMERO_REGLEMENT
  , acr.AMOUNT MONTANT_REGLEMENT
  ,acr.CURRENCY_CODE DEVISE
  ,acr.COMMENTS COMMENTAIRES_REGLEMENTS
  , 'RAPPROCHEMENT BANCAIRE' TYPE_MAJ
  , DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.MEANING) MOTIF_ANNULATION
  ,acr.REVERSAL_COMMENTS  COMMENTAIRES_ANNULATION
  ,acr.DOC_SEQUENCE_VALUE NUM_DOCUMENT
  ,trunc(acr.CREATION_DATE) DATE_CREATION_REGLEMENT
  ,acr.RECEIPT_DATE DATE_REGLEMENT
  ,ps.DUE_DATE DATE_EXIGIBILITE
  , case

  when arcs.NAME = 'PRELEVEMENT' then
    to_char(to_date(acr.ATTRIBUTE4,'DD-MON-YY'), 'DD/MM/YYYY')
    else null end DATE_PRELEVEMENT
  , acr.REVERSAL_DATE DATE_ANNULATION_REGLEMENT
  ,   CASE  
  
   WHEN piece.type_maj = 'LETTRAGE MANUEL' 
   
 THEN trunc(APP.APPLY_DATE)
  
    
    else null END  DATE_LETTRAGE
  ,CASE  WHEN  piece.type_maj = 'DELETTRAGE MANUEL'
   
  then trunc(ps_inv.LAST_UPDATE_DATE)
   when piece.total  = 0 AND  ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Annulé'
      then trunc(ps_inv.LAST_UPDATE_DATE)
       else null
      END DATE_DELETTRAGE
  ,fu.user_name REGLEMENT_CREE_PAR
  ,piece.trx_number NUMERO_PIECE_AR
  ,substr(hou.name, 4, 4)||'_'||return_value||'_'||piece.doc_sequence_value IDENTIFIANT_PIECE_SYRUS
  ,case when folio.concaten_Fact ='OUI'
  then substr(hou.name, 4, 4)||' '|| substr(hou.name, 2, 1)||' '|| piece.trx_number
   else piece.trx_number
     end
   NUM_PIECE_AMONT
  --,ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh.STATUS)
  , folio.code_folio CODE_FOLIO
  ,folio.description LIBELLE_FOLIO
  ,DECODE(SIGN(APP.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) TYPE_PIECE_AR
  --, app.AMOUNT_APPLIED_FROM MONTANT_PIECE_AR
   ,ps_inv.AMOUNT_DUE_ORIGINAL
    MONTANT_PIECE_AR

  ,case
  WHEN piece.type_maj = 'LETTRAGE MANUEL'  and ps_inv.AMOUNT_DUE_ORIGINAL >=0 
   then ABS(piece.MONTANT_PIECE_AR)
   when  piece.type_maj = 'LETTRAGE MANUEL' and ps_inv.AMOUNT_DUE_ORIGINAL <0
    then  piece.MONTANT_PIECE_AR
     
     when piece.total  <0 then 
        piece.MONTANT_PIECE_AR
        
      when ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Annulé' then 0
   else
        0
    end
   MONTANT_LETTRE
   ,case  
    WHEN  piece.total  = 0 and piece.type_maj = 'DELETTRAGE MANUEL' and ps_inv.AMOUNT_DUE_ORIGINAL >=0 then 
   ABS(piece.MONTANT_PIECE_AR)
   
   WHEN  piece.total  = 0 and piece.type_maj = 'DELETTRAGE MANUEL'  and ps_inv.AMOUNT_DUE_ORIGINAL <0 then 
    -1 * piece.MONTANT_PIECE_AR
     
     when piece.total  <0 and piece.type_maj = 'DELETTRAGE MANUEL'and ps_inv.AMOUNT_DUE_ORIGINAL >=0 then 
     ABS(piece.total) 
     
     when piece.total  <0 and piece.type_maj = 'DELETTRAGE MANUEL'and ps_inv.AMOUNT_DUE_ORIGINAL <0 then 
     piece.total
    
       
     when ARPT_SQL_FUNC_UTIL.get_lookup_meaning('RECEIPT_CREATION_STATUS', acrh1.STATUS) = 'Annulé'
    THEN ps_inv.AMOUNT_DUE_ORIGINAL
    else 0
   end
    MONTANT_DELETTRE
   -- ,piece.MONTANT_PIECE_AR
   --,piece.total
   , acr.STATUS STATE_DSP
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al.MEANING)
  ,acr.REVERSAL_REASON_CODE REVERSAL_REASON_CODE
  ,DECODE(acr.REVERSAL_REASON_CODE, NULL, NULL, al1.DESCRIPTION) REVERSAL_REASON_DESCRIPTION
  ,banque_info.bank_account_id


FROM

   ar_cash_receipts_all acr
   ,HZ_CUST_ACCOUNTS CUST
   ,ar_cash_receipt_history_all acrh
   ,ar_cash_receipt_history_all acrh1
   ,hr_operating_units hou
   ,HZ_PARTIES PARTY
   ,gl_ledgers gl
   ,ar_receipt_methods rcrm
   ,AR_RECEIPT_CLASSES arcs
   ,fnd_user             fu
   ,DKA_STRANSCO_LINES    DSTL
   ,DKA_STRANSCO_HEADERS  DSTH
   ,DKA_RB_LINES T
   ,(    SELECT DISTINCT ffvt.description description ,
           ffv.ATTRIBUTE2 concaten_Fact ,
       ffv.flex_value code_folio,
       CTL.customer_trx_id 
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values     ffv,
             RA_CUSTOMER_TRX_LINES_all CTL,
             fnd_flex_values_tl  ffvt
       WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         and NVL(CTL.ATTRIBUTE9,'Y') = NVL(ffv.flex_value,'Y')
          AND ffv.enabled_flag = 'Y'
         AND ffv.flex_value_id = ffvt.flex_value_id
           )folio
   ,(
  select  app.AMOUNT_APPLIED,
 app.AMOUNT_APPLIED,
 bs.name,
 rcta.doc_sequence_value,
    DECODE(SIGN(app.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) type,
    rcta.trx_number,
    app.CASH_RECEIPT_ID,
    app.APPLIED_PAYMENT_SCHEDULE_ID,
    --CTL.ATTRIBUTE9 code_folio,
    RCTA.customer_trx_id,
    app.RECEIVABLE_APPLICATION_ID,
     apsa.AMOUNT_DUE_ORIGINAL,
    NVL(app.AMOUNT_APPLIED_FROM, app.AMOUNT_APPLIED)MONTANT_PIECE_AR,
  
abs( app.amount_applied )total ,

 'LETTRAGE MANUEL' type_maj
  
  
from ar_receivable_applications_all app,
    -- ar_receivable_applications_all araa,
 RA_CUSTOMER_TRX_ALL             rcta,
   AR_CASH_RECEIPTS_ALL            acra
 ,AR_PAYMENT_SCHEDULES_all  apsa
 , RA_BATCH_SOURCES_all BS
        ,AR_LOOKUPS al
  
where  apsa.class = al.LOOKUP_CODE
 AND al.LOOKUP_TYPE = 'INV/CM'
  AND BS.BATCH_SOURCE_ID  = rcta.BATCH_SOURCE_ID
and app.CASH_RECEIPT_ID = acra.CASH_RECEIPT_ID
AND rcta.CUSTOMER_TRX_ID = app.APPLIED_CUSTOMER_TRX_ID
AND app.APPLIED_PAYMENT_SCHEDULE_ID = apsa.PAYMENT_SCHEDULE_ID
AND trunc(app.last_update_date) = trunc(acra.last_update_date)
 and app.status = 'APP' 
 and not exists ( select distinct 1
                   from ar_receivable_applications_all t
                   where t.cash_receipt_id =app.cash_receipt_id 
                   and t.status = 'APP' 
                   and t.PAYMENT_SCHEDULE_ID = app.PAYMENT_SCHEDULE_ID
                   and t.APPLIED_CUSTOMER_TRX_ID = app.APPLIED_CUSTOMER_TRX_ID
                   and T.amount_applied != app.amount_applied
                   and T.RECEIVABLE_APPLICATION_ID != app.RECEIVABLE_APPLICATION_ID
                  )
                   
                   
 union all
 
 select distinct
 araa.AMOUNT_APPLIED,
 app.AMOUNT_APPLIED,
 bs.name,
 rcta.doc_sequence_value,
    DECODE(SIGN(araa.APPLIED_PAYMENT_SCHEDULE_ID), -1,NULL, al.MEANING) type,
    rcta.trx_number,
    araa.CASH_RECEIPT_ID,
    araa.APPLIED_PAYMENT_SCHEDULE_ID,
    --CTL.ATTRIBUTE9 code_folio,
    RCTA.customer_trx_id,
    araa.RECEIVABLE_APPLICATION_ID,
     apsa.AMOUNT_DUE_ORIGINAL,
    NVL(araa.AMOUNT_APPLIED_FROM, araa.AMOUNT_APPLIED)MONTANT_PIECE_AR,
  
abs (ARAA.amount_applied)  - abs(APP.amount_applied) total ,
CASE WHEN abs(ARAA.amount_applied) < abs(APP.amount_applied)
  then 'DELETTRAGE MANUEL'
   WHEN abs(ARAA.amount_applied) > abs(APP.amount_applied) 
 THEN 'LETTRAGE MANUEL'
   when ARAA.amount_applied =-1*APP.amount_applied 
     then 'DELETTRAGE MANUEL'
    end type_maj
from AR_CASH_RECEIPTS_ALL            acra,
ar_receivable_applications_all app,
     ar_receivable_applications_all araa,
  RA_CUSTOMER_TRX_ALL             rcta,
  AR_PAYMENT_SCHEDULES_all  apsa , RA_BATCH_SOURCES_all BS
        ,AR_LOOKUPS al
  
where  acra.CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID
 and apsa.class = al.LOOKUP_CODE
 AND al.LOOKUP_TYPE = 'INV/CM'
 AND rcta.CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
  AND araa.APPLIED_PAYMENT_SCHEDULE_ID = apsa.PAYMENT_SCHEDULE_ID
    and app.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
 and app.status = 'APP' 
 AND trunc(araa.creation_date) = trunc(acra.last_update_date)
 AND (ABS(app.amount_applied) != ABS(araa.AMOUNT_APPLIED) or 
 (araa.RECEIVABLE_APPLICATION_ID = (select max(T.RECEIVABLE_APPLICATION_ID)
                                           from ar_receivable_applications_all t
                                       where t.cash_receipt_id =araa.cash_receipt_id  and t.status = 'APP'
                                      and t.PAYMENT_SCHEDULE_ID = araa.PAYMENT_SCHEDULE_ID
                                      and t.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
                                       )))
    AND BS.BATCH_SOURCE_ID  = rcta.BATCH_SOURCE_ID
  and app.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID(+)
  and app.cash_receipt_id =araa.cash_receipt_id(+)
   and araa.status = 'APP' 
  and app.PAYMENT_SCHEDULE_ID = araa.PAYMENT_SCHEDULE_ID(+)
  and app.RECEIVABLE_APPLICATION_ID < ARAA.RECEIVABLE_APPLICATION_ID
 
  
  and ARAA.RECEIVABLE_APPLICATION_ID = ( select min(T.RECEIVABLE_APPLICATION_ID)
                                           from ar_receivable_applications_all t
                                       where t.cash_receipt_id =araa.cash_receipt_id  and t.status = 'APP'
                                      and t.PAYMENT_SCHEDULE_ID = araa.PAYMENT_SCHEDULE_ID
                                       and t.APPLIED_CUSTOMER_TRX_ID = araa.APPLIED_CUSTOMER_TRX_ID
                                       and T.RECEIVABLE_APPLICATION_ID > app.RECEIVABLE_APPLICATION_ID) 
       
    )
   piece
   ,( SELECT        CEA.BANK_ACCOUNT_NUM ,
                    CBB.bank_name ,
                    CBB.BANK_BRANCH_NAME ,
                    acr1.cash_receipt_id,
                    arma.org_id,
                    cea.bank_account_id

                  FROM
                     AR_RECEIPT_METHODS arm1
                    ,ar_cash_receipts_all acr1
                    ,ar_receipt_method_accounts_all arma
                    ,CE_BANK_ACCT_USES_ALL cbaua
                    ,CE_BANK_ACCOUNTS CEA
                    ,ce_bank_branches_v CBB
                   WHERE
                    acr1.receipt_method_id = arma.receipt_method_id
                   AND ARM1.receipt_method_id = ARMA.receipt_method_id
                   AND arma.primary_flag = 'Y'
                   AND arma.REMIT_BANK_ACCT_USE_ID(+) = cbaua.BANK_ACCT_USE_ID
                   AND cbaua.BANK_ACCOUNT_ID = CEA.bank_account_id
                   AND cbb.bank_party_id = cea.bank_id
                   AND cbb.branch_party_id = cea.bank_branch_id
    ) banque_info

   ,HZ_CUST_SITE_USES_ALL SITE_USES
   ,AR_PAYMENT_SCHEDULES_all ps_inv
   ,AR_PAYMENT_SCHEDULES_all ps
  -- ,RA_CUSTOMER_TRX CT
   --RA_CUST_TRX_TYPES CTT ,
   ,AR_LOOKUPS al
   ,AR_LOOKUPS al1
   ,AR_RECEIVABLE_APPLICATIONS_all APP
  WHERE
     
      acr.cash_receipt_id = acrh.cash_receipt_id
  and acr.cash_receipt_id = acrh1.cash_receipt_id
  AND acr.PAY_FROM_CUSTOMER = CUST.CUST_ACCOUNT_ID (+)
  AND acr.CUSTOMER_SITE_USE_ID = SITE_USES.SITE_USE_ID (+)
--AND acrh.CASH_RECEIPT_HISTORY_ID = app.CASH_RECEIPT_HISTORY_ID(+)
  AND acr.ORG_ID = SITE_USES.ORG_ID (+)
  and fu.user_id= acr.created_by
  AND app.cash_receipt_id = acr.cash_receipt_id
  and piece.cash_receipt_id =acr.cash_receipt_id
   AND piece.customer_trx_id         = folio.customer_trx_id(+)
 -- and NVL(piece.code_folio,'Y') = NVL(folio.code_folio,'Y')
 and app.RECEIVABLE_APPLICATION_ID = piece.RECEIVABLE_APPLICATION_ID
  and  APP.APPLIED_PAYMENT_SCHEDULE_ID = piece.APPLIED_PAYMENT_SCHEDULE_ID
  AND AL1.LOOKUP_TYPE (+) = 'CKAJST_REASON'
  AND AL1.LOOKUP_CODE (+) = ACR.REVERSAL_REASON_CODE
  --AND PS_INV.ORG_ID(+) = acr.ORG_ID
  --AND CT.CUSTOMER_TRX_ID(+) = PS_INV.CUSTOMER_TRX_ID
  --AND CTT.CUST_TRX_TYPE_ID(+) = PS_INV.CUST_TRX_TYPE_ID
  AND CUST.CUST_ACCOUNT_ID(+) = PS_INV.CUSTOMER_ID
  AND PS.CASH_RECEIPT_ID(+) = acr.CASH_RECEIPT_ID
  AND PS.ORG_ID(+) = acr.ORG_ID
  AND APP.APPLIED_PAYMENT_SCHEDULE_ID = PS_INV.PAYMENT_SCHEDULE_ID
  AND acr.org_id = hou.organization_id
  AND hou.SET_OF_BOOKS_ID =  gl.LEDGER_ID
  AND acr.receipt_method_id = rcrm.receipt_method_id
  AND rcrm.RECEIPT_CLASS_ID = arcs.RECEIPT_CLASS_ID
  AND hou.organization_id = banque_info.org_id(+)
  AND banque_info.cash_receipt_id = acr.cash_receipt_id
  AND CUST.PARTY_ID = PARTY.PARTY_ID(+)
  AND  PS_INV.class = al.LOOKUP_CODE
  AND al.LOOKUP_TYPE = 'INV/CM'
  and acrh.CURRENT_RECORD_FLAG ='Y'
  and acrh1.CURRENT_RECORD_FLAG ='Y'
  AND acrh.ORG_ID = acr.ORG_ID
  AND acrh1.ORG_ID = acr.ORG_ID
  and DSTL.SET_ID = DSTH.SET_ID
  and  piece.name like '%'|| DSTL.PARAMS_VALUE ||'%'
  AND DSTH.SET_NAME = 'DKA_TYPE_MVT_AR'
  AND DSTL.ENABLE = 'Y'

-- AND acrh1.ORG_ID = acr.ORG_ID
  ------ debut ne pas extraire
  --  Les règlements non identifiès
  and CUST.ACCOUNT_NUMBER  is not null
  and RTRIM(RTRIM ( SUBSTRB ( PARTY.PARTY_NAME , 1 , 50 ) ),to_multi_byte(' '))  is not null
  --  Les règlements crèès et annulès le mème jour
  AND to_char(acr.CREATION_DATE,'DD/MM/YYYY')!= NVL(acr.REVERSAL_DATE, to_date('01/01/1901','DD/MM/YYYY'))
  --  Les règlements de type DIVERS
  AND acr.type != 'MISC'
  --  Crèation dèun règlement non lettrè quand le montant du règlement = montant non lettrè
  AND ( acr.status !='UNAPP' or acr.AMOUNT != DECODE (acr.status, 'UNAPP', NVL (ps.amount_applied, 0), 0))
  --  Les factures mise en litige
  and not exists (select CTT.NAME  from AR_ADJUSTMENTS_all ADJ ,AR_PAYMENT_SCHEDULES_all PS,RA_CUSTOMER_TRX_all CT, RA_CUST_TRX_TYPES_all CTT,AR_LOOKUPS REASON  
 where PS.CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
  AND CT.REASON_CODE = REASON.LOOKUP_CODE (+)
  AND REASON.LOOKUP_TYPE (+) = 'ADJUST_REASON'
 AND REASON.ENABLED_FLAG (+) = 'Y'
 AND CTT.CUST_TRX_TYPE_ID = CT.CUST_TRX_TYPE_ID
 and ADJ.CHARGEBACK_CUSTOMER_TRX_ID = CT.CUSTOMER_TRX_ID 
 AND adj.PAYMENT_SCHEDULE_ID = ps_inv.PAYMENT_SCHEDULE_ID
 and CTT.NAME ='DOUTEUX')
  
    ------Extraction PRELEVEMENT Remis en banque
and (exists ( select hist.STATUS from ar_cash_receipt_history_all hist where hist.CASH_RECEIPT_ID =  acr.cash_receipt_id
  and STATUS = 'REMITTED' and arcs.name = 'PRELEVEMENT')or arcs.name !='PRELEVEMENT') 
  and trunc(acr.CREATION_DATE) <  trunc(t.matching_sysdate)
  and T.bank_account_id          = banque_info.bank_account_id
  and T.amount                   = acr.amount
  and T.check_number             = acr.RECEIPT_NUMBER

 order BY cash_receipt_id
;

    vn_nb_lignes_EC NUMBER :=0;
    cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';
    vv_buffer      VARCHAR2(4000);
    va_file_id utl_file.file_type;
    vv_filename VARCHAR2(80);
    vv_directory_name        dba_directories.directory_path%TYPE ;
    v_DATE_VALEUR_RB         rb_lines.LINE_DATE%TYPE;
    v_DATE_OPERATION_RB      rb_lines.BANK_DATE%TYPE;
    v_DATE_RAPPROCHEMENT_RB  rb_lines.MATCHING_DATE%TYPE;
    v_REF_RAPPROCHEMENT_RB   rb_lines.MATCHING_REF%TYPE;
    V_MATCHED_BY             rb_lines.MATCHED_BY%TYPE;
    V_MATCHING_STATUS        rb_lines.MATCHING_STATUS%TYPE;
    V_ORG_ID                 rb_lines.ORG_ID%TYPE;
  V_LINE_DATE              rb_lines.LINE_DATE%TYPE;
    V_BANK_DATE              rb_lines.BANK_DATE%TYPE;
    --V_TYPE_MAJ VARCHAR2(50);

  BEGIN
    pv_errbuf  := NULL;
    pn_retcode := 0;
    pn_nb_lignes_ec := 0;
    v_DATE_VALEUR_RB            := NULL;
    v_DATE_OPERATION_RB         := NULL;
    v_DATE_RAPPROCHEMENT_RB     := NULL;
    v_REF_RAPPROCHEMENT_RB      := NULL;
    V_MATCHED_BY                := NULL;
    V_ORG_ID          := NULL;
    V_MATCHING_STATUS           := NULL;



    dka_tools_pkg.put_debug_message('==> Dèbut du traitement');


      ------------------------
      -- Edition du fichier --
      ------------------------
      dka_tools_pkg.put_debug_message('Edition du fichier');

      vv_filename := 'ENCAISSEMENTS_CLIENTS_'||TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')||'.csv';
      -----------------------------------------
      -- Recherche du fichier de destination --
      -----------------------------------------


      --------------------------------------------------------
      -- Recherche du rèpertoire de destination du fichier. --
      --------------------------------------------------------
      SELECT dd.directory_path
        INTO vv_directory_name
        FROM dba_directories dd
       WHERE dd.directory_name = 'DKA_OUT_DIR';

      ---------------------------------------------------
      -- Vèrifie que le fichier n'est pas dèja ouvert. --
      ---------------------------------------------------

      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fermeture du fichier pour l''extraction encaissements clients.');
        --------------------------
        -- fermeture du fichier --
        --------------------------
        utl_file.fclose(va_file_id);
        dka_tools_pkg.put_log_message('  fichier fermè');
      END IF;

      -------------------------------------------
      -- Ouverture du fichier en Mode Ecriture --
      -------------------------------------------
      va_file_id := utl_file.fopen(cv_directory, vv_filename, 'w',5000);

      ------------------------------------------------------------
      -- Vèrifie que l'on a bien ouvert le fichier en ècriture. --
      ------------------------------------------------------------
      IF utl_file.is_open(va_file_id) THEN
        dka_tools_pkg.put_log_message('  fichier ' || vv_directory_name || '/' ||
                                      vv_filename || ' ouvert en ècriture');
      ELSE
        RAISE e_file;
      END IF;

      utl_file.put_line(va_file_id, 'IDENTIFIANT_AR;CASH_RECEIPT_ID;CASH_RECEIPT_HISTORY_ID;NOM_SOCIETE;CODE_SOCIETE;REGION;UO;CLASSE_DE_REGLEMENT;TYPE_REGLEMENT;MODE_DE_REGLEMENT;COMPTE_BANCAIRE;BANQUE_REMISE;AGENCE_REMISE;NUM_CLIENT;NOM_CLIENT;CODE_ADRESSE_CLIENT;TYPE_ACTION;NUMERO_REGLEMENT;MONTANT_REGLEMENT;DEVISE;COMMENTAIRES_REGLEMENTS;TYPE_MAJ;MOTIF_ANNULATION;COMMENTAIRES_ANNULATION;NUM_DOCUMENT;DATE_CREATION_REGLEMENT;DATE_REGLEMENT;DATE_EXIGIBILITE;DATE_PRELEVEMENT;DATE_ANNULATION_REGLEMENT;DATE_LETTRAGE;DATE_DELETTRAGE;REGLEMENT_CREE_PAR;NUMERO_PIECE_AR;IDENTIFIANT_PIECE_SYRUS;NUM_PIECE_AMONT;CODE_FOLIO;LIBELLE_FOLIO;TYPE_PIECE_AR;MONTANT_PIECE_AR;MONTANT_LETTRE;MONTANT_DELETTRE;DATE_VALEUR_RB;DATE_OPERATION_RB;DATE_RAPPROCHEMENT_RB;REF_RAPPROCHEMENT_RB');

    
      ---------------------------------------------------------------------
      -- Parcours du curseur contenant les diffèrentes lignes a insèrer. --
      ---------------------------------------------------------------------
      FOR rec_extract_encaissement IN cur_extract_encaissement LOOP

  BEGIN
     select
      MATCHING_DATE
     ,MATCHING_REF
     ,MATCHED_BY
     ,MATCHING_STATUS
     ,ORG_ID
   ,LINE_DATE
   ,BANK_DATE

   into

    v_DATE_RAPPROCHEMENT_RB
   ,v_REF_RAPPROCHEMENT_RB
   ,V_MATCHED_BY
   ,V_MATCHING_STATUS
   ,V_ORG_ID
   ,V_LINE_DATE
   ,V_BANK_DATE
     from rb_lines rla
   where rla.bank_account_id            = rec_extract_encaissement.bank_account_id
       and rla.amount                   = rec_extract_encaissement.MONTANT_REGLEMENT
       and check_number                 = rec_extract_encaissement.NUMERO_REGLEMENT
       AND RLA.line_type                = 'A'
        and rownum<2 
       ;

     if V_MATCHING_STATUS  = 'Y'  then


    select
      max(LINE_DATE)
     ,max(BANK_DATE)
   into
    v_DATE_VALEUR_RB
   ,v_DATE_OPERATION_RB

     from rb_lines rla
     where
     rla.MATCHING_REF                  = v_REF_RAPPROCHEMENT_RB
     and   rla.ORG_ID                  = v_ORG_ID
        AND RLA.line_type              = 'B'
     ;
   
   IF v_DATE_VALEUR_RB is null and v_DATE_OPERATION_RB is null then 
   
      v_DATE_VALEUR_RB     := V_LINE_DATE;
      v_DATE_OPERATION_RB  := V_BANK_DATE;
    
  END if ; 

      else


            v_DATE_VALEUR_RB             := NULL;
            v_DATE_OPERATION_RB          := NULL;
            v_DATE_RAPPROCHEMENT_RB      := NULL;
            v_REF_RAPPROCHEMENT_RB       := NULL;
            V_MATCHING_STATUS            := NULL;

            END if ;
    EXCEPTION
    WHEN OTHERS THEN
            v_DATE_VALEUR_RB             := NULL;
            v_DATE_OPERATION_RB          := NULL;
            v_DATE_RAPPROCHEMENT_RB      := NULL;
            v_REF_RAPPROCHEMENT_RB       := NULL;
            V_MATCHING_STATUS            := NULL;
  END;


          vv_buffer :=
            rec_extract_encaissement.IDENTIFIANT_AR||';'||
            rec_extract_encaissement.CASH_RECEIPT_ID||';'||
            rec_extract_encaissement.CASH_RECEIPT_HISTORY_ID||';'||
            rec_extract_encaissement.NOM_SOCIETE||';'||
            rec_extract_encaissement.CODE_SOCIETE||';'||
            rec_extract_encaissement.REGION||';'||
            rec_extract_encaissement.UO||';'||
            rec_extract_encaissement.CLASSE_DE_REGLEMENT||';'||
            rec_extract_encaissement.TYPE_REGLEMENT||';'||
            rec_extract_encaissement.MODE_DE_REGLEMENT||';'||
            rec_extract_encaissement.COMPTE_BANCAIRE||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.BANQUE_REMISE  ,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.AGENCE_REMISE,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            lpad(rec_extract_encaissement.NUM_CLIENT, 8, '0')||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.NOM_CLIENT,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            rec_extract_encaissement.CODE_ADRESSE_CLIENT||';'||
            rec_extract_encaissement.TYPE_ACTION||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.NUMERO_REGLEMENT,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            REPLACE(to_char(rec_extract_encaissement.MONTANT_REGLEMENT), '.', ',')||';'||
            rec_extract_encaissement.DEVISE||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.COMMENTAIRES_REGLEMENTS,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            rec_extract_encaissement.TYPE_MAJ||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.MOTIF_ANNULATION,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.COMMENTAIRES_ANNULATION,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            rec_extract_encaissement.NUM_DOCUMENT||';'||
            rec_extract_encaissement.DATE_CREATION_REGLEMENT||';'||
            rec_extract_encaissement.DATE_REGLEMENT||';'||
            rec_extract_encaissement.DATE_EXIGIBILITE||';'||
            rec_extract_encaissement.DATE_PRELEVEMENT||';'||
            rec_extract_encaissement.DATE_ANNULATION_REGLEMENT
            ||';'||rec_extract_encaissement.DATE_LETTRAGE||';'||
            rec_extract_encaissement.DATE_DELETTRAGE||';'||
            rec_extract_encaissement.REGLEMENT_CREE_PAR||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.NUMERO_PIECE_AR,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            rec_extract_encaissement.IDENTIFIANT_PIECE_SYRUS||';'||
            rec_extract_encaissement.NUM_PIECE_AMONT||';'||
            rec_extract_encaissement.CODE_FOLIO||';'||
            REPLACE(REPLACE(REPLACE (REPLACE(REPLACE (rec_extract_encaissement.LIBELLE_FOLIO,  chr(34), ' ') ,  chr(39), ' '),chr(10), ''),chr(13), ''),chr(59))||';'||
            rec_extract_encaissement.TYPE_PIECE_AR||';'||
            REPLACE(to_char(rec_extract_encaissement.MONTANT_PIECE_AR), '.', ',')||';'||
            REPLACE(to_char(rec_extract_encaissement.MONTANT_LETTRE), '.', ',')||';'||
            REPLACE(to_char(rec_extract_encaissement.MONTANT_DELETTRE), '.', ',')||';'||
            V_DATE_VALEUR_RB||';'||
            V_DATE_OPERATION_RB||';'||
            V_DATE_RAPPROCHEMENT_RB||';'||
            V_REF_RAPPROCHEMENT_RB;

          utl_file.put_line(va_file_id, vv_buffer);
          vn_nb_lignes_EC := vn_nb_lignes_EC + 1;


      END LOOP;

      ---------------------------------------
      -- Fermeture du fichier en ècriture. --
      ---------------------------------------
      utl_file.fclose(va_file_id);
      ----------------------------------------------------------
    pn_nb_lignes_ec  := vn_nb_lignes_EC;
  ----------------------------------------------------------
  dka_tools_pkg.put_debug_message('==> Mise è jour du paramètre Last_EXTENCAISSCLIENT_Date dans la table dka_parameters');
  -- Mise è jour du paramètre Last_EXTENCAISSCLIENT_Date dans la table dka_parameters
         UPDATE dka_parameters
         SET varchar2_value = to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')
         WHERE program_code = 'DKA_SAREXTENCAISSCLIENT'
           AND parameter_name = 'Last_EXTENCAISSCLIENT_Date';

          commit;
    dka_tools_pkg.put_debug_message('==> Fin du traitement');


  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLCODE || ' - ' || substr(SQLERRM, 1, 80);
      pn_retcode := 2;
     UTL_FILE.FREMOVE (vv_directory_name, vv_filename );
      pn_nb_lignes_ec  :=0;

  END Extraction_encaissements_clients;

/*
*************************************************************************
* PROCEDURE NAME : main
*
* DESCRIPTION
*  Procèdure gènèrale du traitement
*
* PARAMETERS
* ==========
* NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
* p_errbuf            Retour de message èventuel
* p_retcode           Statut du traitement en sortie
************************************************************************
*/
PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   )
IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  v_file                     VARCHAR2(100);
  pn_date_pivot VARCHAR2(20);
  pn_nb_lignes_ec number := 0;

BEGIN

EXECUTE IMMEDIATE 'alter session set nls_date_format="DD/MM/YYYY"';

     select  varchar2_value
      into pn_date_pivot
      from dka_parameters
         WHERE program_code = 'DKA_SAREXTENCAISSCLIENT'
           AND parameter_name = 'Last_EXTENCAISSCLIENT_Date';

      v_file := 'ENCAISSEMENTS_CLIENTS_'||TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')||'.csv';
      Output_Header;
 
       ----- Load dka_rb_lines 
   delete from DKA_RB_LINES; 
   commit;
 
  insert into DKA_RB_LINES
  (select * from rb_lines rla
   where  
    matching_status='Y'
   AND RLA.line_type                = 'A'
   and RLA.application_id = 222
   and rla.MATCHING_SYSDATE>to_date(pn_date_pivot, 'DD/MM/YYYY HH24:MI:SS') )
       ; 
    commit;
  
    Extraction_encaissements_clients(v_errbuf,v_retcode,pn_date_pivot,pn_nb_lignes_ec);

    IF v_retcode = 2
      THEN
          Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
          RAISE Erreur_Programme;
    ELSIF v_retcode = 1
    THEN
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Il y''a aucune donnèe è traiter.');
      Pv_Errbuf  := v_errbuf;
          Pn_Retcode := v_retcode;
    ELSIF v_retcode = 0
    THEN
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Date de dernière exécution de l''export : ' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Nom du fichier généré : ' || v_file);
    Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Nombre des lignes générées dans le fichier  : ' || pn_nb_lignes_ec);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)|| 'Fin normale du traitement.');
          Pn_Retcode := v_retcode;
      END IF;

      output_end;

  EXCEPTION
        WHEN Erreur_Programme THEN
            Pn_Retcode   := 2;
            Pv_Errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||' Extraction_encaissements_clients '||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.LOG, '==> Fin de la procédure '||' Extraction_encaissements_clients '||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
       WHEN OTHERS
       THEN
           fnd_concurrent.af_rollback;
           Pn_Retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SAREXTENCAISSCLIENT_PKG.' || ' Extraction_encaissements_clients '||CHR(10)||' A retournè     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           Pv_Errbuf := SQLERRM;
END main;

END DKA_SAREXTENCAISSCLIENT_PKG;
/
SHOW ERRORS
EXIT