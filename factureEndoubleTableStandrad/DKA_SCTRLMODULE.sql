CREATE OR REPLACE PACKAGE DKA_SARRECOUVREMENT_PKG
AS
    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SARRECOUVREMENT_PKG
    -- DESCRIPTION      : DKA_SARRECOUVREMENT_PKG Package Specifications
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 21/03/2008
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
    ---                 pour l'extraction du ratio client.
    -- 21/04/2010 EMA Modification du package selon l'EID20100090 : Ajout de 
    --                nouveaux champs dans l'extraction
    --                Ajout des fonctions : Get_Lib_Centre_Gestion
    --                                      Get_Classe_Client
    --                                      Get_Categorie_Client
    --                Dans les champs Commentaires, les éventuels ; sont remplacés
    --                par des espaces 
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- -----------------------------------------------------------------------------
    -- Nom              : Get_Last_Date
    -- Description      : Fonction de recherche de la date de fin de la dernière
    --                    période fermée
    --
    -- PARAMETRES       : Pv_Periode         Entrée        Période
    --                    Pd_End_Date_Period        Sortie Date de fin de période
    --
    -- VALEUR RETOURNEE :
    --     Description       : 
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    FUNCTION Get_Last_Date (Pv_Periode IN VARCHAR2, Pn_Org_ID IN NUMBER) RETURN DATE;


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
    FUNCTION Get_Lib_Centre_Gestion (Pv_Centre_Gestion IN VARCHAR2) RETURN VARCHAR2;


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
    FUNCTION Get_Classe_Client (Pv_Classe_Client IN VARCHAR2) RETURN VARCHAR2;


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
    FUNCTION Get_Categorie_Client (Pv_Categorie_Client IN VARCHAR2) RETURN VARCHAR2;


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
                                 Pv_Periode     IN      VARCHAR2);


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
    --                    Pv_Periode    Entrée          Période
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Extraction_Avoirs(Pv_Errbuf         OUT  VARCHAR2,
                                Pn_Retcode        OUT  NUMBER,
                                Pv_Debug_Mode  IN      VARCHAR2,
                                Pn_Org_ID      IN      NUMBER,
                                Pv_Periode     IN      VARCHAR2);



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
                                Pv_Detail_Charge  IN      VARCHAR2);


END DKA_SARRECOUVREMENT_PKG;
/
SHOW ERRORS
EXIT

