------------------------------------------------------------------------------------
-- $Id: DKA_SPORES_CONTRAT_I.sql 153 2007-09-12 09:25:26Z NORDEST\jjardez $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPORES_CONTRAT_I.sql
-- DESCRIPTION       : Insertion dans la table des parametres
--
-- AUTEUR            : J. JARDEZ (Capgemini)
-- NOM               : DKA_SPORES_CONTRAT_I.sql
-- DOC. ASSOCIEE     : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- 18/10/2018 QSN artf3037488 TASK0064570 modifier le paramétrage portant sur le nombre de reconductions possibles dans le module SSTR
-- ---------- --- ------------------------------------------------------------------
-- 
------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

DELETE FROM DKA_PARAMETERS WHERE PROGRAM_CODE = 'SPORES_CONTRAT';

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT INSERTION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

INSERT INTO DKA_PARAMETERS (PROGRAM_CODE,PARAMETER_NAME,DESCRIPTION,DATA_TYPE,VARCHAR2_VALUE,NUMBER_VALUE) VALUES ('SPORES_CONTRAT','NB_RECONDUCTION_MAX','Nombre de reconduction maximum pour un contrat','NUMBER',NULL,7);
INSERT INTO DKA_PARAMETERS (PROGRAM_CODE,PARAMETER_NAME,DESCRIPTION,DATA_TYPE,VARCHAR2_VALUE,NUMBER_VALUE) VALUES ('SPORES_CONTRAT','SMTP_CONNECTION','Connection SMTP','VARCHAR2','smtp.dalkia.net',NULL);
INSERT INTO DKA_PARAMETERS (PROGRAM_CODE,PARAMETER_NAME,DESCRIPTION,DATA_TYPE,VARCHAR2_VALUE,NUMBER_VALUE) VALUES ('SPORES_CONTRAT','EXPEDITEUR_MAIL','Expediteur du mail automatique','VARCHAR2','<no-reply@dalkia.fr>',NULL);

COMMIT;

EXIT;

