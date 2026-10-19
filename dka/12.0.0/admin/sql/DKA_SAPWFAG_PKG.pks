SET VERIFY OFF;
DEFINE package_name = "DKA_SAPWFAG_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPWFAG_PKG.pks
-- DESCRIPTION       : DKA_SAPWFAG_PKG package spec :
---
--- AUTEUR           : Evelyne SIMON (CGEY)
--- DATE DE CREATION : 24/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 12/07/04   SLE Portage spécifique pour projet PHENIX 2004
---		       Ajout d'une procédure GET_AP_SEGMENT7_VALUE
--- 07/07/16   MEG Migration R12
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT1_VALUE
--  Description   : Procédure de détermination de la valeur du segment1
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment1_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT2_VALUE
--  Description   : Procédure de détermination de la valeur du segment2
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment2_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT3_VALUE
--  Description   : Procédure de détermination de la valeur du segment3 :
--                  COMPTE LOCAL
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment3_value(itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                result   OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT4_VALUE
--  Description   : Procédure de détermination de la valeur du segment4
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment4_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT5_VALUE
--  Description   : Procédure de détermination de la valeur du segment5
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment5_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT6_VALUE
--  Description   : Procédure de détermination de la valeur du segment5
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment6_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);

-- PHENIX 2004
-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT7_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment7_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);
-- PHENIX 2004

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT8_VALUE
--  Description   : Procédure de détermination de la valeur du segment8
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment8_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT9_VALUE
--  Description   : Procédure de détermination de la valeur du segment9
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment9_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT10_VALUE
--  Description   : Procédure de détermination de la valeur du segment10
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment10_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);
                                  
-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT11_VALUE
--  Description   : Procédure de détermination de la valeur du segment11
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment11_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);

-------------------------------------------------------------------------------------
--  Nom           : GET_AP_SEGMENT12_VALUE
--  Description   : Procédure de détermination de la valeur du segment12
--
--  PARAMETRES    :
--     itemtype                 Entrée          Identifiant du workflow
--     itemkey                  Entrée          Identifiant du process en cours d'exécution
--     actid                    Entrée          Id de l'activité du process ayant appelé cette procédure
--     funcmode                 Entrée          Mode de fonctionnement du workflow : doit être à 'RUN'
--     result                   Sortie          Valeur retournée à l'activité du process : 'SUCCESS' ou 'FAILURE'
--  
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
------------------------------------------------------------------------------------                       
PROCEDURE get_ap_segment12_value ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);

END &&package_name; -- Spécification du package
/
SHOW ERRORS;

EXIT
