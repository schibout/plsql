CREATE OR REPLACE Package Body DKA_AMOR_FISC_PKG As

--------------------------------------------------------------------------------
-- $Header: H:/developpement/CVSROOT/ETA040\040-\040Amortissements\040fiscaux\040-\040Mouvements\040de\040la\040période\040-/Sources/SFAAMORFISC/sql/DKA_AMOR_FISC_PKG.pkb,v 1.2 2004/08/06 12:57:00 stiberghien Exp $
-- FICHIER       : @@Package_name..sql @@version_Package
-- DESCRIPTION   :  Outils de chargement/dechargement de programmes
--
-- AUTEUR        :  Prénom, Nom de l'auteur
--
-- DATE CREATION :  Date de création
--
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             : 1.1
-- Date                : 22/09/2003
-- Auteur              : EM
-- Nature              : Modification de la recherche de l'amortissement de
--                       début et des valeurs de réévaluation et de dotations
--------------------------------------------------------------------------------
-- PHENIX 2004
-- Version             : 1.2
-- Date                : 30/09/2004
-- Auteur              : SL
-- Nature              : Modification du curseur afin d'écarter les
--			 cessions annulées (supprimées)
-- PHENIX 2004
--------------------------------------------------------------------------------

-- 06/08/2004 STI   Portage Specifique PHENIX 2004
--                  Procedure Insert_Data, modification des 3 premiers caracteres du segment1 --> Centre de Gestion-->segment2
--                                         modification des 4 derniers caracteres du segment1 --> societe-->segment1
--------------------------------------------------------------------------------
-- Version             : 1.3
-- Date                : 23/03/2005
-- Auteur              : SL
-- Nature              : Modification de la recherche des diminutions d'amortissements
--                       dans le cas des cessions. Suppression de la jointure avec la vue fa_retirements_v
-- PHENIX 2004
--------------------------------------------------------------------------------
-- Version             : 1.4
-- Date                : 19/05/2006
-- Auteur              : EMA
-- Nature              : Prise en compte des immos fusionnées.
--------------------------------------------------------------------------------

-- **************************************************************************
--                    DECLARATIONS GLOBALES
-- **************************************************************************

-- **************************************************************************
--                    FONCTIONS ET PROCEDURES PRIVEES
-- **************************************************************************

-- **************************************************************************
--                    FONCTIONS ET PROCEDURES PUBLIQUES
-- **************************************************************************

Function version
    Return Varchar2
IS
BEGIN
    Return ('$Header: H:/developpement/CVSROOT/ETA040\040-\040Amortissements\040fiscaux\040-\040Mouvements\040de\040la\040période\040-/Sources/SFAAMORFISC/sql/DKA_AMOR_FISC_PKG.pkb,v 1.2 2004/08/06 12:57:00 stiberghien Exp $'|| CHR (10) || '@@version_Package');
END version;

-----------------------------------------------------------------
--  Nom           : Insert_Data
--  Description   :
--
--  PARAMETRES :
--     Pv_Societe          Entrée                  Code Société
--     Pv_Centre_Gestion   Entrée                  Code Centre de Gestion
--     Pv_Period_From      Entrée                  Période de début
--     Pv_Period_To        Entrée                  Période de fin
--     Pn_Set_Of_Books_Id  Entrée                  Set Of Books
--     Pn_User_Id          Entrée                  Id Utilisateur
--     Pn_Conc_Request_Id  Entrée                  Id Traitement
--     Pv_Debug_Mode       Entrée                  Mode Debug
--     Pn_Code_Retour      Entrée/Sortie           Code Retour
--     Pv_Message_Erreur   Entrée/Sortie           Message Erreur
-----------------------------------------------------------------
Procedure Insert_Data ( Pv_Societe          In     Varchar2,
                        Pv_Centre_Gestion   In     Varchar2,
                        Pv_Period_From      In     Varchar2,
                        Pv_Period_To        In     Varchar2,
                        Pn_Set_Of_Books_Id  In     Number,
                        Pn_User_Id          In     Number,
                        Pn_Conc_Request_Id  In     Number,
                        Pv_Debug_Mode       In     Varchar2,
                        Pn_Code_Retour      In Out Number,
                        Pv_Message_Erreur   In Out Varchar2 )
