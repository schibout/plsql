CREATE OR REPLACE PACKAGE DKA_AR_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_AR_TOOLS_PKG.pks
-- DESCRIPTION       : DKA_AR_TOOLS_PKG package spec : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  11/08/2017 NBO artf2211142 - Fonction commune de détermination d'un compte de surtaxe
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
  gv_debug_mode        VARCHAR2 (1);

---------------------------------------------------------------------------------------
--  Nom           : get_customer_partner
--  Description   : Procédure permettant d'obtenir les identifiants du client, addresse client,
--                  et lieu de facturation correspondant a la société passée en parametre
--                  et définis dans le centre de gestion et l'organisation passés en entrée
--
--  PARAMETRES :
--          pv_orgname              Entrée
--          pn_org_id               Entrée
--          pn_customer_id                 Sortie
--          pv_customer_number             Sortie
--          pn_customer_site_id            Sortie
--          pn_bill_to_site_use_id         Sortie
--          pv_interco                     Sortie
--          pv_errbuf              Entrée  Sortie
--          pn_retcode                     Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
  PROCEDURE get_customer_partner (
      pv_orgname               IN       VARCHAR2,
      pn_org_id                IN       NUMBER,
      pn_customer_id              OUT   NUMBER,
      pv_customer_number          OUT   VARCHAR2,
      pn_customer_site_id         OUT   NUMBER,
      pn_bill_to_site_use_id      OUT   NUMBER,
      pv_interco                  OUT   VARCHAR2,
      pv_errbuf                IN OUT   VARCHAR2,
      pn_retcode                  OUT   NUMBER
  );
    
---------------------------------------------------------------------------------------------------------------
  --  Nom           : alim_corresp_operations
  --  Description   :  procédure alimentant l'ecran Configuration /type de pieces 
  --                       dans resp DKA RB RESPONSABLE RAPPROCHEMENT
  --
  --  PARAMETRES    :
  --                     pv_type_operation  EFFETS ou PRELEVEMENT
  --
  --  VALEUR RETOURNEE :
  --     Description       : pn_retcode  
  --     Valeurs possibles :      0 succes, 1 erreur
---------------------------------------------------------------------------------------------------------------
  PROCEDURE alim_corresp_operations (pv_type_operation IN VARCHAR2,
                                     pn_retcode        OUT number,
                                     pv_err_buffer     OUT varchar2);

--  11/08/2017 NBO artf2211142 - Fonction commune de détermination d'un compte de surtaxe
  ----------------------------------------------------------------------------
  --  Nom           : isSurtaxeAccount
  --  Description   : Valide si un compte local est de type surtaxe
  -- PARAMETRES     :
  --  pv_localaccount    Compte local à valider
  --
  -- VALEUR RETOURNEE :
  --  VARCHAR2    TRUE Si il est de type local. 
  ----------------------------------------------------------------------------
  FUNCTION issurtaxeaccount(pv_localaccount fnd_flex_values.flex_value%TYPE) RETURN VARCHAR2;
                                     
END DKA_AR_TOOLS_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;
