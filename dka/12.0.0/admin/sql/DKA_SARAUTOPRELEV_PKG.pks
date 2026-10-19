CREATE OR REPLACE PACKAGE APPS.DKA_SARAUTOPRELEV_PKG IS
  ----------------------------------------------------------------------------------------------
  -- $Id: DKA_SARAUTOPRELEV_PKG.pks 63 2008-09-18 15:34:04Z viknab $
  --
  -- NOM               : DKA_SARAUTOPRELEV_PKG.pks
  -- DESCRIPTION       : 
  ---
  --- AUTEUR           : C. Trochu (Capgemini)
  --- DATE DE CREATION : 10/07/2008
  --- DOC. ASSOCIEE    : Spécifications fonctionnelles (0SPF20080090_NEXT - Remise en banque des prélèvements clients.doc)
  ---                    Spécifications techniques (PDO-MD070-003-V1.00-FR-DNX-Remise en banque des prélèvements clients.doc)
  ---                    
  ----------------------------------------------------------------------------------------------------
  -- Variables globales  
  -- Modif GV20090324 : ajout des 3 variables globales ci-dessous
  TYPE dka_typ_trt IS RECORD(
    request_id   NUMBER,
    printer_name VARCHAR2(50));
  TYPE dka_tab_trt IS TABLE OF dka_typ_trt INDEX BY BINARY_INTEGER;
  gd_remit_date DATE;

  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  -- 12/07/2013 JJA DGE20130023 :Evolution F56 Bis Avennat au format DD IMPORT 
  -- 01/07/2024 ARA EDB379 - MISE EN PLACE DES PRELEVEMENTS EXPRESS
  -------------------------------------------------------------------------------------------- 

  -----------------------------------------------------------------
  --  Nom           : create_seq_prlv_ar
  --  Description   : Creation des sequences de prelevements AR
  --
  --  PARAMETRES :
  --     pv_user_name       Sortie  --> Varchar2
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------  
/*  PROCEDURE create_seq_prlv_ar(pn_retcode IN OUT NOCOPY NUMBER,
                               pv_errbuf  IN OUT NOCOPY VARCHAR2);*/

  -----------------------------------------------------------------
  --  Nom           : INSERT_PRELEV  
  --  Description   : Procédure permettant de creer les fichiers bancaires pour les effets de commerce
  --
  --  PARAMETRES :
  --     pv_errbuf       Sortie  --> Varchar2
  --     pn_retcode      Sortie  --> Number
  --     pn_batch_id     Entrée  --> Varchar2 
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  PROCEDURE INSERT_PRELEV(pv_errbuf   IN OUT NOCOPY VARCHAR2,
                          pn_retcode  IN OUT NOCOPY NUMBER,
                          pv_batch_id IN VARCHAR2);
						  
						  
  --ARA EDB379
  PROCEDURE INSERT_PRELEV_EXP(pv_errbuf   IN OUT NOCOPY VARCHAR2,
                          pn_retcode  IN OUT NOCOPY NUMBER,
                          pv_batch_id IN VARCHAR2);

  -----------------------------------------------------------------
  --  Nom           : CREATE_DDIMPORT  
  --  Description   : Procédure permettant de créer les fichiers au
  --                  format DDIMPORT envoyés à la banque pour 
  --                  effectuer les virements ou prélèvements
  --
  --  PARAMETRES :
  --     pv_errbuf       Sortie  --> Varchar2
  --     pn_retcode      Sortie  --> Number
  --     pv_date         Entrée  --> Varchar2
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  PROCEDURE CREATE_DDIMPORT(pv_errbuf  IN OUT NOCOPY VARCHAR2,
                            pn_retcode IN OUT NOCOPY NUMBER,
                            pv_date    IN VARCHAR2);

  -----------------------------------------------------------------
  --  Nom           : MAIN 
  --  Description   : Procédure appelee par le traitement 
  --                  DKA : Règlements automatiques effet de commerce des factures clients
  --
  --  PARAMETRES :
  --     pv_errbuf       Sortie  --> Varchar2
  --     pn_retcode      Sortie  --> Number
  --
  --  VALEUR RETOURNEE :
  --
  -----------------------------------------------------------------
  PROCEDURE MAIN(pv_errbuf        IN OUT NOCOPY VARCHAR2,
                 pn_retcode       IN OUT NOCOPY NUMBER,
                 pv_date_echeance IN VARCHAR2);

END DKA_SARAUTOPRELEV_PKG;
/
SHOW ERRORS
EXIT