CREATE OR REPLACE PACKAGE DKA_REPAPDESAC_PKG AS
  --------------------------------------------------------------------------------
  -- Nom du fichier : DKA_REPAPDESAC_PKG.pks                                            
  -- Version        : 1.0                                                               
  -- Auteur         : Maxime EGOT / SOCIETE : CAPGEMINI                                 
  -- Date           : 03/05/2017                                                        
  --------------------------------------------------------------------------------
  -- Traitement     : DKA : desactivation des sites fournisseur / POST-REPRISE                    
  --                                                                             
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 
  --------------------------------------------------------------------------------

  PROCEDURE MAIN(p_errbuf IN OUT VARCHAR2, 
                 p_retcode IN OUT NUMBER, 
                 p_simulation VARCHAR2);

END DKA_REPAPDESAC_PKG;
/
SHOW ERRORS PACKAGE DKA_REPAPFRSIMP_PKG;
EXIT
