CREATE OR REPLACE PACKAGE BODY Dka_Controle_Refac_Pkg IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_CONTROLE_REFAC_PKG.pkb
    -- DESCRIPTION      : DKA_CONTROLE_REFAC_PKG Package Body
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 26/02/2007
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    -- 01/03/2007 EMA Modification de la requête de recherche des sites clients
    --                manquants.
    -- 10/11/2017 YWA Migration R12
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- -----------------------------------------------------------------------------
    -- Nom              : Step_1
    -- Description      : Détermination des clients avec des sociétés groupes
    --                    identiques
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_1(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER) IS

        CURSOR Cur_Lignes IS
            /*SELECT Rc.Customer_Name,
                   Rc.Customer_Number,
                   Rc.Attribute1
            FROM   AR_CUSTOMERS Rc --Ra_Customers Rc --YWA R12 (Attribute1 a revoir pas de detail sur le cuf 11i=> r12)
            WHERE  Rc.Attribute1 IN
                   (SELECT Rc1.Attribute1
                    FROM   AR_CUSTOMERS Rc --RA_CUSTOMERS Rc1 --YWA R12
                    WHERE  Rc1.Status = 'A'
                    AND    Rc1.Attribute1 IS NOT NULL
                    AND    Rc1.Customer_Number NOT IN ('00009739', '00029285')
                    AND EXISTS (/*SELECT 1
                                FROM   Ra_Addresses_All Ra
                                WHERE  Ra.Status = 'A'
                                AND    Ra.Customer_Id = Rc1.Customer_Id*/ --11i
                               /* SELECT 1
                                FROM hz_party_sites party_site,
                                  hz_locations loc,
                                  hz_cust_acct_sites_all acct_site
                                WHERE acct_site.party_site_id = party_site.party_site_id
                                AND loc.location_id           = party_site.location_id
                                AND acct_site.cust_account_id = Rc1.Customer_Id
                                AND acct_site.status          ='A')--YWA R12
                    GROUP  BY Rc1.Attribute1
                    HAVING COUNT(*) > 1);*/ --YWA R12
            SELECT  Rc.Customer_Name,
                   Rc.Customer_Number,
                   substr(hcasa.Attribute8,4) Attribute8
            FROM   AR_CUSTOMERS Rc,
                  HZ_CUST_ACCT_SITES_ALL hcasa
            WHERE hcasa.cust_account_id = Rc.Customer_Id
            AND hcasa.Attribute8 IN ( SELECT acct_site.Attribute8
                                FROM AR_CUSTOMERS Rc1,
                                  HZ_PARTY_SITES party_site,
                                  -- hz_locations loc,
                                  HZ_CUST_ACCT_SITES_ALL acct_site
                                WHERE Rc1.Status             = 'A'
                                AND acct_site.Attribute8    IS NOT NULL
                                AND Rc1.Customer_Number NOT IN ('00009739', '00029285')
                                AND acct_site.party_site_id  = party_site.party_site_id
                                  --AND loc.location_id           = party_site.location_id
                                AND acct_site.cust_account_id = Rc1.Customer_Id
                                AND acct_site.status          ='A'
                                GROUP BY acct_site.Attribute8
                                HAVING COUNT(*) > 1
                               )
            GROUP BY Rc.Customer_Name,
                   Rc.Customer_Number,
                   substr(hcasa.Attribute8,4)  ;--YWA R12

        Rec_Lignes Cur_Lignes%ROWTYPE;

        Vn_Nb_Enreg NUMBER := 0;

    BEGIN

        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 1 : Clients avec des codes sociétés groupes identiques');
        Dka_Tools_Pkg.Put_Outdebug_Message('    ------------------------------------------------------------');

        OPEN Cur_Lignes;
        LOOP
            FETCH Cur_Lignes INTO Rec_Lignes;
            EXIT WHEN Cur_Lignes%NOTFOUND;

            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Nom du client', 51) ||
                                                   Rpad('Num.Client', 11) ||
                                                   Rpad('Part', 4));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 50, '-') || ' ' ||
                                                   Rpad('-', 10, '-') || ' ' ||
                                                   Rpad('-', 4, '-'));

            END IF;
            Dka_Tools_Pkg.Put_Outdebug_Message(Rpad(Rec_Lignes.Customer_Name, 51) || Rpad(Rec_Lignes.Customer_Number, 11) ||Rpad(Rec_Lignes.Attribute8, 4));

            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 1';
        END LOOP;
        CLOSE Cur_Lignes;

    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_1 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_1;

    -- -----------------------------------------------------------------------------
    -- Nom              : Step_2
    -- Description      : Contrôle du détail des mouvements non refacturées
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --                    Pv_Period_Name     Entrée Nom de la période
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_2(Pv_Errbuf         OUT VARCHAR2,
                     Pn_Retcode        OUT NUMBER,
                     Pv_Period_Name IN     VARCHAR2) IS

        CURSOR Cur_Lignes IS
        ---- DEPENSES NON REFACTUREES AVEC OU SANS PROJET A REFACTURER D'ORIGINE AUTRE QUE AP --
            SELECT /*+ ordered use_nl (pt, pei, pcdl, gcc, pp_refac, dsp)*/
                   'Dépense' Origine,
                   Pei.Expenditure_Item_Id Id,
                   Pp.Segment1 Projet_Refac,
                   Pei.Expenditure_Type Type_Mouvement,
                   Nvl(Dsp.Ap_Expenditure_Type, 'Non refacturable') Refacture_En,
                   Pei.Expenditure_Item_Date Date_Mouvement,
                   Pcdl.Gl_Date Date_Gl,
                   Pcdl.Amount Montant,
                   Gcc.Concatenated_Segments Cle,
                   Nvl(Pp_Refac.Segment1, 'Projet à refacturer manquant') Projet_a_Refac,
                   Nvl(Pp_Refac.Description, 'Projet à refacturer manquant') Lib_Projet_a_Refac,
                   Decode(Sign(Ptc.Start_Date_Active - Trunc(Last_Day(SYSDATE))),
                          1, 'NON ACTIF',
                          (Decode(Sign(Ptc.End_Date_Active - Trunc(Last_Day(SYSDATE))),
                                  -1, 'NON ACTIF'))) Statut_Mouvement,
                   Nvl(Hou_Refac.Attribute4, 'N') Soc_Geree,
                   Pp_Refac.Project_Status_Code Statut_Projet,
                   Decode(Pp_Refac.Segment1,
                          NULL, NULL,
                          Decode(Dsp.Ap_Expenditure_Type,
                                 NULL, NULL,
                                 Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Couts_f(Pp_Refac.Project_Id,
                                                                                  Dsp.Ap_Expenditure_Type,
                                                                                  Pei.Expenditure_Item_Id,
                                                                                  Pt_Refac.task_id, --YWA R12
                                                                                  NULL))) Cpt_Groupe,
                   Pei.Creation_Date Date_Creation_Ligne,
                   Orig.Orig_Txn_Number No_Piece_Origine,
                   Orig.Orig_Line_Num No_Ligne_Origine,
                   Orig.Orig_Application Module_Origine,
                   Dst.Transfer_Status_Code Statut_Refac,
                   Dst.Transfer_Rejection_Reason Motif_De_Rejet_Refac
            FROM   Fnd_Flex_Value_Sets Ffvs,
                   Fnd_Flex_Values Ffv,
                   Pa_Projects_All Pp,
                   Hr_Operating_Units hou_pp, --YWA R12
                   Pa_Tasks Pt,
                   PA_EXPENDITURE_ITEMS_ALL Pei,
                   Pa_Cost_Distribution_Lines_All Pcdl,
                   Gl_Code_Combinations_Kfv Gcc,
                   Pa_Projects_All Pp_Refac,
                   Pa_Tasks Pt_Refac, --YWA R12
                   Pa_Project_Classes Ppc_Refac,
                   Pa_Transaction_Controls Ptc,
                   HR_ALL_ORGANIZATION_UNITS Hou_Refac,
                   Dka_Sarrefac_Param Dsp,
                   (SELECT Pei.Expenditure_Item_Id Expenditure_Item_Id,
                           101 Orig_Application_Id,
                           'GL' Orig_Application,
                           Gjh.NAME Orig_Txn_Number,
                           Gjl.Je_Line_Num Orig_Line_Num,
                           ('gjh.je_header_id = ' ||
                           To_Char(Gjh.Je_Header_Id)) Orig_Txn_Id,
                           Gjh.Doc_Sequence_Value Orig_Sequence_Number,
                           Gjl.Effective_Date Orig_Line_Date
                    FROM   Pa_Expenditure_Items_All Pei,
                           Gl_Je_Headers            Gjh,
                           Gl_Je_Lines              Gjl
                    WHERE  Pei.Attribute3 IS NULL
                    AND    Pei.Attribute_Category = 'GL_REFAC'
                    AND    Pei.System_Linkage_Function NOT IN ('VI', 'ER')
                    --AND    Gjh.Je_Header_Id = To_Number(Substr(Pei.Attribute4, 1, (Instr(Pei.Attribute4, '_') - 1)))
                    AND    Gjh.Je_Header_Id = To_Number(Pei.Attribute4)
                    AND    Gjl.Je_Header_Id = Gjh.Je_Header_Id
                    --AND    Gjl.Je_Line_Num = To_Number(Substr(Pei.Attribute4, (Instr(Pei.Attribute4, '_') + 1)))) Orig,
                    AND    Gjl.Je_Line_Num = To_Number(Pei.Attribute8)) Orig,
                   Dka_Sarrefac_Tmp Dst
            WHERE  Ffvs.Flex_Value_Set_Name = 'DAOPCCF_STE'
            AND    Ffv.Flex_Value_Set_Id = Ffvs.Flex_Value_Set_Id
            AND    Ffv.Summary_Flag = 'N'
            AND    hou_pp.name LIKE '%' || Ffv.Flex_Value --YWA R12
            AND    Pp.org_id = Hou_Pp.Organization_Id --YWA R12
            AND    Pei.Task_Id = Pt.Task_Id
            AND    Pp.Project_Id = Pt.Project_Id
            AND    Gcc.Code_Combination_Id = Pcdl.Dr_Code_Combination_Id
            AND    Pp.Project_Type = 'REFAC'
            AND    Pp_Refac.Project_Id(+) = Pei.Attribute1
            AND    Pt_Refac.task_id = Pei.Attribute7 --YWA R12
            AND    Ppc_Refac.Project_Id = Pp_Refac.Project_Id
            AND    Ppc_Refac.Class_Category = 'AFFAIRE'
            AND    Hou_Refac.organization_id = Pei.Attribute2  --YWA R12
            AND    Ptc.Project_Id = Ppc_Refac.Project_Id
            AND    Ptc.Expenditure_Type = Pei.Expenditure_Type
            AND    Pcdl.Expenditure_Item_Id = Pei.Expenditure_Item_Id
            AND    Pei.Expenditure_Type != 'REFACTURATION PRODUITS'
            AND    Pei.Attribute3 IS NULL
            AND    Pcdl.Transfer_Status_Code != 'V'
            AND    Dsp.Orig_Transaction_Type(+) = Pei.Expenditure_Type
            AND    Orig.Expenditure_Item_Id(+) = Pei.Expenditure_Item_Id
            AND    Dst.Transaction_Source(+) = 'EXPENDITURE'
            AND    Dst.Expenditure_Item_Id(+) = Pei.Expenditure_Item_Id 
            UNION ALL
            ---- DEPENSES NON REFACTUREES AVEC OU SANS PROJET A REFACTURER D'ORIGINE AP --
            SELECT /*+ ordered use_nl (pt, pei, pcdl, aid, gcc, pp_refac, dsp)*/
                   'Dépense' Origine,
                   Pei.Expenditure_Item_Id Id,
                   Pp.Segment1 Projet_Refac,
                   Pei.Expenditure_Type Type_Depense,
                   Nvl(Dsp.Ap_Expenditure_Type, 'Non refacturable') Refacture_En,
                   Pei.Expenditure_Item_Date Date_Depense,
                   Pcdl.Gl_Date Date_Gl,
                   Pcdl.Amount Montant,
                   Gcc.Concatenated_Segments Cle,
                   Nvl(Pp_Refac.Segment1, 'Projet à refacturer manquant') Projet_a_Refac,
                   Nvl(Pp_Refac.Description, 'Projet à refacturer manquant') Lib_Projet_a_Refac,
                   Decode(Sign(Ptc.Start_Date_Active - Trunc(Last_Day(SYSDATE))),
                          1, 'NON ACTIF',
                          (Decode(Sign(Ptc.End_Date_Active - Trunc(Last_Day(SYSDATE))),
                                  -1, 'NON ACTIF'))) Statut_Mouvement,
                   Nvl(Hou_Refac.Attribute4, 'N') Soc_Geree,
                   Pp_Refac.Project_Status_Code Statut_Projet,
                   Decode(Pp_Refac.Segment1,
                          NULL, NULL,
                          Decode(Dsp.Ap_Expenditure_Type,
                                 NULL, NULL,
                                 Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Couts_f(Pp_Refac.Project_Id,
                                                                                  Dsp.Ap_Expenditure_Type,
                                                                                  Pei.Expenditure_Item_Id,
                                                                                  Pt_Refac.task_id, --YWA R12
                                                                                  NULL))) Cpt_Groupe,
                   Pei.Creation_Date Date_Creation_Ligne,
                   Orig.Orig_Txn_Number No_Piece_Origine,
                   Orig.Orig_Line_Num No_Ligne_Origine,
                   Orig.Orig_Application Module_Origine,
                   Dst.Transfer_Status_Code Statut_Refac,
                   Dst.Transfer_Rejection_Reason Motif_De_Rejet_Refac
            FROM   Fnd_Flex_Value_Sets Ffvs,
                   Fnd_Flex_Values Ffv,
                   Pa_Projects_All Pp,
                   Hr_Operating_Units hou_pp, --YWA R1
                   Pa_Tasks Pt,
                   Pa_Expenditure_Items_All Pei,
                   Pa_Cost_Distribution_Lines_All Pcdl,
                   Ap_Invoice_Distributions_All Aid,
                   Gl_Code_Combinations_Kfv Gcc,
                   Pa_Projects_All Pp_Refac,
                   Pa_Tasks pt_Refac,
                   Pa_Project_Classes Ppc_Refac,
                   Pa_Transaction_Controls Ptc,
                   Hr_All_Organization_Units Hou_Refac,
                   Dka_Sarrefac_Param Dsp,
                   (SELECT Pei.Expenditure_Item_Id Expenditure_Item_Id,
                           200 Orig_Application_Id,
                           'AP' Orig_Application,
                           Ai.Invoice_Num Orig_Txn_Number,
                           Aid.Distribution_Line_Number Orig_Line_Num,
                           ('aid.invoice_distribution_id = ' ||
                           To_Char(Aid.Invoice_Distribution_Id)) Orig_Txn_Id,
                           Ai.Doc_Sequence_Value Orig_Sequence_Number,
                           Aid.Accounting_Date Orig_Line_Date
                    FROM   Pa_Expenditure_Items_All       Pei,
                           Pa_Cost_Distribution_Lines_All Pcdl,
                           Ap_Invoices_All                Ai,
                           Ap_Invoice_Distributions_All   Aid
                    WHERE  Pei.Attribute3 IS NULL
                    AND    Pei.System_Linkage_Function IN ('VI', 'ER')
                    AND    Pcdl.Expenditure_Item_Id = Pei.Expenditure_Item_Id
                    --AND    Ai.Invoice_Id = To_Number(Pcdl.System_Reference2)  --YWA R12
                    AND    Aid.Invoice_Id = Ai.Invoice_Id
                    --AND    Aid.Distribution_Line_Number = To_Number(Pcdl.System_Reference3)--YWA R12
                    AND    pei.document_distribution_id = Aid.invoice_distribution_id --YWA R12
                    ) Orig,
                   Dka_Sarrefac_Tmp Dst
            WHERE  Ffvs.Flex_Value_Set_Name = 'DAOPCCF_STE'
            AND    Ffv.Flex_Value_Set_Id = Ffvs.Flex_Value_Set_Id
            AND    Ffv.Summary_Flag = 'N'
            AND    hou_pp.name LIKE '%' || Ffv.Flex_Value --YWA R12
            AND    Pp.org_id = Hou_Pp.Organization_Id --YWA R12
            --AND    Pp.Segment1 LIKE '%' || Ffv.Flex_Value
            AND    Pei.Task_Id = Pt.Task_Id
            AND    Pp.Project_Id = Pt.Project_Id
            AND    Gcc.Code_Combination_Id = Pcdl.Dr_Code_Combination_Id
            AND    Pp.Project_Type = 'REFAC'
            AND    Pcdl.Expenditure_Item_Id = Pei.Expenditure_Item_Id
            AND    Pei.Expenditure_Type != 'REFACTURATION PRODUITS'
            AND    Pei.Attribute3 IS NULL
            AND    Pcdl.Transfer_Status_Code = 'V'
            --AND    Aid.Invoice_Id = Pcdl.System_Reference2 --YWA R12
           -- AND    Aid.Distribution_Line_Number = Pcdl.System_Reference3 --YWA R12
            AND    pei.document_distribution_id = Aid.invoice_distribution_id --YWA R12
            AND    Pp_Refac.Project_Id(+) = Aid.Attribute1
            AND    Pt_Refac.task_id(+) = Aid.Attribute7 --YWA R12
            AND    Ppc_Refac.Project_Id = Pp_Refac.Project_Id
            AND    Ppc_Refac.Class_Category = 'AFFAIRE' --YWA R12
            AND    Hou_Refac.organization_id(+) = Pp_Refac.org_id --YWA R12
            AND    Ptc.Project_Id = Ppc_Refac.Project_Id
            AND    Ptc.Expenditure_Type = Pei.Expenditure_Type
            AND    Dsp.Orig_Transaction_Type(+) = Pei.Expenditure_Type
            AND    Orig.Expenditure_Item_Id(+) = Pei.Expenditure_Item_Id
            AND    Dst.Transaction_Source(+) = 'EXPENDITURE'
            AND    Dst.Expenditure_Item_Id(+) = Pei.Expenditure_Item_Id
            UNION ALL
            ---- EVENEMENTS NON REFACTURES AU NIVEAU TACHE AVEC OU SANS PROJET A REFACTURER --
            SELECT /*+ ordered use_nl (pt) */
                   'Evènement' Origine,
                   Pe.Event_Id Id,
                   Pp.Segment1 Projet_Refac,
                   Pe.Event_Type Type_Mouvement,
                   Nvl(Dsp.Ar_Event_Type, 'Non refacturable') Refacture_En,
                   Pe.Completion_Date Date_Mouvement,
                   Pe.Completion_Date Date_Gl,
                   Pcer.Amount Montant,
                   Gcc.Concatenated_Segments Cle,
                   Nvl(Pp_Refac.Segment1, 'Projet à refacturer manquant') Projet_a_Refac,
                   Nvl(Pp_Refac.Description, 'Projet à refacturer manquant') Lib_Projet_a_Refac,
                   Decode(Sign(Pet.Start_Date_Active - Trunc(SYSDATE, 'MM')),
                          1, 'NON ACTIF',
                          (Decode(Sign(Pet.End_Date_Active - Trunc(Last_Day(SYSDATE))),
                                  -1, 'NON ACTIF'))) Statut_Mouvement,
                   Nvl(Hou_Refac.Attribute4, 'N') Soc_Geree,
                   Pp_Refac.Project_Status_Code Statut_Projet,
                   Decode(Pp_Refac.Segment1,
                          NULL, NULL,
                          Decode(Dsp.Ar_Event_Type,
                                 NULL, NULL,
                                 Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Produit_f(Pp_Refac.Project_Id,
                                                                                    Dsp.Ar_Event_Type,
                                                                                    Pt_Refac.task_id --YWA R12
                                                                                    ))) Cpt_Groupe,
                   Pe.Creation_Date Date_Creation_Ligne,
                   Orig.Orig_Txn_Number No_Piece_Origine,
                   Orig.Orig_Line_Num No_Ligne_Origine,
                   Orig.Orig_Application Module_Origine,
                   Dst.Transfer_Status_Code Statut_Refac,
                   Dst.Transfer_Rejection_Reason Motif_De_Rejet_Refac
            FROM   Fnd_Flex_Value_Sets Ffvs,
                   Fnd_Flex_Values Ffv,
                   Pa_Projects_All Pp,
                   Pa_Tasks Pt,
                   pa_events Pe,
                   Pa_Cust_Event_Rdl_All Pcer,
                   Pa_Projects_All Pp_Refac,
                   Hr_Operating_Units hou_pp, --YWA R12
                   Pa_Tasks Pt_Refac, --YWA R12
                   Pa_Project_Classes Ppc_Refac,
                   Pa_Event_Types Pet,
                   Hr_All_Organization_Units Hou_Refac,
                   Gl_Code_Combinations_Kfv Gcc,
                   Dka_Sarrefac_Param Dsp,
                   (SELECT Pe.Event_Id Event_Id,
                           222 Orig_Application_Id,
                           'AR' Orig_Application,
                           Rct.Trx_Number Orig_Txn_Number,
                           Rctl.Line_Number Orig_Line_Num,
                           ('rctlgd.cust_trx_line_gl_dist_id = ' ||
                           To_Char(Rctlgd.Cust_Trx_Line_Gl_Dist_Id)) Orig_Txn_Id,
                           Rct.Doc_Sequence_Value Orig_Sequence_Number,
                           Rct.Trx_Date Orig_Line_Date
                    FROM   Pa_Events                    Pe,
                           Ra_Customer_Trx_All          Rct,
                           Ra_Customer_Trx_Lines_All    Rctl,
                           Ra_Cust_Trx_Line_Gl_Dist_All Rctlgd
                    WHERE  Pe.Attribute_Category = 'AR_REFAC'
                    AND    Rctlgd.Cust_Trx_Line_Gl_Dist_Id = To_Number(Pe.Attribute4)
                    AND    Rctl.Customer_Trx_Line_Id = Rctlgd.Customer_Trx_Line_Id
                    AND    Rct.Customer_Trx_Id = Rctlgd.Customer_Trx_Id
                    UNION ALL
                    SELECT Pe.Event_Id Event_Id,
                           101 Orig_Application_Id,
                           'GL' Orig_Application,
                           Gjh.NAME Orig_Txn_Number,
                           Gjl.Je_Line_Num Orig_Line_Num,
                           ('gjh.je_header_id = ' ||
                           To_Char(Gjh.Je_Header_Id)) Orig_Txn_Id,
                           Gjh.Doc_Sequence_Value Orig_Sequence_Number,
                           Gjl.Effective_Date Orig_Line_Date
                    FROM   Pa_Events     Pe,
                           Gl_Je_Headers Gjh,
                           Gl_Je_Lines   Gjl
                    WHERE  Pe.Attribute3 IS NULL
                    AND    Pe.Attribute_Category = 'GL_REFAC'
                    --AND    Gjh.Je_Header_Id = To_Number(Substr(Pe.Attribute5, 1, (Instr(Pe.Attribute5, '_') - 1)))
                    AND    Gjh.Je_Header_Id = To_Number(Pe.Attribute5)
                    AND    Gjl.Je_Header_Id = Gjh.Je_Header_Id
                    --AND    Gjl.Je_Line_Num = To_Number(Substr(Pe.Attribute5, (Instr(Pe.Attribute5, '_') + 1)))) Orig,
                   AND    Gjl.Je_Line_Num = To_Number(Pe.Attribute8)) Orig,
                   Dka_Sarrefac_Tmp Dst
            WHERE  Ffvs.Flex_Value_Set_Name = 'DAOPCCF_STE'
            AND    Ffv.Flex_Value_Set_Id = Ffvs.Flex_Value_Set_Id
            AND    Ffv.Summary_Flag = 'N'
            AND    hou_pp.name LIKE '%' || Ffv.Flex_Value --YWA R12
            AND    Pp.org_id = Hou_Pp.Organization_Id --YWA R12
            --AND    Pp.Segment1 LIKE '%' || Ffv.Flex_Value
            AND    Pe.Task_Id = Pt.Task_Id
            AND    Pp.Project_Id = Pt.Project_Id
            AND    Pp.Project_Type = 'REFAC'
            AND    Pe.Event_Type NOT IN (SELECT DISTINCT Ar_Event_Type
                                         FROM   Dka_Sarrefac_Param
                                         WHERE  Ar_Event_Type LIKE '%REFAC%')
            AND    Pe.Attribute3 IS NULL
            AND    Pe.Attribute1 = Pp_Refac.Project_Id(+)
            AND    Pe.Attribute7 = Pt_Refac.task_id(+) --YWA R12
            AND    Ppc_Refac.Project_Id = Pp_Refac.Project_Id
            AND    Ppc_Refac.Class_Category = 'AFFAIRE'
            AND    Hou_Refac.ORGANIZATION_id(+) = Pe.attribute2 --YWA R12
            AND    Pet.Event_Type = Pe.Event_Type
            AND    Pcer.Project_Id = Pe.Project_Id
            AND    Pcer.Task_Id = Pe.Task_Id
            AND    Pcer.Event_Num = Pe.Event_Num
            AND    Pcer.Code_Combination_Id = Gcc.Code_Combination_Id
            AND    Dsp.Orig_Transaction_Type(+) = Pe.Event_Type
            AND    Orig.Event_Id(+) = Pe.Event_Id
            AND    Dst.Transaction_Source(+) = 'EVENT'
            AND    Dst.Event_Id(+) = Pe.Event_Id
            UNION ALL
            ---- EVENEMENTS NON REFACTURES AU NIVEAU PROJET AVEC OU SANS PROJET A REFACTURER --
            SELECT /*+ ordered use_nl (pe, pcer) */
                   'Evènement' Origine,
                   Pe.Event_Id Id,
                   Pp.Segment1 Projet_Refac,
                   Pe.Event_Type Type_Mouvement,
                   Nvl(Dsp.Ar_Event_Type, 'Non refacturable') Refacture_En,
                   Pe.Completion_Date Date_Mouvement,
                   Pe.Completion_Date Date_Gl,
                   Pcer.Amount Montant,
                   Gcc.Concatenated_Segments Cle,
                   Nvl(Pp_Refac.Segment1, 'Projet à refacturer manquant') Projet_a_Refac,
                   Nvl(Pp_Refac.Description, 'Projet à refacturer manquant') Lib_Projet_a_Refac,
                   Decode(Sign(Pet.Start_Date_Active - Trunc(SYSDATE, 'MM')),
                          1, 'NON ACTIF',
                          (Decode(Sign(Pet.End_Date_Active - Trunc(Last_Day(SYSDATE))),
                                  -1, 'NON ACTIF'))) Statut_Mouvement,
                   Nvl(Hou_Refac.Attribute4, 'N') Soc_Geree,
                   Pp_Refac.Project_Status_Code Statut_Projet,
                   Decode(Pp_Refac.Segment1,
                          NULL, NULL,
                          Decode(Dsp.Ar_Event_Type,
                                 NULL, NULL,
                                 Dka_Spaautoaccounting_Pkg.Run_Cpt_Groupe_Produit_f(Pp_Refac.Project_Id,
                                                                                    Dsp.Ar_Event_Type,
                                                                                    Pt_Refac.task_id --YWA R12
                                                                                    ))) Cpt_Groupe,
                   Pe.Creation_Date Date_Creation_Ligne,
                   Orig.Orig_Txn_Number No_Piece_Origine,
                   Orig.Orig_Line_Num No_Ligne_Origine,
                   Orig.Orig_Application Module_Origine,
                   Dst.Transfer_Status_Code Statut_Refac,
                   Dst.Transfer_Rejection_Reason Motif_De_Rejet_Refac
            FROM   Fnd_Flex_Value_Sets Ffvs,
                   Fnd_Flex_Values Ffv,
                   Pa_Projects_All Pp,
                   Pa_Events Pe,
                   Pa_Cust_Event_Rdl_All Pcer,
                   Pa_Projects_All Pp_Refac,
                   Hr_Operating_Units hou_pp, --YWA R12
                   Pa_Tasks Pt_Refac, --YWA R12
                   Pa_Project_Classes Ppc_Refac,
                   Pa_Event_Types Pet,
                   Hr_All_Organization_Units Hou_Refac,
                   Gl_Code_Combinations_Kfv Gcc,
                   Dka_Sarrefac_Param Dsp,
                   (SELECT Pe.Event_Id Event_Id,
                           222 Orig_Application_Id,
                           'AR' Orig_Application,
                           Rct.Trx_Number Orig_Txn_Number,
                           Rctl.Line_Number Orig_Line_Num,
                           ('rctlgd.cust_trx_line_gl_dist_id = ' || To_Char(Rctlgd.Cust_Trx_Line_Gl_Dist_Id)) Orig_Txn_Id,
                           Rct.Doc_Sequence_Value Orig_Sequence_Number,
                           Rct.Trx_Date Orig_Line_Date
                    FROM   Pa_Events                    Pe,
                           Ra_Customer_Trx_All          Rct,
                           Ra_Customer_Trx_Lines_All    Rctl,
                           Ra_Cust_Trx_Line_Gl_Dist_All Rctlgd
                    WHERE  Pe.Attribute_Category = 'AR_REFAC'
                    AND    Rctlgd.Cust_Trx_Line_Gl_Dist_Id = To_Number(Pe.Attribute4)
                    AND    Rctl.Customer_Trx_Line_Id = Rctlgd.Customer_Trx_Line_Id
                    AND    Rct.Customer_Trx_Id = Rctlgd.Customer_Trx_Id
                    UNION ALL
                    SELECT Pe.Event_Id Event_Id,
                           101 Orig_Application_Id,
                           'GL' Orig_Application,
                           Gjh.NAME Orig_Txn_Number,
                           Gjl.Je_Line_Num Orig_Line_Num,
                           ('gjh.je_header_id = ' || To_Char(Gjh.Je_Header_Id)) Orig_Txn_Id,
                           Gjh.Doc_Sequence_Value Orig_Sequence_Number,
                           Gjl.Effective_Date Orig_Line_Date
                    FROM   Pa_Events     Pe,
                           Gl_Je_Headers Gjh,
                           Gl_Je_Lines   Gjl
                    WHERE  Pe.Attribute3 IS NULL
                    AND    Pe.Attribute_Category = 'GL_REFAC'
                    --AND    Gjh.Je_Header_Id = To_Number(Substr(Pe.Attribute5, 1, (Instr(Pe.Attribute5, '_') - 1)))
                    AND    Gjh.Je_Header_Id = To_Number(Pe.Attribute5)
                    AND    Gjl.Je_Header_Id = Gjh.Je_Header_Id
                    -- AND    Gjl.Je_Line_Num = To_Number(Substr(Pe.Attribute5, (Instr(Pe.Attribute5, '_') + 1)))) Orig,
                    AND    Gjl.Je_Line_Num = To_Number(Pe.Attribute5)) Orig,
                   Dka_Sarrefac_Tmp Dst
            WHERE  1 = 1
            AND    Ffvs.Flex_Value_Set_Name = 'DAOPCCF_STE'
            AND    Ffv.Flex_Value_Set_Id = Ffvs.Flex_Value_Set_Id
            AND    Ffv.Summary_Flag = 'N'
            AND    hou_pp.name LIKE '%' || Ffv.Flex_Value --YWA R12
            AND    Pp.org_id = Hou_Pp.Organization_Id --YWA R12
            --AND    Pp.Segment1 LIKE '%' || Ffv.Flex_Value
            AND    Pp.Project_Id = Pe.Project_Id
            AND    Pp.Project_Type = 'REFAC'
            AND    Pe.Event_Type NOT IN (SELECT DISTINCT Ar_Event_Type
                                         FROM   Dka_Sarrefac_Param
                                         WHERE  Ar_Event_Type LIKE '%REFAC%')
            AND    Pe.Attribute3 IS NULL
            AND    Pe.Attribute1 = Pp_Refac.Project_Id(+)
            AND    Pe.Attribute7 = Pt_Refac.task_id(+) --YWA R12
            AND    Ppc_Refac.Project_Id = Pp_Refac.Project_Id
            AND    Ppc_Refac.Class_Category = 'AFFAIRE'
            AND    Hou_Refac.ORGANIZATION_id(+) = Pe.attribute2 --YWA R12
            AND    Pet.Event_Type = Pe.Event_Type
            AND    Pcer.Project_Id = Pe.Project_Id
            AND    Pcer.Event_Num = Pe.Event_Num
            AND    Pcer.Code_Combination_Id = Gcc.Code_Combination_Id
            AND    Dsp.Orig_Transaction_Type(+) = Pe.Event_Type
            AND    Orig.Event_Id(+) = Pe.Event_Id
            AND    Dst.Transaction_Source(+) = 'EVENT'
            AND    Dst.Event_Id(+) = Pe.Event_Id;

        Rec_Lignes Cur_Lignes%ROWTYPE;

        Vn_Nb_Enreg       NUMBER := 0;
        Vb_Edition_Detail BOOLEAN;
        Vc_Dummy          VARCHAR2(1);

        PROCEDURE Edition_Detail IS
        BEGIN
            IF NOT Vb_Edition_Detail THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message('Anomalie pour le mouvement suivant :');
                Dka_Tools_Pkg.Put_Outdebug_Message('------------------------------------');
                Dka_Tools_Pkg.Put_Outdebug_Message('    Origine                 : ' || Rec_Lignes.Origine);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Id                      : ' || Rec_Lignes.Id);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Projet Refacturation    : ' || Rec_Lignes.Projet_Refac);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Type de mouvement       : ' || Rec_Lignes.Type_Mouvement);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Refacturé en            : ' || Rec_Lignes.Refacture_En);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Date du mouvement       : ' || Rec_Lignes.Date_Mouvement);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Date GL                 : ' || Rec_Lignes.Date_Gl);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Montant                 : ' || Rec_Lignes.Montant);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Clé                     : ' || Rec_Lignes.Cle);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Projet à refacturer     : ' || Rec_Lignes.Projet_a_Refac);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Libellé projet à refac. : ' || Rec_Lignes.Lib_Projet_a_Refac);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Statut du mouvement     : ' || Rec_Lignes.Statut_Mouvement);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Societé gérée           : ' || Rec_Lignes.Soc_Geree);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Statut du projet        : ' || Rec_Lignes.Statut_Projet);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Compte groupe           : ' || Rec_Lignes.Cpt_Groupe);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Date de création        : ' || Rec_Lignes.Date_Creation_Ligne);
                Dka_Tools_Pkg.Put_Outdebug_Message('    N° de pièce origine     : ' || Rec_Lignes.No_Piece_Origine);
                Dka_Tools_Pkg.Put_Outdebug_Message('    N° de ligne origine     : ' || Rec_Lignes.No_Ligne_Origine);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Module origine          : ' || Rec_Lignes.Module_Origine);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Statut refacturation    : ' || Rec_Lignes.Statut_Refac);
                Dka_Tools_Pkg.Put_Outdebug_Message('    Motif de rejet          : ' || Rec_Lignes.Motif_De_Rejet_Refac);
            END IF;
            Vb_Edition_Detail := TRUE;
        END;

    BEGIN

        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 2 : Détail des mouvements non refacturés');
        Dka_Tools_Pkg.Put_Outdebug_Message('    ----------------------------------------------');

        OPEN Cur_Lignes;
        LOOP
            FETCH Cur_Lignes INTO Rec_Lignes;
            EXIT WHEN Cur_Lignes%NOTFOUND;

            Vn_Nb_Enreg       := Vn_Nb_Enreg + 1;
            Vb_Edition_Detail := FALSE;

            -------------------------------------------------
            -- Le projet ne doit pas être non refacturable --
            -------------------------------------------------
            IF Rec_Lignes.Refacture_En = 'Non refacturable' THEN
                Edition_Detail;
                Dka_Tools_Pkg.Put_Outdebug_Message('====> Le projet est non refacturable');
                Pn_Retcode := 1;
            END IF;

            -------------------------------------------------------------------------------------------------
            -- Le type de dépense ne doit pas faire partie des types de dépense non autorisés en saisie AP --
            -------------------------------------------------------------------------------------------------
            IF Rec_Lignes.Origine = 'Dépense' THEN
                BEGIN
                    SELECT 'X'
                    INTO   Vc_Dummy
                    FROM   Pa_Expenditure_Types_Expend_v Pete
                    WHERE  Pete.Expenditure_Type = Rec_Lignes.Refacture_En
                    AND    Pete.System_Linkage_Function = 'VI'
                    AND    Last_Day(SYSDATE) BETWEEN Pete.Expnd_Typ_Start_Date_Active
                                             AND     Nvl(Pete.Expnd_Typ_End_Date_Active, Last_Day(SYSDATE))
                    AND    Last_Day(SYSDATE) BETWEEN Pete.Sys_Link_Start_Date_Active
                                             AND     Nvl(Pete.Sys_Link_End_Date_Active, Last_Day(SYSDATE));

                EXCEPTION
                    WHEN OTHERS THEN
                        Edition_Detail;
                        Dka_Tools_Pkg.Put_Outdebug_Message('====> Le type de dépense ' || Rec_Lignes.Refacture_En ||
                                                           ' est non autorisé en saisie AP');
                        Pn_Retcode := 1;
                END;
            END IF;

            ---------------------------------------------------------
            -- la date GL doit faire partie de la période en cours --
            ---------------------------------------------------------
            BEGIN

                SELECT 'X'
                INTO   Vc_Dummy
                FROM   Gl_Period_Statuses Gps
                WHERE  Gps.Period_Name = Pv_Period_Name
                AND    Gps.Application_Id = 101
               -- AND    Gps.Set_Of_Books_Id = 1  --YWA  R12
                AND rownum = 1  --YWA  R12
                AND    Rec_Lignes.Date_Gl BETWEEN Gps.Start_Date
                                          AND     Gps.End_Date;

            EXCEPTION
                WHEN OTHERS THEN
                    Edition_Detail;
                    Dka_Tools_Pkg.Put_Outdebug_Message('====> La date GL n''est pas comprise dans la période courante');
                    Pn_Retcode := 1;
            END;

            ------------------------------------------------
            -- Le projet à refacturer doit être renseigné --
            ------------------------------------------------
            IF Rec_Lignes.Projet_a_Refac IS NULL THEN
                Edition_Detail;
                Dka_Tools_Pkg.Put_Outdebug_Message('====> Le projet à refacturer doit être renseigné');
                Pn_Retcode := 1;
            END IF;

            ----------------------------------------------------
            -- Le statut du mouvement doit être non renseigné --
            ----------------------------------------------------
            IF Rec_Lignes.Statut_Mouvement IS NOT NULL THEN
                Edition_Detail;
                Dka_Tools_Pkg.Put_Outdebug_Message('====> Le statut du mouvement doit être non renseigné');
                Pn_Retcode := 1;
            END IF;

            ------------------------------------------------
            -- La société gérée doit être différente de N --
            ------------------------------------------------
            IF Rec_Lignes.Soc_Geree = 'N' THEN
                Edition_Detail;
                Dka_Tools_Pkg.Put_Outdebug_Message('====> La société gérée doit être différente de N');
                Pn_Retcode := 1;
            END IF;

            -------------------------------------------------------
            -- Le statut du projet doit être différent de CLOSED --
            -------------------------------------------------------
            IF Rec_Lignes.Statut_Projet = 'CLOSED' THEN
                Edition_Detail;
                Dka_Tools_Pkg.Put_Outdebug_Message('====> Le statut du projet doit être différent de CLOSED');
                Pn_Retcode := 1;
            END IF;

            ------------------------------------------
            -- Le compte groupe doit être renseigné --
            ------------------------------------------
            IF Rec_Lignes.Cpt_Groupe IS NULL THEN
                Edition_Detail;
                Dka_Tools_Pkg.Put_Outdebug_Message('====> Le compte groupe doit être renseigné');
                Pn_Retcode := 1;
            END IF;

        END LOOP;
        CLOSE Cur_Lignes;

        IF Pn_Retcode = 1 THEN
           Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 2';
        END IF;


    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_2 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_2;

    -- -----------------------------------------------------------------------------
    -- Nom              : Step_3
    -- Description      : Détermination des sites fournisseurs et clients manquants
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --                    Pv_Period_Name     Entrée Nom de la période
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_3(Pv_Errbuf         OUT VARCHAR2,
                     Pn_Retcode        OUT NUMBER,
                     Pv_Period_Name IN     VARCHAR2) IS

        Vv_Sql_Stmt VARCHAR2(32000);
        Vd_End_Date DATE;

        ----------------------------------------------------------------------------
        -- Curseur de lecture des fournisseurs et/ou sites fournisseurs manquants --
        ----------------------------------------------------------------------------
        CURSOR Cur_Four IS
            SELECT v.Org_Name Partenaire,
                   Pv.Vendor_Name Nom_Fournisseur,
                   Pv.Segment1 Code_Fournisseur,
                   v.Acct_Center Site_Manquant,
                   v.Transaction_Source Transaction_Source,
                   SUM(v.Nb_Lignes) Nb_De_Lignes,
                   SUM(v.Montant) Montant
            FROM   (SELECT Dst.From_Org_Name_Project Org_Name,
                           Dst.To_Acct_Center Acct_Center,
                           Dst.Transaction_Source,
                           COUNT(1) Nb_Lignes,
                           SUM(Amount) Montant
                    FROM   Dka_Controle_Refac Dst
                    WHERE  Dst.Transaction_Source = 'EXPENDITURE'
                    GROUP  BY Dst.From_Org_Name_Project,
                              Dst.To_Acct_Center,
                              Dst.Transaction_Source
                    UNION
                    SELECT Dst.To_Org_Name_Project Org_Name,
                           Dst.From_Acct_Center Acct_Center,
                           Dst.Transaction_Source,
                           COUNT(1) Nb_Lignes,
                           SUM(Amount) Montant
                    FROM   Dka_Controle_Refac Dst
                    WHERE  Dst.Transaction_Source = 'EVENT'
                    GROUP  BY Dst.To_Org_Name_Project,
                              Dst.From_Acct_Center,
                              Dst.Transaction_Source) v,
                   PO_VENDORS Pv
            WHERE  Pv.Attribute2(+) = v.Org_Name
            /*AND    NOT EXISTS (SELECT 'x'
                               FROM   Po_Vendor_Sites_All Pvsa,
                                      Po_Vendors          Pv
                               WHERE  1 = 1
                               AND    Pv.Vendor_Id = Pvsa.Vendor_Id
                               AND    Pv.Attribute2 = v.Org_Name
                               AND    Pvsa.Vendor_Site_Code LIKE v.Acct_Center || '%'
                               AND    Pvsa.Inactive_Date IS NULL)*/
              AND    NOT EXISTS (SELECT 'x'
                               FROM   ap_supplier_sites_all Pvsa,
                                      Po_Vendors          Pv,
                                      HR_OPERATING_UNITS hou
                               WHERE  1 = 1
                               AND    Pv.Vendor_Id = Pvsa.Vendor_Id
                               AND    Pv.Attribute2 = v.Org_Name
                               AND    hou.organization_id= Pvsa.org_id
                               AND    hou.name LIKE v.Acct_Center || '%' --YWA region r12
                               AND    Pvsa.Inactive_Date IS NULL) --YWA  r12
            GROUP  BY v.Org_Name,
                      v.Acct_Center,
                      Pv.Vendor_Name,
                      Pv.Segment1,
                      v.Transaction_Source;

        ------------------------------------------------------------------
        -- Curseur de lecture des clients et/ou sites clients manquants --
        ------------------------------------------------------------------
        -- Modif EMA du 01/03/2007 : Modification de la requête
        CURSOR Cur_Client IS
            SELECT v.Org_Name Partenaire,
                   h.Account_Number Code_Client,
                   v.Acct_Center Site_Manquant,
                   v.Transaction_Source Transaction_Source,
                   SUM(v.Nb_Lignes) Nb_De_Lignes,
                   SUM(v.Montant) Montant
            -- EMA 01/03/2007 FROM   (SELECT Dst.To_Org_Name Org_Name,
            FROM   (SELECT Dst.To_Org_Name_Project Org_Name,
                           Dst.From_Acct_Center Acct_Center,
                           Dst.Transaction_Source Transaction_Source,
                           COUNT(1) Nb_Lignes,
                           SUM(Amount) Montant
                    FROM   Dka_Controle_Refac Dst
                    WHERE  Dst.Transaction_Source = 'EXPENDITURE'
            -- EMA 01/03/2007 GROUP  BY Dst.To_Org_Name,
                    GROUP  BY Dst.To_Org_Name_Project,
                              Dst.From_Acct_Center,
                              Dst.Transaction_Source
                    UNION ALL
            -- EMA 01/03/2007 SELECT Dst.From_Org_Name Org_Name,
                    SELECT Dst.From_Org_Name_Project Org_Name,
                           Dst.To_Acct_Center Acct_Center,
                           Dst.Transaction_Source Transaction_Source,
                           COUNT(1) Nb_Lignes,
                           SUM(Amount) Montant
                    FROM   Dka_Controle_Refac Dst
                    WHERE  Dst.Transaction_Source = 'EVENT'
            -- EMA 01/03/2007 GROUP  BY Dst.From_Org_Name,
                    GROUP  BY Dst.From_Org_Name_Project,
                              Dst.To_Acct_Center,
                              Dst.Transaction_Source) v,
                   Hz_Cust_Accounts h,
                   HZ_CUST_ACCT_SITES_ALL Hcasa --YWA r12
            WHERE  Hcasa.Attribute8(+) = v.Org_Name  --YWA r12
            AND    h.Cust_Account_Id = Hcasa.Cust_Account_Id  --YWA r12
            AND    NOT EXISTS (SELECT 'x'
                               FROM   Gl_Code_Combinations   Gcc,
                                      Hz_Cust_Site_Uses_All  Hcsu,
                                      Hz_Cust_Acct_Sites_All Hcas,
                                      Hz_Cust_Accounts       Hca
                               WHERE  Hcsu.Gl_Id_Rec = Gcc.Code_Combination_Id
                               AND    Hcsu.Cust_Acct_Site_Id = Hcas.Cust_Acct_Site_Id
                               AND    Hcsu.Org_Id = Hcas.Org_Id
                               AND    Hca.Cust_Account_Id = Hcas.Cust_Account_Id
                               AND    Hcsu.Site_Use_Code = 'BILL_TO'
                               AND    Hcsu.Status = 'A'
                               AND    Hcas.Status = 'A'
                               AND    Hcas.Attribute8 = v.Org_Name --YWA r12
                               AND    Gcc.Segment2 = v.Acct_Center)
            GROUP  BY v.Org_Name,
                      h.Account_Number,
                      v.Acct_Center,
                      v.Transaction_Source;

        Rec_Four    Cur_Four%ROWTYPE;
        Rec_Client  Cur_Client%ROWTYPE;
        Vn_Nb_Enreg NUMBER := 0;

    BEGIN
        Vv_Sql_Stmt := 'TRUNCATE TABLE DKA.DKA_CONTROLE_REFAC';

        EXECUTE IMMEDIATE Vv_Sql_Stmt;

        SELECT DISTINCT Gps.End_Date
        INTO   Vd_End_Date
        FROM   Gl_Period_Statuses Gps
        WHERE  Gps.Period_Name = Pv_Period_Name
        AND    Gps.Application_Id = 101 ;
        --AND    Gps.Set_Of_Books_Id = 1; --YWA R12

        ----------------------------------------------------
        -- Insertion des données dans la table de travail --
        ----------------------------------------------------
        /*INSERT INTO Dka_Controle_Refac
            /*SELECT 'EXPENDITURE' Transaction_Source,
                   From_Hou.Organization_Id From_Org_Id,
                   From_Hou.NAME From_Org_Name,
                   Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                            0,
                                                                            Trunc(SYSDATE),
                                                                            NULL), 4, 4) From_Org_Name_Project,
                   To_Hou.Organization_Id To_Org_Id,
                   To_Hou.NAME To_Org_Name,
                   Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                            0,
                                                                            Trunc(SYSDATE),
                                                                            NULL), 4, 4) To_Org_Name_Project,
                   From_Pp.Project_Id From_Project_Id,
                   From_Pt.Task_Id From_Task_Id,
                   To_Pp.Project_Id To_Project_Id,
                   To_Pt.Task_Id To_Task_Id,
                   Decode(From_Digi.Segmented_Company_Flag,
                          'N', From_Digi.Mainoffice_Cost_Center,
                          Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                                   0,
                                                                                   Trunc(SYSDATE),
                                                                                   NULL), 1, 3)) From_Acct_Center,
                   Decode(To_Digi.Segmented_Company_Flag,
                          'N', To_Digi.Mainoffice_Cost_Center,
                          Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                                   0,
                                                                                   Trunc(SYSDATE),
                                                                                   NULL), 1, 3)) To_Acct_Center,
                   Nvl(To_Hou.Attribute4, 'Y') Create_Ap_Data_Flag,
                   Nvl(From_Hou.Attribute4, 'Y') Create_Ar_Data_Flag,
                   Pei.Expenditure_Item_Id Expenditure_Item_Id,
                   NULL Event_Id,
                   Pec.Expenditure_Comment Description,
                   Pcdl.Cr_Code_Combination_Id Pa_Cr_Ccid,
                   Pcdl.Dr_Code_Combination_Id Pa_Dr_Ccid,
                   Pei.Quantity Quantity,
                   Pei.Expenditure_Item_Date Orig_Transaction_Date,
                   Pcdl.Gl_Date Gl_Date,
                   Pei.Expenditure_Type Orig_Transaction_Type,
                   Dsp.Ar_Event_Type Ar_Event_Type,
                   Dsp.Ap_Expenditure_Type Ap_Expenditure_Type,
                   Pei.Raw_Cost Amount
            FROM   Pa_Expenditure_Items_All       Pei,
                   Pa_Cost_Distribution_Lines_All Pcdl,
                   Pa_Expenditure_Comments        Pec,
                   Pa_Projects_All                From_Pp,
                   Pa_Tasks                       From_Pt,
                   Pa_Projects_All                To_Pp,
                   Pa_Project_Classes             Ppc,
                   Pa_Tasks                       To_Pt,
                   Dka_Sarrefac_Param             Dsp,
                   Hr_All_Organization_Units      From_Hou,
                   Hr_All_Organization_Units      From_Hou_Fils,
                   Hr_All_Organization_Units      To_Hou,
                   Pa_Implementations_All         Pi,
                   Dka_Ibdsoc_General_Info        From_Digi,
                   Dka_Ibdsoc_General_Info        To_Digi
            WHERE  Pi.Set_Of_Books_Id = 1
            AND    Pei.Org_Id = Pi.Org_Id
            AND    Pei.Attribute3 IS NULL
            AND    Pei.Attribute1 IS NOT NULL
            AND    Pei.System_Linkage_Function NOT IN ('VI', 'ER')
            AND    To_Pp.Project_Id = To_Number(Pei.Attribute1)
            AND    From_Pt.Task_Id = Pei.Task_Id
            AND    From_Pp.Project_Id = From_Pt.Project_Id
            AND    From_Pp.Org_Id = Pei.Org_Id
            AND    From_Pp.Project_Type = 'REFAC'
            AND    Pcdl.Expenditure_Item_Id = Pei.Expenditure_Item_Id
            AND    Pcdl.Org_Id = Pei.Org_Id
            AND    Pcdl.Transfer_Status_Code IN ('A', 'V')
            AND    Trunc(Pcdl.Gl_Date) <= Trunc(Vd_End_Date)
            AND    Dsp.Orig_Transaction_Type = Pei.Expenditure_Type
            AND    Pec.Expenditure_Item_Id(+) = Pei.Expenditure_Item_Id
            AND    From_Hou_Fils.Organization_Id = Pei.Override_To_Organization_Id
            AND    From_Hou.NAME = From_Hou_Fils.Attribute1
            AND    Ppc.Project_Id = To_Pp.Project_Id
            AND    Ppc.Class_Category = 'SOCIETE'
            AND    To_Hou.NAME = Ppc.Class_Code
            AND    To_Pt.Task_Id = (SELECT MIN(Pt.Task_Id)
                                    FROM   Pa_Tasks Pt
                                    WHERE  Pt.Project_Id = To_Pp.Project_Id
                                    AND    Pt.Chargeable_Flag = 'Y'
                                    AND    Pei.Expenditure_Item_Date BETWEEN Pt.Start_Date
                                                                     AND     Nvl(Pt.Completion_Date, Pei.Expenditure_Item_Date))
                                    AND    From_Digi.Company_Code = Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                                                                             0,
                                                                                                                             Trunc(SYSDATE),
                                                                                                                             NULL), 4, 4)
                                    AND    To_Digi.Company_Code = Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                                                                           0,
                                                                                                                           Trunc(SYSDATE),
                                                                                                                           NULL), 4, 4)
            UNION ALL
            SELECT 'EXPENDITURE' Transaction_Source,
                   From_Hou.Organization_Id From_Org_Id,
                   From_Hou.NAME From_Org_Name,
                   Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                            0,
                                                                            Trunc(SYSDATE),
                                                                            NULL), 4, 4) From_Org_Name_Project,
                   To_Hou.Organization_Id To_Org_Id,
                   To_Hou.NAME To_Org_Name,
                   Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                            0,
                                                                            Trunc(SYSDATE),
                                                                            NULL), 4, 4) To_Org_Name_Project,
                   From_Pp.Project_Id From_Project_Id,
                   From_Pt.Task_Id From_Task_Id,
                   To_Pp.Project_Id To_Project_Id,
                   To_Pt.Task_Id To_Task_Id,
                   Decode(From_Digi.Segmented_Company_Flag,
                          'N', From_Digi.Mainoffice_Cost_Center,
                          Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                                   0,
                                                                                   Trunc(SYSDATE),
                                                                                   NULL), 1, 3)) From_Acct_Center,
                   Decode(To_Digi.Segmented_Company_Flag,
                          'N', To_Digi.Mainoffice_Cost_Center,
                          Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                                   0,
                                                                                   Trunc(SYSDATE),
                                                                                   NULL), 1, 3)) To_Acct_Center,
                   Nvl(To_Hou.Attribute4, 'Y') Create_Ap_Data_Flag,
                   Nvl(From_Hou.Attribute4, 'Y') Create_Ar_Data_Flag,
                   Pei.Expenditure_Item_Id Expenditure_Item_Id,
                   NULL Event_Id,
                   Pec.Expenditure_Comment Description,
                   Pcdl.Cr_Code_Combination_Id Pa_Cr_Ccid,
                   Pcdl.Dr_Code_Combination_Id Pa_Dr_Ccid,
                   Pei.Quantity Quantity,
                   Pei.Expenditure_Item_Date Orig_Transaction_Date,
                   Pcdl.Gl_Date Gl_Date,
                   Pei.Expenditure_Type Orig_Transaction_Type,
                   Dsp.Ar_Event_Type Ar_Event_Type,
                   Dsp.Ap_Expenditure_Type Ap_Expenditure_Type,
                   Pei.Raw_Cost Amount
            FROM   Pa_Expenditure_Items_All Pei,
                   Pa_Cost_Distribution_Lines_All Pcdl,
                   Pa_Expenditure_Comments Pec,
                   Pa_Projects_All From_Pp,
                   Pa_Tasks From_Pt,
                   Pa_Projects_All To_Pp,
                   Pa_Project_Classes Ppc,
                   Pa_Tasks To_Pt,
                   Dka_Sarrefac_Param Dsp,
                   Hr_All_Organization_Units From_Hou,
                   Hr_All_Organization_Units From_Hou_Fils,
                   Hr_All_Organization_Units To_Hou,
                   Pa_Implementations_All Pi,
                   Dka_Ibdsoc_General_Info From_Digi,
                   Dka_Ibdsoc_General_Info To_Digi,
                   (SELECT Expenditure_Item_Id,
                           Aid.Attribute1
                    FROM   Pa_Cost_Distribution_Lines_All Pcdl,
                           Ap_Invoice_Distributions_All   Aid
                    WHERE  1 = 1
                    AND    Aid.Org_Id = 81
                    AND    Aid.Invoice_Id = Pcdl.System_Reference2
                    AND    Aid.Distribution_Line_Number = Pcdl.System_Reference3) Fact_Ap
            WHERE  Pi.Set_Of_Books_Id = 1
            AND    Pei.Org_Id = Pi.Org_Id
            AND    Pei.Attribute3 IS NULL
            AND    Pei.System_Linkage_Function IN ('VI', 'ER')
            AND    To_Pp.Project_Id = To_Number(Fact_Ap.Attribute1)
            AND    Fact_Ap.Expenditure_Item_Id = Pei.Expenditure_Item_Id
            AND    From_Pt.Task_Id = Pei.Task_Id
            AND    From_Pp.Project_Id = From_Pt.Project_Id
            AND    From_Pp.Org_Id = Pei.Org_Id
            AND    From_Pp.Project_Type = 'REFAC'
            AND    Pcdl.Expenditure_Item_Id = Pei.Expenditure_Item_Id
            AND    Pcdl.Org_Id = Pei.Org_Id
            AND    Pcdl.Transfer_Status_Code IN ('A', 'V')
            AND    Trunc(Pcdl.Gl_Date) <= Trunc(Vd_End_Date)
            AND    Dsp.Orig_Transaction_Type = Pei.Expenditure_Type
            AND    Pec.Expenditure_Item_Id(+) = Pei.Expenditure_Item_Id
            AND    From_Hou_Fils.Organization_Id = Pei.Override_To_Organization_Id
            AND    From_Hou.NAME = From_Hou_Fils.Attribute1
            AND    Ppc.Project_Id = To_Pp.Project_Id
            AND    Ppc.Class_Category = 'SOCIETE'
            AND    To_Hou.NAME = Ppc.Class_Code
            AND    To_Pt.Task_Id = (SELECT MIN(Pt.Task_Id)
                                    FROM   Pa_Tasks Pt
                                    WHERE  Pt.Project_Id = To_Pp.Project_Id
                                    AND    Pt.Chargeable_Flag = 'Y'
                                    AND    Pei.Expenditure_Item_Date BETWEEN Pt.Start_Date
                                                                     AND     Nvl(Pt.Completion_Date, Pei.Expenditure_Item_Date))
                                    AND    From_Digi.Company_Code = Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                                                                             0,
                                                                                                                             Trunc(SYSDATE),
                                                                                                                             NULL), 4, 4)
                                    AND    To_Digi.Company_Code = Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                                                                           0,
                                                                                                                           Trunc(SYSDATE),
                                                                                                                           NULL), 4, 4)
            UNION ALL
            SELECT 'EVENT' Transaction_Source,
                   From_Hou.Organization_Id From_Org_Id,
                   From_Hou.NAME From_Org_Name,
                   Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                            0,
                                                                            Trunc(SYSDATE),
                                                                            NULL), 4, 4) From_Org_Name_Project,
                   To_Hou.Organization_Id To_Org_Id,
                   To_Hou.NAME To_Org_Name,
                   Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                            0,
                                                                            Trunc(SYSDATE),
                                                                            NULL), 4, 4) To_Org_Name_Project,
                   From_Pp.Project_Id From_Project_Id,
                   From_Pt.Task_Id From_Task_Id,
                   To_Pp.Project_Id To_Project_Id,
                   To_Pt.Task_Id To_Task_Id,
                   Decode(From_Digi.Segmented_Company_Flag,
                          'N', From_Digi.Mainoffice_Cost_Center,
                          Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                                   0,
                                                                                   Trunc(SYSDATE),
                                                                                   NULL), 1, 3)) From_Acct_Center,
                   Decode(To_Digi.Segmented_Company_Flag,
                          'N', To_Digi.Mainoffice_Cost_Center,
                          Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                                   0,
                                                                                   Trunc(SYSDATE),
                                                                                   NULL), 1, 3)) To_Acct_Center,
                   Nvl(From_Hou.Attribute4, 'Y') Create_Ap_Data_Flag,
                   Nvl(To_Hou.Attribute4, 'Y') Create_Ar_Data_Flag,
                   NULL Expenditure_Item_Id,
                   Pe.Event_Id Event_Id,
                   Pe.Description Description,
                   Pdr.Unearned_Code_Combination_Id Pa_Cr_Ccid,
                   Pcer.Code_Combination_Id Pa_Dr_Ccid,
                   Pe.Revenue_Amount Quantity,
                   Pe.Completion_Date Orig_Transaction_Date,
                   Pdr.Gl_Date Gl_Date,
                   Pe.Event_Type Orig_Transaction_Type,
                   Dsp.Ar_Event_Type Ar_Event_Type,
                   Dsp.Ap_Expenditure_Type Ap_Expenditure_Type,
                   Pe.Revenue_Amount Amount
            FROM   Pa_Events                 Pe,
                   Pa_Cust_Event_Rdl_All     Pcer,
                   Pa_Draft_Revenues_All     Pdr,
                   Pa_Projects_All           From_Pp,
                   Pa_Tasks                  From_Pt,
                   Pa_Projects_All           To_Pp,
                   Pa_Project_Classes        Ppc,
                   Pa_Tasks                  To_Pt,
                   Dka_Sarrefac_Param        Dsp,
                   Hr_All_Organization_Units From_Hou,
                   Hr_All_Organization_Units From_Hou_Fils,
                   Hr_All_Organization_Units To_Hou,
                   Pa_Implementations_All    Pi,
                   Dka_Ibdsoc_General_Info   From_Digi,
                   Dka_Ibdsoc_General_Info   To_Digi
            WHERE  Pi.Set_Of_Books_Id = 1
            AND    From_Pp.Org_Id = Pi.Org_Id
            AND    Pe.Attribute3 IS NULL
            AND    Pe.Attribute1 IS NOT NULL
            AND    From_Pp.Project_Id = Pe.Project_Id
            AND    From_Pp.Project_Type = 'REFAC'
            AND    To_Pp.Project_Id = To_Number(Pe.Attribute1)
            AND    Dsp.Orig_Transaction_Type = Pe.Event_Type
            AND    Pcer.Project_Id = Pe.Project_Id
            AND    Pcer.Event_Num = Pe.Event_Num
            AND    Pcer.Org_Id = From_Pp.Org_Id
            AND    Pdr.Project_Id = Pcer.Project_Id
            AND    Pdr.Draft_Revenue_Num = Pcer.Draft_Revenue_Num
            AND    Pdr.Org_Id = Pcer.Org_Id
            AND    Trunc(Pdr.Gl_Date) <= Trunc(Vd_End_Date)
            AND    From_Hou_Fils.Organization_Id = Pe.Organization_Id
            AND    From_Hou.NAME = From_Hou_Fils.Attribute1
            AND    Ppc.Project_Id = To_Pp.Project_Id
            AND    Ppc.Class_Category = 'SOCIETE'
            AND    To_Hou.NAME = Ppc.Class_Code
            AND    From_Pt.Project_Id = From_Pp.Project_Id
            AND    From_Pt.Task_Id = (SELECT MIN(Pt.Task_Id)
                                      FROM   Pa_Tasks Pt
                                      WHERE  Pt.Project_Id = From_Pp.Project_Id
                                      AND    Pt.Chargeable_Flag = 'Y'
                                      AND    Pe.Completion_Date BETWEEN Pt.Start_Date
                                                                AND     Nvl(Pt.Completion_Date, Pe.Completion_Date))
            AND    To_Pt.Project_Id = To_Pp.Project_Id
            AND    To_Pt.Task_Id = (SELECT MIN(Pt.Task_Id)
                                    FROM   Pa_Tasks Pt
                                    WHERE  Pt.Project_Id = To_Pp.Project_Id
                                    AND    Pt.Chargeable_Flag = 'Y'
                                    AND    Pe.Completion_Date BETWEEN Pt.Start_Date
                                                              AND     Nvl(Pt.Completion_Date, Pe.Completion_Date))
            AND    From_Digi.Company_Code = Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(From_Pp.Project_Id,
                                                                                                     0,
                                                                                                     Trunc(SYSDATE),
                                                                                                     NULL), 4, 4)
            AND    To_Digi.Company_Code = Substr(Dka_Ibdsoc_Tools_Pkg.Get_Proj_Acct_Area_Company_f(To_Pp.Project_Id,
                                                                                                   0,
                                                                                                   Trunc(SYSDATE),
                                                                                                   NULL), 4, 4);*/ -- YWA 11i

        INSERT INTO Dka_Controle_Refac
            SELECT 'EXPENDITURE' Transaction_Source,
              From_Hou.Organization_Id From_Org_Id,
              From_Hou.NAME From_Org_Name,
              SUBSTR(From_Hou.NAME, 4, 4) From_Org_Name_Project,
              To_Hou.Organization_Id To_Org_Id,
              To_Hou.NAME To_Org_Name,
              SUBSTR(To_Hou.NAME, 4, 4) To_Org_Name_Project,
              From_Pp.Project_Id From_Project_Id,
              From_Pt.Task_Id From_Task_Id,
              To_Pp.Project_Id To_Project_Id,
              To_Pt.Task_Id To_Task_Id,
              SUBSTR(From_Hou.NAME, 1, 3) From_Acct_Center ,
              SUBSTR(To_Hou.NAME, 1, 3) To_Acct_Center,
              NVL(To_Hou.Attribute4, 'Y') Create_Ap_Data_Flag,
              NVL(From_Hou.Attribute4, 'Y') Create_Ar_Data_Flag,
              Pei.Expenditure_Item_Id Expenditure_Item_Id,
              NULL Event_Id,
              Pec.Expenditure_Comment Description,
              Pcdl.Cr_Code_Combination_Id Pa_Cr_Ccid,
              Pcdl.Dr_Code_Combination_Id Pa_Dr_Ccid,
              Pei.Quantity Quantity,
              Pei.Expenditure_Item_Date Orig_Transaction_Date,
              Pcdl.Gl_Date Gl_Date,
              Pei.Expenditure_Type Orig_Transaction_Type,
              Dsp.Ar_Event_Type Ar_Event_Type,
              Dsp.Ap_Expenditure_Type Ap_Expenditure_Type,
              Pei.Raw_Cost Amount
            FROM PA_EXPENDITURE_ITEMS_ALL Pei,
              Pa_Cost_Distribution_Lines_All Pcdl,
              Pa_Expenditure_Comments Pec,
              Pa_Projects_All From_Pp,
              Pa_Tasks From_Pt,
              Pa_Projects_All To_Pp,
              Pa_Project_Classes Ppc,
              Pa_Tasks To_Pt,
              Dka_Sarrefac_Param Dsp,
              Hr_All_Organization_Units From_Hou,
              Hr_All_Organization_Units From_Hou_Fils,
              Hr_All_Organization_Units To_Hou
            WHERE pei.attribute3                IS NULL     -- Non traité
            AND pei.attribute1                  IS NOT NULL -- Avec un projet
            AND pei.attribute7                  IS NOT NULL -- Avec une tache
            AND pcdl.expenditure_item_id         = pei.expenditure_item_id
            AND pcdl.org_id                      = pei.org_id
            AND pcdl.transfer_status_code       IN ('A', 'V')
            AND Pei.System_Linkage_Function NOT IN ('VI', 'ER')
            AND TRUNC (pcdl.gl_date)            <= TRUNC (Vd_End_Date)
            AND to_pp.project_id              = TO_NUMBER (pei.attribute1)
            AND to_pt.task_id                 = TO_NUMBER (pei.attribute7)
            AND to_pt.project_id              = to_pp.project_id
            AND From_Pt.Task_Id               = Pei.Task_Id
            AND From_Pp.Project_Id            = From_Pt.Project_Id
            AND From_Pp.Org_Id                = Pei.Org_Id
            AND From_Pp.Project_Type          = 'REFAC'
            AND Ppc.Project_Id                = To_Pp.Project_Id
            AND Ppc.Class_Category            = 'AFFAIRE'
            AND from_hou_fils.organization_id = pei.override_to_organization_id
            AND to_pp.org_id                  = To_Hou.organization_id
            AND from_hou.organization_id      = TO_NUMBER (pei.attribute2)
            AND Pec.Expenditure_Item_Id(+)    = Pei.Expenditure_Item_Id
            AND Dsp.Orig_Transaction_Type     = Pei.Expenditure_Type
            UNION ALL
            SELECT 'EXPENDITURE' Transaction_Source,
              From_Hou.Organization_Id From_Org_Id,
              From_Hou.NAME From_Org_Name,
              SUBSTR(From_Hou.NAME, 4, 4) From_Org_Name_Project,
              To_Hou.Organization_Id To_Org_Id,
              To_Hou.NAME To_Org_Name,
              SUBSTR(To_Hou.NAME, 4, 4) To_Org_Name_Project,
              From_Pp.Project_Id From_Project_Id,
              From_Pt.Task_Id From_Task_Id,
              To_Pp.Project_Id To_Project_Id,
              To_Pt.Task_Id To_Task_Id,
              SUBSTR(From_Hou.NAME, 1, 3) From_Acct_Center ,
              SUBSTR(To_Hou.NAME, 1, 3) To_Acct_Center,
              NVL(To_Hou.Attribute4, 'Y') Create_Ap_Data_Flag,
              NVL(From_Hou.Attribute4, 'Y') Create_Ar_Data_Flag,
              Pei.Expenditure_Item_Id Expenditure_Item_Id,
              NULL Event_Id,
              Pec.Expenditure_Comment Description,
              Pcdl.Cr_Code_Combination_Id Pa_Cr_Ccid,
              Pcdl.Dr_Code_Combination_Id Pa_Dr_Ccid,
              Pei.Quantity Quantity,
              Pei.Expenditure_Item_Date Orig_Transaction_Date,
              Pcdl.Gl_Date Gl_Date,
              Pei.Expenditure_Type Orig_Transaction_Type,
              Dsp.Ar_Event_Type Ar_Event_Type,
              Dsp.Ap_Expenditure_Type Ap_Expenditure_Type,
              Pei.Raw_Cost Amount
            FROM PA_EXPENDITURE_ITEMS_ALL Pei,
              Pa_Cost_Distribution_Lines_All Pcdl,
              Pa_Expenditure_Comments Pec,
              Pa_Projects_All From_Pp,
              Pa_Tasks From_Pt,
              Pa_Projects_All To_Pp,
              Pa_Project_Classes Ppc,
              Pa_Tasks To_Pt,
              Dka_Sarrefac_Param Dsp,
              Hr_All_Organization_Units From_Hou,
              Hr_All_Organization_Units From_Hou_Fils,
              Hr_All_Organization_Units To_Hou,
              AP_INVOICE_DISTRIBUTIONS_ALL Aid
            WHERE pei.attribute3                IS NULL     -- Non traité
            AND pei.attribute1                  IS NOT NULL -- Avec un projet
            AND pei.attribute7                  IS NOT NULL -- Avec une tache
            AND pcdl.expenditure_item_id         = pei.expenditure_item_id
            AND pcdl.org_id                      = pei.org_id
            AND pcdl.transfer_status_code       IN ('A', 'V')
            AND Pei.System_Linkage_Function NOT IN ('VI', 'ER')
            AND TRUNC (pcdl.gl_date) <= TRUNC (Vd_End_Date)
            AND to_pp.project_id              = TO_NUMBER (Aid.attribute1)
            AND to_pt.task_id                 = TO_NUMBER (Aid.attribute7)
            AND to_pt.project_id              = to_pp.project_id
            AND From_Pt.Task_Id               = Pei.Task_Id
            AND From_Pp.Project_Id            = From_Pt.Project_Id
            AND From_Pp.Org_Id                = Pei.Org_Id
            AND From_Pp.Project_Type          = 'REFAC'
            AND Ppc.Project_Id                = To_Pp.Project_Id
            AND Ppc.Class_Category            = 'AFFAIRE'
            AND from_hou_fils.organization_id = pei.override_to_organization_id
            AND to_pp.org_id                  = To_Hou.organization_id
            AND from_hou.organization_id      = TO_NUMBER (pei.attribute2)
            AND Pec.Expenditure_Item_Id(+)    = Pei.Expenditure_Item_Id
            AND Dsp.Orig_Transaction_Type     = Pei.Expenditure_Type
            AND Aid.invoice_distribution_id   = Pei.document_distribution_id
            UNION ALL
            SELECT 'EVENT' Transaction_Source,
              From_Hou.Organization_Id From_Org_Id,
              From_Hou.NAME From_Org_Name,
              SUBSTR(From_Hou.NAME, 4, 4) From_Org_Name_Project,
              To_Hou.Organization_Id To_Org_Id,
              To_Hou.NAME To_Org_Name,
              SUBSTR(To_Hou.NAME, 4, 4) To_Org_Name_Project,
              From_Pp.Project_Id From_Project_Id,
              From_Pt.Task_Id From_Task_Id,
              To_Pp.Project_Id To_Project_Id,
              To_Pt.Task_Id To_Task_Id,
              SUBSTR(From_Hou.NAME, 1, 3) From_Acct_Center,
              SUBSTR(To_Hou.NAME, 1, 3) To_Acct_Center,
              NVL(From_Hou.Attribute4, 'Y') Create_Ap_Data_Flag,
              NVL(To_Hou.Attribute4, 'Y') Create_Ar_Data_Flag,
              NULL Expenditure_Item_Id,
              Pe.Event_Id Event_Id,
              Pe.Description Description,
              Pdr.Unearned_Code_Combination_Id Pa_Cr_Ccid,
              Pcer.Code_Combination_Id Pa_Dr_Ccid,
              Pe.Revenue_Amount Quantity,
              Pe.Completion_Date Orig_Transaction_Date,
              Pdr.Gl_Date Gl_Date,
              Pe.Event_Type Orig_Transaction_Type,
              Dsp.Ar_Event_Type Ar_Event_Type,
              Dsp.Ap_Expenditure_Type Ap_Expenditure_Type,
              Pe.Revenue_Amount Amount
            FROM Pa_Events Pe,
              Pa_Cust_Event_Rdl_All Pcer,
              Pa_Draft_Revenues_All Pdr,
              Pa_Projects_All From_Pp,
              Pa_Tasks From_Pt,
              Pa_Projects_All To_Pp,
              Pa_Project_Classes Ppc,
              Pa_Tasks To_Pt,
              Dka_Sarrefac_Param Dsp,
              Hr_All_Organization_Units From_Hou,
              Hr_All_Organization_Units From_Hou_Fils,
              Hr_All_Organization_Units To_Hou,
              Pa_Implementations_All Pi,
              gl_ledgers gl
            WHERE pi.set_of_books_id      = gl.ledger_id
            AND from_pp.org_id            = pi.org_id
            AND pe.attribute3            IS NULL     -- Non traité
            AND pe.attribute1            IS NOT NULL -- Avec un projet
            AND pe.attribute7            IS NOT NULL -- Avec une tache
            AND from_pp.project_id        = pe.project_id
            AND from_pp.project_type      = 'REFAC'
            AND to_pp.project_id          = TO_NUMBER (pe.attribute1)
            AND dsp.orig_transaction_type = pe.event_type
            AND pcer.project_id           = pe.project_id
            AND pcer.event_num            = pe.event_num
            AND pcer.org_id               = from_pp.org_id
            AND pdr.project_id            = pcer.project_id
            AND pdr.draft_revenue_num     = pcer.draft_revenue_num
            AND pdr.org_id                = pcer.org_id
            AND    Trunc(Pdr.Gl_Date) <= Trunc(Vd_End_Date)
            AND from_hou.organization_id      = from_pp.org_id
            AND from_hou_fils.organization_id = pe.organization_id
            AND to_hou.organization_id        = to_pp.org_id
            AND from_pt.project_id            = from_pp.project_id
            AND from_pt.task_id               =
              (SELECT MIN (pt.task_id)
              FROM pa_tasks pt
              WHERE pt.project_id    = from_pp.project_id
              AND pt.chargeable_flag = 'Y'
              AND pe.completion_date BETWEEN pt.start_date AND NVL (pt.completion_date, pe.completion_date)
              )
            AND to_pt.project_id   = to_pp.project_id
            AND to_pt.task_id      = TO_NUMBER (pe.attribute7)
            AND Ppc.Project_Id     = To_Pp.Project_Id
            AND Ppc.Class_Category = 'AFFAIRE';  --YWA R12


        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 3 : Détermination des sites fournisseurs et clients manquants');
        Dka_Tools_Pkg.Put_Outdebug_Message('    -------------------------------------------------------------------');

        ----------------------------------------------------
        -- Détermination des sites fournisseurs manquants --
        ----------------------------------------------------
        OPEN Cur_Four;
        LOOP
            FETCH Cur_Four INTO Rec_Four;
            EXIT WHEN Cur_Four%NOTFOUND;

            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Partenaire', 11) ||
                                                   Rpad('Nom Fournisseur', 51) ||
                                                   Rpad('Code Fournisseur', 17) ||
                                                   Rpad('Site manquant pour Cdg', 23) ||
                                                   Rpad('Transaction source', 19) ||
                                                   Rpad('Nombre de lignes', 17) ||
                                                   Rpad('Montant', 15));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 10, '-') || ' ' ||
                                                   Rpad('-', 50, '-') || ' ' ||
                                                   Rpad('-', 16, '-') || ' ' ||
                                                   Rpad('-', 22, '-') || ' ' ||
                                                   Rpad('-', 18, '-') || ' ' ||
                                                   Rpad('-', 16, '-') || ' ' ||
                                                   Rpad('-', 15, '-'));

            END IF;

            Dka_Tools_Pkg.Put_Outdebug_Message(Rpad(Substr(Rec_Four.Partenaire, 1, 10), 10) || ' ' ||
                                               Rpad(Substr(Rec_Four.Nom_Fournisseur, 1, 50), 50) || ' ' ||
                                               Rpad(Substr(Rec_Four.Code_Fournisseur, 1, 16), 16) || ' ' ||
                                               Rpad(Substr(Rec_Four.Site_Manquant, 1, 22), 22) || ' ' ||
                                               Rpad(Substr(Rec_Four.Transaction_Source, 1, 18), 18) || ' ' ||
                                               Lpad(To_Char(Rec_Four.Nb_De_Lignes, '999G999G999'), 16) || ' ' ||
                                               Lpad(To_Char(Rec_Four.Nb_De_Lignes, '999G999G999D99'), 15));

            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 3';
        END LOOP;
        CLOSE Cur_Four;

        COMMIT;

        -----------------------------------------------
        -- Détermination des sites clients manquants --
        -----------------------------------------------
        Vn_Nb_Enreg := 0;
        OPEN Cur_Client;
        LOOP
            FETCH Cur_Client INTO Rec_Client;
            EXIT WHEN Cur_Client%NOTFOUND;

            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Partenaire', 11) ||
                                                   Rpad('Code Client', 17) ||
                                                   Rpad('Site manquant pour Cdg', 23) ||
                                                   Rpad('Transaction source', 19) ||
                                                   Rpad('Nombre de lignes', 17) ||
                                                   Rpad('Montant', 15));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 10, '-') || ' ' ||
                                                   Rpad('-', 16, '-') || ' ' ||
                                                   Rpad('-', 22, '-') || ' ' ||
                                                   Rpad('-', 18, '-') || ' ' ||
                                                   Rpad('-', 16, '-') || ' ' ||
                                                   Rpad('-', 15, '-'));

            END IF;

            Dka_Tools_Pkg.Put_Outdebug_Message(Rpad(Substr(Rec_Client.Partenaire, 1, 10), 10) || ' ' ||
                                               Rpad(Substr(Rec_Client.Code_Client, 1, 16), 16) || ' ' ||
                                               Rpad(Substr(Rec_Client.Site_Manquant, 1, 22), 22) || ' ' ||
                                               Rpad(Substr(Rec_Client.Transaction_Source, 1, 18), 18) || ' ' ||
                                               Lpad(To_Char(Rec_Client.Nb_De_Lignes, '999G999G999'), 16) || ' ' ||
                                               Lpad(To_Char(Rec_Client.Nb_De_Lignes, '999G999G999D99'), 15));

            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 3';
        END LOOP;
        CLOSE Cur_Client;

    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_3 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_3;


    -- -----------------------------------------------------------------------------
    -- Nom              : Step_4
    -- Description      : Liste des lignes AP non transférées dans PA
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --                    Pv_Period_Name     Entrée Nom de la période
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_4(Pv_Errbuf         OUT VARCHAR2,
                     Pn_Retcode        OUT NUMBER,
                     Pv_Period_Name IN     VARCHAR2) IS

        CURSOR Cur_Lignes IS
            SELECT Aid.Period_Name              Period_Name,
                   Aid.Invoice_Id               Invoice_Id,
                   Ai.Invoice_Num               Invoice_Num,
                   Aid.Distribution_Line_Number Line_Number,
                   Ai.Description               Description,
                   Aid.Pa_Addition_Flag         Flag,
                   Aid.Amount                   Montant,
                   Aid.Project_Id               Id_Projet_Refac,
                   Aid.Pa_Quantity              Quantite,
                   Pp.Segment1                  Projet_Refac,
                   Pp.Project_Type              Type_Projet,
                   Aid.Attribute1               Id_Projet_Init,
                   P2.Segment1                  Projet_Init,
                   P2.Project_Type              Type_Projet_Init,
                   Pc.Class_Code                Societe
            FROM   Ap_Invoice_Distributions_All Aid,
                   Ap_Invoices_All              Ai,
                   Pa_Projects_All              Pp,
                   Pa_Project_Classes           Pc,
                   Pa_Projects_All              P2
            WHERE  1 = 1
            AND    Ai.Invoice_Id = Aid.Invoice_Id
            AND    Aid.Project_Id = Pp.Project_Id
            AND    To_Char(Aid.Attribute1) = To_Char(P2.Project_Id)
            AND    P2.Project_Id = Pc.Project_Id
             AND    Pc.Class_Category = 'AFFAIRE'  --  YWA
            AND    Aid.Project_Id IS NOT NULL
            AND    Aid.Period_Name = Pv_Period_Name
            AND    Aid.Pa_Addition_Flag = 'Z'
            AND    Aid.Attribute1 IS NOT NULL
            AND    Pp.Project_Type = 'REFAC'
            AND    Aid.Amount != 0
            AND    (Aid.Invoice_Id, Aid.Attribute1) NOT IN (SELECT DISTINCT Aid2.Invoice_Id, --YWA REVOIR ATTRIBUTE7 TACHE OU ATTRIBUTE1 projet (ok)
                                                                   Aid2.Attribute1
                                                            FROM   Ap_Invoice_Distributions_All Aid2,
                                                                   Pa_Projects_All              Ppa2
                                                            WHERE  Aid2.Attribute1 = To_Char(Ppa2.Project_Id)
                                                            AND    Aid2.Pa_Addition_Flag = 'Z'
                                                            AND    Aid2.Period_Name = Pv_Period_Name
                                                            AND    Aid2.Attribute1 IS NOT NULL
                                                            GROUP  BY Aid2.Invoice_Id,
                                                                      Aid2.Attribute1
                                                            HAVING SUM(Amount) = 0)-- YWA
            ORDER  BY 2, 5;

        Rec_Lignes  Cur_Lignes%ROWTYPE;
        Vn_Nb_Enreg NUMBER := 0;

    BEGIN
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 4 : Liste des lignes AP non transférées dans PA');
        Dka_Tools_Pkg.Put_Outdebug_Message('    -----------------------------------------------------');

        OPEN Cur_Lignes;
        LOOP
            FETCH Cur_Lignes INTO Rec_Lignes;
            EXIT WHEN Cur_Lignes%NOTFOUND;
            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Periode', 8) ||
                                                   Rpad('Invoice_Id', 11) ||
                                                   Rpad('Invoice_Num', 13) ||
                                                   Rpad('Ligne', 6) ||
                                                   Rpad('Description', 21) ||
                                                   Rpad('Flag', 5) ||
                                                   Rpad('Montant', 16) ||
                                                   Rpad('Id_Projet_Refac', 16) ||
                                                   Rpad('Quantite', 16) ||
                                                   Rpad('Projet_Refac', 13) ||
                                                   Rpad('Type_Projet_Refac', 18) ||
                                                   Rpad('Id_Projet_Init', 16) ||
                                                   Rpad('Projet_Init', 13) ||
                                                   Rpad('Type_Projet_Init', 18) ||
                                                   Rpad('Societe', 7));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 7, '-') || ' ' ||
                                                   Rpad('-', 10, '-') || ' ' ||
                                                   Rpad('-', 12, '-') || ' ' ||
                                                   Rpad('-', 5, '-') || ' ' ||
                                                   Rpad('-', 20, '-') || ' ' ||
                                                   Rpad('-', 4, '-') || ' ' ||
                                                   Rpad('-', 15,'-') || ' ' ||
                                                   Rpad('-', 15, '-') || ' ' ||
                                                   Rpad('-', 15, '-') || ' ' ||
                                                   Rpad('-', 12, '-') || ' ' ||
                                                   Rpad('-', 17, '-') || ' ' ||
                                                   Rpad('-', 15, '-') || ' ' ||
                                                   Rpad('-', 12, '-') || ' ' ||
                                                   Rpad('-', 17, '-') || ' ' ||
                                                   Rpad('-', 7, '-'));

            END IF;

            Dka_Tools_Pkg.Put_Outdebug_Message(Rpad(Substr(Rec_Lignes.Period_Name, 1, 7), 7) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Invoice_Id), 10) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Invoice_Num, 1, 12), 12) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Line_Number), 5) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Description, 1, 20), 20) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Flag, 1, 4), 4) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Montant, '999G999G999D99'), 15) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Id_Projet_Refac), 15) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Quantite), 15) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Projet_Refac, 1, 12), 12) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Type_Projet, 1, 17), 17) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Id_Projet_Init), 15) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Projet_Init, 1, 12), 12) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Type_Projet_Init, 1, 17), 17) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Societe, 1, 7), 7));

            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 4';
        END LOOP;
        CLOSE Cur_Lignes;

    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_4 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_4;

    -- -----------------------------------------------------------------------------
    -- Nom              : Step_5
    -- Description      : Liste des sociétés segmentées sans territorialité
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_5(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER) IS

        CURSOR Cur_Lignes IS
            /*SELECT Digi.Company_Code Code_Societe,
                   Digi.Company_Name Nom_Societe,
                   To_Char(Digi.Creation_Date, 'DD/MM/YYYY') Date_Creation
            FROM   Dka_Ibdsoc_General_Info Digi
            WHERE  Digi.Segmented_Company_Flag = 'Y'
            AND    NOT EXISTS (SELECT 'x'
                               FROM   Dka_Ibdsoc_Territorialities Dit
                               WHERE  Dit.Company_Code = Digi.Company_Code)
            ORDER  BY Digi.Company_Code;*/
            SELECT val.FLEX_VALUE Code_Societe,
                  val.description Nom_Societe,
                  val.Creation_Date Date_Creation
            FROM fnd_flex_value_sets sets,
                  fnd_flex_values_vl val,
                  gl_ledgers gl
            WHERE sets.flex_value_set_id = val.flex_value_set_id
            AND gl.short_name            = val.flex_value
            AND ledger_category_code     = 'PRIMARY'
            AND val.enabled_flag         = 'Y'
            AND SYSDATE BETWEEN NVL(val.start_date_active, SYSDATE) AND NVL(val.end_date_active, SYSDATE)
            AND val.summary_flag   = 'N'
            AND val.VALUE_CATEGORY = 'DAOPCCF_STE'
            AND val.attribute2
              ||val.FLEX_VALUE NOT IN
              (SELECT name
              FROM HR_OPERATING_UNITS
              WHERE TRUNC(SYSDATE) BETWEEN NVL(DATE_FROM, TRUNC(SYSDATE)) AND NVL(DATE_TO, TRUNC(SYSDATE))
              AND gl.ledger_id = set_of_books_id
              )
            ORDER  BY val.FLEX_VALUE  ;---YWA R12

        Rec_Lignes Cur_Lignes%ROWTYPE;

        Vn_Nb_Enreg NUMBER := 0;

    BEGIN

        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 5 : Liste des sociétés segmentées sans territorialité');
        Dka_Tools_Pkg.Put_Outdebug_Message('    -----------------------------------------------------------');

        OPEN Cur_Lignes;
        LOOP
            FETCH Cur_Lignes INTO Rec_Lignes;
            EXIT WHEN Cur_Lignes%NOTFOUND;
            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Code Societe', 13) ||
                                                   Rpad('Libelle Societe', 51) ||
                                                   Rpad('Date Creation', 13));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 12, '-') || ' ' ||
                                                   Rpad('-', 50, '-') || ' ' ||
                                                   Rpad('-', 13, '-'));
            END IF;
            Dka_Tools_Pkg.Put_Outdebug_Message(Rpad(Substr(Rec_Lignes.Code_Societe, 1, 12), 12) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Nom_Societe, 1, 50), 50) || ' ' ||
                                               Rpad(Rec_Lignes.Date_Creation, 13));
            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 5';
        END LOOP;
        CLOSE Cur_Lignes;

    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_5 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_5;

    -- -----------------------------------------------------------------------------
    -- Nom              : Step_6
    -- Description      : Liste des rejets de l'Open Interface
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --                    Pv_Period_Name     Entrée Nom de la période
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_6(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER) IS

        CURSOR Cur_Lignes IS
            SELECT v.Ar_Reference Reference_Facture_Refac,
                   v.Ar_Trx_Number No_Facture_Ap_De_Refac,
                   Hou_Soc_Ap.NAME Soc_Facture_Ap_De_Refac,
                   v.Ap_Invoice_Id Invoice_Id_Open_Interface_Ap,
                   (Pv.Segment1 || '-' || Pv.Vendor_Name) Fournisseur,
                   To_Char(v.Ap_Invoice_Date, 'DD/MM/YYYY') Date_Facture_Ap,
                   To_Char(v.Ap_Invoice_Gl_Date, 'DD/MM/YYYY') Date_Gl_Facture_Ap,
                   v.Ap_Invoice_Amount Montant_Facture_Ap,
                   v.Ap_Invoice_Line_Id Invoice_Line_Id,
                   v.Line_Number No_Ligne,
                   v.Line_Amount Montant_Ligne,
                   To_Char(v.Ap_Inv_Line_Gl_Date, 'DD/MM/YYYY') Date_Gl_Ligne,
                   To_Char(v.Ap_Inv_Line_Exp_Date, 'DD/MM/YYYY') Date_Depense_Ligne,
                   v.Ap_Expenditure_Type Type_De_Depense_Ligne,
                   v.Ap_Project_Number Projet_Ligne,
                   v.Ap_Project_Name Lib_Projte_Ligne,
                   v.Ap_Project_Status_Code Statut_Projet,
                   To_Char(v.Ap_Project_Date_Debut, 'DD/MM/YYYY') Date_Debut_Projet,
                   To_Char(v.Ap_Project_Date_Cloture, 'DD/MM/YYYY') Date_Cloture_Projet,
                   To_Char(v.Ap_Project_Date_Fermeture, 'DD/MM/YYYY') Date_Fermeture_Projet,
                   v.Ap_Reject_Code Motif_De_Rejet,
                   v.Orig_Txn_Number No_Piece_Origine,
                   v.Orig_Txn_Line_Number No_Ligne_Origine,
                   v.Orig_Application Module_Origine,
                   v.Orig_User_Name User_Origine
            FROM   (SELECT Dsaai.Ar_Reference Ar_Reference,
                           Dsaai.Ar_Trx_Number,
                           Dsaai.Ap_Org_Id Ap_Org_Id,
                           Dsaai.Ap_Invoice_Id,
                           Dsaai.Ap_Vendor_Id,
                           Dsaai.Ap_Invoice_Date,
                           Dsaai.Ap_Invoice_Gl_Date,
                           Dsaai.Ap_Invoice_Amount,
                           Dsaai.Ap_Invoice_Line_Number Line_Number,
                           Dsaai.Ap_Invoice_Line_Id,
                           Dsaai.Ap_Inv_Line_Gl_Date,
                           Dsaai.Ap_Inv_Line_Exp_Date,
                           Dsaai.Ap_Expenditure_Type,
                           Dsaai.Ap_Project_Number,
                           Dsaai.Ap_Project_Name,
                           Dsaai.Ap_Project_Status_Code,
                           Dsaai.Ap_Project_Date_Debut,
                           Dsaai.Ap_Project_Date_Cloture,
                           Dsaai.Ap_Project_Date_Fermeture,
                           Dsaai.Ap_Reject_Code,
                           Dsaai.Ar_Customer_Trx_Id Customer_Trx_Id,
                           Dsaai.Ar_Customer_Trx_Line_Id Customer_Trx_Line_Id,
                           Dsaai.Ar_Rctlgd_Attribute14,
                           To_Number(Dsaai.Ar_Rctlgd_Attribute15),
                           275 Orig_Application_Id,
                           'PA' Orig_Application,
                           Pe.Expenditure_Group Orig_Txn_Number,
                           To_Number(NULL) Orig_Txn_Line_Number,
                           To_Number(NULL) Orig_Sequence_Number,
                           Pei.Expenditure_Item_Date Orig_Line_Date,
                           Dsaai.Ar_Line_Amount Line_Amount,
                           Nvl(Pei.Attribute9, Fu.User_Name) Orig_User_Name
                    FROM   (SELECT Rct.Interface_Header_Attribute1 Ar_Reference,
                                   Rct.Trx_Number Ar_Trx_Number,
                                   Rct.Customer_Trx_Id Ar_Customer_Trx_Id,
                                   Rctl.Customer_Trx_Line_Id Ar_Customer_Trx_Line_Id,
                                   Rctlgd.Cust_Trx_Line_Gl_Dist_Id Ar_Cust_Trx_Line_Gl_Dist_Id,
                                   Aid.Line_Number Ap_Invoice_Line_Number,
                                   Rctl.Extended_Amount Ar_Line_Amount,
                                   Rctlgd.Code_Combination_Id Ar_Code_Combination_Id,
                                   Rctlgd_Gcc.Segment3 Ar_Acct_Segment3,
                                   Rctlgd.Attribute14 Ar_Rctlgd_Attribute14,
                                   Rctlgd.Attribute15 Ar_Rctlgd_Attribute15,
                                   Hou_Cust.Organization_Id Ap_Org_Id,
                                   Ai.Invoice_Id Ap_Invoice_Id,
                                   Ai.Vendor_Id Ap_Vendor_Id,
                                   Ai.Invoice_Date Ap_Invoice_Date,
                                   Ai.Gl_Date Ap_Invoice_Gl_Date,
                                   Ai.Invoice_Amount Ap_Invoice_Amount,
                                   Aid.Line_Number Ap_Distribution_Line_Number,
                                   Aid.Invoice_Line_Id Ap_Invoice_Line_Id,
                                   Aid.Accounting_Date Ap_Inv_Line_Gl_Date,
                                   Aid.Expenditure_Item_Date Ap_Inv_Line_Exp_Date,
                                   Aid.Expenditure_Type Ap_Expenditure_Type,
                                   Pp.Project_Id Ap_Project_Id,
                                   Pp.Segment1 Ap_Project_Number,
                                   Pp.Description Ap_Project_Name,
                                   Pp.Project_Status_Code Ap_Project_Status_Code,
                                   Pp.Start_Date Ap_Project_Date_Debut,
                                   Fnd_Date.Canonical_To_Date(Pp.Attribute8) Ap_Project_Date_Cloture,
                                   Nvl(Pp.Completion_Date, Fnd_Date.Canonical_To_Date(Pp.Attribute7)) Ap_Project_Date_Fermeture,
                                   (SELECT Alc.Displayed_Field
                                    FROM   Ap_Lookup_Codes Alc
                                    WHERE  Alc.Lookup_Type(+) = 'REJECT CODE'
                                    AND    Alc.Lookup_Code(+) = Nvl(Air_Line.Reject_Lookup_Code, Air_Inv.Reject_Lookup_Code)) Ap_Reject_Code
                            FROM   Ra_Customer_Trx_All          Rct,
                                   Ra_Customer_Trx_Lines_All    Rctl,
                                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgd,
                                   Gl_Code_Combinations         Rctlgd_Gcc,
                                   Ra_Customers                 Rc,
                                   Hr_All_Organization_Units    Hou_Cust,
                                   Po_Vendors                   Pv,
                                   Hr_All_Organization_Units    Hou_Vend,
                                   Ap_Invoices_Interface        Ai,
                                   Ap_Invoice_Lines_Interface   Aid,
                                   Ap_Interface_Rejections      Air_Line,
                                   Ap_Interface_Rejections      Air_Inv,
                                   Pa_Projects_All              Pp
                            WHERE  Rct.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctl.Line_Type = 'LINE'
                            -- Récupération des lignes de facture AR de Refac
                            AND    Rctlgd.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctlgd.Customer_Trx_Line_Id = Rctl.Customer_Trx_Line_Id
                            AND    Rctlgd.Account_Set_Flag = 'N'
                            AND    Rctlgd.Account_Class = 'REV'
                            AND    Rctlgd_Gcc.Code_Combination_Id = Rctlgd.Code_Combination_Id
                            -- Récupération de l'org_id de AP
                            AND    Rc.Customer_Id = Rct.Bill_To_Customer_Id
                            --AND    Hou_Cust.NAME = Rc.Attribute1 --YWA 11i
                            AND   Hou_Cust.organization_id = Rct.org_id  --YWA R12
                            -- Récupération du fournisseur
                           -- AND    Pv.Attribute2 = Hou_Vend.NAME --YWA 11i
                            AND   Ai.org_id= Hou_Vend.organization_id --YWA R12
                            AND    Ai.Vendor_Id = Pv.Vendor_Id
                            -- Récupération de la ligne de facture AP de Refac
                            AND    Ai.Invoice_Num = Rct.Trx_Number
                            AND    Aid.Invoice_Id = Ai.Invoice_Id
                            --AND aid.distribution_line_number = TO_NUMBER (rctlgd.attribute13)
                          --   AND    Aid.Attribute13 = Rctlgd.Attribute13 --YWA R12 a revoir
                            -- Récupération du projet
                            AND    Pp.Project_Id = Aid.Project_Id
                            AND    Ai.SOURCE = 'REFAC'
                            AND    Ai.Status = 'REJECTED'
                            AND    Air_Line.Parent_Id(+) = Aid.Invoice_Line_Id
                            AND    Air_Line.Parent_Table(+) = 'AP_INVOICE_LINES_INTERFACE'
                            AND    Air_Line.Reject_Lookup_Code(+) != 'ACCOUNT REQUIRED'
                            AND    Air_Inv.Parent_Id(+) = Aid.Invoice_Id
                            AND    Air_Inv.Parent_Table(+) = 'AP_INVOICES_INTERFACE') Dsaai,
                           Pa_Expenditure_Items_All Pei,
                           Pa_Expenditures_All Pe,
                           Fnd_User Fu
                    WHERE  Dsaai.Ar_Rctlgd_Attribute14 = 'EXPENDITURE'
                    -- Récupération de la ligne de dépense
                    AND    Pei.Expenditure_Item_Id = To_Number(Dsaai.Ar_Rctlgd_Attribute15)
                    -- Limitation aux lignes d'origine PA
                    AND    Pei.Attribute_Category = 'REFAC'
                    -- Récupération du lot
                    AND    Pe.Expenditure_Id = Pei.Expenditure_Id
                    AND    Fu.User_Id(+) = Pei.Created_By
                    UNION ALL
                    -- Lignes de type EXPENDITURE d'origine AP
                    SELECT Dsaai.Ar_Reference Ar_Reference,
                           Dsaai.Ar_Trx_Number,
                           Dsaai.Ap_Org_Id Ap_Org_Id,
                           Dsaai.Ap_Invoice_Id,
                           Dsaai.Ap_Vendor_Id,
                           Dsaai.Ap_Invoice_Date,
                           Dsaai.Ap_Invoice_Gl_Date,
                           Dsaai.Ap_Invoice_Amount,
                           Dsaai.Ap_Invoice_Line_Number Line_Number,
                           Dsaai.Ap_Invoice_Line_Id,
                           Dsaai.Ap_Inv_Line_Gl_Date,
                           Dsaai.Ap_Inv_Line_Exp_Date,
                           Dsaai.Ap_Expenditure_Type,
                           Dsaai.Ap_Project_Number,
                           Dsaai.Ap_Project_Name,
                           Dsaai.Ap_Project_Status_Code,
                           Dsaai.Ap_Project_Date_Debut,
                           Dsaai.Ap_Project_Date_Cloture,
                           Dsaai.Ap_Project_Date_Fermeture,
                           Dsaai.Ap_Reject_Code,
                           Dsaai.Ar_Customer_Trx_Id Customer_Trx_Id,
                           Dsaai.Ar_Customer_Trx_Line_Id Customer_Trx_Line_Id,
                           Dsaai.Ar_Rctlgd_Attribute14,
                           To_Number(Dsaai.Ar_Rctlgd_Attribute15),
                           200 Orig_Application_Id,
                           'AP' Orig_Application,
                           Orig_Ai.Invoice_Num Orig_Txn_Number,
                           Orig_Aid.Distribution_Line_Number Orig_Txn_Line_Number,
                           Orig_Ai.Doc_Sequence_Value Orig_Sequence_Number,
                           Orig_Ai.Invoice_Date Orig_Line_Date,
                           Dsaai.Ar_Line_Amount Line_Amount,
                           Nvl(Orig_Aid.Attribute9, Fu.User_Name) Orig_User_Name
                    FROM   (SELECT Rct.Interface_Header_Attribute1 Ar_Reference,
                                   Rct.Trx_Number Ar_Trx_Number,
                                   Rct.Customer_Trx_Id Ar_Customer_Trx_Id,
                                   Rctl.Customer_Trx_Line_Id Ar_Customer_Trx_Line_Id,
                                   Rctlgd.Cust_Trx_Line_Gl_Dist_Id Ar_Cust_Trx_Line_Gl_Dist_Id,
                                   Aid.Line_Number Ap_Invoice_Line_Number,
                                   Rctl.Extended_Amount Ar_Line_Amount,
                                   Rctlgd.Code_Combination_Id Ar_Code_Combination_Id,
                                   Rctlgd_Gcc.Segment3 Ar_Acct_Segment3,
                                   Rctlgd.Attribute14 Ar_Rctlgd_Attribute14,
                                   Rctlgd.Attribute15 Ar_Rctlgd_Attribute15,
                                   Hou_Cust.Organization_Id Ap_Org_Id,
                                   Ai.Invoice_Id Ap_Invoice_Id,
                                   Ai.Vendor_Id Ap_Vendor_Id,
                                   Ai.Invoice_Date Ap_Invoice_Date,
                                   Ai.Gl_Date Ap_Invoice_Gl_Date,
                                   Ai.Invoice_Amount Ap_Invoice_Amount,
                                   Aid.Line_Number Ap_Distribution_Line_Number,
                                   Aid.Invoice_Line_Id Ap_Invoice_Line_Id,
                                   Aid.Accounting_Date Ap_Inv_Line_Gl_Date,
                                   Aid.Expenditure_Item_Date Ap_Inv_Line_Exp_Date,
                                   Aid.Expenditure_Type Ap_Expenditure_Type,
                                   Pp.Project_Id Ap_Project_Id,
                                   Pp.Segment1 Ap_Project_Number,
                                   Pp.Description Ap_Project_Name,
                                   Pp.Project_Status_Code Ap_Project_Status_Code,
                                   Pp.Start_Date Ap_Project_Date_Debut,
                                   Fnd_Date.Canonical_To_Date(Pp.Attribute8) Ap_Project_Date_Cloture,
                                   Nvl(Pp.Completion_Date, Fnd_Date.Canonical_To_Date(Pp.Attribute7)) Ap_Project_Date_Fermeture,
                                   (SELECT Alc.Displayed_Field
                                    FROM   Ap_Lookup_Codes Alc
                                    WHERE  Alc.Lookup_Type(+) = 'REJECT CODE'
                                    AND    Alc.Lookup_Code(+) = Nvl(Air_Line.Reject_Lookup_Code, Air_Inv.Reject_Lookup_Code)) Ap_Reject_Code
                            FROM   Ra_Customer_Trx_All          Rct,
                                   Ra_Customer_Trx_Lines_All    Rctl,
                                   RA_CUST_TRX_LINE_GL_DIST_ALL Rctlgd,
                                   Gl_Code_Combinations         Rctlgd_Gcc,
                                   Ra_Customers                 Rc,
                                   Hr_All_Organization_Units    Hou_Cust,
                                   PO_VENDORS                   Pv,
                                   Hr_All_Organization_Units    Hou_Vend,
                                   Ap_Invoices_Interface        Ai,
                                   Ap_Invoice_Lines_Interface   Aid,
                                   Ap_Interface_Rejections      Air_Line,
                                   Ap_Interface_Rejections      Air_Inv,
                                   Pa_Projects_All              Pp
                            WHERE  Rct.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctl.Line_Type = 'LINE'
                            -- Récupération des lignes de facture AR de Refac
                            AND    Rctlgd.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctlgd.Customer_Trx_Line_Id = Rctl.Customer_Trx_Line_Id
                            AND    Rctlgd.Account_Set_Flag = 'N'
                            AND    Rctlgd.Account_Class = 'REV'
                            AND    Rctlgd_Gcc.Code_Combination_Id = Rctlgd.Code_Combination_Id
                            -- Récupération de l'org_id de Ar
                            AND    Rc.Customer_Id = Rct.Bill_To_Customer_Id
                             --AND    Hou_Cust.NAME = Rc.Attribute1 --YWA 11i
                            AND   Hou_Cust.organization_id = Rct.org_id  --YWA R12
                            -- Récupération du fournisseur
                           -- AND    Pv.Attribute2 = Hou_Vend.NAME --YWA 11i
                            AND   Ai.org_id= Hou_Vend.organization_id --YWA R12
                            AND    Ai.Vendor_Id = Pv.Vendor_Id
                            -- Récupération de la ligne de facture AP de Refac
                            AND    Ai.Invoice_Num = Rct.Trx_Number
                            AND    Aid.Invoice_Id = Ai.Invoice_Id
                            --  AND    Aid.Attribute13 = Rctlgd.Attribute13 --YWA R12
                            -- Récupération du projet
                            AND    Pp.Project_Id = Aid.Project_Id
                            AND    Ai.SOURCE = 'REFAC'
                            AND    Ai.Status = 'REJECTED'
                            AND    Air_Line.Parent_Id(+) = Aid.Invoice_Line_Id
                            AND    Air_Line.Parent_Table(+) = 'AP_INVOICE_LINES_INTERFACE'
                            AND    Air_Line.Reject_Lookup_Code(+) != 'ACCOUNT REQUIRED'
                            AND    Air_Inv.Parent_Id(+) = Aid.Invoice_Id
                            AND    Air_Inv.Parent_Table(+) = 'AP_INVOICES_INTERFACE') Dsaai,
                           Pa_Expenditure_Items_All Pei,
                           Pa_Cost_Distribution_Lines_All Pcdl,
                           Ap_Invoices_All Orig_Ai,
                           Ap_Invoice_Distributions_All Orig_Aid,
                           Fnd_User Fu
                    WHERE  Dsaai.Ar_Rctlgd_Attribute14 = 'EXPENDITURE'
                    -- Récupération de la ligne de dépense
                    AND    Pei.Expenditure_Item_Id = To_Number(Dsaai.Ar_Rctlgd_Attribute15)
                    -- Limitation aux lignes d'origine AP
                    AND    Pei.Attribute_Category = 'AP_REFAC'
                    AND    Pei.System_Linkage_Function IN ('VI', 'ER')
                    -- Récupération de la facture AP d'origine
                    AND    Pcdl.Expenditure_Item_Id = Pei.Expenditure_Item_Id
                    --AND    Orig_Ai.Invoice_Id = To_Number(Pcdl.System_Reference2)  --YWA R12
                    AND    Orig_Aid.Invoice_Id = Orig_Ai.Invoice_Id
                    --AND    Orig_Aid.Distribution_Line_Number = To_Number(Pcdl.System_Reference3) --YWA R12
                    AND    pei.document_distribution_id = orig_aid.invoice_distribution_id --YWA R12
                    AND    Fu.User_Id(+) = Orig_Aid.Created_By
                    UNION ALL
                    -- Lignes de type EXPENDITURE d'origine GL
                    SELECT Dsaai.Ar_Reference Ar_Reference,
                           Dsaai.Ar_Trx_Number,
                           Dsaai.Ap_Org_Id Ap_Org_Id,
                           Dsaai.Ap_Invoice_Id,
                           Dsaai.Ap_Vendor_Id,
                           Dsaai.Ap_Invoice_Date,
                           Dsaai.Ap_Invoice_Gl_Date,
                           Dsaai.Ap_Invoice_Amount,
                           Dsaai.Ap_Invoice_Line_Number Line_Number,
                           Dsaai.Ap_Invoice_Line_Id,
                           Dsaai.Ap_Inv_Line_Gl_Date,
                           Dsaai.Ap_Inv_Line_Exp_Date,
                           Dsaai.Ap_Expenditure_Type,
                           Dsaai.Ap_Project_Number,
                           Dsaai.Ap_Project_Name,
                           Dsaai.Ap_Project_Status_Code,
                           Dsaai.Ap_Project_Date_Debut,
                           Dsaai.Ap_Project_Date_Cloture,
                           Dsaai.Ap_Project_Date_Fermeture,
                           Dsaai.Ap_Reject_Code,
                           Dsaai.Ar_Customer_Trx_Id Customer_Trx_Id,
                           Dsaai.Ar_Customer_Trx_Line_Id Customer_Trx_Line_Id,
                           Dsaai.Ar_Rctlgd_Attribute14,
                           To_Number(Dsaai.Ar_Rctlgd_Attribute15),
                           101 Orig_Application_Id,
                           'GL' Orig_Application,
                           Gjh.NAME Orig_Txn_Number,
                           Gjl.Je_Line_Num Orig_Txn_Line_Number,
                           Gjh.Doc_Sequence_Value Orig_Sequence_Number,
                           Gjl.Effective_Date Orig_Line_Date,
                           Dsaai.Ar_Line_Amount Line_Amount,
                           Nvl(Gjl.Attribute9, Fu.User_Name) Orig_User_Name
                    FROM   (SELECT Rct.Interface_Header_Attribute1 Ar_Reference,
                                   Rct.Trx_Number Ar_Trx_Number,
                                   Rct.Customer_Trx_Id Ar_Customer_Trx_Id,
                                   Rctl.Customer_Trx_Line_Id Ar_Customer_Trx_Line_Id,
                                   Rctlgd.Cust_Trx_Line_Gl_Dist_Id Ar_Cust_Trx_Line_Gl_Dist_Id,
                                   Aid.Line_Number Ap_Invoice_Line_Number,
                                   Rctl.Extended_Amount Ar_Line_Amount,
                                   Rctlgd.Code_Combination_Id Ar_Code_Combination_Id,
                                   Rctlgd_Gcc.Segment3 Ar_Acct_Segment3,
                                   Rctlgd.Attribute14 Ar_Rctlgd_Attribute14,
                                   Rctlgd.Attribute15 Ar_Rctlgd_Attribute15,
                                   Hou_Cust.Organization_Id Ap_Org_Id,
                                   Ai.Invoice_Id Ap_Invoice_Id,
                                   Ai.Vendor_Id Ap_Vendor_Id,
                                   Ai.Invoice_Date Ap_Invoice_Date,
                                   Ai.Gl_Date Ap_Invoice_Gl_Date,
                                   Ai.Invoice_Amount Ap_Invoice_Amount,
                                   Aid.Line_Number Ap_Distribution_Line_Number,
                                   Aid.Invoice_Line_Id Ap_Invoice_Line_Id,
                                   Aid.Accounting_Date Ap_Inv_Line_Gl_Date,
                                   Aid.Expenditure_Item_Date Ap_Inv_Line_Exp_Date,
                                   Aid.Expenditure_Type Ap_Expenditure_Type,
                                   Pp.Project_Id Ap_Project_Id,
                                   Pp.Segment1 Ap_Project_Number,
                                   Pp.Description Ap_Project_Name,
                                   Pp.Project_Status_Code Ap_Project_Status_Code,
                                   Pp.Start_Date Ap_Project_Date_Debut,
                                   Fnd_Date.Canonical_To_Date(Pp.Attribute8) Ap_Project_Date_Cloture,
                                   Nvl(Pp.Completion_Date, Fnd_Date.Canonical_To_Date(Pp.Attribute7)) Ap_Project_Date_Fermeture,
                                   (SELECT Alc.Displayed_Field
                                    FROM   Ap_Lookup_Codes Alc
                                    WHERE  Alc.Lookup_Type(+) = 'REJECT CODE'
                                    AND    Alc.Lookup_Code(+) = Nvl(Air_Line.Reject_Lookup_Code, Air_Inv.Reject_Lookup_Code)) Ap_Reject_Code
                            FROM   Ra_Customer_Trx_All          Rct,
                                   Ra_Customer_Trx_Lines_All    Rctl,
                                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgd,
                                   Gl_Code_Combinations         Rctlgd_Gcc,
                                   Ra_Customers                 Rc,
                                   Hr_All_Organization_Units    Hou_Cust,
                                   Po_Vendors                   Pv,
                                   Hr_All_Organization_Units    Hou_Vend,
                                   Ap_Invoices_Interface        Ai,
                                   Ap_Invoice_Lines_Interface   Aid,
                                   Ap_Interface_Rejections      Air_Line,
                                   Ap_Interface_Rejections      Air_Inv,
                                   Pa_Projects_All              Pp
                            WHERE  Rct.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctl.Line_Type = 'LINE'
                            -- Récupération des lignes de facture AR de Refac
                            AND    Rctlgd.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctlgd.Customer_Trx_Line_Id = Rctl.Customer_Trx_Line_Id
                            AND    Rctlgd.Account_Set_Flag = 'N'
                            AND    Rctlgd.Account_Class = 'REV'
                            AND    Rctlgd_Gcc.Code_Combination_Id = Rctlgd.Code_Combination_Id
                            -- Récupération de l'org_id de AP
                            AND    Rc.Customer_Id = Rct.Bill_To_Customer_Id
                             --AND    Hou_Cust.NAME = Rc.Attribute1 --YWA 11i
                            AND   Hou_Cust.organization_id = Rct.org_id  --YWA R12
                            -- Récupération du fournisseur
                           -- AND    Pv.Attribute2 = Hou_Vend.NAME --YWA 11i
                            AND   Ai.org_id= Hou_Vend.organization_id --YWA R12
                            AND    Ai.Vendor_Id = Pv.Vendor_Id
                            -- Récupération de la ligne de facture AP de Refac
                            AND    Ai.Invoice_Num = Rct.Trx_Number
                            AND    Aid.Invoice_Id = Ai.Invoice_Id
                            -- AND    Aid.Attribute13 = Rctlgd.Attribute13 --YWA R12
                            -- Récupération du projet
                            AND    Pp.Project_Id = Aid.Project_Id
                            AND    Ai.SOURCE = 'REFAC'
                            AND    Ai.Status = 'REJECTED'
                            AND    Air_Line.Parent_Id(+) = Aid.Invoice_Line_Id
                            AND    Air_Line.Parent_Table(+) = 'AP_INVOICE_LINES_INTERFACE'
                            AND    Air_Line.Reject_Lookup_Code(+) != 'ACCOUNT REQUIRED'
                            AND    Air_Inv.Parent_Id(+) = Aid.Invoice_Id
                            AND    Air_Inv.Parent_Table(+) = 'AP_INVOICES_INTERFACE') Dsaai,
                           PA_EXPENDITURE_ITEMS_ALL Pei,
                           Gl_Je_Headers Gjh,
                           Gl_Je_Lines Gjl,
                           Fnd_User Fu
                    WHERE  Dsaai.Ar_Rctlgd_Attribute14 = 'EXPENDITURE'
                    -- Récupération de la ligne de dépense
                    AND    Pei.Expenditure_Item_Id = To_Number(Dsaai.Ar_Rctlgd_Attribute15)
                    -- Limitation aux lignes d'origine GL
                    AND    Pei.Attribute_Category = 'GL_REFAC'
                    -- Récupération de la ligne GL
                    --AND    Gjh.Je_Header_Id = To_Number(Substr(Pei.Attribute4, 1, (Instr(Pei.Attribute4, '_') - 1)))
                    AND    Gjh.Je_Header_Id = To_Number(Pei.Attribute4)
                    AND    Gjl.Je_Header_Id = Gjh.Je_Header_Id
                    --AND    Gjl.Je_Line_Num = To_Number(Substr(Pei.Attribute4, (Instr(Pei.Attribute4, '_') + 1)))
                    AND    Gjl.Je_Line_Num = To_Number(Pei.Attribute8)
                    AND    Gjl.Created_By = Fu.User_Id(+)
                    UNION ALL
                     -- Lignes de type EVENT d'origine AR
                    SELECT Dsaai.Ar_Reference Ar_Reference,
                           Dsaai.Ar_Trx_Number,
                           Dsaai.Ap_Org_Id Ap_Org_Id,
                           Dsaai.Ap_Invoice_Id,
                           Dsaai.Ap_Vendor_Id,
                           Dsaai.Ap_Invoice_Date,
                           Dsaai.Ap_Invoice_Gl_Date,
                           Dsaai.Ap_Invoice_Amount,
                           Dsaai.Ap_Invoice_Line_Number Line_Number,
                           Dsaai.Ap_Invoice_Line_Id,
                           Dsaai.Ap_Inv_Line_Gl_Date,
                           Dsaai.Ap_Inv_Line_Exp_Date,
                           Dsaai.Ap_Expenditure_Type,
                           Dsaai.Ap_Project_Number,
                           Dsaai.Ap_Project_Name,
                           Dsaai.Ap_Project_Status_Code,
                           Dsaai.Ap_Project_Date_Debut,
                           Dsaai.Ap_Project_Date_Cloture,
                           Dsaai.Ap_Project_Date_Fermeture,
                           Dsaai.Ap_Reject_Code,
                           Dsaai.Ar_Customer_Trx_Id Customer_Trx_Id,
                           Dsaai.Ar_Customer_Trx_Line_Id Customer_Trx_Line_Id,
                           Dsaai.Ar_Rctlgd_Attribute14,
                           To_Number(Dsaai.Ar_Rctlgd_Attribute15),
                           222 Orig_Application_Id,
                           'AR' Orig_Application,
                           Orig_Rct.Trx_Number Orig_Txn_Number,
                           Orig_Rctl.Line_Number Orig_Txn_Line_Number,
                           Orig_Rct.Doc_Sequence_Value Orig_Sequence_Number,
                           Orig_Rct.Trx_Date Orig_Line_Date,
                           Dsaai.Ar_Line_Amount Line_Amount,
                           Nvl(Orig_Rct.Attribute9, Fu.User_Name) Orig_User_Name
                    FROM   (SELECT Rct.Interface_Header_Attribute1 Ar_Reference,
                                   Rct.Trx_Number Ar_Trx_Number,
                                   Rct.Customer_Trx_Id Ar_Customer_Trx_Id,
                                   Rctl.Customer_Trx_Line_Id Ar_Customer_Trx_Line_Id,
                                   Rctlgd.Cust_Trx_Line_Gl_Dist_Id Ar_Cust_Trx_Line_Gl_Dist_Id,
                                   Aid.Line_Number Ap_Invoice_Line_Number,
                                   Rctl.Extended_Amount Ar_Line_Amount,
                                   Rctlgd.Code_Combination_Id Ar_Code_Combination_Id,
                                   Rctlgd_Gcc.Segment3 Ar_Acct_Segment3,
                                   Rctlgd.Attribute14 Ar_Rctlgd_Attribute14,
                                   Rctlgd.Attribute15 Ar_Rctlgd_Attribute15,
                                   Hou_Cust.Organization_Id Ap_Org_Id,
                                   Ai.Invoice_Id Ap_Invoice_Id,
                                   Ai.Vendor_Id Ap_Vendor_Id,
                                   Ai.Invoice_Date Ap_Invoice_Date,
                                   Ai.Gl_Date Ap_Invoice_Gl_Date,
                                   Ai.Invoice_Amount Ap_Invoice_Amount,
                                   Aid.Line_Number Ap_Distribution_Line_Number,
                                   Aid.Invoice_Line_Id Ap_Invoice_Line_Id,
                                   Aid.Accounting_Date Ap_Inv_Line_Gl_Date,
                                   Aid.Expenditure_Item_Date Ap_Inv_Line_Exp_Date,
                                   Aid.Expenditure_Type Ap_Expenditure_Type,
                                   Pp.Project_Id Ap_Project_Id,
                                   Pp.Segment1 Ap_Project_Number,
                                   Pp.Description Ap_Project_Name,
                                   Pp.Project_Status_Code Ap_Project_Status_Code,
                                   Pp.Start_Date Ap_Project_Date_Debut,
                                   Fnd_Date.Canonical_To_Date(Pp.Attribute8) Ap_Project_Date_Cloture,
                                   Nvl(Pp.Completion_Date, Fnd_Date.Canonical_To_Date(Pp.Attribute7)) Ap_Project_Date_Fermeture,
                                   (SELECT Alc.Displayed_Field
                                    FROM   Ap_Lookup_Codes Alc
                                    WHERE  Alc.Lookup_Type(+) = 'REJECT CODE'
                                    AND    Alc.Lookup_Code(+) = Nvl(Air_Line.Reject_Lookup_Code, Air_Inv.Reject_Lookup_Code)) Ap_Reject_Code
                            FROM   Ra_Customer_Trx_All          Rct,
                                   Ra_Customer_Trx_Lines_All    Rctl,
                                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgd,
                                   Gl_Code_Combinations         Rctlgd_Gcc,
                                   Ra_Customers                 Rc,
                                   Hr_All_Organization_Units    Hou_Cust,
                                   Po_Vendors                   Pv,
                                   Hr_All_Organization_Units    Hou_Vend,
                                   Ap_Invoices_Interface        Ai,
                                   Ap_Invoice_Lines_Interface   Aid,
                                   Ap_Interface_Rejections      Air_Line,
                                   Ap_Interface_Rejections      Air_Inv,
                                   Pa_Projects_All              Pp
                            WHERE  Rct.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctl.Line_Type = 'LINE'
                            -- Récupération des lignes de facture AR de Refac
                            AND    Rctlgd.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctlgd.Customer_Trx_Line_Id = Rctl.Customer_Trx_Line_Id
                            AND    Rctlgd.Account_Set_Flag = 'N'
                            AND    Rctlgd.Account_Class = 'REV'
                            AND    Rctlgd_Gcc.Code_Combination_Id = Rctlgd.Code_Combination_Id
                            -- Récupération de l'org_id de AP
                            AND    Rc.Customer_Id = Rct.Bill_To_Customer_Id
                            --AND    Hou_Cust.NAME = Rc.Attribute1 --YWA 11i
                            AND   Hou_Cust.organization_id = Rct.org_id  --YWA R12
                            -- Récupération du fournisseur
                           -- AND    Pv.Attribute2 = Hou_Vend.NAME --YWA 11i
                            AND   Ai.org_id= Hou_Vend.organization_id --YWA R12
                            AND    Ai.Vendor_Id = Pv.Vendor_Id
                            -- Récupération de la ligne de facture AP de Refac
                            AND    Ai.Invoice_Num = Rct.Trx_Number
                            AND    Aid.Invoice_Id = Ai.Invoice_Id
                           -- AND    Aid.Attribute13 = Rctlgd.Attribute13
                            -- Récupération du projet
                            AND    Pp.Project_Id = Aid.Project_Id
                            AND    Ai.SOURCE = 'REFAC'
                            AND    Ai.Status = 'REJECTED'
                            AND    Air_Line.Parent_Id(+) = Aid.Invoice_Line_Id
                            AND    Air_Line.Parent_Table(+) = 'AP_INVOICE_LINES_INTERFACE'
                            AND    Air_Line.Reject_Lookup_Code(+) != 'ACCOUNT REQUIRED'
                            AND    Air_Inv.Parent_Id(+) = Aid.Invoice_Id
                            AND    Air_Inv.Parent_Table(+) = 'AP_INVOICES_INTERFACE') Dsaai,
                           PA_EVENTS Pe,
                           Ra_Customer_Trx_All Orig_Rct,
                           Ra_Cust_Trx_Line_Gl_Dist_All Orig_Rctlgd,
                           Ra_Customer_Trx_Lines_All Orig_Rctl,
                           Fnd_User Fu
                    WHERE  Dsaai.Ar_Rctlgd_Attribute14 = 'EVENT'
                    -- Récupération de la ligne d'évènement
                    AND    Pe.Event_Id = To_Number(Dsaai.Ar_Rctlgd_Attribute15)
                    -- Limitation aux lignes d'origine AR
                    AND    Pe.Attribute_Category = 'AR_REFAC'
                    -- Récupération de la ligne de facture d'origine
                    AND    Orig_Rctlgd.Cust_Trx_Line_Gl_Dist_Id = To_Number(Pe.Attribute4)
                    AND    Orig_Rct.Customer_Trx_Id = Orig_Rctlgd.Customer_Trx_Id
                    AND    Orig_Rctl.Customer_Trx_Line_Id = Orig_Rctlgd.Customer_Trx_Line_Id
                    AND    Fu.User_Id(+) = Orig_Rct.Created_By
                    UNION ALL
                    -- Lignes de type EVENT d'origine GL
                    SELECT Dsaai.Ar_Reference Ar_Reference,
                           Dsaai.Ar_Trx_Number,
                           Dsaai.Ap_Org_Id Ap_Org_Id,
                           Dsaai.Ap_Invoice_Id,
                           Dsaai.Ap_Vendor_Id,
                           Dsaai.Ap_Invoice_Date,
                           Dsaai.Ap_Invoice_Gl_Date,
                           Dsaai.Ap_Invoice_Amount,
                           Dsaai.Ap_Invoice_Line_Number Line_Number,
                           Dsaai.Ap_Invoice_Line_Id,
                           Dsaai.Ap_Inv_Line_Gl_Date,
                           Dsaai.Ap_Inv_Line_Exp_Date,
                           Dsaai.Ap_Expenditure_Type,
                           Dsaai.Ap_Project_Number,
                           Dsaai.Ap_Project_Name,
                           Dsaai.Ap_Project_Status_Code,
                           Dsaai.Ap_Project_Date_Debut,
                           Dsaai.Ap_Project_Date_Cloture,
                           Dsaai.Ap_Project_Date_Fermeture,
                           Dsaai.Ap_Reject_Code,
                           Dsaai.Ar_Customer_Trx_Id Customer_Trx_Id,
                           Dsaai.Ar_Customer_Trx_Line_Id Customer_Trx_Line_Id,
                           Dsaai.Ar_Rctlgd_Attribute14,
                           To_Number(Dsaai.Ar_Rctlgd_Attribute15),
                           101 Orig_Application_Id,
                           'GL' Orig_Application,
                           Gjh.NAME Orig_Txn_Number,
                           Gjl.Je_Line_Num Orig_Txn_Line_Number,
                           Gjh.Doc_Sequence_Value Orig_Sequence_Number,
                           Gjl.Effective_Date Orig_Line_Date,
                           Dsaai.Ar_Line_Amount Line_Amount,
                           Nvl(Gjl.Attribute9, Fu.User_Name) Orig_User_Name
                    FROM   (SELECT Rct.Interface_Header_Attribute1 Ar_Reference,
                                   Rct.Trx_Number Ar_Trx_Number,
                                   Rct.Customer_Trx_Id Ar_Customer_Trx_Id,
                                   Rctl.Customer_Trx_Line_Id Ar_Customer_Trx_Line_Id,
                                   Rctlgd.Cust_Trx_Line_Gl_Dist_Id Ar_Cust_Trx_Line_Gl_Dist_Id,
                                   Aid.Line_Number Ap_Invoice_Line_Number,
                                   Rctl.Extended_Amount Ar_Line_Amount,
                                   Rctlgd.Code_Combination_Id Ar_Code_Combination_Id,
                                   Rctlgd_Gcc.Segment3 Ar_Acct_Segment3,
                                   Rctlgd.Attribute14 Ar_Rctlgd_Attribute14,
                                   Rctlgd.Attribute15 Ar_Rctlgd_Attribute15,
                                   Hou_Cust.Organization_Id Ap_Org_Id,
                                   Ai.Invoice_Id Ap_Invoice_Id,
                                   Ai.Vendor_Id Ap_Vendor_Id,
                                   Ai.Invoice_Date Ap_Invoice_Date,
                                   Ai.Gl_Date Ap_Invoice_Gl_Date,
                                   Ai.Invoice_Amount Ap_Invoice_Amount,
                                   Aid.Line_Number Ap_Distribution_Line_Number,
                                   Aid.Invoice_Line_Id Ap_Invoice_Line_Id,
                                   Aid.Accounting_Date Ap_Inv_Line_Gl_Date,
                                   Aid.Expenditure_Item_Date Ap_Inv_Line_Exp_Date,
                                   Aid.Expenditure_Type Ap_Expenditure_Type,
                                   Pp.Project_Id Ap_Project_Id,
                                   Pp.Segment1 Ap_Project_Number,
                                   Pp.Description Ap_Project_Name,
                                   Pp.Project_Status_Code Ap_Project_Status_Code,
                                   Pp.Start_Date Ap_Project_Date_Debut,
                                   Fnd_Date.Canonical_To_Date(Pp.Attribute8) Ap_Project_Date_Cloture,
                                   Nvl(Pp.Completion_Date, Fnd_Date.Canonical_To_Date(Pp.Attribute7)) Ap_Project_Date_Fermeture,
                                   (SELECT Alc.Displayed_Field
                                    FROM   Ap_Lookup_Codes Alc
                                    WHERE  Alc.Lookup_Type(+) = 'REJECT CODE'
                                    AND    Alc.Lookup_Code(+) = Nvl(Air_Line.Reject_Lookup_Code, Air_Inv.Reject_Lookup_Code)) Ap_Reject_Code
                            FROM   Ra_Customer_Trx_All          Rct,
                                   Ra_Customer_Trx_Lines_All    Rctl,
                                   Ra_Cust_Trx_Line_Gl_Dist_All Rctlgd,
                                   Gl_Code_Combinations         Rctlgd_Gcc,
                                   Ra_Customers                 Rc,
                                   Hr_All_Organization_Units    Hou_Cust,
                                   Po_Vendors                   Pv,
                                   Hr_All_Organization_Units    Hou_Vend,
                                   Ap_Invoices_Interface        Ai,
                                   Ap_Invoice_Lines_Interface   Aid,
                                   Ap_Interface_Rejections      Air_Line,
                                   Ap_Interface_Rejections      Air_Inv,
                                   Pa_Projects_All              Pp
                            WHERE  Rct.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctl.Line_Type = 'LINE'
                            -- Récupération des lignes de facture AR de Refac
                            AND    Rctlgd.Customer_Trx_Id = Rctl.Customer_Trx_Id
                            AND    Rctlgd.Customer_Trx_Line_Id = Rctl.Customer_Trx_Line_Id
                            AND    Rctlgd.Account_Set_Flag = 'N'
                            AND    Rctlgd.Account_Class = 'REV'
                            AND    Rctlgd_Gcc.Code_Combination_Id = Rctlgd.Code_Combination_Id
                            -- Récupération de l'org_id de AP
                            AND    Rc.Customer_Id = Rct.Bill_To_Customer_Id
                            --AND    Hou_Cust.NAME = Rc.Attribute1 --YWA 11i
                            AND   Hou_Cust.organization_id = Rct.org_id  --YWA R12
                            -- Récupération du fournisseur
                           -- AND    Pv.Attribute2 = Hou_Vend.NAME --YWA 11i
                            AND   Ai.org_id= Hou_Vend.organization_id --YWA R12
                            AND    Ai.Vendor_Id = Pv.Vendor_Id
                            -- Récupération de la ligne de facture AP de Refac
                            AND    Ai.Invoice_Num = Rct.Trx_Number
                            AND    Aid.Invoice_Id = Ai.Invoice_Id
                           -- AND    Aid.Attribute13 = Rctlgd.Attribute13-YWA R12
                            -- Récupération du projet
                            AND    Pp.Project_Id = Aid.Project_Id
                            AND    Ai.SOURCE = 'REFAC'
                            AND    Ai.Status = 'REJECTED'
                            AND    Air_Line.Parent_Id(+) = Aid.Invoice_Line_Id
                            AND    Air_Line.Parent_Table(+) = 'AP_INVOICE_LINES_INTERFACE'
                            AND    Air_Line.Reject_Lookup_Code(+) != 'ACCOUNT REQUIRED'
                            AND    Air_Inv.Parent_Id(+) = Aid.Invoice_Id
                            AND    Air_Inv.Parent_Table(+) = 'AP_INVOICES_INTERFACE') Dsaai,
                           Pa_Events Pe,
                           Gl_Je_Headers Gjh,
                           Gl_Je_Lines Gjl,
                           Fnd_User Fu
                    WHERE  Dsaai.Ar_Rctlgd_Attribute14 = 'EVENT'
                    -- Récupération de la ligne d'évènement
                    AND    Pe.Event_Id = To_Number(Dsaai.Ar_Rctlgd_Attribute15)
                    -- Limitation aux lignes d'origine GL
                    AND    Pe.Attribute_Category = 'GL_REFAC'
                    -- Récupération de la ligne GL
                    --AND    Gjh.Je_Header_Id = To_Number(Substr(Pe.Attribute5, 1, (Instr(Pe.Attribute5, '_') - 1)))
                    AND    Gjh.Je_Header_Id = To_Number(Pe.Attribute5)
                    AND    Gjl.Je_Header_Id = Gjh.Je_Header_Id
                    --AND    Gjl.Je_Line_Num = To_Number(Substr(Pe.Attribute5, (Instr(Pe.Attribute5, '_') + 1)))
                    AND    Gjl.Je_Line_Num = To_Number(Pe.Attribute8)
                    AND    Fu.User_Id(+) = Gjl.Created_By) v,
                   Hr_All_Organization_Units Hou_Soc_Ap,
                   Po_Vendors Pv
            WHERE  Hou_Soc_Ap.Organization_Id = v.Ap_Org_Id
            AND    Pv.Vendor_Id = v.Ap_Vendor_Id
            AND    v.Ap_Reject_Code IS NOT NULL
            ORDER  BY v.Ar_Reference,
                      v.Line_Number;

        Rec_Lignes Cur_Lignes%ROWTYPE;

        Vn_Nb_Enreg NUMBER := 0;

    BEGIN

        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 6 : Rejets Open Interface');
        Dka_Tools_Pkg.Put_Outdebug_Message('    -------------------------------');

        OPEN Cur_Lignes;
        LOOP
            FETCH Cur_Lignes INTO Rec_Lignes;
            EXIT WHEN Cur_Lignes%NOTFOUND;
            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Reference facture', 19) ||
                                                   Rpad('No Facture', 19) ||
                                                   Rpad('Soc.', 5) ||
                                                   Rpad('Invoice_Id', 16) ||
                                                   Rpad('Fournisseur', 41) ||
                                                   Rpad('Facture', 11) ||
                                                   Rpad('Montant Facture', 16) ||
                                                   Rpad('Invoice_Line_Id', 16) ||
                                                   Rpad('No Ligne', 9) ||
                                                   Rpad('Montant Ligne', 16) ||
                                                   Rpad('Motif de rejet', 50));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 18, '-') || ' ' ||
                                                   Rpad('-', 18, '-') || ' ' ||
                                                   Rpad('-', 4, '-') || ' ' ||
                                                   Rpad('-', 15, '-') || ' ' ||
                                                   Rpad('-', 40, '-') || ' ' ||
                                                   Rpad('-', 10, '-') || ' ' ||
                                                   Rpad('-', 15, '-') || ' ' ||
                                                   Rpad('-', 15, '-') || ' ' ||
                                                   Rpad('-', 8, '-') || ' ' ||
                                                   Rpad('-', 15, '-') || ' ' ||
                                                   Rpad('-', 50, '-'));
            END IF;

            Dka_Tools_Pkg.Put_Outdebug_Message(Rpad(Substr(Rec_Lignes.Reference_Facture_Refac, 1, 18), 18) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.No_Facture_Ap_De_Refac, 1, 18), 18) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Soc_Facture_Ap_De_Refac, 1, 4), 4) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Invoice_Id_Open_Interface_Ap), 15) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Fournisseur, 1, 40), 40) || ' ' ||
                                               Rpad(Rec_Lignes.Date_Facture_Ap, 10) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Montant_Facture_Ap, '999G999G999D99'), 15) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Invoice_Line_Id), 15) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.No_Ligne), 8) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Montant_Ligne, '999G999G999D99'), 15) || ' ' ||
                                               Rpad(Rec_Lignes.Motif_De_Rejet, 50));
            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 6';
        END LOOP;
        CLOSE Cur_Lignes;

    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_6 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_6;


    -- -----------------------------------------------------------------------------
    -- Nom              : Step_7
    -- Description      : Liste des factures AP saisies le jour même sur des projets
    --                    fermés
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_7(Pv_Errbuf    OUT VARCHAR2,
                     Pn_Retcode   OUT NUMBER) IS

        CURSOR Cur_Lignes IS
            SELECT Invoice_Id               Invoice_Id,
                   Distribution_Line_Number Dist_Line_Number,
                   Attribute1               Project_Id
            FROM   AP_INVOICE_DISTRIBUTIONS_ALL
            WHERE  Trunc(Creation_Date) = Trunc(SYSDATE)
            AND    Attribute1 IN (SELECT Project_Id
                                  FROM   Pa_Projects_All
                                  WHERE  Project_Status_Code = 'CLOSED');--YWA VALIDE r12

        Rec_Lignes Cur_Lignes%ROWTYPE;

        Vn_Nb_Enreg NUMBER := 0;

    BEGIN

        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 7 : Factures AP saisies le jour même sur un projet fermé');
        Dka_Tools_Pkg.Put_Outdebug_Message('    --------------------------------------------------------------');

        OPEN Cur_Lignes;
        LOOP
            FETCH Cur_Lignes
                INTO Rec_Lignes;
            EXIT WHEN Cur_Lignes%NOTFOUND;
            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Invoice_id', 21) ||
                                                   Rpad('Dist_Line_Number', 21) ||
                                                   Rpad('Project_Id', 20));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 20, '-') || ' ' ||
                                                   Rpad('-', 20, '-') || ' ' ||
                                                   Rpad('-', 20, '-'));
            END IF;

            Dka_Tools_Pkg.Put_Outdebug_Message(Lpad(To_Char(Rec_Lignes.Invoice_Id), 20) || ' ' ||
                                               Lpad(To_Char(Rec_Lignes.Dist_Line_Number), 20) || ' ' ||
                                               Lpad(Rec_Lignes.Project_Id, 20));
            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 7';
        END LOOP;
        CLOSE Cur_Lignes;

    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_7 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_7;

    -- -----------------------------------------------------------------------------
    -- Nom              : Step_8
    -- Description      : Liste des types de dépense de refacturation non valides
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Step_8(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER) IS

        CURSOR Cur_Lignes IS
            SELECT Dsp.Ap_Expenditure_Type Type_Depense_Ap,
                   Nvl(Fu1.User_Name, 'User supprimé') Cree_Par,
                   Nvl(Fu1.Description, 'User supprimé') Desc_Cree_Par,
                   Nvl(Fu2.User_Name, 'User supprimé') Maj_Par,
                   Nvl(Fu2.Description, 'User supprimé') Desc_Maj_Par,
                   Dsp.Orig_Transaction_Type Type_Mvt_Origine,
                   Dsp.Ar_Event_Type Type_Event_Ar
            FROM   Dka_Sarrefac_Param Dsp,
                   Fnd_User           Fu1,
                   Fnd_User           Fu2
            WHERE  Fu1.User_Id(+) = Dsp.Created_By
            AND    Fu2.User_Id(+) = Dsp.Last_Updated_By
            AND    Dsp.Ap_Expenditure_Type NOT IN (SELECT Pete.Expenditure_Type
                                                   FROM   Pa_Expenditure_Types_Expend_v Pete
                                                   WHERE  Pete.System_Linkage_Function = 'VI'
                                                   AND    Last_Day(SYSDATE) BETWEEN Pete.Expnd_Typ_Start_Date_Active
                                                                            AND     Nvl(Pete.Expnd_Typ_End_Date_Active, Last_Day(SYSDATE))
                                                   AND    Last_Day(SYSDATE) BETWEEN Pete.Sys_Link_Start_Date_Active
                                                                            AND     Nvl(Pete.Sys_Link_End_Date_Active, Last_Day(SYSDATE)))
            ORDER  BY Dsp.Ap_Expenditure_Type; --YWA VALIDE r12

        Rec_Lignes Cur_Lignes%ROWTYPE;

        Vn_Nb_Enreg NUMBER := 0;

    BEGIN

        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message(' ');
        Dka_Tools_Pkg.Put_Outdebug_Message('==> ETAPE 8 : Types de dépenses de refacturation non valides');
        Dka_Tools_Pkg.Put_Outdebug_Message('    --------------------------------------------------------');

        OPEN Cur_Lignes;
        LOOP
            FETCH Cur_Lignes INTO Rec_Lignes;
            EXIT WHEN Cur_Lignes%NOTFOUND;
            Vn_Nb_Enreg := Vn_Nb_Enreg + 1;

            IF Vn_Nb_Enreg = 1 THEN
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');
                Dka_Tools_Pkg.Put_Outdebug_Message(' ');

                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('Type depense AP', 41) ||
                                                   Rpad('Créé par', 21) ||
                                                   Rpad('Nom créé par', 31) ||
                                                   Rpad('Maj par', 21) ||
                                                   Rpad('Nom maj par', 31) ||
                                                   Rpad('Type mouvement origine', 41) ||
                                                   Rpad('Type évènement Ar', 41));
                Dka_Tools_Pkg.Put_Outdebug_Message(Rpad('-', 40, '-') || ' ' ||
                                                   Rpad('-', 20, '-') || ' ' ||
                                                   Rpad('-', 30, '-') || ' ' ||
                                                   Rpad('-', 20, '-') || ' ' ||
                                                   Rpad('-', 30, '-') || ' ' ||
                                                   Rpad('-', 40, '-') || ' ' ||
                                                   Rpad('-', 40, '-'));
            END IF;

            Dka_Tools_Pkg.Put_Outdebug_Message(Rpad(Substr(Rec_Lignes.Type_Depense_Ap, 1, 40), 40) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Cree_Par, 1, 20), 20) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Desc_Cree_Par, 1, 30), 30) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Maj_Par, 1, 20), 20) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Desc_Maj_Par, 1, 30), 30) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Type_Mvt_Origine, 1, 40), 40) || ' ' ||
                                               Rpad(Substr(Rec_Lignes.Type_Event_Ar, 1, 40), 40));
            Pn_Retcode := 1;
            Pv_Errbuf  := 'Anomalie(s) constatée(s) lors du contrôle de l''étape 8';
        END LOOP;
        CLOSE Cur_Lignes;

    EXCEPTION
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := 'ERREUR Step_8 : ' || Substr(SQLERRM, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);

    END Step_8;

    -- -----------------------------------------------------------------------------
    -- Nom              : Main
    -- Description      : Enchainement des 8 étapes
    --
    -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
    --                    Pn_Retcode         Sortie Code Retour de la procédure
    --                                              '0' : Normal
    --                                              '1' : Avertissement
    --                                              '2' : Erreur
    --                    Pv_Period_Name     Entrée Nom de la période
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Main(Pv_Errbuf      IN OUT VARCHAR2,
                   Pn_Retcode     IN OUT NUMBER,
                   Pv_Period_Name IN     VARCHAR2,
                   Pv_Ctrl_Sites  IN     VARCHAR2) IS

        Vn_Retcode       NUMBER := 0;
        Vc_Errbuf        VARCHAR2(250);

        E_Error          EXCEPTION;

    BEGIN

        ---------------------------------------------------------------------
        -- Contrôle des clients avec des codes sociétés groupes identiques --
        ---------------------------------------------------------------------
        Vc_Errbuf  := NULL;
        Vn_Retcode := 0;
        Step_1(Vc_Errbuf, Vn_Retcode);
        IF Vn_Retcode = 1 THEN
           Pn_Retcode := Vn_Retcode;
        ELSIF Vn_Retcode = 2 THEN
           RAISE E_Error;
        END IF;

        --------------------------------------------
        -- Contrôle des mouvements non refacturés --
        --------------------------------------------
        Vc_Errbuf  := NULL;
        Vn_Retcode := 0;
        Step_2(Vc_Errbuf, Vn_Retcode, Pv_Period_Name);
        IF Vn_Retcode = 1 THEN
           Pn_Retcode := Vn_Retcode;
        ELSIF Vn_Retcode = 2 THEN
           RAISE E_Error;
        END IF;

        ---------------------------------------------------------------
        -- Détermination des sites fournisseurs et clients manquants --
        ---------------------------------------------------------------
        IF Pv_Ctrl_Sites = 'Y' THEN
           Vc_Errbuf  := NULL;
           Vn_Retcode := 0;
           Step_3(Vc_Errbuf, Vn_Retcode, Pv_Period_Name);
           IF Vn_Retcode = 1 THEN
              Pn_Retcode := Vn_Retcode;
           ELSIF Vn_Retcode = 2 THEN
              RAISE E_Error;
           END IF;
        END IF;

        -------------------------------------------------
        -- Liste des lignes AP non transférées dans PA --
        -------------------------------------------------
        Vc_Errbuf  := NULL;
        Vn_Retcode := 0;
        Step_4(Vc_Errbuf, Vn_Retcode, Pv_Period_Name);
        IF Vn_Retcode = 1 THEN
           Pn_Retcode := Vn_Retcode;
        ELSIF Vn_Retcode = 2 THEN
           RAISE E_Error;
        END IF;

        -------------------------------------------------------
        -- Liste des sociétés segmentées sans territorialité --
        -------------------------------------------------------
        Vc_Errbuf  := NULL;
        Vn_Retcode := 0;
        Step_5(Vc_Errbuf, Vn_Retcode);
        IF Vn_Retcode = 1 THEN
           Pn_Retcode := Vn_Retcode;
        ELSIF Vn_Retcode = 2 THEN
           RAISE E_Error;
        END IF;

        ------------------------------
        -- Rejets Open Interface AP --
        ------------------------------
        Vc_Errbuf  := NULL;
        Vn_Retcode := 0;
        Step_6(Vc_Errbuf, Vn_Retcode);
        IF Vn_Retcode = 1 THEN
           Pn_Retcode := Vn_Retcode;
        ELSIF Vn_Retcode = 2 THEN
           RAISE E_Error;
        END IF;

        ---------------------------------------------
        -- Factures AP saisies sur un projet fermé --
        ---------------------------------------------
        Vc_Errbuf  := NULL;
        Vn_Retcode := 0;
        Step_7(Vc_Errbuf, Vn_Retcode);
        IF Vn_Retcode = 1 THEN
           Pn_Retcode := Vn_Retcode;
        ELSIF Vn_Retcode = 2 THEN
           RAISE E_Error;
        END IF;

        ---------------------------------------------------
        -- Types de dépense de refacturation non valides --
        ---------------------------------------------------
        Vc_Errbuf  := NULL;
        Vn_Retcode := 0;
        Step_8(Vc_Errbuf, Vn_Retcode);
        IF Vn_Retcode = 1 THEN
           Pn_Retcode := Vn_Retcode;
        ELSIF Vn_Retcode = 2 THEN
           RAISE E_Error;
        END IF;

    EXCEPTION
        WHEN E_Error THEN
            Pn_Retcode := Vn_Retcode;
            Pv_Errbuf  := Vc_Errbuf;
        WHEN OTHERS THEN
            Pn_Retcode := 2;
            Pv_Errbuf  := SUBSTR(Sqlerrm, 1, 80);
            Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
    END;

END Dka_Controle_Refac_Pkg;
/
SHOW ERRORS
EXIT
