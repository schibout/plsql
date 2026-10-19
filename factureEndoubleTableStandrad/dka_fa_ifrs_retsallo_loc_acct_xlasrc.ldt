-----------------------------------------------------------------------------------------------
-- CAPGEMINI NORD
-- PROJET                 : HELIOS
-- NOM                    : DKA_SPORETRT_DA_ANOS_PKG.pkg
-- DESCRIPTION            : DKA_SPORETRT_DA_ANOS_PKG package body
--                            package contenant les procédures de traitements des anomalies sur DA
--- AUTEUR                : Benjamin COUDRIER
--- DATE DE CREATION    : 15 juin 2012
-- COMMENTAIRE            : A exécuter sur SQLPLUS avec le user APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 18/05/2016 BDE Modification du nom du package (Remplacement XXVE -> DKA )
-- 15/03/2017 MEG Modification : artf2120386 
-- 14/02/2018 RBE artf2376259 : SPE178 - Correction de la sélection Employés 
--------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY DKA_SPORETRT_DA_ANOS_PKG
AS

    --------------------------------------------------------------------------------
    --    Déclaration : Variable Globale.                                           --
    --------------------------------------------------------------------------------
    gv_conn                       VARCHAR2(30);
  gv_expediteur                 VARCHAR2(50);
  gv_mail_test                  VARCHAR2(240) := NULL;
    gn_erreur                        PLS_INTEGER;
    gn_erreur_avert                  PLS_INTEGER;
    gn_erreur_search                   PLS_INTEGER;
    --------------------------------------------------------------------------------
    --  Nom           : init
    --  Description   : Procédure d'initialisation pour l'envoi de mail.
    --
    --  Paramètres    : pv_errbuf         message d'erreur
    --                  pn_retcode       code de retour
    --------------------------------------------------------------------------------
    PROCEDURE init (pv_errbuf    IN OUT   VARCHAR2,
                    pn_retcode   OUT      NUMBER
                    )
    IS
        l_param           VARCHAR2(100);
        rec_param         dka_parameters%ROWTYPE;
        e_err_param       EXCEPTION;
        gv_base             VARCHAR2(50);
    BEGIN
        gn_erreur := 0;
        gn_erreur_avert := 0;
        gn_erreur_search := 0;
        IF pn_retcode != 0 THEN
            RAISE e_err_param;
        END IF;
        --Récupération du nom de la base de données concernée
        BEGIN
            SELECT name
            INTO gv_base
            FROM v$database;
        EXCEPTION
            WHEN OTHERS THEN
                pv_errbuf := 'ERREUR lors de la recherche du nom de la base de données';
                pn_retcode := 2;
                RAISE;
        END;
        --Recuperation des parametres de connexion
        l_param := 'SMTP_CONNECTION';
        Dka_Tools_Pkg.get_parameter ('SPORETRT_ERRORS', 'SMTP_CONNECTION', rec_param, pn_retcode,pv_errbuf);
        gv_conn := rec_param.varchar2_value;

        Dka_Tools_Pkg.put_log_message('Connexion SMTP : '||gv_conn);
        IF pn_retcode != 0 THEN
            RAISE e_err_param;
        END IF;

        --Recuperation du nombre de reconduction max
        l_param := 'EXPEDITEUR_MAIL';
        Dka_Tools_Pkg.get_parameter ('SPORETRT_ERRORS', 'EXPEDITEUR_MAIL', rec_param, pn_retcode, pv_errbuf);
        gv_expediteur := rec_param.varchar2_value;
        Dka_Tools_Pkg.put_log_message('Expediteur mail : '||gv_expediteur);

        IF pn_retcode != 0 THEN
            RAISE e_err_param;
        END IF;

    EXCEPTION
        WHEN e_err_param THEN
            pv_errbuf  := 'Erreur parametre '||l_param||' : '|| SQLERRM;
            pn_retcode := 2;
            Dka_Tools_Pkg.put_log_message(pv_errbuf);
        WHEN OTHERS THEN
            pv_errbuf  := 'Erreur procedure INIT '|| SQLERRM;
            pn_retcode := 2;
            Dka_Tools_Pkg.put_log_message(pv_errbuf);
    END init;
    
    --------------------------------------------------------------------------------
    --  Nom           : DA_Catalog_Non_Trans_Cmd_Relan
    --  Description   : DA Catalogue non transformée automatiquement en commande.
    --
    --  Paramètres    : pv_errbuf     message d'erreur
    --                  pn_retcode    code de retour
    --------------------------------------------------------------------------------
    PROCEDURE DA_Catalog_Non_Trans_Cmd_Relan (pv_errbuf       OUT VARCHAR2,
                                                     pn_retcode      OUT NUMBER
                                                    )
    IS
        -- Curseur de recherche des DA Catalogue non transformée automatiquement. --
        CURSOR Cur_Da_Catalogue(Pd_Date_Trait IN DATE) IS
            SELECT      DISTINCT 
                        PRHA.SEGMENT1                AS     NUM_ENTETE,
                        PRLA.REQUISITION_HEADER_ID    AS    ID_LINE,
                        MAX(PAH.ACTION_DATE)        AS    MAX_DATE
            FROM        PO_REQUISITION_LINES_ALL   PRLA,
                        PO_REQUISITION_HEADERS_ALL   PRHA,
                        PO_ACTION_HISTORY      PAH
            WHERE       PRHA.REQUISITION_HEADER_ID = PRLA.REQUISITION_HEADER_ID
            AND         PRHA.REQUISITION_HEADER_ID = PAH.OBJECT_ID
            -- RG1 Les demandes d'achats ont un statut "ouvert". --
            AND         PRHA.CLOSED_CODE           = 'OPEN'
            -- RG2 Les champs fournisseur et site fournisseur doivent être renseignés. --
            AND         PRLA.VENDOR_ID             IS NOT NULL
            AND         PRLA.VENDOR_SITE_ID        IS NOT NULL
            -- RG3 La demande d'achat doit être approuvée. --
            AND         PRHA.AUTHORIZATION_STATUS  = 'APPROVED'
            AND         PAH.ACTION_CODE            = 'APPROVE'
            AND         TRUNC(PAH.ACTION_DATE)     = TRUNC(Pd_Date_Trait)
            -- RG4 Le code de fermeture non renseigné. --
            AND         PRLA.CLOSED_CODE           IS NULL
            -- RG5 la date d'annulation non renseigné. --
            AND         PRLA.CANCEL_DATE           IS NULL
            -- RG6 Il n'existe pas de lien entre une demande d'achat et un ordre d'achat. --
            AND         PRLA.LINE_LOCATION_ID      IS NULL
            -- Permet de rechercher la DA Catalogue à une date Maximum. --
            GROUP BY    PRHA.SEGMENT1,
                        PRLA.REQUISITION_HEADER_ID;
            
            
        Rec_Da_Catalogue     Cur_Da_Catalogue%ROWTYPE;
        
        -- Nombre de Workflow relancé. --
        Nbr_Workflow        NUMBER;
        
        -- Heure de lancement du traitement. --
        vn_htrait            NUMBER;
        vd_date_trait        DATE;
        
        -- Variable Workflow. --
        wf_item_type        wf_items.item_type%TYPE;
        wf_item_key            wf_items.item_key%TYPE;
        
        -- Nombre de ligne supprimé. --
        vn_count     NUMBER;
    BEGIN
        Nbr_Workflow    :=    0;
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
        Dka_Tools_Pkg.put_log_message('--      DA Catalogue non transformée automatiquement en commande      --');
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
        Dka_Tools_Pkg.put_log_message(' ');
        Dka_Tools_Pkg.put_log_message('| N° Entête DA Catalogue | Identifiant Ligne DA Catalogue | Type de Workflow | Clé de Workflow |');
        ------------------------------------------------------
        -- Recherche de l'heure du lancement du traitement. --
        ------------------------------------------------------
        BEGIN
            SELECT     TO_NUMBER(TO_CHAR(SYSDATE,'HH24')) 
            INTO    vn_htrait
            FROM     dual;
        EXCEPTION
            WHEN OTHERS THEN
                pn_retcode     :=     1;
                pv_errbuf     :=    '# SQLERRM : ' || SQLERRM;
                Dka_Tools_Pkg.put_log_message('Erreur : ');
                Dka_Tools_Pkg.put_log_message('SELECT     TO_NUMBER(TO_CHAR( ' || SYSDATE || ',''HH24'')) 
                                                INTO    vn_htrait
                                                FROM     dual;');
                Dka_Tools_Pkg.put_log_message(pv_errbuf);
        END;
        
        IF vn_htrait < 7 THEN
            vd_date_trait    :=    SYSDATE - 1;
        ELSE
            vd_date_trait    :=    SYSDATE;
        END IF;
        
        -------------------------------
        -- Vider la table temporaire --
        -------------------------------
        BEGIN
            DELETE FROM DKA_SPORETRT_DA_ANOS_TMP;
            vn_count := SQL%ROWCOUNT;
            commit;
            Dka_Tools_Pkg.put_log_message(vn_count || ' ligne(s) supprimée(s).');
        EXCEPTION
            WHEN OTHERS THEN
                -- Mise en avertissement du traitement : --
                pn_retcode     := 1;
                -- Message d'erreur de type standard : --
                pv_errbuf    := 'Erreur inconnue : ' || SQLERRM;
                Dka_Tools_Pkg.put_log_message('# SQLCODE : ' || SQLCODE);
                Dka_Tools_Pkg.put_log_message('# SQLERRM : ' || SQLERRM);
                Dka_Tools_Pkg.put_log_message('DELETE TABLE DKA_SPORETRT_DA_ANOS_TMP');
        END;
        ---------------------------------------------------------------------------
        -- Parcours l'ensemble des DA Catalogue non transformée automatiquement. --
        ---------------------------------------------------------------------------
        FOR Rec_Da_Catalogue IN Cur_Da_Catalogue (vd_date_trait)
            LOOP
                -------------------------------------------------
                -- Recherche du workflow DKACRTPO lié à la DA. --
                -------------------------------------------------
                BEGIN
                    SELECT    wi.item_type,
                            wi.item_key
                    INTO    wf_item_type,
                            wf_item_key
                    FROM    wf_items wi
                    WHERE    wi.item_type     =        'DKACRTPO'
                    AND        wi.root_activity =         'OVERALL_AUTOCREATE_PROCESS'
                    AND        wi.item_key        like    Rec_Da_Catalogue.ID_LINE || '-%';
                EXCEPTION
                    WHEN OTHERS THEN
                        wf_item_type := NULL;
                        wf_item_key     := NULL;
                        -- Mise en avertissement du traitement : --
                        pn_retcode     := 1;
                        -- Message d'erreur de type standard : --
                        pv_errbuf    := 'Erreur : ' || SQLERRM;
                END;
                
                IF wf_item_type IS NULL AND wf_item_key IS NULL THEN
                    Dka_Tools_Pkg.put_log_message('| ' || Rec_Da_Catalogue.NUM_ENTETE || ' | ' || Rec_Da_Catalogue.ID_LINE || ' | IMPOSSIBLE DE DETERMINER ITEM_TYPE | IMPOSSIBLE DE DETERMINER ITEM_KEY | Il n''existe aucun workflow de création automatique de commande pour cette DA.');
                ELSE
                    Dka_Tools_Pkg.put_log_message('| ' || Rec_Da_Catalogue.NUM_ENTETE || ' | ' || Rec_Da_Catalogue.ID_LINE || ' | ' || wf_item_type || ' | ' || wf_item_key || ' |');
                    -- Relance le workflow des DA Catalogue non transformée automatiquement. --
                    Wf_Engine_Util.Start_Process_Internal(itemtype=> wf_item_type,
                                                          itemkey => wf_item_key,
                                                          runmode => 'START');
                    
                    --------------------------------------------------------------------------------------------------------------------------
                    -- Insertion de l'item_type, de l'item_key, du numéro d'entête et de l'identifiant de la ligne dans une table temporaire.
                    -- Afin de permettre la relance des notifications.
                    --------------------------------------------------------------------------------------------------------------------------
                    BEGIN
                        INSERT INTO DKA_SPORETRT_DA_ANOS_TMP 
                        VALUES (wf_item_type,
                                wf_item_key, 
                                Rec_Da_Catalogue.NUM_ENTETE, 
                                Rec_Da_Catalogue.ID_LINE
                                );
                    EXCEPTION
                        WHEN OTHERS THEN
                            -- Mise en avertissement du traitement : --
                            pn_retcode    := 1;
                            -- Message d'avertissement de type standard : --
                            pv_errbuf    := 'Erreur lors de l''insert tmp : ' || SQLERRM;
                            Dka_Tools_Pkg.put_log_message('Erreur : ');
                            Dka_Tools_Pkg.put_log_message('INSERT INTO DKA_SPORETRT_DA_ANOS_TMP 
                                                            VALUES ('||wf_item_type||',
                                                                    '||wf_item_key||', 
                                                                    '||Rec_Da_Catalogue.NUM_ENTETE||', 
                                                                    '||Rec_Da_Catalogue.ID_LINE||'
                                                                    );');
                            Dka_Tools_Pkg.put_log_message(pv_errbuf);
                    END;
                    
                    -- Incrémentation du nombre de Workflow. --
                    Nbr_Workflow := Nbr_Workflow + 1;
                END IF;
            END LOOP;
        -- Commit de l'ensemble des insertions dans la table temporaire DKA_SPORETRT_DA_ANOS_TMP. --
        commit;
        -- Affichage du nombre de workflow exécuter. --
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
        Dka_Tools_Pkg.put_log_message('-- Nombre de Workflow relancé : ' || Nbr_Workflow || '');
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
    EXCEPTION
        WHEN OTHERS THEN
            -- Retour à l'état précédent : --
            ROLLBACK;
            -- Mise en avertissement du traitement : --
            pn_retcode     := 2;
            -- Message d'erreur de type standard : --
            pv_errbuf    := 'Erreur inconnue : ' || SQLERRM;
            Dka_Tools_Pkg.put_log_message('Erreur :');
            Dka_Tools_Pkg.put_log_message('# SQLCODE : ' || SQLCODE);
            Dka_Tools_Pkg.put_log_message('# SQLERRM : ' || SQLERRM);
            Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
            Dka_Tools_Pkg.put_log_message('-- Nombre de Workflow relancé : ' || Nbr_Workflow || '');
            Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
    END DA_Catalog_Non_Trans_Cmd_Relan;
    
    
    --------------------------------------------------------------------------------
    --  Nom           : DA_Catalog_Non_Trans_Cmd_Notif
    --  Description   : DA Catalogue non transformée automatiquement en commande.
    --
    --  Paramètres    : pv_errbuf     message d'erreur
    --                  pn_retcode    code de retour
    --------------------------------------------------------------------------------
    PROCEDURE DA_Catalog_Non_Trans_Cmd_Notif (pv_errbuf       OUT VARCHAR2,
                                                     pn_retcode      OUT NUMBER
                                                    )
    IS
        -- Curseur de recherche des DA Catalogue dans la table temporaire. --
        -- Cette recherche permet de déterminer les DA Catalogue donc les notifications sont de type WF_ERROR. --
        -- Recherche des Workflow POAPPRV. --
        CURSOR Cur_Da_Catalogue IS
            SELECT  DISTINCT
                    XXSDAT.T_WF_ITEM_TYPE             AS     ITEM_TYPE,
                    XXSDAT.T_WF_ITEM_KEY              AS     ITEM_KEY,
                    XXSDAT.T_SEGMENT1                AS     NUM_ENTETE,
                    XXSDAT.T_REQUISITION_HEADER_ID    AS    ID_LINE,
                    PHA.SEGMENT1                    AS    NUM_CMD,
                    PHA.PO_HEADER_ID                AS    ID_CMD,
                    PHA.WF_ITEM_TYPE                AS    ITEM_TYPE_CMD,
                    PHA.WF_ITEM_KEY                    AS    ITEM_KEY_CMD
            FROM    DKA_SPORETRT_DA_ANOS_TMP       XXSDAT,
                    PO_HEADERS_ALL                  PHA,
                    PO_REQUISITION_HEADERS_ALL      PRHA,
                    PO_REQUISITION_LINES_ALL        PRLA,
                    PO_LINE_LOCATIONS_ALL           PLLA
            WHERE   PHA.PO_HEADER_ID                 = PLLA.PO_HEADER_ID
            AND     PRLA.REQUISITION_HEADER_ID      = PRHA.REQUISITION_HEADER_ID
            AND     PRLA.LINE_LOCATION_ID           = PLLA.LINE_LOCATION_ID
            AND     XXSDAT.T_REQUISITION_HEADER_ID     = PRHA.REQUISITION_HEADER_ID
            AND     PRHA.SEGMENT1                   = XXSDAT.T_SEGMENT1;
            
            
        Rec_Da_Catalogue     Cur_Da_Catalogue%ROWTYPE;

        -- Nom de l'erreur dans le processus. --
        l_wf_process_name    wf_process_activities.process_name%TYPE;
        
        -- Nombre de Workflow relancé. --
        Nbr_Workflow        NUMBER;
        
        -- Variables contenant l'item_key et l'item_type pour réessayer le workflow POAPPRV. --
        l_wf_item_key        wf_item_activity_statuses.item_key%TYPE;
        l_wf_item_type        wf_item_activity_statuses.item_type%TYPE;
    BEGIN
        Nbr_Workflow    :=    0;
        Dka_Tools_Pkg.put_log_message('-- ----------------------------------------------------------------------------------- --');
        Dka_Tools_Pkg.put_log_message('--      DA Catalogue non transformée dont les notifications sont de type WF_ERROR      --');
        Dka_Tools_Pkg.put_log_message('-- ----------------------------------------------------------------------------------- --');
        Dka_Tools_Pkg.put_log_message(' ');
        Dka_Tools_Pkg.put_log_message('| N° Entête DA Catalogue | Identifiant Ligne DA Catalogue | Type de Workflow | Clé de Workflow |');
        
        ---------------------------------------------------------------------------
        -- Parcours l'ensemble des DA Catalogue non transformée automatiquement. --
        ---------------------------------------------------------------------------
        FOR Rec_Da_Catalogue IN Cur_Da_Catalogue
            LOOP
                -- Réessayer le workflow des DA Catalogue non transformé automatiquement. --
                --On rejoue l'activité en erreur
                BEGIN
                    SELECT     wpa.process_name,
                            wias.item_key,
                            wias.item_type
                    INTO    l_wf_process_name,
                            l_wf_item_key,
                            l_wf_item_type
                    FROM      wf_item_activity_statuses wias,
                            wf_process_activities wpa
                    WHERE   wias.item_key             =    Rec_Da_Catalogue.ITEM_KEY_CMD
                    AND        wias.item_type            =    'POAPPRV'
                    AND     wpa.instance_id         =     wias.process_activity
                    AND     wias.activity_status     =     'ERROR';
                EXCEPTION
                    WHEN OTHERS THEN
                        -- Mise en avertissement du traitement : --
                        pn_retcode    := 1;
                END;
                
                -- Relance le Workflow DKA_SPO_WF_CREATEPO. --
                IF l_wf_process_name IS NOT NULL THEN
                    WF_ENGINE.HandleError(itemtype => l_wf_item_type,
                                          itemkey => l_wf_item_key,
                                          activity => l_wf_process_name,
                                          command => wf_engine.eng_retry,
                                          result => pv_errbuf);
                    Dka_Tools_Pkg.put_log_message('| ' || Rec_Da_Catalogue.NUM_ENTETE || ' | ' || Rec_Da_Catalogue.ID_LINE || ' | ' || l_wf_item_type || ' | ' || l_wf_item_key || ' |');
                    -- Incrémentation du nombre de Workflow. --
                    Nbr_Workflow := Nbr_Workflow + 1;
                ELSE
                    Dka_Tools_Pkg.put_log_message('NON RELANCE | ' || Rec_Da_Catalogue.NUM_ENTETE || ' | ' || Rec_Da_Catalogue.ID_LINE || ' | IMPOSSIBLE DE DETERMINER ITEM_TYPE | IMPOSSIBLE DE DETERMINER ITEM_KEY | Vérifier que le workflow de création automatique de commande c''est terminé sans erreur.');
                END IF;
                
            END LOOP;
        -- Commit de l'ensemble des insertions dans la table temporaire DKA_SPORETRT_DA_ANOS_TMP. --
        commit;
        -- Affichage du nombre de notification de type WF_ERROR générée. --
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
        Dka_Tools_Pkg.put_log_message('-- Nombre de notification de type WF_ERROR générée : ' || Nbr_Workflow || '');
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
    EXCEPTION
        WHEN OTHERS THEN
            -- Retour à l'état précédent : --
            ROLLBACK;
            -- Mise en avertissement du traitement : --
            pn_retcode     := 2;
            -- Message d'erreur de type standard : --
            pv_errbuf    := 'Erreur inconnue : ' || SQLERRM;
            Dka_Tools_Pkg.put_log_message('Erreur :');
            Dka_Tools_Pkg.put_log_message('# SQLCODE : ' || SQLCODE);
            Dka_Tools_Pkg.put_log_message('# SQLERRM : ' || SQLERRM);
            Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
            Dka_Tools_Pkg.put_log_message('-- Nombre de notification de type WF_ERROR générée : ' || Nbr_Workflow || '');
            Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
    END DA_Catalog_Non_Trans_Cmd_Notif;
    
    
    --------------------------------------------------------------------------------
    --  Nom           : DA_Statut_Incomplet
    --  Description   : DA en statut "INCOMPLET".
    --
    --  Paramètres    : pv_errbuf     message d'erreur
    --                  pn_retcode    code de retour
    --------------------------------------------------------------------------------
    PROCEDURE DA_Statut_Incomplet (pv_errbuf       OUT VARCHAR2,
                                   pn_retcode      OUT NUMBER
                                  )
    IS
        -- Curseur de recherche des DA en statut "INCOMPLET". --
        CURSOR Cur_Da_Incomplet (Pd_Date_Trait IN DATE) IS
            SELECT     DISTINCT PRHA.WF_ITEM_TYPE             AS     ITEM_TYPE,
                    PRHA.WF_ITEM_KEY              AS     ITEM_KEY,
                    PRHA.SEGMENT1                AS     NUM_ENTETE,
                    PRHA.REQUISITION_HEADER_ID    AS    ID_LINE
            FROM    PO_REQUISITION_LINES_ALL   PRLA,
                    PO_REQUISITION_HEADERS_ALL   PRHA
            WHERE    PRHA.REQUISITION_HEADER_ID = PRLA.REQUISITION_HEADER_ID
            -- RG1 - Les demandes d'achats ont un statut "ouvert". --
            AND        PRHA.CLOSED_CODE           IS NULL
            -- RG2 - Les champs wf_item_key et wf_item_type sont renseignés. --
            AND        PRHA.WF_ITEM_KEY           IS NOT NULL
            AND        PRHA.WF_ITEM_TYPE           IS NOT NULL
            -- RG3 - Les demandes d'achats doivent être au statut "INCOMPLETE". --
            AND        PRHA.AUTHORIZATION_STATUS  = 'INCOMPLETE'
            AND        TRUNC(PRHA.CREATION_DATE)  = TRUNC(Pd_Date_Trait)
            -- RG4 Le code de fermeture non renseigné. --
            AND     PRLA.CLOSED_CODE           IS NULL
            -- RG5 - La date d'annulation non renseigné. --
            AND        PRLA.CANCEL_DATE           IS NULL
            -- RG6 - Il n'existe pas de lien entre une demande d'achat et un ordre d'achat. --
            AND        PRLA.LINE_LOCATION_ID       IS NULL;
        
        Rec_Da_Incomplet     Cur_Da_Incomplet%ROWTYPE;
        
        -- Nombre de Workflow relancé. --
        Nbr_Workflow        NUMBER;
        
        -- Heure de lancement du traitement. --
        vn_htrait            NUMBER;
        vd_date_trait        DATE;
        
        -- Variable Workflow. --
        wf_item_type        wf_items.item_type%TYPE;
        wf_item_key            wf_items.item_key%TYPE;
        
    BEGIN
        -- Initialisation du compteur de Workflow : --
        Nbr_Workflow    :=    0;
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
        Dka_Tools_Pkg.put_log_message('--                      DA en statut "INCOMPLET"                      --');
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
        Dka_Tools_Pkg.put_log_message(' ');
        Dka_Tools_Pkg.put_log_message('| N° Entête DA Catalogue | Identifiant Ligne DA Catalogue | Type de Workflow | Clé de Workflow |');
        
        ------------------------------------------------------
        -- Recherche de l'heure du lancement du traitement. --
        ------------------------------------------------------
        BEGIN
            select     TO_NUMBER(TO_CHAR(SYSDATE,'HH24')) 
            into    vn_htrait
            from     dual;
        EXCEPTION
            WHEN OTHERS THEN
                pn_retcode     :=     1;
                pv_errbuf     :=    '# SQLERRM : ' || SQLERRM;
                Dka_Tools_Pkg.put_log_message('Erreur : ');
                Dka_Tools_Pkg.put_log_message('SELECT     TO_NUMBER(TO_CHAR( ' || SYSDATE || ',''HH24'')) 
                                                INTO    vn_htrait
                                                FROM     dual;');
                Dka_Tools_Pkg.put_log_message(pv_errbuf);
        END;
        
        IF vn_htrait < 7 THEN
            vd_date_trait    :=    SYSDATE - 1;
        ELSE
            vd_date_trait    :=    SYSDATE;
        END IF;
        
        -------------------------------------------------------
        -- Parcours l'ensemble des DA en statut "INCOMPLET". --
        -------------------------------------------------------
        FOR Rec_Da_Incomplet IN Cur_Da_Incomplet (vd_date_trait)
            LOOP
                -------------------------------------------------
                -- Recherche du workflow DKACRTPO lié à la DA. --
                -------------------------------------------------
                BEGIN
                    SELECT    wi.item_type,
                            wi.item_key
                    INTO    wf_item_type,
                            wf_item_key
                    FROM    wf_items wi
                    WHERE    wi.item_type     =        'REQAPPRV'
                    AND        wi.item_key        like    Rec_Da_Incomplet.ID_LINE || '-%';
                EXCEPTION
                    WHEN OTHERS THEN
                        wf_item_type := NULL;
                        wf_item_key     := NULL;
                        -- Mise en avertissement du traitement : --
                        pn_retcode     := 1;
                        -- Message d'erreur de type standard : --
                        pv_errbuf    := 'Erreur : ' || SQLERRM;
                END;
                
                IF wf_item_type IS NULL AND wf_item_key IS NULL THEN
                    Dka_Tools_Pkg.put_log_message('| ' || Rec_Da_Incomplet.NUM_ENTETE || ' | ' || Rec_Da_Incomplet.ID_LINE || ' | IMPOSSIBLE DE DETERMINER ITEM_TYPE | IMPOSSIBLE DE DETERMINER ITEM_KEY | Il n''existe aucun workflow d''approbation des demandes d''achats.');
                ELSE
                    Dka_Tools_Pkg.put_log_message('| ' || Rec_Da_Incomplet.NUM_ENTETE || ' | ' || Rec_Da_Incomplet.ID_LINE || ' | ' || wf_item_type || ' | ' || wf_item_key || ' |');
                    -- Relance le workflow des DA en statut "INCOMPLET". --
                    Wf_Engine_Util.Start_Process_Internal(itemtype=> wf_item_type,
                                                          itemkey => wf_item_key,
                                                          runmode => 'START');
                
                    -- Incrémentation du nombre de Workflow. --
                    Nbr_Workflow := Nbr_Workflow + 1;
                END IF;
            END LOOP;
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
        Dka_Tools_Pkg.put_log_message('-- Nombre de Workflow relancé : ' || Nbr_Workflow || '');
        Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
    EXCEPTION
        WHEN OTHERS THEN
            -- Retour à l'état précédent : --
            ROLLBACK;
            -- Mise en avertissement du traitement : --
            pn_retcode     := 2;
            -- Message d'erreur de type standard : --
            pv_errbuf    := 'Erreur inconnue : ' || SQLERRM;
            Dka_Tools_Pkg.put_log_message('Erreur :');
            Dka_Tools_Pkg.put_log_message('# SQLCODE : ' || SQLCODE);
            Dka_Tools_Pkg.put_log_message('# SQLERRM : ' || SQLERRM);
            Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
            Dka_Tools_Pkg.put_log_message('-- Nombre de Workflow relancé : ' || Nbr_Workflow || '');
            Dka_Tools_Pkg.put_log_message('-- ------------------------------------------------------------------ --');
    END DA_Statut_Incomplet;
    
    
    --------------------------------------------------------------------------------
    --  Nom           : DA_Statut_System_Saved
    --  Description   : DA en statut "SYSTEM SAVED".
    --
    --  Paramètres    : pv_errbuf     message d'erreur
    --                  pn_retcode    code de retour
    --------------------------------------------------------------------------------
    PROCEDURE DA_Statut_System_Saved (pv_errbuf       OUT VARCHAR2,
                                                    pn_retcode      OUT NUMBER,
                                                      pv_mail_envoi   IN VARCHAR2,
                                    pv_mail_test    IN VARCHAR2
                                     )
    IS
        -- Curseur de recherche des DA en statut "SYSTEM_SAVED". --
        CURSOR Cur_Da_System_Saved (Pd_Date_Trait IN DATE) IS
            SELECT     DISTINCT PRHA.REQUISITION_HEADER_ID     AS     REQUISITION_HEADER_ID,
                    PRHA.ORG_ID                       AS     ORG_ID,
                    PRHA.SEGMENT1                AS     NUM_ENTETE,
                    PRHA.DESCRIPTION            AS    DESCRIPTION
            FROM    PO_REQUISITION_LINES_ALL   PRLA,
                    PO_REQUISITION_HEADERS_ALL   PRHA
            WHERE    PRHA.REQUISITION_HEADER_ID = PRLA.REQUISITION_HEADER_ID
            -- RG1 - Les demandes d'achats ont un statut "ouvert". --
            AND        NVL(PRHA.CLOSED_CODE,'OPEN')           = 'OPEN'
            -- RG2 - Les champs wf_item_key et wf_item_type ne doivent pas être renseignés. --
            AND        PRHA.WF_ITEM_KEY           IS NULL
            AND        PRHA.WF_ITEM_TYPE           IS NULL
            -- RG3 - Les demandes d'achats doivent être au statut "SYSTEM_SAVED". --
            AND        PRHA.AUTHORIZATION_STATUS  = 'SYSTEM_SAVED'
            AND        TRUNC(PRHA.CREATION_DATE)  = TRUNC(Pd_Date_Trait)
            -- RG4 - Le code de fermeture non renseigné. --
            AND        PRLA.CLOSED_CODE            IS NULL
            -- RG5 - La date d'annulation non renseigné. --
            AND        PRLA.CANCEL_DATE           IS NULL
            -- RG6 - Il n'existe pas de lien entre une demande d'achat et un ordre d'achat. --
            AND        PRLA.LINE_LOCATION_ID       IS NULL;
        
        Rec_Da_System_Saved     Cur_Da_System_Saved%ROWTYPE;
        
        -- initialisation des variables d'envoi de mail. --
        pv_mail                VARCHAR2(100);
        pv_name_mail        VARCHAR2(300);
        pv_appart_demandeur    VARCHAR2(200);
        
        -- Heure de lancement du traitement. --
        vn_htrait            NUMBER;
        vd_date_trait        DATE;
        
    BEGIN
        -- Initialisation des variables de connexion pour l'envoi d'un mail. --
        IF pv_mail_envoi = 'Y' THEN
            init(pv_errbuf, pn_retcode);
        END IF;
        
        Dka_Tools_Pkg.put_log_message('-- ----------------------------------------------------------------- --');
        Dka_Tools_Pkg.put_log_message('--                    DA en statut "SYSTEM SAVED"                    --');
        Dka_Tools_Pkg.put_log_message('-- ----------------------------------------------------------------- --');
        Dka_Tools_Pkg.put_log_message(' ');
        Dka_Tools_Pkg.put_log_message('| Identifiant Entête DA Catalogue | Identifiant de l''Organisation | Numéro de l''entête de la DA Catalogue | Description |');
        ------------------------------------------------------
        -- Recherche de l'heure du lancement du traitement. --
        ------------------------------------------------------
        BEGIN
            select     TO_NUMBER(TO_CHAR(SYSDATE,'HH24')) 
            into    vn_htrait
            from     dual;
        EXCEPTION
            WHEN OTHERS THEN
                pn_retcode     :=     1;
                pv_errbuf     :=    '# SQLERRM : ' || SQLERRM;
                Dka_Tools_Pkg.put_log_message('Erreur : ');
                Dka_Tools_Pkg.put_log_message('SELECT     TO_NUMBER(TO_CHAR( ' || SYSDATE || ',''HH24'')) 
                                                INTO    vn_htrait
                                                FROM     dual;');
                Dka_Tools_Pkg.put_log_message(pv_errbuf);
        END;
        
        IF vn_htrait < 7 THEN
            vd_date_trait    :=    SYSDATE - 1;
        ELSE
            vd_date_trait    :=    SYSDATE;
        END IF;
        FOR Rec_Da_System_Saved IN Cur_Da_System_Saved (vd_date_trait)
            LOOP
                Dka_Tools_Pkg.put_log_message('| ' || Rec_Da_System_Saved.REQUISITION_HEADER_ID || ' | ' || Rec_Da_System_Saved.ORG_ID || ' | ' || Rec_Da_System_Saved.NUM_ENTETE || ' | ' || Rec_Da_System_Saved.DESCRIPTION ||' |');
                -- Mise à jour des DA sélectionnés au statut "INCOMPLET". --
        BEGIN
                    UPDATE     PO_REQUISITION_HEADERS_ALL PRHA
                    SET        PRHA.AUTHORIZATION_STATUS     = 'INCOMPLET'
                    WHERE    PRHA.REQUISITION_HEADER_ID    = Rec_Da_System_Saved.REQUISITION_HEADER_ID
                    AND        PRHA.WF_ITEM_KEY           IS NULL
                    AND        PRHA.WF_ITEM_TYPE           IS NULL;
                EXCEPTION
                    WHEN OTHERS THEN
                        Dka_Tools_Pkg.put_log_message('-- ----------------------------------------------------------------- --');
                        Dka_Tools_Pkg.put_log_message('-- Erreur : Mise à jour de la DA ' || Rec_Da_System_Saved.NUM_ENTETE);
                        Dka_Tools_Pkg.put_log_message('-- ----------------------------------------------------------------- --');
                END;
                IF pv_mail_envoi = 'Y' THEN
                    -- Recherche de l'adresse mail de l'utilisateur qui a fait la demande d'achat. --
          recherche_mail(pv_errbuf, pn_retcode, pv_mail, pv_name_mail, pv_appart_demandeur, Rec_Da_System_Saved.REQUISITION_HEADER_ID, pv_mail_test);
          
          Dka_Tools_Pkg.put_log_message('-- pv_errbuf : ' || pv_errbuf);
                    Dka_Tools_Pkg.put_log_message('-- pn_retcode : ' || pn_retcode);
                    Dka_Tools_Pkg.put_log_message('-- pv_mail : ' || pv_mail);
                    Dka_Tools_Pkg.put_log_message('-- pv_name_mail : ' || pv_name_mail);
                    Dka_Tools_Pkg.put_log_message('-- pv_appart_demandeur : ' || pv_appart_demandeur);

                    -- Envoi d'un mail au créateur de la DA. --
                    envoi_mail(pv_errbuf, pn_retcode, pv_mail, pv_name_mail, pv_appart_demandeur, Rec_Da_System_Saved.NUM_ENTETE, Rec_Da_System_Saved.DESCRIPTION);

        ELSE
                    Dka_Tools_Pkg.put_log_message('-- Pas d''envoi de mail à l''utilisateur ayant fait la demande d''achat.');
                END IF;
            END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            -- Retour à l'état précédent : --
            ROLLBACK;
            -- Mise en avertissement du traitement : --
            pn_retcode     := 2;
            -- Message d'erreur de type standard : --
            pv_errbuf    := 'Erreur inconnue : ' || SQLERRM;
            Dka_Tools_Pkg.put_log_message('Erreur :');
            Dka_Tools_Pkg.put_log_message('# SQLCODE : ' || SQLCODE);
            Dka_Tools_Pkg.put_log_message('# SQLERRM : ' || SQLERRM);
    END DA_Statut_System_Saved;
    
    
    --------------------------------------------------------------------------------
    --  Nom           : recherche_mail
    --  Description   : Recherche de l'adresse mail ainsi que du nom de l'utilisateur
    --                    qui a fait la demande d'achat.
    --
    --  Paramètres    : pv_errbuf         message d'erreur
    --                  pn_retcode       code de retour
    --                    pv_mail            mail de l'utilisateur qui a fait la DA.
    --                    pv_name_mail    mail et nom de l'utilisateur qui a fait la DA.
    --                    pn_header_id    identifiant de l'entête de la DA.
    --                     pn_line_id        identifiant de la ligne de la DA.
    --------------------------------------------------------------------------------
    PROCEDURE recherche_mail (pv_errbuf                    OUT    VARCHAR2,
                            pn_retcode                OUT NUMBER,
                            pv_mail                      OUT VARCHAR2,
                            pv_name_mail              OUT VARCHAR2,
                            pv_appart_demandeur    OUT    VARCHAR2,
                            pn_header_id              IN    NUMBER,
                            pv_mail_test        IN  VARCHAR2
                            )
    IS
    -- Déclaration des variables concernant les informations d'envoi de mail au demandeur de la DA. --
    nom_prenom_demandeur    VARCHAR2(200);
    mail_demandeur            VARCHAR2(200);
    appart_demandeur        VARCHAR2(100);
    
    BEGIN
        BEGIN
            SELECT  papf2.full_name,                                -- nom / prenom du demandeur.
                    nvl(fu.email_address,papf2.email_address),        -- adresse mail du demandeur.
                    papf2.attribute1                                -- appartenance du demandeur.
            INTO    nom_prenom_demandeur,
                    mail_demandeur,
                    appart_demandeur
            FROM    po_requisition_headers_all prha,
                    fnd_user fu,
                    --per_all_people_f papf2 -- RBE artf2376259
                    per_people_v7  papf2     -- RBE artf2376259
            WHERE   fu.user_id = prha.created_by
            AND     papf2.person_id = fu.employee_id
            AND     prha.requisition_header_id = pn_header_id;
        EXCEPTION
            WHEN OTHERS THEN
                -- Erreur s'il est impossible d'envoyer un mail au destinaire.
                pn_retcode     :=     2;
                pv_errbuf    :=    'Erreur lors de la recherche de l''utilisateur qui a fait la demande de DA. ' || SQLERRM;
                Dka_Tools_Pkg.put_log_message(pv_errbuf);
        END;
        
        pv_mail             :=     '<' || mail_demandeur || '>';
        pv_name_mail        :=     nom_prenom_demandeur || '<' || mail_demandeur || '>';
        pv_appart_demandeur :=    appart_demandeur;
        
    ------------------------------------
    --INITIALISATION ADRESSE MAIL TEST--
    ------------------------------------
    DKA_SEND_MAIL_PKG.mail_test(pv_mail_test,gv_mail_test);
    Dka_Tools_Pkg.put_log_message('Mail de test : '||gv_mail_test);
    
    EXCEPTION
        WHEN OTHERS THEN
            pn_retcode     := 2;
            pv_errbuf    := 'Erreur : Impossible de déterminer le mail et le nom de l''utilisateur qui a fait la demande de DA. ' || SQLERRM;
            Dka_Tools_Pkg.put_log_message(pv_errbuf);
    END recherche_mail;
    
    
    --------------------------------------------------------------------------------
    --  Nom           : envoi_mail
    --  Description   : Envoi d'un mail à l'utilisateur qui a fait la demande de DA.
    --
    --  Paramètres    : pv_errbuf         message d'erreur
    --                  pn_retcode       code de retour
    --                    pv_mail            mail de l'utilisateur qui a fait la DA.
    --                    pv_name_mail    mail et nom de l'utilisateur qui a fait la DA.
    --------------------------------------------------------------------------------
    PROCEDURE envoi_mail (pv_errbuf               OUT     VARCHAR2,
                          pn_retcode                          OUT     NUMBER,
                          pv_mail                                  IN          VARCHAR2,
                          pv_name_mail                          IN          VARCHAR2,
                          pv_appart_demandeur                IN          VARCHAR2,
                          pv_segment1                            IN          VARCHAR2,
                          pv_description                      IN          VARCHAR2
                          )
    IS
        crlf VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );
        mesg VARCHAR2( 4000 );
        conn UTL_SMTP.CONNECTION;
        vv_sujet_mail  VARCHAR2(200);
        vv_corps_mail  VARCHAR2(2000);
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        
        -- Récupération du sujet du mail et adaptation au contexte        
        vv_sujet_mail     := Dka_Tools_Pkg.get_message ('DKA',
                                                        'DKA_SPOWFDA_ERRORS_MAIL_SUJET',
                                                        'NUM_DA',
                                                         pv_segment1,
                                                        'APPART',
                                                         pv_appart_demandeur,
                                                        'DESCRIPTION',
                                                         pv_description);


        -- Récupération du corps du mail et adaptation au contexte
        vv_corps_mail     := Dka_Tools_Pkg.get_message ('DKA',
                                                        'DKA_SPOWFDA_ERRORS_MAIL_CORPS',
                                                        'NUM_DA',
                                                         pv_segment1,
                                                        'DESCRIPTION',
                                                         pv_description);

        -- Création et envoi du mail au créateur
        conn:= utl_smtp.open_connection( gv_conn, 25 ); 
        
            utl_smtp.helo( conn , gv_conn );
        utl_smtp.mail( conn , gv_expediteur );
        utl_smtp.rcpt( conn , NVL(gv_mail_test,pv_mail) );
        utl_smtp.open_data(conn);
        mesg:= 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || crlf ||
               'From: ' || gv_expediteur || crlf ||
               'To: ' || pv_mail || crlf ||
               'Subject:' || vv_sujet_mail || utl_tcp.CRLF ||
               'Content-Type: multipart/mixed;' || utl_tcp.CRLF ||
               vv_corps_mail || crlf;
        utl_smtp.write_data(conn, mesg);
        utl_smtp.close_data(conn);
        utl_smtp.quit( conn );
        
    EXCEPTION
        WHEN OTHERS THEN
            -- STATUS EN AVERTISSEMENT. --
            pn_retcode     :=     1;
            pv_errbuf    :=    'MAIL - ' || SQLERRM;
            Dka_Tools_Pkg.put_log_message(pv_errbuf);
    END envoi_mail;
    
END DKA_SPORETRT_DA_ANOS_PKG;
/
SHOW ERROR

EXIT