Is

    --------------------------------------------
    -- Curseur de lecture des immobilisations --
    --------------------------------------------
    Cursor Cur_Immo (Pv_Book_Type_Code  Varchar2,
                     Pv_Societe         Varchar2,
                     Pv_Centre_Gestion  Varchar2,
                     Pn_Period_From_Pc  Number,
                     Pd_Period_From_Pod Date,
                     Pd_Period_To_Pcd   Date)
    Is
        Select To_Number(Ffvv_cate.Flex_Value)                                     Code_Cate,
               Ffvv_Cate.Description                                               Desc_Cate,
               Ffvv_Immo.Flex_Value                                                Code_Immo,
               Ffvv_Immo.Description                                               Desc_Immo,
               -1                                                                  Asset_Id,
               Null                                                                Asset_Number,
               -1                                                                  Distribution_Id
               --To_Date(Null)                                                       Date_Cession, -- MODIF PHENIX 23_03_05
               --0                                                                   Diminution_Amortissement -- MODIF PHENIX 23_03_05
        From   Fnd_Flex_Value_Sets     Ffvs_Cate,
               Fnd_Flex_Values_Vl      Ffvv_Cate,
               Fnd_Flex_Value_Sets     Ffvs_Immo,
               Fnd_Flex_Values_Vl      Ffvv_Immo
        Where  Ffvs_Cate.Flex_Value_Set_Name = 'DKA_CATEG_IMMOS_LIASSE_FISCALE'
        And    Ffvs_Cate.Flex_Value_Set_Id   = Ffvv_Cate.Flex_Value_Set_Id
        And    Ffvs_Immo.Flex_Value_Set_Name = 'DAOPCCF_LOCAL'
        And    Ffvs_Immo.Flex_Value_Set_Id   = Ffvv_Immo.Flex_Value_Set_Id
        And    Ffvv_Immo.Attribute6          = Ffvv_Cate.Flex_Value
        Union All
        Select To_Number(Ffvv_Cate.Flex_Value)                                     Code_Cate,
               Ffvv_Cate.Description                                               Desc_Cate,
               Ffvv_Immo.Flex_Value                                                Code_Immo,
               Ffvv_Immo.Description                                               Desc_Immo,
               Fbv.Asset_Id                                                        Asset_Id,
               Fab.Asset_Number                                                    Asset_Number,
               Fdh.Distribution_Id                                                 Distribution_Id
               --Trunc(Frv.date_Retired)                                             Date_Cession, -- MODIF PHENIX 23_03_05
               --Nvl(Frv.Unrevalued_Cost_Retired, 0) - Nvl(Frv.Nbv_Retired, 0)       Diminution_Amortissement -- MODIF PHENIX 23_03_05
        From   Fnd_Flex_Value_Sets           Ffvs_Cate,
               Fnd_Flex_Values_Vl            Ffvv_Cate,
               Fnd_Flex_value_Sets           Ffvs_Immo,
               Fnd_Flex_Values_Vl            Ffvv_Immo,
               Fa_Books_V                    Fbv,
               Fa_Additions_B                Fab,
               Fa_Categories                 Fc,
               Fa_Category_Books             Fcb,
               Gl_Code_Combinations          Gcc,
               Fa_Distribution_History       Fdh,
               Gl_Code_Combinations          Gcc1
               --Fa_Retirements_V              Frv -- MODIF PHENIX 23_03_05
        Where  Ffvs_Cate.Flex_Value_Set_Name = 'DKA_CATEG_IMMOS_LIASSE_FISCALE'
        And    Ffvs_Cate.Flex_Value_Set_Id   = Ffvv_Cate.Flex_Value_Set_Id
        And    Ffvs_Immo.Flex_Value_Set_Name = 'DAOPCCF_LOCAL'
        And    Ffvs_Immo.Flex_Value_Set_Id   = Ffvv_Immo.Flex_Value_Set_Id
        And    Ffvv_Immo.Attribute6          = Ffvv_Cate.Flex_Value
        And    Fbv.Book_Type_Code            = Pv_Book_Type_Code
        And    Fbv.Asset_Id                  = Fab.Asset_Id
        And    Fab.Asset_Category_Id         = Fc.Category_Id
        And    Fc.Category_Id                = Fcb.Category_Id
        And    Fcb.Book_Type_Code            = Fbv.Book_Type_Code
        And    Fcb.Asset_Cost_Account_Ccid   = Gcc.Code_Combination_Id
        And    Gcc.Segment3                  = Ffvv_Immo.Flex_Value
        And    Fdh.Book_Type_Code            = Fbv.Book_Type_Code
        And    Fdh.Asset_Id                  = Fbv.Asset_Id
        And    Fdh.Date_Ineffective         Is Null
        And    Fdh.Code_Combination_Id       = Gcc1.Code_Combination_Id
        --And    Substr(Gcc1.Segment1, 1, 3)   = Nvl(Pv_Centre_Gestion, Substr(Gcc1.Segment1, 1, 3)) -- PHENIX 2004
        And    Gcc1.Segment2   = Nvl(Pv_Centre_Gestion, Gcc1.Segment2) -- PHENIX 2004
        -- And    Substr(Gcc1.Segment1, 4, 4)   = Nvl(Pv_Societe, Substr(Gcc1.Segment1, 4, 4)) -- PHENIX 2004
        And    Gcc1.Segment1   = Nvl(Pv_Societe, Gcc1.Segment1) -- PHENIX 2004
