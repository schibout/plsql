create or replace package DKA_SPE037_ACC_GEN_FA_PKG is
  ----------------------------------------------------------------------------------------------
  -- NOM               : DKA_SPE037_ACC_GEN_FA_PKG.pks
  -- DESCRIPTION       : DKA_SPE037_ACC_GEN_FA_PKG spec : composant wf account generator FA
  ---
  --- AUTEUR           : NBOUSSEKEYT
  --- DATE DE CREATION : 05/10/2016
  --- DOC. ASSOCIEE    :
  ---
  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --  05/10/2016 NBO Création
  --------------------------------------------------------------------------------------------
  -----------------------------------------------------------------
  --  Variables globales
  -----------------------------------------------------------------

  -------------------------------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : Procedure d'initialisation des item_attributes
  --
  --  PARAMETRES    :
  --     itemtype                 Entree          Identifiant du workflow
  --     itemkey                  Entree          Identifiant du process en cours d'execution
  --     actid                    Entree          Id de l'activite du process ayant appele cette procedure
  --     funcmode                 Entree          Mode de fonctionnement du workflow : doit être à 'RUN'
  --     result                   Sortie          Valeur retournee à l'activite du process : 'SUCCESS' ou 'FAILURE'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ------------------------------------------------------------------------------------
  PROCEDURE init(itemtype IN VARCHAR2,
                 itemkey  IN VARCHAR2,
                 actid    IN NUMBER,
                 funcmode IN VARCHAR2,
                 result   OUT VARCHAR2);

end DKA_SPE037_ACC_GEN_FA_PKG;
/
SHOW ERRORS
EXIT;