CREATE OR REPLACE PACKAGE DKA_IARRECSICM_MEN_PKG
AS
    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : Projet Hélios
    -- NOM              : DKA_IARRECSICM_MEN_PKG
    -- DESCRIPTION      : DKA_IARRECSICM_MEN_PKG Package Specifications
    --
    -- AUTEUR           : Capgemini
    -- DATE DE CREATION : 12/04/2016
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description 
    -- ---------- --- --------------------------------------------------------------
    -- 08/09/2016 BDE Modificaiton pour le projet Hélios
    -- -----------------------------------------------------------------------------


    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --Gn_Org_Id                NUMBER := TO_NUMBER(Fnd_Profile.Value('ORG_ID'));

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    -- -----------------------------------------------------------------------------
    -- Nom              : Get_Lib_UO
    -- Description      : Fonction de recherche du libellé du centre de gestion
    --                    passé en parametre
    --
    -- PARAMETRES       : Pv_UO     Entrée         Centre de Gestion
    --                    Pv_Lib_UO        Sortie  Libellé Centre de Gestion
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    --FUNCTION Get_Lib_UO(Pv_UO IN VARCHAR2) RETURN VARCHAR2 ;


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
    --FUNCTION Get_Classe_Client (Pv_Classe_Client IN VARCHAR2) RETURN VARCHAR2;


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
    --FUNCTION Get_Categorie_Client (Pv_Categorie_Client IN VARCHAR2) RETURN VARCHAR2;


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
    --                    Pv_Region     Entrée          Centre de gestion
    --                    Pv_Periode    Entrée          Période
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Extraction_Encours(Pv_Errbuf         OUT  VARCHAR2,
                                 Pn_Retcode        OUT  NUMBER,
                                 Pv_Periode IN OUT VARCHAR2,
                                 PV_Region IN VARCHAR2);


END DKA_IARRECSICM_MEN_PKG;
/
SHOW ERROR
EXIT;

