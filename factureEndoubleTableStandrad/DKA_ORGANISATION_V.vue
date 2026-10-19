CREATE OR REPLACE TRIGGER DKA_AP_INVOICES_INTERFACE_BUD
   BEFORE
   UPDATE or DELETE
   ON ap.ap_invoices_interface
   FOR EACH ROW
----------------------------------------------------------------------------------------------
-- $Id: DKA_AP_INVOICES_INTERFACE_BUD.trg$
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_INVOICES_INTERFACE_BUD.trg
-- DESCRIPTION       : Trigger sur la table AP_INVOICES_INTERFACE
---
--- AUTEUR           : Dominique Marchand (CGEY)
--- DATE DE CREATION : 18/09/2008
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 2016/09/02 JJA Portage Helios R12
--------------------------------------------------------------------------------------------

DECLARE

vn_count number;
BEGIN
    
  IF DELETING THEN
   
    IF :old.status = 'PROCESSED'  THEN
        
        select count(1) into  vn_count
        from DKA_IAPFACXGS_REPORTING_ALL
        where REFERENCE_lad=  :old.attribute3
        and STATUT_OI is null;
  
        IF vn_count= 1 THEN
            update DKA_IAPFACXGS_REPORTING_ALL
            set STATUT_OI = 'INTEGRE AP',
                USER_ID_OI = fnd_global.USER_NAME , --nvl( fnd_global.USER_NAME, 'EXPLOITATION'),
                LAST_UPDATE_DATE_OI = sysdate
            where
                REFERENCE_lad=  :old.attribute3
                and STATUT_OI is null;
        ELSIF vn_count> 1 THEN
            update DKA_IAPFACXGS_REPORTING_ALL
            set STATUT_OI = 'DOUBLONS',
                USER_ID_OI = fnd_global.USER_NAME ,
                LAST_UPDATE_DATE_OI = sysdate
            where
                REFERENCE_lad=  :old.attribute3
                and STATUT_OI is null;
        END IF;
    END IF;
   
    IF nvl(:old.status,'P') != 'PROCESSED' and :old.source ='SCAN_XGS' THEN
        --evol M11bis
        select count(1) into  vn_count
        from DKA_IAPFACXGS_REPORTING_ALL
        where REFERENCE_lad=  :old.attribute3
        and STATUT_OI is null;
  
        IF vn_count= 1 THEN
            update DKA_IAPFACXGS_REPORTING_ALL
            set STATUT_OI = 'SUPPRIME',
                USER_ID_OI =  fnd_global.USER_NAME,
                LAST_UPDATE_DATE_OI = sysdate
            where
                    REFERENCE_lad=  :old.attribute3
                    and STATUT_OI is null;
        ELSIF vn_count> 1 THEN
            update DKA_IAPFACXGS_REPORTING_ALL
            set STATUT_OI = 'DOUBLONS',
                USER_ID_OI = fnd_global.USER_NAME , 
                LAST_UPDATE_DATE_OI = sysdate
            where
                REFERENCE_lad=  :old.attribute3
                and STATUT_OI is null;
        END IF;
    END IF;
  
  END IF; --DELETING
     
END;
/
SHOW ERRORS
EXIT;
