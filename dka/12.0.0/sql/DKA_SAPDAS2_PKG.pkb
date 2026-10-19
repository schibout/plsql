CREATE OR REPLACE PACKAGE BODY Dka_Sapdas2_Pkg AS

  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : DALKIA Oracle Applications
  -- NOM              : DKA_SAPDAS2_PKG
  -- DESCRIPTION      : DKA_SAPDAS2_PKG Package Body
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
  -- 04/04/2007 EMA Les données composant la déclaration ne doivent être générées
  --                que dans le fichier de sortie et les messages d'erreur 
  --                uniquement dans le fichier journal.
  --                Ajout des fonctions Put_Out_Message et Put_Log_Message pour 
  --                affichage des messages dans la sortie ou la log uniquement.
  -- 15/12/2008 JVI Evolution nouveaux codes APE : passage de 4 à 5 caractères 
  -- 20/08/2015 JJA Correctif : seuil paramétrable via DKA_PARAMETERS
  -- 25/11/2016 NSI Migration R12
  -- -----------------------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


  -- -----------------------------------------------------------------------------
  -- Nom              : Put_Out_Message
  -- Description      : Eciture d'une chaine de caractères dans le fichier de
  --                    sortie.
  --
  -- PARAMETRES       : Pv_Message     Entrée         Message
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       : 
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Put_Out_Message(Pv_Message IN VARCHAR2) 
  IS
  BEGIN
    Fnd_File.Put_Line(Fnd_File.Output, Pv_Message);
  END;

  -- -----------------------------------------------------------------------------
  -- Nom              : Put_Log_Message
  -- Description      : Eciture d'une chaine de caractères dans le fichier
  --                    journal.
  --
  -- PARAMETRES       : Pv_Message     Entrée         Message
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       : 
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Put_Log_Message(Pv_Controle IN VARCHAR2,
                            Pv_Message  IN VARCHAR2) IS

  BEGIN
    IF Pv_Controle = 'Y' THEN
      Fnd_File.Put_Line(Fnd_File.Output, Pv_Message);
    ELSE
      Fnd_File.Put_Line(Fnd_File.Log, Pv_Message);
    END IF;
  END;

  -- -----------------------------------------------------------------------------
  -- Nom              : Est_Numerique
  -- Description      : Contrôle qu'une variable est numérique
  --
  -- PARAMETRES       : Pv_Chaine      Entrée         Chaine à vérifier
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       : 
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  FUNCTION Est_Numerique(Pv_Chaine IN VARCHAR2) RETURN BOOLEAN
  IS
    Vn_Nombre                       NUMBER;
  BEGIN

    SELECT To_Number(Pv_Chaine) 
    INTO   Vn_Nombre
    FROM   Dual;

    IF Vn_Nombre IS NOT NULL THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END;

  -- -----------------------------------------------------------------------------
  -- Nom              : Conversion_Chaine
  -- Description      : Supprime tous les caractères "parasites"
  --
  -- PARAMETRES       : Pv_Chaine      Entrée         Chaine à convertir
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       : 
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  FUNCTION Conversion_Chaine(Pv_Chaine VARCHAR2) RETURN VARCHAR2
  IS
    Vv_Conversion_In                VARCHAR2(255);
    Vv_Conversion_Out               VARCHAR2(255);
    Vv_Chaine_Out                   VARCHAR2(250);
  
    Vn_Position                     INTEGER;
    Vb_Continue                     BOOLEAN;
    Vv_Chaine_Avant                 VARCHAR2(255);
    Vv_Chaine_Apres                 VARCHAR2(255);

  BEGIN
    Vv_Conversion_In  := 'abcdefghijklmnopqrstuvwxyzÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜYÝàáâãäåæçèéêëìíîïñòóôõöùúûüýÿ&,./!"#$%''()*+-:;<=>?@[\]^_`{|}~¡¢£¥§©ª«¬­®¯°±²³µ¶·¹º»Ð×ØÞßð÷øþ';
    Vv_Conversion_Out := 'ABCDEFGHIJKLMNOPQRSTUVWXYZAAAAAAACEEEEIIIINOOOOOUUUUYYAAAAAAACEEEEIIIINOOOOOUUUUyy&                                                             ';

    --------------------------------------------
    -- Suppression des caractères "parasites" --
    --------------------------------------------
    SELECT Translate(Pv_Chaine, Vv_Conversion_In, Vv_Conversion_Out)
    INTO   Vv_Chaine_Out
    FROM   Dual;

    ------------------------------------------------------------------
    -- Suppression des doubles espaces dans la chaine de caractères --
    ------------------------------------------------------------------
    Vb_Continue     := TRUE;
    Vv_Chaine_Avant := NULL;
    Vv_Chaine_Apres := Trim(Vv_Chaine_Out);        
    
    WHILE Vb_Continue LOOP
      Vn_Position := Nvl(Instr(Vv_Chaine_Apres, '  '), 0);
      IF Vn_Position = 0 THEN
        Vb_Continue := FALSE;
      ELSE
        Vv_Chaine_Avant := Vv_Chaine_Avant || Substr(Vv_Chaine_Apres, 1, Vn_Position);
        Vv_Chaine_Apres := Ltrim(Substr(Vv_Chaine_Apres, Vn_Position, 255));
      END IF;
    END LOOP;

    Vv_Chaine_Out := Rtrim(Vv_Chaine_Avant || Vv_Chaine_Apres);

    RETURN(Vv_Chaine_Out);
  END;

  -- -----------------------------------------------------------------------------
  -- Nom              : Extract_Data
  -- Description      : Extraction des données pour l'édition de la DAS2;
  --
  -- PARAMETRES       : Pn_Request_Id  Entrée         Numéro de traitement
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Extract_Data(Pn_Request_Id  IN NUMBER) IS
         
    -------------------------------------------------------------------
    -- Curseur d'extraction et de formatage de la ligne d'entête 010 --
    -------------------------------------------------------------------
    CURSOR Cur_010 IS 
    SELECT Siren_Entreprise || 
           Z1 || 
           Type_Enregistrement || 
           Z2 || 
           Code_Ape || 
           Z3 || 
           Raison_Sociale || 
           Adresse_Complement || 
           Z4 || 
           Adresse_Voie || 
           Code_Insee || 
           Z5 || 
           Commune || 
           Code_Postal || 
           Z6 || 
           Bureau_Distributeur || 
           Z7 || 
           Type_Fichier || 
           Siret_Etablissement || 
           Z8 || 
           Adresse_Complement_Etab || 
           Z9 || 
           Adresse_Voie_Etab || 
           Code_Insee_Etab || 
           Z10 || 
           Commune_Etab || 
           Code_Postal_Etab || 
           Z11 || 
           Bureau_Distributeur_Etab || 
           Z12 || 
           Z13   Enreg_010
    FROM   Dka_Sapdas2_010
    WHERE  Request_Id = Pn_Request_Id;

    -------------------------------------------------------------------
    -- Curseur d'extraction et de formatage de la ligne d'entête 020 --
    -------------------------------------------------------------------
    CURSOR Cur_020 IS
    SELECT Siren_Etablissement || 
           Nic_Etablissement || 
           Code_Section_Etablissement || 
           Validite || 
           Type_Dads || 
           Type_Enregistrement || 
           Z1 || 
           Code_Ape || 
           Z2 || 
           Siren_01_Jan || 
           Nic_01_Jan || 
           Z3 || 
           Raison_Sociale || 
           Adresse_Complement || 
           Z4 || 
           Adresse_Voie || 
           Code_Insee || 
           Z5 || 
           Commune || 
           Code_Postal || 
           Z6 || 
           Bureau_Distributeur || 
           Profession || 
           Z7 || 
           Code_Taxe_Salaires || 
           Z8    Enreg_020
    FROM   Dka_Sapdas2_020
    WHERE  Request_Id = Pn_Request_Id;

    -----------------------------------------------------------------------
    -- Curseur d'extraction et de formatage de la ligne d'honoraires 210 --
    -----------------------------------------------------------------------
    CURSOR Cur_210 IS
    SELECT Siren_Etablissement || 
           Nic_Etablissement || 
           Code_Section_Etablissement || 
           Validite || 
           Type_Dads || 
           Type_Enregistrement || 
           Siret_Beneficiaire || 
           Nom || 
           Prenom || 
           Raison_Sociale || 
           Profession || 
           Adresse_Complement || 
           Z1 || 
           Adresse_Voie || 
           Code_Insee || 
           Z2 || 
           Commune || 
           Code_Postal || 
           Z3 || 
           Bureau_Distributeur || 
           Lpad(To_Char(Sum(Dhon_H)), 10, '0') || 
           Lpad(To_Char(Sum(Dcom_C)), 10, '0') || 
           Lpad(To_Char(Sum(Dco_Co)), 10, '0') || 
           Lpad(To_Char(Sum(Dris_R)), 10, '0') || 
           Lpad(To_Char(Sum(Dje_Jp)), 10, '0') || 
           Lpad(To_Char(Sum(Dda_Da)), 10, '0') || 
           Lpad(To_Char(Sum(Ddi_Di)), 10, '0') || 
           Lpad(To_Char(Sum(Dau_Ar)), 10, '0') || 
           Lpad(To_Char(Sum(Inde)), 10, '0') || 
           Lpad(To_Char(Sum(Avan)), 10, '0') || 
           Lpad(To_Char(Sum(Rete)), 10, '0') || 
           Nat_Avan_Nour || 
           Nat_Avan_Loge || 
           Nat_Avan_Voit || 
           Nat_Avan_Autr || 
           Nat_Avan_Ntic || 
           Nat_Inde_Forf || 
           Nat_Inde_Remb || 
           Nat_Inde_Pris || 
           Nat_Tva_Redui || 
           Nat_Tva_Dispe || 
           Lpad(To_Char(Sum(Tva_Nette)), 10, '0') || 
           Z4    Enreg_210
    FROM   Dka_Sapdas2_210
    WHERE  Request_Id = Pn_Request_Id
    GROUP BY Siren_Etablissement,
             Nic_Etablissement,
             Code_Section_Etablissement,
             Validite,
             Type_Dads,
             Type_Enregistrement,
             Siret_Beneficiaire,
             Nom,
             Prenom,
             Raison_Sociale,
             Profession,
             Adresse_Complement,
             Z1,
             Adresse_Voie,
             Code_Insee,
             Z2,
             Commune,
             Code_Postal,
             Z3,
             Bureau_Distributeur,
             Nat_Avan_Nour,
             Nat_Avan_Loge,
             Nat_Avan_Voit,
             Nat_Avan_Autr,
             Nat_Avan_Ntic,
             Nat_Inde_Forf,
             Nat_Inde_Remb,
             Nat_Inde_Pris,
             Nat_Tva_Redui,
             Nat_Tva_Dispe,
             Z4;

    -------------------------------------------------------------------
    -- Curseur d'extraction et de formatage de la ligne de total 300 --
    -------------------------------------------------------------------
    CURSOR Cur_300 IS
    SELECT Siren_Etablissement || 
           Nic_Etablissement || 
           Code_Section_Etablissement || 
           Validite || 
           Type_Dads || 
           Type_Enregistrement || 
           Z1 || 
           Lpad(To_Char(Base_Brute_Fiscale), 12, '0') || 
           Lpad(To_Char(Remunerations_Nettes), 12, '0') || 
           Lpad(To_Char(Avantages_Nature), 12, '0') || 
           Lpad(To_Char(Frais_Professionnels), 12, '0') || 
           Lpad(To_Char(Cheques_Vacances), 12, '0') || 
           Lpad(To_Char(Total_Imposable), 12, '0') || 
           Lpad(To_Char(Total_Base_Imposable_1), 12, '0') || 
           Lpad(To_Char(Total_Base_Imposable_2), 12, '0') || 
           Lpad(To_Char(Total_Retenu_Source), 12, '0') || 
           Lpad(To_Char(Dhon_H), 12, '0') || 
           Lpad(To_Char(Dcom_C), 12, '0') || 
           Lpad(To_Char(Dco_Co), 12, '0') || 
           Lpad(To_Char(Dris_R), 12, '0') || 
           Lpad(To_Char(Dje_Jp), 12, '0') || 
           Lpad(To_Char(Dda_Da), 12, '0') || 
           Lpad(To_Char(Ddi_Di), 12, '0') || 
           Lpad(To_Char(Dau_Ar), 12, '0') || 
           Lpad(To_Char(Inde), 12, '0') || 
           Lpad(To_Char(Avan), 12, '0') || 
           Lpad(To_Char(Rete), 12, '0') || 
           Z2 || 
           Lpad(To_Char(Montant_Taxe), 12, '0') || 
           Z3 || 
           Lpad(To_Char(Effectif), 6, '0') || 
           Z4 || 
           Nom_Responsable || 
           Prenom_Responsable || 
           Telephone_Responsable || 
           Z5    Enreg_300
    FROM   Dka_Sapdas2_300
    WHERE  Request_Id = Pn_Request_Id;

    -------------------------------------------------------------------
    -- Curseur d'extraction et de formatage de la ligne de total 310 --
    -------------------------------------------------------------------
    CURSOR Cur_310 IS
    SELECT Siren_Entreprise || 
           Z1 || 
           Type_Enregistrement || 
           Lpad(To_Char(Nombre_Etablissements), 5, '0') || 
           Lpad(To_Char(Nombre_Salaries), 6, '0') || 
           Lpad(To_Char(Nombre_Honoraires), 6, '0') || 
           Z2 || 
           Lpad(To_Char(Base_Brute_Fiscale), 12, '0') || 
           Lpad(To_Char(Remunerations_Nettes), 12, '0') || 
           Lpad(To_Char(Avantages_Nature), 12, '0') || 
           Lpad(To_Char(Frais_Professionnels), 12, '0') || 
           Lpad(To_Char(Cheques_Vacances), 12, '0') || 
           Lpad(To_Char(Total_Imposable), 12, '0') || 
           Lpad(To_Char(Total_Base_Imposable_1), 12, '0') || 
           Lpad(To_Char(Total_Base_Imposable_2), 12, '0') || 
           Lpad(To_Char(Total_Retenu_Source), 12, '0') || 
           Lpad(To_Char(Dhon_H), 12, '0') || 
           Lpad(To_Char(Dcom_C), 12, '0') || 
           Lpad(To_Char(Dco_Co), 12, '0') || 
           Lpad(To_Char(Dris_R), 12, '0') || 
           Lpad(To_Char(Dje_Jp), 12, '0') || 
           Lpad(To_Char(Dda_Da), 12, '0') || 
           Lpad(To_Char(Ddi_Di), 12, '0') || 
           Lpad(To_Char(Dau_Ar), 12, '0') || 
           Lpad(To_Char(Inde), 12, '0') || 
           Lpad(To_Char(Avan), 12, '0') || 
           Lpad(To_Char(Rete), 12, '0') || 
           Z3 || 
           Lpad(To_Char(Montant_Taxe), 12, '0') || 
           Z4 || 
           Lpad(To_Char(Effectif), 6, '0') || 
           Z5    Enreg_310
    FROM   Dka_Sapdas2_310
    WHERE  Request_Id = Pn_Request_Id;


    Rec_010                         Cur_010%ROWTYPE;
    Rec_020                         Cur_020%ROWTYPE;
    Rec_210                         Cur_210%ROWTYPE;
    Rec_300                         Cur_300%ROWTYPE;
    Rec_310                         Cur_310%ROWTYPE;

  BEGIN

    -- Dka_Tools_Pkg.Put_Outdebug_Message(' ');                       04/04/2007 EMA
    -- Dka_Tools_Pkg.Put_Outdebug_Message('DEBUT DU FICHIER DAS2');   04/04/2007 EMA
    -- Dka_Tools_Pkg.Put_Outdebug_Message('=====================');   04/04/2007 EMA

    -------------------------------------------
    -- Constitution de la ligne d'entête 010 --
    -------------------------------------------
    OPEN Cur_010;
    LOOP
      FETCH Cur_010 INTO Rec_010;
      EXIT WHEN Cur_010%NOTFOUND;

      -- Dka_Tools_Pkg.Put_Outdebug_Message(Rec_010.Enreg_010);     04/04/2007 EMA
      Put_Out_Message(Rec_010.Enreg_010);                        -- 04/04/2007 EMA

    END LOOP;
    CLOSE Cur_010;       

    -------------------------------------------
    -- Constitution de la ligne d'entête 020 --
    -------------------------------------------
    OPEN Cur_020;
    LOOP
      FETCH Cur_020 INTO Rec_020;
      EXIT WHEN Cur_020%NOTFOUND;

      -- Dka_Tools_Pkg.Put_Outdebug_Message(Rec_020.Enreg_020);     04/04/2007 EMA
      Put_Out_Message(Rec_020.Enreg_020);                        -- 04/04/2007 EMA

    END LOOP;
    CLOSE Cur_020;

    -----------------------------------------------
    -- Constitution de la ligne d'honoraires 210 --
    -----------------------------------------------
    OPEN Cur_210;
    LOOP
      FETCH Cur_210 INTO Rec_210;
      EXIT WHEN Cur_210%NOTFOUND;

      -- Dka_Tools_Pkg.Put_Outdebug_Message(Rec_210.Enreg_210);     04/04/2007 EMA
      Put_Out_Message(Rec_210.Enreg_210);                        -- 04/04/2007 EMA

    END LOOP;
    CLOSE Cur_210;

    -------------------------------------------
    -- Constitution de la ligne de total 300 --
    -------------------------------------------
    OPEN Cur_300;
    LOOP
      FETCH Cur_300 INTO Rec_300;
      EXIT WHEN Cur_300%NOTFOUND;

      -- Dka_Tools_Pkg.Put_Outdebug_Message(Rec_300.Enreg_300);     04/04/2007 EMA
      Put_Out_Message(Rec_300.Enreg_300);                        -- 04/04/2007 EMA

    END LOOP;
    CLOSE Cur_300;

    -------------------------------------------
    -- Constitution de la ligne de total 310 --
    -------------------------------------------
    OPEN Cur_310;
    LOOP
      FETCH Cur_310 INTO Rec_310;
      EXIT WHEN Cur_310%NOTFOUND;

      -- Dka_Tools_Pkg.Put_Outdebug_Message(Rec_310.Enreg_310);     04/04/2007 EMA
      Put_Out_Message(Rec_310.Enreg_310);                        -- 04/04/2007 EMA

    END LOOP;
    CLOSE Cur_310;

  END Extract_Data;


  -- -----------------------------------------------------------------------------
  -- Nom              : Control_Data
  -- Description      : Controle des données pour l'édition de la DAS2;
  --
  -- PARAMETRES       : Pv_Errbuf                  Sortie Message d'erreur
  --                    Pn_Retcode                 Sortie Code Retour de la procédure
  --                                                      '0' : Normal
  --                                                      '1' : Avertissement
  --                                                      '2' : Erreur
  --                    Pn_Request_Id      Entrée         Numéro de traitement
  --                    Pv_Annee           Entrée         Année de déclaration
  --                    Pv_Societe         Entrée         Société de déclaration
  --                    Pv_Controle        Entrée         Indique que seul le contrôle
  --                                                      est effectué
  --                    Pv_Debug_Mode      Entrée         Mode de debogage
  --                    Pn_Set_Of_Books_Id Entreé         Set_Books_Id
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Control_Data(Pv_Errbuf              OUT  VARCHAR2,
                         Pn_Retcode             OUT  NUMBER,
                         Pv_Annee           IN       VARCHAR2,
                         Pv_Societe         IN       VARCHAR2,
                         Pv_Controle        IN       VARCHAR2,
                         Pv_Debug_Mode      IN       VARCHAR2,
                         Pn_Set_Of_Books_Id IN       NUMBER) IS


    Vv_Debut_Message                VARCHAR2(250);
    Vv_Raison_Sociale               VARCHAR2(50);
    Vv_Profession                   VARCHAR2(30);
    Vv_Commune                      VARCHAR2(26);
    Vn_Request_Id                   NUMBER;
    Vb_Erreur_Controle              BOOLEAN;

    Vv_Raison_Sociale_Entreprise    VARCHAR2(50);
    Vv_Numero_Siren_Entreprise      VARCHAR2(9);
    Vv_Numero_Siret_Entreprise      VARCHAR2(14);
    Vv_Code_Ape_Entreprise          VARCHAR2(5);--Modif JVI 15/12/2008 : Passage de 4 à 5 caractères
    Vv_Adr_Comp_Entreprise          VARCHAR2(32);
    Vv_Adr_Voie_Entreprise          VARCHAR2(32);
    Vv_Code_Postal_Entreprise       VARCHAR2(5);
    Vv_Commune_Entreprise           VARCHAR2(26);
    Vv_Activite_Entreprise          VARCHAR2(40);
    Vv_Siren                        VARCHAR2(9);
    Vv_Nic                          VARCHAR2(5);
    Vv_Siret                        VARCHAR2(14);
    Vv_Siren_Beneficiaire           VARCHAR2(9);
    Vv_Nic_Beneficiaire             VARCHAR2(5);
    Vv_Siret_Beneficiaire           VARCHAR2(14);
    Vn_Nb_Enreg_020                 NUMBER := 0;
    Vn_Nb_Enreg_210                 NUMBER := 0;
    Vn_Nb_Total_Enreg               NUMBER := 0;
    Vn_Montant_Total_Honoraires     NUMBER := 0;
    
    -->JJA 2015/08/20
    vn_retcode                      NUMBER;
    vv_err_msg                      VARCHAR2(255);
    vr_data                         dka_parameters%ROWTYPE;
    vn_seuil                        NUMBER;
    erreur_seuil                    EXCEPTION;
    --<JJA 2015/08/20
        
  ----------------------------------------------------------------------
  -- Curseur de lecture pour la constitution de la ligne d'entête 010 --
  ----------------------------------------------------------------------
  CURSOR Cur_010 IS
  SELECT Vn_Request_Id                                                           Request_Id,
         Substr(Area.Tax_Identification_Num, 1, 9)                               Siren_Entreprise,
         Lpad('0', 12, '0')                                                      Z1,
         '010'                                                                   Type_Enregistrement,
         Rpad(' ', 14, ' ')                                                      Z2,
         Rpad(Nvl(Houa.Attribute8, ' '), 5, ' ')                                 Code_Ape,--Modif JVI 15/12/2008 : Passage de 4 à 5 caractères
         Rpad(' ', 5, ' ')                                                       Z3,
         Area.Entity_Name                                                        Raison_Sociale,
         Hla.Address_Line_2                                                      Adresse_Complement,
         ' '                                                                     Z4,
         Hla.Address_Line_1                                                      Adresse_Voie,
         Lpad(Nvl(Decode(Hla.Style,'FR_GLB',Hla.Attribute4,Hla.Region_2),'0'), 5, '0')   Code_Insee,
         ' '                                                                     Z5,
         Hla.Town_Or_City                                                        Commune,
         Hla.Postal_Code                                                         Code_Postal,
         ' '                                                                     Z6,
         Nvl(Hla.Attribute5, Hla.Town_Or_City)                                   Bureau_Distributeur,
         Rpad('0', 8, '0')                                                       Z7,
         'X'                                                                     Type_Fichier,
         Area.Tax_Identification_Num                                             Siret_Etablissement,
         Rpad(' ', 5, ' ')                                                       Z8,
         ' '                                                                     Z9,
         ' '                                                                     Z10,
         ' '                                                                     Z11,
         ' '                                                                     Z12,
         Rpad(' ', 288, ' ')                                                     Z13
  FROM Ap_Reporting_Entities_All       Area,
       Ap_Reporting_Entity_Lines_All   Arela,
       Hr_Locations_All                Hla,
       Hr_All_Organization_Units       Houa
  WHERE Area.Tax_Entity_Id            = Arela.Tax_Entity_Id
    AND Area.Location_Id              = Hla.Location_Id
    AND Area.org_id                   = Houa.organization_id
    AND Arela.Balancing_Segment_Value = Pv_Societe;

  ----------------------------------------------------------------------
  -- Curseur de lecture pour la constitution de la ligne d'entête 020 --
  ----------------------------------------------------------------------
  CURSOR Cur_020 IS
  SELECT Vn_Request_Id                                                           Request_Id,
         Substr(Area.Tax_Identification_Num, 1, 9)                               Siren_Etablissement,
         Substr(Area.Tax_identification_Num, 10, 5)                              Nic_Etablissement,
         '00'                                                                    Code_Section_etablissement,
         Pv_Annee                                                                Validite,
         '1'                                                                     Type_Dads,
         '020'                                                                   Type_Enregistrement,
         Rpad(' ', 14, ' ')                                                      Z1,
         Rpad(Nvl(Houa.Attribute8, ' '), 5, ' ')                                 Code_Ape,--Modif JVI 15/12/2008 : Passage de 4 à 5 caractères
         ' '                                                                     Z2,
         Lpad('0', 9, '0')                                                       Siren_01_Jan,
         Lpad('0', 5, '0')                                                       Nic_01_Jan,
         Rpad(' ', 41, ' ')                                                      Z3,
         Area.Entity_Name                                                        Raison_Sociale,
         Hla.Address_Line_2                                                      Adresse_Complement,
         ' '                                                                     Z4,
         Hla.Address_Line_1                                                      Adresse_Voie,
         Lpad(Nvl(Decode(Hla.Style,'FR_GLB', Hla.Attribute4,Hla.Region_2), '0'),5,'0')  Code_Insee,
         ' '                                                                     Z5,
         Hla.Town_Or_City                                                        Commune,
         Hla.Postal_Code                                                         Code_Postal,
         ' '                                                                     Z6,
         Nvl(Hla.Attribute5, Hla.Town_Or_City)                                   Bureau_Distributeur,
         Rpad(Nvl(Substr(Houa.Attribute9, 1, 40), ' '), 40, ' ')                 Profession,
         Rpad(' ', 53, ' ')                                                      Z7,
         'N'                                                                     Code_Taxe_Salaires,
         Rpad(' ', 301, ' ')                                                     Z8
  FROM Ap_Reporting_Entities_All       Area,
       Ap_Reporting_Entity_Lines_All   Arela,
       Hr_Locations_All                Hla,
       Hr_All_Organization_Units       Houa
  WHERE Area.Tax_Entity_Id            = Arela.Tax_Entity_Id
    AND Area.Location_Id              = Hla.Location_Id
    AND Area.org_id                   = Houa.organization_id
    AND Arela.Balancing_Segment_Value = Pv_Societe;

  --------------------------------------------------------------------------
  -- Curseur de lecture pour la constitution de la ligne d'honoraires 210 --
  --------------------------------------------------------------------------
  CURSOR Cur_210 IS 
  SELECT Pv.Segment1                                                             Numero_Fournisseur,
         Pvsa.Vendor_Site_Code                                                   Site_Fournisseur,
         Vn_Request_Id                                                           Request_Id,
         Pv.Vendor_Id                                                            Vendor_Id,
         Pvsa.Vendor_Site_Id                                                     Vendor_Site_Id,
         Substr(Area.Tax_Identification_Num, 1, 9)                               Siren_Etablissement,
         Substr(Area.Tax_Identification_Num, 10, 5)                              Nic_Etablissement,
         '00'                                                                    Code_Section_Etablissement,
         Pv_Annee                                                                Validite,
         '1'                                                                     Type_Dads,
         '210'                                                                   Type_Enregistrement,
         Decode(Pv.Num_1099,
                'PROVISOIRE', '999999999',
                'HONORAIRE' , '999999999',
                'ARTISAN'   , '999999999',
                '000000000' , '999999999',
                Decode(Pv.Organization_Type_Lookup_Code,
                       'INDIVIDUAL', Nvl(Pv.Num_1099, '999999999'),
                       Pv.Num_1099))                                             Siren_Beneficiaire,
         Decode(Pvsa.Attribute1, 
                'PROVI', '99999',
                '00000', '99999',
                'HONO' , '99999',
                Decode(Pv.Organization_Type_Lookup_Code,
                       'INDIVIDUAL', Nvl(Pvsa.Attribute1, '99999'),
                       Pvsa.Attribute1))                                         Nic_Beneficiaire,
         Decode(Pv.Organization_Type_Lookup_Code,
                'CORPORATION', ' ',
                'FOREIGN CORPORATION', ' ',
                NULL, ' ',
                'INDIVIDUAL', Pvc.Last_Name)                                     Nom,
         Decode(Pv.Organization_Type_Lookup_Code,
                'CORPORATION', ' ',
                'FOREIGN CORPORATION', ' ',
                NULL, ' ',
                'INDIVIDUAL', Pvc.First_Name)                                    Prenom,
         Decode(Pv.Organization_Type_Lookup_Code,
                'CORPORATION', Substr(Pv.Vendor_Name, 1, 50),
                'FOREIGN CORPORATION', Substr(Pv.Vendor_Name, 1, 50),
                NULL, Substr(Pv.Vendor_Name, 1, 50),
                'INDIVIDUAL', ' ',
                Substr(Pv.Vendor_Name, 1, 50))                                   Raison_Sociale,
         Pv.Minority_Group_Lookup_Code                                           Profession,
         Pvsa.Address_Line2                                                      Adresse_Complement,
         ' '                                                                     Z1,
         Pvsa.Address_Line1                                                      Adresse_Voie,
         Lpad(Nvl(Substr(Pvsa.Attribute6, 1, 5), '0'), 5, '0')                   Code_Insee,
         ' '                                                                     Z2,
         Pvsa.City                                                               Commune,
         Substr(Decode(Pvsa.Country,
                       NULL, Upper(Pvsa.Zip),
                       Decode(Pvsa.Country,
                              'FR', Upper(Pvsa.Zip),
                               Decode(Pvsa.Country,
                                      'MC', '99138',
                                      Decode(Pvsa.Country, 
                                             'AD', '99130', 
                                             '99999')))), 1, 5)                  Code_Postal,
         ' '                                                                     Z3,
         Nvl(Pvsa.Attribute7, Pvsa.City)                                         Bureau_Distributeur,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DHON/H', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Dhon_H,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DCOM/C', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Dcom_C,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DCO/CO', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   DCo_Co,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DRIS/R', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Dris_r,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DJE/JP', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Dje_Jp,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DDA/DA', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0))) +
         Trunc(Sum(Decode(Aida.Type_1099,
                          'TVA/55', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Dda_Da,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DDI/DI', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Ddi_Di,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'DAU/AR', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Dau_Ar,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'INDE/F', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)) +
               Sum(Decode(Aida.Type_1099,
                          'INDE/R', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)) +
               Sum(Decode(Aida.Type_1099,
                          'INDE/P', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Inde,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'AVAN/N', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)) +
               Sum(Decode(Aida.Type_1099,
                          'AVAN/L', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)) +
               Sum(Decode(Aida.Type_1099,
                          'AVAN/V', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)) +
               Sum(Decode(Aida.Type_1099,
                          'AVAN/A', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Avan,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'RETE/R', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)) +
               Sum(Decode(Aida.Type_1099,
                          'RETE/D', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Rete,
         Decode(Sum(Decode(Aida.Type_1099,
                           'AVAN/N', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'N')                                                             Nat_Avan_Nour,
         Decode(Sum(Decode(Aida.Type_1099,
                           'AVAN/L', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'L')                                                             Nat_Avan_Loge,
         Decode(Sum(Decode(Aida.Type_1099,
                           'AVAN/V', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'V')                                                             Nat_Avan_Voit,
         Decode(Sum(Decode(Aida.Type_1099,
                           'AVAN/A', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'A')                                                             Nat_Avan_Autr,
         ' '                                                                     Nat_Avan_Ntic,
         Decode(Sum(Decode(Aida.Type_1099,
                           'INDE/F', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'F')                                                             Nat_Inde_Forf,
         Decode(Sum(Decode(Aida.Type_1099,
                           'INDE/R', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'R')                                                             Nat_Inde_Remb,
         Decode(Sum(Decode(Aida.Type_1099,
                           'INDE/P', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'P')                                                             Nat_Inde_Pris,
         Decode(Sum(Decode(Aida.Type_1099,
                           'RETE/R', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'R')                                                             Nat_Tva_Redui,
         Decode(Sum(Decode(Aida.Type_1099,
                           'RETE/D', Round(Aipa.Amount * 
                                           (Aida.Amount / Aia.Invoice_Amount)),
                           0)),
                0, ' ',
                'D')                                                             Nat_Tva_Dispe,
         Trunc(Sum(Decode(Aida.Type_1099,
                          'TVA/47', Decode(Aipa.Exchange_Rate,
                                           NULL, Round(Aipa.Amount *
                                                       (Aida.Amount / Aia.Invoice_Amount)),
                                           Round(Aipa.Payment_Base_Amount *
                                                 (Aida.Base_Amount / Aia.Base_Amount))),
                          0)))                                                   Tva_Nette,
         Lpad(' ', 245, ' ')                                                     Z4
  FROM Ap_Reporting_Entities_All                    Area,
       Ap_Reporting_Entity_Lines_All                Arela,
       Gl_Code_Combinations                         Gcc,
       Ap_Invoice_Distributions_All                 Aida,
       Ap_Invoices_All                              Aia,
       Ap_Invoice_Payments_All                      Aipa,
       Ap_Checks_All                                Aca,
       ap_suppliers                                 Pv,
       ap_supplier_sites_all                        Pvsa,
       po_vendor_Contacts                           Pvc
  WHERE Area.Tax_Entity_Id                         = Arela.Tax_Entity_Id 
    AND Arela.Balancing_Segment_Value              = Gcc.Segment1 
    AND Gcc.Code_Combination_Id                    = Aida.Dist_Code_Combination_Id 
    AND Aida.Set_Of_Books_Id                       = Pn_Set_Of_Books_Id
    AND Aida.Invoice_Id                            = Aia.Invoice_Id 
    AND Aia.Set_Of_Books_Id                        = Pn_Set_Of_Books_Id
    AND Aida.Type_1099 IN ('DHON/H', 'DCOM/C', 'AVAN/N', 'DCO/CO', 'DRIS/R', 
                           'DJE/JP', 'DDA/DA', 'DDI/DI', 'DAU/AR', 'AVAN/L', 
                           'AVAN/V', 'AVAN/A', 'INDE/F', 'INDE/R', 'INDE/P', 
                           'RETE/R', 'RETE/D', 'TVA/55', 'TVA/47', 'COTIS') 
    AND Aipa.Invoice_Id                            = Aia.Invoice_Id 
    AND Aipa.Set_Of_Books_Id                       = Pn_Set_Of_Books_Id
    AND To_Char(Aipa.Accounting_Date, 'YYYY')      = Pv_Annee
    AND Aipa.Amount                               != 0 
    AND Decode(Aipa.Exchange_Rate,NULL, Aia.Invoice_Amount,Aia.Base_Amount) != 0 
    AND Aipa.Check_Id                              = Aca.Check_Id
    AND Aia.Vendor_Id                              = Pv.Vendor_Id
    --AND Pv.Set_Of_Books_Id                         = Pn_Set_Of_Books_Id
    AND Aia.Vendor_Site_Id                         = Pvsa.Vendor_Site_Id
    AND Pvc.Vendor_Site_Id(+)                      = Pvsa.Vendor_Site_Id
    AND Nvl(Trunc(Pvc.Inactive_Date), SYSDATE + 1) > SYSDATE 
    AND Nvl(Pvc.Vendor_Contact_Id, -9999) = ( SELECT Vendor_Contact_Id
                                              FROM   Po_Vendor_Contacts Pvc1
                                              WHERE  Pvc1.Vendor_Site_Id = Pvc.Vendor_Site_Id 
                                              AND    Nvl(Trunc(Pvc1.Inactive_Date), SYSDATE + 1) > SYSDATE 
                                              AND    Rownum = 1
                                              UNION ALL
                                              SELECT -9999
                                              FROM   Dual
                                              WHERE  Pvc.Vendor_Contact_Id IS NULL) 
    AND    Arela.Balancing_Segment_Value = Pv_Societe
    GROUP  BY Pv.Segment1,
              Pvsa.Vendor_Site_Code,
              Pv.Vendor_Id,
              Pvsa.Vendor_Site_Id,
              Area.Tax_Identification_Num,
              Pv.Num_1099,
              Pvsa.Attribute1,
              Pv.Organization_Type_Lookup_Code,
              Pvc.Last_Name,
              Pvc.First_Name,
              Pv.Vendor_Name,
              Pv.Minority_Group_Lookup_Code,
              Pvsa.Address_Line2,
              Pvsa.Address_Line1,
              Pvsa.Attribute6,
              Pvsa.City,
              Pvsa.Country,
              Pvsa.Zip,
              Pvsa.Attribute7;

  ----------------------------------------------------------------------
  -- Curseur de lecture pour la constitution de la ligne de total 300 --
  ----------------------------------------------------------------------
  CURSOR Cur_300 IS
  SELECT Ds_020.Request_Id                                                     Request_Id,
         Ds_020.Siren_Etablissement                                            Siren_Etablissement,
         Ds_020.Nic_Etablissement                                              Nic_Etablissement,
         '00'                                                                  Code_Section_Etablissement,
         Pv_Annee                                                              Validite,
         '1'                                                                   Type_Dads,
         '300'                                                                 Type_Enregistrement,
         Rpad(' ', 36, ' ')                                                    Z1,
         0                                                                     Base_Brute_Fiscale,
         0                                                                     Remunerations_Nettes,
         0                                                                     Avantages_Nature,
         0                                                                     Frais_Professionnels,
         0                                                                     Cheques_Vacances,
         0                                                                     Total_Imposable,
         0                                                                     Total_Base_Imposable_1,
         0                                                                     Total_Base_Imposable_2,
         0                                                                     Total_Retenu_Source,
         Ds_210.Dhon_H                                                         Dhon_H,
         Ds_210.Dcom_C                                                         Dcom_C,
         Ds_210.Dco_Co                                                         Dco_Co,
         Ds_210.Dris_R                                                         Dris_R,
         Ds_210.Dje_Jp                                                         Dje_Jp,
         Ds_210.Dda_da                                                         Dda_Da,
         Ds_210.Ddi_Di                                                         Ddi_Di,
         Ds_210.Dau_Ar                                                         Dau_Ar,
         Ds_210.Inde                                                           Inde,
         Ds_210.Avan                                                           Avan,
         Ds_210.Rete                                                           Rete,
         Rpad(' ', 12, ' ')                                                    Z2,
         0                                                                     Montant_Taxe,
         Rpad(' ', 12, ' ')                                                    Z3,
         0                                                                     Effectif,
         Rpad(' ', 134, ' ')                                                   Z4,
         Rpad(' ', 30, ' ')                                                    Nom_Responsable,
         Rpad(' ', 20, ' ')                                                    Prenom_Responsable,
         Rpad(' ', 39, ' ')                                                    Telephone_Responsable,
         Rpad(' ', 107, ' ')                                                   Z5
  FROM Dka_Sapdas2_020  Ds_020,
       (SELECT Nvl(Sum(Dhon_H), 0)  Dhon_H,
               Nvl(Sum(Dcom_C), 0)  Dcom_C,
               Nvl(Sum(Dco_Co), 0)  Dco_Co,
               Nvl(Sum(Dris_R), 0)  Dris_R,
               Nvl(Sum(Dje_Jp), 0)  Dje_Jp,
               Nvl(Sum(Dda_da), 0)  Dda_Da,
               Nvl(Sum(Ddi_Di), 0)  Ddi_Di,
               Nvl(Sum(Dau_Ar), 0)  Dau_Ar,
               Nvl(Sum(Inde), 0)    Inde,
               Nvl(Sum(Avan), 0)    Avan,
               Nvl(Sum(Rete), 0)    Rete
        FROM Dka_Sapdas2_210
        WHERE Request_Id = Vn_Request_Id)  Ds_210
  WHERE Ds_020.Request_Id = Vn_Request_Id;

  ----------------------------------------------------------------------
  -- Curseur de lecture pour la constitution de la ligne de total 310 --
  ----------------------------------------------------------------------
  CURSOR Cur_310 IS
  SELECT Ds_010.Request_Id                                                     Request_Id,
         Ds_010.Siren_Entreprise                                               Siren_Entreprise,
         Rpad('9', 12, '9')                                                    Z1,
         '310'                                                                 Type_Enregistrement,
         Ds_020.Nombre_Etablissements                                          Nombre_Etablissements,
         0                                                                     Nombre_Salaries,
         Vn_Nb_Enreg_210                                                       Nombre_Honoraires,
         Rpad(' ', 36, ' ')                                                    Z2,
         0                                                                     Base_Brute_Fiscale,
         0                                                                     Remunerations_Nettes,
         0                                                                     Avantages_Nature,
         0                                                                     Frais_Professionnels,
         0                                                                     Cheques_Vacances,
         0                                                                     Total_Imposable,
         0                                                                     Total_Base_Imposable_1,
         0                                                                     Total_Base_Imposable_2,
         0                                                                     Total_Retenu_Source,
         Ds_210.Dhon_H                                                         Dhon_H,
         Ds_210.Dcom_C                                                         Dcom_C,
         Ds_210.Dco_Co                                                         Dco_Co,
         Ds_210.Dris_R                                                         Dris_R,
         Ds_210.Dje_Jp                                                         Dje_Jp,
         Ds_210.Dda_da                                                         Dda_Da,
         Ds_210.Ddi_Di                                                         Ddi_Di,
         Ds_210.Dau_Ar                                                         Dau_Ar,
         Ds_210.Inde                                                           Inde,
         Ds_210.Avan                                                           Avan,
         Ds_210.Rete                                                           Rete,
         Rpad(' ', 12, ' ')                                                    Z3,
         0                                                                     Montant_Taxe,
         Rpad(' ', 12, ' ')                                                    Z4,
         0                                                                     Effectif,
         Rpad(' ', 313, ' ')                                                   Z5
  FROM Dka_Sapdas2_010                     Ds_010,
       (SELECT Count(*) Nombre_Etablissements
        FROM   Dka_Sapdas2_020
        WHERE  Request_Id = Vn_Request_Id) Ds_020,
       (SELECT Nvl(Sum(Dhon_H), 0)  Dhon_H,
               Nvl(Sum(Dcom_C), 0)  Dcom_C,
               Nvl(Sum(Dco_Co), 0)  Dco_Co,
               Nvl(Sum(Dris_R), 0)  Dris_R,
               Nvl(Sum(Dje_Jp), 0)  Dje_Jp,
               Nvl(Sum(Dda_Da), 0)  Dda_Da,
               Nvl(Sum(Ddi_Di), 0)  Ddi_Di,
               Nvl(Sum(Dau_Ar), 0)  Dau_Ar,
               Nvl(Sum(Inde), 0)    Inde,
               Nvl(Sum(Avan), 0)    Avan,
               Nvl(Sum(Rete), 0)    Rete
        FROM   Dka_Sapdas2_210  
        WHERE  Request_Id = Vn_Request_Id) Ds_210
  WHERE Ds_010.Request_Id = Vn_Request_Id;


  Rec_010                         Cur_010%ROWTYPE;
  Rec_020                         Cur_020%ROWTYPE;
  Rec_210                         Cur_210%ROWTYPE;
  Rec_300                         Cur_300%ROWTYPE;
  Rec_310                         Cur_310%ROWTYPE;

  --------------------------------------------------------------
  -- Fonction de constitution du debut de message             --
  --           => On affiche le numéro de fournisseur en      --
  --              début de ligne si l'erreur concerne une     --
  --              ligne d'honoraires                          --
  --------------------------------------------------------------
  FUNCTION Debut_Message(Pv_Fournisseur VARCHAR2,
                         Pv_Site        VARCHAR2) RETURN VARCHAR2 IS

    Vv_Message                  VARCHAR2(250);

  BEGIN

    SELECT Decode(Pv_Fournisseur,NULL,NULL,'Fournisseur ' || Pv_Fournisseur || ' - Site ' || Pv_Site || ' : ') 
    INTO   Vv_Message
    FROM   Dual;

    RETURN(Vv_Message);

  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du numéro de SIREN                 --
  --           => Il doit être numérique                      --
  --           => Il doit avoir une longueur de 9 caractères  --
  --           => Il doit être renseigné                      --
  --------------------------------------------------------------
  PROCEDURE Controle_Siren(Pv_Controle     VARCHAR2,
                           Pv_Numero_Siren VARCHAR2,
                           Pv_Fournisseur  VARCHAR2,
                           Pv_Site         VARCHAR2) IS 

  BEGIN
    Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

    IF Pv_Numero_Siren IS NULL THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le numéro de SIREN doit être renseigné');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le numéro de SIREN doit être renseigné');
      Vb_Erreur_Controle := TRUE;
    ELSE
      IF NOT Est_Numerique(Pv_Numero_Siren) THEN
        -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le numéro de SIREN ' || Pv_Numero_Siren || 'n''est pas numérique');
        Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le numéro de SIREN ' || Pv_Numero_Siren || 'n''est pas numérique');
        Vb_Erreur_Controle := TRUE;
      END IF;

      IF Length(Pv_Numero_Siren) <> 9 THEN
        -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'La longueur du numéro de SIREN ' || Pv_Numero_Siren || ' est incorrecte');
        Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'La longueur du numéro de SIREN ' || Pv_Numero_Siren || ' est incorrecte');
        Vb_Erreur_Controle := TRUE;
      END IF;

      IF Pv_Numero_Siren = Rpad('0', 9, '0') THEN
        -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le numéro de SIREN doit être différent de 000000000');
        Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le numéro de SIREN doit être différent de 000000000');
        Vb_Erreur_Controle := TRUE;
      END IF;
    END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle de la raison sociale               --
  --           => Elle doit faire 50 caractères maxi          --
  --           => Elle doit être renseignée (Pv_Renseigne = Y)--
  --------------------------------------------------------------
  PROCEDURE Controle_Raison_Sociale(Pv_Controle       VARCHAR2,
                                    Pv_Raison_Sociale VARCHAR2,
                                    Pv_Renseigne      VARCHAR2,
                                    Pv_Fournisseur    VARCHAR2,
                                    Pv_Site           VARCHAR2) IS 

  BEGIN
    Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

    IF Length(Pv_Raison_Sociale) > 50 THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'La raison sociale fait plus de 50 caractères');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'La raison sociale fait plus de 50 caractères');
      Vb_Erreur_Controle := TRUE;
    END IF;

    IF Pv_Renseigne = 'Y' AND Pv_Raison_Sociale IS NULL THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'La raison sociale doit être renseignée');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'La raison sociale doit être renseignée');
      Vb_Erreur_Controle := TRUE;
    END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du complément adresse              --
  --           => Il doit faire 32 caractères maxi            --
  --------------------------------------------------------------
  PROCEDURE Controle_Adresse_Comp(Pv_Controle           VARCHAR2,
                                  Pv_Adresse_Complement VARCHAR2,
                                  Pv_Fournisseur        VARCHAR2,
                                  Pv_Site               VARCHAR2) IS

  BEGIN
    Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

    IF Length(Pv_Adresse_Complement) > 32 THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message || 'Le complément adresse fait plus de 32 caractères');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le complément adresse fait plus de 32 caractères');
      Vb_Erreur_Controle := TRUE;
    END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle de l'adresse voie                  --
  --           => Elle doit faire 32 caractères maxi          --
  --------------------------------------------------------------
  PROCEDURE Controle_Adresse_Voie(Pv_Controle     VARCHAR2,
                                  Pv_Adresse_Voie VARCHAR2,
                                  Pv_Fournisseur  VARCHAR2,
                                  Pv_Site         VARCHAR2) IS 

  BEGIN
    Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

    IF Length(Pv_Adresse_Voie) > 32 THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'L''adresse voie fait plus de 32 caractères');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message || 'L''adresse voie fait plus de 32 caractères');
      Vb_Erreur_Controle := TRUE;
    END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du code INSEE                      --
  --           => Il doit être numérique                      --
  --           => Il peut commencer par 2A ou 2B              --
  --------------------------------------------------------------
  PROCEDURE Controle_Code_Insee(Pv_Controle     VARCHAR2,
                                Pv_Code_Insee  VARCHAR2,
                                Pv_Fournisseur VARCHAR2,
                                Pv_Site        VARCHAR2) IS 

  BEGIN
    Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

    IF NOT (Substr(Pv_Code_Insee, 1, 2) IN ('2A', '2B') AND Est_Numerique(Substr(Pv_Code_Insee, 3, 3)) OR Est_Numerique(Pv_Code_Insee)) THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le code INSEE ' || Pv_Code_Insee || ' est incorrect');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le code INSEE ' || Pv_Code_Insee || ' est incorrect');
      Vb_Erreur_Controle := TRUE;
    END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle de la commune                      --
  --           => Elle doit faire 26 caractères maxi          --
  --           => Elle doit être renseignée                   --
  --------------------------------------------------------------
  PROCEDURE Controle_Commune(Pv_Controle     VARCHAR2,
                             Pv_Commune     VARCHAR2,
                             Pv_Fournisseur VARCHAR2,
                             Pv_Site        VARCHAR2) IS 

  BEGIN
    Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

    IF Length(Pv_Commune) > 26 THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'La commune fait plus de 26 caractères');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'La commune fait plus de 26 caractères');
      Vb_Erreur_Controle := TRUE;
    ELSIF Pv_Commune IS NULL THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'La commune doit être renseignée');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'La commune doit être renseignée');
      Vb_Erreur_Controle := TRUE;
    END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du code postal                     --
  --           => Il doit être renseigné                      --
  --           => Il doit être numérique                      --
  --           => Il doit être différent de 0                 --
  --------------------------------------------------------------
  PROCEDURE Controle_Code_Postal(Pv_Controle    VARCHAR2,
                                 Pv_Code_postal VARCHAR2,
                                 Pv_Fournisseur VARCHAR2,
                                 Pv_Site        VARCHAR2) IS 

  BEGIN
    Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

    IF NOT Est_Numerique(Pv_Code_Postal) THEN
      -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le Code Postal ' || Pv_Code_Postal || ' n''est pas numérique');
      Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le Code Postal ' || Pv_Code_Postal || ' n''est pas numérique');
      Vb_Erreur_Controle := TRUE;
    ELSE
      IF Length(Pv_Code_Postal) > 5 THEN
        -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'La longueur du Code Postal ' || Pv_Code_Postal || ' est incorrecte');
        Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'La longueur du Code Postal ' || Pv_Code_Postal || ' est incorrecte');
        Vb_Erreur_Controle := TRUE;
      END IF;
      IF Pv_Code_Postal IS NULL THEN
        -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le Code Postal '|| Pv_Code_Postal || ' doit être renseigné');
        Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le Code Postal '|| Pv_Code_Postal || ' doit être renseigné');
        Vb_Erreur_Controle := TRUE;
      END IF;
      IF Pv_Code_Postal = '00000' THEN
        -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le Code Postal '|| Pv_Code_Postal || ' doit être différent de 00000');
        Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le Code Postal '|| Pv_Code_Postal || ' doit être différent de 00000');
        Vb_Erreur_Controle := TRUE;
      END IF;
      IF Substr(Pv_Code_Postal, 1, 2) = '00' THEN
        -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||'Le Code Postal '|| Pv_Code_Postal || ' ne doit pas commencé par 00');
        Put_Log_Message(Pv_Controle, Vv_Debut_Message ||'Le Code Postal '|| Pv_Code_Postal || ' ne doit pas commencé par 00');
        Vb_Erreur_Controle := TRUE;
      END IF;
    END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du bureau distributeur             --
  --           => Il doit faire 26 caractères maxi            --
  --           => Il doit être renseignée                     --
  --------------------------------------------------------------
  PROCEDURE Controle_Bureau_Distributeur(Pv_Controle            VARCHAR2,
                                         Pv_Bureau_Distributeur VARCHAR2,
                                         Pv_Fournisseur         VARCHAR2,
                                         Pv_Site                VARCHAR2) IS 

  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF Length(Pv_Bureau_Distributeur) > 26 THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le bureau distributeur fait plus de 26 caractères');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le bureau distributeur fait plus de 26 caractères');
          Vb_Erreur_Controle := TRUE;
      ELSIF Pv_Bureau_Distributeur IS NULL THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le bureau distributeur doit être renseigné');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le bureau distributeur doit être renseigné');
          Vb_Erreur_Controle := TRUE;
      END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du numéro de SIRET                 --
  --           => Il doit être numérique                      --
  --           => Il doit avoir une longueur de 14 caractères --
  --           => Il doit être renseigné (Pv_Renseigne = 'Y') --
  --------------------------------------------------------------
  PROCEDURE Controle_Siret(Pv_Controle     VARCHAR2,
                           Pv_Numero_Siret VARCHAR2, 
                           Pv_Renseigne    VARCHAR2,
                           Pv_Fournisseur  VARCHAR2,
                           Pv_Site         VARCHAR2) IS 

  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF NOT Est_Numerique(Pv_Numero_Siret) THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le numéro de SIRET ' || Pv_Numero_Siret || ' n''est pas numérique');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le numéro de SIRET ' || Pv_Numero_Siret || ' n''est pas numérique');
          Vb_Erreur_Controle := TRUE;
      ELSE
          IF Length(Pv_Numero_Siret) <> 14 THEN
              -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
              --                                    'La longueur du numéro de SIRET ' || Pv_Numero_Siret || ' est incorrecte');
              Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                              'La longueur du numéro de SIRET ' || Pv_Numero_Siret || ' est incorrecte');
              Vb_Erreur_Controle := TRUE;
          END IF;
          IF Pv_Renseigne    = 'Y'   AND
             Pv_Numero_Siret IS NULL THEN
              -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
              --                                    'Le numéro de SIRET doit être renseigné');
              Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                              'Le numéro de SIRET doit être renseigné');
              Vb_Erreur_Controle := TRUE;
          END IF;
          IF Pv_Numero_Siret = Rpad('0', 14, '0') THEN
              -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
              --                                    'Le numéro de SIRET doit être différent de 00000000000000');
              Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                              'Le numéro de SIRET doit être différent de 00000000000000');
              Vb_Erreur_Controle := TRUE;
          END IF;
      END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du numéro de NIC                   --
  --           => Il doit être numérique                      --
  --           => Il doit avoir une longueur de 5 caractères  --
  --           => Il doit être renseigné                      --
  --------------------------------------------------------------
  PROCEDURE Controle_Nic(Pv_Controle    VARCHAR2,
                         Pv_Numero_Nic  VARCHAR2,
                         Pv_Fournisseur VARCHAR2,
                         Pv_Site        VARCHAR2) IS 

  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF Pv_Numero_Nic IS NULL THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le numéro de NIC doit être renseigné');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le numéro de NIC doit être renseigné');
          Vb_Erreur_Controle := TRUE;
      ELSE
          IF NOT Est_Numerique(Pv_Numero_Nic) THEN
              -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
              --                                    'Le NIC ' || Pv_Numero_Nic || ' n''est pas numérique');
              Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                              'Le NIC ' || Pv_Numero_Nic || ' n''est pas numérique');
              Vb_Erreur_Controle := TRUE;
          END IF;
          IF Length(Pv_Numero_Nic) <> 5 THEN
              -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
              --                                    'La longueur du numéro du NIC ' || Pv_Numero_Nic || ' est incorrecte');
              Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                              'La longueur du numéro du NIC ' || Pv_Numero_Nic || ' est incorrecte');
              Vb_Erreur_Controle := TRUE;
          END IF;
          IF Pv_Numero_Nic = Rpad('0', 5, '0') THEN
              -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
              --                                    'Le numéro de NIC doit être différent de 00000');
              Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                              'Le numéro de NIC doit être différent de 00000');
              Vb_Erreur_Controle := TRUE;
          END IF;
      END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du nom                             --
  --           => Il doit faire 30 caractères maxi            --
  --------------------------------------------------------------
  PROCEDURE Controle_Nom(Pv_Controle    VARCHAR2,
                         Pv_Nom         VARCHAR2,
                         Pv_Fournisseur VARCHAR2,
                         Pv_Site        VARCHAR2) IS 

  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF Length(Pv_Nom) > 30 THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le nom du bénéficiaire fait plus de 30 caractères');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le nom du bénéficiaire fait plus de 30 caractères');
          Vb_Erreur_Controle := TRUE;
      END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du prénom                          --
  --           => Il doit faire 20 caractères maxi            --
  --------------------------------------------------------------
  PROCEDURE Controle_Prenom(Pv_Controle    VARCHAR2,
                            Pv_Prenom      VARCHAR2,
                            Pv_Fournisseur VARCHAR2,
                            Pv_Site        VARCHAR2) IS 
 
  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF Length(Pv_Prenom) > 20 THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le prénom du bénéficiaire fait plus de 20 caractères');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le prénom du bénéficiaire fait plus de 20 caractères');
          Vb_Erreur_Controle := TRUE;
      END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle de la profession                   --
  --           => Il doit faire 30 caractères maxi            --
  --------------------------------------------------------------
  PROCEDURE Controle_Profession(Pv_Controle    VARCHAR2,
                                Pv_Profession  VARCHAR2,
                                Pv_Fournisseur VARCHAR2,
                                Pv_Site        VARCHAR2) IS 
 
  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF Length(Pv_Profession) > 30 THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'La profession fait plus de 30 caractères');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'La profession fait plus de 30 caractères');
          Vb_Erreur_Controle := TRUE;
      END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du nom et du prénom                --
  --           => pour les personnes physiques, le nom et le  --
  --              prénom doivent être renseignés              --
  --------------------------------------------------------------
  PROCEDURE Controle_Nom_Prenom(Pv_Controle       VARCHAR2,
                                Pv_Nom            VARCHAR2,
                                Pv_Prenom         VARCHAR2,
                                Pv_Fournisseur    VARCHAR2,
                                Pv_Site           VARCHAR2) IS 
 
  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF Pv_Nom    != Rpad(' ', 30, ' ') AND
         Pv_Prenom  = Rpad(' ', 20, ' ') THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le prénom du bénéficiaire doit être obligatoirement renseigné');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le prénom du bénéficiaire doit être obligatoirement renseigné');
          Vb_Erreur_Controle := TRUE;
      END IF;
  END;

  --------------------------------------------------------------
  -- Procédure de contrôle du nom et de la raison sociale     --
  --           => le nom ou la raison sociale doivent être    --
  --              renseignés                                  --
  --------------------------------------------------------------
  PROCEDURE Controle_Nom_Raison_Sociale(Pv_Controle       VARCHAR2,
                                        Pv_Nom            VARCHAR2,
                                        Pv_Raison_Sociale VARCHAR2,
                                        Pv_Fournisseur    VARCHAR2,
                                        Pv_Site           VARCHAR2) IS 
 
  BEGIN
      Vv_Debut_Message := Debut_Message(Pv_Fournisseur, Pv_Site);

      IF Pv_Nom            = Rpad(' ', 30, ' ') AND
         Pv_Raison_Sociale = Rpad(' ', 50, ' ') THEN
          -- Dka_Tools_Pkg.Put_Outdebug_Message(Vv_Debut_Message ||
          --                                    'Le nom du bénéficiaire ou la raison sociale doivent être obligatoirement renseignés');
          Put_Log_Message(Pv_Controle, Vv_Debut_Message ||
                          'Le nom du bénéficiaire ou la raison sociale doivent être obligatoirement renseignés');
          Vb_Erreur_Controle := TRUE;
      END IF;
  END;
  ----------------------------------------------------------------

