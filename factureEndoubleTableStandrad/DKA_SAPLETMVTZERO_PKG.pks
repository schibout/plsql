CREATE OR REPLACE PACKAGE DKA_SGLEQUILIB_PKG
AS
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI 
-- PROJET            : DALKIA Oracle Applications
-- NOM		         : DKA_SGLEQUILIB_PKG.pks
-- DESCRIPTION	     : EQUILIBRE COMPTABLE PAR CENTRE DE GESTION
--
--- AUTEUR	     : Samira LARDJOUNE (Cap gemini)
--- DATE DE CREATION : 23/06/2005
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
--  21/07/2009  SL  Adaptation des différentes fonctions/procédures pour prendre en compte l'éclatement du lot
--                  d'equilibre par centre de gestion en plusieurs lots (un par société segmentée)

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---------------------------------------------------------------------------------------------------------------
--  Nom           : Init
--  Description   : Procédure d'initialisation, Récupération des paramètres
--
--  PARAMETRES :
--  pn_period                 Entree             Nom de la période
--  pv_errbuf                 Entree/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A

--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
 Procedure  Init
            (pn_period            IN  VARCHAR2,
             pv_errbuf            IN OUT   VARCHAR2,
             pn_retcode           IN OUT   NUMBER
            );

---------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_REQUEST
--  Description   : Procédure lançant la génération des pièces répétitives
--
--  pv_errbuf                 Entree/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
 Procedure  launch_request
            (
            pv_errbuf    IN OUT   VARCHAR2,
            pv_retcode   OUT   NUMBER
            ) ;


---------------------------------------------------------------------------------------------------------------
--  Nom           : wait_GLPRJE
--  Description   : Attente de la fin d'execution du traitement GLPRJE soumis
--
--  PARAMETRES    :
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  PROCEDURE wait_GLPRJE
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );


--------------------------------------------------------------------------------------------------------------
--  Nom           : wait_GLPAUTOP
--  Description   : Attente de la fin d'execution du traitement GLPAUTOP soumis
--
--  PARAMETRES    :
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  PROCEDURE wait_GLPAUTOP
   (
    pv_errbuf    IN OUT   VARCHAR2,
    pn_retcode   IN OUT   NUMBER
    );

    
--------------------------------------------------------------------------------------------------------------
--  Nom           : wait_GLPOS
--  Description   : Attente de la fin d'execution du traitement GLPOS soumis
--
--  PARAMETRES    :
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

      PROCEDURE wait_GLPOS
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );
    
---------------------------------------------------------------------------------------------------------------
--  Nom           : delete_batch
--  Description   : Procédure supprimant un lot
--
--  pv_je_batch_id            Entrée             Identifiant du lot à supprimer
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
Procedure delete_batch ( pv_je_batch_id IN NUMBER,
                         pv_errbuf      IN OUT   VARCHAR2,
                         pn_retcode     IN OUT   NUMBER
                         );


---------------------------------------------------------------------------------------------------------------
--  Nom           : delete_header
--  Description   : Procédure de suppression d'une pièce
--
--  pv_je_header_id           Entrée             Identifiant de la pièce à supprimer
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
 Procedure delete_header (pv_je_header_id IN NUMBER,
                          pv_errbuf    IN OUT   VARCHAR2,
                          pn_retcode     IN OUT   NUMBER);


---------------------------------------------------------------------------------------------------------------
--  Nom           : delete_lines
--  Description   : Procédure de suppression d'une écriture
--
--  pv_je_header_id           Entrée             Identifiant de la pièce pour laquelle une écriture
--                                               doit être supprimée
--  pv_je_line_num            Entrée             Numéro de la ligne à supprimer
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
  Procedure delete_lines (pv_je_header_id IN NUMBER,
                          pv_je_line_num  IN NUMBER,
                          pv_errbuf    IN OUT   VARCHAR2,
                          pn_retcode     IN OUT   NUMBER);

---------------------------------------------------------------------------------------------------------------
--  Nom           : check_data
--  Description   : Procédure de vérification des pièces et des écritures
--
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  Procedure check_data (pv_errbuf    IN OUT   VARCHAR2, pn_retcode OUT NUMBER);

---------------------------------------------------------------------------------------------------------------
--  Nom           : run_posting
--  Description   : Procédure de lancement du programme d'imputation automatique
--
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  Procedure run_posting (pv_errbuf    IN OUT   VARCHAR2, Pv_Retcode OUT NUMBER);


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_first_char
--  Description   : Fonction pour chercher la premiere lettre en fonction du code societé
--  
--  AUTEUR     : RBE
--  PARAMETRES :
--  VALEUR RETOURNEE : Caractere trouvé
---------------------------------------------------------------------------------------------------------------
   FUNCTION get_first_char
 RETURN VARCHAR2;
  
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur
--                  pn_retcode             	Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--		    		pn_period	   			Entrée
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE main(pv_errbuf        	IN OUT VARCHAR2,
               pn_retcode           	OUT NUMBER,
               pn_period		       IN VARCHAR2
               )
;


end DKA_SGLEQUILIB_PKG;
/
SHOW ERROR
EXIT;