-- MODIF PHENIX 23_03_05 DEBUT
        /*
        And    Fbv.Asset_Id                  = Frv.Asset_Id(+)
        And    Fbv.Book_Type_Code            = Frv.Book_Type_Code(+)
        And    Trunc(Nvl(Frv.date_Retired, Pd_Period_From_Pod)) >= Trunc(Pd_Period_From_Pod)
--      And    Trunc(Nvl(Frv.date_Retired, Pd_Period_From_Pod)) Between Trunc(Pd_Period_From_Pod)
--                                                                And     Trunc(Pd_Period_To_Pcd)
        And    Nvl(Frv.Status,' ')           != 'DELETED'        -- PHENIX 2004 SL
        */
-- MODIF PHENIX 23_03_05 FIN
        ;

    Rec_Immo                                           Cur_Immo%RowType;
    Vn_Period_From_Pc                                  Fa_Deprn_Periods.Period_Counter%Type;
    Vn_Period_From_Fy                                  Fa_Deprn_Periods.Fiscal_Year%Type;
    Vd_Period_From_Pod                                 Fa_Deprn_Periods.Period_Open_Date%Type;
    Vd_Period_From_Pcd                                 Fa_Deprn_Periods.Period_Close_Date%Type;
    Vn_Period_To_Pc                                    Fa_Deprn_Periods.Period_Counter%Type;
    Vn_Period_To_Fy                                    Fa_Deprn_Periods.Fiscal_Year%Type;
    Vd_Period_To_Pod                                   Fa_Deprn_Periods.Period_Open_Date%Type;
    Vd_Period_To_Pcd                                   Fa_Deprn_Periods.Period_Close_Date%Type;

    Vn_Amortissement_Debut                             Dka_Amor_Fisc.Amortissement_Debut%Type;
    Vn_Reevaluation_Exercice                           Dka_Amor_Fisc.Reevaluation_Exercice%Type;
    Vn_Dotations_Exercice                              Dka_Amor_Fisc.Dotations_Exercice%Type;
    Vn_Diminution_Amortissement                        Dka_Amor_Fisc.Diminution_Amortissement%Type;

    Vc_Book_Type_Code                                  Fa_Book_Controls.Book_Type_Code%Type;
    
    Vn_Nombre                                          Number;
    Vc_Fusion                                          Varchar2(1);
    Vc_Dummy                                           Varchar2(1);
    Vn_Old_Asset_Id                                    Fa_Additions_B.Asset_Id%Type;
    Vc_Old_Company_Name                                Dka_Stransco_Lines.Params_Value%Type;
    Vc_Old_Book_Type_Code                              Fa_Book_Controls.Book_Type_Code%Type;