BEGIN

  Vb_Erreur_Controle := FALSE;

  --------------------------------------------------
  -- Récupération du numéro de traitement courant --
  --------------------------------------------------
  Vn_Request_Id := Fnd_Global.Conc_Request_Id;

  -->JJA 2015/08/20
  --------------------------------------------------
  -- Récupération de la valeur SEUIL              --
  --------------------------------------------------
  dka_tools_pkg.get_parameter('DKA_SAPDAS2_CTL','SEUIL',vr_data,vn_retcode,vv_err_msg);
        
  IF  vn_retcode != 0 THEN
    Dka_Tools_Pkg.put_outdebug_message('Le seuil ne peut pas être défini.'||chr(10)||
                                       'Valider le paramétrage de DKA_SAPDAS2_CTL / SEUIL de DKA_PARAMETERS.');
    raise erreur_seuil;
  END IF;
        
  vn_seuil := vr_data.number_value;
  Dka_Tools_Pkg.put_log_message('Le seuil est de : '||vn_seuil);
  --<JJA 2015/08/20

  ---------------------------------------------------
  -- Suppression des données des tables de travail --
  ---------------------------------------------------
  IF Pv_Debug_Mode = 'N' THEN
    DELETE FROM Dka_Sapdas2_010 Ds
    WHERE  EXISTS (SELECT 'X' 
                   FROM   Fnd_Concurrent_Requests Fcr
                   WHERE  Fcr.Request_Id = Ds.Request_Id
                   AND    Fcr.Phase_Code = 'C');

    DELETE FROM Dka_Sapdas2_020 Ds
    WHERE  EXISTS (SELECT 'X' 
                   FROM   Fnd_Concurrent_Requests Fcr
                   WHERE  Fcr.Request_Id = Ds.Request_Id
                   AND    Fcr.Phase_Code = 'C');

    DELETE FROM Dka_Sapdas2_210 Ds
    WHERE  EXISTS (SELECT 'X' 
                   FROM   Fnd_Concurrent_Requests Fcr
                   WHERE  Fcr.Request_Id = Ds.Request_Id
                   AND    Fcr.Phase_Code = 'C');

    DELETE FROM Dka_Sapdas2_300 Ds
    WHERE  EXISTS (SELECT 'X' 
                   FROM   Fnd_Concurrent_Requests Fcr
                   WHERE  Fcr.Request_Id = Ds.Request_Id
                   AND    Fcr.Phase_Code = 'C');

    DELETE FROM Dka_Sapdas2_310 Ds
    WHERE  EXISTS (SELECT 'X' 
                   FROM   Fnd_Concurrent_Requests Fcr
                   WHERE  Fcr.Request_Id = Ds.Request_Id
                   AND    Fcr.Phase_Code = 'C');
  END IF;
        
  -----------------------------------------
  -- Contrôle de l'entête Entreprise 010 --
  -----------------------------------------
  -- Dka_Tools_Pkg.Put_Outdebug_Message('=> CONTROLE DE L''ENTETE ENTREPRISE 010');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('======================================');
  Put_Log_Message(Pv_Controle, '=> CONTROLE DE L''ENTETE ENTREPRISE 010');
  Put_Log_Message(Pv_Controle, '======================================');

  OPEN Cur_010;
  LOOP
    FETCH Cur_010 INTO Rec_010;
    EXIT WHEN Cur_010%NOTFOUND;

    Vn_Nb_Total_Enreg := Vn_Nb_Total_Enreg + 1;

    -------------------------------------------------------------------------
    -- Le numéro de siren doit être renseigné, numérique et différent de 0 --
    -------------------------------------------------------------------------
    Controle_Siren(Pv_Controle, Rec_010.Siren_Entreprise, NULL, NULL);
    Vv_Siren := Lpad(Nvl(Rec_010.Siren_Entreprise, '0'), 9, '0');

    -----------------------------------------------------------------------
    -- La raison sociale doit faire 50 caractères maxi et être renseigné --
    -----------------------------------------------------------------------
    Controle_Raison_Sociale(Pv_Controle, Rec_010.Raison_Sociale, 'Y', NULL, NULL);
    Vv_Raison_Sociale := Rpad(Nvl(Conversion_Chaine(Substr(Rec_010.Raison_Sociale, 1, 50)), ' '), 50, ' ');

    --------------------------------------------------------
    -- L'adresse complément doit faire 32 caractères maxi --
    --------------------------------------------------------
    Controle_Adresse_Comp(Pv_Controle, Rec_010.Adresse_Complement, NULL, NULL);
    Rec_010.Adresse_Complement := Rpad(Nvl(Conversion_Chaine(Substr(Rec_010.Adresse_Complement, 1, 32)), ' '), 32, ' ');

    --------------------------------------------------
    -- L'adresse voie doit faire 32 caractères maxi --
    --------------------------------------------------
    Controle_Adresse_Voie(Pv_Controle, Rec_010.Adresse_Voie, NULL, NULL);
    Rec_010.Adresse_Voie := Rpad(Nvl(Conversion_Chaine(Substr(Rec_010.Adresse_Voie, 1, 32)), ' '), 32, ' ');

    ---------------------------------------
    -- Le code INSEE doit être numérique --
    ---------------------------------------
    Controle_Code_Insee(Pv_Controle, Rec_010.Code_Insee, NULL, NULL);

    -----------------------------------------------------------------
    -- La commune doit faire 26 caractères maxi et être renseignée --
    -----------------------------------------------------------------
    Controle_Commune(Pv_Controle, Rec_010.Commune, NULL, NULL);
    Rec_010.Commune := Rpad(Nvl(Conversion_Chaine(Substr(Rec_010.Commune, 1, 26)), ' '), 26, ' ');

    ---------------------------------------------------------------------
    -- Le code postal doit être renseigné, numérique et différent de 0 --
    ---------------------------------------------------------------------
    Controle_Code_Postal(Pv_Controle, Rec_010.Code_Postal, NULL, NULL);
    Rec_010.Code_Postal := Lpad(Nvl(Substr(Rec_010.Code_postal, 1, 5), '0'), 5, '0');

    ----------------------------------------------------------------------------
    -- Le bureau distributeur doit faire 26 caractères maxi et être renseigné --
    ----------------------------------------------------------------------------
    Controle_Bureau_Distributeur(Pv_Controle, Rec_010.Bureau_Distributeur, NULL, NULL);
    Rec_010.Bureau_Distributeur := Rpad(Nvl(Conversion_Chaine(Substr(Rec_010.Bureau_Distributeur, 1, 26)), ' '), 26, ' ');

    -------------------------------------------------------------------------
    -- Le numéro de siret doit être renseigné, numérique et différent de 0 --
    -------------------------------------------------------------------------
    Controle_Siret(Pv_Controle, Rec_010.Siret_Etablissement, 'Y', NULL, NULL);
    Vv_Siret := Lpad(Nvl(Rec_010.Siret_Etablissement, '0'), 14, '0');

    ---------------------------------------------
    -- Insertion dans la table Dka_Sapdas2_010 --
    ---------------------------------------------
    INSERT INTO Dka_Sapdas2_010
    VALUES
        (Rec_010.Request_Id,
         Vv_Siren,
         Rec_010.Z1,
         Rec_010.Type_Enregistrement,
         Rec_010.Z2,
         Rec_010.Code_Ape,
         Rec_010.Z3,
         Vv_Raison_Sociale,
         Rec_010.Adresse_Complement,
         Rec_010.Z4,
         Rec_010.Adresse_Voie,
         Rec_010.Code_Insee,
         Rec_010.Z5,
         Rec_010.Commune,
         Rec_010.Code_Postal,
         Rec_010.Z6,
         Rec_010.Bureau_Distributeur,
         Rec_010.Z7,
         Rec_010.Type_Fichier,
         Vv_Siret,
         Rec_010.Z8,
         Rec_010.Adresse_Complement,
         Rec_010.Z9,
         Rec_010.Adresse_Voie,
         Rec_010.Code_Insee,
         Rec_010.Z10,
         Rec_010.Commune,
         Rec_010.Code_Postal,
         Rec_010.Z11,
         Rec_010.Bureau_Distributeur,
         Rec_010.Z12,
         Rec_010.Z13);

    Vv_Raison_Sociale_Entreprise := Vv_Raison_Sociale;
    Vv_Numero_Siren_Entreprise   := Vv_Siren;
    Vv_Code_Ape_Entreprise       := Rec_010.Code_Ape;
    Vv_Adr_Comp_Entreprise       := Rec_010.Adresse_Complement;
    Vv_Adr_Voie_Entreprise       := Rec_010.Adresse_Voie;
    Vv_Code_Postal_Entreprise    := Rec_010.Code_Postal;
    Vv_Commune_Entreprise        := Rec_010.Commune;

  END LOOP;
  CLOSE Cur_010;

  --------------------------------------------
  -- Contrôle de l'entête Etablissement 020 --
  --------------------------------------------
  -- Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('=> CONTROLE DE L''ENTETE ETABLISSEMENT 020');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('=========================================');
  Put_Log_Message(Pv_Controle, ' ');
  Put_Log_Message(Pv_Controle, '=> CONTROLE DE L''ENTETE ETABLISSEMENT 020');
  Put_Log_Message(Pv_Controle, '=========================================');

  OPEN Cur_020;
  LOOP
    FETCH Cur_020 INTO Rec_020;
    EXIT WHEN Cur_020%NOTFOUND;

    ---------------------------------------------------
    -- Incrémentation des compteurs d'enregistrement --
    ---------------------------------------------------
    Vn_Nb_Enreg_020   := Vn_Nb_Enreg_020   + 1;
    Vn_Nb_Total_Enreg := Vn_Nb_Total_Enreg + 1;

    -------------------------------------------------------------------------
    -- Le numéro de siren doit être renseigné, numérique et différent de 0 --
    -------------------------------------------------------------------------
    Controle_Siren(Pv_Controle, Rec_020.Siren_Etablissement, NULL, NULL);
    Vv_Siren := Lpad(Nvl(Rec_020.Siren_Etablissement, '0'), 9, '0');

    -------------------------------------------------------------
    -- Le NIC doit être renseigné, numérique et différent de 0 --
    -------------------------------------------------------------
    Controle_Nic(Pv_Controle, Rec_020.Nic_Etablissement, NULL, NULL);
    Vv_Nic := Lpad(Nvl(Rec_020.Nic_Etablissement, '0'), 5, '0');

    -----------------------------------------------------------------------
    -- La raison sociale doit faire 50 caractères maxi et être renseigné --
    -----------------------------------------------------------------------
    Controle_Raison_Sociale(Pv_Controle, Rec_020.Raison_Sociale, 'Y', NULL, NULL);
    Vv_Raison_Sociale := Rpad(Nvl(Conversion_Chaine(Substr(Rec_020.Raison_Sociale, 1, 50)), ' '), 50, ' ');

    --------------------------------------------------------
    -- L'adresse complément doit faire 32 caractères maxi --
    --------------------------------------------------------
    Controle_Adresse_Comp(Pv_Controle, Rec_020.Adresse_Complement, NULL, NULL);
    Rec_020.Adresse_Complement := Rpad(Nvl(Conversion_Chaine(Substr(Rec_020.Adresse_Complement, 1, 32)), ' '), 32, ' ');

    --------------------------------------------------
    -- L'adresse voie doit faire 32 caractères maxi --
    --------------------------------------------------
    Controle_Adresse_Voie(Pv_Controle, Rec_020.Adresse_Voie, NULL, NULL);
    Rec_020.Adresse_Voie := Rpad(Nvl(Conversion_Chaine(Substr(Rec_020.Adresse_Voie, 1, 32)), ' '), 32, ' ');

    ---------------------------------------
    -- Le code INSEE doit être numérique --
    ---------------------------------------
    Controle_Code_Insee(Pv_Controle, Rec_020.Code_Insee, NULL, NULL);

    -----------------------------------------------------------------
    -- La commune doit faire 26 caractères maxi et être renseignée --
    -----------------------------------------------------------------
    Controle_Commune(Pv_Controle, Rec_020.Commune, NULL, NULL);
    Rec_020.Commune := Rpad(Nvl(Conversion_Chaine(Substr(Rec_020.Commune, 1, 26)), ' '), 26, ' ');

    ---------------------------------------------------------------------
    -- Le code postal doit être renseigné, numérique et différent de 0 --
    ---------------------------------------------------------------------
    Controle_Code_Postal(Pv_Controle, Rec_020.Code_Postal, NULL, NULL);
    Rec_020.Code_Postal := Lpad(Nvl(Substr(Rec_020.Code_postal, 1, 5), '0'), 5, '0');

    ----------------------------------------------------------------------------
    -- Le bureau distributeur doit faire 26 caractères maxi et être renseigné --
    ----------------------------------------------------------------------------
    Controle_Bureau_Distributeur(Pv_Controle, Rec_020.Bureau_Distributeur, NULL, NULL);
    Rec_020.Bureau_Distributeur := Rpad(Nvl(Conversion_Chaine(Substr(Rec_020.Bureau_Distributeur, 1, 26)), ' '), 26, ' ');

    ---------------------------------------------
    -- Insertion dans la table Dka_Sapdas2_020 --
    ---------------------------------------------
    INSERT INTO Dka_Sapdas2_020
    VALUES
        (Rec_020.Request_Id,
         Vv_Siren,
         Vv_Nic,
         Rec_020.Code_Section_etablissement,
         Rec_020.Validite,
         Rec_020.Type_Dads,
         Rec_020.Type_Enregistrement,
         Rec_020.Z1,
         Rec_020.Code_Ape,
         Rec_020.Z2,
         Rec_020.Siren_01_Jan,
         Rec_020.Nic_01_Jan,
         Rec_020.Z3,
         Vv_Raison_Sociale,
         Rec_020.Adresse_Complement,
         Rec_020.Z4,
         Rec_020.Adresse_Voie,
         Rec_020.Code_Insee,
         Rec_020.Z5,
         Rec_020.Commune,
         Rec_020.Code_Postal,
         Rec_020.Z6,
         Rec_020.Bureau_Distributeur,
         Rec_020.Profession,
         Rec_020.Z7,
         Rec_020.Code_Taxe_Salaires,
         Rec_020.Z8);

    Vv_Numero_Siret_Entreprise := Rec_020.Siren_Etablissement || Rec_020.Nic_Etablissement;
    Vv_Activite_Entreprise     := Rec_020.Profession;

  END LOOP;
  CLOSE Cur_020;

  -------------------------------------------
  -- Contrôle de la ligne d'honoraires 210 --
  -------------------------------------------
  -- Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('=> CONTROLE DE LA LIGNE HONORAIRES 210');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('======================================');
  Put_Log_Message(Pv_Controle, ' ');
  Put_Log_Message(Pv_Controle, '=> CONTROLE DE LA LIGNE HONORAIRES 210');
  Put_Log_Message(Pv_Controle, '======================================');

  OPEN Cur_210;
  LOOP
    FETCH Cur_210 INTO Rec_210;
    EXIT WHEN Cur_210%NOTFOUND;

    -----------------------------------------------------------------
    -- On ne prend en compte que les montants supérieurs à vn_seuil--
    -----------------------------------------------------------------
    IF Rec_210.Dhon_H > vn_seuil/*JJA 2015/08/20 -- 76*/ THEN
      -------------------------------------------------------------------------
      -- Le numéro de siren doit être renseigné, numérique et différent de 0 --
      -------------------------------------------------------------------------
      Controle_Siren(Pv_Controle, Rec_210.Siren_Etablissement, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Vv_Siren := Lpad(Nvl(Rec_210.Siren_Etablissement, '0'), 9, '0');

      -------------------------------------------------------------
      -- Le NIC doit être renseigné, numérique et différent de 0 --
      -------------------------------------------------------------
      Controle_Nic(Pv_Controle, Rec_210.Nic_Etablissement, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Vv_Nic := Lpad(Nvl(Rec_210.Nic_Etablissement, '0'), 5, '0');

      -----------------------------------------------------------------------------------------
      -- Le numéro de siren du bénéficiaire doit être renseigné, numérique et différent de 0 --
      -----------------------------------------------------------------------------------------
      Controle_Siren(Pv_Controle, Rec_210.Siren_Beneficiaire, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Vv_Siren_Beneficiaire := Lpad(Nvl(Rec_210.Siren_Beneficiaire, '0'), 9, '0');

      -----------------------------------------------------------------------------
      -- Le NIC du bénéficiaire doit être renseigné, numérique et différent de 0 --
      -----------------------------------------------------------------------------
      Controle_Nic(Pv_Controle, Rec_210.Nic_Beneficiaire, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Vv_Nic_Beneficiaire := Lpad(Nvl(Rec_210.Nic_Beneficiaire, '0'), 5, '0');

      ------------------------------------------------------------
      -- Le numéro de SIRET du bénéficiaire doit être numérique --
      ------------------------------------------------------------
      Vv_Siret_Beneficiaire := Vv_Siren_Beneficiaire || Vv_Nic_Beneficiaire;
      Controle_Siret(Pv_Controle, Vv_Siret_Beneficiaire, 'N', Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);

      ----------------------------------------------------------
      -- Le nom du bénéficiaire doit faire 30 caractères maxi --
      ----------------------------------------------------------
      Controle_Nom(Pv_Controle, Rec_210.Nom, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Rec_210.Nom := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Nom, 1, 30)), ' '), 30, ' ');

      -------------------------------------------------------------
      -- Le prénom du bénéficiaire doit faire 20 caractères maxi --
      -------------------------------------------------------------
      Controle_Prenom(Pv_Controle, Rec_210.Prenom, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Rec_210.Prenom := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Prenom, 1, 20)), ' '), 20, ' ');

      -------------------------------------------------------------------------------
      -- Pour les personnes physiques, le nom et le prénom doivent être renseignés --
      -------------------------------------------------------------------------------
      Controle_Nom_Prenom(Pv_Controle, Rec_210.Nom, Rec_210.Prenom, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);

      -----------------------------------------------------
      -- La raison sociale doit faire 50 caractères maxi --
      -----------------------------------------------------
      Controle_Raison_Sociale(Pv_Controle, Rec_210.Raison_Sociale, 'N', Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Vv_Raison_Sociale := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Raison_Sociale, 1, 50)), ' '), 50, ' ');

      -------------------------------------------------------------------------
      -- Le nom du bénéficiaire ou la raison sociale doivent être renseignés --
      -------------------------------------------------------------------------
      Controle_Nom_Raison_Sociale(Pv_Controle, Rec_210.Nom, Vv_Raison_Sociale, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);

      -------------------------------------------------
      -- La profession doit faire 30 caractères maxi --
      -------------------------------------------------
      Controle_Profession(Pv_Controle, Rec_210.Profession, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Vv_Profession := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Profession, 1, 30)), ' '), 30, ' ');

      --------------------------------------------------------
      -- L'adresse complément doit faire 32 caractères maxi --
      --------------------------------------------------------
      Controle_Adresse_Comp(Pv_Controle, Rec_210.Adresse_Complement, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Rec_210.Adresse_Complement := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Adresse_Complement, 1, 32)), ' '), 32, ' ');

      --------------------------------------------------
      -- L'adresse voie doit faire 32 caractères maxi --
      --------------------------------------------------
      Controle_Adresse_Voie(Pv_Controle, Rec_210.Adresse_Voie, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Rec_210.Adresse_Voie := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Adresse_Voie, 1, 32)), ' '), 32, ' ');

      ---------------------------------------
      -- Le code INSEE doit être numérique --
      ---------------------------------------
      Controle_Code_Insee(Pv_Controle, Rec_210.Code_Insee, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);

      -----------------------------------------------------------------
      -- La commune doit faire 26 caractères maxi et être renseignée --
      -----------------------------------------------------------------
      Controle_Commune(Pv_Controle, Rec_210.Commune, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Vv_Commune := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Commune, 1, 26)), ' '), 26, ' ');

      ---------------------------------------------------------------------
      -- Le code postal doit être renseigné, numérique et différent de 0 --
      ---------------------------------------------------------------------
      Controle_Code_Postal(Pv_Controle, Rec_210.Code_Postal, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Rec_210.Code_Postal := Lpad(Nvl(Substr(Rec_210.Code_postal, 1, 5), '0'), 5, '0');

      ----------------------------------------------------------------------------
      -- Le bureau distributeur doit faire 26 caractères maxi et être renseigné --
      ----------------------------------------------------------------------------
      Controle_Bureau_Distributeur(Pv_Controle, Rec_210.Bureau_Distributeur, Rec_210.Numero_Fournisseur, Rec_210.Site_Fournisseur);
      Rec_210.Bureau_Distributeur := Rpad(Nvl(Conversion_Chaine(Substr(Rec_210.Bureau_Distributeur, 1, 26)), ' '), 26, ' ');

      ---------------------------------------------
      -- Insertion dans la table Dka_Sapdas2_210 --
      ---------------------------------------------
      INSERT INTO Dka_Sapdas2_210
      VALUES
          (Rec_210.Request_Id,
           Rec_210.Vendor_Id,
           Rec_210.Vendor_Site_Id,
           Vv_Siren,
           vv_Nic,
           Rec_210.Code_Section_Etablissement,
           Rec_210.Validite,
           Rec_210.Type_Dads,
           Rec_210.Type_Enregistrement,
           Vv_Siret_Beneficiaire,
           Rec_210.Nom,
           Rec_210.Prenom,
           Vv_Raison_Sociale,
           Vv_Profession,
           Rec_210.Adresse_Complement,
           Rec_210.Z1,
           Rec_210.Adresse_Voie,
           Rec_210.Code_Insee,
           Rec_210.Z2,
           Vv_Commune,
           Rec_210.Code_Postal,
           Rec_210.Z3,
           Rec_210.Bureau_Distributeur,
           Rec_210.Dhon_H,
           Rec_210.Dcom_C,
           Rec_210.Dco_Co,
           Rec_210.Dris_R,
           Rec_210.Dje_Jp,
           Rec_210.Dda_Da,
           Rec_210.Ddi_Di,
           Rec_210.Dau_Ar,
           Rec_210.Inde,
           Rec_210.Avan,
           Rec_210.Rete,
           Rec_210.Nat_Avan_Nour,
           Rec_210.Nat_Avan_Loge,
           Rec_210.Nat_Avan_Voit,
           Rec_210.Nat_Avan_Autr,
           Rec_210.Nat_Avan_Ntic,
           Rec_210.Nat_Inde_Forf,
           Rec_210.Nat_Inde_Remb,
           Rec_210.Nat_Inde_Pris,
           Rec_210.Nat_Tva_Redui,
           Rec_210.Nat_Tva_Dispe,
           Rec_210.Tva_Nette,
           Rec_210.Z4);
    END IF;

  END LOOP;
  CLOSE Cur_210;

  ------------------------------------------------------------------------------
  -- Calcul du nombre d'enregistrements "cumulés" de la table Dka_Sapdas2_210 --
  ------------------------------------------------------------------------------
  SELECT COUNT (DISTINCT(Ds.Siren_Etablissement || 
                         Ds.Nic_Etablissement || 
                         Ds.Code_Section_Etablissement || 
                         Ds.Validite || 
                         Ds.Type_Dads || 
                         Ds.Type_Enregistrement || 
                         Ds.Siret_Beneficiaire || 
                         Ds.Nom || 
                         Ds.Prenom || 
                         Ds.Raison_Sociale || 
                         Ds.Profession || 
                         Ds.Adresse_Complement || 
                         Ds.Z1 || 
                         Ds.Adresse_Voie || 
                         Ds.Code_Insee || 
                         Ds.Z2 || 
                         Ds.Commune || 
                         Ds.Code_Postal || 
                         Ds.Z3 || 
                         Ds.Bureau_Distributeur || 
                         Ds.Nat_Avan_Nour || 
                         Ds.Nat_Avan_Loge || 
                         Ds.Nat_Avan_Voit || 
                         Ds.Nat_Avan_Autr || 
                         Ds.Nat_Avan_Ntic || 
                         Ds.Nat_Inde_Forf || 
                         Ds.Nat_Inde_Remb || 
                         Ds.Nat_Inde_Pris || 
                         Ds.Nat_Tva_Redui || 
                         Ds.Nat_Tva_Dispe || 
                         Ds.Z4))
  INTO   Vn_Nb_Enreg_210
  FROM   Dka_Sapdas2_210 Ds
  WHERE  Ds.Request_Id = Vn_Request_Id;

  ----------------------------------------------------
  -- Incrémentation des compteurs d'enregistrements --
  ----------------------------------------------------
  Vn_Nb_Total_Enreg := Vn_Nb_Total_Enreg + Vn_Nb_Enreg_210;

  --------------------------------------------------
  -- Contrôle de la ligne Total Etablissement 300 --
  --------------------------------------------------
  -- Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('=> CONTROLE DU TOTAL ETABLISSEMENT 300');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('======================================');
  Put_Log_Message(Pv_Controle, ' ');
  Put_Log_Message(Pv_Controle, '=> CONTROLE DU TOTAL ETABLISSEMENT 300');
  Put_Log_Message(Pv_Controle, '======================================');

  OPEN Cur_300;
  LOOP
    FETCH Cur_300 INTO Rec_300;
    EXIT WHEN Cur_300%NOTFOUND;

    ----------------------------------------------------
    -- Incrémentation des compteurs d'enregistrements --
    ----------------------------------------------------
    Vn_Nb_Total_Enreg := Vn_Nb_Total_Enreg + 1;

    -------------------------------------------------------------------------
    -- Le numéro de siren doit être renseigné, numérique et différent de 0 --
    -------------------------------------------------------------------------
    Controle_Siren(Pv_Controle, Rec_300.Siren_Etablissement, NULL, NULL);

    -------------------------------------------------------------
    -- Le NIC doit être renseigné, numérique et différent de 0 --
    -------------------------------------------------------------
    Controle_Nic(Pv_Controle, Rec_300.Nic_Etablissement, NULL, NULL);

    ---------------------------------------------
    -- Insertion dans la table Dka_Sapdas2_300 --
    ---------------------------------------------
    INSERT INTO Dka_Sapdas2_300
    VALUES
        (Rec_300.Request_Id,
         Rec_300.Siren_Etablissement,
         Rec_300.Nic_Etablissement,
         Rec_300.Code_Section_Etablissement,
         Rec_300.Validite,
         Rec_300.Type_Dads,
         Rec_300.Type_Enregistrement,
         Rec_300.Z1,
         Rec_300.Base_Brute_Fiscale,
         Rec_300.Remunerations_Nettes,
         Rec_300.Avantages_Nature,
         Rec_300.Frais_Professionnels,
         Rec_300.Cheques_Vacances,
         Rec_300.Total_Imposable,
         Rec_300.Total_Base_Imposable_1,
         Rec_300.Total_Base_Imposable_2,
         Rec_300.Total_Retenu_Source,
         Rec_300.Dhon_H,
         Rec_300.Dcom_C,
         Rec_300.Dco_Co,
         Rec_300.Dris_R,
         Rec_300.Dje_Jp,
         Rec_300.Dda_Da,
         Rec_300.Ddi_Di,
         Rec_300.Dau_Ar,
         Rec_300.Inde,
         Rec_300.Avan,
         Rec_300.Rete,
         Rec_300.Z2,
         Rec_300.Montant_Taxe,
         Rec_300.Z3,
         Rec_300.Effectif,
         Rec_300.Z4,
         Rec_300.Nom_Responsable,
         Rec_300.Prenom_Responsable,
         Rec_300.Telephone_Responsable,
         Rec_300.Z5);

  END LOOP;
  CLOSE Cur_300;

  -----------------------------------------------
  -- Contrôle de la ligne Total Entreprise 310 --
  -----------------------------------------------
  -- Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('=> CONTROLE DU TOTAL ENTREPRISE 310');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('===================================');
  Put_Log_Message(Pv_Controle, ' ');
  Put_Log_Message(Pv_Controle, '=> CONTROLE DU TOTAL ENTREPRISE 310');
  Put_Log_Message(Pv_Controle, '===================================');

  OPEN Cur_310;
  LOOP
    FETCH Cur_310 INTO Rec_310;
    EXIT WHEN Cur_310%NOTFOUND;

    ----------------------------------------------------
    -- Incrémentation des compteurs d'enregistrements --
    ----------------------------------------------------
    Vn_Nb_Total_Enreg := Vn_Nb_Total_Enreg + 1;

    -------------------------------------------------------------------------
    -- Le numéro de siren doit être renseigné, numérique et différent de 0 --
    -------------------------------------------------------------------------
    Controle_Siren(Pv_Controle, Rec_310.Siren_Entreprise, NULL, NULL);

    ---------------------------------------------
    -- Insertion dans la table Dka_Sapdas2_310 --
    ---------------------------------------------
    INSERT INTO Dka_Sapdas2_310
    VALUES
        (Rec_310.Request_Id,
         Rec_310.Siren_Entreprise,
         Rec_310.Z1,
         Rec_310.Type_Enregistrement,
         Rec_310.Nombre_Etablissements,
         Rec_310.Nombre_Salaries,
         Rec_310.Nombre_Honoraires,
         Rec_310.Z2,
         Rec_310.Base_Brute_Fiscale,
         Rec_310.Remunerations_Nettes,
         Rec_310.Avantages_Nature,
         Rec_310.Frais_Professionnels,
         Rec_310.Cheques_Vacances,
         Rec_310.Total_Imposable,
         Rec_310.Total_Base_Imposable_1,
         Rec_310.Total_Base_Imposable_2,
         Rec_310.Total_Retenu_Source,
         Rec_310.Dhon_H,
         Rec_310.Dcom_C,
         Rec_310.Dco_Co,
         Rec_310.Dris_R,
         Rec_310.Dje_Jp,
         Rec_310.Dda_Da,
         Rec_310.Ddi_Di,
         Rec_310.Dau_Ar,
         Rec_310.Inde,
         Rec_310.Avan,
         Rec_310.Rete,
         Rec_310.Z3,
         Rec_310.Montant_Taxe,
         Rec_310.Z4,
         Rec_310.Effectif,
         Rec_310.Z5);

    Vn_Montant_Total_Honoraires := Rec_310.Dhon_H;

  END LOOP;
  CLOSE Cur_310;

  COMMIT;

  -------------------------------
  -- Affichage du compte-rendu --
  -------------------------------
  -- Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('INFORMATIONS DE CONTROLE');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('========================');
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Raison sociale      : ' || Vv_Raison_Sociale_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Numéro SIREN        : ' || Vv_Numero_Siren_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Code APE            : ' || Vv_Code_Ape_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Adresse complète    : ' || Vv_Adr_Voie_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('                      ' || Vv_Adr_Comp_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('                      ' || Vv_Code_Postal_Entreprise || ' ' || Vv_Commune_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Numéro SIRET        : ' || Vv_Numero_Siret_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Profession/Activité : ' || Vv_Activite_Entreprise);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Nombre enreg. 020   : ' || Vn_Nb_Enreg_020);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Nombre enreg. 210   : ' || Vn_Nb_Enreg_210);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Nombre total enreg. : ' || Vn_Nb_Total_Enreg);
  -- Dka_Tools_Pkg.Put_Outdebug_Message('Montant total honor.: ' || Vn_Montant_Total_Honoraires);
  Put_Log_Message(Pv_Controle, ' ');
  Put_Log_Message(Pv_Controle, 'INFORMATIONS DE CONTROLE');
  Put_Log_Message(Pv_Controle, '========================');
  Put_Log_Message(Pv_Controle, 'Raison sociale      : ' || Vv_Raison_Sociale_Entreprise);
  Put_Log_Message(Pv_Controle, 'Numéro SIREN        : ' || Vv_Numero_Siren_Entreprise);
  Put_Log_Message(Pv_Controle, 'Code APE            : ' || Vv_Code_Ape_Entreprise);
  Put_Log_Message(Pv_Controle, 'Adresse complète    : ' || Vv_Adr_Voie_Entreprise);
  Put_Log_Message(Pv_Controle, '                      ' || Vv_Adr_Comp_Entreprise);
  Put_Log_Message(Pv_Controle, '                      ' || Vv_Code_Postal_Entreprise || ' ' || Vv_Commune_Entreprise);
  Put_Log_Message(Pv_Controle, 'Numéro SIRET        : ' || Vv_Numero_Siret_Entreprise);
  Put_Log_Message(Pv_Controle, 'Profession/Activité : ' || Vv_Activite_Entreprise);
  Put_Log_Message(Pv_Controle, 'Seuil               : ' || vn_seuil);   --JJA 20/08/2015
  Put_Log_Message(Pv_Controle, 'Nombre enreg. 020   : ' || Vn_Nb_Enreg_020);
  Put_Log_Message(Pv_Controle, 'Nombre enreg. 210   : ' || Vn_Nb_Enreg_210);
  Put_Log_Message(Pv_Controle, 'Nombre total enreg. : ' || Vn_Nb_Total_Enreg);
  Put_Log_Message(Pv_Controle, 'Montant total honor.: ' || Vn_Montant_Total_Honoraires);

  ----------------------------------------------------------------------
  -- Extraction des données pour formatage et constitution du fichier --
  ----------------------------------------------------------------------
  IF Pv_Controle = 'N' AND NOT Vb_Erreur_Controle THEN
    Extract_Data(Vn_Request_Id);
  END IF;

  ---------------------------------------------------
  -- Suppression des données des tables de travail --
  ---------------------------------------------------
  IF Pv_Debug_Mode = 'N' THEN
    DELETE FROM Dka_Sapdas2_010
    WHERE  Request_Id = Vn_Request_Id;

    DELETE FROM Dka_Sapdas2_020
    WHERE  Request_Id = Vn_Request_Id;

    DELETE FROM Dka_Sapdas2_210
    WHERE  Request_Id = Vn_Request_Id;

    DELETE FROM Dka_Sapdas2_300
    WHERE  Request_Id = Vn_Request_Id;

    DELETE FROM Dka_Sapdas2_310
    WHERE  Request_Id = Vn_Request_Id;
  END IF;

  COMMIT;

  -------------------------------------------------------------------------------------
  -- Si il existe des erreurs de contrôle, on termine le traitement en avertissement --
  -------------------------------------------------------------------------------------
  IF Vb_Erreur_Controle THEN
      Pn_Retcode := 1;
      Pv_Errbuf  := 'Erreur lors du contrôle des données : voir le compte-rendu';
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Pn_Retcode := 2;
    Pv_Errbuf  := 'ERREUR LORS DU TRAITEMENT : ' || SQLCODE || ' - ' || Substr(SQLERRM, 1, 80);
END Control_Data;

END Dka_Sapdas2_Pkg;
/
SHOW ERRORS
EXIT
