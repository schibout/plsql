SET VERIFY OFF;
DEFINE package_name = "DKA_SPOBON_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_PKG.pks
-- DESCRIPTION       : DKA_SPOBON_PKG package spec :procedure utiliser dans les vues specifiques
--                     pour edition du bon de commande
--- AUTEUR           : Bernard HANQUIER (CGEY)
--- DATE DE CREATION : 24/06/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : NB_SHIP_TO_LOCATION_ID
        --  Description   : Retourne le nombre de ship_to_location_id different pour une commande
        --
        --  PARAMETRES    :
        --    p_po_header_id        number
        --  VALEUR RETOURNEE :
        --     Description       :
        --     Valeurs possibles : 
        -------------------------------------------------------------------------------------------------------------------
    FUNCTION nb_ship_to_location_id (
        p_po_header_id   IN   NUMBER
    )
        RETURN NUMBER;


        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : NB_PROMISED_DATE
        --  Description   : Retourne le nombre de dates de livraison differentes pour une commande
        --
        --  PARAMETRES    :
        --    p_po_header_id        number
        --  VALEUR RETOURNEE :
        --     Description       :
        --     Valeurs possibles : 
        -------------------------------------------------------------------------------------------------------------------
    FUNCTION nb_promised_date (
        p_po_header_id   IN   NUMBER
    )
        RETURN NUMBER;


        -------------------------------------------------------------------------------------------------------------------
        --  Nom           : NB_PROMISED_DATE_LINE
        --  Description   : Retourne le nombre de dates de livraison differentes pour une ligne de commande
        --
        --  PARAMETRES    :
        --    p_po_line_id        number
        --  VALEUR RETOURNEE :
        --     Description       :
        --     Valeurs possibles : 
        -------------------------------------------------------------------------------------------------------------------
    FUNCTION nb_promised_date_line (
        p_po_line_id   IN   NUMBER
    )
        RETURN NUMBER;


END &&package_name;
/

SHOW ERRORS;

EXIT
