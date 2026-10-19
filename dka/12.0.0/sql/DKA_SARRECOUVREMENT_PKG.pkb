CREATE OR REPLACE PACKAGE BODY DKA_SARRECOUVREMENT_PKG
AS
    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SARRECOUVREMENT_PKG
    -- DESCRIPTION      : DKA_SARRECOUVREMENT_PKG Package Body
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 29/11/2006
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    -- 11/06/2009 EMA Evolution du composant conformément à l'EID20080271b
    --                + Ajout des entêtes de colonne pour les 3 états.
    --                + Ajout du paramètre Période pour tous les traitements.
    --                + Ajouts des paramètres : Société
    --                                          Chargé de recouvrement
    --                                          Niveau de détail Société
    --                                          Niveau de détail Chargé de recouvrement
    --                  pour l'extraction du ratio client.
    -- 01/07/2009 EMA Ajout du total général
    -- 02/07/2009 EMA Modification de la requête de recherche du projet dans les
    --                procédures :
    --                             - Extraction_Encours
    --                             - Extraction_Avoirs
    -- 31/03/2010 EMA Modification de la procédure Extraction_Ratios : prise en
    --                compte des nouveaux paramètres dans l'appel de
    --                Dka_Rarratioscli_Pkg.Init_Etat
    -- 21/04/2010 EMA Modification du package selon l'EID20100090 : Ajout de
    --                nouveaux champs dans l'extraction
    --                Ajout des fonctions : Get_Lib_Centre_Gestion
    --                                      Get_Classe_Client
    --                                      Get_Categorie_Client
    --                Dans les champs Commentaires, les éventuels ; sont remplacés
    --                par des espaces
    -- 22/09/2010 EMA Modification du package selon EIS20100086 : la valeur 
    --                GROUPE est exclue lors de la recherche des valeurs par 
    --                défaut des paramètres « Classe Client ».
    -- 15/03/2011 EMA Modification de l'alimentation de la table DKA_RATIOS_CLIENT.
    -- 18/07/2012 BCO Modification du curseur Cur_Fichier_Total:
    --				  la valeur VALEUR : Remplacement de la valeur 'ZZZZZZZZZZZZ...'
    --				  par la valeur du centre de gestion saisi en paramètre.
    -- 07/02/2017 OBE Modification - artf2097154
    -- 08/08/2017 YWA artf2209651 : SPE133 - Alimentation des tableaux de recouvrement - defect BeB #1040
    -- 08/03/2018 OBE artf2413132 : SPE133 - Correctif sélection date de fin de période
    -- 09/10/2018 NBO artf3037802 : INC0247321 analyser les problèmes de performance sur le traitement "DKA : Extraction En-cours Recouvrement"
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    -- -----------------------------------------------------------------------------
    -- Nom              : Get_Last_Date
    -- Description      : Fonction de recherche de la date de fin de la période
    --                    passée en paramètre
    --
    -- PARAMETRES       : Pv_Periode         Entrée        Période
    --                    Pd_End_Date_period        Sortie Date de fin de période
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    FUNCTION Get_Last_Date (Pv_Periode IN VARCHAR2, Pn_Org_ID IN NUMBER) RETURN DATE
    IS

        Pd_End_Date_Period              Gl_Period_Statuses.End_Date%TYPE;

        ---------------------------------------------
        -- Curseur de lecture des périodes fermées --
        ---------------------------------------------
        CURSOR Cur_Last_Period IS
            SELECT Gps.End_Date
            FROM   Gl_Period_Statuses Gps, 
			       gl_ledgers gl,                -- OBE artf2413132
				   hr_all_organization_units hr, -- OBE artf2413132
				   GL_ACCESS_SET_LEDGERS gla     -- OBE artf2413132
            WHERE  Gps.Period_Name            = Pv_Periode
            AND    Gps.Application_Id         = 222
            --AND    Gps.Set_Of_Books_Id        = Fnd_Profile.Value('GL_SET_OF_BKS_ID')     -- <== TODO  : rechercher le livre qui correpsond à l'UO passée en param -- OBE artf2413132
            AND    Gps.Adjustment_Period_Flag = 'N'
            --AND    Gps.Closing_Status         = 'C'
			AND gla.access_set_id = fnd_profile.VALUE('GL_ACCESS_SET_ID') -- OBE artf2413132
			AND gla.ledger_id = gl.ledger_id                              -- OBE artf2413132
			AND gps.ledger_id  = gl.ledger_id                             -- OBE artf2413132
			AND gl.short_name = substr(hr.name,4,4)			              -- OBE artf2413132
			AND hr.organization_id = pn_org_id                            -- OBE artf2413132
            ORDER  BY Gps.Effective_Period_Num DESC;

    BEGIN

        OPEN Cur_Last_Period;
        FETCH Cur_Last_Period INTO Pd_End_Date_Period;
        CLOSE Cur_Last_Period;

        RETURN(Pd_End_Date_Period);

    END Get_Last_Date;


    -- -----------------------------------------------------------------------------
    -- Nom              : Get_Lib_Centre_Gestion
    -- Description      : Fonction de recherche du libellé du centre de gestion
    --                    passé en paramètre
    --
    -- PARAMETRES       : Pv_Centre_Gestion     Entrée         Centre de Gestion
    --                    Pv_Lib_Centre_Gestion        Sortie  Libellé Centre de Gestion
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    FUNCTION Get_Lib_Centre_Gestion (Pv_Centre_Gestion IN VARCHAR2) RETURN VARCHAR2
    IS

        Pv_Lib_Centre_Gestion           Fnd_Flex_Values_Tl.Description%TYPE;

    BEGIN

        ---------------------------------------
        -- Recherche du libellé de la région --
        ---------------------------------------
        BEGIN
            SELECT Ffvt.Description
            INTO   Pv_Lib_Centre_Gestion
            FROM   Fnd_Flex_Value_Sets Ffvs,
                   Fnd_Flex_Values     Ffv,
                   Fnd_Flex_Values_Tl  Ffvt
            WHERE  Ffvs.Flex_Value_Set_Name = 'DAOPCCF_UO'--YWA artf2209651 
            AND    Ffvs.Flex_Value_Set_Id   = Ffv.Flex_Value_Set_Id
            AND    Ffv.Flex_Value           = Pv_Centre_Gestion
            AND    Ffv.Flex_Value_Id        = Ffvt.Flex_Value_Id
            AND    Ffvt.Language            = Userenv('LANG');

        EXCEPTION
            WHEN OTHERS THEN
                 Pv_Lib_Centre_Gestion := NULL;
        END;

        RETURN(Pv_Lib_Centre_Gestion);

    END Get_Lib_Centre_Gestion;


    -- -----------------------------------------------------------------------------
    -- Nom              : Get_Classe_Client
    -- Description      : Fonction de recherche du libellé de la classe client
    --                    passée en paramètre
    --
    -- PARAMETRES       : Pv_Classe_Client      Entrée         Classe Client
    --                    Pv_Lib_Classe_Client         Sortie  Libellé Classe Client
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    FUNCTION Get_Classe_Client (Pv_Classe_Client IN VARCHAR2) RETURN VARCHAR2
    IS

        Pv_Lib_Classe_Client            Ar_Lookups.Meaning%TYPE;

    BEGIN

        -----------------------------------
        -- Recherche de la classe client --
        -----------------------------------
        BEGIN
            SELECT Al.Meaning
            INTO   Pv_Lib_Classe_Client
            FROM   Ar_Lookups Al
            WHERE  Al.Lookup_Type = 'CUSTOMER CLASS'
            AND    Al.Lookup_Code = Pv_Classe_Client;

        EXCEPTION
            WHEN OTHERS THEN
                 Pv_Lib_Classe_Client := NULL;
        END;

        RETURN(Pv_Lib_Classe_Client);

    END Get_Classe_Client;


    -- -----------------------------------------------------------------------------
    -- Nom              : Get_Categorie_Client
    -- Description      : Fonction de recherche du libellé de la catégorie client
    --                    passée en paramètre
    --
    -- PARAMETRES       : Pv_Categorie_Client      Entrée         Catégorie Client
    --                    Pv_Lib_Categorie_Client         Sortie  Libellé Catégorie Client
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    FUNCTION Get_Categorie_Client (Pv_Categorie_Client IN VARCHAR2) RETURN VARCHAR2
    IS

        Pv_Lib_Categorie_Client         Ar_Lookups.Meaning%TYPE;

    BEGIN

         --------------------------------------
         -- Recherche de la catégorie client --
         --------------------------------------
         BEGIN
             SELECT Al.Meaning
             INTO   Pv_Lib_Categorie_Client
             FROM   Ar_Lookups Al
             WHERE  Al.Lookup_Type = 'CUSTOMER_CATEGORY'
             AND    Al.Lookup_Code = Pv_Categorie_Client;

        EXCEPTION
             WHEN OTHERS THEN
                  Pv_Lib_Categorie_Client := NULL;
        END;

        RETURN(Pv_Lib_Categorie_Client);

    END Get_Categorie_Client;


    -- -----------------------------------------------------------------------------
    --  Retourne la région qui correspond à l'operating unit
    FUNCTION Get_Region(p_org_id in hr_operating_units.organization_id%type) return hr_operating_units.name%type is
      l_result hr_operating_units.name%type;
    begin
      if p_org_id is not null then 
        select substr(name, 1, 3)
        into l_result
        from  hr_operating_units hou
        where organization_id = p_org_id;
      else
        l_result := null;
      end if;      
      return l_result;
    exception
      when no_data_found then 
        Dka_Tools_Pkg.Put_Debug_Message('ORG_ID invalide : ' || p_org_id);        
    end get_region;
    

    -- -----------------------------------------------------------------------------
    -- Nom              : Extraction_Encours
    -- Description      : Extraction des données pour la génération du fichier de
    --                    sortie justifiant l'encours
    --
    -- PARAMETRES       : Pv_Errbuf              Sortie Message d'erreur
    --                    Pn_Retcode             Sortie Code Retour de la procédure
    --                                                  '0' : Normal
    --                                                  '1' : Avertissement
    --                                                  '2' : Erreur
    --                    Pv_Debug_Mode Entrée          Mode debug
    --                    Pv_ORG_ID     Entrée          Unité Opérationnelle (ex : id de DRW001)
    --                    Pv_Periode    Entrée          Période
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Extraction_Encours(Pv_Errbuf         OUT  VARCHAR2,
                                 Pn_Retcode        OUT  NUMBER,
                                 Pv_Debug_Mode  IN      VARCHAR2,
                                 Pn_Org_ID      IN      NUMBER,
                                 Pv_Periode     IN      VARCHAR2)
    IS

        -----------------------------------------------------------------
        -- Curseur de lecture des factures à la date de fin de période --
        -----------------------------------------------------------------
        CURSOR Cur_Factures(Pd_End_Date DATE, Pn_Org_ID IN NUMBER, Pv_Region VARCHAR2) IS
        SELECT Fnd_Global.Conc_Request_Id    Request_Id,
               Gcc.Segment2                  Centre_Gestion,
               ac.customer_number            Code_Client,
               ac.customer_Name                 Client,
               Apsa.Trx_Date                 Date_Mouvement,
               Apsa.Due_Date                 Echeance,
               Rctlgda.Acctd_Amount          Solde_Du,
               NULL                          Charge_Recouvrement,
               NULL                          Centre_finance,
               Rctad.TACHE_MAJORITAIRE       as id_tache_majoritaire,
               NULL                          Projet_Majoritaire,
               NULL                          Tache_Majoritaire,
               Gcc.Segment1                  Societe,
               Rcta.Trx_Number               Num_Piece,
               Flvv_Class.Meaning            Classe_Piece,
               Gcc.Segment3                  Compte_Client,
               Hcsua.Location                Site_Client,
               NULL                          Num_Client_Destinataire,
               NULL                          Client_Destinataire,
               Flvv_Status.Meaning           Statut,
               Rctta.NAME        Type_De_Mouvement, --Substr(Rctta.NAME, 6)         Type_De_Mouvement, --YWA artf2209651 
               Apsa.Amount_In_Dispute        Montant_En_Litige,
               Rcta.Comments                 Commentaire,
               Apsa.Customer_Site_Use_Id     Customer_Site_Use_Id,
               Apsa.Customer_Id              Customer_Id,
               Hcsua.Cust_Acct_Site_Id       Cust_Acct_Site_Id,
               Rcta.Customer_Trx_Id          Customer_Trx_Id,
               ac.Customer_Class_Code        Classe_Client,            -- Modif EMA du 21/04/2010
               ac.Customer_Category_Code     Categorie_Client,          -- Modif EMA du 21/04/2010
               Apsa.Org_Id                  --YWA artf2209651
        FROM   Ar_Payment_Schedules          Apsa
        join   Ra_Customer_Trx_All           Rcta          on (Apsa.Customer_Trx_Id  = Rcta.Customer_Trx_Id AND Apsa.Org_Id = Rcta.Org_Id)
        join   Ra_Customer_Trx_All_DFV       Rctad         on (rctad.row_id          = rcta.rowid)
        join   Ra_Cust_Trx_Types_All         Rctta         on (Rcta.Cust_Trx_Type_Id = Rctta.Cust_Trx_Type_Id AND Rcta.Org_Id = Rctta.Org_Id)
        join   Ra_Cust_Trx_Line_Gl_Dist_All  Rctlgda       on (Rcta.Customer_Trx_Id  = Rctlgda.Customer_Trx_Id AND Rcta.Org_Id = Rctlgda.Org_Id)
        join   Gl_Code_Combinations          Gcc           on (Rctlgda.Code_Combination_Id = Gcc.Code_Combination_Id)
        join   Hz_Cust_Site_Uses_All         Hcsua         on (Apsa.Customer_Site_Use_Id = Hcsua.Site_Use_Id AND Apsa.Org_Id = Hcsua.Org_Id)
        join   AR_CUSTOMERS                  ac            on (Apsa.Customer_Id = ac.Customer_id)
        join   Fnd_Lookup_Values_Vl          Flvv_Class    on (Rctta.Type = Flvv_Class.Lookup_Code AND Flvv_Class.Lookup_Type = 'INV/CM')
        join   Fnd_Lookup_Values_Vl          Flvv_Status   on (Apsa.Status = Flvv_Status.Lookup_Code AND Flvv_Status.Lookup_Type = 'PAYMENT_SCHEDULE_STATUS')
        WHERE  1=1
        and    Apsa.Gl_Date_Closed         > Pd_End_Date
        AND    Apsa.Class                 <> 'PMT'
        AND    Apsa.Org_Id                = nvl(Pn_Org_Id,Apsa.Org_Id ) --YWA artf2209651
        AND    Rcta.Complete_Flag          = 'Y'
        AND    Rctlgda.Account_Class       = 'REC'
        AND    Rctlgda.Gl_Date            <= Pd_End_Date
        AND    Rctlgda.Gl_Posted_Date IS NOT NULL
        AND    Gcc.Segment2                = nvl(Pv_Region,Gcc.Segment2); --YWA artf2209651

        -------------------------------------------------------------------
        -- Curseur de lecture des règlements à la date de fin de période --
        -------------------------------------------------------------------
        CURSOR Cur_Reglements(Pd_End_Date DATE, Pn_Org_ID IN NUMBER, Pv_Region VARCHAR2) IS
        SELECT Fnd_Global.Conc_Request_Id              Request_Id,
               Gcc.Segment2                            Centre_Gestion,
               Rc.Customer_Number                      Code_Client,
               Rc.Customer_Name                        Client,
               Apsa.Trx_Date                           Date_Mouvement,
               Apsa.Due_Date                           Echeance,
               Sum(Decode(Acrha.Status, 'REVERSED', -araa.Amount_Applied, +araa.Amount_Applied)) Solde_Du,
               NULL                                    Charge_Recouvrement,
               'Pas d''appartenance'                   Centre_finance,
               NULL                                    Tache_majoritaire,
               NULL                                    Project_Id,
               'Pas de projet'                         Projet_Majoritaire,
               Gcc.Segment1                            Societe,
               Acra.Receipt_Number                     Num_Piece,
               Flvv_Class.Meaning                      Classe_Piece,
               '419000'                                Compte_Client,
               NULL                                    Site_Client,
               NULL                                    Num_Client_Destinataire,
               NULL                                    Client_Destinataire,
               Flvv_Status.Meaning                     Statut,
               'En compte'                             Type_De_Mouvement,
               Apsa.Amount_In_Dispute                  Montant_En_Litige,
               Acra.Comments                           Commentaire,
               Apsa.Customer_Site_Use_Id               Customer_Site_Use_Id,
               Apsa.Customer_Id                        Customer_Id,
               Rc.Customer_Class_Code                  Classe_Client,            -- Modif EMA du 21/04/2010
               Rc.Customer_Category_Code               Categorie_Client,          -- Modif EMA du 21/04/2010
               Apsa.Org_Id                              --YWA artf2209651
        FROM   Ar_Payment_Schedules                    Apsa
        join   Ar_Cash_Receipts_All                    Acra          on (Apsa.Cash_Receipt_Id = Acra.Cash_Receipt_Id and Apsa.Org_Id = Acra.Org_Id) 
        join   Ar_Receivable_Applications_All          Araa          on (Acra.Cash_Receipt_Id = Araa.Cash_Receipt_Id and Acra.Org_Id = Araa.Org_Id)
        join   Ar_Cash_Receipt_History_All             Acrha         on (Araa.Cash_Receipt_Id = Acrha.Cash_Receipt_Id and Araa.Org_Id = Acrha.Org_Id)
        join   Gl_Code_Combinations                    Gcc           on (Acrha.Account_Code_Combination_Id = Gcc.Code_Combination_Id)
        join   AR_Customers                            Rc            on (Apsa.Customer_Id = Rc.Customer_Id)
        join   Fnd_Lookup_Values_Vl                    Flvv_Class    on (Flvv_Class.Lookup_Type = 'INV/CM' and Flvv_Class.Lookup_Code = Apsa.Class) 
        join   Fnd_Lookup_Values_Vl                    Flvv_Status   on (Apsa.Status = Flvv_Status.Lookup_Code and Flvv_Status.Lookup_Type = 'PAYMENT_SCHEDULE_STATUS')
        WHERE  Apsa.Gl_Date_Closed                   > Pd_End_Date   
        AND    Apsa.Class                            = 'PMT'
        AND    Apsa.Org_Id                          = nvl(Pn_Org_Id,Apsa.Org_Id) --YWA artf2209651
        AND    Acrha.Gl_Posted_Date IS NOT NULL
        AND    Acrha.Cash_Receipt_History_Id = (SELECT MAX(Acrh1.Cash_Receipt_History_Id)
                                                FROM   Ar_Cash_Receipt_History_All Acrh1
                                                WHERE  Acrh1.Cash_Receipt_Id = Acrha.Cash_Receipt_Id
                                                AND    Acrh1.Org_Id          = Acrha.Org_Id
                                                AND    Acrh1.Gl_Date        <= Pd_End_Date
                                                AND    Acrh1.Gl_Posted_Date IS NOT NULL)
        AND    (Gcc.Segment2 = Pv_Region or Pv_Region is null)
        AND    Araa.Status IN ('UNAPP', 'ACC')
        AND    Araa.Gl_Date                         <= Pd_End_Date
        AND    Araa.Gl_Posted_Date IS NOT NULL
        AND    Nvl(Araa.Applied_Customer_Trx_Id, -1) = -1
        GROUP  BY Gcc.Segment2,
                  Rc.Customer_Number,
                  Rc.Customer_Name,
                  Apsa.Trx_Date,
                  Apsa.Due_Date,
                  Gcc.Segment1,
                  Acra.Receipt_Number,
                  Flvv_Class.Meaning,
                  Gcc.Segment3,
                  Flvv_Status.Meaning,
                  Apsa.Amount_In_Dispute,
                  Acra.Comments,
                  Apsa.Customer_Site_Use_Id,
                  Apsa.Customer_Id,
                  Rc.Customer_Class_Code,            -- Modif EMA du 21/04/2010
                  Rc.Customer_Category_Code,         -- Modif EMA du 21/04/2010
                  Apsa.Org_Id ; --YWA artf2209651
        ------------------------------------------------------------------
        -- Curseur de lecture des lignes de la table Dka_Encours_Client --
        ------------------------------------------------------------------
        CURSOR Cur_Fichier(Pv_Region VARCHAR2) IS
            SELECT Dec.Code_Client                                    || ';' ||
                   Dec.Client                                         || ';' ||
                   To_Char(Dec.Date_Mouvement, 'DD/MM/YYYY')          || ';' ||
                   To_Char(Dec.Echeance, 'DD/MM/YYYY')                || ';' ||
                   Replace(To_Char(Dec.Solde_Du), '.', ',')           || ';' ||
                   Dec.Charge_Recouvrement                            || ';' ||
                   Dec.Centre_Finance                                 || ';' ||
                   Dec.Tache_Majoritaire                              || ';' ||
                   Dec.Projet_Majoritaire                             || ';' ||
                   Dec.Societe                                        || ';' ||
                   Dec.Num_Piece                                      || ';' ||
                   Dec.Classe_Piece                                   || ';' ||
                   Dec.Compte_Client                                  || ';' ||
                   Dec.Site_Client                                    || ';' ||
                   Dec.Num_Client_Destinataire                        || ';' ||
                   Dec.Client_Destinataire                            || ';' ||
                   Dec.Statut                                         || ';' ||
                   Dec.Type_De_Mouvement                              || ';' ||
                   Replace(To_Char(Dec.Montant_En_Litige), '.', ',')  || ';' ||
                   --Dec.Commentaire                                    ||                    Modif EMA du 21/04/2010
                   Replace(Dec.Commentaire, ';', ' ')                 ||                   -- Modif EMA du 21/04/2010
                   Decode(Pv_Region, NULL, ';' || Dec.Centre_Gestion     ||                -- Modif EMA du 21/04/2010
                                           ';' || Dec.Lib_Centre_Gestion ||                -- Modif EMA du 21/04/2010
                                           ';' || Dec.Classe_Client      ||                -- Modif EMA du 21/04/2010
                                           ';' || Dec.Categorie_Client,                    -- Modif EMA du 21/04/2010
                                     NULL)                            Ligne                -- Modif EMA du 21/04/2010
            FROM   Dka_Encours_Client Dec
            WHERE  Dec.Request_Id = Fnd_Global.Conc_Request_Id;

        vv_region                       varchar2(100);
        Vn_Nombre                       NUMBER := 0;
        Vn_Factures                     NUMBER := 0;
        Vn_Reglements                   NUMBER := 0;
        Vn_Solde                        NUMBER;
        Vn_Montant1                     NUMBER;
        Vn_Montant2                     NUMBER;
        Vn_Montant3                     NUMBER;
        Vn_Montant4                     NUMBER;
        Vd_End_Date                     Gl_Period_Statuses.End_Date%TYPE;
        Vv_Entete                       VARCHAR2(400);
        Vv_Lib_Centre_Gestion           Fnd_Flex_Values_Tl.Description%TYPE;
        Vv_Classe_Client                Ar_Lookups.Meaning%TYPE;
        Vv_Categorie_Client             Ar_Lookups.Meaning%TYPE;

    BEGIN

        Pv_Errbuf  := NULL;
        Pn_Retcode := 0;

        Dka_Tools_Pkg.Put_Debug_Message('==> Début du traitement');
        vv_Region := get_region(Pn_org_id);
        Dka_Tools_Pkg.Put_Debug_Message('Région            : ' || vv_Region);
        Dka_Tools_Pkg.Put_Debug_Message('Période           : ' || Pv_Periode);

        ---------------------------------------------------------------
        -- Recherche de la date de fin de la dernière période fermée --
        ---------------------------------------------------------------
        Vd_End_Date := Get_Last_Date(Pv_Periode,pn_org_id);
        Dka_Tools_Pkg.Put_Debug_Message(/*'Date de fin de période : '*/'Date de fin de la dernière période : ' || To_Char(Vd_End_Date, 'DD/MM/YYYY')); -- OBE

        --------------------------------------------------------------
        -- Suppression des données de tous les traitements terminés --
        --------------------------------------------------------------
        IF Pv_Debug_Mode = 'N' THEN
            Dka_Tools_Pkg.Put_Debug_Message('Suppression des données des traitements précédents');

            DELETE FROM Dka_Encours_Client Dec
            WHERE  EXISTS (SELECT 'X'
                           FROM   Fnd_Concurrent_Requests Fcr,
                                  Fnd_Concurrent_Programs Fcp
                           WHERE  Fcr.Concurrent_Program_Id = Fcp.Concurrent_Program_Id
                           AND    Fcr.Phase_Code            = 'C'
                           AND    Fcp.Concurrent_Program_Name IN ('DKA_ENCOURS_RECOUVREMENT', 'DKA_ENCOURS_FRANCE')
                           AND    Fcr.Request_Id            = Dec.Request_Id);

            Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT || ' enregistrements supprimés');

            COMMIT;      -- <== Supprimer ce commit

        END IF;

        -----------------------------
        -- Traitement des factures --
        -----------------------------
        Dka_Tools_Pkg.Put_Debug_Message('Traitement des factures');
        FOR Rec_Factures in Cur_Factures(Vd_End_Date, Pn_Org_id, vv_Region) LOOP
            Vn_Solde    := 0;
            Vn_Montant1 := Nvl(Rec_Factures.Solde_Du, 0);
            Vn_Montant2 := 0;
            Vn_Montant3 := 0;
            Vn_Montant4 := 0;

            ----------------------------------------
            -- Recherche des règlements appliqués --
            ----------------------------------------
            BEGIN
                SELECT Nvl(Sum(Nvl(Araa.Acctd_Amount_Applied_To, 0)), 0)
                INTO   Vn_Montant2
                FROM   Ar_Receivable_Applications_All Araa
                WHERE  Araa.Applied_Customer_Trx_Id = Rec_Factures.Customer_Trx_Id
                AND    Araa.Org_Id                  = Rec_Factures.Org_Id --YWA artf2209651
                AND    Araa.Status                  = 'APP'
                AND    Araa.Gl_Date                <= Vd_End_Date
                AND    Araa.Gl_Posted_Date IS NOT NULL;
            END;

            ------------------------------------------------
            -- Cas du lettrage d'une facture par un avoir --
            ------------------------------------------------
            IF Rec_Factures.Type_De_Mouvement = 'Avoir' THEN
                BEGIN
                    SELECT Nvl(Sum(Nvl(-araa.Acctd_Amount_Applied_To, 0)), 0)
                    INTO   Vn_Montant3
                    FROM   Ar_Receivable_Applications_All Araa
                    WHERE  Araa.Customer_Trx_Id = Rec_Factures.Customer_Trx_Id
                    AND    Araa.Org_Id          = Rec_Factures.Org_Id --YWA artf2209651
                    AND    Araa.Status          = 'APP'
                    AND    Araa.Gl_Date        <= Vd_End_Date
                    AND    Araa.Gl_Posted_Date IS NOT NULL;
                END;
            END IF;

            -------------------------------
            -- Recherche des ajustements --
            -------------------------------
            BEGIN
                SELECT Nvl(Sum(Nvl(Aaa.Amount, 0)), 0)
                INTO   Vn_Montant4
                FROM   Ar_Adjustments_All    Aaa
                WHERE  Aaa.Customer_Trx_Id = Rec_Factures.Customer_Trx_Id
                AND    Aaa.Org_Id          = Rec_Factures.Org_Id --YWA artf2209651
                AND    Aaa.Status          = 'A'
                AND    Aaa.Gl_Date        <= Vd_End_Date
                AND    Aaa.Gl_Posted_Date IS NOT NULL;
            END;

            ------------------------
            -- Calcul du solde dû --
            ------------------------
            Vn_Solde := Vn_Montant1 - Vn_Montant2 - Vn_Montant3 + Vn_Montant4;

            ---------------------------------------------------------------------------------------------
            -- Si le solde dû est différent de 0, on insère une ligne dans la table DKA_ENCOURS_CLIENT --
            ---------------------------------------------------------------------------------------------
            IF Vn_Solde <> 0 THEN

                -------------------------------------
                -- Recherche du Projet Majoritaire --
                -------------------------------------
                Rec_Factures.Projet_Majoritaire := 'Pas de Projet';
                Rec_Factures.Centre_Finance     := NULL;
                Rec_Factures.tache_majoritaire  := NULL;
                BEGIN
                    IF Rec_Factures.id_tache_majoritaire IS NOT NULL THEN
                        SELECT Ppa.Segment1,
                               haou.name,
                               pt.task_number
                        INTO   Rec_Factures.Projet_Majoritaire,
                               Rec_Factures.Centre_finance,
                               Rec_Factures.tache_majoritaire
                        FROM   pa_tasks                  pt,
                               Pa_Projects_All           Ppa,
                               Hr_All_Organization_Units Haou
                        WHERE  pt.task_id                       = Rec_Factures.id_tache_majoritaire
                        AND    Ppa.Project_Id                   = pt.project_id
                        --AND    Ppa.Org_Id                       = Rec_Factures.Org_Id --YWA artf2209651 --Pn_Org_Id                  -- Modif EMA du 02/07/2009
                        AND    Ppa.Carrying_Out_Organization_Id = Haou.Organization_Id;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                         Rec_Factures.Projet_Majoritaire := 'Pas de Projet';
                         Rec_Factures.Centre_Finance     := NULL;
                         Rec_Factures.tache_majoritaire  := NULL;
                END;

                ------------------------------------------------
                -- Recherche du nom du chargé de recouvrement --
                ------------------------------------------------
                BEGIN
                    SELECT Ac.Name
                    INTO   Rec_Factures.Charge_Recouvrement
                    FROM   Hz_Customer_Profiles  Hcp,
                           Ar_Collectors         Ac
                    WHERE  Hcp.Cust_Account_Id = Rec_Factures.Customer_Id
                    AND    Hcp.Collector_Id    = Ac.Collector_Id
                    AND    Hcp.Site_Use_Id     = Nvl(Rec_Factures.Customer_Site_Use_Id, Hcp.Site_Use_Id);

                EXCEPTION
                    WHEN OTHERS THEN
                         Rec_Factures.Charge_Recouvrement := NULL;
                END;

                --------------------------------------
                -- Recherche du client destinataire --
                --------------------------------------
                BEGIN
                  SELECT Nvl(hcad.destinataire, Rc_Dest.Customer_Number), Rc_Dest.Customer_Name
                  INTO Rec_Factures.Num_Client_Destinataire, Rec_Factures.Client_Destinataire
                  FROM HZ_CUST_ACCT_SITES_all       hcas
                  JOIN HZ_CUST_ACCT_SITES_all_DFV   hcad     on (hcad.row_id = hcas.rowid)
                  -- 09/10/2018 NBO artf3037802 : INC0247321 analyser les problèmes de performance sur le traitement "DKA : Extraction En-cours Recouvrement"
                  --JOIN AR_Customers                 Rc_Dest  on (Rc_Dest.Customer_Number = nvl(hcad.destinataire, Rc_Dest.Customer_Number))
                  LEFT JOIN ar_customers rc_dest ON (rc_dest.customer_number = hcad.destinataire)
                  WHERE  hcas.cust_acct_site_id     = Rec_Factures.Cust_Acct_Site_Id
                  AND    hcas.Org_Id                = Rec_Factures.Org_Id; --YWA artf2209651 -pn_org_id;

                EXCEPTION
                    WHEN OTHERS THEN
                         Rec_Factures.Num_Client_Destinataire := Rec_Factures.Code_Client;
                         Rec_Factures.Client_Destinataire     := Rec_Factures.Client;
                END;

                ----------------------------------------------------------------------------------------------------
                -- Modif EMA du 21/04/2010 : Si l'extraction est de type France (Pv_Region IS NULL), on recherche --
                --                           le libellé du centre de gestion, la classe et la catégorie du client --
                ----------------------------------------------------------------------------------------------------
                Vv_Lib_Centre_Gestion := NULL;
                Vv_Classe_Client      := NULL;
                Vv_Categorie_Client   := NULL;

                IF vv_Region IS NULL THEN
                    -----------------------------------------------
                    -- Recherche du libellé du centre de gestion --
                    -----------------------------------------------
                    Vv_Lib_Centre_Gestion := Get_Lib_Centre_Gestion(Rec_Factures.Centre_Gestion);

                    -----------------------------------
                    -- Recherche de la classe client --
                    -----------------------------------
                    Vv_Classe_Client      := Get_Classe_Client(Rec_Factures.Classe_Client);

                    --------------------------------------
                    -- Recherche de la catégorie client --
                    --------------------------------------
                    Vv_Categorie_Client   := Get_Categorie_Client(Rec_Factures.Categorie_Client);

                END IF;

                ------------------------------------------------
                -- Insertion dans la table Dka_Encours_Client --
                ------------------------------------------------
                INSERT INTO Dka_Encours_Client
                    (Request_Id,
                     Centre_Gestion,
                     Lib_Centre_Gestion,                   -- Modif EMA du 21/04/2010
                     Code_Client,
                     Client,
                     Date_Mouvement,
                     Echeance,
                     Solde_Du,
                     Charge_Recouvrement,
                     Centre_Finance,
                     Tache_Majoritaire,
                     Projet_Majoritaire,
                     Societe,
                     Num_Piece,
                     Classe_Piece,
                     Compte_Client,
                     Site_Client,
                     Num_Client_Destinataire,
                     Client_Destinataire,
                     Statut,
                     Type_De_Mouvement,
                     Montant_En_Litige,
                     Commentaire,
                     Classe_Client,                        -- Modif EMA du 21/04/2010
                     Categorie_Client,                     -- Modif EMA du 21/04/2010
                     Creation_Date,
                     Created_By)
                VALUES
                    (Rec_Factures.Request_Id,
                     Rec_Factures.Centre_Gestion,
                     Vv_Lib_Centre_Gestion,                -- Modif EMA du 21/04/2010
                     Rec_Factures.Code_Client,
                     Rec_Factures.Client,
                     Rec_Factures.Date_Mouvement,
                     Rec_Factures.Echeance,
                     Vn_Solde,
                     Rec_Factures.Charge_Recouvrement,
                     Rec_Factures.Centre_finance,
                     Rec_Factures.tache_majoritaire,
                     Rec_Factures.Projet_Majoritaire,
                     Rec_Factures.Societe,
                     Rec_Factures.Num_Piece,
                     Rec_Factures.Classe_Piece,
                     Rec_Factures.Compte_Client,
                     Rec_Factures.Site_Client,
                     Rec_Factures.Num_Client_Destinataire,
                     Rec_Factures.Client_Destinataire,
                     Rec_Factures.Statut,
                     Rec_Factures.Type_De_Mouvement,
                     Rec_Factures.Montant_En_Litige,
                     Rec_Factures.Commentaire,
                     Vv_Classe_Client,                     -- Modif EMA du 21/04/2010
                     Vv_Categorie_Client,                  -- Modif EMA du 21/04/2010
                     SYSDATE,
                     Fnd_Global.User_Id);

                Vn_Nombre   := Vn_Nombre + 1;
                Vn_Factures := Vn_Factures + 1;
            END IF;
        END LOOP;

        Dka_Tools_Pkg.Put_Debug_Message(Vn_Factures || ' factures insérées dans la table Dka_Encours_Client');

        -------------------------------
        -- Traitement des règlements --
        -------------------------------
        Dka_Tools_Pkg.Put_Debug_Message('Traitement des règlements');
        FOR Rec_Reglements in Cur_Reglements(Vd_End_Date, pn_org_id, vv_Region) LOOP
            ------------------------
            -- Calcul du solde dû --
            ------------------------
            Vn_Solde := -Nvl(Rec_Reglements.Solde_Du, 0);

            ---------------------------------------------------------------------------------------------
            -- Si le solde dû est différent de 0, on insère une ligne dans la table DKA_ENCOURS_CLIENT --
            ---------------------------------------------------------------------------------------------
            IF Vn_Solde <> 0 THEN

                ------------------------------------------------
                -- Recherche du nom du chargé de recouvrement --
                ------------------------------------------------
                BEGIN
                    SELECT Ac.Name
                    INTO   Rec_Reglements.Charge_Recouvrement
                    FROM   Hz_Customer_Profiles       Hcp,
                           Ar_Collectors              Ac
                    WHERE  Hcp.Cust_Account_Id      = Rec_Reglements.Customer_Id
                    AND    Hcp.Collector_Id         = Ac.Collector_Id
                    AND    Nvl(Hcp.Site_Use_Id, -1) = Nvl(Rec_Reglements.Customer_Site_Use_Id, -1);

                EXCEPTION
                    WHEN OTHERS THEN
                         Rec_Reglements.Charge_Recouvrement := NULL;
                END;

                --------------------------------------
                -- Recherche du client destinataire --
                --------------------------------------
                BEGIN
                    -----------------------------------------------------
                    -- Le règlement est passé sur un site avec adresse --
                    -----------------------------------------------------
                    IF Rec_Reglements.Customer_Site_Use_Id IS NOT NULL THEN
                        SELECT Nvl(Raa.Attribute1, Rec_Reglements.Code_Client),
                               Rc.Customer_Name,
                               Hcsua.Location
                        INTO   Rec_Reglements.Num_Client_Destinataire,
                               Rec_Reglements.Client_Destinataire,
                               Rec_Reglements.Site_Client
                        FROM   Ra_Addresses_All        Raa,
                               Hz_Cust_Site_Uses_All   Hcsua,
                               Ra_Customers            Rc
                        WHERE  Hcsua.Site_Use_Id                               = Rec_Reglements.Customer_Site_Use_Id
                        AND    Hcsua.Org_Id                                    = Rec_Reglements.Org_Id --YWA artf2209651 --Pn_Org_Id
                        AND    Raa.Address_Id                                  = Hcsua.Cust_Acct_Site_Id
                        AND    Raa.Org_Id                                      = Hcsua.Org_Id
                        AND    Nvl(Raa.Attribute1, Rec_Reglements.Code_Client) = Rc.Customer_Number;
                    ELSE
                    -----------------------------------------------------
                    -- Le règlement est passé sur un site sans adresse --
                    -----------------------------------------------------
                        SELECT Nvl(Raa.Attribute1, Rec_Reglements.Code_Client),
                               Rc.Customer_Name,
                               NULL
                        INTO   Rec_Reglements.Num_Client_Destinataire,
                               Rec_Reglements.Client_Destinataire,
                               Rec_Reglements.Site_Client
                        FROM   Ra_Addresses_All   Raa,
                               Ra_Customers       Rc
                        WHERE  Raa.Customer_Id                                 = Rec_Reglements.Customer_Id
                        AND    Raa.Org_Id                                      = Rec_Reglements.Org_Id --YWA artf2209651 Pn_Org_Id
                        AND    Nvl(Raa.Attribute1, Rec_Reglements.Code_Client) = Rc.Customer_Number
                        AND    Rownum                                          = 1;
                    END IF;

                EXCEPTION
                    WHEN OTHERS THEN
                         Rec_Reglements.Num_Client_Destinataire := Rec_Reglements.Code_Client;
                         Rec_Reglements.Client_Destinataire     := Rec_Reglements.Client;
                         Rec_Reglements.Site_Client             := NULL;
                END;

                ----------------------------------------------------------------------------------------------------
                -- Modif EMA du 21/04/2010 : Si l'extraction est de type France (Pv_Region IS NULL), on recherche --
                --                           le libellé du centre de gestion, la classe et la catégorie du client --
                ----------------------------------------------------------------------------------------------------
                Vv_Lib_Centre_Gestion := NULL;
                Vv_Classe_Client      := NULL;
                Vv_Categorie_Client   := NULL;

                IF vv_Region IS NULL THEN
                    -----------------------------------------------
                    -- Recherche du libellé du centre de gestion --
                    -----------------------------------------------
                    Vv_Lib_Centre_Gestion := Get_Lib_Centre_Gestion(Rec_Reglements.Centre_Gestion);

                    -----------------------------------
                    -- Recherche de la classe client --
                    -----------------------------------
                    Vv_Classe_Client      := Get_Classe_Client(Rec_Reglements.Classe_Client);

                    --------------------------------------
                    -- Recherche de la catégorie client --
                    --------------------------------------
                    Vv_Categorie_Client   := Get_Categorie_Client(Rec_Reglements.Categorie_Client);

                END IF;

                ------------------------------------------------
                -- Insertion dans la table Dka_Encours_Client --
                ------------------------------------------------
                INSERT INTO Dka_Encours_Client
                    (Request_Id,
                     Centre_Gestion,
                     Lib_Centre_Gestion,                        -- Modif EMA du 21/04/2010
                     Code_Client,
                     Client,
                     Date_Mouvement,
                     Echeance,
                     Solde_Du,
                     Charge_Recouvrement,
                     Centre_Finance,
                     tache_majoritaire,
                     Projet_Majoritaire,
                     Societe,
                     Num_Piece,
                     Classe_Piece,
                     Compte_Client,
                     Site_Client,
                     Num_Client_Destinataire,
                     Client_Destinataire,
                     Statut,
                     Type_De_Mouvement,
                     Montant_En_Litige,
                     Commentaire,
                     Classe_Client,                             -- Modif EMA du 21/04/2010
                     Categorie_Client,                          -- Modif EMA du 21/04/2010
                     Creation_Date,
                     Created_By)
                VALUES
                    (Rec_Reglements.Request_Id,
                     Rec_Reglements.Centre_Gestion,
                     Vv_Lib_Centre_Gestion,                     -- Modif EMA du 21/04/2010
                     Rec_Reglements.Code_Client,
                     Rec_Reglements.Client,
                     Rec_Reglements.Date_Mouvement,
                     Rec_Reglements.Echeance,
                     Vn_Solde,
                     Rec_Reglements.Charge_Recouvrement,
                     Rec_Reglements.Centre_finance,
                     Rec_Reglements.tache_majoritaire,
                     Rec_Reglements.Projet_Majoritaire,
                     Rec_Reglements.Societe,
                     Rec_Reglements.Num_Piece,
                     Rec_Reglements.Classe_Piece,
                     Rec_Reglements.Compte_Client,
                     Rec_Reglements.Site_Client,
                     Rec_Reglements.Num_Client_Destinataire,
                     Rec_Reglements.Client_Destinataire,
                     Rec_Reglements.Statut,
                     Rec_Reglements.Type_De_Mouvement,
                     Rec_Reglements.Montant_En_Litige,
                     Rec_Reglements.Commentaire,
                     Vv_Classe_Client,                          -- Modif EMA du 21/04/2010
                     Vv_Categorie_Client,                       -- Modif EMA du 21/04/2010
                     SYSDATE,
                     Fnd_Global.User_Id);

                Vn_Nombre     := Vn_Nombre + 1;
                Vn_Reglements := Vn_Reglements + 1;

            END IF;

        END LOOP;

        Dka_Tools_Pkg.Put_Debug_Message(Vn_Reglements || ' règlemnts insérés dans la table Dka_Encours_Client');
        Dka_Tools_Pkg.Put_Debug_Message(Vn_Nombre || ' lignes insérées dans la table Dka_Encours_Client');

        COMMIT;

        ------------------------
        -- Edition du fichier --
        ------------------------
        Dka_Tools_Pkg.Put_Debug_Message('Edition du fichier');

        -- Modif EMA du 11/06/2009 : Ajout de l'entête de colonne
        Vv_Entete := 'Code Client;Client;Date Mouvement;Echéance;Solde dû;'||
                     'Chargé Recouvrement;Centre finance;Tâche;Projet Majoritaire;Société;'||
                     'Num. Pièce;Classe Pièce;Compte Client;Site Client;Num. Client Destinataire;'||
                     'Client Destinataire;Statut;Type de mouvement;Montant en litige;Commentaires';

        ------------------------------------------------------------------------------------------------------
        -- Modif EMA du 21/04/2010 : Dans le cas d'une édition de type France (Pv_Region IS NULL), l'entête --
        --                           est complétée avec le centre de gestion, le libellé du centre de       --
        --                           gestion, la classe client et la catégorie client                       --
        ------------------------------------------------------------------------------------------------------
        IF vv_Region IS NULL THEN
            Vv_Entete := Vv_Entete ||
                         ';Centre de Gestion;Libellé Centre de Gestion;Classe Client;Catégorie Client';
        END IF;

        Fnd_File.Put_Line(Fnd_File.output, Vv_Entete);

        FOR Rec_Fichier in Cur_Fichier(vv_region) LOOP
            Fnd_File.Put_Line(Fnd_File.output, Rec_Fichier.Ligne);
        END LOOP;

        -------------------------------------------
        -- Suppression des données du traitement --
        -------------------------------------------
        IF Pv_Debug_Mode = 'N' THEN
            Dka_Tools_Pkg.Put_Debug_Message('Suppression des données du traitement');
            DELETE FROM Dka_Encours_Client Dec
            WHERE  Dec.Request_Id = Fnd_Global.Conc_Request_Id;

            Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT || ' enregistrements supprimés');

            COMMIT;

        END IF;

        Dka_Tools_Pkg.Put_Debug_Message('==> Fin du traitement');

    EXCEPTION
        WHEN OTHERS THEN
             Pv_Errbuf  := SQLCODE || ' - ' || SUBSTR(SQLERRM, 1, 80);
             Pn_Retcode := 2;

    END Extraction_Encours;



    -- -----------------------------------------------------------------------------
    -- Nom              : Extraction_Avoirs
    -- Description      : Extraction des données pour la génération du fichier de
    --                    sortie justifiant les avoirs émis sur l'année civile
    --
    -- PARAMETRES       : Pv_Errbuf              Sortie Message d'erreur
    --                    Pn_Retcode             Sortie Code Retour de la procédure
    --                                                  '0' : Normal
    --                                                  '1' : Avertissement
    --                                                  '2' : Erreur
    --                    Pv_Debug_Mode Entrée          Mode debug
    --                    Pv_ORG_ID     Entrée          Unité Opérationnelle (ex : id de DRW001)
    --                    Pv_Periode    Entréée         Période
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Extraction_Avoirs(Pv_Errbuf         OUT  VARCHAR2,
                                Pn_Retcode        OUT  NUMBER,
                                Pv_Debug_Mode  IN      VARCHAR2,
                                Pn_Org_ID      IN      NUMBER,
                                Pv_Periode     IN      VARCHAR2)
    IS

        -----------------------------------
        -- Curseur de lecture des avoirs --
        -----------------------------------
        CURSOR Cur_Avoirs(Pd_Start_Date DATE, Pd_End_Date DATE, Pn_Org_ID IN NUMBER, Pv_Region VARCHAR2) IS
            --Factures et Avoirs avec un montant négatif
        SELECT Fnd_Global.Conc_Request_Id    Request_Id,
               Gcc.Segment2                  Centre_Gestion,
               ac.Customer_Number            Code_Client,
               ac.Customer_Name              Client,
               Apsa.Trx_Date                 Date_Mouvement,
               Apsa.Due_Date                 Echeance,
               Apsa.Amount_Due_Original      Montant,
               NULL                          Charge_Recouvrement,
               NULL                          Centre_finance,
               NULL                          id_projet_majoritaire,
               Rctad.TACHE_MAJORITAIRE       id_tache_majoritaire,
               NULL                          Tache_majoritaire,
               NULL                          Projet_Majoritaire,
               Gcc.Segment1                  Societe,
               Rcta.Trx_Number               Num_Piece,
               Flvv_Class.Meaning            Classe_Piece,
               Gcc.Segment3                  Compte_Client,
               Hcsua.Location                Site_Client,
               NULL                          Num_Client_Destinataire,
               NULL                          Client_Destinataire,
               Flvv_Status.Meaning           Statut,
               Rctta.NAME        Type_De_Mouvement, --Substr(Rctta.NAME, 6)         Type_De_Mouvement, --YWA artf2209651 
               Apsa.Amount_In_Dispute        Montant_En_Litige,
               Rcta.Comments                 Commentaire,
               Apsa.Customer_Site_Use_Id     Customer_Site_Use_Id,
               Apsa.Customer_Id              Customer_Id,
               Hcsua.Cust_Acct_Site_Id       Cust_Acct_Site_Id,
               Rcta.Customer_Trx_Id          Customer_Trx_Id,
               null                          date_lettrage,
               Apsa.Org_Id                   --YWA artf2209651
        FROM   Ar_Payment_Schedules_all          Apsa
        join   Ra_Customer_Trx_All           Rcta          on (Apsa.Customer_Trx_Id  = Rcta.Customer_Trx_Id AND Apsa.Org_Id = Rcta.Org_Id)
        join   Ra_Customer_Trx_All_DFV       Rctad         on (rctad.row_id          = rcta.rowid)
        join   Ra_Cust_Trx_Types_All         Rctta         on (Rcta.Cust_Trx_Type_Id = Rctta.Cust_Trx_Type_Id AND Rcta.Org_Id = Rctta.Org_Id)
        join   Ra_Cust_Trx_Line_Gl_Dist_All  Rctlgda       on (Rcta.Customer_Trx_Id  = Rctlgda.Customer_Trx_Id AND Rcta.Org_Id = Rctlgda.Org_Id)
        join   Gl_Code_Combinations          Gcc           on (Rctlgda.Code_Combination_Id = Gcc.Code_Combination_Id)
        join   Hz_Cust_Site_Uses_All         Hcsua         on (Apsa.Customer_Site_Use_Id = Hcsua.Site_Use_Id AND Apsa.Org_Id = Hcsua.Org_Id)
        join   AR_CUSTOMERS                  ac            on (Apsa.Customer_Id = ac.Customer_id)
        join   Fnd_Lookup_Values_Vl          Flvv_Class    on (Rctta.Type = Flvv_Class.Lookup_Code AND Flvv_Class.Lookup_Type = 'INV/CM')
        join   Fnd_Lookup_Values_Vl          Flvv_Status   on (Apsa.Status = Flvv_Status.Lookup_Code AND Flvv_Status.Lookup_Type = 'PAYMENT_SCHEDULE_STATUS')
        WHERE  Apsa.Class                  = 'CM'
        AND    Apsa.Org_Id                 =  NVL(Pn_Org_Id, Apsa.Org_id) --Pn_Org_Id -- OBE
        AND    Rcta.Complete_Flag          = 'Y'
        AND    Rctlgda.Account_Class       = 'REC'
        AND    Rcta.Trx_Date          BETWEEN Pd_Start_Date AND Pd_End_Date
        AND    Rctlgda.Gl_Posted_Date IS NOT NULL
        AND    Apsa.Amount_Due_Original   <= 0
        AND    Gcc.Segment2                = Nvl(Pv_Region, Gcc.Segment2);             -- Modif EMA du 21/04/2010


        -----------------------------------------------------------------
        -- Curseur de lecture des lignes de la table Dka_Avoirs_Client --
        -----------------------------------------------------------------
        CURSOR Cur_Fichier(pv_region in varchar2) IS
            SELECT Dac.Code_Client                                    || ';' ||
                   Dac.Client                                         || ';' ||
                   To_Char(Dac.Date_Mouvement, 'DD/MM/YYYY')          || ';' ||
                   To_Char(Dac.Echeance, 'DD/MM/YYYY')                || ';' ||
                   Replace(To_Char(Dac.Montant), '.', ',')            || ';' ||
                   Dac.Charge_Recouvrement                            || ';' ||
                   Dac.Centre_Finance                                 || ';' ||
                   Dac.Tache_Majoritaire                              || ';' ||
                   Dac.Projet_Majoritaire                             || ';' ||
                   Dac.Societe                                        || ';' ||
                   Dac.Num_Piece                                      || ';' ||
                   Dac.Classe_Piece                                   || ';' ||
                   Dac.Compte_Client                                  || ';' ||
                   Dac.Site_Client                                    || ';' ||
                   Dac.Num_Client_Destinataire                        || ';' ||
                   Dac.Client_Destinataire                            || ';' ||
                   Dac.Statut                                         || ';' ||
                   Dac.Type_De_Mouvement                              || ';' ||
                   Replace(To_Char(Dac.Montant_En_Litige), '.', ',')  || ';' ||
                   --Dac.Commentaire                                    ||                     Modif EMA du 21/04/2010
                   Replace(Dac.Commentaire, ';', ' ')                 || ';' ||             -- Modif EMA du 21/04/2010
                   to_char(Dac.date_lettrage, 'DD/MM/YYYY')           || --|| ';' || --YWA artf2209651 
                   Decode(Pv_Region, NULL, ';' || Dac.Centre_Gestion  ||                    -- Modif EMA du 21/04/2010
                                           ';' || Dac.Lib_Centre_Gestion,                   -- Modif EMA du 21/04/2010
                                     NULL)                            Ligne                 -- Modif EMA du 21/04/2010
            FROM   Dka_Avoirs_Client Dac
            WHERE  Dac.Request_Id = Fnd_Global.Conc_Request_Id;

        vv_region                       varchar2(100);
        Vd_Start_Date                   Gl_Period_Statuses.Start_Date%TYPE;
        Vd_End_Date                     Gl_Period_Statuses.End_Date%TYPE;
        Vv_Lib_Centre_Gestion           Fnd_Flex_Values_Tl.Description%TYPE;

        Vn_Nombre                       NUMBER := 0;
        Vv_Entete                       VARCHAR2(400);


    BEGIN

        Pv_Errbuf  := NULL;
        Pn_Retcode := 0;

        Dka_Tools_Pkg.Put_Debug_Message('==> Début du traitement');
        vv_Region := get_region(Pn_org_id);
        Dka_Tools_Pkg.Put_Debug_Message('Région            : ' || vv_Region);
        Dka_Tools_Pkg.Put_Debug_Message('Periode           : ' || Pv_Periode);

        ---------------------------------------------------------------
        -- Recherche de la date de fin de la dernière période fermée --
        ---------------------------------------------------------------
        Vd_End_Date := Get_Last_Date(Pv_Periode,pn_org_id);
        Dka_Tools_Pkg.Put_Debug_Message(/*'Date de fin de période : '*/'Date de fin de la dernière période : ' || To_Char(Vd_End_Date, 'DD/MM/YYYY')); -- OBE 

        -----------------------------------------------------
        -- Recherche de la date de début de l'année civile --
        -----------------------------------------------------
        BEGIN
            SELECT Trunc(Vd_End_Date, 'YYYY')
            INTO   Vd_Start_Date
            FROM   Dual;
        END;
        Dka_Tools_Pkg.Put_Debug_Message(/*'Date de début de période : '*/'Date de début de l''année : ' || To_Char(Vd_Start_Date, 'DD/MM/YYYY')); -- OBE

        --------------------------------------------------------------
        -- Suppression des données de tous les traitements terminés --
        --------------------------------------------------------------
        IF Pv_Debug_Mode = 'N' THEN
            Dka_Tools_Pkg.Put_Debug_Message('Suppression des données des traitements précédents');

            DELETE FROM Dka_Avoirs_Client Dac
            WHERE  EXISTS (SELECT 'X'
                           FROM   Fnd_Concurrent_Requests Fcr,
                                  Fnd_Concurrent_Programs Fcp
                           WHERE  Fcr.Concurrent_Program_Id = Fcp.Concurrent_Program_Id
                           AND    Fcr.Phase_Code            = 'C'
                           AND    Fcp.Concurrent_Program_Name IN ('DKA_AVOIRS_RECOUVREMENT', 'DKA_AVOIRS_FRANCE')
                           AND    Fcr.Request_Id            = Dac.Request_Id);

            Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT || ' enregistrements supprimés');

            COMMIT;


        END IF;

        ---------------------------
        -- Traitement des avoirs --
        ---------------------------
        Dka_Tools_Pkg.Put_Debug_Message('Traitement des avoirs');
        FOR Rec_Avoirs in Cur_Avoirs(Vd_Start_Date, Vd_End_Date, pn_org_id, vv_Region) LOOP
            -------------------------------------
            -- Recherche du Projet Majoritaire --
            -------------------------------------
            Rec_Avoirs.Projet_Majoritaire := 'Pas de Projet';
            Rec_Avoirs.Centre_finance     := NULL;
            Rec_Avoirs.Tache_majoritaire  := NULL;

            BEGIN
                IF Rec_Avoirs.id_tache_majoritaire IS NOT NULL THEN
                    SELECT Ppa.Segment1,
                           haou.name,
                           pt.task_number
                    INTO   Rec_Avoirs.Projet_Majoritaire,
                           Rec_Avoirs.Centre_finance,
                           Rec_Avoirs.Tache_majoritaire
                    FROM   pa_tasks                  pt,
                           Pa_Projects_All           Ppa,
                           Hr_All_Organization_Units Haou
                    WHERE  pt.task_id                       = Rec_Avoirs.id_tache_majoritaire
                    AND    Ppa.Project_Id                   = pt.Project_Id
                    --AND    Ppa.Org_Id                       = Rec_Avoirs.Org_Id                   --YWA artf2209651 --Pn_Org_Id                 -- Modif EMA du 02/07/2009
                    AND    Ppa.Carrying_Out_Organization_Id = Haou.Organization_Id;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    Rec_Avoirs.Projet_Majoritaire := 'Pas de Projet';
                    Rec_Avoirs.Centre_finance     := NULL;
                    Rec_Avoirs.Tache_majoritaire  := NULL;
            END;

            ------------------------------------------------
            -- Recherche du nom du chargé de recouvrement --
            ------------------------------------------------
            BEGIN
                select name INTO  Rec_Avoirs.Charge_Recouvrement
                from (
                  SELECT *                                
                  FROM   Hz_Customer_Profiles  Hcp, Ar_Collectors         Ac
                  WHERE  Hcp.Cust_Account_Id = Rec_Avoirs.Customer_Id
                  AND    Hcp.Collector_Id    = Ac.Collector_Id
                  AND    Hcp.Site_Use_Id     = Nvl(Rec_Avoirs.Customer_Site_Use_Id, Hcp.Site_Use_Id)
                  order by Hcp.Site_Use_Id  nulls last 
                )
                where rownum=1;

            EXCEPTION
                WHEN OTHERS THEN
                    Rec_Avoirs.Charge_Recouvrement := NULL;
            END;

            --------------------------------------
            -- Recherche du client destinataire --
            --------------------------------------
            BEGIN                
                SELECT Nvl(hcad.destinataire, Rc_Dest.Customer_Number), Rc_Dest.Customer_Name
                INTO   Rec_Avoirs.Num_Client_Destinataire, Rec_Avoirs.Client_Destinataire
                FROM HZ_CUST_ACCT_SITES_all       hcas
                JOIN HZ_CUST_ACCT_SITES_all_DFV   hcad     on (hcad.row_id = hcas.rowid)
                JOIN AR_Customers                 Rc_Dest  on (Rc_Dest.Customer_Number = nvl(hcad.destinataire, Rc_Dest.Customer_Number))
                WHERE  hcas.cust_acct_site_id     = Rec_Avoirs.cust_acct_site_id
                AND    hcas.Org_Id                =  Rec_Avoirs.Org_Id;                   --YWA artf2209651 -- pn_org_id;
            EXCEPTION
                WHEN OTHERS THEN
                    Rec_Avoirs.Num_Client_Destinataire := Rec_Avoirs.Code_Client;
                    Rec_Avoirs.Client_Destinataire     := Rec_Avoirs.Client;
            END;

            --------------------------------------
            -- Recherche de la date de lettrage --
            --------------------------------------
            IF Rec_Avoirs.Type_De_Mouvement = 'Avoir' THEN
                BEGIN
                    SELECT Trunc(Max(Araa.Apply_Date))
                    INTO   Rec_Avoirs.Date_Lettrage
                    FROM   Ar_Receivable_Applications_All Araa
                    WHERE  Araa.Customer_Trx_Id = Rec_Avoirs.Customer_Trx_Id
                    AND    Araa.Status          = 'APP'
                    AND    Araa.Gl_Date        <= Vd_End_Date
                    AND    Araa.Gl_Posted_Date IS NOT NULL;
                END;
            ELSE
                BEGIN
                    SELECT Trunc(Max(Araa.Apply_Date))
                    INTO   Rec_Avoirs.Date_Lettrage
                    FROM   Ar_Receivable_Applications_All Araa
                    WHERE  Araa.Applied_Customer_Trx_Id = Rec_Avoirs.Customer_Trx_Id
                    AND    Araa.Status                  = 'APP'
                    AND    Araa.Gl_Date                <= Vd_End_Date
                    AND    Araa.Gl_Posted_Date IS NOT NULL;
                END;
            END IF;

            --SELECT Trunc(Max(Araa.Apply_Date))
            --INTO   Rec_Avoirs.Date_Lettrage
            --FROM   Ar_Receivable_Applications_All Araa
            --WHERE  (Araa.Applied_Customer_Trx_Id = Rec_Avoirs.Customer_Trx_Id
            --        OR Araa.Customer_Trx_Id = Rec_Avoirs.Customer_Trx_Id)
            --AND    Araa.Status                  = 'APP'
            ----AND    Araa.Gl_Date                <= Vd_End_Date
            --AND    Araa.Gl_Posted_Date IS NOT NULL;


            ----------------------------------------------------------------------------------------------------
            -- Modif EMA du 21/04/2010 : Si l'extraction est de type France (Pv_Region IS NULL), on recherche --
            --                           le libellé du centre de gestion                                      --
            ----------------------------------------------------------------------------------------------------
            Vv_Lib_Centre_Gestion := NULL;

            IF vv_Region IS NULL THEN
                -----------------------------------------------
                -- Recherche du libellé du centre de gestion --
                -----------------------------------------------
                Vv_Lib_Centre_Gestion := Get_Lib_Centre_Gestion(Rec_Avoirs.Centre_Gestion);

            END IF;

            ------------------------------------------------------------
            -- Insertion des données dans la table Dka_Avoirs_Clients --
            ------------------------------------------------------------
            BEGIN
                INSERT INTO Dka_Avoirs_Client
                    (Request_Id,
                     Centre_Gestion,
                     Lib_Centre_Gestion,                        -- Modif EMA du 21/04/2010
                     Code_Client,
                     Client,
                     Date_Mouvement,
                     Echeance,
                     Montant,
                     Charge_Recouvrement,
                     Centre_Finance,
                     Tache_Majoritaire,
                     Projet_Majoritaire,
                     Societe,
                     Num_Piece,
                     Classe_Piece,
                     Compte_Client,
                     Site_Client,
                     Num_Client_Destinataire,
                     Client_Destinataire,
                     Statut,
                     Type_De_Mouvement,
                     Montant_En_Litige,
                     Commentaire,
                     Creation_Date,
                     Created_By)
                VALUES
                    (Rec_Avoirs.Request_Id,
                     Rec_Avoirs.Centre_Gestion,
                     Vv_Lib_Centre_Gestion,                     -- Modif EMA du 21/04/2010
                     Rec_Avoirs.Code_Client,
                     Rec_Avoirs.Client,
                     Rec_Avoirs.Date_Mouvement,
                     Rec_Avoirs.Echeance,
                     Rec_Avoirs.Montant,
                     Rec_Avoirs.Charge_Recouvrement,
                     Rec_Avoirs.Centre_Finance,
                     Rec_Avoirs.Tache_Majoritaire,
                     Rec_Avoirs.Projet_Majoritaire,
                     Rec_Avoirs.Societe,
                     Rec_Avoirs.Num_Piece,
                     Rec_Avoirs.Classe_Piece,
                     Rec_Avoirs.Compte_Client,
                     Rec_Avoirs.Site_Client,
                     Rec_Avoirs.Num_Client_Destinataire,
                     Rec_Avoirs.Client_Destinataire,
                     Rec_Avoirs.Statut,
                     Rec_Avoirs.Type_De_Mouvement,
                     Rec_Avoirs.Montant_En_Litige,
                     Rec_Avoirs.Commentaire,
                     SYSDATE,
                     Fnd_Global.User_Id);

                Vn_Nombre := Vn_Nombre + 1;
            END;

        END LOOP;

        Dka_Tools_Pkg.Put_Debug_Message(Vn_Nombre || ' avoirs insérés dans la table Dka_Avoirs_Client');

        COMMIT;

        ------------------------
        -- Edition du fichier --
        ------------------------
        Dka_Tools_Pkg.Put_Debug_Message('Edition du fichier');

        -- Modif EMA du 11/06/2009 : Ajout de l'entête de colonne
        Vv_Entete := 'Code Client;Client;Date Mouvement;Echéance;Solde dû;'||
                     'Chargé Recouvrement;Centre Finance;Tâche;Projet Majoritaire;Société;'||
                     'Num. Pièce;Classe Pièce;Compte Client;Site Client;Num. Client Destinataire;'||
                     'Client Destinataire;Statut;Type de mouvement;Montant en litige;Commentaires;Date de lettrage';
        /*IF vv_Region IS NULL THEN
            Vv_Entete := Vv_Entete ||
                         ';Centre de Gestion;Libellé Centre de Gestion';
        END IF;*/      --YWA artf2209651
        ------------------------------------------------------------------------------------------------------
        -- Modif EMA du 21/04/2010 : Dans le cas d'une édition de type France (Pv_Region IS NULL), l'entête --
        --                           est complétée avec le centre de gestion, le libellé du centre de       --
        --                           gestion                                                                --
        ------------------------------------------------------------------------------------------------------
        IF vv_Region IS NULL THEN
            Vv_Entete := Vv_Entete ||
                         ';Centre de Gestion;Libellé Centre de Gestion';
        END IF;

        Fnd_File.Put_Line(Fnd_File.output, Vv_Entete);
        
        FOR Rec_Fichier in Cur_Fichier(vv_region) LOOP
            Fnd_File.Put_Line(Fnd_File.output, Rec_Fichier.Ligne);
        END LOOP;

        -------------------------------------------
        -- Suppression des données du traitement --
        -------------------------------------------
        IF Pv_Debug_Mode = 'N' THEN
            Dka_Tools_Pkg.Put_Debug_Message('Suppression des données du traitement');
            DELETE FROM Dka_Avoirs_Client Dac
            WHERE  Dac.Request_Id = Fnd_Global.Conc_Request_Id;

            Dka_Tools_Pkg.Put_Debug_Message('==> ' || SQL%ROWCOUNT || ' enregistrements supprimés');

            COMMIT;

        END IF;

        COMMIT;

        Dka_Tools_Pkg.Put_Debug_Message('==> Fin du traitement');

    EXCEPTION
        WHEN OTHERS THEN
             Pv_Errbuf  := SQLCODE || ' - ' || SUBSTR(SQLERRM, 1, 80);
             Pn_Retcode := 2;

    END Extraction_Avoirs;



    -- -----------------------------------------------------------------------------
    -- Nom              : Extraction_Ratios
    -- Description      : Extraction des données pour la génération du fichier de
    --                    sortie justifiant les ratios clients
    --
    -- PARAMETRES       : Pv_Errbuf                Sortie Message d'erreur
    --                    Pn_Retcode               Sortie Code Retour de la procédure
    --                                                    '0' : Normal
    --                                                    '1' : Avertissement
    --                                                    '2' : Erreur
    --                    Pv_Debug_Mode     Entrée        Mode debug
    --                    Pv_Periode        Entrée        Période
    --                    Pv_ORG_ID         Entrée        Unité Opérationnelle (ex : id de DRW001)
    --                    Pv_Societe_De     Entrée        Société de
    --                    Pv_Societe_A      Entrée        Société à
    --                    Pv_Detail_Societe Entrée        Niveau de détail société
    --                    Pv_Charge_De      Entrée        Chargé de recouvrement De
    --                    Pv_Charge_A       Entrée        Chargé de recouvrement A
    --                    Pv_Detail_Charge  Entrée        Niveau de détail Chargé de recouvrement
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Extraction_Ratios(Pv_Errbuf            OUT  VARCHAR2,
                                Pn_Retcode           OUT  NUMBER,
                                Pv_Debug_Mode     IN      VARCHAR2,
                                Pv_Periode        IN      VARCHAR2,
                                Pn_Org_ID         IN      NUMBER,
                                Pv_Societe_De     IN      VARCHAR2,
                                Pv_Societe_A      IN      VARCHAR2,
                                Pv_Detail_Societe IN      VARCHAR2,
                                Pv_Charge_De      IN      VARCHAR2,
                                Pv_Charge_A       IN      VARCHAR2,
                                Pv_Detail_Charge  IN      VARCHAR2)
    IS
    BEGIN
      NULL;
    END Extraction_Ratios;

END DKA_SARRECOUVREMENT_PKG;
/
SHOW ERRORS
EXIT
