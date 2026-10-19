CREATE OR REPLACE TRIGGER DKA_FND_RESTRICTED_USER_BU
------------------------------------------------------------------------
-- $Id: DKA_FND_RESTRICTED_USER_BU.trg$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_FND_USER_RESTREINT_BU.trg
-- DESCRIPTION       : Trigger sur la table FND_USER
--- AUTEUR           : Julien Jardez (Capgemini)
--- DATE DE CREATION : 13/04/2018
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------
-- 2018/04/13 JJA Création
------------------------------------------------------------------------
BEFORE UPDATE
ON applsys.FND_USER
FOR EACH ROW
WHEN (    NEW.user_id >= 1000
      AND (   NEW.last_logon_date <> OLD.last_logon_date
           OR (    OLD.last_logon_date IS NULL
               AND NEW.last_logon_date IS NOT NULL
              )
          )
     )
DECLARE
    e_flag_tp       EXCEPTION;
    
    vn_tp_ouvert    INTEGER; --(1 = ouvert, 0 = fermé)
    vv_autorisation VARCHAR2(20);
    
BEGIN
    BEGIN
    
      SELECT number_value
      INTO vn_tp_ouvert
      FROM dka_parameters
      WHERE
      program_code = 'SFND_CLOSE_TP'
      AND parameter_name = 'TP';
      
    EXCEPTION
     WHEN OTHERS THEN
      vn_tp_ouvert := 0;
    END;
    
    IF vn_tp_ouvert = 0 THEN
      
      SELECT 'TP_RESTREINT'
        INTO vv_autorisation
        FROM ak_web_user_sec_attr_values
       WHERE web_user_id    = :NEW.user_id
         AND attribute_code = 'DKA_UTILISATEUR_TP_RESTREINT'
         AND VARCHAR2_VALUE = 'Y';
             
    ELSIF nvl(vn_tp_ouvert,-1) != 1 THEN
    
      raise e_flag_tp; 
    
    END IF;
        
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error (-20000, 'TP Fermé : Connexion interdite');
    WHEN e_flag_tp THEN
        raise_application_error (-20000, 'Flag TP incohérent : Connexion interdite');
END;
/

SHOW ERRORS TRIGGER DKA_FND_RESTRICTED_USER_BU
EXIT
