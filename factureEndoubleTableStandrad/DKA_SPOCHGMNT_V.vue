CREATE OR REPLACE PACKAGE DKA_SARRGLTPRLV_CREATE_AUT_PKG AS

  ---------------------------------------------------------------------------------------------------------------
  -- NOM               : DKA_SARRGLTPRLV_CREATE_AUT_PKG.pks
  -- DESCRIPTION       : Lancement du traitement de creation des lots de réglement AR
  ---
  --- AUTEUR           : Asma AMENKOUR
  --- DATE DE CREATION : 01/10/2019
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------------------------
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --  01/10/2019   AAM Creation

  ---------------------------------------------------------------------------------------------------------------
  TYPE myrecord IS RECORD(
    request_id NUMBER);

  TYPE mytable IS TABLE OF myrecord INDEX BY BINARY_INTEGER;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER,
                 P_DATE     IN VARCHAR2
                 
                 );
  ---------------------------------------------------------------------------------------------------------------
END DKA_SARRGLTPRLV_CREATE_AUT_PKG;
/
SHOW ERROR
EXIT;
