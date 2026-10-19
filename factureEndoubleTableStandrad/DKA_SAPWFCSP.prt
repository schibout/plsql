-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_AP_AGING_PERIODS.sql
-- DESCRIPTION      : Création des périodes de balance âgée :
--                    - DKA : Justification des factures échues
--                    - DKA : Justification des factures non échues
--
-- AUTEUR           : E.MATUSZEWSKI (Capgemini)
-- DATE DE CREATION : 12/01/2010
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 11/03/2010 EMA Modification des limtes des périodes de balance âgée
-- -----------------------------------------------------------------------------

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

DECLARE

    Vn_Retcode                          NUMBER;
    Vc_Errbuf                           VARCHAR2(250);
    Vc_Periode_Fact_Echues              Ap_Aging_Periods.Period_Name%TYPE := 'DKA : Justification des factures échues';
    Vc_Libelle_Fact_Echues              Ap_Aging_Periods.Period_Name%TYPE := 'Justification des factures échues';
    Vc_Periode_Fact_Non_Echues          Ap_Aging_Periods.Period_Name%TYPE := 'DKA : Justification des factures non échues';
    Vc_Libelle_Fact_Non_Echues          Ap_Aging_Periods.Period_Name%TYPE := 'Justification des factures non échues';
    Vn_Aging_Period_Id                  Ap_Aging_Periods.Aging_Period_Id%TYPE;

    E_Error                             Exception;

    -- -----------------------------------------------------------------------------
    -- Nom              : Exist_Period_Name
    -- Description      : Fonction de vérification de l'existence de la période de 
    --                    balance âgée
    --
    -- PARAMETRES       : Pv_Period_Name   Entrée       Période de balance âgée
    --
    -- VALEUR RETOURNEE :
    --     Description       : Code Retour de la fonction
    --     Valeurs possibles : TRUE  : la période existe
    --                         FALSE : La période n'existe pas
    -- -----------------------------------------------------------------------------
    FUNCTION Exist_Period_Name (Pv_Period_Name VARCHAR2) RETURN BOOLEAN IS

        Vc_Dummy                        VARCHAR2(1);

    BEGIN
        SELECT 'X'
        INTO   Vc_Dummy
        FROM   Ap_Aging_Periods
        WHERE  Period_Name = Pv_Period_Name;

        RETURN TRUE;

    EXCEPTION
        WHEN OTHERS THEN
             RETURN FALSE;

    END Exist_Period_Name;


    -- -----------------------------------------------------------------------------
    -- Nom              : Insert_Aging_Periods
    -- Description      : Insertion d'un enregistrement dans la table Ap_Aging_Periods.
    --
    -- PARAMETRES       : Pv_Period_Name     Entrée        Période de balance âgée
    --                    Pv_Description     Entrée        Description de la période de 
    --                                                     balance âgée
    --                    Pn_Aging_period_Id        Sortie Id de la période de
    --                                                     balance âgée
    --                    Pn_Retcode                Sortie Code retour
    --                    Pv_Errbuf                 Sortie Message d'erreur
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    --
    -- -----------------------------------------------------------------------------
    PROCEDURE Insert_Aging_Periods (Pv_Period_Name     IN     VARCHAR2,
                                    Pv_Description     IN     VARCHAR2,
                                    Pn_Aging_Period_Id    OUT NUMBER,
                                    Pn_Retcode            OUT NUMBER,
                                    Pv_Errbuf             OUT VARCHAR2) IS

    BEGIN

        Pn_Retcode := 0;
        Pv_Errbuf  := NULL;

        ----------------------------
        -- Recherche du nouvel Id --
        ----------------------------
        SELECT Ap_Aging_Periods_S.Nextval
        INTO   Pn_Aging_Period_Id
        FROM   Dual;

        ----------------------------------------------
        -- Insertion dans la table Ap_Aging_Periods --
        ----------------------------------------------
        INSERT INTO Ap_Aging_Periods
            (Aging_Period_Id,
             Last_Updated_By,
             Last_Update_Date,
             Created_By,
             Creation_Date,
             Period_Name,
             Description,
             Status,
             Aging_Type,
             Last_Update_Login)
        VALUES
            (Pn_Aging_Period_Id,
             Fnd_Global.User_Id,
             SYSDATE,
             Fnd_Global.User_Id,
             SYSDATE,
             Pv_Period_Name,
             Pv_Description,
             'A',
             '4PERIOD',
             Fnd_Global.Login_Id);

        Dbms_Output.Put_Line(Chr(10));
        Dbms_Output.Put_Line('==> Periode "' || Pv_Period_Name || '" inseree dans la table AP_AGING_PERIODS');

    EXCEPTION
        WHEN OTHERS THEN
             Pn_Retcode := Sqlcode;
             Pv_Errbuf  := SUBSTR(Sqlerrm, 1, 80);
             Dbms_Output.Put_Line(Chr(10));
             Dbms_Output.Put_Line('==> Erreur lors de l''insertion dans la table AP_AGING_PERIODS');
             Dbms_Output.Put_Line('==> SQLCODE : ' || Pn_Retcode);
             Dbms_Output.Put_Line('==> SQLERRM : ' || Pv_Errbuf);
 

    END Insert_Aging_Periods;


    -- -----------------------------------------------------------------------------
    -- Nom              : Insert_Aging_Period_Lines
    -- Description      : Insertion d'un enregistrement dans la table 
    --                    Ap_Aging_Period_Lines.
    --
    -- PARAMETRES       : Pn_Aging_Period_Id Entrée        Id de la période de
    --                                                     balance âgée
    --                    Pn_Sequence_Num    Entrée        Numéro de séquence
    --                    Pn_Days_Start      Entrée        Premier jour
    --                    Pn_Days_To         Entrée        Dernier jour
    --                    Pv_Type            Entrée        Type
    --                    Pv_Heading1        Entrée        Entête de colonne 1
    --                    Pv_Heading2        Entrée        Entête de colonne 1
    --                    Pn_Retcode                Sortie Code retour
    --                    Pv_Errbuf                 Sortie Message d'erreur
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    --
    -- -----------------------------------------------------------------------------
    PROCEDURE Insert_Aging_Period_Lines (Pn_Aging_Period_Id IN     NUMBER,
                                         Pn_Sequence_Num    IN     NUMBER,
                                         Pn_Days_Start      IN     NUMBER,
                                         Pn_Days_To         IN     NUMBER,
                                         Pv_Type            IN     VARCHAR2,
                                         Pv_Heading1        IN     VARCHAR2,
                                         Pv_Heading2        IN     VARCHAR2,
                                         Pn_Retcode            OUT NUMBER,
                                         Pv_Errbuf             OUT VARCHAR2) IS

        Vn_Aging_Period_Line_Id         Ap_Aging_Period_Lines.Aging_Period_line_Id%TYPE;

    BEGIN

        Pn_Retcode := 0;
        Pv_Errbuf  := NULL;

        ----------------------------
        -- Recherche du nouvel Id --
        ----------------------------
        SELECT Ap_Aging_Period_Lines_S.Nextval
        INTO   Vn_Aging_Period_Line_Id
        FROM   Dual;
        
        ---------------------------------------------------
        -- Insertion dans la table Ap_Aging_Period_Lines --
        ---------------------------------------------------
        INSERT INTO Ap_Aging_Period_Lines
            (Aging_Period_Line_Id,
             Last_Updated_By,
             Last_Update_Date,
             Created_By,
             Creation_Date,
             Aging_Period_Id,
             Period_Sequence_Num,
             Days_Start,
             Days_To,
             Type,
             Report_Heading1,
             Report_Heading2,
             Last_Update_Login)
        VALUES
            (Vn_Aging_Period_Line_Id,
             Fnd_Global.User_Id,
             SYSDATE,
             Fnd_Global.User_Id,
             SYSDATE,
             Pn_Aging_Period_Id,
             Pn_Sequence_Num,
             Pn_Days_Start,
             Pn_Days_To,
             Pv_Type,
             Pv_Heading1,
             Pv_Heading2,
             Fnd_Global.Login_Id);

        Dbms_Output.Put_Line(Chr(10));
        Dbms_Output.Put_Line('==> Sequence "' || Pn_Sequence_Num || '" inseree dans la table AP_AGING_PERIODS');

    EXCEPTION
        WHEN OTHERS THEN
             Pn_Retcode := Sqlcode;
             Pv_Errbuf  := SUBSTR(Sqlerrm, 1, 80);
             Dbms_Output.Put_Line(Chr(10));
             Dbms_Output.Put_Line('==> Erreur lors de l''insertion dans la table AP_AGING_PERIOD_LINES');
             Dbms_Output.Put_Line('==> SQLCODE : ' || Pn_Retcode);
             Dbms_Output.Put_Line('==> SQLERRM : ' || Pv_Errbuf);

    END Insert_Aging_Period_Lines;

