CREATE OR REPLACE PACKAGE DKA_SFAACCPB_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SFAACCPB_PKG
  -- DESCRIPTION       : Traitement de la cloture des périodes FA _ Création de pièces comptables (Lancement de DKA_SFAACCPB_PKG)
  ---
  --- AUTEUR           :Roshanak GHARAGOZLOU
  --- DATE DE CREATION : 04/10/2016
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 29/11/16   NBO Ajout du parametre SOB
  ---------------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure qui enchaine le reste des procedures
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER, pn_sob IN NUMBER);
  ---------------------------------------------------------------------------------------------------------------
END DKA_SFAACCPB_PKG; -- Spécification du package


/
SHOW ERRORS
EXIT