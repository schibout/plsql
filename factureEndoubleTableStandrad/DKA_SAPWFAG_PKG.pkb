CREATE OR REPLACE TRIGGER DKA_AR_ADJUSTMENTS_ALL_BRU
----------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AR_ADJUSTMENTS_ALL_BRU.trg
-- DESCRIPTION       : Trigger sur la table AR_ADJUSTMENTS_ALL
---
--- AUTEUR           : Grégory Vanackere (Capgemini)
--- DATE DE CREATION : 01/03/2005
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
--- 2016/07/26 JJA Migration Helios R12
----------------------------------------------------------------------------------------------
BEFORE UPDATE
    ON ar.ar_adjustments_all
    FOR EACH ROW
    
when (OLD.ATTRIBUTE11 IS NOT NULL OR OLD.ATTRIBUTE13 IS NOT NULL OR OLD.ATTRIBUTE14 IS NOT NULL)
DECLARE            
       
BEGIN
     -- Conserver les attribute11 , attribute13 et attribute14
     :NEW.ATTRIBUTE11 := :OLD.ATTRIBUTE11;
     :NEW.ATTRIBUTE13 := :OLD.ATTRIBUTE13;
     :NEW.ATTRIBUTE14 := :OLD.ATTRIBUTE14;
     
EXCEPTION
    WHEN OTHERS THEN
        app_exception.raise_exception;
END DKA_AR_ADJUSTMENTS_ALL_BRU;
/
SHOW ERROR
EXIT