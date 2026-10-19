CREATE OR REPLACE PACKAGE DKA_FUSION_AP_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM         : DKA_FUSION_AP_PKG.pks
  -- DESCRIPTION       : DKA_FUSION_AP_PKG package spec :
  ---
  --- AUTEUR       : O.CLEMENT
  --- DATE DE CREATION : 09/2019
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---------------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Extract
  --  Description   : procédure principale d'extraction des donnees
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Extract(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         Pv_Debug   IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Ctr
  --  Description   : procédure principale du controle
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Ctr(pv_errbuf  IN OUT VARCHAR2,
                     pn_retcode OUT NUMBER,
                     Pv_Debug   IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Insert
  --  Description   : procédure principale de l'insertion dans les tables standard d'interface
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Insert(pv_errbuf  IN OUT VARCHAR2,
                        pn_retcode OUT NUMBER,
                        Pv_Debug   IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Post_Fusion
  --  Description   : procédure principale post-fusion
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Post_Fusion(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER,
                             Pv_Debug   IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Hold_No_Cent
  --  Description   : procédure principale d'insertion des code blocages
  --                  n'autorisant pas la centralisation
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Hold_No_Cent(pv_errbuf  IN OUT VARCHAR2,
                              pn_retcode OUT NUMBER,
                              Pv_Debug   IN VARCHAR2);
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Rattchmt_Images
  --  Description   : procédure de rattachement des images sur les factures
  --                  créées sur la société absorbante
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Rattchmt_Images(pv_errbuf     IN OUT VARCHAR2,
                                 pn_retcode    OUT NUMBER,
                                 Pv_Simulation IN VARCHAR2,
                                 Pv_Debug      IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Annul_workflow
  --  Description   : procédure d'annulation des workflow sur société absorbée
  --                  créées sur la société absorbante
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Annul_workflow(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER,
                                Pv_Debug   IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Let_Rec
  --  Description   : procédure principale de recensement des mouvements à lettrer
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Let_Rec(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         Pv_Debug   IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Let_Maj
  --  Description   : procédure principale de mise à jour des mouvements à lettrer
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Let_Maj(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         Pv_Debug   IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main_Let_Mvt
  --  Description   : procédure principale d'affichage des mouvements non pris en compte et affectation blocage
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main_Let_Mvt(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         Pv_Debug   IN VARCHAR2);

end DKA_FUSION_AP_PKG;

/
SHOW ERROR
EXIT;