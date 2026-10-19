CREATE OR REPLACE PACKAGE DKA_SFABUDGET_PKG
AS
---------------------------------------------------------------------------------------------- 
-- $$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFABUDGET_PKG.pkb
-- DESCRIPTION	   : package body pour l'interface Fa Budget
--
-- AUTEUR            : E. Flass
-- DATE DE CREATION  : 18/06/2004
-- DOC. ASSOCIEE     : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  22/05/2007 SL  Modification main - ajout d'un paramètre : date de référence
-- Fonctions pour la suppression des donnees du traitement precedent
--- ---------- --- -------------------------------------------------------------------------
---- 02/08/2019  SELO SFD : SPE073 - Interface FA - Budget-1-SFD.doc
----------------------------------------------------------------------------------------------------
--  Nom           : DKA_DEL_SFABUDGET_WORK
--  Description   : Procedure de suppression des donnees de l'ancien traitement
--
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_DEL_SFABUDGET_WORK (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT      NUMBER
    );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_BOOK_PERIODS_CTR
--  Description   : Procedure de pre-controle pour un livre
--                  Y a t il 12 periodes definies dans le calendrier
--                  pour la prochaine annee civile (01/01 au 31/12) ?
--
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pv_Book_Type_Code         Entree             Code du livre
-- Pv_Calendar_Type          Entree             Type de calendrier associe au livre en parametre
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_BOOK_PERIODS_CTR (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT      NUMBER,
        Pv_Book_Type_Code IN  VARCHAR2,
        Pv_Calendar_Type  IN  VARCHAR2
    );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_BOOK_MAIN_CTR
--  Description   : Procedure de pre-controle d'un livre
--
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pv_Book_Type_Code         Entree             Code du livre
-- Pv_Calendar_Type          Entree             Type de calendrier associe au livre en parametre
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_BOOK_MAIN_CTR (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        Pv_Book_Type_Code IN  VARCHAR2,
        Pv_Calendar_Type  IN  VARCHAR2
    );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_MAIN_CTR
--  Description   : Procédure principale de pre-controle 
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_MAIN_CTR (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );

-- Fonctions pour la soumission du programme de generation des cles (FAGDA)
----------------------------------------------------------------------------------------------------
--  Nom           : DKA_WAIT_FAGDA
--  Description   : Attente de la fin d'execution de l'ensemble des programmes FAGDA soumis
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_WAIT_FAGDA
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_SUBMIT_FAGDA
--  Description   : Soumission du programme de generation des cles de dotation pour le livre passe 
--                  en parametre
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pv_Book_Type_Code         Entree             Livre
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_SUBMIT_FAGDA
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER, 
        Pv_Book_Type_Code IN  VARCHAR2
        );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_CTR_ALL_CCID
--  Description   : Controle que l 'ensemble des cle de dotations ont ete generees pour un livre 
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pv_Book_Type_Code         Entree             Livre
-- Pb_exists                 Sortie             Au moins une cle n'a pas ete generee
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_CTR_ALL_CCID
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER, 
        Pv_Book_Type_Code IN  VARCHAR2,
        Pb_Exists    OUT      BOOLEAN
        );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_MAIN_FAGDA
--  Description   : Soumission du programme de generation des cles
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- pv_book_type_Code         Entree             Code du livre
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_MAIN_FAGDA (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );

-- Fonctions pour la soumission du programme de previsions d'amortissement (FAPROJ)
----------------------------------------------------------------------------------------------------
--  Nom           : DKA_WAIT_FAPROJ
--  Description   : Attente de la fin d'execution de l'ensemble des programmes FAPROJ soumis
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_WAIT_FAPROJ
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_SUBMIT_FAPROJ
--  Description   : Soumission du programme de generation des cles de dotation pour le livre/Caleendrier 
--                  passe en parametre
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pv_Book_Type_Code         Entree             Livre
-- Pv_Calendar_Type          Entree             Type de calendrier associe au livre en parametre
-- Pv_First_Period           Entre              Premiere periode
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_SUBMIT_FAPROJ
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER, 
        Pv_Book_Type_Code IN  VARCHAR2,
        Pv_Calendar_Type IN   VARCHAR2,
        Pv_First_Period  IN   VARCHAR2,
        Pv_Nb_Periode    IN   NUMBER
        );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_FIRST_PERIODE
--  Description   : Premiere periode de l'annee civile N+1 
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- pv_Calendar_Type          Entree             Code du calendrier
-- pv_Period_Name            Sortie             Nom de la periode
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_FIRST_PERIODE (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        Pv_Calendar_Type IN   VARCHAR2,
        Pv_Period_Name   OUT  VARCHAR2
        );
        
--------------------------------------------------------------------------------------------------------
--  Nom           : DKA_FIRST_PERIODE_NEW
--  Description   : Premiere periode de l'annee civile N+1 
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- pv_Calendar_Type          Entree             Code du calendrier
-- pv_Period_Name            Sortie             Nom de la periode
-- Pv_Nb_period              Sortie             Nombre de prévision pour le prévisionnel
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_FIRST_PERIODE_NEW (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        Pv_Calendar_Type IN   VARCHAR2,
        Pv_Period_Name   OUT  VARCHAR2,
        Pv_Nb_period     OUT  NUMBER
        );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_MAIN_FAPROJ
--  Description   : Soumission du programme de prevision d'amortissement
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- pv_book_type_Code         Entree             Code du livre
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_MAIN_FAPROJ (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );

-- Fonctions pour l'alimentation de la table DKA_FABUDGET_WORK a partir des tables 
-- generees par les traitements de prevision des amortissement
----------------------------------------------------------------------------------------------------
--  Nom           : DKA_INS_TRAITEMENT
--  Description   : Insertion des donnees generees par un traitement
--                  On execute l'ordre dynamiquement car nom de la table d'origine 
--                  est fonction de l'id. du traitement passe en parametre
--
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pn_Request_Id             Entree             Id du traitement
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_INS_TRAITEMENT
       (
        pv_errbuf     IN OUT   VARCHAR2,
        pn_retcode    IN OUT   NUMBER,
        pn_request_Id IN      NUMBER,
        pn_annee_n    IN NUMBER
        ) ;

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_GET_APPARTENANCE
--  Description   : Organisation d'appartenance du projet passe en parametre
--
--
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- pn_Project_Id             Entree             Id. du projet
-- Pv_Org_Name               Sortie             Nom de l'organisation d'appartenance
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_GET_APPARTENANCE
        (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        Pn_Project_Id IN      NUMBER,
        Pv_Org_Name   OUT     VARCHAR2
        ) ;

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_GET_CENTRE
--  Description   : Centre attache a l'organisation (Hierarchie 'HIERARCHIE_MENSUELLE' - Niveau 4) 
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pv_Org_Name               Entree             Nom de l'organisation d'appartenance
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_GET_CENTRE
        (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        Pv_Org_Name  IN       VARCHAR2,
        Pv_Centre    OUT      VARCHAR2
        ) ;

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_UPDATE_DATA
--  Description   : Mise a jour des donnees dans la table DKA_SFABUDGET_WORK
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_UPDATE_DATA
        (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        ) ;

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_MAIN_COPY_DATA 
--  Description   : Insertion dans la table DKA_SFABUDGET_WORK des donnees generees par 
--                  les traitements de prevision des amortissements
--
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- pv_book_type_Code         Entree             Code du livre
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_MAIN_COPY_DATA 
        (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        ) ;

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_MAIN_GEN_DATA
--  Description   : Generation des donnees 
--
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- pv_book_type_Code         Entree             Code du livre
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_MAIN_GEN_DATA
        (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );

-- Fonctions pour la suppression des tables generees par les traitements de prevision des amortissements
----------------------------------------------------------------------------------------------------
--  Nom           : DKA_REQUEST_DROP_TABLE
--  Description   : Suppression de la table generee par le traitement de prevision dont l'id. de traitement
--                  est passe en parametre
--
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
-- Pn_resquest_Id            Entree             Id. du traitement
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_REQUEST_DROP_TABLE
        (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        Pn_request_id IN      NUMBER
        );

----------------------------------------------------------------------------------------------------
--  Nom           : DKA_MAIN_DROP_TABLE
--  Description   : suppression des tables generees par les traitements de prevision des amortissements
--
--
--  PARAMETRES    :
-- pv_errbuf                 Entrée/Sortie      message d'erreur
-- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE DKA_MAIN_DROP_TABLE
        (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        );

 ------------------------------------------------------------------------------------
  --  Nom           : p_validate
  --  Description   :
  --
  --  PARAMETRES    : p_condition: Si FALSE => Affiche un message dans le journal et
  --                                           genere une erreur fatale
  --                               Si TRUE  => Fait aucune action
  --                  p_message:   Message a afficher dans le journal
  ------------------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN,
                       p_message   IN VARCHAR2 DEFAULT NULL);
 --------------------------------------------------------------------------------------------------
--  Nom           : Extraction justif
--  Description   : Procédure Extraction justif
--
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
PROCEDURE p_extr_data_justif(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                             p_file_name      IN VARCHAR2,
                             p_nb_lignes      IN OUT VARCHAR2);   
							 
-- SELOO
PROCEDURE EDIT_REG_JUSTIF (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        p_regoin     IN       VARCHAR2, -- 25/04/2007
		p_file       IN       VARCHAR2
    );							 
-- SELOO
    PROCEDURE EDIT_REG_HYP (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        p_regoin     IN       VARCHAR2, -- 25/04/2007
		p_file       IN       VARCHAR2
    );
	
PROCEDURE p_extr_data_justif_REG(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2,
						   p_region         IN VARCHAR2,
						   vn_request_id    out number );
						   
PROCEDURE p_extr_data_hyperion(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           
						   p_file_name      IN VARCHAR2,
							vn_request_id   out  NUMBER );

PROCEDURE p_extr_data_hyperion_REG(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                              
                               p_file_name      IN VARCHAR2,
							   p_region IN VARCHAR2,
							   vn_request_id  out NUMBER );

    -----------------------------------------------------------------
  --  Nom           : SEND_MSG
  --  Description   : procédure d'envoi de mail avec pièce jointe
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  --   vb_boucle        IN         BOOLEAN
  -----------------------------------------------------------------
  
  PROCEDURE SEND_MSG (p_to          IN VARCHAR2,
                                       p_from        IN VARCHAR2,
                                       p_subject     IN VARCHAR2,
                                       p_text_msg    IN VARCHAR2 DEFAULT NULL,
                                       p_attach_name IN VARCHAR2 DEFAULT NULL,
                                       p_attach_mime IN VARCHAR2 DEFAULT NULL,
                                       p_smtp_host   IN VARCHAR2,
                                       p_smtp_port   IN NUMBER DEFAULT 25);
--------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale du specifique DKA_SFABUDGET
--
--  PARAMETRES    :
-- pv_errbuf                 Entree/Sortie      message d'erreur
-- pn_retcode                Entree/Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER,
        pv_ref_date  IN       VARCHAR2,
		region_budget       IN       VARCHAR2
    );


END DKA_SFABUDGET_PKG; -- Package specs
/
SHOW ERRORS;

EXIT
