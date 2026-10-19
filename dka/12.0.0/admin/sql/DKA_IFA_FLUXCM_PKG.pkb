create or replace package body DKA_IFA_FLUXCM_PKG

AS
--------------------------------------------------------------------------------
-- $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_IFA_FLUXCM_PKG
-- Description      : Body du package DKA_IFA_FLUXCM_PKG
-- Auteur           : C.Defaux
-- Date de création : 28/10/2011
-- Doc. associée    :
-- Commentaires     : 
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 05/09/2011 EMA Prise en compte des remarques de D.Oblin suite à la recette
-- 24/10/2016 HDE Migration R12 Helios
-- 08/12/2016 PBR artf2062660: Ajout du task_number dans le fichier de sortie.
-- 03/01/2017 NBO artf2062660 - SPE049 - Ajout tâche et modification centre de gestion
-- 10/01/2017 YWA artf2079733 - Modifier le nom du fichier de sortie 
-- 22/06/2017 OBE artf2180188 : SPE049 - Gestion en cas d'erreur sur périodes FA - defect BeB # 834
--------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TYPES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SUBTYPE T_CODE_SOCIETE is varchar2(100); 

TYPE REC_SOCIETE is record (
    societe                          T_CODE_SOCIETE,
    Book_type_code                   Fa_Book_Controls.book_type_code%type,
    Period_From_Pc                   Fa_Deprn_Periods.Period_Counter%TYPE,
    Period_From_Pod                  Fa_Deprn_Periods.Calendar_Period_Open_Date%TYPE,
    Period_From_Pcd                  Fa_Deprn_Periods.Calendar_Period_Close_Date%TYPE,
    Period_To_Pc                     Fa_Deprn_Periods.Period_Counter%TYPE,
    Period_To_Pod                    Fa_Deprn_Periods.Calendar_Period_Open_Date%TYPE, 
    Period_To_Pcd                    Fa_Deprn_Periods.Calendar_Period_Close_Date%TYPE, 
    fusion                           boolean
);

type TAB_CACHE_SOCIETE is table of REC_SOCIETE index by T_CODE_SOCIETE;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TYPES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
g_cache_societe TAB_CACHE_SOCIETE;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CURSEURS
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --------------------------------------------
    -- Curseur de lecture des immobilisations --
    --------------------------------------------
    CURSOR Cur_Immo (Pv_Period_From VARCHAR2, Pv_Period_To VARCHAR2, pv_region in varchar2, p_security_profile_id in number) IS