Begin

    -----------------------------------------
    -- Recherche du nom du livre comptable --
    -----------------------------------------
    Begin
        Select Book_Type_Code
        Into   Vc_Book_Type_Code
        From   Fa_Book_Controls
        Where  Book_Type_Code Like Pv_Societe||'%'
        And    Book_Class     = 'CORPORATE'
        And    Date_Ineffective Is Null;
    End;

    -------------------------------------------------------------------
    -- Recherche des dates de début et de fin de la période de début --
    -------------------------------------------------------------------
    Begin
        Select Period_Counter,
               Fiscal_Year,
               --Period_Open_Date,
               --Nvl(Period_Close_Date, Sysdate)
               Calendar_Period_Open_Date,
               Calendar_Period_Close_Date
        Into   Vn_Period_From_Pc,
               Vn_Period_From_Fy,
               Vd_Period_From_Pod,
               Vd_Period_From_Pcd
        From   Fa_Deprn_Periods Fdp
        Where  Fdp.Book_Type_Code = Vc_Book_Type_Code
        And    Fdp.Period_Name    = Pv_Period_From;
    End;

    -----------------------------------------------------------------
    -- Recherche des dates de début et de fin de la période de fin --
    -----------------------------------------------------------------
    Begin
        Select Period_Counter,
               Fiscal_Year,
               --Period_Open_Date,
               --Nvl(Period_Close_Date, Sysdate)
               Calendar_Period_Open_Date,
               Calendar_Period_Close_Date
        Into   Vn_Period_To_Pc,
               Vn_Period_To_Fy,
               Vd_Period_To_Pod,
               Vd_Period_To_Pcd
        From   Fa_Deprn_Periods Fdp
        Where  Fdp.Book_Type_Code = Vc_Book_Type_Code
        And    Fdp.Period_Name    = Pv_Period_To;
    End;
    
    ----------------------------------------------------------------------
    -- On recherche si la société a été la société réceptrice d'une fusion
    ----------------------------------------------------------------------
    Begin
        Select count(*)
        Into   Vn_Nombre
        From   Dka_Stransco_Headers Dsh,
               Dka_Stransco_Lines   Dsl
        Where  Dsh.Set_Name = 'FUSION_SOCIETE_VERS_SOCIETE'
        And    Dsh.Set_Id   = Dsl.Set_Id
        And    Return_Value = Pv_Societe
        And    Trunc(Start_Date, 'YYYY') Between Trunc(Vd_Period_From_Pod, 'YYYY')
                                         And     Trunc(Vd_Period_To_Pcd, 'YYYY');
        
        If Vn_Nombre = 0 Then
           Vc_Fusion := 'N';
        Else
           Vc_Fusion := 'O';
        End If;
    End;

    -------------------------------------------
    -- Boucle de lecture des immobilisations --
    -------------------------------------------
    Open Cur_Immo (Vc_Book_Type_Code, Pv_Societe, Pv_Centre_Gestion, Vn_Period_From_Pc,
                   Vd_Period_From_Pod, Vd_Period_To_Pcd);
    Loop
        Fetch Cur_Immo Into Rec_Immo;
        Exit When Cur_Immo%NotFound;

        Vn_Amortissement_Debut      := 0;
        Vn_Reevaluation_Exercice    := 0;
        Vn_Diminution_Amortissement := 0;
        Vn_Dotations_Exercice       := 0;

        If Rec_Immo.Asset_Id <> -1 Then
        
           If Vc_Fusion = 'O' Then
              Begin
                  -- On recherche si l'immobilisation fait partie des immos "fusionnées"
                  Select 'X'
                  Into   Vc_Dummy
                  From   Fa_Asset_Invoices Fai
                  Where  Fai.Asset_Id = Rec_Immo.Asset_Id
                  And    Fai.Feeder_System_Name = 'FUSION'
                  And    Trunc(Fai.Date_Effective, 'YYYY') Between Trunc(Vd_Period_From_Pod, 'YYYY')
                                                           And     Trunc(Vd_Period_To_Pcd, 'YYYY');
                   
                  -- On recherche l'immobilisation d'origine
                  Select Fab.Asset_Id, 
                         Dsl.Params_Value
                  Into   Vn_Old_Asset_Id,
                         Vc_Old_Company_Name
                  From   Fa_Additions_B       Fab,
                         Dka_Stransco_Headers Dsh,
                         Dka_Stransco_Lines   Dsl
                  Where  Dsh.Set_Name    = 'FUSION_SOCIETE_VERS_SOCIETE'
                  And    Dsh.Set_Id      = Dsl.Set_Id
                  And    Dsl.Return_Value = Pv_Societe
                  And    Trunc(Dsl.Start_Date, 'YYYY') Between Trunc(Vd_Period_From_Pod, 'YYYY')
                                                       And     Trunc(Vd_Period_To_Pcd, 'YYYY')
                  And    Fab.Asset_Number = Substr(Rec_Immo.Asset_Number, 1, Instr(Rec_Immo.Asset_Number, '-'||Dsl.Param1_Value, 1)-1)
                  And    Instr(Rec_Immo.Asset_Number, '-'||Dsl.Param1_Value, 1) > 0;
                  
                  -- On recherche le livre comptable d'origine
                  Select Fbc.Book_Type_Code
                  Into   Vc_Old_Book_Type_Code
                  From   Fa_Book_Controls           Fbc,
                         Hr_All_Organization_Units  Haou
                  Where  Fbc.Org_Id        = Haou.Organization_Id
                  And    Fbc.Book_Class = 'CORPORATE'
                  And    Haou.Name      = Vc_Old_Company_Name
                  And    Fbc.Book_Type_Code Like Vc_Old_Company_Name || '%COMPTABLE';
                  
              Exception
                  When Others Then
                       Vn_Old_Asset_Id       := Rec_Immo.Asset_Id;
                       Vc_Old_Book_Type_Code := Vc_Book_Type_Code;
                                                           
              End;
           End If;                                                

           --------------------------------------------------------
           -- Recherche de la valeur de l'amortissement de début --
           --------------------------------------------------------
           Begin
               --Select Nvl(Fdd.Deprn_Reserve, 0)
               --Into   Vn_Amortissement_Debut
               --From   Fa_Deprn_Detail Fdd
               --Where  Fdd.Book_Type_Code  = Vc_Book_Type_Code
               --And    Fdd.Asset_Id        = Rec_Immo.Asset_Id
               --And    Fdd.Distribution_Id = Rec_Immo.Distribution_Id
               --And    Fdd.Period_Counter  = ( Select Max(Fdd2.Period_Counter)
               --                               From   Fa_Deprn_Detail Fdd2
               --                               Where  Fdd2.Book_Type_Code  = Fdd.Book_Type_Code
               --                               And    Fdd2.Asset_Id        = Fdd.Asset_Id
               --                               And    Fdd2.Distribution_Id = Fdd.Distribution_Id
               --                               And    Fdd2.Period_Counter <= (Vn_Period_From_Pc - 1) );
               Select Nvl(Fds.Deprn_Reserve, 0)
               Into   Vn_Amortissement_Debut
               From   Fa_Deprn_Summary Fds
               --Where  Fds.Book_Type_Code  = Vc_Book_Type_Code
               --And    Fds.Asset_Id        = Rec_Immo.Asset_Id
               Where  Fds.Book_Type_Code In ( Vc_Book_Type_Code, Vc_Old_Book_Type_Code )
               And    Fds.Asset_Id       In ( Rec_Immo.Asset_Id, Vn_Old_Asset_Id )
               And    Fds.Period_Counter  = ( Select Max(Fds2.Period_Counter)
                                              From   Fa_Deprn_Summary Fds2
                                              Where  Fds2.Book_Type_Code  = Fds.Book_Type_Code
                                              And    Fds2.Asset_Id        = Fds.Asset_Id
                                              And    Fds2.Period_Counter  < Vn_Period_From_Pc );
           Exception
               When Others Then
                    Vn_Amortissement_Debut := 0;
           End;

           -----------------------------------------------------------
           -- Recherche des valeurs de réévaluation et de dotations --
           -----------------------------------------------------------
           Begin
               --Select Nvl(Sum(Nvl(Reval_Amortization, 0)), 0),
               --       Nvl(Sum(Nvl(Deprn_Amount, 0)), 0)
               --Into   Vn_Reevaluation_Exercice,
               --       Vn_Dotations_Exercice
               --From   Fa_Deprn_Detail
               --Where  Book_Type_Code  = Vc_Book_Type_Code
               --And    Asset_Id        = Rec_Immo.Asset_Id
               --And    Period_Counter  Between Vn_Period_From_Pc
               --                       And     Vn_Period_To_Pc;
               --And    Distribution_Id = Rec_Immo.Distribution_Id;
               Select Nvl(Sum(Nvl(Reval_Amortization, 0)), 0),
                      Nvl(Sum(Nvl(Deprn_Amount, 0)), 0)
               Into   Vn_Reevaluation_Exercice,
                      Vn_Dotations_Exercice
               From   Fa_Deprn_Summary
               --Where  Book_Type_Code  = Vc_Book_Type_Code
               --And    Asset_Id        = Rec_Immo.Asset_Id
               Where  Book_Type_Code In ( Vc_Book_Type_Code, Vc_Old_Book_Type_Code )
               And    Asset_Id       In ( Rec_Immo.Asset_Id, Vn_Old_Asset_Id )
               And    Period_Counter  Between Vn_Period_From_Pc
                                      And     Vn_Period_To_Pc;
           End;
        End If;

        ----------------------------------------------------------------------------
        -- Calcul de la diminution d'amortissement si l'immobilisation a été cédé --
        ----------------------------------------------------------------------------
        --If Rec_Immo.Date_Cession Is Not Null Then
        --   Begin
        --       Select Nvl(Fdd.Deprn_Reserve, 0)
        --       Into   Vn_Diminution_Amortissement
        --       From   Fa_Deprn_Detail Fdd
        --       Where  Fdd.Book_Type_Code  = Vc_Book_Type_Code
        --       And    Fdd.Asset_Id        = Rec_Immo.Asset_Id
        --       And    Fdd.Distribution_Id = Rec_Immo.Distribution_Id
        --       And    Fdd.Period_Counter  = ( Select Max(Fdd2.Period_Counter)
        --                                      From   Fa_Deprn_Detail  Fdd2,
        --                                             Fa_Deprn_Periods Fdp
        --                                      Where  Fdd2.Book_Type_Code            = Fdd.Book_Type_Code
        --                                      And    Fdd2.Asset_Id                  = Fdd.Asset_Id
        --                                      And    Fdd2.Distribution_Id           = Fdd.Distribution_Id
        --                                      And    Fdd2.Book_Type_Code            = Fdp.Book_Type_Code
        --                                      And    Fdd2.Period_Counter            = Fdp.Period_Counter
        --                                      And    Fdp.Calendar_Period_Close_Date < Rec_Immo.Date_Cession );
        --   Exception
        --       When Others Then
        --            Vn_Diminution_Amortissement := 0;
        --   End;
        --End If;

