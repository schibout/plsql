PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DU TRIGGER DKA_GL_JE_LINES_BIR2
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TRIGGER DKA_GL_JE_LINES_BIR2;

CREATE OR REPLACE TRIGGER DKA_GL_JE_LINES_BIR2
    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_GL_JE_LINES_BIR2.trg
    -- DESCRIPTION      : Trigger sur la table Gl_Je_Lines
    --                    Pour les pieces de type ABONNEMENTS, ce trigger :
    --                    => renseigne le CUF 'Saisir pieces: Informations saisies'
    --                       de la ligne a partir des informations du CUF 'Définir
    --                       piece répétitive: Lignes' de la piece répétitive.
    --                    => Gere les annulations 
    --                    => Recalcule la clé comptable
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 18/07/2006
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    -- 29/03/2007 EMA Ajout de la recherche des types de piece dans le jeu de 
    --                valeurs DKA_ABON_TYPE_PIECE
    -- 14/11/2011 EMA EARS00009717370
    --                Modification des contrôles de date par rapport a la date du
    --                jour ==> ajout Trunc(SYDATE)
	-- 27/09/2016 RGH Migration R12
    -- 04/07/2017 YWA artf2188071 : SPE108 - Forcer désactivation Triggers en cas de plantage
    -- -----------------------------------------------------------------------------
    BEFORE INSERT ON GL.Gl_Je_Lines
    FOR EACH ROW

DECLARE
    Vn_Je_Header_id                     Gl_Je_Headers.Je_Header_Id%TYPE;
    Vn_From_recurring_Header_Id         Gl_Je_Headers.From_Recurring_Header_Id%TYPE;
    Vv_Context                          Gl_Recurring_Lines.Context%TYPE;
    Vv_Attribute1                       Gl_Recurring_Lines.Attribute1%TYPE;
    Vv_Attribute2                       Gl_Recurring_Lines.Attribute2%TYPE;
    Vv_Attribute3                       Gl_Recurring_Lines.Attribute3%TYPE;
    Vv_Attribute4                       Gl_Recurring_Lines.Attribute4%TYPE;--YWA artf2188071
    Vn_Mois_Annulation                  NUMBER;
    Vv_Context_Charges                  Gl_Je_Lines.Context3%TYPE := 'Y.E.X';
    Vv_Context_Produits                 Gl_Je_Lines.Context3%TYPE := 'Y.R.X';
    Vv_Old_Segment1                     Gl_Code_Combinations.Segment1%TYPE;
    Vv_Old_Segment2                     Gl_Code_Combinations.Segment2%TYPE;
    Vv_Old_Segment3                     Gl_Code_Combinations.Segment3%TYPE;
    Vv_Old_Segment4                     Gl_Code_Combinations.Segment4%TYPE;
    Vv_Old_Segment5                     Gl_Code_Combinations.Segment5%TYPE;
    Vv_Old_Segment6                     Gl_Code_Combinations.Segment6%TYPE;
    Vv_Old_Segment7                     Gl_Code_Combinations.Segment7%TYPE;
    Vv_Old_Segment8                     Gl_Code_Combinations.Segment8%TYPE;
    Vv_Old_Segment9                     Gl_Code_Combinations.Segment9%TYPE;
    Vv_Old_Segment10                    Gl_Code_Combinations.Segment10%TYPE;
    Vv_Old_Segment11                    Gl_Code_Combinations.Segment11%TYPE;
    Vv_Old_Segment12                    Gl_Code_Combinations.Segment12%TYPE;
    Vv_New_Segment1                     Gl_Code_Combinations.Segment1%TYPE;
    Vv_New_Segment2                     Gl_Code_Combinations.Segment2%TYPE;
    Vv_New_Segment3                     Gl_Code_Combinations.Segment3%TYPE;
    Vv_New_Segment4                     Gl_Code_Combinations.Segment4%TYPE;
    Vv_New_Segment5                     Gl_Code_Combinations.Segment5%TYPE;
    Vv_New_Segment6                     Gl_Code_Combinations.Segment6%TYPE;
    Vv_New_Segment7                     Gl_Code_Combinations.Segment7%TYPE;
    Vv_New_Segment8                     Gl_Code_Combinations.Segment8%TYPE;
    Vv_New_Segment9                     Gl_Code_Combinations.Segment9%TYPE;
    Vv_New_Segment10                    Gl_Code_Combinations.Segment10%TYPE;
    Vv_New_Segment11                    Gl_Code_Combinations.Segment11%TYPE;
    Vv_New_Segment12                    Gl_Code_Combinations.Segment12%TYPE;
	
	
    Vn_New_Ccid                         Gl_Code_Combinations.Code_Combination_Id%TYPE;
    Vv_User_Je_Category_Name            Gl_Recurring_Headers_V.User_Je_Category_Name%TYPE;
    Vn_Project_Id_Refac                 Pa_projects_All.Project_Id%TYPE;
    Vn_task_id_refac                    Pa_Tasks.Task_Id%TYPE; -- RGH
    Vv_Amount_Type                      VARCHAR2(1);
    Vn_Quantity                         NUMBER;
    Vn_ledger_id                        NUMBER; --YWA artf2188071
    Vv_Concatenated_Segs                VARCHAR2(2500);
    Vv_Errbuf                           VARCHAR2(2500);
    Vv_Message_Info                     VARCHAR2(2500);
    Vn_Retcode                          NUMBER;
    Vv_Jeu_De_Valeurs                   Fnd_Flex_Value_Sets.Flex_Value_Set_Name%TYPE := 'DKA_ABON_TYPE_PIECE';
    
    Erreur_Calcul_Ccid                  EXCEPTION;
    
