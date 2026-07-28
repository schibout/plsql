          gv_step := 'INSERT_AR_DATA 000 - DEBUT.';
          /*INSERT INTO DKA_SCTLFLUX_ARFLAG_EAI
            SELECT DISTINCT
             dii.origin,
             dii.company_code,
             dii.invoice_number,
             dii.fic_ident,
             cn_num_traitement,
             gn_user_id,
             sysdate
            from
             DKA_IARPAFAC_INTERFACE dii
            where
              nvl(DII.OA_STATUS, 'P') != 'A'
              AND (DII.ORIGIN IS NULL OR
                  DII.ORIGIN = nvl('CYC', DII.ORIGIN))
              AND DII.CREATION_DATE >= to_date('09/12/2025','DD/MM/YYYY')
              AND DII.CREATION_DATE <= nvl(to_date('10/12/2025','DD/MM/YYYY'), SYSDATE)
              AND EXISTS
                   (SELECT 'X'
                     FROM FND_FLEX_VALUES_VL ffv,
                          fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
                      and ffvs.flex_value_set_id = ffv.flex_value_set_id
                      AND ffv.ENABLED_FLAG = 'Y'
                      AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                      AND ffv.ATTRIBUTE1 = DII.ORIGIN)
              AND (gv_reprise = 'Y' OR NOT EXISTS (SELECT NULL
                                                   FROM DKA_SCTLFLUX_ARFLAG_EAI dsae
                                                   WHERE
                                                     dsae.origin = dii.origin
                                                    AND dsae.company_code = dii.company_code
                                                    AND dsae.invoice_number = dii.invoice_number
                                                    AND dsae.fic_ident = dii.fic_ident ));*/

          gv_step := 'INSERT_AR_DATA 001 - CONTRÔLE DE FLUX DKA_IARPAFAC_INTERFACE.';
          lstep = 'DKA_SCTLFLUX_EAI';
          /*INSERT INTO DKA_SCTLFLUX_EAI
               (CODE_FOLIO,
                DATE_EXEC,
                NB_PIECE,
                DEBIT,
                CREDIT,
                FICHIER,
                TRAITE,
                N_TRAITEMENT,
                DATE_DEBUT,
                DATE_FIN,
                CREATED_BY,
                CREATION_DATE)*/
               SELECT DII.ORIGIN, -- CODE_FOLIO
                      TO_CHAR(MIN(TRUNC(dii.creation_date)),'DD/MM/YYYY'),--JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(DISTINCT DII.INVOICE_NUMBER || ORIGIN ||
                            CATEGORY || FIC_IDENT), -- NB_PIECE
                      SUM(DECODE(SUBSTR(dii.local_account, 1, 3),
                                 '411', NVL(DECODE(NVL(DII.TYPMVT,
                                                       DECODE(DII.DEBIT_OR_CREDIT,
                                                              'C', 'SYST_AMONT_AVOIR',
                                                              'FACTURE')),
                                                   'SYST_AMONT_AVOIR',     (-1) * NVL(DII.FMT_AMOUNT, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                                   'SYST_AMONT_ANNUL_AVO', (-1) * NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                                   NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100)),
                                            0),
                                 0)), -- DEBIT
                      SUM(DECODE(SUBSTR(dii.local_account, 1, 3),
                                 '411', 0,
                                 NVL(DECODE(NVL(DII.TYPMVT,
                                                DECODE(DII.DEBIT_OR_CREDIT,
                                                       'C', 'SYST_AMONT_AVOIR',
                                                       'FACTURE')),
                                            'SYST_AMONT_AVOIR',     (-1) * NVL(DII.FMT_AMOUNT, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                            'SYST_AMONT_ANNUL_AVO', (-1) * NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                            NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100)),
                                     0)
                                )), -- CREDIT
                      DII.FIC_IDENT, -- FICHIER
                      0, -- TRAITE
                      46463898 cn_num_traitement, -- N_TRAITEMENT
                      trunc(to_date('09/12/2025','DD/MM/YYYY')), -- DATE_DEBUT
                      trunc(nvl(to_date('10/12/2025','DD/MM/YYYY'), SYSDATE)), -- DATE_FIN
                      -1 gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM DKA_IARPAFAC_INTERFACE DII
                WHERE
                  nvl(DII.OA_STATUS, 'P') != 'A'
                  AND (DII.ORIGIN IS NULL OR
                      DII.ORIGIN = nvl('CYC', DII.ORIGIN))
                  AND DII.CREATION_DATE >= to_date('09/12/2025','DD/MM/YYYY')
                  AND DII.CREATION_DATE <= nvl(to_date('10/12/2025','DD/MM/YYYY'), SYSDATE)
                  AND EXISTS
                       (SELECT 'X'
                         FROM FND_FLEX_VALUES_VL ffv,
                              fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
                          and ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.ENABLED_FLAG = 'Y'
                          AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                          AND ffv.ATTRIBUTE1 = DII.ORIGIN)
                  AND EXISTS ( SELECT NULL
                               FROM DKA_SCTLFLUX_ARFLAG_EAI dsae
                               WHERE
                                 dsae.origin = dii.origin
                                AND dsae.company_code = dii.company_code
                                AND dsae.invoice_number = dii.invoice_number
                                AND dsae.fic_ident = dii.fic_ident
                                AND dsae.request_id = 46463898)
                GROUP BY DII.ORIGIN, DII.FIC_IDENT;
         
          gv_step := 'INSERT_AR_DATA 003 - CONTRÔLE DE FLUX RA_INTERFACE_LINES.';
          log_msg(gv_step);
          /*INSERT INTO DKA_SCTLFLUX_EAI
               (CODE_FOLIO,
                DATE_EXEC,
                NB_PIECE,
                CREDIT,
                FICHIER,
                TRAITE,
                N_TRAITEMENT,
                DATE_DEBUT,
                DATE_FIN,
                CREATED_BY,
                CREATION_DATE)*/
               SELECT RII.ATTRIBUTE9, -- CODE_FOLIO
                      TO_CHAR(MIN(TRUNC(rii.creation_date)),'DD/MM/YYYY'),--JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(DISTINCT (RII.interface_line_attribute1 || RII.interface_line_attribute2 || RII.interface_line_attribute3)), -- NB_PIECE
                      SUM(NVL(RID.AMOUNT,0)), -- CREDIT
                      RII.ATTRIBUTE10, -- FICHIER
                      1, -- TRAITE
                      46463898 cn_num_traitement, -- N_TRAITEMENT
                      trunc(to_date('09/12/2025','DD/MM/YYYY')), -- DATE_DEBUT
                      trunc(nvl(to_date('10/12/2025','DD/MM/YYYY'), SYSDATE)), -- DATE_FIN
                      -1 gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM RA_INTERFACE_LINES_ALL         RII,
                      RA_CUST_TRX_TYPES_ALL          RCCT,
                      RA_INTERFACE_DISTRIBUTIONS_ALL RID
                WHERE
                  RII.ATTRIBUTE8 = to_char(46463898)
                  AND RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
                  AND RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
                  AND SUBSTR(RID.SEGMENT3, 1, 3) = '411'
                  AND (RII.ATTRIBUTE9 IS NULL OR RII.ATTRIBUTE9 = nvl('CYC', RII.ATTRIBUTE9))
                  AND EXISTS
                       (SELECT 'X'
                         FROM FND_FLEX_VALUES_VL ffv,
                              fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
                          and ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.ENABLED_FLAG = 'Y'
                          AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                          AND ffv.ATTRIBUTE1 = RII.ATTRIBUTE9)
                  AND RII.INTERFACE_LINE_CONTEXT != 'REFAC'
                  AND nvl(RII.INTERFACE_STATUS, 'X') != 'P'
                  AND RII.CREATION_DATE >= to_date('09/12/2025','DD/MM/YYYY')
                  AND RII.CREATION_DATE <= nvl(to_date('10/12/2025','DD/MM/YYYY'), SYSDATE)
                GROUP BY RII.ATTRIBUTE9, RII.ATTRIBUTE10;
          gv_step := 'INSERT_AR_DATA 003 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT || ' A PARTIR DE RA_INTERFACE_LINES.';
          log_msg(gv_step);
          COMMIT;

          gv_step := 'INSERT_AR_DATA 004 - MAJ DEBIT EN FONCTION DE RA_INTERFACE_LINES';
          log_msg(gv_step);
          UPDATE DKA_SCTLFLUX_EAI DSE
             SET DSE.DEBIT  = (SELECT SUM(NVL(DECODE(substr(RCCT.name, 6, length(RCCT.name) - 5),
                                                     'SI_AMONT_AVOIR',  (-1) * RID.AMOUNT,
                                                     'SI_AMT_ANNUL_AV', (-1) * RID.AMOUNT,
                                                     RID.AMOUNT), 0)) -- JJA 23/09/2015 -- CORRECTION KDFI-2198
                                      --SUM(NVL(RID.AMOUNT,0))  -- DEBIT (ANCIEN CODE INCORRECT)
                                 FROM RA_INTERFACE_LINES_ALL         RII,
                                      RA_CUST_TRX_TYPES_ALL          RCCT,
                                      RA_INTERFACE_DISTRIBUTIONS_ALL RID
                                WHERE RII.ATTRIBUTE8 = to_char(46463898)
                                  AND RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
                                  AND RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
                                  AND SUBSTR(RID.SEGMENT3, 1, 3) = '411'
                                  AND DSE.CODE_FOLIO = RII.ATTRIBUTE9
                                  AND DSE.FICHIER = RII.ATTRIBUTE10
                                  AND DSE.N_TRAITEMENT = 46463898),
                 DSE.TRAITE = 0
           WHERE (DSE.CODE_FOLIO IS NULL OR
                 DSE.CODE_FOLIO = nvl('CYC', DSE.CODE_FOLIO))
             AND DSE.TRAITE = 1
             AND DSE.N_TRAITEMENT = 46463898;
         
          gv_step := 'INSERT_AR_DATA 005 - CONTRÔLE DE FLUX RA_CUSTOMER_TRX_LINES_ALL.';
          log_msg(gv_step);
          INSERT INTO DKA_SCTLFLUX_EAI
               (CODE_FOLIO,
                DATE_EXEC,
                NB_PIECE,
                CREDIT,
                FICHIER,
                TRAITE,
                N_TRAITEMENT,
                DATE_DEBUT,
                DATE_FIN,
                CREATED_BY,
                CREATION_DATE)
               SELECT RCTL.ATTRIBUTE9, -- CODE_FOLIO
                      TO_CHAR(MIN(TRUNC(RCTL.CREATION_DATE)),'DD/MM/YYYY'),--JJA - 18/05/2015to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(DISTINCT(RCTL.CUSTOMER_TRX_ID)), -- NB_PIECE
                      /*SUM(NVL(DECODE(SUBSTR(RCTT.NAME, 6, LENGTH(RCTT.NAME) - 5), 'SI_AMONT_AVOIR', (-1) *
                                      RCTL.EXTENDED_AMOUNT, 'SI_AMT_ANNUL_AV', (-1) *
                                      RCTL.EXTENDED_AMOUNT, RCTL.EXTENDED_AMOUNT), 0)), JJA 23/09/2015 */
                      SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)), -- CREDIT
                      RCTL.ATTRIBUTE10, -- FICHIER
                      1, -- TRAITE
                      46463898 cn_num_traitement, -- N_TRAITEMENT
                      trunc(to_date('09/12/2025','DD/MM/YYYY')), -- DATE_DEBUT
                      trunc(nvl(to_date('10/12/2025','DD/MM/YYYY'), SYSDATE)), -- DATE_FIN
                      -1 gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM RA_CUSTOMER_TRX_LINES_ALL    RCTL,
                      RA_CUSTOMER_TRX_ALL          RCT,
                      RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGD,
                      RA_CUST_TRX_TYPES_ALL        RCTT,
                      GL_CODE_COMBINATIONS     GCC
                WHERE
                      RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                  AND RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
                  AND RCTLGD.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                  AND RCTLGD.CUSTOMER_TRX_LINE_ID = RCTL.CUSTOMER_TRX_LINE_ID
                  AND RCTLGD.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
                  AND SUBSTR(GCC.SEGMENT3, 1, 3) != '411'
                  AND RCTL.ATTRIBUTE8 = to_char(46463898)
                  AND (RCTL.ATTRIBUTE9 IS NULL OR
                            RCTL.ATTRIBUTE9 = nvl('CYC', RCTL.ATTRIBUTE9))
                        AND EXISTS
                             (SELECT 'X'
                               FROM FND_FLEX_VALUES_VL ffv,
                                    fnd_flex_value_sets ffvs
                              WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
                                and ffvs.flex_value_set_id = ffv.flex_value_set_id
                                AND ffv.ENABLED_FLAG = 'Y'
                                AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                                AND ffv.ATTRIBUTE1 = RCTL.ATTRIBUTE9)
                  AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
                  AND RCTL.CREATION_DATE >= to_date('09/12/2025','DD/MM/YYYY')
                  AND RCTL.CREATION_DATE <= nvl(to_date('10/12/2025','DD/MM/YYYY'), SYSDATE)
                  AND EXISTS (SELECT NULL
                              FROM RA_CUSTOMER_TRX RCT
                              WHERE RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                              AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION')
                GROUP BY RCTL.ATTRIBUTE9, RCTL.ATTRIBUTE10;
          gv_step := 'INSERT_AR_DATA 005 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT || ' A PARTIR DE RA_CUSTOMER_TRX_LINES_ALL.';
          log_msg(gv_step);
          COMMIT;

          gv_step := 'INSERT_AR_DATA 006 - MAJ DEBIT EN FONCTION DE RA_CUSTOMER_TRX_LINES_ALL';
          log_msg(gv_step);
          UPDATE DKA_SCTLFLUX_EAI DSE
             SET DSE.DEBIT  = (SELECT SUM(NVL(DECODE(SUBSTR(RCTT.NAME, 6, LENGTH(RCTT.NAME) - 5), 'SI_AMONT_AVOIR', (-1) *
                                                      RCTL.EXTENDED_AMOUNT, 'SI_AMT_ANNUL_AV', (-1) *
                                                      RCTL.EXTENDED_AMOUNT, RCTL.EXTENDED_AMOUNT), 0)) -- JJA 23/09/2015 -- CORRECTION KDFI-2198
                                      --SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)) --DEBIT (ANCIEN CODE INCORRECT)
                                 FROM RA_CUSTOMER_TRX_LINES_ALL    RCTL,
                                      RA_CUSTOMER_TRX_ALL          RCT,
                                      RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGD,
                                      RA_CUST_TRX_TYPES_ALL        RCTT,
                                      GL_CODE_COMBINATIONS     GCC
                                WHERE RCTL.ATTRIBUTE8 = 46463898
                                  AND RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                                  AND RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
                                  AND RCTLGD.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                                  AND RCTLGD.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
                                  AND DSE.CODE_FOLIO = RCTL.ATTRIBUTE9
                                  AND DSE.FICHIER = RCTL.ATTRIBUTE10
                                  AND DSE.N_TRAITEMENT = 46463898
                                  AND SUBSTR(GCC.SEGMENT3, 1, 3) = '411'),
                 DSE.TRAITE = 0
           WHERE (DSE.CODE_FOLIO IS NULL OR
                 DSE.CODE_FOLIO = nvl('CYC', DSE.CODE_FOLIO))
             AND DSE.TRAITE = 1
             AND DSE.N_TRAITEMENT = 46463898;
         