-- MODIF PHENIX 23_03_05 DEBUT

/*        If Rec_Immo.Date_Cession Is Not Null Then
           If Rec_Immo.Date_Cession Between Vd_Period_From_Pod And Vd_Period_To_Pcd Then
              Vn_Diminution_Amortissement := Rec_Immo.Diminution_Amortissement;
           End If;
        End If;*/

        Select   Nvl(sum(Nvl(Frv.Unrevalued_Cost_Retired, 0) - Nvl(Frv.Nbv_Retired, 0)),0)
        into     Vn_Diminution_Amortissement
        From     Fa_retirements_v frv
        Where    Rec_Immo.Asset_Id = Frv.Asset_Id(+)
        And      Vc_Book_Type_Code            = Frv.Book_Type_Code(+)
        And      Trunc(Nvl(Frv.date_Retired, Vd_Period_From_Pod)) >= Trunc(Vd_Period_From_Pod)
        And      Nvl(Frv.Status,' ')           != 'DELETED'
        And      Frv.date_Retired Between Vd_Period_From_Pod And Vd_Period_To_Pcd;

-- MODIF PHENIX 23_03_05 FIN

        ----------------------------------
        -- Insertion dans Dka_Amor_Fisc --
        ----------------------------------
        Insert Into Dka_Amor_Fisc
             ( Set_Of_Books_Id,
               Request_Id,
               Debug_Mode,
               Code_Cate,
               Desc_Cate,
               Code_Immo,
               Desc_Immo,
               Asset_Id,
               Distribution_Id,
               Amortissement_Debut,
               Reevaluation_Exercice,
               Dotations_Exercice,
               Diminution_Amortissement,
               Created_By,
               Creation_Date,
               Last_Updated_By,
               Last_Update_Date )
        Values
             ( Pn_Set_Of_Books_Id,                   --Set_Of_Books_Id
               Pn_Conc_Request_Id,                   --Request_Id
               Pv_Debug_Mode,                        --Debug_Mode
               Rec_Immo.Code_Cate,                   --Code_Cate
               Rec_Immo.Desc_Cate,                   --Desc_Cate
               Rec_Immo.Code_Immo,                   --Code_Immo
               Rec_Immo.Desc_Immo,                   --Desc_Immo
               Rec_Immo.Asset_Id,                    --Asset_Id
               Rec_Immo.Distribution_Id,             --Distribution_Id
               Vn_Amortissement_Debut,               --Amortissement_Debut
               Vn_Reevaluation_Exercice,             --Reevaluation_Exercice
               Vn_Dotations_Exercice,                --Dotations_Exercice
               Vn_Diminution_Amortissement,          --Diminution_Amortissement
               Pn_User_Id,                           --Created_By
               Sysdate,                              --Creation_Date
               Pn_User_Id,                           --Last_Updated_By
               Sysdate );                            --Last_Update_Date

    End Loop;

    Commit;