BEGIN

    BEGIN
        -----------------------------------------------------------------------------------------
        -- Recherche si la ligne a été générée par une écriture répétitive de type ABONNEMENTS --
        -----------------------------------------------------------------------------------------
        SELECT Gjh.Je_Header_Id,
               Gjh.From_Recurring_Header_Id,
               To_Number(Grhv.Attribute1),
               Grhv.User_Je_Category_Name,
               Grl.Context,
               Grl.Attribute1,
               Grl.Attribute2,
               Grl.Attribute3,
               Grl.Attribute4, --YWA artf2188071
               Gjh.ledger_id --YWA artf2188071
        INTO   Vn_Je_Header_Id,
               Vn_From_Recurring_Header_Id,
               Vn_Mois_Annulation,
               Vv_User_Je_Category_Name,
               Vv_Context,
               Vv_Attribute1,
               Vv_Attribute2,
               Vv_Attribute3,
               Vv_Attribute4, --YWA artf2188071
               Vn_ledger_id --YWA artf2188071
        FROM   Gl_Je_Headers Gjh,
               Gl_Recurring_Headers_V         Grhv,
               Gl_Recurring_Lines             Grl
        WHERE  Gjh.Je_Header_Id             = :NEW.Je_Header_Id
        AND    Gjh.From_Recurring_Header_Id =  Grhv.Recurring_Header_Id
        AND    Gjh.Je_Source                = 'Recurring'
        -- AND    Grhv.User_Je_Category_Name   = 'ABONNEMENTS'                                   Modif EMA du 29/03/2007
        AND EXISTS (SELECT 'X'                                                                -- Modif EMA du 29/03/2007
                    FROM   Fnd_Flex_Value_Sets        Ffvs,                                   -- Modif EMA du 29/03/2007
                           Fnd_Flex_Values            Ffv                                     -- Modif EMA du 29/03/2007
                    WHERE  Ffvs.Flex_Value_Set_Name = Vv_Jeu_De_Valeurs                       -- Modif EMA du 29/03/2007
                    AND    Ffvs.Flex_Value_Set_Id   = Ffv.Flex_Value_Set_Id                   -- Modif EMA du 29/03/2007
                    AND    Ffv.Flex_Value           = Grhv.User_Je_Category_Name              -- Modif EMA du 29/03/2007
                    AND    Ffv.Enabled_Flag         = 'Y'                                     -- Modif EMA du 29/03/2007
                    AND    Trunc(SYSDATE) BETWEEN Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE))  -- Modif EMA du 29/03/2007
                                          AND     Nvl(Ffv.End_Date_Active, Trunc(SYSDATE)))   -- Modif EMA du 29/03/2007
        AND    Grhv.Recurring_Header_Id     = Grl.Recurring_Header_Id
        AND    Grl.Recurring_Line_Num       = :NEW.Je_Line_Num;

        ---------------------------------------------------------------------------------------
        -- Renseignement du CUF 'Saisir pieces : Informations saisie' a partir des           --
        -- informations du CUF 'Définir pieces répétitives : Lignes' de la piece répétitive  --
        ---------------------------------------------------------------------------------------
        :NEW.Context3    := Vv_Context;      -- Contexte
        :NEW.Attribute11 := Vv_Attribute1;   -- Project_Id
        :NEW.ATTRIBUTE17 := vv_attribute2;   -- task_id --YWA artf2188071
        :NEW.Attribute13 := Vv_Attribute4;   -- Type de dépense --YWA artf2188071
        :NEW.Attribute12 := Vv_Attribute3;   -- Type d'évenement
        
        ---------------------------------------------------------------------------------
        -- La piece répétitive a son CUF 'Définir piece répétitive : Pieces' renseigné --
        -- Il s'agit d'une annulation : on mulplie les montants par -Mois_Annulation   --
        ---------------------------------------------------------------------------------
        IF Vn_Mois_Annulation <> 0 THEN
           :NEW.Entered_Dr   := -Vn_Mois_Annulation * :NEW.Entered_Dr;
           :NEW.Entered_Cr   := -Vn_Mois_Annulation * :NEW.Entered_Cr;
           :NEW.Accounted_Dr := -Vn_Mois_Annulation * :NEW.Accounted_Dr;
           :NEW.Accounted_Cr := -Vn_Mois_Annulation * :NEW.Accounted_Cr;
        END IF;
        
        ----------------------------------
        -- Recalcul de la clé comptable --
        ----------------------------------
        IF :NEW.Context3 = Vv_Context_Charges  OR
           :NEW.Context3 = Vv_Context_Produits THEN
           
           IF :NEW.Accounted_Dr IS NOT NULL THEN
              Vv_Amount_Type := 'D';
              Vn_Quantity := :NEW.Accounted_Dr;
           ELSE
              Vv_Amount_Type := 'C';
              Vn_Quantity := :NEW.Accounted_Cr;
           END IF;
           
           SELECT Gcc.Segment1,
                  Gcc.Segment2,
                  Gcc.Segment3,
                  Gcc.Segment4,
                  Gcc.Segment5,
                  Gcc.Segment6,
                  Gcc.Segment7,
                  Gcc.Segment8,
                  Gcc.Segment9,
                  Gcc.Segment10, 
                  Gcc.Segment11, 
                  Gcc.Segment12 
				  
           INTO   Vv_Old_Segment1,
                  Vv_Old_Segment2,
                  Vv_Old_Segment3,
                  Vv_Old_Segment4,
                  Vv_Old_Segment5,
                  Vv_Old_Segment6,
                  Vv_Old_Segment7,
                  Vv_Old_Segment8,
                  Vv_Old_Segment9,
                  Vv_Old_Segment10,
                  Vv_Old_Segment11,
                  Vv_Old_Segment12
           FROM   Gl_Code_Combinations Gcc
           WHERE  Gcc.Code_Combination_Id = :NEW.Code_Combination_Id;
           
           -----------------------------------------------------------
           -- Appel de la procédure de recalcul de la clé comptable --
           -----------------------------------------------------------
           Dka_Spacutoffgl_Pkg.Controler_Line_Gl (Pv_Errbuf                => Vv_Errbuf,
                                                  Pn_Retcode               => Vn_Retcode,
                                                  Pv_User_Je_Category_Name => Vv_User_Je_Category_Name,
                                                  -- Pd_Gl_Date               => SYSDATE,        Modif EMA du 14/11/2011
                                                  Pd_Gl_Date               => Trunc(SYSDATE), -- Modif EMA du 14/11/2011
                                                  Pv_Amount_Type           => Vv_Amount_Type,
                                                  Pv_Segment1_In           => Vv_Old_Segment1,
                                                  Pv_Segment2_In           => Vv_Old_Segment2,
                                                  Pv_Segment3_In           => Vv_Old_Segment3,
                                                  Pv_Segment4_In           => Vv_Old_Segment4,
                                                  Pv_Segment5_In           => Vv_Old_Segment5,
                                                  Pv_Segment6_In           => Vv_Old_Segment6,
                                                  Pv_Segment7_In           => Vv_Old_Segment7,
                                                  Pv_Segment8_In           => Vv_Old_Segment8,
                                                  Pv_Segment9_In           => Vv_Old_Segment9,
                                                  Pv_Segment10_In          => Vv_Old_Segment10,
                                                  Pv_Segment11_In          => Vv_Old_Segment11, -- RGH
                                                  Pv_Segment12_In          => Vv_Old_Segment12, -- RGH
                                                  Pn_Project_Id            => Vv_Attribute1,
												  pn_task_id               => Vv_Attribute2,    -- RGH
                                                  Pv_Expenditure_Type      => vv_attribute4,--YWA artf2188071 												  
                                                  Pv_Event_Type            => Vv_Attribute3,
                                                  Pn_Quantity              => Vn_Quantity,
                                                  Pn_ledger_id             => Vn_ledger_id, --YWA artf2188071
                                                  Pn_Project_Id_Refac      => Vn_Project_Id_Refac,
												  pn_task_id_refac         => Vn_task_id_refac, -- RGH
                                                  Pv_Segment1_Out          => Vv_New_Segment1,
                                                  Pv_Segment2_Out          => Vv_New_Segment2,
                                                  Pv_Segment3_Out          => Vv_New_Segment3,
                                                  Pv_Segment4_Out          => Vv_New_Segment4,
                                                  Pv_Segment5_Out          => Vv_New_Segment5,
                                                  Pv_Segment6_Out          => Vv_New_Segment6,
                                                  Pv_Segment7_Out          => Vv_New_Segment7,
                                                  Pv_Segment8_Out          => Vv_New_Segment8,
                                                  Pv_Segment9_Out          => Vv_New_Segment9,
                                                  Pv_Segment10_Out         => Vv_New_Segment10,
                                                  Pv_Segment11_Out         => Vv_New_Segment11, -- RGH
                                                  Pv_Segment12_Out         => Vv_New_Segment12, -- RGH
                                                  Pv_Concatenated_Segs     => Vv_Concatenated_Segs,
                                                  Pn_Ccid                  => Vn_New_Ccid,
                                                  Pv_Message_Info          => Vv_Message_Info);
                                                  
            IF Vn_Retcode <> 0 THEN
               RAISE Erreur_Calcul_Ccid;
            END IF;

            -------------------------------------------
            -- Ré-affectation du Code_Combination_Id --
            -------------------------------------------
            :NEW.Code_Combination_Id := Vn_New_Ccid;
           
        END IF;
        
        
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
             NULL;
        WHEN Erreur_Calcul_Ccid THEN
             App_Exception.Raise_Exception;
        WHEN OTHERS THEN
             App_Exception.Raise_Exception;
    END;

END Dka_Gl_Je_Lines_Bir2;
/
SHOW ERRORS

ALTER TRIGGER Dka_Gl_Je_Lines_Bir2 DISABLE;

EXIT