----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOCHARGE_ERRORS.tab
-- DESCRIPTION      : Création de la table DKA_SPOCHARGE_ERRORS
--
-- AUTEUR           : Guillaume LEBLON (CGEY)
-- DATE DE CREATION : 11/03/2004
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA
--                    en lui passant 3 paramètres :                                                 
--                           1) Password DKA                                                        
--                           2) Password APPS                                                       
--                           3) Tablespace des données pour schéma DKA 
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
Connect DKA/&1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE dka_SPOCHARGE_ERRORS
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE dka_SPOCHARGE_ERRORS;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE dka_SPOCHARGE_ERRORS
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE dka_SPOCHARGE_ERRORS(
        soc_cap                                     VARCHAR2(4),
        cdg_cap                                     VARCHAR2(3),
        soc_commande                                VARCHAR2(4),
        num_commande                                VARCHAR2(20),
        date_commande                               DATE,
        num_ligne_commande                          NUMBER,
        project_code                                VARCHAR2(25),
        type_depense                                VARCHAR2(30),
        concatenated_segments                       VARCHAR2(200),
        amount_dr                                   NUMBER(22,5),
        amount_cr                                   NUMBER(22,5),
        po_distribution_id                          NUMBER(15),
        rejection_reason                            VARCHAR2(240),
        Creation_Date                               DATE,
        Created_By                                  NUMBER(15),
        Last_Update_Date                            DATE,
        Last_Updated_By                             NUMBER(15),
        Last_Update_Login                           NUMBER(15),
        request_id                                  NUMBER(15)
        )
TABLESPACE &3 ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES COMMENTAIRES DE COLONNE
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.soc_cap                  IS 'Société de la charge à payer';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.cdg_cap                  IS 'Centre de gestion de la charge à payer';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.soc_commande             IS 'Société de la commande';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.num_commande             IS 'N° de la commande';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.date_commande            IS 'Date de création de la commande';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.num_ligne_commande       IS 'N° de ligne de la commande';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.project_code             IS 'Projet';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.type_depense             IS 'Type de dépense';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.concatenated_segments    IS 'Compte d''imputation de la commande';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.amount_dr                IS 'Montant provisionné au débit';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.amount_cr                IS 'Montant provisionné au crédit';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.po_distribution_id       IS 'Id de la ligne d''imputation de la commande';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.rejection_reason         IS 'Motif de rejet';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.Creation_Date            IS 'Date de réation';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.Created_By               IS 'User de réation';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.Last_Update_Date         IS 'Date de mise à jour';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.Last_Updated_By          IS 'User de mise à jour';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.Last_Update_Login        IS 'Login de mise à jour';
COMMENT ON COLUMN dka_SPOCHARGE_ERRORS.request_id               IS 'N° de traitement';

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON dka_SPOCHARGE_ERRORS TO APPS WITH GRANT OPTION;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&2

DROP SYNONYM dka_SPOCHARGE_ERRORS;
CREATE SYNONYM dka_SPOCHARGE_ERRORS FOR dka.dka_SPOCHARGE_ERRORS;


EXIT;
