--------------------------------------------------------------------------------
-- $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SARG00C8_PKG
-- Description      : Body du package DKA_SARG00C8_PKG
-- Auteur           : B.Coudrier
-- Date de création : 25/04/2014
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS 
--------------------------------------------------------------------------------
-- Modifications
--------------------------------------------------------------------------------
-- Auteur           : Maxime EGOT
-- Date de modif    : 20/11/2017
-- Commentaires     : artf2280629 : SPE076 - Performance - Defect Beb # 1139
--------------------------------------------------------------------------------
-- Auteur           : Oussama BENHAYOUN
-- Date de modif    : 15/12/2017
-- Commentaires     : artf2294060 : SPE076 - Anomalie - Defect Beb #1139
--------------------------------------------------------------------------------
-- Auteur           : Nicolas BOUSSEKEYT
-- Date de modif    : 16/03/2018
-- Commentaires     : artf2438704 : INC0199852 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE Monitored Item 
--------------------------------------------------------------------------------


CREATE OR REPLACE PACKAGE BODY DKA_SARG00C8_PKG AS
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

    ------------------------------------------------------------------------------------
    --  Nom           : SARG00C8_ETAT
    --  Description   : Procédure principale du traitement DKA : Comparaison mensuelle - Etat de comparaison
    --
    --  PARAMETRES    :
    --      Pv_Errbuf         Message d'erreur
    --      Pn_Retcode        Code de retour
    --      P_Set_Of_Books_Id   Identifiant du Set_Of_Books
    --    P_Periode      Nom de la période.
    --  VALEUR RETOURNEE :
    --     Valeurs possibles : 0: deroulement correct
    --                         1: avertissement
    --                         2: deroulement avec erreur
    ------------------------------------------------------------------------------------
    PROCEDURE SARG00C8_ETAT(Pv_Errbuf         OUT VARCHAR2,
                            Pn_Retcode        OUT NUMBER,
                            --P_Set_Of_Books_Id IN NUMBER,
                            P_Periode         IN VARCHAR2) IS
        
		--< OBE artf2294060
		/*
        CURSOR cur_soc IS
            SELECT DISTINCT val.flex_value company_name,
              gl.ledger_id
            FROM fnd_flex_value_sets sets,
              fnd_flex_values_vl val ,
              gl_ledgers gl
            WHERE sets.flex_value_set_id = val.flex_value_set_id
            AND gl.short_name            =val.flex_value
            AND ledger_category_code     = 'PRIMARY'
            AND val.enabled_flag         = 'Y'
            AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
            AND val.summary_flag   = 'N'
            AND val.VALUE_CATEGORY ='DAOPCCF_STE';--YWA
	    */
		--> OBE artf2294060

        -- NBO - 16/03/2018 : artf2438704 : INC0199852 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE Monitored Item 
        CURSOR CUR_SARG00C8_ETAT /*(p_ledger_id NUMBER)*/ IS
        SELECT societe,
               facture,
               date_facture,
               client_anael,
               client_oracle,
               origine_facture,
               TYPE,
               annu,
               montant_facture,
               montant_compta,
               imput,
               compte,
               Refer,
               Orig,
               Manu,
               Libelle_Erreur
          FROM dka.dka_sarg00c8_tmp
         ORDER BY 1, 2, 3;
    
        REC_SARG00C8_ETAT CUR_SARG00C8_ETAT%ROWTYPE;
    
        Vn_Nb_Error    NUMBER;
        Vv_Lib_Societe VARCHAR2(240);
    BEGIN
        log_msg('SARG00C8_ETAT (+)');
        Vn_Nb_Error := 0;

        -- NBO - 16/03/2018 : artf2438704 : INC0199852 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE Monitored Item 
        EXECUTE IMMEDIATE 'TRUNCATE TABLE dka.dka_Sarg00c8_tmp';
        
        INSERT /*+ APPEND */ INTO dka.dka_Sarg00c8_tmp 
        SELECT Societe Societe,
       Ds.Num_Facture Facture,
       Ds.Date_Facture Date_Facture,
       Ds.Client_Payeur Client_Anael,
       NULL Client_Oracle,
       Ds.Origine_Facture Origine_Facture,
       Ds.Contrat_Negoce Type,
       Ds.Indic_Annule Annu,
       To_Number(Ds.Signe || Ds.Montant_Ttc) / 100 Montant_Facture,
       NULL Montant_Compta,
       NULL Imput,
       NULL Compte,
       NULL Refer,
       NULL Orig,
       NULL Manu,
       lpad('Absence Comptabilité', 39, ' ') Libelle_Erreur
  FROM Dka_Sarg00c8 Ds
 WHERE NOT EXISTS
 (SELECT 'X'
          FROM Ra_Customer_Trx_All          Rcta,
               Ra_Cust_Trx_Line_Gl_Dist_All Rctlgda,
               --Hz_Cust_Accounts             Hca,
               Hz_Cust_Site_Uses_All        Hcsua,
               Hz_Cust_Acct_Sites_All       Hcasa,
               Gl_Code_Combinations         Gcc,
               Gl_Period_Statuses           Gps,
   --< OBE artf2294060
   fnd_flex_value_sets          sets,
               --fnd_flex_values_vl           val,
               fnd_flex_values           val,
               gl_ledgers                   gl
   --> OBE artf2294060
         WHERE Rcta.Customer_Trx_Id = Rctlgda.Customer_Trx_Id
           AND Rctlgda.Account_Class = 'REC'
           AND Rctlgda.Latest_Rec_Flag = 'Y'
           --AND Rcta.Bill_To_Customer_Id = Hca.Cust_Account_Id
           AND Rcta.Bill_To_Site_Use_Id = Hcsua.Site_Use_Id
           AND Hcsua.Cust_Acct_Site_Id =
               Hcasa.Cust_Acct_Site_Id
           AND Rctlgda.Code_Combination_Id =
               Gcc.Code_Combination_Id
           AND Rctlgda.Gl_Date BETWEEN Gps.Start_Date AND
               Gps.End_Date
           AND Gps.Application_Id = 101
           --AND Gps.Set_Of_Books_Id = p_ledger_id -- OBE artf2294060
 AND gps.ledger_id = gl.ledger_id        -- OBE artf2294060
           AND Gps.Period_Name = P_Periode
         --AND Dka_Tools_Pkg.Numeric_Check(Gcc.Segment3) = 0
           AND DECODE (RTRIM (TRANSLATE (REPLACE (Gcc.Segment3, ' ', 'X'), '1234567890', '          ')), '', '0', '1') = 0
           AND Gcc.Segment1 = Ds.Societe
           AND Rcta.Trx_Number = Ds.Num_Facture
           AND Rcta.Trx_Date = Ds.Date_Facture
           AND Hcasa.Attribute3 = Ds.Client_Payeur
           AND rcta.attribute1 IN
               (SELECT ffvv.flex_value --23/04/2012
                  FROM --fnd_flex_values_vl  ffvv,
                       fnd_flex_values ffvv,
                       fnd_flex_value_sets ffvs
                 WHERE ffvs.flex_value_set_name =
                       'DKA_COMPARAISON_AR'
                   AND ffvs.flex_value_set_id =
                       ffvv.FLEX_VALUE_SET_ID
                   AND ffvv.ENABLED_FLAG = 'Y'
                   AND ffvv.summary_flag   = 'N'
                   AND SYSDATE BETWEEN
                       nvl(ffvv.START_DATE_ACTIVE, SYSDATE) AND
                       nvl(ffvv.END_DATE_ACTIVE, SYSDATE))
--< OBE artf2294060          
           AND sets.flex_value_set_id = val.flex_value_set_id
           AND gl.short_name            =val.flex_value
           AND ledger_category_code     = 'PRIMARY'
           AND val.enabled_flag         = 'Y'
           AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
           AND val.summary_flag   = 'N'
           --AND val.VALUE_CATEGORY ='DAOPCCF_STE'   
           AND sets.flex_value_set_name = 'DAOPCCF_STE'                       
           AND gl.ledger_id = Rcta.Set_Of_Books_Id
        -->	OBE artf2294060	   
								   
);
        COMMIT;

        INSERT /*+ APPEND */ INTO dka.dka_Sarg00c8_tmp 
            SELECT Gcc.Segment1 Societe,
                   Rcta.Trx_Number Facture,
                   Rcta.Trx_Date Date_Facture,
                   Hcasa.Attribute3 Client_Anael,
                   Hca.Account_Number Client_Oracle,
                   NULL Origine_Facture,
                   NULL Type,
                   NULL Annu,
                   NULL Montant_Facture,
                   Rctlgda.Amount Montant_Compta,
                   Ppa.Segment1 Imput,
                   Gcc.Segment3 Compte,
                   Rcta.Attribute1 Refer,
                   Rbsa.Name Orig,
                   CASE
                       WHEN substr(Rbsa.name,1,6) IN ('MANUEL', 'MANUAL') THEN
                        'X'
                       ELSE
                        NULL
                   END Manu,
                   'Absence Facturation' Libelle_Erreur
              FROM Ra_Batch_Sources_All         Rbsa,
                   Ra_Customer_Trx_All          Rcta,
                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgda,
                   Hz_Cust_Accounts             Hca,
                   Hz_Cust_Site_Uses_All        Hcsua,
                   Hz_Cust_Acct_Sites_All       Hcasa,
                   Gl_Code_Combinations         Gcc,
                   Pa_Projects_All              Ppa,
                   Gl_Period_Statuses           Gps,
				   --< OBE artf2294060
				   fnd_flex_value_sets          sets,
                   fnd_flex_values_vl           val,
                   gl_ledgers                   gl
			       --> OBE artf2294060
             WHERE Rbsa.Batch_Source_Id = Rcta.Batch_Source_Id
			   AND rbsa.org_id = Rctlgda.org_id -- OBE artf2294060
               AND Rcta.Customer_Trx_Id = Rctlgda.Customer_Trx_Id
               AND Rctlgda.Account_Class = 'REC'
               AND Rctlgda.Latest_Rec_Flag = 'Y'
               AND Rcta.Bill_To_Customer_Id = Hca.Cust_Account_Id
               AND Rcta.Bill_To_Site_Use_Id = Hcsua.Site_Use_Id
               AND Hcsua.Cust_Acct_Site_Id = Hcasa.Cust_Acct_Site_Id
               AND Rctlgda.Code_Combination_Id = Gcc.Code_Combination_Id
               AND Rctlgda.Gl_Date BETWEEN Gps.Start_Date AND Gps.End_Date
               AND Gps.Application_Id = 101
               --AND Gps.Set_Of_Books_Id = p_ledger_id -- OBE artf2294060
		       AND gps.ledger_id = gl.ledger_id        -- OBE artf2294060
               AND Gps.Period_Name = P_Periode
               AND Rcta.Attribute10 = Ppa.Project_Id(+)
             --AND Dka_Tools_Pkg.Numeric_Check(Gcc.Segment3) = 0
               AND DECODE (RTRIM (TRANSLATE (REPLACE (Gcc.Segment3, ' ', 'X'), '1234567890', '          ')), '', '0', '1') = 0
               AND rcta.attribute1 IN
                   (SELECT ffvv.flex_value --23/04/2012
                      FROM fnd_flex_values_vl  ffvv,
                           fnd_flex_value_sets ffvs
                     WHERE ffvs.flex_value_set_name = 'DKA_COMPARAISON_AR'
                       AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
                       AND ffvv.ENABLED_FLAG = 'Y'
                       AND SYSDATE BETWEEN
                           nvl(ffvv.START_DATE_ACTIVE, SYSDATE) AND
                           nvl(ffvv.END_DATE_ACTIVE, SYSDATE))
               /*AND NOT EXISTS
             (SELECT 'x'
                      FROM Dka_Sarg00c8 Ds
                     WHERE Ds.Societe = Gcc.Segment1
                       AND Ds.Num_Facture = Rcta.Trx_Number
                       AND Ds.Date_Facture = Rcta.Trx_Date
                       AND Ds.Client_Payeur = Hcasa.Attribute3)*/
             AND    NOT EXISTS 
             (SELECT 'x'
              FROM   Dka_Sarg00c8 Ds, hr_operating_units hou
              WHERE  Ds.Societe       = Gcc.Segment1
              AND    Ds.Num_Facture   = Rcta.Trx_Number
              AND    Ds.Date_Facture  = Rcta.Trx_Date
              AND    Ds.Client_Payeur = Hcasa.Attribute3
              AND    hou.organization_id = Rcta.org_id
              AND    ds.societe = substr(hou.name,4))
                    --< OBE artf2294060          
                       AND sets.flex_value_set_id = val.flex_value_set_id
                       AND gl.short_name            =val.flex_value
                       AND ledger_category_code     = 'PRIMARY'
                       AND val.enabled_flag         = 'Y'
                       AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
                       AND val.summary_flag   = 'N'
                       --AND val.VALUE_CATEGORY ='DAOPCCF_STE'   
                       AND sets.flex_value_set_name = 'DAOPCCF_STE'                     
                       AND gl.ledger_id = Rcta.Set_Of_Books_Id;
                     -->	OBE artf2294060
            COMMIT;
                     
            INSERT /*+ APPEND */ INTO dka.dka_Sarg00c8_tmp 
            SELECT Gcc.Segment1 Societe,
                   Rcta.Trx_Number Facture,
                   Rcta.Trx_Date Date_Facture,
                   Hcasa.Attribute3 Client_Anael,
                   Hca.Account_Number Client_Oracle,
                   Ds.Origine_Facture Origine_Facture,
                   Ds.Contrat_Negoce Type,
                   Ds.Indic_Annule Annu,
                   To_Number(Ds.Signe || Ds.Montant_Ttc) / 100 Montant_Facture,
                   Rctlgda.Amount Montant_Compta,
                   Ppa.Segment1 Imput,
                   Gcc.Segment3 Compte,
                   Rcta.Attribute1 Refer,
                   Rbsa.Name Orig,
                   CASE
                       WHEN substr(Rbsa.name,1,6) IN ('MANUEL', 'MANUAL')  THEN
                        'X'
                       ELSE
                        NULL
                   END Manu,
                   lpad('Montants différents', 30, ' ') Libelle_Erreur
              FROM Ra_Batch_Sources_All         Rbsa,
                   Ra_Customer_Trx_All          Rcta,
                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgda,
                   Hz_Cust_Accounts             Hca,
                   Hz_Cust_Site_Uses_All        Hcsua,
                   Hz_Cust_Acct_Sites_All       Hcasa,
                   Gl_Code_Combinations         Gcc,
                   Pa_Projects_All              Ppa,
                   Gl_Period_Statuses           Gps,
                   Dka_Sarg00c8                 Ds,
				   --< OBE artf2294060
				   
			       --> OBE artf2294060				   
                   hr_operating_units            hou2
             WHERE Rbsa.Batch_Source_Id = Rcta.Batch_Source_Id
			         AND rbsa.org_id = Rctlgda.org_id -- OBE artf2294060
               AND Rcta.Customer_Trx_Id = Rctlgda.Customer_Trx_Id
               AND Rctlgda.Account_Class = 'REC'
               AND Rctlgda.Latest_Rec_Flag = 'Y'
               AND Rcta.Bill_To_Customer_Id = Hca.Cust_Account_Id
               AND Rcta.Bill_To_Site_Use_Id = Hcsua.Site_Use_Id
               AND Hcsua.Cust_Acct_Site_Id = Hcasa.Cust_Acct_Site_Id
               AND Rctlgda.Code_Combination_Id = Gcc.Code_Combination_Id
               AND Rctlgda.Gl_Date BETWEEN Gps.Start_Date AND Gps.End_Date
               AND Gps.Application_Id = 101
               --AND Gps.Set_Of_Books_Id = p_ledger_id -- OBE artf2294060
		           AND Gps.Period_Name = P_Periode
               AND Rcta.Attribute10 = Ppa.Project_Id(+)
             --AND Dka_Tools_Pkg.Numeric_Check(Gcc.Segment3) = 0
               AND EXISTS (SELECT 'x' 
                            FROM fnd_flex_values ffvv, fnd_flex_value_sets ffvs
                           WHERE ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
                             AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                             AND ffvv.enabled_flag = 'Y'
                             AND SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                                 nvl(ffvv.end_date_active, SYSDATE)
                             AND ffvv.summary_flag = 'N'
                             AND decode(rtrim(translate(REPLACE(ffvv.flex_value, ' ', 'X'),
                                                        '1234567890',
                                                        '          ')),
                                        '',
                                        '0',
                                        '1') = 0
                             AND ffvv.flex_value = Gcc.Segment3)
               AND Ds.Societe = Gcc.Segment1
               AND Ds.Num_Facture = Rcta.Trx_Number
               AND Ds.Date_Facture = Rcta.Trx_Date
               AND Ds.Client_Payeur = Hcasa.Attribute3
               AND Hou2.organization_id = Hcasa.org_id
               AND To_Number(Ds.Signe || Ds.Montant_Ttc) / 100 !=
                   Rctlgda.Amount
               AND EXISTS
                   (SELECT 'x' 
                      FROM fnd_flex_values  ffvv,
                           fnd_flex_value_sets ffvs
                     WHERE ffvs.flex_value_set_name = 'DKA_COMPARAISON_AR'
                       AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
                       AND ffvv.ENABLED_FLAG = 'Y'
                       AND SYSDATE BETWEEN
                           nvl(ffvv.START_DATE_ACTIVE, SYSDATE) AND
                           nvl(ffvv.END_DATE_ACTIVE, SYSDATE) AND
                           ffvv.summary_flag   = 'N' AND
                           ffvv.flex_value = rcta.attribute1)
               AND    hou2.organization_id = Rcta.org_id
               AND    ds.societe = substr(hou2.name,4)
			--< OBE artf2294060    
         AND EXISTS (select 'x' from fnd_flex_value_sets          sets,
                   fnd_flex_values           val,
                   gl_ledgers                   gl    
                     WHERE sets.flex_value_set_id = val.flex_value_set_id
                     AND gl.short_name            =val.flex_value
                     AND gl.ledger_category_code     = 'PRIMARY'
                     AND val.enabled_flag         = 'Y'
                     AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
                     AND val.summary_flag   = 'N'
                     --AND val.VALUE_CATEGORY ='DAOPCCF_STE'   
                     AND sets.flex_value_set_name = 'DAOPCCF_STE'                    
                     AND gl.ledger_id = Rcta.Set_Of_Books_Id
                     AND gps.ledger_id = gl.ledger_id        -- OBE artf2294060
                     );
			 -->	OBE artf2294060
       
         COMMIT;
        -- Fin NBO - 16/03/2018 : artf2438704 : INC0199852 : DYSFONCTIONNEMENT - APPLICATIONS METIERS - ORACLE FINANCE Monitored Item 

        --FOR soc IN cur_soc
        --LOOP
        
            OPEN CUR_SARG00C8_ETAT/*(soc.ledger_id)*/;
            LOOP
                FETCH CUR_SARG00C8_ETAT
                    INTO REC_SARG00C8_ETAT;
                EXIT WHEN CUR_SARG00C8_ETAT%NOTFOUND;
                Vn_Nb_Error := Vn_Nb_Error + 1;
                log_msg('SARG00C8_ETAT 1 - Facture en erreur : ' ||
                        REC_SARG00C8_ETAT.Facture);
                -- Insertion de l'entête du fichier.
                IF Vn_Nb_Error = 1 THEN
                    out_msg('Société;Libellé Société;Facture;Date Facture;Référence Adresse Client;Client OA;FACTURATION Orig;FACTURATION Type;FACTURATION Annu;FACTURATION Montant Facture;COMPTABILITE Mt Comptabilisé;COMPTABILITE Imput;COMPTABILITE Compte;COMPTABILITE Référence;COMPTABILITE Origine;COMPTABILITE Manuel;Erreur;');
                END IF;
            
                -- Recherche du libellé de la facture.
                BEGIN
                    /*SELECT Company_Name
                      INTO Vv_Lib_Societe
                      FROM Dka_Ibdsoc_General_Info
                     WHERE Company_Code = REC_SARG00C8_ETAT.Societe;*/
                    SELECT ffvv.description
                    INTO   Vv_Lib_Societe
                    FROM   fnd_flex_value_sets ffvs,
                           fnd_flex_values_vl  ffvv
                    WHERE  ffvs.flex_value_set_id = ffvv.flex_value_set_id
                    AND    ffvs.flex_value_set_name = 'DAOPCCF_STE'
                    AND    flex_value = REC_SARG00C8_ETAT.Societe;
                     
                EXCEPTION
                    WHEN OTHERS THEN
                        Vv_Lib_Societe := NULL;
                END;
                -- Insertion du corps du fichier.
                out_msg(REC_SARG00C8_ETAT.Societe || ';' || --Société
                        Vv_Lib_Societe || ';' || --Libellé Société
                        REC_SARG00C8_ETAT.Facture || ';' || --Facture
                        REC_SARG00C8_ETAT.Date_Facture || ';' || --Date Facture
                        REC_SARG00C8_ETAT.Client_Anael || ';' || --Client ANAEL
                        REC_SARG00C8_ETAT.Client_Oracle || ';' || --Client OA
                        REC_SARG00C8_ETAT.Origine_Facture || ';' || --FACTURATION Orig
                        REC_SARG00C8_ETAT.Type || ';' || --FACTURATION Type
                        REC_SARG00C8_ETAT.Annu || ';' || --FACTURATION Annu
                        REC_SARG00C8_ETAT.Montant_Facture || ';' || --FACTURATION Montant Facture
                        REC_SARG00C8_ETAT.Montant_Compta || ';' || --COMPTABILITE Mt Comptabilisé
                        REC_SARG00C8_ETAT.Imput || ';' || --COMPTABILITE Imput
                        REC_SARG00C8_ETAT.Compte || ';' || --COMPTABILITE Compte
                        REC_SARG00C8_ETAT.Refer || ';' || --COMPTABILITE Référence
                        REC_SARG00C8_ETAT.Orig || ';' || --COMPTABILITE Origine
                        REC_SARG00C8_ETAT.Manu || ';' || --COMPTABILITE Manuel
                        REC_SARG00C8_ETAT.Libelle_Erreur || ';'); --Erreur
            
            END LOOP;
            CLOSE CUR_SARG00C8_ETAT;
        --END LOOP;    
            
        log_msg('SARG00C8_ETAT 2 - Nombre d''enregistrement présent : ' ||
                Vn_Nb_Error);
        log_msg('SARG00C8_ETAT (-)');
    EXCEPTION
        WHEN OTHERS THEN
            Pv_Errbuf  := 'Erreur lors de l''exécution de la procédure SARG00C8_ETAT ' ||
                          Substr(SQLERRM, 1, 80);
            Pn_Retcode := 2;
    END SARG00C8_ETAT;

    ------------------------------------------------------------------------------------
    --  Nom           : SARG00C8_RATT
    --  Description   : Procédure principale du traitement DKA : Comparaison mensuelle - Etat de comparaison
    --
    --  PARAMETRES    :
    --      Pv_Errbuf         Message d'erreur
    --      Pn_Retcode        Code de retour
    --      P_Set_Of_Books_Id   Identifiant du Set_Of_Books
    --    P_Periode_Debut    Nom de la période de début.
    --    P_Periode_Fin    Nom de la période de fin.
    --  VALEUR RETOURNEE :
    --     Valeurs possibles : 0: deroulement correct
    --                         1: avertissement
    --                         2: deroulement avec erreur
    ------------------------------------------------------------------------------------
    PROCEDURE SARG00C8_RATT(Pv_Errbuf         OUT VARCHAR2,
                            Pn_Retcode        OUT NUMBER,
                            --P_Set_Of_Books_Id IN NUMBER,
                            P_Periode_Debut   IN VARCHAR2,
                            P_Periode_Fin     IN VARCHAR2) IS
          /*                  
        CURSOR cur_soc IS
            SELECT DISTINCT val.flex_value company_name,
              gl.ledger_id
            FROM fnd_flex_value_sets sets,
              fnd_flex_values_vl val ,
              gl_ledgers gl
            WHERE sets.flex_value_set_id = val.flex_value_set_id
            AND gl.short_name            =val.flex_value
            AND ledger_category_code     = 'PRIMARY'
            AND val.enabled_flag         = 'Y'
            AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
            AND val.summary_flag   = 'N'
            AND val.VALUE_CATEGORY ='DAOPCCF_STE';--YWA*/
            
        CURSOR CUR_SARG00C8_RATT/*(p_ledger_id NUMBER)*/ IS
            SELECT Societe Societe,
                   Ds.Num_Facture Facture,
                   Ds.Date_Facture Date_Facture,
                   Ds.Client_Payeur Client_Anael,
                   NULL Client_Oracle,
                   Ds.Origine_Facture Origine_Facture,
                   Ds.Contrat_Negoce Type,
                   Ds.Indic_Annule Annu,
                   To_Number(Ds.Signe || Ds.Montant_Ttc) / 100 Montant_Facture,
                   NULL Montant_Compta,
                   NULL Imput,
                   NULL Compte,
                   NULL Refer,
                   NULL Orig,
                   NULL Manu,
                   lpad('Absence Comptabilité', 39, ' ') Libelle_Erreur
              FROM Dka_Sarg00c8 Ds
             WHERE NOT EXISTS
             (SELECT 'X'
                      FROM Ra_Customer_Trx_All Rcta,
                           Ra_Cust_Trx_Line_Gl_Dist_All Rctlgda,
                           Hz_Cust_Accounts Hca,
                           Hz_Cust_Site_Uses_All Hcsua,
                           Hz_Cust_Acct_Sites_All Hcasa,
                           Gl_Code_Combinations Gcc,
                           Gl_Period_Statuses Gps,
                           (SELECT DISTINCT Gps1.Period_Name
                              FROM Gl_Period_Statuses Gps1,
                                   (SELECT Start_Date
                                      FROM Gl_Period_Statuses
                                     WHERE Application_Id = 101
                                       --AND Set_Of_Books_Id = p_ledger_id
                                       AND Period_Name = P_Periode_Debut
									   AND ROWNUM = 1) Begin_Period,
                                   (SELECT End_Date
                                      FROM Gl_Period_Statuses
                                     WHERE Application_Id = 101
                                       --AND Set_Of_Books_Id = p_ledger_id
                                       AND Period_Name = P_Periode_Fin
									   AND ROWNUM = 1) End_Period
                             WHERE Gps1.Application_Id = 101
                               --AND Gps1.Set_Of_Books_Id = p_ledger_id
                               AND Gps1.Start_Date BETWEEN
                                   Begin_Period.Start_Date AND
                                   End_Period.End_Date
                               AND Gps1.End_Date BETWEEN
                                   Begin_Period.Start_Date AND
                                   End_Period.End_Date) Period_Value,
								   --< OBE artf2294060
				                   fnd_flex_value_sets          sets,
                                   fnd_flex_values_vl           val,
                                   gl_ledgers                   gl
			                       --> OBE artf2294060
                     WHERE Rcta.Customer_Trx_Id = Rctlgda.Customer_Trx_Id
                       AND Rctlgda.Account_Class = 'REC'
                       AND Rctlgda.Latest_Rec_Flag = 'Y'
                       AND Rcta.Bill_To_Customer_Id = Hca.Cust_Account_Id
                       AND Rcta.Bill_To_Site_Use_Id = Hcsua.Site_Use_Id
                       AND Hcsua.Cust_Acct_Site_Id =
                           Hcasa.Cust_Acct_Site_Id
                       AND Rctlgda.Code_Combination_Id =
                           Gcc.Code_Combination_Id
                       AND Rctlgda.Gl_Date BETWEEN Gps.Start_Date AND
                           Gps.End_Date
                       AND Gps.Application_Id = 101
                       --AND Gps.Set_Of_Books_Id = p_ledger_id -- OBE artf2294060
	                   AND gps.ledger_id = gl.ledger_id        -- OBE artf2294060
                       AND Gps.Period_Name = Period_Value.Period_Name
                     --AND Dka_Tools_Pkg.Numeric_Check(Gcc.Segment3) = 0
                       AND DECODE (RTRIM (TRANSLATE (REPLACE (Gcc.Segment3, ' ', 'X'), '1234567890', '          ')), '', '0', '1') = 0
                       AND Gcc.Segment1 = Ds.Societe
                       AND Rcta.Trx_Number = Ds.Num_Facture
                       AND Rcta.Trx_Date = Ds.Date_Facture
                       AND Hcasa.Attribute3 = Ds.Client_Payeur
                       AND rcta.attribute1 IN
                           (SELECT ffvv.flex_value --23/04/2012
                              FROM fnd_flex_values_vl  ffvv,
                                   fnd_flex_value_sets ffvs
                             WHERE ffvs.flex_value_set_name =
                                   'DKA_COMPARAISON_AR'
                               AND ffvs.flex_value_set_id =
                                   ffvv.FLEX_VALUE_SET_ID
                               AND ffvv.ENABLED_FLAG = 'Y'
                               AND SYSDATE BETWEEN
                                   nvl(ffvv.START_DATE_ACTIVE, SYSDATE) AND
                                   nvl(ffvv.END_DATE_ACTIVE, SYSDATE))
                       --< OBE artf2294060          
			           AND sets.flex_value_set_id = val.flex_value_set_id
			           AND gl.short_name            =val.flex_value
			           AND ledger_category_code     = 'PRIMARY'
			           AND val.enabled_flag         = 'Y'
			           AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
			           AND val.summary_flag   = 'N'
			           AND val.VALUE_CATEGORY ='DAOPCCF_STE'                       
			           AND gl.ledger_id = Rcta.Set_Of_Books_Id
			           -->	OBE artf2294060
			    
				)
            UNION ALL
            SELECT Gcc.Segment1 Societe,
                   Rcta.Trx_Number Facture,
                   Rcta.Trx_Date Date_Facture,
                   Hcasa.Attribute3 Client_Anael,
                   Hca.Account_Number Client_Oracle,
                   NULL Origine_Facture,
                   NULL Type,
                   NULL Annu,
                   NULL Montant_Facture,
                   Rctlgda.Amount Montant_Compta,
                   Ppa.Segment1 Imput,
                   Gcc.Segment3 Compte,
                   Rcta.Attribute1 Refer,
                   Rbsa.Name Orig,
                   CASE
                       WHEN Rbsa.Name LIKE '%MANUEL%' OR Rbsa.Name LIKE '%MANUAL%' THEN
                        'X'
                       ELSE
                        NULL
                   END Manu,
                   'Absence Facturation' Libelle_Erreur
              FROM Ra_Batch_Sources_All         Rbsa,
                   Ra_Customer_Trx_All          Rcta,
                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgda,
                   Hz_Cust_Accounts             Hca,
                   Hz_Cust_Site_Uses_All        Hcsua,
                   Hz_Cust_Acct_Sites_All       Hcasa,
                   Gl_Code_Combinations         Gcc,
                   Pa_Projects_All              Ppa,
                   Gl_Period_Statuses           Gps,
				   --< OBE artf2294060
				   fnd_flex_value_sets          sets,
                   fnd_flex_values_vl           val,
                   gl_ledgers                   gl
			       --> OBE artf2294060
				   
             WHERE Rbsa.Batch_Source_Id = Rcta.Batch_Source_Id
			   AND rbsa.org_id = Rctlgda.org_id -- OBE artf2294060
               AND Rcta.Customer_Trx_Id = Rctlgda.Customer_Trx_Id
               AND Rctlgda.Account_Class = 'REC'
               AND Rctlgda.Latest_Rec_Flag = 'Y'
               AND Rcta.Bill_To_Customer_Id = Hca.Cust_Account_Id
               AND Rcta.Bill_To_Site_Use_Id = Hcsua.Site_Use_Id
               AND Hcsua.Cust_Acct_Site_Id = Hcasa.Cust_Acct_Site_Id
               AND Rctlgda.Code_Combination_Id = Gcc.Code_Combination_Id
               AND Rctlgda.Gl_Date BETWEEN Gps.Start_Date AND Gps.End_Date
               AND Gps.Application_Id = 101
               --AND Gps.Set_Of_Books_Id = p_ledger_id -- OBE artf2294060
	           AND gps.ledger_id = gl.ledger_id        -- OBE artf2294060
               AND Gps.Period_Name IN
                   (SELECT Gps1.Period_Name
                      FROM Gl_Period_Statuses Gps1,
                           (SELECT Start_Date
                              FROM Gl_Period_Statuses
                             WHERE Application_Id = 101
                               AND Set_Of_Books_Id = gl.ledger_id
                               AND Period_Name = P_Periode_Debut) Begin_Period,
                           (SELECT End_Date
                              FROM Gl_Period_Statuses
                             WHERE Application_Id = 101
                               AND Set_Of_Books_Id = gl.ledger_id
                               AND Period_Name = P_Periode_Fin) End_Period
                     WHERE Gps1.Application_Id = 101
                       AND Gps1.Set_Of_Books_Id = gl.ledger_id
                       AND Gps1.Start_Date BETWEEN Begin_Period.Start_Date AND
                           End_Period.End_Date
                       AND Gps1.End_Date BETWEEN Begin_Period.Start_Date AND
                           End_Period.End_Date)
               AND Rcta.Attribute10 = Ppa.Project_Id(+)
             --AND Dka_Tools_Pkg.Numeric_Check(Gcc.Segment3) = 0
               AND DECODE (RTRIM (TRANSLATE (REPLACE (gcc.segment3, ' ', 'X'), '1234567890', '          ')), '', '0', '1') = 0
               AND rcta.attribute1 IN
                   (SELECT ffvv.flex_value
                      FROM fnd_flex_values_vl  ffvv,
                           fnd_flex_value_sets ffvs
                     WHERE ffvs.flex_value_set_name = 'DKA_COMPARAISON_AR'
                       AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
                       AND ffvv.ENABLED_FLAG = 'Y'
                       AND SYSDATE BETWEEN
                           nvl(ffvv.START_DATE_ACTIVE, SYSDATE) AND
                           nvl(ffvv.END_DATE_ACTIVE, SYSDATE))
               AND NOT EXISTS
             (SELECT 'x'
                      FROM Dka_Sarg00c8 Ds
                     WHERE Ds.Societe = Gcc.Segment1
                       AND Ds.Num_Facture = Rcta.Trx_Number
                       AND Ds.Date_Facture = Rcta.Trx_Date
                       AND Ds.Client_Payeur = Hcasa.Attribute3)
                       --< OBE artf2294060          
			           AND sets.flex_value_set_id = val.flex_value_set_id
			           AND gl.short_name            =val.flex_value
			           AND ledger_category_code     = 'PRIMARY'
			           AND val.enabled_flag         = 'Y'
			           AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
			           AND val.summary_flag   = 'N'
			           AND val.VALUE_CATEGORY ='DAOPCCF_STE'                       
			           AND gl.ledger_id = Rcta.Set_Of_Books_Id
			           -->	OBE artf2294060
            UNION ALL
            SELECT Gcc.Segment1 Societe,
                   Rcta.Trx_Number Facture,
                   Rcta.Trx_Date Date_Facture,
                   Hcasa.Attribute3 Client_Anael,
                   Hca.Account_Number Client_Oracle,
                   Ds.Origine_Facture Origine_Facture,
                   Ds.Contrat_Negoce Type,
                   Ds.Indic_Annule Annu,
                   To_Number(Ds.Signe || Ds.Montant_Ttc) / 100 Montant_Facture,
                   Rctlgda.Amount Montant_Compta,
                   Ppa.Segment1 Imput,
                   Gcc.Segment3 Compte,
                   Rcta.Attribute1 Refer,
                   Rbsa.Name Orig,
                   CASE
                       WHEN Rbsa.Name LIKE '%MANUEL%' OR Rbsa.Name LIKE '%MANUAL%' THEN
                        'X'
                       ELSE
                        NULL
                   END Manu,
                   lpad('Montants différents', 30, ' ') Libelle_Erreur
              FROM Ra_Batch_Sources_All         Rbsa,
                   Ra_Customer_Trx_All          Rcta,
                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgda,
                   Hz_Cust_Accounts             Hca,
                   Hz_Cust_Site_Uses_All        Hcsua,
                   Hz_Cust_Acct_Sites_All       Hcasa,
                   Gl_Code_Combinations         Gcc,
                   Pa_Projects_All              Ppa,
                   Gl_Period_Statuses           Gps,
                   Dka_Sarg00c8                 Ds,
				   --< OBE artf2294060
				   fnd_flex_value_sets          sets,
                   fnd_flex_values_vl           val,
                   gl_ledgers                   gl
			       --> OBE artf2294060				   
             WHERE Rbsa.Batch_Source_Id = Rcta.Batch_Source_Id
			   AND rbsa.org_id = Rctlgda.org_id -- OBE artf2294060
               AND Rcta.Customer_Trx_Id = Rctlgda.Customer_Trx_Id
               AND Rctlgda.Account_Class = 'REC'
               AND Rctlgda.Latest_Rec_Flag = 'Y'
               AND Rcta.Bill_To_Customer_Id = Hca.Cust_Account_Id
               AND Rcta.Bill_To_Site_Use_Id = Hcsua.Site_Use_Id
               AND Hcsua.Cust_Acct_Site_Id = Hcasa.Cust_Acct_Site_Id
               AND Rctlgda.Code_Combination_Id = Gcc.Code_Combination_Id
               AND Rctlgda.Gl_Date BETWEEN Gps.Start_Date AND Gps.End_Date
               AND Gps.Application_Id = 101
               --AND Gps.Set_Of_Books_Id = p_ledger_id -- OBE artf2294060
	           AND gps.ledger_id = gl.ledger_id        -- OBE artf2294060
               AND Gps.Period_Name IN
                   (SELECT Gps1.Period_Name
                      FROM Gl_Period_Statuses Gps1,
                           (SELECT Start_Date
                              FROM Gl_Period_Statuses
                             WHERE Application_Id = 101
                               AND Set_Of_Books_Id = gl.ledger_id
                               AND Period_Name = P_Periode_Debut) Begin_Period,
                           (SELECT End_Date
                              FROM Gl_Period_Statuses
                             WHERE Application_Id = 101
                               AND Set_Of_Books_Id = gl.ledger_id
                               AND Period_Name = P_Periode_Fin) End_Period
                     WHERE Gps1.Application_Id = 101
                       AND Gps1.Set_Of_Books_Id = gl.ledger_id
                       AND Gps1.Start_Date BETWEEN Begin_Period.Start_Date AND
                           End_Period.End_Date
                       AND Gps1.End_Date BETWEEN Begin_Period.Start_Date AND
                           End_Period.End_Date)
               AND Rcta.Attribute10 = Ppa.Project_Id(+)
             --AND Dka_Tools_Pkg.Numeric_Check(Gcc.Segment3) = 0
               AND DECODE (RTRIM (TRANSLATE (REPLACE (Gcc.Segment3, ' ', 'X'), '1234567890', '          ')), '', '0', '1') = 0
               AND Ds.Societe = Gcc.Segment1
               AND Ds.Num_Facture = Rcta.Trx_Number
               AND Ds.Date_Facture = Rcta.Trx_Date
               AND Ds.Client_Payeur = Hcasa.Attribute3
               AND To_Number(Ds.Signe || Ds.Montant_Ttc) / 100 !=
                   Rctlgda.Amount
               AND rcta.attribute1 IN
                   (SELECT ffvv.flex_value
                      FROM fnd_flex_values_vl  ffvv,
                           fnd_flex_value_sets ffvs
                     WHERE ffvs.flex_value_set_name = 'DKA_COMPARAISON_AR'
                       AND ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
                       AND ffvv.ENABLED_FLAG = 'Y'
                       AND SYSDATE BETWEEN
                           nvl(ffvv.START_DATE_ACTIVE, SYSDATE) AND
                           nvl(ffvv.END_DATE_ACTIVE, SYSDATE))
                       --< OBE artf2294060          
			           AND sets.flex_value_set_id = val.flex_value_set_id
			           AND gl.short_name            =val.flex_value
			           AND ledger_category_code     = 'PRIMARY'
			           AND val.enabled_flag         = 'Y'
			           AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
			           AND val.summary_flag   = 'N'
			           AND val.VALUE_CATEGORY ='DAOPCCF_STE'                       
			           AND gl.ledger_id = Rcta.Set_Of_Books_Id
			           -->	OBE artf2294060						   
             ORDER BY 1, 2, 3;
    
        REC_SARG00C8_RATT CUR_SARG00C8_RATT%ROWTYPE;
    
        Vn_Nb_Error    NUMBER;
         Vv_Lib_Societe VARCHAR2(240);
    BEGIN
        Dka_Tools_Pkg.Put_Debug_Message('SARG00C8_RATT (+)');
        Vn_Nb_Error := 0;
        --FOR soc IN cur_soc
        --LOOP
            OPEN CUR_SARG00C8_RATT/*(soc.ledger_id)*/;
            LOOP
                FETCH CUR_SARG00C8_RATT
                    INTO REC_SARG00C8_RATT;
                EXIT WHEN CUR_SARG00C8_RATT%NOTFOUND;
                Vn_Nb_Error := Vn_Nb_Error + 1;
                log_msg('SARG00C8_RATT 1 - Facture en erreur : ' ||
                        REC_SARG00C8_RATT.Facture);
                -- Insertion de l'entête du fichier.
                IF Vn_Nb_Error = 1 THEN
                    out_msg('Société;Libellé Société;Facture;Date Facture;Référence Adresse Client;Client OA;FACTURATION Orig;FACTURATION Type;FACTURATION Annu;FACTURATION Montant Facture;COMPTABILITE Mt Comptabilisé;COMPTABILITE Imput;COMPTABILITE Compte;COMPTABILITE Référence;COMPTABILITE Origine;COMPTABILITE Manuel;Erreur;');
                END IF;
            
                -- Recherche du libellé de la facture.
                BEGIN
                    /*SELECT Company_Name
                      INTO Vv_Lib_Societe
                      FROM Dka_Ibdsoc_General_Info
                     WHERE Company_Code = REC_SARG00C8_RATT.Societe;*/
                    SELECT ffvv.description
                    INTO   Vv_Lib_Societe
                    FROM   fnd_flex_value_sets ffvs,
                           fnd_flex_values_vl  ffvv
                    WHERE  ffvs.flex_value_set_id = ffvv.flex_value_set_id
                    AND    ffvs.flex_value_set_name = 'DAOPCCF_STE'
                    AND    flex_value = REC_SARG00C8_RATT.Societe;
                    
                EXCEPTION
                    WHEN OTHERS THEN
                        Vv_Lib_Societe := NULL;
                END;
                -- Insertion du corps du fichier.
                out_msg(REC_SARG00C8_RATT.Societe || ';' || --Société
                        Vv_Lib_Societe || ';' || --Libellé Société
                        REC_SARG00C8_RATT.Facture || ';' || --Facture
                        REC_SARG00C8_RATT.Date_Facture || ';' || --Date Facture
                        REC_SARG00C8_RATT.Client_Anael || ';' || --Client ANAEL
                        REC_SARG00C8_RATT.Client_Oracle || ';' || --Client OA
                        REC_SARG00C8_RATT.Origine_Facture || ';' || --FACTURATION Orig
                        REC_SARG00C8_RATT.Type || ';' || --FACTURATION Type
                        REC_SARG00C8_RATT.Annu || ';' || --FACTURATION Annu
                        REC_SARG00C8_RATT.Montant_Facture || ';' || --FACTURATION Montant Facture
                        REC_SARG00C8_RATT.Montant_Compta || ';' || --COMPTABILITE Mt Comptabilisé
                        REC_SARG00C8_RATT.Imput || ';' || --COMPTABILITE Imput
                        REC_SARG00C8_RATT.Compte || ';' || --COMPTABILITE Compte
                        REC_SARG00C8_RATT.Refer || ';' || --COMPTABILITE Référence
                        REC_SARG00C8_RATT.Orig || ';' || --COMPTABILITE Origine
                        REC_SARG00C8_RATT.Manu || ';' || --COMPTABILITE Manuel
                        REC_SARG00C8_RATT.Libelle_Erreur || ';'); --Erreur
            
            END LOOP;
            CLOSE CUR_SARG00C8_RATT;
        --END LOOP;    
        log_msg('SARG00C8_RATT 2 - Nombre d''enregistrement présent : ' ||
                Vn_Nb_Error);
        log_msg('SARG00C8_RATT (-)');
    EXCEPTION
        WHEN OTHERS THEN
            Pv_Errbuf  := 'Erreur lors de l''exécution de la procédure SARG00C8_RATT ' ||
                          Substr(SQLERRM, 1, 80);
            Pn_Retcode := 2;
    END SARG00C8_RATT;

END DKA_SARG00C8_PKG;
/
SHOW ERRORS PACKAGE BODY DKA_SARG00C8_PKG; 
EXIT
