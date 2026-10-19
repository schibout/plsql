CREATE OR REPLACE PACKAGE DKA_SARRGLTPRLV_AUTO_PKG
IS

---------------------------------------------------------------------------------------------------------------
--- NOM               : DKA_SARRGLTPRLV_AUTO_PKG.pks
--- DESCRIPTION       : Automatisation des prelevements clients
---
--- AUTEUR            : Sara CHARKAOUI
--- DATE DE CREATION  : 26/09/2019
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Date         Qui  Description
--- ----------   ---  --------------------------------------------------------------------------------------------
--- 26/09/2019   SCH  Creation

---------------------------------------------------------------------------------------------------------------


/*==========================================================================
-- Procedure         : MAIN1
-- Description       : LANCEMENT de l'etat ETA121
-- Parametres entree : P_DATE    IN DATE       : une date d'echeance
--                   : P_REGION  IN VARCHAR2   : une REGION
-- Parametres sortie : AUCUN
-- Remarques         :
--==========================================================================*/


PROCEDURE MAIN1( pv_errbuf    IN OUT   VARCHAR2,
           pn_retcode      OUT   NUMBER,
           P_DATE     IN     VARCHAR2,
           P_REGION     IN       VARCHAR2
           ) ;

/*==========================================================================
-- Procedure         : MAIN2
-- Description       : LANCEMENT de l'etat ETA122
-- Parametres entree : P_DATE    IN DATE       : une date d'echeance
--                   : P_REGION  IN VARCHAR2   : une REGION
-- Parametres sortie : AUCUN
-- Remarques         :
--==========================================================================*/

PROCEDURE MAIN2( pv_errbuf    IN OUT   VARCHAR2,
           pn_retcode      OUT   NUMBER,
           P_DATE     IN     VARCHAR2,
           P_REGION     IN       VARCHAR2
           ) ;

/*==========================================================================
-- Procedure         : MAIN3
-- Description       : LANCEMENT de l'etat ETA123
-- Parametres entree : P_DATE    IN DATE       : une date d'echeance
--                   : P_REGION  IN VARCHAR2   : une REGION
-- Parametres sortie : AUCUN
-- Remarques         :
--==========================================================================*/

PROCEDURE MAIN3( pv_errbuf    IN OUT   VARCHAR2,
           pn_retcode      OUT   NUMBER,
           P_DATE     IN     VARCHAR2,
           P_REGION     IN       VARCHAR2
           ) ;
/*================================================================================================================
-- Procedure         : ENVOI_MAIL
-- Description       : Procedure principale du traitement "DKA : Envoi des etats pour le prelevement automatique"
-- Parametres entree : P_Req_Id    IN NUMBER : le numero de traitement
--               Pv_Errbuf   IN OUT    : Message d'avertissement
--             Pn_Retcode  IN OUT    : Code erreur
--             P_Region    IN        : REGION
--             P_Date      IN        : date echeance
--
-- Parametres sortie : AUCUN
-- Remarques         :
--================================================================================================================*/

PROCEDURE ENVOI_MAIL(Pv_Errbuf  IN OUT  VARCHAR2,
           Pn_Retcode IN OUT  NUMBER,
           P_Req_Id   IN    NUMBER,
           P_Region   IN    VARCHAR2,
           P_Date   IN    VARCHAR2
             );

END DKA_SARRGLTPRLV_AUTO_PKG;
/
SHOW ERRORS
EXIT