BEGIN

    -----------------------------------------------------------------------------------------
    -- Insertion de la période de balance âgée : "DKA : Justification des factures échues" --
    -----------------------------------------------------------------------------------------
    IF Exist_Period_Name (Vc_Periode_Fact_Echues) THEN
        Dbms_Output.Put_Line(Chr(10));
        Dbms_Output.Put_Line('==> La periode "' || Vc_Periode_Fact_Echues || '" existe deja !');
    ELSE
        ----------------------------------------------
        -- Insertion dans la table Ap_Aging_Periods --
        ----------------------------------------------
        Vn_Retcode := 0;
        Vc_Errbuf  := NULL;
        Insert_Aging_Periods (Vc_Periode_Fact_Echues, 
                              Vc_Libelle_Fact_Echues, 
                              Vn_Aging_Period_Id, 
                              Vn_Retcode, 
                              Vc_Errbuf);              


        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ---------------------------------------
        -- Insertion de la première séquence --
        ---------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   1,
                                   -9999,
                                   -1,
                                   'CURRENT',
                                   'Factures',
                                   'non échues',
                                   Vn_Retcode,
                                   Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ---------------------------------------
        -- Insertion de la deuxième séquence --
        ---------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   2,
                                   0,
                                   180,
                                   'PAST',
                                   'Retard',
                                   '0 à 6 mois',
                                   Vn_Retcode,
                                   Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ----------------------------------------
        -- Insertion de la troisième séquence --
        ----------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   3,
                                   181,
                                   360,
                                   'PAST',
                                   'Retard',
                                   '6 à 12 mois',
                                   Vn_Retcode,
                                   Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ----------------------------------------
        -- Insertion de la quatrième séquence --
        ----------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   4,
                                   361,
                                   9999,
                                   'PAST',
                                   'Retard',
                                   'Plus d''un an',
                                    Vn_Retcode,
                                    Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;
    END IF;


    ---------------------------------------------------------------------------------------------
    -- Insertion de la période de balance âgée : "DKA : Justification des factures non échues" --
    ---------------------------------------------------------------------------------------------
    IF Exist_Period_Name (Vc_Periode_Fact_Non_Echues) THEN
        Dbms_Output.Put_Line(Chr(10));
        Dbms_Output.Put_Line('==> La periode "' || Vc_Periode_Fact_Non_Echues || '" existe deja !');
    ELSE
        ----------------------------------------------
        -- Insertion dans la table Ap_Aging_Periods --
        ----------------------------------------------
        Vn_Retcode := 0;
        Vc_Errbuf  := NULL;
        Insert_Aging_Periods (Vc_Periode_Fact_Non_Echues, 
                              Vc_Libelle_Fact_Non_Echues, 
                              Vn_Aging_Period_Id, 
                              Vn_Retcode, 
                              Vc_Errbuf);              


        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ---------------------------------------
        -- Insertion de la première séquence --
        ---------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   1,
                                   0,
                                   9999,
                                   'PAST',
                                   'Factures',
                                   'échues',
                                   Vn_Retcode,
                                   Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ---------------------------------------
        -- Insertion de la deuxième séquence --
        ---------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   2,
                                   -30,
                                   -1,
                                   'CURRENT',
                                   'Fact non échues',
                                   '< 1 mois',
                                   Vn_Retcode,
                                   Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ----------------------------------------
        -- Insertion de la troisième séquence --
        ----------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   3,
                                   -60,
                                   -31,
                                   'CURRENT',
                                   'Fact non échues',
                                   '1 à 2 mois',
                                   Vn_Retcode,
                                   Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;

        ----------------------------------------
        -- Insertion de la quatrième séquence --
        ----------------------------------------
        Insert_Aging_Period_Lines (Vn_Aging_Period_Id,
                                   4,
                                   -9999,
                                   -61,
                                   'CURRENT',
                                   'Fact non échues',
                                   '> 2 mois',
                                    Vn_Retcode,
                                    Vc_Errbuf);

        IF Vn_Retcode != 0 THEN
            RAISE E_Error;
        END IF;
    END IF;

    COMMIT;

EXCEPTION
    WHEN E_Error THEN
         ROLLBACK;
    WHEN OTHERS THEN
         ROLLBACK;

END;
/
EXIT