Exception
    When Others Then
         Pn_Code_Retour    := SqlCode;
         Pv_Message_Erreur := Substr(SqlErrm, 1, 250);

End Insert_Data;


-----------------------------------------------------------------
--  Nom           : Delete_Data
--  Description   :
--
--  PARAMETRES :
--     Pn_Set_Of_Books_Id  Entrée                  Set Of Books
--     Pn_Conc_Request_Id  Entrée                  Id Traitement
--     Pv_Debug_Mode       Entrée                  Mode Debug
--     Pn_Code_Retour      Entrée/Sortie           Code Retour
--     Pv_Message_Erreur   Entrée/Sortie           Message Erreur
-----------------------------------------------------------------
Procedure Delete_Data ( Pn_Set_Of_Books_Id  In     Number,
                        Pn_Conc_Request_Id  In     Number,
                        Pv_Debug_Mode       In     Varchar2,
                        Pn_Code_Retour      In Out Number,
                        Pv_Message_Erreur   In Out Varchar2 )
Is
Begin
    Begin
        Delete From DKA_AMOR_FISC
        Where  Set_Of_Books_Id = Pn_Set_Of_Books_Id
        And    Request_Id      = Pn_Conc_Request_Id
        And    Debug_Mode      = 'N';
    End;

    Commit;

End Delete_Data;


End DKA_AMOR_FISC_PKG; -- Package body

/
Show Error

Exit;