with regions as (
      -- Les codes régions accessibles depuis le profil de sécurité courant 
      SELECT substr(hou.name, 1, 3) as code_region
      FROM per_security_profiles      psp   
      JOIN per_organization_list      pol   ON (pol.security_profile_id   = psp.security_profile_id) 
      JOIN hr_operating_units         hou   ON (hou.organization_id       = pol.organization_id)
      WHERE nvl(hou.usable_flag, 'Y')='Y'
        and psp.security_profile_id= p_security_profile_id
        and pol.user_id  is null
        and sysdate between nvl(hou.date_from, sysdate) and nvl(hou.date_to, sysdate)+1
    ), 
    rub_principale as (
      -- La liste des rubriques principales (segment 1) de la clé catégorie FA
      SELECT SEGMENT_NAME, APPLICATION_COLUMN_NAME,SEGMENT_NUM,DISPLAY_FLAG, ffv.flex_value, ffv.flex_value_meaning, ffv.description
      FROM FND_ID_FLEX_SEGMENTS_VL   fifs
      JOIN FND_FLEX_VALUES_VL        ffv on (fifs.flex_value_set_id = ffv.flex_value_set_id)
      WHERE fifs.ID_FLEX_NUM=101 
      and fifs.ID_FLEX_CODE='CAT#' 
      and fifs.APPLICATION_ID=140 
      and fifs.application_column_name='SEGMENT1'
    ), 
    compte_local as (
      -- Les comptes comptables et leur attribut 6 (catégorie d'immo)
      select ffvs.flex_value_set_name,  ffv.flex_value, ffv.description
      from fnd_flex_values_vl  ffv
      join fnd_flex_value_sets ffvs on (ffv.flex_value_set_id = ffvs.flex_value_set_id)
      where ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
    ),
    assets as (
    SELECT DISTINCT project_id, task_id, asset_id 
    FROM fa_asset_invoices) --artf2062660
    -- requête principale
    select 
      Gcc1.Segment1                   Societe,                                                                         
      Gcc1.Segment2                   Centre_De_Gestion,                                                               
      Pv_Period_From                  Periode_Debut_Amortissement,                                                     
      Pv_Period_To                    Periode_Fin_Amortissement,                                                       
      Fbc.Book_Type_Code              Livre_Comptable, 
      gcc.segment3                    Compte,                                                                          
      cpt.Description                 Libelle_Compte,
      r.flex_value_meaning            Code_Categorie,                                                                                   
      r.Description                   Categorie_Immobilisation,                                                        
      Fb.Asset_Id                     Asset_Id,                                                                  
      Fab.Asset_Number                Numero_Immo,                                                                     
      Fab.Description                 Libelle_Immo,                                                                    
      Gcc1.Segment2                   Code_Etablissement,                                                              
      Ppa.Segment1                    Projet,                                                                          
      Fb.Date_Placed_In_Service       Date_De_Mise_En_Service,                                                         
      Fb.Life_In_Months               Duree_Amortissement,                                                             
      Fb.Deprn_Method_Code            Type_Amortissement,                                                              
      Fb.Cost                         Valeur_Origine,                                                                  
      Fth.Transaction_Header_Id       Transaction_Header_Id,
      null                            old_book_type_code,
      null                            old_Asset_id,
      null                            Val_Debut_Periode,
      null                            Val_Fin_Periode,
      null                            Val_Cumule,
      null                            Val_Residuelle,
      pt.task_number                  Tache --artf2062660
    from Fa_Books                        Fb                                                                              
    join Fa_Book_Controls                Fbc on (Fb.Book_Type_Code             = Fbc.Book_Type_Code)                                                                             
    join Fa_Additions                    Fab on (Fb.Asset_Id                   = Fab.Asset_Id)
    join FA_CATEGORIES_B_KFV             fc  on (fc.category_id                = fab.ASSET_CATEGORY_ID)
    join rub_principale                  r   on (r.flex_value                  = fc.segment1)
    join Fa_Transaction_Headers          Fth on (Fth.Asset_Id                  = Fb.Asset_Id                                                                      
                                                 AND Fth.Book_Type_Code        = Fb.Book_Type_Code                                                                
                                                 AND Fth.Transaction_Header_Id >= Fb.Transaction_Header_Id_In                                                      
                                                 AND Fth.Transaction_Header_Id < Nvl(Fb.Transaction_Header_Id_Out, Fth.Transaction_Header_Id+1))                                             
    join Fa_Asset_History                Fah on (Fth.Asset_Id                  = Fah.Asset_Id                                                                     
                                                 AND Fth.Transaction_Header_Id >= Fah.Transaction_Header_Id_In                                                     
                                                 AND Fth.Transaction_Header_Id <  Nvl(Fah.Transaction_Header_Id_Out, Fth.Transaction_Header_Id+1) )                                                                             
    join Fa_Category_Books               Fcb on (Fcb.Category_Id               = Fah.Category_Id                                                                  
                                                 AND Fcb.Book_Type_Code        = Fbc.Book_Type_Code)                                                                            
    join Gl_Code_Combinations            Gcc on (Fcb.Asset_Cost_Account_Ccid   = Gcc.Code_Combination_Id)                                                                          
    join Fa_Distribution_History         Fdh on (Fth.Asset_Id                  = Fdh.Asset_Id                                                                     
                                                 AND Fth.Transaction_Header_Id >= Fdh.Transaction_Header_Id_In                                                     
                                                 AND Fth.Transaction_Header_Id <  Nvl(Fdh.Transaction_Header_Id_Out, Fth.Transaction_Header_Id+1)) 
    join Gl_Code_Combinations            Gcc1 on (Fdh.Code_Combination_Id       = Gcc1.Code_Combination_Id and Fb.Book_Type_Code LIKE  Gcc1.Segment1 || '%') 
    join assets                          ass  on (ass.asset_id = Fab.asset_id) --artf2062660
    join pa_tasks                        pt   on (ass.task_id = pt.task_id)    --artf2062660
    left outer join Pa_Projects_All      Ppa  on (pt.project_id = Ppa.Project_Id and ass.project_id = ppa.project_id) --artf2062660
    left outer join compte_local         cpt  on (cpt.flex_value = gcc.segment3)
    where 1=1
      AND Nvl(Fbc.Date_Ineffective, Trunc(Sysdate)) >= Trunc(Sysdate)  
      and (Gcc1.Segment2 = Pv_Region or Pv_Region is null and Gcc1.Segment2 in (select code_region from regions))
      AND Fth.Transaction_Header_Id = ( SELECT Max(Fth1.Transaction_Header_Id)                                                
                                        FROM   Fa_Transaction_Headers Fth1,                                                   
                                               Fa_Deprn_Periods       Fdp                                                     
                                        WHERE  Fth1.Asset_Id                  = Fth.Asset_Id                                  
                                        AND    Fth1.Book_Type_Code            = Fth.Book_Type_Code         
                                        AND    Fth1.Book_Type_Code            = Fdp.Book_Type_Code                            
                                        AND    Fdp.Period_Name                = Pv_Period_To                                  
                                        AND    Fth1.Transaction_Date_Entered <= Nvl(Fdp.Calendar_Period_Close_Date, Sysdate) ) --24132 )    
      AND Fth.Transaction_Type_Code    != 'FULL RETIREMENT'    
    ORDER BY Centre_De_Gestion, Societe, Code_Categorie, Categorie_Immobilisation, Compte, Libelle_Compte, Asset_Id;
    
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES 
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    ------------------------------------------------------------------------------------
    procedure check_setup(pv_directory in varchar2)
    is
    begin
      -- directories
      dka_tools_pkg.check_directory(pv_directory);     
      
      -- Jeux de valeurs
      dka_tools_pkg.check_value_set('DAOPCCF_STE');
    
    end check_setup;

    ------------------------------------------------------------------------------------
    -- Nom              : Get_Info
    -- Description      : Fonction de recherche des infos liées à la société
    --
    -- PARAMETRES       : Pv_Societe     Entrée        Société
    --                    Pv_Period_From Entrée        Période début
    --                    Pv_Period_To   Entrée        Période fin
    --
    -- VALEUR RETOURNEE :
    --     Description       : Société ayannt fais l'objet d'une fusion
    --     Valeurs possibles : TRUE ou FALSE
    ------------------------------------------------------------------------------------
    FUNCTION Get_Info(Pv_Societe     IN VARCHAR2,
                      Pv_Period_From IN VARCHAR2,
                      Pv_Period_To   IN VARCHAR2) RETURN REC_SOCIETE 
    IS
      Vn_Nombre                     NUMBER(15);
      v_result                      REC_SOCIETE;
    BEGIN
        Dka_Tools_Pkg.Put_Log_Message('(+) Get_Info');
        Dka_Tools_Pkg.Put_Log_Message('==> Pv_Societe     : ' || Pv_Societe);
        Dka_Tools_Pkg.Put_Log_Message('==> Pv_Period_From : ' || Pv_Period_From);
        Dka_Tools_Pkg.Put_Log_Message('==> Pv_Period_To   : ' || Pv_Period_To);
        
        if g_cache_societe.exists(Pv_Societe) then
          return g_cache_societe(Pv_Societe);
        end if;
    
        BEGIN -- OBE artf2180188
          SELECT Book_Type_Code
          INTO   v_result.Book_Type_Code
          FROM   Fa_Book_Controls Fbc
          WHERE  Rownum = 1
          AND    Book_Type_Code LIKE Pv_Societe || '%'
          AND    Nvl(Date_Ineffective, Trunc(SYSDATE)) >= Trunc(SYSDATE);
          Dka_Tools_Pkg.Put_Log_Message('====> Vv_Book_Type_Code  : ' || v_result.Book_Type_Code);
        --< OBE artf2180188  
        EXCEPTION         
         WHEN OTHERS THEN
            Dka_Tools_Pkg.Put_Log_Message('====> Impossible de déterminer le code du Livre comptable');
            v_result.Book_Type_Code := NULL;
        END;
        --> OBE artf2180188

        
        BEGIN -- OBE artf2180188        
          SELECT Period_Counter,
                 Calendar_Period_Open_Date,
                 Nvl(Calendar_Period_Close_Date, Sysdate)
          INTO   v_result.Period_From_Pc,
                 v_result.Period_From_Pod,
                 v_result.Period_From_Pcd
          FROM   Fa_Deprn_Periods
          WHERE  Book_Type_Code = v_result.Book_Type_Code
          AND    Rownum         = 1
          AND    Calendar_Period_Open_Date >= (SELECT Start_Date
                                               FROM   Fa_Calendar_Periods
                                               WHERE  Period_Name = Pv_Period_From
                                               AND    Rownum      = 1)
          ORDER BY Period_Counter;
          Dka_Tools_Pkg.Put_Log_Message('====> Gn_Period_From_Pc  : ' || v_result.Period_From_Pc);
          Dka_Tools_Pkg.Put_Log_Message('====> Gd_Period_From_Pod : ' || v_result.Period_From_Pod);
          Dka_Tools_Pkg.Put_Log_Message('====> Period_from_Pcd : ' || v_result.Period_From_Pcd);
        
        --< OBE artf2180188  
        EXCEPTION         
         WHEN OTHERS THEN
            Dka_Tools_Pkg.Put_Log_Message('====> Impossible de déterminer la période de début pour ce livre');
            v_result.Period_From_Pc := NULL;
            v_result.Period_From_Pod := NULL;
            v_result.Period_From_Pcd := NULL;
        END;
        --> OBE artf2180188        
    
        BEGIN -- OBE artf2180188        
        
          SELECT Period_Counter,
                 Calendar_Period_Open_Date,
                 Nvl(Calendar_Period_Close_Date, Sysdate)
          INTO   v_result.Period_To_Pc,
                 v_result.Period_To_Pod,
                 v_result.Period_To_Pcd
          FROM   Fa_Deprn_Periods
          WHERE  Book_Type_Code = v_result.Book_Type_Code
          AND    Rownum         = 1
          AND    Calendar_Period_Close_Date >= (SELECT End_Date
                                                FROM   Fa_Calendar_Periods
                                                WHERE  Period_Name = Pv_Period_To
                                                AND    Rownum      = 1)
          ORDER BY Period_Counter;
          Dka_Tools_Pkg.Put_Log_Message('====> Gn_Period_To_Pc  : ' || v_result.Period_To_Pc);
          Dka_Tools_Pkg.Put_Log_Message('====> Gd_Period_To_Pod : ' || v_result.Period_To_Pod);
          Dka_Tools_Pkg.Put_Log_Message('====> Period_To_Pcd : ' || v_result.Period_To_Pcd);
        
        --< OBE artf2180188  
        EXCEPTION         
         WHEN OTHERS THEN
            Dka_Tools_Pkg.Put_Log_Message('====> Impossible de déterminer la période de fin pour ce livre');
            v_result.Period_To_Pc := NULL;
            v_result.Period_To_Pod := NULL;
            v_result.Period_To_Pcd := NULL;
        END;
        --> OBE artf2180188            
    
        -----------------------------------------------------------------------------
        -- On recherche si la société demandée a été a été la société destinatrice --
        -- d'une fusion durant la période demandée                                 --
        -----------------------------------------------------------------------------
        SELECT COUNT(*)
        INTO   Vn_Nombre                                                            
        FROM   Dka_Stransco_Headers Dsh,                                            
               Dka_Stransco_Lines  Dsl                                              
        WHERE  Dsh.Set_Name     = 'FUSION_SOCIETE_VERS_SOCIETE'                     
        AND    Dsh.Set_Id       = Dsl.Set_Id                                        
        AND    Dsl.Return_Value = Pv_Societe                                        
        AND    Trunc(Dsl.Start_Date, 'YYYY') Between Trunc(v_result.Period_From_Pod, 'YYYY')
                                             And     Trunc(v_result.Period_To_Pcd, 'YYYY'); 
                                             
        IF Vn_Nombre = 0 THEN
           Dka_Tools_Pkg.Put_Log_Message('====> Société n''ayant pas fait l''objet d''une fusion');
           Dka_Tools_Pkg.Put_Log_Message('(-) Get_Info');
           v_result.fusion := FALSE;
        ELSE
           Dka_Tools_Pkg.Put_Log_Message('====> Société ayant fait l''objet d''une fusion');
           Dka_Tools_Pkg.Put_Log_Message('(-) Get_Info');
           v_result.fusion := TRUE;
        END IF;
        
        g_cache_societe(Pv_Societe) := v_result;
        RETURN v_result;

    END Get_Info;
    
    
    ------------------------------------------------------------------------------------
    -- Nom              : Get_Old_Asset
    -- Description      : Dans le cas où la société a fait l'objet d'une fusion, 
    --                    on recherche l'immobilisation dans le livre comptable 
    --                    de la société dont elle dépendait précédemment. 
    --
    -- PARAMETRES       : p_societe
    --                    p_immo
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    ------------------------------------------------------------------------------------
    PROCEDURE Get_Old_Asset (p_societe in REC_SOCIETE, p_immo in out nocopy cur_immo%ROWTYPE) 
    IS
        Vc_Dummy                        VARCHAR2(1);                           
        Vv_Old_Company_Name             Hr_All_Organization_Units.Name%TYPE;   
    BEGIN

        Dka_Tools_Pkg.Put_Log_Message('(+) Get_Old_Asset');
        Dka_Tools_Pkg.Put_Log_Message('==> Societe           : ' || p_immo.Societe);
        Dka_Tools_Pkg.Put_Log_Message('==> Livre_comptable   : ' || p_immo.Livre_comptable);
        Dka_Tools_Pkg.Put_Log_Message('==> Asset_Id          : ' || p_immo.Asset_Id);
        Dka_Tools_Pkg.Put_Log_Message('==> Asset_Number      : ' || p_immo.Numero_Immo);

        ---------------------------------------------------------------
        -- On recherche si l'immo fait partie des immos "fusionnées" --
        ---------------------------------------------------------------
        BEGIN            
            SELECT 'X'
            INTO   Vc_Dummy 
            FROM   Fa_Asset_Invoices Fai
            WHERE  Fai.Asset_Id           = p_immo.Asset_Id
            AND    Fai.Feeder_System_Name = 'FUSION'
            AND    Trunc(Fai.Date_Effective, 'YYYY') BETWEEN Trunc(p_societe.Period_From_Pod, 'YYYY')
                                                     AND     Trunc(p_societe.Period_To_Pcd, 'YYYY');
            
            Dka_Tools_Pkg.Put_Log_Message('====> Vc_Dummy              : '||Vc_Dummy);
            
            ------------------------------------------------                          
            -- On recherche l'immo d'origine de la fusion --
            ------------------------------------------------                          
            SELECT Asset_Id, 
                   Dsl.Param1_Value
            INTO   p_immo.Old_Asset_Id, 
                   Vv_Old_Company_Name
            FROM   Fa_Additions_B       Fab,
                   Dka_Stransco_Headers Dsh,
                   Dka_Stransco_Lines   Dsl
            WHERE  Dsh.Set_Name     = 'FUSION_SOCIETE_VERS_SOCIETE'
            AND    Dsh.Set_Id       = Dsl.Set_Id
            AND    Dsl.Return_Value = p_immo.Societe
            AND    Trunc(Dsl.Start_Date, 'YYYY') BETWEEN Trunc(p_societe.Period_From_Pod, 'YYYY')
                                                 AND     Trunc(p_societe.Period_To_Pcd, 'YYYY')
            AND    Fab.Asset_Number = Substr(p_immo.Numero_Immo, 1, Instr(p_immo.Numero_Immo, '-' || Dsl.Param1_Value, 1)-1)
            AND    Instr(p_immo.Numero_Immo, '-' || Dsl.Param1_Value, 1) > 0;
            
            Dka_Tools_Pkg.Put_Log_Message('====> Old_Asset_Id          : '|| p_immo.Old_Asset_Id);
            Dka_Tools_Pkg.Put_Log_Message('====> Vv_Old_Company_Name   : '|| Vv_Old_Company_Name);
            
            --------------------------------------------
            -- Recherche du livre comptable d'origine --
            --------------------------------------------
            SELECT Fbc.Book_Type_Code
            INTO   p_immo.Old_Book_Type_Code
            FROM   Fa_Book_Controls Fbc,
                   Hr_All_Organization_Units Haou
            WHERE  Fbc.Org_Id     = Haou.Organization_Id
            AND    Fbc.Book_Class = 'CORPORATE'
            AND    Haou.Name      = Vv_Old_Company_Name
            AND    Fbc.Book_Type_Code Like Vv_Old_Company_Name ||'%COMPTABLE';
            
            Dka_Tools_Pkg.Put_Log_Message('====> Old_Book_Type_Code : '|| p_immo.Old_Book_Type_Code);            
        EXCEPTION
            WHEN OTHERS THEN
                p_immo.Old_Book_Type_Code := null;
                p_immo.Old_Asset_Id       := null;
        END;  

        
        Dka_Tools_Pkg.Put_Log_Message('====> Gv_Old_Book_Type_Code : ' || p_immo.Old_Book_Type_Code);
        Dka_Tools_Pkg.Put_Log_Message('====> Gn_Old_Asset_Id       : ' || p_immo.Old_Asset_Id);
                    
        Dka_Tools_Pkg.Put_Log_Message('(-) Get_Old_Asset');      
    END Get_Old_Asset;


    ------------------------------------------------------------------------------------
    -- Nom              : Val_Debut_Periode
    -- Description      : Fonction de la calcul de la valeur de l'immo en 
    --                    début de période 
    --
    -- PARAMETRES       : p_societe
    --                    p_immo
    --
    -- VALEUR RETOURNEE :
    --     Description       : Valeur de début de période
    --     Valeurs possibles :
    ------------------------------------------------------------------------------------
    FUNCTION Val_Debut_Periode (p_societe in REC_SOCIETE, p_immo in cur_immo%ROWTYPE) RETURN NUMBER 
    IS
        Vn_Deprn_Reserve                Fa_Deprn_Detail.Deprn_Reserve%TYPE;
        Vn_Period_Counter               Fa_Deprn_Detail.Period_Counter%TYPE;
        Vn_Count                        NUMBER;
      
        ------------------------------------------------------------------
        -- Curseur de calcul de la valeur de l'immo en début de période --
        ------------------------------------------------------------------
        CURSOR Cur_Reserve (p_societe in REC_SOCIETE, p_immo in cur_immo%ROWTYPE, Pn_Period_Counter NUMBER) IS
            SELECT Fdd.Deprn_Reserve
            FROM   Fa_Deprn_Detail         Fdd,
                   Fa_Distribution_History Fdh
            WHERE  Fdd.Book_Type_Code  IN (P_immo.Livre_comptable, p_immo.Old_Book_Type_Code)
            AND    Fdd.Asset_Id        IN (p_immo.Asset_Id, p_immo.Old_Asset_Id)
            AND    Fdd.Period_Counter  BETWEEN Nvl(Pn_Period_Counter,0) AND Nvl(p_societe.Period_To_Pc,0)
            AND    Fdd.Distribution_Id = Fdh.Distribution_Id
            ORDER BY Fdd.Period_Counter ASC, Nvl(Fdh.Date_Ineffective, Sysdate) DESC, Fdd.Distribution_Id DESC;
      
        ------------------------------------------------------------------
        -- Curseur de calcul de la valeur de l'immo en début de période --
        -- dans la cas où elle a fait l'objet d'une cession partielle   --
        ------------------------------------------------------------------
        CURSOR Cur_Reserve_Prorata (p_societe in REC_SOCIETE, p_immo in cur_immo%ROWTYPE, Pn_Period_Counter NUMBER) IS
            SELECT (p_immo.Valeur_Origine/Decode(Fdd.Cost, 0, Decode(p_immo.Valeur_Origine, 0, 1, p_immo.Valeur_Origine), Fdd.Cost)) * Fdd.Deprn_Reserve
            FROM   Fa_Deprn_Detail         Fdd,
                   Fa_Distribution_History Fdh
            WHERE  Fdd.Book_Type_Code  IN (P_immo.Livre_comptable, p_immo.Old_Book_Type_Code)
            AND    Fdd.Asset_Id        IN (p_immo.Asset_Id, p_immo.Old_Asset_Id)
            AND    Fdd.Period_Counter  BETWEEN Nvl(Pn_Period_Counter,0) AND Nvl(p_societe.Period_To_Pc,0)
            AND    Fdd.Distribution_Id = Fdh.Distribution_Id
            ORDER BY Fdd.Period_Counter ASC, Nvl(Fdh.Date_Ineffective, Sysdate) DESC, Fdd.Distribution_Id DESC;
              
    BEGIN
        Dka_Tools_Pkg.Put_Log_Message('(+) Val_Debut_Periode');
        Dka_Tools_Pkg.Put_Log_Message('==> P_immo.Livre_comptable : ' || P_immo.Livre_comptable || ' / ' || p_immo.Old_Book_Type_Code);
        Dka_Tools_Pkg.Put_Log_Message('==> P_immo.Asset_Id        : ' || P_immo.Asset_Id || ' / ' || p_immo.Old_Asset_Id);
        Dka_Tools_Pkg.Put_Log_Message('==> P_immo.Val_Origine     : ' || P_immo.Valeur_Origine);
    
        --------------------------------------
        -- Recherche du pointeur de période --
        --------------------------------------
        BEGIN
            SELECT Max(Fdd.Period_Counter)
            INTO   Vn_Period_Counter
            FROM   Fa_Deprn_Detail Fdd
            WHERE  Fdd.Book_Type_Code IN (P_immo.Livre_comptable, p_immo.Old_Book_Type_Code)      
            AND    Fdd.Asset_Id       IN (p_immo.Asset_Id, p_immo.Old_Asset_Id)
            AND    Fdd.Period_Counter < Nvl(p_societe.Period_From_Pc, 0);
            
        EXCEPTION
            WHEN OTHERS THEN
                Vn_Period_Counter := p_societe.Period_From_Pc;
        END;
        Dka_Tools_Pkg.Put_Log_Message('====> Vn_Period_Counter : '|| Vn_Period_Counter);
      
        ----------------------------------------------------------------------------
        -- On cherche sur la période demandée si l'immo a été partiellement cédée --
        -- si c'est le cas on calcule la valeur des amortissements de début       --
        -- au prorata des valeurs                                                 --
        ----------------------------------------------------------------------------
        Vn_Deprn_Reserve := Null;
        BEGIN 
            SELECT COUNT(Fth.Transaction_Header_Id)
            INTO   Vn_Count
            FROM   Fa_Transaction_Headers Fth
            WHERE  Fth.Book_Type_Code IN (P_immo.Livre_comptable, p_immo.Old_Book_Type_Code)
            AND    Fth.Asset_Id       IN (p_immo.Asset_Id, p_immo.Old_Asset_Id)
            AND    Fth.Transaction_Date_Entered BETWEEN p_societe.Period_From_Pod AND p_societe.Period_To_Pcd
            AND    Fth.Transaction_Type_Code = 'PARTIAL RETIREMENT';
        
            IF Vn_Count > 0 THEN    
               Dka_Tools_Pkg.Put_Log_Message('====> Cession partielle');
               OPEN Cur_Reserve_Prorata(p_societe, p_immo, Vn_Period_Counter);
               FETCH Cur_Reserve_Prorata INTO Vn_Deprn_Reserve;
               CLOSE Cur_Reserve_Prorata;    
            ELSE
               Dka_Tools_Pkg.Put_Log_Message('====> Pas de cession partielle');
               OPEN Cur_Reserve(p_societe, p_immo, Vn_Period_Counter);
               FETCH Cur_Reserve INTO Vn_Deprn_Reserve;
               CLOSE Cur_Reserve;    
            END IF;
          
        END;

        Dka_Tools_Pkg.Put_Log_Message('====> Vn_Deprn_Reserve  : '|| Vn_Deprn_Reserve);
        Dka_Tools_Pkg.Put_Log_Message('(-) Val_Debut_Periode');
      
        RETURN Vn_Deprn_Reserve;
        
    END Val_Debut_Periode;


    ------------------------------------------------------------------------------------
    -- Nom              : Val_Fin_Periode
    -- Description      : Fonction de la calcul de la valeur de l'immo en 
    --                    fin de période 
    --
    -- PARAMETRES       : p_societe
    --                    p_immo
    --
    -- VALEUR RETOURNEE :
    --     Description       : Valeur de début de période
    --     Valeurs possibles :
    ------------------------------------------------------------------------------------
    FUNCTION Val_Fin_Periode (p_societe in REC_SOCIETE, p_immo in cur_immo%ROWTYPE) RETURN NUMBER 
    IS
        Vn_Deprn_Reserve                Fa_Deprn_Detail.Deprn_Reserve%TYPE;
    
        ---------------------------------------------------------
        -- Curseur de recherche de la valeur de fin de période --
        ---------------------------------------------------------
        CURSOR Cur_Reserve (p_societe in REC_SOCIETE, p_immo in cur_immo%ROWTYPE) Is
            SELECT (p_immo.Valeur_Origine/Decode(Fdd.Cost, 0, Decode(p_immo.Valeur_Origine, 0, 1, p_immo.Valeur_Origine), Fdd.Cost)) * Fdd.Deprn_Reserve
            FROM   Fa_Deprn_Detail         Fdd,
                   Fa_Distribution_History Fdh
            WHERE  Fdd.Book_Type_Code  IN (P_immo.Livre_comptable, p_immo.Old_Book_Type_Code)
            AND    Fdd.Asset_Id        IN (p_immo.Asset_Id, p_immo.Old_Asset_Id)
            AND    Fdd.Period_Counter <= Nvl(p_societe.Period_To_Pc, 0)
            AND    Fdd.Distribution_Id = Fdh.Distribution_Id
            ORDER BY Fdd.Period_Counter DESC, Nvl(Fdh.Date_Ineffective, Sysdate) DESC, Fdd.Distribution_Id DESC;
    
    BEGIN
        
        Dka_Tools_Pkg.Put_Log_Message('(+) Val_Fin_Periode');
        Dka_Tools_Pkg.Put_Log_Message('==> P_immo.Livre_comptable : ' || P_immo.Livre_comptable || ' / ' || p_immo.Old_Book_Type_Code);
        Dka_Tools_Pkg.Put_Log_Message('==> P_immo.Asset_Id        : ' || P_immo.Asset_Id || ' / ' || p_immo.Old_Asset_Id);
        Dka_Tools_Pkg.Put_Log_Message('==> P_immo.Valeur_Origine  : ' || P_immo.Valeur_Origine);
        
        Vn_Deprn_Reserve := NULL;
        OPEN Cur_Reserve (p_societe, P_immo);
        FETCH Cur_Reserve INTO Vn_Deprn_Reserve;
        CLOSE Cur_Reserve;    

        Dka_Tools_Pkg.Put_Log_Message('====> Vn_Deprn_Reserve  : '|| Vn_Deprn_Reserve);
        Dka_Tools_Pkg.Put_Log_Message('(-) Val_Fin_Periode');
        
        RETURN Vn_Deprn_Reserve;
    
    END Val_Fin_Periode;

    
    ------------------------------------------------------------------------------------
    -- Nom              : Main
    -- Description      : Procédure principale du traitement 
    --
    -- PARAMETRES       : Pv_Errbuf             Sortie Message d'erreur
    --                    Pn_Retcode            Sortie Code Retour de la procédure
    --                                                 '0' : Normal
    --                                                 '1' : Avertissement
    --                                                 '2' : Erreur
    --                    Pv_Societe     Entrée        Société
    --                    Pv_Region      Entrée        Région
    --                    Pv_Projet      Entrée        Projet
    --                    Pv_Period_From Entrée        Période début
    --                    Pv_Period_To   Entrée        Période fin
    --                    Pv_Compte_From Entrée        Compte début
    --                    Pv_Compte_To   Entrée        Compte fin
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    ------------------------------------------------------------------------------------
    PROCEDURE Main(Pv_Errbuf         OUT VARCHAR2,
                   Pn_Retcode        OUT NUMBER,
                   Pv_Period_From IN     VARCHAR2,
                   Pv_Period_To   IN     VARCHAR2) 
    IS
      Pv_Fic_out_name                 Varchar2(128) := 'IMMOBILISATIONS_' || TO_CHAR(sysdate, 'YYYYMMDD') || '.csv';--  'FOACMFA.TXT' ;-- YWA artf2079733 
      Pv_FicOUTptr	                  UTL_FILE.FILE_TYPE;
      Pv_Dir_out                      Varchar(30)   := 'DKA_IEOARCRM01_DIR' ;
  
      Vv_Region_Utilisateur           Fnd_Profile_Option_Values.Profile_Option_Value%TYPE;
      vn_security_profile_id          per_security_profiles.security_profile_id%type;
      l_info_societe                  REC_SOCIETE;
      l_counter                       pls_integer := 0;
    BEGIN
        check_setup(Pv_Dir_out);
    
        --ouverture fichier de sortie
        Pv_FicOUTptr := UTL_FILE.FOPEN( Pv_Dir_out, Pv_Fic_out_name, 'W', 32764 ) ;
 
        Dka_Tools_Pkg.Put_Log_Message('(+) Main');
        Dka_Tools_Pkg.Put_Log_Message('==> Pv_Period_From : ' || Pv_Period_From);
        Dka_Tools_Pkg.Put_Log_Message('==> Pv_Period_To   : ' || Pv_Period_To);
        
        Pv_Errbuf  := NULL;
        Pn_Retcode := 0;
       

        -- option de profil "DKA : Région d'appartenance de l'utilisateur"
        Vv_Region_Utilisateur := Fnd_Profile.Value('DKA_REGION');
        
        -- 03/01/2017 NBO artf2062660 - SPE049 - Ajout tâche et modification centre de gestion
        --vn_security_profile_id := fnd_profile.value('FA_SECURITY_PROFILE_ID');
        vn_security_profile_id := fnd_profile.value('XLA_MO_SECURITY_PROFILE_LEVEL');

        -----------------------------
        -- modif EMA du 05/09/2011 --
        -- Ecriture de l'entête    --
        -----------------------------        
        UTL_FILE.PUT_LINE( Pv_FicOUTptr,     '"Société";' ||
                                             '"UO Dalkia";' || -- artf2062660
                                             '"Période Début";' ||
                                             '"Période Fin";' ||
                                             '"Livre Comptable";' ||        
                                             '"Catégorie";' ||   
                                             '"Compte";'  ||                     
                                             '"Libellé Compte";' ||             
                                             '"Numéro Immo";' ||                
                                             '"Libellé Immo";' ||               
                                             --Rec_Immo.Code_Etablissement || '";"' ||         
                                             '"Projet";' ||                     
                                             '"Date Mise En Service";' ||    
                                             '"Durée Amortissement";' ||        
                                             '"Type Amortissement";' ||         
                                             '"Valeur Origine";' ||
                                             '"Amortissement Début Période";' ||
                                             '"Amortissement Exercice";' ||
                                             '"Amortissement Cumulé";' ||
                                             '"Valeur Résiduelle";' ||
                                             '"Tâche"'); --artf2062660
          
        
        -------------------------------------------
        -- Boucle de lecture des immobilisations --
        -------------------------------------------
        FOR Rec_Immo in Cur_Immo(Pv_Period_From, Pv_Period_To, Vv_Region_Utilisateur, vn_security_profile_id) LOOP
            Dka_Tools_Pkg.Put_Log_Message('====> Region    :' || Rec_Immo.Centre_De_Gestion);
            
            l_info_societe := get_info(rec_immo.societe, Pv_Period_From, Pv_Period_To);
            
            --< OBE artf2180188
            IF l_info_societe.book_type_code IS NULL
               OR l_info_societe.Period_From_Pc IS NULL
               OR l_info_societe.Period_To_Pc IS NULL
            THEN
                pn_retcode := 1;
                RETURN;
            END IF;
            --> OBE artf2180188

            if l_info_societe.fusion then 
              --------------------------------------------------
              -- Recherche de l'immo dans le cas d'une fusion --
              --------------------------------------------------
              Get_Old_Asset (l_info_societe, Rec_immo);
            end if;
            
            ------------------------------------------------               
            -- Recherche de la valeur de début de période --
            ------------------------------------------------               
            Rec_Immo.Val_Debut_Periode := Val_Debut_Periode(l_info_societe, Rec_immo);

            ----------------------------------------------
            -- Recherche de la valeur de fin de période --
            ----------------------------------------------
            Rec_Immo.Val_Fin_Periode := Val_Fin_Periode(l_info_societe, Rec_immo);
              
            ---------------------------------                                                   
            -- Calcul de la valeur cumulée --
            ---------------------------------                                                   
            Rec_Immo.Val_Cumule     := Rec_Immo.Val_Fin_Periode - Rec_Immo.Val_Debut_Periode;
            
            ------------------------------------                                                              
            -- Calcul de la valeur résiduelle --
            ------------------------------------                                                              
            Rec_Immo.Val_Residuelle := Rec_Immo.Valeur_Origine - Rec_Immo.Val_Fin_Periode;
        
            -------------------------------------
            -- Génération du fichier de sortie --
            -------------------------------------
            UTL_FILE.PUT_LINE( Pv_FicOUTptr,   '"' || Rec_Immo.Societe      || '";"' ||
                                               Rec_Immo.Centre_De_Gestion   || '";"' ||
                                               Rec_Immo.Periode_Debut_Amortissement || '";"' ||
                                               Rec_Immo.Periode_Fin_Amortissement || '";"' ||
                                               Rec_Immo.Livre_Comptable     || '";"' ||        
                                               Rec_Immo.Categorie_Immobilisation || '";"' ||   
                                               Rec_Immo.Compte              || '";"' ||                     
                                               Rec_Immo.Libelle_Compte      || '";"' ||             
                                               Rec_Immo.Numero_Immo         || '";"' ||                
                                               --REPLACE(Rec_Immo.Libelle_Immo, '"', '''''') || '";"' ||
                                               TRANSLATE(Rec_Immo.Libelle_Immo, 
                                                         '";' || Chr(10) || Chr(13) || Chr(12) || Chr(14) || Chr(11) || Chr(15) || Chr(9),
                                                         ''',       ')      || '";"' ||              
                                               --Rec_Immo.Code_Etablissement || '";"' ||         
                                               Rec_Immo.Projet              || '";"' ||                     
                                               Rec_Immo.Date_De_Mise_En_Service || '";"' ||    
                                               Rec_Immo.Duree_Amortissement || '";"' ||        
                                               Rec_Immo.Type_Amortissement  || '";' ||         
                                               Rec_Immo.Valeur_Origine      || ';' ||
                                               Rec_Immo.Val_Debut_Periode   || ';' ||
                                               Rec_Immo.Val_Cumule          || ';' ||
                                               Rec_Immo.Val_Fin_Periode     || ';' ||
                                               Rec_Immo.Val_Residuelle      || ';' ||  --artf2062660
                                               Rec_Immo.tache);                   --artf2062660

          l_counter := l_counter + 1;
        END LOOP;  
        
        Dka_Tools_Pkg.Put_Log_Message('==> nb d''enregistrements extraits : ' || l_counter);
        Dka_Tools_Pkg.Put_Log_Message('(-) Main');
      
        UTL_FILE.FCLOSE( Pv_FicOUTptr ) ;  
        
    -- 03/01/2017 NBO artf2062660 - SPE049 - Ajout tâche et modification centre de gestion
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'MAIN - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END Main;

    
end DKA_IFA_FLUXCM_PKG;
/
SHOW ERRORS;

EXIT
