PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DU TRIGGER DKA_GL_JE_HEADERS_BIR
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TRIGGER DKA_GL_JE_HEADERS_BIR;

CREATE OR REPLACE TRIGGER DKA_GL_JE_HEADERS_BIR
    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_GL_JE_HEADERS_BIR.trg
    -- DESCRIPTION      : Trigger sur la table Gl_Je_Headers
    --                    Pour les pieces de type ABONNEMENTS, ce trigger :
    --                    => Gere les annulations 
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
    -- 29/03/2007 EMA Ajout de la recherche des types de pieces dans le jeu de 
    --                valeurs DKA_ABON_TYPE_PIECE.
    -- 14/11/2011 EMA EARS00009717370
    --                Modification des contrôles de date par rapport a la date du
    --                jour ==> ajout Trunc(SYDATE)
    -- -----------------------------------------------------------------------------
    BEFORE INSERT ON GL.Gl_Je_Headers
    FOR EACH ROW    
    WHEN (NEW.Je_Source = 'Recurring')

DECLARE
    Vn_Mois_Annulation                  NUMBER;
    Vn_Running_Total_Dr                 Gl_Je_Headers.Running_Total_Dr%TYPE;
    Vn_Running_Total_Cr                 Gl_Je_Headers.Running_Total_Cr%TYPE;
    Vn_Running_Total_Accounted_Dr       Gl_Je_Headers.Running_Total_Accounted_Dr%TYPE;
    Vn_Running_Total_Accounted_Cr       Gl_Je_Headers.Running_Total_Accounted_Cr%TYPE;
    Vv_Jeu_De_Valeurs                   Fnd_Flex_Value_Sets.Flex_Value_Set_Name%TYPE := 'DKA_ABON_TYPE_PIECE';

BEGIN

    BEGIN
        -----------------------------------------------------------------------------------------
        -- Recherche si la piece a été générée par une écriture répétitive de type ABONNEMENTS --
        -----------------------------------------------------------------------------------------
        SELECT To_Number(Grhv.Attribute1)
        INTO   Vn_Mois_Annulation
        FROM   Gl_Recurring_Headers_V Grhv
        WHERE  Grhv.Recurring_Header_Id     = :NEW.From_Recurring_Header_Id
        -- AND    Grhv.User_Je_Category_Name   = 'ABONNEMENTS';                                  Modif EMA du 29/03/2007
        AND EXISTS (SELECT 'X'                                                                -- Modif EMA du 29/03/2007
                    FROM   Fnd_Flex_Value_Sets        Ffvs,                                   -- Modif EMA du 29/03/2007
                           Fnd_Flex_Values            Ffv                                     -- Modif EMA du 29/03/2007
                    WHERE  Ffvs.Flex_Value_Set_Name = Vv_Jeu_De_Valeurs                       -- Modif EMA du 29/03/2007
                    AND    Ffvs.Flex_Value_Set_Id   = Ffv.Flex_Value_Set_Id                   -- Modif EMA du 29/03/2007
                    AND    Ffv.Flex_Value           = Grhv.User_Je_Category_Name              -- Modif EMA du 29/03/2007
                    AND    Ffv.Enabled_Flag         = 'Y'                                     -- Modif EMA du 29/03/2007
                    AND    Trunc(SYSDATE) BETWEEN Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE))  -- Modif EMA du 29/03/2007
                                          AND     Nvl(Ffv.End_Date_Active, Trunc(SYSDATE)));  -- Modif EMA du 29/03/2007

        ---------------------------------------------------------------------------------
        -- La piece répétitive a son CUF 'Définir piece répétitive : Pieces' renseigné --
        -- Il s'agit d'une annulation : on mulplie les montants par -Mois_Annulation   --
        ---------------------------------------------------------------------------------
        IF Vn_Mois_Annulation <> 0 THEN
           :NEW.Name := 'ANNULATION : ' || :NEW.Name;
        END IF;
        
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
             NULL;
        WHEN OTHERS THEN
             App_Exception.Raise_Exception;
    END;

END Dka_Gl_Je_Headers_Bir;
/
SHOW ERRORS

ALTER TRIGGER Dka_Gl_Je_Headers_Bir DISABLE;

EXIT
