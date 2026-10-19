SET VERIFY OFF;
DEFINE package_name = "DKA_SPOWFAG_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOWFAG_PKG.pkb
-- DESCRIPTION	     : spécification du package pour les workflows de génération de comptes PO
--
-- AUTEUR            : Evelyne SIMON
-- DATE DE CREATION  : 11/02/2002
-- DOC. ASSOCIEE     : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 21/07/2016 MEG Migration R12
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PROCEDURE get_po_cp_segment5_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


PROCEDURE get_po_cp_segment3_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);
									  
									  
-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT1_VALUE
--  Description   : Procédure de détermination de la valeur du segment1 du compte Expense Charge Account:
--                  SOCIETE
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
PROCEDURE get_po_eca_segment1_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT2_VALUE
--  Description   : Procédure de détermination de la valeur du segment2 :
--                  UO
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
PROCEDURE get_po_eca_segment2_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT3_VALUE
--  Description   : Procédure de détermination de la valeur du segment3 :
--                  COMPTE_LOCAL
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
PROCEDURE get_po_eca_segment3_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT4_VALUE
--  Description   : Procédure de détermination de la valeur du segment4
--                  COMPTE_ANALYTIQUE
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
PROCEDURE get_po_eca_segment4_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT5_VALUE
--  Description   : Procédure de détermination de la valeur du segment5
--                  INTERCO
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
PROCEDURE get_po_eca_segment5_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT6_VALUE
--  Description   : Procédure de détermination de la valeur du segment5
--                  CENTRE_FI
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
PROCEDURE get_po_eca_segment6_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT7_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--                  AFFAIRE
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
PROCEDURE get_po_eca_segment7_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT8_VALUE
--  Description   : Procédure de détermination de la valeur du segment8
--                  PROJET_FI
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
PROCEDURE get_po_eca_segment8_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT9_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--                  FLUX
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
PROCEDURE get_po_eca_segment9_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT10_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--                  RESERVE1
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
PROCEDURE get_po_eca_segment10_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT11_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--                  RESERVE2
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
PROCEDURE get_po_eca_segment11_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);


-------------------------------------------------------------------------------------
--  Nom           : GET_PO_ECA_SEGMENT12_VALUE
--  Description   : Procédure de détermination de la valeur du segment7
--                  RESERVE3
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
PROCEDURE get_po_eca_segment12_value ( itemtype        IN  VARCHAR2,
                                      itemkey         IN  VARCHAR2,
                                      actid           IN  NUMBER,
                                      funcmode        IN  VARCHAR2,
                                      result          OUT VARCHAR2);

-------------------------------------------------------------------------------------
--  Nom           : IS_PO_PROJECT_RELATED
--  Description   : Procédure retournant vrai si la génération du compte se fait sur projet
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
PROCEDURE is_po_project_related ( itemtype        IN  VARCHAR2,
                                  itemkey         IN  VARCHAR2,
                                  actid           IN  NUMBER,
                                  funcmode        IN  VARCHAR2,
                                  result          OUT VARCHAR2);

-------------------------------------------------------------------------------------
--  Nom           : IS_PROJECT_TYPE_INVEST
--  Description   : Procédure retournant vrai si le type de projet est Investissement
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
PROCEDURE is_project_type_invest(itemtype IN VARCHAR2,
                                 itemkey  IN VARCHAR2,
                                 actid    IN NUMBER,
                                 funcmode IN VARCHAR2,
                                 result   OUT NOCOPY VARCHAR2);

END &&package_name; -- spécification du package
/
SHOW ERRORS;

EXIT
