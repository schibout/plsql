create or replace PACKAGE BODY      DKA_SCTLFLUX_EAI_PKG AS
     ------------------------------------------------------------------------
     -- $Id: APPS.DKA_SCTLFLUX_EAI_PKG.pkb
     -- Capgemini
     -- Nom              : DKA_SCTLFLUX_EAI_PKG.pkb
     -- Description      : Corps du package DKA_SCTLFLUX_EAI_PKG
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 25/08/2014
     -- Doc. associée    :
     -- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
     ------------------------------------------------------------------------
     -- Historique
     -- Date       Qui Description
     -- ---------- --- ------------------------------------------------------
     -- 18/05/2015 JJA Correction de la date - on utlise la + petite date de
     --                création des piece
     -- 22/05/2015 JJA Correction décompte du nombre de piece dans GL_INTERFACE
     -- 23/09/2015 JJA DPE20140071 : Sélection des sources, calcul des montants
     -- 04/05/2016 RAZ Migration R12 - SPE186 Migration Extraction du contrôle des flux OA
     -- 04/11/2016 JJA artf2039715 : SPE186 - Modification du nom du fichier
     -- 01/02/2017 YWA artf2093138 
     -- 23/02/2017 YWA artf2105170 
     -- 02/05/2017 YWA artf2147003
     -- 12/02/2017 MEG artf2153115 : SPE186 - Utilisation des tables _ALL - Defect Bout_en_Bout_Helios_Ref #660
     -- 30/08/2017 OBE artf2216795 : SPE186 - Restriction aux livres primaires - Defect Beb #1062
     -- 24/01/2018 OBE artf2324535 : SPE186 - Controle de flux - Colonne crédit vide  
     -- 25/11/2019 SEL artf07326817: SPE186 - MAJ folio et nom de fichier de RA_CUSTOMER_TRX_LINES_ALL pour les lignes de taxe 
   -- 01/06/2023 IBA EDB295 Remboursement Avoir Client (lot 2)
     -- ---------- --- ------------------------------------------------------


     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     -- CONSTANTES ET VARIABLES PRIVEES
     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

     cn_num_traitement CONSTANT NUMBER := fnd_profile.value('CONC_REQUEST_ID');
     --gn_org_id  NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
     --gn_sob     NUMBER := TO_NUMBER(FND_PROFILE.VALUE('GL_SET_OF_BKS_ID'));
     gn_user_id NUMBER := TO_NUMBER(FND_PROFILE.VALUE('USER_ID'));
     gv_nom_fichier    VARCHAR2(150);
     
     gv_step    VARCHAR2(500);
     gv_reprise VARCHAR2(1);

     -----------------------------------------------------------------
     --  Nom           : OUT_MSG
     --  Description   : procedure d'affichage des messages
     --
     --  PARAMETRES :
     --   p_message          texte a imprimer dans la sortie
     --
     -----------------------------------------------------------------
     PROCEDURE out_msg(p_message in varchar2) IS
     BEGIN
          -- Ecriture dans le fichier de sortie
          fnd_file.put_line(fnd_file.output, p_message);
     END out_msg;

     -----------------------------------------------------------------
     --  Nom           : LOG_MSG
     --  Description   : procedure d'affichage des messages
     --
     --  PARAMETRES :
     --   p_message      texte a imprimer dans le log
     --
     -----------------------------------------------------------------
     PROCEDURE log_msg(p_message in varchar2) IS
          l_message VARCHAR2(1000);
     BEGIN

          l_message := SUBSTR(p_message, 1, 1000);

          IF (l_message IS NULL) THEN
               l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
          END IF;

          fnd_file.put_line(fnd_file.LOG, l_message);
     END log_msg;

     -------------------------------------------------------------------------------
     --  Nom           : INSERT_GL_DATA
     --  Description   : Procédure d'insertion des données a extraire pour GL
     --
     --  PARAMETRES   :   pv_retcode              Code retour.
     --                   pn_errbuf               Description de l'erreur.
     --                pv_folio              Folio.
     --                pd_date_debut      Date de début.
     --                pd_date_fin        Date de fin.
     -------------------------------------------------------------------------------
     PROCEDURE INSERT_GL_DATA(pv_errbuf     OUT VARCHAR2,
                              pn_retcode    OUT NUMBER,
                              pv_folio      IN VARCHAR2,
                              pd_date_debut IN DATE,
                              pd_date_fin   IN DATE) IS
     BEGIN
          gv_step := 'INSERT_GL_DATA 000 - DEBUT.';
          log_msg(gv_step);

          gv_step := 'INSERT_GL_DATA 001A - FLAG GL_INTERFACE.';
          log_msg(gv_step);
          update  GL_INTERFACE GI
          set GI.attribute5 = cn_num_traitement
          WHERE
           --(GI.ATTRIBUTE9 IS NULL OR
                GI.ATTRIBUTE9 = nvl(pv_folio, GI.ATTRIBUTE9)--)--YWA artf2093138 
            AND EXISTS
                (SELECT 'X'
                   FROM FND_FLEX_VALUES_VL ffv,
                        fnd_flex_value_sets ffvs
                  WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_GL'
                    and ffvs.flex_value_set_id = ffv.flex_value_set_id
                    AND ffv.ENABLED_FLAG = 'Y'
                    AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                    AND ffv.ATTRIBUTE1 = GI.ATTRIBUTE9)
            AND GI.DATE_CREATED >= pd_date_debut
            AND GI.DATE_CREATED <= nvl(pd_date_fin, SYSDATE)
            --AND GI.LEDGER_ID = gn_sob   -- RAZ Migration R12 --YWA artf2093138 
            AND (GI.attribute5 is null or gv_reprise = 'Y')
            --< OBE artf2216795
            AND GI.ledger_id IN (SELECT ledger_id
                                 FROM gl_ledgers
                                 WHERE ledger_category_code = 'PRIMARY')
            --> OBE artf2216795
            ;

          gv_step := 'INSERT_GL_DATA 001 - CONTRÔLE DE FLUX GL_INTERFACE.';
          log_msg(gv_step);
          INSERT INTO DKA_SCTLFLUX_EAI
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
                CREATION_DATE)
               SELECT GI.ATTRIBUTE9, -- CODE_FOLIO
                      TO_CHAR(MIN(trunc(gi.DATE_CREATED)),'DD/MM/YYYY'),--JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(DISTINCT (attribute9 ||'|'||reference4)), -- NB_PIECE --JJA - 22/05/2015
                      SUM(GI.Entered_Dr), -- DEBIT
                      SUM(GI.Entered_Cr), -- CREDIT
                      GI.ATTRIBUTE10, -- FICHIER
                      0, -- TRAITE
                      cn_num_traitement, -- N_TRAITEMENT
                      trunc(pd_date_debut), -- DATE_DEBUT
                      trunc(nvl(pd_date_fin, SYSDATE)), -- DATE_FIN
                      gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM GL_INTERFACE GI
                WHERE --(GI.ATTRIBUTE9 IS NULL OR
                      GI.ATTRIBUTE9 = nvl(pv_folio, GI.ATTRIBUTE9)--)--YWA artf2093138 
                  AND EXISTS
                      (SELECT 'X'
                         FROM FND_FLEX_VALUES_VL ffv,
                              fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_GL'
                          and ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.ENABLED_FLAG = 'Y'
                          AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                          AND ffv.ATTRIBUTE1 = GI.ATTRIBUTE9)
                  AND GI.DATE_CREATED >= pd_date_debut
                  AND GI.DATE_CREATED <= nvl(pd_date_fin, SYSDATE)
                  --AND GI.LEDGER_ID = gn_sob   -- RAZ Migration R12 --YWA artf2093138 
                  AND GI.attribute5 = to_char(cn_num_traitement)
                GROUP BY GI.ATTRIBUTE9, GI.ATTRIBUTE10;

          gv_step := 'INSERT_GL_DATA 002 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT || ' A PARTIR DE GL_INTERFACE.';
          log_msg(gv_step);
          COMMIT;

          gv_step := 'INSERT_GL_DATA 003A - FLAG GL_JE_HEADERS ET GL_JE_LINES.';
          log_msg(gv_step);
          UPDATE GL_JE_LINES GJL
          SET ATTRIBUTE5 =  cn_num_traitement
          WHERE
                GJL.CREATION_DATE >= pd_date_debut
            AND GJL.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
            AND --(GJL.ATTRIBUTE9 IS NULL OR
                GJL.ATTRIBUTE9 = nvl(pv_folio, GJL.ATTRIBUTE9)--)--YWA artf2093138 
            AND EXISTS
                (SELECT 'X'
                   FROM FND_FLEX_VALUES_VL ffv,
                        fnd_flex_value_sets ffvs
                  WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_GL'
                    and ffvs.flex_value_set_id = ffv.flex_value_set_id
                    AND ffv.ENABLED_FLAG = 'Y'
                    AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                    AND ffv.ATTRIBUTE1 = GJL.ATTRIBUTE9)
            --AND GJL.ledger_id = gn_sob  -- RAZ Migration R12--YWA artf2093138 
            AND EXISTS (SELECT 'non contrepassé'
                        FROM GL_JE_HEADERS GJH
                        WHERE GJL.JE_HEADER_ID = GJH.JE_HEADER_ID
                          AND GJH.REVERSED_JE_HEADER_ID IS NULL )
            AND (GJL.attribute5 is null or gv_reprise = 'Y')
            --< OBE artf2216795
            AND GJL.ledger_id IN (SELECT ledger_id
                                  FROM gl_ledgers
                                  WHERE ledger_category_code = 'PRIMARY')            
            --> OBE artf2216795
            ;


          gv_step := 'INSERT_GL_DATA 003 - CONTRÔLE DE FLUX GL_JE_HEADERS ET GL_JE_LINES.';
          log_msg(gv_step);
          INSERT INTO DKA_SCTLFLUX_EAI
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
                CREATION_DATE)
               SELECT GJL.ATTRIBUTE9, -- CODE_FOLIO
                      TO_CHAR(MIN(trunc(gjl.creation_date)),'DD/MM/YYYY'), --JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(DISTINCT GJL.JE_HEADER_ID), -- NB_PIECE
                      SUM(GJL.Entered_Dr), -- DEBIT
                      SUM(GJL.Entered_Cr), -- CREDIT
                      GJL.ATTRIBUTE10, -- FICHIER
                      0, -- TRAITE
                      cn_num_traitement, -- N_TRAITEMENT
                      trunc(pd_date_debut), -- DATE_DEBUT
                      trunc(nvl(pd_date_fin, SYSDATE)), -- DATE_FIN
                      gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM GL_JE_LINES GJL
                WHERE
                      GJL.CREATION_DATE >= pd_date_debut
                  AND GJL.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
                  AND --(GJL.ATTRIBUTE9 IS NULL OR
                      GJL.ATTRIBUTE9 = nvl(pv_folio, GJL.ATTRIBUTE9)--)--YWA artf2093138 
                  AND EXISTS
                      (SELECT 'X'
                         FROM FND_FLEX_VALUES_VL ffv,
                              fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_GL'
                          and ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.ENABLED_FLAG = 'Y'
                          AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                          AND ffv.ATTRIBUTE1 = GJL.ATTRIBUTE9)
                  --AND GJL.LEDGER_ID = gn_sob   -- RAZ Migration R12--YWA artf2093138 
                  AND EXISTS (SELECT 'non contrepassé'
                              FROM GL_JE_HEADERS GJH
                              WHERE GJL.JE_HEADER_ID = GJH.JE_HEADER_ID
                                AND GJH.REVERSED_JE_HEADER_ID IS NULL )
                  AND ATTRIBUTE5 =  to_char(cn_num_traitement)
                GROUP BY GJL.ATTRIBUTE9, GJL.ATTRIBUTE10;

          gv_step := 'INSERT_GL_DATA 004 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT ||
                     ' A PARTIR DE GL_JE_HEADERS / GL_JE_LINES.';
          log_msg(gv_step);
          COMMIT;
          gv_step := 'INSERT_GL_DATA 999 - FIN.';
          log_msg(gv_step);
     EXCEPTION
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'INSERT_GL_DATA 999 - ERROR - ' || SQLERRM;
               log_msg(pv_errbuf);
     END INSERT_GL_DATA;

     -------------------------------------------------------------------------------
     --  Nom           : INSERT_AP_DATA
     --  Description   : Procédure d'insertion des données a extraire pour AP
     --
     --  PARAMETRES   :   pv_retcode              Code retour.
     --                   pn_errbuf               Description de l'erreur.
     --               pv_folio              Folio.
     --               pd_date_debut      Date de début.
     --               pd_date_fin        Date de fin.
     -------------------------------------------------------------------------------
     PROCEDURE INSERT_AP_DATA(pv_errbuf     OUT VARCHAR2,
                              pn_retcode    OUT NUMBER,
                              pv_folio      IN VARCHAR2,
                              pd_date_debut IN DATE,
                              pd_date_fin   IN DATE) IS
     BEGIN
          gv_step := 'INSERT_AP_DATA 000 - DEBUT.';
          log_msg(gv_step);

          gv_step := 'INSERT_AP_DATA 001A - FLAG AP_INVOICES_INTERFACE.';
          log_msg(gv_step);
          UPDATE   AP_INVOICES_INTERFACE      AII
          SET ATTRIBUTE7 =  cn_num_traitement
          WHERE
            nvl(AII.STATUS, 'X') != 'PROCESSED'
            AND --(AII.ATTRIBUTE9 IS NULL OR
                AII.ATTRIBUTE9 = nvl(pv_folio, AII.ATTRIBUTE9)--)--YWA artf2093138 
            AND EXISTS
                 (SELECT 'X'
                   FROM FND_FLEX_VALUES_VL ffv,
                        fnd_flex_value_sets ffvs
                  WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AP'
                    and ffvs.flex_value_set_id = ffv.flex_value_set_id
                    AND ffv.ENABLED_FLAG = 'Y'
                    AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                    AND ffv.ATTRIBUTE1 = AII.ATTRIBUTE9)
            AND AII.SOURCE != 'REFAC'
            AND AII.CREATION_DATE >= pd_date_debut
            AND AII.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
            --AND AII.ORG_ID = gn_org_id --YWA artf2093138 
            AND (AII.attribute7 IS NULL OR gv_reprise = 'Y')
      and AII.INVOICE_TYPE_LOOKUP_CODE <> 'PAYMENT REQUEST'  ---IBA EDB295 lot2
      ;

          gv_step := 'INSERT_AP_DATA 001 - CONTRÔLE DE FLUX AP_INVOICES_INTERFACE.';
          log_msg(gv_step);
          INSERT INTO DKA_SCTLFLUX_EAI
               (CODE_FOLIO,
                DATE_EXEC,
                NB_PIECE,
                DEBIT,
                FICHIER,
                TRAITE,
                N_TRAITEMENT,
                DATE_DEBUT,
                DATE_FIN,
                CREATED_BY,
                CREATION_DATE)
               SELECT AII.ATTRIBUTE9, -- CODE_FOLIO
                      TO_CHAR(MIN(TRUNC(AII.CREATION_DATE)),'DD/MM/YYYY'),--JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(1), -- NB_PIECE
                      /*SUM(NVL(DECODE(AII.INVOICE_TYPE_LOOKUP_CODE, 'STANDARD', AII.INVOICE_AMOUNT, (-1) *
                                      AII.INVOICE_AMOUNT), 0)) JJA 23/09/2015*/
                      SUM(NVL(AII.INVOICE_AMOUNT,0)), -- DEBIT
                      AII.ATTRIBUTE10, -- FICHIER
                      1, -- TRAITE
                      cn_num_traitement, -- N_TRAITEMENT
                      trunc(pd_date_debut), -- DATE_DEBUT
                      trunc(nvl(pd_date_fin, SYSDATE)), -- DATE_FIN
                      gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM AP_INVOICES_INTERFACE      AII
                WHERE nvl(AII.STATUS, 'X') != 'PROCESSED'
                  AND --(AII.ATTRIBUTE9 IS NULL OR
                      AII.ATTRIBUTE9 = nvl(pv_folio, AII.ATTRIBUTE9)--)--YWA artf2093138 
                  AND EXISTS
                       (SELECT 'X'
                         FROM FND_FLEX_VALUES_VL ffv,
                              fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AP'
                          and ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.ENABLED_FLAG = 'Y'
                          AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                          AND ffv.ATTRIBUTE1 = AII.ATTRIBUTE9)
                  AND AII.SOURCE != 'REFAC'
                  AND AII.CREATION_DATE >= pd_date_debut
                  AND AII.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
                  --AND AII.ORG_ID = gn_org_id --YWA artf2093138 
                  AND ATTRIBUTE7 =  to_char(cn_num_traitement)
          and AII.INVOICE_TYPE_LOOKUP_CODE <> 'PAYMENT REQUEST'  ---IBA EDB295 lot2
                GROUP BY AII.ATTRIBUTE9, AII.ATTRIBUTE10;
          gv_step := 'INSERT_AP_DATA 002 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT || ' A PARTIR DE AP_INVOICES_INTERFACE.';
          log_msg(gv_step);
          COMMIT;

          gv_step := 'INSERT_AP_DATA 005 - MAJ CREDIT EN FONCTION DE AP_INVOICE_DISTRIBUTIONS';
          log_msg(gv_step);
          UPDATE DKA_SCTLFLUX_EAI DSE
             SET DSE.CREDIT = (SELECT /*SUM(NVL(DECODE(AII.INVOICE_TYPE_LOOKUP_CODE, 'STANDARD', AILI.AMOUNT, (-1) *
                                                      AILI.AMOUNT), 0)) JJA 23/09/2015 */
                                      SUM(AILI.AMOUNT)
                                 FROM AP_INVOICES_INTERFACE      AII,
                                      AP_INVOICE_LINES_INTERFACE AILI
                                WHERE AII.INVOICE_ID = AILI.INVOICE_ID
                                  AND nvl(AII.STATUS, 'X') != 'PROCESSED'
                                  AND AII.ATTRIBUTE7 =  to_char(cn_num_traitement)
                                  AND DSE.CODE_FOLIO = AII.ATTRIBUTE9
                                  AND DSE.FICHIER = AII.ATTRIBUTE10
                                  AND DSE.N_TRAITEMENT = cn_num_traitement
                  and AII.INVOICE_TYPE_LOOKUP_CODE <> 'PAYMENT REQUEST' ---IBA EDB295 lot2
                  ),
                 DSE.TRAITE = 0
           WHERE (DSE.CODE_FOLIO IS NULL OR
                 DSE.CODE_FOLIO = nvl(pv_folio, DSE.CODE_FOLIO))
             AND DSE.TRAITE = 1
             AND DSE.N_TRAITEMENT = cn_num_traitement;
          COMMIT;

          gv_step := 'INSERT_AP_DATA 003A - FLAG AP_INVOICES_ALL.';
          log_msg(gv_step);
          UPDATE   AP_INVOICES_ALL      AIA
          SET ATTRIBUTE7 =  cn_num_traitement
          WHERE
            AIA.SOURCE NOT IN ('Manual Invoice Entry', 'REFAC')
            AND --(AIA.ATTRIBUTE9 IS NULL OR
                AIA.ATTRIBUTE9 = nvl(pv_folio, AIA.ATTRIBUTE9)--)--YWA artf2093138 
            AND EXISTS
                 (SELECT 'X'
                   FROM FND_FLEX_VALUES_VL ffv,
                        fnd_flex_value_sets ffvs
                  WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AP'
                    and ffvs.flex_value_set_id = ffv.flex_value_set_id
                    AND ffv.ENABLED_FLAG = 'Y'
                    AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                    AND ffv.ATTRIBUTE1 = AIA.ATTRIBUTE9)
            AND AIA.CREATION_DATE >= pd_date_debut
            AND AIA.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
            AND (AIA.attribute7 IS NULL OR gv_reprise = 'Y')
      and AIA.INVOICE_TYPE_LOOKUP_CODE <> 'PAYMENT REQUEST'  ---IBA EDB295 lot2
      ;


          gv_step := 'INSERT_AP_DATA 003 - CONTRÔLE DE FLUX AP_INVOICES_ALL.';
          log_msg(gv_step);
          INSERT INTO DKA_SCTLFLUX_EAI
               (CODE_FOLIO,
                DATE_EXEC,
                NB_PIECE,
                DEBIT,
                FICHIER,
                TRAITE,
                N_TRAITEMENT,
                DATE_DEBUT,
                DATE_FIN,
                CREATED_BY,
                CREATION_DATE)
               SELECT AIA.ATTRIBUTE9, -- CODE_FOLIO
                      TO_CHAR(MIN(TRUNC(AIA.CREATION_DATE)),'DD/MM/YYYY'),--JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(1), -- NB_PIECE
                      /*SUM(NVL(DECODE(AIA.INVOICE_TYPE_LOOKUP_CODE, 'STANDARD', AIA.INVOICE_AMOUNT, (-1) *
                                      AIA.INVOICE_AMOUNT), 0)) JJA 23/09/2015*/
                      SUM(NVL(AIA.INVOICE_AMOUNT,0)), -- DEBIT
                      AIA.ATTRIBUTE10, -- FICHIER
                      1, -- TRAITE
                      cn_num_traitement, -- N_TRAITEMENT
                      trunc(pd_date_debut), -- DATE_DEBUT
                      trunc(nvl(pd_date_fin, SYSDATE)), -- DATE_FIN
                      gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM AP_INVOICES_ALL AIA
                WHERE  AIA.SOURCE NOT IN ('Manual Invoice Entry', 'REFAC')
                  AND --(AIA.ATTRIBUTE9 IS NULL OR
                      AIA.ATTRIBUTE9 = nvl(pv_folio, AIA.ATTRIBUTE9)--)--YWA artf2093138 
                  AND EXISTS
                       (SELECT 'X'
                         FROM FND_FLEX_VALUES_VL ffv,
                              fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AP'
                          and ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.ENABLED_FLAG = 'Y'
                          AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                          AND ffv.ATTRIBUTE1 = AIA.ATTRIBUTE9)
                  AND AIA.CREATION_DATE >= pd_date_debut
                  AND AIA.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
                  AND ATTRIBUTE7 =  to_char(cn_num_traitement)
          and AIA.INVOICE_TYPE_LOOKUP_CODE <> 'PAYMENT REQUEST'  ---IBA EDB295 lot2
                GROUP BY AIA.ATTRIBUTE9, AIA.ATTRIBUTE10;
          gv_step := 'INSERT_AP_DATA 004 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT || ' A PARTIR DE AP_INVOICES_ALL.';
          log_msg(gv_step);
          COMMIT;

          gv_step := 'INSERT_AP_DATA 005 - MAJ CREDIT EN FONCTION DE AP_INVOICE_DISTRIBUTIONS';
          log_msg(gv_step);
          UPDATE DKA_SCTLFLUX_EAI DSE
             SET DSE.CREDIT = (SELECT /*SUM(NVL(DECODE(AIA.INVOICE_TYPE_LOOKUP_CODE, 'STANDARD', AIDA.AMOUNT, (-1) *
                                                      AIDA.AMOUNT), 0)) JJA 23/09/2015 */
                                      SUM(AILA.AMOUNT)
                                 FROM AP_INVOICES_ALL              AIA,
                                      --AP_INVOICE_DISTRIBUTIONS_ALL AIDA -- OBE artf2324535
                    AP_INVOICE_LINES_ALL         AILA   -- OBE artf2324535
                                WHERE AIA.INVOICE_ID = AILA.INVOICE_ID
                                  AND AIA.ATTRIBUTE7 =  to_char(cn_num_traitement)
                                  AND DSE.CODE_FOLIO = AIA.ATTRIBUTE9
                                  AND DSE.FICHIER = AIA.ATTRIBUTE10
                                  AND DSE.CREATED_BY = gn_user_id
                                  AND DSE.N_TRAITEMENT = cn_num_traitement
                  and AIA.INVOICE_TYPE_LOOKUP_CODE <> 'PAYMENT REQUEST'  ---IBA EDB295 lot2
                  ),
                 DSE.TRAITE = 0
           WHERE (DSE.CODE_FOLIO IS NULL OR
                 DSE.CODE_FOLIO = nvl(pv_folio, DSE.CODE_FOLIO))
             AND DSE.TRAITE = 1
             AND DSE.N_TRAITEMENT = cn_num_traitement;
          COMMIT;
          gv_step := 'INSERT_AP_DATA 999 - FIN.';
          log_msg(gv_step);
     EXCEPTION
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'INSERT_AP_DATA 999 - ERROR - ' || SQLERRM;
               log_msg(pv_errbuf);
     END INSERT_AP_DATA;

     -------------------------------------------------------------------------------
     --  Nom           : INSERT_AR_DATA
     --  Description   : Procédure d'insertion des données a extraire pour AP
     --
     --  PARAMETRES   :   pv_retcode              Code retour.
     --                   pn_errbuf               Description de l'erreur.
     --               pv_folio              Folio.
     --               pd_date_debut      Date de début.
     --               pd_date_fin        Date de fin.
     -------------------------------------------------------------------------------
     PROCEDURE INSERT_AR_DATA(pv_errbuf     OUT VARCHAR2,
                              pn_retcode    OUT NUMBER,
                              pv_folio      IN VARCHAR2,
                              pd_date_debut IN DATE,
                              pd_date_fin   IN DATE) IS
     BEGIN
          gv_step := 'INSERT_AR_DATA 000 - DEBUT.';
          log_msg(gv_step);

          gv_step := 'INSERT_AR_DATA 001A - FLAG DKA_IARPAFAC_INTERFACE.';
          log_msg(gv_step);
          --INSERT TABLE FLAG
          INSERT INTO DKA_SCTLFLUX_ARFLAG_EAI
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
                  DII.ORIGIN = nvl(pv_folio, DII.ORIGIN))
              AND DII.CREATION_DATE >= pd_date_debut
              AND DII.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
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
                                                    AND dsae.fic_ident = dii.fic_ident ));

          gv_step := 'INSERT_AR_DATA 001 - CONTRÔLE DE FLUX DKA_IARPAFAC_INTERFACE.';
          log_msg(gv_step);
          INSERT INTO DKA_SCTLFLUX_EAI
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
                CREATION_DATE)
               SELECT DII.ORIGIN, -- CODE_FOLIO
                      TO_CHAR(MIN(TRUNC(dii.creation_date)),'DD/MM/YYYY'),--JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(DISTINCT DII.INVOICE_NUMBER || ORIGIN ||
                            CATEGORY || FIC_IDENT), -- NB_PIECE
                      SUM(DECODE(SUBSTR(dii.local_account, 1, 3),
                                 '411', NVL(DECODE(NVL(DII.TYPMVT,
                                                       DECODE(DII.DEBIT_OR_CREDIT,
                                                              'C', 'SYST_AMONT_AVOIR',
                                                              'FACTURE')),
                                                   'SYST_AMONT_AVOIR',     (1) * NVL(DII.FMT_AMOUNT, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                                   'SYST_AMONT_ANNUL_AVO', (1) * NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                                   NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100)),
                                            0),
                                 0)), -- DEBIT
                      SUM(DECODE(SUBSTR(dii.local_account, 1, 3),
                                 '411', 0,
                                 NVL(DECODE(NVL(DII.TYPMVT,
                                                DECODE(DII.DEBIT_OR_CREDIT,
                                                       'C', 'SYST_AMONT_AVOIR',
                                                       'FACTURE')),
                                            'SYST_AMONT_AVOIR',     (1) * NVL(DII.FMT_AMOUNT, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                            'SYST_AMONT_ANNUL_AVO', (1) * NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100),
                                            NVL(dii.fmt_amount, TO_NUMBER(dii.SIGN || translate(dii.amount, '0123456789' || translate(dii.amount, 'A0123456789', 'A'), '0123456789')) / 100)),
                                     0)
                                )), -- CREDIT
                      DII.FIC_IDENT, -- FICHIER
                      0, -- TRAITE
                      cn_num_traitement, -- N_TRAITEMENT
                      trunc(pd_date_debut), -- DATE_DEBUT
                      trunc(nvl(pd_date_fin, SYSDATE)), -- DATE_FIN
                      gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM DKA_IARPAFAC_INTERFACE DII
                WHERE
                  nvl(DII.OA_STATUS, 'P') != 'A'
                  AND (DII.ORIGIN IS NULL OR
                      DII.ORIGIN = nvl(pv_folio, DII.ORIGIN))
                  AND DII.CREATION_DATE >= pd_date_debut
                  AND DII.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
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
                                AND dsae.request_id = cn_num_traitement)
                GROUP BY DII.ORIGIN, DII.FIC_IDENT;
          gv_step := 'INSERT_AR_DATA 002 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT || ' A PARTIR DE DKA_IARPAFAC_INTERFACE.';
          log_msg(gv_step);
          COMMIT;

          gv_step := 'INSERT_AR_DATA 003A - FLAG RA_INTERFACE_LINES.';
          log_msg(gv_step);
          UPDATE RA_INTERFACE_LINES RIL
          SET ATTRIBUTE8 = cn_num_traitement
          WHERE
           (RIL.ATTRIBUTE9 IS NULL OR RIL.ATTRIBUTE9 = nvl(pv_folio, RIL.ATTRIBUTE9))
            AND EXISTS
                 (SELECT 'X'
                   FROM FND_FLEX_VALUES_VL ffv,
                        fnd_flex_value_sets ffvs
                  WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
                    and ffvs.flex_value_set_id = ffv.flex_value_set_id
                    AND ffv.ENABLED_FLAG = 'Y'
                    AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                    AND ffv.ATTRIBUTE1 = RIL.ATTRIBUTE9)
            AND RIL.INTERFACE_LINE_CONTEXT != 'REFAC'
            AND nvl(RIL.INTERFACE_STATUS, 'X') != 'P'
            AND RIL.CREATION_DATE >= pd_date_debut
            AND RIL.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
            AND ((  RIL.attribute8 IS NULL
                OR gv_reprise = 'Y'
                )AND (NOT EXISTS (SELECT NULL
                               FROM DKA_SCTLFLUX_ARFLAG_EAI dsae
                               WHERE
                                 dsae.origin = ril.Interface_Line_Attribute1
                                AND dsae.company_code =  ril.Interface_Line_Attribute2
                                AND dsae.invoice_number =  ril.Interface_Line_Attribute3
                                AND dsae.fic_ident = ril.attribute10 )
                      OR gv_reprise = 'Y'));


          gv_step := 'INSERT_AR_DATA 003 - CONTRÔLE DE FLUX RA_INTERFACE_LINES.';
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
               SELECT RII.ATTRIBUTE9, -- CODE_FOLIO
                      TO_CHAR(MIN(TRUNC(rii.creation_date)),'DD/MM/YYYY'),--JJA - 18/05/2015 to_char(SYSDATE, 'DD/MM/YYYY'), -- DATE_EXEC
                      COUNT(DISTINCT (RII.interface_line_attribute1 || RII.interface_line_attribute2 || RII.interface_line_attribute3)), -- NB_PIECE
                      /*SUM(NVL(DECODE(substr(RCCT.name, 6, length(RCCT.name) - 5),
                                     'SI_AMONT_AVOIR',  (-1) * RID.AMOUNT,
                                     'SI_AMT_ANNUL_AV', (-1) * RID.AMOUNT,
                                     RID.AMOUNT), 0)), JJA 23/09/2015*/
                      SUM(NVL(RID.AMOUNT,0)), -- CREDIT
                      RII.ATTRIBUTE10, -- FICHIER
                      1, -- TRAITE
                      cn_num_traitement, -- N_TRAITEMENT
                      trunc(pd_date_debut), -- DATE_DEBUT
                      trunc(nvl(pd_date_fin, SYSDATE)), -- DATE_FIN
                      gn_user_id, -- CREATED_BY
                      trunc(SYSDATE) -- CREATION_DATE
                 FROM RA_INTERFACE_LINES_ALL         RII,
                      RA_CUST_TRX_TYPES_ALL          RCCT,
                      RA_INTERFACE_DISTRIBUTIONS_ALL RID
                WHERE
                  RII.ATTRIBUTE8 = to_char(cn_num_traitement)
                  AND RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
                  AND RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
                  AND SUBSTR(RID.SEGMENT3, 1, 3) != '411'
                  AND (RII.ATTRIBUTE9 IS NULL OR RII.ATTRIBUTE9 = nvl(pv_folio, RII.ATTRIBUTE9))
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
                  AND RII.CREATION_DATE >= pd_date_debut
                  AND RII.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
                GROUP BY RII.ATTRIBUTE9, RII.ATTRIBUTE10;
          gv_step := 'INSERT_AR_DATA 003 - NOMBRE D''ENREGISTREMENT INSERE : ' ||
                     SQL%ROWCOUNT || ' A PARTIR DE RA_INTERFACE_LINES.';
          log_msg(gv_step);
          COMMIT;

          gv_step := 'INSERT_AR_DATA 004 - MAJ DEBIT EN FONCTION DE RA_INTERFACE_LINES';
          log_msg(gv_step);
          UPDATE DKA_SCTLFLUX_EAI DSE
             SET DSE.DEBIT  = (SELECT /*SUM(NVL(DECODE(substr(RCCT.name, 6, length(RCCT.name) - 5),
                                                     'SI_AMONT_AVOIR',  (-1) * RID.AMOUNT,
                                                     'SI_AMT_ANNUL_AV', (-1) * RID.AMOUNT,
                                                     RID.AMOUNT), 0)) JJA 23/09/2015 */
                                      SUM(NVL(RID.AMOUNT,0))  -- DEBIT
                                 FROM RA_INTERFACE_LINES_ALL         RII,
                                      RA_CUST_TRX_TYPES_ALL          RCCT,
                                      RA_INTERFACE_DISTRIBUTIONS_ALL RID
                                WHERE RII.ATTRIBUTE8 = to_char(cn_num_traitement)
                                  AND RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
                                  AND RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
                                  AND SUBSTR(RID.SEGMENT3, 1, 3) = '411' -- Compte client uniquement
                                  AND DSE.CODE_FOLIO = RII.ATTRIBUTE9
                                  AND DSE.FICHIER = RII.ATTRIBUTE10
                                  AND DSE.N_TRAITEMENT = cn_num_traitement),
                 DSE.TRAITE = 0
           WHERE (DSE.CODE_FOLIO IS NULL OR
                 DSE.CODE_FOLIO = nvl(pv_folio, DSE.CODE_FOLIO))
             AND DSE.TRAITE = 1
             AND DSE.N_TRAITEMENT = cn_num_traitement;
          COMMIT;
      
      -- SEL - artf07326817 -- MAJ folio et nom de fichier de RA_CUSTOMER_TRX_LINES_ALL pour les lignes de taxe
          gv_step := 'INSERT_AR_DATA 005B - MAJ folio et nom de fichier de RA_CUSTOMER_TRX_LINES_ALL pour les lignes de taxe.';
          log_msg(gv_step);
          UPDATE RA_CUSTOMER_TRX_LINES_ALL rctl
          SET ATTRIBUTE9 = (select RCTL1.ATTRIBUTE9 from RA_CUSTOMER_TRX_LINES_ALL RCTL1
                                                where RCTL1.line_type='LINE' and RCTL1.customer_trx_id =RCTL.customer_trx_id
                                                and rownum<2)
      , ATTRIBUTE10 = (select RCTL1.attribute10 from RA_CUSTOMER_TRX_LINES_ALL RCTL1
                                                where RCTL1.line_type='LINE' and RCTL1.customer_trx_id =RCTL.customer_trx_id
                                                and rownum<2) 
          WHERE
           (RCTL.ATTRIBUTE9 IS NULL OR
                      RCTL.ATTRIBUTE9 = nvl(pv_folio, RCTL.ATTRIBUTE9))
                /*  AND EXISTS
                       (SELECT 'X'
                         FROM FND_FLEX_VALUES_VL ffv,
                              fnd_flex_value_sets ffvs
                        WHERE ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AR'
                          and ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.ENABLED_FLAG = 'Y'
                          AND SYSDATE between nvl(ffv.START_DATE_ACTIVE,SYSDATE) and nvl(ffv.END_DATE_ACTIVE,SYSDATE)
                          AND ffv.ATTRIBUTE1 = RCTL.ATTRIBUTE9)*/
            AND RCTL.INTERFACE_LINE_CONTEXT != 'REFAC'
            AND RCTL.CREATION_DATE >= pd_date_debut
            AND RCTL.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
            AND EXISTS (SELECT NULL
                        FROM RA_CUSTOMER_TRX RCT
                        WHERE RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                        AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION')
            AND ((  RCTL.attribute8 IS NULL
                OR gv_reprise = 'Y'
                )AND  (NOT EXISTS (SELECT NULL
                               FROM DKA_SCTLFLUX_ARFLAG_EAI dsae
                               WHERE
                                 dsae.origin = rctl.Interface_Line_Attribute1
                                AND dsae.company_code =  rctl.Interface_Line_Attribute2
                                AND dsae.invoice_number =  rctl.Interface_Line_Attribute3
                                AND dsae.fic_ident = rctl.attribute10 )
                                OR gv_reprise = 'Y'))
            and RCTL.line_type='TAX'; 
        -- SEL - FIN artf07326817
      
          gv_step := 'INSERT_AR_DATA 005A - FLAG RA_CUSTOMER_TRX_LINES_ALL.';
          log_msg(gv_step);
          UPDATE RA_CUSTOMER_TRX_LINES_ALL rctl
          SET ATTRIBUTE8 = cn_num_traitement
          WHERE
           (RCTL.ATTRIBUTE9 IS NULL OR
                      RCTL.ATTRIBUTE9 = nvl(pv_folio, RCTL.ATTRIBUTE9))
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
            AND RCTL.CREATION_DATE >= pd_date_debut
            AND RCTL.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
            AND EXISTS (SELECT NULL
                        FROM RA_CUSTOMER_TRX RCT
                        WHERE RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                        AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION')
            AND ((  RCTL.attribute8 IS NULL
                OR gv_reprise = 'Y'
                )AND  (NOT EXISTS (SELECT NULL
                               FROM DKA_SCTLFLUX_ARFLAG_EAI dsae
                               WHERE
                                 dsae.origin = rctl.Interface_Line_Attribute1
                                AND dsae.company_code =  rctl.Interface_Line_Attribute2
                                AND dsae.invoice_number =  rctl.Interface_Line_Attribute3
                                AND dsae.fic_ident = rctl.attribute10 )
                                OR gv_reprise = 'Y'));

          

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
                      cn_num_traitement, -- N_TRAITEMENT
                      trunc(pd_date_debut), -- DATE_DEBUT
                      trunc(nvl(pd_date_fin, SYSDATE)), -- DATE_FIN
                      gn_user_id, -- CREATED_BY
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
                  AND RCTL.ATTRIBUTE8 = to_char(cn_num_traitement)
                  AND (RCTL.ATTRIBUTE9 IS NULL OR
                            RCTL.ATTRIBUTE9 = nvl(pv_folio, RCTL.ATTRIBUTE9))
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
                  AND RCTL.CREATION_DATE >= pd_date_debut
                  AND RCTL.CREATION_DATE <= nvl(pd_date_fin, SYSDATE)
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
             SET DSE.DEBIT  = (SELECT /*SUM(NVL(DECODE(SUBSTR(RCTT.NAME, 6, LENGTH(RCTT.NAME) - 5), 'SI_AMONT_AVOIR', (-1) *
                                                      RCTL.EXTENDED_AMOUNT, 'SI_AMT_ANNUL_AV', (-1) *
                                                      RCTL.EXTENDED_AMOUNT, RCTL.EXTENDED_AMOUNT), 0)) JJA 23/09/2015*/
                                      SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)) --DEBIT
                                 FROM RA_CUSTOMER_TRX_LINES_ALL    RCTL,
                                      RA_CUSTOMER_TRX_ALL          RCT,
                                      RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGD,
                                      RA_CUST_TRX_TYPES_ALL        RCTT,
                                      GL_CODE_COMBINATIONS     GCC
                                WHERE RCTL.ATTRIBUTE8 = cn_num_traitement
                                  AND RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                                  AND RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
                                  AND RCTLGD.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
                                  AND RCTLGD.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
                                  AND DSE.CODE_FOLIO = RCTL.ATTRIBUTE9
                                  AND DSE.FICHIER = RCTL.ATTRIBUTE10
                                  AND DSE.N_TRAITEMENT = cn_num_traitement
                                  AND SUBSTR(GCC.SEGMENT3, 1, 3) = '411'),
                 DSE.TRAITE = 0
           WHERE (DSE.CODE_FOLIO IS NULL OR
                 DSE.CODE_FOLIO = nvl(pv_folio, DSE.CODE_FOLIO))
             AND DSE.TRAITE = 1
             AND DSE.N_TRAITEMENT = cn_num_traitement;
          COMMIT;
          gv_step := 'INSERT_AR_DATA 999 - FIN.';
          log_msg(gv_step);
     EXCEPTION
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'INSERT_AR_DATA 999 - ERROR - ' || SQLERRM;
               log_msg(pv_errbuf);
     END INSERT_AR_DATA;

     -----------------------------------------------------------------
     --  NOM           : main
     --  DESCRIPTION   : Procédure principale du traitement
     --
     --  PARAMETRES   :   pv_retcode                Code retour.
     --                   pn_errbuf                 Description de l'erreur.
     --                  pv_folio                Folio.
     --                  pn_traitement_reprise     Numéro du traitement a rejouer.
     --                  pd_date_reprise_de        Date a reprendre a partir de.
     --                  pd_date_reprise_a          Date a reprendre jusqu'au.
     -----------------------------------------------------------------
     PROCEDURE main(pv_errbuf             OUT VARCHAR2,
                    pn_retcode            OUT NUMBER,
                    pv_folio              IN VARCHAR2,
                    pn_traitement_reprise IN NUMBER,
                    pd_date_reprise_de    IN VARCHAR2,
                    pd_date_reprise_a     IN VARCHAR2) IS

          pd_ref_date DATE;
          pd_rep_date DATE;
          CURSOR cur_ctrl_flux IS
               SELECT DSE.CODE_FOLIO,
                      DSE.DATE_EXEC,
                      SUM(DSE.NB_PIECE) NB_PIECE,
                      SUM(DSE.DEBIT) DEBIT,
                      SUM(DSE.CREDIT) CREDIT,
                      DSE.FICHIER,
                      DSE.TRAITE,
                      DSE.N_TRAITEMENT,
                      DSE.DATE_DEBUT,
                      DSE.DATE_FIN,
                      DSE.CREATED_BY,
                      DSE.CREATION_DATE
                 FROM DKA_SCTLFLUX_EAI DSE
                WHERE DSE.N_TRAITEMENT =
                      nvl(pn_traitement_reprise, cn_num_traitement)
                GROUP BY DSE.CODE_FOLIO,
                         DSE.DATE_EXEC,
                         DSE.FICHIER,
                         DSE.TRAITE,
                         DSE.N_TRAITEMENT,
                         DSE.DATE_DEBUT,
                         DSE.DATE_FIN,
                         DSE.CREATED_BY,
                         DSE.CREATION_DATE;

          rec_ctrl_flux cur_ctrl_flux%ROWTYPE;
          rec_param   dka_parameters%ROWTYPE;     

          -- Variable d'écriture dans un fichier de sortie
          fileHandler UTL_FILE.FILE_TYPE;
          filename    varchar2(50);
          cv_directory CONSTANT VARCHAR2(50) := 'SCTLFLUX_OUT_DIR';

          vn_nb_line NUMBER;
          
          e_error EXCEPTION;
     BEGIN
          ----- Initialisation des variables -----
          gv_step := 'MAIN 000 - INITIALISATION VARIABLES.';
          log_msg(gv_step);
          pv_errbuf  := NULL;
          pn_retcode := 0;
          vn_nb_line := 0;
          
          -- Récupération des variables de la table des parametres
          Dka_Tools_Pkg.get_parameter ('SCTLFLUX_EAI', 'NOM_FICHIER', rec_param, pn_retcode, pv_errbuf);
          gv_nom_fichier           := rec_param.varchar2_value;

          IF pn_retcode != 0 THEN
            pv_errbuf    := 'NOM_FICHIER - ' || pv_errbuf;
            RAISE e_error;
          END IF;
          
          
          --JJA 2015/10/12
          --Mode reprise ou non?
          IF pd_date_reprise_de is not null  or pd_date_reprise_a is not null then
           gv_reprise := 'Y';
          ELSE
           gv_reprise := 'N';
          END IF;

          IF pn_traitement_reprise IS NULL THEN
               ----- Calcul de la date de reference -----
               gv_step := 'MAIN 001 - RECHERCHE DE LA DATE DE REFERENCE.';
               log_msg(gv_step);
               IF pd_date_reprise_de IS NULL THEN
                    BEGIN
                         SELECT TO_DATE(nvl(to_char(max(fcr.actual_completion_date),'dd/mm/yyyy'),'01/01/' || TO_CHAR(SYSDATE , 'YYYY')), 'DD/MM/YYYY') -- YWA artf2147003  -- MAX(fcr.actual_completion_date)
                           INTO pd_ref_date
                           FROM fnd_concurrent_requests fcr,
                                fnd_concurrent_programs fcp
                          WHERE fcp.concurrent_program_name =
                                'DKA_SCTLFLUX_EAI'
                            AND fcr.concurrent_program_id =
                                fcp.concurrent_program_id
                            AND fcr.status_code IN ('C', 'G')
                            AND fcr.argument1 IS NULL
                            AND fcr.argument2 IS NULL
                            AND fcr.argument3 IS NULL
                            AND fcr.argument4 IS NULL;
                    EXCEPTION
                         WHEN others THEN
                              pd_ref_date := TO_DATE('01/01/' || TO_CHAR(SYSDATE, 'yyyy'), 'dd/mm/yyyy');--YWA artf2147003  --SYSDATE - 1;
                    END;
               ELSE
                    pd_ref_date := to_date(pd_date_reprise_de, 'YYYY/MM/DD HH24:MI:SS');
               END IF;
               pd_rep_date := to_date(pd_date_reprise_a, 'YYYY/MM/DD HH24:MI:SS');

               gv_step := 'MAIN 002 - INSERTION DES DONNEES GL.';
               log_msg(gv_step);
               gv_step := 'MAIN 002.1 - date de debut d''extraction '||pd_ref_date; --YWA artf2147003 
               log_msg(gv_step);

               INSERT_GL_DATA(pv_errbuf, pn_retcode, pv_folio, pd_ref_date, pd_rep_date);
               IF pn_retcode != 0 THEN
                    gv_step := 'MAIN 002 ERROR - ERREUR LORS DU CONTRÔLE DE FLUX GL.';
                    log_msg(gv_step);
               END IF;

               gv_step := 'MAIN 003 - INSERTION DES DONNEES AP.';
               log_msg(gv_step);

               INSERT_AP_DATA(pv_errbuf, pn_retcode, pv_folio, pd_ref_date, pd_rep_date);
               IF pn_retcode != 0 THEN
                    gv_step := 'MAIN 003 ERROR - ERREUR LORS DU CONTRÔLE DE FLUX AP.';
                    log_msg(gv_step);
               END IF;

               gv_step := 'MAIN 004 - INSERTION DES DONNEES AR.';
               log_msg(gv_step);

               INSERT_AR_DATA(pv_errbuf, pn_retcode, pv_folio, pd_ref_date, pd_rep_date);
               IF pn_retcode != 0 THEN
                    gv_step := 'MAIN 004 ERROR - ERREUR LORS DU CONTRÔLE DE FLUX AR.';
                    log_msg(gv_step);
               END IF;
          END IF;

          filename := gv_nom_fichier || '_' ||
                      to_char(SYSDATE, 'YYMMDD-HH24MISS') || '.csv';--YWA artf2105170 
          gv_step  := 'MAIN 005 - CREATION DU FICHIER : ' || filename;
          log_msg(gv_step);
          -- Ouverture du fichier en mode écriture.
          fileHandler := utl_file.fopen(cv_directory, filename, 'w');
          gv_step     := 'MAIN 006 - INSERTION DES ENREGISTREMENTS DANS LE FICHIER.';
          log_msg(gv_step);
          OPEN cur_ctrl_flux;
          LOOP
               FETCH cur_ctrl_flux
                    INTO rec_ctrl_flux;
               EXIT WHEN cur_ctrl_flux%NOTFOUND;
               INSERT INTO DKA_SCTLFLUX_EAI
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
                     CREATION_DATE)
               VALUES
                    (rec_ctrl_flux.CODE_FOLIO,
                     rec_ctrl_flux.DATE_EXEC,
                     rec_ctrl_flux.NB_PIECE,
                     rec_ctrl_flux.DEBIT,
                     rec_ctrl_flux.CREDIT,
                     rec_ctrl_flux.FICHIER,
                     2,
                     rec_ctrl_flux.N_TRAITEMENT,
                     rec_ctrl_flux.DATE_DEBUT,
                     rec_ctrl_flux.DATE_FIN,
                     rec_ctrl_flux.CREATED_BY,
                     rec_ctrl_flux.CREATION_DATE);
               COMMIT;

               gv_step := rec_ctrl_flux.CODE_FOLIO || ';' ||
                          rec_ctrl_flux.DATE_EXEC || ';' ||
                          rec_ctrl_flux.NB_PIECE || ';' ||
                          ROUND(NVL(rec_ctrl_flux.DEBIT,0), 2) || ';' ||  -- OBE artf2324535 
                          ROUND(NVL(rec_ctrl_flux.CREDIT,0), 2) || ';' || -- OBE artf2324535
                          rec_ctrl_flux.FICHIER || ';' ||
                          rec_ctrl_flux.TRAITE;
               utl_file.put_line(fileHandler, gv_step);
               out_msg(gv_step);
               vn_nb_line := vn_nb_line + 1;
          END LOOP;
          CLOSE cur_ctrl_flux;

          gv_step := 'MAIN 007 - SUPPRESSION DES LIGNES EN DOUBLES.';
          log_msg(gv_step);
          DELETE FROM DKA_SCTLFLUX_EAI DSE
           WHERE DSE.TRAITE = 0
             AND DSE.N_TRAITEMENT =
                 nvl(pn_traitement_reprise, cn_num_traitement);

          UPDATE DKA_SCTLFLUX_EAI DSE
             SET DSE.TRAITE = 0
           WHERE DSE.N_TRAITEMENT =
                 nvl(pn_traitement_reprise, cn_num_traitement);
          COMMIT;

          gv_step := 'MAIN 009 - FERMETURE DU FICHIER.';
          log_msg(gv_step);
          utl_file.fclose(fileHandler);

          gv_step := 'MAIN 999 - FIN.';
          log_msg(gv_step);
     EXCEPTION
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'MAIN 999 - ERROR - :' ||gv_step || chr(10) || SQLERRM;
               log_msg(pv_errbuf);
     END main;

END DKA_SCTLFLUX_EAI_PKG;
