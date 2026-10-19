Def Version_Package='v1.0 10/09/2002'
Def Package_Name='DKA_AMOR_FISC_PKG'

--------------------------------
--------------------------------
--   Package  SPECIFICATION   --
--------------------------------
--------------------------------

Set verify off
Create Or Replace Package &&Package_Name As

--------------------------------------------------------------------------------
-- $Header: H:/developpement/CVSROOT/ETA040\040-\040Amortissements\040fiscaux\040-\040Mouvements\040de\040la\040période\040-/Sources/SFAAMORFISC/sql/DKA_AMOR_FISC_PKG.pks,v 1.1.1.1 2004/06/29 13:35:07 flechene Exp $
-- FICHIER       : &&Package_name..sql &&version_Package 
-- DESCRIPTION   :  Outils de chargement/dechargement de programmes
--
-- AUTEUR        :  Prénom, Nom de l'auteur
--
-- DATE CREATION :  Date de création
--
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             : 
-- Date                :
-- Auteur              :
-- Nature              :
--------------------------------------------------------------------------------

Function version
    Return Varchar2;

-- Declaration des type de données spécifique

-- Declaration des Procedures et fonctions publiques

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
                        Pv_Message_Erreur   In Out Varchar2 );

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
                        Pv_Message_Erreur   In Out Varchar2 );

--PRAGMA RESTRICT_REFERENCES (asset_listing_run, RNDS, RNPS, WNDS, WNPS);


-- Declaration des variables globales

End &&Package_Name; -- Package specification
/
Show Error

Exit;
